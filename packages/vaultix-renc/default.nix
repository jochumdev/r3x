{ pkgs, ... }@args: pkgs.callPackage ../vaultix/renc.nix (builtins.removeAttrs args [ "pkgs" ])
