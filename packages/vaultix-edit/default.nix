{ pkgs, ... }@args: pkgs.callPackage ../vaultix/edit.nix (builtins.removeAttrs args [ "pkgs" ])
