--[[
	Rexity UI: ThemeManager + SaveManager (module)
	Usage:
		local Managers = loadstring(game:HttpGet(".../RexityManagers.lua"))()
		local ThemeManager, SaveManager = Managers.ThemeManager, Managers.SaveManager
]]

local HttpService = game:GetService("HttpService")

-- ════════════════════════════════════════════════════════════════
--  SHARED HELPERS
-- ════════════════════════════════════════════════════════════════
local fsOk = type(writefile) == "function" and type(readfile) == "function"
	and type(isfile) == "function" and type(isfolder) == "function"
	and type(makefolder) == "function" and type(listfiles) == "function"

local function Sanitize(text)
	local clean = tostring(text or ""):gsub("[^%w_%- ]", "")
	return clean:sub(1, 40)
end

local function ListFiles(folder)
	local out = {}
	if not fsOk or not isfolder(folder) then return out end
	local ok, files = pcall(listfiles, folder)
	if ok then
		for _, path in ipairs(files) do
			local name = path:match("([^/\\]+)%.json$")
			if name then table.insert(out, name) end
		end
	end
	table.sort(out)
	return out
end

local function WriteJSON(path, data)
	if not fsOk then return false, "File functions unavailable" end
	return pcall(function()
		writefile(path, HttpService:JSONEncode(data))
	end)
end

local function ReadJSON(path)
	if not fsOk or not isfile(path) then return nil end
	local ok, data = pcall(function()
		return HttpService:JSONDecode(readfile(path))
	end)
	return ok and data or nil
end

local function HexToColor(hex)
	hex = tostring(hex or ""):gsub("#", ""):gsub("%s", "")
	if #hex == 3 then
		hex = hex:sub(1, 1):rep(2) .. hex:sub(2, 2):rep(2) .. hex:sub(3, 3):rep(2)
	end
	if #hex ~= 6 or not hex:match("^%x+$") then return nil end
	return Color3.fromRGB(tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16))
end

local function ColorToHex(c)
	return string.format("#%02X%02X%02X", math.floor(c.R * 255 + 0.5), math.floor(c.G * 255 + 0.5), math.floor(c.B * 255 + 0.5))
end

local function EnsureFolders(root)
	if not fsOk then return end
	for _, path in ipairs({ root, root .. "/configs", root .. "/themes" }) do
		if not isfolder(path) then pcall(makefolder, path) end
	end
end

-- ════════════════════════════════════════════════════════════════
--  THEME MANAGER
-- ════════════════════════════════════════════════════════════════
local DEFAULT_THEME = { Accent = "#EB3852", Background = "#0D0D12", Sidebar = "#0B0B0F", Font = "Default" }

local Presets = {
	Crimson = { Accent = "#EB3852", Background = "#0D0D12", Sidebar = "#0B0B0F", Font = "Default" },
	Ocean = { Accent = "#388CFF", Background = "#0A0F1A", Sidebar = "#080C15", Font = "Default" },
	Violet = { Accent = "#8A5CF6", Background = "#100D18", Sidebar = "#0D0B14", Font = "Default" },
	Emerald = { Accent = "#28C882", Background = "#0A130F", Sidebar = "#08100C", Font = "Default" },
	Amber = { Accent = "#FFAA32", Background = "#14100A", Sidebar = "#100D08", Font = "Default" },
	Midnight = { Accent = "#5865F2", Background = "#000000", Sidebar = "#050507", Font = "Default" },
}
local PresetNames = { "Crimson", "Ocean", "Violet", "Emerald", "Amber", "Midnight" }

local FontNames = {}
for _, item in ipairs(Enum.Font:GetEnumItems()) do
	if item.Name ~= "Unknown" and item.Name ~= "Legacy" then
		table.insert(FontNames, item.Name)
	end
end
table.sort(FontNames)

local Popular = {}
for _, name in ipairs({
	"Gotham", "GothamMedium", "GothamBold", "GothamBlack", "SourceSans", "SourceSansBold", "Ubuntu",
	"Roboto", "RobotoMono", "RobotoCondensed", "Nunito", "Oswald", "Merriweather", "JosefinSans",
	"TitilliumWeb", "FredokaOne", "Bangers", "PermanentMarker", "IndieFlower", "Code", "Arcade",
	"SciFi", "Fantasy", "Cartoon", "Arial", "ArialBold", "Highway", "Jura", "Michroma",
}) do
	if table.find(FontNames, name) then table.insert(Popular, name) end
end

