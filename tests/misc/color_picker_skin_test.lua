-- The color picker skin (SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua):
--   - with Skinning -> Color picker on: SaftUI's panel behind ColorPickerFrame in
--     the Skinning look (following the frame's width, which Blizzard changes with
--     the alpha slider), Blizzard's border and the header's metal faded, the
--     title in the Skinning font; the Okay and Cancel buttons' art faded, a box
--     of SaftUI's drawn as a control and a hover; the hex box's border faded and
--     a backdrop of SaftUI's drawn as a control, with a white border while it has
--     focus; the texts in the Skinning font;
--   - the wheel, the sliders, the swatches and the checkerboard left alone;
--   - off, or under the Blizzard theme, nothing touched; the theme switch and the
--     toggle going both ways live, Blizzard's fonts and art coming back;
--   - nothing written onto Blizzard's tables (the key lists before and after are
--     the same, and every frame and region is locked: lib/locked_widget.lua),
--     no script replaced, none of Blizzard's functions run from SaftUI's code, and
--     the picker's behaviour (what an addon sets in it, the buttons' clicks)
--     unchanged;
--   - a part a client lacks skipping its step with no error;
--   - styled in combat with nothing blocked; the addon loading after SaftUI.
-- On both clients: the picker is the same on each.
--
-- Real: SaftUI-Misc's config.lua, Skinning/skinning.lua and
-- Skinning/blizzard/Blizzard_ColorPicker.lua, Core's helpers and the theme engine.
-- Blizzard's picker is fixtures/color_picker.lua.
local T = load_test_file('lib/theme_helpers.lua')

local st, drawn, CP, SK, skin, profile

local blizzard -- Blizzard's frames and regions, as a set
local built -- their key lists as built, before any skin

local function key_lists_of(widgets)
	local out = {}
	for _, widget in ipairs(widgets) do out[widget] = CP.keys(widget) end
	return out
end

