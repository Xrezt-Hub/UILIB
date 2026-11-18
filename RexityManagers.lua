--[[
	Rexity UI: Save Manager + Theme Manager
	- Save / load / delete / autoload configs (every component with a Flag is saved automatically)
	- Export config to clipboard, import by paste, URL, or by dropping a .json in the configs folder
	- Loading a config RE-APPLIES every saved value, so saved toggles turn on and their callbacks run
	- Theme Manager: presets, hex colors, font search, custom font, save/load themes
]]

local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/Xrezt-Hub/UILIB/refs/heads/main/RexityUILibrary.lua"))()
local HttpService = game:GetService("HttpService")

local Window = Library:CreateWindow({
	Name = "Rexity Test",
	LoadingTitle = "Rexity Test",
	LoadingSubtitle = "Save + Theme Manager",
	ToggleKey = Enum.KeyCode.RightShift,
	DefaultTabs = false,
})

-- ════════════════════════════════════════════════════════════════
--  FLAG REGISTRY (auto-registers every component that has a Flag)
-- ════════════════════════════════════════════════════════════════
local Registry = {}
local TabClass = getmetatable(Window.HomeTab).__index
local Kinds = {
	CreateToggle = "toggle",
	CreateSlider = "slider",
	CreateDropdown = "dropdown",
	CreateInput = "input",
	CreateKeybind = "keybind",
}
for method, kind in pairs(Kinds) do
	local original = TabClass[method]
	TabClass[method] = function(self, cfg)
		local obj = original(self, cfg)
		if type(cfg) == "table" and cfg.Flag then
			Registry[cfg.Flag] = { Object = obj, Kind = kind }
		end
		return obj
	end
end

local Validators = {
	toggle = function(v) return type(v) == "boolean" end,
	slider = function(v) return type(v) == "number" end,
	dropdown = function(v) return type(v) == "string" or type(v) == "table" end,
	input = function(v) return type(v) == "string" end,
	keybind = function(v) return type(v) == "string" end,
}

-- ════════════════════════════════════════════════════════════════
--  FILE HELPERS
-- ════════════════════════════════════════════════════════════════
local ROOT = "RexityTest"
local CFG = ROOT .. "/configs"
local THM = ROOT .. "/themes"
local AUTO = ROOT .. "/autoload.txt"

local fsOk = type(writefile) == "function" and type(readfile) == "function"
	and type(isfile) == "function" and type(isfolder) == "function"
	and type(makefolder) == "function" and type(listfiles) == "function"

local function EnsureFolders()
	if not fsOk then return end
	for _, path in ipairs({ ROOT, CFG, THM }) do
		if not isfolder(path) then pcall(makefolder, path) end
	end
end
EnsureFolders()

local function ListFiles(folder)
	local out = {}
	if not fsOk then return out end
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

local function Sanitize(text)
	local clean = tostring(text or ""):gsub("[^%w_%- ]", "")
	return clean:sub(1, 40)
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

local function Notify(title, content, kind)
	Window:Notify({ Title = title, Content = content, Type = kind or "Info", Duration = 3.5 })
end

-- ════════════════════════════════════════════════════════════════
--  THEME MANAGER (logic)
-- ════════════════════════════════════════════════════════════════
local DEFAULT_THEME = { Accent = "#EB3852", Background = "#0D0D12", Sidebar = "#0B0B0F", Font = "Default" }
local Theme = {}
for k, v in pairs(DEFAULT_THEME) do Theme[k] = v end

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

local accentInput, backgroundInput, sidebarInput -- set later

local function Recolor(fromHex, toHex)
	local from, to = HexToColor(fromHex), HexToColor(toHex)
	if not from or not to then return end
	for _, d in ipairs(Window.Gui:GetDescendants()) do
		if d:IsA("GuiObject") and d.BackgroundTransparency < 1 and d.BackgroundColor3 == from then
			d.BackgroundColor3 = to
		end
	end
