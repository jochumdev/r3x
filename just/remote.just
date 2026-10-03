deploy region host remote="local-https" *args:
    #!/usr/bin/env bash
    set -euo pipefail

    repo_root="$(pwd)"
    region="{{ region }}"
    host="{{ host }}"

    if [ -z "$region" ]; then
      echo "ERROR: region argument is required! Usage: just deploy <region> <host> [remote]" >&2
      exit 1
    fi
    if [ -z "$host" ]; then
      echo "ERROR: host argument is required! Usage: just deploy <region> <host> [remote]" >&2
      exit 1
    fi

    host_dir="$repo_root/regions/${region}/hosts/${host}"
    if [ ! -d "$host_dir" ]; then
      echo "ERROR: Host directory '$host_dir' does not exist!" >&2
      exit 1
    fi

    nix_target="${region}-${host}"
    identities_dir="$repo_root/regions/${region}/identities"
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

    echo "==> Deploying $host ($nix_target) in region '$region' to Incus remote '{{ remote }}'..."

    # Create temporary directory for decrypted extra-files and image assembly
    tmp=$(mktemp -d)
    cleanup() {
      rm -rf "$tmp"
    }
    trap cleanup EXIT

    extra_dir="$tmp/extra"
    mkdir -p "$extra_dir/etc/ssh"
    chmod 755 "$extra_dir/etc/ssh"

    if [ ! -f "$host_dir/ssh_host_ed25519_key.age" ]; then
      echo "ERROR: Host key '$host_dir/ssh_host_ed25519_key.age' not found!" >&2
      exit 1
    fi

    echo "==> Decrypting ed25519 host key for $host..."
    rage -d "$host_dir/ssh_host_ed25519_key.age" -i "$yubikey_id" > "$extra_dir/etc/ssh/ssh_host_ed25519_key"
    chmod 600 "$extra_dir/etc/ssh/ssh_host_ed25519_key"
    cp "$host_dir/ssh_host_ed25519_key.pub" "$extra_dir/etc/ssh/"
    chmod 644 "$extra_dir/etc/ssh/ssh_host_ed25519_key.pub"

    if [ -f "$host_dir/ssh_host_rsa_key.age" ]; then
      echo "==> Decrypting RSA host key for $host..."
      rage -d "$host_dir/ssh_host_rsa_key.age" -i "$yubikey_id" > "$extra_dir/etc/ssh/ssh_host_rsa_key"
      chmod 600 "$extra_dir/etc/ssh/ssh_host_rsa_key"
      cp "$host_dir/ssh_host_rsa_key.pub" "$extra_dir/etc/ssh/"
      chmod 644 "$extra_dir/etc/ssh/ssh_host_rsa_key.pub"
    fi

    # Determine if target host is a container or VM
    is_container=$(nix eval --json ".#nixosConfigurations.${nix_target}.config.boot.isContainer" 2>/dev/null || echo "false")

    echo "==> Building system image for $nix_target (isContainer=$is_container)..."
    metadata=$(nix build ".#nixosConfigurations.${nix_target}.config.system.build.metadata" --print-out-paths)

    if [ "$is_container" = "true" ]; then
      squashfs=$(nix build ".#nixosConfigurations.${nix_target}.config.system.build.squashfs" --print-out-paths)
      meta_tar_path=$(ls "$metadata"/tarball/nixos-image-lxc-*.tar.xz)
      upload_rootfs=$(ls "$squashfs"/nixos-lxc-image-*.squashfs)
    else
      qemu_img=$(nix build ".#nixosConfigurations.${nix_target}.config.system.build.qemuImage" --print-out-paths)
      meta_tar_path=$(ls "$metadata"/tarball/nixos.tar.xz)
      upload_rootfs=$(ls "$qemu_img"/nixos.qcow2)
    fi

    echo "==> Uploading image to {{ remote }}:nixos/$host..."
    incus image delete "{{ remote }}:nixos/$host" >/dev/null 2>&1 || true
    incus image import "$meta_tar_path" "$upload_rootfs" "{{ remote }}:" --alias "nixos/$host"

    state_file="state/${region}/${host}.tfstate"
    cd infra/opentofu
    mkdir -p "state/${region}"

    # Auto-migrate legacy unpartitioned state file if regional state doesn't exist
    if [ ! -f "$state_file" ] && [ -f "state/${host}.tfstate" ]; then
      echo "==> Migrating legacy state from state/${host}.tfstate to $state_file..."
      mv "state/${host}.tfstate" "$state_file"
      [ -f "state/${host}.tfstate.backup" ] && mv "state/${host}.tfstate.backup" "state/${region}/${host}.tfstate.backup" || true
    fi

    if command -v tofu >/dev/null 2>&1; then
      tofu_cmd=(tofu)
    else
      tofu_cmd=(nix run --extra-experimental-features "nix-command flakes" nixpkgs#opentofu --)
    fi

    "${tofu_cmd[@]}" init -upgrade=false >/dev/null

    var_files=()
    if [ -f "$host_dir/host.tfvars" ]; then
      var_files+=(-var-file="$host_dir/host.tfvars")
    elif [ -f "$host_dir/${host}.tfvars" ]; then
      var_files+=(-var-file="$host_dir/${host}.tfvars")
    elif [ -f "$host_dir/host.tfvars.json" ]; then
      var_files+=(-var-file="$host_dir/host.tfvars.json")
    elif [ -f "$host_dir/${host}.tfvars.json" ]; then
      var_files+=(-var-file="$host_dir/${host}.tfvars.json")
    fi

    files_json=()
    for f in "$extra_dir"/etc/ssh/*; do
      [ -f "$f" ] || continue
      fname=$(basename "$f")
      mode="0644"
      [[ "$fname" == *key && "$fname" != *.pub ]] && mode="0600"
      files_json+=("{\"target_path\":\"etc/ssh/$fname\",\"source_path\":\"$f\",\"mode\":\"$mode\"}")
    done
    echo "{\"persist_files\": [$(IFS=,; echo "${files_json[*]}")]}" > "$tmp/secrets.tfvars.json"
    var_files+=(-var-file="$tmp/secrets.tfvars.json")

    echo "==> Removing existing instance for $host..."
    if [ -f "$state_file" ]; then
      "${tofu_cmd[@]}" destroy -target=incus_instance.instance -auto-approve -state="$state_file" -var="host=$host" -var="incus_remote={{ remote }}" "${var_files[@]}" {{ args }} >/dev/null 2>&1 || true
    fi
    incus delete -f "{{ remote }}:$host" >/dev/null 2>&1 || true

    echo "==> Provisioning fresh instance for $host..."
    "${tofu_cmd[@]}" apply -auto-approve -state="$state_file" -var="host=$host" -var="incus_remote={{ remote }}" "${var_files[@]}" {{ args }}

    echo "==> Cleaning up image from {{ remote }}..."
    incus image delete "{{ remote }}:nixos/$host" >/dev/null 2>&1 || true

    echo "==> $host deployed successfully to {{ remote }}!"
    incus list "{{ remote }}:" "$host"

deploy-switch region host target=host *args:
    #!/usr/bin/env bash
    set -euo pipefail
    region="{{ region }}"
    host="{{ host }}"
    target="{{ target }}"
    extra_args=()
    if [[ "$target" == -* ]]; then
      extra_args+=("$target")
      target="$host"
    fi
    nix_target="${host#${region}-}"
    nix_target="${region}-${nix_target}"
    nixos-rebuild switch --flake ".#${nix_target}" --target-host "${target}" --elevate=sudo --ask-elevate-password "${extra_args[@]}" {{ args }}

rotate-ssh region host type="all":
    #!/usr/bin/env bash
    set -euo pipefail

    region="{{ region }}"
    host="{{ host }}"

    if [ -z "$region" ]; then
      echo "ERROR: region argument is required! Usage: just rotate-ssh <region> <host> [type]" >&2
      exit 1
    fi
    if [ -z "$host" ]; then
      echo "ERROR: host argument is required! Usage: just rotate-ssh <region> <host> [type]" >&2
      exit 1
    fi

    host_dir="regions/${region}/hosts/${host}"
    if [ ! -d "$host_dir" ]; then
      echo "ERROR: Host directory '$host_dir' does not exist!" >&2
      exit 1
    fi
    mkdir -p "$host_dir"

    tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    rotate_key() {
      local ktype="$1"
      local bits="$2"
      local priv_name="ssh_host_${ktype}_key"
      local age_file="$host_dir/${priv_name}.age"
      local pub_file="$host_dir/${priv_name}.pub"
      local tmp_key="$tmpdir/$priv_name"

      echo "==> Generating new ${ktype} host key for {{ host }}..."
      if [ -n "$bits" ]; then
        ssh-keygen -t "$ktype" -b "$bits" -N "" -C "root@{{ host }}" -f "$tmp_key"
      else
        ssh-keygen -t "$ktype" -N "" -C "root@{{ host }}" -f "$tmp_key"
      fi

      echo "==> Updating public key in $pub_file..."
      cp "${tmp_key}.pub" "$pub_file"

      echo "==> Encrypting private key into $age_file via vaultix-edit..."
      if vaultix-edit "$region" "$age_file" < "$tmp_key"; then
        echo "==> Successfully encrypted $age_file"
      else
        echo "ERROR: vaultix-edit failed" >&2
        exit 1
      fi
    }

    case "{{ type }}" in
      ed25519)
        rotate_key "ed25519" ""
        ;;
      rsa)
        rotate_key "rsa" "4096"
        ;;
      all)
        rotate_key "ed25519" ""
        rotate_key "rsa" "4096"
        ;;
      *)
        echo "Unknown key type '{{ type }}'. Valid options: ed25519, rsa, all" >&2
        exit 1
        ;;
    esac

    echo "==> Running vaultix-renc to update secrets cache..."
    vaultix-renc "$region"

    echo "==> Staging updated keys and cache in git..."
    git add "$host_dir" secrets/cache

    echo "==> SSH host key rotation completed for {{ host }}!"

destroy-host region host remote="local-https" *args:
    #!/usr/bin/env bash
    set -euo pipefail

    repo_root="$(pwd)"
    region="{{ region }}"
    host="{{ host }}"

    if [ -z "$region" ]; then
      echo "ERROR: region argument is required! Usage: just destroy-host <region> <host> [remote]" >&2
      exit 1
    fi
    if [ -z "$host" ]; then
      echo "ERROR: host argument is required! Usage: just destroy-host <region> <host> [remote]" >&2
      exit 1
    fi

    echo "==> Destroying host $host in region '$region' on Incus remote '{{ remote }}'..."
    state_file="state/${region}/${host}.tfstate"
    cd infra/opentofu

    if command -v tofu >/dev/null 2>&1; then
      tofu_cmd=(tofu)
    else
      tofu_cmd=(nix run --extra-experimental-features "nix-command flakes" nixpkgs#opentofu --)
    fi

    if [ -f "$state_file" ]; then
      "${tofu_cmd[@]}" destroy -auto-approve -state="$state_file" -var="host=$host" -var="incus_remote={{ remote }}" {{ args }} >/dev/null 2>&1 || true
      rm -f "$state_file" "$state_file.backup"
    fi
    incus delete -f "{{ remote }}:$host" >/dev/null 2>&1 || true
    incus storage volume delete "{{ remote }}:default" "${host}-persist" >/dev/null 2>&1 || true
    echo "==> Completely destroyed $host and deleted persistent volume from {{ remote }}."
