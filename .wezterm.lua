-- Pull in the wezterm API
local wezterm = require("wezterm")

local act = wezterm.action
local mux = wezterm.mux

local function basename(s)
	local res = string.gsub(s, "(.*[/\\])(.*)", "%2")
	return res
end

wezterm.on("gui-startup", function()
	local _, _, dev_window = mux.spawn_window({
		workspace = "dev",
		cwd = wezterm.home_dir .. "/.dotfiles",
		args = { "/opt/homebrew/bin/nvim" },
	})

	dev_window:gui_window():toggle_fullscreen()

	dev_window:spawn_tab({
		cwd = wezterm.home_dir .. "/dev/watercooler-labs/toggl-cli",
	})

	dev_window:spawn_tab({
		cwd = wezterm.home_dir .. "/dev/shantanuraj/podcst-web",
	})

	dev_window:spawn_tab({
		cwd = wezterm.home_dir .. "/dev/shantanuraj/sraj.me",
	})

	local _, pane, window = mux.spawn_window({
		workspace = "REKKI",
		args = { "/opt/homebrew/bin/nvim" },
		cwd = wezterm.home_dir .. "/dev/rekki/buyer-app",
	})

	pane:split({
		cwd = wezterm.home_dir .. "/dev/rekki/buyer-app",
	})

	window:spawn_tab({
		cwd = wezterm.home_dir .. "/dev/rekki/go",
	})
end)

wezterm.on("update-right-status", function(window)
	window:set_right_status(window:active_workspace() .. " ")
end)

wezterm.on("format-tab-title", function(tab)
	local pane = tab.active_pane
	local title = basename(pane.current_working_dir)
	return {
		{ Text = " " .. title .. " " },
	}
end)

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.initial_cols = 160
config.initial_rows = 48
config.default_prog = { "/bin/zsh", "-l" }
config.color_scheme = "Catppuccin Mocha"
config.default_workspace = "dev"
config.font = wezterm.font("Berkeley Mono")
config.font_size = 14.0
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.show_tab_index_in_tab_bar = false
config.show_new_tab_button_in_tab_bar = false
config.window_frame = {
	font_size = 14.0,
	-- active_titlebar_bg = "#12131d",
	-- inactive_titlebar_bg = "#1e2030",
}
config.window_padding = {
	left = 0,
	right = 0,
	top = 0,
	bottom = 0,
}
config.bold_brightens_ansi_colors = true
config.keys = {
	{
		key = "w",
		mods = "SUPER",
		action = act.ShowLauncherArgs({
			flags = "FUZZY|WORKSPACES",
		}),
	},
	{
		key = "l",
		mods = "SUPER|SHIFT",
		action = act.SwitchWorkspaceRelative(1),
	},
	{
		key = "r",
		mods = "SUPER|SHIFT",
		action = act.RotatePanes("Clockwise"),
	},
	{
		key = "f",
		mods = "SUPER",
		action = act.Search("CurrentSelectionOrEmptyString"),
	},
	{ key = "a", mods = "ALT", action = wezterm.action.ShowLauncher },
	{ key = " ", mods = "ALT", action = wezterm.action.ShowTabNavigator },
	{ mods = "SUPER", key = "d", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ mods = "SUPER|SHIFT", key = "d", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Left") },
	{ key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Right") },
	{ key = "j", mods = "SUPER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "SUPER", action = act.ActivatePaneDirection("Up") },
	-- maxmize current pane
	{
		key = "Enter",
		mods = "SUPER|SHIFT",
		action = wezterm.action.TogglePaneZoomState,
	},
}

return config
