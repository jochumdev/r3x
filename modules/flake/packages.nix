{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      system = pkgs.stdenvNoCC.targetPlatform.system;
      vaultixPkg = inputs.vaultix.packages.${system}.default;
      vaultixTools = pkgs.callPackage ../../packages/vaultix {
        inherit vaultixPkg;
        nixosConfigurations = inputs.self.nixosConfigurations or { };
      };
    in
    {
      packages = {
        cosmic-ext-extra-sessions = pkgs.callPackage ../../packages/cosmic-ext-extra-sessions { };
        terminal = pkgs.callPackage ../../packages/terminal { };

        vaultix-manifest = vaultixTools.manifest;
        vaultix-edit = vaultixTools.edit;
        vaultix-renc = vaultixTools.renc;
        vaultix-tools = vaultixTools;
      };
    };
}
