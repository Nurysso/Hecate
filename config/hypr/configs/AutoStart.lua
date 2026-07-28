--  _   _ _____ ____    _  _____ _____
-- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
-- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
-- |  _  | |__| |___ / ___ \| | | |___      > ^ <
-- |_| |_|_____\____/_/   \_\_| |_____|
--
-- 🚀 Auto Start CONFIGURATION
-- -----------------------------------------
-- 📚 Wiki: https://wiki.hypr.land/Configuring/Keywords/
--       exec-once = command will execute only on launch
-- -----------------------------------------

hl.on("hyprland.start", function()
    local HOME = os.getenv("HOME")
    local localBin   = HOME .. "/.local/bin"
    local scriptsDir = HOME .. "/.config/hypr/scripts"

    ----------------------------------------------------------------
    -- Wallpaper and widgets daemon
    ----------------------------------------------------------------
    hl.exec_cmd("awww-daemon --format xrgb")
    hl.exec_cmd("batsignal")

    ----------------------------------------------------------------
    -- Environment sync (Wayland vars)
    ----------------------------------------------------------------
    hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
    hl.exec_cmd("systemctl --user import-environment WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")

    ----------------------------------------------------------------
    -- Startup applications
    ----------------------------------------------------------------
    hl.exec_cmd("nm-applet --indicator")   -- Network Manager
    hl.exec_cmd("swaync")                  -- Notification daemon
    hl.exec_cmd("blueman-applet")          -- Bluetooth manager

    ----------------------------------------------------------------
    -- QuickShell launcher (native Lua, replaces launch-widgets.sh)
    ----------------------------------------------------------------
    launchWidgets()

    ----------------------------------------------------------------
    -- Hecate startup (delayed)
    ----------------------------------------------------------------
    hl.exec_cmd("bash -c 'sleep 2 && " .. localBin .. "/hecate startup 2>&1 | tee /tmp/hecate-startup.log'")

    ----------------------------------------------------------------
    -- Clipboard manager (cliphist)
    ----------------------------------------------------------------
    hl.exec_cmd("wl-paste --type text --watch cliphist store")
    hl.exec_cmd("wl-paste --type image --watch cliphist store")

    ----------------------------------------------------------------
    -- Lock + idle management
    ----------------------------------------------------------------
    hl.exec_cmd("hypridle")

    ----------------------------------------------------------------
    -- Polkit auth agent
    ----------------------------------------------------------------
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")

    ----------------------------------------------------------------
    -- Plugin loader (HyprPM) — disabled
    ----------------------------------------------------------------
    -- hl.exec_cmd("hyprpm reload -n")
end)

----------------------------------------------------------------
-- QuickShell launcher function
-- (replaces launch-widgets.sh: only starts quickshell if not
--  already running)
----------------------------------------------------------------
function launchWidgets()
    local handle = io.popen("pgrep -x quickshell")
    local result = handle:read("*a")
    handle:close()

    if result ~= "" then
        print("quickshell is already running.")
    else
        print("Starting quickshell...")
        hl.exec_cmd("quickshell")
    end
end
