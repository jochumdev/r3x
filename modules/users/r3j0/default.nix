{
  den,
  r3x,
  ...
}:
{
  den.aspects."r3j0" = {
    includes = [
      r3x.everywhere
    ];

    homeManager =
      { lib, ... }:
      {
        xdg.configFile."bat/config".source = ./dots/config/bat/config;
        programs.ssh = {
          enable = true;
          enableDefaultConfig = false;
          settings = {
            "*" = {
              PasswordAuthentication = "no";
              KbdInteractiveAuthentication = "no";
              IdentityFile = [
                "~/.ssh/id_ed25519_sk"
                "~/.ssh/id_ed25519_sk_2"
              ];
            };
          };
        };

        programs.git.signing = {
          key = "~/.ssh/id_ed25519_sk.pub";
          signByDefault = true;
        };

        programs.jujutsu.settings = {
          signing.key = lib.mkForce "~/.ssh/id_ed25519_sk.pub";
          templates.commit_trailers = "format_signed_off_by_trailer(self)";
          git.subprocess = true;
        };
      };

    nixos =
      {
        config,
        host,
        lib,
        ...
      }:
      let
        regionDir =
          if config ? settings && config.settings ? region && config.settings.region != null then
            config.settings.region
          else
            "home";
        shadowPath = ../../../regions + "/${regionDir}/users/r3j0/secrets/shadow.age";
      in
      lib.mkMerge [
        {
          users.users."r3j0" = {
            openssh.authorizedKeys.keyFiles = [
              ./authorized_keys
            ];
            extraGroups = [
              "ssh"
              "media"
            ];
          };

          programs.ssh.enableAskPassword = false;
        }

        (lib.optionalAttrs (!host.iso) (
          lib.mkIf (config.vaultix.enable && builtins.pathExists shadowPath) {
            users.users."r3j0".hashedPasswordFile = config.vaultix.secrets.shadow_r3j0.path;

            vaultix = {
              secrets.shadow_r3j0 = {
                file = shadowPath;
              };
              beforeUserborn = [ "shadow_r3j0" ];
            };
          }
        ))
      ];
  };
}
