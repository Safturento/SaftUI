-- SaftUI's color picker in the real /sui window (optionscolorpicker.lua, and
-- the color type's Pick, optionstypes.lua): what happens to it, and to the
-- setting it is changing, when the window draws another page, a tab or a
-- search under it, when it closes, and when the setting changes under it (a
-- profile switch). The picker alone is options_color_picker_test.lua's.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OM, W, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsWindow
local close_all, cell, tick = H.close_all, H.cell, H.tick
local M = W.ColorMath

local function type_hex(text)
	local F = W.GetColorPickerFrames()
	F.hex:SetFocus()
	F.hex:SetText(text)
	stub.fire_script(F.hex, 'OnEnterPressed')
end

local function hex_of(c) return M.FormatHex(c.r, c.g, c.b) end

-- Opens Mage's color on the Colors tab, changes it, and says what it opened on.
local function open_mage()
	st.Config:Open('Fonts', 'colors')
	local mage = st.config.profile.colors.class.MAGE
	local original = hex_of(mage)
	stub.click(cell('MAGE').widget.frame)
	check(W.ColorPickerShown(), 'the picker is open')
	type_hex(original == '#FF0000' and '#00FF00' or '#FF0000')
	check(hex_of(mage) ~= original, 'the live change reached the setting')
	return mage, original
end

test('a page change under the picker closes it as a Cancel: the setting gets its opening color back', function()
	local mage, original = open_mage()
	OW:Navigate('Loot')
	tick()
	check(not W.ColorPickerShown(), 'the picker is closed')
	eq(hex_of(mage), original, 'the opening color is back in the setting')
	close_all()
end)

test('a tab change under the picker restores the setting, and no picker is left beside another row', function()
	st.Config:Open('Fonts', 'colors')
	-- The last color row of the tab: the pool hands its widget to the next page first.
	local last
	for _, d in ipairs(OW.GetDrawnRows()) do
		if d.row.type == 'color' then last = d end
	end
	local widget, root, row = last.widget, last.widget.root, last.widget.row
	local function stored() return OM.Get(root, row) end
	local original = stored()
	stub.click(widget.frame)
	type_hex('#00FF00')
	check(stored() ~= original, 'live change')
	OW:Navigate('Fonts', { tab = 'theme' })
	tick()
	check(not W.ColorPickerShown(), 'the picker is closed, not left beside a different setting')
	eq(stored(), original, 'the row it opened on has its opening color back')
	close_all()
end)

test('a search under the picker restores the setting and closes it', function()
	local mage, original = open_mage()
	local box = OW.GetFrames().search
	box:SetFocus()
	box:SetText('loot')
	tick(0.3)
	tick()
	check(not W.ColorPickerShown(), 'the picker is closed')
	eq(hex_of(mage), original, 'restored')
	close_all()
end)

