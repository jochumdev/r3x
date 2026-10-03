{ ... }:
{
  r3x.base.lxc-container = {
    nixos =
      {
        modulesPath,
        ...
      }:
      {
        imports = [ (modulesPath + "/virtualisation/lxc-container.nix") ];

        i18n.defaultLocale = "en_US.UTF-8";

        services.userborn.enable = true;

      };
  };
}
