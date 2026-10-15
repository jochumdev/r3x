{
  r3x,
  ...
}:
{
  r3x.development = {
    includes = [
      r3x.development.git
      r3x.development.jujutsu
      r3x.development.direnv
      r3x.development.nix-ld
      r3x.development.go
      r3x.development.incus
    ];

    nixos = {
      virtualisation.containers.enable = true;
    };

    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.devenv
        ];
      };
  };
}