local ThemeManager = {
	Folder = "Rexity",
	Window = nil,
	Theme = {},
	Inputs = {},
}
for k, v in pairs(DEFAULT_THEME) do ThemeManager.Theme[k] = v end

local Originals = setmetatable({}, { __mode = "k" })
local activeFont = nil
local fontConnected = false

function ThemeManager:SetWindow(window)
	self.Window = window
	if window and window.Gui and not fontConnected then
		fontConnected = true
		window.Gui.DescendantAdded:Connect(function(d)
			task.defer(function()
				self:_StyleText(d)
			end)
		end)
	end
end

function ThemeManager:SetFolder(folder)
	self.Folder = Sanitize(folder) ~= "" and Sanitize(folder) or "Rexity"
	EnsureFolders(self.Folder)
end

function ThemeManager:GetTheme()
	local copy = {}
	for k, v in pairs(self.Theme) do copy[k] = v end
	return copy
end

function ThemeManager:_Recolor(fromHex, toHex)
	local from, to = HexToColor(fromHex), HexToColor(toHex)
	if not from or not to or not self.Window then return end
	for _, d in ipairs(self.Window.Gui:GetDescendants()) do
		if d:IsA("GuiObject") and d.BackgroundTransparency < 1 and d.BackgroundColor3 == from then
			d.BackgroundColor3 = to
		end
	end
end

function ThemeManager:SetAccent(hex)
	local c = HexToColor(hex)
	if not c or not self.Window then return false end
	self.Window:SetAccent(c)
	self.Theme.Accent = ColorToHex(c)
	if self.Inputs.Accent then self.Inputs.Accent:Set(self.Theme.Accent, true) end
	return true
end

function ThemeManager:SetBackground(hex)
	local c = HexToColor(hex)
	if not c then return false end
	local new = ColorToHex(c)
	self:_Recolor(self.Theme.Background, new)
	self.Theme.Background = new
	if self.Inputs.Background then self.Inputs.Background:Set(new, true) end
	return true
end

function ThemeManager:SetSidebar(hex)
	local c = HexToColor(hex)
	if not c then return false end
	local new = ColorToHex(c)
	self:_Recolor(self.Theme.Sidebar, new)
	self.Theme.Sidebar = new
	if self.Inputs.Sidebar then self.Inputs.Sidebar:Set(new, true) end
	return true
end

