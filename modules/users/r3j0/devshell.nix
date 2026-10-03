{
  den,
  users,
  r3x,
  ...
}:
{
  den.aspects."r3j0".includes = [
    (den.lib.policy.when ({ host, ... }: host.hasAspect r3x.roles.devshell) users.r3j0.devshell)
  ];

  users.r3j0.devshell = {
    includes = [
      r3x.development
    ];
  };
}
