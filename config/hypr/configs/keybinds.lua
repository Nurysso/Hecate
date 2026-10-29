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

-- Toggles a Quickshell panel (see ~/.config/quickshell/shell.qml)
local function panel(name)
    return hl.dsp.exec_cmd("qs ipc call hecate toggle " .. name)
end

-- Runs a script by name out of Scripts/
local function run_script(script_name)
    return hl.dsp.exec_cmd(Scripts .. "/" .. script_name)
end

-- Safe bind for dispatchers whose exact Lua name/args I could not verify
-- against the docs. If the dispatcher doesn't exist, the bind is skipped
-- instead of aborting the rest of this file.
-- Once a bind works, you can turn it into a plain hl.bind().
local function try_bind(keys, build, opts)
    local ok, dsp = pcall(build)
    if ok and dsp then
        pcall(hl.bind, keys, dsp, opts)
    end
end

-- Adjust cursor zoom factor by a multiplier, clamped to a 1.0 minimum
local function zoomCursor(factor)
    return function()
        local zoom = hl.get_config("cursor.zoom_factor") or 1
        if zoom < 1 then zoom = 1 end
        hl.config({ cursor = { zoom_factor = zoom * factor } })
    end
end

--/ Brightness (works on lockscreen, repeats while held)
hl.bind("XF86MonBrightnessDown", run("brightnessctl s 10%-"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessUp",   run("brightnessctl s 10%+"), { locked = true, repeating = true })

--/ Session Control
hl.bind("CTRL + ALT + Delete", hl.dsp.exit())                                   -- Exit Hyprland
hl.bind("CTRL + ALT + L",      run_script("LockScreen.sh"))                     -- Lock Screen
hl.bind(mainMod .. " + SHIFT + Q",  panel("power"))                             -- Power Menu
hl.bind(mainMod .. " + ALT + R",    run_script("Refresh.sh"))                   -- Refresh Waybar, swaync, etc.
hl.bind(mainMod .. " + ALT + L",    run_script("ChangeLayout.sh"))              -- Toggle Layout (Master/Dwindle)
hl.bind(mainMod .. " + CTRL + W",   panel("wallpaper"))                         -- Change Wallpaper
hl.bind(mainMod .. " + ALT + B",    run("pkill -SIGUSR1 waybar"))               -- Toggle Waybar Visibility
hl.bind(mainMod .. " + Q",          hl.dsp.window.close())                      -- Close Active Window
hl.bind(mainMod .. " + R",          run("hyprctl reload"))                      -- Reload Hyprland

--/ Applications
hl.bind(mainMod .. " + D",       panel("launcher"))                           -- App Launcher
hl.bind(mainMod .. " + B",       run_script("System-apps.sh browser"))                -- Launch Browser
hl.bind(mainMod .. " + C",       run("code"))                                         -- Launch VSCode
hl.bind(mainMod .. " + E",       run("dolphin"))                                      -- Launch Dolphin File Manager
hl.bind(mainMod .. " + Return",  run_script("System-apps.sh term"))                   -- Launch Terminal
hl.bind(mainMod .. " + SHIFT + Return", run_script("Dropterminal.sh kitty -e zsh"))   -- Dropdown Terminal
hl.bind(mainMod .. " + H",       run("hyprsettings"))                                 -- Settings

-- SUPER + Space: Launch or kill Aoiler
hl.bind(mainMod .. " + Space", run(Scripts .. "/Aoiler.sh"))

-- SUPER + A: Hide/show Aoiler (without killing)
hl.bind(mainMod .. " + A", hl.dsp.workspace.toggle_special("aoiler"))

hl.bind(mainMod .. " + ALT + E", panel("emoji"))                             -- Emoji Picker
hl.bind(mainMod .. " + V",       panel("clipboard"))                         -- Clipboard Manager
hl.bind(mainMod .. " + SHIFT + V", run("pavucontrol"))                       -- Audio Control
hl.bind(mainMod .. " + SHIFT + N", panel("notifications"))                   -- Notification Panel
hl.bind(mainMod .. " + N",         panel("connectivity"))                    -- Wi-Fi & Bluetooth
hl.bind(mainMod .. " + ALT + C",   run("hyprpicker -a"))                     -- Color Picker (copies to clipboard)

--/ Screenshots
hl.bind(mainMod .. " + Print",         run_script("ScreenShot.sh full"))     -- Fullscreen Screenshot
hl.bind(mainMod .. " + SHIFT + Print", run_script("ScreenShot.sh window"))   -- Active Window Screenshot
hl.bind(mainMod .. " + SHIFT + S",     run_script("ScreenShot.sh area"))     -- Select Area Screenshot

--/ Workspaces
hl.bind(mainMod .. " + Tab",         hl.dsp.focus({ workspace = "m+1" }))  -- Next Workspace
hl.bind(mainMod .. " + SHIFT + Tab", hl.dsp.focus({ workspace = "m-1" }))  -- Previous Workspace
hl.bind("SUPER + mouse_down", hl.dsp.focus({ workspace = "e+1" }))         -- Scroll to Next Workspace
hl.bind("SUPER + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))         -- Scroll to Previous Workspace

for i = 1, 10 do
    local key = i % 10 -- 10 maps to key 0
    hl.bind("SUPER + " .. key,         hl.dsp.focus({ workspace = i }))
    hl.bind("SUPER + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
    hl.bind("SUPER + CTRL + " .. key,  hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + SHIFT + bracketleft",  hl.dsp.window.move({ workspace = "-1" }))               -- Move Window to Prev Workspace
hl.bind(mainMod .. " + SHIFT + bracketright", hl.dsp.window.move({ workspace = "+1" }))               -- Move Window to Next Workspace
hl.bind(mainMod .. " + CTRL + bracketleft",   hl.dsp.window.move({ workspace = "-1", follow = false }))-- Move Silently to Prev Workspace
hl.bind(mainMod .. " + CTRL + bracketright",  hl.dsp.window.move({ workspace = "+1", follow = false }))-- Move Silently to Next Workspace

--/ Scratchpad
hl.bind(mainMod .. " + U",         hl.dsp.workspace.toggle_special())                              -- Toggle Special Workspace
hl.bind(mainMod .. " + S",         hl.dsp.workspace.toggle_special("magic"))                       -- Toggle Scratchpad
hl.bind(mainMod .. " + ALT + S",   hl.dsp.window.move({ workspace = "special:magic" }))            -- Send Window to Scratchpad

--/ Window Focus (native dispatchers, no hyprctl)
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))         -- Focus Left
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))        -- Focus Right
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))           -- Focus Up
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))         -- Focus Down

