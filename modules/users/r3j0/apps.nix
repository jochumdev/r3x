{
  lib,
  ...
}:
{
  users.r3j0.apps = {
    homeManager =
      { pkgs, ... }:
      {
        nixpkgs.config.allowUnfreePredicate =
          pkg:
          builtins.elem (lib.getName pkg) [
            "spotify"
          ];

        home.packages = with pkgs; [
          spotify
          signal-desktop
          chromium
          libreoffice
          gimp
          vlc
          pavucontrol
        ];
      };
  };
}
