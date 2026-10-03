{
  ...
}:
{
  r3x.development.nix-ld = {
    os =
      { pkgs, ... }:
      {
        programs.nix-ld.enable = true;
        programs.nix-ld.libraries = with pkgs; [
          # Base C/C++ runtime & compression
          stdenv.cc.cc.lib
          glibc
          zlib

          # Spring / Recoil game engine dependencies
          SDL2
          libGL
          openal
          libx11
          libxcursor
          libxrandr
          libxi
          libxinerama
          curl

          # Media & system
          alsa-lib
          libpulseaudio
          udev
        ];
      };
  };
}