hl.bind("ALT + Tab",         hl.dsp.window.cycle_next({ next = true }))      -- Cycle Windows Forward
hl.bind("ALT + SHIFT + Tab", hl.dsp.window.cycle_next({ next = false }))     -- Cycle Windows Backward
hl.bind("CTRL + Tab",        hl.dsp.window.cycle_next({ next = true }))      -- Cycle Through Applications

--/ Window Movement
hl.bind(mainMod .. " + CTRL + left",  hl.dsp.window.move({ direction = "left" }))   -- Move Window Left
hl.bind(mainMod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))  -- Move Window Right
hl.bind(mainMod .. " + CTRL + up",    hl.dsp.window.move({ direction = "up" }))     -- Move Window Up
hl.bind(mainMod .. " + CTRL + down",  hl.dsp.window.move({ direction = "down" }))   -- Move Window Down

-- The next binds use dispatcher names I could not verify (see try_bind above).
try_bind(mainMod .. " + ALT + left",  function() return hl.dsp.window.swap({ direction = "left" }) end)   -- Swap with Left Window
try_bind(mainMod .. " + ALT + right", function() return hl.dsp.window.swap({ direction = "right" }) end)  -- Swap with Right Window
try_bind(mainMod .. " + ALT + up",    function() return hl.dsp.window.swap({ direction = "up" }) end)     -- Swap with Upper Window
try_bind(mainMod .. " + ALT + down",  function() return hl.dsp.window.swap({ direction = "down" }) end)   -- Swap with Lower Window

