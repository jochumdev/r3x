{
  os =
    { lib, ... }:
    {
      nix = {
        optimise.automatic = true;
        settings = {
          substituters = lib.mkForce [
            "https://ncps.home.jochum.dev"
            "https://attic.xuyh0120.win/lantian"
            "https://cache.nixos.org"
          ];
          trusted-public-keys = [
            "ncps.home.jochum.dev:a76FHtNLe746pic7VS2K2d3BBR/QJUyqRUrNTO4BwgE="
            "lantian:EeAUQ+W+6r7EtwnmYjeVwx5kOGEBpjlBfPlzGlTNvHc="
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
          ];
          connect-timeout = 60;
          stalled-download-timeout = 900;
          download-attempts = 5;
          narinfo-cache-negative-ttl = 10;
        };
      };
    };
}
