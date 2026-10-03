{
  den,
  users,
  r3x,
  ...
}:
{
  den.aspects."r3j0".includes = [
    (den.lib.policy.when ({ host, ... }: host.hasAspect r3x.roles.desktop) users.r3j0.desktop)
  ];

  users.r3j0.desktop = {
    includes = [
      r3x.development
      r3x.browser
      r3x.proton-pass
      r3x.proton-mail
      r3x.games.bar
      r3x.virtualization.virt-client
      r3x.dark-theme
      users.r3j0.alacritty
      users.r3j0.apps
      users.r3j0.zed-editor
      (den.lib.policy.when ({ host, ... }: host.hasAspect r3x.graphical.cosmic) {
        homeManager = {
          xdg.configFile."cosmic" = {
            source = ./dots/config/cosmic;
            recursive = true;
          };
          xdg.configFile."cosmic-initial-setup-done" = {
            source = ./dots/config/cosmic-initial-setup-done;
          };
          home.file.".local/share/wallpapers/win2kOrBetter-Linux.jpg".source =
            ./dots/local/share/wallpapers/win2kOrBetter-Linux.jpg;
          home.file."Pictures/wallpapers/win2kOrBetter-Linux.jpg".source =
            ./dots/local/share/wallpapers/win2kOrBetter-Linux.jpg;
          xdg.desktopEntries."com.system76.CosmicSettings.Accessibility" = {
            name = "Accessibility";
            noDisplay = true;
          };
        };
      })
      (den.lib.policy.when ({ host, ... }: host.hasAspect r3x.graphical.niri) users.r3j0.niri)
    ];

    homeManager =
      { pkgs, ... }:
      {
        systemd.user.services.attic-watch-store = {
          Unit = {
            Description = "Attic Nix Store Watcher (prod)";
            After = [ "network-online.target" ];
          };
          Install = {
            WantedBy = [ "default.target" ];
          };
          Service = {
            ExecStart = "${pkgs.attic-client}/bin/attic watch-store prod";
            Restart = "always";
            RestartSec = "5s";
          };
        };

        home.packages = [
          pkgs.udev-gothic-nf
        ];
        fonts.fontconfig.enable = true;
      };
  };
}
