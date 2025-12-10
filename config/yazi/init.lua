-- Full border for a cleaner look
require("full-border"):setup({
	type = ui.Border.ROUNDED,
})

-- Git integration
require("git"):setup()

-- Starship prompt integration
local starship_ok = pcall(require, "starship")
if starship_ok then
	require("starship"):setup()
end

-- Custom linemode showing size and mtime
function Linemode:size_and_mtime()
	local time = math.floor(self._file.cha.mtime or 0)
	local time_str = ""

	if time == 0 then
		time_str = ""
	elseif os.date("%Y", time) == os.date("%Y") then
		time_str = os.date("%b %d %H:%M", time)
	else
		time_str = os.date("%b %d  %Y", time)
	end

	local size = self._file:size()
	local size_str = size and ya.readable_size(size) or "-"

	return string.format("%s %s", size_str, time_str)
end

-- Git status linemode
function Linemode:git()
	local git_status = self._file:git()
	if not git_status then
		return ""
	end

	local symbols = {
		[" M"] = " •",  -- Modified
		["M "] = " ✓",  -- Staged modified
		["MM"] = " ±",  -- Modified and staged
		["A "] = " +",  -- Added
		["AA"] = " +",  -- Added
		["??"] = " ?",  -- Untracked
		["D "] = " -",  -- Deleted
		[" D"] = " -",  -- Deleted
		["R "] = " →",  -- Renamed
		["C "] = " ©",  -- Copied
	}

	return symbols[git_status] or git_status
end

-- Smart enter: open files or directories intelligently
function smart_enter()
	local hovered = cx.active.current.hovered
	if not hovered then
		return
	end

	if hovered.cha.is_dir then
		ya.manager_emit("enter", {})
	else
		ya.manager_emit("open", {})
	end
end


-- Enhanced file type detection for better previews
local function get_file_type(path)
	local ext = path:match("^.+%.(.+)$")
	if not ext then
		return "file"
	end

	local dev_exts = {
		go = "go",
		rs = "rust",
		ts = "typescript",
		tsx = "react",
		jsx = "react",
		js = "javascript",
		py = "python",
		rb = "ruby",
		c = "c",
		cpp = "cpp",
		h = "header",
		md = "markdown",
		json = "json",
		yaml = "yaml",
		yml = "yaml",
		toml = "toml",
		sh = "shell",
	}

	return dev_exts[ext:lower()] or ext
end

-- ===== CUSTOM STATUS LINE =====

function Status:name()
	local h = self._tab.current.hovered
	if not h then
		return ui.Line {}
	end

	local linked = ""
	if h.link_to then
		linked = " -> " .. tostring(h.link_to)
	end

	return ui.Line(" " .. h.name .. linked)
end

-- Enhanced status showing Git branch
function Status:mode()
	local mode = tostring(self._tab.mode):upper()
	if mode == "UNSET" then
		mode = "NORMAL"
	end

	local style = self:style()
	return ui.Line {
		ui.Span(" " .. mode .. " "):style(style),
	}
end

-- Show Git branch in status bar
function Status:git_branch()
	local cwd = tostring(self._tab.current.cwd)
	local handle = io.popen("git -C " .. cwd .. " branch --show-current 2>/dev/null")
	if not handle then
		return ui.Line {}
	end

	local branch = handle:read("*a"):gsub("\n", "")
	handle:close()

	if branch == "" then
		return ui.Line {}
	end

	return ui.Line {
		ui.Span(" "):fg("blue"),
		ui.Span(" " .. branch .. " "):fg("blue"),
	}
end


-- Display helpful shortcuts on startup
ya.notify({
	title = "Yazi Dev Setup",
	content = [[
Welcome! Quick shortcuts:
• ff - Find files (fzf)
• gg - Open lazygit
• ov - Open in VS Code
• z  - Jump (zoxide)
• ?  - Show all shortcuts
	]],
	timeout = 5,
	level = "info",
})

-- ===== PERFORMANCE OPTIMIZATIONS =====

-- Disable animations for better performance (optional)
-- Status.render = function()
--   return {}
-- end

-- ===== UTILITY FUNCTIONS =====

-- Quick function to copy current path
function copy_current_path()
	local h = cx.active.current.hovered
	if not h then
		return
	end

	ya.clipboard(tostring(h.url))
	ya.notify({
		title = "Path Copied",
		content = tostring(h.url),
		timeout = 2,
	})
end

-- Function to count files in directory
function count_files()
	local cwd = tostring(cx.active.current.cwd)
	local handle = io.popen("find " .. cwd .. " -maxdepth 1 -type f | wc -l")
	if not handle then
		return
	end

	local count = handle:read("*a"):gsub("\n", "")
	handle:close()

	ya.notify({
		title = "File Count",
		content = count .. " files in current directory",
		timeout = 2,
	})
end

-- ===== DEVELOPMENT HELPERS =====

-- Auto-detect project type and provide hints
function detect_project_type()
	local cwd = tostring(cx.active.current.cwd)
	local files = {
		["go.mod"] = "Go project",
		["package.json"] = "Node.js project",
		["Cargo.toml"] = "Rust project",
		["requirements.txt"] = "Python project",
		["Gemfile"] = "Ruby project",
		["Makefile"] = "C/C++ project",
	}

	for file, proj_type in pairs(files) do
		local f = io.open(cwd .. "/" .. file, "r")
		if f then
			f:close()
			ya.notify({
				title = "Project Detected",
				content = proj_type,
				timeout = 2,
			})
			return
		end
	end
end

-- Run on directory change
-- detect_project_type()
