--  _   _ _____ ____    _  _____ _____
-- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
-- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
-- |  _  | |__| |___ / ___ \| | | |___      > ^ <
-- |_| |_|_____\____/_/   \_\_| |_____|
--
-- 🚀 ANIMATIONS CONFIGURATION
-- -----------------------------------------
-- 📚 Wiki: https://wiki.hypr.land/Configuring/Animations/
--          Usage animation = NAME, ONOFF, SPEED, CURVE [,STYLE]
-- 💡 Quick Tips:
--    - Control animation speed, curves, and styles.
--    - Set `animations:enabled = true` to activate.
--    - Use consistent easing for smooth UX.
-- -----------------------------------------

hl.config({
    animations = {
        enabled = true,
    }
})


-- Animation Curves (Bezier)

hl.curve("wind",           { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.05} } })
hl.curve("winIn",          { type = "bezier", points = { {0.1, 1.1},   {0.1, 1.1} } })
hl.curve("winOut",         { type = "bezier", points = { {0.3, -0.3},  {0, 1} } })
hl.curve("liner",          { type = "bezier", points = { {1, 1},       {1, 1} } })

-- Material Design (MD3) style curves
hl.curve("md3_standard",   { type = "bezier", points = { {0.2, 0},     {0, 1} } })
hl.curve("md3_decel",      { type = "bezier", points = { {0.05, 0.7},  {0.1, 1} } })
hl.curve("md3_accel",      { type = "bezier", points = { {0.3, 0},     {0.8, 0.15} } })
hl.curve("md2",            { type = "bezier", points = { {0.4, 0},     {0.2, 1} } })

-- Fun / experimental curves
hl.curve("overshot",       { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.1} } })
hl.curve("crazyshot",      { type = "bezier", points = { {0.1, 1.5},   {0.76, 0.92} } })
hl.curve("hyprnostretch",  { type = "bezier", points = { {0.05, 0.9},  {0.1, 1.0} } })

-- Menu/UI curves
hl.curve("menu_decel",     { type = "bezier", points = { {0.1, 1},     {0, 1} } })
hl.curve("menu_accel",     { type = "bezier", points = { {0.38, 0.04}, {1, 0.07} } })

-- Easing functions
hl.curve("easeInOutCirc",  { type = "bezier", points = { {0.85, 0},    {0.15, 1} } })
hl.curve("easeOutCirc",    { type = "bezier", points = { {0, 0.55},    {0.45, 1} } })
hl.curve("easeOutExpo",    { type = "bezier", points = { {0.16, 1},    {0.3, 1} } })
hl.curve("softAcDecel",    { type = "bezier", points = { {0.26, 0.26}, {0.15, 1} } })


-- Animation Rules

-- Window Animations
hl.animation({ leaf = "windows",          enabled = true, speed = 6,   bezier = "wind",       style = "slide" })
hl.animation({ leaf = "windowsIn",        enabled = true, speed = 6,   bezier = "winIn",      style = "slide" })
hl.animation({ leaf = "windowsOut",       enabled = true, speed = 5,   bezier = "winOut",     style = "slide" })
hl.animation({ leaf = "windowsMove",      enabled = true, speed = 5,   bezier = "wind",       style = "slide" })

-- Borders & Angles
hl.animation({ leaf = "border",           enabled = true, speed = 1,   bezier = "liner" })
hl.animation({ leaf = "borderangle",      enabled = true, speed = 30,  bezier = "liner",      style = "once" })

-- Fade & Layer Animations
hl.animation({ leaf = "fade",             enabled = true, speed = 3,   bezier = "md3_decel" })
hl.animation({ leaf = "layersIn",         enabled = true, speed = 3,   bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "layersOut",        enabled = true, speed = 1.6, bezier = "menu_accel" })
hl.animation({ leaf = "fadeLayersIn",     enabled = true, speed = 2,   bezier = "menu_decel" })
hl.animation({ leaf = "fadeLayersOut",    enabled = true, speed = 4.5, bezier = "menu_accel" })

-- Workspace Transitions
hl.animation({ leaf = "workspaces",       enabled = true, speed = 7,   bezier = "menu_decel", style = "slide" })
hl.animation({ leaf = "workspaces",       enabled = true, speed = 5,   bezier = "wind" })

-- Special Workspace
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,   bezier = "md3_decel",  style = "slidefadevert 15%" })
hl.animation({ leaf = "specialWorkspace", enabled = true, speed = 3,   bezier = "md3_decel",  style = "slidevert" })
