-- The General tab of Global Settings (SaftUI-Core/Config/general.lua): Icon
-- zoom with its preview, Title bar height and Screen edge margin. Each row
-- reads and writes its profile key at call time, so a profile switch reaches
-- the new profile; the preview is cut as st:IconTexCoords (skinning.lua) cuts
-- SaftUI's icons at the zoom set now. Title bar height reaches every window
-- with a header at once (st:UpdateHeader, SaftUI-Core/panels.lua), and the
-- margin every frame kept inside it (st:UpdateScreenMargin, SaftUI-Core/api.lua;
-- the window with a header here), in combat too where the frame isn't
-- protected. tests/core/screen_margin_test.lua checks the margin on the other
-- frames it keeps in.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua,
-- with Core's helpers, skinning.lua among them), the options model the window
-- reads rows with (optionsmodel.lua), and panels.lua's headers and footers on
-- a panel from st:CreatePanel.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
local OM = st.OptionsModel

local ICONS_NOTE = 'The preview changes at once. The icons across SaftUI change when you reload (Reload UI, bottom left).'
local PREVIEW_ICON = 'Interface\\Icons\\Spell_Nature_Lightning'
local WINDOWS_NOTE = "The margin keeps all of SaftUI's frames that far from the screen's edges, not just the bags and bank; the minimap, which is Blizzard's, only when you drag it. Title bars and the margin change at once. The bags' Bag Slots button keeps its old height until you reload (Reload UI, bottom left)."

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

test('General: an Icons section, then Layout, each with a note; ranges with tooltips, and the preview', function()
	local tab = Tab()
	eq(tab.name, 'General')
	eq(tab.type, 'group')
	local sections = ByOrder(tab.args)
	eq(#sections, 2, 'two sections')
	eq(sections[1].key .. ',' .. sections[2].key, 'icons,windows')
	-- The second section's key is still windows; its name is Layout, since the
	-- margin keeps every frame in, not just the windows.
	eq(sections[1].v.name .. ',' .. sections[2].v.name, 'Icons,Layout')
	for _, s in ipairs(sections) do
		eq(s.v.type, 'group', s.key)
		eq(s.v.inline, true, s.key .. ' is a section, not a tab')
	end
	eq(tab.args.icons.desc, ICONS_NOTE, "Icons' note")
	eq(tab.args.windows.desc, WINDOWS_NOTE, "Layout's note")

	local function names(section)
		local out = {}
		for i, r in ipairs(ByOrder(section.args)) do out[i] = r.key .. '=' .. r.v.name end
		return table.concat(out, ',')
	end
	eq(names(tab.args.icons), 'icon_trim=Icon zoom,icon_preview=Preview')
	eq(names(tab.args.windows), 'header_height=Title bar height,clamp_inset=Screen edge margin')

	-- Every row is a range but the preview, a description (a line of its own,
	-- with no tooltip: it shows what the zoom does).
	eq(tab.args.icons.args.icon_preview.type, 'description', 'the preview')
	eq(tab.args.icons.args.icon_preview.width, nil, 'the preview has no Ace width')
	for _, section in pairs(tab.args) do
		for key, option in pairs(section.args) do
			if key ~= 'icon_preview' then
				eq(option.type, 'range', key)
				check(type(option.desc) == 'string' and #option.desc > 40, key .. ' has a desc')
				eq(option.width, nil, key .. ' has no Ace width')
				-- A slider can't be small in SaftUI's window; it takes a half.
				eq(option.size, nil, key .. ' takes the normal size')
			end
		end
	end
	eq(tab.args.windows.args.clamp_inset.desc, "How close to the screen's edges frames can go.", "the margin's tooltip, in the user's words")
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

-- The preview's imageCoords as text, read through the model as the window
-- reads them.
local function PreviewCoords()
	local root, row = Row('icon_preview')
	local coords = OM.Member(root, row, 'imageCoords')
	return type(coords) == 'table' and table.concat(coords, ',') or tostring(coords)
end

test("Icon zoom's preview: a lightning icon at 36 by 36, cut as st:IconTexCoords cuts SaftUI's icons at the zoom set now", function()
	local root, row = Row('icon_preview')
	eq(row.type, 'description', 'a description row')
	eq(row.size, 'wide', 'on a line of its own')
	eq(row.name, 'Preview', 'its text')
	local zoomOrder = Tab().args.icons.args.icon_trim.order
	check(Tab().args.icons.args.icon_preview.order > zoomOrder, 'after Icon zoom')
	eq(OM.Member(root, row, 'image'), PREVIEW_ICON, 'the icon')
	eq(OM.Member(root, row, 'imageWidth'), 36, 'width')
	eq(OM.Member(root, row, 'imageHeight'), 36, 'height')

	local function Expected(trim) return table.concat({ st:IconTexCoords(trim, 36, 36) }, ',') end
	eq(PreviewCoords(), Expected(0.065), 'the default zoom')
	eq(#OM.Member(root, row, 'imageCoords'), 4, 'left, right, top, bottom')
	Set('icon_trim', 0.15)
	eq(PreviewCoords(), Expected(0.15), 'a new zoom, read when the coords are read')
	eq(PreviewCoords(), '0.15,0.85,0.15,0.85', '0.15 off each edge')
	st.config.profile.misc.icon_trim = 0
	eq(PreviewCoords(), '0,1,0,1', 'no zoom: the whole icon')
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
	st:UpdateScreenMargin() -- what a profile change in combat runs
	eq(Insets(panel), '-5,5,5,-5', 'an unprotected window, at once')
	eq(Insets(guarded), '-20,20,20,-20', 'the protected one keeps its margin in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(Insets(guarded), '-5,5,5,-5', 'and takes the new one when combat ends')
	st.config.profile.misc.clamp_inset = 20
	st:UpdateScreenMargin()
	eq(#take_errors(), 0, 'no errors')
end)

test('after a profile switch, each row reads and writes the new profile, and the windows take its values', function()
	local first = st.config:GetCurrentProfile()
	Set('icon_trim', 0.1)
	Set('header_height', 44)
	Set('clamp_inset', 0)

	eq(PreviewCoords(), table.concat({ st:IconTexCoords(0.1, 36, 36) }, ','), 'the preview at the first profile\'s zoom')
	st.config:SetProfile('GeneralTestTwo')
	eq(Get('icon_trim'), 0.065, "the new profile's icon zoom")
	eq(PreviewCoords(), table.concat({ st:IconTexCoords(0.065, 36, 36) }, ','), "the preview takes the new profile's zoom")
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
