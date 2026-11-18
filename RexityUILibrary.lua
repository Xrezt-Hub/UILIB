--[[
	╔══════════════════════════════════════════════════════════════╗
	║                    REXITY UI LIBRARY  v1.0.0                 ║
	║         Premium dark UI library for Roblox (Luau)            ║
	╚══════════════════════════════════════════════════════════════╝

	QUICK START
	────────────────────────────────────────────────────────────────
	local Library = loadstring(game:HttpGet("YOUR_URL"))()

	local Window = Library:CreateWindow({
		Name = "Rexity Hub",
		LoadingTitle = "Rexity Hub",
		LoadingSubtitle = "Premium Edition",
		ToggleKey = Enum.KeyCode.RightShift, -- optional
		Accent = Color3.fromRGB(235, 56, 82), -- optional
		DefaultTabs = true, -- Home, Main, Combat, Player, Visuals, Settings
	})

	local Tab = Window:CreateTab("Main", "home") -- returns existing tab if it already exists

	Tab:CreateSection("Example")
	Tab:CreateButton({ Name = "Button", Callback = function() print("clicked") end })
	Tab:CreateToggle({ Name = "Toggle", CurrentValue = false, Flag = "T1", Callback = function(v) print(v) end })
	Tab:CreateSlider({ Name = "Speed", Range = {0, 100}, Increment = 1, Suffix = "studs", CurrentValue = 16, Callback = function(v) print(v) end })
	Tab:CreateDropdown({ Name = "Mode", Options = {"A", "B", "C"}, CurrentOption = "A", Callback = function(v) print(v) end })
	Tab:CreateInput({ Name = "Name", PlaceholderText = "Type...", Callback = function(text) print(text) end })
	Tab:CreateLabel("Just a label")
	Tab:CreateParagraph({ Title = "Title", Content = "Long wrapped text." })
	Tab:CreateKeybind({ Name = "Key", CurrentKeybind = "E", Callback = function(isDown) print(isDown) end })

	Window:Notify({ Title = "Hello", Content = "Loaded!", Duration = 4, Type = "Success" })

	NOTES
	────────────────────────────────────────────────────────────────
	• Dropdown callback gets a string (single) or a table (MultipleOptions = true).
	• Keybind callback gets `true` on press (and `false` on release if HoldToInteract = true).
	• Icons: a name from the built-in set (home, main, combat, player, visuals, settings,
	  players, fps, ping, game, info, search, star, heart, bolt, shield, ...), any emoji,
	  or an "rbxassetid://123" image.
	• Window.Flags[FlagName] holds the live value of every component that has a Flag.
]]

local Library = {
	Version = "1.0.0",
}

-- ════════════════════════════════════════════════════════════════
--  SERVICES
-- ════════════════════════════════════════════════════════════════
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local MarketplaceService = game:GetService("MarketplaceService")
local Stats = game:GetService("Stats")
local CoreGui = game:GetService("CoreGui")

local LocalPlayer = Players.LocalPlayer

-- ════════════════════════════════════════════════════════════════
--  THEME
-- ════════════════════════════════════════════════════════════════
local Theme = {
	Background = Color3.fromRGB(13, 13, 18),
	TopBar = Color3.fromRGB(18, 18, 25),
	Sidebar = Color3.fromRGB(11, 11, 15),
	Element = Color3.fromRGB(22, 22, 29),
	ElementHover = Color3.fromRGB(29, 29, 38),
	Input = Color3.fromRGB(15, 15, 20),
	Stroke = Color3.fromRGB(38, 38, 50),
	StrokeHover = Color3.fromRGB(62, 62, 80),
	Text = Color3.fromRGB(240, 240, 246),
	SubText = Color3.fromRGB(148, 148, 166),
	Accent = Color3.fromRGB(235, 56, 82),
	AccentDark = Color3.fromRGB(118, 28, 41),
	Good = Color3.fromRGB(76, 214, 128),
	Warn = Color3.fromRGB(255, 190, 60),
	Bad = Color3.fromRGB(255, 84, 96),
}

local AccentPresets = {
	Crimson = Color3.fromRGB(235, 56, 82),
	Ocean = Color3.fromRGB(56, 140, 255),
	Violet = Color3.fromRGB(138, 92, 246),
	Emerald = Color3.fromRGB(40, 200, 130),
	Amber = Color3.fromRGB(255, 170, 50),
}
local AccentOrder = { "Crimson", "Ocean", "Violet", "Emerald", "Amber" }

local Font = {
	Regular = Enum.Font.Gotham,
	Medium = Enum.Font.GothamMedium,
	Bold = Enum.Font.GothamBold,
}

local Icons = {
	default = "◆",
	home = "🏠",
	main = "🧩",
	combat = "⚔️",
	player = "👤",
	visuals = "👁️",
	settings = "⚙️",
	players = "👥",
	fps = "⚡",
	ping = "📶",
	game = "🎮",
	info = "ℹ️",
	search = "🔍",
	star = "⭐",
	heart = "❤️",
	bolt = "⚡",
	shield = "🛡️",
	world = "🌍",
	tools = "🛠️",
	user = "👤",
	list = "📋",
	target = "🎯",
	eye = "👁️",
	lock = "🔒",
	key = "🔑",
	code = "💻",
	teleport = "🌀",
	misc = "📦",
}

-- ════════════════════════════════════════════════════════════════
--  UTILITIES
-- ════════════════════════════════════════════════════════════════
local Maid = {}
Maid.__index = Maid

function Maid.new()
	return setmetatable({ _tasks = {} }, Maid)
end

function Maid:Give(item)
	table.insert(self._tasks, item)
	return item
end

function Maid:Clean()
	local tasks = self._tasks
	self._tasks = {}
	for _, item in ipairs(tasks) do
		local kind = typeof(item)
		if kind == "RBXScriptConnection" then
			item:Disconnect()
		elseif kind == "Instance" then
			item:Destroy()
		elseif kind == "function" then
			pcall(item)
		end
	end
end

local function New(className, props, children)
	local inst = Instance.new(className)
	if inst:IsA("GuiObject") then
		inst.BorderSizePixel = 0
		if inst:IsA("GuiButton") then
			inst.AutoButtonColor = false
		end
		if inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox") then
			inst.BackgroundTransparency = 1
			inst.Font = Font.Medium
			inst.TextColor3 = Theme.Text
			inst.TextSize = 14
			if inst:IsA("TextButton") then
				inst.Text = ""
			end
		elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
			inst.BackgroundTransparency = 1
		end
	end
	local parent
	for key, value in pairs(props or {}) do
		if key == "Parent" then
			parent = value
		else
			inst[key] = value
		end
	end
	for _, child in ipairs(children or {}) do
		child.Parent = inst
	end
	inst.Parent = parent
	return inst
end

local function Corner(parent, radius)
	return New("UICorner", { CornerRadius = UDim.new(0, radius), Parent = parent })
end

local function Stroke(parent, color, transparency, thickness)
	return New("UIStroke", {
		Color = color or Theme.Stroke,
		Transparency = transparency or 0,
		Thickness = thickness or 1,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		Parent = parent,
	})
end

local function Padding(parent, top, right, bottom, left)
	return New("UIPadding", {
		PaddingTop = UDim.new(0, top or 0),
		PaddingRight = UDim.new(0, right or 0),
		PaddingBottom = UDim.new(0, bottom or 0),
		PaddingLeft = UDim.new(0, left or 0),
		Parent = parent,
	})
end

local function Tween(inst, duration, props, style, direction)
	local tween = TweenService:Create(
		inst,
		TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
		props
	)
	tween:Play()
	return tween
end

local function SafeCall(fn, ...)
	if type(fn) ~= "function" then
		return
	end
	local ok, err = pcall(fn, ...)
	if not ok then
		warn("[Rexity UI] Callback error: " .. tostring(err))
	end
end

local function Round(value, decimals)
	local mult = 10 ^ (decimals or 0)
	return math.floor(value * mult + 0.5) / mult
end

local function MakeIcon(parent, icon, size, color)
	local asset
	if type(icon) == "number" then
		asset = "rbxassetid://" .. tostring(icon)
	elseif type(icon) == "string" and (icon:find("^rbxassetid://") or icon:find("^rbxasset://")) then
		asset = icon
	end

	if asset then
		return New("ImageLabel", {
			Name = "Icon",
			Size = UDim2.fromOffset(size, size),
			Image = asset,
			ImageColor3 = color or Theme.Text,
			Parent = parent,
		})
	end

	local key = string.lower(tostring(icon or "default"))
	local glyph = Icons[key]
	if not glyph then
		local length = utf8.len(tostring(icon)) or 99
		glyph = (length <= 3) and tostring(icon) or Icons.default
	end

	return New("TextLabel", {
		Name = "Icon",
		Size = UDim2.fromOffset(size, size),
		Text = glyph,
		TextSize = size - 3,
		Font = Font.Bold,
		TextColor3 = color or Theme.Text,
		Parent = parent,
	})
end

local function SetIconAlpha(icon, alpha)
	if icon:IsA("TextLabel") then
		Tween(icon, 0.2, { TextTransparency = alpha })
	else
		Tween(icon, 0.2, { ImageTransparency = alpha })
	end
end

local function ApplyHover(card, stroke, trigger)
	trigger = trigger or card
	trigger.MouseEnter:Connect(function()
		Tween(card, 0.18, { BackgroundColor3 = Theme.ElementHover })
		Tween(stroke, 0.18, { Color = Theme.StrokeHover })
	end)
	trigger.MouseLeave:Connect(function()
		Tween(card, 0.18, { BackgroundColor3 = Theme.Element })
		Tween(stroke, 0.18, { Color = Theme.Stroke })
	end)
end

local BindState = { Active = false, Last = 0 }

local function BindingBusy()
	return BindState.Active or (os.clock() - BindState.Last) < 0.15
end

local function MakeDraggable(handle, target, maid)
	local dragging = false
	local dragStart, startPos

	handle.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			local conn
			conn = input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
					if conn then
						conn:Disconnect()
					end
				end
			end)
		end
	end)

	maid:Give(UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
		then
			local delta = input.Position - dragStart
			local camera = workspace.CurrentCamera
			local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
			local offsetX = startPos.X.Offset + delta.X
			local offsetY = startPos.Y.Offset + delta.Y
			offsetX = math.clamp(offsetX, 40 - startPos.X.Scale * viewport.X, viewport.X - 40 - startPos.X.Scale * viewport.X)
			offsetY = math.clamp(offsetY, 40 - startPos.Y.Scale * viewport.Y, viewport.Y - 40 - startPos.Y.Scale * viewport.Y)
			target.Position = UDim2.new(startPos.X.Scale, offsetX, startPos.Y.Scale, offsetY)
		end
	end))
