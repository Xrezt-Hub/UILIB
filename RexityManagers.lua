local HttpService = game:GetService("HttpService")

local function HexToColor(hex)
	hex = tostring(hex or ""):gsub("#", ""):gsub("%s", "")
	if #hex == 3 then hex = hex:sub(1,1):rep(2) .. hex:sub(2,2):rep(2) .. hex:sub(3,3):rep(2) end
	if #hex ~= 6 or not hex:match("^%x+$") then return nil end
	return Color3.fromRGB(tonumber(hex:sub(1,2),16), tonumber(hex:sub(3,4),16), tonumber(hex:sub(5,6),16))
end
local function ColorToHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R*255+0.5), math.floor(c.G*255+0.5), math.floor(c.B*255+0.5))
end
local function Sanitize(s)
	return (tostring(s or ""):gsub("[^%w_%- ]", "")):sub(1, 40)
end
local fsOk = type(writefile) == "function" and type(readfile) == "function" and type(isfile) == "function"
	and type(isfolder) == "function" and type(makefolder) == "function" and type(listfiles) == "function"

-- ═════════════ THEME MANAGER ═════════════
local ThemeManager = { Inputs = {}, Originals = setmetatable({}, { __mode = "k" }) }
ThemeManager.Default = { Accent = "#EB3852", Background = "#0D0D12", Sidebar = "#0B0B0F", Font = "Default" }
ThemeManager.Current = {}
for k, v in pairs(ThemeManager.Default) do ThemeManager.Current[k] = v end
ThemeManager.Presets = {
	Crimson = { Accent = "#EB3852", Background = "#0D0D12", Sidebar = "#0B0B0F" },
	Ocean = { Accent = "#388CFF", Background = "#0A0F1A", Sidebar = "#080C15" },
	Violet = { Accent = "#8A5CF6", Background = "#100D18", Sidebar = "#0D0B14" },
	Emerald = { Accent = "#28C882", Background = "#0A130F", Sidebar = "#08100C" },
	Amber = { Accent = "#FFAA32", Background = "#14100A", Sidebar = "#100D08" },
	Midnight = { Accent = "#5865F2", Background = "#000000", Sidebar = "#050507" },
}

function ThemeManager:SetWindow(window)
	self.Window = window
	window.Gui.DescendantAdded:Connect(function(d) task.defer(self._Style, self, d) end)
end

function ThemeManager:SetColor(key, hex)
	local c = HexToColor(hex)
	if not c then return false end
	local new = ColorToHex(c)
	if key == "Accent" then
		self.Window:SetAccent(c)
	else
		local from = HexToColor(self.Current[key])
		for _, d in ipairs(self.Window.Gui:GetDescendants()) do
			if d:IsA("GuiObject") and d.BackgroundTransparency < 1 and d.BackgroundColor3 == from then
				d.BackgroundColor3 = c
			end
		end
	end
	self.Current[key] = new
	if self.Inputs[key] then self.Inputs[key]:Set(new, true) end
	return true
end

function ThemeManager:_Style(d)
	if not (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) or d.Name == "Icon" then return end
	if self.Originals[d] == nil then self.Originals[d] = d.Font end
	local f = self.ActiveFont
	if f == nil then pcall(function() d.Font = self.Originals[d] end)
	elseif typeof(f) == "EnumItem" then d.Font = f
	else d.FontFace = f end
end

