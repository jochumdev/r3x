{ ... }:
{
  r3x.virtualization.virt-client = {
    homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.virt-viewer
        ];
      };
  };
}
