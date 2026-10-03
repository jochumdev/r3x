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
    ];
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.devenv
        ];
      };
  };
}
