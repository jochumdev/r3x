{ lib, ... }:
{
  r3x.graphical.cosmic = {
    nixos =
      { pkgs, ... }:
      {
        services.dbus = {
          enable = true;
          packages = with pkgs; [ bluez ];
        };

        boot.plymouth = {
          enable = true;
          font = "${pkgs.jetbrains-mono}/share/fonts/truetype/JetBrainsMono-Regular.ttf";
          # Installs all catppuccin themes
          # Options:  catppuccin-{mocha, macchiato, frappe, latte}
          themePackages = [ (pkgs.catppuccin-plymouth.override { variant = "mocha"; }) ];
          theme = lib.mkForce "catppuccin-mocha";
        };

        # https://wiki.nixos.org/wiki/COSMIC
        environment.sessionVariables.COSMIC_DATA_CONTROL_ENABLED = 1;

        services.desktopManager.cosmic.enable = true;
        environment.cosmic.excludePackages = with pkgs; [
          cosmic-edit
          networkmanagerapplet
        ];

        # Mask blueman-applet autostart service so it does not start alongside COSMIC's applet
        systemd.user.services."app-blueman@autostart".enable = false;

        security.polkit.enable = true;
        # security.gnome-keyring.enable = true;
      };

    homeManager =
      { ... }:
      {
        # Also mark blueman.desktop as hidden in user autostart for XDG compliance
        xdg.configFile."autostart/blueman.desktop".text = ''
          [Desktop Entry]
          Type=Application
          Name=Blueman Applet
          Exec=blueman-applet
          Hidden=true
        '';
      };
  };
}
