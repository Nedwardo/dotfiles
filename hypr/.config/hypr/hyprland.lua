-- See https://wiki.hyprland.org/Configuring
-- #################
-- ### Variables ###
-- #################
local hypr_config_dir = os.getenv("HOME") .. "/.config/hypr"
local active_border = "rgba(33ccffee)"
local inactive_border = "rgba(595959aa)"

-- ################
-- ### Monitors ###
-- ################
-- See https://wiki.hyprland.org/Configuring/Monitors/
require("monitors")

-- ###############
-- ### Windows ###
-- ###############
require("window_rules")

-- ##################
-- ### Workspaces ###
-- ##################
require("workspaces")

-- ##################
-- ### Appearance ###
-- ##################
hl.config({
	-- See https://wiki.hyprland.org/Configuring/Variables/#general
	general = {
		gaps_in = 0,
		gaps_out = 0,
		border_size = 1,
		col = {
			active_border = active_border,
			inactive_border = inactive_border,
		},
		resize_on_border = false,
		allow_tearing = false,
		layout = "master",
	},
	-- See https://wiki.hyprland.org/Configuring/Variables/#decoration
	decoration = {
		rounding = 0,
		active_opacity = 1.0,
		inactive_opacity = 1.0,
		blur = {
			enabled = false,
		},
	},
	animations = {
		enabled = false,
	},

	-- See https://wiki.hyprland.org/Configuring/Master-Layout/
	master = {
		new_status = "slave",
		smart_resizing = false,
	},
})

-- See https://wiki.hyprland.org/Configuring/Variables/#misc
hl.config({
	misc = {
		force_default_wallpaper = 0,
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		focus_on_activate = false,
		font_family = "JetBrainsMono Nerd Font",
	},
	ecosystem = {
		no_update_news = true,
	},
})

require("io")
require("keybinds")
