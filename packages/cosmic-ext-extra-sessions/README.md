# cosmic-ext-extra-sessions

COSMIC-based alternative sessions with different compositors:
- [sway](https://github.com/swaywm/sway)
- [niri](https://github.com/YaLTeR/niri)
- [miracle-wm](https://miracle-wm.org/)

**Note**: These are unsupported configurations for **alpha** software. Things will break!
Please confirm any bugs against standard COSMIC, before opening issues on it's projects.
If in doubt open an issue here first!

## But what about ...

Just add it! Please take a look at [How This Works](./HowThisWorks.md) and start a PR!

### But what about hyprland

No.

### But ...

No. I won't debate you on it. Go and do this somewhere else and don't expect support.

## Why?

- Because it's fun!
- (And it nicely shows off what using common standards can give you.)
-  ((Also, I can't count the amount of issues of people wanting scrolling tiling in COSMIC. Here, just use niri while we decide what to do about this. It's a great project!))

## How?

Cosmic uses a lot of open protocols, the only little magic bit happens in [`cosmic-ext-alternative-startup`](https://github.com/drakulix/cosmic-ext-alternative-startup).

For specific instructions for each environment look into their specific folder:
- [sway](./sway)
- [niri](./niri)
- [miracle-wm](./miracle)

## Requirements

- You need a `cosmic-session` binary build with this [patch](https://github.com/pop-os/cosmic-session/pull/75)
- You will want a very recent nightly build of cosmic-panel, that fixes crashes on other compositors.
- cosmic + your compositor of choice installed
