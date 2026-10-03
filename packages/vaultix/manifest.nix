{
  lib,
  pkgs,
  nixosConfigurations ? { },
  vaultixBin,
  regionsDir ? ../../regions,
}:
let
  configs = lib.filterAttrs (
    _: c: (c.config ? vaultix) && !(c.config._module.args.host.iso or false) && !(c.config ? isoImage)
  ) nixosConfigurations;

  mkProfile =
    c:
    pkgs.writeTextFile {
      name = "vaultix-material-${c.config.networking.hostName}";
      text = builtins.toJSON {
        inherit (c.config.vaultix)
          beforeUserborn
          placeholder
          secrets
          settings
          templates
          ;
      };
    };

  hostsByRegion = lib.groupBy (c: c.config.settings.region or "home") (builtins.attrValues configs);

  regionsOnDisk =
    if builtins.pathExists regionsDir then
      builtins.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir regionsDir))
    else
      [ ];

  allRegionNames = lib.unique ((builtins.attrNames hostsByRegion) ++ regionsOnDisk);
in
pkgs.writeTextFile {
  name = "vaultix-manifest.json";
  text = builtins.toJSON {
    inherit vaultixBin;
    regions = lib.genAttrs allRegionNames (
      region:
      let
        hostConfigs = hostsByRegion.${region} or [ ];
      in
      {
        identitiesDir = "regions/${region}/identities";
        hosts = map (c: {
          hostName = c.config.networking.hostName;
          profile = "${mkProfile c}";
          secretFiles = lib.mapAttrsToList (
            _: s:
            let
              base = baseNameOf (toString s.file);
            in
            if builtins.stringLength base > 33 && builtins.substring 32 1 base == "-" then
              builtins.substring 33 (-1) base
            else
              base
          ) (c.config.vaultix.secrets or { });
        }) hostConfigs;
      }
    );
  };
}
