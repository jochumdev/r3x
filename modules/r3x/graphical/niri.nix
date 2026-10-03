{ ... }:
{
  r3x.graphical.niri = {
    nixos =
      { pkgs, ... }:
      {
        services.dbus = {
          enable = true;
          packages = with pkgs; [ bluez ];
        };

        programs.niri.enable = true;
        systemd.user.services.niri.enableDefaultPath = false;
        # services.displayManager.defaultSession = lib.mkForce "niri";
        environment.systemPackages = with pkgs; [
          # Base Niri utilities
          xwayland-satellite
          wl-clipboard
          cliphist

          # Default config dependencies
          alacritty
          brightnessctl
          playerctl
        ];

        systemd.user.services.cliphist = {
          description = "Store clipboard text to cliphist";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --watch ${pkgs.cliphist}/bin/cliphist store";
            Restart = "on-failure";
            Slice = "session.slice";
          };
        };

        systemd.user.services.cliphist-images = {
          description = "Store clipboard image to cliphist";
          wantedBy = [ "graphical-session.target" ];
          partOf = [ "graphical-session.target" ];
          after = [ "graphical-session.target" ];
          serviceConfig = {
            ExecStart = "${pkgs.wl-clipboard}/bin/wl-paste --type image --watch ${pkgs.cliphist}/bin/cliphist store";
            Restart = "on-failure";
            Slice = "session.slice";
          };
        };

        security.polkit.enable = true;
        # security.gnome-keyring.enable = true;
      };
  };
}
