-- A font row's dots inside a part's menu open a second menu over it (the owner's case: Unit
-- frames > a unit > General > Parts > Health text's menu, its Font row's dots closed the part's
-- menu and showed nothing). SaftUI-Core/Config/optionsmenu.lua's second level, in the unit
-- frames' page world (page_world.lua), over the real part rows (config/parts.lua).
local PW = load_test_file('unitframes/page_world.lua').world()
local st, UF, OM, OW, W = PW.st, PW.UF, PW.OM, PW.OW, PW.W
local OB = st.OptionsBody

local UNITS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
	'party', 'raid10', 'raid40', 'nameplate', 'friendlynameplate' }

local function tree() return { Unitframes = UF:GetConfigTable() } end

-- General drawn in a body on its own, for the part rows' widgets.
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

-- The first menu's font rows (type 'font' cells), in order.
local function font_cells(m)
	local out = {}
	for _, c in ipairs(m.body.cells) do
		if c.row.type == 'font' then out[#out + 1] = c end
	end
	return out
end

local function typeface_font_cell(m)
	for _, c in ipairs(font_cells(m)) do
		if c.widget.kind == 'typeface' then return c end
	end
end

test("the owner's case: the Font row's dots in Health text's menu open the typeface menu over it", function()
	local root = tree()
	local body, by = draw_general(root, 'player')
	local part = by.healthtext
	check(part and part.widget, 'Health text is a part row')
	check(part.widget:OpenMenu(), 'its menu opens')
	local first = OW.GetMenuFrames()
	-- Find its font row; give it a typeface through the row's own pick.
	local font
	for _, c in ipairs(font_cells(first)) do font = c end
	check(font, 'the part menu has a Font row')
	font.widget:Pick('face:Arial Narrow')
	font = typeface_font_cell(first)
	check(font, 'the Font row now shows a typeface')
	local widgets = {}
	for _, c in ipairs(first.body.cells) do widgets[c.row.key] = c.widget end
	font.widget:ToggleMenu()
	check(OW:IsMenuShown(font.widget), "the Font row's menu is shown")
	local second = OW.GetMenuFrames(2)
	check(first.frame:IsShown(), 'the part menu is still shown')
	check(OW:IsMenuShown(part.widget), 'and it is still the part row\'s menu')
	eq(first.owner and first.owner.path[#first.owner.path], 'healthtext', 'its owner is the part row')
	check(second ~= first, 'the second menu is its own')
	check(second.frame:IsShown(), 'the second menu is shown')
	if second == first or not OW:IsMenuShown(part.widget) then OW:CloseMenu(); body:Release(); return end
	check(second.title:GetText():find('Arial Narrow', 1, true), 'its title names the typeface: ' .. tostring(second.title:GetText()))
	local rows = {}
	for _, c in ipairs(second.body.cells) do rows[#rows + 1] = c.row.name end
	eq(table.concat(rows, ','), 'Size,Outline,Shadow offset X,Shadow offset Y,Line spacing', 'its rows')
	-- Set Size there.
	local size
	for _, c in ipairs(second.body.cells) do if c.row.name == 'Size' then size = c end end
	size.widget:Commit(23)
	eq(st:FontFields(UF:GetProfileConfig().player.health.text.font).font_size, 23, 'the saved font has the new size')
	eq(font.widget.value.font_size, 23, "the first menu's Font row shows it")
	check(first.frame:IsShown() and second.frame:IsShown(), 'both still shown')
	for _, c in ipairs(first.body.cells) do
		check(widgets[c.row.key] == c.widget, "the first menu's row " .. tostring(c.row.key) .. ' is the same widget')
	end
	OW:CloseMenu()
	body:Release()
end)

-- Every Font row inside a unit frame part's menu that is not face-only can open its typeface
-- menu over the part's (so this cannot regress silently: the owner's case was one such row).
test('every Font row in a part menu, on every unit, opens its typeface menu over the part menu', function()
	local seen = 0
	for _, unit in ipairs(UNITS) do
		local root = tree()
		local body, by = draw_general(root, unit)
		for key, cell in pairs(by) do
			if cell.row.type == 'item' and cell.widget.isPart then
				check(cell.widget:OpenMenu(), unit .. ' ' .. key .. ': the menu opens')
				local first = OW.GetMenuFrames(1)
				local rows = {}
				for _, c in ipairs(first.body.cells) do
					if c.row.type == 'font' and not c.row.option.faceOnly then rows[#rows + 1] = c.row.path end
				end
				for _, path in ipairs(rows) do
					local font
					for _, c in ipairs(first.body.cells) do
						if c.row.path == path then font = c end
					end
					font.widget:Pick('face:Arial Narrow') -- a typeface, so it has dots with a menu
					for _, c in ipairs(first.body.cells) do
						if c.row.path == path then font = c end
					end
					local where = unit .. ' ' .. key .. ' ' .. tostring(path[#path - 1]) .. ': '
					check(font.widget.kind == 'typeface' and font.widget.dots:IsShown(), where .. 'has its dots')
					font.widget:ToggleMenu()
					check(OW:IsMenuShown(font.widget), where .. 'its typeface menu is shown')
					check(OW.GetMenuFrames(2).frame:IsShown() and first.frame:IsShown(), where .. 'over the part menu')
					OW.GetMenuFrames(2).frame:Hide()
					seen = seen + 1
				end
				OW:CloseMenu()
			end
		end
		body:Release()
	end
	check(seen >= 10, 'font rows checked: ' .. seen)
end)
