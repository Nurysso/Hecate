--  _   _ _____ ____    _  _____ _____
-- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
-- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
-- |  _  | |__| |___ / ___ \| | | |___      > ^
-- |_| |_|_____\____/_/   \_\_| |_____|
--
-- 🚀 KEYBINDS CONFIGURATION
-- -----------------------------------------
-- 📚 Wiki: https://wiki.hypr.land/Configuring/Basics/Binds/
--          hl.bind(keys, dispatcher, options)
-- NOTE: This script is dynamically loaded by the Hecate-helper app
-- "--." hides a line from the parser; a trailing "--" comment on a bind
-- is shown in the app as the description for that bind.
-- "--/" starts a new category.
-- -----------------------------------------

local Scripts = os.getenv("HOME") .. "/.config/hypr/scripts"
local mainMod = "SUPER"

-- Runs a raw shell command
local function run(cmd, window_rules)
    return hl.dsp.exec_cmd(cmd, window_rules)
end

-- Runs a script by name out of Scripts/
local function run_script(script_name)
    return hl.dsp.exec_cmd(Scripts .. "/" .. script_name)
end

-- toggle_rofi adds toggle behavior to rofi.
-- If the menu is already shown, this closes it.
local function toggle_rofi(cmd)
    return hl.dsp.exec_cmd(Scripts .. "/toggle_rofi " .. cmd)
end

local function toggle_rofi_script(script_name)
    return toggle_rofi(Scripts .. "/" .. script_name)
end

-- Generates layout-specific binds to avoid Hyprland warnings
local function layout_bind(bind_table)
    return function()
        local workspace = hl.get_active_special_workspace() or hl.get_active_workspace()
        if not workspace then
            return
        end
        local layout = workspace.tiled_layout
        if bind_table[layout] then
            hl.dispatch(bind_table[layout])
        end
    end
end

-- Adjust cursor zoom factor by a multiplier, clamped to a 1.0 minimum
-- local function zoomCursor(factor)
--     return function()
--         local zoom = hl.get_config("cursor.zoom_factor") or 1
--         if zoom < 1 then zoom = 1 end
--         hl.config({ cursor = { zoom_factor = zoom * factor } })
--     end
-- end

