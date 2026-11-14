-- Which movers show in edit mode (SaftUI-Core/EditMode/filter.lua, Bar/barshow.lua):
-- the one rule (the module choice and the filter, then disabled under Show
-- disabled and hidden under Show hidden), the module list and its face, the
-- filter box, a selected mover that stops showing, a frame that comes on
-- screen while edit mode is open, and the labels of movers that overlap.
--
-- Real: the /sui window's world, edit mode's files and the bar's. Movers are
-- registered with st:RegisterConfigMover on bare frames; their predicates are
-- the test's. The mouse is played by stub.cursor_x/y and firing scripts, the
-- game's time by firing the ticker's OnUpdate with a delta.

local P = load_test_file('lib/pixels.lua')

local H, st, EM, W

local function build()
	H = load_test_file('core/options_window_helpers.lua')
	load_editmode_bar()
	st = SaftUI
	EM, W = st.EditModeFrames, st.OptionsWidgets
	EM:Enable()
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
end

build()

local function settings() return EM:GetSettings() end
local function control(key) return EM:BarControl(key) end
local function frame_of(key) return EM:BarControl(key).frame end

local function set_screen(width, height)
	stub.screen_width, stub.screen_height = width, height
	UIParent:SetScale(768 / height)
end

local added = {}

-- A mover on a 100 x 50 frame at x, y from the screen's middle. extra: module,
-- isDisabled, isHidden, label. apply puts the frame where its position says.
local function add_mover(key, extra)
	extra = extra or {}
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(100, 50)
	local config = { position = { point = 'CENTER', x_off = extra.x or 0, y_off = extra.y or 0 } }
	local function apply()
		local pos = config.position
		frame:ClearAllPoints()
		frame:SetPoint(pos.point, UIParent, pos.point, tonumber(pos.x_off) or 0, tonumber(pos.y_off) or 0)
	end
	apply()
	local spec = { key = key, config = function() return config end, apply = apply }
	for field, value in pairs(extra) do
		if field ~= 'x' and field ~= 'y' then spec[field] = value end
	end
	local mover = st:RegisterConfigMover(frame, spec)
	added[key] = true
	return mover, config
end

local function look(name)
	st.config.profile.theme.name = name
	st:ThemeChanged()
end

local function reset()
	if EM.active then EM:Deactivate() end
	for key in pairs(added) do
		local mover = EM.movers[key]
		if mover then mover.overlay:Hide() end
		EM.movers[key] = nil
		added[key] = nil
	end
	local s = settings()
	s.show_hidden, s.show_disabled, s.hidden_modules = true, false, {}
	s.grid, s.snap_grid, s.snap_frames, s.coordinates, s.dim = false, false, false, false, true
	EM:SetFilter('')
	stub.in_combat = false
	stub.size_noise = 0
	set_screen(1920, 1080)
	look('thick')
	H.close_all()
end

local function names(list) return table.concat(list, ',') end

------------------------------------------------------------------ the rule

test('the settings: Show hidden is on and Show disabled off by default, no module is unticked', function()
	local defaults = st.defaults.editmode
	eq(defaults.show_hidden, true, 'Show hidden on')
	eq(defaults.show_disabled, false, 'Show disabled off')
	eq(type(defaults.hidden_modules), 'table', 'hidden_modules is a table')
	eq(next(defaults.hidden_modules), nil, 'and empty')
	check(settings().show_hidden == true and settings().show_disabled == false, 'the profile has them')
end)