test('closing /sui restores the setting from a real row, and Okay can never record a color no setting holds', function()
	st.config.global.colorPicker.recent = {}
	local mage, original = open_mage()
	st.Config:Close()
	check(not W.ColorPickerShown(), 'closed with the window')
	eq(hex_of(mage), original, 'restored')
	eq(#st.config.global.colorPicker.recent, 0, 'nothing recorded')
	close_all()
end)

test('Okay after the field was released records nothing', function()
	st.config.global.colorPicker.recent = {}
	st.Config:Open('Fonts', 'colors')
	stub.click(cell('MAGE').widget.frame)
	type_hex('#FF0000')
	OW:Navigate('Loot')
	tick()
	local F = W.GetColorPickerFrames()
	if F.okay:IsShown() then stub.click(F.okay) end
	eq(#st.config.global.colorPicker.recent, 0, 'nothing recorded')
	close_all()
end)

test('entering combat with the picker open cancels it (the event is registered)', function()
	local mage, original = open_mage()
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(not W.ColorPickerShown(), 'closed')
	eq(hex_of(mage), original, 'restored')
	close_all()
end)

test('closing the small dialog restores a color opened from one of its rows', function()
	st.Config:Open('Loot')
	local value = { 0.2, 0.4, 0.6, 1 }
	OW:OpenDialog('Colors', { type = 'group', name = 'D', args = {
		c = { type = 'color', name = 'C', get = function() return unpack(value) end,
			set = function(_, r, g, b, a) value = { r, g, b, a } end },
	} })
	local row
	for _, c in ipairs(OW.GetDialogFrames().body.cells) do
		if c.row.key == 'c' then row = c end
	end
	stub.click(row.widget.frame)
	type_hex('#FF0000')
	eq(value[1], 1, 'live')
	OW:CloseDialog()
	check(not W.ColorPickerShown(), 'closed')
	eq(value[1], 0.2, 'restored')
	close_all()
end)

------------------------------------------------------------------ the setting changes under it

-- A bound color widget for a setting kept per profile: the getter and the
-- setter read the current one. pick types into the picker's hex box.
local parent = CreateFrame('Frame', nil, UIParent)
parent:SetSize(800, 600)
parent:SetPoint('CENTER')

local function bind_color(option)
	local root = { page = { type = 'group', name = 'Page', args = { tint = option } } }
	local row
	for _, section in ipairs(OM.BuildView(root, 'page').sections) do
		for _, r in ipairs(section.rows) do
			if r.key == 'tint' then row = r end
		end
	end
	local w = W.Create(parent, 'color')
	w:Bind(root, row, function() end)
	return w, root, row
end

local function profile_widget()
	local profiles = { A = { 0.2, 0.4, 0.6, 1 }, B = { 0.9, 0.9, 0.9, 1 } }
	local current = 'A'
	local w = bind_color({ type = 'color', name = 'Tint',
		get = function() return unpack(profiles[current]) end,
		set = function(_, r, g, b, a) profiles[current] = { r, g, b, a } end })
	local helpers = { pick_color = function(r, g, b)
		type_hex(M.FormatHex(r, g, b))
	end }
	return w, profiles, function(name) current = name end, helpers
end

test('a profile switch under the picker closes it and writes nothing into the new profile', function()
	local w, profiles, switch, helpers = profile_widget()
	stub.click(w.frame)
	helpers.pick_color(1, 0, 0)
	eq(profiles.A[1], 1, 'live in A')
	switch('B')
	-- A change in the picker before the next frame: it must not reach B.
	helpers.pick_color(0, 0, 1)
	check(not W.ColorPickerShown(), 'the picker closed on the stored color changing')
	eq(profiles.B[1], 0.9, "B's red untouched")
	eq(profiles.B[3], 0.9, "B's blue untouched")
	eq(profiles.A[1], 1, 'A keeps what was set live (there is no hook to put it back)')
	w:Release()
end)

test('a profile switch is noticed on the next frame, without a change', function()
	local w, profiles, switch, helpers = profile_widget()
	stub.click(w.frame)
	helpers.pick_color(1, 0, 0)
	switch('B')
	stub.fire_script(W.GetColorPickerFrames().frame, 'OnUpdate', 0.016)
	check(not W.ColorPickerShown(), 'closed')
	eq(profiles.B[1], 0.9, "B's color untouched")
	w:Release()
end)

test('releasing or rebinding the field closes the picker with the restore reaching its row', function()
	local w, profiles, _, helpers = profile_widget()
	stub.click(w.frame)
	helpers.pick_color(1, 0, 0)
	w:Release()
	check(not W.ColorPickerShown(), 'closed by the release')
	eq(profiles.A[1], 0.2, 'restored')
	local w2 = bind_color({ type = 'color', name = 'T', get = function() return 0, 0, 0, 1 end, set = function() end })
	stub.click(w2.frame)
	local _, root, row = bind_color({ type = 'color', name = 'O', get = function() return 1, 1, 1, 1 end, set = function() end })
	w2:Bind(root, row, function() end)
	check(not W.ColorPickerShown(), 'a rebind to another row closes it')
	w2:Release()
end)
