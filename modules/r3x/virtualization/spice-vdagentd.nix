{ ... }:
{
  r3x.virtualization.spice-vdagentd = {
    nixos =
      { ... }:
      {
        services.spice-vdagentd.enable = true;
      };
  };
}
