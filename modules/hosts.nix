{ den, lib, ... }:
let
  r3j0User = {
    fullName = "René Jochum";
    description = "René Jochum";
    email = "rene@jochum.dev";
    editor = "hx";
    diffEditor = "hx";
  };

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
      settingsDir = dir + "/settings";

      # Supports regions/${region}/settings.json or settings.nix
      regionSettings =
        if builtins.pathExists (regionDir + "/settings.json") then
          builtins.fromJSON (builtins.readFile (regionDir + "/settings.json"))
        else if builtins.pathExists (regionDir + "/settings.nix") then
          import (regionDir + "/settings.nix")
        else
          { };

      # Supports settings.json, settings.nix, settings/settings.json, or settings/default.nix
      hostSettings =
        if builtins.pathExists (dir + "/settings.json") then
          builtins.fromJSON (builtins.readFile (dir + "/settings.json"))
        else if builtins.pathExists (dir + "/settings.nix") then
          import (dir + "/settings.nix")
        else if builtins.pathExists (settingsDir + "/settings.json") then
          builtins.fromJSON (builtins.readFile (settingsDir + "/settings.json"))
        else if builtins.pathExists (settingsDir + "/default.nix") then
          import (settingsDir + "/default.nix")
        else
          { };

      # Merges host settings on top of regional settings
      settings = lib.recursiveUpdate regionSettings hostSettings;

      flatSettings = if settings ? settings then (settings // settings.settings) else settings;

      rawUsers =
        if flatSettings ? users then
          flatSettings.users
        else if flatSettings ? user then
          flatSettings.user
        else
          [ "r3j0" ];

      userValidation =
        assert lib.assertMsg (builtins.isList rawUsers)
          "Host '${targetName}': settings.users must be a list of strings (no coercion allowed)";
        assert lib.assertMsg (rawUsers != [ ]) "Host '${targetName}': settings.users must not be empty";
        assert lib.assertMsg (lib.all (u: builtins.isString u || (builtins.isAttrs u && u ? name)) rawUsers)
          "Host '${targetName}': elements of settings.users must be strings or attribute sets with a 'name'";
        true;

      userNames = builtins.seq userValidation (
        map (u: if builtins.isAttrs u then u.name else u) rawUsers
      );
      primaryUserName = builtins.head userNames;

      getUserAttrs =
        userName:
        let
          userDir = ../modules/users + "/${userName}";
          userNix = userDir + "/user.nix";
          userJson = userDir + "/user.json";
        in
        if userName == "r3j0" then
          r3j0User
        else if builtins.pathExists userJson then
          builtins.fromJSON (builtins.readFile userJson)
        else if builtins.pathExists userNix then
          import userNix
        else
          {
            fullName = userName;
            description = userName;
          };

      mkUser =
        userItem:
        let
          userName = if builtins.isAttrs userItem then userItem.name else userItem;
          extraUserAttrs = if builtins.isAttrs userItem then userItem else { };
          baseAttrs = getUserAttrs userName;
          isPrimary = (userName == primaryUserName);
        in
        baseAttrs
        // extraUserAttrs
        // {
          includes =
            (baseAttrs.includes or [ ])
            ++ (extraUserAttrs.includes or [ ])
            ++ lib.optional isPrimary den.provides.primary-user;
        };

      hostUsers = builtins.listToAttrs (
        map (u: {
          name = if builtins.isAttrs u then u.name else u;
          value = mkUser u;
        }) rawUsers
      );

      templateName =
        settings.template or (
          let
            templateFile = settingsDir + "/template";
          in
          if builtins.pathExists templateFile then
            lib.removeSuffix "\n" (builtins.readFile templateFile)
          else
            "devcontainer"
        );

      aspect =
        den.aspects.${templateName}
          or (throw "Host '${targetName}' specified unknown template '${templateName}'");

      diskDevice =
        settings.disk or (
          let
            diskFile = settingsDir + "/disk";
          in
          if builtins.pathExists diskFile then lib.removeSuffix "\n" (builtins.readFile diskFile) else null
        );

      regionName = settings.region or region;

      domainName = settings.domain or "${regionName}.jochum.dev";

      regionModules = lib.optional (builtins.pathExists (regionDir + "/default.nix")) (
        let
          mod = import (regionDir + "/default.nix");
        in
        if builtins.isAttrs mod && (mod ? os || mod ? nixos) then mod else { os = mod; }
      );

      extraModules = lib.optional (builtins.pathExists (settingsDir + "/default.nix")) (
        let
          mod = import (settingsDir + "/default.nix");
        in
        if builtins.isAttrs mod && (mod ? os || mod ? nixos) then mod else { os = mod; }
      );

      settingsAspect = {
        nixos = {
          config = {
            networking.hostName = lib.mkForce name;
            networking.domain = lib.mkDefault domainName;
          };

          options.settings = {
            region = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = regionName;
            };
            disk = lib.mkOption {
              type = lib.types.nullOr lib.types.str;
              default = diskDevice;
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
              default = domainName;
            };
            users = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = userNames;
              description = "List of users for this host, where the first element is the primary user.";
            };
            user = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = userNames;
              description = "Alias for settings.users.";
            };
            primaryUser = lib.mkOption {
              type = lib.types.str;
              default = primaryUserName;
              description = "The primary user for this host (the first element of settings.users).";
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
    }
    // lib.optionalAttrs (diskDevice != null) {
      settings.disk.device = diskDevice;
    }
    // lib.optionalAttrs (regionName != null) {
      settings.region = regionName;
    }
    // {
      settings.users = userNames;
      settings.user = userNames;
      settings.primaryUser = primaryUserName;
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
