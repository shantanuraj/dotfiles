-- Pull in the wezterm API
local wezterm = require("wezterm")

local act = wezterm.action
local mux = wezterm.mux

--- @param s string
--- @return string
local function basename(s)
	if s == "/" then
		return s
	end
	if string.find(s, "^file://") == nil then
		local res = string.match(s, ".-([^/]+)/$")
		if res then
			return res
		end
	end
	local str = string.gsub(s, "file://[^/]*", "")
	local dirName = string.match(str, "/([^/]+)/?$")
	return dirName or s
end

--- @param workspace string
--- @param cwd string
--- @return string[]
local function set_dir(workspace, cwd)
	return {
		workspace = workspace,
		cwd = cwd,
	}
end

wezterm.on("gui-startup", function()
	local dotfiles_tab, dotfiles_pane, dev_window = mux.spawn_window(set_dir("dev", wezterm.home_dir .. "/.dotfiles"))
	dotfiles_pane:send_text("nvim\n")

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

	dotfiles_tab:activate()

	local app_tab, app_pane, work_window =
		mux.spawn_window(set_dir("REKKI", wezterm.home_dir .. "/dev/rekki/buyer-app"))
	app_pane:send_text("nvim\n")

	app_pane:split({})

	local _, api_pane, _ = work_window:spawn_tab(set_dir("REKKI", wezterm.home_dir .. "/dev/rekki/go"))
	api_pane:send_text("nvim\n")

	api_pane:split({
		cwd = wezterm.home_dir .. "/dev/rekki/go",
	})

	app_tab:activate()
end)

wezterm.on("update-status", function(window)
	local workspace = window:active_workspace()
	local date = wezterm.strftime("%a %b %-d %H:%M")
	window:set_right_status(workspace .. " | 󰃰 " .. date)
end)

--- trim_prefix returns s with the prefix removed.
--- @param s string
--- @param prefix string
--- @return string
local function trim_prefix(s, prefix)
	local len = #s
	local plen = #prefix
	if len == 0 or plen == 0 or len < plen then
		return s
	elseif s == prefix then
		return ""
	elseif string.sub(s, 1, plen) == prefix then
		-- remove prefix
		return string.sub(s, plen + 1)
	end

	return s
end

wezterm.on("format-tab-title", function(tab)
	local pane = tab.active_pane

	if pane.current_working_dir == nil then
		return " " .. pane.title .. " "
	end

	local title = basename(pane.current_working_dir.file_path) or ""

	if title == "" and pane.domain_name then
		title = trim_prefix(pane.domain_name, "SSH to ") .. ":" .. basename(pane.title)
	end
	title = trim_prefix(title, "local:")

	if pane.is_zoomed then
		title = title .. " +"
	end

	return {
		{ Text = " " .. title .. " " },
	}
end)

wezterm.on("user-var-changed", function(window, pane, name, value)
	local overrides = window:get_config_overrides() or {}
	if name == "ZEN_MODE" then
		local incremental = value:find("+")
		local number_value = tonumber(value)
		if incremental ~= nil then
			while number_value > 0 do
				window:perform_action(wezterm.action.IncreaseFontSize, pane)
				number_value = number_value - 1
			end
			overrides.enable_tab_bar = false
		elseif number_value < 0 then
			window:perform_action(wezterm.action.ResetFontSize, pane)
			overrides.font_size = nil
			overrides.enable_tab_bar = true
		else
			overrides.font_size = number_value
			overrides.enable_tab_bar = false
		end
	end
	window:set_config_overrides(overrides)
end)

local function get_appearance()
	if wezterm.gui then
		return wezterm.gui.get_appearance()
	end
	return "Dark"
end

local function colors_for_appearance(appearance)
	if appearance:find("Dark") then
		-- Adapted from https://github.com/mcchrish/zenbones.nvim/blob/main/extras/wezterm/Zenbones_dark.toml
		return {
			foreground = "#B4BDC3",
			background = "#171210",
			cursor_fg = "#1C1917",
			cursor_bg = "#C4CACF",
			cursor_border = "#1C1917",
			selection_fg = "#B4BDC3",
			selection_bg = "#3D4042",
			ansi = { "#1C1917", "#DE6E7C", "#819B69", "#B77E64", "#6099C0", "#B279A7", "#66A5AD", "#B4BDC3" },
			brights = { "#403833", "#E8838F", "#8BAE68", "#D68C67", "#61ABDA", "#CF86C1", "#65B8C1", "#888F94" },
		}
	else
		-- Adapted from https://github.com/mcchrish/zenbones.nvim/blob/main/extras/wezterm/Zenbones_light.toml
		return {
			foreground = "#2C363C",
			background = "#F0EDEC",
			cursor_fg = "#F0EDEC",
			cursor_bg = "#2C363C",
			cursor_border = "#F0EDEC",
			selection_fg = "#2C363C",
			selection_bg = "#CBD9E3",
			ansi = { "#F0EDEC", "#A8334C", "#4F6C31", "#944927", "#286486", "#88507D", "#3B8992", "#2C363C" },
			brights = { "#CFC1BA", "#94253E", "#3F5A22", "#803D1C", "#1D5573", "#7B3B70", "#2B747C", "#4F5E68" },
			tab_bar = {
				background = "#CBD9E3",
				active_tab = {
					bg_color = "#BBABA3",
					fg_color = "#2C363C",
					intensity = "Bold",
				},
				inactive_tab = {
					bg_color = "#CBD9E3",
					fg_color = "#2C363C",
				},
				inactive_tab_hover = {
					bg_color = "#CBD9E3",
					fg_color = "#2C363C",
					italic = true,
				},
			},
		}
	end
