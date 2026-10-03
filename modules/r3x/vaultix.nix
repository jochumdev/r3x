{ inputs, ... }:
{
  r3x.vaultix = {
    os =
      {
        config,
        lib,
        ...
      }:
      let
        regionDir =
          if config ? settings && config.settings ? region && config.settings.region != null then
            config.settings.region
          else
            "home";
        shortHost =
          config.settings.hostName or (lib.removePrefix "${regionDir}-" config.networking.hostName);
        p1 = ../../regions + "/${regionDir}/hosts/${shortHost}/ssh_host_ed25519_key.pub";
        p2 = ../../regions + "/${regionDir}/hosts/${config.networking.hostName}/ssh_host_ed25519_key.pub";
        hostPubkeyPath =
          if builtins.pathExists p1 then
            p1
          else if builtins.pathExists p2 then
            p2
          else
            null;
      in
      {
        imports = [
          inputs.vaultix.nixosModules.default
        ];

        options.vaultix.enable = lib.mkEnableOption "vaultix secret management" // {
          default = true;
        };

        config = lib.mkMerge [
          (lib.mkIf config.vaultix.enable {
            services.userborn.enable = true;
            # Provide self with outPath so Vaultix can locate the flake root and secret cache
            vaultix.settings.flake = inputs.self // {
              outPath = inputs.self.outPath or ../../.;
            };

            # Automatically use files/hosts/<hostname>/ssh_host_ed25519_key.pub if the file exists
            vaultix.settings.hostPubkey = lib.mkIf (builtins.pathExists hostPubkeyPath) (
              lib.mkDefault (lib.removeSuffix "\n" (builtins.readFile hostPubkeyPath))
            );

            vaultix.settings.hostKeys = lib.mkDefault [
              {
                path = "/persist/etc/ssh/ssh_host_ed25519_key";
                type = "ed25519";
              }
            ];

            systemd.services.vaultix-activate.after = [ "systemd-tmpfiles-setup.service" ];
          })
          (lib.mkIf (!config.vaultix.enable) {
            systemd.services.vaultix-activate.enable = false;
          })
        ];
      };
  };
}
