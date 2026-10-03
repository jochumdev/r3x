{ ... }:
{
  r3x.services.incus = {
    nixos =
      { pkgs, ... }:
      {
        boot.kernelModules = [ "openvswitch" ];

        virtualisation.incus = {
          enable = true;
          package = pkgs.incus;
          preseed = {
            config = {
              "core.https_address" = ":8443";
            };

            networks = [
              {
                name = "incusbr0";
                type = "bridge";
                config = {
                  "ipv4.address" = "10.90.190.1/24";
                  "ipv4.nat" = "true";
                  "ipv6.address" = "auto";
                  "ipv6.nat" = "true";
                };
              }
            ];
            profiles = [
              {
                name = "default";
                devices = {
                  eth0 = {
                    name = "eth0";
                    network = "incusbr0";
                    type = "nic";
                  };
                  root = {
                    path = "/";
                    pool = "default";
                    type = "disk";
                  };
                };
              }
            ];
            storage_pools = [
              {
                name = "default";
                driver = "btrfs";
                config = {
                  source = "/var/lib/incus/storage-pools/default";
                };
              }
            ];
          };
        };

        networking.nftables.enable = true;

        # Incus maintains `table inet incus` and dynamically populates `set bridges`.
        # Because `nixos-fw` drops unmatched packets by default, we attach prerouting
        # and forward hooks to `table inet incus` to mark traffic from/to `@bridges`.
        # This allows `nixos-fw` to trust any arbitrary bridge managed by Incus dynamically.
        networking.nftables.tables."incus" = {
          family = "inet";
          content = ''
            set bridges {
              type ifname
            }
            chain incus_bridge_mark_prerouting {
              type filter hook prerouting priority -150;
              iifname @bridges meta mark set 0x494e43
            }
            chain incus_bridge_mark_forward {
              type filter hook forward priority -150;
              oifname @bridges meta mark set 0x494e43
            }
          '';
        };

        networking.firewall = {
          extraInputRules = ''
            meta mark 0x494e43 accept comment "trust all incus managed bridges via @bridges"
          '';
          extraForwardRules = ''
            meta mark 0x494e43 accept comment "allow traffic for all incus managed bridges via @bridges"
          '';
        };
      };
  };
}
