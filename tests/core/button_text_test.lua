-- Kinds of text (Global settings > Fonts) says what each row changes, and does it:
--   - Button text (profile buttons.font) is the label of every SaftUI button made
--     by st:CreateButton and every button st:SkinButton skins with no font of
--     its own: its text, and the button's own normal, highlight and disabled
--     font objects, follow a change at once, a shared font or a typeface.
--   - Check box labels (profile panels.font) is the label of every check box
--     st:SkinCheckButton skins, until a caller puts a font on it. The bags' Edit
--     toggle is the one check box with a label; it puts none of its own.
--   - Neither row reaches the other's widgets, nor the totem bar's timers
--     (tests/misc/totem_timer_font_test.lua).
--
-- Every case sets a font that is not the default, so a hard-coded Pixel fails.
-- Real: Core's widgets (Widgets/button.lua, checkbutton.lua), the fonts and
-- the Fonts tab's rows on a real AceDB profile.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Widgets/checkbutton.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
local OM = st.OptionsModel
local FN = st:GetModule('Fonts')

local function Kinds() return st.Config:GetOptionsTable().Fonts.args.fonts.args.kinds end

local TYPEFACE = { font_name = 'Homespun', font_size = 13, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }

local function ButtonText(value)
	st.config.profile.buttons.font = value
	st:FontsChanged()
end

local function CheckLabels(value)
	st.config.profile.panels.font = value
	st:FontsChanged()
end

local function Fresh()
	ButtonText('pixel')
	CheckLabels('normal')
end

-- What a button draws its label in: its text, then its three state objects.
local function Drawn(button)
	return button.text:GetFontObject(), button:GetNormalFontObject(), button:GetHighlightFontObject(), button:GetDisabledFontObject()
end

local function AllOn(button, object, label)
	local text, normal, highlight, disabled = Drawn(button)
	check(text == object, label .. ': the label')
	check(normal == object, label .. ': the normal font object')
	check(highlight == object, label .. ': the highlight font object')
	check(disabled == object, label .. ': the disabled font object')
end

