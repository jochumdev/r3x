{
  inputs,
  lib,
  r3x,
  ...
}:
{
  flake-file.inputs.nixos-facter-modules.url = "github:numtide/nixos-facter-modules";

  den.aspects.desktop = {
    includes = [
      r3x.roles.desktop
      r3x.base.baremetal
      # r3x.disks.impermanence
      r3x.disks.btrfs
      r3x.nix-settings
      r3x.vaultix
      r3x.services.pipewire
      r3x.services.openssh
      r3x.services.cosmic-greeter
      r3x.graphical.niri-cosmic
      r3x.all-firmware
      r3x.yubikey
      r3x.pbs-client
      r3x.system-tools
      r3x.services.incus
    ];

    nixos =
      {
        config,
        pkgs,
        ...
      }:
      let
        cachy-kernel-x86_64-v3 =
          inputs.nix-cachyos-kernel.legacyPackages.x86_64-linux.linuxPackages-cachyos-bore-lto-x86_64-v3;
        regionDir =
          if config ? settings && config.settings ? region && config.settings.region != null then
            config.settings.region
          else
            "home";
        shortHost =
          config.settings.hostName or (lib.removePrefix "${regionDir}-" config.networking.hostName);
        p1 = ../../../regions + "/${regionDir}/hosts/${shortHost}/settings/facter.json";
        p2 = ../../../regions + "/${regionDir}/hosts/${config.networking.hostName}/settings/facter.json";
        facterPath =
          if builtins.pathExists p1 then
            p1
          else if builtins.pathExists p2 then
            p2
          else
            null;
      in
      {
        imports = [
          inputs.nixos-facter-modules.nixosModules.facter
        ];

        facter.reportPath = lib.mkIf (builtins.pathExists facterPath) facterPath;

        users.users.root.hashedPassword = "!";
        users.users.root.initialHashedPassword = lib.mkForce null;
        security.pam.services.login.allowNullPassword = lib.mkForce false;

        boot.kernelPackages = cachy-kernel-x86_64-v3;
        powerManagement.cpuFreqGovernor = "performance";

        boot.kernelModules = [ "kvm-amd" ];

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

        fonts.packages = with pkgs; [
          udev-gothic-nf
        ];
      };
  };
}
