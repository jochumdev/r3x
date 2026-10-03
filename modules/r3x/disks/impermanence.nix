{
  lib,
  inputs,
  ...
}:
{
  r3x.disks.impermanence = {
    den.quirks.persist.description = "System paths kept on /persist";
    den.quirks.cache.description = "System paths kept on /cache";
    den.quirks.persistHome.description = "Home paths kept on /persist";
    den.quirks.cacheHome.description = "Home paths kept on /cache";

    settings.wipeRootOnBoot = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Roll the root filesystem back to its empty snapshot on boot";
    };

    nixos = { persist, lib, ... }: {
      imports = [ inputs.impermanence.nixosModules.impermanence ];

      system.impermanence.enable = true;

      boot.initrd.systemd.enable = true;

      security.sudo.extraConfig = ''
        # rollback results in sudo lectures after each reboot
        Defaults lecture = never
      '';

      programs.fuse.userAllowOther = true;

      environment.persistence."/persist" = {
        hideMounts = true;
        directories = lib.unique (lib.concatMap (e: e.directories or [ ]) persist);
        files = lib.unique (lib.concatMap (e: e.files or [ ]) persist) + [
          "/etc/machine-id"
          "/etc/adjtime"
          "/var/lib/systemd/credential.secret"
        ];
      };
    };

    homeManager = { persistHome, lib, ... }: {
      home.persistence."/persist" = {
        directories = lib.unique (lib.concatMap (e: e.directories or [ ]) persistHome);
        files = lib.unique (lib.concatMap (e: e.files or [ ]) persistHome);
      };
    };
  };
}
