-- Pull in the wezterm API
local wezterm = require("wezterm")

local act = wezterm.action
local mux = wezterm.mux

--- @param path string
--- @return string
local function basename(path)
	if path == nil or path == "" then
		return ""
	end

	path = tostring(path):gsub("^%a[%w+.-]*://[^/]*", ""):gsub("/$", "")

	if path == "" then
		return "/"
	end

	return path:match("([^/]+)$") or path
end

local startup_windows = {
	{
		workspace = "dev",
		fullscreen = true,
		tabs = {
			{ cwd = wezterm.home_dir .. "/.dotfiles", send_text = "nvim\n", activate = true },
			{ cwd = wezterm.home_dir .. "/dev/watercooler-labs/toggl-cli" },
			{ cwd = wezterm.home_dir .. "/dev/shantanuraj/podcst-web" },
			{ cwd = wezterm.home_dir .. "/dev/shantanuraj/sraj.me" },
		},
	},
	{
		workspace = "REKKI",
		tabs = {
			{
				cwd = wezterm.home_dir .. "/dev/rekki/buyer-app",
				send_text = "nvim\n",
				splits = { {} },
				activate = true,
			},
			{
				cwd = wezterm.home_dir .. "/dev/rekki/go",
				send_text = "nvim\n",
				splits = {
					{ cwd = wezterm.home_dir .. "/dev/rekki/go" },
				},
			},
		},
	},
}

local function spawn_startup_window(spec)
	local first_tab = spec.tabs[1]
	local tab, pane, window = mux.spawn_window({
		workspace = spec.workspace,
		cwd = first_tab.cwd,
	})
	local active_tab = first_tab.activate and tab or nil

	local function configure_tab(tab_spec, current_tab, current_pane)
		if tab_spec.send_text then
			current_pane:send_text(tab_spec.send_text)
		end

		for _, split in ipairs(tab_spec.splits or {}) do
			current_pane:split(split)
		end

		if tab_spec.activate then
			active_tab = current_tab
		end
	end

	configure_tab(first_tab, tab, pane)

	if spec.fullscreen then
		window:gui_window():toggle_fullscreen()
	end

	for i = 2, #spec.tabs do
		local tab_spec = spec.tabs[i]
		local next_tab, next_pane = window:spawn_tab({
			workspace = spec.workspace,
			cwd = tab_spec.cwd,
		})
		configure_tab(tab_spec, next_tab, next_pane)
	end

	if active_tab then
		active_tab:activate()
	end
end

wezterm.on("gui-startup", function()
	for _, spec in ipairs(startup_windows) do
		spawn_startup_window(spec)
	end
end)

local function status_colors_for_appearance(appearance)
	if appearance:find("Dark") then
		return {
			workspace = "#819B69",
			separator = "#888F94",
			date = "#B279A7",
		}
	end

	return {
		workspace = "#4F6C31",
		separator = "#4F5E68",
		date = "#88507D",
	}
end

wezterm.on("update-status", function(window)
	local workspace = window:active_workspace()
	local date = wezterm.strftime("%a %b %-d %H:%M")
	local colors = status_colors_for_appearance(window:get_appearance())

	window:set_right_status(wezterm.format({
		{ Foreground = { Color = colors.workspace } },
		{ Text = workspace },
		{ Foreground = { Color = colors.separator } },
		{ Text = " | " },
		{ Foreground = { Color = colors.date } },
		{ Text = date .. " " },
	}))
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

local local_hostname = wezterm.hostname()

local function clean_host(host)
	if host == nil or host == "" then
		return nil
	end

	host = trim_prefix(host, "SSH to ")
	host = trim_prefix(host, "ssh://")
	host = host:gsub("/.*$", ""):gsub("^.*@", "")

	if host == "" or host == "local" or host == "local:" or host == "localhost" then
		return nil
	end

	return host
end

local function host_stem(host)
	if host == nil then
		return nil
	end

	return host:lower():match("^[^.]+") or host:lower()
end

local function is_local_host(host)
	local candidate = host_stem(host)
	local local_candidate = host_stem(local_hostname)
	return candidate ~= nil and local_candidate ~= nil and candidate == local_candidate
end

local function pane_host(pane)
	local cwd_host = pane.current_working_dir and clean_host(pane.current_working_dir.host)
	if cwd_host and not is_local_host(cwd_host) then
		return cwd_host
	end

	return clean_host(pane.domain_name)
end

wezterm.on("format-tab-title", function(tab)
	local pane = tab.active_pane
	local title = basename(pane.current_working_dir and pane.current_working_dir.file_path or pane.title)
	local host = pane_host(pane)

	if title == "" then
		title = basename(pane.title)
	end

	if host then
		title = host .. ":" .. title
	else
		title = trim_prefix(title, "local:")
	end

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
			tab_bar = {
				background = "#1C1917",
				active_tab = {
					bg_color = "#403833",
					fg_color = "#C4CACF",
					intensity = "Bold",
				},
				inactive_tab = {
					bg_color = "#1C1917",
					fg_color = "#888F94",
				},
				inactive_tab_hover = {
					bg_color = "#3D4042",
					fg_color = "#B4BDC3",
					italic = true,
				},
			},
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

config.enable_kitty_keyboard = true
config.macos_fullscreen_extend_behind_notch = true
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
config.bold_brightens_ansi_colors = false
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
