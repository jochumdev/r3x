{ ... }:
{
  r3x.services.openssh = {
    nixos =
      {
        host,
        lib,
        ...
      }:
      lib.mkMerge [
        {
          users.groups.ssh = { };

          services.openssh = {
            enable = true;
            openFirewall = true;
            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
              PermitRootLogin = "no";
              AllowGroups = [ "ssh" ];
              MaxAuthTries = 10;
              PerSourcePenalties = "crash:3600s authfail:3600s max:86400s";
            };
          };
        }

        (lib.optionalAttrs (!host.iso) ({
          services.openssh = {
            generateHostKeys = false;
            hostKeys = [
              {
                bits = 4096;
                path = "/persist/etc/ssh/ssh_host_rsa_key";
                type = "rsa";
              }
              {
                path = "/persist/etc/ssh/ssh_host_ed25519_key";
                type = "ed25519";
              }
            ];
          };
        }))
      ];
  };
}
