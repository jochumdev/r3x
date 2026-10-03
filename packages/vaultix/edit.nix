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
  fzf ? pkgs.fzf,
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
    fzf
    age-plugin-yubikey
    git
  ];
in
pkgs.writeShellScriptBin "vaultix-edit" ''
    set -euo pipefail
    export PATH="${toolsBinPath}:$PATH"

    MANIFEST="${vaultixManifest}"
    VAULTIX_BIN="${vaultixBin}"
    CACHE_DIR="./secrets/cache"

    ORIG_PWD="$PWD"
    FLAKE_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)

    usage() {
      echo "Usage: vaultix-edit [region] [file] [--stdin] [--no-renc]" >&2
      echo "       echo \"secret\" | vaultix-edit [region] <file>" >&2
      echo "" >&2
      echo "Available regions:" >&2
      jq -r '.regions | keys[]' "$MANIFEST" | sed 's/^/  - /' >&2
      exit "''${1:-1}"
    }

    no_renc=false
    stdin_flag=false
    raw_args=()
    for a in "$@"; do
      if [ "$a" = "-h" ] || [ "$a" = "--help" ]; then
        usage 0
      elif [ "$a" = "--no-renc" ]; then
        no_renc=true
      elif [ "$a" = "--stdin" ] || [ "$a" = "-" ]; then
        stdin_flag=true
      else
        raw_args+=("$a")
      fi
    done

    from_stdin=false
    if [ "$stdin_flag" = true ] || [ ! -t 0 ]; then
      from_stdin=true
    fi

    tmp_dir=$(mktemp -d)
    cleanup() {
      rm -rf "$tmp_dir"
    }
    trap cleanup EXIT

    if [ "$from_stdin" = true ]; then
      stdin_tmp="$tmp_dir/stdin_content"
      cat > "$stdin_tmp"
    fi

    region=""
    file=""

    if [ ''${#raw_args[@]} -ge 2 ]; then
      region="''${raw_args[0]}"
      file="''${raw_args[1]}"
      if ! jq -e --arg r "$region" '.regions[$r]' "$MANIFEST" >/dev/null 2>&1; then
        echo "Error: Unknown region '$region'" >&2
        usage 1
      fi
    elif [ ''${#raw_args[@]} -eq 1 ]; then
      arg="''${raw_args[0]}"
      if jq -e --arg r "$arg" '.regions[$r]' "$MANIFEST" >/dev/null 2>&1; then
        region="$arg"
        file=""
      elif [[ "$arg" =~ ^(\./)?regions/([^/]+)/ ]]; then
        region="''${BASH_REMATCH[2]}"
        file="$arg"
      else
        file_cand="$arg"
        region_count=$(jq '.regions | keys | length' "$MANIFEST")
        if [ "$region_count" -eq 1 ]; then
          region=$(jq -r '.regions | keys[0]' "$MANIFEST")
          file="$file_cand"
        else
          mapfile -t found < <(find "$FLAKE_ROOT/regions" -type f -name "$(basename "$file_cand")" 2>/dev/null || true)
          if [ ''${#found[@]} -eq 1 ]; then
            rel_found=$(realpath --relative-to="$FLAKE_ROOT" "''${found[0]}")
            file="$rel_found"
            if [[ "$file" =~ ^regions/([^/]+)/ ]]; then
              region="''${BASH_REMATCH[1]}"
            fi
          elif [ ''${#found[@]} -gt 1 ]; then
            echo "Error: Multiple files named '$(basename "$file_cand")' found across regions:" >&2
            for f in "''${found[@]}"; do
              echo "  - $(realpath --relative-to="$FLAKE_ROOT" "$f")" >&2
            done
            echo "Please specify region: vaultix-edit [region] <file>" >&2
            exit 1
          else
            echo "Error: Cannot determine region for '$file_cand'. Please specify: vaultix-edit [region] <file>" >&2
            usage 1
          fi
        fi
      fi
    fi

    # If file was passed as relative path in caller's PWD, convert to relative to FLAKE_ROOT
    if [ -n "$file" ] && [ -f "$ORIG_PWD/$file" ]; then
      file=$(realpath --relative-to="$FLAKE_ROOT" "$ORIG_PWD/$file")
    fi

    cd "$FLAKE_ROOT"

    # Interactive file selection if file is omitted
    if [ -z "$file" ]; then
      if [ "$from_stdin" = true ]; then
        echo "Error: Cannot write stdin without specifying a target file." >&2
        echo "" >&2
        usage 1
      fi
      if [ -t 0 ] && command -v fzf >/dev/null 2>&1; then
        search_path="regions"
        if [ -n "$region" ]; then
          search_path="regions/$region"
        fi
        file=$(find "$search_path" -type f -name "*.age" 2>/dev/null | fzf --prompt="Select secret to edit: " || true)
        if [ -z "$file" ]; then
          echo "No secret selected." >&2
          exit 0
        fi
        if [ -z "$region" ] && [[ "$file" =~ ^(\./)?regions/([^/]+)/ ]]; then
          region="''${BASH_REMATCH[2]}"
        fi
      else
        if [ -n "$region" ]; then
          echo "Error: No secret file specified for region '$region'." >&2
          echo "" >&2
          echo "Available secret files in region '$region':" >&2
          find "regions/$region" -type f -name "*.age" 2>/dev/null | sed 's/^/  - /' >&2
        else
          echo "Error: No region or secret file specified." >&2
        fi
        echo "" >&2
        usage 1
      fi
    fi

    # If region is still not known, try to deduce from file path
    if [ -z "$region" ]; then
      if [[ "$file" =~ ^(\./)?regions/([^/]+)/ ]]; then
        region="''${BASH_REMATCH[2]}"
      else
        region_count=$(jq '.regions | keys | length' "$MANIFEST")
        if [ "$region_count" -eq 1 ]; then
          region=$(jq -r '.regions | keys[0]' "$MANIFEST")
        else
          echo "Error: Cannot determine region for '$file'. Please specify: vaultix-edit [region] <file>" >&2
          usage 1
        fi
      fi
    fi

    # Resolve file path inside region if relative
    if [ ! -f "$file" ]; then
      if [ -f "regions/$region/$file" ]; then
        file="regions/$region/$file"
      else
        mapfile -t found_in_reg < <(find "regions/$region" -type f -name "$(basename "$file")" 2>/dev/null || true)
        if [ ''${#found_in_reg[@]} -eq 1 ]; then
          file="''${found_in_reg[0]}"
        elif [ ''${#found_in_reg[@]} -gt 1 ]; then
          echo "Error: Multiple files named '$(basename "$file")' found in region '$region':" >&2
          for f in "''${found_in_reg[@]}"; do
            echo "  - $f" >&2
          done
          echo "Please specify the full relative path." >&2
          exit 1
        else
          if [[ "$file" != regions/* ]]; then
            file="regions/$region/$file"
          fi
        fi
      fi
    fi

    if [ ! -f "$file" ]; then
      mkdir -p "$(dirname "$file")"
    fi

    identities_dir="regions/$region/identities"
    if [ ! -d "$identities_dir" ]; then
      echo "Error: Identities directory '$identities_dir' does not exist." >&2
      exit 1
    fi

    mapfile -t id_files < <(find "$identities_dir" -maxdepth 1 -name "*.txt" | sort)
    if [ ''${#id_files[@]} -eq 0 ]; then
      echo "Error: No identity files found in $identities_dir" >&2
      exit 1
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

    recipient_args=()
    for idf in "''${id_files[@]}"; do
      recip=$(grep -E '^[#[:space:]]*Recipient:' "$idf" 2>/dev/null | head -n 1 | awk '{print $NF}')
      if [ -n "$recip" ]; then
        recipient_args+=(--recipient "$recip")
      fi
    done

    pre_hash=""
    if [ -f "$file" ]; then
      pre_hash=$(sha256sum "$file" | awk '{print $1}')
    fi

    if [ "$from_stdin" = true ]; then
      writer="$tmp_dir/writer.sh"
      cat << 'EOF' > "$writer"
  #!/usr/bin/env bash
  cat "$STDIN_TMP_FILE" > "$1"
  EOF
      chmod +x "$writer"

      export STDIN_TMP_FILE="$stdin_tmp"
      export VISUAL="$writer"
      export EDITOR="$writer"

      echo "==> [Region: $region] Encrypting stdin to $file using identity $active_id..."
    else
      echo "==> [Region: $region] Editing $file using identity $active_id..."
    fi

    "$VAULTIX_BIN" edit --identity "$active_id" "''${recipient_args[@]}" "$file"

    post_hash=""
    if [ -f "$file" ]; then
      post_hash=$(sha256sum "$file" | awk '{print $1}')
    fi

    if [ "$no_renc" = false ] && [ -f "$file" ] && [ "$pre_hash" != "$post_hash" ]; then
      fname=$(basename "$file")
      mapfile -t host_profiles < <(jq -r --arg r "$region" --arg f "$fname" \
        '.regions[$r].hosts[] | select(.secretFiles | index($f)) | .profile' "$MANIFEST")
      mapfile -t host_names < <(jq -r --arg r "$region" --arg f "$fname" \
        '.regions[$r].hosts[] | select(.secretFiles | index($f)) | .hostName' "$MANIFEST")

      if [ ''${#host_profiles[@]} -gt 0 ]; then
        echo "==> [Region: $region] Secret changed. Re-encrypting for hosts (''${host_names[*]}) using identity '$active_id'..."
        profile_args=()
        for p in "''${host_profiles[@]}"; do
          profile_args+=(--profile "$p")
        done
        "$VAULTIX_BIN" "''${profile_args[@]}" renc --identity "$active_id" --cache "$CACHE_DIR"
        echo "==> [Region: $region] Cache updated successfully."
      fi
    fi
''
