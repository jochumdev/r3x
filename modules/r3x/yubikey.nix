{ ... }:
{
  r3x.yubikey = {
    os =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        services.udev.packages = [
          pkgs.yubikey-personalization
          pkgs.libfido2
        ];

        services.pcscd.enable = true;

        environment.etc =
          let
            activeUsers =
              if config ? settings && config.settings ? users && builtins.isList config.settings.users then
                config.settings.users
              else if config ? settings && config.settings ? user && builtins.isList config.settings.user then
                config.settings.user
              else
                builtins.attrNames (builtins.readDir ../users);
            userFiles = builtins.filter builtins.pathExists (
              map (u: ../users + "/${u}/u2f_mappings") activeUsers
            );
            u2fSource =
              if userFiles == [ ] then
                null
              else if builtins.length userFiles == 1 then
                builtins.path {
                  path = builtins.head userFiles;
                  name = "u2f_mappings";
                }
              else
                pkgs.concatText "u2f_mappings" userFiles;
          in
          lib.mkIf (u2fSource != null) {
            "u2f_mappings".source = u2fSource;
          };

        assertions = [
          {
            assertion =
              config.environment.etc ? u2f_mappings
              -> lib.isStorePath (toString config.environment.etc.u2f_mappings.source);
            message = "/etc/u2f_mappings source must be a Nix store path, but got: ${
              toString (config.environment.etc.u2f_mappings.source or "")
            }";
          }
        ];

        security.pam.u2f = {
          enable = true;
          control = "sufficient";
          settings = {
            cue = true;
            authfile = "/etc/u2f_mappings";
            origin = "pam://host";
            appid = "pam://host";
          };
        };

        security.pam.services = {
          login = {
            u2fAuth = true;
            rules.auth = {
              unix.control = lib.mkForce "requisite";
              u2f = {
                order = config.security.pam.services.login.rules.auth.unix.order + 10;
                control = "sufficient";
              };
            };
          };

          sudo = {
            u2fAuth = true;
            rules.auth = {
              check_not_ssh = {
                order = config.security.pam.services.sudo.rules.auth.unix.order - 10;
                control = "[success=1 default=ignore]";
                modulePath = "${config.security.pam.package}/lib/security/pam_exec.so";
                args = [
                  "quiet"
                  "${pkgs.writeShellScript "check-not-ssh" ''
                    PID=$$
                    while [ "$PID" -gt 1 ] 2>/dev/null; do
                      if grep -qz "^SSH_CONNECTION=" /proc/$PID/environ 2>/dev/null; then
                        exit 1
                      fi
                      COMM=$(cat /proc/$PID/comm 2>/dev/null)
                      if [ "$COMM" = "sshd" ]; then
                        exit 1
                      fi
                      PID=$(awk '{print $4}' /proc/$PID/stat 2>/dev/null)
                    done
                    if [ -n "$SSH_CONNECTION" ] || [ -n "$SSH_CLIENT" ] || [ -n "$SSH_TTY" ]; then
                      exit 1
                    fi
                    exit 0
                  ''}"
                ];
              };
              unix.control = lib.mkForce "[success=done default=die]";
              u2f = {
                order = config.security.pam.services.sudo.rules.auth.unix.order + 10;
                control = "sufficient";
              };
            };
          };

          swaylock = {
            u2fAuth = true;
            rules.auth = {
              unix.control = lib.mkForce "requisite";
              u2f = {
                order = config.security.pam.services.swaylock.rules.auth.unix.order + 10;
                control = "sufficient";
              };
            };
          };

          polkit-1 = {
            u2fAuth = true;
            rules.auth = {
              unix.control = lib.mkForce "requisite";
              u2f = {
                order = config.security.pam.services.polkit-1.rules.auth.unix.order + 10;
                control = "sufficient";
              };
            };
          };
        };

        security.sudo.extraConfig = ''
          Defaults env_keep += "SSH_CONNECTION SSH_CLIENT SSH_TTY"
        '';

        environment.systemPackages = with pkgs; [
          pam_u2f
          yubikey-manager
          libfido2
        ];

        services.udev.extraRules = ''
          ACTION=="remove", ENV{ID_BUS}=="usb", ENV{ID_VENDOR_ID}=="1050", RUN+="${pkgs.systemd}/bin/loginctl lock-sessions"
        '';
      };
  };
}
