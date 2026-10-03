{
  users,
  r3x,
  ...
}:
{
  den.aspects."r3j0".includes = [
    (r3x.hasRole r3x.roles.devshell users.r3j0.devshell)
  ];

  users.r3j0.devshell = {
    includes = [
      r3x.development
    ];
  };
}