function ThemeManager:SetFont(name)
	local font
	if name and name ~= "Default" then
		if name:sub(1, 7) == "custom:" then
			local ok, f = pcall(Font.new, name:sub(8), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
			font = ok and f or nil
		else
			local ok, f = pcall(function() return Enum.Font[name] end)
			font = ok and f or nil
		end
	end
	self.ActiveFont = font
	self.Current.Font = font and name or "Default"
	for _, d in ipairs(self.Window.Gui:GetDescendants()) do self:_Style(d) end
end

function ThemeManager:Apply(t)
	if type(t) ~= "table" then return end
	for _, key in ipairs({ "Accent", "Background", "Sidebar" }) do
		if type(t[key]) == "string" then self:SetColor(key, t[key]) end
	end
	if type(t.Font) == "string" then self:SetFont(t.Font) end
end

function ThemeManager:GetTheme()
	local copy = {}
	for k, v in pairs(self.Current) do copy[k] = v end
	return copy
end

function ThemeManager:BuildSection(tab)
	local names = {}
	for _, item in ipairs(Enum.Font:GetEnumItems()) do
		if item.Name ~= "Unknown" and item.Name ~= "Legacy" then table.insert(names, item.Name) end
	end
	table.sort(names)
	local popular = {}
	for _, n in ipairs({ "Gotham", "GothamBold", "SourceSans", "Ubuntu", "Roboto", "RobotoMono", "Nunito", "Oswald",
		"Merriweather", "FredokaOne", "Bangers", "PermanentMarker", "Code", "Arcade", "SciFi", "Fantasy", "Arial", "Jura" }) do
		if table.find(names, n) then table.insert(popular, n) end
	end

	tab:CreateSection("Theme Manager")
	local presetNames = {}
	for k in pairs(self.Presets) do table.insert(presetNames, k) end
	table.sort(presetNames)
	tab:CreateDropdown({
		Name = "Preset", Options = presetNames, Placeholder = "Choose a preset",
		Callback = function(n) self:Apply(self.Presets[n]) end,
	})
	for _, key in ipairs({ "Accent", "Background", "Sidebar" }) do
		self.Inputs[key] = tab:CreateInput({
			Name = key .. " (Hex)", CurrentValue = self.Current[key], PlaceholderText = "#RRGGBB",
			Callback = function(t)
				if not self:SetColor(key, t) then
					self.Window:Notify({ Title = "Invalid hex", Content = "Use a color like #EB3852", Type = "Error", Duration = 3 })
				end
			end,
		})
	end

	local fontDD
	tab:CreateInput({
		Name = "Search Fonts", PlaceholderText = "Type to filter...",
		OnChanged = function(text)
			text = string.lower(text or "")
			local results = {}
			for _, n in ipairs(names) do
				if text == "" or string.find(string.lower(n), text, 1, true) then table.insert(results, n) end
			end
			fontDD:Refresh(results, true)
		end,
	})
	fontDD = tab:CreateDropdown({
		Name = "All Fonts (" .. #names .. ")", Options = names, Placeholder = "Select a font",
		Callback = function(n) self:SetFont(n) end,
	})
	tab:CreateDropdown({
		Name = "Popular Fonts", Options = popular, Placeholder = "Select a font",
		Callback = function(n) self:SetFont(n) end,
	})
	tab:CreateInput({
		Name = "Custom Font Family", PlaceholderText = "rbxasset://fonts/families/Montserrat.json",
		Callback = function(t) if t ~= "" then self:SetFont("custom:" .. t) end end,
	})
	tab:CreateButton({
		Name = "Reset Theme",
		Callback = function() self:Apply(self.Default) end,
	})
end

-- ═════════════ SAVE MANAGER ═════════════
local SaveManager = { Registry = {}, Folder = "Rexity", Selected = nil, NameText = "", Pasted = "" }
SaveManager.Validators = {
	toggle = function(v) return type(v) == "boolean" end,
	slider = function(v) return type(v) == "number" end,
	dropdown = function(v) return type(v) == "string" or type(v) == "table" end,
	input = function(v) return type(v) == "string" end,
	keybind = function(v) return type(v) == "string" end,
}

function SaveManager:SetWindow(w) self.Window = w end
function SaveManager:SetThemeManager(tm) self.ThemeManager = tm end
function SaveManager:SetFolder(f)
	self.Folder = f
	self.ConfigFolder = f .. "/configs"
	self.AutoFile = f .. "/autoload.txt"
	if fsOk then
		for _, p in ipairs({ f, self.ConfigFolder }) do
			if not isfolder(p) then pcall(makefolder, p) end
		end
	end
end

-- Call BEFORE creating components so every Flag gets registered
function SaveManager:Hook()
	local TabClass = getmetatable(self.Window.HomeTab).__index
	local kinds = { CreateToggle = "toggle", CreateSlider = "slider", CreateDropdown = "dropdown",
		CreateInput = "input", CreateKeybind = "keybind" }
	for method, kind in pairs(kinds) do
		local original = TabClass[method]
		TabClass[method] = function(tab, cfg)
			local obj = original(tab, cfg)
			if type(cfg) == "table" and cfg.Flag then self.Registry[cfg.Flag] = { Object = obj, Kind = kind } end
			return obj
		end
	end
end

function SaveManager:Collect()
	local flags = {}
	for flag in pairs(self.Registry) do
		local v = self.Window.Flags[flag]
		if v ~= nil then flags[flag] = v end
	end
	return { Version = 1, Flags = flags, Theme = self.ThemeManager and self.ThemeManager:GetTheme() or nil }
end

function SaveManager:List()
	local out = {}
	if not fsOk then return out end
	local ok, files = pcall(listfiles, self.ConfigFolder)
	if ok then
		for _, p in ipairs(files) do
			local n = p:match("([^/\\]+)%.json$")
			if n then table.insert(out, n) end
		end
	end
	table.sort(out)
	return out
end

function SaveManager:Save(name)
	name = Sanitize(name)
	if name == "" then return false, "Enter a config name" end
	if not fsOk then return false, "No file functions" end
	return pcall(function() writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(self:Collect())) end)
end

-- Re-applies every saved value; toggles fire their callbacks so features start running
function SaveManager:ApplyData(data)
	if type(data) ~= "table" or type(data.Flags) ~= "table" then return false, "Invalid config" end
	if type(data.Theme) == "table" and self.ThemeManager then self.ThemeManager:Apply(data.Theme) end
	local count = 0
	for flag, value in pairs(data.Flags) do
		local e = self.Registry[flag]
		if e and self.Validators[e.Kind](value) then
			if pcall(e.Object.Set, e.Object, value) then count += 1 end
			task.wait()
		end
	end
	return true, count
