test-u2f host=hostname:
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

    if [ -z "$region" ]; then
      region="home"
    fi
    nix_target="${region}-${host_name}"
    mapping_file="modules/users/{{ username }}/u2f_mappings"
    if [ ! -f "$mapping_file" ]; then
      # Fallback to any user mapping found
      found_map=$(find modules/users -name "u2f_mappings" 2>/dev/null | head -n 1)
      if [ -n "$found_map" ]; then
        mapping_file="$found_map"
      fi
    fi

    echo "==> Testing U2F configuration for $host_name ($nix_target)..."

    if [ ! -f "$mapping_file" ]; then
      echo "No u2f_mappings found at $mapping_file"
      exit 0
    fi

    echo "  [1/3] Validating $mapping_file syntax and credentials..."
    python3 -c "
    import base64

    with open('$mapping_file') as f:
        content = f.read().strip()

    if not content:
        raise ValueError('u2f_mappings file is empty')

    parts = content.split(':')
    user = parts[0]
    print(f'        User: {user}')
    if not user:
        raise ValueError('Missing user in mapping file')

    for i, cred in enumerate(parts[1:], 1):
        fields = cred.split(',')
        if len(fields) < 4:
            raise ValueError(f'Credential #{i} has fewer than 4 fields: {cred}')
        kh, pk, cose, opt = fields[0], fields[1], fields[2], fields[3]
        kh_bytes = base64.b64decode(kh)
        pk_bytes = base64.b64decode(pk)
        if len(pk_bytes) != 64:
            raise ValueError(f'Credential #{i} public key length is {len(pk_bytes)}, expected 64 raw EC bytes')
        if cose != 'es256':
            raise ValueError(f'Credential #{i} unexpected COSE type: {cose}')
        print(f'        Credential #{i}: KH={len(kh_bytes)}B, PK={len(pk_bytes)}B ({cose}, {opt}) - OK')
    "

    echo "  [2/3] Checking NixOS evaluation for store path..."
    src=$(nix-instantiate --eval -E "(import ./default.nix).nixosConfigurations.${nix_target}.config.environment.etc.u2f_mappings.source" 2>/dev/null || echo "")
    if [[ "$src" == *"\"/home/"* ]]; then
      echo "  ERROR: environment.etc.u2f_mappings.source points to /home/: $src" >&2
      exit 1
    fi
    echo "        Nix path: $src"

    echo "  [3/3] Checking connected FIDO2 / YubiKey devices..."
    if command -v fido2-token >/dev/null 2>&1; then
      fido2-token -L || true
    else
      nix-shell -p libfido2 --run "fido2-token -L" 2>/dev/null || true
    fi

    echo "==> U2F configuration test passed!"

enroll-u2f user=username *args:
    #!/usr/bin/env bash
    set -euo pipefail
    target_user="{{ user }}"
    mapping_file="modules/users/${target_user}/u2f_mappings"
    echo "==> Enrolling U2F / FIDO2 key for user '$target_user' (origin: pam://host)..."
    echo "==> Please touch your YubiKey / FIDO device when it flashes..."
    line=$(pamu2fcfg -o pam://host -i pam://host -u "$target_user" {{ args }})
    echo "==> Generated credential: $line"
    echo "$line" > "$mapping_file"
    echo "==> Successfully enrolled key for $target_user in $mapping_file!"

enroll-ssh-sk user=username key_name="id_ed25519_sk" *args:
    #!/usr/bin/env bash
    set -euo pipefail
    target_user="{{ user }}"
    key_name="{{ key_name }}"
    ssh_dir="$HOME/.ssh"
    key_file="$ssh_dir/$key_name"
    mkdir -p "$ssh_dir"
    chmod 700 "$ssh_dir"
    if [ -f "$key_file" ]; then
      echo "==> Note: $key_file already exists."
      if [ "$key_name" = "id_ed25519_sk" ] && [ ! -f "$ssh_dir/id_ed25519_sk_2" ]; then
        suggested="id_ed25519_sk_2"
      elif [ ! -f "$ssh_dir/id_ed25519_sk_backup" ]; then
        suggested="id_ed25519_sk_backup"
      else
        suggested="${key_name}_new"
      fi
      read -r -p "Enter filename to save key descriptor [default: $suggested]: " custom_file
      chosen_name="${custom_file:-$suggested}"
      key_file="$ssh_dir/$chosen_name"
    fi
    echo "==> Enrolling FIDO2 ed25519-sk resident SSH key for user '$target_user' -> $key_file..."
    echo "==> Please touch your YubiKey when it flashes (and enter PIN if prompted for resident enrollment)..."
    ssh-keygen -t ed25519-sk -O resident -C "${target_user}@$(hostname -s)-$(basename "$key_file")" -f "$key_file" {{ args }}
    pub_key=$(cat "${key_file}.pub")
    echo "==> Successfully generated hardware-backed SSH key!"
    echo "    Public key: $pub_key"
    user_auth_file="modules/users/${target_user}/authorized_keys"
    if [ -f "$user_auth_file" ]; then
      if ! grep -qF "$pub_key" "$user_auth_file"; then
        read -r -p "Do you want to append this key to $user_auth_file? [Y/n] " add_confirm
        if [[ ! "$add_confirm" =~ ^[nN] ]]; then
          echo "$pub_key" >> "$user_auth_file"
          echo "==> Added public key to $user_auth_file"
        fi
      else
        echo "==> Public key is already present in $user_auth_file"
      fi
    fi

fetch-ssh-sk *args:
    #!/usr/bin/env bash
    set -euo pipefail
    ssh_dir="$HOME/.ssh"
    mkdir -p "$ssh_dir"
    cd "$ssh_dir"
    echo "==> Fetching resident FIDO2 keys from connected YubiKey into ~/.ssh/..."
    ssh-keygen -K {{ args }}
    echo "==> Resident keys in ~/.ssh/:"
    ls -la "$ssh_dir"/id_*_sk* 2>/dev/null || true
