{ inputs, lib, ... }:
{
  r3x.disks.btrfs = {
    settings.device = lib.mkOption { type = lib.types.str; };

    nixos =
      {
        config,
        host,
        lib,
        ...
      }:
      {
        imports = [ inputs.disko.nixosModules.default ];
        disko.devices.disk.main = {
          type = "disk";
          device = host.settings.disk.device;
          content.type = "gpt";
          content.partitions.ESP = {
            label = "ESP";
            name = "ESP";
            size = "512M";
            type = "EF00";
            content = {
              type = "filesystem";
              format = "vfat";
              mountpoint = "/boot";
              mountOptions = [
                "defaults"
                "umask=0077"
                "dmask=0077"
                "fmask=0177"
              ];
            };
          };
          content.partitions.root = {
            size = "100%";
            content = {
              type = "btrfs";
              extraArgs = [
                "-L"
                "nixos"
                "-f"
              ];
              postCreateHook = ''
                mount -t btrfs /dev/disk/by-label/nixos /mnt
                btrfs subvolume snapshot -r /mnt/root /mnt/root-blank

                # Pre-create critical directories in /persist for first boot
                # This is essential for nixos-anywhere + impermanence to work
                mkdir -p /mnt/persist/{root,srv,etc/nixos,etc/ssh}
                mkdir -p /mnt/persist/var/{spool,cache,db}
                mkdir -p /mnt/persist/var/lib/{nixos,systemd,dbus,bluetooth,NetworkManager}
                mkdir -p /mnt/persist/var/lib/systemd/{coredump,timers,timesync}
                mkdir -p /mnt/persist/var/db/sudo
                mkdir -p /mnt/persist/etc/NetworkManager/system-connections

                # Set proper permissions
                chmod 700 /mnt/persist/root
                chmod 700 /mnt/persist/var/db/sudo
                chmod 700 /mnt/persist/etc/NetworkManager/system-connections

                umount /mnt
              '';
              subvolumes = {
                "/root" = {
                  mountpoint = "/";
                  mountOptions = [
                    "subvol=@root"
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/home" = {
                  mountpoint = "/home";
                  mountOptions = [
                    "subvol=@home"
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/nix" = {
                  mountpoint = "/nix";
                  mountOptions = [
                    "subvol=@nix"
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/persist" = {
                  mountpoint = "/persist";
                  mountOptions = [
                    "subvol=@persist"
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/log" = {
                  mountpoint = "/var/log";
                  mountOptions = [
                    "subvol=@log"
                    "compress=zstd"
                    "noatime"
                  ];
                };
                "/swap" = {
                  mountpoint = "/swap";
                  mountOptions = [
                    "noatime"
                    "compress=no"
                  ];
                  swap.swapfile.size = lib.mkDefault (host.settings.disk.swapSize or "32G");
                };
              };
            };
          };
        };
        fileSystems = {
          "/persist".neededForBoot = true;
          "/var/log".neededForBoot = true;
          "/home".neededForBoot = true;
        };

        boot.initrd.systemd.services.rollback =
          lib.mkIf (host.settings.impermanence.wipeRootOnBoot or false)
            {
              description = "Rollback BTRFS root subvolume to a pristine state";
              wantedBy = [ "initrd.target" ];
              before = [ "sysroot.mount" ];
              unitConfig.DefaultDependencies = "no";
              serviceConfig = {
                Type = "oneshot";
                UMask = "0077";
              };
              script = ''
                set -euo pipefail

                echo "Starting impermanence rollback..."

                # LUKS_DEVICE=""
                # for device in /dev/mapper/enc /dev/mapper/cryptroot; do
                #   if [[ -b "$device" ]]; then
                #     LUKS_DEVICE="$device"
                #     break
                #   fi
                # done

                # if [[ -z "$LUKS_DEVICE" ]]; then
                #   echo "Error: No LUKS device found (tried enc, cryptroot), skipping rollback"
                #   exit 0
                # fi

                # echo "Found LUKS device: $LUKS_DEVICE"

                mkdir -p /mnt

                if ! mount -o subvol=/@ "$LUKS_DEVICE" /mnt; then
                  echo "Error: Failed to mount root filesystem"
                  exit 1
                fi

                if [[ ! -d "/mnt/root-blank" ]]; then
                  echo "Error: /mnt/root-blank snapshot not found, skipping rollback"
                  umount /mnt || true
                  exit 0
                fi

                echo "Found root-blank snapshot, proceeding with rollback"

                if [[ -d "/mnt/root" ]]; then
                  echo "Removing nested subvolumes..."
                  btrfs subvolume list -o /mnt/root | cut -f9 -d' ' | while read -r subvolume; do
                    if [[ -n "$subvolume" ]]; then
                      echo "Deleting /$subvolume subvolume..."
                      btrfs subvolume delete "/mnt/$subvolume" || echo "Warning: Failed to delete $subvolume"
                    fi
                  done

                  echo "Deleting /root subvolume..."
                  if ! btrfs subvolume delete /mnt/root; then
                    echo "Error: Failed to delete /root subvolume"
                    umount /mnt || true
                    exit 1
                  fi
                fi

                echo "Restoring blank /root subvolume..."
                if ! btrfs subvolume snapshot /mnt/root-blank /mnt/root; then
                  echo "Error: Failed to create snapshot"
                  umount /mnt || true
                  exit 1
                fi

                echo "Rollback completed successfully"
                umount /mnt || echo "Warning: Failed to unmount /mnt"
              '';
            };

        assertions = lib.optionals (host.settings.impermanence.wipeRootOnBoot or false) [
          {
            assertion = config.fileSystems."/persist".fsType or null == "btrfs";
            message = "Impermanence requires /persist to be mounted as btrfs";
          }
          {
            assertion = builtins.any (fs: fs.mountPoint == "/" && fs.fsType == "btrfs") (
              builtins.attrValues config.fileSystems
            );
            message = "Impermanence requires root filesystem to be btrfs";
          }
        ];
      };
  };
}
