local _, Addon = ...

local CPU = Addon.ElvUI_CPU

--local hooksecurefunc = hooksecurefunc

local CreateFrame = CreateFrame

local GameFontNomal = GameFontNomal
local GameFontHighlight = GameFontHighlight
local GameFontDisable = GameFontDisable

local CheckButton = CPU:RegisterWidget("CheckButton")

function CheckButton:Create(parent)
	local frame = CreateFrame("CheckButton", nil, parent)
	frame:SetSize(20, 20)
	frame:SetNormalFontObject(GameFontNomal)
	local normalFont = frame:GetNormalFontObject()
	normalFont:SetTextColor(1, 1, 1)
	frame:SetHighlightFontObject(GameFontHighlight)
	local highlightFont = frame:GetHighlightFontObject()
	highlightFont:SetTextColor(1, 0.82, 0)
	frame:SetDisabledFontObject(GameFontDisable)
	local disableFont = frame:GetDisabledFontObject()
	disableFont:SetTextColor(0.5, 0.5, 0.5)
	frame:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up")
	frame:SetCheckedTexture("Interface\\Buttons\\UI-Common-MouseHilight")
	frame:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight")

	frame.text = frame:CreateFontString(nil, "Overlay")
	frame.text:SetFontObject(GameFontNomal)
	frame.text:SetJustifyH("Left")
	frame.text:SetJustifyV("Middle")
	frame.text:SetWordWrap(false)
	frame.text:SetPoint("Left", frame, "Right", 1, 1)
	frame.text:SetText("CheckButton")

	frame:SetFontString(frame.text)
	frame:SetHitRectInsets(0, -frame:GetWidth() + 10 - frame.text:GetStringWidth(), 0, 4)

	-- Only for non-static text
	--[[hooksecurefunc(frame.text, "SetText", function(self)
		frame:SetHitRectInsets(0, -frame:GetWidth() + 10 - frame.text:GetStringWidth(), 0, 0)
	end)]]

	return frame
end

local CheckButtonIcon = CPU:RegisterWidget("CheckButtonIcon")

function CheckButtonIcon:Create(parent)
	local frame = CreateFrame("CheckButton", nil, parent)
	frame:SetSize(100, 32)
	frame:SetNormalFontObject(GameFontNomal)
	local normalFont = frame:GetNormalFontObject()
	normalFont:SetTextColor(1, 1, 1)
	frame:SetHighlightFontObject(GameFontHighlight)
	local highlightFont = frame:GetHighlightFontObject()
	highlightFont:SetTextColor(1, 0.82, 0)
	frame:SetDisabledFontObject(GameFontDisable)
	local disableFont = frame:GetDisabledFontObject()
	disableFont:SetTextColor(0.5, 0.5, 0.5)

	frame.icon = frame:CreateTexture(nil, "Artwork")
	frame.icon:SetSize(24, 24)
	frame.icon:SetPoint("TopLeft", 4, -4)

	frame.text = frame:CreateFontString(nil, "Overlay")
	frame.text:SetFontObject(GameFontNomal)
	frame.text:SetPoint("TopLeft", 36, -4)
	frame.text:SetPoint("BottomRight", -4, 4)
	frame.text:SetJustifyV("Middle")
	frame.text:SetJustifyH("Left")
	frame.text:SetText("CheckButton")

	frame:SetFontString(frame.text)

	-- Only for non-static text
	--[[hooksecurefunc(frame.text, "SetText", function(self)
		frame:SetHitRectInsets(0, -frame:GetWidth() + 10 - frame.text:GetStringWidth(), 0, 0)
	end)]]

	return frame
end

local CheckButtonSquare = CPU:RegisterWidget("CheckButtonSquare")

function CheckButtonSquare:Create(parent)
	local frame = CreateFrame("CheckButton", nil, parent)
	frame:SetSize(32, 32)

	frame:SetNormalTexture("Interface\\Buttons\\UI-SquareButton-Up")
	frame:GetNormalTexture():SetDesaturated(true)
	frame:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8, 1.0)
	frame:GetNormalTexture():SetDrawLayer("Overlay", 3)

	frame:SetPushedTexture("Interface\\Buttons\\UI-SquareButton-Down")
	frame:GetPushedTexture():SetDesaturated(true)
	frame:GetPushedTexture():SetVertexColor(0.8, 0.8, 0.8, 1.0)
	frame:GetPushedTexture():SetDrawLayer("Overlay", 3)

	frame:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

	frame:GetHighlightTexture():SetBlendMode("Add")
	frame:GetHighlightTexture():SetAlpha(0.75)
	frame:GetHighlightTexture():SetPoint("TopLeft", frame, "TopLeft", 0, -2)
	frame:GetHighlightTexture():SetPoint("BottomRight", frame, "BottomRight", -2, 1)

	frame.texture = frame:CreateTexture("Overlay")
	frame.texture:SetDrawLayer("Overlay", 5)
	frame.texture:SetSize(14, 14)
	frame.texture:SetPoint("Center", frame, "Center", 0, 0)

	frame:SetScript("OnMouseDown", function(self, button)
		self.texture:SetVertexColor(0.5, 0.5, 0.5, 1.0)
		self.texture:SetPoint("Center", self, "Center", -1, -2)
	end)
	frame:SetScript("OnMouseUp", function(self, button)
		self.texture:SetVertexColor(0.8, 0.8, 0.8, 1.0)
		self.texture:SetPoint("Center", self, "Center", 0, 0)
	end)

	return frame
end