end

local function MountGui(gui)
	if typeof(syn) == "table" and syn.protect_gui then
		pcall(syn.protect_gui, gui)
	end
	local parent
	if typeof(gethui) == "function" then
		local ok, result = pcall(gethui)
		if ok and typeof(result) == "Instance" then
			parent = result
		end
	end
	if not parent then
		local ok = pcall(function()
			gui.Parent = CoreGui
		end)
		if ok and gui.Parent == CoreGui then
			return
		end
		parent = LocalPlayer:WaitForChild("PlayerGui")
	end
	gui.Parent = parent
end

local function PurgeOld(guiName)
	local roots = {}
	if typeof(gethui) == "function" then
		local ok, result = pcall(gethui)
		if ok and typeof(result) == "Instance" then
			table.insert(roots, result)
		end
	end
	table.insert(roots, CoreGui)
	local playerGui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
	if playerGui then
		table.insert(roots, playerGui)
	end
	for _, root in ipairs(roots) do
		pcall(function()
			local old = root:FindFirstChild(guiName)
			if old then
				old:Destroy()
			end
		end)
	end
end

local function GetPing()
	local ok, value = pcall(function()
		return Stats.Network.ServerStatsItem["Data Ping"]:GetValue()
	end)
	if ok and type(value) == "number" and value > 0 then
		return value
	end
	local ok2, fallback = pcall(function()
		return LocalPlayer:GetNetworkPing() * 1000
	end)
	if ok2 and type(fallback) == "number" then
		return fallback
	end
	return 0
end

-- ════════════════════════════════════════════════════════════════
--  CLASSES
-- ════════════════════════════════════════════════════════════════
local Window = {}
Window.__index = Window

local Tab = {}
Tab.__index = Tab

-- ════════════════════════════════════════════════════════════════
--  WINDOW: THEMING / MAID HELPERS
-- ════════════════════════════════════════════════════════════════
function Window:NewMaid()
	local maid = Maid.new()
	self.Maid:Give(function()
		maid:Clean()
	end)
	return maid
end

function Window:OnTheme(fn, maid)
	table.insert(self.ThemeCallbacks, fn)
	pcall(fn)
	if maid then
		maid:Give(function()
			local index = table.find(self.ThemeCallbacks, fn)
			if index then
				table.remove(self.ThemeCallbacks, index)
			end
		end)
	end
end

function Window:SetAccent(color)
	if typeof(color) == "string" then
		color = AccentPresets[color]
	end
	if typeof(color) ~= "Color3" then
		return
	end
	Theme.Accent = color
	Theme.AccentDark = color:Lerp(Color3.new(0, 0, 0), 0.55)
	for _, fn in ipairs(self.ThemeCallbacks) do
		pcall(fn)
	end
end

-- ════════════════════════════════════════════════════════════════
--  WINDOW: NOTIFICATIONS
-- ════════════════════════════════════════════════════════════════
function Window:Notify(config)
	if self.Destroyed then
		return
	end
	config = type(config) == "table" and config or { Content = tostring(config) }
	local duration = tonumber(config.Duration) or 4
	local colors = { Info = Theme.Accent, Success = Theme.Good, Warning = Theme.Warn, Error = Theme.Bad }
	local color = colors[config.Type or "Info"] or Theme.Accent

	self.NotifyCounter = self.NotifyCounter + 1

	local wrap = New("Frame", {
		Name = "Notification",
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		LayoutOrder = self.NotifyCounter,
		Parent = self.NotifyHolder,
	})

	local inner = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Position = UDim2.new(1, 60, 0, 0),
		BackgroundColor3 = Theme.TopBar,
		ClipsDescendants = true,
		Parent = wrap,
	})
	Corner(inner, 10)
	Stroke(inner, Theme.Stroke, 0, 1)

	New("Frame", {
		Size = UDim2.new(0, 3, 1, 0),
		BackgroundColor3 = color,
		Parent = inner,
	})

	local content = New("Frame", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		Parent = inner,
	})
	Padding(content, 10, 12, 14, 16)
	New("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })

	New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 16),
		Text = tostring(config.Title or "Notification"),
		Font = Font.Bold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = content,
	})

	if config.Content and tostring(config.Content) ~= "" then
		New("TextLabel", {
			Size = UDim2.new(1, 0, 0, 0),
			AutomaticSize = Enum.AutomaticSize.Y,
			Text = tostring(config.Content),
			TextSize = 12,
			TextColor3 = Theme.SubText,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
			LayoutOrder = 2,
			Parent = content,
		})
	end

	local barTrack = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 2),
		BackgroundTransparency = 1,
		Parent = inner,
	})
	local barFill = New("Frame", {
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = color,
		Parent = barTrack,
	})

	Tween(inner, 0.4, { Position = UDim2.new(0, 0, 0, 0) }, Enum.EasingStyle.Back)
	Tween(barFill, duration, { Size = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Linear)

	task.delay(duration, function()
		if not wrap.Parent then
			return
		end
		Tween(inner, 0.3, { Position = UDim2.new(1, 60, 0, 0) })
		task.wait(0.32)
		if wrap.Parent then
			wrap:Destroy()
		end
	end)
end

-- ════════════════════════════════════════════════════════════════
--  WINDOW: VISIBILITY / MINIMIZE / DESTROY
-- ════════════════════════════════════════════════════════════════
function Window:SetVisible(state)
	if self.Destroyed or self.Loading then
		return
	end
	self.Visible = state
	if state then
		self.Holder.Visible = true
		self.Pop.Scale = 0.92
		Tween(self.Pop, 0.3, { Scale = 1 }, Enum.EasingStyle.Back)
	else
		Tween(self.Pop, 0.15, { Scale = 0.92 })
		task.delay(0.16, function()
			if not self.Visible and not self.Destroyed then
				self.Holder.Visible = false
			end
		end)
	end
end

function Window:Toggle()
	self:SetVisible(not self.Visible)
end

function Window:SetMinimized(state)
	if self.Destroyed then
		return
	end
	self.Minimized = state
	local mainSize = state and UDim2.new(1, 0, 0, 48) or UDim2.new(1, 0, 1, 0)
	local shadowSize = state and UDim2.new(1, 70, 0, 118) or UDim2.new(1, 70, 1, 70)
	if not state then
		self.Body.Visible = true
	end
	Tween(self.Main, 0.35, { Size = mainSize })
	Tween(self.Shadow, 0.35, { Size = shadowSize })
	self.MinButton.Text = state and "+" or "–"
	if state then
		task.delay(0.36, function()
			if self.Minimized and not self.Destroyed then
				self.Body.Visible = false
			end
		end)
	end
end

function Window:SetToggleKey(key)
	if typeof(key) == "string" then
		local ok, kc = pcall(function()
			return Enum.KeyCode[key]
		end)
		key = ok and kc or nil
	end
	self.ToggleKey = typeof(key) == "EnumItem" and key or nil
end

function Window:SetScale(value)
	self.UserScale = math.clamp(tonumber(value) or 1, 0.5, 1.5)
	self:_UpdateScale()
end

function Window:_UpdateScale()
	local camera = workspace.CurrentCamera
	local viewport = camera and camera.ViewportSize or Vector2.new(1280, 720)
	local fit = math.min((viewport.X - 24) / self.BaseSize.X, (viewport.Y - 24) / self.BaseSize.Y, 1)
	self.ScaleObject.Scale = math.max(fit, 0.45) * self.UserScale
end

function Window:Destroy()
	if self.Destroyed then
		return
	end
	self.Destroyed = true
	if self.OnClose then
		SafeCall(self.OnClose)
	end
	self.Maid:Clean()
	if self.Gui then
		self.Gui:Destroy()
	end
	if _G.RexityWindows and _G.RexityWindows[self.GuiName] == self then
		_G.RexityWindows[self.GuiName] = nil
	end
end

function Window:Close()
	if self.Destroyed then
		return
	end
	if self.Holder.Visible then
		Tween(self.Pop, 0.2, { Scale = 0.85 })
		task.wait(0.2)
	end
	self:Destroy()
end

-- ════════════════════════════════════════════════════════════════
--  WINDOW: TABS
-- ════════════════════════════════════════════════════════════════
function Window:SelectTab(target)
	local tab = type(target) == "table" and target or self.Tabs[target]
	if not tab or tab == self.CurrentTab then
		return
	end
	local old = self.CurrentTab
	if old then
		old:_SetSelected(false)
		old.Page.Visible = false
	end
	self.CurrentTab = tab
	tab:_SetSelected(true)
	tab.Page.GroupTransparency = 1
	tab.Page.Position = UDim2.fromOffset(0, 14)
	tab.Page.Visible = true
	Tween(tab.Page, 0.32, { GroupTransparency = 0, Position = UDim2.fromOffset(0, 0) })
end

function Window:CreateTab(name, icon)
	name = tostring(name or "Tab")
	if self.Tabs[name] then
		return self.Tabs[name]
	end
	return self:_BuildTab(name, icon or "main", name, false)
end

function Window:_BuildTab(name, icon, title, noEmpty)
	local order = #self.TabList + 1

	local button = New("TextButton", {
		Name = name,
		Size = UDim2.new(1, 0, 0, 38),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 1,
		LayoutOrder = order,
		Parent = self.TabHolder,
	})
	Corner(button, 9)

	local indicator = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 3, 0, 0),
		BackgroundColor3 = Theme.Accent,
		Parent = button,
	})
	Corner(indicator, 2)

	local iconObject = MakeIcon(button, icon, 20)
	iconObject.AnchorPoint = Vector2.new(0, 0.5)
	iconObject.Position = UDim2.new(0, 14, 0.5, 0)
	if iconObject:IsA("TextLabel") then
		iconObject.TextTransparency = 0.45
	else
		iconObject.ImageTransparency = 0.45
	end

	local label = New("TextLabel", {
		Position = UDim2.fromOffset(44, 0),
		Size = UDim2.new(1, -50, 1, 0),
		Text = name,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = button,
	})

	self:OnTheme(function()
		button.BackgroundColor3 = Theme.Accent
		indicator.BackgroundColor3 = Theme.Accent
	end, self.Maid)

	-- Page
	local page = New("CanvasGroup", {
		Name = name .. "_Page",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = self.Content,
	})

	local scroll = New("ScrollingFrame", {
		Name = "Scroll",
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundTransparency = 1,
		ScrollBarThickness = 3,
		ScrollBarImageColor3 = Theme.Accent,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = page,
	})
	Padding(scroll, 14, 14, 16, 14)
	New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = scroll })

	self:OnTheme(function()
		scroll.ScrollBarImageColor3 = Theme.Accent
	end, self.Maid)

	New("TextLabel", {
		Name = "Header",
		Size = UDim2.new(1, 0, 0, 34),
		Text = title,
		Font = Font.Bold,
		TextSize = 22,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 0,
		Parent = scroll,
	})

	local tab = setmetatable({
		Window = self,
		Name = name,
		Button = button,
		Indicator = indicator,
		IconObject = iconObject,
		Label = label,
		Page = page,
		Scroll = scroll,
		Order = 100,
		Selected = false,
	}, Tab)

	if not noEmpty then
		tab.EmptyLabel = New("TextLabel", {
			Name = "Empty",
			Size = UDim2.new(1, 0, 0, 60),
			Text = "Nothing here yet.\nAdd components with Tab:CreateButton, CreateToggle, CreateSlider...",
			TextSize = 12,
			TextColor3 = Theme.SubText,
			TextWrapped = true,
			LayoutOrder = 99999,
			Parent = scroll,
		})
	end

	button.MouseEnter:Connect(function()
		if not tab.Selected then
			Tween(button, 0.15, { BackgroundTransparency = 0.94 })
		end
	end)
	button.MouseLeave:Connect(function()
		if not tab.Selected then
			Tween(button, 0.15, { BackgroundTransparency = 1 })
		end
	end)
	button.MouseButton1Click:Connect(function()
		self:SelectTab(tab)
	end)

	self.Tabs[name] = tab
	table.insert(self.TabList, tab)
	return tab
