hm user=username host=hostname *args:
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{ host }}"
    user="{{ user }}"
    region=""
    host_name="$target"

    found=$(find regions -mindepth 3 -maxdepth 3 -type d -name "$target" 2>/dev/null | head -n 1)
    if [ -n "$found" ]; then
      region=$(basename "$(dirname "$(dirname "$found")")")
      host_name=$(basename "$found")
    elif [[ "$target" == *-* ]]; then
      cand_region="${target%%-*}"
      cand_host="${target#*-}"
      if [ -d "regions/$cand_region/hosts/$cand_host" ]; then
        region="$cand_region"
        host_name="$cand_host"
      fi
    fi

    if [ -n "$region" ]; then
      target="${region}-${host_name}"
    fi

    echo "==> Building and activating Home Manager for user '$user' on '$target'..."
    gen_path=$(nix build --file . "nixosConfigurations.${target}.config.home-manager.users.${user}.home.activationPackage" --no-link --print-out-paths {{ args }})
    "$gen_path/activate"

build host=hostname *args:
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{ host }}"
    region=""
    host_name="$target"

    found=$(find regions -mindepth 3 -maxdepth 3 -type d -name "$target" 2>/dev/null | head -n 1)
    if [ -n "$found" ]; then
      region=$(basename "$(dirname "$(dirname "$found")")")
      host_name=$(basename "$found")
    elif [[ "$target" == *-* ]]; then
      cand_region="${target%%-*}"
      cand_host="${target#*-}"
      if [ -d "regions/$cand_region/hosts/$cand_host" ]; then
        region="$cand_region"
        host_name="$cand_host"
      fi
    fi

    if [ -n "$region" ]; then
      target="${region}-${host_name}"
    fi

    nh os build --file . "nixosConfigurations.$target" {{ args }}

switch host=hostname *args:
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{ host }}"
    region=""
    host_name="$target"

    found=$(find regions -mindepth 3 -maxdepth 3 -type d -name "$target" 2>/dev/null | head -n 1)
    if [ -n "$found" ]; then
      region=$(basename "$(dirname "$(dirname "$found")")")
      host_name=$(basename "$found")
    elif [[ "$target" == *-* ]]; then
      cand_region="${target%%-*}"
      cand_host="${target#*-}"
      if [ -d "regions/$cand_region/hosts/$cand_host" ]; then
        region="$cand_region"
        host_name="$cand_host"
      fi
    fi

    if [ -n "$region" ]; then
      target="${region}-${host_name}"
    fi

    nh os switch --file . "nixosConfigurations.$target" --ask {{ args }}

boot host=hostname *args:
    #!/usr/bin/env bash
    set -euo pipefail
    target="{{ host }}"
    region=""
    host_name="$target"

    found=$(find regions -mindepth 3 -maxdepth 3 -type d -name "$target" 2>/dev/null | head -n 1)
    if [ -n "$found" ]; then
      region=$(basename "$(dirname "$(dirname "$found")")")
      host_name=$(basename "$found")
    elif [[ "$target" == *-* ]]; then
      cand_region="${target%%-*}"
      cand_host="${target#*-}"
      if [ -d "regions/$cand_region/hosts/$cand_host" ]; then
        region="$cand_region"
        host_name="$cand_host"
      fi
    fi

    if [ -n "$region" ]; then
      target="${region}-${host_name}"
    fi

    nh os boot --file . "nixosConfigurations.$target" --ask {{ args }}

reboot host=hostname *args:
    just boot {{ host }} {{ args }}
    reboot

