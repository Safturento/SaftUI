-- The item menu's second level (SaftUI-Core/Config/optionsmenu.lua): a widget whose row a menu's
-- own body draws (a font row's dots in a part's menu) opens a second menu over the first, the
-- first held as it is. Levels and catchers, Esc, the toggle, two levels only, the owner going,
-- OW:CloseMenu(body), a render with both open, the color edit's count, combat, whole pixels.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0, the model, the widgets, the body and the
-- window's files, as options_window_helpers.lua loads them. Levels, a synthetic module: Part, an
-- item whose menu holds a Font row, a Size range and Sub (an item with a menu of its own).
local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local OM, W, OB, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsBody, st.OptionsWindow
local close_all, click, cell, theme = H.close_all, H.click, H.cell, H.theme
local FN = st:GetModule('Fonts')

local vals
local function fresh()
	vals = { font = { font_name = 'Arial Narrow', font_size = 12, font_outline = '' }, size = 5, subs = 0 }
end
fresh()

local function MenuOfPart()
	return {
		type = 'group', name = 'Part',
		args = {
			font = (function()
				local option = st.Config.generators.font(1, 'Its font.')
				option.name = 'Font'
				option.get = function() return vals.font end
				option.set = function(_, value) vals.font = value end
				return option
			end)(),
			size = { order = 2, type = 'range', name = 'Size', desc = 'Its size.', min = 1, max = 20, step = 1,
				get = function() return vals.size end, set = function(_, value) vals.size = value end },
			sub = { order = 3, type = 'item', name = 'Sub', desc = 'A part in a menu.', size = 'small',
				get = function() return true end, set = function() end,
				menu = { type = 'group', name = 'Sub', args = {
					count = { order = 1, type = 'range', name = 'Count', desc = 'Count.', min = 0, max = 9, step = 1,
						get = function() return vals.subs end, set = function(_, value) vals.subs = value end },
				} } },
		},
	}
end

local LV = st:NewModule('Levels')
function LV:GetConfigTable()
	return {
		name = 'Levels', type = 'group', category = 'Frames',
		args = { texts = { order = 1, type = 'group', name = 'Texts', args = {
			part = { order = 1, type = 'item', name = 'Part', desc = 'A part.', size = 'small',
				get = function() return true end, set = function() end,
				summary = function() return 'size ' .. tostring(FN.FieldValue(st:FontFields(vals.font), 'font_size')) end,
				menu = MenuOfPart() },
		} } },
	}
end

local function M(level) return OW.GetMenuFrames(level) end
local function menuCell(m, key)
	for _, c in ipairs(m.body.cells) do
		if c.row.key == key or c.row.name == key then return c end
	end
end
local function point(region)
	local _, rel = region:GetPoint(1)
	return rel
end

-- The part's menu open, its Font row a typeface, then the font row's dots clicked: both shown.
local function open_both()
	fresh()
	st.Config:Open('Levels', 'texts')
	click(cell('part').widget.dots)
	local font = menuCell(M(), 'font')
	font.widget:Pick('face:Arial Narrow')
	font = menuCell(M(), 'font')
	click(font.widget.dots)
	return font
end