end

function Tab:_SetSelected(state)
	self.Selected = state
	Tween(self.Button, 0.25, { BackgroundTransparency = state and 0.88 or 1 })
	Tween(self.Indicator, 0.3, { Size = UDim2.new(0, 3, 0, state and 18 or 0) }, Enum.EasingStyle.Back)
	Tween(self.Label, 0.2, { TextColor3 = state and Theme.Text or Theme.SubText })
	SetIconAlpha(self.IconObject, state and 0 or 0.45)
end

function Tab:_NextOrder()
	self.Order = self.Order + 1
	if self.EmptyLabel then
		self.EmptyLabel:Destroy()
		self.EmptyLabel = nil
	end
	return self.Order
end

function Tab:_NewCard(height, name)
	local card = New("Frame", {
		Name = name or "Component",
		BackgroundColor3 = Theme.Element,
		Size = height and UDim2.new(1, 0, 0, height) or UDim2.new(1, 0, 0, 0),
		AutomaticSize = height and Enum.AutomaticSize.None or Enum.AutomaticSize.Y,
		ClipsDescendants = true,
		LayoutOrder = self:_NextOrder(),
		Parent = self.Scroll,
	})
	Corner(card, 9)
	local stroke = Stroke(card, Theme.Stroke, 0, 1)
	return card, stroke
end

-- ════════════════════════════════════════════════════════════════
--  COMPONENTS
-- ════════════════════════════════════════════════════════════════

-- ─── Section ────────────────────────────────────────────────────
function Tab:CreateSection(config)
	if type(config) == "string" then
		config = { Name = config }
	end
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()

	local holder = New("Frame", {
		Name = "Section",
		Size = UDim2.new(1, 0, 0, 24),
		BackgroundTransparency = 1,
		LayoutOrder = self:_NextOrder(),
		Parent = self.Scroll,
	})

	local line = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Theme.Stroke,
		Parent = holder,
	})

	local label = New("TextLabel", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 18),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Background,
		Text = string.upper(tostring(config.Name or "Section")),
		Font = Font.Bold,
		TextSize = 11,
		TextColor3 = Theme.Accent,
		Parent = holder,
	})
	Padding(label, 0, 10, 0, 0)

	window:OnTheme(function()
		label.TextColor3 = Theme.Accent
	end, maid)

	local obj = { Instance = holder }
	function obj:SetName(text)
		label.Text = string.upper(tostring(text))
	end
	function obj:Destroy()
		maid:Clean()
		holder:Destroy()
	end
	return obj
end

-- ─── Button ─────────────────────────────────────────────────────
function Tab:CreateButton(config)
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()
	local card, stroke = self:_NewCard(40, "Button")

	local nameLabel = New("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -56, 1, 0),
		Text = tostring(config.Name or "Button"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	local arrow = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(20, 20),
		Text = "›",
		Font = Font.Bold,
		TextSize = 24,
		TextColor3 = Theme.Accent,
		Parent = card,
	})
	window:OnTheme(function()
		arrow.TextColor3 = Theme.Accent
	end, maid)

	local click = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), ZIndex = 2, Parent = card })
	ApplyHover(card, stroke, click)

	click.MouseButton1Click:Connect(function()
		card.BackgroundColor3 = Theme.Accent:Lerp(Theme.Element, 0.72)
		Tween(card, 0.4, { BackgroundColor3 = Theme.ElementHover })
		Tween(arrow, 0.12, { Position = UDim2.new(1, -8, 0.5, 0) })
		task.delay(0.12, function()
			Tween(arrow, 0.25, { Position = UDim2.new(1, -14, 0.5, 0) }, Enum.EasingStyle.Back)
		end)
		SafeCall(config.Callback)
	end)

	local obj = { Instance = card }
	function obj:SetName(text)
		nameLabel.Text = tostring(text)
	end
	function obj:SetCallback(fn)
		config.Callback = fn
	end
	function obj:Fire()
		SafeCall(config.Callback)
	end
	function obj:Destroy()
		maid:Clean()
		card:Destroy()
	end
	return obj
end

-- ─── Toggle ─────────────────────────────────────────────────────
function Tab:CreateToggle(config)
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()
	local card, stroke = self:_NewCard(40, "Toggle")
	local state = config.CurrentValue == true

	local nameLabel = New("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -76, 1, 0),
		Text = tostring(config.Name or "Toggle"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	local switch = New("Frame", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -14, 0.5, 0),
		Size = UDim2.fromOffset(42, 22),
		BackgroundColor3 = Color3.fromRGB(52, 52, 66),
		Parent = card,
	})
	Corner(switch, 11)

	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 3, 0.5, 0),
		Size = UDim2.fromOffset(16, 16),
		BackgroundColor3 = Color3.fromRGB(255, 255, 255),
		Parent = switch,
	})
	Corner(knob, 8)

	local function Render(animate)
		local goalPosition = state and UDim2.new(1, -19, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
		local goalColor = state and Theme.Accent or Color3.fromRGB(52, 52, 66)
		if animate then
			Tween(knob, 0.22, { Position = goalPosition }, Enum.EasingStyle.Back)
			Tween(switch, 0.2, { BackgroundColor3 = goalColor })
		else
			knob.Position = goalPosition
			switch.BackgroundColor3 = goalColor
		end
	end

	if config.Flag then
		window.Flags[config.Flag] = state
	end
	Render(false)
	window:OnTheme(function()
		if state then
			switch.BackgroundColor3 = Theme.Accent
		end
	end, maid)

	local click = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), ZIndex = 2, Parent = card })
	ApplyHover(card, stroke, click)

	local obj = { Instance = card }
	function obj:Set(value, silent)
		state = value and true or false
		Render(true)
		if config.Flag then
			window.Flags[config.Flag] = state
		end
		if not silent then
			SafeCall(config.Callback, state)
		end
	end
	function obj:Get()
		return state
	end
	function obj:SetName(text)
		nameLabel.Text = tostring(text)
	end
	function obj:Destroy()
		maid:Clean()
		card:Destroy()
	end

	click.MouseButton1Click:Connect(function()
		obj:Set(not state)
	end)

	return obj
end

-- ─── Slider ─────────────────────────────────────────────────────
function Tab:CreateSlider(config)
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()
	local card, stroke = self:_NewCard(56, "Slider")
	ApplyHover(card, stroke)

	local range = config.Range or { 0, 100 }
	local minValue, maxValue = tonumber(range[1]) or 0, tonumber(range[2]) or 100
	local increment = tonumber(config.Increment) or 1
	if increment <= 0 then
		increment = 1
	end
	local suffix = config.Suffix and (" " .. tostring(config.Suffix)) or ""

	local function Snap(value)
		value = math.clamp(value, minValue, maxValue)
		value = minValue + math.floor((value - minValue) / increment + 0.5) * increment
		value = math.clamp(value, minValue, maxValue)
		return Round(value, 4)
	end

	local value = Snap(tonumber(config.CurrentValue) or minValue)

	local nameLabel = New("TextLabel", {
		Position = UDim2.fromOffset(14, 8),
		Size = UDim2.new(1, -120, 0, 18),
		Text = tostring(config.Name or "Slider"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	local valueLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -14, 0, 8),
		Size = UDim2.fromOffset(100, 18),
		Text = "",
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		Parent = card,
	})

	local track = New("Frame", {
		Position = UDim2.fromOffset(14, 37),
		Size = UDim2.new(1, -28, 0, 6),
		BackgroundColor3 = Color3.fromRGB(40, 40, 52),
		Parent = card,
	})
	Corner(track, 3)

	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	})
	Corner(fill, 3)
	local gradient = New("UIGradient", { Parent = fill })
	window:OnTheme(function()
		gradient.Color = ColorSequence.new(Theme.AccentDark:Lerp(Theme.Accent, 0.4), Theme.Accent)
	end, maid)

	local knob = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0, 0, 0.5, 0),
		Size = UDim2.fromOffset(14, 14),
		BackgroundColor3 = Color3.new(1, 1, 1),
		ZIndex = 2,
		Parent = track,
	})
	Corner(knob, 7)
	Stroke(knob, Theme.Accent, 0, 2)

	local function Render()
		local alpha = (maxValue == minValue) and 0 or (value - minValue) / (maxValue - minValue)
		Tween(fill, 0.08, { Size = UDim2.new(alpha, 0, 1, 0) }, Enum.EasingStyle.Linear)
		Tween(knob, 0.08, { Position = UDim2.new(alpha, 0, 0.5, 0) }, Enum.EasingStyle.Linear)
		valueLabel.Text = tostring(value) .. suffix
	end

	if config.Flag then
		window.Flags[config.Flag] = value
	end
	Render()

	local obj = { Instance = card }
	function obj:Set(newValue, silent)
		newValue = Snap(tonumber(newValue) or value)
		local changed = newValue ~= value
		value = newValue
		Render()
		if config.Flag then
			window.Flags[config.Flag] = value
		end
		if changed and not silent then
			SafeCall(config.Callback, value)
		end
	end
	function obj:Get()
		return value
	end
	function obj:SetName(text)
		nameLabel.Text = tostring(text)
	end
	function obj:Destroy()
		maid:Clean()
		card:Destroy()
	end

	local dragging = false
	local function FromInput(input)
		local width = track.AbsoluteSize.X
		if width <= 0 then
			return
		end
		local alpha = math.clamp((input.Position.X - track.AbsolutePosition.X) / width, 0, 1)
		obj:Set(minValue + (maxValue - minValue) * alpha)
	end

	local hit = New("TextButton", {
		Position = UDim2.fromOffset(8, 26),
		Size = UDim2.new(1, -16, 0, 26),
		ZIndex = 3,
		Parent = card,
	})

	hit.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			self.Scroll.ScrollingEnabled = false
			Tween(knob, 0.12, { Size = UDim2.fromOffset(18, 18) })
			FromInput(input)
		end
	end)

	maid:Give(UserInputService.InputChanged:Connect(function(input)
		if
			dragging
			and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch)
		then
			FromInput(input)
		end
	end))

	maid:Give(UserInputService.InputEnded:Connect(function(input)
		if
			dragging
			and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)
		then
			dragging = false
			self.Scroll.ScrollingEnabled = true
			Tween(knob, 0.15, { Size = UDim2.fromOffset(14, 14) })
		end
	end))

	maid:Give(function()
		if self.Scroll then
			self.Scroll.ScrollingEnabled = true
		end
	end)

	return obj