--/ Brightness (works on lockscreen, repeats while held)
hl.bind("XF86MonBrightnessDown", run("brightnessctl s 10%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   run("brightnessctl s 10%+"), { locked = true, repeating = true })

--/ Session Control
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())                                   -- Exit Hyprland
hl.bind("CTRL + ALT + L",      run_script("LockScreen.sh"))                     -- Lock Screen
hl.bind(mainMod .. " + SHIFT + Q",  run("wlogout"))                             -- Logout Menu
hl.bind(mainMod .. " + ALT + R",    run_script("Refresh.sh"))                   -- Refresh Waybar, swaync, etc.
hl.bind(mainMod .. " + ALT + L",    run_script("ChangeLayout.sh"))              -- Toggle Layout (Master/Dwindle)
hl.bind(mainMod .. " + CTRL + W",   run("waypaper --backend swww"))             -- Change Wallpaper
hl.bind(mainMod .. " + ALT + B",    run("pkill -SIGUSR1 waybar"))               -- Toggle Waybar Visibility
hl.bind(mainMod .. " + Q",          hl.dsp.window.close())                      -- Close Active Window
hl.bind("CTRL + Tab",               run("hyprctl dispatch cyclenext"))          -- Cycle Through Applications
hl.bind(mainMod .. " + R",          run("hyprctl reload"))                      -- Reload Hyprland

--/ Applications
hl.bind(mainMod .. " + D",       run_script("drun.sh"))                       -- App Launcher (Rofi)
hl.bind(mainMod .. " + B",       run_script("System-apps.sh browser"))                -- Launch Browser
hl.bind(mainMod .. " + C",       run("code"))                                         -- Launch VSCode
hl.bind(mainMod .. " + E",       run("dolphin"))                                      -- Launch Dolphin File Manager
hl.bind(mainMod .. " + Return",  run_script("System-apps.sh term"))                   -- Launch Terminal
hl.bind(mainMod .. " + SHIFT + Return", run_script("Dropterminal.sh kitty -e zsh"))   -- Dropdown Terminal
hl.bind(mainMod .. " + H",       run("hyprsettings"))                                 -- Settings

-- SUPER + Space: Launch or kill Aoiler
hl.bind(mainMod .. " + Space", run(os.getenv("HOME") .. "/.config/hypr/scripts/Aoiler.sh"))

-- SUPER + A: Hide/show Aoiler (without killing)
hl.bind(mainMod .. " + A", hl.dsp.workspace.toggle_special("aoiler"))

hl.bind(mainMod .. " + ALT + E", run('rofi -modi emoji -show emoji -config ~/.config/rofi/config-emoji.rasi')) -- Emoji Picker
hl.bind(mainMod .. " + V",       run_script("ClipManager.sh"))               -- Clipboard Manager
hl.bind(mainMod .. " + SHIFT + V", run("pavucontrol"))                       -- Audio Control
hl.bind(mainMod .. " + SHIFT + N", run("swaync-client -t -sw"))              -- Notification Panel

--/ Screenshots
hl.bind(mainMod .. " + Print",         run_script("ScreenShot.sh full"))     -- Fullscreen Screenshot
hl.bind(mainMod .. " + SHIFT + Print", run_script("ScreenShot.sh window"))   -- Active Window Screenshot
hl.bind(mainMod .. " + SHIFT + S",     run_script("ScreenShot.sh area"))     -- Select Area Screenshot

--/ Workspaces
hl.bind(mainMod .. " + Tab",         hl.dsp.focus({ workspace = "m+1" }))  -- Next Workspace
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))  -- Previous Workspace
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind("SUPER + " .. key,         hl.dsp.focus({ workspace = i}))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false}))
    hl.bind("SUPER + CTRL + " .. key,  hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }))               -- Move Window to Prev Workspace
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }))               -- Move Window to Next Workspace
hl.bind(mainMod .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1", follow = false }))-- Move Silently to Prev Workspace
hl.bind(mainMod .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1", follow = false }))-- Move Silently to Next Workspace

hl.bind(mainMod .. " + U", hl.dsp.workspace.toggle_special())                 -- Toggle Special Workspace

--/ Window Management
hl.bind(mainMod .. " + left",  run("hyprctl dispatch movefocus l"))          -- Focus Left
hl.bind(mainMod .. " + right", run("hyprctl dispatch movefocus r"))          -- Focus Right
hl.bind(mainMod .. " + up",    run("hyprctl dispatch movefocus u"))          -- Focus Up
hl.bind(mainMod .. " + down",  run("hyprctl dispatch movefocus d"))          -- Focus Down

hl.bind(mainMod .. " + ALT + left",  run("hyprctl dispatch swapwindow l"))   -- Swap with Left Window
hl.bind(mainMod .. " + ALT + right", run("hyprctl dispatch swapwindow r"))   -- Swap with Right Window
hl.bind(mainMod .. " + ALT + up",    run("hyprctl dispatch swapwindow u"))   -- Swap with Upper Window
hl.bind(mainMod .. " + ALT + down",  run("hyprctl dispatch swapwindow d"))   -- Swap with Lower Window

hl.bind(mainMod .. " + CTRL + left",  run("hyprctl dispatch movewindow l"))  -- Move Floating Window Left
hl.bind(mainMod .. " + CTRL + right", run("hyprctl dispatch movewindow r"))  -- Move Floating Window Right
hl.bind(mainMod .. " + CTRL + up",    run("hyprctl dispatch movewindow u"))  -- Move Floating Window Up
hl.bind(mainMod .. " + CTRL + down",  run("hyprctl dispatch movewindow d"))  -- Move Floating Window Down

hl.bind(mainMod .. " + SHIFT + left",  run("hyprctl dispatch resizeactive -50 0"), { repeating = true }) -- Resize Left
hl.bind(mainMod .. " + SHIFT + right", run("hyprctl dispatch resizeactive 50 0"),  { repeating = true }) -- Resize Right
hl.bind(mainMod .. " + SHIFT + up",    run("hyprctl dispatch resizeactive 0 -50"), { repeating = true }) -- Resize Up
hl.bind(mainMod .. " + SHIFT + down",  run("hyprctl dispatch resizeactive 0 50"),  { repeating = true }) -- Resize Down

hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))     -- Toggle Floating
hl.bind(mainMod .. " + ALT + SPACE",   run("hyprctl dispatch workspaceopt allfloat"))  -- Toggle All Float
hl.bind(mainMod .. " + F",             hl.dsp.window.fullscreen())                     -- Toggle Fullscreen
hl.bind(mainMod .. " + CTRL + F",      hl.dsp.window.fullscreen({ mode = 1 }))         -- Fullscreen (Mode 1)