end

local function SetAccent(hex)
	local c = HexToColor(hex)
	if not c then return false end
	Window:SetAccent(c)
	Theme.Accent = ColorToHex(c)
	if accentInput then accentInput:Set(Theme.Accent, true) end
	return true
end

local function SetBackground(hex)
	local c = HexToColor(hex)
	if not c then return false end
	local new = ColorToHex(c)
	Recolor(Theme.Background, new)
	Theme.Background = new
	if backgroundInput then backgroundInput:Set(new, true) end
	return true
end

local function SetSidebar(hex)
	local c = HexToColor(hex)
	if not c then return false end
	local new = ColorToHex(c)
	Recolor(Theme.Sidebar, new)
	Theme.Sidebar = new
	if sidebarInput then sidebarInput:Set(new, true) end
	return true
end

-- Fonts
local Originals = setmetatable({}, { __mode = "k" })
local activeFont = nil

local function ResolveFont(name)
	if not name or name == "Default" then return nil end
	if name:sub(1, 7) == "custom:" then
		local ok, font = pcall(Font.new, name:sub(8), Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		return ok and font or nil
	end
	local ok, item = pcall(function() return Enum.Font[name] end)
	return ok and item or nil
end

local function StyleText(d)
	if not (d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox")) or d.Name == "Icon" then return end
	if Originals[d] == nil then Originals[d] = d.Font end
	if activeFont == nil then
		pcall(function() d.Font = Originals[d] end)
	elseif typeof(activeFont) == "EnumItem" then
		d.Font = activeFont
	else
		d.FontFace = activeFont
	end
end

Window.Gui.DescendantAdded:Connect(function(d)
	task.defer(StyleText, d)
end)

local function SetFont(name)
	local font = ResolveFont(name)
	activeFont = font
	Theme.Font = font and name or "Default"
	for _, d in ipairs(Window.Gui:GetDescendants()) do
		StyleText(d)
	end
	return font ~= nil or name == "Default"
end

local function ApplyTheme(t)
	if type(t) ~= "table" then return end
	if type(t.Accent) == "string" then SetAccent(t.Accent) end
	if type(t.Background) == "string" then SetBackground(t.Background) end
	if type(t.Sidebar) == "string" then SetSidebar(t.Sidebar) end
	if type(t.Font) == "string" then SetFont(t.Font) end
end

local Presets = {
	Crimson = { Accent = "#EB3852", Background = "#0D0D12", Sidebar = "#0B0B0F", Font = "Default" },
	Ocean = { Accent = "#388CFF", Background = "#0A0F1A", Sidebar = "#080C15", Font = "Default" },
	Violet = { Accent = "#8A5CF6", Background = "#100D18", Sidebar = "#0D0B14", Font = "Default" },
	Emerald = { Accent = "#28C882", Background = "#0A130F", Sidebar = "#08100C", Font = "Default" },
	Amber = { Accent = "#FFAA32", Background = "#14100A", Sidebar = "#100D08", Font = "Default" },
	Midnight = { Accent = "#5865F2", Background = "#000000", Sidebar = "#050507", Font = "Default" },
}
local PresetNames = { "Crimson", "Ocean", "Violet", "Emerald", "Amber", "Midnight" }

-- Font lists
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

-- ════════════════════════════════════════════════════════════════
--  SAVE MANAGER (logic)
-- ════════════════════════════════════════════════════════════════
local function Collect()
	local flags = {}
	for flag in pairs(Registry) do
		local value = Window.Flags[flag]
		if value ~= nil then flags[flag] = value end
	end
	local themeCopy = {}
	for k, v in pairs(Theme) do themeCopy[k] = v end
	return { Version = 1, Flags = flags, Theme = themeCopy }
end

-- Re-applies saved values. Toggles fire their callbacks, so features start running.
local function ApplyConfig(data)
	if type(data) ~= "table" or type(data.Flags) ~= "table" then
		return false, "Invalid config"
	end
	if type(data.Theme) == "table" then ApplyTheme(data.Theme) end
	local applied = 0
	for flag, value in pairs(data.Flags) do
		local entry = Registry[flag]
		if entry and Validators[entry.Kind](value) then
			if pcall(entry.Object.Set, entry.Object, value) then
				applied += 1
			end
			task.wait()
		end
	end
	return true, applied
end

-- ════════════════════════════════════════════════════════════════
--  TABS
-- ════════════════════════════════════════════════════════════════
local Features = Window:CreateTab("Features", "main")
local Configs = Window:CreateTab("Configs", "tools")
local Themes = Window:CreateTab("Themes", "visuals")

Window.HomeTab.Button.Visible = false
Window:SelectTab(Features)

-- ───────── Features (put YOUR toggles here; each needs a unique Flag) ─────────
Features:CreateSection("Example Features (saved automatically)")
Features:CreateToggle({
	Name = "Example Toggle A",
	CurrentValue = false,
	Flag = "ExampleA",
	Callback = function(v) print("Example A:", v) end,
})
Features:CreateToggle({
	Name = "Example Toggle B",
	CurrentValue = false,
	Flag = "ExampleB",
	Callback = function(v) print("Example B:", v) end,
})
Features:CreateSlider({
	Name = "Example Slider",
	Range = { 0, 100 },
	Increment = 1,
	CurrentValue = 50,
	Flag = "ExampleSlider",
	Callback = function(v) print("Slider:", v) end,
})
Features:CreateDropdown({
	Name = "Example Mode",
	Options = { "Easy", "Normal", "Hard" },
	CurrentOption = "Normal",
	Flag = "ExampleMode",
	Callback = function(v) print("Mode:", v) end,
})
Features:CreateKeybind({
	Name = "Example Key",
	CurrentKeybind = "E",
	Flag = "ExampleKey",
	Callback = function() print("Key pressed") end,
})

-- ───────── Configs ─────────
local selected, nameText, pasted, urlText = nil, "", "", ""
local configDropdown

local function Refresh()
	configDropdown:Refresh(ListFiles(CFG), true)
end

local function CurrentName()
	local n = Sanitize(nameText)
	if n == "" then n = selected or "" end
	return n
end

Configs:CreateSection("Save Manager")
if not fsOk then
	Configs:CreateLabel({ Text = "Your executor has no file functions. Saving to disk is unavailable, but Export/Import by clipboard may still work.", Color = Color3.fromRGB(255, 190, 60) })
end

Configs:CreateInput({
	Name = "Config Name",
	PlaceholderText = "e.g. Best BFC Chain",
	OnChanged = function(t) nameText = t end,
	Callback = function(t) nameText = t end,
})

configDropdown = Configs:CreateDropdown({
	Name = "Saved Configs",
	Options = ListFiles(CFG),
	Placeholder = "Select a config",
	Callback = function(v) selected = v end,
})

Configs:CreateButton({
	Name = "Save Config",
	Callback = function()
		local name = CurrentName()
		if name == "" then return Notify("Save", "Type a config name first.", "Warning") end
		local ok, err = WriteJSON(CFG .. "/" .. name .. ".json", Collect())
		if ok then
			Refresh()
			Notify("Saved", name, "Success")
		else
			Notify("Save failed", tostring(err), "Error")
		end
	end,
})

Configs:CreateButton({
	Name = "Load Selected Config",
	Callback = function()
		if not selected then return Notify("Load", "Select a config first.", "Warning") end
		local data = ReadJSON(CFG .. "/" .. selected .. ".json")
		if not data then return Notify("Load failed", "File missing or corrupt.", "Error") end
		task.spawn(function()
			local ok, count = ApplyConfig(data)
			if ok then Notify("Loaded", selected .. " (" .. count .. " settings applied)", "Success")
			else Notify("Load failed", tostring(count), "Error") end
		end)
	end,
})

Configs:CreateButton({
	Name = "Overwrite Selected Config",
	Callback = function()
		if not selected then return Notify("Overwrite", "Select a config first.", "Warning") end
		local ok, err = WriteJSON(CFG .. "/" .. selected .. ".json", Collect())
		if ok then Notify("Overwritten", selected, "Success") else Notify("Failed", tostring(err), "Error") end
	end,
})

Configs:CreateButton({
	Name = "Delete Selected Config",
	Callback = function()
		if not selected or not fsOk then return Notify("Delete", "Select a config first.", "Warning") end
		local path = CFG .. "/" .. selected .. ".json"
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

Configs:CreateButton({ Name = "Refresh List", Callback = Refresh })

Configs:CreateSection("Autoload")
Configs:CreateButton({
	Name = "Set Selected as Autoload",
	Callback = function()
		if not selected or not fsOk then return Notify("Autoload", "Select a config first.", "Warning") end
		pcall(writefile, AUTO, selected)
		Notify("Autoload set", selected .. " will load on start.", "Success")
	end,
})
Configs:CreateButton({
	Name = "Clear Autoload",
	Callback = function()
		if fsOk and isfile(AUTO) then pcall(writefile, AUTO, "") end
		Notify("Autoload", "Cleared.", "Info")
	end,
})

Configs:CreateSection("Share / Import")
Configs:CreateButton({
	Name = "Copy Current Config (Export)",
	Callback = function()
		local clip = setclipboard or toclipboard
		if type(clip) ~= "function" then return Notify("Export", "Clipboard is unavailable.", "Warning") end
		clip(HttpService:JSONEncode(Collect()))
		Notify("Exported", "Config copied to clipboard. Send it to anyone.", "Success")
	end,
})
Configs:CreateInput({
	Name = "Paste Config JSON",
	PlaceholderText = "Paste exported config",
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
		WriteJSON(CFG .. "/" .. name .. ".json", data)
		Refresh()
	end
	task.spawn(function()
		local applied, count = ApplyConfig(data)
		if applied then Notify("Imported", name .. " (" .. count .. " settings applied)", "Success") end
	end)
end

Configs:CreateButton({
	Name = "Import Pasted Config",
	Callback = function()
		if pasted == "" then return Notify("Import", "Paste a config first.", "Warning") end
		ImportData(pasted)
	end,
})
Configs:CreateInput({
	Name = "Import From URL",
	PlaceholderText = "https://.../config.json",
	Callback = function(t) urlText = t end,
})
Configs:CreateButton({
	Name = "Import From URL (Apply)",
	Callback = function()
		if urlText == "" then return Notify("Import", "Enter a URL first.", "Warning") end
		local ok, body = pcall(function() return game:HttpGet(urlText) end)
		if not ok then return Notify("Import failed", "Could not download the file.", "Error") end
		ImportData(body)
	end,
})
Configs:CreateParagraph({
	Title = "How it works",
	Content = "Configs are plain data. Only settings that exist in this UI are applied, and nothing in a config is executed as code. You can also drop a .json file into the " .. CFG .. " folder and press Refresh List.",
})

-- ───────── Themes ─────────
Themes:CreateSection("Presets")
Themes:CreateDropdown({
	Name = "Theme Preset",
	Options = PresetNames,
	Placeholder = "Choose a preset",
	Callback = function(name) ApplyTheme(Presets[name]) end,
})

Themes:CreateSection("Colors (Hex)")
accentInput = Themes:CreateInput({
	Name = "Accent Color",
	CurrentValue = Theme.Accent,
	PlaceholderText = "#RRGGBB",
	Callback = function(t)
		if not SetAccent(t) then Notify("Invalid hex", "Use a color like #EB3852", "Error") end
	end,
})
backgroundInput = Themes:CreateInput({
	Name = "Background Color",
	CurrentValue = Theme.Background,
	PlaceholderText = "#RRGGBB",
	Callback = function(t)
		if not SetBackground(t) then Notify("Invalid hex", "Use a color like #0D0D12", "Error") end
	end,
})
sidebarInput = Themes:CreateInput({
	Name = "Sidebar Color",
	CurrentValue = Theme.Sidebar,
	PlaceholderText = "#RRGGBB",
	Callback = function(t)
		if not SetSidebar(t) then Notify("Invalid hex", "Use a color like #0B0B0F", "Error") end
	end,
})

Themes:CreateSection("Fonts")
local fontDropdown
Themes:CreateInput({
	Name = "Search Fonts",
	PlaceholderText = "Type to filter...",
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
fontDropdown = Themes:CreateDropdown({
	Name = "All Fonts (" .. #FontNames .. ")",
	Options = FontNames,
	Placeholder = "Select a font",
	Callback = function(name) SetFont(name) end,
})
Themes:CreateDropdown({
	Name = "Popular Fonts",
	Options = Popular,
	Placeholder = "Select a font",
	Callback = function(name) SetFont(name) end,
})
Themes:CreateInput({
	Name = "Custom Font Family",
	PlaceholderText = "rbxasset://fonts/families/Montserrat.json",
	Callback = function(t)
		if t == "" then return end
		SetFont("custom:" .. t)
		Notify("Custom font", "Applied. If nothing changed, the family path is invalid.", "Info")
	end,
})
Themes:CreateButton({
	Name = "Reset Font",
	Callback = function() SetFont("Default") end,
})

Themes:CreateSection("Saved Themes")
local themeName, selectedTheme = "", nil
local themeDropdown
Themes:CreateInput({
	Name = "Theme Name",
	PlaceholderText = "My Theme",
	OnChanged = function(t) themeName = t end,
})
themeDropdown = Themes:CreateDropdown({
	Name = "Your Themes",
	Options = ListFiles(THM),
	Placeholder = "Select a theme",
	Callback = function(v) selectedTheme = v end,
})
Themes:CreateButton({
	Name = "Save Current Theme",
	Callback = function()
		local name = Sanitize(themeName)
		if name == "" then return Notify("Theme", "Type a theme name first.", "Warning") end
		local copy = {}
		for k, v in pairs(Theme) do copy[k] = v end
		local ok, err = WriteJSON(THM .. "/" .. name .. ".json", copy)
		if ok then
			themeDropdown:Refresh(ListFiles(THM), true)
			Notify("Theme saved", name, "Success")
		else
			Notify("Save failed", tostring(err), "Error")
		end
	end,
})
Themes:CreateButton({
	Name = "Load Selected Theme",
	Callback = function()
		if not selectedTheme then return Notify("Theme", "Select a theme first.", "Warning") end
		local data = ReadJSON(THM .. "/" .. selectedTheme .. ".json")
		if data then ApplyTheme(data) Notify("Theme loaded", selectedTheme, "Success")
		else Notify("Load failed", "File missing or corrupt.", "Error") end
	end,
})
Themes:CreateButton({
	Name = "Reset Theme to Default",
	Callback = function() ApplyTheme(DEFAULT_THEME) end,
})

-- ════════════════════════════════════════════════════════════════
--  AUTOLOAD
-- ════════════════════════════════════════════════════════════════
task.spawn(function()
	repeat task.wait(0.1) until not Window.Loading or Window.Destroyed
	if Window.Destroyed or not fsOk or not isfile(AUTO) then return end
	local name = Sanitize(readfile(AUTO))
	if name == "" then return end
	local data = ReadJSON(CFG .. "/" .. name .. ".json")
	if not data then return end
	task.wait(0.5)
	local ok, count = ApplyConfig(data)
	if ok then Notify("Autoload", name .. " (" .. count .. " settings applied)", "Success") end
end)