test('st:CreateButton draws its label in Button text and follows a change at once', function()
	Fresh()
	local button = st:CreateButton('ButtonTextA', UIParent, 'Go', 'theme', 'solid')
	AllOn(button, st:GetFont('pixel'), 'at the default')

	ButtonText('heading')
	AllOn(button, st:GetFont('heading'), 'on Heading')
	ButtonText('pixel_med')
	AllOn(button, st:GetFont('pixel_med'), 'on Large numbers')
	ButtonText(TYPEFACE)
	AllOn(button, st:FontObject(TYPEFACE), 'on a typeface')
	ButtonText('pixel')
	AllOn(button, st:GetFont('pixel'), 'back at the default')
	eq(#take_errors(), 0, 'no errors')
end)

test('a button made after Button text was changed starts in it', function()
	Fresh()
	ButtonText('subtitle')
	local button = st:CreateButton('ButtonTextB', UIParent, 'Go', 'theme', 'solid')
	AllOn(button, st:GetFont('subtitle'), 'made on Subtitle')
	ButtonText('pixel')
end)

test('a button the caller gives a font keeps it through a Button text change', function()
	Fresh()
	local button = st:CreateButton('ButtonTextC', UIParent, 'Go', 'none', 'theme', 'normal')
	AllOn(button, st:GetFont('normal'), 'given Text')
	ButtonText('heading')
	AllOn(button, st:GetFont('normal'), 'after Button text moved')
	ButtonText('pixel')
end)

test('st:SkinButton on a button of Blizzard\'s follows Button text, with its own label too', function()
	Fresh()
	local button = CreateFrame('Button', 'ButtonTextSkinned', UIParent)
	local label = button:CreateFontString(nil, 'ARTWORK')
	st:SkinButton(button, 'theme', 'solid')
	local _, normal = Drawn({ text = label, GetNormalFontObject = function() return button:GetNormalFontObject() end,
		GetHighlightFontObject = function() return button:GetHighlightFontObject() end,
		GetDisabledFontObject = function() return button:GetDisabledFontObject() end })
	check(normal == st:GetFont('pixel'), 'at the default')

	ButtonText('heading')
	check(button:GetNormalFontObject() == st:GetFont('heading'), 'normal follows')
	check(button:GetHighlightFontObject() == st:GetFont('heading'), 'highlight follows')
	check(button:GetDisabledFontObject() == st:GetFont('heading'), 'disabled follows')
	ButtonText(TYPEFACE)
	check(button:GetNormalFontObject() == st:FontObject(TYPEFACE), 'a typeface reaches the state fonts too')

	-- With a font of its own it follows nothing.
	local own = CreateFrame('Button', 'ButtonTextOwn', UIParent)
	st:SkinButton(own, 'theme', 'solid', 'normal')
	ButtonText('subtitle')
	check(own:GetNormalFontObject() == st:GetFont('normal'), 'a skin with a font of its own is left alone')
	ButtonText('pixel')
end)

test('st:SkinButton on a plain frame follows Button text through its label regions', function()
	Fresh()
	local frame = CreateFrame('Frame', 'ButtonTextPlain', UIParent)
	frame.SetNormalFontObject = nil
	local label = frame:CreateFontString(nil, 'ARTWORK')
	st:SkinButton(frame, 'theme', 'solid')
	check(label:GetFontObject() == st:GetFont('pixel'), 'at the default')
	ButtonText('heading')
	check(label:GetFontObject() == st:GetFont('heading'), 'a Button text change reaches it')
	ButtonText('pixel')
end)

test('the shipped Button text draws what the buttons drew before: Small text', function()
	Fresh()
	eq(st.config.profile.buttons.font, 'pixel', 'the default is Small text')
	local button = st:CreateButton('ButtonTextD', UIParent, 'Go', 'theme', 'solid')
	local obj = button.text:GetFontObject()
	local path, size, flags = obj:GetFont()
	local want = st:FontValues('pixel')
	local _, wantSize, wantFlags = st:FontValues('pixel')
	eq(size, wantSize, 'size')
	eq(flags, wantFlags, 'outline')
	local x, y = obj:GetShadowOffset()
	eq(x .. ',' .. y, '0,0', 'no shadow')
	check(path == want, 'face')
end)

test('Button text does not reach a check box, and Check box labels not a button', function()
	Fresh()
	local button = st:CreateButton('ButtonTextE', UIParent, 'Go', 'theme', 'solid')
	local box = CreateFrame('CheckButton', 'ButtonTextBox', UIParent)
	box.Text = box:CreateFontString(nil, 'ARTWORK')
	st:SkinCheckButton(box)
	check(box.text:GetFontObject() == st:GetFont('normal'), 'a label starts in Check box labels')

	ButtonText('heading')
	check(box.text:GetFontObject() == st:GetFont('normal'), 'Button text leaves the label')
	CheckLabels('subtitle')
	check(box.text:GetFontObject() == st:GetFont('subtitle'), 'Check box labels reach the label')
	AllOn(button, st:GetFont('heading'), 'and leave the button')
	CheckLabels(TYPEFACE)
	check(box.text:GetFontObject() == st:FontObject(TYPEFACE), 'a typeface reaches the label')
	Fresh()
end)

test("a check box label the caller sets a font on follows no more; the bags' Edit toggle sets none", function()
	Fresh()
	local box = CreateFrame('CheckButton', 'ButtonTextBox2', UIParent)
	box.Text = box:CreateFontString(nil, 'ARTWORK')
	st:SkinCheckButton(box)
	box:SetTextFont('heading')
	CheckLabels('subtitle')
	check(box.text:GetFontObject() == st:GetFont('heading'), 'its own font stays')
	Fresh()

	local source = read_saftui_source('SaftUI-Bags/header.lua')
	check(source ~= nil, 'the bags header is there')
	local code = select(1, load_test_file('lib/source_lex.lua').Lex(source))
	check(not code:find('SetTextFont', 1, true), "the Edit toggle's label is left to Check box labels")
end)

test('the Kinds of text rows say what they change', function()
	local button, check_labels = Kinds().args.button_text, Kinds().args.checkbox_labels
	check(button.desc:find('and its totem timers', 1, true) == nil, "Button text no longer claims the totem bar's timers: " .. button.desc)
	check(button.desc:find('own on the Totem bar', 1, true), 'it says where the timers went: ' .. button.desc)
	check(button.desc:find('Bag Slots', 1, true) and button.desc:find('Done', 1, true), 'it names the buttons: ' .. button.desc)
	check(button.desc:find('totem', 1, true), "and the totem bar's key bindings, counts and names: " .. button.desc)
	check(check_labels.desc:find('Edit', 1, true), "Check box labels names the one label there is: " .. check_labels.desc)
end)

test('every SaftUI button is made by Core, so no module hard-codes Small text on one', function()
	-- A hard-coded Pixel on a button's label would not follow Button text. The
	-- Core widget takes it from the profile (a given font: the clock's, which the
	-- micro menu keeps in Small text).
	local source = read_saftui_source('SaftUI-Core/Widgets/button.lua')
	local code = select(1, load_test_file('lib/source_lex.lua').Lex(source))
	check(not code:find("font or 'pixel'", 1, true), "st:SkinButton has no hard-coded 'pixel' left")
	check(not code:find("CreateFontString(button, 'pixel'", 1, true), "st:CreateButton's label has none either")
end)

test("the micro menu's clock keeps Small text: it is given the font, since the bar sets it on every layout", function()
	local code = select(1, load_test_file('lib/source_lex.lua').Lex(read_saftui_source('SaftUI-Minimap/clockbutton.lua')))
	check(code:find("st:CreateButton%('ClockButton', UIParent, nil, 'none', 'theme', 'pixel'%)"), 'a font of its own')
end)
