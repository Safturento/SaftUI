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
local original -- their fonts, colors and title anchor as built

local function key_lists_of(widgets)
	local out = {}
	for _, widget in ipairs(widgets) do out[widget] = CP.keys(widget) end
	return out
end

-- Every font, color and the title's anchor as they are now.
local function snapshot()
	local frame = CP.frame
	local out = {}
	local function text(key, fs)
		if not fs then return end
		out[key] = { fs:GetFontObject(), T.rgb(fs:GetTextColor()) }
	end
	text('title', frame.Header and frame.Header.Text)
	text('hash', frame.Content.HexBox.Hash)
	text('instructions', frame.Content.HexBox.Instructions)
	text('hex', frame.Content.HexBox)
	for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
		local b = frame.Footer[key]
		out[key] = { b:GetNormalFontObject(), b:GetHighlightFontObject(), b:GetDisabledFontObject() }
	end
	out.title_point = T.anchor(frame.Header.Text, { [frame.Header] = 'header' })
	local hex = frame.Content.HexBox
	out.hash_point = hex.Hash and T.anchor(hex.Hash, { [hex] = 'hexbox' })
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
	local build = { forever = client == 'forever' }
	for key, value in pairs(opts.build or {}) do build[key] = value end
	if not opts.late then CP.build(build) end
	blizzard = {}
	for _, widget in ipairs(CP.widgets or {}) do blizzard[widget] = true end
	built = CP.widgets and key_lists_of(CP.widgets)
	original = CP.frame and not opts.build and snapshot()
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

------------------------------------------------------------------ checks

