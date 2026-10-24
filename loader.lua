local hubs = {
	[1802741133] = { name = "Cabin Crew Simulator", url = "https://raw.githubusercontent.com/proxylol/lsdresearch/refs/heads/main/cabincrewsim.lua" },
	[9898409899] = { name = "K2 Climbing", url = "https://raw.githubusercontent.com/proxylol/lsdresearch/refs/heads/main/k2climbing.lua" },
}

if not game:IsLoaded() then
	game.Loaded:Wait()
end

local popup = messagebox or messageboxasync

local function notify(msg, err)
	task.spawn(function()
		if not (popup and pcall(popup, msg, "lsdresearch", err and 0x10 or 0x40)) then
			warn("[lsdresearch] " .. msg)
		end
	end)
end

local hub = hubs[game.GameId]
if not hub then
	local names = {}
	for _, h in pairs(hubs) do
		table.insert(names, h.name)
	end
	table.sort(names)
	notify("This game isn't supported.\nSupported: " .. table.concat(names, ", "), true)
	return
end

local ok, source = pcall(game.HttpGet, game, hub.url)
if not ok or type(source) ~= "string" or source == "" then
	notify("Couldn't download the " .. hub.name .. " script. Check your connection and try again.", true)
	return
end

local fn, compileErr = loadstring(source)
if not fn then
	notify("The " .. hub.name .. " script failed to load:\n" .. tostring(compileErr), true)
	return
end

local ran, runErr = pcall(fn)
if not ran then
	notify("The " .. hub.name .. " script hit an error:\n" .. tostring(runErr), true)
end
