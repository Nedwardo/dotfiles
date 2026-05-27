local left_main ="desc: ViewSonic Corporation VX2458-mhd" 
local right_main = "desc: HP Inc. HP E233 CNC0261JJL"
local laptop = "desc: AU Optronics 0xD291"
local tv = "desc: Hisense Electric Co. Ltd."
local other_tv = "desc: LG Electronics LG TV"
local TOTAL_WORKSPACES = 10


hl.monitor({
	output = left_main,
	mode = "1920x1080@144",
	position = "0x0",
	scale = 1,
})
hl.monitor({ output = right_main, mode = "1920x1080@60", position = "1920x0", scale = 1 })
hl.monitor({ output = laptop, mode = "1920x1200@60", position = "1920x0", scale = 1 })
hl.monitor({ output = tv, mode = "4096x2160@60.00Hz", position = "0x0", scale = 2.0 })
hl.monitor({ output = other_tv, mode = "4096x2160@60.00Hz", position = "0x0", scale = 2 })

local function get_ordered_monitors()
	local f = io.popen("hyprctl monitors -j")
	if not f then return {} end
	local raw = f:read("*a")
	f:close()

	local monitors = {}
	for entry in raw:gmatch("{[^{}]+}") do
		local name = entry:match('"name"%s*:%s*"([^"]+)"')
		local x = entry:match('"x"%s*:%s*(%-?%d+)')
		if name and x then
		monitors[#monitors + 1] = { name = name, x = tonumber(x) }
		end
	end

	table.sort(monitors, function(a, b) return a.x < b.x end)
	return monitors
end
local function distribute_workspaces()
	local monitors = get_ordered_monitors()
	local n = #monitors
	if n == 0 then return end


	for ws = 1, TOTAL_WORKSPACES do
		hl.dispatch(hl.dsp.workspace.move_to_monitor({
			workspace = tostring(ws),
			monitor = monitors[( ws -1 ) % n + 1].name
		}))
	end
end

distribute_workspaces()

hl.on("monitor.added",   distribute_workspaces )
hl.on("monitor.removed", distribute_workspaces )
-- for i = 1, 5 do
-- 	hl.workspace_rule({
-- 		workspace = "" .. i * 2 - 1,
-- 		monitor = "desc: ViewSonic Corporation VX2458-mhd",
-- 		default = true,
-- 	})
-- 	hl.workspace_rule({ workspace = "" .. i * 2, monitor = "desc: HP Inc. HP E233 CNC0261JJL", default = true })
-- end