try_bind(mainMod .. " + SHIFT + left",  function() return hl.dsp.window.resize({ x = -50, y = 0, relative = true }) end, { repeating = true }) -- Resize Left
try_bind(mainMod .. " + SHIFT + right", function() return hl.dsp.window.resize({ x = 50,  y = 0, relative = true }) end, { repeating = true }) -- Resize Right
try_bind(mainMod .. " + SHIFT + up",    function() return hl.dsp.window.resize({ x = 0, y = -50, relative = true }) end, { repeating = true }) -- Resize Up
try_bind(mainMod .. " + SHIFT + down",  function() return hl.dsp.window.resize({ x = 0, y = 50,  relative = true }) end, { repeating = true }) -- Resize Down

--/ Window State
hl.bind(mainMod .. " + SHIFT + SPACE", hl.dsp.window.float({ action = "toggle" }))     -- Toggle Floating
hl.bind(mainMod .. " + ALT + SPACE",   run("hyprctl dispatch workspaceopt allfloat"))  -- Toggle All Float
hl.bind(mainMod .. " + F",             hl.dsp.window.fullscreen())                     -- Toggle Fullscreen
hl.bind(mainMod .. " + CTRL + F",      hl.dsp.window.fullscreen({ mode = 1 }))         -- Fullscreen (Mode 1)
try_bind(mainMod .. " + SHIFT + P",    function() return hl.dsp.window.pin() end)      -- Pin Floating Window (all workspaces)
try_bind(mainMod .. " + SHIFT + C",    function() return hl.dsp.window.center() end)   -- Center Floating Window

--/ Monitors
try_bind(mainMod .. " + comma",         function() return hl.dsp.focus({ monitor = "-1" }) end)                -- Focus Previous Monitor
try_bind(mainMod .. " + period",        function() return hl.dsp.focus({ monitor = "+1" }) end)                -- Focus Next Monitor
try_bind(mainMod .. " + SHIFT + comma", function() return hl.dsp.window.move({ monitor = "-1" }) end)          -- Move Window to Previous Monitor
try_bind(mainMod .. " + SHIFT + period",function() return hl.dsp.window.move({ monitor = "+1" }) end)          -- Move Window to Next Monitor

--/ Groups & Layouts
hl.bind(mainMod .. " + G",          hl.dsp.group.toggle())                    -- Toggle Group
hl.bind(mainMod .. " + CTRL + Tab", hl.dsp.group.next())                      -- Cycle Group Window
try_bind(mainMod .. " + SHIFT + G", function() return hl.dsp.group.prev() end)-- Cycle Group Window Backward
hl.bind(mainMod .. " + CTRL + D",   hl.dsp.layout("removemaster"))            -- Remove Master
hl.bind(mainMod .. " + I",          hl.dsp.layout("addmaster"))               -- Add Master
hl.bind(mainMod .. " + J",          hl.dsp.layout("cyclenext"))               -- Cycle Next Window
hl.bind(mainMod .. " + K",          hl.dsp.layout("cycleprev"))               -- Cycle Prev Window
hl.bind(mainMod .. " + CTRL + Return", hl.dsp.layout("swapwithmaster master"))-- Swap with Master
hl.bind(mainMod .. " + P",          run("hyprctl dispatch pseudo"))           -- Toggle Pseudo Tiling

--/ Mouse
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })  -- Drag to Move
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })  -- Drag to Resize

hl.bind(mainMod .. " + ALT + mouse_down", zoomCursor(2.0))   -- Zoom In Cursor
hl.bind(mainMod .. " + ALT + mouse_up",   zoomCursor(0.5))   -- Zoom Out Cursor

--/ Media
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
