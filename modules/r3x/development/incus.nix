{
  ...
}:
{
  r3x.development.incus = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.incus.client
        ];
      };
  };
}
