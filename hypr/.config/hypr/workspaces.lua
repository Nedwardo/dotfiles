local TOTAL_WORKSPACES = 10

local function get_ordered_monitors()
	local f = io.popen("hyprctl monitors -j")
	if not f then
		return {}
	end
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

	table.sort(monitors, function(a, b)
		return a.x < b.x
	end)
	return monitors
end
local function distribute_workspaces()
	local monitors = get_ordered_monitors()
	local n = #monitors
	if n == 0 then
		return
	end

	for ws = 1, TOTAL_WORKSPACES do
		hl.workspace_rule({
			workspace = tostring(ws),
			monitor = monitors[(ws - 1) % n + 1].name,
			default = true,
		})
		hl.dispatch(hl.dsp.workspace.move({
			workspace = tostring(ws),
			monitor = monitors[(ws - 1) % n + 1].name,
		}))
	end
end

distribute_workspaces()

hl.on("monitor.added", distribute_workspaces)
hl.on("monitor.removed", distribute_workspaces)
