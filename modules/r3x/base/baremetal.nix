{ lib, ... }:
{
  r3x.base.baremetal = {
    nixos =
      { ... }:
      {
        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.networkmanager.enable = true;
        networking.useDHCP = lib.mkDefault true;

        i18n.defaultLocale = "en_US.UTF-8";

        hardware.bluetooth.enable = true;
        hardware.bluetooth.powerOnBoot = true;
        services.blueman.enable = true;

        services.userborn.enable = true;

        security.rtkit.enable = true;
      };
  };
}
