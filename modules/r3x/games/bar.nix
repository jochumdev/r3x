{
  ...
}:
{
  r3x.games.bar = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.beyond-all-reason
        ];
      };
  };
}