test('one rule: the module choice and the filter first, then disabled under Show disabled, hidden under Show hidden', function()
	local a = add_mover('a', { module = 'Chat', label = 'Chat' })
	local d = add_mover('d', { module = 'Unit frames', label = 'Boss', isDisabled = function() return true end })
	local h = add_mover('h', { module = 'Unit frames', label = 'Target', isHidden = function() return true end })
	settings().show_hidden = false
	EM:Activate()
	check(a.overlay:IsShown() and not d.overlay:IsShown() and not h.overlay:IsShown(), 'both toggles off: only the shown one')
	EM:SetSetting('show_hidden', true)
	check(h.overlay:IsShown() and not d.overlay:IsShown(), 'Show hidden: the hidden one')
	EM:SetSetting('show_disabled', true)
	check(d.overlay:IsShown(), 'Show disabled: the disabled one')
	EM:SetModuleShown('Unit frames', false)
	check(not d.overlay:IsShown() and not h.overlay:IsShown() and a.overlay:IsShown(), 'a module unticked hides its movers whatever the toggles')
	eq(settings().hidden_modules['Unit frames'], true, 'the profile has the module unticked')
	EM:SetModuleShown('Unit frames', true)
	eq(settings().hidden_modules['Unit frames'], nil, 'ticked again: the key is cleared, not false')
	check(d.overlay:IsShown() and h.overlay:IsShown(), 'both back')
	-- A disabled mover that is also hidden follows Show disabled alone.
	local both = add_mover('both', { module = 'Chat', isDisabled = function() return true end, isHidden = function() return true end })
	EM:SetSetting('show_disabled', false)
	EM:SetSetting('show_hidden', true)
	check(not both.overlay:IsShown(), 'disabled and hidden: Show hidden does not bring it back')
	-- A predicate that errors, or answers something other than true, counts as no.
	local bad = add_mover('bad', { isHidden = function() return 1 end, isDisabled = function() return 'yes' end })
	check(bad.overlay:IsShown(), 'a predicate that answers non-true shows the mover')
	-- A mover added while edit mode is on follows the rule at once.
	local late = add_mover('late', { isHidden = function() return true end })
	check(late.overlay:IsShown(), 'a late hidden mover under Show hidden shows')
	EM:SetSetting('show_hidden', false)
	local late2 = add_mover('late2', { isHidden = function() return true end })
	check(not late2.overlay:IsShown(), 'a late hidden mover without it does not')
	-- Turning edit mode off hides every overlay.
	EM:Deactivate()
	check(not a.overlay:IsShown(), 'off: nothing shows')
	EM:SetSetting('show_hidden', true)
	check(not h.overlay:IsShown(), 'a setting changed while edit mode is off shows nothing')
	reset()
end)

------------------------------------------------------------------ the modules

test('the module list holds only modules with movers, alphabetical, Other last; the face says what shows', function()
	add_mover('u', { module = 'Unit frames' })
	add_mover('c', { module = 'Chat' })
	add_mover('o')
	add_mover('c2', { module = 'Chat' })
	eq(names(EM:GetModules()), 'Chat,Unit frames,Other', 'sorted, one each, Other last')
	local all = function() return true end
	eq(EM.ShowFaceText(EM:GetModules(), all), 'All modules', 'all')
	eq(EM.ShowFaceText(EM:GetModules(), function(n) return n == 'Chat' end), 'Chat', 'one')
	eq(EM.ShowFaceText(EM:GetModules(), function(n) return n ~= 'Other' end), '2 modules', 'two of three')
	eq(EM.ShowFaceText(EM:GetModules(), function() return false end), 'Nothing', 'none')
	EM:Activate()
	local face = frame_of('modules')
	eq(face.text:GetText(), 'All modules', 'the face reads All modules')
	stub.click(face)
	eq(W.ListOwner(), face, 'a click on the face opens the list under it')
	local list = W.GetListFrames()
	eq(list.rows[1].entry.label .. ',' .. list.rows[2].entry.label .. ',' .. list.rows[3].entry.label, 'Chat,Unit frames,Other', 'a row each')
	eq(list.rows[4] and list.rows[4]:IsShown() or false, false, 'and no more')
	-- A row applies at once and keeps the list open.
	stub.click(list.rows[2])
	eq(EM:IsModuleShown('Unit frames'), false, 'the row unticked its module')
	check(not EM.movers.u.overlay:IsShown() and EM.movers.c.overlay:IsShown(), 'its mover is gone at once')
	eq(W.ListOwner(), face, 'the list is still open')
	eq(face.text:GetText(), '2 modules', 'the face follows')
	-- None and All.
	stub.click(list.checkButtons[2])
	for i = 1, 3 do check(not list.rows[i].box.mark:IsShown(), 'None: row ' .. i .. ' unchecked') end
	eq(W.ListOwner(), face, 'None keeps the list open')
	eq(face.text:GetText(), 'Nothing', 'Nothing')
	check(not EM.movers.c.overlay:IsShown() and not EM.movers.o.overlay:IsShown(), 'no mover shows')
	stub.click(list.checkButtons[1])
	for i = 1, 3 do check(list.rows[i].box.mark:IsShown(), 'All: row ' .. i .. ' checked') end
	eq(face.text:GetText(), 'All modules', 'All modules')
	check(EM.movers.u.overlay:IsShown(), 'every mover shows')
	eq(next(settings().hidden_modules), nil, 'the profile holds no key')
	eq(list.checkButtons[1].text:GetText() .. list.checkButtons[2].text:GetText(), 'AllNone', 'the buttons')
	W.CloseList()
	reset()
end)

