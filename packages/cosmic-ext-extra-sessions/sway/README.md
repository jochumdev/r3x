# cosmic-ext-sway

This is cosmic running on sway!

## Install

Either clone the repo and run `just install-sway` or install manually:
- `start-cosmic-ext-sway` somewhere in your `PATH`, e.g. `/usr/local/bin`
- `cosmic-ext-sway.desktop` into `/usr/share/wayland-sessions/cosmic-ext-sway.desktop`
- `config-cosmic` to `/etc/sway/config-cosmic`

Optionally install `cosmic-ext-sway-daemon` to your `PATH` for further integration.

## Configuration

The default configuration on various distributions sets up it's own session code and possibly systemd integration, which potentially conflicts with what `cosmic-ext-sway` is doing.

Additionally we need to launch a couple of programs (`cosmic-ext-alternative-startup` and optionally `cosmic-ext-sway-daemon`).


If you want to configure this yourself, I recommend either using `config-cosmic` as a starting base or just including `config-cosmic` in your local configuration and then override settings you don't like.