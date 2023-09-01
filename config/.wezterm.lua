local wezterm = require("wezterm")
local act = wezterm.action
local config = {}


config.front_end = 'Software'


config.audible_bell = "Disabled"
config.color_scheme = 'Pencil Dark (Gogh)'
config.font = wezterm.font 'Fira Code'
config.window_close_confirmation = 'NeverPrompt'
config.initial_cols = 180
config.initial_rows = 50

config.keys = {
     {
     key = 'c',
     mods = 'CTRL',
     action = wezterm.action_callback(function(window, pane)
         selection_text = window:get_selection_text_for_pane(pane)
         is_selection_active = string.len(selection_text) ~= 0
         if is_selection_active then
             window:perform_action(wezterm.action.CopyTo('ClipboardAndPrimarySelection'), pane)
         else
             window:perform_action(wezterm.action.SendKey{ key='c', mods='CTRL' }, pane)
         end
     end),
     },{
     key = 'v',
     mods = 'CTRL',
     action = wezterm.action_callback(function(window, pane)
         window:perform_action(act.PasteFrom('Clipboard'), pane)
         -- window:perform_action(act.PasteFrom('PrimarySelection'), pane)
     end)
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


return config


