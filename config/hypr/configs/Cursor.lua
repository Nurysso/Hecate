--  _   _ _____ ____    _  _____ _____
-- | | | | ____/ ___|  / \|_   _| ____|     /\_/\
-- | |_| |  _|| |     / _ \ | | |  _|      ( o.o )
-- |  _  | |__| |___ / ___ \| | | |___      > ^ <
-- |_| |_|_____\____/_/   \_\_| |_____|
--
-- 🚀 CURSOR CONFIGURATION
-- -----------------------------------------
-- 📚 Wiki: https://wiki.hypr.land/FAQ/#how-do-i-change-me-mouse-cursor
--
-- 💡 Quick Tips:
--    - Customize cursor theme, size, and scaling.
--    - Example:  exec-once=hyprctl setcursor [THEME] [SIZE] t
-- -----------------------------------------

hl.env({
	"XCURSOR_THEME,Vimix-cursors",
	"XCURSOR_SIZE,30",
	"HYPRCURSOR_THEME,Vimix-cursors",
	"HYPRCURSOR_SIZE,30",
})

hl.exec_once("hyprctl setcursor Vimix-cursors 24")
