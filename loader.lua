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

local keyApi
do
	local ok, lib = pcall(function()
		return loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
	end)
	if ok and type(lib) == "table" then
		lib.script_id = hub.url:match("loaders/(%w+)%.lua")
		keyApi = lib
	end
end

local function checkKey(key)
	if type(key) ~= "string" or key == "" then
		return false, "Paste your key first."
	end
	if not keyApi then
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

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Theme = {
	Background = Color3.fromRGB(12, 13, 15),
	Panel = Color3.fromRGB(22, 28, 38),
	Stroke = Color3.fromRGB(52, 66, 89),
	Accent = Color3.fromRGB(152, 181, 255),
	Text = Color3.fromRGB(255, 255, 255),
	SubText = Color3.fromRGB(180, 180, 180),
	Error = Color3.fromRGB(255, 125, 125),
	Success = Color3.fromRGB(140, 220, 160),
}

local Fonts = {
	Bold = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold),
	Regular = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium),
}

local function tween(object, duration, goal)
	local t = TweenService:Create(object, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), goal)
	t:Play()
	return t
end

local function make(className, props, children)
	local object = Instance.new(className)
	for key, value in pairs(props) do
		object[key] = value
	end
	for _, child in ipairs(children or {}) do
		child.Parent = object
	end
	return object
end

local function corner(radius)
	return make("UICorner", { CornerRadius = UDim.new(0, radius) })
end

