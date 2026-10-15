local hubs = {
	[1802741133] = {
		name = "Cabin Crew Simulator",
		url = "https://api.luarmor.net/files/v4/loaders/89d5ae806ab22a5d80efbe13b41090ae.lua",
	},
	[9898409899] = {
		name = "K2 Climbing",
		url = "https://api.luarmor.net/files/v4/loaders/14ab05bb43ff4bcf9d3801b68d6b495e.lua",
	},
}

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local popup = messagebox or messageboxasync
local ERROR_ICON, INFO_ICON = 0x10, 0x40

local function notify(text, isError)
	task.spawn(function()
		local shown = type(popup) == "function" and pcall(popup, text, "lsdresearch", isError and ERROR_ICON or INFO_ICON)
		if not shown then
			warn("[lsdresearch] " .. text)
		end
	end)
end

local hub = hubs[game.GameId]
if not hub then
	local names = {}
	for _, supported in pairs(hubs) do
		table.insert(names, supported.name)
	end
	table.sort(names)
	notify("This game isn't supported.\nSupported: " .. table.concat(names, ", "), true)
	return
end

local source
for attempt = 1, 3 do
	local ok, result = pcall(game.HttpGet, game, hub.url)
	if ok and type(result) == "string" and #result > 0 then
		source = result
		break
	end
	if attempt < 3 then
		task.wait(attempt)
	end
end

if not source then
	notify("Couldn't reach " .. hub.name .. ". Try again in a moment.", true)
	return
end

local run, compileErr = loadstring(source)
if not run then
	warn("[lsdresearch] " .. tostring(compileErr))
	notify("The " .. hub.name .. " script didn't load. Try again in a moment.", true)
	return
end

local ok, runErr = pcall(run)
if not ok then
	warn("[lsdresearch] " .. tostring(runErr))
	notify(hub.name .. " stopped with an error. Try re-executing.", true)
end