-- SaftUI-Core/Config/optionswindow.lua's drawing: a set that hides an option
-- removes its row, a validate failure shows in the status line, ConfigTableChange
-- re-renders on the next frame and coalesced, and a slider drag draws nothing
-- until the mouse is let go (the other rows read their rows again in place), and
-- every cell on whole pixels.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 and AceConfigRegistry-3.0
-- (config_helpers.lua), the model (optionsmodel.lua), the widgets
-- (load_options_widgets), the body (optionsbody.lua), the window
-- (load_options_window) and edit mode. The /sui tree is the real one
-- Config:GetOptionsTable builds, from the real General, Fonts, Colors, Theme and
-- EditMode modules, AceDBOptions' profiles table, and the synthetic modules
-- options_window_helpers.lua registers. The mouse, the keyboard and the frame
-- clock are played by firing scripts (stub.fire_script): the window re-renders
-- and searches on its ticker's OnUpdate, which the stubs never run by
-- themselves.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local W, OW = st.OptionsWidgets, st.OptionsWindow
local close_all, drawn, cell, click, uf = H.close_all, H.drawn, H.cell, H.click, H.uf
local frames, tick = H.frames, H.tick

-- A texture's eight corners as text, rounded so float drift doesn't decide a
-- check; corners(l, r, t, b) is what SetTexCoord(l, r, t, b) gives back.
local function coords_of(texture)
	local out = {}
	for i, v in ipairs({ texture:GetTexCoord() }) do out[i] = string.format('%.4f', v) end
	return table.concat(out, ',')
end
local function corners(l, r, t, b)
	local out = {}
	for i, v in ipairs({ l, t, l, b, r, t, r, b }) do out[i] = string.format('%.4f', v) end
	return table.concat(out, ',')
end

------------------------------------------------------------------ opening, the sidebar and the wiring

test('rerender after set: a set that hides an option removes its row', function()
	st.Config:Open('Unitframes', 'player', 'power')
	eq(drawn(), 'copy,enable,height,size', 'height shows while power is on')
	local before = OW.GetRenderCount()
	click(cell('enable').widget.frame)
	eq(uf.player.power.enable, false, 'set through the model')
	eq(drawn(), 'copy,enable,size', 'height is gone on the render after the set')
	eq(OW.GetRenderCount(), before + 1, 'one render')
	click(cell('enable').widget.frame)
	eq(drawn(), 'copy,enable,height,size', 'and back')
	close_all()
end)

test('a validate failure shows in the status line and sets nothing', function()
	st.Config:Open('Unitframes', 'player', 'power')
	local box = cell('size').widget.frame
	box:SetText('abc')
	stub.fire_script(box, 'OnEnterPressed')
	eq(frames().status:GetText(), 'Size: a number, please', 'the validate message')
	OW:SetStatus('Something else')
	eq(frames().status:GetText(), 'Something else', 'SetStatus')
	OW:Navigate('Loot')
	eq(frames().status:GetText(), '', 'cleared by navigating')
	close_all()
end)

test('ConfigTableChange re-renders on the next frame, coalesced, and keeps the selection', function()
	st.Config:Open('Unitframes', 'target', 'power')
	local before = OW.GetRenderCount()
	uf.target.power.enable = false
	st.Config:Refresh()
	st.Config:Refresh()
	eq(drawn(), 'copy,enable,height,size', 'not re-rendered straight away')
	eq(OW.GetRenderCount(), before, 'no render yet')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'two changes, one render')
	eq(drawn(), 'copy,enable,size', 'the hidden row is gone')
	eq(OW:GetState().pick .. '/' .. OW:GetState().tab, 'target/power', 'the picker and tab stay')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'nothing more to do')
	uf.target.power.enable = true

	-- A pick that vanishes falls back to the first; when it's back, it's selected again.
	hideTarget = true
	st.Config:Refresh(); tick()
	eq(OW:GetState().pick, 'player', 'target hidden: the first unit')
	hideTarget = false
	st.Config:Refresh(); tick()
	eq(OW:GetState().pick, 'target', 'target is back')
	close_all()
end)

test("a get that notifies the registry doesn't re-render in a loop", function()
	-- The footer control's dropdown, as UF's real profile select: its get notifies.
	st.Config:Open('Unitframes', 'player', 'general')
	local function dropdown() return frames().footerWidgets[1] end
	eq(dropdown().text:GetText(), 'Main', "the footer's dropdown")
	local before = OW.GetRenderCount()
	tick(); tick(); tick()
	eq(OW.GetRenderCount(), before, 'gets during a render are ignored')

	-- Opening its list runs the get again: the render waits until the list closes.
	click(dropdown().frame)
	check(W.ListOwner() ~= nil, 'the list is open')
	tick(); tick()
	eq(OW.GetRenderCount(), before, 'no render under the open list')
	check(W.ListOwner() ~= nil, 'still open')
	click(W.GetListFrames().rows[1]) -- Alt
	eq(ufProfile, 'Alt', 'picked')
	eq(OW.GetRenderCount(), before + 1, 'the set re-renders once')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'and nothing is left pending')
	ufProfile = 'Main'
	close_all()
