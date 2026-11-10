-- The General tab of Global Settings (SaftUI-Core/Config/general.lua): Icon
-- zoom, Title bar height and Screen edge margin. Each row reads and writes its
-- profile key at call time, so a profile switch reaches the new profile, and
-- the two window settings reach every window with a header at once
-- (st:UpdateHeader, SaftUI-Core/panels.lua), in combat too where the window
-- isn't protected.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua),
-- the options model the window reads rows with (optionsmodel.lua), and
-- panels.lua's headers and footers on a panel from st:CreatePanel.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
local OM = st.OptionsModel

local ICONS_NOTE = 'SaftUI cuts its icons when it builds its frames: reload (Reload UI, bottom left) to see a change everywhere.'
local WINDOWS_NOTE = "Title bars and the margin change at once. The bags' Bag Slots button keeps its old height until you reload (Reload UI, bottom left)."

local function Tab() return st.Config:GetOptionsTable().Fonts.args.general end

local function ByOrder(t)
	local out = {}
	for key, v in pairs(t) do out[#out + 1] = { key = key, v = v } end
	table.sort(out, function(a, b) return a.v.order < b.v.order end)
	return out
end

-- The model's row for key on the General tab, and the tree it's in.
local function Row(key)
	local root = st.Config:GetOptionsTable()
	for _, section in ipairs(OM.BuildView(root, 'Fonts', { tab = 'general' }).sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return root, row end
		end
	end
	error('no row ' .. key)
end

local function Get(key) local root, row = Row(key); return OM.Get(root, row) end
local function Set(key, value) local root, row = Row(key); return OM.Set(root, row, value) end

-- A frame's clamp insets as 'left,right,top,bottom' (-0 written as 0).
local function Insets(frame)
	local out = { frame:GetClampRectInsets() }
	for i, v in ipairs(out) do out[i] = tostring(v == 0 and 0 or v) end
	return table.concat(out, ',')
end

local panel = st:CreatePanel('General test', 200, 100)
st:CreateFooter(panel)

test('General: an Icons section, then Windows, each with a note; ranges with tooltips', function()
	local tab = Tab()
	eq(tab.name, 'General')
	eq(tab.type, 'group')
	local sections = ByOrder(tab.args)
	eq(#sections, 2, 'two sections')
	eq(sections[1].key .. ',' .. sections[2].key, 'icons,windows')
	eq(sections[1].v.name .. ',' .. sections[2].v.name, 'Icons,Windows')
	for _, s in ipairs(sections) do
		eq(s.v.type, 'group', s.key)
		eq(s.v.inline, true, s.key .. ' is a section, not a tab')
	end
	eq(tab.args.icons.desc, ICONS_NOTE, "Icons' note")
	eq(tab.args.windows.desc, WINDOWS_NOTE, "Windows' note")

	local function names(section)
		local out = {}
		for i, r in ipairs(ByOrder(section.args)) do out[i] = r.key .. '=' .. r.v.name end
		return table.concat(out, ',')
	end
	eq(names(tab.args.icons), 'icon_trim=Icon zoom')
	eq(names(tab.args.windows), 'header_height=Title bar height,clamp_inset=Screen edge margin')

	for _, section in pairs(tab.args) do
		for key, option in pairs(section.args) do
			eq(option.type, 'range', key)
			check(type(option.desc) == 'string' and #option.desc > 40, key .. ' has a desc')
			eq(option.width, nil, key .. ' has no Ace width')
			-- A slider can't be small in SaftUI's window; it takes a half.
			eq(option.size, nil, key .. ' takes the normal size')
		end
	end
	check(tab.args.windows.args.clamp_inset.desc:find('in from', 1, true), "the margin's tooltip says it keeps windows in from the edge")
	check(tab.args.windows.args.clamp_inset.desc:find('past', 1, true), 'and that below 0 lets them past it')
end)

test("Icon zoom is a percent of each edge, and its value is the profile's fraction", function()
	local zoom = Tab().args.icons.args.icon_trim
	eq(zoom.isPercent, true, 'shown as a percent')
	eq(zoom.min, 0); eq(zoom.max, 0.2, 'up to 20%'); eq(zoom.step, 0.005, 'in steps of half a percent')
	eq(Get('icon_trim'), 0.065, 'the default')
	Set('icon_trim', 0.1)
	eq(st.config.profile.misc.icon_trim, 0.1, 'a set writes the fraction')
	eq(Get('icon_trim'), 0.1, 'and reads it back')
	Set('icon_trim', 0.065)
end)

test('Title bar height resizes every header and footer at once', function()
	eq(Get('header_height'), 31, 'the default')
	eq(panel.header:GetHeight(), 31)
	Set('header_height', 40)
	eq(st.config.profile.headers.height, 40, 'the profile')
	eq(panel.header:GetHeight(), 40, 'the header')
	eq(panel.footer:GetHeight(), 40, 'the footer')
	local range = Tab().args.windows.args.header_height
	eq(range.min .. '-' .. range.max .. '/' .. range.step, '20-60/1')
	Set('header_height', 31)
	eq(panel.header:GetHeight(), 31, 'and back')
end)

test("Screen edge margin keeps a window that far in from the screen's edges, and changes at once", function()
	eq(Get('clamp_inset'), 20, 'the default')
	check(panel:IsClampedToScreen(), 'a window with a header is clamped to the screen')
	-- The clamp rect is the frame's rect grown by the insets, and the game keeps
	-- it on screen: a positive margin keeps the window that far in.
	eq(Insets(panel), '-20,20,20,-20', 'the default margin')
	Set('clamp_inset', -10)
	eq(st.config.profile.misc.clamp_inset, -10, 'the profile')
	eq(Insets(panel), '10,-10,-10,10', 'below 0: the window can go that far past the edge')
	local range = Tab().args.windows.args.clamp_inset
	eq(range.min .. '-' .. range.max .. '/' .. range.step, '-50-50/1')
	Set('clamp_inset', 20)
	eq(Insets(panel), '-20,20,20,-20', 'and back')
end)

test("in combat a protected window's margin waits for the end of combat; the others change at once", function()
	-- Stub frames are never protected; this one says it is, as a bag window
	-- holding Blizzard's item buttons may be in game.
	local guarded = st:CreatePanel('General guarded', 200, 100)
	function guarded:IsProtected() return true, true end
	stub.in_combat = true
	st.config.profile.misc.clamp_inset = 5
	st:UpdateHeader() -- what a profile change in combat runs
	eq(Insets(panel), '-5,5,5,-5', 'an unprotected window, at once')
	eq(Insets(guarded), '-20,20,20,-20', 'the protected one keeps its margin in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(Insets(guarded), '-5,5,5,-5', 'and takes the new one when combat ends')
	st.config.profile.misc.clamp_inset = 20
	st:UpdateHeader()
	eq(#take_errors(), 0, 'no errors')
end)

test('after a profile switch, each row reads and writes the new profile, and the windows take its values', function()
	local first = st.config:GetCurrentProfile()
	Set('icon_trim', 0.1)
	Set('header_height', 44)
	Set('clamp_inset', 0)

	st.config:SetProfile('GeneralTestTwo')
	eq(Get('icon_trim'), 0.065, "the new profile's icon zoom")
	eq(Get('header_height'), 31, "the new profile's title bar height")
	eq(Get('clamp_inset'), 20, "the new profile's margin")
	eq(panel.header:GetHeight(), 31, 'the header takes it')
	eq(Insets(panel), '-20,20,20,-20', 'so does the margin')

	Set('header_height', 36)
	eq(st.config.profile.headers.height, 36, 'a set reaches the new profile')
	eq(panel.header:GetHeight(), 36)

	st.config:SetProfile(first)
	eq(Get('icon_trim'), 0.1, "the first profile's values are as they were")
	eq(Get('header_height'), 44)
	eq(Get('clamp_inset'), 0)
	eq(panel.header:GetHeight(), 44, 'and the windows take them again')
	eq(Insets(panel), '0,0,0,0')
	Set('icon_trim', 0.065)
	Set('header_height', 31)
	Set('clamp_inset', 20)
	eq(#take_errors(), 0, 'no errors')
end)
