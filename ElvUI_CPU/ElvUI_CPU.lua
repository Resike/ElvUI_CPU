local AddonName, Addon = ...

local ElvUI = LibStub("AceAddon-3.0"):GetAddon("ElvUI")
Addon.ElvUI = ElvUI

local CPU = { }
Addon.ElvUI_CPU = CPU

local getmetatable, setmetatable = getmetatable, setmetatable
local print, type, pairs, tonumber = print, type, pairs, tonumber
local wipe, max, floor = wipe, max, floor

local CreateFrame = CreateFrame
local ResetCPUUsage = ResetCPUUsage
local GetAddOnCPUUsage = GetAddOnCPUUsage
local GetAddOnMetadata = GetAddOnMetadata
local GetCursorPosition = GetCursorPosition
local GetFunctionCPUUsage = GetFunctionCPUUsage
local UpdateAddOnCPUUsage = UpdateAddOnCPUUsage
local PlaySound = PlaySound
local GetTime = GetTime

local UIParent = UIParent
local GameFontHighlightSmall = GameFontHighlightSmall
local GameFontNormal = GameFontNormal

_G.ElvUI_CPU = CPU

local round = function(num, decimals)
	local mult = 10^(decimals or 0)

	return floor(num * mult + 0.5) / mult
end

math.round = round

CPU.events = CreateFrame("Frame")
CPU.events:RegisterEvent("ADDON_LOADED")

CPU.events:SetScript("OnEvent", function(self, event, ...)
	CPU[event](CPU, ...)
end)

CPU.peaks = {}
CPU.widgets = { }

function CPU:Print(msg, ...)
	print("|cff1784d1ElvUI|r |cfffe7b2cCPU Analyzer|r: "..msg, ...)
end

-- Widgets
function CPU:RegisterWidget(name)
	if self.widgets[name] then
		CPU:Print("Widget is already registered with this name:", name)
	end

	local class = { }
	class["name"] = name

	self.widgets[name] = class

	return class
end

function CPU:CreateWidget(name, ...)
	local class = self.widgets[name]

	if not class then
		CPU:Print("Widget is not registered:", name)

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

function CPU:GetWidget(name)
	return self.widgets[name]
end

function CPU:HasWidget(name)
	return not not self.widgets[name]
end

function CPU:GetLoadedTime()
	return floor(GetTime() - ElvUI.loadedtime or self.loadedtime)
end

function CPU:ADDON_LOADED(addon)
	if addon == AddonName then
		CPU.loadedtime = GetTime()

		self:CreateOptions()

		if not self.frame.main.devtools.table.loaded then
			self:AddFunctions()
			self:UpdateFunctions()

			self.frame.main.devtools.table.loaded = true
		end

		CPU:Print("Addon loaded into the memory.")
	end
end

