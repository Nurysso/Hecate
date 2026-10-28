hl.config({
    general = { border_size = 3, gaps_in = 7, col = { active_border = "rgba(33ccffee)" } },
    decoration = { rounding = "big" },
})
hl.config({ ["decoration.blur.enabled"] = false, bogus = { x = 1 } })
require("mods.extra")
print(os.getenv("HOME"))
function later() hl.config({ general = { layout = "master" } }) end

local function try_bind(keys, dsp) pcall(hl.bind, keys, dsp) end

--/ Apps
hl.bind("SUPER + Q", hl.dsp.window.close()) -- Close it
hl.bind("SUPER + T", hl.dsp.exec_cmd("kitty --x"), { locked = true })
try_bind("SUPER + P", hl.dsp.exec_cmd("p"))
try_bind("SUPER + O", hl.dsp.exec_cmd("o"))

--/ Workspaces
for i = 1, 2 do hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i })) end
hl.bind("SUPER + F", function() end)
local z = hl.bind("SUPER + Z", hl.dsp.exit())
z:unbind()
hl.bind("SUPER + X", hl.dsp.exit())
hl.unbind("SUPER + X")

hl.curve("c", { type = "bezier", points = { {0, 1}, {1, 0} } })
hl.curve("s", { type = "spring", mass = 1, stiffness = 80, damping = 12 })
hl.curve("c", { type = "bezier", points = { {0.1, 1.1}, {0.3, -0.3} } })
