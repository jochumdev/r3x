{
  lib,
  pkgs,
  coreutils ? pkgs.coreutils,
  findutils ? pkgs.findutils,
  gnused ? pkgs.gnused,
  gawk ? pkgs.gawk,
  gnugrep ? pkgs.gnugrep,
  jq ? pkgs.jq,
  yubikey-manager ? pkgs.yubikey-manager,
  age-plugin-yubikey ? pkgs.age-plugin-yubikey,
  git ? pkgs.git,
  vaultixManifest,
  vaultixBin,
}:
let
  toolsBinPath = lib.makeBinPath [
    coreutils
    findutils
    gnused
    gawk
    gnugrep
    jq
    yubikey-manager
    age-plugin-yubikey
    git
  ];
in
pkgs.writeShellScriptBin "vaultix-renc" ''
  set -euo pipefail
  export PATH="${toolsBinPath}:$PATH"

  MANIFEST="${vaultixManifest}"
  VAULTIX_BIN="${vaultixBin}"
  CACHE_DIR="./secrets/cache"

  ORIG_PWD="$PWD"
  FLAKE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

  usage() {
    echo "Usage: vaultix-renc [region] [file]" >&2
    echo "" >&2
    echo "Available regions:" >&2
    jq -r '.regions | keys[]' "$MANIFEST" | sed 's/^/  - /' >&2
    exit "''${1:-1}"
  }

  if [ $# -ge 1 ] && { [ "$1" = "-h" ] || [ "$1" = "--help" ]; }; then
    usage 0
  fi

  target_regions=()
  filter_file=""

  if [ $# -eq 0 ]; then
    mapfile -t target_regions < <(jq -r '.regions | keys[]' "$MANIFEST")
  elif [ $# -eq 1 ]; then
    arg="$1"
    if jq -e --arg r "$arg" '.regions[$r]' "$MANIFEST" >/dev/null 2>&1; then
      target_regions=("$arg")
    elif [[ "$arg" =~ ^(\./)?regions/([^/]+)/ ]]; then
      target_regions=("''${BASH_REMATCH[2]}")
      filter_file=$(basename "$arg")
    else
      fname=$(basename "$arg")
      # Check which regions consume this file
      mapfile -t matched_regions < <(jq -r --arg f "$fname" \
        '.regions | to_entries[] | select(.value.hosts[].secretFiles | index($f)) | .key' "$MANIFEST" | sort -u)
      if [ ''${#matched_regions[@]} -gt 0 ]; then
        target_regions=("''${matched_regions[@]}")
        filter_file="$fname"
      else
        # Check if file exists on disk in any region
        mapfile -t disk_regions < <(find "$FLAKE_ROOT/regions" -type f -name "$fname" 2>/dev/null | sed -n 's|.*/regions/\([^/]*\)/.*|\1|p' | sort -u)
        if [ ''${#disk_regions[@]} -gt 0 ]; then
          target_regions=("''${disk_regions[@]}")
          filter_file="$fname"
        else
          region_count=$(jq '.regions | keys | length' "$MANIFEST")
          if [ "$region_count" -eq 1 ]; then
            target_regions=($(jq -r '.regions | keys[0]' "$MANIFEST"))
            filter_file="$fname"
          else
            echo "Error: Unknown region or file '$arg'" >&2
            usage 1
          fi
        fi
      fi
    fi
  else
    target_regions=("$1")
    filter_file=$(basename "$2")
    if ! jq -e --arg r "''${target_regions[0]}" '.regions[$r]' "$MANIFEST" >/dev/null 2>&1; then
      echo "Error: Unknown region \"''${target_regions[0]}\"" >&2
      usage 1
    fi
  fi

  cd "$FLAKE_ROOT"

  for reg in "''${target_regions[@]}"; do
    identities_dir="regions/$reg/identities"
    if [ ! -d "$identities_dir" ]; then
      echo "Warning: Identities directory '$identities_dir' does not exist. Skipping region $reg." >&2
      continue
    fi

    mapfile -t id_files < <(find "$identities_dir" -maxdepth 1 -name "*.txt" | sort)
    if [ ''${#id_files[@]} -eq 0 ]; then
      echo "Warning: No identity files found in $identities_dir. Skipping region $reg." >&2
      continue
    fi

    active_id="''${id_files[0]}"
    connected_serials=$(ykman list 2>/dev/null | awk '{print $NF}' || true)

    if [ -n "$connected_serials" ]; then
      for idf in "''${id_files[@]}"; do
        for ser in $connected_serials; do
          if grep -q "Serial:[[:space:]]*$ser" "$idf" 2>/dev/null; then
            active_id="$idf"
            break 2
          fi
        done
      done
    fi

    if [ -n "$filter_file" ]; then
      mapfile -t host_profiles < <(jq -r --arg r "$reg" --arg f "$filter_file" \
        '.regions[$r].hosts[] | select(.secretFiles | index($f)) | .profile' "$MANIFEST")
      mapfile -t host_names < <(jq -r --arg r "$reg" --arg f "$filter_file" \
        '.regions[$r].hosts[] | select(.secretFiles | index($f)) | .hostName' "$MANIFEST")
    else
      mapfile -t host_profiles < <(jq -r --arg r "$reg" \
        '.regions[$r].hosts[].profile' "$MANIFEST")
      mapfile -t host_names < <(jq -r --arg r "$reg" \
        '.regions[$r].hosts[].hostName' "$MANIFEST")
    fi

    if [ ''${#host_profiles[@]} -eq 0 ]; then
      if [ -n "$filter_file" ]; then
        echo "==> [Region: $reg] No hosts consume secret '$filter_file'. Skipping."
      else
        echo "==> [Region: $reg] No hosts found. Skipping."
      fi
      continue
    fi

    profile_args=()
    for p in "''${host_profiles[@]}"; do
      profile_args+=(--profile "$p")
    done

    echo "==> [Region: $reg] Re-encrypting secrets for hosts (''${host_names[*]}) using identity '$active_id'..."
    "$VAULTIX_BIN" "''${profile_args[@]}" renc --identity "$active_id" --cache "$CACHE_DIR"
    echo "==> [Region: $reg] Done."
  done
''