function CPU:CreateOptions()
	self.frame = self:CreateWidget("Window", "ElvUI_CPUOptions", UIParent)
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
				if v == "ElvUI_CPUOptions" then
					tremove(UISpecialFrames, i)
				end
			end
		end)
		InterfaceOptionsFrame:HookScript("OnHide", function(self)
			tinsert(UISpecialFrames, "ElvUI_CPUOptions")
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

			--local x = round((left + (self:GetWidth() / 2)) - (UIParent:GetWidth() / 2))
			--local y = round((bottom + (self:GetHeight() / 2)) - (UIParent:GetHeight() / 2))

			local x = round(left)
			local y = round(-UIParent:GetHeight() + bottom + self:GetHeight())

			self:ClearAllPoints()
			self:SetPoint("TopLeft", UIParent, "TopLeft", x, y)
		end
	end)

	--[[self.frame:SetScript("OnMouseWheel", function(self, delta)
		self.overlay.texture:SetAlpha(self.overlay.texture:GetAlpha() - (delta / 50))
		self.Bg:SetAlpha(self.Bg:GetAlpha() - (delta / 200))
	end)]]

	self.frame.title:SetText("|cff1784d1ElvUI|r |cfffe7b2cCPU Analyzer|r")

	self.frame.version = self.frame:CreateFontString(nil, "Overlay")
	self.frame.version:SetFontObject(GameFontNormal)
	self.frame.version:SetVertexColor(0.8, 0.8, 0.8, 0.3)
	self.frame.version:SetPoint("BottomRight", self.frame, "BottomRight", -15, 3)
	self.frame.version:SetWidth(120)
	self.frame.version:SetHeight(20)
	self.frame.version:SetJustifyV("Middle")
	self.frame.version:SetJustifyH("Right")
	self.frame.version:SetText(GetAddOnMetadata("ElvUI_CPU", "Version"))
	self.frame.version:SetWordWrap(false)

	self.frame.main = { }
	self.frame.main.devtools = { }

	self.frame.main.devtools.table = self:CreateWidget("Table", self.frame)
	self.frame.main.devtools.table:SetPoint("TopLeft", self.frame, "TopLeft", 2 + 20, -84)
	self.frame.main.devtools.table:SetPoint("BottomRight", self.frame, "BottomRight", -5 - 20, 75)
	--self.frame.main.devtools.table:Hide()

	self.frame.main.devtools.table:AddColumn("Function", 0.33)
	self.frame.main.devtools.table:AddColumn("Calls", 0.1)
	self.frame.main.devtools.table:AddColumn("Calls/sec", 0.11, "%.3f")
	self.frame.main.devtools.table:AddColumn("Peak time", 0.12, "%.3f ms")
	self.frame.main.devtools.table:AddColumn("Time/call", 0.12, "%.3f ms")
	self.frame.main.devtools.table:AddColumn("Total time", 0.12, "%.3f ms")
	self.frame.main.devtools.table:AddColumn("Overall", 0.1, "%.2f%%", true)

	self.frame.main.devtools.table:SetScript("OnShow", function(frame)
		CPU:UpdateFunctions()
	end)

	self.frame.main.devtools.table.toggle = self:CreateWidget("CheckButtonSquare", self.frame.main.devtools.table)
	self.frame.main.devtools.table.toggle:SetPoint("TopLeft", self.frame.main.devtools.table, "BottomLeft", -2, 0)

	self.frame.main.devtools.table.toggle.texture:SetSize(7, 13)
	self.frame.main.devtools.table.toggle.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\Play")
	self.frame.main.devtools.table.toggle.texture:SetTexCoord(0.3125, 0.75, 0.0625, 0.875)

	self.frame.main.devtools.table.toggle:SetScript("OnClick", function(self, button)
		if self:GetChecked() then
			CPU.timer:SetScript("OnUpdate", CPU.FunctionsOnUpdate)

			self.texture:SetSize(9, 13)
			self.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\Stop")
			self.texture:SetTexCoord(0.1875, 0.75, 0.0625, 0.875)
		else
			CPU.timer:SetScript("OnUpdate", nil)

			self.texture:SetSize(7, 13)
			self.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\Play")
			self.texture:SetTexCoord(0.3125, 0.75, 0.0625, 0.875)
		end
	end)

	self.frame.main.devtools.table.refresh = self:CreateWidget("ButtonSquare", self.frame.main.devtools.table)
	self.frame.main.devtools.table.refresh:SetPoint("TopLeft", self.frame.main.devtools.table.toggle, "TopRight", 0, 0)
	self.frame.main.devtools.table.refresh.texture:SetTexture("Interface\\Buttons\\UI-RefreshButton")
	self.frame.main.devtools.table.refresh:SetScript("OnClick", function(self, button)
		local silent = CPU.update_silent
		CPU.update_silent = nil

		CPU:UpdateFunctions()

		CPU.update_silent = silent
	end)

	self.frame.main.devtools.table.clear = self:CreateWidget("ButtonSquare", self.frame.main.devtools.table)
	self.frame.main.devtools.table.clear:SetPoint("TopLeft", self.frame.main.devtools.table.refresh, "TopRight", 0, 0)
	self.frame.main.devtools.table.clear.texture:SetTexture("Interface\\Buttons\\UI-OptionsButton")
	self.frame.main.devtools.table.clear:SetScript("OnClick", function(self, button)
		wipe(CPU.peaks)

		local silent = CPU.update_silent
		CPU.update_silent = nil
		CPU.allow_reset = true

		ResetCPUUsage()
		CPU.loadedtime = GetTime()
		CPU:UpdateFunctions()

		CPU.allow_reset = nil
		CPU.update_silent = silent
	end)

	self.frame.main.devtools.table.silent = self:CreateWidget("CheckButtonSquare", self.frame.main.devtools.table)
	self.frame.main.devtools.table.silent:SetPoint("TopLeft", self.frame.main.devtools.table.clear, "TopRight", 0, 0)

	self.frame.main.devtools.table.silent.texture:SetSize(7, 13)
	self.frame.main.devtools.table.silent.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\Play")
	self.frame.main.devtools.table.silent.texture:SetTexCoord(0.3125, 0.75, 0.0625, 0.875)

	self.frame.main.devtools.table.silent:SetScript("OnClick", function(self, button)
		if self:GetChecked() then
			CPU.update_silent = true

			self.texture:SetSize(9, 13)
			self.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\Stop")
			self.texture:SetTexCoord(0.1875, 0.75, 0.0625, 0.875)
		else
			CPU.update_silent = nil

			self.texture:SetSize(7, 13)
			self.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\Play")
			self.texture:SetTexCoord(0.3125, 0.75, 0.0625, 0.875)
		end
	end)

	self.frame.main.devtools.table.edit = self:CreateWidget("EditBox", self.frame.main.devtools.table)
	self.frame.main.devtools.table.edit:SetSize(300, 26)
	self.frame.main.devtools.table.edit:SetPoint("Left", self.frame.main.devtools.table.silent, "Right", 3, 0)

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

		CPU.frame.main.devtools.table.edit:SetText("")
		CPU.frame.main.devtools.table.edit:ClearFocus()
	end)

	self.frame.main.devtools.table.edit.clear.texture = self.frame.main.devtools.table.edit.clear:CreateTexture(nil, "Overlay")
	self.frame.main.devtools.table.edit.clear.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\Close")
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

		CPU.frame.main.devtools.table:SetFilter(text)

		if text == "" then
			CPU.frame.main.devtools.table.edit.number:SetFormattedText("%d functions: %0.3f ms", #CPU.frame.main.devtools.table.sorted, CPU:GetTotal(5))
		else
			CPU.frame.main.devtools.table.edit.number:SetFormattedText("%d functions: %0.3f ms", #CPU.frame.main.devtools.table.filtered, CPU:GetFiltered(5))
		end
	end)

	self.frame.childrens = {self.frame:GetChildren()}

	self:MakeScaleable(self.frame)

	self.frame:Hide()

	PlaySound(841)
end

function CPU:ToggleFrame()
	if not self.frame:IsShown() then
		self.frame:Show()
	else
		self.frame:Hide()
	end
end

function CPU:RegisterPlugin(pluginName)
	if (not self.plugins) then
		self.plugins = {};
	end
	self.plugins[pluginName] = true;
end

function CPU:RegisterPluginModule(pluginName, moduleName, module)
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

function CPU:AddFunction(key, func)
	local subs = false
	local usage, calls = GetFunctionCPUUsage(func, subs)
	usage = max(0, usage)
	self.frame.main.devtools.table:AddRow(key, calls, calls / self:GetLoadedTime(), (self.peaks[func] and self.peaks[func].ms) or 0, usage / max(1, calls), usage, (usage / max(1, GetAddOnCPUUsage("ElvUI"))) * 100)
end

function CPU:AddFunctions()
	for key, func in pairs(ElvUI) do
		if type(func) == "function" then
			self:AddFunction("ElvUI:"..key, func)
		end
	end

	for module, tbl in pairs(ElvUI.modules) do
		for key, func in pairs(tbl) do
			if type(func) == "function" then
				self:AddFunction(module..":"..key, func)
			end
		end
	end

	self.frame.main.devtools.table:ApplyFilter()
end

function CPU:UpdateFunction(key, func)
	local subs = false
	local usage, calls = GetFunctionCPUUsage(func, subs)
	usage = max(0, usage)

	local peaks = self.peaks[func]
	if not peaks then
		self.peaks[func] = { ms = 0 }
		peaks = self.peaks[func]
	end

	if peaks.last then
		local times = calls - peaks.past
		local diff = times > 0 and ((usage - peaks.last) / times)
		if diff and (diff > peaks.ms) then
			peaks.ms = diff
		end
	end

	peaks.last = usage
	peaks.past = calls

	if CPU.update_silent then return end

	local callspersec = calls / self:GetLoadedTime()
	local timepercall = usage / max(1, calls)
	local overallusage = (usage / max(1, GetAddOnCPUUsage("ElvUI"))) * 100

	if not CPU.allow_reset and (calls == 0 and callspersec == 0 and timepercall == 0 and usage == 0 and overallusage == 0) then
		return
	end

	self.frame.main.devtools.table:UpdateRow(key, calls, callspersec, peaks.ms, timepercall, usage, overallusage)
end

CPU.timer = CreateFrame('Frame')
function CPU:FunctionsOnUpdate(elapsed)
	self.time = (self.time or 0) + elapsed

	if (CPU.update_silent or CPU.frame:IsShown()) and self.time >= 1 then
		CPU:UpdateFunctions()
		self.time = 0
	end
end

function CPU:UpdateTimes()
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

	for module, tbl in pairs(ElvUI.modules) do
		for key, func in pairs(tbl) do
			if type(func) == "function" then
				self:UpdateFunction(module..":"..key, func)
			end
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
end

function CPU:UpdateFunctions()
	CPU:UpdateTimes()

	self.frame.main.devtools.table:Update()

	if CPU.frame.main.devtools.table.edit:GetText() == "" then
		CPU.frame.main.devtools.table.edit.number:SetFormattedText("%d functions: %0.3f ms", #CPU.frame.main.devtools.table.sorted, CPU:GetTotal(5))
	else
		CPU.frame.main.devtools.table.edit.number:SetFormattedText("%d functions: %0.3f ms", #CPU.frame.main.devtools.table.filtered, CPU:GetFiltered(5))
	end
end

function CPU:GetTotal(row)
	local x = 0

	for i = 1, #self.frame.main.devtools.table.sorted do
		x = x + tonumber(self.frame.main.devtools.table.sorted[i][row].text)
	end

	return x
end

function CPU:GetFiltered(row)
	local x = 0

	for i = 1, #self.frame.main.devtools.table.filtered do
		x = x + tonumber(self.frame.main.devtools.table.filtered[i][row].text)
	end

	return x
end

function CPU:MakeScaleable(frame)
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
	frame:SetResizeBounds(round(frame.width * 0.66125), round(frame.height * 0.66125), round(frame.width * 1.50375), round(frame.height * 1.50375))
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
	frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")

	frame.br:SetScript("OnEnter", function(self)
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
	end)
	frame.br:SetScript("OnLeave", function(self)
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
	end)
	frame.br:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:SetResizable(true)
			frame.resizing = true
			frame:StartSizing("Right")
		end

		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")

		frame.version:SetFormattedText("%.3f", frame.scale)
	end)
	frame.br:SetScript("OnMouseUp", function(self, button)
		if button == "MiddleButton" then
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		end

		local x, y = GetCursorPosition()
		local fx = self:GetLeft() * self:GetEffectiveScale()
		local fy = self:GetBottom() * self:GetEffectiveScale()
		if x >= fx and x <= (fx + self:GetWidth()) and y >= fy and y <= (fy + self:GetHeight()) then
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		else
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		end

		frame.resizing = nil
		frame.direction = nil
		frame:StopMovingOrSizing()
		frame:SetResizable(false)

		frame.version:SetText(GetAddOnMetadata("ElvUI_CPU", "Version"))
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
	frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")

	frame.bl:SetScript("OnEnter", function(self)
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
	end)
	frame.bl:SetScript("OnLeave", function(self)
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
	end)
	frame.bl:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:SetResizable(true)
			frame.resizing = true
			frame:StartSizing("Left")
		end

		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")

		frame.version:SetFormattedText("%.3f", frame.scale)
	end)
	frame.bl:SetScript("OnMouseUp", function(self, button)
		if button == "MiddleButton" then
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		end

		local x, y = GetCursorPosition()
		local fx = self:GetLeft() * self:GetEffectiveScale()
		local fy = self:GetBottom() * self:GetEffectiveScale()
		if x >= fx and x <= (fx + self:GetWidth()) and y >= fy and y <= (fy + self:GetHeight()) then
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		else
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		end

		frame.resizing = nil
		frame.direction = nil
		frame:StopMovingOrSizing()
		frame:SetResizable(false)

		frame.version:SetText(GetAddOnMetadata("ElvUI_CPU", "Version"))
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
	frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")

	frame.tl:SetScript("OnEnter", function(self)
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
	end)
	frame.tl:SetScript("OnLeave", function(self)
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
	end)
	frame.tl:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:SetResizable(true)
			frame.resizing = true
			frame.direction = "TopLeft"
			frame:StartSizing("Top")
		end

		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")
		frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")

		frame.version:SetFormattedText("%.3f", frame.scale)
	end)
	frame.tl:SetScript("OnMouseUp", function(self, button)
		if button == "MiddleButton" then
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		end

		local x, y = GetCursorPosition()
		local fx = self:GetLeft() * self:GetEffectiveScale()
		local fy = self:GetBottom() * self:GetEffectiveScale()
		if x >= fx and x <= (fx + self:GetWidth()) and y >= fy and y <= (fy + self:GetHeight()) then
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		else
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.bl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		end

		frame.resizing = nil
		frame.direction = nil
		frame:StopMovingOrSizing()
		frame:SetResizable(false)

		frame.version:SetText(GetAddOnMetadata("ElvUI_CPU", "Version"))
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
	frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")

	frame.tr:SetScript("OnEnter", function(self)
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
	end)
	frame.tr:SetScript("OnLeave", function(self)
		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
	end)
	frame.tr:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			frame:SetResizable(true)
			frame.resizing = true
			frame.direction = "TopRight"
			frame:StartSizing("Top")
		end

		frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")
		frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")
		frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberDown")

		frame.version:SetFormattedText("%.3f", frame.scale)
	end)
	frame.tr:SetScript("OnMouseUp", function(self, button)
		if button == "MiddleButton" then
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		end

		local x, y = GetCursorPosition()
		local fx = self:GetLeft() * self:GetEffectiveScale()
		local fy = self:GetBottom() * self:GetEffectiveScale()
		if x >= fx and x <= (fx + self:GetWidth()) and y >= fy and y <= (fy + self:GetHeight()) then
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberHighlight")
		else
			frame.tr.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.tl.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
			frame.br.texture:SetTexture("Interface\\AddOns\\ElvUI_CPU\\Textures\\SizeGrabberUp")
		end

		frame.resizing = nil
		frame.direction = nil
		frame:StopMovingOrSizing()
		frame:SetResizable(false)

		frame.version:SetText(GetAddOnMetadata("ElvUI_CPU", "Version"))
	end)

	frame:SetScript("OnSizeChanged", function(self)
		if not self.resizing then
			return
		end

		local left, bottom = self:GetLeft(), self:GetBottom()

		if self.direction == "TopLeft" or self.direction == "TopRight" then
			self:ClearAllPoints()
			if self.direction == "TopLeft" then
				local x = round(-UIParent:GetWidth() + self:GetRight())
				local y = round(bottom)

				self:SetPoint("BottomRight", UIParent, "BottomRight", x, y)
			else
				local x = round(left)
				local y = round(bottom)

				self:SetPoint("BottomLeft", UIParent, "BottomLeft", x, y)
			end

			local scale = self:GetHeight() / frame.height
			self.scale = scale
			--local modifier = ((1 - scale) / 1.8) -- Figure out why the hell do we need this.
			--local xy = modifier / (scale + 1.5)
			self:SetWidth(round(frame.width * scale))
			--frame.overlay:SetScale(scale)
			self.overlay:SetScale(scale)
			--self.main.menu:SetPoint("TopLeft", self.main, "TopLeft", 50, round(-43 / scale))

			self.shadow.upper:SetPoint("TopLeft", 0, round(-21 / self.scale))
			self.shadow.upper:SetPoint("TopRight", round(-2 / self.scale), round(-21 / self.scale))
			self.shadow.upper:SetScale(scale)

			for i = 1, #self.main.devtools.table.frame.columns do
				if self.main.devtools.table.frame:GetWidth() == 800 then
					return
				end

				local column = self.main.devtools.table.frame.columns[i][1]

				column:SetWidth(round(self.main.devtools.table.frame:GetWidth() * self.main.devtools.table.frame.columns[i][6]))
				column:SetMaxResize(round(column:GetWidth() * 2), round(column:GetHeight() * 2))
				column:SetMinResize(round(column:GetWidth() / 1.4), round(column:GetHeight() / 1.4))
			end

			local y = round(self:GetHeight() - (self.overlay:GetHeight() * scale) + 5)
			self.main.devtools.table:SetPoint("TopLeft", self, "TopLeft", 2 + 20, -y)

			self.version:SetFormattedText("%.3f", self.scale)

			--CPU:ScaleChildrens(self, scale)
		else
			self:ClearAllPoints()
			local x = round(left)
			local y = round(-UIParent:GetHeight() + bottom + self:GetHeight())
			self:SetPoint("TopLeft", UIParent, "TopLeft", x, y)

			local scale = self:GetWidth() / frame.width
			self.scale = scale
			--local modifier = ((1 - scale) / 1.8) -- Figure out why the hell do we need this.
			--local xy = modifier / (scale + 1.5)
			self:SetHeight(round(frame.height * scale))
			--frame.overlay:SetScale(scale)
			self.overlay:SetScale(scale)
			--self.main.menu:SetPoint("TopLeft", self.main, "TopLeft", 50, round(-43 / scale))

			self.shadow.upper:SetPoint("TopLeft", 0, round(-21 / self.scale))
			self.shadow.upper:SetPoint("TopRight", round(-2 / self.scale), round(-21 / self.scale))
			self.shadow.upper:SetScale(scale)

			for i = 1, #self.main.devtools.table.frame.columns do
				if self.main.devtools.table.frame:GetWidth() == 800 then
					return
				end

				local column = self.main.devtools.table.frame.columns[i][1]

				column:SetWidth(round(self.main.devtools.table.frame:GetWidth() * self.main.devtools.table.frame.columns[i][6]))
				column:SetMaxResize(round(column:GetWidth() * 2), round(column:GetHeight() * 2))
				column:SetMinResize(round(column:GetWidth() / 1.4), round(column:GetHeight() / 1.4))
			end

			local y = round(self:GetHeight() - (self.overlay:GetHeight() * scale) + 5)
			self.main.devtools.table:SetPoint("TopLeft", self, "TopLeft", 2 + 20, -y)

			self.version:SetFormattedText("%.3f", self.scale)

			--CPU:ScaleChildrens(self, scale)
		end
	end)
end

function CPU:ScaleChildrens(frame, scale)
	--local childrens = {frame:GetChildren()}
	--for _, child in ipairs(childrens) do
	for i = 1, #self.frame.childrens do
		local child = self.frame.childrens[i]
		if child ~= frame.bl and child ~= frame.b and child ~= frame.br and child ~= frame.tr and child ~= frame.t and child ~= frame.tl and child ~= frame.l and child ~= frame.r then
			child:SetScale(scale)
		end
	end
end
