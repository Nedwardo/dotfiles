-- See https://wiki.hyprland.org/Configuring/Binds/
local main_mod = "SUPER"

-- Lock screen
hl.bind(main_mod .. " + L", hl.dsp.exit())

-- Rofi
hl.bind(main_mod .. " + SPACE", hl.dsp.exec_cmd("rofi -show drun"))
hl.bind(main_mod .. " + ALT + SPACE", hl.dsp.exec_cmd("rofi -show window"))

-- Screenshots
hl.bind(
	main_mod .. " + Print",
	hl.dsp.exec_cmd("wayfreeze --after-freeze-cmd 'grim -g \"$(slurp)\" - | wl-copy; killall wayfreeze'")
)

-- Kill and create
hl.bind(main_mod .. " + Q", hl.dsp.exec_cmd("exec $TERMINAL"))
hl.bind(main_mod .. " + W", hl.dsp.window.close())

-- Window Control
hl.bind(main_mod .. " + V", hl.dsp.window.float())
hl.bind(main_mod .. " + F", hl.dsp.window.fullscreen())
hl.bind(main_mod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind(main_mod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

hl.bind(main_mod .. " + CTRL + left", hl.dsp.window.move({ direction = "left" }))
hl.bind(main_mod .. " + CTRL + right", hl.dsp.window.move({ direction = "right" }))
hl.bind(main_mod .. " + CTRL + up", hl.dsp.window.move({ direction = "up" }))
hl.bind(main_mod .. " + CTRL + down", hl.dsp.window.move({ direction = "down" }))

-- Focus Swapping
hl.bind(main_mod .. " + left", hl.dsp.focus({ direction = "left" }))
hl.bind(main_mod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(main_mod .. " + up", hl.dsp.focus({ direction = "up" }))
hl.bind(main_mod .. " + down", hl.dsp.focus({ direction = "down" }))

-- Workspace control
for i = 1, 10 do
	local key = i % 10
	hl.bind(main_mod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(main_mod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i, follow = true }))
	hl.bind(main_mod .. " + CTRL + " .. key, hl.dsp.window.move({ workspace = i, follow = false }))
end

-- Audio
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd('pactl set-sink-volume "@DEFAULT_SINK@" +5%'))
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd('pactl set-sink-volume "@DEFAULT_SINK@" -5%'))
hl.bind("XF86AudioMute", hl.dsp.exec_cmd('pactl set-sink-mute "@DEFAULT_SINK@" toggle'))
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"))
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"))
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"))

-- Misc fn buttons
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s 5%+"))
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("brightnessctl s 5%-"))
