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
config.hide_tab_bar_if_only_one_tab = true

config.window_padding = {
    left = 0,
    right = 0,
    top = 0,
    bottom = 0,
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
    ["My Pencil Dark"] = default_scheme,
}
config.color_scheme = "My Pencil Dark"
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

wezterm.on("format-window-title", function(tab, pane, tabs, panes, config)
    local zoomed = " 🗗 "
    if tab.active_pane.is_zoomed then
        zoomed = " 🗖 "
    end

    local index = ""
    if #tabs > 1 then
        index = string.format("[%d/%d] ", tab.tab_index + 1, #tabs)
    end

    return zoomed .. index .. tab.active_pane.title
end)

wezterm.on("update-right-status", function(window, pane)
    local active_workspace = window:active_workspace()
    local name = window:active_key_table()
    if name then
        name = "TABLE: " .. name
    end
    local prompt_status = "Workspace: " .. active_workspace .. " "
    window:set_right_status(prompt_status)
end)

config.keys = {
    -- show launcher
    { key = "l", mods = "ALT",        action = wezterm.action.ShowLauncher },

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
        action = wezterm.action.SplitHorizontal({ domain = "CurrentPaneDomain" }),
    },
    -- Split panel to the donw horizontal.
    {
        key = "-",
        mods = "CTRL|ALT",
        action = wezterm.action.SplitVertical({ domain = "CurrentPaneDomain" }),
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
    { key = "LeftArrow",  mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Left", 5 }) },
    { key = "DownArrow",  mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Down", 5 }) },
    { key = "UpArrow",    mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Up", 5 }) },
    { key = "RightArrow", mods = "LEADER", action = wezterm.action.AdjustPaneSize({ "Right", 5 }) },

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
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = "Constant"
config.cursor_blink_ease_out = "Constant"

return config
