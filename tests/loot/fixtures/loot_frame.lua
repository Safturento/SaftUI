--[[
	Blizzard's loot window (LootFrame: Blizzard_UIPanels_Game's LootFrame.xml and
	LootFrame.lua, ScrollingFlatPanel.xml and the DefaultPanelFlatTemplate of
	Blizzard_SharedXML), as far as SaftUI's skin (SaftUI-Loot/popup.lua) reads it.
	Load it with `local LF = load_test_file('loot/fixtures/loot_frame.lua')`, then
	LF.build{ client = 'forever' | 'retail' } makes what the game makes when the
	addon loads. Checked 2026-11-15 against the `forever` and `live` branches of
	Gethe/wow-ui-source: both clients have this one scroll box window (there is no
	LootButton1 to LootButton4 window on either), and differ only in the gamepad
	pieces:
	  - LootFrame, a hidden HIGH strata frame, 220 by 290, clamped, with
	    .NineSlice, .Bg, .TitleContainer.TitleText ("Items"), .ClosePanelButton
	    (a Button with four state textures), .ScrollBox (a Frame with
	    .ScrollTarget, and the Update method Blizzard's scroll box calls after
	    it hands out a row) and .ScrollBar. Forever's also has .FrameGlow and the
	    three jump hints (DefaultPanelBaseTemplate's FocusFramesInterfaceMixin
	    pieces); retail's has none.
	  - A row, in the scroll target and pooled: LootFrameItemElementTemplate (an
	    item or a currency) or LootFrameMoneyElementTemplate, 202 by 46, with
	    .Item (an ItemButton: .icon under a round .Mask, .Count, .IconBorder,
	    its normal, pushed and highlight textures, the OnEnter, OnLeave,
	    OnMouseDown, OnMouseUp, OnUpdate and OnClick scripts Blizzard sets),
	    .NameFrame, .BorderFrame, .IconQuestTexture, .HighlightNameFrame (alpha
	    0.7, hidden), .PushedNameFrame (hidden), .Text, and on item rows
	    .QualityStripe and .QualityText. The methods are fields of the row, as a
	    mixin's are: Init (sets the text, its color, the card's color, the icon,
	    the count and the item button's quality border, as
	    LootFrameElementMixin:Init does), GetQuality, GetSlotIndex.
	  - LF.open(slots) is LOOT_OPENED: each slot { kind = 'item' | 'money',
	    quality, name, count } gets a row from the pool (a new one when it has
	    none), Blizzard's Init runs on it, and the scroll box's Update runs, as it
	    does once the rows are acquired. LF.change(index, slot) is
	    LOOT_SLOT_CHANGED (Init again on that row), LF.close() puts every row back
	    in the pool and hides the window.
	Every frame and region is locked once built (lib/locked_widget.lua), so a
	skin that writes a field onto one, or SetScripts one, fails; the fixture's own
	writes use rawset. LF.calls lists, by name, every changing method (Set...,
	Hide, Show, Clear..., Enable, Disable, Create..., Add..., Remove..., Hook...)
	SaftUI's code calls on a Blizzard widget, outside the fixture's own drivers.
	LF.rows is the rows made, LF.elements() the ones in use.
	LF.build{ protected = true } makes LootFrame report IsProtected, as it would
	be if some other addon anchored a secure frame to it. LF.build{ omit = {...} }
	leaves out named parts, as a client that lacked one.
]]

local lock_widget = load_test_file('lib/locked_widget.lua')
local OWNER = 'Blizzard loot frame'

local LF = {}

-- The named fonts the templates use; the stubs have only some.
for _, name in ipairs({ 'GameFontNormal', 'GameFontWhiteTiny2', 'NumberFontNormal' }) do
	if not _G[name] then
		local font = CreateFont(name)
		font:SetFont([[Fonts\FRIZQT__.TTF]], 12, '')
	end
end

