-- SaftUI's tracker's interaction states (the interaction states plan, Task 8;
-- SaftUI-Core/Widgets/states.lua): quest rows and popup rows are 'row' states
-- (the Layer 2 past the row, at the derived hover), the quest item buttons and the
-- nearest one 'icon' states (their own HIGHLIGHT texture, BLEND, color only, no
-- attribute touched; the cost case is in rows_test.lua), the chevrons 'glyph' states (Muted, edgeHover under the mouse).
-- The focus bar, the popup bar, the tag and the pin are markers: they keep the Accent.
--
-- Real: SaftUI-Tracker's files, Core's helpers, theme engine and states. The scroll
-- frame is tracker_world.lua's stand-in. Each case runs on both clients.
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q
local SL = load_test_file('lib/states_look.lua')

local function log(ids, with_items)
	local entries = { Q.header('Elwynn Forest') }
	for _, id in ipairs(ids) do
		local fields = { objectives = { { text = '1/2 Wolves', type = 'monster' } } }
		if with_items then fields.item = { link = 'item:' .. (1000 + id), texture = 134400 + id, charges = 0 } end
		entries[#entries + 1] = Q.quest(id, fields)
	end
	Q.set(entries, ids)
end

local function ids(n)
	local list = {}
	for i = 1, n do list[i] = i end
	return list
end

local function world(client, n, with_items)
	local list = ids(n)
	local st, TR = RW.world({ client = client, enabling = function() log(list, with_items) end })
	return st, TR
end

local function same(a, b) return ('%.3f,%.3f,%.3f,%.3f'):format(unpack(a)) == ('%.3f,%.3f,%.3f,%.3f'):format(unpack(b)) end

for _, client in ipairs({ 'forever', 'retail' }) do
	local function case(name, fn) test(name .. ' [' .. client .. ']', function() fn(client) eq(#take_errors(), 0, 'no error reported') end) end

	case('quest rows at rest as before; under the mouse a 16% tint 2 past the row; the focus bar unchanged', function()
		local st, TR = world(client, 2)
		local row = RW.quest(TR, 1)
		local look = st:StateLook(row)
		eq(look.shape, 'row', 'a row')
		check(not look.layer.shown, 'nothing shown at rest')
		check(not look.fill.shown and not look.bar.shown, 'no fill and no bar: a quest row is never selected')
		local function focus_color() local c = stub.state(TR.focusBar).color_texture return { c[1], c[2], c[3], c[4] } end
		local focus = focus_color()
		stub.fire_script(row, 'OnEnter', true)
		look = st:StateLook(row)
		check(look.layer.shown, 'the tint under the mouse')
		eq(look.layer.blend, 'BLEND', 'BLEND')
		local h = { st:StateColor('hover') }
		eq(('%.2f'):format(look.layer.a), '0.16', '16%')
		eq(SL.bytes(look.layer), SL.bytes({ r = h[1], g = h[2], b = h[3] }), 'in the tone T+')
		eq(row:GetTop() + 2, look.pieces.layer:GetTop(), '2 above the row')
		eq(row:GetLeft() - 2, look.pieces.layer:GetLeft(), 'and 2 beside it')
		check(same(focus_color(), focus), 'the focus bar is unchanged by the hover')
		local accent = st.config.profile.theme.accent
		eq(SL.bytes({ r = focus[1], g = focus[2], b = focus[3] }), SL.bytes(accent), 'a marker: the Accent itself')
		stub.fire_script(row, 'OnLeave', true)
		check(not st:StateLook(row).layer.shown, 'gone on leave')
	end)

	case('a row back in the pool is at rest, and reuse makes nothing (AddStates once for the frame)', function()
		local st, TR = world(client, 2)
		local row = RW.quest(TR, 1)
		stub.fire_script(row, 'OnEnter', true)
		stub.fire_script(row, 'OnMouseDown', 'LeftButton')
		check(st:GetState(row, 'hover') and st:GetState(row, 'pushed'), 'hovered and held')
		Q.set({ Q.header('Elwynn Forest') }, {})
		TR:Refresh()
		eq(st:GetState(row, 'hover'), false, 'released: no hover')
		eq(st:GetState(row, 'pushed'), false, 'released: no push')
		check(not st:StateLook(row).layer.shown, 'and no tint')
		local regions = #{ row:GetRegions() }
		local counter = RW.counter()
		for _ = 1, 5 do
			log({ 1, 2 })
			TR:Refresh()
			Q.set({ Q.header('Elwynn Forest') }, {})
			TR:Refresh()
		end
		log({ 1 })
		TR:Refresh()
		eq(counter.frames, 0, 'no frame made by reuse')
		counter.stop()
		local again = RW.quest(TR, 1)
		eq(#{ again:GetRegions() }, regions, 'no texture made by reuse: the pieces are the frame\'s for life')
		stub.fire_script(again, 'OnEnter', true)
		eq(st:GetState(again, 'hover'), true, 'a reused row hovers')
		stub.fire_script(again, 'OnLeave', true)
		eq(st:GetState(again, 'hover'), false, 'once, and leaves')
	end)

	case('popup rows take the row states too: tint, push and release', function()
		local st, TR = world(client, 1)
		Q.set({ Q.header('A'), Q.quest(1, { objectives = { { text = 'x', type = 'monster' } } }) }, { 1 },
			{ popups = { { id = 9, kind = 'OFFER' } }, titles = { [9] = 'An offer' } })
		TR:Refresh()
		local rows = RW.rows(TR, 'popup')
		eq(#rows, 1, 'a popup row is drawn')
		local row = rows[1]
		local look = st:StateLook(row)
		eq(look.shape, 'row', 'a popup row is a row')
		check(not look.layer.shown, 'no tint at rest')
		stub.fire_script(row, 'OnEnter', true)
		look = st:StateLook(row)
		check(look.layer.shown, 'tinted under the mouse')
		eq(look.layer.layer .. look.layer.sublevel, 'ARTWORK-8', 'under the popup bar')
		eq(look.pieces.layer:GetTop(), row:GetTop() + 2, '2 past the row')
		eq(SL.bytes(look.layer), SL.bytes({ r = st:StateColor('hover') and select(1, st:StateColor('hover')), g = select(2, st:StateColor('hover')), b = select(3, st:StateColor('hover')) }), 'the hover tone')
		stub.fire_script(row, 'OnMouseDown', 'LeftButton')
		look = st:StateLook(row)
		eq(SL.bytes(look.layer), SL.bytes({ r = select(1, st:StateColor('pushed')), g = select(2, st:StateColor('pushed')), b = select(3, st:StateColor('pushed')) }), 'the pushed tone while held')
		stub.fire_script(row, 'OnMouseUp', 'LeftButton')
		stub.fire_script(row, 'OnLeave', true)
		check(not st:StateLook(row).layer.shown, 'released: back')
		local bar = { row.bar:GetVertexColor() }
		local c = stub.state(row.bar).color_texture or bar
		local accent = st.config.profile.theme.accent
		eq(SL.bytes({ r = c[1], g = c[2], b = c[3] }), SL.bytes(accent), 'the popup bar keeps the Accent (a marker)')
	end)

	case('zone header rows are rows: hover, and the chevron keeps the row hovered; a press on the slot or icon pushes the row', function()
		local st, TR = world(client, 2, true)
		local zone = RW.rows(TR, 'zone')[1]
		eq(st:StateLook(zone).shape, 'row', 'a zone header is a row')
		stub.fire_script(zone, 'OnEnter', true)
		check(st:StateLook(zone).layer.shown, 'tinted under the mouse')
		local layer = st:StateLook(zone).pieces.layer
		eq(layer:GetTop(), zone:GetTop() + 2, "a header's Layer is 2 past the row above")
		eq(layer:GetBottom(), zone:GetBottom() - 2, 'and 2 below')
		stub.fire_script(zone, 'OnLeave', true)
		check(not st:StateLook(zone).layer.shown, 'and back')
		stub.fire_script(zone.chevron, 'OnEnter', true)
		check(st:GetState(zone, 'hover'), 'the chevron takes the mouse: the header stays hovered')
		stub.fire_script(zone.chevron, 'OnLeave', true)
		check(not st:GetState(zone, 'hover'), 'and clears on leave')
		-- a quest row's slot and icon button: a left press shows the row pushed
		local row = RW.quest(TR, 1)
		for _, key in ipairs({ 'slot', 'iconButton' }) do
			local part = row[key]
			stub.fire_script(part, 'OnMouseDown', 'LeftButton')
			check(st:GetState(row, 'pushed'), key .. ': the row is pushed while held')
			stub.fire_script(part, 'OnMouseUp', 'LeftButton')
			check(not st:GetState(row, 'pushed'), key .. ': released')
			stub.fire_script(part, 'OnMouseDown', 'RightButton')
			check(not st:GetState(row, 'pushed'), key .. ': a right press does not')
		end
		-- the secure item button has no hook for it
		local b = TR:GetItemButton(1)
		eq(#{ b:GetScript('OnMouseDown') and 1 or nil }, 0, 'the secure item button has no OnMouseDown')
	end)

	case('quest item buttons: a BLEND hover; the combat dim and the in-area edge unchanged', function()
		local st, TR = world(client, 3, true)
		local b = TR:GetItemButton(1)
		check(b ~= nil, 'a button')
		local look = st:StateLook(b)
		eq(look.shape, 'icon', 'an icon')
		eq(look.hover_piece.blend, 'BLEND', 'BLEND, never added')
		eq(look.hover_piece.layer, 'HIGHLIGHT', 'its own HIGHLIGHT texture')
		check(b.hover == look.pieces.hover, 'the button\'s own hover texture')
		check(b:GetHighlightTexture() ~= b.hover, 'never handed to SetHighlightTexture')
		local h = { st:StateColor('hover') }
		check(same({ b.hover:GetVertexColor() }, h), 'the derived hover, 0.16, not the Accent at 0.4')
		eq(('%.2f'):format(look.hover_piece.a), '0.16', '16%')
		-- the combat dim is the layer's and the button's alpha, never the states' (nothing is disabled)
		local alpha = b:GetAlpha()
		TW.combat(true)
		stub.blocked = {}
		st:ColorsChanged('accent')
		eq(b:GetAlpha(), alpha, 'a pass in combat leaves the dim alone')
		eq(#stub.blocked, 0, 'nothing blocked in combat')
		TW.combat(false)
	end)

	case('the tracker draws its own look in every theme: under Blizzard the item hover and a row\'s tint are still SaftUI\'s', function()
		local st, TR = world(client, 2, true)
		TR.config.theme = 'blizzard'
		TR:UpdateConfig()
		local b = TR:GetItemButton(1)
		check(same({ b.hover:GetVertexColor() }, { st:StateColor('hover') }), 'the item hover is still tinted (never the white of an uncolored texture)')
		eq(b.hover:GetBlendMode(), 'BLEND', 'BLEND')
		-- a restyle under the Blizzard theme: without blizzard = false the helper would
		-- leave the hover texture bare (no texture, so no hover at all)
		st:RestyleStates(b)
		eq(b.hover:GetTexture(), st.BLANK_TEX, 'after a restyle the hover still has its flat texture')
		check(same({ b.hover:GetVertexColor() }, { st:StateColor('hover') }), 'and its tint')
		-- the record is not Blizzard's: a pass still colors it (it would skip a Blizzard record)
		local accent = st.config.profile.theme.accent
		accent:SetRGB(0.9, 0.2, 0.4)
		st:ColorsChanged('accent')
		check(same({ b.hover:GetVertexColor() }, { st:StateColor('hover') }), 'an Accent pass under the Blizzard theme still tints it')
		accent:SetRGB(0, 0.68, 0.94)
		st:ColorsChanged('accent')
		local row = RW.quest(TR, 1)
		stub.fire_script(row, 'OnEnter', true)
		check(st:StateLook(row).layer.shown and not st:StateLook(row).blizzard, 'and a row tints')
	end)

	case('the chevrons: Muted at rest, the lighter tone (edgeHover) under the mouse', function()
		local st, TR = world(client, 2)
		local muted = st.config.profile.colors.text.muted
		local header = TR.header
		local chevron = header.collapse
		eq(st:StateLook(chevron).shape, 'glyph', 'a glyph')
		eq(SL.bytes(st:StateLook(chevron).glyph), SL.bytes({ r = muted.r, g = muted.g, b = muted.b }), 'Muted at rest')
		stub.fire_script(chevron, 'OnEnter', true)
		local want = { st:StateColor('edgeHover') }
		local r, g, b = chevron.icon:GetVertexColor()
		eq(SL.bytes({ r = r, g = g, b = b }), SL.bytes({ r = want[1], g = want[2], b = want[3] }), 'edgeHover under the mouse')
		stub.fire_script(chevron, 'OnLeave', true)
		r, g, b = chevron.icon:GetVertexColor()
		eq(SL.bytes({ r = r, g = g, b = b }), SL.bytes({ r = muted.r, g = muted.g, b = muted.b }), 'Muted again')
		-- a Colors tab change of Muted reaches a chevron at rest
		muted:SetRGB(0.3, 0.3, 0.3)
		TR:OnColorsChanged('text')
		r, g, b = chevron.icon:GetVertexColor()
		eq(SL.bytes({ r = r, g = g, b = b }), '4d4d4d', 'the new Muted')
		-- a zone header's chevron too
		local zone = RW.zone(TR, 'Elwynn Forest') or RW.rows(TR, 'zone')[1]
		if zone then eq(st:StateLook(zone.chevron).shape, 'glyph', 'a zone header\'s chevron is one') end
	end)

end
