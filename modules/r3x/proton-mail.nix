{ ... }:
{
  r3x.proton-mail = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [ pkgs.protonmail-desktop ];
        xdg.mimeApps.defaultApplications = {
          "x-scheme-handler/proton-inbox" = "proton-mail.desktop";
        };
      };
  };
}