test('a font row in a menu opens a second level over it: frame levels, its own catcher, the dots it hangs from', function()
	local font = open_both()
	local first, second = M(1), M(2)
	check(first.frame:IsShown() and second.frame:IsShown(), 'both shown')
	check(first ~= second and M() == first, 'two instances; the default is the first')
	eq(first.frame:GetFrameLevel() .. '/' .. first.catcher:GetFrameLevel(), '410/400', 'the first as it was')
	eq(second.frame:GetFrameLevel() .. '/' .. second.catcher:GetFrameLevel(), '430/420', 'the second over it, its catcher between')
	eq(second.frame:GetFrameStrata(), 'FULLSCREEN_DIALOG')
	eq(second.catcher:GetFrameStrata(), 'FULLSCREEN_DIALOG')
	check(second.catcher:IsShown() and second.catcher:IsMouseEnabled(), 'taking the mouse')
	eq(second.owner.body, first.body, "its item is in the first menu's body")
	eq(second.owner.path[#second.owner.path], 'font', 'the Font row')
	eq(point(second.frame), font.widget.dots, "on the Font row's dots")
	eq(first.owner.path[#first.owner.path], 'part', 'the first is still the Part row\'s')
	check(OW:IsMenuShown(font.widget) and OW:IsMenuShown(cell('part').widget), 'IsMenuShown answers for either level')
	check(OW:IsMenuShown(), 'and none given')
	eq(second.title:GetText(), 'Font: Arial Narrow', 'the typeface menu\'s title')
	eq(second.body.width, 376, 'drawn as the first is')
	close_all()
end)

test('a click on the second level\'s catcher closes it only; the first\'s catcher then closes the first', function()
	open_both()
	local first, second = M(1), M(2)
	stub.fire_script(second.catcher, 'OnMouseDown', 'LeftButton')
	check(not second.frame:IsShown() and not second.catcher:IsShown(), 'the second closed')
	check(first.frame:IsShown() and first.catcher:IsShown(), 'the first stays')
	eq(second.owner, nil, 'the second has no owner')
	stub.fire_script(first.catcher, 'OnMouseDown', 'LeftButton')
	check(not first.frame:IsShown(), 'a click outside, with only the first open: it closes as before')
	close_all()
end)

test('closing the first closes the second first; CloseMenu with no body closes both', function()
	open_both()
	local order = {}
	M(2).frame:HookScript('OnHide', function() order[#order + 1] = 'second' end)
	M(1).frame:HookScript('OnHide', function() order[#order + 1] = 'first' end)
	OW:CloseMenu()
	check(not M(1).frame:IsShown() and not M(2).frame:IsShown(), 'both closed')
	eq(table.concat(order, ','), 'second,first', 'the second hid inside the first\'s hide, before the first was done')
	check(not OW:IsMenuShown(), 'none shown')
	close_all()
end)

test('Esc closes the second level first, then the first', function()
	open_both()
	local first, second = M(1), M(2)
	-- The first passes Esc on while the second shows.
	stub.fire_script(first.keys, 'OnKeyDown', 'ESCAPE')
	check(first.frame:IsShown() and second.frame:IsShown(), 'the first does not take it')
	stub.fire_script(second.keys, 'OnKeyDown', 'ESCAPE')
	check(not second.frame:IsShown() and first.frame:IsShown(), 'the second closes, the first stays')
	stub.fire_script(first.keys, 'OnKeyDown', 'ESCAPE')
	check(not first.frame:IsShown(), 'then the first')
	close_all()
end)

test("the font row's dots again close the second level and leave the first", function()
	local font = open_both()
	click(font.widget.dots)
	check(not M(2).frame:IsShown(), 'the second closed')
	check(M(1).frame:IsShown() and OW:IsMenuShown(cell('part').widget), 'the first stays')
	check(not OW:IsMenuShown(font.widget), 'the Font row has no menu shown')
	click(font.widget.dots)
	check(M(2).frame:IsShown() and OW:IsMenuShown(font.widget), 'and again opens it')
	close_all()
end)

test('two levels only: a widget of the second level asks for a menu and gets false', function()
	open_both()
	local second = M(2)
	local widget = menuCell(second, 'Size').widget
	widget.dots = widget.frame -- a row that has dots and a menu, in the second level
	widget.Menu = function() return { type = 'group', name = 'Third', args = {} }, 'Third' end
	eq(OW:OpenMenu(widget), false, 'refused')
	check(second.frame:IsShown() and M(1).frame:IsShown(), 'both as they were')
	eq(second.owner.path[#second.owner.path], 'font', 'the second still the Font row\'s')
	widget.Menu, widget.dots = nil, nil
	close_all()
end)

test('the owner gone: the font becomes a shared font and a render closes the second only', function()
	open_both()
	local first = M(1)
	vals.font = 'Text'
	OW:Render()
	check(not M(2).frame:IsShown(), 'the second closed: its row has no typeface menu now')
	check(first.frame:IsShown(), 'the first stays')
	eq(menuCell(first, 'font').widget.kind, 'shared', "and its Font row reads it, in place")
	close_all()
	-- The row gone altogether (the page changed): both close.
	open_both()
	OW:Navigate('Levels', { tab = 'texts' })
	close_all()
end)

test('OW:CloseMenu(body): the page\'s body closes both, the first menu\'s body closes the second only', function()
	open_both()
	local first = M(1)
	OW:CloseMenu({})
	check(first.frame:IsShown() and M(2).frame:IsShown(), 'another body: nothing')
	OW:CloseMenu(first.body)
	check(not M(2).frame:IsShown() and first.frame:IsShown(), "the first menu's body: the second closes")
	close_all()
	open_both()
	OW:CloseMenu(first.owner.body)
	check(not first.frame:IsShown() and not M(2).frame:IsShown(), "the page's body: both")
	close_all()
end)

test('a render with both open leaves the first menu\'s rows and moves both onto their new dots', function()
	local font = open_both()
	local first, second = M(1), M(2)
	local rows = {}
	for _, c in ipairs(first.body.cells) do rows[c.row.key] = c.widget end
	local rows2 = #second.body.cells
	local title = first.title:GetText()
	OW:Render()
	check(first.frame:IsShown() and second.frame:IsShown(), 'both still shown')
	for _, c in ipairs(first.body.cells) do
		check(rows[c.row.key] == c.widget, "the first menu's " .. tostring(c.row.key) .. ' row is the same widget')
	end
	eq(first.title:GetText(), title, "its title as it was")
	eq(point(first.frame), cell('part').widget.dots, "the first on the page's new dots")
	eq(point(second.frame), menuCell(first, 'font').widget.dots, 'the second on the Font row\'s dots')
	eq(menuCell(first, 'font').widget, font.widget, 'the very Font row')
	eq(#second.body.cells, rows2, 'the second drawn again')
	close_all()
end)

test('a set in the second level saves, shows in the first menu\'s Font row and the page, and draws nothing of the first again', function()
	local font = open_both()
	local first, second = M(1), M(2)
	local rows = {}
	for _, c in ipairs(first.body.cells) do rows[c.row.key] = c.widget end
	eq(cell('part').widget.summary:GetText(), 'size 12', 'the page: the part row\'s summary')
	menuCell(second, 'Size').widget:Commit(23)
	eq(FN.FieldValue(st:FontFields(vals.font), 'font_size'), 23, 'saved')
	eq(font.widget.value.font_size, 23, "the first menu's Font row shows it")
	eq(cell('part').widget.summary:GetText(), 'size 23', 'and the page behind follows')
	check(first.frame:IsShown() and second.frame:IsShown(), 'both stay')
	for _, c in ipairs(first.body.cells) do
		check(rows[c.row.key] == c.widget, "the first menu's " .. tostring(c.row.key) .. ' row is the same widget')
	end
	close_all()
end)

-- Whether the part's menu and the Sub item's menu change colors (colorEdit), set on the tables the page drew.
local function color_edits(part, sub)
	local menu = cell('part').row.option.menu
	menu.colorEdit = part or nil
	menu.args.sub.menu.colorEdit = sub or nil
end

test('the color edit stays balanced with two levels', function()
	fresh()
	st.Config:Open('Levels', 'texts')
	color_edits(true, true)
	check(not st:InColorEdit(), 'none to start')
	click(cell('part').widget.dots)
	check(st:InColorEdit(), 'the first begins it')
	click(menuCell(M(), 'sub').widget.dots)
	check(M(2).frame:IsShown(), 'an item row of the menu opens a second level too')
	check(st:InColorEdit(), 'with both')
	OW:CloseMenuOf(menuCell(M(), 'sub').widget)
	check(not M(2).frame:IsShown() and M(1).frame:IsShown(), 'the second alone closed')
	check(st:InColorEdit(), "the first's hold is still there")
	click(menuCell(M(), 'sub').widget.dots)
	OW:CloseMenu()
	check(not st:InColorEdit(), 'both closed: ended')
	close_all()
	-- Only the second changes colors: it begins its own and ends it.
	st.Config:Open('Levels', 'texts')
	color_edits(false, true)
	click(cell('part').widget.dots)
	check(not st:InColorEdit())
	click(menuCell(M(), 'sub').widget.dots)
	check(st:InColorEdit(), 'the second begins its own')
	stub.fire_script(M(2).catcher, 'OnMouseDown', 'LeftButton')
	check(not st:InColorEdit(), 'and ends it')
	color_edits(false, false)
	close_all()
end)

test('combat: refused to open a second level, and entering combat closes both', function()
	local font = open_both()
	click(font.widget.dots) -- closed
	stub.in_combat = true
	eq(OW:OpenMenu(font.widget), false, 'refused in combat')
	check(not M(2).frame:IsShown(), 'no second level')
	stub.in_combat = false
	click(font.widget.dots)
	check(M(2).frame:IsShown(), 'open again')
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not M(1).frame:IsShown() and not M(2).frame:IsShown(), 'both closed')
	close_all()
end)

test('the second level sits on whole pixels, as the first does', function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		theme(look)
		for _, noise in ipairs({ 0, 2 ^ -14, -2 ^ -14 }) do
			stub.size_noise = noise
			for _, low in ipairs({ false, true }) do
				st.config.global.optionsWindow = low and { point = 'CENTER', x = 0, y = -300 } or nil
				local where = ('%s, noise %s%s'):format(look, noise, low and ', low' or '')
				open_both()
				check(M(2).frame:IsShown(), where .. ': open')
				local off = P.off(M(2).frame)
				eq(#off, 0, where .. ': ' .. P.report(off))
				off = P.off(M(1).frame)
				eq(#off, 0, where .. ' (first): ' .. P.report(off))
				close_all()
			end
		end
	end
	stub.size_noise = 0
	st.config.global.optionsWindow = nil
	theme('thick')
end)
