{ r3x, ... }:
{
  r3x.services.cosmic-greeter = {
    nixos =
      {
        config,
        host,
        lib,
        pkgs,
        ...
      }:
      let
        desktops = config.services.displayManager.sessionData.desktops;
        pkg = config.services.displayManager.cosmic-greeter.package;
      in
      {
        services.xserver.enable = true;
        services.xserver.xkb = {
          layout = "us";
          variant = "";
        };

        services.displayManager.cosmic-greeter.enable = true;

        # Ensure wayland-sessions are linked into /run/current-system/sw/share/wayland-sessions
        environment.pathsToLink = [ "/share/wayland-sessions" ];

        # Pass session directories to cosmic-greeter via XDG_DATA_DIRS in default_session
        services.greetd.settings.default_session.command = lib.mkForce (
          ''${lib.getExe' pkgs.coreutils "env"} XDG_DATA_DIRS="${desktops}/share:/run/current-system/sw/share" XCURSOR_THEME="''${XCURSOR_THEME:-Pop}" ${lib.getExe' pkg "cosmic-greeter-start"}''
        );

        # Also set XDG_DATA_DIRS in greetd systemd service environment
        systemd.services.greetd.environment.XDG_DATA_DIRS =
          "${desktops}/share:/run/current-system/sw/share";

        security.pam.services = {
          greetd.rules.auth.greeter-permit = {
            order = config.security.pam.services.greetd.rules.auth.login.order - 10;
            control = "[success=done default=ignore]";
            modulePath = "${config.security.pam.package}/lib/security/pam_succeed_if.so";
            args = [
              "user"
              "in"
              "cosmic-greeter:greeter"
            ];
          };

          cosmic-greeter = lib.mkIf (host.hasAspect r3x.yubikey) {
            u2fAuth = true;
            rules.auth = {
              unix.control = lib.mkForce "requisite";
              u2f = {
                order = config.security.pam.services.cosmic-greeter.rules.auth.unix.order + 10;
                control = "sufficient";
              };
            };
          };
        };
      };
  };
}