end

-- ─── Dropdown ───────────────────────────────────────────────────
function Tab:CreateDropdown(config)
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()
	local card, stroke = self:_NewCard(40, "Dropdown")

	local options = {}
	for _, option in ipairs(config.Options or {}) do
		table.insert(options, option)
	end
	local multi = config.MultipleOptions == true
	local selected = {}
	local isOpen = false

	local current = config.CurrentOption
	if type(current) == "table" then
		if not multi then
			current = current[1]
		end
	end
	if type(current) == "table" then
		for _, v in ipairs(current) do
			selected[v] = true
		end
	elseif current ~= nil then
		selected[current] = true
	end

	local nameLabel = New("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0.5, -14, 0, 40),
		Text = tostring(config.Name or "Dropdown"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	local valueLabel = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -38, 0, 0),
		Size = UDim2.new(0.5, -24, 0, 40),
		Text = "",
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Right,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	local arrow = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -12, 0, 10),
		Size = UDim2.fromOffset(20, 20),
		Text = "▾",
		Font = Font.Bold,
		TextSize = 16,
		TextColor3 = Theme.Accent,
		Parent = card,
	})
	window:OnTheme(function()
		arrow.TextColor3 = Theme.Accent
	end, maid)

	local header = New("TextButton", { Size = UDim2.new(1, 0, 0, 40), ZIndex = 2, Parent = card })
	ApplyHover(card, stroke, header)

	local list = New("ScrollingFrame", {
		Position = UDim2.fromOffset(10, 46),
		Size = UDim2.new(1, -20, 0, 38),
		BackgroundColor3 = Theme.Input,
		BackgroundTransparency = 0,
		ScrollBarThickness = 2,
		ScrollBarImageColor3 = Theme.Accent,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		ElasticBehavior = Enum.ElasticBehavior.Never,
		Parent = card,
	})
	Corner(list, 8)
	Stroke(list, Theme.Stroke, 0, 1)
	Padding(list, 4, 4, 4, 4)
	New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder, Parent = list })
	window:OnTheme(function()
		list.ScrollBarImageColor3 = Theme.Accent
	end, maid)

	local optionButtons = {}

	local function GetValue()
		if multi then
			local result = {}
			for _, option in ipairs(options) do
				if selected[option] then
					table.insert(result, option)
				end
			end
			return result
		end
		for _, option in ipairs(options) do
			if selected[option] then
				return option
			end
		end
		return nil
	end

	local function UpdateHeader()
		if multi then
			local values = GetValue()
			local names = {}
			for _, v in ipairs(values) do
				table.insert(names, tostring(v))
			end
			valueLabel.Text = #names > 0 and table.concat(names, ", ") or tostring(config.Placeholder or "Select...")
		else
			local value = GetValue()
			valueLabel.Text = value ~= nil and tostring(value) or tostring(config.Placeholder or "Select...")
		end
	end

	local function UpdateVisuals()
		for option, parts in pairs(optionButtons) do
			local isSelected = selected[option] == true
			Tween(parts.Button, 0.15, { BackgroundTransparency = isSelected and 0.82 or 1 })
			Tween(parts.Label, 0.15, { TextColor3 = isSelected and Theme.Text or Theme.SubText })
			Tween(parts.Check, 0.15, { TextTransparency = isSelected and 0 or 1 })
		end
		UpdateHeader()
	end

	local function ListHeight()
		return math.clamp(#options * 30 + 8, 38, 168)
	end

	local function Resize()
		local height = ListHeight()
		list.Size = UDim2.new(1, -20, 0, height)
		Tween(card, 0.28, { Size = UDim2.new(1, 0, 0, isOpen and (46 + height + 10) or 40) })
		Tween(arrow, 0.25, { Rotation = isOpen and 180 or 0 })
	end

	local function Commit(silent)
		local value = GetValue()
		if config.Flag then
			window.Flags[config.Flag] = value
		end
		UpdateVisuals()
		if not silent then
			SafeCall(config.Callback, value)
		end
	end

	local function Pick(option)
		if multi then
			selected[option] = not selected[option] or nil
		else
			selected = { [option] = true }
			isOpen = false
			Resize()
		end
		Commit(false)
	end

	local function Rebuild()
		for _, parts in pairs(optionButtons) do
			parts.Button:Destroy()
		end
		optionButtons = {}
		for index, option in ipairs(options) do
			local button = New("TextButton", {
				Name = "Option",
				Size = UDim2.new(1, 0, 0, 28),
				BackgroundColor3 = Theme.Accent,
				BackgroundTransparency = 1,
				LayoutOrder = index,
				Parent = list,
			})
			Corner(button, 6)
			local label = New("TextLabel", {
				Position = UDim2.fromOffset(10, 0),
				Size = UDim2.new(1, -34, 1, 0),
				Text = tostring(option),
				TextSize = 13,
				TextColor3 = Theme.SubText,
				TextXAlignment = Enum.TextXAlignment.Left,
				TextTruncate = Enum.TextTruncate.AtEnd,
				Parent = button,
			})
			local check = New("TextLabel", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -8, 0.5, 0),
				Size = UDim2.fromOffset(16, 16),
				Text = "✓",
				Font = Font.Bold,
				TextSize = 14,
				TextColor3 = Theme.Accent,
				TextTransparency = 1,
				Parent = button,
			})
			optionButtons[option] = { Button = button, Label = label, Check = check }

			button.MouseEnter:Connect(function()
				if not selected[option] then
					Tween(button, 0.12, { BackgroundTransparency = 0.93 })
				end
			end)
			button.MouseLeave:Connect(function()
				if not selected[option] then
					Tween(button, 0.12, { BackgroundTransparency = 1 })
				end
			end)
			button.MouseButton1Click:Connect(function()
				Pick(option)
			end)
		end
		for option in pairs(selected) do
			if not table.find(options, option) then
				selected[option] = nil
			end
		end
		UpdateVisuals()
	end

	window:OnTheme(function()
		for _, parts in pairs(optionButtons) do
			parts.Button.BackgroundColor3 = Theme.Accent
			parts.Check.TextColor3 = Theme.Accent
		end
	end, maid)

	header.MouseButton1Click:Connect(function()
		isOpen = not isOpen
		Resize()
	end)

	Rebuild()
	if config.Flag then
		window.Flags[config.Flag] = GetValue()
	end

	local obj = { Instance = card }
	function obj:Set(value, silent)
		selected = {}
		if type(value) == "table" then
			if multi then
				for _, v in ipairs(value) do
					selected[v] = true
				end
			elseif value[1] ~= nil then
				selected[value[1]] = true
			end
		elseif value ~= nil then
			selected[value] = true
		end
		Commit(silent)
	end
	function obj:Get()
		return GetValue()
	end
	function obj:Refresh(newOptions, keepSelection)
		options = {}
		for _, option in ipairs(newOptions or {}) do
			table.insert(options, option)
		end
		if keepSelection == false then
			selected = {}
		end
		Rebuild()
		if isOpen then
			Resize()
		end
		if config.Flag then
			window.Flags[config.Flag] = GetValue()
		end
	end
	function obj:SetName(text)
		nameLabel.Text = tostring(text)
	end
	function obj:Destroy()
		maid:Clean()
		card:Destroy()
	end
	return obj
end

-- ─── Input ──────────────────────────────────────────────────────
function Tab:CreateInput(config)
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()
	local card, stroke = self:_NewCard(40, "Input")
	ApplyHover(card, stroke)

	local nameLabel = New("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(0.5, -14, 1, 0),
		Text = tostring(config.Name or "Input"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	local box = New("TextBox", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0.5, -10, 0, 26),
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Input,
		Font = Font.Regular,
		TextSize = 13,
		Text = tostring(config.CurrentValue or ""),
		PlaceholderText = tostring(config.PlaceholderText or "Type here..."),
		PlaceholderColor3 = Color3.fromRGB(100, 100, 118),
		ClearTextOnFocus = false,
		TextXAlignment = Enum.TextXAlignment.Left,
		ClipsDescendants = true,
		Parent = card,
	})
	Corner(box, 6)
	Padding(box, 0, 8, 0, 8)
	New("UISizeConstraint", { MinSize = Vector2.new(90, 0), MaxSize = Vector2.new(260, 100), Parent = box })
	local boxStroke = Stroke(box, Theme.Stroke, 0, 1)

	if config.Flag then
		window.Flags[config.Flag] = box.Text
	end

	box.Focused:Connect(function()
		Tween(boxStroke, 0.2, { Color = Theme.Accent })
	end)

	box.FocusLost:Connect(function()
		Tween(boxStroke, 0.2, { Color = Theme.Stroke })
		local text = box.Text
		if config.NumbersOnly then
			text = text:gsub("[^%d%.%-]", "")
			box.Text = text
		end
		if config.Flag then
			window.Flags[config.Flag] = text
		end
		SafeCall(config.Callback, text)
		if config.RemoveTextAfterFocusLost then
			box.Text = ""
		end
	end)

	if config.OnChanged then
		box:GetPropertyChangedSignal("Text"):Connect(function()
			SafeCall(config.OnChanged, box.Text)
		end)
	end

	local obj = { Instance = card }
	function obj:Set(text, silent)
		box.Text = tostring(text or "")
		if config.Flag then
			window.Flags[config.Flag] = box.Text
		end
		if not silent then
			SafeCall(config.Callback, box.Text)
		end
	end
	function obj:Get()
		return box.Text
	end
	function obj:SetName(text)
		nameLabel.Text = tostring(text)
	end
	function obj:Destroy()
		maid:Clean()
		card:Destroy()
	end
	return obj
