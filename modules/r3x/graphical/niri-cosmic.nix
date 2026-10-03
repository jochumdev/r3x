{ r3x, ... }:
{
  r3x.graphical.niri-cosmic = {
    includes = [
      r3x.graphical.cosmic
      r3x.graphical.niri
    ];

    nixos =
      { pkgs, ... }:
      let
        cosmic-ext-extra-sessions = pkgs.callPackage ../../../packages/cosmic-ext-extra-sessions {
          sessions = [ "niri" ];
        };
      in
      {
        services.displayManager.sessionPackages = [
          cosmic-ext-extra-sessions
        ];

        environment.systemPackages = with pkgs; [
          cosmic-ext-extra-sessions
        ];
      };
  };
}
