-- The accent (Theme > Accent, st.config.profile.theme.accent, st:Color('accent')):
-- what the options kit and edit mode draw in it where they drew Buttons > Blue
-- and Text > Blue, the own marks at OB.OWN_STRENGTH, and the live recolors
-- (a selected mover and the edit mode bar follow at once, Review Focus 4).
-- The accent row and the migration are theme_tab_test.lua's and
-- color_migration_test.lua's.
--
-- Real: the /sui window's world (options_widgets_helpers.lua for the kit's
-- controls), edit mode's files and its bar. The mouse is played by firing
-- scripts.
local H = load_test_file('core/options_widgets_helpers.lua')
load_editmode_bar()
local SL = load_test_file('lib/states_look.lua')
local st = SaftUI
local W, OB, EM = st.OptionsWidgets, st.OptionsBody, st.EditModeFrames
local bind, opt, theme, click, range = H.bind, H.opt, H.theme, H.click, H.range
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

local function accent() return st.config.profile.theme.accent end
local function text(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local function T(c) return text(c.r, c.g, c.b) end
local DEFAULT = '0.00,0.68,0.94'
local function texture_rgb(t) return text(unpack(stub.state(t).color_texture)) end
local function with_accent(r, g, b, fn)
	local c = accent()
	local keep = { c.r, c.g, c.b }
	c:SetRGB(r, g, b)
	fn()
	c:SetRGB(unpack(keep))
end

test("OB.Accent is the accent's r, g, b, exported as S.Accent too; OB.OWN_STRENGTH is 1", function()
	eq(text(OB.Accent()), DEFAULT)
	eq(OB.OWN_STRENGTH, 1); eq(OB.OWN_TEXT, nil, 'the light blue is gone'); eq(OB.Blue, nil, 'and the old name')
	with_accent(0.1, 0.2, 0.3, function() eq(text(OB.Accent()), '0.10,0.20,0.30', 'read at each call') end)
end)

test('the kit draws the accent where it drew Buttons > Blue and Text > Blue: same color at the defaults', function()
	theme('thick')
	local slider = range({ value = 0.5, min = 0, max = 1, step = 0.1 })
	eq(texture_rgb(slider.fill), DEFAULT, 'a slider fill')
	slider:Release()
	local toggle = bind('toggle', 'on', opt('toggle', 'On', { get = function() return true end, set = function() end }))
	eq(SL.rgb(st:StateLook(toggle.frame).mark), DEFAULT, 'a check mark (the states helper draws it in the accent)')
	toggle:Release()
	local button = W.Button(CreateFrame('Frame', nil, UIParent), 'Go', function() end)
	stub.fire_script(button, 'OnEnter', true)
	local r, g, b = button:GetBackdropBorderColor()
	eq(text(r, g, b), text(unpack(st.BOX_COLORS.edge)), 'a button under the mouse keeps its edge: the body tints')
	check(SL.near(st:StateLook(button).layer, '5cc6ff'), 'and the Layer is the lighter tone of the accent')
	stub.fire_script(button, 'OnLeave', true)
end)

test('a changed accent reaches each of them after the window draws again, and Roles > Tank stays', function()
	theme('thick')
	with_accent(0.9, 0.1, 0.2, function()
		local slider = range({ value = 0.5, min = 0, max = 1, step = 0.1 })
		eq(texture_rgb(slider.fill), '0.90,0.10,0.20', 'a slider fill')
		slider:Release()
		local toggle = bind('toggle', 'on', opt('toggle', 'On', { get = function() return true end, set = function() end }))
		eq(SL.rgb(st:StateLook(toggle.frame).mark), '0.90,0.10,0.20', 'a check mark')
		toggle:Release()
		eq(T(st:Color('roles', 'TANK')), DEFAULT, 'Tank keeps its own color')
		eq(T(st:Color('factions', 'Alliance')), DEFAULT, 'and Alliance')
	end)
end)

test("a list row under the mouse is the lighter tone at the hover strength, the picked one a bar and the fade (the own marks at OB.OWN_STRENGTH are options_share_test.lua's)", function()
	theme('thick')
	local values = { a = 'Alpha', b = 'Beta' }
	local w = bind('select', 'pick', opt('select', 'Pick', { values = values, get = function() return 'a' end, set = function() end }))
	click(w.frame)
	local list = W.GetListFrames()
	local picked = st:StateLook(list.rows[1])
	check(picked.selected and picked.bar.shown and picked.fill.shown, 'the picked entry is selected: the bar and the fade')
	eq(SL.rgb(picked.bar), DEFAULT, 'the bar in the accent')
	local plain = list.rows[2]
	stub.fire_script(plain, 'OnEnter')
	local look = st:StateLook(plain)
	check(look.layer.shown and SL.near(look.layer, '5cc6ff'), 'the row under the mouse is tinted in the lighter tone')
	eq(string.format('%.2f', look.layer.a), string.format('%.2f', select(4, st:StateColor('hover'))), 'at the hover strength')
	stub.fire_script(plain, 'OnLeave')
	check(not st:StateLook(plain).layer.shown, 'and not once it leaves')
	W.CloseList()
	w:Release()
end)

-- Edit mode.

local EMH = load_test_file('core/editmode_helpers.lua')
local frame_of = EMH.frame_of

local function mover_world()
	EM:Enable()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50); frame:SetPoint('CENTER')
	local config = { position = { point = 'CENTER', x_off = 0, y_off = 0 } }
	return st:RegisterConfigMover(frame, { key = 'accent_mover', config = function() return config end, apply = function() end })