end

function SaveManager:Load(name)
	local path = self.ConfigFolder .. "/" .. tostring(name) .. ".json"
	if not fsOk or not isfile(path) then return false, "Config not found" end
	local ok, data = pcall(function() return HttpService:JSONDecode(readfile(path)) end)
	if not ok then return false, "Corrupt config" end
	return self:ApplyData(data)
end

function SaveManager:Notify(title, content, kind)
	self.Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3.5 })
end

function SaveManager:LoadAutoload()
	task.spawn(function()
		repeat task.wait(0.1) until not self.Window.Loading or self.Window.Destroyed
		if self.Window.Destroyed or not fsOk or not isfile(self.AutoFile) then return end
		local name = Sanitize(readfile(self.AutoFile))
		if name == "" then return end
		task.wait(0.5)
		local ok, count = self:Load(name)
		if ok then self:Notify("Autoload", name .. " (" .. count .. " applied)", "Success") end
	end)
end

function SaveManager:BuildSection(tab)
	local dd
	local function refresh() dd:Refresh(self:List(), true) end
	tab:CreateSection("Save Manager")
	tab:CreateInput({
		Name = "Config Name", PlaceholderText = "e.g. My Config",
		OnChanged = function(t) self.NameText = t end,
	})
	dd = tab:CreateDropdown({
		Name = "Saved Configs", Options = self:List(), Placeholder = "Select a config",
		Callback = function(v) self.Selected = v end,
	})
	tab:CreateButton({ Name = "Save Config", Callback = function()
		local ok, err = self:Save(self.NameText ~= "" and self.NameText or self.Selected)
		if ok then refresh() self:Notify("Saved", "Config saved.", "Success")
		else self:Notify("Save failed", tostring(err), "Error") end
	end })
	tab:CreateButton({ Name = "Load Selected", Callback = function()
		if not self.Selected then return self:Notify("Load", "Select a config first.", "Warning") end
		task.spawn(function()
			local ok, res = self:Load(self.Selected)
			if ok then self:Notify("Loaded", self.Selected .. " (" .. res .. " applied)", "Success")
			else self:Notify("Load failed", tostring(res), "Error") end
		end)
	end })
	tab:CreateButton({ Name = "Overwrite Selected", Callback = function()
		if not self.Selected then return self:Notify("Overwrite", "Select a config first.", "Warning") end
		local ok = self:Save(self.Selected)
		self:Notify(ok and "Overwritten" or "Failed", self.Selected, ok and "Success" or "Error")
	end })
	tab:CreateButton({ Name = "Delete Selected", Callback = function()
		local path = self.Selected and (self.ConfigFolder .. "/" .. self.Selected .. ".json")
		if path and type(delfile) == "function" and isfile(path) then
			pcall(delfile, path)
			self.Selected = nil
			dd:Set(nil, true)
			refresh()
			self:Notify("Deleted", "Config removed.", "Success")
		else
			self:Notify("Delete", "Select a config first.", "Warning")
		end
	end })
	tab:CreateButton({ Name = "Refresh List", Callback = refresh })

	tab:CreateSection("Autoload / Share")
	tab:CreateButton({ Name = "Set Selected as Autoload", Callback = function()
		if not self.Selected or not fsOk then return self:Notify("Autoload", "Select a config first.", "Warning") end
		writefile(self.AutoFile, self.Selected)
		self:Notify("Autoload", self.Selected .. " will load on start.", "Success")
	end })
	tab:CreateButton({ Name = "Clear Autoload", Callback = function()
		if fsOk and isfile(self.AutoFile) then writefile(self.AutoFile, "") end
		self:Notify("Autoload", "Cleared.", "Info")
	end })
	tab:CreateButton({ Name = "Copy Config (Export)", Callback = function()
		local clip = setclipboard or toclipboard
		if type(clip) ~= "function" then return self:Notify("Export", "Clipboard unavailable.", "Warning") end
		clip(HttpService:JSONEncode(self:Collect()))
		self:Notify("Exported", "Copied to clipboard.", "Success")
	end })
	tab:CreateInput({
		Name = "Paste Config JSON", PlaceholderText = "Paste exported config",
		Callback = function(t) self.Pasted = t end,
	})
	tab:CreateButton({ Name = "Import Pasted Config", Callback = function()
		local ok, data = pcall(function() return HttpService:JSONDecode(self.Pasted) end)
		if not ok or type(data) ~= "table" or type(data.Flags) ~= "table" then
			return self:Notify("Import failed", "Not a valid config.", "Error")
		end
		if fsOk then
			local name = Sanitize(self.NameText)
			if name == "" then name = "imported_" .. os.time() end
			pcall(function() writefile(self.ConfigFolder .. "/" .. name .. ".json", HttpService:JSONEncode(data)) end)
			refresh()
		end
		task.spawn(function()
			local applied, count = self:ApplyData(data)
			if applied then self:Notify("Imported", count .. " settings applied.", "Success") end
		end)
	end })
end

return { ThemeManager = ThemeManager, SaveManager = SaveManager }
