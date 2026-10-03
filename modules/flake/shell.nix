{
  inputs,
  lib,
  den,
  ...
}:
{
  perSystem =
    {
      pkgs,
      config,
      ...
    }:
    let
      system = pkgs.stdenvNoCC.targetPlatform.system;
      vaultix-renc = config.packages.vaultix-renc;
      vaultix-edit = config.packages.vaultix-edit;

      vaultixApps = [
        vaultix-renc
        vaultix-edit
      ];
    in
    {
      apps = {
        vaultix-renc = {
          type = "app";
          program = lib.getExe vaultix-renc;
        };
        vaultix-edit = {
          type = "app";
          program = lib.getExe vaultix-edit;
        };
      };

      devShells.default =
        let
          denApps = den.lib.nh.denApps {
            outPrefix = [ ];
            fromFlake = false;
          } pkgs;

          formatter = inputs.self.formatter.${system};
          fmtt = pkgs.writeShellApplication {
            name = "fmtt";
            text = ''
              ${lib.getExe formatter} "$@"
            '';
          };

          firstHostConfig =
            let
              configs = inputs.self.nixosConfigurations or { };
              names = builtins.attrNames configs;
            in
            if names != [ ] then configs.${builtins.head names}.config else null;

          nix_conf =
            if firstHostConfig != null then
              {
                inherit (firstHostConfig.nix.settings)
                  experimental-features
                  substituters
                  trusted-public-keys
                  connect-timeout
                  stalled-download-timeout
                  download-attempts
                  narinfo-cache-negative-ttl
                  ;
              }
            else
              { };

          nix_conf_file = pkgs.writeTextFile {
            name = "nix.conf";
            text = lib.concatStringsSep "\n" (
              lib.mapAttrsToList (
                name: value:
                let
                  valStr = if lib.isList value then lib.concatStringsSep " " value else toString value;
                in
                if name == "substituters" || !lib.isList value then
                  "${name} = ${valStr}"
                else
                  "extra-${name} = ${valStr}"
              ) nix_conf
            );
          };

          shellHook = ''
            export NIX_USER_CONF_FILES="${nix_conf_file}"
          '';

        in
        pkgs.mkShell {
          shellHook = shellHook;
          buildInputs =
            denApps
            ++ vaultixApps
            ++ [
              fmtt
              # apps.vic-sops-rotate
              # apps.vic-sops-get
              # apps.edgevpn
              # apps.gh-deps-update
              pkgs.nh
              pkgs.sops
              pkgs.just
              pkgs.npins
              pkgs.attic-client
              pkgs.nix-unit

              pkgs.opentofu

              # age
              pkgs.rage
              pkgs.age-plugin-yubikey

              pkgs.nixos-rebuild
              pkgs.nixos-facter
            ];
        };
    };
}