local function stroke(transparency)
	return make("UIStroke", { Color = Theme.Stroke, Transparency = transparency, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function padding(top, bottom, left, right)
	return make("UIPadding", {
		PaddingTop = UDim.new(0, top),
		PaddingBottom = UDim.new(0, bottom),
		PaddingLeft = UDim.new(0, left),
		PaddingRight = UDim.new(0, right),
	})
end

local function text(props)
	props.BackgroundTransparency = 1
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return make("TextLabel", props)
end

local function row(order, height)
	return make("Frame", {
		LayoutOrder = order,
		Size = UDim2.new(1, 0, 0, height),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 0.5,
	}, { corner(5), stroke(0.6), padding(9, 9, 12, 12) })
end

local function keyWindow(firstMessage)
	local done = Instance.new("BindableEvent")
	local acceptedKey

	local gui = make("ScreenGui", {
		Name = "lsdresearchKey",
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		IgnoreGuiInset = true,
	})
	if not pcall(function()
		gui.Parent = gethui and gethui() or game:GetService("CoreGui")
	end) then
		gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end

	local WIDTH, TOPBAR = 360, 44

	local window = make("CanvasGroup", {
		Size = UDim2.fromOffset(WIDTH, 260),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BackgroundTransparency = 0.05,
		GroupTransparency = 1,
		Parent = gui,
	}, { corner(10), stroke(0.5) })
	local scale = make("UIScale", { Scale = 0.95, Parent = window })

	local topbar = make("TextButton", {
		Size = UDim2.new(1, 0, 0, TOPBAR),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = window,
	})
	local title = text({
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -60, 0, 16),
		FontFace = Fonts.Bold,
		TextSize = 13,
		TextColor3 = Theme.Accent,
		TextTransparency = 0.2,
		Text = "lsdresearch",
		Parent = topbar,
	})
	make("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(155, 155, 155), Color3.fromRGB(255, 255, 255)),
		Parent = title,
	})
	text({
		Position = UDim2.fromOffset(16, 24),
		Size = UDim2.new(1, -60, 0, 12),
		FontFace = Fonts.Regular,
		TextSize = 10,
		TextColor3 = Theme.Text,
		TextTransparency = 0.6,
		Text = hub.name,
		Parent = topbar,
	})

	local close = make("TextButton", {
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(1, -36, 0.5, -11),
		BackgroundColor3 = Theme.Panel,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = topbar,
	}, { corner(5) })
	for _, angle in ipairs({ 45, -45 }) do
		make("Frame", {
			Size = UDim2.fromOffset(12, 2),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = angle,
			BackgroundColor3 = Theme.Text,
			BackgroundTransparency = 0.4,
			Parent = close,
		})
	end
	close.MouseEnter:Connect(function()
		tween(close, 0.25, { BackgroundTransparency = 0.5 })
	end)
	close.MouseLeave:Connect(function()
		tween(close, 0.25, { BackgroundTransparency = 1 })
	end)

	make("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, TOPBAR),
		BackgroundColor3 = Theme.Stroke,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = window,
	})

	local body = make("Frame", {
		Position = UDim2.fromOffset(0, TOPBAR + 1),
		Size = UDim2.new(1, 0, 1, -(TOPBAR + 1)),
		BackgroundTransparency = 1,
		Parent = window,
	}, { padding(12, 14, 14, 14) })
	local list = make("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		Parent = body,
	})

	text({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 14),
		FontFace = Fonts.Bold,
		TextSize = 11,
		TextColor3 = Theme.Accent,
		TextTransparency = 0.3,
		Text = "KEY SYSTEM",
		Parent = body,
	})

	local boxRow = row(2, 38)
	boxRow.Parent = body
	local box = make("TextBox", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		FontFace = Fonts.Regular,
		TextSize = 12,
		TextColor3 = Theme.Text,
		TextXAlignment = Enum.TextXAlignment.Left,
		PlaceholderText = "Paste your key here",
		PlaceholderColor3 = Theme.SubText,
		ClearTextOnFocus = false,
		Text = "",
		Parent = boxRow,
	})
	local boxStroke = boxRow:FindFirstChildOfClass("UIStroke")
	box.Focused:Connect(function()
		tween(boxStroke, 0.3, { Transparency = 0.2, Color = Theme.Accent })
	end)
	box.FocusLost:Connect(function()
		tween(boxStroke, 0.3, { Transparency = 0.6, Color = Theme.Stroke })
	end)

	local function actionRow(order, titleText, descText, pillText, onClick)
		local r = row(order, 46)
		r.Parent = body
		local rowTitle = text({
			Size = UDim2.new(1, -80, 0, 14),
			FontFace = Fonts.Bold,
			TextSize = 12,
			TextColor3 = Theme.Text,
			TextTransparency = 0.15,
			Text = titleText,
			Parent = r,
		})
		text({
			Position = UDim2.fromOffset(0, 15),
			Size = UDim2.new(1, -80, 0, 12),
			FontFace = Fonts.Regular,
			TextSize = 10,
			TextColor3 = Theme.Accent,
			TextTransparency = 0.5,
			Text = descText,
			Parent = r,
		})
		local pill = make("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.85,
			FontFace = Fonts.Bold,
			TextSize = 10,
			TextColor3 = Theme.Accent,
			Text = pillText,
			Parent = r,
		}, { corner(4), padding(0, 0, 8, 8) })
		local hit = make("TextButton", {
			Size = UDim2.fromScale(1, 1),
			BackgroundTransparency = 1,
			Text = "",
			Parent = r,
		})
		hit.MouseEnter:Connect(function()
			tween(rowTitle, 0.3, { TextTransparency = 0 })
			tween(r, 0.3, { BackgroundTransparency = 0.3 })
		end)
		hit.MouseLeave:Connect(function()
			tween(rowTitle, 0.3, { TextTransparency = 0.15 })
			tween(r, 0.3, { BackgroundTransparency = 0.5 })
		end)
		hit.MouseButton1Click:Connect(function()
			pill.BackgroundTransparency = 0.5
			tween(pill, 0.4, { BackgroundTransparency = 0.85 })
			onClick()
		end)
		return pill
	end

	local status = text({
		LayoutOrder = 5,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		FontFace = Fonts.Regular,
		TextSize = 10,
		TextWrapped = true,
		TextColor3 = Theme.Error,
		Text = firstMessage or "",
		Parent = body,
	})

	local function setStatus(message, color)
		status.Text = message
		status.TextColor3 = color
	end

	actionRow(3, "Get Key", "Copies the key link, open it in your browser", "Copy", function()
		if setclipboard then
			setclipboard(KEY_LINK)
			setStatus("Link copied. Open it in your browser to get a key.", Theme.Success)
		else
			setStatus(KEY_LINK, Theme.SubText)
		end
	end)

	local checking = false
	local submitPill
	submitPill = actionRow(4, "Submit", "Checks your key and loads " .. hub.name, "Check", function()
		if checking then
			return
		end
		checking = true
		submitPill.Text = "..."
		setStatus("Checking...", Theme.SubText)
		local key = box.Text:gsub("%s", "")
		local valid, message = checkKey(key)
		if valid then
			acceptedKey = key
			setStatus("Key accepted, loading...", Theme.Success)
			done:Fire()
		else
			setStatus(message, Theme.Error)
		end
		submitPill.Text = "Check"
		checking = false
	end)

	local function fit()
		window.Size = UDim2.fromOffset(WIDTH, TOPBAR + 1 + list.AbsoluteContentSize.Y + 26)
	end
	list:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(fit)
	fit()

	local dragStart, startPos
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart, startPos = input.Position, window.Position
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragStart and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
			local delta = input.Position - dragStart
			window.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragStart = nil
		end
	end)

	close.MouseButton1Click:Connect(function()
		done:Fire()
	end)

	tween(window, 0.5, { GroupTransparency = 0 })
	tween(scale, 0.5, { Scale = 1 })

	done.Event:Wait()

	tween(window, 0.3, { GroupTransparency = 1 })
	tween(scale, 0.3, { Scale = 0.95 }).Completed:Wait()
	gui:Destroy()
	done:Destroy()
	return acceptedKey
end

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
	if not key then
		return
	end
end

saveKey(key)
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