--/ Groups & Layouts
hl.bind(mainMod .. " + G",          hl.dsp.group.toggle())                    -- Toggle Group
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.group.next())                      -- Cycle Group Window
hl.bind(mainMod .. " + CTRL + D",   hl.dsp.layout("removemaster"))            -- Remove Master
hl.bind(mainMod .. " + I",          hl.dsp.layout("addmaster"))               -- Add Master
hl.bind(mainMod .. " + J",          hl.dsp.layout("cyclenext"))               -- Cycle Next Window
hl.bind(mainMod .. " + K",          hl.dsp.layout("cycleprev"))               -- Cycle Prev Window
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster master"))-- Swap with Master
-- hl.bind(mainMod .. " + SHIFT + I", run("hyprctl dispatch togglesplit"))    -- Toggle Split Layout
hl.bind(mainMod .. " + P", run("hyprctl dispatch pseudo"))                    -- Toggle Pseudo Tiling
-- hl.bind(mainMod .. " + M", hl.dsp.layout("splitratio 0.3"))                   -- Set Split Ratio 0.3

--/ Mouse
hl.bind(mainMod .. "+ mouse:272", hl.dsp.window.drag(),   { mouse = true })       -- Drag to Move
hl.bind(mainMod .. "+ mouse:273", hl.dsp.window.resize(), { mouse = true })       -- Drag to Resize

-- Adjust cursor zoom factor by a multiplier, clamped to a 1.0 minimum
local function zoomCursor(factor)
    return function()
        local zoom = hl.get_config("cursor.zoom_factor") or 1
        if zoom < 1 then zoom = 1 end
        hl.config({ cursor = { zoom_factor = zoom * factor } })
    end
end

hl.bind(mainMod .. " + ALT + mouse_down", zoomCursor(2.0))   -- Zoom In Cursor
hl.bind(mainMod .. " + ALT + mouse_up",   zoomCursor(0.5))   -- Zoom Out Cursor
--/ Media
hl.bind(mainMod .. " + ALT + V", run("pavucontrol"))
hl.bind("xf86audioraisevolume", run_script("Volume.sh --inc"),        { repeating = true })
hl.bind("xf86audiolowervolume", run_script("Volume.sh --dec"),        { repeating = true })
hl.bind("XF86AudioMicMute",     run_script("Volume.sh --toggle-mic"), { locked = true })
hl.bind("xf86audiomute",        run_script("Volume.sh --toggle"),     { locked = true })
hl.bind("XF86AudioPause",       run_script("MediaContol.sh --pause"), { locked = true })
hl.bind("XF86AudioPlay",        run_script("MediaContol.sh --pause"), { locked = true })
hl.bind("XF86AudioNext",        run_script("MediaContol.sh --nxt"),   { locked = true })
hl.bind("XF86AudioPrev",        run_script("MediaContol.sh --prv"),   { locked = true })
hl.bind("xf86audiostop",        run_script("MediaContol.sh --stop"),  { locked = true })
hl.bind("XF86Sleep",            run("systemctl suspend"),             { locked = true })
hl.bind("XF86Rfkill",           run_script("AirplaneMode.sh"),        { locked = true })
