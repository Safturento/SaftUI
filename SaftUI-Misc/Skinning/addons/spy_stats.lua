local st = SaftUI
local SP = st:GetModule('Skinning'):GetModule('Spy')
local L = SP.lib

-- The Spy skin's Statistics window (SpyStatsFrame, SpyStats.xml). Shares spy.lua's pieces
-- through SP.lib. Nothing is written onto a Spy frame: SaftUI's boxes are children of
-- Spy's buttons and are kept in the tables of spy.lua and below.
--
-- What is left in Spy's look, because the helper that would draw it writes fields onto the
-- widget (.agents/taint.md, rule 1 and its third-party note): the four check boxes
-- (st:SkinCheckButton sets .text, .SetText, .SetTextFont) and the list's scroll bar
-- (st:SkinScrollBar sets .Thumb). Their labels do wear the Skinning font. The tab button
-- is hidden by Spy until it has a second tab; the drop-down is Blizzard's.
local boxed = setmetatable({}, L.weak)   -- Spy's UIPanelButtonTemplate button -> its hover hooks are on
local skinned = setmetatable({}, L.weak) -- Spy's frame -> true once drawn

local BUTTON_ART = { 'Left', 'Middle', 'Right', 'LeftDisabled', 'MiddleDisabled', 'RightDisabled' }
local SORT_COLUMNS = { 'Name', 'Level', 'Rank', 'Class', 'Guild', 'Wins', 'Loses', 'Reason' }
local SORT_OTHERS = { 'List', 'Time', 'Zone' }
local LINE_TEXTS = { 'Name', 'Level', 'Rank', 'Class', 'Guild', 'Wins', 'Loses', 'Reason', 'Zone', 'List', 'Time' }
local CHECKS = { 'Kos', 'Realm', 'WinsLoses', 'Reason' }
local HEADER_LINE_Y = -19 -- the line under the title, down from the window's top; the sort headers are below it

local function Fade(region)
	if type(region) == 'table' and region.SetAlpha then region:SetAlpha(0) end
end

-- A button's own textures (normal, pushed, disabled, highlight) at alpha 0.
local function FadeButtonTextures(button)
	for _, getter in ipairs({ 'GetNormalTexture', 'GetPushedTexture', 'GetDisabledTexture', 'GetHighlightTexture' }) do
		if button[getter] then Fade(button[getter](button)) end
	end
end

local function Global(name)
	local value = _G[name]
	return type(value) == 'table' and value or nil
end

-- A UIPanelButtonTemplate button: Blizzard's three parts and its highlight at alpha 0, a SaftUI
-- box (a 'control') inside it with the hover and the press drawn by the states, the label in
-- the Skinning font. The box is the button's backdrop, so a Theme change redraws it.
local function SkinPanelButton(button)
	if type(button) ~= 'table' or boxed[button] or not button.HookScript then return end
	local box = L.Panel(button, 'control')
	if not box then return end
	boxed[button] = true
	for _, key in ipairs(BUTTON_ART) do Fade(button[key]) end
	FadeButtonTextures(button)
	st:AddStates(box, 'box', { edge = 'theme', wire = false })
	-- Post-hooks that only color SaftUI's own box. The game passes a second argument
	-- (motion) to OnEnter and OnLeave, which they don't use.
	button:HookScript('OnEnter', function() st:SetState(box, 'hover', true) end)
	button:HookScript('OnLeave', function() st:SetState(box, 'hover', false) end)
	button:HookScript('OnMouseDown', function(_, mouse)
		if mouse == nil or mouse == 'LeftButton' then st:SetState(box, 'pushed', true) end
	end)
	button:HookScript('OnMouseUp', function() st:SetState(box, 'pushed', false) end)
	L.HookFont(button.GetFontString and button:GetFontString(), 'text')
end

-- A sort header: no art of its own, its label in the Skinning font.
local function SkinSortHeader(button)
	if type(button) ~= 'table' then return end
	FadeButtonTextures(button)
	L.HookFont(button.GetFontString and button:GetFontString(), 'text')
end

-- A line of the list: Spy's highlight bar replaced by SaftUI's flat one, which the states
-- draw under the mouse; its texts in the Skinning font.
local function SkinLine(line)
	if type(line) ~= 'table' or not line.SetHighlightTexture then return end
	line:SetHighlightTexture(st.BLANK_TEX, 'BLEND')
	st:AddStates(line, 'icon', { pieces = { hover = line:GetHighlightTexture() } })
	local name = line.GetName and line:GetName()
	if name then
		for _, key in ipairs(LINE_TEXTS) do L.HookFont(Global(name .. key), 'text') end
	end
end

function SP:SkinStats()
	local frame = Global('SpyStatsFrame')
	if not frame or skinned[frame] then return end
	skinned[frame] = true

	-- Spy's art: the dialog's header texture, and the backdrop frames its OnLoad scripts made
	-- (fields of the frames, which are only read).
	for _, region in ipairs({ frame:GetRegions() }) do
		if region.GetObjectType and region:GetObjectType() == 'Texture' then Fade(region) end
	end
	Fade(frame.StatsFrame)

	-- One panel, and a line under the title above the sort headers.
	local panel = L.Panel(frame)
	if panel then
		local line = L.MakeDivider(panel)
		line:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, HEADER_LINE_Y)
		line:SetPoint('TOPRIGHT', frame, 'TOPRIGHT', 0, HEADER_LINE_Y)
	end

	L.HookFont(Global('SpyStatsFrame_Title'), 'title')
	for _, name in ipairs({ 'SpyStatsFrameFilterText', 'SpyStatsFrameShowOnlyText', 'SpyStatsHonorKillsText', 'SpyStatsPvPDeathsText' }) do
		L.HookFont(Global(name), 'text')
	end

	L.SkinIconButton(Global('SpyStatsFrameTopCloseButton'), st.icons.x)

	SkinPanelButton(Global('SpyStatsRefreshButton'))
	for _, key in ipairs(SORT_COLUMNS) do SkinSortHeader(Global('SpyStatsPlayers' .. key .. 'Sort')) end
	for _, key in ipairs(SORT_OTHERS) do SkinSortHeader(Global('SpyStats' .. key .. 'Sort')) end

	-- The content frame's tooltip-style backdrop (a field Spy's OnLoad sets) is faded: the
	-- window's panel is the one background.
	local content = Global('SpyStatsTabFrameTabContentFrame')
	if content then Fade(content.ContentFrame) end

	for i = 1, 100 do
		local line = Global('SpyStatsPlayerHistoryFrameListFrameLine' .. i)
		if not line then break end
		SkinLine(line)
	end

	-- The filter box: a 'control' backdrop of SaftUI's (st:SkinEditBox would put fields on it),
	-- Spy's own backdrop frame faded, a border in the Accent while it has focus.
	local box = Global('SpyStatsFilterBox')
	if box then
		Fade(box.FilterBox)
		local backdrop = L.Panel(box, 'control')
		if backdrop and box.HookScript then
			st:AddStates(backdrop, 'box', { edge = 'theme', wire = false })
			box:HookScript('OnEditFocusGained', function() st:SetState(backdrop, 'focus', true) end)
			box:HookScript('OnEditFocusLost', function() st:SetState(backdrop, 'focus', false) end)
		end
		L.HookFont(box, 'text')
	end

	for _, key in ipairs(CHECKS) do L.HookFont(Global('SpyStats' .. key .. 'CheckboxText'), 'text') end
end
