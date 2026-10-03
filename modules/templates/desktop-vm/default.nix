{
  lib,
  r3x,
  ...
}:
{
  den.aspects.desktop-vm = {
    includes = [
      r3x.roles.desktop
      r3x.base.incus-vm
      # r3x.disks.impermanence
      r3x.disks.btrfs
      r3x.nix-settings
      r3x.vaultix
      r3x.services.pipewire
      r3x.services.openssh
      r3x.services.cosmic-greeter
      r3x.graphical.niri-cosmic
      r3x.yubikey
      r3x.pbs-client
      r3x.system-tools
    ];

    nixos = {
      users.users.root.hashedPassword = "!";
      users.users.root.initialHashedPassword = lib.mkForce null;
      security.pam.services.login.allowNullPassword = lib.mkForce false;

      boot.initrd.availableKernelModules = [
        "ahci"
        "xhci_pci"
        "virtio_pci"
        "virtio_scsi"
        "sd_mod"
        "sr_mod"
      ];

      fileSystems."/".fsType = lib.mkForce "btrfs";
      fileSystems."/".device = lib.mkForce "/dev/disk/by-partlabel/disk-main-root";

      fileSystems."/boot".device = lib.mkForce "/dev/disk/by-partlabel/ESP";

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