-- ITEM_QUALITY_COLORS as the game has them (Blizzard's default colors).
local QUALITY = {
	[0] = { 0.62, 0.62, 0.62 }, { 1, 1, 1 }, { 0.12, 1, 0 }, { 0, 0.44, 0.87 }, { 0.64, 0.21, 0.93 }, { 1, 0.5, 0 },
}

local driving = 0
local omitted = {}

local function drive(fn, ...)
	driving = driving + 1
	local ok, err = pcall(fn, ...)
	driving = driving - 1
	if not ok then error(err, 0) end
end

-- The fields a Blizzard table has now, as a sorted 'key,key' text.
function LF.keys(widget)
	local out = {}
	for key in pairs(widget) do out[#out + 1] = tostring(key) end
	table.sort(out)
	return table.concat(out, ',')
end

local function wanted(path) return not omitted[path] end

local function texture(parent, key, layer, path)
	if not wanted(path) then return end
	local t = parent:CreateTexture(nil, layer)
	rawset(parent, key, t)
	return t
end

local function fontstring(parent, key, layer, font, path)
	if not wanted(path) then return end
	local fs = parent:CreateFontString(nil, layer)
	fs:SetFontObject(font)
	rawset(parent, key, fs)
	return fs
end

local PREFIXES = { 'Set', 'Hide', 'Show', 'Clear', 'Enable', 'Disable', 'Create', 'Add', 'Remove', 'Hook', 'Register', 'Unregister' }
local function changes(name)
	for _, prefix in ipairs(PREFIXES) do
		if name:sub(1, #prefix) == prefix then return true end
	end
end

-- Locks a widget and counts the changing calls SaftUI's code makes on it.
local function guard(widget)
	lock_widget(widget, OWNER)
	LF.widgets[#LF.widgets + 1] = widget
	LF.set[widget] = true
	LF.keys0[widget] = LF.keys(widget)
	local meta = getmetatable(widget)
	local base = meta.__index
	meta.__index = function(t, key)
		local value = base[key]
		if type(value) == 'function' and type(key) == 'string' and changes(key) then
			return function(...)
				if driving == 0 then LF.calls[#LF.calls + 1] = key end
				return value(...)
			end
		end
		return value
	end
end

local function guard_tree(frame)
	for _, region in ipairs({ frame:GetRegions() }) do guard(region) end
	for _, kid in ipairs({ frame:GetChildren() }) do guard_tree(kid) end
	guard(frame)
end

------------------------------------------------------------------ a row

local function quality_of(row) return row.data.quality or 1 end

-- LootFrameElementMixin:Init (and LootFrameItemElementMixin:Init): what Blizzard
-- sets on a row for its slot.
local function init(row)
	local data = row.data
	row.Text:SetText(data.name or 'Item')
	local color = QUALITY[quality_of(row)] or QUALITY[1]
	row.Text:SetVertexColor(unpack(color))
	if row.NameFrame then row.NameFrame:SetVertexColor(unpack(color)) end
	if row.IconQuestTexture then row.IconQuestTexture:Hide() end
	row.Item.icon:SetTexture(data.icon or 134400)
	local count = row.Item.Count
	if count then
		if (data.count or 1) > 1 then
			count:SetText(data.count)
			count:Show()
		else
			count:Hide()
		end
	end
	local border = row.Item.IconBorder
	if border then
		if data.kind == 'item' then
			border:SetTexture([[Interface\Common\WhiteIconFrame]])
			border:SetVertexColor(unpack(color))
			border:Show()
		else
			border:Hide()
		end
	end
	if data.kind == 'item' then row.QualityText:SetText('Quality ' .. quality_of(row)) end
	row.Item:Enable()
end

local function make_row(kind)
	local row = CreateFrame('Frame', nil, LF.scroll_target)
	row:SetSize(202, 46)
	local item = CreateFrame('Button', nil, row)
	item:SetSize(37, 37)
	item:SetPoint('TOPLEFT', row, 'TOPLEFT', 5, -4)
	item:SetFrameLevel(row:GetFrameLevel()) -- useParentLevel
	rawset(row, 'Item', item)

	-- ItemButton (Blizzard_ItemButton's Shared/ItemButtonTemplate.xml).
	local icon = texture(item, 'icon', 'BORDER', 'Item.icon')
	local mask = item:CreateMaskTexture()
	mask:SetAllPoints(item)
	rawset(item, 'Mask', mask)
	if icon then
		icon:SetSize(37, 37)
		icon:SetPoint('CENTER')
		icon:AddMaskTexture(mask)
	end
	local count = fontstring(item, 'Count', 'ARTWORK', NumberFontNormal, 'Item.Count')
	if count then count:Hide() end
	local border = texture(item, 'IconBorder', 'OVERLAY', 'Item.IconBorder')
	if border then
		border:SetSize(37, 37)
		border:SetPoint('CENTER')
		border:Hide()
	end
	item:SetNormalTexture([[Interface\Buttons\UI-Quickslot2]])
	item:SetPushedTexture([[Interface\Buttons\UI-Quickslot-Depress]])
	item:SetHighlightTexture([[Interface\Buttons\ButtonHilight-Square]])
	rawset(item, 'NormalTexture', item:GetNormalTexture())
	rawset(item, 'PushedTexture', item:GetPushedTexture())
	rawset(item, 'HighlightTexture', item:GetHighlightTexture())
	item:GetNormalTexture():AddMaskTexture(mask)
	item:GetPushedTexture():AddMaskTexture(mask)

	-- LootFrameElementTemplate's regions.
	local name = texture(row, 'NameFrame', 'BACKGROUND', 'NameFrame')
	if name then name:SetAllPoints(row) end
	local stroke = texture(row, 'BorderFrame', 'BORDER', 'BorderFrame')
	if stroke then stroke:SetAllPoints(row) end
	local quest = texture(row, 'IconQuestTexture', 'OVERLAY', 'IconQuestTexture')
	if quest then
		quest:SetSize(37, 38)
		quest:SetPoint('TOP', item, 'TOP')
	end
	local highlight = texture(row, 'HighlightNameFrame', 'OVERLAY', 'HighlightNameFrame')
	if highlight then
		highlight:SetAllPoints(row)
		highlight:SetAlpha(0.7)
		highlight:Hide()
	end
	local pushed = texture(row, 'PushedNameFrame', 'OVERLAY', 'PushedNameFrame')
	if pushed then
		pushed:SetAllPoints(row)
		pushed:Hide()
	end
	if kind == 'item' then
		local stripe = texture(row, 'QualityStripe', 'BACKGROUND', 'QualityStripe')
		if stripe then
			stripe:SetSize(100, 13)
			stripe:SetPoint('TOPRIGHT')
		end
		fontstring(row, 'QualityText', 'ARTWORK', GameFontWhiteTiny2, 'QualityText'):SetPoint('TOPRIGHT', -4, -2)
	end
	local text = fontstring(row, 'Text', 'ARTWORK', GameFontNormal, 'Text')
	text:SetSize(150, 30)
	text:SetPoint('TOPLEFT', item, 'TOPRIGHT', 8, -8)

	-- The scripts Blizzard's OnLoad sets on the item button.
	item:SetScript('OnEnter', function() if row.HighlightNameFrame then row.HighlightNameFrame:Show() end end)
	item:SetScript('OnLeave', function() if row.HighlightNameFrame then row.HighlightNameFrame:Hide() end end)
	item:SetScript('OnMouseDown', function() if row.PushedNameFrame then row.PushedNameFrame:Show() end end)
	item:SetScript('OnMouseUp', function() if row.PushedNameFrame then row.PushedNameFrame:Hide() end end)
	item:SetScript('OnUpdate', function() end)
	item:SetScript('OnClick', function() LF.clicked = (LF.clicked or 0) + 1 end)

	-- The mixin's methods, fields of the row. Init is what the scroll box's
	-- initializer calls, and what LOOT_SLOT_CHANGED calls again.
	-- A call of Init from outside the fixture's drivers is SaftUI's (LF.stray):
	-- rule 3, no Blizzard function that writes runs from SaftUI's code.
	rawset(row, 'Init', function(self)
		if driving == 0 then LF.stray[#LF.stray + 1] = 'Init' end
		drive(init, self)
	end)
	rawset(row, 'GetQuality', function(self) return quality_of(self) end)
	rawset(row, 'GetSlotIndex', function(self) return self.data.index end)
	rawset(row, 'kind', kind)
	rawset(row, 'data', {})

	guard_tree(row)
	LF.rows[#LF.rows + 1] = row
	return row
end

------------------------------------------------------------------ the window

function LF.build(opts)
	opts = opts or {}
	omitted = {}
	for _, path in ipairs(opts.omit or {}) do omitted[path] = true end
	LF.client = opts.client or 'forever'
	LF.calls, LF.stray, LF.widgets, LF.rows, LF.pool, LF.active = {}, {}, {}, {}, { item = {}, money = {} }, {}
	-- Every Blizzard widget made, as a set, and its key list as built.
	LF.set, LF.keys0 = {}, {}
	LF.updates = 0

	local frame = CreateFrame('Frame', 'LootFrame', UIParent)
	frame:SetSize(220, 290)
	frame:SetFrameStrata('HIGH')
	frame:EnableMouse(true)
	frame:SetClampedToScreen(true)
	frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', 300.5, 400.5) -- at the cursor
	frame:Hide()
	if opts.protected then rawset(frame, 'IsProtected', function() return true, true end) end

	local title = CreateFrame('Frame', nil, frame)
	title:SetSize(100, 20)
	rawset(frame, 'TitleContainer', title)
	local text = title:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject(GameFontNormal)
	text:SetText('Items')
	rawset(title, 'TitleText', text)

	if wanted('NineSlice') then
		local nine = CreateFrame('Frame', nil, frame)
		nine:SetAllPoints(frame)
		for _, piece in ipairs({ 'TopLeftCorner', 'TopEdge', 'LeftEdge' }) do
			rawset(nine, piece, nine:CreateTexture(nil, 'BORDER'))
		end
		rawset(frame, 'NineSlice', nine)
	end
	if wanted('Bg') then
		local bg = CreateFrame('Frame', nil, frame)
		bg:SetPoint('TOPLEFT', frame, 'TOPLEFT', 6, -20)
		bg:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', -2, 2)
		bg:SetFrameLevel(0)
		rawset(frame, 'Bg', bg)
	end
	if wanted('ClosePanelButton') then
		local close = CreateFrame('Button', nil, frame)
		close:SetSize(24, 24)
		close:SetPoint('TOPRIGHT', 1, 0)
		close:SetNormalTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Up]])
		close:SetPushedTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Down]])
		close:SetDisabledTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Disabled]])
		close:SetHighlightTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]])
		close:SetScript('OnClick', function() frame:Hide() end)
		rawset(frame, 'ClosePanelButton', close)
	end
	if opts.client == 'forever' then
		for _, key in ipairs({ 'FrameGlow', 'LeftJumpHint', 'RightJumpHint', 'FocusJumpHint' }) do
			local piece = CreateFrame('Frame', nil, frame)
			piece:Hide()
			rawset(frame, key, piece)
		end
	end

	local box = CreateFrame('Frame', nil, frame)
	box:SetPoint('TOPLEFT', frame, 'TOPLEFT', 4, -22)
	box:SetPoint('BOTTOM', frame, 'BOTTOM', 0, 4)
	box:SetWidth(214)
	local target = CreateFrame('Frame', nil, box)
	target:SetAllPoints(box)
	rawset(box, 'ScrollTarget', target)
	rawset(box, 'Update', function() LF.updates = LF.updates + 1 end)
	rawset(frame, 'ScrollBox', box)
	LF.scroll_target, LF.scroll_box = target, box
	local bar = CreateFrame('Frame', nil, frame)
	rawset(frame, 'ScrollBar', bar)

	-- The frame's OnShow is Blizzard's (it registers the slot events).
	frame:SetScript('OnShow', function() LF.shown = (LF.shown or 0) + 1 end)

	guard_tree(frame)
	LF.frame = frame
	return frame
