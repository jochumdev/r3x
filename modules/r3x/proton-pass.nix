{ ... }:
{
  r3x.proton-pass = {
    homeManager =
      { config, pkgs, ... }:
      {
        home.packages = [ pkgs.proton-pass-cli ];

        home.sessionVariables = {
          SSH_AUTH_SOCK = "${config.home.homeDirectory}/.ssh/proton-pass-agent.sock";
          PROTON_PASS_LINUX_KEYRING = "dbus";
        };

        programs.librewolf.policies.ExtensionSettings = {
          "78272b6fa58f4a1abaac99321d503a20@proton.me" = {
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/proton-pass/latest.xpi";
            installation_mode = "force_installed";
          };
        };

        systemd.user.services.pass-cli-ssh-agent = {
          Unit = {
            Description = "Proton pass-cli ssh-agent";
            PartOf = [ "graphical-session.target" ];
            After = [ "graphical-session.target" ];
          };
          Service = {
            Type = "simple";
            ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.ssh";
            ExecStart = "${pkgs.proton-pass-cli}/bin/pass-cli ssh-agent start";
            Restart = "on-failure";
            RestartSec = "5s";
            Environment = [
              "PROTON_PASS_LINUX_KEYRING=dbus"
            ];
          };
          Install = {
            WantedBy = [ "graphical-session.target" ];
          };
        };
      };
  };
}
