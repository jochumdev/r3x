{ lib, ... }:
{
  r3x.base.incus-vm = {
    nixos =
      {
        config,
        modulesPath,
        ...
      }:
      {
        imports = [ (modulesPath + "/virtualisation/incus-virtual-machine.nix") ];

        fileSystems."/persist" = {
          device = lib.mkDefault "incus_persist";
          fsType = lib.mkDefault "virtiofs";
          neededForBoot = lib.mkDefault true;
        };

        boot.loader.systemd-boot.enable = true;
        boot.loader.efi.canTouchEfiVariables = true;

        networking.networkmanager.enable = true;
        networking.useDHCP = lib.mkDefault true;

        i18n.defaultLocale = "en_US.UTF-8";

        # services.xserver.videoDrivers = [ "qxl" ];

        hardware.bluetooth.enable = true;
        hardware.bluetooth.powerOnBoot = true;
        services.blueman.enable = true;

        services.userborn.enable = true;

        services.spice-vdagentd.enable = lib.mkIf (
          config.services.displayManager.enable || config.services.xserver.enable
        ) true;

        security.rtkit.enable = true;
      };
  };
}