------------------------------------------------------------------ the filter

test('the filter narrows inside the choice, never brings one back, and Enter selects the first match', function()
	local t = add_mover('t', { module = 'Unit frames', label = 'Target', x = -300 })
	local t2 = add_mover('t2', { module = 'Chat', label = 'Target 2', x = 300 })
	local b = add_mover('b', { module = 'Chat', label = 'Bar 2', y = 200 })
	-- Under the bar: its top is UIParent's top. Another named bar, in an unticked module, sorts first.
	local b1 = add_mover('b1', { module = 'Chat', label = 'bar 1', y = UIParent:GetHeight() / 2 - 25 })
	local b0 = add_mover('b0', { module = 'Hid', label = 'bar 0', y = -200 })
	EM:SetModuleShown('Hid', false)
	EM:Activate()
	EM:SetModuleShown('Chat', false)
	EM:SetFilter('TAR')
	eq(EM.filterText, 'tar', 'kept lowercase')
	check(t.overlay:IsShown(), "'Target' matches")
	check(not t2.overlay:IsShown(), 'Target 2 is in an unticked module: it stays hidden')
	check(not b.overlay:IsShown(), 'Bar 2 does not match')
	check(EM:MatchesFilter(t) and not EM:MatchesFilter(b), 'MatchesFilter')
	EM:SetFilter('(')
	check(not EM:MatchesFilter(t), 'a plain find: no pattern characters')
	EM:SetModuleShown('Chat', true)
	EM:SetFilter('')
	check(t.overlay:IsShown() and t2.overlay:IsShown() and b.overlay:IsShown(), 'cleared: everything shows')

	-- The box.
	local box = frame_of('filter')
	box:SetText('bar')
	eq(EM.filterText, 'bar', 'typing sets the filter')
	check(not t.overlay:IsShown() and b.overlay:IsShown() and b1.overlay:IsShown() and not b0.overlay:IsShown(), 'only the bars show')
	box:SetFocus()
	stub.fire_script(box, 'OnEnterPressed')
	eq(EM.selected, b1, 'Enter selects the first match that is shown, by name, ignoring case (not bar 0 in an unticked module)')
	check(GetCurrentKeyBoardFocus() == nil, 'and drops the focus')
	-- The arrow keys reach the nudge through edit mode's key catcher.
	local x0 = b1.def.getPosition().x_off
	stub.fire_script(EM.keyCatcher, 'OnKeyDown', 'RIGHT')
	eq(b1.def.getPosition().x_off, x0 + 1, 'the arrow nudges it, with no click on the mover')
	-- Esc clears.
	box:SetFocus()
	stub.fire_script(box, 'OnEscapePressed')
	eq(box:GetText(), '', 'Esc empties the box')
	eq(EM.filterText, '', 'the filter')
	check(GetCurrentKeyBoardFocus() == nil, 'and drops the focus')
	check(t.overlay:IsShown(), 'every mover is back')
	-- Enter with nothing matching changes nothing.
	EM:Select(nil)
	box:SetText('zzz')
	eq(EM:SelectFirstMatch(), nil, 'no match')
	eq(EM.selected, nil, 'nothing selected')
	-- Disabled clears it.
	box:SetText('bar')
	EM:Deactivate()
	eq(EM.filterText, '', 'edit mode off: the filter is cleared')
	eq(box:GetText(), '', 'and the box')
	reset()
end)

test('the filter box drops focus when a mover is pressed or dragged, and when edit mode closes', function()
	local m = add_mover('f1')
	EM:Activate()
	local box = frame_of('filter')
	for _, event in ipairs({ 'Pressed', 'DragStarted' }) do
		box:SetFocus()
		check(GetCurrentKeyBoardFocus() == box, 'focused')
		EM:Fire(event, m)
		check(GetCurrentKeyBoardFocus() == nil, event .. ' drops the focus')
	end
	EM:Fire('DragStopped', m) -- the fake drag is over
	box:SetFocus()
	EM:Deactivate()
	check(GetCurrentKeyBoardFocus() == nil, 'Disabled drops the focus')
	reset()
end)

