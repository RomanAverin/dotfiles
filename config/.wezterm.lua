local wezterm = require("wezterm")
local act = wezterm.action
local config = {}


--local gpus = wezterm.gui.enumerate_gpus()
--config.front_end = 'Software'
config.animation_fps = 60

--config.front_end = 'WebGpu'
--config.webgpu_preferred_adapter = gpus[2]
config.enable_wayland = true

config.use_fancy_tab_bar = true
config.audible_bell = "Disabled"
config.color_scheme = 'Pencil Dark (Gogh)'
--config.color_scheme = 'Relaxed (Gogh)'
--config.font = wezterm.font { family = 'Fira Code', weight = 'Light' }
config.font = wezterm.font { family = 'Fira Mono' }
config.window_close_confirmation = 'NeverPrompt'
config.initial_cols = 180
config.initial_rows = 50

config.inactive_pane_hsb = {
    saturation = 0.9,
    brightness = 0.6,
}

wezterm.on('format-window-title', function(tab, pane, tabs, panes, config)
  local zoomed = ' 🗗 '
  if tab.active_pane.is_zoomed then
    zoomed = ' 🗖 '
  end

  local index = ''
  if #tabs > 1 then
    index = string.format('[%d/%d] ', tab.tab_index + 1, #tabs)
  end

  return zoomed .. index .. tab.active_pane.title
end)

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

     -- Split panel to the right.
    {
      key = 'r',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.SplitHorizontal { domain = 'CurrentPaneDomain' },
    },
    {
      key = 'd',
      mods = 'CTRL|SHIFT',
      action = wezterm.action.SplitVertical { domain = 'CurrentPaneDomain' },
    },
    {
      key = 'r',
      mods= 'CTRL|SHIFT|SUPER',
      action = wezterm.action.SplitPane {
        direction = 'Right',
        top_level = true
      }
    },
    {
      key = 'd',
      mods= 'CTRL|SHIFT|SUPER',
      action = wezterm.action.SplitPane {
        direction = 'Down',
        top_level = true
      },
    },
    -- Rotate panes --
    -- See https://wezfurlong.org/wezterm/config/lua/keyassignment/RotatePanes.html --
    {
      key = 'LeftArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = wezterm.action.RotatePanes 'CounterClockwise',
    },
    {
      key = 'RightArrow',
      mods = 'CTRL|SHIFT|SUPER',
      action = wezterm.action.RotatePanes 'Clockwise',
    },
    { key = 'LeftArrow', mods = 'LEADER', action = wezterm.action.AdjustPaneSize { 'Left', 5 } },
    { key = 'DownArrow', mods = 'LEADER', action = wezterm.action.AdjustPaneSize { 'Down', 5 } },
    { key = 'UpArrow', mods = 'LEADER', action = wezterm.action.AdjustPaneSize { 'Up', 5 } },
    { key = 'RightArrow', mods = 'LEADER', action = wezterm.action.AdjustPaneSize { 'Right', 5 } },

    -- Close pane --
    {
        key = 'w',
        mods =  'CTRL',
        action = wezterm.action.CloseCurrentPane { confirm = true }
    },

    -- Zoom --
    {
		key = 'z',
		mods = 'CTRL|WIN',
		action = wezterm.action.TogglePaneZoomState,
	},
    -- Itentity panel ---
    {
		key = "I",
		mods = "CTRL",
		action = wezterm.action.PaneSelect({
            show_pane_ids = true,
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
    font = wezterm.font { family = 'Fira Code', weight = 'Medium' },
  -- active_titlebar_bg = '#333333',
  -- inactive_titlebar_bg = '#333333',
}

-- Cursor --
config.default_cursor_style = "BlinkingBlock"
config.cursor_blink_rate = 500
config.cursor_blink_ease_in = 'Constant'
config.cursor_blink_ease_out = 'Constant'

-- Colors --
config.colors = {
    cursor_bg = '#52ad70',
    -- Overrides the text color when the current cell is occupied by the cursor
    cursor_fg = 'black',
    -- Specifies the border color of the cursor when the cursor style is set to Block,
    -- or the color of the vertical or horizontal bar when the cursor style is set to
    -- Bar or Underline.
    cursor_border = '#52ad70',


   	selection_fg = 'black',
	selection_bg = '#79C0FF',
    split = '#B694DF',
    tab_bar = {
        -- The color of the inactive tab bar edge/divider
        inactive_tab_edge = '#575757',

        active_tab = {
            -- The color of the background area for the tab
            bg_color = '#1f1f1f',
            -- The color of the text for the tab
            fg_color = '#c0bfbc',
        },
        inactive_tab = {
            bg_color = '#434750',
            fg_color = '#808080',
        },


  },

}

return config


