use anyhow::Context;
use cosmic_theme::{Theme, ThemeMode};

pub struct State {
    ipc: swayipc::Connection,
    theme: cosmic::theme::Theme,
}

fn update_theme(ipc: &mut swayipc::Connection, theme: &Theme) {
    let active_hint = if let Some(hint) = theme.window_hint {
        hint.into()
    } else {
        theme.accent_color()
    };
    let _ = ipc.run_command(format!(
        "client.focused #{:X?}{:X?}{:X?} #{:02X?}{:02X?}{:02X?} #{:02X?}{:02X?}{:02X?}",
        (active_hint.red * 255.0).round() as u32,
        (active_hint.green * 255.0).round() as u32,
        (active_hint.blue * 255.0).round() as u32,
        (theme.accent_color().red * 255.0).round() as u32,
        (theme.accent_color().green * 255.0).round() as u32,
        (theme.accent_color().blue * 255.0).round() as u32,
        (theme.on_accent_color().red * 255.0).round() as u32,
        (theme.on_accent_color().green * 255.0).round() as u32,
        (theme.on_accent_color().blue * 255.0).round() as u32,
    ));
    let _ = ipc.run_command(format!("border normal {}", theme.active_hint));
    let _ = ipc.run_command(format!("default_border normal {}", theme.active_hint));
    let _ = ipc.run_command(format!("gaps outer all set {}", theme.gaps.0));
    let _ = ipc.run_command(format!("gaps inner all set {}", theme.gaps.1));
}

fn main() -> anyhow::Result<()> {
    let mut evlh = calloop::EventLoop::<'static, State>::try_new()
        .context("Failed to create event loop")?;
    let (ping_tx, ping_rx) = calloop::ping::make_ping().context("Failed to create ping source")?;

    let config_mode_helper = ThemeMode::config()?;
    let config_dark_helper = Theme::dark_config()?;
    let config_light_helper = Theme::light_config()?;

    evlh.handle().insert_source(ping_rx, move |_, _, state| {
        let new_theme = cosmic::theme::system_preference();

        if state.theme.theme_type != new_theme.theme_type {
            state.theme = new_theme;
            update_theme(&mut state.ipc, state.theme.cosmic());
        }
    }).context("Failed to setup ping source")?;

    let ping_tx_clone = ping_tx.clone();
    let theme_watcher_mode = config_mode_helper.watch(move |_, _keys| {
        ping_tx_clone.ping();
    })?;
    let ping_tx_clone = ping_tx.clone();
    let theme_watcher_light = config_light_helper.watch(move |_, _keys| {
        ping_tx_clone.ping();
    })?;
    let theme_watcher_dark = config_dark_helper.watch(move |_, _keys| {
        ping_tx.ping();
    })?;

    std::mem::forget(theme_watcher_dark);
    std::mem::forget(theme_watcher_light);
    std::mem::forget(theme_watcher_mode);

    let mut ipc = swayipc::Connection::new().context("Failed to connect to sway")?;
    let theme = cosmic::theme::system_preference();
    update_theme(&mut ipc, theme.cosmic());
    let mut state = State {
        ipc,
        theme,
    };

    evlh.run(None, &mut state, |_| {}).context("Event loop broke")?;

    Ok(())
}
