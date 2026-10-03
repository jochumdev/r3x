{ ... }:
{
  r3x.pbs-client = {
    os =
      { pkgs, ... }:
      {
        environment.systemPackages = [
          pkgs.proxmox-backup-client
        ];
      };
  };
}
