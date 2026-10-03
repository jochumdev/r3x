{
  den,
  r3x,
  ...
}:
let
  resolveRole = role: if builtins.isString role then r3x.roles.${role} else role;

  hasRole =
    role: payload: den.lib.policy.when ({ host, ... }: host.hasAspect (resolveRole role)) payload;

  withoutRole =
    role: payload: den.lib.policy.when ({ host, ... }: !host.hasAspect (resolveRole role)) payload;
in
{
  r3x.hasRole = {
    __functor = _self: hasRole;
  };
  r3x.withoutRole = {
    __functor = _self: withoutRole;
  };

  r3x.roles.desktop = { };
  r3x.roles.shell = { };
  r3x.roles.devshell = { };
}
