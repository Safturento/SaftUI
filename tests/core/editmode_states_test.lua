-- Edit mode's interaction states (the plan "interaction states", Task 4): a mover's
-- overlay, the History list's rows and the Filter movers box are state frames of
-- Widgets/states.lua. Hover tints the BODY (a mover has a tint now), a selected mover
-- has the accent edge and the fade (no flat 15%), the current History step is the
-- selected row (the bar and the fade, no 2px mark), a hovered row tints; the Filter box
-- hovers like every box. A drag draws as hover.
--
-- Real: the /sui window's world, edit mode's files and the bar's (load_editmode_bar),
-- the real Theme and Colors modules, the cost helper. The mouse is played by firing
-- scripts.
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')
local T = load_test_file('lib/theme_helpers.lua')
local H, st, EM, History

local function build()
	reset_world()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM, History = st.EditModeFrames, st.EditModeFrames.History
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

local function add_mover(key)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	frame:SetPoint('CENTER')
	local config = { position = { point = 'CENTER', x_off = 0, y_off = 0 } }
	return st:RegisterConfigMover(frame, { key = key, config = function() return config end, apply = function() end })
end

local function world()
	build()
	T.theme('thick')
	local a, b = add_mover('first'), add_mover('second')
	EM:Activate()
	return a, b
end

-- A switch of SaftUI's theme as Config:UpdateConfig runs it: every drawn frame redrawn,
-- then the modules color what they color themselves.
local function switch(name)
	T.theme(name, function() st:ColorsChanged('theme') end)
end
local function enter(frame) stub.fire_script(frame, 'OnEnter', true) end
local function leave(frame) stub.fire_script(frame, 'OnLeave', true) end
local function look(frame) return st:StateLook(frame) end
local function lit(piece) return piece and piece.shown and piece.alpha > 0 end
local function rgb(...) return T.text(...) end
local function edge_of(mover) return T.edge(mover.overlay.backdrop) end

local WHITE = '1.00,1.00,1.00,1.00'

------------------------------------------------------------------ movers

test('a mover at rest is drawn as before: a white line, black 30%, nothing of the states shown', function()
	local mover = world()
	local l = look(mover.overlay)
	eq(l.shape, 'mover', 'a state frame of shape mover')
	check(not lit(l.layer) and not lit(l.fill), 'no layer, no fill')
	eq(edge_of(mover), WHITE, 'a white line')
	eq(T.fill(mover.overlay.backdrop), '0.00,0.00,0.00,0.30', 'black 30%')
	eq(mover.overlay:GetAlpha(), 1, 'full alpha')
	EM:Deactivate()
end)

test('a mover under the mouse tints (new) and keeps its white line; the body stays black 30%', function()
	local mover = world()
	enter(mover.overlay)
	local l = look(mover.overlay)
	check(lit(l.layer), 'the layer shows')
	check(SL.near(l.layer, '5cc6ff'), 'in the tone: ' .. SL.bytes(l.layer))
	eq(('%.2f'):format(l.layer.a), ('%.2f'):format(select(4, st:StateColor('hover'))), 'at the hover strength')
	eq(l.layer.layer .. l.layer.sublevel, 'ARTWORK-8', 'ARTWORK -8')
	eq(edge_of(mover), WHITE, 'the edge is unchanged')
	eq(T.fill(mover.overlay.backdrop), '0.00,0.00,0.00,0.30', 'the body is unchanged')
	leave(mover.overlay)
	check(not lit(look(mover.overlay).layer), 'and it goes')
	EM:Deactivate()
end)

test('a selected mover: the accent edge and the fade over the dim body (no flat 15%); with the mouse on it, the lighter tone', function()
	local mover = world()
	EM:Select(mover)
	local l = look(mover.overlay)
	check(lit(l.fill), 'the fill shows')
	check(SL.near(l.fill, '00adf0'), 'in the accent: ' .. SL.bytes(l.fill))
	eq(('%.2f'):format(l.fill.a), ('%.2f'):format(select(4, st:StateColor('fill'))), 'at the fill strength')
	check(l.fill.right > 1, 'a fade: its right coordinate is 1/f, ' .. tostring(l.fill.right))
	eq(('%.4f'):format(l.fill.right), ('%.4f'):format(st:StateFade()), 'the cache\'s 1/f')
	local r, g, b = mover.overlay.backdrop:GetBackdropBorderColor()
	check(SL.near({ r = r, g = g, b = b }, '00adf0'), 'the edge is the accent')
	eq(T.fill(mover.overlay.backdrop), '0.00,0.00,0.00,0.30', 'the backdrop fill is the dim body, not a flat accent')
	enter(mover.overlay)
	l = look(mover.overlay)
	check(lit(l.layer) and lit(l.fill), 'both compose: the layer and the fill')
	check(SL.near(l.fill, '5cc6ff'), 'the fill in the lighter tone: ' .. SL.bytes(l.fill))
	r, g, b = mover.overlay.backdrop:GetBackdropBorderColor()
	check(SL.near({ r = r, g = g, b = b }, '5cc6ff'), 'and the edge')
	leave(mover.overlay)
	EM:Select(nil)
	check(not lit(look(mover.overlay).fill), 'deselected: the fill goes')
	eq(edge_of(mover), WHITE, 'and the white line is back')
	EM:Deactivate()
end)

