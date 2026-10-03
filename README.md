# r3x - René Jochum's NixOS Environment

Fleet infrastructure, system configurations, and desktop environments built using [Den](https://github.com/denful/den) / [Dendritic](https://dendritic.oeiuwq.com) architecture, based on [Vic's vix](https://github.com/vic/vix).

This configuration manages multi-region baremetal machines, Incus virtual machines, and LXC development containers with unified secret management, hardware-backed identity encryption, and modular recipes.

> [!WARNING]
> **AI-Assisted Codebase**: This repository and its configurations are heavily written, refactored, and maintained using AI coding tools. Review configurations, Nix modules, and scripts carefully before adapting or applying them to your own infrastructure.

---

## Architecture & Principles

- **Dendritic Design via [Den](https://github.com/denful/den)**: Composable system aspects, roles, and parametric policies separating system concerns from user dotfiles.
- **Unflaked Inputs**: Dependencies are declared with [`flake-file.inputs`](https://github.com/vic/flake-file), pinned via [npins](https://github.com/andir/npins), and loaded at evaluation time using [with-inputs](https://github.com/vic/with-inputs) and [flake-parts](https://github.com/hercules-ci/flake-parts).
- **Two Den Namespaces**:
  - `r3x`: Reusable infrastructure modules, system roles, desktop environments (COSMIC, Niri), disk partitioning schemes (Btrfs, Impermanence), security, and services.
  - `users`: User configurations, dotfiles, desktop settings, applications, and home-manager integration (e.g. [`modules/users/r3j0`](modules/users/r3j0)).

---

## Directory Organization

```
.
├── Justfile               # Entrypoint delegating to modular just/*.just recipes
├── just/
│   ├── local.just         # Local machine build, switch, boot, and install recipes
│   ├── remote.just        # Remote Incus deployments and SSH host key rotation
│   └── u2f.just           # U2F / FIDO2 authentication testing and enrollment
├── modules/
│   ├── den.nix            # Declares the 'r3x' and 'users' namespaces
│   ├── defaults.nix       # Base schema defaults and settings options
│   ├── hosts.nix          # Dynamic host discovery and user mapping
│   ├── r3x/               # Shared aspects: roles, desktops, disks, services
│   ├── templates/         # Host templates: desktop, desktop-vm, devcontainer, live
│   └── users/             # User aspect definitions and configurations
├── packages/              # Custom derivations (e.g. vaultix tool suite)
├── regions/               # Region-scoped hosts, settings, secrets, and identities
│   └── home/
│       ├── settings.json  # Regional settings (region, domain, default users)
│       ├── identities/    # Hardware-backed Age identities (YubiKey public recipients)
│       ├── hosts/         # Host-specific settings, keys, and OpenTofu variables
│       │   ├── dev01/     # LXC devcontainer
│       │   ├── w2020/     # Baremetal workstation
│       │   └── w2020-vm/  # Incus desktop VM
│       └── users/         # Regional secrets (e.g. shadow.age)
└── secrets/cache/         # Encrypted secret material cached per host for offline boot
```

---

## Regional & Host Configuration

Host declarations live under `regions/<region>/hosts/<host>/`.

1. **Regional Defaults (`regions/<region>/settings.json`)**:
   Sets region-wide defaults inherited by all hosts in that region:

   ```json
   {
     "region": "home",
     "domain": "home.jochum.dev",
     "users": ["r3j0"]
   }
   ```

2. **Host Settings (`regions/<region>/hosts/<host>/settings.json`)**:
   Overrides template, disk devices, or user lists per machine:
   ```json
   {
     "template": "desktop",
     "disk": "/dev/nvme0n1",
     "users": ["r3j0"]
   }
   ```

### Available Host Templates

| Template       | Role                  | Notes                                                               |
| -------------- | --------------------- | ------------------------------------------------------------------- |
| `desktop`      | Baremetal workstation | Btrfs, COSMIC Desktop, Niri, PipeWire, NixOS facter, YubiKey, Incus |
| `desktop-vm`   | Incus VM Desktop      | Virtualized desktop with graphical support and system tools         |
| `devcontainer` | Incus LXC Container   | Fast, lightweight container with developer tools and SSH            |
| `live`         | Installation ISO      | Bootable installer with ZFS, facter, and hardware detection         |

### Current Hosts

| Target          | Region | Host       | Template       | Platform     | Users                    |
| --------------- | ------ | ---------- | -------------- | ------------ | ------------------------ |
| `home-w2020`    | `home` | `w2020`    | `desktop`      | x86_64-linux | `r3j0`                   |
| `home-w2020-vm` | `home` | `w2020-vm` | `desktop-vm`   | x86_64-linux | `r3j0`                   |
| `home-dev01`    | `home` | `dev01`    | `devcontainer` | x86_64-linux | `r3j0`, `r3j0-2`         |
| `live`          | —      | `live`     | `live`         | x86_64-linux | `nixos`                  |

---

## User Management (`settings.users`)

Host configurations specify users and their groups directly in `settings.json`:

```json
"users": {
  "r3j0": {
    "groups": ["wheel", "networkmanager"]
  }
}
```

- **Group Control**: Groups such as `wheel` (for `sudo` access) and `networkmanager` are configured explicitly per user per host rather than relying on list order.
- **U2F Authentication**: `/etc/u2f_mappings` dynamically aggregates credentials from `modules/users/<user>/u2f_mappings` for all users active on the host.

---

## YubiKey & Authentication Management

Hardware security keys (YubiKeys) serve two core functions in this environment:

1. **PAM U2F / FIDO2 Authentication**: Passwordless `sudo`, display manager login (`cosmic-greeter`), screen unlock, and polkit authorization.
2. **Age Hardware Identity Decryption**: Decrypting host private keys, passwords, and Vaultix secrets without private keys stored on disk.

### Sudo Authentication (Local vs. SSH)

The PAM configuration in [`modules/r3x/yubikey.nix`](modules/r3x/yubikey.nix) implements context-aware privilege escalation:

```
                  ┌──────────────────────┐
                  │      sudo cmd        │
                  └──────────┬───────────┘
                             │
                  ┌──────────▼───────────┐
                  │   check_not_ssh      │
                  │ (inspect /proc/environ)
                  └──────────┬───────────┘
                             │
              ┌──────────────┴──────────────┐
              │                             │
    [Local Session (exit 0)]       [SSH Session (exit 1)]
              │                             │
    Skip pam_unix (1 jump)         Run pam_unix (requisite)
              │                             │
    ┌─────────▼──────────┐         ┌────────▼───────────┐
    │     pam_u2f        │         │   Password Prompt  │
    │  (Touch YubiKey)   │         │  (Unix credentials)│
    └────────────────────┘         └────────────────────┘
```

- **Local `sudo` (Passwordless Touch)**:
  - The custom PAM helper `check-not-ssh` inspects the process hierarchy and environment variables (`SSH_CONNECTION`, `SSH_CLIENT`, `SSH_TTY`, `sshd` parent processes).
  - On local sessions, it exits `0`. With `[success=1 default=ignore]`, PAM skips the standard `pam_unix` password prompt and jumps directly to `pam_u2f`.
  - The terminal cues you (`Please touch the device.`), and tapping your YubiKey completes authentication instantly.
- **`sudo` over SSH (Password Fallback)**:
  - When invoked from an SSH session, `check-not-ssh` detects the SSH environment and exits `1`.
  - The skip is bypassed, and `pam_unix` is evaluated with `[success=done default=die]`.
  - The user is prompted for their Unix password instead of waiting for a physical key touch on the remote machine. If password verification succeeds, authentication is immediately complete (`success=done`).

### Session Auto-Lock on YubiKey Removal

A custom udev rule in [`modules/r3x/yubikey.nix`](modules/r3x/yubikey.nix) monitors the USB bus for YubiKey disconnect events:

```udev
ACTION=="remove", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="1050", RUN+="loginctl lock-sessions"
```

Unplugging your YubiKey immediately triggers `loginctl lock-sessions`, securing the workstation when stepping away.

### Greeter, Login, and Polkit Integration

YubiKey U2F authentication is enabled with `sufficient` control across all authentication entry points:

- **COSMIC Greeter**: Graphical login screen accepts YubiKey touch (configured in [`modules/r3x/services/cosmic-greeter.nix`](modules/r3x/services/cosmic-greeter.nix)).
- **Console Login**: TTY login accepts key touch.
- **Polkit-1**: Graphical privilege escalation dialogs prompt for YubiKey touch.
- **Swaylock**: Lock screen unlock via touch.

### U2F Key Enrollment & Verification

U2F credential mappings are stored declaratively at `modules/users/<user>/u2f_mappings` and built into `/etc/u2f_mappings` in the Nix store.

1. **Enroll Primary / New Key**:

   ```bash
   # Enrolls a key for the specified user (defaults to current user)
   just enroll-u2f [user]
   ```

   This invokes `pamu2fcfg -o pam://host -i pam://host -u <user>` and writes the mapping record.

2. **Add Backup / Secondary Keys**:
   To add a second key to an existing user without overwriting:

   ```bash
   # Generate credential string for the second key
   pamu2fcfg -n -o pam://host -i pam://host -u <user>
   ```

   Append the output as a colon-separated credential to `modules/users/<user>/u2f_mappings`:

   ```
   <username>:<credential_1>:<credential_2>
   ```

3. **Verify Configuration**:
   ```bash
   just test-u2f [host]
   ```
   Validates mapping syntax (decodes base64 keys, verifies ES256 COSE algorithm), verifies the Nix store path, and queries connected FIDO2 tokens.

### Hardware SSH Keys (FIDO2 / `ssh-sk`) & Proton Pass

This environment supports OpenSSH FIDO2 hardware keys (`sk-ssh-ed25519@openssh.com`) alongside Proton Pass (`pass-cli ssh-agent`):

- **How `ssh-sk` Works with Proton Pass**:
  - Proton Pass manages software keys stored in your cloud vault via `SSH_AUTH_SOCK` (`~/.ssh/proton-pass-agent.sock`).
  - For `ssh-sk` keys, the private key is physically trapped inside the YubiKey's secure element. OpenSSH accesses the YubiKey directly via `libfido2` (`/dev/hidraw*`).
  - OpenSSH client configuration in [`modules/users/r3j0/default.nix`](modules/users/r3j0/default.nix) automatically offers `~/.ssh/id_ed25519_sk` alongside keys loaded in the Proton Pass agent. Both work seamlessly side-by-side without contention.

- **Enrolling Primary and Secondary (Backup) Keys**:
  Each physical YubiKey possesses an independent secure element; private keys cannot be duplicated across keys. Therefore, each physical YubiKey produces a separate public key that is added to `modules/users/<user>/authorized_keys`:

  ```bash
  # 1. Plug in Key 1 (Primary)
  just enroll-ssh-sk [user] id_ed25519_sk

  # 2. Plug in Key 2 (Backup)
  just enroll-ssh-sk [user] id_ed25519_sk_2
  ```
  - Both public keys are appended to `modules/users/<user>/authorized_keys` so that any target machine in your fleet will accept either key.
  - OpenSSH client is preconfigured in `modules/users/<user>/default.nix` to iterate over `id_ed25519_sk`, `id_ed25519_sk_2`, and `id_ed25519_sk_backup`. If Key 2 is plugged in, OpenSSH automatically tries Key 2 when Key 1 is absent.
  - `-O resident`: Stored internally on the YubiKey flash memory (can be fetched on any new machine via `ssh-keygen -K`).
  - **Touch-Only Verification**: Keys are enrolled without `-O verify-required`, requiring only a physical touch on your YubiKey for each Git commit or SSH session (no PIN required during use).

- **Fetching Resident Keys on a New Machine**:
  ```bash
  # Downloads resident key handles from whichever YubiKey is currently connected to ~/.ssh/
  just fetch-ssh-sk
  ```
  No need to copy key files between machines—simply plug in either YubiKey and run `just fetch-ssh-sk` or load it directly into memory with `ssh-add -K`.

### Hardware-Backed Age Identities (`age-plugin-yubikey`)

Vaultix and host secrets use [`age-plugin-yubikey`](https://github.com/str4d/age-plugin-yubikey) for hardware-backed decryption:

- **Identity Files (`regions/<region>/identities/`)**:
  Files such as `r3j0-1.txt` and `r3j0-2.txt` declare the YubiKey serial, slot, and public Age recipient (`age1yubikey1...`).
- **Dynamic Serial Detection**:
  When running `vaultix-edit` or `vaultix-renc`, the script queries `ykman list` to detect which physical YubiKey is currently plugged into the system and selects the corresponding identity file automatically.
- **Provisioning a New YubiKey for Age**:
  ```bash
  # Generate an age identity on a plugged-in YubiKey
  age-plugin-yubikey > regions/<region>/identities/<user>-<slot>.txt
  ```

---

## Secret Management with Vaultix

Host and user secrets are encrypted using `vaultix` with regional Age / YubiKey identities:

- **Region-Aware Secret Editing**:
  ```bash
  # Interactive editing
  vaultix-edit <region> <secret-file>

  # Pipe directly from stdin
  vaultix-edit <region> <secret-file> < plaintext-secret
  ```
- **Re-encryption**:
  ```bash
  # Re-encrypt secret caches for all hosts within a region
  vaultix-renc <region> [secret-file]
  ```
- **Host Key Rotation**:
  ```bash
  # Automatically generate new host keys, encrypt via vaultix, and re-encrypt caches
  just rotate-ssh <region> <host> [type]
  ```

---

## Everyday Usage

All routine workflows are orchestrated through [just](Justfile):

### Local System Management

```bash
# Build system derivation for a host (defaults to current hostname)
just build [host]

# Switch running system configuration
just switch [host]

# Build and set as boot default without immediately switching
just boot [host]

# Build, set boot default, and reboot
just reboot [host]

# Switch standalone Home Manager profile
just hm [user] [host]

# Format disk with Disko and install system from scratch
just local-install [host] [region]
```

### Remote Deployments & Infrastructure

```bash
# Build system image, upload, and provision to Incus via OpenTofu
just deploy <region> <host> [remote]

# Remote rebuild switch over SSH
just deploy-switch <region> <host> [target-ssh-host] [args...]

# Rotate host SSH keys (ed25519, rsa, or all) and update Vaultix cache
just rotate-ssh <region> <host> [all|ed25519|rsa]

# Destroy remote instance and delete persistent storage volume
just destroy-host <region> <host> [remote]
```

### U2F / YubiKey Authentication

```bash
# Verify U2F mappings syntax, Nix store path, and connected tokens
just test-u2f [host]

# Enroll a new FIDO2 / U2F key for PAM authentication
just enroll-u2f [user]
```

### Code Quality & Formatting

```bash
# Format all codebase files (nixfmt, deadnix, fish_indent, kdlfmt)
just fmt

# Run unit tests via nix-unit
just ci [test]
```

---

## Development Shell

Enter the environment manually or automatically via [direnv](https://direnv.net/):

```bash
# Automatically loads packages via .envrc
direnv allow

# Or open manually
nix-shell
```

The shell provides:

- `nh` (Nix CLI helper for builds and switches)
- `vaultix-edit`, `vaultix-renc`, `vaultix-manifest` (Secret management)
- `rage` and `age-plugin-yubikey` (Age encryption)
- `disko` (Declarative disk partitioning)
- `opentofu` (Infrastructure provisioning)
- `treefmt`, `nixfmt`, `deadnix` (Code formatting & linting)

---

## Acknowledgments & History

My journey into NixOS began at **Linux Day Vorarlberg** (Dornbirn, Austria), where the folks from [BWI Suisse AG](https://bwi-suisse.ch/) first introduced me to the power and beauty of declarative systems. That initial spark eventually evolved into the architecture powering this fleet.

This repository builds upon concepts and tools pioneered in [Vic's vix](https://github.com/vic/vix) and the broader [Dendritic](https://dendritic.oeiuwq.com) ecosystem:

- [Den](https://github.com/denful/den): Declarative multi-system and multi-user framework
- [npins](https://github.com/andir/npins): Dependency pinning without traditional flake locks
- [with-inputs](https://github.com/vic/with-inputs): Lightweight runtime input forwarding
- [flake-file](https://github.com/vic/flake-file): Declarative flake inputs extraction
