{
  ...
}:
{
  r3x.development.go = {
    homeManager =
      { config, pkgs, ... }:
      {
        home.packages = with pkgs; [
          # Go toolchain & language server
          go
          gopls

          # Testing & Linting
          gotestsum
          golangci-lint

          # Debugging & Task execution
          delve

          just
          gnumake
        ];

        home.sessionPath = [ "${config.home.homeDirectory}/go/bin" ];

        home.sessionVariables = {
          GOPATH = "${config.home.homeDirectory}/go";
        };
      };
  };
}