-- How far down its panel's top a SaftUI dialog's title sits (optionssmalldialog.lua).
local DIALOG_TITLE_Y = 18

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
	local now = snapshot()
	for key, value in pairs(original) do
		if type(value) == 'table' then
			for i, v in ipairs(value) do eq(now[key][i], v, where .. ': ' .. key .. ' as Blizzard had it (' .. i .. ')') end
		else
			eq(now[key], value, where .. ': ' .. key .. ' as Blizzard had it')
		end
	end
	eq(now.OkayButton[1], GameFontNormal, where .. ": the buttons' normal font is UIPanelButtonNoTooltipTemplate's")
	eq(now.OkayButton[2], GameFontHighlight, where .. ': and its highlight font')
	eq(now.CancelButton[3], GameFontDisable, where .. ': and its disabled font')
	eq(now.hash[2], T.rgb(0.6, 0.6, 0.6), where .. ': the "#" grey as Blizzard\'s XML has it')
	eq(now.instructions[2], T.rgb(0.35, 0.35, 0.35), where .. ': the placeholder grey')
	for _, button in ipairs({ CP.frame.Footer.OkayButton, CP.frame.Footer.CancelButton }) do
		eq(#own_regions(button), 0, where .. ': no hover texture of SaftUI\'s over the label')
	end
	for _, child in ipairs(own_children(CP.frame)) do check(not child:IsShown(), where .. ': no panel shows') end
	for _, child in ipairs(own_children(CP.frame.Content.HexBox)) do
		check(not child:IsShown(), where .. ': no hex box backdrop shows')
	end
end

-- The picker's three frames of SaftUI's: its panel and the two frames that take
-- the mouse over the panel's parts beside the picker: the top band (which also
-- drags the picker) and the strip under its bottom.
local function own_frames(frame)
	local panel, band, foot
	local children = own_children(frame)
	eq(#children, 3, "three frames of SaftUI's on the picker: its panel, the band over its top and the strip under it")
	for _, child in ipairs(children) do
		if not child:IsMouseEnabled() then
			panel = child
		elseif child:GetTop() > frame:GetTop() then
			band = child
		else
			foot = child
		end
	end
	return panel, band, foot
end

local function panel_of(frame) return (own_frames(frame)) end

local function check_skinned(where)
	local frame = CP.frame
	local font = st:GetFont(profile.skinning.font)
	for _, path in ipairs(ALPHA_PARTS) do
		eq(part(path):GetAlpha(), 0, where .. ': ' .. table.concat(path, '.') .. ' faded')
	end

	local panel = panel_of(frame)
	eq(drawn(frame), 'theme,solid,panel', where .. ': drawn in the Skinning theme, solid, as a panel')
	check(panel:IsShown(), where .. ': the panel shows')
	check(panel:GetFrameLevel() < frame:GetFrameLevel(), where .. ': under the picker')
	check(panel:GetLeft() < frame:GetLeft() and panel:GetRight() > frame:GetRight()
		and panel:GetTop() > frame:GetTop() and panel:GetBottom() < frame:GetBottom(),
		where .. ': around the picker, as Thick draws a border')

	eq(frame.Header.Text:GetFontObject(), st:GetFont(profile.headers.font), where .. ': the title in the Window titles font')
	eq(T.anchor(frame.Header.Text, { [panel] = 'panel' }),
		('TOP panel TOP %s'):format(T.text(0, -DIALOG_TITLE_Y)),
		where .. ": the title centered, as far down the panel's top as a SaftUI dialog's title")
	check(panel:GetTop() >= frame.Header:GetTop(), where .. ': the panel covers the drag strip above the frame')
	check(panel:GetTop() <= frame.Header:GetTop() + 2, where .. ': and no more than the theme border above it')

	for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
		local button = frame.Footer[key]
		local box = the_one(own_children(button), where .. ': one frame of SaftUI\'s on ' .. key)
		check(box:IsShown(), where .. ': ' .. key .. "'s box shows")
		eq(drawn(box), 'theme,theme,control', where .. ': ' .. key .. ' drawn as a control')
		check(box:GetLeft() >= button:GetLeft() and box:GetRight() <= button:GetRight(), where .. ': inside the button')
		eq(button:GetHighlightTexture():GetAlpha(), 0, where .. ': ' .. key .. "'s highlight faded")
		eq(#own_regions(button), 0, where .. ': nothing of SaftUI\'s drawn over ' .. key .. "'s label")
		check(box:GetFrameLevel() < button:GetFrameLevel(), where .. ': the box under the button')
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
	eq(T.rgb(hex.Hash:GetTextColor()), T.rgb(0.6, 0.6, 0.6), where .. ': the "#" keeps its grey')
	eq(T.rgb(hex.Instructions:GetTextColor()), T.rgb(0.35, 0.35, 0.35), where .. ': the placeholder keeps its grey')

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
	SK:UpdateConfig()
	st:ColorsChanged('theme')
	eq(table.concat(CP.calls, ','), '', "no call that changes anything was made on any of Blizzard's widgets")
	for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
		eq(#own_children(CP.frame.Footer[key]), 0, key .. ': nothing made on it')
		eq(#own_regions(CP.frame.Footer[key]), 0, key .. ': no texture made on it')
	end
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
	SK:UpdateConfig()
	st:ColorsChanged('theme')
	eq(table.concat(CP.calls, ','), '', "no call that changes anything was made on any of Blizzard's widgets")
	for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
		eq(#own_children(CP.frame.Footer[key]), 0, key .. ': nothing made on it')
		eq(#own_regions(CP.frame.Footer[key]), 0, key .. ': no texture made on it')
	end
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

-- Global settings > Theme > Window titles: the row's own set, as the options
-- window calls it, reaches the picker's title at once, with no skin update.
test("a change through Theme > Window titles reaches the picker's title at once; the Skinning font stays", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		world(client)
		local row = st:GetModule('Theme'):GetConfigTable().args.window_titles.args.font
		local function resetTitles()
			-- This world has no /sui tree: the Theme tab alone, as the page 'Fonts' holds it.
			local root = { Fonts = { type = 'group', name = 'Fonts', args = { theme = st:GetModule('Theme'):GetConfigTable() } } }
			for _, section in ipairs(st.OptionsModel.BuildView(root, 'Fonts', { tab = 'theme' }).sections) do
				for _, r in ipairs(section.rows) do
					if r.key == 'font' and r.path[#r.path - 1] == 'window_titles' then
						eq(st.OptionsModel.DefaultReset(root, r), true, client .. ': the derived reset ran')
					end
				end
			end
		end
		eq(row.type, 'font', client .. ': the Theme tab has the row')
		eq(CP.frame.Header.Text:GetFontObject(), st:GetFont('normal'), client .. ': Text to start with')
		row.set({}, 'subtitle')
		eq(profile.headers.font, 'subtitle', client .. ': saved in headers.font')
		eq(CP.frame.Header.Text:GetFontObject(), st:GetFont('subtitle'), client .. ': the title, at once')
		eq(CP.frame.Footer.OkayButton:GetNormalFontObject(), st:GetFont(profile.skinning.font), client .. ': the buttons stay in the Skinning font')
		local face = { font_name = 'Homespun', font_size = 13, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
		row.set({}, face)
		eq(CP.frame.Header.Text:GetFontObject(), st:FontObject(face), client .. ': a typeface, at once')
		resetTitles()
		eq(CP.frame.Header.Text:GetFontObject(), st:GetFont('normal'), client .. ': its reset, at once')
		-- Skinning off: the picker keeps Blizzard's font whatever the setting says.
		profile.skinning.color_picker = false
		SK:UpdateConfig()
		row.set({}, 'subtitle')
		check(CP.frame.Header.Text:GetFontObject() ~= st:GetFont('subtitle'), client .. ': a picker not skinned keeps its own title font')
		resetTitles()
		eq(#take_errors(), 0, client .. ': no errors')
		clean()
	end
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
	eq(#own_children(CP.frame), 3, 'one panel, one band and one strip')
	eq(#own_children(CP.frame.Content.HexBox), 1, 'one hex backdrop')
	clean()
end)

test("hovering Okay or Cancel turns the edge of SaftUI's box blue; nothing covers the label", function()
	world('forever')
	local blue = T.text(profile.theme.accent:GetRGB())
	for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
		local button = CP.frame.Footer[key]
		local box = the_one(own_children(button), key .. "'s box")
		local normal = T.edge(box)
		check(normal ~= T.text(1, 1, 1, 1) and not normal:find(blue, 1, true), key .. ': not blue at rest')
		-- The game passes a second argument, motion, to OnEnter and OnLeave.
		stub.fire_script(button, 'OnEnter', true)
		check(T.edge(box):find(blue, 1, true) ~= nil, key .. ': blue under the mouse')
		eq(#own_regions(button), 0, key .. ": no texture of SaftUI's, which would sit over the label")
		stub.fire_script(button, 'OnLeave', true)
		eq(T.edge(box), normal, key .. ': back when the mouse leaves')
	end
	-- A recolor while hovered keeps the hover.
	local button = CP.frame.Footer.OkayButton
	stub.fire_script(button, 'OnEnter', true)
	st:ColorsChanged('theme')
	check(T.edge(the_one(own_children(button), 'the box')):find(blue, 1, true) ~= nil, 'a recolor keeps the hover')
	-- A change of the accent while hovered reaches it, and an accent that is not the default is the edge.
	profile.theme.accent:SetRGB(0.9, 0.2, 0.4)
	st:ColorsChanged('accent')
	check(T.edge(the_one(own_children(button), 'the box')):find(T.text(0.9, 0.2, 0.4), 1, true) ~= nil, "a change of the accent reaches the hovered box")
	profile.theme.accent:SetRGB(0, 0.68, 0.94)
	st:ColorsChanged('accent')
	stub.fire_script(button, 'OnLeave', true)
	-- Under the Blizzard theme the hooks color nothing.
	switch('blizzard')
	stub.fire_script(button, 'OnEnter', true)
	stub.fire_script(button, 'OnLeave', true)
	clean()
end)

-- Every frame and region of SaftUI's on the picker, under its panel and boxes.
local function own_pieces()
	local out = {}
	local function walk(region)
		out[#out + 1] = region
		if region.GetRegions then
			for _, part in ipairs({ region:GetRegions() }) do walk(part) end
			for _, kid in ipairs({ region:GetChildren() }) do walk(kid) end
		end
	end
	local panel, band, foot = own_frames(CP.frame)
	walk(panel)
	walk(band)
	walk(foot)
	for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do walk(the_one(own_children(CP.frame.Footer[key]), key)) end
	walk(the_one(own_children(CP.frame.Content.HexBox), 'the hex box backdrop'))
	return out
end

test('SaftUI\'s frames are kept on whole pixels at both widths and after a drag', function()
	-- The stubs lay nothing out by pixels (SetRoundLayoutToNearestPixel is only
	-- remembered), so what is checked is that the game is asked to, for every
	-- frame and region of SaftUI's, with the picker on a fractional offset.
	world('forever')
	local function check_rounded(where)
		local pieces = own_pieces()
		check(#pieces > 3, where .. ': pieces of SaftUI\'s to check')
		for i, piece in ipairs(pieces) do
			eq(stub.state(piece).round_layout, true, where .. ': piece ' .. i .. ' rounded to whole pixels')
		end
	end
	CP.frame:ClearAllPoints()
	CP.frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', 100.5, 700.5)
	for _, opacity in ipairs({ true, false }) do
		CP.show({ r = 1, g = 0, b = 0, hasOpacity = opacity, opacity = 1, swatchFunc = function() end })
		check_rounded(opacity and '388 wide' or '331 wide')
	end
	-- After a drag: Blizzard anchors it by a corner somewhere else.
	CP.frame:ClearAllPoints()
	CP.frame:SetPoint('CENTER', UIParent, 'CENTER', 33.5, -20.5)
	CP.show({ r = 1, g = 0, b = 0, hasOpacity = true, opacity = 1, swatchFunc = function() end })
	check_rounded('after a drag, 388')
	CP.show({ r = 1, g = 0, b = 0, hasOpacity = false, opacity = 1, swatchFunc = function() end })
	check_rounded('after a drag, 331')
	-- A theme switch draws new pieces: they are rounded too.
	switch('thin')
	check_rounded('Thin')
	-- No size or point of Blizzard's was changed for it: the controls sit where Blizzard put them.
	eq(T.offset(CP.frame.Footer.CancelButton, 'BOTTOMRIGHT'), '-11.50,0.00', "Cancel is where Blizzard anchors it")
	clean()
end)

test('skin on then off puts back every font, color and the title anchor it read', function()
	world('forever')
	check_skinned('on')
	profile.skinning.color_picker = false
	SK:UpdateConfig()
	check_blizzard('off again')
	-- And a second round trip.
	profile.skinning.color_picker = true
	SK:UpdateConfig()
	check_skinned('on again')
	switch('blizzard')
	check_blizzard('Blizzard')
	clean()
end)

test("a click on the panel's top band is not a click outside the picker; the drag bar keeps its clicks", function()
	world('forever')
	local frame = CP.frame
	for _, opacity in ipairs({ true, false }) do
		CP.show({ r = 1, g = 0, b = 0, hasOpacity = opacity, opacity = 1, swatchFunc = function() end, cancelFunc = function() end })
		local panel, band = own_frames(frame)
		local header = frame.Header
		local top = frame:GetTop()
		local y = top + (panel:GetTop() - top) / 2 -- in the band above the picker
		check(y > top, 'the band reaches above the picker')
		check(band:GetTop() == panel:GetTop() and band:GetBottom() == panel:GetTop() - profile.headers.height,
			"the band is the panel's top strip, a Window titles header high")
		local where = opacity and '388' or '331'
		-- Left and right of the header (which is 200 wide, centered).
		for _, x in ipairs({ frame:GetLeft() + 12, frame:GetRight() - 12 }) do
			check(x < header:GetLeft() or x > header:GetRight(), 'a point beside the header')
			local focus, cancelled = CP.click(x, y)
			eq(focus, band, where .. ': the band takes the click beside the header')
			eq(cancelled, false, where .. ': not treated as outside')
			check(frame:IsShown(), where .. ': the picker stays open')
		end
		-- On the header the drag bar still gets it, and it is the picker's own.
		local focus, cancelled = CP.click((header:GetLeft() + header:GetRight()) / 2, y)
		eq(focus, frame.DragBar, where .. ': the drag bar gets the click on the header')
		eq(cancelled, false, where .. ': and it is not outside either')
		-- The panel under the buttons is not outside either.
		local _, _, foot = own_frames(frame)
		focus, cancelled = CP.click(frame:GetLeft() + 100, frame:GetBottom() - 5)
		eq(focus, foot, where .. ': the strip under the picker takes the click')
		eq(cancelled, false, where .. ': not treated as outside')
		-- A click inside the picker, and one outside the band and the picker.
		focus, cancelled = CP.click(frame:GetLeft() + 30, top - 40)
		eq(cancelled, false, where .. ': inside the picker')
		focus, cancelled = CP.click(frame:GetLeft() + 12, panel:GetTop() + 20)
		eq(cancelled, true, where .. ': above the panel is outside, as before')
		check(not frame:IsShown(), where .. ': so it cancelled')
	end
	clean()
end)

test('the band takes the mouse only while skinned: off, or under the Blizzard theme, nothing of SaftUI\'s does', function()
	local function mouse_takers()
		local count = 0
		local function walk(f)
			if not blizzard[f] and f.IsMouseEnabled and f:IsMouseEnabled() and f:IsShown() then count = count + 1 end
			for _, kid in ipairs({ f:GetChildren() }) do walk(kid) end
		end
		walk(CP.frame)
		return count
	end
	world('forever', { off = true })
	eq(mouse_takers(), 0, 'toggle off at load')
	world('forever', { theme = 'blizzard' })
	eq(mouse_takers(), 0, 'Blizzard from the start')
	world('forever')
	eq(mouse_takers(), 2, 'skinned: the band and the strip under the picker')
	switch('blizzard')
	eq(mouse_takers(), 0, 'Blizzard: the band hidden, takes no mouse')
	switch('thick')
	eq(mouse_takers(), 2, 'Thick again')
	profile.skinning.color_picker = false
	SK:UpdateConfig()
	eq(mouse_takers(), 0, 'toggled off')
	clean()
end)

------------------------------------------------------------------ pixels and padding

local CONTENT_PAD = 23 -- the wheel's left and the hex box's right, in from the picker's sides (Blizzard's XML)

local function whole(value) return math.abs(value - math.floor(value + 0.5)) < 1e-3 end

-- The picker opened the way an addon opens it: Blizzard's OnShow sets the
-- width, and nothing else tells the skin (no size event is fired here).
local function open_picker(opacity)
	CP.show({ r = 1, g = 0, b = 0, hasOpacity = opacity, opacity = 1, swatchFunc = function() end, cancelFunc = function() end })
end

test('Okay and Cancel: two boxes of one size, 6 apart, evenly padded, inside their buttons, on whole pixels', function()
	world('forever')
	local frame = CP.frame
	for _, opacity in ipairs({ true, false }) do
		local where = opacity and '388 wide: ' or '331 wide: '
		open_picker(opacity)
		local okay = the_one(own_children(frame.Footer.OkayButton), 'the Okay box')
		local cancel = the_one(own_children(frame.Footer.CancelButton), 'the Cancel box')
		eq(okay:GetWidth(), cancel:GetWidth(), where .. 'equal widths')
		eq(okay:GetHeight(), cancel:GetHeight(), where .. 'equal heights')
		eq(cancel:GetLeft() - okay:GetRight(), 6, where .. 'a gap of 6, as SaftUI uses')
		local left, right = okay:GetLeft() - frame:GetLeft(), frame:GetRight() - cancel:GetRight()
		eq(left, right, where .. 'the same padding at both ends')
		if opacity then
			eq(left, 40, where .. "the buttons' own edges: the box can't leave its button")
		else
			check(left >= CONTENT_PAD and left <= CONTENT_PAD + 1, where .. 'in line with the wheel and the hex box, which are 23 in')
		end
		for _, key in ipairs({ 'OkayButton', 'CancelButton' }) do
			local button, box = frame.Footer[key], key == 'OkayButton' and okay or cancel
			check(box:GetLeft() >= button:GetLeft() and box:GetRight() <= button:GetRight()
				and box:GetTop() <= button:GetTop() and box:GetBottom() >= button:GetBottom(), where .. key .. ': inside the button')
			for _, edge in ipairs({ box:GetLeft(), box:GetRight(), box:GetTop(), box:GetBottom() }) do
				check(whole(edge), where .. key .. ': an edge on a whole unit, ' .. tostring(edge))
			end
		end
		-- The panel's padding under the buttons is the padding at the sides of the picker's content.
		local panel = panel_of(frame)
		eq(okay:GetBottom() - panel:GetBottom(), frame:GetLeft() - panel:GetLeft() + CONTENT_PAD,
			where .. "the panel's bottom as far from the boxes as its sides are from the content")
	end
	clean()
end)

test("the boxes follow a theme switch and the toggle, and keep their place", function()
	world('forever')
	open_picker(false)
	local box = the_one(own_children(CP.frame.Footer.OkayButton), 'the Okay box')
	local before = box:GetLeft()
	switch('thin')
	eq(box:GetLeft(), before, 'Thin: the box has not moved')
	profile.skinning.color_picker = false
	SK:UpdateConfig()
	profile.skinning.color_picker = true
	SK:UpdateConfig()
	eq(box:GetLeft(), before, 'off and on again: the same place')
	clean()
end)

------------------------------------------------------------------ moving the picker

-- Whether the picker is being moved by the mouse (StartMoving with no StopMovingOrSizing since).
local function moving(frame) return stub.state(frame).moving == true end

test("dragging the panel's top band moves the picker, and letting go stops it; Blizzard's scripts are not replaced", function()
	world('forever')
	local frame = CP.frame
	local before = {}
	for _, widget in ipairs(CP.widgets) do before[widget] = { stub.state(widget).scripts } end
	open_picker(true)
	local _, band = own_frames(frame)
	check(frame:IsMovable(), 'Blizzard makes it movable')
	stub.fire_script(band, 'OnMouseDown', 'LeftButton')
	eq(moving(frame), true, 'the band starts the picker moving')
	check(frame:IsShown(), 'a drag is not a click outside')
	stub.fire_script(band, 'OnMouseUp', 'LeftButton')
	eq(moving(frame), false, 'and the mouse up stops it')
	stub.fire_script(band, 'OnMouseDown', 'RightButton')
	eq(moving(frame), false, 'only the left button drags')
	-- Letting go after the picker was hidden, and hiding it mid-drag.
	stub.fire_script(band, 'OnMouseDown', 'LeftButton')
	frame:Hide()
	eq(moving(frame), false, 'hiding the picker in a drag stops it')
	frame:Show()
	stub.fire_script(band, 'OnMouseUp', 'LeftButton')
	eq(moving(frame), false, 'a mouse up with no drag of SaftUI\'s moves and stops nothing')
	eq(#CP.stray, 0, "none of Blizzard's own functions ran")
	for _, widget in ipairs(CP.widgets) do
		eq(stub.state(widget).scripts, before[widget][1], "no script table of Blizzard's was replaced")
	end
	clean()
end)

test("the band does not stop a move that isn't SaftUI's, and does nothing in a picker that isn't movable", function()
	world('forever')
	local frame = CP.frame
	open_picker(true)
	local _, band = own_frames(frame)
	frame:StartMoving() -- Blizzard's own drag bar's
	stub.fire_script(band, 'OnMouseUp', 'LeftButton')
	eq(moving(frame), true, "a mouse up on the band leaves Blizzard's own drag alone")
	frame:StopMovingOrSizing()
	frame:SetMovable(false)
	stub.fire_script(band, 'OnMouseDown', 'LeftButton')
	eq(moving(frame), false, 'not movable: no move, no error')
	clean()
end)

test('the band drags in combat when the picker is not protected', function()
	world('forever')
	open_picker(true)
	local _, band = own_frames(CP.frame)
	stub.in_combat, stub.blocked = true, {}
	stub.fire_script(band, 'OnMouseDown', 'LeftButton')
	eq(moving(CP.frame), true, 'moving')
	stub.fire_script(band, 'OnMouseUp', 'LeftButton')
	eq(#stub.blocked, 0, 'nothing blocked')
	stub.in_combat = false
	clean()
end)

test('after a drag the pieces of SaftUI are on whole pixels at both widths', function()
	world('forever')
	local frame = CP.frame
	for _, opacity in ipairs({ true, false }) do
		open_picker(opacity)
		local _, band = own_frames(frame)
		stub.fire_script(band, 'OnMouseDown', 'LeftButton')
		-- Where the game leaves it: a corner anchor, on a fraction.
		frame:ClearAllPoints()
		frame:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', 412.37, 655.81)
		stub.fire_script(band, 'OnMouseUp', 'LeftButton')
		local pieces = own_pieces()
		check(#pieces > 5, 'pieces of SaftUI\'s to check')
		for i, piece in ipairs(pieces) do
			eq(stub.state(piece).round_layout, true, 'piece ' .. i .. ' rounded to whole pixels after a drag')
		end
	end
	clean()
end)

test('off, or under the Blizzard theme, the band moves nothing', function()
	world('forever')
	open_picker(true)
	local _, band = own_frames(CP.frame)
	switch('blizzard')
	stub.fire_script(band, 'OnMouseDown', 'LeftButton')
	eq(moving(CP.frame), false, 'Blizzard theme: the band is not there to drag')
	clean()
end)

------------------------------------------------------------------ the hex box

test('the hex box: a backdrop as tall as the buttons\' boxes, its right end in line with Cancel\'s, room before the "#"', function()
	world('forever')
	local frame = CP.frame
	local hex = frame.Content.HexBox
	for _, opacity in ipairs({ true, false }) do
		local where = opacity and '388 wide: ' or '331 wide: '
		open_picker(opacity)
		local backdrop = the_one(own_children(hex), where .. 'the hex backdrop')
		local cancel = the_one(own_children(frame.Footer.CancelButton), 'the Cancel box')
		eq(backdrop:GetHeight(), cancel:GetHeight(), where .. "as tall as the buttons' boxes")
		if opacity then
			check(backdrop:GetRight() >= cancel:GetRight(), where .. "the content's own end, which the button can't reach")
		else
			check(math.abs(backdrop:GetRight() - cancel:GetRight()) <= 1, where .. "right end in line with Cancel's box")
		end
		eq(T.anchor(hex.Hash, { [backdrop] = 'backdrop' }), 'LEFT backdrop LEFT ' .. T.text(5, 0), where .. 'the "#" anchored to the backdrop, 5 in')
		check(backdrop:GetLeft() < hex:GetLeft(), where .. 'the backdrop reaches left of the box, as Blizzard\'s art does')
		eq(stub.state(backdrop).round_layout, true, where .. 'rounded to whole pixels')
	end
	-- Off: the "#" is where Blizzard anchored it (check_blizzard compares the snapshot).
	profile.skinning.color_picker = false
	SK:UpdateConfig()
	check_blizzard('off')
	clean()
end)

------------------------------------------------------------------ a missed mouse up

test('the band stops the move when the button is up, whichever way it was let go', function()
	world('forever')
	open_picker(true)
	local _, band = own_frames(CP.frame)
	stub.mouse_buttons = { LeftButton = true }
	stub.fire_script(band, 'OnMouseDown', 'LeftButton')
	stub.fire_script(band, 'OnUpdate', 0.016)
	check(moving(CP.frame), 'button still down: moving')
	stub.mouse_buttons = {}
	stub.fire_script(band, 'OnUpdate', 0.016)
	check(not moving(CP.frame), 'button up, no mouse up seen: stopped')
	clean()
end)

------------------------------------------------------------------ a solid panel

test('the picker\'s panel is solid whatever the Skinning Background; the boxes keep theirs', function()
	world('forever')
	profile.skinning.background = 'transparent'
	SK:UpdateConfig()
	local function alpha(f) return select(4, f:GetBackdropColor()) end
	local frame = CP.frame
	eq(alpha(panel_of(frame)), 1, 'see-through Background: the panel is opaque')
	check(alpha(the_one(own_children(frame.Content.HexBox), 'the hex backdrop')) < 1, 'the hex backdrop keeps the see-through Background')
	check(alpha(the_one(own_children(frame.Footer.OkayButton), 'the Okay box')) < 1, 'and so does the Okay box')
	profile.skinning.background = 'solid'
	SK:UpdateConfig()
	eq(alpha(panel_of(frame)), 1, 'solid Background: opaque too')
	clean()
end)

test('the skin repaints for its groups only: a Class pass touches nothing', function()
	local C = load_test_file('lib/color_cost.lua')
	world('forever')
	for group, key in pairs({ class = 'MAGE', reaction = 4, power = 'MANA', text = 'muted', button = 'normal', status = 'tapped' }) do
		st:ColorChanged(group, key)
		local m = C.measure(function() st:ColorChanged(group, key) end)
		eq(m.calls.total, 0, group .. ': no color set')
		eq(m.forbidden.total, 0, group .. ': nothing forbidden')
	end
	for _, group in ipairs({ 'accent', 'theme' }) do
		st:ColorsChanged(group)
		local m = C.measure(function() st:ColorChanged(group) end)
		check(m.calls.total > 0, group .. ': the hover edges are colored')
		eq(m.forbidden.total, 0, group .. ': nothing forbidden')
		eq(m.made, 0, group .. ': nothing made')
	end
	clean()
end)