local-install host=hostname region="" *args:
    #!/usr/bin/env bash
    set -euo pipefail

    host="{{ host }}"
    region="{{ region }}"

    if [ -z "$region" ]; then
      found=$(find regions -mindepth 3 -maxdepth 3 -type d -name "$host" 2>/dev/null | head -n 1)
      if [ -n "$found" ]; then
        region=$(basename "$(dirname "$(dirname "$found")")")
        host=$(basename "$found")
      elif [[ "$host" == *-* ]]; then
        cand_region="${host%%-*}"
        cand_host="${host#*-}"
        if [ -d "regions/$cand_region/hosts/$cand_host" ]; then
          region="$cand_region"
          host="$cand_host"
        fi
      fi
      if [ -z "$region" ]; then
        region="home"
      fi
    fi

    nix_target="${region}-${host}"
    host_dir="regions/${region}/hosts/${host}"
    identities_dir="regions/${region}/identities"
    yubikey_id=""
    connected_serials=$(ykman list 2>/dev/null | awk '{print $NF}' || true)
    if [ -d "$identities_dir" ] && [ -n "$connected_serials" ]; then
      for idf in "$identities_dir"/*.txt; do
        [ -f "$idf" ] || continue
        for ser in $connected_serials; do
          if grep -q "Serial:[[:space:]]*$ser" "$idf" 2>/dev/null; then
            yubikey_id="$idf"
            break 2
          fi
        done
      done
    fi
    if [ -z "$yubikey_id" ] && [ -d "$identities_dir" ]; then
      yubikey_id=$(find "$identities_dir" -maxdepth 1 -name "*.txt" | sort | head -n 1)
    fi

    target_disk=""
    if [ -f "$host_dir/settings.json" ]; then
      target_disk=$(jq -r '.disk // empty' "$host_dir/settings.json")
    elif [ -f "$host_dir/settings/disk" ]; then
      target_disk=$(cat "$host_dir/settings/disk")
    fi

    if [ -z "$target_disk" ]; then
      echo "ERROR: Disk setting not found for $host in $host_dir/settings.json!" >&2
      exit 1
    fi

    read -r -p "Do you realy want to format $target_disk? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[yY]([eE][sS])?$ ]]; then
      echo "Installation cancelled."
      exit 1
    fi

    echo "==> Installing $nix_target to $target_disk..."

    # Create a temporary directory for host secrets
    temp=$(mktemp -d)
    cleanup() {
      rm -rf "$temp"
    }
    trap cleanup EXIT

    install -d -m755 "$temp/etc/ssh" "$temp/persist/etc/ssh"
    extra_files_args=()

    if [ -f "$host_dir/ssh_host_rsa_key.age" ]; then
      cp "$host_dir/ssh_host_rsa_key.pub" "$temp/etc/ssh/"
      cp "$host_dir/ssh_host_rsa_key.pub" "$temp/persist/etc/ssh/"
      rage -d "$host_dir/ssh_host_rsa_key.age" -i "$yubikey_id" > "$temp/etc/ssh/ssh_host_rsa_key"
      chmod 600 "$temp/etc/ssh/ssh_host_rsa_key"
      cp "$temp/etc/ssh/ssh_host_rsa_key" "$temp/persist/etc/ssh/ssh_host_rsa_key"
      chmod 600 "$temp/persist/etc/ssh/ssh_host_rsa_key"

      extra_files_args+=(--extra-files "$temp/etc/ssh/ssh_host_rsa_key" etc/ssh/ssh_host_rsa_key)
      extra_files_args+=(--extra-files "$temp/etc/ssh/ssh_host_rsa_key.pub" etc/ssh/ssh_host_rsa_key.pub)
      extra_files_args+=(--extra-files "$temp/persist/etc/ssh/ssh_host_rsa_key" persist/etc/ssh/ssh_host_rsa_key)
      extra_files_args+=(--extra-files "$temp/persist/etc/ssh/ssh_host_rsa_key.pub" persist/etc/ssh/ssh_host_rsa_key.pub)
    fi

    if [ -f "$host_dir/ssh_host_ed25519_key.age" ]; then
      cp "$host_dir/ssh_host_ed25519_key.pub" "$temp/etc/ssh/"
      cp "$host_dir/ssh_host_ed25519_key.pub" "$temp/persist/etc/ssh/"
      rage -d "$host_dir/ssh_host_ed25519_key.age" -i "$yubikey_id" > "$temp/etc/ssh/ssh_host_ed25519_key"
      chmod 600 "$temp/etc/ssh/ssh_host_ed25519_key"
      cp "$temp/etc/ssh/ssh_host_ed25519_key" "$temp/persist/etc/ssh/ssh_host_ed25519_key"
      chmod 600 "$temp/persist/etc/ssh/ssh_host_ed25519_key"

      extra_files_args+=(--extra-files "$temp/etc/ssh/ssh_host_ed25519_key" etc/ssh/ssh_host_ed25519_key)
      extra_files_args+=(--extra-files "$temp/etc/ssh/ssh_host_ed25519_key.pub" etc/ssh/ssh_host_ed25519_key.pub)
      extra_files_args+=(--extra-files "$temp/persist/etc/ssh/ssh_host_ed25519_key" persist/etc/ssh/ssh_host_ed25519_key)
      extra_files_args+=(--extra-files "$temp/persist/etc/ssh/ssh_host_ed25519_key.pub" persist/etc/ssh/ssh_host_ed25519_key.pub)
    fi

    # Clean up any lingering mounts from previous failed attempts
    sudo umount -R /mnt/disko-install-root 2>/dev/null || true

    sudo env PATH="/run/wrappers/bin:/run/current-system/sw/bin:/nix/var/nix/profiles/system/sw/bin:$PATH" \
      nix --extra-experimental-features "nix-command flakes" run github:nix-community/disko/latest#disko-install -- \
      --flake ".#${nix_target}" \
      --disk main "$target_disk" \
      "${extra_files_args[@]}" \
      --write-efi-boot-entries \
      {{ args }}
