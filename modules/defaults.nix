{ den, lib, ... }:
{
  den.schema.user.includes = [ den._.mutual-provider ];

  den.default = {
    settings.region = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
    };

    settings.users = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ "r3j0" ];
      description = "List of users for this host, where the first element is the primary user.";
    };

    settings.primaryUser = lib.mkOption {
      type = lib.types.str;
      default = "r3j0";
      description = "The primary user for this host (the first element of settings.users).";
    };

    nixos = {
      system.stateVersion = lib.mkDefault "26.05";
    };
    darwin.system.stateVersion = lib.mkDefault 6;

    includes = [
      den.provides.define-user
      den.provides.hostname
      den.provides.inputs'
      den.provides.self'
    ];
  };
}
