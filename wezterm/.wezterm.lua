local wezterm = require("wezterm")
local act = wezterm.action
local config = {}

config.animation_fps = 60
config.enable_wayland = false
config.front_end = "WebGpu"

config.use_fancy_tab_bar = true
-- config.window_decorations = "INTEGRATED_BUTTONS"
config.window_background_opacity = 0.98
config.audible_bell = "Disabled"
-- config.hide_tab_bar_if_only_one_tab = true
config.scrollback_lines = 3500
config.window_padding = {
	left = 10,
	right = 10,
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
--default_scheme.background = '#212121'
--default_scheme.background = '#2c2e34'
default_scheme.cursor_bg = "#26a269"
default_scheme.cursor_border = "#26a269"
--default_scheme.cursor_fg = '#ffffff'
--default_scheme.selection_fg = 'black'
--default_scheme.selection_bg = '#79C0FF'
--default_scheme.split = '#B694DF'
default_scheme.tab_bar = {
	inactive_tab_edge = "#575757",
	active_tab = {
		bg_color = "#1f1f1f",
		fg_color = "#c0bfbc",
	},
	inactive_tab = {
		bg_color = "#434750",
		fg_color = "#808080",
	},
}

config.color_schemes = {
	["Custom"] = default_scheme,
}
config.color_scheme = "Custom"
--
--
--
--
config.font = wezterm.font({ family = "JetBrainsMono NF", weight = "ExtraLight" })
config.font_size = 12.5
--config.font = wezterm.font { family = 'Fira Code', weight = 'Light' }

config.window_close_confirmation = "NeverPrompt"
config.initial_cols = 180
config.initial_rows = 50

config.scrollback_lines = 10000

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
	local active_workspace = window:active_workspace()
	local name = window:active_key_table()
	if name then
		name = "TABLE: " .. name
	end
	local workspace_prompt = string.format("Workspace: %s %s", active_workspace, name or "")
	window:set_right_status(workspace_prompt)
end)

-- Key bindings
-- See https://wezfurlong.org/wezterm/config/lua/keyassignment/
--
config.leader = { key = ";", mods = "CTRL", timeout_milliseconds = 1000 }

config.keys = {
	-- show launcher
	{ key = "l", mods = "ALT", action = wezterm.action.ShowLauncher },

	-- Switch to the default workspace
	{
		key = "y",
		mods = "CTRL|SHIFT",
		action = act.SwitchToWorkspace({
			name = "default",
		}),
	},

	-- Switch to btop workspace
	{
		key = "b",
		mods = "CTRL|SHIFT",
		action = act.SwitchToWorkspace({
			name = "monitoring",
			spawn = {
				args = { "btop" },
			},
		}),
	},

	-- Create a new workspace with a random name and switch to it
	{ key = "i", mods = "CTRL|SHIFT", action = act.SwitchToWorkspace },
	-- Show the launcher in fuzzy selection mode and have it list all workspaces
	-- and allow activating one.
	{
		key = "9",
		mods = "ALT",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|WORKSPACES",
		}),
	},

	-- Prompt for a name to use for a new workspace and switch to it.
	{
		key = "s",
		mods = "CTRL|SHIFT",
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
			selection_text = window:get_selection_text_for_pane(pane)
			is_selection_active = string.len(selection_text) ~= 0
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
		key = "/",
		mods = "CTRL|ALT",
		action = wezterm.action.SplitPane({
			direction = "Right",
			size = { Percent = 50 },
		}),
	},
	-- Split panel to the down horizontal.
	{
		key = "-",
		mods = "CTRL|ALT",
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
	{ key = "LeftArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
	{ key = "DownArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
	{ key = "UpArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
	{ key = "RightArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },

	-- Move between panes
	{
		key = "LeftArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Left"),
	},
	{
		key = "RightArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Right"),
	},
	{
		key = "UpArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Up"),
	},
	{
		key = "DownArrow",
		mods = "ALT",
		action = act.ActivatePaneDirection("Down"),
	},

	-- New pane
	{
		key = "t",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnCommandInNewTab,
	},

	-- Close pane --
	{
		key = "w",
		mods = "CTRL|SHIFT",
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
		key = "I",
		mods = "CTRL|SHIFT",
		action = wezterm.action.PaneSelect({
			show_pane_ids = true,
		}),
	},
	-- New Window
	{
		key = "n",
		mods = "CTRL|SHIFT",
		action = wezterm.action.SpawnCommandInNewWindow({
			cwd = wezterm.home_dir,
		}),
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
