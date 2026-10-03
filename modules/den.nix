{
  inputs,
  den,
  ...
}:
{
  imports = [
    inputs.den.flakeModule
    (inputs.den.namespace "r3x" true)
    (inputs.den.namespace "users" false)
  ];

  config._module.args.__findFile = den.lib.__findFile;
}
