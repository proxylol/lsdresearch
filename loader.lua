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

-- key system

local KEY_LINK = "https://ads.luarmor.net/get_key?for=Lootlabs-osbeSQDHFyMg"
local KEY_FOLDER = "lsdresearch"
local KEY_FILE = KEY_FOLDER .. "/key.txt"

local keyMessages = {
	KEY_EXPIRED = "Your key expired. Get a new one.",
	KEY_HWID_LOCKED = "This key is locked to another device. Reset it in the Discord.",
	KEY_INCORRECT = "That key doesn't exist. Check you copied all of it.",
	KEY_INVALID = "That doesn't look like a key.",
	KEY_BANNED = "This key has been blacklisted.",
}

local function readSavedKey()
	local ok, key = pcall(function()
		return isfile(KEY_FILE) and readfile(KEY_FILE)
	end)
	return ok and type(key) == "string" and key:gsub("%s", "") or nil
end

local function saveKey(key)
	pcall(function()
		if not isfolder(KEY_FOLDER) then
			makefolder(KEY_FOLDER)
		end
		writefile(KEY_FILE, key)
	end)
end

local function forgetKey()
	pcall(function()
		if isfile(KEY_FILE) then
			delfile(KEY_FILE)
		end
	end)
end

-- Luarmor's key check library tells us why a key is bad without kicking the player
local keyApi
do
	local ok, lib = pcall(function()
		return loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
	end)
	if ok and type(lib) == "table" then
		-- keys work for every script in the project, so this game's script id is enough to check them
		lib.script_id = hub.url:match("loaders/(%w+)%.lua")
		keyApi = lib
	end
end

-- returns true, or false plus a message for the player
local function checkKey(key)
	if type(key) ~= "string" or key == "" then
		return false, "Paste your key first."
	end
	if not keyApi then
		-- couldn't reach the checker; let Luarmor's own check decide when the script loads
		return true
	end
	local ok, status = pcall(keyApi.check_key, key)
	if not ok or type(status) ~= "table" then
		return false, "Couldn't check the key. Try again."
	end
	if status.code == "KEY_VALID" then
		return true
	end
	return false, keyMessages[status.code] or tostring(status.message)
end

local function keyWindow(firstMessage)
	local done = Instance.new("BindableEvent")
	local acceptedKey

	local gui = Instance.new("ScreenGui")
	gui.Name = "lsdresearchKey"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local ok = pcall(function()
		gui.Parent = gethui and gethui() or game:GetService("CoreGui")
	end)
	if not ok then
		gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end

	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(340, 190)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BackgroundColor3 = Color3.fromRGB(24, 24, 30)
	frame.BorderSizePixel = 0
	frame.Parent = gui
	Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)

	local function label(text, y, size, color)
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(1, -32, 0, size + 6)
		l.Position = UDim2.fromOffset(16, y)
		l.Font = Enum.Font.GothamMedium
		l.TextSize = size
		l.TextColor3 = color
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextWrapped = true
		l.Text = text
		l.Parent = frame
		return l
	end

	label("lsdresearch", 14, 18, Color3.fromRGB(240, 240, 245))
	label("Enter your key to load " .. hub.name, 38, 13, Color3.fromRGB(150, 150, 165))

	local box = Instance.new("TextBox")
	box.Size = UDim2.new(1, -32, 0, 36)
	box.Position = UDim2.fromOffset(16, 66)
	box.BackgroundColor3 = Color3.fromRGB(36, 36, 44)
	box.BorderSizePixel = 0
	box.Font = Enum.Font.Gotham
	box.TextSize = 14
	box.TextColor3 = Color3.fromRGB(235, 235, 240)
	box.PlaceholderText = "Paste your key here"
	box.PlaceholderColor3 = Color3.fromRGB(110, 110, 125)
	box.ClearTextOnFocus = false
	box.Text = ""
	box.Parent = frame
	Instance.new("UICorner", box).CornerRadius = UDim.new(0, 6)

	local status = label(firstMessage or "", 108, 12, Color3.fromRGB(240, 110, 110))

	local function button(text, x, color)
		local b = Instance.new("TextButton")
		b.Size = UDim2.new(0.5, -20, 0, 34)
		b.Position = UDim2.new(x, x == 0 and 16 or 4, 0, 140)
		b.BackgroundColor3 = color
		b.BorderSizePixel = 0
		b.Font = Enum.Font.GothamMedium
		b.TextSize = 14
		b.TextColor3 = Color3.fromRGB(255, 255, 255)
		b.Text = text
		b.AutoButtonColor = true
		b.Parent = frame
		Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
		return b
	end

	local getKey = button("Get Key", 0, Color3.fromRGB(60, 60, 75))
	local submit = button("Submit", 0.5, Color3.fromRGB(88, 101, 242))

	getKey.MouseButton1Click:Connect(function()
		if setclipboard then
			setclipboard(KEY_LINK)
			status.TextColor3 = Color3.fromRGB(120, 200, 140)
			status.Text = "Link copied. Open it in your browser to get a key."
		else
			status.TextColor3 = Color3.fromRGB(150, 150, 165)
			status.Text = KEY_LINK
		end
	end)

	local checking = false
	submit.MouseButton1Click:Connect(function()
		if checking then
			return
		end
		checking = true
		local key = box.Text:gsub("%s", "")
		status.TextColor3 = Color3.fromRGB(150, 150, 165)
		status.Text = "Checking..."
		local valid, message = checkKey(key)
		if valid then
			acceptedKey = key
			done:Fire()
		else
			status.TextColor3 = Color3.fromRGB(240, 110, 110)
			status.Text = message
		end
		checking = false
	end)

	done.Event:Wait()
	gui:Destroy()
	done:Destroy()
	return acceptedKey
end

-- a key set above the loadstring wins, then the one saved last time, then we ask
local candidates = {}
if type(script_key) == "string" and script_key ~= "" then
	table.insert(candidates, script_key)
end
local saved = readSavedKey()
if saved and saved ~= "" then
	table.insert(candidates, saved)
end

local key, reason
for _, candidate in ipairs(candidates) do
	local valid, message = checkKey(candidate)
	if valid then
		key = candidate
		break
	end
	reason = message
end

if not key then
	forgetKey()
	key = keyWindow(reason)
end

saveKey(key)
-- the Luarmor loader reads the key from this global
local env = getgenv and getgenv() or _G
env.script_key = key
script_key = key

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
