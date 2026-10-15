{ den, lib, ... }:
let
  regionsDir = ../regions;
  regionEntries =
    if builtins.pathExists regionsDir then
      lib.filterAttrs (_: type: type == "directory") (builtins.readDir regionsDir)
    else
      { };

  # Discovers all { region, name } pairs from regions/<region>/hosts/<name>
  allHosts = lib.flatten (
    lib.mapAttrsToList (
      region: _:
      let
        regionDir = regionsDir + "/${region}";
        hostsDir = regionDir + "/hosts";
        hostEntries =
          if builtins.pathExists hostsDir then
            lib.filterAttrs (name: type: type == "directory" && !lib.hasPrefix "." name) (
              builtins.readDir hostsDir
            )
          else
            { };
      in
      map (name: { inherit region name; }) (builtins.attrNames hostEntries)
    ) regionEntries
  );

  mkHost =
    { region, name }:
    let
      targetName = "${region}-${name}";
      regionDir = regionsDir + "/${region}";
      dir = regionDir + "/hosts/${name}";

      regionSettings =
        if builtins.pathExists (regionDir + "/settings.json") then
          builtins.fromJSON (builtins.readFile (regionDir + "/settings.json"))
        else
          { };

      hostSettings =
        if builtins.pathExists (dir + "/settings.json") then
          builtins.fromJSON (builtins.readFile (dir + "/settings.json"))
        else
          { };

      # Merges host settings on top of regional settings
      settings = lib.recursiveUpdate regionSettings hostSettings;

      usersAttr =
        if settings ? users then
          settings.users
        else
          {
            nixos = {
              groups = [ ];
            };
          };

      userValidation =
        assert lib.assertMsg (builtins.isAttrs usersAttr)
          "Host '${targetName}': settings.users must be an attribute set or list of users";
        assert lib.assertMsg (usersAttr != { }) "Host '${targetName}': settings.users must not be empty";
        assert lib.assertMsg (lib.all (u: builtins.isAttrs usersAttr.${u}) (
          builtins.attrNames usersAttr
        )) "Host '${targetName}': user definitions in settings.users must be attribute sets";
        true;

      userNames = builtins.seq userValidation (builtins.attrNames usersAttr);

      getUserAttrs =
        userName:
        let
          userJson = regionDir + "/users" + "/${userName}" + "/settings.json";
        in
        builtins.fromJSON (builtins.readFile userJson);

      mkUser =
        userName: userConfig:
        let
          baseAttrs = getUserAttrs userName;
          extraUserAttrs = removeAttrs userConfig [ "groups" ];
        in
        baseAttrs
        // extraUserAttrs
        // {
          inherit (userConfig) groups;
          includes = (baseAttrs.includes or [ ]) ++ (extraUserAttrs.includes or [ ]);
        };

      hostUsers = lib.mapAttrs (
        userName: userConfig:
        mkUser userName (if builtins.isAttrs userConfig then userConfig else { groups = [ ]; })
      ) usersAttr;

      templateName = settings.template or "devcontainer";

      aspect =
        den.aspects.${templateName}
          or (throw "Host '${targetName}' specified unknown template '${templateName}'");

      regionModules = lib.optional (builtins.pathExists (regionDir + "/default.nix")) (
        import (regionDir + "/default.nix")
      );

      extraModules = lib.optional (builtins.pathExists (dir + "/default.nix")) (
        import (dir + "/default.nix")
      );

      settingsAspect = {
        nixos = {
          config = {
            networking.hostName = lib.mkForce name;
            networking.domain = lib.mkDefault settings.domain;
            users.users = lib.mapAttrs (
              _userName: userConfig:
              lib.optionalAttrs (userConfig ? groups) {
                extraGroups = userConfig.groups;
              }
            ) usersAttr;
          };

          options.settings = {
            region = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = settings.region;
            };
            disk = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = settings.disk;
            };
            template = lib.mkOption {
              type = lib.types.str;
              default = templateName;
            };
            hostName = lib.mkOption {
              type = lib.types.str;
              default = name;
            };
            domain = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = settings.domain;
            };
            users = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = userNames;
              description = "List of users for this host.";
            };
          };
        };
      };
    in
    {
      users = hostUsers;
      includes = [
        aspect
        settingsAspect
      ]
      ++ regionModules
      ++ extraModules;
    };

  hostsAttr = builtins.listToAttrs (
    map (h: {
      name = "${h.region}-${h.name}";
      value = mkHost h;
    }) allHosts
  );

  hostsByName = lib.groupBy (h: h.name) allHosts;
  uniqueBareHosts = builtins.listToAttrs (
    lib.concatMap (
      name:
      let
        matching = hostsByName.${name};
      in
      if builtins.length matching == 1 then
        [
          {
            inherit name;
            value = mkHost (builtins.head matching);
          }
        ]
      else
        [ ]
    ) (builtins.attrNames hostsByName)
  );
in
{
  den.hosts.x86_64-linux =
    uniqueBareHosts
    // hostsAttr
    // {
      live = {
        iso = true;
      };
    };
}
