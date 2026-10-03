{
  lib,
  r3x,
  ...
}:
{
  den.aspects.devcontainer = {
    includes = [
      r3x.roles.devshell
      r3x.base.lxc-container
      r3x.nix-settings
      r3x.vaultix
      r3x.services.openssh
      r3x.system-tools
    ];

    nixos =
      { ... }:
      {
        users.users.root.hashedPassword = "!";
        users.users.root.initialHashedPassword = lib.mkForce null;
        security.pam.services.login.allowNullPassword = lib.mkForce false;

        time.timeZone = "Europe/Vienna";

        i18n.extraLocaleSettings = {
          LC_ADDRESS = "de_AT.UTF-8";
          LC_IDENTIFICATION = "de_AT.UTF-8";
          LC_MEASUREMENT = "de_AT.UTF-8";
          LC_MONETARY = "de_AT.UTF-8";
          LC_NAME = "de_AT.UTF-8";
          LC_NUMERIC = "de_AT.UTF-8";
          LC_PAPER = "de_AT.UTF-8";
          LC_TELEPHONE = "de_AT.UTF-8";
          LC_TIME = "de_AT.UTF-8";
        };
      };
  };
}
