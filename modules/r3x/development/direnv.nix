{
  ...
}:
let
  use_nix_installables = ''
    use_nix_installables() {
      direnv_load nix shell "''${@}" -c $direnv dump
    }
  '';
in
{
  r3x.development.direnv = {
    homeManager = {
      programs.direnv = {
        enable = true;
        nix-direnv.enable = true;
      };
      home.file.".config/direnv/lib/use_nix_installables.sh".text = use_nix_installables;
    };
  };
}
