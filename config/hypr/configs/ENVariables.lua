--  _   _ _____ ____    _  _____ _____
-- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
-- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
-- |  _  | |__| |___ / ___ \| | | |___      > ^ <
-- |_| |_|_____\____/_/   \_\_| |_____|
--
-- 🚀 ENVIRONMENT VARIABLES CONFIGURATION
-- -----------------------------------------
-- 📚 Wiki: https://wiki.hypr.land/Configuring/Environment-variables/
--
-- 💡 Quick Tips:
--    - Use this file to define session-wide env variables.
--    - Example: `env = XCURSOR_SIZE,24`
--    - Keep it clean — avoid duplicates!
-- -----------------------------------------

-- Theme EnvVars
hl.env({"QT_QPA_PLATFORMTHEME", "qt5ct"})
hl.env({"QT_WAYLAND_DISABLE_WINDOWDECORATION", "1"})
hl.env({"QT_AUTO_SCRENN_FACTOR", "1"})

-- Toolkit Backend Prefrence
hl.env({"GDK_BACKEND", "wayland", "x11"})
hl.env({"QT_QPA_PLATFORM", "wayland", "xcb"})
hl.env({"SDL_VIDEODRIVER", "wayland", "x11"})
hl.env({"ELECTRON_OZONE_PLATORM_HINT", "auto"})

-- XDG DESKTOP
hl.env({"XDG_CURRENT_DESKTOP", "Hyprland"})
hl.env({"XDG_SESSION_TYPE", "wayland"})
hl.env({"XDG_SESSION_DESKTOP", "Hyprland"})

-- JAVA
hl.env({"_JAVA_AWT_WM_NONREPARENTING", "1"})
