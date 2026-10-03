{
  ...
}:
{
  users.r3j0.niri = {
    homeManager =
      { pkgs, ... }:
      {
        xdg.configFile."niri/config.kdl".source = ./dots/config/niri/config.kdl;
        xdg.configFile."rofi/config.rasi".source = ./dots/config/rofi/config.rasi;

        home.packages = with pkgs; [
          (pkgs.callPackage ../../../packages/terminal { })
          kitty
          anyrun
          rofi
          sway-contrib.grimshot
          grim
          slurp
          swappy
          libnotify
          dunst
        ];
      };
  };
}
