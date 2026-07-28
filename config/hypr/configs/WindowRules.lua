--  _   _ _____ ____    _  _____ _____
-- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
-- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
-- |  _  | |__| |___ / ___ \| | | |___      > ^ <
-- |_| |_|_____\____/_/   \_\_| |_____|
--
-- 🚀 WINDOW RULES CONFIGURATION
-- -----------------------------------------
-- 📚 Wiki: https://wiki.hypr.land/Configuring/Window-Rules/
--
-- 💡 Quick Tips:
--    - Control window behavior and attributes.
--    - Syntax: windowrule=RULE,PARAMETERS
--    - Example: `windowrule = float, ^(pavucontrol)$`
-- -----------------------------------------

--------------------------------------------------------------------------------
-- Window Rules
-- Wiki: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--------------------------------------------------------------------------------

-- hl.window_rule({ opacity = "$windowOpacity override", match = { fullscreen = false } })

-- They use native transparency or we want them opaque
hl.window_rule({ opaque = true, match = { class = "foot|equibop|org\\.quickshell|imv|swappy" } })

-- Center all floating windows (not xwayland, cause popups)
hl.window_rule({ center = true, match = { float = true, xwayland = false } })

hl.window_rule({ float = true, match = { class = "guifetch" } })
hl.window_rule({ float = true, match = { class = "yad" } })
hl.window_rule({ float = true, match = { class = "org\\.gnome\\.FileRoller" } })
hl.window_rule({ float = true, match = { class = "file-roller" } })
hl.window_rule({ float = true, match = { class = "blueman-manager" } })
hl.window_rule({ float = true, match = { class = "com\\.github\\.GradienceTeam\\.Gradience" } })
hl.window_rule({ float = true, match = { class = "feh" } })
hl.window_rule({ float = true, match = { class = "imv" } })
hl.window_rule({ float = true, match = { class = "system-config-printer" } })
hl.window_rule({ float = true, match = { class = "org\\.quickshell" } })
hl.window_rule({ float = true, workspace = "special", size = { "70%", "80%" }, match = { class = "com\\.obsproject\\.Studio" } })

hl.window_rule({ float = true, match = { class = "foot", title = "nmtui" } })
hl.window_rule({ size = { "70%", "70%" }, match = { class = "pulseaudio.pavucontrol" } })
hl.window_rule({ size = { "60%", "70%" }, match = { class = "foot", title = "nmtui" } })
hl.window_rule({ center = true, match = { class = "foot", title = "nmtui" } })
hl.window_rule({ float = true, match = { title = "Library" } })
hl.window_rule({ float = true, match = { class = "nm-connection-editor" } })
hl.window_rule({ float = true, match = { class = "org\\.gnome\\.Settings" } })
hl.window_rule({ size = { "70%", "80%" }, match = { class = "org\\.gnome\\.Settings" } })
hl.window_rule({ center = true, match = { class = "org\\.gnome\\.Settings" } })
hl.window_rule({ float = true, match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser|waypaper" } })
hl.window_rule({ size = { "80%", "70%" }, match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser|waypaper" } })
hl.window_rule({ center = true, match = { class = "org\\.pulseaudio\\.pavucontrol|yad-icon-browser|waypaper" } })
hl.window_rule({ float = true, match = { class = "nwg-look" } })
hl.window_rule({ size = { "50%", "60%" }, match = { class = "nwg-look" } })
hl.window_rule({ center = true, match = { class = "nwg-look" } })
hl.window_rule({ float = true, match = { class = "hyprsettings" } })
hl.window_rule({ float = true, match = { class = "xdg-desktop-portal-gtk" } })
hl.window_rule({ float = true, match = { class = "Hera" } })

-- Dialogs
hl.window_rule({ float = true, match = { title = "(Select|Open)( a)? (File|Folder)(s)?" } })
hl.window_rule({ float = true, match = { title = "File (Operation|Upload)( Progress)?" } })
hl.window_rule({ float = true, match = { class = "^firefox$", title = "^Opening .*$" } })
hl.window_rule({ float = true, match = { title = "nmtui" } })
hl.window_rule({ float = true, match = { title = ".* Properties" } })
hl.window_rule({ float = true, match = { title = "Export Image as PNG" } })
hl.window_rule({ float = true, match = { title = "GIMP Crash Debug" } })
hl.window_rule({ float = true, match = { title = "Save As" } })
hl.window_rule({ float = true, match = { title = "Library" } })

-- hl.window_rule({ float = true, border_size = 0, center = true, size = {923, 573}, match = { class = "nm-connection-editor", float = true } })

--------------------------------------------------------------------------------
-- Workspace Rules
--------------------------------------------------------------------------------
hl.workspace_rule({ workspace = "w[tv1]s[false]", gaps_out = 10 })
hl.workspace_rule({ workspace = "f[1]s[false]",   gaps_out = 10 })

--------------------------------------------------------------------------------
-- Layer Rules
--------------------------------------------------------------------------------
hl.layer_rule({ animation = "fade", match = { namespace = "hyprpicker" } })      -- Colour picker out animation
hl.layer_rule({ animation = "fade", match = { namespace = "logout_dialog" } })   -- wlogout
hl.layer_rule({ animation = "fade", match = { namespace = "selection" } })       -- slurp
hl.layer_rule({ animation = "fade", match = { namespace = "wayfreeze" } })

-- Fuzzel
hl.layer_rule({ animation = "popin 80%", match = { namespace = "launcher" } })
hl.layer_rule({ blur = true,             match = { namespace = "launcher" } })

--------------------------------------------------------------------------------
-- Named Window Rules
--------------------------------------------------------------------------------
hl.window_rule({
    name  = "windowrule-7",
    float = true,
    match = { title = "^(System Monitor)$" },
})

-- Picture-in-Picture special behavior
hl.window_rule({
    name  = "windowrule-8",
    float = true,
    pin   = true,
    move  = { "monitor_w*0.695", "monitor_h*0.04" },
    match = { title = "^(Picture-in-Picture)$" },
})

hl.window_rule({
    name        = "windowrule-9",
    center      = true,
    border_size = 0,
    match       = { title = "^(update-window)$" },
})

hl.window_rule({
    name  = "windowrule-10",
    float = true,
    size  = { 900, 600 },
    match = { class = "^(dotfiles-floating)$" },
})

hl.window_rule({
    name        = "windowrule-11",
    border_size = 0,
    no_shadow   = true,
    match       = { title = "^(Firefox)$" },
})

-- hl.window_rule({ float = true, match = { class = "^(dropdown)$" } })
-- hl.window_rule({ workspace = "special", silent = true, match = { class = "^(dropdown)$" } })

-- System Visualizer Widget Rules
hl.window_rule({
    name        = "windowrule-15",
    float       = true,
    border_size = 0,
    no_blur     = true,
    match       = { class = "^(Pulse)$" },
})

-- hl.window_rule({ pin = true, match = { class = "^(Pulse)$" } })

hl.window_rule({
    name        = "windowrule-16",
    float       = true,
    border_size = 0,
    no_blur     = true,
    match       = { class = "^(Hecate-Settings)$" },
})

-- Window rules for Aoiler
hl.window_rule({
    name      = "windowrule-17",
    workspace = "special:aoiler",
    float     = true,
    size      = { "monitor_w*0.2", "monitor_h*0.95" },
    move      = { 10, 40 },
    match     = { class = "(Aoiler)" },
})

hl.window_rule({
    name  = "windowrule-18",
    float = true,
    match = { initial_class = "^(shotcut)$", initial_title = "^(Projects Folder)$" },
})
