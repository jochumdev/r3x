{
  lib,
  rustPlatform,
  bash,
  dbus,
  cosmic-session,
  sessions ? [ "niri" ], # Supported: "niri", "miracle", "sway"
}:

rustPlatform.buildRustPackage {
  pname = "cosmic-ext-extra-sessions";
  version = "0.1.0";

  src = ./.;

  cargoRoot = "cosmic-ext-alternative-startup";
  buildAndTestSubdir = "cosmic-ext-alternative-startup";

  cargoLock = {
    lockFile = ./cosmic-ext-alternative-startup/Cargo.lock;
  };

  nativeBuildInputs = [ bash ];

  postInstall = ''
    mkdir -p $out/bin $out/share/wayland-sessions

    ${lib.optionalString (lib.elem "niri" sessions) ''
      # Install Niri session files
      install -Dm0755 niri/start-cosmic-ext-niri $out/bin/start-cosmic-ext-niri
      install -Dm0644 niri/cosmic-ext-niri.desktop $out/share/wayland-sessions/cosmic-ext-niri.desktop
      install -Dm0644 niri/xdg-desktop-portal/niri-portals.conf $out/share/xdg-desktop-portal/niri-portals.conf

      substituteInPlace $out/share/wayland-sessions/cosmic-ext-niri.desktop \
        --replace-warn "/usr/bin/env start-cosmic-ext-niri" "$out/bin/start-cosmic-ext-niri" \
        --replace-warn "/usr/local/bin/start-cosmic-ext-niri" "$out/bin/start-cosmic-ext-niri" \
        --replace-warn "/usr/bin/start-cosmic-ext-niri" "$out/bin/start-cosmic-ext-niri"

      substituteInPlace $out/bin/start-cosmic-ext-niri \
        --replace-warn "exec bash -c" "exec ${bash}/bin/bash -c" \
        --replace-warn "/usr/bin/env dbus-run-session" "${dbus}/bin/dbus-run-session" \
        --replace-warn "/usr/bin/dbus-run-session" "${dbus}/bin/dbus-run-session" \
        --replace-warn "/usr/bin/env cosmic-session" "${cosmic-session}/bin/cosmic-session" \
        --replace-warn "/usr/bin/cosmic-session" "${cosmic-session}/bin/cosmic-session"
    ''}

    ${lib.optionalString (lib.elem "miracle" sessions) ''
      # Install Miracle session files
      install -Dm0755 miracle/start-cosmic-ext-miracle $out/bin/start-cosmic-ext-miracle
      install -Dm0644 miracle/cosmic-ext-miracle.desktop $out/share/wayland-sessions/cosmic-ext-miracle.desktop

      substituteInPlace $out/share/wayland-sessions/cosmic-ext-miracle.desktop \
        --replace-warn "/usr/bin/env start-cosmic-ext-miracle" "$out/bin/start-cosmic-ext-miracle" \
        --replace-warn "/usr/local/bin/start-cosmic-ext-miracle" "$out/bin/start-cosmic-ext-miracle" \
        --replace-warn "/usr/bin/start-cosmic-ext-miracle" "$out/bin/start-cosmic-ext-miracle"

      substituteInPlace $out/bin/start-cosmic-ext-miracle \
        --replace-warn "exec bash -c" "exec ${bash}/bin/bash -c" \
        --replace-warn "/usr/bin/env dbus-run-session" "${dbus}/bin/dbus-run-session" \
        --replace-warn "/usr/bin/dbus-run-session" "${dbus}/bin/dbus-run-session" \
        --replace-warn "/usr/bin/env cosmic-session" "${cosmic-session}/bin/cosmic-session" \
        --replace-warn "/usr/bin/cosmic-session" "${cosmic-session}/bin/cosmic-session"
    ''}

    ${lib.optionalString (lib.elem "sway" sessions) ''
      # Install Sway session files
      install -Dm0755 sway/start-cosmic-ext-sway $out/bin/start-cosmic-ext-sway
      install -Dm0644 sway/cosmic-ext-sway.desktop $out/share/wayland-sessions/cosmic-ext-sway.desktop
      install -Dm0644 sway/config-cosmic $out/etc/sway/config-cosmic

      substituteInPlace $out/share/wayland-sessions/cosmic-ext-sway.desktop \
        --replace-warn "/usr/bin/env start-cosmic-ext-sway" "$out/bin/start-cosmic-ext-sway" \
        --replace-warn "/usr/local/bin/start-cosmic-ext-sway" "$out/bin/start-cosmic-ext-sway" \
        --replace-warn "/usr/bin/start-cosmic-ext-sway" "$out/bin/start-cosmic-ext-sway"

      substituteInPlace $out/bin/start-cosmic-ext-sway \
        --replace-warn "exec bash -c" "exec ${bash}/bin/bash -c" \
        --replace-warn "/usr/bin/env dbus-run-session" "${dbus}/bin/dbus-run-session" \
        --replace-warn "/usr/bin/dbus-run-session" "${dbus}/bin/dbus-run-session" \
        --replace-warn "/usr/bin/env cosmic-session" "${cosmic-session}/bin/cosmic-session" \
        --replace-warn "/usr/bin/cosmic-session" "${cosmic-session}/bin/cosmic-session"
    ''}

    patchShebangs $out/bin
  '';

  passthru = {
    providedSessions = map (s: "cosmic-ext-${s}") sessions;
  };

  meta = with lib; {
    description = "COSMIC session integration for alternative Wayland compositors (Niri, Sway, Miracle)";
    homepage = "https://github.com/Drakulix/cosmic-ext-extra-sessions";
    license = licenses.gpl3Only;
    platforms = platforms.linux;
    mainProgram = "cosmic-ext-alternative-startup";
  };
}
