local wezterm = require("wezterm")
local act = wezterm.action
local config = {}

config.animation_fps = 60
-- config.enable_wayland = false
config.front_end = "WebGpu"
config.xcursor_theme = "Adwaita"
-- config.use_fancy_tab_bar = true
config.window_decorations = "INTEGRATED_BUTTONS"
config.window_background_opacity = 0.98
config.audible_bell = "Disabled"
-- config.hide_tab_bar_if_only_one_tab = true

-- Visual bell
config.audible_bell = "Disabled"
config.visual_bell = {
	target = "CursorColor",
	fade_in_function = "EaseIn",
	fade_in_duration_ms = 150,
	fade_out_function = "EaseOut",
	fade_out_duration_ms = 300,
}

config.scrollback_lines = 10000
config.window_padding = {
	left = 5,
	right = 5,
	top = 0,
	bottom = 5,
}
config.quick_select_patterns = {
	"[0-9a-f]{7,40}", -- hashes
	"[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}", -- uuids
	"https?:\\/\\/\\S+",
}

--
--  Color scheme
--

local default_scheme = wezterm.color.get_builtin_schemes()["Sonokai (Gogh)"]

-- Override color scheme
default_scheme.cursor_bg = "#26a269"
default_scheme.cursor_border = "#26a269"
--default_scheme.cursor_fg = '#ffffff'
--default_scheme.selection_fg = 'black'
--default_scheme.selection_bg = '#79C0FF'
--default_scheme.split = '#B694DF'
default_scheme.tab_bar = {
	inactive_tab_edge = "#575757",
	active_tab = {
		bg_color = "#222327",
		fg_color = "#c0bfbc",
	},
	inactive_tab = {
		bg_color = "#414550",
		fg_color = "#808080",
	},
}

config.color_schemes = {
	["Custom"] = default_scheme,
}
config.color_scheme = "Custom"

config.font = wezterm.font({ family = "JetBrainsMono NF", weight = "ExtraLight" })
config.font_size = 12.5
--config.font = wezterm.font { family = 'Fira Code', weight = 'Light' }

config.window_close_confirmation = "NeverPrompt"
config.initial_cols = 180
config.initial_rows = 50

config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.6,
}

-- copied and modified from https://github.com/protiumx/.dotfiles/blob/main/stow/wezterm/.config/wezterm/wezterm.lua
local process_icons = {
	["docker"] = wezterm.nerdfonts.linux_docker,
	["docker-compose"] = wezterm.nerdfonts.linux_docker,
	["psql"] = "󱤢",
	["usql"] = "󱤢",
	["kuberlr"] = wezterm.nerdfonts.linux_docker,
	["ssh"] = wezterm.nerdfonts.md_remote_desktop,
	["ssh-add"] = wezterm.nerdfonts.fa_exchange,
	["kubectl"] = wezterm.nerdfonts.linux_docker,
	["stern"] = wezterm.nerdfonts.linux_docker,
	["nvim"] = wezterm.nerdfonts.linux_neovim,
	["make"] = wezterm.nerdfonts.seti_makefile,
	["node"] = wezterm.nerdfonts.mdi_hexagon,
	["go"] = wezterm.nerdfonts.seti_go,
	["python3"] = "",
	["zsh"] = wezterm.nerdfonts.oct_terminal,
	["bash"] = wezterm.nerdfonts.cod_terminal_bash,
	["btm"] = wezterm.nerdfonts.mdi_chart_donut_variant,
	["htop"] = wezterm.nerdfonts.mdi_chart_donut_variant,
	["cargo"] = wezterm.nerdfonts.dev_rust,
	["sudo"] = wezterm.nerdfonts.fa_hashtag,
	["lazydocker"] = wezterm.nerdfonts.linux_docker,
	["git"] = wezterm.nerdfonts.dev_git,
	["lua"] = wezterm.nerdfonts.seti_lua,
	["wget"] = wezterm.nerdfonts.mdi_arrow_down_box,
	["curl"] = wezterm.nerdfonts.mdi_flattr,
	["gh"] = wezterm.nerdfonts.dev_github_badge,
	["ruby"] = wezterm.nerdfonts.cod_ruby,
	["flatpak"] = "",
}

