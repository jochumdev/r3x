{
  self,
  inputs,
  lib,
  ...
}:
let
  regionsDir = ../../regions;
  allRegions =
    if builtins.pathExists regionsDir then
      builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir regionsDir))
    else
      [ ];

  allIdentityEntries = lib.flatten (
    map (
      region:
      let
        idDir = regionsDir + "/${region}/identities";
      in
      if builtins.pathExists idDir then
        map (f: {
          path = idDir + "/${f}";
          relPath = "./regions/${region}/identities/${f}";
        }) (builtins.filter (f: lib.hasSuffix ".txt" f) (builtins.attrNames (builtins.readDir idDir)))
      else
        [ ]
    ) allRegions
  );

  extractRecipient =
    file:
    let
      content = builtins.readFile file;
      lines = lib.splitString "\n" content;
      recipientLine = lib.findFirst (l: lib.hasInfix "Recipient:" l) null lines;
    in
    if recipientLine != null then
      lib.trim (lib.removePrefix "#" (lib.elemAt (lib.splitString "Recipient:" recipientLine) 1))
    else
      null;

  primaryEntry = if allIdentityEntries != [ ] then builtins.head allIdentityEntries else null;
  otherEntries = if allIdentityEntries != [ ] then builtins.tail allIdentityEntries else [ ];

  extraRecipients = builtins.filter (r: r != null) (map (e: extractRecipient e.path) otherEntries);
in
{
  imports = [
    inputs.vaultix.flakeModules.default
  ];

  flake.vaultix = {
    # Path to your age identity / private key file
    identity = if primaryEntry != null then primaryEntry.relPath else null;
    inherit extraRecipients;

    nodes = lib.filterAttrs (
      _name: node:
      !(node.config._module.args.host.iso or false)
      && !(node.config ? isoImage)
      && (node.config ? vaultix)
    ) self.nixosConfigurations;
  };

  flake-file.inputs = {
    crane.url = "github:ipetkov/crane";
    pre-commit-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs = {
        flake-compat.follows = "";
        nixpkgs.follows = "nixpkgs";
      };
    };
    vaultix.url = "github:milieuim/vaultix";
  };
}
