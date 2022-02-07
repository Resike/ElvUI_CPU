local _, Addon = ...

local ElvUI_CPU = Addon.ElvUI_CPU

local CreateFrame = CreateFrame
local PlaySound = PlaySound

local UIParent = UIParent
local GameFontHighlight = GameFontHighlight

local Window = ElvUI_CPU:RegisterWidget("Window")

function Window:Create(name, parent)
	local frame = CreateFrame("Frame", name, parent or UIParent, "BasicFrameTemplate")
	frame:SetClampedToScreen(true)

	frame.Bg:SetTexture("Interface\\FrameGeneral\\UI-Background-Marble", true, true)
	frame.Bg:SetHorizTile(true)
	frame.Bg:SetVertTile(true)
	frame.Bg:SetAlpha(1)

	frame.TitleBg:SetTexture("Interface\\HelpFrame\\DarkSandstone-Tile", true, false)
	frame.TitleBg:SetHorizTile(true)
	frame.TitleBg:SetVertTile(false)

	--[[frame.gradient = frame:CreateTexture(nil, "Background")
	frame.gradient:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	--frame.gradient:SetMask("Interface\\CharacterFrame\\Button_BloodPresence_DeathKnight")
	frame.gradient:SetBlendMode("Add")
	frame.gradient:SetGradientAlpha("Vertical", 1, 1, 1, 1, 0.1, 0.1, 0.1, 0)
	--frame.gradient:SetPoint("TopLeft", frame, "TopLeft", 1, -1)
	--frame.gradient:SetPoint("BottomRight", frame, "BottomRight", -1, 1)
	frame.gradient:SetAllPoints(frame.Bg)]]

	frame.overlay = CreateFrame("Frame", nil, frame)
	frame.overlay:SetPoint("TopLeft", 2, -76)
	frame.overlay:SetPoint("BottomRight", -2, 2)

	frame.overlay.texture = frame:CreateTexture(nil, "Background")
	frame.overlay.texture:SetDrawLayer("Background", 3)
	frame.overlay.texture:SetAllPoints(frame.overlay)
	frame.overlay.texture:SetTexture("Interface\\HelpFrame\\DarkSandstone-Tile", true, true)
	frame.overlay.texture:SetDrawLayer("Background", 2)
	frame.overlay.texture:SetHorizTile(true)
	frame.overlay.texture:SetVertTile(true)

	frame.line = frame.overlay:CreateTexture(nil, "Border")
	frame.line:SetDrawLayer("Background", 5)
	frame.line:SetTexture("Interface\\LevelUp\\LevelUpTex")
	frame.line:SetTexCoord(0.00195313, 0.81835938, 0.035, 0.018625)
	--frame.line:SetTexCoord(0, 0.8203125, 0.03125, 0.03515625) -- SetHeight(2)
	frame.line:SetPoint("TopLeft", 0, 0)
	frame.line:SetPoint("TopRight", 0, 0)
	frame.line:SetHeight(7)

	frame.shadow = { }

	frame.shadow.upper = CreateFrame("Frame", nil, frame)
	frame.shadow.upper:SetHeight(43)
	frame.shadow.upper:SetPoint("TopLeft", 0, -21)
	frame.shadow.upper:SetPoint("TopRight", -2, -21)
	frame.shadow.upper:SetFrameLevel(1)
	frame.shadow.upper:Hide()

	frame.shadow.upper.texture = frame.shadow.upper:CreateTexture(nil, "Background")
	frame.shadow.upper.texture:SetDrawLayer("Background", 4)
	frame.shadow.upper.texture:SetTexture("Interface\\Common\\bluemenu-goldborder-horiz", true, true)
	frame.shadow.upper.texture:SetTexCoord(0, 1, 0.015625, 0.3515625)
	frame.shadow.upper.texture:SetHorizTile(true)
	frame.shadow.upper.texture:SetHeight(43)
	frame.shadow.upper.texture:SetAllPoints(frame.shadow.upper)

	frame.shadow.top = frame.overlay:CreateTexture(nil, "Background")
	frame.shadow.top:SetDrawLayer("Background", 4)
	frame.shadow.top:SetTexture("Interface\\Common\\bluemenu-goldborder-horiz", true, true)
	frame.shadow.top:SetTexCoord(0, 1, 0.015625, 0.3515625)
	frame.shadow.top:SetHorizTile(true)
	frame.shadow.top:SetHeight(43)
	frame.shadow.top:SetPoint("TopLeft", 0, 0)
	frame.shadow.top:SetPoint("TopRight", -2, 0)

	frame.shadow.bottom = frame.overlay:CreateTexture(nil, "Background")
	frame.shadow.bottom:SetDrawLayer("Background", 4)
	frame.shadow.bottom:SetTexture("Interface\\Common\\bluemenu-goldborder-horiz", true, true)
	frame.shadow.bottom:SetTexCoord(0, 1, 0.3515625, 0.6875)
	frame.shadow.bottom:SetHorizTile(true)
	frame.shadow.bottom:SetHeight(43)
	frame.shadow.bottom:SetPoint("BottomLeft", 0, 0)
	frame.shadow.bottom:SetPoint("BottomRight", 0, 0)

	frame.title = frame:CreateFontString(nil, "Overlay")
	frame.title:SetPoint("Top", 0, 1.5)
	frame.title:SetHeight(24)
	frame.title:SetFontObject(GameFontHighlight)
	frame.title:SetTextColor(1, 0.82, 0)
	frame.title:SetShadowOffset(1, -1)
	frame.title:SetJustifyH("Center")
	frame.title:SetJustifyV("Middle")
	frame.title:SetText("")

	--[[if collapse then
		frame.collapse = CreateFrame("Button", nil, frame)
		frame.collapse:SetHitRectInsets(7, 7, 7, 7)
		frame.collapse:SetPoint("Right", frame.CloseButton, "Left", 10, 0)
		frame.collapse:SetWidth(32)
		frame.collapse:SetHeight(32)
		frame.collapse:SetNormalTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Up")
		frame.collapse:SetPushedTexture("Interface\\Buttons\\UI-Panel-CollapseButton-Down")
		frame.collapse:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", "Add")
	end]]

	frame.CloseButton:SetHitRectInsets(6, 6, 6, 6)

	frame:SetScript("OnMouseDown", function(self, button)
		if button == "LeftButton" then
			self:StartMoving()
		end
	end)
	frame:SetScript("OnMouseUp", function(self, button)
		if button == "LeftButton" then
			self:StopMovingOrSizing()
		end
	end)

	frame:SetScript("OnShow", function(self, button)
		PlaySound(841)
	end)
	frame:SetScript("OnHide", function(self, button)
		PlaySound(851)
	end)

	return frame
end
