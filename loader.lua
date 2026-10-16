-- v2
local hubs = {
	[1802741133] = { name = "Cabin Crew Simulator", url = "https://api.luarmor.net/files/v4/loaders/89d5ae806ab22a5d80efbe13b41090ae.lua" },
	[9898409899] = { name = "K2 Climbing", url = "https://api.luarmor.net/files/v4/loaders/14ab05bb43ff4bcf9d3801b68d6b495e.lua" },
}

local keyLinks = {
	{ name = "Lootlabs", tag = "Recommended", url = "https://ads.luarmor.net/get_key?for=Lootlabs-osbeSQDHFyMg", logo = "rbxassetid://102357888982176" },
	{ name = "Work.ink", url = "https://ads.luarmor.net/get_key?for=Workink-EbOASIcGCvwd", logo = "rbxassetid://100851789389252" },
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

local folder = "lsdresearch"
local keyPath = folder .. "/key.txt"

local errors = {
	KEY_EXPIRED = "Your key expired. Get a new one.",
	KEY_HWID_LOCKED = "This key is locked to another device. Reset it in the Discord.",
	KEY_INCORRECT = "That key doesn't exist. Check you copied all of it.",
	KEY_INVALID = "That doesn't look like a key.",
	KEY_BANNED = "This key has been blacklisted.",
}

local function savedKey()
	local ok, k = pcall(function()
		return isfile(keyPath) and readfile(keyPath)
	end)
	if ok and type(k) == "string" then
		return (k:gsub("%s", ""))
	end
end

local api
pcall(function()
	api = loadstring(game:HttpGet("https://sdkapi-public.luarmor.net/library.lua"))()
	api.script_id = hub.url:match("loaders/(%w+)%.lua")
end)

local function check(k)
	if not k or k == "" then
		return false, "Paste your key first."
	end
	if not api then
		return true
	end
	local ok, res = pcall(api.check_key, k)
	if not ok or type(res) ~= "table" then
		return false, "Couldn't check the key. Try again."
	end
	if res.code == "KEY_VALID" then
		return true
	end
	return false, errors[res.code] or tostring(res.message)
end

local TweenService = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

local bg = Color3.fromRGB(12, 13, 15)
local panel = Color3.fromRGB(22, 28, 38)
local outline = Color3.fromRGB(52, 66, 89)
local accent = Color3.fromRGB(152, 181, 255)
local white = Color3.new(1, 1, 1)
local grey = Color3.fromRGB(180, 180, 180)
local red = Color3.fromRGB(255, 125, 125)
local green = Color3.fromRGB(140, 220, 160)

local bold = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.SemiBold)
local medium = Font.new("rbxasset://fonts/families/Montserrat.json", Enum.FontWeight.Medium)