end

wezterm.on("window-config-reloaded", function(window)
	local overrides = window:get_config_overrides() or {}
	local appearance = window:get_appearance()
	local colors = colors_for_appearance(appearance)
	if overrides.colors ~= colors then
		overrides.colors = colors
		window:set_config_overrides(overrides)
	end
end)

local config = {}

if wezterm.config_builder then
	config = wezterm.config_builder()
end

config.initial_cols = 160
config.initial_rows = 48
config.default_prog = { "/bin/zsh", "-l" }

config.colors = colors_for_appearance(get_appearance())

config.default_workspace = "dev"
config.font = wezterm.font("Berkeley Mono")
config.term = "wezterm"
config.font_size = 14.0
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.tab_max_width = 24
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
		mods = "SUPER|SHIFT",
		action = act.QuickSelect,
	},
	{
		key = "f",
		mods = "SUPER",
		action = act.Search("CurrentSelectionOrEmptyString"),
	},
	{
		key = "g",
		mods = "SUPER",
		action = act.ActivateCopyMode,
	},
	{ key = "a", mods = "ALT", action = act.ShowLauncher },
	{ key = " ", mods = "ALT", action = act.ShowTabNavigator },
	{ mods = "SUPER", key = "d", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ mods = "SUPER|SHIFT", key = "d", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "[", mods = "SUPER", action = act.ActivatePaneDirection("Prev") },
	{ key = "]", mods = "SUPER", action = act.ActivatePaneDirection("Next") },
	-- maxmize current pane
	{
		key = "Enter",
		mods = "SUPER|SHIFT",
		action = act.TogglePaneZoomState,
	},
	{ key = "UpArrow", mods = "SHIFT", action = act.ScrollToPrompt(-1) },
	{ key = "DownArrow", mods = "SHIFT", action = act.ScrollToPrompt(1) },
}
config.mouse_bindings = {
	{
		event = { Down = { streak = 3, button = "Left" } },
		action = act.SelectTextAtMouseCursor("SemanticZone"),
		mods = "NONE",
	},
}

--- @generic T
--- @param dst T[]
--- @param ... T[]
--- @return T[]
local function list_extend(dst, ...)
	for _, list in ipairs({ ... }) do
		for _, v in ipairs(list) do
			table.insert(dst, v)
		end
	end
	return dst
end

local accept_pattern = {
	Multiple = {
		{ CopyMode = "ClearSelectionMode" },
		{ CopyMode = "AcceptPattern" },
	},
}
local clear_pattern = {
	Multiple = {
		{ CopyMode = "ClearPattern" },
		{ CopyMode = "ClearSelectionMode" },
		{ CopyMode = "AcceptPattern" },
	},
}

local key_tables = wezterm.gui.default_key_tables()

list_extend(key_tables.copy_mode, {
	{ key = "/", action = { Search = { CaseInSensitiveString = "" } } },
	{ key = "n", action = { CopyMode = "NextMatch" } },
	{ key = "n", mods = "SHIFT", action = { CopyMode = "PriorMatch" } },
	{ key = "c", mods = "CTRL", action = clear_pattern },
	{
		key = "y",
		action = {
			Multiple = {
				{ CopyTo = "PrimarySelection" },
				{ CopyMode = "Close" },
			},
		},
	},
	{
		key = "[",
		mods = "NONE",
		action = act.CopyMode("MoveBackwardSemanticZone"),
	},
	{
		key = "]",
		mods = "NONE",
		action = act.CopyMode("MoveForwardSemanticZone"),
	},
})
list_extend(key_tables.search_mode, {
	{ key = "Enter", action = accept_pattern },
	{ key = "c", mods = "CTRL", action = clear_pattern },
})

config.key_tables = key_tables

return config
