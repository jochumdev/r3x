{
  lib,
  r3x,
  ...
}:
{
  den.aspects.live = {
    includes = [
      r3x.roles.desktop
      r3x.nix-settings
      r3x.all-firmware
      r3x.graphical.xfce-no-lock
    ];

    nixos =
      {
        pkgs,
        modulesPath,
        config,
        ...
      }:
      {
        imports = [
          "${toString modulesPath}/installer/cd-dvd/installation-cd-base.nix"
        ];

        hardware.enableAllFirmware = true;
        hardware.enableRedistributableFirmware = true;
        nixpkgs.config.allowUnfree = true;

        system.stateVersion = "26.05";

        users.users.nixos.uid = 1001;

        isoImage.edition = lib.mkDefault config.networking.hostName;
        networking.networkmanager.enable = true;
        networking.wireless.enable = lib.mkImageMediaOverride false;

        services.pulseaudio.enable = false;

        security.sudo.wheelNeedsPassword = false;
        services.displayManager.autoLogin = {
          enable = true;
          user = "nixos";
        };

        boot.supportedFilesystems = [ "zfs" ];
        boot.zfs.forceImportRoot = false;

        services.openssh = {
          enable = true;
          openFirewall = true;
          settings = {
            PasswordAuthentication = false;
            KbdInteractiveAuthentication = false;
            PermitRootLogin = lib.mkForce "yes";
            MaxAuthTries = 10;
          };
        };

        users.users.root.openssh.authorizedKeys.keyFiles = builtins.filter builtins.pathExists (
          map (u: ../../users + "/${u}/authorized_keys") (builtins.attrNames (builtins.readDir ../../users))
        );

        users.users.nixos.openssh.authorizedKeys.keyFiles = builtins.filter builtins.pathExists (
          map (u: ../../users + "/${u}/authorized_keys") (builtins.attrNames (builtins.readDir ../../users))
        );

        environment.systemPackages = with pkgs; [
          parted
          git
          vim
          btop
          curl
          wget
          zfs
          smartmontools
          nvme-cli
          pciutils
          lshw
          tmux
          zellij
          ethtool
          usbutils
          nixos-facter
        ];
      };
  };
}