end

-- ─── Label ──────────────────────────────────────────────────────
function Tab:CreateLabel(config)
	if type(config) == "string" then
		config = { Text = config }
	end
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()
	local card = self:_NewCard(nil, "Label")
	card.BackgroundColor3 = Theme.Input
	Padding(card, 9, 14, 9, 14)
	New("UISizeConstraint", { MinSize = Vector2.new(0, 34), Parent = card })

	local label = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(config.Text or config.Name or "Label"),
		TextSize = 13,
		TextColor3 = config.Color or Theme.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = card,
	})

	local obj = { Instance = card }
	function obj:Set(text)
		label.Text = tostring(text)
	end
	function obj:SetColor(color)
		label.TextColor3 = color
	end
	function obj:Destroy()
		maid:Clean()
		card:Destroy()
	end
	return obj
end

-- ─── Paragraph ──────────────────────────────────────────────────
function Tab:CreateParagraph(config)
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()
	local card, stroke = self:_NewCard(nil, "Paragraph")
	ApplyHover(card, stroke)
	Padding(card, 11, 14, 12, 14)
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })

	local title = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(config.Title or "Paragraph"),
		Font = Font.Bold,
		TextSize = 14,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		LayoutOrder = 1,
		Parent = card,
	})

	local content = New("TextLabel", {
		Size = UDim2.new(1, 0, 0, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Text = tostring(config.Content or ""),
		Font = Font.Regular,
		TextSize = 13,
		TextColor3 = Theme.SubText,
		TextWrapped = true,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextYAlignment = Enum.TextYAlignment.Top,
		LayoutOrder = 2,
		Parent = card,
	})

	local obj = { Instance = card }
	function obj:Set(newTitle, newContent)
		if newTitle ~= nil then
			title.Text = tostring(newTitle)
		end
		if newContent ~= nil then
			content.Text = tostring(newContent)
		end
	end
	function obj:Destroy()
		maid:Clean()
		card:Destroy()
	end
	return obj
end

-- ─── Keybind ────────────────────────────────────────────────────
function Tab:CreateKeybind(config)
	config = config or {}
	local window = self.Window
	local maid = window:NewMaid()
	local card, stroke = self:_NewCard(40, "Keybind")

	local hold = config.HoldToInteract == true

	local function ToKeyCode(value)
		if typeof(value) == "EnumItem" then
			return value
		end
		if type(value) == "string" and value ~= "None" then
			local ok, keyCode = pcall(function()
				return Enum.KeyCode[value]
			end)
			if ok then
				return keyCode
			end
		end
		return nil
	end

	local keyCode = ToKeyCode(config.CurrentKeybind)
	local binding = false
	local isDown = false

	local nameLabel = New("TextLabel", {
		Position = UDim2.fromOffset(14, 0),
		Size = UDim2.new(1, -120, 1, 0),
		Text = tostring(config.Name or "Keybind"),
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = card,
	})

	local bindButton = New("TextButton", {
		AnchorPoint = Vector2.new(1, 0.5),
		Position = UDim2.new(1, -10, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 26),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Input,
		Text = keyCode and keyCode.Name or "None",
		Font = Font.Bold,
		TextSize = 12,
		ZIndex = 2,
		Parent = card,
	})
	Corner(bindButton, 6)
	Padding(bindButton, 0, 12, 0, 12)
	New("UISizeConstraint", { MinSize = Vector2.new(56, 26), Parent = bindButton })
	local bindStroke = Stroke(bindButton, Theme.Stroke, 0, 1)

	ApplyHover(card, stroke)

	if config.Flag then
		window.Flags[config.Flag] = keyCode and keyCode.Name or "None"
	end

	local function Display()
		bindButton.Text = keyCode and keyCode.Name or "None"
		Tween(bindStroke, 0.2, { Color = Theme.Stroke })
		bindButton.TextColor3 = Theme.Text
	end

	local function StopBinding()
		binding = false
		BindState.Active = false
		BindState.Last = os.clock()
		Display()
	end

	bindButton.MouseButton1Click:Connect(function()
		if binding then
			StopBinding()
			return
		end
		binding = true
		BindState.Active = true
		bindButton.Text = "..."
		bindButton.TextColor3 = Theme.Accent
		Tween(bindStroke, 0.2, { Color = Theme.Accent })
	end)

	maid:Give(UserInputService.InputBegan:Connect(function(input)
		if binding then
			if input.UserInputType == Enum.UserInputType.Keyboard then
				if input.KeyCode == Enum.KeyCode.Escape then
					-- cancel, keep previous key
				elseif input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.Delete then
					keyCode = nil
					if config.Flag then
						window.Flags[config.Flag] = "None"
					end
					SafeCall(config.OnChanged, "None")
				else
					keyCode = input.KeyCode
					if config.Flag then
						window.Flags[config.Flag] = keyCode.Name
					end
					SafeCall(config.OnChanged, keyCode.Name)
				end
				StopBinding()
			end
			return
		end

		if BindingBusy() or not keyCode then
			return
		end
		if input.KeyCode == keyCode and not UserInputService:GetFocusedTextBox() then
			isDown = true
			SafeCall(config.Callback, true)
		end
	end))

	maid:Give(UserInputService.InputEnded:Connect(function(input)
		if hold and isDown and keyCode and input.KeyCode == keyCode then
			isDown = false
			SafeCall(config.Callback, false)
		end
	end))

	maid:Give(function()
		if binding then
			BindState.Active = false
		end
	end)

	local obj = { Instance = card }
	function obj:Set(value, silent)
		keyCode = ToKeyCode(value)
		Display()
		if config.Flag then
			window.Flags[config.Flag] = keyCode and keyCode.Name or "None"
		end
		if not silent then
			SafeCall(config.OnChanged, keyCode and keyCode.Name or "None")
		end
	end
	function obj:Get()
		return keyCode and keyCode.Name or "None"
	end
	function obj:SetName(text)
		nameLabel.Text = tostring(text)
	end
	function obj:Destroy()
		maid:Clean()
		card:Destroy()
	end
	return obj
end

-- ════════════════════════════════════════════════════════════════
--  HOME PAGE (live statistics)
-- ════════════════════════════════════════════════════════════════
local function BuildHome(window, tab)
	local scroll = tab.Scroll
	local maid = window:NewMaid()
	local white = Color3.new(1, 1, 1)

	local function CardGradient(parent)
		return New("UIGradient", {
			Color = ColorSequence.new(Color3.fromRGB(28, 28, 37), Color3.fromRGB(17, 17, 23)),
			Rotation = 135,
			Parent = parent,
		})
	end

	-- ── Welcome banner ──────────────────────────────────────────
	local banner = New("Frame", {
		Name = "Banner",
		Size = UDim2.new(1, 0, 0, 84),
		BackgroundColor3 = white,
		ClipsDescendants = true,
		LayoutOrder = 1,
		Parent = scroll,
	})
	Corner(banner, 12)
	Stroke(banner, Theme.Stroke, 0, 1)
	local bannerGradient = New("UIGradient", { Rotation = 20, Parent = banner })
	window:OnTheme(function()
		bannerGradient.Color = ColorSequence.new(Theme.AccentDark:Lerp(Theme.Element, 0.55), Theme.Element)
	end, maid)

	local avatarFrame = New("Frame", {
		Position = UDim2.fromOffset(16, 16),
		Size = UDim2.fromOffset(52, 52),
		BackgroundColor3 = Theme.Input,
		Parent = banner,
	})
	Corner(avatarFrame, 26)
	local avatarStroke = Stroke(avatarFrame, Theme.Accent, 0, 2)
	window:OnTheme(function()
		avatarStroke.Color = Theme.Accent
	end, maid)
	local avatar = New("ImageLabel", { Size = UDim2.new(1, 0, 1, 0), Parent = avatarFrame })
	Corner(avatar, 26)

	task.spawn(function()
		local ok, content = pcall(function()
			return Players:GetUserThumbnailAsync(
				LocalPlayer.UserId,
				Enum.ThumbnailType.HeadShot,
				Enum.ThumbnailSize.Size100x100
			)
		end)
		if ok and content and avatar.Parent then
			avatar.Image = content
		end
		if window.UserAvatar then
			window.UserAvatar(content)
		end
	end)

	New("TextLabel", {
		Position = UDim2.fromOffset(82, 15),
		Size = UDim2.new(1, -170, 0, 26),
		Text = "Welcome back, " .. LocalPlayer.DisplayName,
		Font = Font.Bold,
		TextSize = 18,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = banner,
	})

	local sessionLabel = New("TextLabel", {
		Position = UDim2.fromOffset(82, 43),
		Size = UDim2.new(1, -170, 0, 20),
		Text = "Session 00:00:00",
		TextSize = 12,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = banner,
	})

	local versionPill = New("TextLabel", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, -16, 0, 16),
		Size = UDim2.fromOffset(0, 22),
		AutomaticSize = Enum.AutomaticSize.X,
		BackgroundTransparency = 0.85,
		BackgroundColor3 = Theme.Accent,
		Text = "v" .. Library.Version,
		Font = Font.Bold,
		TextSize = 11,
		TextColor3 = Theme.Accent,
		Parent = banner,
	})
	Corner(versionPill, 11)
	Padding(versionPill, 0, 10, 0, 10)
	window:OnTheme(function()
		versionPill.BackgroundColor3 = Theme.Accent
		versionPill.TextColor3 = Theme.Accent
	end, maid)

	-- ── Stat grid ───────────────────────────────────────────────
	local grid = New("Frame", {
		Name = "Stats",
		Size = UDim2.new(1, 0, 0, 120),
		BackgroundTransparency = 1,
		LayoutOrder = 2,
		Parent = scroll,
	})
	New("UIGridLayout", {
		CellSize = UDim2.new(1 / 3, -7, 1, 0),
		CellPadding = UDim2.fromOffset(10, 10),
		SortOrder = Enum.SortOrder.LayoutOrder,
		FillDirection = Enum.FillDirection.Horizontal,
		Parent = grid,
	})

	local stats = {}

	local function MakeStat(order, def)
		local card = New("Frame", {
			Name = def.Title,
			BackgroundColor3 = white,
			ClipsDescendants = true,
			LayoutOrder = order,
			Parent = grid,
		})
		Corner(card, 12)
		local stroke = Stroke(card, Theme.Stroke, 0, 1)
		CardGradient(card)
		local scale = New("UIScale", { Parent = card })

		local glow = New("Frame", {
			AnchorPoint = Vector2.new(1, 0),
			Position = UDim2.new(1, 26, 0, -26),
			Size = UDim2.fromOffset(100, 100),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.9,
			Parent = card,
		})
		Corner(glow, 50)

		local iconBox = New("Frame", {
			Position = UDim2.fromOffset(14, 12),
			Size = UDim2.fromOffset(28, 28),
			BackgroundColor3 = Theme.Accent,
			BackgroundTransparency = 0.85,
			Parent = card,
		})
		Corner(iconBox, 8)
		local icon = MakeIcon(iconBox, def.Icon, 16)
		icon.AnchorPoint = Vector2.new(0.5, 0.5)
		icon.Position = UDim2.new(0.5, 0, 0.5, 0)

		New("TextLabel", {
			Position = UDim2.fromOffset(50, 12),
			Size = UDim2.new(1, -60, 0, 28),
			Text = def.Title,
			TextSize = 13,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = card,
		})

		local valueLabel = New("TextLabel", {
			Position = UDim2.fromOffset(14, 44),
			Size = UDim2.new(1, -28, 0, 36),
			Text = "0",
			RichText = true,
			Font = Font.Bold,
			TextSize = 30,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = card,
		})

		local descLabel = New("TextLabel", {
			Position = UDim2.fromOffset(14, 82),
			Size = UDim2.new(1, -28, 0, 16),
			Text = def.Description or "",
			TextSize = 11,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = card,
		})

		local barTrack = New("Frame", {
			Position = UDim2.fromOffset(14, 106),
			Size = UDim2.new(1, -28, 0, 4),
			BackgroundColor3 = Color3.fromRGB(38, 38, 50),
			Parent = card,
		})
		Corner(barTrack, 2)
		local barFill = New("Frame", {
			Size = UDim2.new(0, 0, 1, 0),
			BackgroundColor3 = Theme.Accent,
			Parent = barTrack,
		})
		Corner(barFill, 2)

		window:OnTheme(function()
			glow.BackgroundColor3 = Theme.Accent
			iconBox.BackgroundColor3 = Theme.Accent
		end, maid)

		local click = New("TextButton", { Size = UDim2.new(1, 0, 1, 0), ZIndex = 5, Parent = card })
		click.MouseEnter:Connect(function()
			Tween(scale, 0.2, { Scale = 1.03 })
			Tween(stroke, 0.2, { Color = Theme.Accent })
			Tween(glow, 0.3, { BackgroundTransparency = 0.72 })
		end)
		click.MouseLeave:Connect(function()
			Tween(scale, 0.2, { Scale = 1 })
			Tween(stroke, 0.2, { Color = Theme.Stroke })
			Tween(glow, 0.3, { BackgroundTransparency = 0.9 })
		end)
		click.MouseButton1Down:Connect(function()
			Tween(scale, 0.1, { Scale = 0.98 })
		end)
		click.MouseButton1Up:Connect(function()
			Tween(scale, 0.15, { Scale = 1.03 })
		end)
		click.MouseButton1Click:Connect(function()
			SafeCall(def.OnClick)
		end)

		local stat = {
			target = 0,
			display = 0,
			shown = -1,
			color = nil,
			format = def.Format,
			valueLabel = valueLabel,
			descLabel = descLabel,
			fill = barFill,
		}

		function stat:Step(dt)
			local diff = self.target - self.display
			if math.abs(diff) < 0.01 then
				self.display = self.target
			else
				self.display = self.display + diff * (1 - math.exp(-dt * 12))
			end
			local shown = math.floor(self.display + 0.5)
			if shown ~= self.shown then
				self.shown = shown
				self.valueLabel.Text = self.format(shown)
			end
		end

		function stat:SetStatus(color, description, alpha)
			if description and self.descLabel.Text ~= description then
				self.descLabel.Text = description
			end
			if color and self.color ~= color then
				self.color = color
				Tween(self.valueLabel, 0.3, { TextColor3 = color })
				Tween(self.fill, 0.3, { BackgroundColor3 = color })
			end
			if alpha then
				Tween(self.fill, 0.4, { Size = UDim2.new(math.clamp(alpha, 0, 1), 0, 1, 0) })
			end
		end

		table.insert(stats, stat)
		return stat
	end

	local function WithUnit(unit)
		return function(n)
			return string.format('%d<font size="15" color="rgb(148,148,166)">%s</font>', n, unit)
		end
	end

	local playersStat = MakeStat(1, {
		Icon = "players",
		Title = "Players Online",
		Description = "In this server",
		Format = function(n)
			return tostring(n)
		end,
		OnClick = function()
			local names = {}
			for index, player in ipairs(Players:GetPlayers()) do
				if index > 12 then
					table.insert(names, "...")
					break
				end
				table.insert(names, player.Name)
			end
			window:Notify({
				Title = "Players in server (" .. #Players:GetPlayers() .. ")",
				Content = table.concat(names, ", "),
				Duration = 5,
			})
		end,
	})

	local fpsStat = MakeStat(2, {
		Icon = "fps",
		Title = "FPS",
		Description = "Frames per second",
		Format = function(n)
			return tostring(n)
		end,
	})

	local pingStat = MakeStat(3, {
		Icon = "ping",
		Title = "Ping",
		Description = "Network latency",
		Format = WithUnit(" ms"),
	})

	-- ── Game information card ───────────────────────────────────
	local info = New("Frame", {
		Name = "GameInfo",
		Size = UDim2.new(1, 0, 0, 186),
		BackgroundColor3 = white,
		ClipsDescendants = true,
		LayoutOrder = 3,
		Parent = scroll,
	})
	Corner(info, 12)
	local infoStroke = Stroke(info, Theme.Stroke, 0, 1)
	CardGradient(info)

	local infoIconBox = New("Frame", {
		Position = UDim2.fromOffset(14, 12),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Theme.Accent,
		BackgroundTransparency = 0.85,
		Parent = info,
	})
	Corner(infoIconBox, 8)
	local infoIcon = MakeIcon(infoIconBox, "game", 16)
	infoIcon.AnchorPoint = Vector2.new(0.5, 0.5)
	infoIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
	window:OnTheme(function()
		infoIconBox.BackgroundColor3 = Theme.Accent
	end, maid)

	New("TextLabel", {
		Position = UDim2.fromOffset(50, 10),
		Size = UDim2.new(1, -60, 0, 18),
		Text = "Game Information",
		Font = Font.Bold,
		TextSize = 14,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = info,
	})
	New("TextLabel", {
		Position = UDim2.fromOffset(50, 28),
		Size = UDim2.new(1, -60, 0, 14),
		Text = "Live details about your current session",
		TextSize = 11,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = info,
	})

	local rows = New("Frame", {
		Position = UDim2.fromOffset(14, 56),
		Size = UDim2.new(1, -28, 1, -66),
		BackgroundTransparency = 1,
		Parent = info,
	})
	New("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = rows })

	local function MakeRow(order, label, valueText, copyText)
		local row = New("Frame", {
			Size = UDim2.new(1, 0, 0, 26),
			BackgroundColor3 = Theme.Input,
			BackgroundTransparency = 0,
			LayoutOrder = order,
			Parent = rows,
		})
		Corner(row, 7)
		New("TextLabel", {
			Position = UDim2.fromOffset(10, 0),
			Size = UDim2.new(0, 74, 1, 0),
			Text = label,
			TextSize = 12,
			TextColor3 = Theme.SubText,
			TextXAlignment = Enum.TextXAlignment.Left,
			Parent = row,
		})
		local value = New("TextLabel", {
			Position = UDim2.fromOffset(86, 0),
			Size = UDim2.new(1, copyText and -150 or -96, 1, 0),
			Text = valueText,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextTruncate = Enum.TextTruncate.AtEnd,
			Parent = row,
		})
		if copyText then
			local copyButton = New("TextButton", {
				AnchorPoint = Vector2.new(1, 0.5),
				Position = UDim2.new(1, -6, 0.5, 0),
				Size = UDim2.fromOffset(46, 18),
				BackgroundTransparency = 0.85,
				BackgroundColor3 = Theme.Accent,
				Text = "Copy",
				Font = Font.Bold,
				TextSize = 10,
				TextColor3 = Theme.Accent,
				Parent = row,
			})
			Corner(copyButton, 6)
			window:OnTheme(function()
				copyButton.BackgroundColor3 = Theme.Accent
				copyButton.TextColor3 = Theme.Accent
			end, maid)
			copyButton.MouseEnter:Connect(function()
				Tween(copyButton, 0.15, { BackgroundTransparency = 0.7 })
			end)
			copyButton.MouseLeave:Connect(function()
				Tween(copyButton, 0.15, { BackgroundTransparency = 0.85 })
			end)
			copyButton.MouseButton1Click:Connect(function()
				local clip = (typeof(setclipboard) == "function" and setclipboard)
					or (typeof(toclipboard) == "function" and toclipboard)
				if clip then
					local ok = pcall(clip, copyText)
					window:Notify({
						Title = ok and "Copied" or "Copy failed",
						Content = ok and (label .. " copied to clipboard.") or "Clipboard error.",
						Type = ok and "Success" or "Error",
						Duration = 2.5,
					})
				else
					window:Notify({
						Title = "Clipboard unavailable",
						Content = "Your executor does not expose setclipboard.",
						Type = "Warning",
						Duration = 3,
					})
				end
			end)
		end
		return value
	end

	local placeId = tostring(game.PlaceId)
	local userText = LocalPlayer.Name
	if LocalPlayer.DisplayName ~= LocalPlayer.Name then
		userText = LocalPlayer.Name .. "  (" .. LocalPlayer.DisplayName .. ")"
	end
	local jobId = tostring(game.JobId)
	local jobText = (jobId == "" and "Studio / Local") or jobId

	local gameValue = MakeRow(1, "Game", "Loading...", nil)
	MakeRow(2, "Place ID", placeId, placeId)
	MakeRow(3, "Username", userText, nil)
	MakeRow(4, "Server ID", jobText, jobId ~= "" and jobId or nil)

	task.spawn(function()
		local name
		if game.PlaceId ~= 0 then
			local ok, productInfo = pcall(function()
				return MarketplaceService:GetProductInfo(game.PlaceId)
			end)
			if ok and productInfo and productInfo.Name then
				name = productInfo.Name
			end
		end
		name = name or ((game.PlaceId == 0) and "Unpublished Place" or game.Name)
		if gameValue.Parent then
			gameValue.Text = name
		end
	end)

	info.MouseEnter:Connect(function()
		Tween(infoStroke, 0.2, { Color = Theme.StrokeHover })
	end)
	info.MouseLeave:Connect(function()
		Tween(infoStroke, 0.2, { Color = Theme.Stroke })
	end)

	-- ── Live data ───────────────────────────────────────────────
	local function RefreshPlayers()
		local count = #Players:GetPlayers()
		local maxPlayers = Players.MaxPlayers
		playersStat.target = count
		playersStat:SetStatus(
			Theme.Text,
			string.format("of %d max players", maxPlayers),
			maxPlayers > 0 and (count / maxPlayers) or 0
		)
		playersStat.fill.BackgroundColor3 = Theme.Accent
	end

	maid:Give(Players.PlayerAdded:Connect(function()
		task.defer(RefreshPlayers)
	end))
	maid:Give(Players.PlayerRemoving:Connect(function()
		task.defer(RefreshPlayers)
	end))
	RefreshPlayers()

	local frames, accumulator = 0, 0
	local samples = {}
	local timer = 0
	local sessionStart = os.clock()

	local function RefreshPing()
		local ping = GetPing()
		pingStat.target = ping
		local color, label
		if ping < 60 then
			color, label = Theme.Good, "Excellent connection"
		elseif ping < 120 then
			color, label = Theme.Good, "Good connection"
		elseif ping < 200 then
			color, label = Theme.Warn, "Fair connection"
		else
			color, label = Theme.Bad, "Poor connection"
		end
		pingStat:SetStatus(color, label, 1 - math.clamp(ping / 300, 0, 1))
	end
	RefreshPing()

	maid:Give(RunService.Heartbeat:Connect(function(dt)
		frames = frames + 1
		accumulator = accumulator + dt

		if accumulator >= 0.25 then
			local fps = frames / accumulator
			frames, accumulator = 0, 0
			fpsStat.target = fps

			table.insert(samples, fps)
			if #samples > 40 then
				table.remove(samples, 1)
			end
			local sum, low = 0, math.huge
			for _, sample in ipairs(samples) do
				sum = sum + sample
				low = math.min(low, sample)
			end
			local average = sum / #samples

			local color = (fps >= 50 and Theme.Good) or (fps >= 30 and Theme.Warn) or Theme.Bad
			fpsStat:SetStatus(
				color,
				string.format("Avg %d  ·  Low %d", math.floor(average + 0.5), math.floor(low + 0.5)),
				fps / 60
			)
		end

		for _, stat in ipairs(stats) do
			stat:Step(dt)
		end

		timer = timer + dt
		if timer >= 1 then
			timer = 0
			RefreshPing()
			RefreshPlayers()
			local elapsed = math.floor(os.clock() - sessionStart)
			sessionLabel.Text = string.format(
				"%s  ·  Session %02d:%02d:%02d",
				window.Name,
				math.floor(elapsed / 3600),
				math.floor(elapsed / 60) % 60,
				elapsed % 60
			)
		end
	end))
end

-- ════════════════════════════════════════════════════════════════
--  LOADING SCREEN
-- ════════════════════════════════════════════════════════════════
local function RunLoading(window, config, onDone)
	local gui = window.Gui
	local card = New("CanvasGroup", {
		Name = "Loading",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.new(0.5, 0, 0.5, 20),
		Size = UDim2.fromOffset(340, 160),
		BackgroundColor3 = Theme.Background,
		GroupTransparency = 1,
		Parent = gui,
	})
	Corner(card, 16)
	Stroke(card, Theme.Stroke, 0, 1)
	New("UIScale", { Scale = math.min(1, (workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.X or 800) / 400), Parent = card })

	local logo = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 20),
		Size = UDim2.fromOffset(38, 38),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = card,
	})
	Corner(logo, 11)
	local logoGradient = New("UIGradient", { Rotation = 45, Parent = logo })
	logoGradient.Color = ColorSequence.new(Theme.Accent, Theme.AccentDark)
	New("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Text = string.upper(string.sub(window.Name, 1, 1)),
		Font = Font.Bold,
		TextSize = 20,
		Parent = logo,
	})

	New("TextLabel", {
		Position = UDim2.fromOffset(0, 66),
		Size = UDim2.new(1, 0, 0, 22),
		Text = tostring(config.LoadingTitle or window.Name),
		Font = Font.Bold,
		TextSize = 18,
		Parent = card,
	})
	New("TextLabel", {
		Position = UDim2.fromOffset(0, 88),
		Size = UDim2.new(1, 0, 0, 16),
		Text = tostring(config.LoadingSubtitle or ""),
		TextSize = 12,
		TextColor3 = Theme.SubText,
		Parent = card,
	})

	local track = New("Frame", {
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 122),
		Size = UDim2.new(1, -60, 0, 5),
		BackgroundColor3 = Color3.fromRGB(38, 38, 50),
		Parent = card,
	})
	Corner(track, 3)
	local fill = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = track,
	})
	Corner(fill, 3)
	New("UIGradient", {
		Color = ColorSequence.new(Theme.AccentDark:Lerp(Theme.Accent, 0.4), Theme.Accent),
		Parent = fill,
	})

	local status = New("TextLabel", {
		Position = UDim2.fromOffset(0, 134),
		Size = UDim2.new(1, 0, 0, 16),
		Text = "Initializing",
		TextSize = 11,
		TextColor3 = Theme.SubText,
		Parent = card,
	})

	Tween(card, 0.4, { GroupTransparency = 0, Position = UDim2.new(0.5, 0, 0.5, 0) })

	local steps = {
		{ "Initializing", 0.25 },
		{ "Loading components", 0.6 },
		{ "Building interface", 0.88 },
		{ "Ready", 1 },
	}
	for _, step in ipairs(steps) do
		if window.Destroyed then
			return
		end
		status.Text = step[1]
		Tween(fill, 0.35, { Size = UDim2.new(step[2], 0, 1, 0) })
		task.wait(0.4)
	end

	task.wait(0.15)
	if window.Destroyed then
		return
	end
	Tween(card, 0.35, { GroupTransparency = 1, Position = UDim2.new(0.5, 0, 0.5, -20) })
	task.wait(0.37)
	card:Destroy()
	onDone()
