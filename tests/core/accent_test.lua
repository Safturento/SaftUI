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
	eq(texture_rgb(toggle.frame.mark), DEFAULT, 'a check mark')
	toggle:Release()
	local button = W.Button(CreateFrame('Frame', nil, UIParent), 'Go', function() end)
	stub.fire_script(button, 'OnEnter', true)
	local r, g, b = button:GetBackdropBorderColor()
	eq(text(r, g, b), DEFAULT, 'a button under the mouse')
	stub.fire_script(button, 'OnLeave', true)
end)

test('a changed accent reaches each of them after the window draws again, and Roles > Tank stays', function()
	theme('thick')
	with_accent(0.9, 0.1, 0.2, function()
		local slider = range({ value = 0.5, min = 0, max = 1, step = 0.1 })
		eq(texture_rgb(slider.fill), '0.90,0.10,0.20', 'a slider fill')
		slider:Release()
		local toggle = bind('toggle', 'on', opt('toggle', 'On', { get = function() return true end, set = function() end }))
		eq(texture_rgb(toggle.frame.mark), '0.90,0.10,0.20', 'a check mark')
		toggle:Release()
		eq(T(st:Color('roles', 'TANK')), DEFAULT, 'Tank keeps its own color')
		eq(T(st:Color('factions', 'Alliance')), DEFAULT, 'and Alliance')
	end)
end)

test('a list row under the mouse is the accent at 0.25 (the own marks at OB.OWN_STRENGTH are options_share_test.lua\'s)', function()
	theme('thick')
	local values = { a = 'Alpha', b = 'Beta' }
	local w = bind('select', 'pick', opt('select', 'Pick', { values = values, get = function() return 'a' end, set = function() end }))
	click(w.frame)
	local list = W.GetListFrames()
	stub.fire_script(list.rows[1], 'OnEnter')
	local hover = list.rows[1].hover
	eq(texture_rgb(hover), DEFAULT, 'the row hover'); eq(string.format('%.2f', hover:GetAlpha()), '0.25')
	local picked = list.rows[1].text
	eq(text(picked:GetTextColor()), DEFAULT, 'the picked entry in the accent')
	stub.fire_script(list.rows[1], 'OnLeave')
	W.CloseList()
	do -- at the row tint, by its name, not a number of its own (the list is drawn again when its look changes)
		local keep = st.TINT_ROW
		st.TINT_ROW = 0.4
		theme('blizzard'); click(w.frame); W.CloseList()
		theme('thick'); click(w.frame)
		eq(string.format('%.2f', W.GetListFrames().rows[1].hover:GetAlpha()), '0.40', 'at st.TINT_ROW')
		st.TINT_ROW = keep
		W.CloseList()
	end
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

test('edit mode: a selected mover is the accent border and the accent at TINT_OBJECT, and follows a change at once', function()
	theme('thick')
	local mover = mover_world()
	EM:Activate()
	EM:Select(mover)
	local backdrop = mover.overlay.backdrop
	local r, g, b = backdrop:GetBackdropBorderColor()
	eq(text(r, g, b), DEFAULT, 'the border')
	local fr, fg, fb, fa = backdrop:GetBackdropColor()
	eq(text(fr, fg, fb), DEFAULT, 'the fill'); eq(string.format('%.2f', fa), string.format('%.2f', st.TINT_OBJECT), 'at TINT_OBJECT')
	with_accent(0.9, 0.1, 0.2, function()
		st:ColorsChanged('accent')
		r, g, b = backdrop:GetBackdropBorderColor()
		eq(text(r, g, b), '0.90,0.10,0.20', 'the border follows at once')
		fr, fg, fb = backdrop:GetBackdropColor()
		eq(text(fr, fg, fb), '0.90,0.10,0.20', 'and the fill')
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
