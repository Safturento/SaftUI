-- The second menu level (menu_in_menu_test.lua runs on an unconverted profile, so no row there is shared) on a
-- Font row that is shared and followed: the unit frames' page world over a converted profile. A set in the
-- second menu makes the unit own the typeface (the decorator's OwnThenSet), the sync puts nothing back, and a
-- change of All units' typeface reaches the units that follow it and not the one that owns its own.
local PW = load_test_file('unitframes/page_world.lua').world()
local st, UF, OM, OW, W = PW.st, PW.UF, PW.OM, PW.OW, PW.W
local OB = st.OptionsBody
load_editmode()

local function tree() return { Unitframes = UF:GetConfigTable() } end
local function draw_general(root, unit)
	local content = CreateFrame('Frame', nil, UIParent)
	content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	content:SetSize(774, 900)
	local body = OB.New(content, root, nil, 774)
	local view = OM.BuildView(root, 'Unitframes', { pick = unit })
	body:Draw(view.sections)
	local by = {}
	for _, c in ipairs(body.cells) do by[c.row.key] = c end
	return body, by
end
local function font_cell(m)
	for _, c in ipairs(m.body.cells) do if c.row.type == 'font' then return c end end
end

test('a followed typeface Font row: its second menu makes the unit own it, and the sync keeps it', function()
	UF:PrepareShared()
	check(UF:SharedReady(), 'the profile is converted')
	local typeface = { font_name = 'Arial Narrow', font_size = 13, font_outline = 'NONE' }
	local changed = UF:SetShared('all', 'health.text.font', typeface)
	check(type(changed) == 'table', 'All units took a typeface')
	local profile = UF:GetProfileConfig()
	eq(UF:IsOwn('target', 'health.text.font'), false, 'target follows')
	eq(type(profile.target.health.text.font), 'table', 'target holds the typeface copy')
	local root = tree()
	local body, by = draw_general(root, 'target')
	local part = by.healthtext
	check(part.widget:OpenMenu(), 'the part menu opens')
	local first = OW.GetMenuFrames(1)
	local font = font_cell(first)
	eq(font.widget.kind, 'typeface', 'the followed Font row is a typeface')
	local state = OM.ShareState(OM.MenuRoot(part.row.option), font.row)
	eq(state and state.own, false, 'not own')
	font.widget:ToggleMenu()
	check(OW:IsMenuShown(font.widget), 'second menu shown')
	local second = OW.GetMenuFrames(2)
	local size
	for _, c in ipairs(second.body.cells) do if c.row.name == 'Size' then size = c end end
	size.widget:Commit(23)
	eq(st:FontFields(profile.target.health.text.font).font_size, 23, "target's font has the new size")
	eq(UF:IsOwn('target', 'health.text.font'), true, 'and target owns it now')
	eq(st:FontFields(rawget(profile, 'all').health.text.font).font_size, 13, "All units' is unchanged")
	eq(st:FontFields(profile.focus.health.text.font).font_size, 13, 'focus still follows')
	eq(UF:SyncShared(), 0, 'the sync has nothing to put back')
	-- Now on All units: change its typeface's size through the second menu: followers follow, target keeps its own.
	OW:CloseMenu(); body:Release()
	root = tree()
	body, by = draw_general(root, 'all')
	check(by.healthtext.widget:OpenMenu(), 'All units part menu')
	first = OW.GetMenuFrames(1)
	font = font_cell(first)
	font.widget:ToggleMenu()
	second = OW.GetMenuFrames(2)
	for _, c in ipairs(second.body.cells) do if c.row.name == 'Size' then size = c end end
	size.widget:Commit(17)
	eq(st:FontFields(profile.focus.health.text.font).font_size, 17, 'focus follows the All units change')
	eq(st:FontFields(profile.target.health.text.font).font_size, 23, 'target keeps its own')
	OW:CloseMenu(); body:Release()
end)