end

-- ════════════════════════════════════════════════════════════════
--  CREATE WINDOW
-- ════════════════════════════════════════════════════════════════
function Library:CreateWindow(config)
	config = type(config) == "table" and config or {}

	local name = tostring(config.Name or "Rexity Hub")
	local subtitle = tostring(config.LoadingSubtitle or config.Subtitle or "Premium Edition")
	local sanitized = name:gsub("%W", "")
	local guiName = "RexityLib_" .. sanitized

	if typeof(config.Accent) == "Color3" then
		Theme.Accent = config.Accent
		Theme.AccentDark = config.Accent:Lerp(Color3.new(0, 0, 0), 0.55)
	end

	-- Replace any previous instance of the same window
	_G.RexityWindows = _G.RexityWindows or {}
	local previous = _G.RexityWindows[guiName]
	if previous and previous.Destroy then
		pcall(previous.Destroy, previous)
	end
	PurgeOld(guiName)

	local baseSize = typeof(config.Size) == "Vector2" and config.Size or Vector2.new(680, 440)

	local window = setmetatable({
		Name = name,
		GuiName = guiName,
		Maid = Maid.new(),
		Flags = {},
		Tabs = {},
		TabList = {},
		ThemeCallbacks = {},
		BaseSize = baseSize,
		UserScale = 1,
		Visible = true,
		Minimized = false,
		Loading = true,
		Destroyed = false,
		NotifyCounter = 0,
		OnClose = config.OnClose,
	}, Window)
	_G.RexityWindows[guiName] = window

	window.ToggleKey = Enum.KeyCode.RightShift
	if config.ToggleKey ~= nil then
		window:SetToggleKey(config.ToggleKey)
	end

	-- ── ScreenGui & root ────────────────────────────────────────
	local gui = New("ScreenGui", {
		Name = guiName,
		ResetOnSpawn = false,
		IgnoreGuiInset = true,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		DisplayOrder = 100,
	})
	MountGui(gui)
	window.Gui = gui

	local holder = New("Frame", {
		Name = "Holder",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(baseSize.X, baseSize.Y),
		BackgroundTransparency = 1,
		Visible = false,
		Parent = gui,
	})
	window.Holder = holder
	window.ScaleObject = New("UIScale", { Parent = holder })

	local shadow = New("ImageLabel", {
		Name = "Shadow",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, -35),
		Size = UDim2.new(1, 70, 1, 70),
		Image = "rbxassetid://6014261993",
		ImageColor3 = Color3.new(0, 0, 0),
		ImageTransparency = 0.45,
		ScaleType = Enum.ScaleType.Slice,
		SliceCenter = Rect.new(49, 49, 450, 450),
		ZIndex = 0,
		Parent = holder,
	})
	window.Shadow = shadow

	local main = New("Frame", {
		Name = "Main",
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, 0, 0, 0),
		Size = UDim2.new(1, 0, 1, 0),
		BackgroundColor3 = Theme.Background,
		ClipsDescendants = true,
		Active = true,
		Parent = holder,
	})
	Corner(main, 14)
	Stroke(main, Theme.Stroke, 0, 1)
	window.Main = main
	window.Pop = New("UIScale", { Scale = 0.9, Parent = main })

	-- ── Top bar ─────────────────────────────────────────────────
	local topBar = New("Frame", {
		Name = "TopBar",
		Size = UDim2.new(1, 0, 0, 48),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = main,
	})
	New("UIGradient", {
		Color = ColorSequence.new(Color3.fromRGB(24, 24, 33), Color3.fromRGB(15, 15, 21)),
		Rotation = 90,
		Parent = topBar,
	})

	local accentLine = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 0, 1, 0),
		Size = UDim2.new(1, 0, 0, 1),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = topBar,
	})
	local lineGradient = New("UIGradient", {
		Transparency = NumberSequence.new({
			NumberSequenceKeypoint.new(0, 0.1),
			NumberSequenceKeypoint.new(0.6, 0.6),
			NumberSequenceKeypoint.new(1, 1),
		}),
		Parent = accentLine,
	})

	local logo = New("Frame", {
		AnchorPoint = Vector2.new(0, 0.5),
		Position = UDim2.new(0, 14, 0.5, 0),
		Size = UDim2.fromOffset(28, 28),
		BackgroundColor3 = Color3.new(1, 1, 1),
		Parent = topBar,
	})
	Corner(logo, 8)
	local logoGradient = New("UIGradient", { Rotation = 45, Parent = logo })
	New("TextLabel", {
		Size = UDim2.new(1, 0, 1, 0),
		Text = string.upper(string.sub(name, 1, 1)),
		Font = Font.Bold,
		TextSize = 15,
		Parent = logo,
	})

	New("TextLabel", {
		Position = UDim2.fromOffset(52, 7),
		Size = UDim2.new(1, -180, 0, 18),
		Text = name,
		Font = Font.Bold,
		TextSize = 15,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = topBar,
	})
	New("TextLabel", {
		Position = UDim2.fromOffset(52, 25),
		Size = UDim2.new(1, -180, 0, 14),
		Text = subtitle,
		TextSize = 11,
		TextColor3 = Theme.SubText,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = topBar,
	})

	local function ControlButton(text, offsetX)
		local button = New("TextButton", {
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, offsetX, 0.5, 0),
			Size = UDim2.fromOffset(28, 28),
			BackgroundTransparency = 0,
			BackgroundColor3 = Theme.Element,
			Text = text,
			Font = Font.Bold,
			TextSize = 18,
			TextColor3 = Theme.SubText,
			Parent = topBar,
		})
		Corner(button, 8)
		return button
	end

	local closeButton = ControlButton("×", -14)
	local minButton = ControlButton("–", -48)
	window.MinButton = minButton

	local function Hover(button, color)
		button.MouseEnter:Connect(function()
			Tween(button, 0.15, { BackgroundColor3 = color, TextColor3 = Theme.Text })
		end)
		button.MouseLeave:Connect(function()
			Tween(button, 0.15, { BackgroundColor3 = Theme.Element, TextColor3 = Theme.SubText })
		end)
	end
	Hover(minButton, Theme.ElementHover)
	Hover(closeButton, Theme.Bad:Lerp(Theme.Element, 0.35))

	minButton.MouseButton1Click:Connect(function()
		window:SetMinimized(not window.Minimized)
	end)
	closeButton.MouseButton1Click:Connect(function()
		task.spawn(function()
			window:Close()
		end)
	end)

	MakeDraggable(topBar, holder, window.Maid)

	-- ── Body ────────────────────────────────────────────────────
	local body = New("Frame", {
		Name = "Body",
		Position = UDim2.fromOffset(0, 48),
		Size = UDim2.new(1, 0, 1, -48),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = main,
	})
	window.Body = body

	local sidebar = New("Frame", {
		Name = "Sidebar",
		Size = UDim2.new(0, 158, 1, 0),
		BackgroundColor3 = Theme.Sidebar,
		Parent = body,
	})
	New("Frame", {
		AnchorPoint = Vector2.new(1, 0),
		Position = UDim2.new(1, 0, 0, 0),
		Size = UDim2.new(0, 1, 1, 0),
		BackgroundColor3 = Theme.Stroke,
		Parent = sidebar,
	})

	New("TextLabel", {
		Position = UDim2.fromOffset(18, 10),
		Size = UDim2.new(1, -30, 0, 14),
		Text = "NAVIGATION",
		Font = Font.Bold,
		TextSize = 10,
		TextColor3 = Color3.fromRGB(100, 100, 120),
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = sidebar,
	})

	local tabHolder = New("ScrollingFrame", {
		Name = "Tabs",
		Position = UDim2.fromOffset(0, 28),
		Size = UDim2.new(1, -1, 1, -92),
		BackgroundTransparency = 1,
		ScrollBarThickness = 0,
		CanvasSize = UDim2.new(0, 0, 0, 0),
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		ScrollingDirection = Enum.ScrollingDirection.Y,
		Parent = sidebar,
	})
	Padding(tabHolder, 4, 10, 4, 10)
	New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = tabHolder })
	window.TabHolder = tabHolder

	-- User card
	local userCard = New("Frame", {
		AnchorPoint = Vector2.new(0, 1),
		Position = UDim2.new(0, 10, 1, -10),
		Size = UDim2.new(1, -21, 0, 48),
		BackgroundColor3 = Theme.Element,
		Parent = sidebar,
	})
	Corner(userCard, 10)
	Stroke(userCard, Theme.Stroke, 0, 1)

	local userAvatar = New("ImageLabel", {
		Position = UDim2.fromOffset(8, 8),
		Size = UDim2.fromOffset(32, 32),
		BackgroundTransparency = 0,
		BackgroundColor3 = Theme.Input,
		Parent = userCard,
	})
	Corner(userAvatar, 16)
	New("TextLabel", {
		Position = UDim2.fromOffset(48, 8),
		Size = UDim2.new(1, -54, 0, 16),
		Text = LocalPlayer.DisplayName,
		Font = Font.Bold,
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Parent = userCard,
	})
	New("TextLabel", {
		Position = UDim2.fromOffset(48, 24),
		Size = UDim2.new(1, -54, 0, 14),
		Text = "● Online",
		TextSize = 10,
		TextColor3 = Theme.Good,
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = userCard,
	})
	window.UserAvatar = function(content)
		if content and userAvatar.Parent then
			userAvatar.Image = content
		end
	end

	local content = New("Frame", {
		Name = "Content",
		Position = UDim2.fromOffset(158, 0),
		Size = UDim2.new(1, -158, 1, 0),
		BackgroundTransparency = 1,
		ClipsDescendants = true,
		Parent = body,
	})
	window.Content = content

	-- Theme bindings for the chrome
	window:OnTheme(function()
		local gradient = ColorSequence.new(Theme.Accent, Theme.AccentDark)
		logoGradient.Color = gradient
		lineGradient.Color = ColorSequence.new(Theme.Accent)
	end, window.Maid)

	-- ── Notifications holder ────────────────────────────────────
	local notifyWidth = UserInputService.TouchEnabled and 240 or 290
	window.NotifyHolder = New("Frame", {
		Name = "Notifications",
		AnchorPoint = Vector2.new(1, 1),
		Position = UDim2.new(1, -16, 1, -16),
		Size = UDim2.new(0, notifyWidth, 1, -32),
		BackgroundTransparency = 1,
		ZIndex = 50,
		Parent = gui,
	})
	New("UIListLayout", {
		Padding = UDim.new(0, 8),
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Bottom,
		Parent = window.NotifyHolder,
	})

	-- ── Responsive scale ────────────────────────────────────────
	window:_UpdateScale()
	local function WatchCamera()
		local camera = workspace.CurrentCamera
		if camera then
			window.Maid:Give(camera:GetPropertyChangedSignal("ViewportSize"):Connect(function()
				window:_UpdateScale()
			end))
		end
	end
	WatchCamera()
	window.Maid:Give(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
		window:_UpdateScale()
		WatchCamera()
	end))

	-- ── Toggle key ──────────────────────────────────────────────
	window.Maid:Give(UserInputService.InputBegan:Connect(function(input)
		if BindingBusy() or UserInputService:GetFocusedTextBox() then
			return
		end
		if window.ToggleKey and input.KeyCode == window.ToggleKey then
			window:Toggle()
		end
	end))

	-- ── Tabs ────────────────────────────────────────────────────
	local home = window:_BuildTab("Home", "home", "Home", true)
	window.HomeTab = home
	BuildHome(window, home)
	window:SelectTab(home)

	if config.DefaultTabs ~= false then
		window:CreateTab("Main", "main")
		window:CreateTab("Combat", "combat")
		window:CreateTab("Player", "player")
		window:CreateTab("Visuals", "visuals")
		local settings = window:_BuildTab("Settings", "settings", "Settings", true)

		settings:CreateSection("Interface")
		settings:CreateKeybind({
			Name = "Toggle UI Key",
			CurrentKeybind = window.ToggleKey and window.ToggleKey.Name or "None",
			OnChanged = function(keyName)
				window:SetToggleKey(keyName)
			end,
		})
		settings:CreateDropdown({
			Name = "Accent Color",
			Options = AccentOrder,
			CurrentOption = "Crimson",
			Callback = function(choice)
				window:SetAccent(AccentPresets[choice])
			end,
		})
		settings:CreateSlider({
			Name = "UI Scale",
			Range = { 60, 130 },
			Increment = 5,
			Suffix = "%",
			CurrentValue = 100,
			Callback = function(value)
				window:SetScale(value / 100)
			end,
		})
		settings:CreateSection("Session")
		settings:CreateButton({
			Name = "Send Test Notification",
			Callback = function()
				window:Notify({
					Title = name,
					Content = "Notifications are working perfectly.",
					Type = "Success",
					Duration = 3.5,
				})
			end,
		})
		settings:CreateButton({
			Name = "Unload UI",
			Callback = function()
				task.spawn(function()
					window:Close()
				end)
			end,
		})
		settings:CreateParagraph({
			Title = name .. " · v" .. Library.Version,
			Content = "Tip: press the toggle key to hide or show the window. "
				.. "Drag the title bar to move it, or use the – button to collapse it.",
		})
	end

	-- ── Mobile floating toggle ──────────────────────────────────
	if UserInputService.TouchEnabled then
		local floating = New("TextButton", {
			Name = "MobileToggle",
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -12, 0.5, 0),
			Size = UDim2.fromOffset(44, 44),
			BackgroundTransparency = 0,
			BackgroundColor3 = Theme.Accent,
			Text = string.upper(string.sub(name, 1, 1)),
			Font = Font.Bold,
			TextSize = 18,
			Visible = false,
			ZIndex = 60,
			Parent = gui,
		})
		Corner(floating, 22)
		Stroke(floating, Color3.new(1, 1, 1), 0.8, 1)
		window:OnTheme(function()
			floating.BackgroundColor3 = Theme.Accent
		end, window.Maid)
		floating.MouseButton1Click:Connect(function()
			window:Toggle()
		end)
		window.MobileToggle = floating
	end

	-- ── Loading sequence ────────────────────────────────────────
	local function Reveal()
		window.Loading = false
		if window.Destroyed then
			return
		end
		holder.Visible = true
		window.Pop.Scale = 0.9
		Tween(window.Pop, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		if window.MobileToggle then
			window.MobileToggle.Visible = true
		end
		if config.ShowWelcome ~= false then
			window:Notify({
				Title = "Welcome, " .. LocalPlayer.DisplayName,
				Content = window.ToggleKey and ("Press " .. window.ToggleKey.Name .. " to toggle the menu.")
					or "Tap the floating button to toggle the menu.",
				Type = "Info",
				Duration = 4,
			})
		end
	end

	if config.ShowLoading == false then
		Reveal()
	else
		task.spawn(RunLoading, window, config, Reveal)
	end

	return window
end

return Library
