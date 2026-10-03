{ r3x, ... }:
{
  r3x.graphical.xfce-no-lock = {
    includes = [
      r3x.graphical.xfce
    ];

    nixos =
      { pkgs, lib, ... }:
      {
        services.xserver = {
          desktopManager.xfce.enableScreensaver = false;
          displayManager.sessionCommands = ''
            ${lib.getBin pkgs.xorg.xset}/bin/xset s off -dpms
          '';
          serverFlagsSection = ''
            Option "BlankTime" "0"
            Option "StandbyTime" "0"
            Option "SuspendTime" "0"
            Option "OffTime" "0"
          '';
        };

        systemd.targets.sleep.enable = false;
        systemd.targets.suspend.enable = false;
        systemd.targets.hibernate.enable = false;
        systemd.targets.hybrid-sleep.enable = false;

        environment.etc = {
          "xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-power-manager.xml".text = ''
            <?xml version="1.0" encoding="UTF-8"?>
            <channel name="xfce4-power-manager" version="1.0">
              <property name="xfce4-power-manager" type="empty">
                <property name="dpms-enabled" type="bool" value="false"/>
                <property name="blank-on-ac" type="int" value="0"/>
                <property name="dpms-on-ac-sleep" type="int" value="0"/>
                <property name="dpms-on-ac-off" type="int" value="0"/>
                <property name="lock-screen-suspend-hibernate" type="bool" value="false"/>
              </property>
            </channel>
          '';
          "xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-screensaver.xml".text = ''
            <?xml version="1.0" encoding="UTF-8"?>
            <channel name="xfce4-screensaver" version="1.0">
              <property name="saver" type="empty">
                <property name="enabled" type="bool" value="false"/>
              </property>
              <property name="lock" type="empty">
                <property name="enabled" type="bool" value="false"/>
              </property>
            </channel>
          '';
          "xdg/xfce4/xfconf/xfce-perchannel-xml/xfce4-session.xml".text = ''
            <?xml version="1.0" encoding="UTF-8"?>
            <channel name="xfce4-session" version="1.0">
              <property name="general" type="empty">
                <property name="LockCommand" type="string" value=""/>
              </property>
            </channel>
          '';
        };
      };
  };
}
