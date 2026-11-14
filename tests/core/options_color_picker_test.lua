-- SaftUI-Core/Config/optionscolorpicker.lua: SaftUI's own color picker
-- (W.OpenColorPicker): what it draws, how the square, the strips, the boxes and
-- the chips change the color, live onChange, Okay and Last used, Cancel and
-- everything that cancels, where it opens, and its pixels under each look.
-- The color maths are options_color_math_test.lua's; the color field that opens
-- it is options_fields_test.lua's.
--
-- Real: the widget files, the theme and the picker. The mouse is played with
-- stub.cursor_x/cursor_y, stub.mouse_buttons and the frames' scripts
-- (stub.fire_script), the keyboard by firing OnKeyDown and the boxes' scripts.
-- Not mimicked: the game's draw (a gradient is only remembered), OnUpdate
-- (fired by hand).
local H = load_test_file('core/options_widgets_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local W = st.OptionsWidgets
local M = W.ColorMath
local click, theme = H.click, H.theme

if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

-- A field to open the picker for: a frame on the screen's left.
local function field(x, y)
	local f = CreateFrame('Frame', nil, UIParent)
	f:SetSize(170, 24)
	f:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', x or 100, -(y or 100))
	return f
end

local function reset()
	stub.mouse_buttons = {}
	stub.in_combat = false
	st.config.global.colorPicker.recent = {}
	W.CloseColorPicker()
end

-- Opens the picker on a color, recording what it tells the field.
local function open(fields)
	fields = fields or {}
	local told = { changes = {}, cancelled = 0 }
	local owner = fields.owner or field()
	local spec = {
		r = fields.r or 0.2, g = fields.g or 0.4, b = fields.b or 0.6, a = fields.a or 0.8,
		hasAlpha = fields.hasAlpha ~= false,
		onChange = function(r, g, b, a) told.changes[#told.changes + 1] = { r, g, b, a } end,
		onCancel = function() told.cancelled = told.cancelled + 1 end,
	}
	told.opened = W.OpenColorPicker(owner, spec)
	told.owner = owner
	function told.last() return unpack(told.changes[#told.changes]) end
	return told, W.GetColorPickerFrames()
end

local function bytes(r, g, b) return M.ToByte(r) .. ',' .. M.ToByte(g) .. ',' .. M.ToByte(b) end

-- Puts the cursor at fx, fy (0 to 1) of area's 168 inside square.
local function cursor_at(area, fx, fy)
	local k = area:GetEffectiveScale()
	stub.cursor_x = (area:GetLeft() + 1 + fx * 168) * k
	stub.cursor_y = (area:GetTop() - 1 - fy * 168) * k
end

local function press(area, fx, fy)
	cursor_at(area, fx, fy)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(area, 'OnMouseDown', 'LeftButton')
end

local function release(area)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(area, 'OnMouseUp', 'LeftButton')
end

local function type_into(edit, text)
	edit:SetFocus()
	edit:SetText(text)
	stub.fire_script(edit, 'OnEnterPressed')
end

local function chips_shown(row)
	local out = {}
	for _, chip in ipairs(row.chips) do
		if chip:IsShown() then out[#out + 1] = chip end
	end
	return out
end

------------------------------------------------------------------ opening

test('it opens on the color: title, boxes, the two color blocks, and no change is told', function()
	theme('thick')
	reset()
	local told, F = open()
	check(told.opened, 'opens')
	check(W.ColorPickerShown(), 'shown')
	check(F.frame:IsShown(), 'the panel is shown')
	eq(F.title:GetText(), 'Color', 'its title')
	eq(F.red:GetText(), '51', 'red')
	eq(F.green:GetText(), '102', 'green')
	eq(F.blue:GetText(), '153', 'blue')
	eq(F.opacity:GetText(), '80%', 'opacity, with a percent sign')
	eq(F.hex:GetText(), '#336699', 'hex')
	eq(#told.changes, 0, 'opening is no change')
	eq(stub.state(F.new.color).color_texture[1], 0.2, 'the right block shows the color')
	eq(stub.state(F.was.color).color_texture[1], 0.2, 'the left block shows the color it opened with')
	check(F.new.text == nil and F.was.text == nil, 'no words on the blocks')
	eq(F.red.label:GetText(), 'Red', 'a box is labelled')
	reset()
	check(not W.ColorPickerShown(), 'closed by the reset')
end)

test('it sits above the window, the small dialog and an item menu, and takes the mouse', function()
	reset()
	local _, F = open()
	eq(F.frame:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'strata')
	check(F.frame:GetFrameLevel() > 410, 'over the menu (410), so over the dialog (300) and the window (100)')
	check(F.frame:IsMouseEnabled(), 'it takes the mouse')
	reset()
end)

test('it refuses to open in combat', function()
	reset()
	stub.in_combat = true
	local told = open()
	check(not told.opened, 'false')
	check(not W.ColorPickerShown(), 'not shown')
	stub.in_combat = false
end)

test('it opens right of the field, 8 apart, at its top; left of it near the screen\'s right; up near its bottom', function()
	reset()
	local owner = field(100, 100)
	local _, F = open({ owner = owner })
	local k = owner:GetEffectiveScale() / UIParent:GetEffectiveScale()
	eq(F.frame:GetLeft(), owner:GetRight() * k + 8, 'left 8 past the field\'s right')
	eq(F.frame:GetTop(), owner:GetTop() * k, 'top at the field\'s top')
	reset()
	local far = field(UIParent:GetWidth() - 200, 100)
	_, F = open({ owner = far })
	check(F.frame:GetRight() <= far:GetLeft() * k - 8 + 0.001, 'flipped to the field\'s left')
	check(F.frame:GetRight() <= UIParent:GetWidth(), 'on the screen')
	reset()
	local low = field(100, UIParent:GetHeight() - 60)
	_, F = open({ owner = low })
	check(F.frame:GetBottom() >= -0.001, 'shifted up onto the screen')
	reset()
end)

test('it is a panel of its own size, narrower by the strip and its gap without an opacity', function()
	reset()
	local _, F = open({ hasAlpha = true })
	local wide = F.frame:GetWidth()
	check(F.alpha:IsShown() and F.opacity:IsShown() and F.alphaCaption:IsShown(), 'opacity: strip, box and caption')
	reset()
	_, F = open({ hasAlpha = false })
	eq(wide - F.frame:GetWidth(), 16 + 16, 'narrower by the strip (16) and its gap (16)')
	check(not F.alpha:IsShown(), 'no opacity strip')
	check(not F.opacity:IsShown(), 'no opacity box')
	check(not F.alphaCaption:IsShown(), 'no opacity caption')
	eq(F.frame:GetWidth() % 2, 0, 'an even width')
	eq(F.frame:GetHeight() % 2, 0, 'and height')
	reset()
end)

------------------------------------------------------------------ drawn with gradients

test('the square and the strips are gradient textures', function()
	reset()
	local _, F = open({ r = 1, g = 0, b = 0 })
	local white, black = stub.state(F.white).gradient, stub.state(F.black).gradient
	eq(white.orientation, 'HORIZONTAL', 'white across')
	eq(table.concat(white.min, ','), '1,1,1,1', 'solid white at the left')
	eq(table.concat(white.max, ','), '1,1,1,0', 'clear at the right')
	eq(black.orientation, 'VERTICAL', 'black down')
	eq(table.concat(black.min, ','), '0,0,0,1', 'black at the bottom')
	eq(table.concat(black.max, ','), '0,0,0,0', 'clear at the top')
	eq(table.concat(stub.state(F.base).color_texture, ','), '1,0,0,1', 'the square is the hue under them')
	eq(#F.hueSegments, 6, 'the hue strip is six segments')
	local total, previous = 0, nil
	for i, segment in ipairs(F.hueSegments) do
		local g = stub.state(segment).gradient
		eq(g.orientation, 'VERTICAL', 'segment ' .. i)
		if previous then eq(table.concat(g.max, ','), table.concat(previous.min, ','), 'segment ' .. i .. ' starts where the last ended') end
		previous = g
		total = total + segment:GetHeight()
	end
	eq(total, 168, 'the segments fill the strip')
	eq(table.concat(stub.state(F.hueSegments[1]).gradient.max, ','), '1,0,0,1', 'red at the top')
	eq(table.concat(stub.state(F.hueSegments[6]).gradient.min, ','), '1,0,0,1', 'and red at the bottom')
	local a = stub.state(F.alphaFill).gradient
	eq(a.orientation, 'VERTICAL', 'the opacity strip')
	eq(table.concat(a.max, ','), '1,0,0,1', 'solid at the top, in the color')
	eq(a.min[4], 0, 'clear at the bottom')
	reset()
end)

test('the square takes the hue, and the opacity strip the color, as they change', function()
	reset()
	local told, F = open({ r = 1, g = 0, b = 0 })
	type_into(F.hex, '#0000FF')
	eq(table.concat(stub.state(F.base).color_texture, ','), '0,0,1,1', 'the square: the blue hue')
	local a = stub.state(F.alphaFill).gradient
	eq(table.concat(a.max, ','), '0,0,1,1', 'the opacity strip: the new color')
	reset()
end)

------------------------------------------------------------------ the square and the strips

test('a click in the square sets saturation and brightness, live, keeping the hue', function()
	reset()
	local told, F = open({ r = 1, g = 0, b = 0 })
	press(F.square, 0.5, 0.25)
	release(F.square)
	eq(#told.changes, 1, 'one change')
	local r, g, b, a = told.last()
	-- Saturation 0.5, brightness 0.75 of red.
	check(near(r, 0.75) and near(g, 0.375) and near(b, 0.375), 'red at half saturation, three quarters bright: ' .. r .. ',' .. g .. ',' .. b)
	eq(a, 0.8, 'opacity untouched')
	check(F.squareThumb:GetLeft() ~= nil, 'the thumb is placed')
end)

test('dragging follows the mouse with OnUpdate while the button is down, and stops when it is let go anywhere', function()
	reset()
	local told, F = open({ r = 1, g = 0, b = 0 })
	press(F.square, 0, 0)
	local n = #told.changes
	cursor_at(F.square, 1, 1)
	stub.fire_script(F.square, 'OnUpdate', 0.016)
	eq(#told.changes, n + 1, 'a move is followed')
	local r, g, b = told.last()
	eq(bytes(r, g, b), '0,0,0', 'to the bottom right: black')
	-- The button comes up outside the frame, and no OnMouseUp reaches it.
	stub.mouse_buttons.LeftButton = nil
	cursor_at(F.square, 0.5, 0.5)
	stub.fire_script(F.square, 'OnUpdate', 0.016)
	eq(#told.changes, n + 1, 'a released button is not followed')
	eq(F.square:GetScript('OnUpdate'), nil, 'and the OnUpdate is gone')
	-- Mouse up stops it too.
	press(F.square, 0.1, 0.1)
	release(F.square)
	eq(F.square:GetScript('OnUpdate'), nil, 'mouse up stops it')
	-- And hiding.
	press(F.square, 0.2, 0.2)
	check(F.square:GetScript('OnUpdate') ~= nil, 'following')
	W.CloseColorPicker()
	eq(F.square:GetScript('OnUpdate'), nil, 'hiding stops it')
	reset()
end)

test('the cursor is read through the frame\'s effective scale', function()
	reset()
	local told, F = open({ r = 1, g = 0, b = 0 })
	F.frame:SetScale(2)
	press(F.square, 0.5, 0)
	release(F.square)
	local r, g, b = told.last()
	eq(bytes(r, g, b), '255,128,128', 'half way across the top, at twice the scale')
	press(F.square, 0, 1)
	release(F.square)
	r, g, b = told.last()
	eq(bytes(r, g, b), '0,0,0', 'the bottom left')
	F.frame:SetScale(1)
	reset()
end)

test('the hue strip sets the hue; the hue is kept while the color is grey or black', function()
	reset()
	local told, F = open({ r = 1, g = 0, b = 0 })
	press(F.hue, 0, 0.5)
	release(F.hue)
	local r, g, b = told.last()
	eq(bytes(r, g, b), '0,255,255', 'half way down is cyan')
	-- Drag the shade through the bottom: black, then back up. The hue stays.
	press(F.square, 0.5, 1)
	release(F.square)
	r, g, b = told.last()
	eq(bytes(r, g, b), '0,0,0', 'black')
	press(F.square, 0.5, 0)
	release(F.square)
	r, g, b = told.last()
	eq(bytes(r, g, b), '128,255,255', 'back up: still the same hue')
	-- A typed grey keeps it too.
	local top = F.hueThumb:GetTop()
	type_into(F.hex, '#808080')
	eq(F.hueThumb:GetTop(), top, 'the hue thumb did not jump for a grey')
	press(F.square, 1, 0)
	release(F.square)
	r, g, b = told.last()
	eq(bytes(r, g, b), '0,255,255', 'the shade drag brings the old hue back')
	reset()
end)

test('the opacity strip sets the opacity, solid at the top', function()
	reset()
	local told, F = open({ r = 1, g = 0, b = 0, a = 1 })
	press(F.alpha, 0, 0.25)
	release(F.alpha)
	local r, g, b, a = told.last()
	eq(bytes(r, g, b), '255,0,0', 'the color is kept')
	check(near(a, 0.75), 'a quarter down: 75%')
	eq(F.opacity:GetText(), '75%', 'the box follows')
	press(F.alpha, 0, 1)
	release(F.alpha)
	eq(select(4, told.last()), 0, 'the bottom is clear')
	reset()
end)

test('the thumbs are on whole pixels', function()
	reset()
	local _, F = open({ r = 0.3, g = 0.7, b = 0.2, a = 0.37 })
	for _, thumb in ipairs({ F.squareThumb, F.hueThumb, F.alphaThumb }) do
		eq(#P.off(thumb), 0, 'a thumb: ' .. P.report(P.off(thumb)))
	end
	press(F.square, 0.333, 0.777)
	release(F.square)
	eq(#P.off(F.squareThumb), 0, 'after a drag: ' .. P.report(P.off(F.squareThumb)))
	reset()
end)

------------------------------------------------------------------ the boxes

test('a box takes its value on Enter, held in range; text that is no number puts the old value back', function()
	reset()
	local told, F = open()
	type_into(F.red, '300')
	eq(F.red:GetText(), '255', 'clamped')
	eq(select(1, told.last()), 1, 'told')
	type_into(F.green, '-4')
	eq(F.green:GetText(), '0', 'clamped at zero')
	local n = #told.changes
	type_into(F.blue, 'abc')
	eq(F.blue:GetText(), '153', 'the old value is back')
	eq(#told.changes, n, 'nothing told')
	type_into(F.opacity, '50%')
	eq(F.opacity:GetText(), '50%', 'a percent sign is taken')
	eq(select(4, told.last()), 0.5, 'opacity set')
	type_into(F.opacity, '250')
	eq(F.opacity:GetText(), '100%', 'opacity held at 100')
	reset()
end)

test('a box takes its value when it loses the keyboard, and Esc puts the text back', function()
	reset()
	local told, F = open()
	F.red:SetFocus()
	F.red:SetText('10')
	F.green:SetFocus() -- red loses it
	eq(select(1, told.last()), 10 / 255, 'red taken on losing focus')
	F.green:SetText('77')
	stub.fire_script(F.green, 'OnEscapePressed')
	eq(F.green:GetText(), '102', 'Esc: the old text')
	check(not F.green:HasFocus(), 'and the keyboard let go')
	local n = #told.changes
	eq(select(2, told.last()), 0.4, 'green was not changed')
	reset()
end)

test('a focused box and a lost focus without a change tell nothing, and keep the color exact', function()
	reset()
	local told, F = open({ r = 0.2137, g = 0.4, b = 0.6 })
	F.red:SetFocus()
	F.red:ClearFocus()
	eq(#told.changes, 0, 'nothing told')
	F.hex:SetFocus()
	F.hex:ClearFocus()
	eq(#told.changes, 0, 'nothing told for the hex either')
	reset()
end)

test('Tab moves through the boxes in order, Shift-Tab back, round', function()
	reset()
	local _, F = open()
	F.red:SetFocus()
	local order = { 'green', 'blue', 'opacity', 'hex', 'red' }
	for _, name in ipairs(order) do
		stub.fire_script(GetCurrentKeyBoardFocus(), 'OnTabPressed')
		check(F[name]:HasFocus(), 'Tab to ' .. name)
	end
	stub.shift_down = true
	stub.fire_script(GetCurrentKeyBoardFocus(), 'OnTabPressed')
	stub.shift_down = false
	check(F.hex:HasFocus(), 'Shift-Tab back to hex')
	reset()
	_, F = open({ hasAlpha = false })
	F.blue:SetFocus()
	stub.fire_script(F.blue, 'OnTabPressed')
	check(F.hex:HasFocus(), 'without opacity, Tab skips its box')
	reset()
end)

test('hex: six digits with or without #, eight set the opacity; bad text puts the old one back', function()
	reset()
	local told, F = open({ r = 0, g = 0, b = 0, a = 1 })
	type_into(F.hex, '8F1F1F')
	eq(F.hex:GetText(), '#8F1F1F', 'six digits, no #')
	local r, g, b, a = told.last()
	eq(bytes(r, g, b), '143,31,31', 'the color')
	eq(a, 1, 'opacity untouched')
	type_into(F.hex, '#8F1F1F80')
	r, g, b, a = told.last()
	eq(a, 128 / 255, 'eight digits set the opacity')
	eq(F.opacity:GetText(), '50%', 'and its box')
	eq(F.hex:GetText(), '#8F1F1F', 'the hex box shows six')
	local n = #told.changes
	type_into(F.hex, 'nope')
	eq(F.hex:GetText(), '#8F1F1F', 'bad text: the old code')
	eq(#told.changes, n, 'nothing told')
	reset()
end)

test('without an opacity: no eighth hex pair is taken, and onChange says opacity 1', function()
	reset()
	local told, F = open({ hasAlpha = false, a = 0.3 })
	type_into(F.hex, '#8F1F1F80')
	eq(F.hex:GetText(), '#336699', 'eight digits are refused')
	eq(#told.changes, 0, 'nothing told')
	type_into(F.hex, '#8F1F1F')
	eq(select(4, told.last()), 1, 'opacity is 1')
	reset()
end)

------------------------------------------------------------------ Was and the chips

test('a click on the left block (the opening color) goes back to it', function()
	reset()
	local told, F = open()
	type_into(F.hex, '#FF0000')
	click(F.was)
	local r, g, b, a = told.last()
	eq(r, 0.2, 'r exactly')
	eq(g, 0.4, 'g exactly')
	eq(b, 0.6, 'b exactly')
	eq(a, 0.8, 'a exactly')
	eq(F.hex:GetText(), '#336699', 'the boxes follow')
	check(W.ColorPickerShown(), 'it stays open')
	reset()
end)

-- The classes a client lists, by token, as the chips show them (by tooltip).
local function class_names(F)
	local out = {}
	for _, chip in ipairs(chips_shown(F.classes)) do out[#out + 1] = chip.tip() end
	return out
end

test('class colors: a chip for each class the client has, SaftUI\'s colors, the class name as the tooltip', function()
	reset()
	local _, F = open()
	local chips = chips_shown(F.classes)
	eq(#chips, 9, 'Forever has nine classes')
	local colors = st.config.profile.colors.class
	local seen = {}
	for i, chip in ipairs(chips) do
		local name, token = GetClassInfo(stub.class_ids[i]) -- by class ID, as the game takes it
		local c = stub.state(chip.color).color_texture
		eq(c[1], colors[token].r, name .. ' red')
		eq(c[3], colors[token].b, name .. ' blue')
		stub.fire_script(chip, 'OnEnter', true)
		eq(GameTooltip:GetOwner(), chip, name .. ': the tooltip is the chip\'s')
		eq(stub.state(GameTooltip).texts[1], name, 'the class name')
		stub.fire_script(chip, 'OnLeave', true)
		check(not GameTooltip:IsShown(), 'gone on leaving')
		seen[name] = true
	end
	check(seen['Warrior'] and seen['Druid'] and not seen['Evoker'], 'Druid (ID 11) is there, no Evoker on Forever')
	reset()
	-- A changed class color is the chip's color.
	st.config.profile.colors.class.WARRIOR = CreateColor(0.1, 0.2, 0.3)
	_, F = open()
	eq(stub.state(F.classes.chips[1].color).color_texture[1], 0.1, 'SaftUI\'s Colors page color')
	reset()
end)

test('class colors: retail has no GetAllClassIDs, its IDs are 1 to GetNumClasses', function()
	local real = C_SpecializationInfo.GetAllClassIDs
	C_SpecializationInfo.GetAllClassIDs = nil
	stub.class_ids = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13 }
	reset()
	local _, F = open()
	eq(#chips_shown(F.classes), 13, 'thirteen')
	eq(class_names(F)[13], 'Evoker', 'in ID order')
	-- A gap (an ID the client has no class for) is skipped, not an error.
	stub.class_ids = { 1, 2, 3, 4, 5, 7, 8, 9, 11 }
	_, F = open()
	eq(#chips_shown(F.classes), 8, 'ID 6 gives no class: skipped (Druid, ID 11, is past GetNumClasses)')
	C_SpecializationInfo.GetAllClassIDs = real
	reset()
end)

test('class colors: with GetAllClassIDs the list is the client\'s own IDs, gaps and all', function()
	reset()
	stub.class_ids = { 1, 2, 3, 4, 5, 7, 8, 9, 11 }
	local _, F = open()
	local names = class_names(F)
	eq(table.concat(names, ','), 'Warrior,Paladin,Hunter,Rogue,Priest,Shaman,Mage,Warlock,Druid', 'nine, in ID order')
	reset()
end)

test('a class chip sets the color and keeps the opacity', function()
	reset()
	local told, F = open({ a = 0.5 })
	local chip = chips_shown(F.classes)[1]
	click(chip)
	local r, g, b, a = told.last()
	local warrior = st.config.profile.colors.class.WARRIOR
	eq(r, warrior.r, 'r')
	eq(g, warrior.g, 'g')
	eq(a, 0.5, 'opacity kept')
	reset()
end)

test('the chips take OnEnter and OnLeave with the game\'s motion argument', function()
	reset()
	local _, F = open()
	local chip = chips_shown(F.classes)[1]
	local ok = pcall(stub.fire_script, chip, 'OnEnter', true)
	check(ok, 'OnEnter(self, motion)')
	ok = pcall(stub.fire_script, F.was, 'OnLeave', true)
	check(ok, 'OnLeave(self, motion)')
	reset()
end)

------------------------------------------------------------------ Okay, Last used and Cancel

test('Okay closes it and records the color: newest first, no duplicates, twelve at most, saved account-wide', function()
	reset()
	local told, F = open()
	check(#chips_shown(F.recent) == 0, 'an empty row shows no chips')
	type_into(F.hex, '#FF0000')
	click(F.okay)
	check(not W.ColorPickerShown(), 'closed')
	eq(told.cancelled, 0, 'Okay is no cancel')
	local recent = st.config.global.colorPicker.recent
	eq(#recent, 1, 'recorded')
	eq(M.FormatHex(recent[1].r, recent[1].g, recent[1].b), '#FF0000', 'the color')
	eq(recent[1].a, 0.8, 'with its opacity')
	-- Another, then the first again: it moves to the front.
	told, F = open()
	type_into(F.hex, '#00FF00')
	click(F.okay)
	told, F = open()
	type_into(F.hex, '#FF0000')
	click(F.okay)
	recent = st.config.global.colorPicker.recent
	eq(#recent, 2, 'no duplicate')
	eq(M.FormatHex(recent[1].r, recent[1].g, recent[1].b), '#FF0000', 'moved to the front')
	for i = 1, 14 do
		told, F = open()
		type_into(F.hex, M.FormatHex(i / 255, 0, 0))
		click(F.okay)
	end
	recent = st.config.global.colorPicker.recent
	eq(#recent, 12, 'twelve')
	told, F = open()
	local chips = chips_shown(F.recent)
	eq(#chips, 12, 'twelve chips')
	click(chips[2])
	eq(bytes(told.last()), '13,0,0', 'a chip sets its color (the second newest)')
	reset()
end)

test('Okay takes a box still being typed in', function()
	reset()
	local told, F = open()
	F.red:SetFocus()
	F.red:SetText('255')
	click(F.okay)
	eq(select(1, told.last()), 1, 'told')
	eq(M.ToByte(st.config.global.colorPicker.recent[1].r), 255, 'recorded with it')
end)

test('a recent chip with an opacity sets it, and without an opacity picker it is solid', function()
	reset()
	st.config.global.colorPicker.recent = { { r = 1, g = 0, b = 0, a = 0.5 } }
	local told, F = open()
	local chip = chips_shown(F.recent)[1]
	check(chip.checker ~= nil, 'drawn over a checker')
	click(chip)
	eq(select(4, told.last()), 0.5, 'its opacity')
	stub.fire_script(chip, 'OnEnter', true)
	eq(stub.state(GameTooltip).texts[1], '#FF0000 \194\183 50%', 'the tooltip names it')
	reset()
	st.config.global.colorPicker.recent = { { r = 1, g = 0, b = 0, a = 0.5 } }
	told, F = open({ hasAlpha = false })
	click(chips_shown(F.recent)[1])
	eq(select(4, told.last()), 1, 'no opacity: solid')
	reset()
end)

test('Cancel puts the opening color back through onChange, then onCancel, and records nothing', function()
	reset()
	local order = {}
	local told, F = open()
	local base = told.changes
	type_into(F.hex, '#FF0000')
	click(F.cancel)
	check(not W.ColorPickerShown(), 'closed')
	local r, g, b, a = told.last()
	eq(r, 0.2, 'r exactly')
	eq(g, 0.4, 'g exactly')
	eq(b, 0.6, 'b exactly')
	eq(a, 0.8, 'a exactly')
	eq(told.cancelled, 1, 'onCancel once')
	eq(#st.config.global.colorPicker.recent, 0, 'nothing recorded')
	reset()
end)

test('Esc cancels, unless a box has the keyboard (its own Esc puts its text back first)', function()
	reset()
	local told, F = open()
	local keys = F.keys
	check(keys:IsKeyboardEnabled(), 'the catcher listens while it is open')
	F.red:SetFocus()
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(W.ColorPickerShown(), 'a box has the keyboard: Esc is its')
	eq(keys:GetPropagateKeyboardInput(), true, 'passed on')
	F.red:ClearFocus()
	stub.fire_script(keys, 'OnKeyDown', 'A')
	eq(keys:GetPropagateKeyboardInput(), true, 'other keys go on')
	check(W.ColorPickerShown(), 'still open')
	stub.fire_script(keys, 'OnKeyDown', 'ESCAPE')
	check(not W.ColorPickerShown(), 'Esc cancels')
	eq(keys:GetPropagateKeyboardInput(), false, 'and is kept')
	eq(told.cancelled, 1, 'onCancel')
	check(not keys:IsKeyboardEnabled(), 'the catcher is off once closed')
end)

test('combat cancels it', function()
	reset()
	local told, F = open()
	type_into(F.hex, '#FF0000')
	stub.fire_script(F.frame, 'OnEvent', 'PLAYER_REGEN_DISABLED')
	check(not W.ColorPickerShown(), 'closed')
	eq(told.cancelled, 1, 'cancelled')
	eq(M.ToByte(select(1, told.last())), 51, 'the opening color is back')
end)

test('a field that goes away under it takes it along (the owner hidden)', function()
	reset()
	local told, F = open()
	told.owner:Hide()
	stub.fire_script(F.frame, 'OnUpdate', 0.016)
	check(not W.ColorPickerShown(), 'closed')
	eq(told.cancelled, 1, 'cancelled')
end)

test('W.CloseColorPicker(within) cancels only a picker whose owner is inside', function()
	reset()
	local holder = CreateFrame('Frame', nil, UIParent)
	local inner = CreateFrame('Frame', nil, holder)
	inner:SetSize(100, 24)
	inner:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	local told = open({ owner = inner })
	W.CloseColorPicker(CreateFrame('Frame', nil, UIParent))
	check(W.ColorPickerShown(), 'another frame: stays')
	W.CloseColorPicker(holder)
	check(not W.ColorPickerShown(), 'its holder: cancelled')
	eq(told.cancelled, 1, 'onCancel')
end)

test('opening for another field accepts the first (as Okay) and opens on the second', function()
	reset()
	local first, F = open()
	type_into(F.hex, '#FF0000')
	local second = open({ owner = field(100, 300), r = 0, g = 1, b = 0, a = 1 })
	check(W.ColorPickerShown(), 'open')
	eq(first.cancelled, 0, 'the first is not cancelled')
	local recent = st.config.global.colorPicker.recent
	eq(#recent, 1, 'the first\'s color is remembered')
	eq(M.FormatHex(recent[1].r, recent[1].g, recent[1].b), '#FF0000', 'as chosen')
	eq(F.hex:GetText(), '#00FF00', 'the picker shows the second\'s color')
	eq(#second.changes, 0, 'no change told to the second')
	type_into(F.hex, '#0000FF')
	eq(#first.changes, 1, 'the first hears nothing more')
	reset()
	eq(second.cancelled, 1, 'the second cancels')
end)

------------------------------------------------------------------ the window around it

test('Blizzard\'s ColorPickerFrame is never read by the Config files', function()
	local files = {}
	for _, path in ipairs(options_widget_files()) do files[#files + 1] = path end
	for _, path in ipairs(options_window_files()) do files[#files + 1] = path end
	for _, path in ipairs(files) do
		-- The code, not the comments that say what it replaced.
		local source = read_saftui_source(path)
		source = source:gsub('%-%-%[%[.-%]%]', ''):gsub('%-%-[^\n]*', '')
		check(not source:find('%f[%w_]ColorPickerFrame%f[^%w_]'), path .. ' reads ColorPickerFrame')
	end
end)

------------------------------------------------------------------ pixels

test('every part is on whole pixels, under each look, with sizes read back a hair off', function()
	local HAIR = 2 ^ -14
	local sizes = {}
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			for _, hasAlpha in ipairs({ true, false }) do
				stub.size_noise = noise
				theme(look)
				reset()
				local where = look .. ' noise ' .. noise .. (hasAlpha and ' alpha' or ' opaque') .. ': '
				st.config.global.colorPicker.recent = { { r = 1, g = 0, b = 0, a = 0.5 }, { r = 0, g = 1, b = 0, a = 1 } }
				local _, F = open({ hasAlpha = hasAlpha, r = 0.31, g = 0.62, b = 0.13, a = 0.47 })
				local off = P.off(F.frame)
				eq(#off, 0, where .. P.report(off))
				press(F.square, 0.37, 0.61)
				release(F.square)
				press(F.hue, 0, 0.77)
				release(F.hue)
				off = P.off(F.frame)
				eq(#off, 0, where .. 'after a drag: ' .. P.report(off))
				local left = F.frame:GetLeft()
				check(left == math.floor(left), where .. 'placed on a whole unit')
				check(F.frame:GetTop() == math.floor(F.frame:GetTop()), where .. 'top on a whole unit')
				reset()
			end
		end
	end
	stub.size_noise = 0
	theme('thick')
end)

test('the title, captions and chips: Class colors and Last used, Shade, Hue and Opacity', function()
	reset()
	local _, F = open()
	eq(F.shadeCaption:GetText(), 'Shade', 'Shade')
	eq(F.hueCaption:GetText(), 'Hue', 'Hue')
	eq(F.alphaCaption:GetText(), 'Opacity', 'Opacity')
	eq(F.classCaption:GetText(), 'Class colors', 'Class colors')
	eq(F.recentCaption:GetText(), 'Last used', 'Last used')
	local r, g, b = st.config.profile.colors.text.grey:GetRGB()
	local cr, cg, cb = F.shadeCaption:GetTextColor()
	eq(cr, r, 'captions are Text > Grey')
	reset()
end)

------------------------------------------------------------------ fix round 1

test('the two blocks are equal and even, a chevron-right centred in the gap between them, the column 152', function()
	reset()
	for _, hasAlpha in ipairs({ true, false }) do
		local _, F = open({ hasAlpha = hasAlpha })
		local where = hasAlpha and 'alpha: ' or 'opaque: '
		eq(F.new:GetWidth(), F.was:GetWidth(), where .. 'equal')
		eq(F.new:GetWidth() % 2, 0, where .. 'even')
		eq(F.new:GetWidth(), 64, where .. '64 wide')
		local gap = F.new:GetLeft() - (F.was:GetLeft() + F.was:GetWidth())
		eq(gap, 24, where .. 'the gap between them')
		eq(F.new:GetLeft() + F.new:GetWidth() - F.was:GetLeft(), 152, where .. 'the column stays 152')
		eq(F.was:GetHeight(), 26, where .. 'height kept')
		eq(F.new:GetHeight(), 26, where .. 'height kept')
		eq(F.frame:GetWidth() % 2, 0, where .. 'the panel is even')
		local arrow = F.arrow
		eq(stub.state(arrow).texture, st.icons.chevronRight, where .. 'a chevron-right')
		eq(arrow:GetWidth(), 16, where .. 'the size the kit draws that chevron')
		eq(arrow:GetHeight(), 16, where .. 'square')
		local before = arrow:GetLeft() - (F.was:GetLeft() + F.was:GetWidth())
		local after = F.new:GetLeft() - (arrow:GetLeft() + arrow:GetWidth())
		eq(before, after, where .. 'centred in the gap')
		check(before >= 2, where .. 'room either side')
		local tr, tg, tb = st.config.profile.colors.text.grey:GetRGB()
		local vr, vg, vb = arrow:GetVertexColor()
		eq(vr .. ',' .. vg .. ',' .. vb, tr .. ',' .. tg .. ',' .. tb, where .. 'Text > Grey')
		eq((F.was:GetHeight() - arrow:GetHeight()) % 2, 0, where .. 'centred on the blocks')
		eq(arrow:GetTop() - F.was:GetTop(), -(F.was:GetHeight() - arrow:GetHeight()) / 2, where .. 'vertically centred')
	end
	reset()
end)

test('the opening color is at the left and the chosen at the right, following a drag', function()
	reset()
	local _, F = open({ r = 0.2, g = 0.4, b = 0.6, a = 1 })
	check(F.was:GetLeft() < F.new:GetLeft(), 'the opening color is left of the chosen')
	press(F.square, 0.9, 0.1)
	release(F.square)
	check(stub.state(F.new.color).color_texture[1] ~= 0.2 or stub.state(F.new.color).color_texture[3] ~= 0.6, 'the right block follows the drag')
	eq(stub.state(F.was.color).color_texture[1], 0.2, 'the left block stays at the opening color')
	eq(stub.state(F.was.color).color_texture[3], 0.6, 'the left block stays at the opening color')
	reset()
end)

test('the two blocks have tooltips: Current and New', function()
	reset()
	local _, F = open()
	stub.fire_script(F.was, 'OnEnter', true)
	eq(GameTooltip:GetOwner(), F.was, 'the left block owns it')
	eq(stub.state(GameTooltip).texts[1], 'Current', 'title')
	eq(stub.state(GameTooltip).texts[2], 'The color it opened with. Click to go back to it.', 'line')
	stub.fire_script(F.was, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'gone on leaving')
	stub.fire_script(F.new, 'OnEnter', true)
	eq(GameTooltip:GetOwner(), F.new, 'the right block owns it')
	eq(stub.state(GameTooltip).texts[1], 'New', 'title')
	eq(stub.state(GameTooltip).texts[2], 'The color being chosen.', 'line')
	stub.fire_script(F.new, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'gone on leaving')
	reset()
end)

test('the opacity strip, the blocks and the chips use the kit\'s checker: its 4px squares and greys', function()
	reset()
	st.config.global.colorPicker.recent = { { r = 1, g = 0, b = 0, a = 0.5 } }
	local _, F = open({ a = 0.5 })
	local function check_checker(owner, name)
		local c = owner.checker
		check(c and #c.squares > 0, name .. ' has a checker')
		for i, square in ipairs(c.squares) do
			if i <= 3 then
				check(square:GetWidth() <= W.Kit.CHECKER and square:GetHeight() <= W.Kit.CHECKER, name .. ' square ' .. i .. ' no bigger than the kit\'s')
			end
		end
		eq(c.squares[1]:GetWidth(), W.Kit.CHECKER, name .. ': the kit\'s square size')
		eq(table.concat(stub.state(c.back).color_texture, ','), table.concat(W.Kit.CHECKER_DARK, ','), name .. ': the kit\'s dark grey')
		eq(table.concat(stub.state(c.squares[1]).color_texture, ','), table.concat(W.Kit.CHECKER_LIGHT, ','), name .. ': the kit\'s light grey')
	end
	check_checker(F.alpha, 'the opacity strip')
	check_checker(F.new, 'the chosen block')
	check_checker(F.recent.chips[1], 'a chip')
	reset()
end)

test('Cancel restores first, then calls onCancel', function()
	reset()
	local order = {}
	local owner = field()
	W.OpenColorPicker(owner, { r = 0.2, g = 0.4, b = 0.6, a = 1, hasAlpha = true,
		onChange = function() order[#order + 1] = 'change' end,
		onCancel = function() order[#order + 1] = 'cancel' end })
	type_into(W.GetColorPickerFrames().hex, '#FF0000')
	order = {}
	click(W.GetColorPickerFrames().cancel)
	eq(table.concat(order, ','), 'change,cancel', 'the restore, then onCancel')
	reset()
end)

test('the hue strip is red at the top and runs down through yellow (not upside down)', function()
	reset()
	local told, F = open({ r = 1, g = 0, b = 0 })
	press(F.hue, 0, 1 / 6)
	release(F.hue)
	local r, g, b = told.last()
	eq(bytes(r, g, b), '255,255,0', 'a sixth down is yellow')
	press(F.hue, 0, 5 / 6)
	release(F.hue)
	r, g, b = told.last()
	eq(bytes(r, g, b), '255,0,255', 'five sixths down is magenta')
	reset()
end)

test('the opening block goes back to the opening opacity too', function()
	reset()
	local told, F = open({ a = 0.8 })
	type_into(F.opacity, '10')
	check(select(4, told.last()) < 0.2, 'opacity changed')
	click(F.was)
	eq(select(4, told.last()), 0.8, 'the opening opacity is back')
	eq(F.opacity:GetText(), '80%', 'and its box')
	reset()
end)

test('a color is handed back bit-exact: typing one channel leaves the other two as they were', function()
	reset()
	local told, F = open({ r = 0.2137, g = 0.8412, b = 0.4421 })
	type_into(F.green, '10')
	local r, g, b = told.last()
	eq(r, 0.2137, 'red exactly')
	eq(b, 0.4421, 'blue exactly')
	eq(g, 10 / 255, 'green as typed')
	reset()
end)

test('the PLAYER_REGEN_DISABLED event is registered on the panel', function()
	reset()
	local _, F = open()
	check(stub.state(F.frame).events and stub.state(F.frame).events.PLAYER_REGEN_DISABLED, 'registered')
	reset()
end)

test('a drag takes a box\'s typed text first, so it cannot override the drag later', function()
	reset()
	local told, F = open()
	F.red:SetFocus()
	F.red:SetText('255')
	press(F.square, 0.5, 0.5)
	release(F.square)
	check(not F.red:HasFocus(), 'the box let go')
	local r = told.last()
	check(r < 1, 'the dragged color kept')
	reset()
end)

test('a number box lights its edge under the mouse, as the kit\'s input does', function()
	reset()
	local _, F = open()
	stub.fire_script(F.red, 'OnEnter', true)
	local blue = W.Kit.Colors().button.blue
	local r = F.red:GetBackdropBorderColor()
	eq(r, blue.r, 'blue edge')
	stub.fire_script(F.red, 'OnLeave', true)
	reset()
end)

test('an onChange that errors does not stop Cancel from calling onCancel', function()
	reset()
	local cancelled = false
	W.OpenColorPicker(field(), { r = 0.2, g = 0.4, b = 0.6, a = 1, hasAlpha = false,
		onChange = function() error('boom') end, onCancel = function() cancelled = true end })
	click(W.GetColorPickerFrames().cancel)
	check(cancelled, 'onCancel ran')
	take_errors()
end)

------------------------------------------------------------------ moving it

-- Whether the picker is being moved by the mouse (StartMoving, no StopMovingOrSizing since).
local function moving(frame) return stub.state(frame).moving == true end

-- Where the game leaves a frame a drag ended: a corner anchor on a fraction.
local function dropped(frame, x, y)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', x, y)
end

test('its title strip drags it: the top strip of the panel, clear of every control', function()
	reset()
	local _, F = open()
	local drag = F.drag
	check(drag ~= nil, 'a drag strip')
	check(F.frame:IsMovable(), 'the panel is movable')
	check(F.frame:IsClampedToScreen(), 'and kept on the screen')
	check(drag:IsMouseEnabled(), 'the strip takes the mouse')
	eq(drag:GetParent(), F.frame, "a child of the panel, so it isn't a click outside anything")
	eq(drag:GetTop(), F.frame:GetTop(), "at the panel's top")
	eq(drag:GetLeft(), F.frame:GetLeft(), "from the panel's left")
	eq(drag:GetRight(), F.frame:GetRight(), "to the panel's right")
	-- It overlaps no control that has a drag or a click of its own.
	for _, key in ipairs({ 'square', 'hue', 'alpha', 'was', 'new', 'red', 'hex', 'okay', 'cancel' }) do
		check(F[key]:GetTop() <= drag:GetBottom(), 'the strip ends above the ' .. key)
	end
	reset()
end)

test('a drag on the title strip moves the panel and does nothing else: no commit, no cancel, no change', function()
	reset()
	local told, F = open()
	local changes = #told.changes
	stub.fire_script(F.drag, 'OnMouseDown', 'LeftButton')
	check(moving(F.frame), 'moving')
	check(W.ColorPickerShown(), 'still open')
	stub.fire_script(F.drag, 'OnMouseUp', 'LeftButton')
	check(not moving(F.frame), 'let go: stopped')
	check(W.ColorPickerShown(), 'still open')
	eq(told.cancelled, 0, 'not cancelled')
	eq(#told.changes, changes, 'no change told to the field')
	eq(#st.config.global.colorPicker.recent, 0, 'nothing remembered: not an Okay')
	stub.fire_script(F.drag, 'OnMouseDown', 'RightButton')
	check(not moving(F.frame), 'only the left button drags')
	reset()
end)

test('the drop is rounded to whole units, and the panel stays there while it is open', function()
	reset()
	local _, F = open()
	stub.fire_script(F.drag, 'OnMouseDown', 'LeftButton')
	dropped(F.frame, 412.37, 655.81)
	stub.fire_script(F.drag, 'OnMouseUp', 'LeftButton')
	eq(F.frame:GetLeft(), 412, 'left rounded')
	eq(F.frame:GetTop(), 656, 'top rounded')
	eq(#P.off(F.frame), 0, 'every part on whole pixels after it: ' .. P.report(P.off(F.frame)))
	-- A box typed in, the square dragged: it doesn't go back.
	press(F.square, 0.5, 0.5)
	release(F.square)
	type_into(F.red, '200')
	eq(F.frame:GetLeft(), 412, 'a change of color leaves it where it was dropped')
	reset()
end)

test('closing it forgets the place: the next open is beside its field again', function()
	reset()
	local owner = field(100, 100)
	local _, F = open({ owner = owner })
	local left, top = F.frame:GetLeft(), F.frame:GetTop()
	stub.fire_script(F.drag, 'OnMouseDown', 'LeftButton')
	dropped(F.frame, 700.4, 500.6)
	stub.fire_script(F.drag, 'OnMouseUp', 'LeftButton')
	click(F.okay)
	check(not W.ColorPickerShown(), 'closed')
	_, F = open({ owner = owner })
	eq(F.frame:GetLeft(), left, 'beside the field again: left')
	eq(F.frame:GetTop(), top, 'and top')
	-- Cancel forgets it too.
	stub.fire_script(F.drag, 'OnMouseDown', 'LeftButton')
	dropped(F.frame, 300, 300)
	stub.fire_script(F.drag, 'OnMouseUp', 'LeftButton')
	click(F.cancel)
	_, F = open({ owner = owner })
	eq(F.frame:GetLeft(), left, 'after Cancel: beside the field')
	reset()
end)

test('the panel closing in a drag stops the move', function()
	reset()
	local _, F = open()
	stub.fire_script(F.drag, 'OnMouseDown', 'LeftButton')
	check(moving(F.frame), 'moving')
	click(F.cancel)
	check(not moving(F.frame), 'hiding it stopped the move')
	reset()
end)

test("pressing the square or a strip drags the color, not the panel; the title strip doesn't touch the color", function()
	reset()
	local told, F = open()
	for _, area in ipairs({ F.square, F.hue, F.alpha }) do
		press(area, 0.5, 0.5)
		check(not moving(F.frame), 'the panel is not moved by a press on a control')
		release(area)
	end
	local count = #told.changes
	stub.fire_script(F.drag, 'OnMouseDown', 'LeftButton')
	stub.fire_script(F.drag, 'OnMouseUp', 'LeftButton')
	eq(#told.changes, count, 'a drag of the panel changes no color')
	reset()
end)

test('a missed mouse up still ends the move: the strip stops it when the button is up', function()
	reset()
	local _, F = open()
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(F.drag, 'OnMouseDown', 'LeftButton')
	stub.fire_script(F.drag, 'OnUpdate', 0.016)
	check(moving(F.frame), 'button down: moving')
	dropped(F.frame, 300.4, 400.6)
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(F.drag, 'OnUpdate', 0.016)
	check(not moving(F.frame), 'button up: stopped')
	eq(F.frame:GetLeft(), 300, 'and dropped on whole units')
	reset()
end)
