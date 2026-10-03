This project is leveraging very recent [`cosmic-session` code](https://github.com/pop-os/cosmic-session/pull/75) to start different compositors.

The only thing missing then is `cosmic-comp`'s session api, which can be provided with [`cosmic-ext-alternative-startup`](https://github.com/drakulix/cosmic-ext-alternative-startup) and needs to be started by the compositor in question once startup is done and all sockets are setup.

This project just puts everything together into an installable package.

If you want to package this for your own compositor, you need a custom `start-cosmic-*` script and wayland-session. I recommend just taking on the existing ones, copy and modify it.

Further integration depends on the compositor in question. Check out the `cosmic-ext-sway-daemon` for a little daemon that watches cosmic theme settings to apply them to `sway`.