local _, Addon = ...

local CPU = Addon.ElvUI_CPU

local CreateFrame = CreateFrame
local BackdropTemplateMixin = BackdropTemplateMixin
local GameFontHighlight = GameFontHighlight
local GameFontNormal = GameFontNormal

local EditBox = CPU:RegisterWidget("EditBox")

function EditBox:Create(parent)
	local frame = CreateFrame("EditBox", nil, parent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	frame:SetSize(200, 26)
	frame:SetJustifyH("Left")
	frame:SetAutoFocus(false)
	frame:SetFontObject(GameFontHighlight)
	frame:SetTextInsets(4, 4, 2, 2)
	frame:SetHitRectInsets(0, 0, 0, 0)
	frame:SetBackdrop({
		bgFile = "Interface\\Buttons\\White8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 13,
		insets = {left = 3, right = 3, top = 2, bottom = 2}
	})
	frame:SetBackdropColor(0, 0, 0, 0.5)
	frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)

	frame.title = frame:CreateFontString(nil, "Overlay")
	frame.title:SetFontObject(GameFontNormal)
	frame.title:SetJustifyH("Left")
	frame.title:SetJustifyV("Middle")
	frame.title:SetWordWrap(false)
	frame.title:SetSize(194, 20)
	frame.title:SetPoint("BottomLeft", frame, "TopLeft", 3, 0)
	frame.title:SetPoint("BottomRight", frame, "TopRight", -3, 0)
	--frame.title:SetText("EditBox")

	frame:SetScript("OnEnter", function(self)
		self:SetBackdropBorderColor(0.45, 0.45, 0.45, 1.0)
	end)
	frame:SetScript("OnLeave", function(self)
		self:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)
	end)

	frame:SetScript("OnEscapePressed", function(self)
		self:ClearFocus()
	end)
	frame:SetScript("OnEnterPressed", function(self)
		self:ClearFocus()
	end)

	frame:SetScript("OnEditFocusLost", function(self)
		self:HighlightText(0, 0)
	end)
	--[[frame:SetScript("OnEditFocusGained", function(self)
		self:HighlightText(0, -1)
	end)]]

	return frame
end