end

-- LOOT_OPENED: a row for each slot, Blizzard's Init on it, the window shown and
-- the scroll box updated.
function LF.open(slots)
	LF.close()
	drive(function()
		LF.frame:Show()
		for index, slot in ipairs(slots) do
			slot.index = index
			slot.kind = slot.kind or 'item'
			local row = table.remove(LF.pool[slot.kind]) or make_row(slot.kind)
			row.data = slot
			row:Init()
			row:Show()
			LF.active[#LF.active + 1] = row
		end
		LF.scroll_box:Update()
	end)
end

-- LOOT_SLOT_CHANGED for the slot at index.
function LF.change(index, slot)
	local row = LF.active[index]
	slot.index, slot.kind = index, row.kind
	row.data = slot
	drive(function() row:Init() end)
end

function LF.close()
	drive(function()
		for _, row in ipairs(LF.active) do
			row:Hide()
			table.insert(LF.pool[row.kind], row)
		end
		LF.active = {}
		if LF.frame and LF.frame:IsShown() then LF.frame:Hide() end
	end)
end

-- Runs one of the rows' scripts as the game does for the mouse: the script and
-- then the hooks on it.
function LF.fire(widget, script, ...)
	local args = { ... }
	drive(function() stub.fire_script(widget, script, unpack(args)) end)
end

-- A click on a row's item button, as the player makes it.
function LF.click(button)
	drive(function() stub.click(button) end)
end

function LF.elements() return LF.active end

-- The window shown, as Blizzard's own Show would.
function LF.show()
	drive(function() LF.frame:Show() end)
end

return LF
