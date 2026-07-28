--  _   _ _____ ____    _  _____ _____
-- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
-- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
-- |  _  | |__| |___ / ___ \| | | |___      > ^ <
-- |_| |_|_____\____/_/   \_\_| |_____|
--
-- 🚀 MONITORS CONFIGURATION
-- -----------------------------------------
-- 📚 Wiki: https://wiki.hypr.land/Configuring/Monitors/
-- syntax monitor = name, resolution, position, scale
-- 💡 Quick Tips:
--    - Define monitor resolutions, scaling, and positions.
--    - Example: `monitor = eDP-1,1920x1080@60,0x0,1`
--    - Ensure names match `hyprctl monitors` output.
-- -----------------------------------------

hl.monitor({
    output = "",
    mode="1920x1080",
    position = "auto",
    scale = 1
})
