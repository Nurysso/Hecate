--  _   _ _____ ____    _  _____ _____
-- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
-- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
-- |  _  | |__| |___ / ___ \| | | |___      > ^ <
-- |_| |_|_____\____/_/   \_\_| |_____|
--
-- 🎀 Decoration Configuration
-- -------------------------------------------------
-- 📚 Official Wiki:
--   Window Rules -> https://wiki.hypr.land/Configuring/Variables/
--   dwindle -> https://wiki.hypr.land/Configuring/Dwindle-Layout/
--   Master -> https://wiki.hypr.land/Configuring/Master-Layout/
--💡 Quick Tips:
--   1. Use `rgba(RRGGBBAA)` for colors — last two digits are transparency.
--   2. Borders & background colors can be animated (see animations.conf).
--
--  Syntax ->  windowrule=RULE,PARAMETERS
-- -------------------------------------------------

--------------------------------------------------------------------------------
-- General
--------------------------------------------------------------------------------
hl.config({
    general = {
        col = {
            active_border   = "rgba(F7DCDE39)",
            inactive_border = "rgba(A58A8D30)",
        },
        gaps_in           = 2,
        gaps_out          = 6,
        resize_on_border  = true,
        layout            = "dwindle",
    },
})

--------------------------------------------------------------------------------
-- Layout Tweaks & Cursor
--------------------------------------------------------------------------------
hl.config({
    dwindle = {
        preserve_split       = true,
        special_scale_factor = 0.8,
        -- smart_split       = true,
    },
})

hl.config({
    master = {
        new_status = "master",
        new_on_top = true,
        mfact      = 0.5,
    },
})

--------------------------------------------------------------------------------
-- Rendering & XWayland
--------------------------------------------------------------------------------
hl.config({
    render = {
        direct_scanout = false,
    },
})

hl.config({
    xwayland = {
        enabled            = true,
        force_zero_scaling = true,
    },
})

--------------------------------------------------------------------------------
-- Bind Behavior
--------------------------------------------------------------------------------
hl.config({
    binds = {
        workspace_back_and_forth = true,
        allow_workspace_cycles   = true,
        pass_mouse_when_bound    = false,
    },
})
