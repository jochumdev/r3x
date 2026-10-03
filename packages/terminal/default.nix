{
  writeShellApplication,
  coreutils,
  gnugrep,
  procps,
  jq,
  xdotool,
  xprop,
}:

writeShellApplication {
  name = "terminal";

  runtimeInputs = [
    coreutils
    gnugrep
    procps
    jq
    xdotool
    xprop
  ];

  text = ''
    # Either "alacritty" or "kitty" is tested; respects $TERMINAL if set
    term="''${TERMINAL:-alacritty}"

    desktop="''${XDG_CURRENT_DESKTOP:-unknown}"

    get_parent_pid() {
    	local pid=""
    	if [[ "$desktop" == "Hyprland" ]]; then
    		# Hyprland
    		pid="$(hyprctl activewindow -j 2>/dev/null | jq -r '.pid // empty' 2>/dev/null || true)"
    	elif [[ "$desktop" == "niri" ]]; then
    		# Niri
    		pid="$(niri msg --json focused-window 2>/dev/null | jq -r '.pid // empty' 2>/dev/null || true)"
    	else
    		# Fallback to i3 / X11
    		local win_id
    		win_id="$(xdotool getactivewindow 2>/dev/null || true)"
    		if [[ -n "$win_id" ]]; then
    			pid="$(xprop -id "$win_id" _NET_WM_PID 2>/dev/null | grep -oP '\d+' | head -n 1 || true)"
    		fi
    	fi

    	if [[ -n "$pid" && "$pid" =~ ^[0-9]+$ && "$pid" -gt 0 ]]; then
    		printf "%d\n" "$pid"
    		return 0
    	fi

    	return 1
    }

    start() {
    	local parent_pid
    	parent_pid="$(get_parent_pid 2>/dev/null)" || return 1
    	[[ -n "$parent_pid" ]] || return 1

    	for pid in $(pgrep -P "$parent_pid" 2>/dev/null); do
    		ps e -p "$pid" 2>/dev/null | grep -q "_WINDOW_ID" || continue

    		local shell_pwd
    		shell_pwd="$(readlink -f /proc/"$pid"/cwd 2>/dev/null || true)"
    		[[ -d "$shell_pwd" ]] || return 1
    		exec "$term" --working-directory "''${shell_pwd}" "$@"
    	done

    	return 1
    }

    if ! start "$@"; then
    	exec "$term" "$@"
    fi
  '';
}
