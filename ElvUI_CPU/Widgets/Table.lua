local _, Addon = ...

local CPU = Addon.ElvUI_CPU

local assert, strfind, tostring = assert, strfind, tostring
local type, select, sort = type, select, sort

local min, max, round = min, max, math.round

local UIParent = UIParent
local PlaySound = PlaySound
local CreateFrame = CreateFrame
local BackdropTemplateMixin = BackdropTemplateMixin
local GameFontHighlightSmall = GameFontHighlightSmall
local GameFontNormalSmall = GameFontNormalSmall

local Table = CPU:RegisterWidget("Table")

local ElvUI = LibStub("AceAddon-3.0"):GetAddon("ElvUI")
Addon.ElvUI = ElvUI

function Table:Create(parent)
	self.frame = CreateFrame("Frame", nil, parent or UIParent, BackdropTemplateMixin and "BackdropTemplate" or nil)
	self.frame:SetPoint("TopLeft", parent, "TopLeft", 0, 0)
	self.frame:SetPoint("BottomRight", parent, "BottomRight", 0, 0)
	self.frame:SetSize(800, 600)

	self.frame.backdrop = {
		bgFile = "Interface\\Buttons\\WHITE8X8",
		edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
		tile = true,
		tileSize = 16,
		edgeSize = 14,
		insets = {left = 2, right = 2, top = 2, bottom = 2},
	}

	self.frame:SetBackdrop(self.frame.backdrop)
	self.frame:SetBackdropColor(0.0, 0.0, 0.0, 0.5)
	self.frame:SetBackdropBorderColor(0.3, 0.3, 0.3, 1.0)

	self.frame.columns = { }
	--self.frame.rows = { }

	--self.frame.rowstext = { }

	self.frame.sorted = { }

	self.frame.sortedheader = 1
	self.frame.descending = false

	self.frame.filtered = { }

	self.frame.filter = ""

	self.frame.scrollframe = CreateFrame("ScrollFrame", nil, self.frame)
	self.frame.scrollframe:SetPoint("TopLeft", self.frame, "TopLeft", 2, -2 - 19)
	self.frame.scrollframe:SetPoint("BottomRight", self.frame, "BottomRight", -2, 2 + 1)
	self.frame.scrollframe:SetClipsChildren(true)

	self.frame.header = CreateFrame("ScrollFrame", nil, self.frame)
	self.frame.header:SetPoint("TopLeft", self.frame, "TopLeft", 0, 0)
	self.frame.header:SetPoint("BottomRight", self.frame, "TopRight", 0, -24)

	self.frame.headerscrolling = CreateFrame("Frame", nil, self.frame.header)
	self.frame.headerscrolling:SetSize(11, 19)
	self.frame.headerscrolling:SetAllPoints(self.frame.header)

	self.frame.header:SetScrollChild(self.frame.headerscrolling)

	self.frame.scrollbar = CreateFrame("Slider", nil, self.frame, "UIPanelScrollBarTemplate")
	self.frame.scrollbar:SetScript("OnValueChanged", nil) -- :GetParent() visibility bug with :SetClipsChildren(true)
	self.frame.scrollbar:SetPoint("TopRight", self.frame, "TopRight", -4 + 21, -18)
	self.frame.scrollbar:SetPoint("BottomRight", self.frame, "BottomRight", -4 + 21, 17)
	self.frame.scrollbar:SetMinMaxValues(0, 0)
	self.frame.scrollbar:SetValueStep(22)
	self.frame.scrollbar:SetObeyStepOnDrag(true)
	self.frame.scrollbar.scrollStep = 1
	self.frame.scrollbar:SetValue(1)
	self.frame.scrollbar.ScrollUpButton:Disable()
	self.frame.scrollbar:SetWidth(16)

	self.frame.scrollbar:SetScript("OnValueChanged", function(self, value)
		if not self:IsShown() then
			return
		end

		local min, max = self:GetMinMaxValues()
		if value == min then
			self.ScrollUpButton:Disable()
		else
			self.ScrollUpButton:Enable()
		end

		if value == max then
			self.ScrollDownButton:Disable()
		else
			self.ScrollDownButton:Enable()
		end

		self:GetParent().scrollframe:SetVerticalScroll(value)

		-- Too expensive
		local offset = (self:GetValue() / self:GetValueStep())

		if offset % 2 == 0 then
			for i = 1, #Table.frame.rowframes do
				for j = 1, #Table.frame.rowframes[i] do
					if i % 2 == 0 then
						Table.frame.rowframes[i][j].bg:SetColorTexture(0.4, 0.4, 0.4)
					else
						Table.frame.rowframes[i][j].bg:SetColorTexture(0.9, 0.9, 1)
					end
				end
			end
		else
			for i = 1, #Table.frame.rowframes do
				for j = 1, #Table.frame.rowframes[i] do
					if i % 2 == 0 then
						Table.frame.rowframes[i][j].bg:SetColorTexture(0.9, 0.9, 1)
					else
						Table.frame.rowframes[i][j].bg:SetColorTexture(0.4, 0.4, 0.4)
					end
				end
			end
		end

		Table:UpdateItems()

		--[[local startline = (self:GetValue() / 22) + 1
		local endline = startline + 18

		if endline > #Table.frame.rows then
			endline = #Table.frame.rows
		end

		for i = 1, #Table.frame.rows do
			for j = 1, #Table.frame.rows[i] do
				if i >= startline and i <= endline then
					Table.frame.rows[i][j]:Show()
				else
					Table.frame.rows[i][j]:Hide()
				end
			end
		end]]
	end)

	self.frame:SetScript("OnMouseWheel", function (self, delta)
		self.scrollbar:SetValue(self.scrollbar:GetValue() - (delta * 27 * self.scrollbar.scrollStep))
	end)

	self.frame.scrollbar.bg = self.frame.scrollbar:CreateTexture(nil, "Background")
	self.frame.scrollbar.bg:SetAllPoints(self.frame.scrollbar)
	self.frame.scrollbar.bg:SetColorTexture(0, 0, 0, 0.4)

	self.frame.scrolling = CreateFrame("Frame", nil, self.frame.scrollframe)
	--self.frame.scrolling:SetPoint("TopLeft", self.frame.scrollframe, "TopLeft", 0, 0)
	--self.frame.scrolling:SetPoint("BottomRight", self.frame.scrollframe, "BottomRight", 0, 0)
	self.frame.scrolling:SetAllPoints(self.frame.scrollframe)
	self.frame.scrolling:SetSize(800, 0)

	self.frame.scrollframe:SetScrollChild(self.frame.scrolling)

	function self.frame.sorter(a, b)
		local col, desc = self.frame.sortedheader, self.frame.descending
		--print(a[col].text, b[col].text)
		return (desc and a[col].text > b[col].text) or
		(not desc and a[col].text < b[col].text) or
		(a[col].text == b[col].text and a[1].text < b[1].text)
	end

	return self.frame
