-- SaftUI-Core/Config/optionswindow.lua's band: a pick's group may carry a
-- pickerBand (SaftUI's field), a strip the window draws under the picker's
-- line, over the body: its height asked once per page, tab, subtab, pick and
-- body width, drawn on every render, refreshed in a slider drag, released when
-- it goes. The helpers' Unitframes page, with ufPickerBand on the player.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OM, OW = st.OptionsModel, st.OptionsWindow
local close_all, cell, click = H.close_all, H.cell, H.click
local frames, tick = H.frames, H.tick

-- A band whose calls are counted in n; the height it answers is n.answer.
local function make_band(answer)
	local n = { height = 0, draw = 0, refresh = 0, release = 0, answer = answer }
	local band = {
		height = function(width) n.height = n.height + 1; n.width = width; return n.answer end,
		draw = function(holder, width, height) n.draw = n.draw + 1; n.holder, n.drawWidth, n.drawHeight = holder, width, height end,
		refresh = function(holder) n.refresh = n.refresh + 1 end,
		release = function(holder) n.release = n.release + 1 end,
	}
	return band, n
end

local function pick(key)
	click(frames().picker.frame)
	for _, row in ipairs(st.OptionsWidgets.GetListFrames().rows) do
		if row:IsShown() and row.text:GetText() == key then click(row) return end
	end
	error('no pick ' .. key)
end

test('band: drawn under the picker line, the body under it', function()
	local band, n = make_band(120)
	ufPickerBand = band
	st.Config:Open('Unitframes', 'player', 'power')
	local f = frames()
	local holder = f.band
	check(holder ~= nil and holder:IsShown(), 'the band is shown')
	eq(holder:GetTop(), f.picker.frame:GetBottom() - 12, "12 under the picker line's bottom")
	eq(holder:GetHeight(), 120, 'the height it asked for')
	eq(holder:GetWidth(), f.body:GetWidth(), 'the body width')
	eq(holder:GetLeft(), f.main:GetLeft() + 28, 'at PAD')
	eq(f.body:GetTop(), holder:GetBottom(), "the body's top at the band's bottom")
	eq(n.holder, holder, 'drawn into the holder')
	eq(n.drawHeight, 120, 'told its height')
	eq(n.drawWidth, holder:GetWidth(), 'and its width')
	eq(n.width, holder:GetWidth(), 'the height asked at that width')
	close_all()
	ufPickerBand = nil
end)

test('band: height asked once per page, tab, pick and width', function()
	local band, n = make_band(120)
	ufPickerBand = band
	st.Config:Open('Unitframes', 'player', 'power')
	eq(n.height, 1, 'one on open')
	click(cell('enable').widget.frame)
	eq(n.height, 1, "a toggle's set renders without asking")
	st.Config:Open('Unitframes', 'player', 'general')
	eq(n.height, 2, 'a tab change asks')
	pick('Target')
	eq(n.height, 2, 'a pick without a band asks nothing')
	pick('Player')
	eq(n.height, 3, 'back on Player asks once')
	OW:SetWindowSize('half')
	eq(n.height, 4, 'a window size change asks')
	OW:SetWindowSize('full')
	eq(n.height, 5, 'and back')
	close_all()
	ufPickerBand = nil
end)

test('band: draw runs on every render', function()
	local band, n = make_band(120)
	ufPickerBand = band
	st.Config:Open('Unitframes', 'player', 'power')
	local before = n.draw
	click(cell('enable').widget.frame)
	eq(n.draw, before + 1, 'drawn again by a render')
	click(cell('enable').widget.frame)
	eq(n.draw, before + 2, 'and again')
	close_all()
	ufPickerBand = nil
end)

test('band: a drag refreshes it, and draws nothing', function()
	local band, n = make_band(120)
	ufPickerBand = band
	st.Config:Open('Unitframes', 'player', 'general')
	local w = cell('width').widget
	local draws, refreshes = n.draw, n.refresh
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(250)
	eq(n.refresh, refreshes + 1, 'refreshed by the drag')
	eq(n.draw, draws, 'not drawn')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(n.draw, draws + 1, 'drawn when let go')
	close_all()
	ufPickerBand = nil
end)

test('band: none without one, for search, or height 0; released once leaving one', function()
	local band, n = make_band(120)
	ufPickerBand = band
	st.Config:Open('Unitframes', 'player', 'power')
	local f = frames()
	local lineBottom = f.picker.frame:GetBottom()
	check(f.band:IsShown(), 'shown on Player')
	eq(n.release, 0, 'not released yet')
	pick('Target')
	check(not f.band:IsShown(), 'hidden on a pick without one')
	eq(f.body:GetTop(), lineBottom, "the body at the picker line's bottom")
	eq(n.release, 1, 'released once')
	pick('Player')
	check(f.band:IsShown(), 'back')
	-- The search page.
	local box = f.search
	box:SetFocus()
	box:SetText('frame wid')
	tick(0.5)
	eq(OW:GetState().search, 'frame wid', 'searching')
	check(not f.band:IsShown(), 'none for search')
	eq(n.release, 2, 'released')
	box:SetText('')
	tick(0.5)
	box:ClearFocus()
	check(f.band:IsShown(), 'back after search')
	-- Height 0.
	n.answer = 0
	st.Config:Open('Unitframes', 'player', 'general')
	check(not f.band:IsShown(), 'height 0: none')
	eq(f.body:GetTop(), f.picker.frame:GetBottom(), 'the body as today')
	eq(n.release, 3, 'released leaving it')
	local asked = n.height
	click(cell('enable').widget.frame)
	eq(n.height, asked, 'a height of 0 is not asked again by a render')
	tick()
	eq(n.release, 3, 'once')
	-- nil too, and on hide.
	n.answer = 90
	st.Config:Open('Unitframes', 'player', 'power')
	check(f.band:IsShown(), 'shown again')
	close_all()
	eq(n.release, 4, 'released when the window hides')
	ufPickerBand = nil
end)

test('band: clips its children, and has the panel look under Thick and none under Blizzard', function()
	local band = make_band(120)
	ufPickerBand = band
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		H.theme(look)
		st.Config:Open('Unitframes', 'player', 'power')
		local f = frames()
		check(stub.state(f.band).clips_children, look .. ': clips')
		check(f.bandFill ~= nil and f.bandFill:IsShown() == (look ~= 'blizzard'), look .. ': the fill only under Thick and Thin')
		close_all()
	end
	H.theme('thick')
	ufPickerBand = nil
end)

test('model: view.picker.band is the picked group\'s pickerBand', function()
	local band = make_band(10)
	local root = {
		Unitframes = {
			type = 'group', name = 'Unitframes', childGroups = 'select',
			args = {
				player = { type = 'group', name = 'Player', pickerBand = band, args = { a = { type = 'toggle', name = 'A', get = function() return true end, set = function() end } } },
				target = { type = 'group', name = 'Target', pickerBand = 'junk', args = { a = { type = 'toggle', name = 'A', get = function() return true end, set = function() end } } },
			},
		},
	}
	eq(OM.BuildView(root, 'Unitframes', { pick = 'player' }).picker.band, band, 'the picked one, as it is')
	eq(OM.BuildView(root, 'Unitframes', { pick = 'target' }).picker.band, nil, 'a non-table is none')
end)

test('band: height asked again for a page change and for a subtab change', function()
	local band, n = make_band(120)
	ufPickerBand = band
	st.Config:Open('Unitframes', 'player', 'power')
	eq(n.height, 1, 'one on open')
	OW:Navigate('Loot')
	st.Config:Open('Unitframes', 'player', 'power')
	eq(n.height, 2, 'away to another page and back asks again')
	close_all()
	ufPickerBand = nil

	-- A subtab change (the Extra tab's two subtabs).
	band, n = make_band(120)
	ufPickerBand, ufSubtabs = band, true
	st.Config:Open('Unitframes', 'player', 'extra', 'one')
	eq(OW:GetState().subtab, 'one', 'on a subtab')
	eq(n.height, 1, 'one on open')
	click(cell('a').widget.frame)
	eq(n.height, 1, 'a render asks nothing')
	st.Config:Open('Unitframes', 'player', 'extra', 'two')
	eq(OW:GetState().subtab, 'two', 'the other subtab')
	eq(n.height, 2, 'a subtab change asks')
	close_all()
	ufPickerBand, ufSubtabs = nil, false
end)

test('band: a fractional height is made whole, and the body under it stays whole', function()
	local band, n = make_band(120.4)
	ufPickerBand = band
	st.Config:Open('Unitframes', 'player', 'power')
	local f = frames()
	eq(f.band:GetHeight(), 121, 'the next whole unit up')
	eq(n.drawHeight, 121, 'drawn at it')
	eq(f.body:GetTop(), f.band:GetBottom(), "the body at the band's bottom")
	eq(f.body:GetTop() % 1, 0, 'on a whole unit')
	n.answer = 120.0000001
	st.Config:Open('Unitframes', 'player', 'general')
	eq(f.band:GetHeight(), 120, 'a hair over a whole number is that number')
	n.answer = 119.9999999
	st.Config:Open('Unitframes', 'player', 'power')
	eq(f.band:GetHeight(), 120, 'and a hair under')
	close_all()
	ufPickerBand = nil
end)
