{
  flake-file = {
    description = "R3J0's Nix Environment";

    nixConfig = {
      extra-substituters = [
        "https://ncps.home.jochum.dev"
        "https://cache.nixos.org"
      ];
      extra-trusted-public-keys = [
        "ncps.home.jochum.dev:a76FHtNLe746pic7VS2K2d3BBR/QJUyqRUrNTO4BwgE="
        "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      ];
    };
  };
}
