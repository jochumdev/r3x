{
  ...
}:
{
  r3x.development.gcc = {
    homeManager =
      { config, pkgs, ... }:
      {
        home.packages = with pkgs; [
          gcc
        ];
      };
  };
}
