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

wezterm.on("update-status", function(window)
	local workspace = window:active_workspace()
	local date = wezterm.strftime("%a %b %-d %H:%M")
	local colors = { workspace = "#EABC75", separator = "#665031", date = "#9B8055" }

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

-- Amberglass stays dark regardless of macOS appearance.
-- Keep ANSI slots in sync with .config/nvim/lua/user/amberglass.lua.
local amberglass = {
	foreground = "#D9AA63",
	background = "#15120D",
	cursor_fg = "#15120D",
	cursor_bg = "#FFD393",
	cursor_border = "#FFD393",
	selection_fg = "#D9AA63",
	selection_bg = "#49351D",
	split = "#665031",
	scrollbar_thumb = "#665031",
	ansi = { "#211B12", "#D98267", "#A7AD79", "#E8B461", "#A3A699", "#B49A79", "#9FA889", "#D9AA63" },
	brights = { "#9B8055", "#E99A7D", "#BCC28C", "#FFD393", "#BDC0B1", "#CBB18D", "#B7C09E", "#EABC75" },
	tab_bar = {
		background = "#100E0A",
		active_tab = { bg_color = "#2C2316", fg_color = "#EABC75", intensity = "Bold" },
		inactive_tab = { bg_color = "#100E0A", fg_color = "#9B8055" },
		inactive_tab_hover = { bg_color = "#211B12", fg_color = "#D9AA63" },
		new_tab = { bg_color = "#100E0A", fg_color = "#9B8055" },
		new_tab_hover = { bg_color = "#211B12", fg_color = "#EABC75" },
	},
}

-- Clear colors left by the old appearance handler when hot-reloading.
-- Preserve unrelated overrides (e.g. zen mode), and avoid a reload loop.
wezterm.on("window-config-reloaded", function(window)
	local overrides = window:get_config_overrides() or {}
	if overrides.colors ~= nil then
		overrides.colors = nil
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

config.colors = amberglass
config.default_cursor_style = "SteadyBlock"
config.window_background_opacity = 1.0
config.text_background_opacity = 1.0
config.inactive_pane_hsb = { saturation = 1.0, brightness = 0.9 }

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
	active_titlebar_bg = "#100E0A",
	inactive_titlebar_bg = "#100E0A",
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