local function tween(obj, t, props)
	local tw = TweenService:Create(obj, TweenInfo.new(t, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function new(class, props, children)
	local obj = Instance.new(class)
	for k, v in pairs(props) do
		obj[k] = v
	end
	for _, c in ipairs(children or {}) do
		c.Parent = obj
	end
	return obj
end

local function round(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end

local function border(t)
	return new("UIStroke", { Color = outline, Transparency = t, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function pad(t, b, l, r)
	return new("UIPadding", {
		PaddingTop = UDim.new(0, t),
		PaddingBottom = UDim.new(0, b),
		PaddingLeft = UDim.new(0, l),
		PaddingRight = UDim.new(0, r),
	})
end

local function label(props)
	props.BackgroundTransparency = 1
	props.TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Left
	return new("TextLabel", props)
end

local function askForKey(firstMsg)
	local done = Instance.new("BindableEvent")
	local result

	local gui = new("ScreenGui", { Name = "lsdresearchKey", ResetOnSpawn = false, IgnoreGuiInset = true })
	if not pcall(function()
		gui.Parent = gethui and gethui() or game:GetService("CoreGui")
	end) then
		gui.Parent = game:GetService("Players").LocalPlayer:WaitForChild("PlayerGui")
	end

	local width = 360

	local main = new("CanvasGroup", {
		Size = UDim2.fromOffset(width, 260),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = bg,
		BackgroundTransparency = 0.05,
		GroupTransparency = 1,
		Parent = gui,
	}, { round(10), border(0.5) })
	local scale = new("UIScale", { Scale = 0.95, Parent = main })

	local top = new("TextButton", {
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = main,
	})

	local title = label({
		Position = UDim2.fromOffset(16, 8),
		Size = UDim2.new(1, -60, 0, 16),
		FontFace = bold,
		TextSize = 13,
		TextColor3 = accent,
		TextTransparency = 0.2,
		Text = "lsdresearch",
		Parent = top,
	})
	new("UIGradient", { Color = ColorSequence.new(Color3.fromRGB(155, 155, 155), white), Parent = title })

	label({
		Position = UDim2.fromOffset(16, 24),
		Size = UDim2.new(1, -60, 0, 12),
		FontFace = medium,
		TextSize = 10,
		TextColor3 = white,
		TextTransparency = 0.6,
		Text = hub.name,
		Parent = top,
	})

	local closeBtn = new("TextButton", {
		Size = UDim2.fromOffset(22, 22),
		Position = UDim2.new(1, -36, 0.5, -11),
		BackgroundColor3 = panel,
		BackgroundTransparency = 1,
		Text = "",
		AutoButtonColor = false,
		Parent = top,
	}, { round(5) })
	for _, rot in ipairs({ 45, -45 }) do
		new("Frame", {
			Size = UDim2.fromOffset(12, 2),
			Position = UDim2.fromScale(0.5, 0.5),
			AnchorPoint = Vector2.new(0.5, 0.5),
			Rotation = rot,
			BackgroundColor3 = white,
			BackgroundTransparency = 0.4,
			Parent = closeBtn,
		})
	end
	closeBtn.MouseEnter:Connect(function()
		tween(closeBtn, 0.25, { BackgroundTransparency = 0.5 })
	end)
	closeBtn.MouseLeave:Connect(function()
		tween(closeBtn, 0.25, { BackgroundTransparency = 1 })
	end)
	closeBtn.MouseButton1Click:Connect(function()
		done:Fire()
	end)

	new("Frame", {
		Size = UDim2.new(1, 0, 0, 1),
		Position = UDim2.fromOffset(0, 44),
		BackgroundColor3 = outline,
		BackgroundTransparency = 0.5,
		BorderSizePixel = 0,
		Parent = main,
	})

	local body = new("Frame", {
		Position = UDim2.fromOffset(0, 45),
		Size = UDim2.new(1, 0, 1, -45),
		BackgroundTransparency = 1,
		Parent = main,
	}, { pad(12, 14, 14, 14) })
	local layout = new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = body })

	local function card(order, height)
		return new("Frame", {
			LayoutOrder = order,
			Size = UDim2.new(1, 0, 0, height),
			BackgroundColor3 = panel,
			BackgroundTransparency = 0.5,
			Parent = body,
		}, { round(5), border(0.6), pad(9, 9, 12, 12) })
	end

	label({
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 14),
		FontFace = bold,
		TextSize = 11,
		TextColor3 = accent,
		TextTransparency = 0.3,
		Text = "KEY SYSTEM",
		Parent = body,
	})

	local input = card(2, 38)
	local box = new("TextBox", {
		Size = UDim2.fromScale(1, 1),
		BackgroundTransparency = 1,
		FontFace = medium,
		TextSize = 12,
		TextColor3 = white,
		TextXAlignment = Enum.TextXAlignment.Left,
		PlaceholderText = "Paste your key here",
		PlaceholderColor3 = grey,
		ClearTextOnFocus = false,
		Text = "",
		Parent = input,
	})
	local inputStroke = input:FindFirstChildOfClass("UIStroke")
	box.Focused:Connect(function()
		tween(inputStroke, 0.3, { Transparency = 0.2, Color = accent })
	end)
	box.FocusLost:Connect(function()
		tween(inputStroke, 0.3, { Transparency = 0.6, Color = outline })
	end)

	local status = label({
		LayoutOrder = 99,
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		FontFace = medium,
		TextSize = 10,
		TextWrapped = true,
		TextColor3 = red,
		Text = firstMsg or "",
		Parent = body,
	})

	local function setStatus(msg, color)
		status.Text = msg
		status.TextColor3 = color
	end

	local function button(order, name, desc, action, logo, tag, onClick)
		local b = card(order, 46)
		local x = logo and 34 or 0

		if logo then
			new("ImageLabel", {
				Size = UDim2.fromOffset(26, 26),
				Position = UDim2.new(0, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0, 0.5),
				BackgroundTransparency = 1,
				Image = logo,
				ScaleType = Enum.ScaleType.Fit,
				Parent = b,
			}, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })
		end

		local line = new("Frame", {
			Position = UDim2.fromOffset(x, 0),
			Size = UDim2.new(1, -80 - x, 0, 14),
			BackgroundTransparency = 1,
			Parent = b,
		}, {
			new("UIListLayout", {
				FillDirection = Enum.FillDirection.Horizontal,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 6),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
		})
		local nameLabel = label({
			LayoutOrder = 1,
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 14),
			FontFace = bold,
			TextSize = 12,
			TextColor3 = white,
			TextTransparency = 0.15,
			Text = name,
			Parent = line,
		})
		if tag then
			label({
				LayoutOrder = 2,
				AutomaticSize = Enum.AutomaticSize.X,
				Size = UDim2.fromOffset(0, 14),
				FontFace = bold,
				TextSize = 10,
				TextColor3 = green,
				Text = tag,
				Parent = line,
			})
		end

		label({
			Position = UDim2.fromOffset(x, 15),
			Size = UDim2.new(1, -80 - x, 0, 12),
			FontFace = medium,
			TextSize = 10,
			TextColor3 = accent,
			TextTransparency = 0.5,
			Text = desc,
			Parent = b,
		})

		local pill = new("TextLabel", {
			AutomaticSize = Enum.AutomaticSize.X,
			Size = UDim2.fromOffset(0, 18),
			Position = UDim2.new(1, 0, 0.5, 0),
			AnchorPoint = Vector2.new(1, 0.5),
			BackgroundColor3 = accent,
			BackgroundTransparency = 0.85,
			FontFace = bold,
			TextSize = 10,
			TextColor3 = accent,
			Text = action,
			Parent = b,
		}, { round(4), pad(0, 0, 8, 8) })

		local click = new("TextButton", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "", Parent = b })
		click.MouseEnter:Connect(function()
			tween(nameLabel, 0.3, { TextTransparency = 0 })
			tween(b, 0.3, { BackgroundTransparency = 0.3 })
		end)
		click.MouseLeave:Connect(function()
			tween(nameLabel, 0.3, { TextTransparency = 0.15 })
			tween(b, 0.3, { BackgroundTransparency = 0.5 })
		end)
		click.MouseButton1Click:Connect(function()
			pill.BackgroundTransparency = 0.5
			tween(pill, 0.4, { BackgroundTransparency = 0.85 })
			onClick(pill)
		end)
	end

	for i, link in ipairs(keyLinks) do
		button(2 + i, link.name, "Get a key through " .. link.name, "Copy", link.logo, link.tag, function()
			if setclipboard then
				setclipboard(link.url)
				setStatus(link.name .. " link copied. Open it in your browser to get a key.", green)
			else
				setStatus(link.url, grey)
			end
		end)
	end

	local busy = false
	button(3 + #keyLinks, "Submit", "Checks your key and loads " .. hub.name, "Check", nil, nil, function(pill)
		if busy then
			return
		end
		busy = true
		pill.Text = "..."
		setStatus("Checking...", grey)

		local k = box.Text:gsub("%s", "")
		local ok, msg = check(k)
		if ok then
			result = k
			setStatus("Key accepted, loading...", green)
			done:Fire()
		else
			setStatus(msg, red)
		end

		pill.Text = "Check"
		busy = false
	end)

	local function resize()
		main.Size = UDim2.fromOffset(width, 45 + layout.AbsoluteContentSize.Y + 26)
	end
	layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(resize)
	resize()

	local dragging, dragFrom, startPos
	top.InputBegan:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging, dragFrom, startPos = true, i.Position, main.Position
		end
	end)
	UIS.InputChanged:Connect(function(i)
		if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then
			local d = i.Position - dragFrom
			main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
		end
	end)
	UIS.InputEnded:Connect(function(i)
		if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then
			dragging = false
		end
	end)

	tween(main, 0.5, { GroupTransparency = 0 })
	tween(scale, 0.5, { Scale = 1 })

	done.Event:Wait()

	tween(main, 0.3, { GroupTransparency = 1 })
	tween(scale, 0.3, { Scale = 0.95 }).Completed:Wait()
	gui:Destroy()
	done:Destroy()
	return result