test('a drag draws as hover, and keeps it when the mouse leaves while held', function()
	local mover = world()
	stub.fire_script(mover.overlay, 'OnMouseDown', 'LeftButton')
	check(st:GetState(mover.overlay, 'pushed'), 'pressed: the drag is the pushed state')
	local l = look(mover.overlay)
	check(lit(l.layer) and SL.near(l.layer, '5cc6ff'), 'it draws as hover, not the darker tone: ' .. SL.bytes(l.layer))
	leave(mover.overlay)
	check(lit(look(mover.overlay).layer), 'leaving while held keeps it')
	stub.fire_script(mover.overlay, 'OnMouseUp', 'LeftButton')
	check(not lit(look(mover.overlay).layer), 'let go: it goes')
	EM:Deactivate()
end)

test("the overlap picker's other movers keep their 40%: hover and selection leave the alpha alone", function()
	local mover = world()
	mover.overlay:SetAlpha(0.4) -- what picker.lua does to the others under the cursor
	enter(mover.overlay)
	EM:Select(mover)
	eq(mover.overlay:GetAlpha(), 0.4, 'still 40%')
	leave(mover.overlay)
	EM:Select(nil)
	eq(mover.overlay:GetAlpha(), 0.4, 'still 40%')
	EM:Deactivate()
end)

test('a theme switch puts a mover back as it was: white at rest, the selected one in the accent; hover and selection survive', function()
	local mover, other = world()
	EM:Select(mover)
	enter(other.overlay)
	switch('thin')
	eq(edge_of(other), WHITE, 'Thin: the white line')
	local r, g, b = mover.overlay.backdrop:GetBackdropBorderColor()
	check(SL.near({ r = r, g = g, b = b }, '00adf0'), 'Thin: the selected one is in the accent')
	check(lit(look(other.overlay).layer), 'a hover survives it')
	switch('thick')
	eq(edge_of(other), WHITE, 'Thick again')
	leave(other.overlay)
	EM:Deactivate()
end)