local function ResolveFont(name)
	if not name or name == "Default" then return nil end
	if name:sub(1, 7) == "custom:" then
		local ok, font = pcall(Font.new, name:sub(8), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		return ok and font or nil
	end
	local ok, item = pcall(function() return Enum.Font[name] end)
	return ok and item or nil
end

function ThemeManager:_StyleText(d)
	if not (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) or d.Name == "Icon" then return end
	if Originals[d] == nil then Originals[d] = d.Font end
	if activeFont == nil then
		pcall(function() d.Font = Originals[d] end)
	elseif typeof(activeFont) == "EnumItem" then
		d.Font = activeFont
	else
		pcall(function() d.FontFace = activeFont end)
	end
end

function ThemeManager:SetFont(name)
	local font = ResolveFont(name)
	activeFont = font
	self.Theme.Font = font and name or "Default"
	if self.Window then
		for _, d in ipairs(self.Window.Gui:GetDescendants()) do
			self:_StyleText(d)
		end
	end
	return font ~= nil or name == "Default"
end

function ThemeManager:ApplyTheme(t)
	if type(t) ~= "table" then return end
	if type(t.Accent) == "string" then self:SetAccent(t.Accent) end
	if type(t.Background) == "string" then self:SetBackground(t.Background) end
	if type(t.Sidebar) == "string" then self:SetSidebar(t.Sidebar) end
	if type(t.Font) == "string" then self:SetFont(t.Font) end
end

function ThemeManager:BuildSection(tab)
	local window = self.Window
	local function Notify(title, content, kind)
		window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3.5 })
	end
	local themeDir = function() return self.Folder .. "/themes" end

	tab:CreateSection("Presets")
	tab:CreateDropdown({
		Name = "Theme Preset",
		Options = PresetNames,
		Placeholder = "Choose a preset",
		Callback = function(name) self:ApplyTheme(Presets[name]) end,
	})

	tab:CreateSection("Colors (Hex)")
	self.Inputs.Accent = tab:CreateInput({
		Name = "Accent Color", CurrentValue = self.Theme.Accent, PlaceholderText = "#RRGGBB",
		Callback = function(t)
			if not self:SetAccent(t) then Notify("Invalid hex", "Use a color like #EB3852", "Error") end
		end,
	})
	self.Inputs.Background = tab:CreateInput({
		Name = "Background Color", CurrentValue = self.Theme.Background, PlaceholderText = "#RRGGBB",
		Callback = function(t)
			if not self:SetBackground(t) then Notify("Invalid hex", "Use a color like #0D0D12", "Error") end
		end,
	})
	self.Inputs.Sidebar = tab:CreateInput({
		Name = "Sidebar Color", CurrentValue = self.Theme.Sidebar, PlaceholderText = "#RRGGBB",
		Callback = function(t)
			if not self:SetSidebar(t) then Notify("Invalid hex", "Use a color like #0B0B0F", "Error") end
		end,
	})

	tab:CreateSection("Fonts")
	local fontDropdown
	tab:CreateInput({
		Name = "Search Fonts", PlaceholderText = "Type to filter...",
		OnChanged = function(text)
			text = string.lower(text or "")
			local results = {}
			for _, name in ipairs(FontNames) do
				if text == "" or string.find(string.lower(name), text, 1, true) then
					table.insert(results, name)
				end
			end
			fontDropdown:Refresh(results, true)
		end,
	})
	fontDropdown = tab:CreateDropdown({
		Name = "All Fonts (" .. #FontNames .. ")", Options = FontNames, Placeholder = "Select a font",
		Callback = function(name) self:SetFont(name) end,
	})
	tab:CreateDropdown({
		Name = "Popular Fonts", Options = Popular, Placeholder = "Select a font",
		Callback = function(name) self:SetFont(name) end,
	})
	tab:CreateInput({
		Name = "Custom Font Family", PlaceholderText = "rbxasset://fonts/families/Montserrat.json",
		Callback = function(t)
			if t == "" then return end
			self:SetFont("custom:" .. t)
			Notify("Custom font", "Applied. If nothing changed, the family path is invalid.", "Info")
		end,
	})
	tab:CreateButton({ Name = "Reset Font", Callback = function() self:SetFont("Default") end })

	tab:CreateSection("Saved Themes")
	local themeName, selectedTheme = "", nil
	local themeDropdown
	tab:CreateInput({
		Name = "Theme Name", PlaceholderText = "My Theme",
		OnChanged = function(t) themeName = t end,
	})
	themeDropdown = tab:CreateDropdown({
		Name = "Your Themes", Options = ListFiles(themeDir()), Placeholder = "Select a theme",
		Callback = function(v) selectedTheme = v end,
	})
	tab:CreateButton({
		Name = "Save Current Theme",
		Callback = function()
			local name = Sanitize(themeName)
			if name == "" then return Notify("Theme", "Type a theme name first.", "Warning") end
			EnsureFolders(self.Folder)
			local ok, err = WriteJSON(themeDir() .. "/" .. name .. ".json", self:GetTheme())
			if ok then
				themeDropdown:Refresh(ListFiles(themeDir()), true)
				Notify("Theme saved", name, "Success")
			else
				Notify("Save failed", tostring(err), "Error")
			end
		end,
	})
	tab:CreateButton({
		Name = "Load Selected Theme",
		Callback = function()
			if not selectedTheme then return Notify("Theme", "Select a theme first.", "Warning") end
			local data = ReadJSON(themeDir() .. "/" .. selectedTheme .. ".json")
			if data then
				self:ApplyTheme(data)
				Notify("Theme loaded", selectedTheme, "Success")
			else
				Notify("Load failed", "File missing or corrupt.", "Error")
			end
		end,
	})
	tab:CreateButton({
		Name = "Reset Theme to Default",
		Callback = function() self:ApplyTheme(DEFAULT_THEME) end,
	})
end

-- ════════════════════════════════════════════════════════════════
--  SAVE MANAGER
-- ════════════════════════════════════════════════════════════════
local SaveManager = {
	Folder = "Rexity",
	Window = nil,
	ThemeManager = nil,
	Registry = {},
	Hooked = false,
}

local Validators = {
	toggle = function(v) return type(v) == "boolean" end,
	slider = function(v) return type(v) == "number" end,
	dropdown = function(v) return type(v) == "string" or type(v) == "table" end,
	input = function(v) return type(v) == "string" end,
	keybind = function(v) return type(v) == "string" end,
}

function SaveManager:SetWindow(window) self.Window = window end
function SaveManager:SetThemeManager(tm) self.ThemeManager = tm end

