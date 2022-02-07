local _, Addon = ...

local ElvUI_CPU = Addon.ElvUI_CPU

local CreateFrame = CreateFrame
local GameFontDisableSmall = GameFontDisableSmall
local GameFontHighlightSmall = GameFontHighlightSmall

local Button = ElvUI_CPU:RegisterWidget("Button")

function Button:Create(parent)
	local frame = CreateFrame("Button", nil, parent)
	frame:SetSize(150, 22)
	frame:SetNormalFontObject(GameFontHighlightSmall)
	frame:SetDisabledFontObject(GameFontDisableSmall)
	frame:SetHighlightFontObject(GameFontHighlightSmall)

	frame.text = frame:CreateFontString(nil, "Overlay")
	frame.text:SetFontObject(GameFontHighlightSmall)
	frame.text:SetJustifyH("Left")
	frame.text:SetJustifyV("Middle")
	frame.text:SetWordWrap(false)
	frame.text:SetPoint("Left", frame, "Right", 5, 0)
	frame.text:SetText("Button")

	frame:SetFontString(frame.text)

	return frame
end

local ButtonSquare = ElvUI_CPU:RegisterWidget("ButtonSquare")

function ButtonSquare:Create(parent)
	local frame = CreateFrame("Button", nil, parent)
	frame:SetSize(32, 32)

	frame:SetNormalTexture("Interface\\Buttons\\UI-SquareButton-Up")
	frame:GetNormalTexture():SetDesaturated(true)
	frame:GetNormalTexture():SetVertexColor(0.8, 0.8, 0.8)
	frame:GetNormalTexture():SetDrawLayer("Overlay", 3)

	frame:SetPushedTexture("Interface\\Buttons\\UI-SquareButton-Down")
	frame:GetPushedTexture():SetDesaturated(true)
	frame:GetPushedTexture():SetVertexColor(0.8, 0.8, 0.8)
	frame:GetPushedTexture():SetDrawLayer("Overlay", 3)

	frame:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight")

	frame:GetHighlightTexture():SetBlendMode("Add")
	frame:GetHighlightTexture():SetAlpha(0.75)
	frame:GetHighlightTexture():SetPoint("TopLeft", frame, "TopLeft", 0, -2)
	frame:GetHighlightTexture():SetPoint("BottomRight", frame, "BottomRight", -2, 1)

	frame.texture = frame:CreateTexture("Overlay")
	frame.texture:SetDrawLayer("Overlay", 5)
	frame.texture:SetSize(14, 14)
	frame.texture:SetPoint("Center", frame, "Center", -1, -1)

	frame:SetScript("OnMouseDown", function(self, button)
		self.texture:SetVertexColor(0.5, 0.5, 0.5)
		self.texture:SetPoint("Center", self, "Center", -2, -3)
	end)
	frame:SetScript("OnMouseUp", function(self, button)
		self.texture:SetVertexColor(1, 1, 1)
		self.texture:SetPoint("Center", self, "Center", -1, -1)
	end)

	return frame
end
