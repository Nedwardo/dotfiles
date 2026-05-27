# See https://wiki.hyprland.org/Configuring/Window-Rules/ for more
hl.window_rule({
	name="prevent maximize",
	match = {
		class= "*"
	},
	fullscreen=false
})
hl.window_rule({
	name="volume control float",
	match = {
		initial_class = "^com\\.saivert\\.pwvucontrol$"
	},
	float = true
})
hl.window_rule({
	name="steam prevent float",
	match = {
		initial_class = "^steam$"
	},
	float = false
})
hl.window_rule({
	name="qBittorrent",
	match = {
		class = ".+qBittorrent$"
	},
	workspace = "10 silent"
})
hl.window_rule({
	name="hexchat",
	match = {
		class = "Hexchat$"
	},
	workspace = "10 silent",
	float = false
})
