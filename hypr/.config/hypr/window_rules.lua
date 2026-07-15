-- # See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
hl.window_rule({
	name = "prevent maximize",
	match = {
		class = "*",
	},
	fullscreen = false,
})
hl.window_rule({
	name = "waybar spawned",
	match = { initial_class = "com.waybar.spawned.ghostty" },
	float = true,
})
hl.window_rule({
	name = "steam prevent float",
	match = {
		initial_class = "^steam$",
	},
	float = false,
})
hl.window_rule({
	name = "qBittorrent",
	match = {
		class = ".+qBittorrent$",
	},
	workspace = "10 silent",
})
hl.window_rule({
	name = "hexchat",
	match = {
		class = "^Hexchat$",
	},
	workspace = "10 silent",
})
hl.window_rule({
	name = "discord",
	match = {
		initial_class = ".iscord",
	},
	workspace = "2 silent",
})
