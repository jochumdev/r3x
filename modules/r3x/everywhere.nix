{
  lib,
  r3x,
  ...
}:
{
  r3x.everywhere = {
    includes = [
      r3x.nix-index
      r3x.nix-registry
      r3x.fish
      r3x.cli-tools
    ];

    nixos = {
      home-manager.backupFileExtension = lib.mkDefault "backup";
      home-manager.overwriteBackup = lib.mkDefault true;
    };

    homeManager.home.stateVersion = lib.mkDefault "26.05";
  };
}
