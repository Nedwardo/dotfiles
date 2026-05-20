hl.monitor({
	output = "desc: ViewSonic Corporation VX2458-mhd",
	mode = "1920x1080@144",
	position = "0x0",
	scale = 1,
})
hl.monitor({ output = "desc: HP Inc. HP E233 CNC0261JJL", mode = "1920x1080@60", position = "1920x0", scale = 1 })
hl.monitor({ output = "desc: Hisense Electric Co. Ltd.", mode = "4096x2160@60.00Hz", position = "0x0", scale = 2.0 })
hl.monitor({ output = "desc: LG Electronics LG TV", mode = "4096x2160@60.00Hz", position = "0x0", scale = 2 })

for i = 1, 5 do
	hl.workspace_rule({
		workspace = "" .. i * 2 - 1,
		monitor = "desc: ViewSonic Corporation VX2458-mhd",
		default = true,
	})
	hl.workspace_rule({ workspace = "" .. i * 2, monitor = "desc: HP Inc. HP E233 CNC0261JJL", default = true })
end