-- A fresh world on client: the skin loaded, the picker built before SaftUI's
-- modules are enabled (as the game loads Blizzard's addon first) unless
-- opts.late, the toggle off with opts.off. Then Skinning and its skins are
-- enabled, as at login.
local function world(client, opts)
	opts = opts or {}
	st = T.client(client)
	-- The stubs' own bare ColorPickerFrame (tests/wow/blizzard.lua) is gone: the
	-- fixture builds Blizzard's, or, with opts.late, the game hasn't yet.
	_G.ColorPickerFrame = nil
	drawn = T.watch()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.off then profile.skinning.color_picker = false end
	if opts.theme then profile.skinning.theme = opts.theme end
	if opts.late then stub.installed_addons.Blizzard_ColorPickerFrame = true end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ColorPicker.lua')
	SK = st:GetModule('Skinning')
	skin = SK:GetModule('Blizzard_ColorPicker')
	CP = load_test_file('misc/fixtures/color_picker.lua')
	if not opts.late then CP.build(opts.build) end
	blizzard = {}
	for _, widget in ipairs(CP.widgets or {}) do blizzard[widget] = true end
	built = CP.widgets and key_lists_of(CP.widgets)
	SK:Enable()
end

-- st:ThemeChanged's steps, as Config:UpdateConfig runs them.
local function switch(name)
	T.theme(name, function()
		SK:UpdateConfig()
		st:ColorsChanged('theme')
	end)
end

local function own_children(frame)
	local out = {}
	for _, child in ipairs({ frame:GetChildren() }) do
		if not blizzard[child] then out[#out + 1] = child end
	end
	return out
end

local function own_regions(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if not blizzard[region] then out[#out + 1] = region end
	end
	return out
end

local function the_one(list, what)
	eq(#list, 1, what)
	return list[1]
end

-- No error, and none of the picker's own functions run from SaftUI's code
-- (.agents/taint.md rule 3).
local function clean()
	eq(#take_errors(), 0, 'no errors')
	eq(table.concat(CP.stray, ','), '', 'SaftUI ran none of the .agents/taint.md rule 3 functions')
end

local function fonts()
	local frame = CP.frame
	return {
		title = frame.Header.Text:GetFontObject(),
		okay = frame.Footer.OkayButton:GetNormalFontObject(),
		okay_hover = frame.Footer.OkayButton:GetHighlightFontObject(),
		cancel_disabled = frame.Footer.CancelButton:GetDisabledFontObject(),
		hex = frame.Content.HexBox:GetFontObject(),
		instructions = frame.Content.HexBox.Instructions:GetFontObject(),
		hash = frame.Content.HexBox.Hash:GetFontObject(),
	}
end

------------------------------------------------------------------ checks

local ALPHA_PARTS = {
	{ 'Border' },
	{ 'Header', 'LeftBG' }, { 'Header', 'RightBG' }, { 'Header', 'CenterBG' },
	{ 'Footer', 'OkayButton', 'Left' }, { 'Footer', 'OkayButton', 'Middle' }, { 'Footer', 'OkayButton', 'Right' },
	{ 'Footer', 'CancelButton', 'Left' }, { 'Footer', 'CancelButton', 'Middle' }, { 'Footer', 'CancelButton', 'Right' },
	{ 'Content', 'HexBox', 'Left' }, { 'Content', 'HexBox', 'Middle' }, { 'Content', 'HexBox', 'Right' },
}

local function part(path)
	local widget = CP.frame
	for _, key in ipairs(path) do widget = widget[key] end
	return widget
end

-- Blizzard's art as the template draws it: nothing faded, nothing of SaftUI's
-- on the picker, Blizzard's fonts.
local function check_blizzard(where)
	for _, path in ipairs(ALPHA_PARTS) do
		eq(part(path):GetAlpha(), 1, where .. ': ' .. table.concat(path, '.') .. ' as Blizzard draws it')
	end
	for _, button in ipairs({ CP.frame.Footer.OkayButton, CP.frame.Footer.CancelButton }) do
		eq(button:GetHighlightTexture():GetAlpha(), 1, where .. ": the button's highlight as Blizzard draws it")
		for _, box in ipairs(own_children(button)) do check(not box:IsShown(), where .. ": SaftUI's box hidden") end
		for _, region in ipairs(own_regions(button)) do check(not region:IsShown(), where .. ": SaftUI's hover hidden") end
	end
	local f = fonts()
	eq(f.title, GameFontNormal, where .. ': the title in Blizzard\'s font')
	eq(f.okay, GameFontNormalOutline, where .. ': the Okay text in Blizzard\'s font')
	eq(f.okay_hover, GameFontHighlightOutline, where .. ': and its highlight font')
	eq(f.cancel_disabled, GameFontDisable, where .. ': and the disabled font')
	eq(f.hex, GameFontHighlightSmall, where .. ': the hex box text')
	eq(f.instructions, GameFontDisableSmall, where .. ': its instructions')
	eq(f.hash, GameFontNormalLarge, where .. ': the "#"')
	for _, child in ipairs(own_children(CP.frame)) do check(not child:IsShown(), where .. ': no panel shows') end
	for _, child in ipairs(own_children(CP.frame.Content.HexBox)) do
		check(not child:IsShown(), where .. ': no hex box backdrop shows')
	end
end

local function panel_of(frame)
	return the_one(own_children(frame), 'one frame of SaftUI\'s on the picker: its panel')
end

local function check_skinned(where)
	local frame = CP.frame
	local font = st:GetFont(profile.skinning.font)
	for _, path in ipairs(ALPHA_PARTS) do
		eq(part(path):GetAlpha(), 0, where .. ': ' .. table.concat(path, '.') .. ' faded')
	end

	local panel = panel_of(frame)
	eq(drawn(frame), 'theme,theme,panel', where .. ': drawn in the Skinning look as a panel')
	check(panel:IsShown(), where .. ': the panel shows')
	check(panel:GetFrameLevel() < frame:GetFrameLevel(), where .. ': under the picker')
	check(panel:GetLeft() < frame:GetLeft() and panel:GetRight() > frame:GetRight()
		and panel:GetTop() > frame:GetTop() and panel:GetBottom() < frame:GetBottom(),
		where .. ': around the picker, as Thick draws a border')

	eq(frame.Header.Text:GetFontObject(), font, where .. ': the title in the Skinning font')

	for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
		local button = frame.Footer[key]
		local box = the_one(own_children(button), where .. ': one frame of SaftUI\'s on ' .. key)
		check(box:IsShown(), where .. ': ' .. key .. "'s box shows")
		eq(drawn(box), 'theme,theme,control', where .. ': ' .. key .. ' drawn as a control')
		check(box:GetLeft() >= button:GetLeft() and box:GetRight() <= button:GetRight(), where .. ': inside the button')
		eq(button:GetHighlightTexture():GetAlpha(), 0, where .. ': ' .. key .. "'s highlight faded")
		local hover = the_one(own_regions(button), where .. ': one texture of SaftUI\'s on ' .. key)
		eq(stub.state(hover).draw_layer, st.ThemeArt.HOVER_LAYER, where .. ': a hover shown only under the mouse')
		eq(button:GetNormalFontObject(), font, where .. ': ' .. key .. ' text in the Skinning font')
		eq(button:GetHighlightFontObject(), font, where .. ': and highlighted')
		eq(button:GetDisabledFontObject(), font, where .. ': and disabled')
	end

	local hex = frame.Content.HexBox
	local backdrop = the_one(own_children(hex), where .. ': one frame of SaftUI\'s on the hex box')
	check(backdrop:IsShown(), where .. ': the hex box backdrop shows')
	eq(drawn(hex), 'theme,theme,control', where .. ': the hex box drawn as a control')
	eq(hex:GetFontObject(), font, where .. ': the hex text in the Skinning font')
	eq(hex.Instructions:GetFontObject(), font, where .. ': its instructions')
	eq(hex.Hash:GetFontObject(), font, where .. ': the "#"')

	-- Left alone.
	for _, path in ipairs({ { 'Content', 'AlphaBackground' }, { 'Content', 'ColorSwatchCurrent' },
			{ 'Content', 'ColorSwatchOriginal' }, { 'Content', 'ColorPicker', 'Wheel' }, { 'Content', 'ColorPicker' } }) do
		eq(part(path):GetAlpha(), 1, where .. ': ' .. table.concat(path, '.') .. ' left as Blizzard draws it')
	end
end

------------------------------------------------------------------ tests

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': the picker is skinned: panel, buttons, hex box and fonts', function()
		world(client)
		check_skinned(client)
		clean()
	end)
end

test("the panel follows the picker's width, which Blizzard changes with the alpha slider", function()
	world('forever')
	local panel = panel_of(CP.frame)
	CP.show({ r = 1, g = 0, b = 0, hasOpacity = true, opacity = 1, swatchFunc = function() end })
	eq(CP.frame:GetWidth(), 388, 'with an alpha slider: 388 wide')
	local wide = T.around(panel, CP.frame)
	CP.show({ r = 1, g = 0, b = 0, hasOpacity = false, swatchFunc = function() end })
	eq(CP.frame:GetWidth(), 331, 'without: 331 wide')
	eq(T.around(panel, CP.frame), wide, 'the panel is as far outside it as before')
	check_skinned('after Blizzard resized it')
	clean()
end)

test('nothing is written onto Blizzard\'s tables, and the picker behaves as Blizzard made it', function()
	world('forever')
	check_skinned('skinned')
	for _, widget in ipairs(CP.widgets) do
		eq(CP.keys(widget), built[widget], 'the same fields on every Blizzard table as when it was built')
	end
	switch('blizzard')
	switch('thick')
	for _, widget in ipairs(CP.widgets) do
		eq(CP.keys(widget), built[widget], 'and after a theme switch both ways')
	end

	-- What an addon sets in it and reads from it.
	local seen = {}
	CP.show({
		r = 0.1, g = 0.2, b = 0.3, hasOpacity = true, opacity = 0.5,
		swatchFunc = function() seen.swatch = true end,
		cancelFunc = function() seen.cancel = true end,
		extraInfo = 'mine',
	})
	eq(CP.frame.extraInfo, 'mine', 'extraInfo kept for the caller')
	eq(CP.frame.previousValues.r, 0.1, 'previousValues kept')
	check(CP.frame:IsShown(), 'it shows')
	stub.click(CP.frame.Footer.OkayButton)
	stub.click(CP.frame.Footer.CancelButton)
	eq(CP.OkayButton.clicks, 1, "Okay's own OnClick ran")
	eq(CP.CancelButton.clicks, 1, "Cancel's own OnClick ran")
	clean()
end)

test('Skinning -> Color picker off at load: nothing touched, nothing made', function()
	local before
	world('forever', { off = true })
	check_blizzard('off at load')
	eq(#own_children(CP.frame), 0, 'no frame of SaftUI\'s on the picker')
	eq(drawn(CP.frame), nil, 'nothing drawn')
	for _, widget in ipairs(CP.widgets) do
		if widget.GetNumChildren then eq(#own_children(widget), 0, 'no frame of SaftUI\'s anywhere') end
	end
	clean()
end)

test('under the Blizzard theme the picker is left as Blizzard draws it, and the theme switch goes both ways', function()
	world('forever')
	check_skinned('Thick')
	switch('blizzard')
	check_blizzard('Blizzard')
	switch('thick')
	check_skinned('Thick again')
	switch('thin')
	check_skinned('Thin')
	clean()

	-- Blizzard from the start: never touched.
	world('forever', { theme = 'blizzard' })
	check_blizzard('Blizzard from the start')
	eq(#own_children(CP.frame), 0, 'no panel made under Blizzard')
	eq(#own_children(CP.frame.Content.HexBox), 0, 'no hex backdrop made under Blizzard')
	clean()
end)

test('the Skinning page toggle goes both ways at once; the font reaches every text', function()
	world('forever')
	check_skinned('on')
	profile.skinning.color_picker = false
	SK:UpdateConfig()
	check_blizzard('toggled off')
	profile.skinning.color_picker = true
	SK:UpdateConfig()
	check_skinned('toggled on again')
	for _, child in ipairs(own_children(CP.frame)) do check(child:IsShown(), 'and the panel shows again') end
	profile.skinning.font = 'normal'
	SK:UpdateConfig()
	check_skinned('in another font')
	eq(CP.frame.Header.Text:GetFontObject(), st:GetFont('normal'), 'the title took it')
	clean()

	-- On from off, live: the picker is hooked and styled then.
	world('forever', { off = true })
	profile.skinning.color_picker = true
	SK:UpdateConfig()
	check_skinned('turned on live')
	clean()
end)

test('the Skinning page has the toggle, on by default', function()
	world('forever')
	eq(profile.skinning.color_picker, true, 'on by default')
	local page = SK:GetConfigTable()
	local toggle = page.args.general.args.color_picker
	check(toggle ~= nil, 'a toggle on the Skinning page')
	eq(toggle.name, 'Color picker', 'named Color picker')
	eq(toggle.type, 'toggle', 'a toggle')
end)

test('a focused hex box shows a white border, and loses it again', function()
	world('forever')
	local hex = CP.frame.Content.HexBox
	local backdrop = the_one(own_children(hex), 'the hex box backdrop')
	local normal = T.edge(backdrop)
	hex:SetFocus()
	stub.fire_script(hex, 'OnEditFocusGained')
	eq(T.edge(backdrop), T.text(1, 1, 1, 1), 'white while it has focus')
	hex:ClearFocus()
	stub.fire_script(hex, 'OnEditFocusLost')
	eq(T.edge(backdrop), normal, "the theme's border again")
	clean()
end)

test('a part a client lacks skips its step, with no error', function()
	local parts = {
		'Border', 'Header', 'Header.Text', 'Header.LeftBG', 'Content', 'Content.HexBox', 'Content.HexBox.Left',
		'Content.HexBox.Instructions', 'Content.HexBox.Hash', 'Footer', 'Footer.OkayButton', 'Footer.CancelButton',
		'Footer.CancelButton.Left',
	}
	for _, part_name in ipairs(parts) do
		world('forever', { build = { omit = { part_name } } })
		eq(#take_errors(), 0, 'without ' .. part_name .. ': no error')
		if part_name ~= 'Header' then
			check(CP.frame.Header ~= nil, 'the rest is still there')
		end
	end
	-- Everything missing at once.
	world('forever', { build = { omit = parts } })
	eq(#take_errors(), 0, 'with every part missing: no error')
	profile.skinning.color_picker = false
	SK:UpdateConfig()
	eq(#take_errors(), 0, 'and turned off again')
	clean()
end)

test('in combat: styled with nothing blocked', function()
	world('forever')
	stub.in_combat, stub.blocked = true, {}
	switch('blizzard')
	check_blizzard('Blizzard in combat')
	switch('thick')
	check_skinned('Thick again in combat')
	eq(#stub.blocked, 0, 'nothing blocked')
	stub.in_combat = false
	clean()
end)

test('the addon loading after SaftUI: skinned once it loads', function()
	world('forever', { late = true })
	eq(_G.ColorPickerFrame, nil, 'not built yet')
	CP.build()
	blizzard = {}
	for _, widget in ipairs(CP.widgets) do blizzard[widget] = true end
	stub.loaded_addons.Blizzard_ColorPickerFrame = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_ColorPickerFrame')
	check_skinned('loaded late')
	clean()
end)

test('skinned once: a second Install and a repeated style add nothing', function()
	world('forever')
	skin:Install()
	skin:StyleAll()
	skin:UpdateConfig()
	check_skinned('after repeats')
	eq(#own_children(CP.frame), 1, 'one panel')
	eq(#own_children(CP.frame.Content.HexBox), 1, 'one hex backdrop')
	clean()
end)