function SaveManager:SetFolder(folder)
	self.Folder = Sanitize(folder) ~= "" and Sanitize(folder) or "Rexity"
	EnsureFolders(self.Folder)
	if self.ThemeManager then self.ThemeManager:SetFolder(self.Folder) end
end

function SaveManager:_Cfg() return self.Folder .. "/configs" end
function SaveManager:_Auto() return self.Folder .. "/autoload.txt" end

-- Call BEFORE creating components so every Flag gets registered
function SaveManager:Hook()
	assert(self.Window, "SaveManager:SetWindow(Window) must be called before Hook()")
	if self.Hooked then return end
	self.Hooked = true

	local TabClass = getmetatable(self.Window.HomeTab).__index
	local kinds = {
		CreateToggle = "toggle",
		CreateSlider = "slider",
		CreateDropdown = "dropdown",
		CreateInput = "input",
		CreateKeybind = "keybind",
	}
	local registry = self.Registry
	for method, kind in pairs(kinds) do
		local original = TabClass[method]
		TabClass[method] = function(tab, cfg)
			local obj = original(tab, cfg)
			if type(cfg) == "table" and cfg.Flag then
				registry[cfg.Flag] = { Object = obj, Kind = kind }
			end
			return obj
		end
	end
end

function SaveManager:Collect()
	local flags = {}
	for flag in pairs(self.Registry) do
		local value = self.Window.Flags[flag]
		if value ~= nil then flags[flag] = value end
	end
	return {
		Version = 1,
		Flags = flags,
		Theme = self.ThemeManager and self.ThemeManager:GetTheme() or nil,
	}
end

function SaveManager:ApplyConfig(data)
	if type(data) ~= "table" or type(data.Flags) ~= "table" then
		return false, "Invalid config"
	end
	if type(data.Theme) == "table" and self.ThemeManager then
		self.ThemeManager:ApplyTheme(data.Theme)
	end
	local applied = 0
	for flag, value in pairs(data.Flags) do
		local entry = self.Registry[flag]
		if entry and Validators[entry.Kind](value) then
			if pcall(entry.Object.Set, entry.Object, value) then
				applied += 1
			end
			task.wait()
		end
	end
	return true, applied
end

function SaveManager:LoadAutoload()
	task.spawn(function()
		local window = self.Window
		repeat task.wait(0.1) until not window.Loading or window.Destroyed
		if window.Destroyed or not fsOk or not isfile(self:_Auto()) then return end
		local name = Sanitize(readfile(self:_Auto()))
		if name == "" then return end
		local data = ReadJSON(self:_Cfg() .. "/" .. name .. ".json")
		if not data then return end
		task.wait(0.5)
		local ok, count = self:ApplyConfig(data)
		if ok then
			window:Notify({ Title = "Autoload", Content = name .. " (" .. count .. " settings applied)", Type = "Success", Duration = 3.5 })
		end
	end)
end