end

function Table:GetSortedColumn()
	return self.frame.sortedheader, self.frame.descending
end

function Table:SetSortedColumn(id, desc)
	self.frame.sortedheader = max(1, min(#(self.frame.columns), id))
	self.frame.descending = not not desc
	self:SortColumn()
end

function Table:SortColumn()
	local items
	if self.frame.filter and self.frame.filter ~= "" then
		items = self.frame.filtered
	else
		items = self.frame.sorted
	end

	sort(items, self.frame.columns[self.frame.sortedheader][5])

	self:UpdateItems()
end

function Table:AddColumn(text, width, format, last)
	local frame = self:CreateColumn(self.frame.headerscrolling, text, width, format, last)
	--frame:SetID(#self.frame.columns + 1)

	--tinsert(self.frame.columns, {frame, text, width, format})

	self.frame.columns[#self.frame.columns + 1] = {frame, text, width, format, self.sorter, width}

	--self:Sort()

	return #self.frame.columns
end

function Table:CreateColumn(parent, text, width, format, last)
	local frame = CreateFrame("Button", nil, parent)
	frame:SetID(#self.frame.columns + 1)

	if last then
		frame.last = last
	end

	if self.frame.lastcolumn then
		if frame.last then
			frame:SetPoint("TopLeft", self.frame.lastcolumn, "TopRight", -2, 0)
			frame:SetPoint("TopRight", self.frame, "TopRight", -2, 0)
		else
			frame:SetPoint("TopLeft", self.frame.lastcolumn, "TopRight", -2, 0)
		end
	else
		frame:SetPoint("TopLeft", parent, "TopLeft", 1, -2)
	end

	--[[local x = 0
	if self.frame.scrollbar:IsShown() then
		x = 12
	end]]

	--frame:SetSize((self.frame:GetWidth() - x) * width, 24)
	frame:SetSize(round(self.frame:GetWidth() * width), 24)
	if ElvUI.Classic then
		frame:SetMaxResize(round(frame:GetWidth() * 2), round(frame:GetHeight() * 2))
		frame:SetMinResize(round(frame:GetWidth() / 1.4), round(frame:GetHeight() / 1.4))
	else
		frame:SetResizeBounds(round(frame:GetWidth() / 1.4), round(frame:GetHeight() / 1.4),round(frame:GetWidth() * 2), round(frame:GetHeight() * 2))
	end

	frame.text = frame:CreateFontString(nil, "Overlay")
	if frame:GetID() == 1 then
		frame.text:SetPoint("TopLeft", frame, "TopLeft", 6.5, -2.5)
	else
		frame.text:SetPoint("TopLeft", frame, "TopLeft", 4.5, -2.5)
	end
	frame.text:SetPoint("BottomRight", frame, "BottomRight", -4 - 20, 6)
	frame.text:SetFontObject(GameFontHighlightSmall)
	--frame.text:SetVertexColor(0.4, 0.7, 1, 1)
	frame.text:SetJustifyH("Left")
	frame.text:SetWordWrap(false)

	frame:SetFontString(frame.text)
	frame:SetText(text)

	--frame:SetNormalFontObject(GameFontHighlightSmall)
	frame:SetHighlightTexture([[Interface\HelpFrame\KnowledgeBaseButtton]])
	frame:GetHighlightTexture():SetTexCoord(0.13085938, 0.63085938, 0.0078125, 0.203125)
	frame:GetHighlightTexture():ClearAllPoints()
	frame:GetHighlightTexture():SetPoint("TopLeft", 2, -1)
	frame:GetHighlightTexture():SetPoint("BottomRight", -1, 5)

	--[=[frame.highlight = CreateFrame("Frame", nil, frame)
	frame.highlight:SetAllPoints(frame)

	frame.highlight.l = frame.highlight:CreateTexture(nil, "Highlight")
	frame.highlight.l:SetTexture([[Interface\ChatFrame\ChatFrameTab-HighlightLeft]])
	frame.highlight.l:SetPoint("TopLeft", frame.highlight, "TopLeft", 1, 0)
	frame.highlight.l:SetBlendMode("Add")
	frame.highlight.l:SetVertexColor(0.2, 0.5, 1, 0.75)
	frame.highlight.l:SetSize(12, 19)
	frame.highlight.l:SetTexCoord(0.25, 1, 0.375, 1)

	frame.highlight.r = frame.highlight:CreateTexture(nil, "Highlight")
	frame.highlight.r:SetTexture([[Interface\ChatFrame\ChatFrameTab-HighlightRight]])
	frame.highlight.r:SetPoint("TopRight", frame.highlight, "TopRight", 0, 0)
	frame.highlight.r:SetBlendMode("Add")
	frame.highlight.r:SetVertexColor(0.2, 0.5, 1, 0.75)
	frame.highlight.r:SetSize(12, 19)
	frame.highlight.r:SetTexCoord(0, 0.75, 0.375, 1)

	frame.highlight.m = frame.highlight:CreateTexture(nil, "Highlight")
	frame.highlight.m:SetTexture([[Interface\ChatFrame\ChatFrameTab-HighlightMid]])
	frame.highlight.m:SetPoint("TopLeft", frame.highlight.l, "TopRight", 0, 0)
	frame.highlight.m:SetPoint("BottomRight", frame.highlight.r, "BottomLeft", 0, 0)
	frame.highlight.m:SetBlendMode("Add")
	frame.highlight.m:SetVertexColor(0.2, 0.5, 1, 0.75)
	frame.highlight.m:SetTexCoord(0, 1, 0.375, 1)

	frame.highlight:SetScript("OnEnter", function(self)
		frame.highlight.l:Show()
		frame.highlight.r:Show()
		frame.highlight.m:Show()
	end)

	frame.highlight:SetScript("OnLeave", function(self)
		frame.highlight.l:Hide()
		frame.highlight.r:Hide()
		frame.highlight.m:Hide()
	end)]=]

	if not frame.last then
		frame.resize = CreateFrame("Frame", nil, frame)
		frame.resize:EnableMouse(true)
		frame.resize:SetSize(7, 17)
		frame.resize:SetPoint("Center", frame, "Right", 0, 0)
		--frame.resize.bg = frame.resize:CreateTexture(nil, "Background")
		--frame.resize.bg:SetAllPoints(frame.resize)
		--frame.resize.bg:SetColorTexture(0.9, 0.9, 1)
		--frame.resize.bg:SetAlpha(0.1)

		frame.resize:SetScript("OnMouseDown", function(resize, button)
			--frame:SetParent(self.frame)
			frame:SetResizable(true)
			frame:StartSizing("Right")
		end)
		frame.resize:SetScript("OnMouseUp", function(resize, button)
			frame:SetResizable(false)
			frame:StopMovingOrSizing()

			for i = 1, #self.frame.columns do
				if i ~= 1 then
					if self.frame.columns[i][1].last then
						self.frame.columns[i][1]:SetPoint("TopLeft", self.frame.columns[i - 1][1], "TopRight", -2, 0)
						self.frame.columns[i][1]:SetPoint("TopRight", self.frame, "TopRight", -2, 0)
					else
						self.frame.columns[i][1]:SetPoint("TopLeft", self.frame.columns[i - 1][1], "TopRight", -2, 0)
					end
				else
					self.frame.columns[i][1]:SetPoint("TopLeft", parent, "TopLeft", 1, -2)
				end

				self.frame.columns[i][6] = self.frame.columns[i][1]:GetWidth() / self.frame:GetWidth()
				--self.frame.columns[i][1]:SetParent(self.frame.headerscrolling)
			end
		end)

		frame.resize:SetScript("OnEnter", function(resize, button)
			frame.right:SetAlpha(1)
			self.frame.columns[frame:GetID() + 1][1].left:SetAlpha(1)
		end)
		frame.resize:SetScript("OnLeave", function(resize, button)
			frame.right:SetAlpha(0.4)
			self.frame.columns[frame:GetID() + 1][1].left:SetAlpha(0.5)
		end)

		frame:SetScript("OnSizeChanged", function(self, button)
			if self.noSizing then
				return
			end

			self:SetWidth(round(self:GetWidth()))

			-- This should be recursive
			--for i = #Table.frame.columns, self:GetID() + 1, -1 do
				local i = 6
				if Table.frame.columns[i][1]:GetWidth() < (Table.frame:GetWidth() * Table.frame.columns[i][3] / 1.4) then
					local diff = Table.frame:GetWidth() * Table.frame.columns[i][3] / 1.4 - Table.frame.columns[i][1]:GetWidth()

					if (Table.frame.columns[i - 1][1]:GetWidth() - diff) > (Table.frame:GetWidth() * Table.frame.columns[i - 1][3] / 1.4) then
						Table.frame.columns[i - 1][1].noSizing = true
						Table.frame.columns[i - 1][1]:SetWidth(round(Table.frame.columns[i - 1][1]:GetWidth() - diff))
						Table.frame.columns[i - 1][1].noSizing = nil
					else
						if (Table.frame.columns[i - 2][1]:GetWidth() - diff) > (Table.frame:GetWidth() * Table.frame.columns[i - 2][3] / 1.4) then
							Table.frame.columns[i - 2][1].noSizing = true
							Table.frame.columns[i - 2][1]:SetWidth(round(Table.frame.columns[i - 2][1]:GetWidth() - diff))
							Table.frame.columns[i - 2][1].noSizing = nil
						else
							if (Table.frame.columns[i - 3][1]:GetWidth() - diff) > (Table.frame:GetWidth() * Table.frame.columns[i - 3][3] / 1.4) then
								Table.frame.columns[i - 3][1].noSizing = true
								Table.frame.columns[i - 3][1]:SetWidth(round(Table.frame.columns[i - 3][1]:GetWidth() - diff))
								Table.frame.columns[i - 3][1].noSizing = nil
							else
								if (Table.frame.columns[i - 4][1]:GetWidth() - diff) > (Table.frame:GetWidth() * Table.frame.columns[i - 4][3] / 1.4) then
									Table.frame.columns[i - 4][1].noSizing = true
									Table.frame.columns[i - 4][1]:SetWidth(round(Table.frame.columns[i - 4][1]:GetWidth() - diff))
									Table.frame.columns[i - 4][1].noSizing = nil
								else
									if (Table.frame.columns[i - 5][1]:GetWidth() - diff) > (Table.frame:GetWidth() * Table.frame.columns[i - 5][3] / 1.4) then
										Table.frame.columns[i - 5][1].noSizing = true
										Table.frame.columns[i - 5][1]:SetWidth(round(Table.frame.columns[i - 5][1]:GetWidth() - diff))
										Table.frame.columns[i - 5][1].noSizing = nil
									end
								end
							end
						end
					end
				end
			--end
		end)
	end

	--if self.frame.lastcolumn then
		frame.left = frame:CreateTexture(nil, "Background")
		frame.left:SetTexture([[Interface\FriendsFrame\WhoFrame-ColumnTabs]])
		frame.left:SetTexCoord(0, 0.078125, 0, 0.59375)
		frame.left:SetVertexColor(0.65, 0.65, 0.65, 1)
		frame.left:SetPoint("TopLeft")
		frame.left:SetSize(5, 19)
		frame.left:SetAlpha(0.4)
	--end

	--if not frame.last then
		frame.right = frame:CreateTexture(nil, "Background")
		frame.right:SetTexture([[Interface\FriendsFrame\WhoFrame-ColumnTabs]])
		frame.right:SetTexCoord(0.90625, 0.96875, 0, 0.59375)
		frame.right:SetVertexColor(0.65, 0.65, 0.65, 1)
		frame.right:SetPoint("TopRight")
		frame.right:SetSize(4, 19)
		frame.right:SetAlpha(0.4)
	--end

	frame.middle = frame:CreateTexture(nil, "Background")
	frame.middle:SetTexture([[Interface\FriendsFrame\WhoFrame-ColumnTabs]])
	frame.middle:SetTexCoord(0.078125, 0.90625, 0, 0.59375)
	frame.middle:SetVertexColor(0.65, 0.65, 0.65, 1)
	frame.middle:SetPoint("Left", frame.left, "Right")
	frame.middle:SetPoint("Right", frame.right, "Left")
	frame.middle:SetSize(10, 19)

	frame.arrow = frame:CreateTexture(nil, "Overlay")
	frame.arrow:SetTexture([[Interface\Minimap\MiniMap-PositionArrows]])
	frame.arrow:SetTexCoord(0, 1, 0, 0.5)
	frame.arrow:SetSize(16, 16)
	frame.arrow:SetPoint("TopRight", -6, -3)
	frame.arrow:Hide()

	frame:SetScript("OnClick", function(self, button)
		local old, dir = Table:GetSortedColumn()
		Table:SetSortedColumn(self:GetID(), (old == self:GetID() and not dir))

		for i = 1, #Table.frame.columns do
			local frame = Table.frame.columns[i][1]
			if frame:GetID() ~= Table.frame.sortedheader then
				frame.arrow:Hide()
				Table.frame.columns[i][1].text:SetFontObject(GameFontHighlightSmall)
			else
				frame.arrow:Show()
				frame.text:SetFontObject(GameFontNormalSmall)
				if Table.frame.descending then
					frame.arrow:SetTexCoord(0, 1, 0.5, 1)
				else
					frame.arrow:SetTexCoord(0, 1, 0, 0.5)
				end
			end
		end

		PlaySound(1115)
	end)

	frame:SetScript("OnMouseUp", function(frame, button)
		if button == "RightButton" then
			frame:SetWidth(self.frame.columns[frame:GetID()][3] * self.frame:GetWidth())

			self.frame.columns[frame:GetID()][6] = self.frame.columns[frame:GetID()][3]

			PlaySound(1115)
		end
	end)

	self.frame.lastcolumn = frame

	return frame
end

function Table:AddRow(...)
	assert(select("#", ...) == #self.frame.columns, "Number of arguments does not match number of columns.")

	if not self.frame.rowframes then
		self.frame.rowframes = { }

		self:CreateRow(self.frame.scrolling, ...)
	end

	--tinsert(self.frame.rows, {#self.frame.rows + 1, ...})

	--self.frame.rows[#self.frame.rows + 1] = { }
	self.frame.sorted[#self.frame.sorted + 1] = { }
	for i = 1, (select("#", ...)) do
		local text = (select(i, ...))
		--self.frame.rows[#self.frame.rows][i] = { }
		--self.frame.rows[#self.frame.rows][i].text = text
		self.frame.sorted[#self.frame.sorted][i] = { }
		self.frame.sorted[#self.frame.sorted][i].text = text
	end

	--self:ApplyFilter()

	--[[self.frame.filtered[#self.frame.filtered + 1] = { }
	for i = 1, (select("#", ...)) do
		local text = (select(i, ...))
		if i == 1 and strfind(text, self.frame.filter) then
			--self.frame.rows[#self.frame.rows][i] = { }
			--self.frame.rows[#self.frame.rows][i].text = text
			self.frame.filtered[#self.frame.filtered][i] = { }
			self.frame.filtered[#self.frame.filtered][i].text = text
		else
			break
		end
	end]]

	--[=[self.frame.scrolling:SetSize(800, #self.frame.filtered * 22)

	if (#self.frame.filtered * 22) > (self.frame:GetHeight() - 22) then
		if (#self.frame.filtered - 19) < 0 then
			self.frame.scrollbar:SetMinMaxValues(0, ((#self.frame.filtered) * 22)--[[ + (22 * 3)]])
		else
			self.frame.scrollbar:SetMinMaxValues(0, ((#self.frame.filtered - 19) * 22)--[[ + (22 * 3)]])
		end

		--self.frame.scrollbar:SetMinMaxValues(0, ((#self.frame.filtered - 19) * 22)--[[ + (22 * 3)]])
		self.frame.scrollbar.ScrollDownButton:Enable()
		self.frame.scrollbar:Show()
	else
		self.frame.scrollbar:SetMinMaxValues(0, 0)
		self.frame.scrollbar.ScrollDownButton:Disable()
		self.frame.scrollbar:Hide()
	end]=]

	--[[for i = 1, #self.frame.rows do
		for j = 1, #self.frame.rows[i] do
			if i % 2 == 0 then
				self.frame.rows[i][j].bg:SetColorTexture(0.5, 0.5, 0.5)
			else
				self.frame.rows[i][j].bg:SetColorTexture(0.9, 0.9, 1)
			end
		end
	end]]

	return #self.frame.sorted
end

-- Update everything
function Table:Update()
	self:ApplyFilter()

	self:SortColumn()

	--self:UpdateItems()

	self:UpdateScrollBar()
end

function Table:UpdateScrollBar()
	local items
	if self.frame.filter and self.frame.filter ~= "" then
		items = self.frame.filtered
	else
		items = self.frame.sorted
	end

	self.frame.scrolling:SetSize(800, #items * 22)

	if (#items * 22) > (self.frame:GetHeight() - 22) then
		if (#items - 19) < 0 then
			self.frame.scrollbar:SetMinMaxValues(0, ((#items) * 22)--[[ + (22 * 3)]])
		else
			self.frame.scrollbar:SetMinMaxValues(0, ((#items - 19) * 22)--[[ + (22 * 3)]])
		end

		--self.frame.scrollbar:SetMinMaxValues(0, ((#items - 19) * 22)--[[ + (22 * 3)]])
		self.frame.scrollbar.ScrollDownButton:Enable()
		self.frame.scrollbar:Show()
	else
		self.frame.scrollbar:SetMinMaxValues(0, 0)
		self.frame.scrollbar.ScrollDownButton:Disable()
		self.frame.scrollbar:Hide()
	end
end

function Table:SetFilter(filter)
	self.frame.filter = filter

	self:Update()
end

function Table:ApplyFilter()
	if not self.frame.filter or self.frame.filter == "" then
		return
	end

	self.frame.filtered = { }

	for i = 1, #self.frame.sorted do
		if strfind(self.frame.sorted[i][1].text, self.frame.filter) then
			self.frame.filtered[#self.frame.filtered + 1] = { }
			for j = 1, #self.frame.sorted[i] do
				self.frame.filtered[#self.frame.filtered][j] = self.frame.sorted[i][j]
			end
		end
	end

	return #self.frame.filtered
end

function Table:UpdateRow(...)
	local name = ...

	-- Only update visible rows
	--[[local startline = (self.frame.scrollbar:GetValue() / 22) + 1
	local endline = startline + 18

	if endline > #self.frame.rows then
		endline = #self.frame.rows
	end]]

	--[=[for j = 1, #self.frame.rows[self.frame.rowstext[name]] do
		local text = (select(j, ...))
		if self.frame.rows[self.frame.rowstext[name]][j].text ~= text then
			self.frame.rows[self.frame.rowstext[name]][j].text = text
		end
	end]=]

	local items
	if self.frame.filter and self.frame.filter ~= "" then
		items = self.frame.filtered
	else
		items = self.frame.sorted
	end

	for i = 1, #items do
		if items[i][1].text == name then
			for j = 2, #items[i] do
				local text = (select(j, ...))
				if items[i][j].text ~= text then
					items[i][j].text = text
				end
			end
			break
		end
	end
end

function Table:CreateRow(parent, ...)
	local rows = (select("#", ...))
	for i = 1, 32 do
		self.frame.rowframes[i] = { }
		for j = 1, rows do
			self.frame.rowframes[i][j] = CreateFrame("Frame", nil, parent)
			self.frame.rowframes[i][j]:SetHeight(22)
			--self.frame.rowframes[i][j]:SetSize(self.frame.columns[j][1]:GetWidth() - 1, 22)

			if self.frame.newrow then
				self.frame.rowframes[i][j]:SetPoint("TopLeft", self.frame.rowframes[i - 1][j], "BottomLeft", 0, 0)
				self.frame.rowframes[i][j]:SetPoint("TopRight", self.frame.rowframes[i - 1][j], "BottomRight", 0, 0)
				self.frame.newrow = nil
			elseif self.frame.lastrow then
				if i == 1 then
					self.frame.rowframes[i][j]:SetPoint("TopLeft", self.frame.lastrow, "TopRight", -1, 0)
					if j == rows then
						self.frame.rowframes[i][j]:SetPoint("TopRight", self.frame.columns[j][1], "BottomRight", -1, 0)
					else
						self.frame.rowframes[i][j]:SetPoint("TopRight", self.frame.columns[j][1], "BottomRight", 0, 0)
					end
				else
					self.frame.rowframes[i][j]:SetPoint("TopLeft", self.frame.rowframes[i - 1][j], "BottomLeft", 0, 0)
					self.frame.rowframes[i][j]:SetPoint("TopRight", self.frame.rowframes[i - 1][j], "BottomRight", 0, 0)
				end
			else
				self.frame.rowframes[i][j]:SetPoint("TopLeft", self.frame.columns[j][1], "BottomLeft", 2, 5)
				self.frame.rowframes[i][j]:SetPoint("TopRight", self.frame.columns[j][1], "BottomRight", 0, 0)
			end

			self.frame.lastrow = self.frame.rowframes[i][j]

			if j == rows then
				self.frame.newrow = true
			end

			self.frame.rowframes[i][j].text = self.frame.rowframes[i][j]:CreateFontString(nil, "Overlay")
			self.frame.rowframes[i][j].text:SetPoint("TopLeft", self.frame.rowframes[i][j], "TopLeft", 4.5, -4.5)
			self.frame.rowframes[i][j].text:SetPoint("BottomRight", self.frame.rowframes[i][j], "BottomRight", -4, 4)
			self.frame.rowframes[i][j].text:SetFontObject(GameFontHighlightSmall)
			self.frame.rowframes[i][j].text:SetJustifyH("Left")
			self.frame.rowframes[i][j].text:SetHeight(24)
			self.frame.rowframes[i][j].text:SetWordWrap(false)

			--self.frame.rowframes[i][j].text:SetText(self.frame.rowframes[i][j].text) --?????

			self.frame.rowframes[i][j].bg = self.frame.rowframes[i][j]:CreateTexture(nil, "Background")
			self.frame.rowframes[i][j].bg:SetAllPoints(self.frame.rowframes[i][j])
			if i % 2 == 0 then
				self.frame.rowframes[i][j].bg:SetColorTexture(0.4, 0.4, 0.4)
			else
				self.frame.rowframes[i][j].bg:SetColorTexture(0.9, 0.9, 1)
			end
			self.frame.rowframes[i][j].bg:SetAlpha(0.1)

			self.frame.rowframes[i][j]:SetScript("OnEnter", function(self)
				self.bg:SetAlpha(0.3)
			end)
			self.frame.rowframes[i][j]:SetScript("OnLeave", function(self)
				self.bg:SetAlpha(0.1)
			end)
		end
	end
end

function Table:UpdateItems()
	--[[self.frame.scrolling:SetSize(800, #self.frame.rows * 22)

	if (#self.frame.rows * 22) > (self.frame:GetHeight() - 22) then
		self.frame.scrollbar:SetMinMaxValues(0, ((#self.frame.rows - 19) * 22) + (22 * 3))
		self.frame.scrollbar.ScrollDownButton:Enable()
		self.frame.scrollbar:Show()
	else
		self.frame.scrollbar:SetMinMaxValues(0, 0)
		self.frame.scrollbar.ScrollDownButton:Disable()
		self.frame.scrollbar:Hide()
	end]]

	--[[local x = 0
	if self.frame.scrollbar:IsShown() then
		x = 12

		for i = 1, #self.frame.columns do
			self.frame.columns[i][1]:SetSize(((self.frame:GetWidth() - x) * self.frame.columns[i][3]), 24)
			--self.frame.columns[i][1]:SetID(i)
		end
	else
		for i = 1, #self.frame.columns do
			if i == #self.frame.columns then
				self.frame.columns[i][1]:SetSize(round(((self.frame:GetWidth() - x) * self.frame.columns[i][3])) + 2, 24)
			else
				self.frame.columns[i][1]:SetSize(round(((self.frame:GetWidth() - x) * self.frame.columns[i][3])) + 1, 24)
			end
			--self.frame.columns[i][1]:SetID(i)
		end
	end]]

	--[[for i = 1, #self.frame.columns do
		if i ~= 1 then
			if self.frame.columns[i][1].last then
				self.frame.columns[i][1]:SetPoint("TopLeft", self.frame.columns[i - 1][1], "TopRight", -2, 0)
				self.frame.columns[i][1]:SetPoint("TopRight", self.frame, "TopRight", -2, 0)
			else
				self.frame.columns[i][1]:SetPoint("TopLeft", self.frame.columns[i - 1][1], "TopRight", -2, 0)
			end
		else
			self.frame.columns[i][1]:SetPoint("TopLeft", self.frame, "TopLeft", 1, -2)
		end
	end]]

	if not self.frame.rowframes then
		return
	end

	local items
	if self.frame.filter and self.frame.filter ~= "" then
		items = self.frame.filtered
	else
		items = self.frame.sorted
	end

	local k
	if #self.frame.rowframes > #items then
		k = #items

		if k < 32 then
			k = 32
		end
	else
		k = #self.frame.rowframes
	end

	local offset = (self.frame.scrollbar:GetValue() / self.frame.scrollbar:GetValueStep())

	for i = 1, k do
		for j = 1, #self.frame.rowframes[i] do
			local format = self.frame.columns[j][4]
			local frame = self.frame.rowframes[i][j]

			if type(format) == "string" then
				if items[i + offset] then
					frame:Show()
					frame.text:SetText(format:format(items[i + offset][j].text))
				else
					frame:Hide()
					frame.text:SetText("")
				end
			else
				if items[i + offset] then
					frame:Show()
					frame.text:SetText(tostring(items[i + offset][j].text))
				else
					frame:Hide()
					frame.text:SetText("")
				end
			end
		end
	end
end