local function get_current_working_dir(tab)
	local current_dir = tab.active_pane and tab.active_pane.current_working_dir or { file_path = "" }
	local home = os.getenv("HOME")
	local pattern = "^(/[^/]+/[^/]+)(.*/)([^/]+)$"
	local path = string.gsub(current_dir.file_path, pattern, "%1/../%3")
	return string.gsub(path, "^" .. home, "~")
end

local function get_process(tab)
	if not tab.active_pane or tab.active_pane.foreground_process_name == "" then
		return "[?]"
	end

	local process_name = string.gsub(tab.active_pane.foreground_process_name, "(.*[/\\])(.*)", "%2")
	if string.find(process_name, "kubectl") then
		process_name = "kubectl"
	end

	return process_icons[process_name] or string.format("[%s]", process_name)
end

wezterm.on("format-tab-title", function(tab, tabs, panes, config, hover, max_width)
	local background = "#414550"
	local foreground = "#ffffff"

	if tab.is_active then
		background = "#222327"
		foreground = "#ffffff"
	elseif hover then
		background = "#181819"
		foreground = "#ffffff"
	end

	local has_unseen_output = false
	if not tab.is_active then
		for _, pane in ipairs(tab.panes) do
			if pane.has_unseen_output then
				has_unseen_output = true
				break
			end
		end
	end

	local cwd = wezterm.format({
		{ Attribute = { Intensity = "Bold" } },
		{ Text = get_current_working_dir(tab) },
	})

	local title = string.format(" %s  %s  ", get_process(tab), cwd)

	if has_unseen_output then
		return {
			{ Foreground = { Color = "#28719c" } },
			{ Text = title },
		}
	end

	return {
		{ Background = { Color = background } },
		{ Foreground = { Color = foreground } },
		{ Text = title },
	}
end)

wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
	local zoomed = " 🗗 "
	if tab.active_pane.is_zoomed then
		zoomed = " 🗖 "
	end

	local index = ""
	if #tabs > 1 then
		index = string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
	end

	return zoomed .. index .. get_process(tab)
end)