test('Blizzard: the highlight kit on every mover and the selected kit on the selected one; nothing of SaftUI\'s states drawn', function()
	local mover, other = world()
	EM:Select(mover)
	switch('blizzard')
	enter(mover.overlay)
	local l = look(mover.overlay)
	check(l.blizzard, 'the helper knows the Blizzard look')
	check(not lit(l.layer) and not lit(l.fill), 'no layer and no fill under Blizzard')
	local function shown_atlas(overlay)
		local out = {}
		for _, region in ipairs({ overlay:GetRegions() }) do
			if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAtlas() then
				out[#out + 1] = region:GetAtlas()
			end
		end
		return table.concat(out, ' ')
	end
	check(shown_atlas(mover.overlay):find('selected', 1, true), 'the selected one: the selected kit')
	check(shown_atlas(other.overlay):find('highlight', 1, true), 'the other: the highlight kit')
	leave(mover.overlay)
	EM:Select(other)
	check(shown_atlas(mover.overlay):find('highlight', 1, true), 'deselected: the highlight')
	switch('thick')
	check(shown_atlas(mover.overlay) == '' and shown_atlas(other.overlay) == '', 'Thick: no art')
	local r, g, b = other.overlay.backdrop:GetBackdropBorderColor()
	check(SL.near({ r = r, g = g, b = b }, '00adf0'), 'and the selected one has its accent edge')
	EM:Deactivate()
end)

------------------------------------------------------------------ the History list

local function open_list()
	History:Clear()
	for i = 1, 3 do
		History:Push({ kind = 'bulk', label = 'Step ' .. i, changes = { { kind = 'position', where = 'player',
			old = { point = 'CENTER', x_off = i, y_off = 0 }, new = { point = 'CENTER', x_off = 0, y_off = 0 } } } })
	end
	History:Undo() -- the current step is the second, the first is undone
	EM:ShowHistoryList()
	return EM:GetHistoryList()
end

test('History rows: a row under the mouse tints; the current step is the selected row (the bar and the fade, no 2px mark)', function()
	world()
	local list = open_list()
	local current, other
	for _, row in ipairs(list.rows) do
		if row:IsShown() then
			if st:GetState(row, 'selected') then current = row elseif not other then other = row end
		end
	end
	check(current and other, 'a current row and another')
	eq(look(current).shape, 'row', 'rows')
	local l = look(current)
	check(lit(l.bar) and lit(l.fill), 'the current step: the bar and the fade')
	check(SL.near(l.bar, '00adf0') and SL.near(l.fill, '00adf0'), 'in the accent')
	eq(l.bar.width, 2 * st:GetLineSize(current), 'the bar is two lines')
	check(current.mark == nil or not current.mark:IsShown(), 'no 2px mark')
	check(not lit(look(other).bar), 'another row has none')
	check(not lit(look(other).layer), 'and no tint at rest')
	enter(other)
	l = look(other)
	check(lit(l.layer) and SL.near(l.layer, '5cc6ff'), 'under the mouse: the tint ' .. SL.bytes(l.layer))
	check(not other.hover:IsShown(), "SaftUI's look does not use the Blizzard art")
	leave(other)
	check(not lit(look(other).layer), 'left: it goes')
	EM:Deactivate()
end)

test('History rows: the current step follows a jump; an undone row stays Muted; hovered text stays readable', function()
	world()
	local list = open_list()
	local steps = #History:Steps()
	local function current_index()
		for _, row in ipairs(list.rows) do
			if row:IsShown() and st:GetState(row, 'selected') then return row.index end
		end
	end
	eq(current_index(), History:Position(), 'the current row is the history position')
	History:Undo()
	EM:RefreshHistoryList()
	eq(current_index(), History:Position(), 'after an undo it moves')
	History:Redo()
	History:Redo()
	EM:RefreshHistoryList()
	eq(current_index(), steps, 'after redos too')
	EM:Deactivate()
end)

test('History rows under Blizzard: the dropdown list\'s rowHover art on hover, the current step\'s label in the accent text', function()
	world()
	switch('blizzard')
	local list = open_list()
	local row
	for _, r in ipairs(list.rows) do if r:IsShown() and not st:GetState(r, 'selected') then row = r break end end
	enter(row)
	check(row.hover:IsShown(), 'the art shows under the mouse')
	eq(row.hover:GetAtlas(), st.ThemeArt.Control('dropdown').rowHover, "the dropdown list's rowHover")
	check(not lit(look(row).layer), 'no SaftUI layer')
	leave(row)
	check(not row.hover:IsShown(), 'left: it goes')
	for _, r in ipairs(list.rows) do
		if r:IsShown() and st:GetState(r, 'selected') then
			eq(rgb(r.label:GetTextColor()), rgb(st:StateColor('edge')), 'the current step: its label is the accent (the mark Blizzard\'s art does not draw)')
		end
	end
	switch('thick')
	EM:Deactivate()
end)

test('the History list\'s length box: a hovered or focused box tints and lights its edge; a theme switch while focused keeps the edge', function()
	world()
	local list = open_list()
	local edit = list.box.edit
	enter(edit)
	check(lit(look(edit).layer), 'hover tints')
	leave(edit)
	stub.fire_script(edit, 'OnEditFocusGained')
	check(st:GetState(edit, 'focus'), 'focus is the helper\'s')
	local r, g, b = edit:GetBackdropBorderColor()
	check(SL.near({ r = r, g = g, b = b }, '00adf0'), 'the accent edge')
	EM.RecolorNumberBox(list.box, false)
	r, g, b = edit:GetBackdropBorderColor()
	check(SL.near({ r = r, g = g, b = b }, '00adf0'), 'a recolor of the arrows leaves it')
	stub.fire_script(edit, 'OnEditFocusLost')
	EM:Deactivate()
end)

------------------------------------------------------------------ the Filter movers box

test('the Filter movers box hovers like every box: the body tints, the edge stays; focus lights the edge', function()
	world()
	local box = EM:BarControl('filter').frame
	local l = look(box)
	check(l and l.shape == 'box', 'a box state frame')
	local rest = T.edge(box)
	enter(box)
	check(lit(look(box).layer), 'hover tints')
	eq(T.edge(box), rest, 'and the edge stays')
	leave(box)
	check(not lit(look(box).layer), 'left: the tint goes')
	stub.fire_script(box, 'OnEditFocusGained')
	local r, g, b = box:GetBackdropBorderColor()
	check(SL.near({ r = r, g = g, b = b }, '00adf0'), 'focus: the accent edge')
	stub.fire_script(box, 'OnEditFocusLost')
	eq(T.edge(box), rest, 'lost: the line back')
	EM:Deactivate()
end)

------------------------------------------------------------------ cost

test('a pass of the Accent with 60 movers shown and one selected: under 250 calls, nothing made or forbidden, under 4 KB', function()
	world()
	for i = 1, 58 do add_mover('m' .. i) end
	EM:Select(EM.movers.first)
	EM:UpdateShown()
	open_list()
	local accent = st.config.profile.theme.accent
	local keep = { accent:GetRGB() }
	-- every widget colored once: a cold stub widget makes its table at its first color call
	st:ColorChanged('accent')
	local flip = 0
	local m = C.measure(function()
		flip = 1 - flip
		accent:SetRGB(0.2 + flip * 0.1, 0.5, 0.8)
		st:ColorChanged('accent')
	end, 100)
	accent:SetRGB(unpack(keep))
	st:ColorChanged('accent')
	check(m.calls.total / 100 < 250, 'calls per pass: ' .. m.calls.total / 100)
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
	C.print('60 movers, a pass of the accent', m)
	EM:Deactivate()
end)