function SaveManager:BuildSection(tab)
	local window = self.Window
	local function Notify(title, content, kind)
		window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3.5 })
	end

	local selected, nameText, pasted, urlText = nil, "", "", ""
	local configDropdown

	local function Refresh()
		configDropdown:Refresh(ListFiles(self:_Cfg()), true)
	end
	local function CurrentName()
		local n = Sanitize(nameText)
		if n == "" then n = selected or "" end
		return n
	end

	tab:CreateSection("Save Manager")
	if not fsOk then
		tab:CreateLabel({
			Text = "Your executor has no file functions. Saving to disk is unavailable, but Export/Import by clipboard may still work.",
			Color = Color3.fromRGB(255, 190, 60),
		})
	end

	tab:CreateInput({
		Name = "Config Name", PlaceholderText = "e.g. Legit Settings",
		OnChanged = function(t) nameText = t end,
		Callback = function(t) nameText = t end,
	})
	configDropdown = tab:CreateDropdown({
		Name = "Saved Configs", Options = ListFiles(self:_Cfg()), Placeholder = "Select a config",
		Callback = function(v) selected = v end,
	})

	tab:CreateButton({
		Name = "Save Config",
		Callback = function()
			local name = CurrentName()
			if name == "" then return Notify("Save", "Type a config name first.", "Warning") end
			EnsureFolders(self.Folder)
			local ok, err = WriteJSON(self:_Cfg() .. "/" .. name .. ".json", self:Collect())
			if ok then Refresh() Notify("Saved", name, "Success")
			else Notify("Save failed", tostring(err), "Error") end
		end,
	})
	tab:CreateButton({
		Name = "Load Selected Config",
		Callback = function()
			if not selected then return Notify("Load", "Select a config first.", "Warning") end
			local data = ReadJSON(self:_Cfg() .. "/" .. selected .. ".json")
			if not data then return Notify("Load failed", "File missing or corrupt.", "Error") end
			task.spawn(function()
				local ok, count = self:ApplyConfig(data)
				if ok then Notify("Loaded", selected .. " (" .. count .. " settings applied)", "Success")
				else Notify("Load failed", tostring(count), "Error") end
			end)
		end,
	})
	tab:CreateButton({
		Name = "Overwrite Selected Config",
		Callback = function()
			if not selected then return Notify("Overwrite", "Select a config first.", "Warning") end
			local ok, err = WriteJSON(self:_Cfg() .. "/" .. selected .. ".json", self:Collect())
			if ok then Notify("Overwritten", selected, "Success") else Notify("Failed", tostring(err), "Error") end
		end,
	})
	tab:CreateButton({
		Name = "Delete Selected Config",
		Callback = function()
			if not selected or not fsOk then return Notify("Delete", "Select a config first.", "Warning") end
			local path = self:_Cfg() .. "/" .. selected .. ".json"
			if type(delfile) == "function" and isfile(path) then
				pcall(delfile, path)
				Notify("Deleted", selected, "Success")
				selected = nil
				configDropdown:Set(nil, true)
				Refresh()
			else
				Notify("Delete failed", "delfile is not available.", "Error")
			end
		end,
	})
	tab:CreateButton({ Name = "Refresh List", Callback = Refresh })

	tab:CreateSection("Autoload")
	tab:CreateButton({
		Name = "Set Selected as Autoload",
		Callback = function()
			if not selected or not fsOk then return Notify("Autoload", "Select a config first.", "Warning") end
			pcall(writefile, self:_Auto(), selected)
			Notify("Autoload set", selected .. " will load on start.", "Success")
		end,
	})
	tab:CreateButton({
		Name = "Clear Autoload",
		Callback = function()
			if fsOk and isfile(self:_Auto()) then pcall(writefile, self:_Auto(), "") end
			Notify("Autoload", "Cleared.", "Info")
		end,
	})

	tab:CreateSection("Share / Import")
	tab:CreateButton({
		Name = "Copy Current Config (Export)",
		Callback = function()
			local clip = setclipboard or toclipboard
			if type(clip) ~= "function" then return Notify("Export", "Clipboard is unavailable.", "Warning") end
			clip(HttpService:JSONEncode(self:Collect()))
			Notify("Exported", "Config copied to clipboard.", "Success")
		end,
	})
	tab:CreateInput({
		Name = "Paste Config JSON", PlaceholderText = "Paste exported config",
		Callback = function(t) pasted = t end,
	})

	local function ImportData(raw)
		local ok, data = pcall(function() return HttpService:JSONDecode(raw) end)
		if not ok or type(data) ~= "table" or type(data.Flags) ~= "table" then
			return Notify("Import failed", "That is not a valid config.", "Error")
		end
		local name = Sanitize(nameText)
		if name == "" then name = "imported_" .. os.time() end
		if fsOk then
			EnsureFolders(self.Folder)
			WriteJSON(self:_Cfg() .. "/" .. name .. ".json", data)
			Refresh()
		end
		task.spawn(function()
			local applied, count = self:ApplyConfig(data)
			if applied then Notify("Imported", name .. " (" .. count .. " settings applied)", "Success") end
		end)
	end

	tab:CreateButton({
		Name = "Import Pasted Config",
		Callback = function()
			if pasted == "" then return Notify("Import", "Paste a config first.", "Warning") end
			ImportData(pasted)
		end,
	})
	tab:CreateInput({
		Name = "Import From URL", PlaceholderText = "https://.../config.json",
		Callback = function(t) urlText = t end,
	})
	tab:CreateButton({
		Name = "Import From URL (Apply)",
		Callback = function()
			if urlText == "" then return Notify("Import", "Enter a URL first.", "Warning") end
			local ok, body = pcall(function() return game:HttpGet(urlText) end)
			if not ok then return Notify("Import failed", "Could not download the file.", "Error") end
			ImportData(body)
		end,
	})
	tab:CreateParagraph({
		Title = "How it works",
		Content = "Configs are plain data. Only settings that exist in this UI are applied, and nothing in a config is executed as code.",
	})
end

return { ThemeManager = ThemeManager, SaveManager = SaveManager }