wezterm.on("update-right-status", function(window, pane)
	-- Each element holds the text for a cell in a "powerline" style << fade
	local cells = {}

	local cwd_uri = pane:get_current_working_dir()
	if cwd_uri then
		local hostname = ""
		if type(cwd_uri) == "userdata" then
			-- Running on a newer version of wezterm and we have
			-- a URL object here, making this simple!

			hostname = cwd_uri.host or wezterm.hostname()
		else
			-- an older version of wezterm, 20230712-072601-f4abf8fd or earlier,
			-- which doesn't have the Url object
			cwd_uri = cwd_uri:sub(8)
			local slash = cwd_uri:find("/")
			if slash then
				hostname = cwd_uri:sub(1, slash - 1)
				-- and extract the cwd from the uri, decoding %-encoding
			end
		end
		-- Remove the domain name portion of the hostname
		local dot = hostname:find("[.]")
		if dot then
			hostname = hostname:sub(1, dot - 1)
		end
		if hostname == "" then
			hostname = wezterm.hostname()
		end

		table.insert(cells, hostname)
	end

	-- Workspace entry
	local active_workspace = window:active_workspace()
	local table_name = window:active_key_table()
	-- Active key table
	if table_name then
		table_name = "mode: " .. table_name
		table.insert(cells, table_name or "")
	end

	table.insert(cells, active_workspace)
	-- An entry for each battery (typically 0 or 1 battery)
	for _, b in ipairs(wezterm.battery_info()) do
		table.insert(cells, string.format("%.0f%% ⚡", b.state_of_charge * 100))
	end

	-- The powerline < symbol
	local LEFT_ARROW = utf8.char(0xe0b3)
	-- The filled in variant of the < symbol
	local SOLID_LEFT_ARROW = utf8.char(0xe0b2)

	-- Color palette for the backgrounds of each cell
	local colors = {
		"#222327",
		"#2c2e34",
		"#33353f",
		"#363944",
		"#414550",
	}

	-- Foreground color for the text across the fade
	local text_fg = "#c0c0c0"

	-- The elements to be formatted
	local elements = {}
	-- How many cells have been formatted
	local num_cells = 0

	-- Translate a cell into elements
	local function push(text, is_last)
		local cell_no = num_cells + 1
		table.insert(elements, { Foreground = { Color = text_fg } })
		table.insert(elements, { Background = { Color = colors[cell_no] } })
		table.insert(elements, { Text = " " .. text .. " " })
		if not is_last then
			table.insert(elements, { Foreground = { Color = colors[cell_no + 1] } })
			table.insert(elements, { Text = SOLID_LEFT_ARROW })
		end
		num_cells = num_cells + 1
	end

	while #cells > 0 do
		local cell = table.remove(cells, 1)
		push(cell, #cells == 0)
	end

	window:set_right_status(wezterm.format(elements))
end)

-- Key bindings
-- See https://wezfurlong.org/wezterm/config/lua/keyassignment/
--
config.leader = {
	key = " ",
	mods = "CTRL",
	timeout_milliseconds = 1000,
}

config.keys = {
	-- show launcher
	{ key = "l", mods = "LEADER", action = wezterm.action.ShowLauncher },

	-- Switch to the default workspace
	{
		key = "y",
		mods = "LEADER",
		action = act.SwitchToWorkspace({
			name = "default",
		}),
	},

	-- Switch to btop workspace
	{
		key = "b",
		mods = "LEADER",
		action = act.SwitchToWorkspace({
			name = "monitoring",
			spawn = {
				args = { "btop" },
			},
		}),
	},

	-- Create a new workspace with a random name and switch to it
	{ key = "s", mods = "LEADER", action = act.SwitchToWorkspace },
	-- Show the launcher in fuzzy selection mode and have it list all workspaces
	-- and allow activating one.
	{
		key = "f",
		mods = "LEADER",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|WORKSPACES",
		}),
	},

	-- Prompt for a name to use for a new workspace and switch to it.
	{
		key = "e",
		mods = "LEADER",
		action = act.PromptInputLine({
			description = wezterm.format({
				{ Attribute = { Intensity = "Bold" } },
				{ Foreground = { AnsiColor = "Fuchsia" } },
				{ Text = "Enter name for new workspace" },
			}),
			action = wezterm.action_callback(function(window, pane, line)
				-- line will be `nil` if they hit escape without entering anything
				-- An empty string if they just hit enter
				-- Or the actual line of text they wrote
				if line then
					window:perform_action(
						act.SwitchToWorkspace({
							name = line,
						}),
						pane
					)
				end
			end),
		}),
	},

	-- Copy and Paste key mapping
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local selection_text = window:get_selection_text_for_pane(pane)
			local is_selection_active = string.len(selection_text) ~= 0
			if is_selection_active then
				window:perform_action(wezterm.action.CopyTo("ClipboardAndPrimarySelection"), pane)
			else
				window:perform_action(wezterm.action.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
	{
		key = "v",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			window:perform_action(act.PasteFrom("Clipboard"), pane)
			-- window:perform_action(act.PasteFrom('PrimarySelection'), pane)
		end),
	},

	-- Split panel to the right vetrical.
	{
		key = "\\",
		mods = "LEADER",
		action = wezterm.action.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	-- Split panel to the down horizontal.
	{
		key = "-",
		mods = "LEADER",
		action = wezterm.action.SplitPane({
			direction = "Down",
			size = { Percent = 50 },
		}),
	},

	-- Rotate panes --
	-- See https://wezfurlong.org/wezterm/config/lua/keyassignment/RotatePanes.html --
	{
		key = "LeftArrow",
		mods = "CTRL|SHIFT|SUPER",
		action = wezterm.action.RotatePanes("CounterClockwise"),
	},
	{
		key = "RightArrow",
		mods = "CTRL|SHIFT|SUPER",
		action = wezterm.action.RotatePanes("Clockwise"),
	},

	-- Resize panes
	{
		key = "r",
		mods = "LEADER",
		action = act.ActivateKeyTable({
			name = "resize_pane",
			one_shot = false,
		}),
	},
	-- One move between panes
	-- or use leader + a for multiple moves
	{
		key = "h",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "l",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "k",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "j",
		mods = "LEADER",
		action = act.ActivatePaneDirection("Down"),
	},
	-- CTRL+Space, followed by 'a' will put us in activate-pane
	-- mode until we press some other key or until 1 second (1000ms)
	-- of time elapses
	{
		key = "a",
		mods = "LEADER",
		action = act.ActivateKeyTable({
			name = "activate_pane",
			timeout_milliseconds = 1000,
		}),
	},

	-- New tab
	{
		key = "t",
		mods = "LEADER",
		action = wezterm.action.SpawnCommandInNewTab,
	},

	-- Close tab
	{
		key = "w",
		mods = "LEADER",
		action = wezterm.action.CloseCurrentPane({ confirm = true }),
	},

	-- Zoom --
	{
		key = "z",
		mods = "CTRL|WIN",
		action = wezterm.action.TogglePaneZoomState,
	},
	-- Itentity panel ---
	{
		key = "i",
		mods = "LEADER",
		action = wezterm.action.PaneSelect({
			show_pane_ids = true,
		}),
	},
	-- New Window
	{
		key = "n",
		mods = "LEADER",
		action = wezterm.action.SpawnCommandInNewWindow({
			cwd = wezterm.home_dir,
		}),
	},
}

