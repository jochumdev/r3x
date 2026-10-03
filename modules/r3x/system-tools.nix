{ ... }:
{
  r3x.system-tools = {
    os =
      { pkgs, ... }:
      {
        environment.systemPackages = with pkgs; [
          smartmontools
          iperf3
          socat
          traceroute
        ];
      };
  };
}