------------------------------------------------------------------ what stops showing

test('a selected mover that stops showing is deselected; an Alt pick and snapping leave it out', function()
	local a = add_mover('a')
	local h = add_mover('h', { isHidden = function() return true end })
	EM:Activate()
	EM:Select(h)
	EM:SetSetting('show_hidden', false)
	eq(EM.selected, nil, 'deselected with Show hidden off')
	eq(EM.coordinates:IsShown(), false, 'and its label goes')
	EM:SetSetting('coordinates', true)
	EM:Select(a)
	check(EM.coordinates:IsShown(), 'a selected shown one has its label')
	EM:SetFilter('zzz')
	eq(EM.selected, nil, 'a filter that leaves it out deselects it too')
	check(not EM.coordinates:IsShown(), 'the label goes with it')
	EM:SetFilter('')

	-- The picker: cursor over a and h, the pointer on a's outline.
	local realFoci = GetMouseFoci
	GetMouseFoci = function() return { a.overlay } end
	stub.cursor_x = UIParent:GetWidth() / 2 * UIParent:GetEffectiveScale()
	stub.cursor_y = UIParent:GetHeight() / 2 * UIParent:GetEffectiveScale()
	local state = EM.GetPickerState()
	stub.fire_script(state.driver, 'OnUpdate', 1)
	eq(#state.stack, 1, 'one mover under the cursor')
	eq(state.stack[1], a, 'a only: h is not shown')
	EM:SetSetting('show_hidden', true)
	stub.fire_script(state.driver, 'OnUpdate', 1)
	eq(#EM.GetPickerState().stack, 2, 'with Show hidden on, h joins the stack')
	check(state.list:IsShown(), 'and the list shows')
	EM:SetSetting('show_hidden', false)
	stub.fire_script(state.driver, 'OnUpdate', 1)
	check(not state.list:IsShown(), 'Show hidden off: the list goes')
	GetMouseFoci = realFoci

	-- Snapping.
	EM:SetSetting('snap_frames', true)
	EM:SetSetting('show_hidden', false)
	local free = add_mover('free', { x = 500 })
	local far = add_mover('far', { x = -400, isHidden = function() return true end })
	local xl = EM:GetSnapLines(free)
	local l, r = EM.GetOutlineRect(far)
	local function has(list, v)
		for _, x in ipairs(list) do if math.abs(x - v) < 1e-6 then return true end end
		return false
	end
	check(not has(xl, l) and not has(xl, r), "the hidden mover's outline is no snap line")
	EM:SetSetting('show_hidden', true)
	xl = EM:GetSnapLines(free)
	check(has(xl, l) and has(xl, r), 'shown, it is')
	reset()
end)

test('a frame that comes on screen in edit mode gets its mover within half a second', function()
	local state = { hidden = true }
	local m = add_mover('late', { isHidden = function() return state.hidden end })
	settings().show_hidden = false
	EM:Activate()
	check(not m.overlay:IsShown(), 'hidden: not shown')
	state.hidden = false
	check(not m.overlay:IsShown(), 'nothing runs by itself')
	eq(EM.SHOWN_INTERVAL, 0.5, 'half a second')
	stub.fire_script(EM.shownFrame, 'OnUpdate', 0.3)
	check(not m.overlay:IsShown(), 'not yet')
	stub.fire_script(EM.shownFrame, 'OnUpdate', 0.3)
	check(m.overlay:IsShown(), 'shown after the interval')
	state.hidden = true
	stub.fire_script(EM.shownFrame, 'OnUpdate', 0.6)
	check(not m.overlay:IsShown(), 'and gone again when its frame is')
	local fired = 0
	EM:On('ShownChanged', function() fired = fired + 1 end)
	stub.fire_script(EM.shownFrame, 'OnUpdate', 0.6)
	eq(fired, 0, 'ShownChanged is silent while nothing changed')
	state.hidden = false
	settings().show_hidden = true
	stub.fire_script(EM.shownFrame, 'OnUpdate', 0.6)
	eq(fired, 1, 'ShownChanged fires once when a mover appears')
	stub.fire_script(EM.shownFrame, 'OnUpdate', 0.6)
	eq(fired, 1, 'and not again')
	local o = add_mover('o2', { x = 20 })
	stub.fire_script(EM.shownFrame, 'OnUpdate', 0.6)
	check(o.overlaps and m.overlaps, 'a mover now overlaps it')
	eq(fired, 2, 'a changed overlap state fires it')
	EM:Deactivate()
	check(not EM.shownFrame:IsShown(), 'the ticker stops with edit mode')
	reset()
end)

------------------------------------------------------------------ overlapping labels

test('where movers overlap, only the one under the mouse shows its label', function()
	local p = add_mover('p', { label = 'Bar 4', x = 0 })
	local q = add_mover('q', { label = 'Bar 5', x = 30 })
	local r = add_mover('r', { label = 'Bar 6', y = 300 })
	EM:Activate()
	check(p.overlaps and q.overlaps and not r.overlaps, 'p and q overlap, r does not')
	check(not p.label:IsShown() and not q.label:IsShown() and r.label:IsShown(), 'p and q labels hidden, r shown')
	EM:UpdateLabels(p)
	check(p.label:IsShown() and not q.label:IsShown() and r.label:IsShown(), "the hovered one's label shows")
	EM:UpdateLabels(nil)
	check(not p.label:IsShown(), 'no hover: hidden again')
	-- q dragged clear.
	EM:CommitPosition(q, -600, 0)
	check(not p.overlaps and not q.overlaps, 'clear of each other')
	check(p.label:IsShown() and q.label:IsShown() and r.label:IsShown(), 'every label shows again')
	-- Touching edges is not overlapping: p's outline and one just beside it.
	local l, rr = EM.GetOutlineRect(p)
	check(EM.RectsOverlap({ left = 0, right = 10, bottom = 0, top = 10 }, { left = 5, right = 15, bottom = 5, top = 15 }), 'sharing area')
	check(not EM.RectsOverlap({ left = 0, right = 10, bottom = 0, top = 10 }, { left = 10, right = 20, bottom = 0, top = 10 }), 'sharing an edge')
	check(not EM.RectsOverlap({ left = 0, right = 10, bottom = 0, top = 10 }, { left = 20, right = 30, bottom = 0, top = 10 }), 'apart')
	check(l and rr, 'the outline rect reads')
	-- A hidden mover is no overlap.
	local g = add_mover('g', { label = 'Ghost', x = 0, isHidden = function() return true end })
	settings().show_hidden = false
	EM:UpdateShown()
	check(not g.overlay:IsShown() and not p.overlaps, 'a mover that does not show overlaps nothing')
	reset()
end)

test("the picker tells the labels which mover is under the mouse", function()
	local p = add_mover('p', { label = 'Bar 4', x = 0 })
	local q = add_mover('q', { label = 'Bar 5', x = 30 })
	EM:Activate()
	local realFoci = GetMouseFoci
	GetMouseFoci = function() return { q.overlay } end
	-- Over q's own part (right of p's rect): the cursor on q only.
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x = (UIParent:GetWidth() / 2 + 70) * scale
	stub.cursor_y = UIParent:GetHeight() / 2 * scale
	stub.fire_script(EM.GetPickerState().driver, 'OnUpdate', 1)
	check(q.label:IsShown() and not p.label:IsShown(), 'over q alone: its label shows, p stays hidden')
	stub.cursor_x = (UIParent:GetWidth() / 2 + 500) * scale
	stub.fire_script(EM.GetPickerState().driver, 'OnUpdate', 1)
	check(not q.label:IsShown() and not p.label:IsShown(), 'the cursor away: both hidden again')
	GetMouseFoci = realFoci
	reset()
end)

------------------------------------------------------------------ the bar's controls

test('the Show group: caption, the two toggles, the module face; the filter group', function()
	EM:Activate()
	eq(control('showDisabled').group.key, 'show', 'Show disabled is in the show group')
	eq(control('showHidden').group.key, 'show', 'Show hidden too')
	eq(control('modules').group.key, 'show', 'and the face')
	eq(control('caption').group.key, 'show', 'and the caption')
	eq(control('filter').group.key, 'filter', 'the filter has its own group')
	eq(control('filter').section, 'show', 'in the floating window it is the show section')
	eq(control('caption').frame.text:GetText(), 'Show', 'the caption says Show')
	-- State.
	local hidden, disabled = frame_of('showHidden'), frame_of('showDisabled')
	check(hidden.on == true and disabled.on ~= true, 'Show hidden lit, Show disabled not, by default')
	stub.click(disabled)
	eq(settings().show_disabled, true, 'a click turns Show disabled on')
	check(disabled.on == true, 'lit')
	stub.click(hidden)
	eq(settings().show_hidden, false, 'a click turns Show hidden off')
	-- Tooltips.
	local lines = {}
	local realAdd = GameTooltip.AddLine
	GameTooltip.AddLine = function(self, text, ...) lines[#lines + 1] = text; return realAdd(self, text, ...) end
	stub.fire_script(disabled, 'OnEnter', true)
	eq(lines[1], 'Show disabled', 'a title')
	eq(lines[2], "Shows the movers of frames you've turned off.", 'and its line')
	lines = {}
	stub.fire_script(disabled, 'OnLeave', true)
	stub.fire_script(hidden, 'OnEnter', true)
	eq(lines[1], 'Show hidden', 'Show hidden title')
	eq(lines[2], "Shows the movers of frames that aren't on screen right now: closed bags, no pet, no boss.", 'its line')
	stub.fire_script(hidden, 'OnLeave', true)
	GameTooltip.AddLine = realAdd
	-- Combat: nothing.
	stub.in_combat = true
	stub.click(hidden)
	eq(settings().show_hidden, false, 'a click in combat does nothing')
	stub.in_combat = false
	-- Widths by stage.
	local caption, face, filter = control('caption'), control('modules'), control('filter')
	eq(caption:Lay(0, false) > 0 and caption:Lay(1, false) > 0 and caption:Lay(2, false), 0, 'the caption goes at stage 2')
	eq(caption:Lay(0, true), 0, 'and when floating')
	eq(face:Lay(0, false) .. ',' .. face:Lay(2, false) .. ',' .. face:Lay(3, false) .. ',' .. face:Lay(0, true), '150,150,110,140', 'the face: 150, 110 from stage 3, 140 floating')
	eq(filter:Lay(0, false) .. ',' .. filter:Lay(1, false) .. ',' .. filter:Lay(4, false) .. ',' .. filter:Lay(5, false) .. ',' .. filter:Lay(0, true),
		'150,100,100,0,140', 'the filter: 150, 100 from stage 1, 0 at stage 5, 140 floating')
	eq(frame_of('filter'):GetHeight(), W.Kit.FIELD_HEIGHT, 'FIELD_HEIGHT tall')
	local c0 = EM:LayoutBar()
	check(c0 >= 0, 'the bar lays out')
	reset()
end)

test('a narrow bar gives up the caption, then narrows the face, then drops the filter', function()
	EM:Activate()
	local wide = EM:BarWidthAt(0)
	check(EM:BarWidthAt(1) < wide, 'stage 1 narrows the filter box')
	check(EM:BarWidthAt(2) < EM:BarWidthAt(1), 'stage 2 hides the caption')
	check(EM:BarWidthAt(3) < EM:BarWidthAt(2), 'stage 3 narrows the face')
	check(EM:BarWidthAt(5) < EM:BarWidthAt(4), 'stage 5 hides the filter')
	set_screen(1920, 1080)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(EM:LayoutBar(), 0, 'a wide screen: stage 0')
	local width = EM:BarWidthAt(3)
	set_screen(width, 600)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	check(EM:LayoutBar() >= 3, 'a narrow one: at least stage 3')
	reset()
end)

test('a filter typed at a wide stage is cleared, and the status says so, when the bar narrows until its box is gone', function()
	local a = add_mover('apple', { label = 'Apple' })
	local b = add_mover('banana', { label = 'Banana' })
	EM:Activate()
	local box = frame_of('filter')
	box:SetText('app')
	eq(EM.filterText, 'app', 'a filter is on')
	check(a.overlay:IsShown() and not b.overlay:IsShown(), 'only Apple shows')
	set_screen(EM:BarWidthAt(4) + 1, 600)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(EM:LayoutBar(), 4, 'stage 4 keeps the box')
	eq(EM.filterText, 'app', 'and the filter')
	set_screen(EM:BarWidthAt(5), 600)
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	eq(EM:LayoutBar(), 5, 'stage 5')
	check(not box:IsShown(), 'the box is gone')
	eq(EM.filterText, '', 'so the filter is cleared')
	eq(box:GetText(), '', 'and the box with it')
	check(b.overlay:IsShown(), 'Banana shows again')
	check(EM.statusText:GetText():find('Filter cleared', 1, true), 'the status says so')
	reset()
end)

test('the Show group and the filter under Blizzard: the Settings dropdown and the search box art', function()
	EM:Activate()
	local face, box = frame_of('modules'), frame_of('filter')
	look('blizzard')
	EM:RefreshBar()
	local function atlases(frame)
		local out = {}
		for _, region in ipairs({ frame:GetRegions() }) do
			if region:GetObjectType() == 'Texture' and region:IsShown() and region:GetAtlas() then out[#out + 1] = region:GetAtlas() end
		end
		table.sort(out)
		return table.concat(out, ',')
	end
	eq(atlases(face), 'common-dropdown-c-button', "the face wears Blizzard's dropdown")
	check(atlases(box):find('common-search-border-middle', 1, true), "the filter wears the search box's art")
	eq(box.icon:IsShown(), false, "the Lucide glass is hidden: Blizzard's is drawn")
	local left = select(1, box:GetTextInsets())
	check(left > 6 + 10, 'the text starts clear of the glass')
	local blue = frame_of('showHidden')
	local r, g, b = blue.icon:GetVertexColor()
	local accent = st.config.profile.colors.button.blue
	local ar, ag, ab = accent:GetRGB()
	check(math.abs(r - ar) < 1e-3 and math.abs(g - ag) < 1e-3 and math.abs(b - ab) < 1e-3, 'Show hidden is on: its icon is in the accent')
	look('thick')
	EM:RefreshBar()
	eq(box.icon:IsShown(), true, 'Thick: the Lucide glass shows')
	eq(select(1, box:GetTextInsets()), 6 + 16 + 4, 'the text starts clear of it')
	eq(box.hint:GetText(), 'Filter movers...', 'the hint')
	box:SetText('x')
	eq(box.hint:IsShown(), false, 'text: no hint')
	box:SetText('')
	eq(box.hint:IsShown(), true, 'empty: the hint')
	reset()
end)

test("the Show group's pieces sit on whole pixels, under each look, at any screen, with the game's read-back noise", function()
	local HAIR = 2 ^ -14
	EM:Activate()
	local bar = EM:GetBar()
	EM:SetFilter('')
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		look(name)
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			stub.size_noise = noise
			for _, screen in ipairs({ { 1920, 1080 }, { 1366, 768 }, { 1024, 768 }, { 800, 600 } }) do
				set_screen(screen[1], screen[2])
				stub.fire_event('DISPLAY_SIZE_CHANGED')
				local where = ('%s noise %s at %dx%d: '):format(name, noise, screen[1], screen[2])
				local off = P.off(bar)
				eq(#off, 0, where .. P.report(off))
				local box = frame_of('filter')
				box:SetFocus()
				off = P.off(bar)
				eq(#off, 0, where .. 'filter focused: ' .. P.report(off))
				box:ClearFocus()
			end
		end
	end
	reset()
end)

------------------------------------------------------------------ the frames' own rects

test('movers overlap by their frames own rects, more than a pixel: frames that touch or sit a few pixels apart keep their labels', function()
	look('thick')
	local p, pc = add_mover('p', { label = 'Bar 4', x = 0 })
	local q, qc = add_mover('q', { label = 'Bar 5', x = 100 })
	EM:Activate()
	local function at(x)
		qc.position.x_off = x
		q.def.apply()
		EM:UpdateShown()
	end
	for _, gap in ipairs({ 0, 1, 2, 3 }) do
		at(100 + gap)
		check(not p.overlaps and not q.overlaps, gap .. ' px apart under Thick: no overlap')
		check(p.label:IsShown() and q.label:IsShown(), gap .. ' px apart: both labels show')
	end
	at(100 - 1e-4)
	check(not p.overlaps and p.label:IsShown() and q.label:IsShown(), 'a read-back error of 1e-4 is not an overlap')
	at(99)
	check(not p.overlaps, 'overlapping by exactly 1 px: still not')
	at(98)
	check(p.overlaps and q.overlaps, 'by 2 px: overlapping')
	check(not p.label:IsShown() and not q.label:IsShown(), 'both labels hidden')
	EM:UpdateLabels(p)
	check(p.label:IsShown() and not q.label:IsShown(), 'the hovered one shows')
	look('thin')
	at(101)
	check(not p.overlaps, 'Thin: a pixel apart, no overlap')
	reset()
end)

test('a mover being dragged keeps its label for the drag, and its overlay though its frame stops showing, until the drop', function()
	local p = add_mover('p', { label = 'Bar 4', x = 0 })
	local gone = false
	local q = add_mover('q', { label = 'Bar 5', x = 30, isHidden = function() return gone end })
	settings().show_hidden = false
	EM:Activate()
	check(not q.label:IsShown() and not p.label:IsShown(), 'overlapping: both hidden')
	stub.cursor_x, stub.cursor_y = 500, 500
	EM:StartDrag(q)
	check(q.label:IsShown() and not p.label:IsShown(), 'dragged: its label shows at once')
	EM:UpdateLabels(nil)
	check(q.label:IsShown(), 'and stays through label updates')
	gone = true
	stub.fire_script(EM.shownFrame, 'OnUpdate', 0.6)
	check(q.overlay:IsShown(), 'its frame stopped showing: the ticker leaves its overlay')
	EM:UpdateShown()
	check(q.overlay:IsShown(), 'so does UpdateShown')
	EM:StopDrag(q)
	check(not q.overlay:IsShown(), 'after the drop the rule applies')
	reset()
end)

------------------------------------------------------------------ guards, hint, tooltips, errors

test('the filter box and the module face do nothing in combat; the hint hides while the box has focus', function()
	local m = add_mover('barx', { label = 'Bar X' })
	EM:Activate()
	local box, face = frame_of('filter'), frame_of('modules')
	box:SetText('bar')
	stub.in_combat = true
	stub.fire_script(box, 'OnEnterPressed')
	eq(EM.selected, nil, 'Enter in combat selects nothing')
	stub.click(face)
	eq(W.ListOwner(), nil, 'the face opens no list in combat')
	stub.in_combat = false
	stub.click(face)
	eq(W.ListOwner(), face, 'out of combat it does')
	W.CloseList()
	box:SetText('')
	check(box.hint:IsShown(), 'empty and unfocused: the hint shows')
	box:SetFocus()
	check(not box.hint:IsShown(), 'focused: no hint')
	box:ClearFocus()
	check(box.hint:IsShown(), 'focus gone: the hint is back')
	reset()
end)

test('one module reads All modules whatever its name; two with one ticked read that name', function()
	add_mover('only', { module = 'Chat' })
	eq(EM.ShowFaceText(EM:GetModules(), function() return true end), 'All modules', 'a single ticked module')
	eq(EM.ShowFaceText(EM:GetModules(), function() return false end), 'Nothing', 'a single unticked one')
	reset()
end)

test('the Show face and the filter have their tooltips; the hint stays inside the box', function()
	EM:Activate()
	local lines = {}
	local realAdd = GameTooltip.AddLine
	GameTooltip.AddLine = function(self, text, ...) lines[#lines + 1] = text; return realAdd(self, text, ...) end
	local face, box = frame_of('modules'), frame_of('filter')
	stub.fire_script(face, 'OnEnter', true)
	eq(lines[1] .. '|' .. tostring(lines[2]), "Show|Which modules' movers edit mode shows.", 'the face')
	stub.fire_script(face, 'OnLeave', true)
	lines = {}
	stub.fire_script(box, 'OnEnter', true)
	eq(lines[1] .. '|' .. tostring(lines[2]),
		'Filter movers|Shows only the movers whose name has this text. Enter selects the first one, Esc clears it.', 'the filter')
	stub.fire_script(box, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'and it goes')
	GameTooltip.AddLine = realAdd
	local right = false
	for i = 1, box.hint:GetNumPoints() do
		if box.hint:GetPoint(i) == 'RIGHT' then right = true end
	end
	check(right, "the hint is anchored at its right edge too: it is cut at the box's")
	reset()
end)

test('a predicate that errors is reported once per mover for a session of edit mode, not every tick', function()
	local m = add_mover('bad', { isHidden = function() error('boom') end })
	take_errors()
	EM:Activate()
	for _ = 1, 5 do stub.fire_script(EM.shownFrame, 'OnUpdate', 0.6) end
	eq(#take_errors(), 1, 'one report for the session')
	check(m.overlay:IsShown(), 'its mover shows (the predicate counts as false)')
	EM:Deactivate()
	EM:Activate()
	eq(#take_errors(), 1, 'a new session reports it again')
	reset()
end)
