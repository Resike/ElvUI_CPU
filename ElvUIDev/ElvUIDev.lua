local AddonName, Addon = ...

local ElvUI = LibStub("AceAddon-3.0"):GetAddon("ElvUI")
Addon.ElvUI = ElvUI

local Distributor = ElvUI:GetModule("Distributor")
local PluginInstaller = ElvUI:GetModule("PluginInstaller")
local Layout = ElvUI:GetModule("Layout")
local ActionBars = ElvUI:GetModule("ActionBars")
local Auras = ElvUI:GetModule("Auras")
local Bags = ElvUI:GetModule("Bags")
local Blizzard = ElvUI:GetModule("Blizzard")
local Chat = ElvUI:GetModule("Chat")
local DataBars = ElvUI:GetModule("DataBars")
local DataTexts = ElvUI:GetModule("DataTexts")
local Minimap = ElvUI:GetModule("Minimap")
local WorldMap = ElvUI:GetModule("WorldMap")
local AFK = ElvUI:GetModule("AFK")
local ChatILvL = ElvUI:GetModule("ChatILvL")
local DebugTools = ElvUI:GetModule("DebugTools")
local Misc = ElvUI:GetModule("Misc")
local RaidUtility = ElvUI:GetModule("RaidUtility")
local Threat = ElvUI:GetModule("Threat")
local Totems = ElvUI:GetModule("Totems")
local NamePlates = ElvUI:GetModule("NamePlates")
local Skins = ElvUI:GetModule("Skins")
local Tooltip = ElvUI:GetModule("Tooltip")
local UnitFrames = ElvUI:GetModule("UnitFrames")

local ElvUIDev = { }
Addon.ElvUIDev = ElvUIDev

_G["ElvUIDev"] = ElvUIDev

math.round = function(num, decimals)
	local mult = 10^(decimals or 0)

	return math.floor(num * mult + 0.5) / mult
end

local L = Addon.L

ElvUIDev.events = CreateFrame("Frame")
ElvUIDev.events:RegisterEvent("ADDON_LOADED")

ElvUIDev.events:SetScript("OnEvent", function(self, event, ...)
	ElvUIDev[event](ElvUIDev, ...)
end)

ElvUIDev.widgets = { }

function ElvUIDev:Print(msg, ...)
	print("|cFF50C0FFElvUIDev|r: "..msg, ...)
end

-- Widgets
function ElvUIDev:RegisterWidget(name)
	if self.widgets[name] then
		ElvUIDev:Print("Widget is already registered with this name:", name)
	end

	local class = { }
	class["name"] = name

	self.widgets[name] = class

	return class
end

function ElvUIDev:CreateWidget(name, ...)
	local class = self.widgets[name]

	if not class then
		ElvUIDev:Print("Widget is not registered:", name)

		return
	end

	local frame = class:Create(...)

	local mt = getmetatable(frame)

	if type(mt.__index) == "table" then
		setmetatable(frame, {
			__index = function(self, key)
				return (key == "Class" and class or key == "name" and class.name or key:sub(1, 2) == "__" and mt.__index[key:sub(3)] or class["__index"] and class.__index(self, key, mt) or key ~= "Create" and class[key] or mt.__index[key])
			end
		})
	end

	return frame
end

function ElvUIDev:GetWidget(name)
	return self.widgets[name]
end

function ElvUIDev:HasWidget(name)
	return not not self.widgets[name]
end

function ElvUIDev:ADDON_LOADED(addon)
	if addon == AddonName then
		ElvUIDev.loadedtime = GetTime()

		self:CreateOptions()

		if not self.frame.main.devtools.table.loaded then
			self:AddFunctions()
			self:UpdateFunctions()

			self.frame.main.devtools.table.loaded = true
		end

		ElvUIDev:Print("Addon loaded into the memory.")
	end
end