end)

test("a slider drag doesn't re-render until the mouse is let go", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local w = cell('width').widget
	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true -- held for the whole drag, as in game
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(250)
	w.slider:SetValue(260)
	eq(uf.player.width, 260, 'set while dragging')
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	st.Config:Refresh(); tick()
	eq(OW.GetRenderCount(), before, 'nor from the registry')
	eq(cell('width').widget, w, 'the same slider is still drawn')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	tick()
	eq(OW.GetRenderCount(), before + 1, 'the pending one went with it')
	close_all()
end)

-- In game a click on the track can move the slider before its OnMouseDown
-- runs; a render then would take the slider out from under the drag.
test("a drag whose first move comes before its mouse-down still doesn't re-render until let go", function()
	st.Config:Open('Unitframes', 'player', 'general')
	local w = cell('width').widget
	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true
	w.slider:SetValue(250)
	eq(OW.GetRenderCount(), before, 'no render from the first move')
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(260)
	eq(uf.player.width, 260, 'set while dragging')
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	eq(cell('width').widget, w, 'the same slider is still drawn')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	close_all()
end)

test('a drag whose mouse-up never arrives still renders once the button is up', function()
	st.Config:Open('Unitframes', 'player', 'general')
	local w = cell('width').widget
	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true
	w.slider:SetValue(255)
	tick()
	eq(OW.GetRenderCount(), before, 'held: no render')
	stub.mouse_buttons.LeftButton = nil
	tick()
	eq(OW.GetRenderCount(), before + 1, 'released: the page catches up')
	close_all()
end)

test('mid-drag the other rows read their rows again in place: values and disabled follow, no row comes or goes', function()
	st.Config:Open('Inventory', 'general')
	eq(drawn(), 'columns,columns_shown,wide,extra,merge', "the General tab's rows")
	local w = cell('columns').widget
	local cellsBefore, widgetsBefore = {}, {}
	for i, c in ipairs(OW.GetDrawnRows()) do cellsBefore[i], widgetsBefore[i] = c, c.widget end
	local pooled = W.Pooled('toggle') .. ',' .. W.Pooled('input') .. ',' .. W.Pooled('range')
	-- The dragged slider is refreshed by its own commit, and by nothing else.
	local refreshes, refresh = 0, w.Refresh
	w.Refresh = function(...) refreshes = refreshes + 1; return refresh(...) end

	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(9)
	w.Refresh = refresh
	eq(columns, 9, 'set while dragging')
	eq(refreshes, 1, "the slider was refreshed once, by its commit")
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	eq(cell('columns_shown').widget.frame:GetText(), '9', "another row's value follows the drag")
	check(cell('wide').widget:IsDisabled(), 'a row disabled at 8 or more is disabled now')
	local r, g, b = cell('wide').label:GetTextColor()
	local gr, gg, gb = st.config.profile.colors.text.grey:GetRGB()
	check(r == gr and g == gg and b == gb, 'and its label is grey')
	eq(drawn(), 'columns,columns_shown,wide,extra,merge', 'a row hidden at 9 or more stays until the drag ends')
	for i, c in ipairs(OW.GetDrawnRows()) do
		check(c == cellsBefore[i] and c.widget == widgetsBefore[i], 'cell ' .. i .. ' and its widget are the ones drawn')
	end
	eq(W.Pooled('toggle') .. ',' .. W.Pooled('input') .. ',' .. W.Pooled('range'), pooled, 'nothing was released')

	-- Back under 8: enabled again, label in the normal color.
	w.slider:SetValue(7)
	check(not cell('wide').widget:IsDisabled(), 'enabled again')
	r, g, b = cell('wide').label:GetTextColor()
	local nr, ng, nb = st.config.profile.colors.text.normal:GetRGB()
	check(r == nr and g == ng and b == nb, 'and its label is the normal color')
	w.slider:SetValue(9)

	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	eq(drawn(), 'columns,columns_shown,wide,merge', 'which leaves the hidden row out')
	eq(cell('columns_shown').widget.frame:GetText(), '9', 'the value as it was set')
	check(cell('wide').widget:IsDisabled(), 'still disabled')
	columns = 5
	close_all()
end)

