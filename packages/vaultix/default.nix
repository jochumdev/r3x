{
  lib,
  pkgs,
  symlinkJoin,
  nixosConfigurations ? { },
  vaultixPkg,
}:
let
  vaultixBin = lib.getExe vaultixPkg;
  manifest = pkgs.callPackage ./manifest.nix {
    inherit vaultixBin nixosConfigurations;
  };
  edit = pkgs.callPackage ./edit.nix {
    inherit vaultixBin;
    vaultixManifest = manifest;
  };
  renc = pkgs.callPackage ./renc.nix {
    inherit vaultixBin;
    vaultixManifest = manifest;
  };
in
symlinkJoin {
  name = "vaultix-tools";
  paths = [
    edit
    renc
  ];
  passthru = {
    inherit manifest edit renc;
  };
}