function ElvUIDev:CreateOptions()
	self.frame = self:CreateWidget("Window", "ElvUIDevOptions", UIParent)
	self.frame:SetFrameStrata("High")
	self.frame:SetSize(800, 600)
	self.frame:SetPoint("TopLeft", UIParent, "TopLeft", (UIParent:GetWidth() / 2) - 400, (-UIParent:GetHeight() / 2) + 300)
	self.frame:EnableMouse(true)
	--self.frame:SetMovable(true)

	--[[if not InterfaceOptionsFrame:IsShown() then
		tinsert(UISpecialFrames, self.frame:GetName())
	end

	if InterfaceOptionsFrame then
		InterfaceOptionsFrame:HookScript("OnShow", function(self)
			for i, v in pairs(UISpecialFrames) do
				if v == "ElvUIDevOptions" then
					tremove(UISpecialFrames, i)
				end
			end
		end)
		InterfaceOptionsFrame:HookScript("OnHide", function(self)
			tinsert(UISpecialFrames, "ElvUIDevOptions")
		end)
	end]]

	self.frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:SetMovable(true)
			self:StartMoving()
		end
	end)
	self.frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
			self:SetMovable(false)

			local left, bottom = self:GetLeft(), self:GetBottom()

			--local x = math.round((left + (self:GetWidth() / 2)) - (UIParent:GetWidth() / 2))
			--local y = math.round((bottom + (self:GetHeight() / 2)) - (UIParent:GetHeight() / 2))

			local x = math.round(left)
			local y = math.round(-UIParent:GetHeight() + bottom + self:GetHeight())

			self:ClearAllPoints()
			self:SetPoint("TopLeft", UIParent, "TopLeft", x, y)
		end
	end)

	--[[self.frame:SetScript("OnMouseWheel", function(self, delta)
		self.overlay.texture:SetAlpha(self.overlay.texture:GetAlpha() - (delta / 50))
		self.Bg:SetAlpha(self.Bg:GetAlpha() - (delta / 200))
	end)]]

	self.frame.title:SetText("ElvUI Dev")

	self.frame.version = self.frame:CreateFontString(nil, "Overlay")
	self.frame.version:SetFontObject(GameFontNormal)
	self.frame.version:SetVertexColor(0.8, 0.8, 0.8, 0.3)
	self.frame.version:SetPoint("BottomRight", self.frame, "BottomRight", -15, 3)
	self.frame.version:SetWidth(120)
	self.frame.version:SetHeight(20)
	self.frame.version:SetJustifyV("Middle")
	self.frame.version:SetJustifyH("Right")
	self.frame.version:SetText(GetAddOnMetadata("ElvUIDev", "Version"))
	self.frame.version:SetWordWrap(false)

	self.frame.main = { }
	self.frame.main.devtools = { }

	self.frame.main.devtools.table = self:CreateWidget("Table", self.frame)
	self.frame.main.devtools.table:SetPoint("TopLeft", self.frame, "TopLeft", 2 + 20, -84)
	self.frame.main.devtools.table:SetPoint("BottomRight", self.frame, "BottomRight", -5 - 20, 75)
	--self.frame.main.devtools.table:Hide()

	self.frame.main.devtools.table:AddColumn("Function", 0.3)
	self.frame.main.devtools.table:AddColumn("Calls", 0.125)
	self.frame.main.devtools.table:AddColumn("Calls/sec", 0.125, "%.3f")
	self.frame.main.devtools.table:AddColumn("Time/call", 0.15, "%.3f ms")
	self.frame.main.devtools.table:AddColumn("Total time", 0.15, "%.3f ms")
	self.frame.main.devtools.table:AddColumn("Overall usage", 0.15, "%.2f%%", true)

	self.frame.main.devtools.table:SetScript("OnShow", function(frame)
		ElvUIDev:UpdateFunctions()
	end)

	--[[self.frame.main.devtools.table.refresh = self:CreateWidget("CheckButtonIcon", self.frame.main.devtools.table)
	self.frame.main.devtools.table.refresh:SetPoint("TopRight", self.frame.main.devtools.table, "BottomRight", 0, 0)
	self.frame.main.devtools.table.refresh.text:SetText("Refresh")
	self.frame.main.devtools.table.refresh.text:SetWordWrap(false)
	self.frame.main.devtools.table.refresh:SetScript("OnClick", function(self, button)
		ElvUIDev:UpdateFunctions()
	end)]]

	self.frame.main.devtools.table.toggle = self:CreateWidget("CheckButtonSquare", self.frame.main.devtools.table)
	self.frame.main.devtools.table.toggle:SetPoint("TopLeft", self.frame.main.devtools.table, "BottomLeft", -2, 0)

	self.frame.main.devtools.table.toggle.texture:SetSize(7, 13)
	self.frame.main.devtools.table.toggle.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\Play")
	self.frame.main.devtools.table.toggle.texture:SetTexCoord(0.3125, 0.75, 0.0625, 0.875)

	self.frame.main.devtools.table.toggle:SetScript("OnClick", function(self, button)
		if self:GetChecked() then
			self:GetParent():SetScript("OnUpdate", ElvUIDev.FunctionsOnUpdate)

			self.texture:SetSize(9, 13)
			self.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\Stop")
			self.texture:SetTexCoord(0.1875, 0.75, 0.0625, 0.875)
		else
			self:GetParent():SetScript("OnUpdate", nil)

			self.texture:SetSize(7, 13)
			self.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\Play")
			self.texture:SetTexCoord(0.3125, 0.75, 0.0625, 0.875)
		end
	end)

	self.frame.main.devtools.table.refresh = self:CreateWidget("ButtonSquare", self.frame.main.devtools.table)
	self.frame.main.devtools.table.refresh:SetPoint("TopLeft", self.frame.main.devtools.table.toggle, "TopRight", 0, 0)

	self.frame.main.devtools.table.refresh.texture:SetTexture("Interface\\Buttons\\UI-RefreshButton")

	self.frame.main.devtools.table.refresh:SetScript("OnClick", function(self, button)
		ElvUIDev:UpdateFunctions()
	end)

	self.frame.main.devtools.table.edit = self:CreateWidget("EditBox", self.frame.main.devtools.table)
	self.frame.main.devtools.table.edit:SetSize(300, 26)
	self.frame.main.devtools.table.edit:SetPoint("Left", self.frame.main.devtools.table.refresh, "Right", 3, 0)

	self.frame.main.devtools.table.edit.clear = CreateFrame("Button", nil, self.frame.main.devtools.table.edit)
	self.frame.main.devtools.table.edit.clear:SetSize(12, 12)
	self.frame.main.devtools.table.edit.clear:SetPoint("Center", self.frame.main.devtools.table.edit, "Right", -6 - 7, 0)
	self.frame.main.devtools.table.edit.clear:SetAlpha(0.3)
	self.frame.main.devtools.table.edit.clear:Hide()

	self.frame.main.devtools.table.edit.clear:SetScript("OnEnter", function(self)
		if self.pushed then
			return
		end

		self:SetAlpha(0.6)
	end)
	self.frame.main.devtools.table.edit.clear:SetScript("OnLeave", function(self)
		if self.pushed then
			return
		end

		self:SetAlpha(0.3)
	end)

	self.frame.main.devtools.table.edit.clear:SetScript("OnMouseDown", function(self, button)
		if button ~= "LeftButton" then
			return
		end

		self.pushed = true

		self:SetAlpha(0.2)

		self:SetSize(10, 10)
	end)
	self.frame.main.devtools.table.edit.clear:SetScript("OnMouseUp", function(self, button)
		if button ~= "LeftButton" then
			return
		end

		self.pushed = nil

		self:SetAlpha(0.3)

		self:SetSize(12, 12)
	end)

	self.frame.main.devtools.table.edit.clear:SetScript("OnClick", function(self, button)
		if button ~= "LeftButton" then
			return
		end

		self.pushed = nil

		self:SetSize(12, 12)

		ElvUIDev.frame.main.devtools.table.edit:SetText("")
		ElvUIDev.frame.main.devtools.table.edit:ClearFocus()
	end)

	self.frame.main.devtools.table.edit.clear.texture = self.frame.main.devtools.table.edit.clear:CreateTexture(nil, "Overlay")
	self.frame.main.devtools.table.edit.clear.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\Close")
	self.frame.main.devtools.table.edit.clear.texture:SetAllPoints(self.frame.main.devtools.table.edit.clear)

	self.frame.main.devtools.table.edit.number = self.frame.main.devtools.table:CreateFontString(nil, "Background")
	self.frame.main.devtools.table.edit.number:SetFontObject(GameFontHighlightSmall)
	self.frame.main.devtools.table.edit.number:SetSize(200, 26)
	self.frame.main.devtools.table.edit.number:SetJustifyV("Middle")
	self.frame.main.devtools.table.edit.number:SetJustifyH("Left")
	self.frame.main.devtools.table.edit.number:SetWordWrap(false)
	self.frame.main.devtools.table.edit.number:SetPoint("Left", self.frame.main.devtools.table.edit, "Right", 3, 0)

	--self.frame.main.devtools.table.edit.number:SetText("0 functions.")

	self.frame.main.devtools.table.edit:SetScript("OnTextChanged", function(self, userInput)
		local text = self:GetText()
		if text == "" then
			self.clear:Hide()
		else
			self.clear:Show()
		end

		ElvUIDev.frame.main.devtools.table:SetFilter(text)

		if text == "" then
			ElvUIDev.frame.main.devtools.table.edit.number:SetFormattedText("%d functions: %0.3f ms", #ElvUIDev.frame.main.devtools.table.sorted, ElvUIDev:GetTotal(5))
		else
			ElvUIDev.frame.main.devtools.table.edit.number:SetFormattedText("%d functions: %0.3f ms", #ElvUIDev.frame.main.devtools.table.filtered, ElvUIDev:GetFiltered(5))
		end
	end)

	self.frame.childrens = {self.frame:GetChildren()}

	self:MakeScaleable(self.frame)

	self.frame:Hide()

	PlaySound(841)
end

function ElvUIDev:ToggleFrame()
	if not self.frame:IsShown() then
		self.frame:Show()
	else
		self.frame:Hide()
	end
end

function ElvUIDev:RegisterPlugin(pluginName)
	if (not self.plugins) then
		self.plugins = {};
	end
	self.plugins[pluginName] = true;
end

function ElvUIDev:RegisterPluginModule(pluginName, moduleName, module)
	if (not self.pluginModules) then
		self.pluginModules = {};
	end
	self.pluginModules[pluginName] = self.pluginModules[pluginName] or {};
	self.pluginModules[pluginName][moduleName] = module;
	for key, func in pairs(module) do
		if type(func) == "function" then
			self:AddFunction(("(Z)%s %s: %s"):format(pluginName, moduleName, key), func);
		end
	end
end

function ElvUIDev:AddFunction(key, func)
	local subs = false
	local usage, calls = GetFunctionCPUUsage(func, subs)
	usage, calls = math.max(0, usage), calls
	self.frame.main.devtools.table:AddRow(key, calls, (calls / math.floor(GetTime() - (ElvUI.loadedtime or ElvUIDev.loadedtime))), (usage / math.max(1, calls)), usage, (usage / math.max(1, GetAddOnCPUUsage("ElvUI"))) * 100)
end

function ElvUIDev:AddFunctions()
	for key, func in pairs(ElvUI) do
		if type(func) == "function" then
			self:AddFunction("ElvUI:"..key, func)
		end
	end

	for key, func in pairs(Distributor) do
		if type(func) == "function" then
			self:AddFunction("Distributor:"..key, func)
		end
	end

	for key, func in pairs(PluginInstaller) do
		if type(func) == "function" then
			self:AddFunction("PluginInstaller:"..key, func)
		end
	end

	for key, func in pairs(Layout) do
		if type(func) == "function" then
			self:AddFunction("Layout:"..key, func)
		end
	end

	for key, func in pairs(ActionBars) do
		if type(func) == "function" then
			self:AddFunction("ActionBars:"..key, func)
		end
	end

	for key, func in pairs(Auras) do
		if type(func) == "function" then
			self:AddFunction("Auras:"..key, func)
		end
	end

	for key, func in pairs(Bags) do
		if type(func) == "function" then
			self:AddFunction("Bags:"..key, func)
		end
	end

	for key, func in pairs(Blizzard) do
		if type(func) == "function" then
			self:AddFunction("Blizzard:"..key, func)
		end
	end

	for key, func in pairs(Chat) do
		if type(func) == "function" then
			self:AddFunction("Chat:"..key, func)
		end
	end

	for key, func in pairs(DataBars) do
		if type(func) == "function" then
			self:AddFunction("DataBars:"..key, func)
		end
	end

	for key, func in pairs(DataTexts) do
		if type(func) == "function" then
			self:AddFunction("DataTexts:"..key, func)
		end
	end

	for key, func in pairs(Minimap) do
		if type(func) == "function" then
			self:AddFunction("Minimap:"..key, func)
		end
	end

	for key, func in pairs(WorldMap) do
		if type(func) == "function" then
			self:AddFunction("WorldMap:"..key, func)
		end
	end

	for key, func in pairs(AFK) do
		if type(func) == "function" then
			self:AddFunction("AFK:"..key, func)
		end
	end

	for key, func in pairs(ChatILvL) do
		if type(func) == "function" then
			self:AddFunction("ChatILvL:"..key, func)
		end
	end

	for key, func in pairs(DebugTools) do
		if type(func) == "function" then
			self:AddFunction("DebugTools:"..key, func)
		end
	end

	for key, func in pairs(Misc) do
		if type(func) == "function" then
			self:AddFunction("Misc:"..key, func)
		end
	end

	for key, func in pairs(RaidUtility) do
		if type(func) == "function" then
			self:AddFunction("RaidUtility:"..key, func)
		end
	end

	for key, func in pairs(Threat) do
		if type(func) == "function" then
			self:AddFunction("Threat:"..key, func)
		end
	end

	for key, func in pairs(Totems) do
		if type(func) == "function" then
			self:AddFunction("Totems:"..key, func)
		end
	end

	for key, func in pairs(NamePlates) do
		if type(func) == "function" then
			self:AddFunction("NamePlates:"..key, func)
		end
	end

	for key, func in pairs(Skins) do
		if type(func) == "function" then
			self:AddFunction("Skins:"..key, func)
		end
	end

	for key, func in pairs(Tooltip) do
		if type(func) == "function" then
			self:AddFunction("Tooltip:"..key, func)
		end
	end

	for key, func in pairs(UnitFrames) do
		if type(func) == "function" then
			self:AddFunction("UnitFrames:"..key, func)
		end
	end

	self.frame.main.devtools.table:ApplyFilter()
end

function ElvUIDev:UpdateFunction(key, func)
	local subs = false
	local usage, calls = GetFunctionCPUUsage(func, subs)
	usage, calls = math.max(0, usage), calls

	local callspersec = (calls / math.floor(GetTime() - (ElvUI.loadedtime or ElvUIDev.loadedtime)))
	local timepercall = (usage / math.max(1, calls))
	local overallusage = (usage / math.max(1, GetAddOnCPUUsage("ElvUI"))) * 100

	if calls == 0 and callspersec == 0 and timepercall == 0 and usage == 0 and overallusage == 0 then
		return
	end

	self.frame.main.devtools.table:UpdateRow(key, calls, callspersec, timepercall, usage, overallusage)
end

function ElvUIDev:FunctionsOnUpdate(elapsed)
	self.time = (self.time or 0) + elapsed
	if self.time < 1 then
		return
	end
	self.time = 0

	ElvUIDev:UpdateFunctions()
end

function ElvUIDev:UpdateFunctions()
	UpdateAddOnCPUUsage("ElvUI")
	if (self.plugins) then
		for plugin, _ in pairs(self.plugins) do
			UpdateAddOnCPUUsage(plugin);
		end
	end

	for key, func in pairs(ElvUI) do
		if type(func) == "function" then
			self:UpdateFunction("ElvUI:"..key, func)
		end
	end

	for key, func in pairs(Distributor) do
		if type(func) == "function" then
			self:UpdateFunction("Distributor:"..key, func)
		end
	end

	for key, func in pairs(PluginInstaller) do
		if type(func) == "function" then
			self:UpdateFunction("PluginInstaller:"..key, func)
		end
	end

	for key, func in pairs(Layout) do
		if type(func) == "function" then
			self:UpdateFunction("Layout:"..key, func)
		end
	end

	for key, func in pairs(ActionBars) do
		if type(func) == "function" then
			self:UpdateFunction("ActionBars:"..key, func)
		end
	end

	for key, func in pairs(Auras) do
		if type(func) == "function" then
			self:UpdateFunction("Auras:"..key, func)
		end
	end

	for key, func in pairs(Bags) do
		if type(func) == "function" then
			self:UpdateFunction("Bags:"..key, func)
		end
	end

	for key, func in pairs(Blizzard) do
		if type(func) == "function" then
			self:UpdateFunction("Blizzard:"..key, func)
		end
	end

	for key, func in pairs(Chat) do
		if type(func) == "function" then
			self:UpdateFunction("Chat:"..key, func)
		end
	end

	for key, func in pairs(DataBars) do
		if type(func) == "function" then
			self:UpdateFunction("DataBars:"..key, func)
		end
	end

	for key, func in pairs(DataTexts) do
		if type(func) == "function" then
			self:UpdateFunction("DataTexts:"..key, func)
		end
	end

	for key, func in pairs(Minimap) do
		if type(func) == "function" then
			self:UpdateFunction("Minimap:"..key, func)
		end
	end

	for key, func in pairs(WorldMap) do
		if type(func) == "function" then
			self:UpdateFunction("WorldMap:"..key, func)
		end
	end

	for key, func in pairs(AFK) do
		if type(func) == "function" then
			self:UpdateFunction("AFK:"..key, func)
		end
	end

	for key, func in pairs(ChatILvL) do
		if type(func) == "function" then
			self:UpdateFunction("ChatILvL:"..key, func)
		end
	end

	for key, func in pairs(DebugTools) do
		if type(func) == "function" then
			self:UpdateFunction("DebugTools:"..key, func)
		end
	end

	for key, func in pairs(Misc) do
		if type(func) == "function" then
			self:UpdateFunction("Misc:"..key, func)
		end
	end

	for key, func in pairs(RaidUtility) do
		if type(func) == "function" then
			self:UpdateFunction("RaidUtility:"..key, func)
		end
	end

	for key, func in pairs(Threat) do
		if type(func) == "function" then
			self:UpdateFunction("Threat:"..key, func)
		end
	end

	for key, func in pairs(Totems) do
		if type(func) == "function" then
			self:UpdateFunction("Totems:"..key, func)
		end
	end

	for key, func in pairs(NamePlates) do
		if type(func) == "function" then
			self:UpdateFunction("NamePlates:"..key, func)
		end
	end

	for key, func in pairs(Skins) do
		if type(func) == "function" then
			self:UpdateFunction("Skins:"..key, func)
		end
	end

	for key, func in pairs(Tooltip) do
		if type(func) == "function" then
			self:UpdateFunction("Tooltip:"..key, func)
		end
	end

	for key, func in pairs(UnitFrames) do
		if type(func) == "function" then
			self:UpdateFunction("UnitFrames:"..key, func)
		end
	end

	if (self.pluginModules) then
		for plugin,modules in pairs(self.pluginModules) do
			for moduleName,module in pairs(modules) do
				for key, func in pairs(module) do
					if type(func) == "function" then
						self:UpdateFunction(("(Z)%s %s: %s"):format(plugin:gsub("ElvUI_",""):sub(1,1), moduleName, key), func);
					end
				end
			end
		end
	end

	self.frame.main.devtools.table:Update()

	if ElvUIDev.frame.main.devtools.table.edit:GetText() == "" then
		ElvUIDev.frame.main.devtools.table.edit.number:SetFormattedText("%d functions: %0.3f ms", #ElvUIDev.frame.main.devtools.table.sorted, ElvUIDev:GetTotal(5))
	else
		ElvUIDev.frame.main.devtools.table.edit.number:SetFormattedText("%d functions: %0.3f ms", #ElvUIDev.frame.main.devtools.table.filtered, ElvUIDev:GetFiltered(5))
	end
end

function ElvUIDev:GetTotal(row)
	local x = 0

	for i = 1, #self.frame.main.devtools.table.sorted do
		x = x + tonumber(self.frame.main.devtools.table.sorted[i][row].text)
	end

	return x
end

function ElvUIDev:GetFiltered(row)
	local x = 0

	for i = 1, #self.frame.main.devtools.table.filtered do
		x = x + tonumber(self.frame.main.devtools.table.filtered[i][row].text)
	end

	return x
end

function ElvUIDev:MakeScaleable(frame)
	if not frame then
		return
	end

	if frame.resizable then
		return
	end

	frame.resizable = true

	frame.width = frame:GetWidth()
	frame.height = frame:GetHeight()
	frame.scale = frame:GetScale()

	frame.frameLevel = frame:GetFrameLevel()
	if frame.frameLevel > 13 then
		frame.frameLevel = 13
	end

	frame:SetMovable(true)
	frame:SetMaxResize(math.round(frame.width * 1.50375), math.round(frame.height * 1.50375))
	frame:SetMinResize(math.round(frame.width * 0.66125), math.round(frame.height * 0.66125))
	frame:SetUserPlaced(true)

	frame.br = CreateFrame("Frame", nil, frame)
	frame.br:SetFrameStrata(frame:GetFrameStrata())
	frame.br:SetPoint("BottomRight", frame, "BottomRight", -2, 1)
	frame.br:SetWidth(16)
	frame.br:SetHeight(16)
	frame.br:SetFrameLevel(frame.frameLevel + 7)
	frame.br:EnableMouse(true)

	frame.br.texture = frame.br:CreateTexture(nil, "Overlay")
	frame.br.texture:SetPoint("TopLeft", frame.br, "TopLeft", 0, 0)
	frame.br.texture:SetWidth(16)
	frame.br.texture:SetHeight(16)
	frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")

	frame.br:SetScript("OnEnter", function(self)
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
	end)
	frame.br:SetScript("OnLeave", function(self)
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
	end)
	frame.br:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:SetResizable(true)
			frame.resizing = true
			frame:StartSizing("Right")
		end

		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")

		frame.version:SetFormattedText("%.3f", frame.scale)
	end)
	frame.br:SetScript("OnMouseUp", function(self, button)
		if button == "MiddleButton" then
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		end

		local x, y = GetCursorPosition()
		local fx = self:GetLeft() * self:GetEffectiveScale()
		local fy = self:GetBottom() * self:GetEffectiveScale()
		if x >= fx and x <= (fx + self:GetWidth()) and y >= fy and y <= (fy + self:GetHeight()) then
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		else
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		end

		frame.resizing = nil
		frame.direction = nil
		frame:StopMovingOrSizing()
		frame:SetResizable(false)

		frame.version:SetText(GetAddOnMetadata("ElvUIDev", "Version"))
	end)

	frame.bl = CreateFrame("Frame", nil, frame)
	frame.bl:SetFrameStrata(frame:GetFrameStrata())
	frame.bl:SetPoint("BottomLeft", frame, "BottomLeft", 0, 1)
	frame.bl:SetWidth(16)
	frame.bl:SetHeight(16)
	frame.bl:SetFrameLevel(frame.frameLevel + 7)
	frame.bl:EnableMouse(true)

	frame.bl.texture = frame.bl:CreateTexture(nil, "Overlay")
	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = frame.bl.texture:GetTexCoord()
	frame.bl.texture:SetTexCoord(URx, URy, LRx, LRy, ULx, ULy, LLx, LLy)
	frame.bl.texture:SetPoint("TopLeft", frame.bl, "TopLeft", 0, 0)
	frame.bl.texture:SetWidth(16)
	frame.bl.texture:SetHeight(16)
	frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")

	frame.bl:SetScript("OnEnter", function(self)
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
	end)
	frame.bl:SetScript("OnLeave", function(self)
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
	end)
	frame.bl:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:SetResizable(true)
			frame.resizing = true
			frame:StartSizing("Left")
		end

		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")

		frame.version:SetFormattedText("%.3f", frame.scale)
	end)
	frame.bl:SetScript("OnMouseUp", function(self, button)
		if button == "MiddleButton" then
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		end

		local x, y = GetCursorPosition()
		local fx = self:GetLeft() * self:GetEffectiveScale()
		local fy = self:GetBottom() * self:GetEffectiveScale()
		if x >= fx and x <= (fx + self:GetWidth()) and y >= fy and y <= (fy + self:GetHeight()) then
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		else
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		end

		frame.resizing = nil
		frame.direction = nil
		frame:StopMovingOrSizing()
		frame:SetResizable(false)

		frame.version:SetText(GetAddOnMetadata("ElvUIDev", "Version"))
	end)

	frame.tl = CreateFrame("Frame", nil, frame)
	frame.tl:SetFrameStrata(frame:GetFrameStrata())
	frame.tl:SetPoint("TopLeft", frame, "TopLeft", 0, -20)
	frame.tl:SetWidth(16)
	frame.tl:SetHeight(16)
	frame.tl:SetFrameLevel(frame.frameLevel + 7)
	frame.tl:EnableMouse(true)

	frame.tl.texture = frame.tl:CreateTexture(nil, "Overlay")
	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = frame.tl.texture:GetTexCoord()
	frame.tl.texture:SetTexCoord(LRx, LRy, URx, URy, LLx, LLy, ULx, ULy)
	frame.tl.texture:SetPoint("TopLeft", frame.tl, "TopLeft", 0, 0)
	frame.tl.texture:SetWidth(16)
	frame.tl.texture:SetHeight(16)
	frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")

	frame.tl:SetScript("OnEnter", function(self)
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
	end)
	frame.tl:SetScript("OnLeave", function(self)
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
	end)
	frame.tl:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:SetResizable(true)
			frame.resizing = true
			frame.direction = "TopLeft"
			frame:StartSizing("Top")
		end

		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")

		frame.version:SetFormattedText("%.3f", frame.scale)
	end)
	frame.tl:SetScript("OnMouseUp", function(self, button)
		if button == "MiddleButton" then
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		end

		local x, y = GetCursorPosition()
		local fx = self:GetLeft() * self:GetEffectiveScale()
		local fy = self:GetBottom() * self:GetEffectiveScale()
		if x >= fx and x <= (fx + self:GetWidth()) and y >= fy and y <= (fy + self:GetHeight()) then
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		else
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		end

		frame.resizing = nil
		frame.direction = nil
		frame:StopMovingOrSizing()
		frame:SetResizable(false)

		frame.version:SetText(GetAddOnMetadata("ElvUIDev", "Version"))
	end)

	frame.tr = CreateFrame("Frame", nil, frame)
	frame.tr:SetFrameStrata(frame:GetFrameStrata())
	frame.tr:SetPoint("TopRight", frame, "TopRight", -2, -20)
	frame.tr:SetWidth(16)
	frame.tr:SetHeight(16)
	frame.tr:SetFrameLevel(frame.frameLevel + 7)
	frame.tr:EnableMouse(true)

	frame.tr.texture = frame.tr:CreateTexture(nil, "Overlay")
	local ULx, ULy, LLx, LLy, URx, URy, LRx, LRy = frame.tr.texture:GetTexCoord()
	frame.tr.texture:SetTexCoord(LLx, LLy, ULx, ULy, LRx, LRy, URx, URy)
	frame.tr.texture:SetPoint("TopLeft", frame.tr, "TopLeft", 0, 0)
	frame.tr.texture:SetWidth(16)
	frame.tr.texture:SetHeight(16)
	frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")

	frame.tr:SetScript("OnEnter", function(self)
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
	end)
	frame.tr:SetScript("OnLeave", function(self)
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
	end)
	frame.tr:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:SetResizable(true)
			frame.resizing = true
			frame.direction = "TopRight"
			frame:StartSizing("Top")
		end

		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberDown")

		frame.version:SetFormattedText("%.3f", frame.scale)
	end)
	frame.tr:SetScript("OnMouseUp", function(self, button)
		if button == "MiddleButton" then
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		end

		local x, y = GetCursorPosition()
		local fx = self:GetLeft() * self:GetEffectiveScale()
		local fy = self:GetBottom() * self:GetEffectiveScale()
		if x >= fx and x <= (fx + self:GetWidth()) and y >= fy and y <= (fy + self:GetHeight()) then
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberHighlight")
		else
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUIDev\\Textures\\SizeGrabberUp")
		end

		frame.resizing = nil
		frame.direction = nil
		frame:StopMovingOrSizing()
		frame:SetResizable(false)

		frame.version:SetText(GetAddOnMetadata("ElvUIDev", "Version"))
	end)

	frame:SetScript("OnSizeChanged", function(self)
		if not self.resizing then
			return
		end

		local left, bottom = self:GetLeft(), self:GetBottom()

		if self.direction == "TopLeft" or self.direction == "TopRight" then
			self:ClearAllPoints()
			if self.direction == "TopLeft" then
				local x = math.round(-UIParent:GetWidth() + self:GetRight())
				local y = math.round(bottom)

				self:SetPoint("BottomRight", UIParent, "BottomRight", x, y)
			else
				local x = math.round(left)
				local y = math.round(bottom)

				self:SetPoint("BottomLeft", UIParent, "BottomLeft", x, y)
			end

			local scale = self:GetHeight() / frame.height
			self.scale = scale
			--local modifier = ((1 - scale) / 1.8) -- Figure out why the hell do we need this.
			--local xy = modifier / (scale + 1.5)
			self:SetWidth(math.round(frame.width * scale))
			--frame.overlay:SetScale(scale)
			self.overlay:SetScale(scale)
			--self.main.menu:SetPoint("TopLeft", self.main, "TopLeft", 50, math.round(-43 / scale))

			self.shadow.upper:SetPoint("TopLeft", 0, math.round(-21 / self.scale))
			self.shadow.upper:SetPoint("TopRight", math.round(-2 / self.scale), math.round(-21 / self.scale))
			self.shadow.upper:SetScale(scale)

			for i = 1, #self.main.devtools.table.frame.columns do
				if self.main.devtools.table.frame:GetWidth() == 800 then
					return
				end

				local column = self.main.devtools.table.frame.columns[i][1]

				column:SetWidth(math.round(self.main.devtools.table.frame:GetWidth() * self.main.devtools.table.frame.columns[i][6]))
				column:SetMaxResize(math.round(column:GetWidth() * 2), math.round(column:GetHeight() * 2))
				column:SetMinResize(math.round(column:GetWidth() / 1.4), math.round(column:GetHeight() / 1.4))
			end

			local y = math.round(self:GetHeight() - (self.overlay:GetHeight() * scale) + 5)
			self.main.devtools.table:SetPoint("TopLeft", self, "TopLeft", 2 + 20, -y)

			self.version:SetFormattedText("%.3f", self.scale)

			--ElvUIDev:ScaleChildrens(self, scale)
		else
			self:ClearAllPoints()
			local x = math.round(left)
			local y = math.round(-UIParent:GetHeight() + bottom + self:GetHeight())
			self:SetPoint("TopLeft", UIParent, "TopLeft", x, y)

			local scale = self:GetWidth() / frame.width
			self.scale = scale
			--local modifier = ((1 - scale) / 1.8) -- Figure out why the hell do we need this.
			--local xy = modifier / (scale + 1.5)
			self:SetHeight(math.round(frame.height * scale))
			--frame.overlay:SetScale(scale)
			self.overlay:SetScale(scale)
			--self.main.menu:SetPoint("TopLeft", self.main, "TopLeft", 50, math.round(-43 / scale))

			self.shadow.upper:SetPoint("TopLeft", 0, math.round(-21 / self.scale))
			self.shadow.upper:SetPoint("TopRight", math.round(-2 / self.scale), math.round(-21 / self.scale))
			self.shadow.upper:SetScale(scale)

			for i = 1, #self.main.devtools.table.frame.columns do
				if self.main.devtools.table.frame:GetWidth() == 800 then
					return
				end

				local column = self.main.devtools.table.frame.columns[i][1]

				column:SetWidth(math.round(self.main.devtools.table.frame:GetWidth() * self.main.devtools.table.frame.columns[i][6]))
				column:SetMaxResize(math.round(column:GetWidth() * 2), math.round(column:GetHeight() * 2))
				column:SetMinResize(math.round(column:GetWidth() / 1.4), math.round(column:GetHeight() / 1.4))
			end

			local y = math.round(self:GetHeight() - (self.overlay:GetHeight() * scale) + 5)
			self.main.devtools.table:SetPoint("TopLeft", self, "TopLeft", 2 + 20, -y)

			self.version:SetFormattedText("%.3f", self.scale)

			--ElvUIDev:ScaleChildrens(self, scale)
		end
	end)
end

function ElvUIDev:ScaleChildrens(frame, scale)
	--local childrens = {frame:GetChildren()}
	--for _, child in ipairs(childrens) do
	for i = 1, #self.frame.childrens do
		local child = self.frame.childrens[i]
		if child ~= frame.bl and child ~= frame.b and child ~= frame.br and child ~= frame.tr and child ~= frame.t and child ~= frame.tl and child ~= frame.l and child ~= frame.r then
			child:SetScale(scale)
		end
	end
end