config.key_tables = {
	-- Defines the keys that are active in our resize-pane mode.
	-- Since we're likely to want to make multiple adjustments,
	-- we made the activation one_shot=false. We therefore need
	-- to define a key assignment for getting out of this mode.
	-- 'resize_pane' here corresponds to the name="resize_pane" in
	-- the key assignments above.
	resize_pane = {
		{ key = "LeftArrow", action = act.AdjustPaneSize({ "Left", 1 }) },
		{ key = "h", action = act.AdjustPaneSize({ "Left", 1 }) },

		{ key = "RightArrow", action = act.AdjustPaneSize({ "Right", 1 }) },
		{ key = "l", action = act.AdjustPaneSize({ "Right", 1 }) },

		{ key = "UpArrow", action = act.AdjustPaneSize({ "Up", 1 }) },
		{ key = "k", action = act.AdjustPaneSize({ "Up", 1 }) },

		{ key = "DownArrow", action = act.AdjustPaneSize({ "Down", 1 }) },
		{ key = "j", action = act.AdjustPaneSize({ "Down", 1 }) },

		-- Cancel the mode by pressing escape
		{ key = "Escape", action = "PopKeyTable" },
	},

	-- Defines the keys that are active in our activate-pane mode.
	-- 'activate_pane' here corresponds to the name="activate_pane" in
	-- the key assignments above.
	activate_pane = {
		{ key = "LeftArrow", action = act.ActivatePaneDirection("Left") },
		{ key = "h", action = act.ActivatePaneDirection("Left") },

		{ key = "RightArrow", action = act.ActivatePaneDirection("Right") },
		{ key = "l", action = act.ActivatePaneDirection("Right") },

		{ key = "UpArrow", action = act.ActivatePaneDirection("Up") },
		{ key = "k", action = act.ActivatePaneDirection("Up") },

		{ key = "DownArrow", action = act.ActivatePaneDirection("Down") },
		{ key = "j", action = act.ActivatePaneDirection("Down") },
	},
}

config.mouse_bindings = {
	{
		event = { Down = { streak = 1, button = "Right" } },
		mods = "NONE",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act({ PasteFrom = "Clipboard" }), pane)
			end
		end),
	},
}

config.window_frame = {
	font_size = 12.0,
	font = wezterm.font({ family = "Fira Code", weight = "Regular" }),
	-- active_titlebar_bg = '#333333',
	-- inactive_titlebar_bg = '#333333',
}

-- Cursor --
config.default_cursor_style = "BlinkingBar"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

return config