test("dragging Icon zoom crops its preview as it goes, with no render, and the slider stays the one dragged", function()
	st.Config:Open('Fonts', 'general')
	local w = cell('icon_trim').widget
	local preview = cell('icon_preview').widget
	eq(preview.type, 'description', 'the preview is a description row')
	eq(preview.image:GetTexture(), 'Interface\\Icons\\Spell_Nature_Lightning', 'with the lightning icon')
	eq(preview.image:GetWidth() .. 'x' .. preview.image:GetHeight(), '36x36', 'at 36 by 36')
	eq(coords_of(preview.image), corners(st:IconTexCoords(0.065, 36, 36)), 'cut at the default zoom')
	eq(coords_of(preview.image), corners(0.065, 0.935, 0.065, 0.935), 'which is 6.5% off each edge')

	local before = OW.GetRenderCount()
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(w.slider, 'OnMouseDown')
	w.slider:SetValue(0.15)
	eq(st.config.profile.misc.icon_trim, 0.15, 'set while dragging')
	eq(OW.GetRenderCount(), before, 'no render mid-drag')
	eq(cell('icon_trim').widget, w, 'the same slider is still drawn')
	eq(cell('icon_preview').widget, preview, 'and the same preview')
	eq(coords_of(preview.image), corners(st:IconTexCoords(0.15, 36, 36)), 'the preview follows the drag')
	w.slider:SetValue(0)
	eq(coords_of(preview.image), corners(0, 1, 0, 1), 'at 0%, the whole icon')
	w.slider:SetValue(0.2)

	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(w.slider, 'OnMouseUp')
	eq(OW.GetRenderCount(), before + 1, 'one render when let go')
	eq(coords_of(cell('icon_preview').widget.image), corners(0.2, 0.8, 0.2, 0.8), 'drawn again at the zoom left set')

	-- A typed zoom re-renders at once, so the preview takes it too.
	local edit = cell('icon_trim').widget.edit
	edit:SetText('10')
	stub.fire_script(edit, 'OnEnterPressed')
	eq(coords_of(cell('icon_preview').widget.image), corners(0.1, 0.9, 0.1, 0.9), 'a typed 10%')
	st.config.profile.misc.icon_trim = 0.065
	close_all()
end)

-- A 1px border blurs when its frame sits between two pixels. The window is on
-- whole pixels (SaftUI's scale makes a unit a pixel), so every cell of the body
-- must start and end on whole units too: under Blizzard a quarter of a 367
-- column is 171.5. Under Thick and Thin the slots are flush (no gap) and each
-- cell is its slot inset by 14, so the second column's cell ends 14 short of
-- the body's edge, the slot's flush with it.
test('every cell of the body starts and ends on whole pixels, at any width', function()
	local OB = st.OptionsBody
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		st.config.profile.theme.name = look
		local pad = look == 'blizzard' and 0 or 14
		for _, width in ipairs({ OB.WIDTH, 775, 480 }) do
			local body = OB.New(CreateFrame('Frame', nil, UIParent), nil, function() end, width)
			local where = look .. ', width ' .. width
			for _, col in ipairs({ 'full', 1, 2 }) do
				for _, quarter in ipairs(col == 'full' and { false } or { false, 1, 2 }) do
					for _, rect in ipairs({ 'SlotRect', 'CellRect' }) do
						local x, w = body[rect](body, col, quarter or nil)
						local name = ('%s, %s(%s, %s)'):format(where, rect, tostring(col), tostring(quarter))
						eq(x, math.floor(x), name .. ': x ' .. tostring(x) .. ' is whole')
						eq(w, math.floor(w), name .. ': width ' .. tostring(w) .. ' is whole')
					end
				end
			end
			local x1, w1 = body:SlotRect(1)
			local x2, w2 = body:SlotRect(2)
			eq(x2 + w2, width, where .. ": the second column's slot ends at the body's edge")
			local q2x, q2w = body:SlotRect(1, 2)
			eq(q2x + q2w, x1 + w1, where .. ": a column's second quarter ends at the column's edge")
			local cx2, cw2 = body:CellRect(2)
			eq(cx2 + cw2, width - pad, where .. ': the second column\'s cell ends ' .. pad .. ' short of the edge')
			local cx1 = body:CellRect(1)
			eq(cx1, pad, where .. ': the first column\'s cell starts ' .. pad .. ' in')
		end
	end
	st.config.profile.theme.name = 'thick'
end)

test('the picker and tabs switch the selection', function()
	st.Config:Open('Unitframes', 'player', 'general')
	click(frames().tabs[2])
	eq(OW:GetState().tab, 'power', 'a tab click')
	click(frames().picker.frame)
	local list = W.GetListFrames()
	local labels = {}
	for i, row in ipairs(list.rows) do
		if row:IsShown() then labels[#labels + 1] = row.text:GetText() end
	end
	eq(table.concat(labels, ','), 'Player,Target', 'the picker lists the units: the profile is in the footer')
	click(list.rows[2])
	eq(OW:GetState().pick, 'target', 'picked Target')
	eq(OW:GetState().tab, 'power', 'the tab is kept')
	close_all()
end)