end

local key, reason
for _, k in ipairs({ script_key or "", savedKey() or "" }) do
	if k ~= "" then
		local ok, msg = check(k)
		if ok then
			key = k
			break
		end
		reason = msg
	end
end

if not key then
	pcall(function()
		if isfile(keyPath) then
			delfile(keyPath)
		end
	end)
	key = askForKey(reason)
	if not key then
		return
	end
end

pcall(function()
	if not isfolder(folder) then
		makefolder(folder)
	end
	writefile(keyPath, key)
end)

local env = getgenv and getgenv() or _G
env.script_key = key
script_key = key

local src
for i = 1, 3 do
	local ok, res = pcall(game.HttpGet, game, hub.url)
	if ok and type(res) == "string" and #res > 0 then
		src = res
		break
	end
	if i < 3 then
		task.wait(i)
	end
end

if not src then
	notify("Couldn't reach " .. hub.name .. ". Try again in a moment.", true)
	return
end

local fn, err = loadstring(src)
if not fn then
	warn("[lsdresearch] " .. tostring(err))
	notify("The " .. hub.name .. " script didn't load. Try again in a moment.", true)
	return
end

local ok, runErr = pcall(fn)
if not ok then
	warn("[lsdresearch] " .. tostring(runErr))
	notify(hub.name .. " stopped with an error. Try re-executing.", true)
end
