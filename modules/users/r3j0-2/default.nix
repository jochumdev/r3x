{
  den,
  r3x,
  users,
  ...
}:
{
  den.aspects."r3j0-2" = {
    includes = [
      r3x.everywhere
      users.r3j0.helix
      (r3x.hasRole r3x.roles.devshell users.r3j0.devshell)
      (r3x.hasRole r3x.roles.desktop users.r3j0.desktop)
      (den.lib.policy.when ({ host, ... }: host.hasAspect r3x.services.incus) {
        nixos.users.users."r3j0-2".extraGroups = [ "incus-admin" ];
      })
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
              IdentitiesOnly = "yes";
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
        shadowPath = ../../../regions + "/${regionDir}/users/r3j0-2/secrets/shadow.age";
      in
      lib.mkMerge [
        {
          users.users."r3j0-2" = {
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
            users.users."r3j0-2".hashedPasswordFile = config.vaultix.secrets.shadow_r3j0_2.path;

            vaultix = {
              secrets.shadow_r3j0_2 = {
                file = shadowPath;
              };
              beforeUserborn = [ "shadow_r3j0_2" ];
            };
          }
        ))
      ];
  };
}
