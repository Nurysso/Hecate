---  _   _ _____ ____    _  _____ _____
--- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
--- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
--- |  _  | |__| |___ / ___ \| | | |___      > ^ <
--- |_| |_|_____\____/_/   \_\_| |_____|
---
--- 🚀 Auto Start CONFIGURATION
--- -----------------------------------------
--- 📚 Wiki: https://wiki.hypr.land/Configuring/Keywords/
---       exec-once = command will execute only on launch
--- -----------------------------------------

hl.on("hyprland.start", function()
	local HOME = os.getenv("HOME")
	local localBin = HOME .. "/.local/bin"
	local scriptsDir = HOME .. "/.config/hypr/scripts"

	-- Wallpaper: awww starts on black (where hecate-sddm's fade ends), then fades in the last one set-wallpaper.sh picked.
	-- QuickShell (bar, panels, notification daemon) starts once that 0.9s fade is done, so it fades in second.
	hl.exec_cmd("bash -c 'awww-daemon --no-cache & until awww query >/dev/null 2>&1; do sleep 0.05; done; awww clear 000000; awww img ~/.cache/hecate/wallpaper -t fade --transition-duration 0.9 --transition-bezier .45,0,.55,1 --transition-fps 60; sleep 0.9; pgrep -x quickshell >/dev/null || exec quickshell'")
	hl.exec_cmd("batsignal")


	-- Environment sync (Wayland vars)
	hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
	hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

	-- Startup applications
	hl.exec_cmd("nm-applet --indicator") -- Network Manager
	hl.exec_cmd("blueman-applet") -- Bluetooth manager


	-- Hecate startup (delayed)

	hl.exec_cmd("bash -c 'sleep 2 && " .. localBin .. "/hecate startup 2>&1 | tee /tmp/hecate-startup.log'")


	-- Clipboard manager (cliphist)

	hl.exec_cmd("wl-paste --type text --watch cliphist store")
	hl.exec_cmd("wl-paste --type image --watch cliphist store")


	-- Lock + idle management

	hl.exec_cmd("hypridle")


	-- Polkit auth agent

	hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

	-- Plugin loader (HyprPM) — disabled
-- hl.exec_cmd("hyprpm reload -n")
end)

