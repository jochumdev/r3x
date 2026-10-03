{ lib, ... }:
{
  r3x.base.qemu-guest = {
    nixos =
      { modulesPath, pkgs, ... }:
      {
        imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        # Use latest kernel.
        boot.kernelPackages = pkgs.linuxPackages_latest;

        networking.networkmanager.enable = true;
        networking.useDHCP = lib.mkDefault true;

        i18n.defaultLocale = "en_US.UTF-8";

        services.xserver.videoDrivers = [ "qxl" ];

        hardware.bluetooth.enable = true;
        hardware.bluetooth.powerOnBoot = true;
        services.blueman.enable = true;

        services.userborn.enable = true;

        security.rtkit.enable = true;
      };
  };
}