end

test('edit mode: a selected mover is the accent border and the accent fade (the states helper\'s fill), and follows a change at once', function()
	theme('thick')
	local mover = mover_world()
	EM:Activate()
	EM:Select(mover)
	local backdrop = mover.overlay.backdrop
	local r, g, b = backdrop:GetBackdropBorderColor()
	eq(text(r, g, b), DEFAULT, 'the border')
	local fade = st:StateLook(mover.overlay).fill
	check(fade.shown, 'the fade shows')
	eq(text(fade.r, fade.g, fade.b), DEFAULT, 'the fill'); eq(string.format('%.2f', fade.a), string.format('%.2f', select(4, st:StateColor('fill'))), 'at the fill strength')
	with_accent(0.9, 0.1, 0.2, function()
		st:ColorsChanged('accent')
		r, g, b = backdrop:GetBackdropBorderColor()
		eq(text(r, g, b), '0.90,0.10,0.20', 'the border follows at once')
		fade = st:StateLook(mover.overlay).fill
		eq(text(fade.r, fade.g, fade.b), '0.90,0.10,0.20', 'and the fill')
	end)
	st:ColorsChanged('accent')
	EM:Deactivate()
end)

test('every live recolor of the accent: the edit mode bar follows at once (Coordinates, the strip and the History list are in their own files)', function()
	theme('thick')
	EM:Activate()
	EM:SetSetting('grid', true)
	local grid = frame_of('grid')
	eq(text(grid.icon:GetVertexColor()), DEFAULT, 'the icon in the accent')
	with_accent(0.9, 0.1, 0.2, function()
		st:ColorsChanged('accent')
		eq(text(grid.icon:GetVertexColor()), '0.90,0.10,0.20', 'the bar follows an accent change')
	end)
	st:ColorsChanged('accent')
	eq(text(grid.icon:GetVertexColor()), DEFAULT, 'and back')
	EM:Deactivate()
end)

test("the Accent's description says nothing of a reload, names what it is not a state of, and says the states are made from it", function()
	local option = st:GetModule('Colors'):AccentOption(5)
	eq(option.desc, "SaftUI's accent under every theme: what is on, picked or current, a field you type in, links and marks, fills that show progress, and the chat prefix. Hover, pushed and selected are made from it; the dots set how.")
	check(not option.desc:lower():find('reload', 1, true), 'no reload')
	eq(option.preview, 'states', 'its preview is the states kind')
	-- "the dots set how" is true: the row has the menu (Task 10, tests/core/accent_menu_test.lua)
	eq(type(option.menu), 'table', 'the dots: a menu of its own')
	eq(option.menu.type, 'group'); eq(option.menuTitle, 'Accent')
	eq(option.menu.colorEdit, true, 'it edits as the picker does')
end)
