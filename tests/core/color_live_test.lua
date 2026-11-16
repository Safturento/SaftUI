-- How a color change reaches what draws it (SaftUI-Core/Media/colors.lua):
-- st:ColorChanged, followers (st:FollowColor), edits (st:BeginColorEdit,
-- st:EndColorEdit), the pass once a frame, the whole pass, the budget guard
-- and the debug line, the Colors rows' calls, the picker beginning and ending
-- an edit, the profile update's whole passes, and Config's font objects.
-- Every reader's own test is in its addon's folder; these run on followers and
-- a stand-in module.
--
-- Real: Core's config on a real AceDB (the widgets world), the options kit's
-- color field and picker, the Colors tab and the theme. The clock the guard
-- reads (debugprofilestop) is a stand-in a paint moves.
local H = load_test_file('core/options_widgets_helpers.lua')
load_editmode_bar() -- the real edit mode, off: a pass costs it nothing (editmode_colors_test.lua)
local C = load_test_file('lib/color_cost.lua')
local st = SaftUI
local W = st.OptionsWidgets
local OM = st.OptionsModel
local CO = st:GetModule('Colors')
local click = H.click

-- A stand-in module: what it was told, as 'group:key' ('text:nil' is a whole pass).
local seen = {}
local M = st:NewModule('LiveProbe')
function M:OnColorsChanged(group, key) seen[#seen + 1] = group .. ':' .. tostring(key) end
local function told() local out = table.concat(seen, ','); return out end
local function forget() for i = #seen, 1, -1 do seen[i] = nil end end

-- Followers record the key they were painted with.
local function Obj() return { painted = {} } end
local function P(object, key) object.painted[#object.painted + 1] = tostring(key) end
local function painted(object) return table.concat(object.painted, ',') end

local function reset()
	st:EndColorEdit()
	W.CloseColorPicker()
	stub.in_combat = false
	forget()
end

test("outside an edit a change passes at once: the color's followers, the group's, then each module", function()
	reset()
	local a, b, c = Obj(), Obj(), Obj()
	local order = {}
	local function mark(name) return function(object, key) order[#order + 1] = name .. ':' .. tostring(key) end end
	st:FollowColor(a, 'text', 'danger', mark('a'))
	st:FollowColor(b, 'text', nil, mark('b'))
	st:FollowColor(c, 'text', 'muted', mark('c'))
	st:ColorChanged('text', 'danger')
	eq(table.concat(order, ','), 'a:danger,b:danger', "the color's follower, then the group's, with the key; not Muted's")
	eq(told(), 'text:danger')
	eq(#take_errors(), 0)
	for _, o in ipairs({ a, b, c }) do st:UnfollowColor(o) end
end)

test('during an edit changes wait for the next frame, and one pass runs however many came', function()
	reset()
	local a, b = Obj(), Obj()
	st:FollowColor(a, 'class', 'MAGE', P)
	st:FollowColor(b, 'text', 'danger', P)
	st:BeginColorEdit()
	check(st:InColorEdit(), 'an edit is on')
	for _ = 1, 50 do st:ColorChanged('class', 'MAGE') end
	for _ = 1, 50 do st:ColorChanged('text', 'danger') end
	eq(painted(a) .. painted(b), '', 'nothing painted yet')
	eq(told(), '', 'nor told')
	check(CO.ticker:IsShown(), 'a pass is due')
	C.step(st)
	eq(painted(a), 'MAGE', 'once')
	eq(painted(b), 'danger', 'once')
	eq(told(), 'class:MAGE,text:danger', 'in the order marked')
	check(not CO.ticker:IsShown(), 'nothing is due now')
	C.step(st)
	eq(told(), 'class:MAGE,text:danger', 'a frame with nothing marked passes nothing')
	st:EndColorEdit()
	st:UnfollowColor(a); st:UnfollowColor(b)
end)

test("an edit's end runs the whole pass of each group it touched, in the order first touched, dropping a pass still due", function()
	reset()
	st:BeginColorEdit()
	st:ColorChanged('text', 'danger')
	C.step(st)
	st:ColorChanged('class', 'MAGE')
	st:ColorChanged('text', 'muted')
	st:EndColorEdit()
	eq(told(), 'text:danger,text:nil,class:nil', 'the pass that ran, then each touched group once; the due ones dropped')
	check(not st:InColorEdit(), 'the edit is over')
	check(not CO.ticker:IsShown(), 'nothing is due')
	C.step(st)
	eq(told(), 'text:danger,text:nil,class:nil', 'and none runs after')
end)

test('st:ColorsChanged(group) is the whole pass: every follower of the group with key nil, then each module with no key', function()
	reset()
	local a, b, c, other = Obj(), Obj(), Obj(), Obj()
	st:FollowColor(a, 'text', 'danger', P)
	st:FollowColor(b, 'text', nil, P)
	st:FollowColor(c, 'text', 'muted', P)
	st:FollowColor(other, 'class', 'MAGE', P)
	st:ColorsChanged('text')
	eq(painted(a) .. '|' .. painted(b) .. '|' .. painted(c) .. '|' .. painted(other), 'nil|nil|nil|', 'every follower of Text, none of Class')
	eq(told(), 'text:nil')
	for _, o in ipairs({ a, b, c, other }) do st:UnfollowColor(o) end
end)

------------------------------------------------------------------ the rows

local function Section(key) return CO:GetConfigTable().args[key] end

local function Recorded(fn)
	local log, changed, whole = {}, st.ColorChanged, st.ColorsChanged
	st.ColorChanged = function(_, group, key) log[#log + 1] = group .. ':' .. tostring(key) end
	st.ColorsChanged = function(_, group) log[#log + 1] = 'WHOLE ' .. tostring(group) end
	local ok, err = pcall(fn)
	st.ColorChanged, st.ColorsChanged = changed, whole
	if not ok then error(err, 0) end
	return table.concat(log, ',')
end

test("the Colors rows and the Accent row say ColorChanged, on a set and on a reset", function()
	local danger = Section('text').args.danger
	local renown = Section('reaction').args.renown
	eq(Recorded(function() danger.set({}, 0.1, 0.2, 0.3) end), 'text:danger', 'a set')
	eq(Recorded(function() danger.default.reset() end), 'text:danger', 'a reset')
	eq(Recorded(function() renown.set({}, 0.1, 0.2, 0.3) end), 'renown:nil', "renown has no key")
	eq(Recorded(function() renown.default.reset() end), 'renown:nil')
	local mage = Section('class').args.MAGE
	eq(Recorded(function() mage.set({}, 0.1, 0.2, 0.3) end), 'class:MAGE')
	mage.default.reset()
	local accent = CO:AccentOption(5)
	eq(Recorded(function() accent.set({}, 0.5, 0.5, 0.5) end), 'accent:nil', "the accent's set")
	eq(Recorded(function() accent.default.reset() end), 'accent:nil', "and its reset")
end)

------------------------------------------------------------------ the picker

-- Text > Danger's field, bound to the real option.
local function danger_field()
	return H.bind('color', 'danger', Section('text').args.danger)
end

local function mage_field()
	return H.bind('color', 'MAGE', Section('class').args.MAGE)
end

local function type_hex(F, text)
	F.hex:SetFocus()
	F.hex:SetText(text)
	stub.fire_script(F.hex, 'OnEnterPressed')
end

test('the picker begins an edit as it opens and ends it as it closes, after Cancel puts the color back', function()
	reset()
	local danger = st.config.profile.colors.text.danger
	local keep = { danger:GetRGB() }
	local w = danger_field()
	click(w.frame)
	local F = W.GetColorPickerFrames()
	check(st:InColorEdit(), 'the edit began as the picker opened')
	type_hex(F, '#FF0000')
	eq(danger.r, 1, 'the drag reaches the profile')
	eq(told(), '', 'but waits for the frame')
	C.step(st)
	eq(told(), 'text:danger', 'one pass')
	type_hex(F, '#00FF00')
	click(F.cancel)
	eq(told(), 'text:danger,text:nil', "the restore's own pass (marked) dropped, the whole pass after onCancel")
	check(not st:InColorEdit(), 'the edit ended')
	eq(danger.r .. ',' .. danger.g .. ',' .. danger.b, keep[1] .. ',' .. keep[2] .. ',' .. keep[3], 'the opening color is back')
	w:Release()
end)

test('Okay ends the edit with the whole pass too', function()
	reset()
	local w = danger_field()
	click(w.frame)
	local F = W.GetColorPickerFrames()
	type_hex(F, '#FF0000')
	click(F.okay)
	eq(told(), 'text:nil', 'the whole pass of the group it touched')
	check(not st:InColorEdit(), 'over')
	w:Release()
	st.config.profile.colors.text.danger:SetRGB(st.defaults.colors.text.danger.r, st.defaults.colors.text.danger.g, st.defaults.colors.text.danger.b)
end)

test('opening for another field ends the first edit first (Review Focus 5)', function()
	reset()
	local w1, w2 = danger_field(), mage_field()
	click(w1.frame)
	local F = W.GetColorPickerFrames()
	type_hex(F, '#FF0000')
	forget()
	click(w2.frame)
	eq(told(), 'text:nil', "the first edit's whole pass ran before the second began")
	check(st:InColorEdit(), 'and a new edit is on')
	click(F.cancel)
	eq(told(), 'text:nil', 'the new edit touched no group: its end runs no pass')
	w1:Release(); w2:Release()
	local d = st.defaults.colors.text.danger
	st.config.profile.colors.text.danger:SetRGB(d.r, d.g, d.b)
end)

test('a profile switch during an edit (Review Focus 1)', function()
	reset()
	local original = st.config:GetCurrentProfile()
	local d = st.defaults.colors.text.danger
	st.config.profile.colors.text.danger:SetRGB(0.3, 0.4, 0.5) -- not B's default, so a restore written into B shows
	local w = danger_field()
	click(w.frame)
	local F = W.GetColorPickerFrames()
	type_hex(F, '#FF0000')
	local read = {}
	local follower = Obj()
	st:FollowColor(follower, 'text', nil, function() read[#read + 1] = st:Color('text', 'danger').r end)
	st.config:SetProfile('Live colors B')
	local b = st.config.profile.colors.text.danger
	eq(b.r, d.r, "B's own color is the default")
	stub.fire_script(F.frame, 'OnUpdate', 0.016) -- the picker sees its field went stale
	check(not W.ColorPickerShown(), 'the picker closed')
	check(not st:InColorEdit(), 'the edit ended')
	eq(st.config.profile.colors.text.danger.r, d.r, "B's color is untouched by the red")
	eq(read[#read], d.r, 'the whole pass ran with B in place')
	st:UnfollowColor(follower)
	w:Release()
	st.config:SetProfile(original)
	st.config.profile.colors.text.danger:SetRGB(d.r, d.g, d.b)
	st.config:DeleteProfile('Live colors B', true)
end)

------------------------------------------------------------------ followers

test('a follower whose paint errors is reported once and forgotten; the rest still paint (Review Focus 3)', function()
	reset()
	take_errors()
	local a, b, c = Obj(), Obj(), Obj()
	st:FollowColor(a, 'text', 'danger', P)
	st:FollowColor(b, 'text', 'danger', function() error('a region another addon took apart') end)
	st:FollowColor(c, 'text', 'danger', P)
	st:ColorChanged('text', 'danger')
	eq(#take_errors(), 1, 'reported once')
	eq(painted(a), 'danger', 'the others painted'); eq(painted(c), 'danger')
	st:ColorChanged('text', 'danger')
	eq(#take_errors(), 0, 'the next pass reports nothing')
	eq(painted(a), 'danger,danger', 'and the other two paint again'); eq(painted(c), 'danger,danger')
	for _, o in ipairs({ a, b, c }) do st:UnfollowColor(o) end
end)

test('a follow made during a pass takes effect after it; UnfollowColor forgets every registration', function()
	reset()
	local late, a = Obj(), Obj()
	st:FollowColor(a, 'text', 'danger', function() st:FollowColor(late, 'text', 'danger', P) end)
	st:ColorChanged('text', 'danger')
	eq(painted(late), '', 'not painted in the pass that made the follow')
	st:ColorChanged('text', 'danger')
	eq(painted(late), 'danger', 'painted by the next')
	st:UnfollowColor(a); st:UnfollowColor(late)

	local o = Obj()
	st:FollowColor(o, 'text', 'danger', P)
	st:FollowColor(o, 'text', nil, P)
	st:FollowColor(o, 'class', 'MAGE', P)
	st:UnfollowColor(o)
	st:ColorChanged('text', 'danger'); st:ColorChanged('class', 'MAGE'); st:ColorsChanged('text')
	eq(painted(o), '', 'nothing of it paints')
	st:FollowColor(o, 'text', 'danger', P)
	st:FollowColor(o, 'text', 'danger', nil)
	st:ColorChanged('text', 'danger')
	eq(painted(o), '', 'a paint nil forgets that one registration')
end)

------------------------------------------------------------------ the guard and the numbers


-- The clock the guard reads, moved by hand.
local function with_clock(fn)
	local real, now = _G.debugprofilestop, 0
	_G.debugprofilestop = function() return now end
	local ok, err = pcall(fn, function(ms) now = now + ms end)
	_G.debugprofilestop = real
	if not ok then error(err, 0) end
end

test('the guard: a pass over 8 ms makes the next wait a frame per 8 ms, three at most', function()
	reset()
	check(CO.PASS_BUDGET_MS == 8 and CO.MAX_WAIT == 3, 'the numbers')
	with_clock(function(move)
		for _, case in ipairs({ { 20, 2 }, { 40, 3 }, { 5, 0 }, { 8, 0 }, { 8.5, 1 }, { 16, 2 } }) do
			local cost, waits = case[1], case[2]
			local o, count = Obj(), 0
			st:FollowColor(o, 'text', 'danger', function() count = count + 1; move(cost) end)
			st:BeginColorEdit()
			st:ColorChanged('text', 'danger')
			C.step(st)
			eq(count, 1, cost .. ' ms: the pass ran')
			local stats = CO.EditStats()
			eq(stats.passes, 1); eq(stats.slowest, cost); eq(stats.slowestGroup, 'text'); eq(stats.slowestKey, 'danger')
			eq(stats.waited, 0, 'nothing has waited yet')
			st:ColorChanged('text', 'danger')
			for step = 1, waits do
				C.step(st)
				eq(count, 1, 'step ' .. step .. ': still waiting')
			end
			eq(stats.waited, waits, cost .. ' ms waits ' .. waits .. ' frames')
			C.step(st)
			eq(count, 2, 'then it runs')
			st:EndColorEdit()
			st:UnfollowColor(o)
		end
	end)
end)

test("the Theme tab's recolor is timed during an edit, as theme, and changes nothing outside one", function()
	reset()
	local tab = st.Config:GetOptionsTable().Fonts.args.theme
	local root = st.Config:GetOptionsTable()
	local row
	for _, section in ipairs(OM.BuildView(root, 'Fonts', { tab = 'theme' }).sections) do
		for _, r in ipairs(section.rows) do if r.key == 'border' then row = r end end
	end
	check(tab and row, 'the Border row')
	local recolors, real = 0, st.RecolorThemed
	with_clock(function(move)
		st.RecolorThemed = function() recolors = recolors + 1; move(5) end
		local ok, err = pcall(function()
			st:BeginColorEdit()
			OM.Set(root, row, 0.2, 0.3, 0.4)
			local stats = CO.EditStats()
			eq(recolors, 1, 'the recolor ran')
			eq(stats.passes, 1, 'counted as a pass'); eq(stats.slowestGroup, 'theme'); eq(stats.slowestKey, nil); eq(stats.slowest, 5)
			eq(stats.waited, 0, 'it makes nothing wait')
			st:EndColorEdit()
			local passes = stats.passes
			OM.Set(root, row, 0.3, 0.4, 0.5)
			eq(recolors, 2, 'outside an edit it recolors as before')
			eq(CO.EditStats().passes, passes, 'and counts nothing')
		end)
		st.RecolorThemed = real
		if not ok then error(err, 0) end
	end)
	OM.DefaultReset(root, row)
end)

-- What /sui debug's line says, colors stripped.
local function printed_by(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = (table.concat(parts, ' '):gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', ''))
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

test('with /sui debug on an edit ends with one line; with no pass, none', function()
	reset()
	load_string_format()
	st.DEBUG = true
	local ok, err = pcall(function()
		with_clock(function(move)
			local o = Obj()
			st:FollowColor(o, 'class', 'MAGE', function() move(3) end)
			local lines = printed_by(function()
				st:BeginColorEdit()
				st:ColorChanged('text', 'danger'); C.step(st)
				st:ColorChanged('class', 'MAGE'); C.step(st)
				st:ColorChanged('text', 'muted'); C.step(st)
				st:EndColorEdit()
			end)
			eq(#lines, 1, 'one line')
			check(lines[1]:find('<DEBUG:Colors> 3 passes, slowest [%d.]+ ms %(class MAGE, slowest reader followers 3%.0 ms%), mean [%d.]+ ms, 0 frames waited%.'),
				lines[1])
			eq(lines[1]:match('slowest ([%d.]+) ms'), '3.0'); eq(lines[1]:match('mean ([%d.]+) ms'), '1.0')
			lines = printed_by(function()
				st:BeginColorEdit()
				st:ColorChanged('text', 'danger') -- marked, never run
				st:EndColorEdit()
			end)
			eq(#lines, 0, 'an edit that ran no pass says nothing')
			st.DEBUG = false
			lines = printed_by(function()
				st:BeginColorEdit()
				st:ColorChanged('text', 'danger'); C.step(st)
				st:EndColorEdit()
			end)
			eq(#lines, 0, 'and with debug off, nothing')
			st:UnfollowColor(o)
		end)
	end)
	st.DEBUG = false
	if not ok then error(err, 0) end
end)

test("the debug line names the slowest pass's slowest reader: a module's handler or the followers as one; nothing is measured with debug off", function()
	reset()
	load_string_format()
	local original = M.OnColorsChanged
	local ok, err = pcall(function()
		with_clock(function(move)
			local o = Obj()
			st:FollowColor(o, 'text', 'danger', function() move(2) end)
			function M:OnColorsChanged(group, key) if group == 'text' then move(5) end end
			st.DEBUG = true
			local lines = printed_by(function()
				st:BeginColorEdit()
				st:ColorChanged('text', 'danger'); C.step(st)
				st:EndColorEdit()
			end)
			eq(#lines, 1, 'one line')
			check(lines[1]:find('slowest 7%.0 ms %(text danger, slowest reader LiveProbe 5%.0 ms%)'), lines[1])
			eq(CO.EditStats().slowestReader, 'LiveProbe', 'the stats name it')
			-- The followers can be the slowest.
			function M:OnColorsChanged() move(1) end
			lines = printed_by(function()
				st:BeginColorEdit()
				st:ColorChanged('text', 'danger'); C.step(st)
				st:EndColorEdit()
			end)
			check(lines[1]:find('slowest reader followers 2%.0 ms'), lines[1])
			-- With debug off no reader is timed: the clock is read four times a pass, as before.
			st.DEBUG = false
			local reads, clock = 0, _G.debugprofilestop
			_G.debugprofilestop = function() reads = reads + 1; return clock() end
			st:BeginColorEdit()
			st:ColorChanged('text', 'danger'); C.step(st)
			_G.debugprofilestop = clock
			eq(reads, 4, 'with debug off the clock is read for the pass alone')
			eq(CO.EditStats().slowestReader, nil, 'and no reader is named')
			st:EndColorEdit()
			-- With debug on it is read more (each reader, the followers).
			st.DEBUG = true
			reads = 0
			_G.debugprofilestop = function() reads = reads + 1; return clock() end
			st:BeginColorEdit()
			st:ColorChanged('text', 'danger'); C.step(st)
			_G.debugprofilestop = clock
			check(reads > 4, 'with debug on the readers are timed too: ' .. reads)
			st:EndColorEdit()
			st:UnfollowColor(o)
		end)
	end)
	st.DEBUG = false
	M.OnColorsChanged = original
	if not ok then error(err, 0) end
end)

test('a pass makes nothing and allocates nothing: 1000 followers, 100 passes', function()
	reset()
	local objects = {}
	local function paint(object) object.texture:SetVertexColor(st:ColorRGBA('text', 'danger')) end
	for i = 1, 1000 do
		objects[i] = { texture = UIParent:CreateTexture(nil, 'ARTWORK') }
		objects[i].texture:SetVertexColor(1, 1, 1) -- the stub makes its color table at the first call, once
		st:FollowColor(objects[i], 'text', 'danger', paint)
	end
	local m
	m = C.measure(function() st:ColorChanged('text', 'danger') end, 100) -- every module real; edit mode's (off here) costs nothing
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing shown, hidden, placed or sized')
	eq(m.calls.by.SetVertexColor, 100000, 'every follower colored, every pass')
	check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
	C.print('1000 followers', m)

	for _, o in ipairs(objects) do st:UnfollowColor(o) end
end)

------------------------------------------------------------------ the profile update

local function expected_whole()
	local out = { 'theme:nil', 'accent:nil' }
	for _, group in ipairs(st.COLOR_GROUPS) do
		if group ~= 'accent' then out[#out + 1] = group .. ':nil' end
	end
	return table.concat(out, ',')
end

test("the profile update runs every group's whole pass after theme and accent, and in combat once it ends", function()
	reset()
	check(#st.COLOR_GROUPS == 14 and st.COLOR_GROUPS[1] == 'text' and st.COLOR_GROUPS[14] == 'accent', 'the groups, in the Colors page order')
	local function themed()
		local out = {}
		for entry in told():gmatch('[^,]+') do out[#out + 1] = entry end
		return table.concat(out, ',')
	end
	st.Config:UpdateConfig()
	eq(themed(), expected_whole())
	forget()
	stub.in_combat = true
	st.Config:UpdateConfig()
	eq(told(), '', 'nothing in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(told(), expected_whole(), 'the same once combat ends')
	eq(#stub.blocked, 0)
end)

test('combat cancels an open picker: the restore and the whole pass run, color only (Review Focus 4)', function()
	reset()
	local danger = st.config.profile.colors.text.danger
	local keep = { danger:GetRGB() }
	-- The picker on the row's own set, without the field the options kit would
	-- repaint (placing it is the field's, not the pass's).
	local owner = CreateFrame('Frame', nil, UIParent)
	owner:SetSize(170, 24)
	owner:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
	local set = Section('text').args.danger.set
	W.OpenColorPicker(owner, { r = keep[1], g = keep[2], b = keep[3], onChange = function(r, g, b) set({}, r, g, b) end })
	local F = W.GetColorPickerFrames()
	type_hex(F, '#FF0000')
	eq(danger.r, 1, 'dragged')
	forget()
	stub.in_combat = true
	local m
	-- Every module real (edit mode's, off here, costs the pass nothing).
	m = C.measure(function() stub.fire_script(F.frame, 'OnEvent', 'PLAYER_REGEN_DISABLED') end, 1,
		{ [F.frame] = true, [F.keys] = true, [F.square] = true, [F.hue] = true, [F.alpha] = true, [F.drag] = true, [CO.ticker] = true })
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'no forbidden call but the picker and the ticker hiding themselves')
	eq(told(), 'text:nil', 'the whole pass ran')
	eq(danger.r .. ',' .. danger.g .. ',' .. danger.b, keep[1] .. ',' .. keep[2] .. ',' .. keep[3], 'the color is the opening one')
	check(not W.ColorPickerShown(), 'closed')
	stub.in_combat = false
	eq(#stub.blocked, 0)
end)

test("Config:OnColorsChanged('text', 'normal') gives the kit's font objects Text's color; ('text', 'danger') does not", function()
	reset()
	local OB = st.OptionsBody
	local heading = OB.Font('label')
	local normal = st.config.profile.colors.text.normal
	local keep = { normal:GetRGB() }
	local function color(font) return string.format('%.2f,%.2f,%.2f', font:GetTextColor()) end
	normal:SetRGB(0.1, 0.6, 0.3)
	W.GetFont():SetTextColor(0.5, 0.5, 0.5)
	heading:SetTextColor(0.5, 0.5, 0.5)
	st.Config:OnColorsChanged('text', 'danger')
	eq(color(W.GetFont()) .. color(heading), '0.50,0.50,0.500.50,0.50,0.50', 'Danger is not Normal')
	st.Config:OnColorsChanged('class', 'MAGE')
	eq(color(W.GetFont()), '0.50,0.50,0.50', 'nor is another group')
	st.Config:OnColorsChanged('text', 'normal')
	eq(color(W.GetFont()), '0.10,0.60,0.30', 'Normal is: the field font')
	eq(color(heading), '0.10,0.60,0.30', "and each of /sui's font objects")
	W.GetFont():SetTextColor(0.5, 0.5, 0.5)
	st.Config:OnColorsChanged('text')
	eq(color(W.GetFont()), '0.10,0.60,0.30', 'and a whole pass of Text')
	-- Only the color: a pass sets no font (SetFont is a re-skin).
	local m
	m = C.measure(function() st.Config:OnColorsChanged('text'); st.Config:OnColorsChanged('text', 'normal') end)
	eq(m.forbidden.by.SetFont, nil, 'no SetFont in a Text pass')
	eq(m.forbidden.total, 0, 'nothing forbidden')
	check(m.calls.by.SetTextColor and m.calls.by.SetTextColor >= 2, 'the font objects take the color')
	normal:SetRGB(unpack(keep))
	st.Config:OnColorsChanged('text')
end)

------------------------------------------------------------------ edges (the review of Task 1)

test('a follower runs before the modules in a pass', function()
	reset()
	local o = Obj()
	st:FollowColor(o, 'text', 'danger', function() seen[#seen + 1] = 'follower' end)
	st:ColorChanged('text', 'danger')
	eq(told(), 'follower,text:danger')
	st:UnfollowColor(o)
end)

test('an unfollow, a paint-nil forget and a follow made during a pass, and a follow made during a whole pass', function()
	reset()
	local late, gone, b = Obj(), Obj(), Obj()
	local a = Obj()
	st:FollowColor(gone, 'text', 'danger', P)
	st:FollowColor(a, 'text', 'danger', function()
		st:FollowColor(late, 'text', 'danger', P)
		st:UnfollowColor(late) -- forgotten before it was ever applied
		st:FollowColor(gone, 'text', 'danger', nil) -- a paint nil, during the pass
	end)
	st:ColorChanged('text', 'danger')
	st:ColorChanged('text', 'danger')
	eq(painted(late), '', 'a pending follow unfollowed in the same pass never paints')
	check(#gone.painted <= 1, 'a paint-nil forget made in a pass takes effect after it')
	st:UnfollowColor(a); st:UnfollowColor(gone)
	local whole = Obj()
	local c = Obj()
	local made = false
	st:FollowColor(c, 'text', nil, function() if not made then made = true; st:FollowColor(whole, 'text', nil, P) end end)
	st:ColorsChanged('text')
	st:ColorsChanged('text')
	eq(painted(whole), 'nil', 'a follow made in a whole pass paints in the next whole pass')
	st:UnfollowColor(c); st:UnfollowColor(whole)
end)

test('followers are held weakly: a dropped object is never painted again', function()
	reset()
	local n = 0
	local function paint() n = n + 1 end
	do
		local o = {}
		st:FollowColor(o, 'text', 'danger', paint)
	end
	collectgarbage(); collectgarbage()
	st:ColorChanged('text', 'danger')
	eq(n, 0)
end)

test('EndColorEdit outside an edit does nothing', function()
	reset()
	st:BeginColorEdit()
	st:ColorChanged('text', 'danger')
	st:EndColorEdit()
	forget()
	st:EndColorEdit()
	eq(told(), '', 'no pass')
end)

test('an edit begun during the whole passes of an edit end keeps its own touched groups', function()
	reset()
	local o, begun = Obj(), false
	st:FollowColor(o, 'text', nil, function()
		if not begun then
			begun = true
			st:BeginColorEdit()
			st:ColorChanged('class', 'MAGE')
		end
	end)
	st:BeginColorEdit()
	st:ColorChanged('text', 'danger')
	st:EndColorEdit()
	check(st:InColorEdit(), 'the new edit is on')
	forget()
	st:EndColorEdit()
	eq(told(), 'class:nil', "the second edit's end runs Class's whole pass")
	st:UnfollowColor(o)
end)

test('a color changed again in the same frame after its pass ran runs next frame', function()
	reset()
	local o, again = Obj(), false
	st:FollowColor(o, 'class', 'MAGE', function()
		if not again then again = true; st:ColorChanged('text', 'danger') end
	end)
	st:BeginColorEdit()
	st:ColorChanged('text', 'danger')
	st:ColorChanged('class', 'MAGE')
	C.step(st)
	eq(told(), 'text:danger,class:MAGE')
	check(CO.ticker:IsShown(), 'a pass is due again')
	C.step(st)
	eq(told(), 'text:danger,class:MAGE,text:danger', 'next frame')
	check(not CO.ticker:IsShown(), 'and nothing after')
	st:EndColorEdit()
	st:UnfollowColor(o)
end)

test('an edit that ends inside a due pass leaves nothing counted, waiting or due', function()
	reset()
	local o = Obj()
	st:FollowColor(o, 'text', 'danger', function() st:EndColorEdit() end)
	st:BeginColorEdit()
	st:ColorChanged('text', 'danger')
	st:ColorChanged('class', 'MAGE')
	C.step(st)
	check(not told():find('class:MAGE', 1, true), 'the rest of the due passes is dropped: ' .. told())
	eq(CO.EditStats().passes, 0, 'nothing counted after the end')
	eq(CO.wait, 0, 'nothing waits'); check(not CO.ticker:IsShown(), 'nothing is due')
	st:UnfollowColor(o)
end)

test('the picker does not leave an edit on when it fails to open', function()
	reset()
	local broken = { GetLeft = function() error('no place') end, GetRight = function() end, GetTop = function() end,
		GetBottom = function() end, IsVisible = function() return true end, GetEffectiveScale = function() return 1 end }
	local ok = pcall(W.OpenColorPicker, broken, { r = 1, g = 0, b = 0, onChange = function() end })
	check(not ok, 'it failed')
	check(not st:InColorEdit(), 'and no edit is on')
	W.CloseColorPicker()
end)

test('FollowColor refuses a group or a key that does not exist', function()
	reset()
	local o = Obj()
	for _, bad in ipairs({ { 'buttons' }, { 'text', 'Normal' }, { 'accent', 'x' }, { 'renown', 'x' }, { 'class', 'MAGEs' } }) do
		check(not pcall(st.FollowColor, st, o, bad[1], bad[2], P), 'refused: ' .. bad[1] .. ' ' .. tostring(bad[2]))
	end
	for _, good in ipairs({ { 'text' }, { 'text', 'normal' }, { 'reaction', 3 }, { 'item_quality', 0 }, { 'accent' }, { 'renown' }, { 'theme' } }) do
		check(pcall(st.FollowColor, st, o, good[1], good[2], P), 'accepted: ' .. good[1] .. ' ' .. tostring(good[2]))
	end
	st:UnfollowColor(o)
end)

------------------------------------------------------------------ edges (the re-review of Task 1)

test("a follow made during a pass is not painted in it, whichever list it goes in (not hash-order dependent)", function()
	reset()
	local late, a = Obj(), Obj()
	-- The group's own list is walked after the color's: a follow applied at once
	-- would always be painted in this pass.
	st:FollowColor(a, 'text', 'danger', function() st:FollowColor(late, 'text', nil, P) end)
	st:ColorChanged('text', 'danger')
	eq(painted(late), '', 'not in the pass that made it')
	st:ColorChanged('text', 'danger')
	eq(painted(late), 'danger', 'in the next')
	st:UnfollowColor(a); st:UnfollowColor(late)
end)

test('EndColorEdit outside an edit prints no second debug line', function()
	reset()
	load_string_format()
	st.DEBUG = true
	local ok, err = pcall(function()
		local lines = printed_by(function()
			st:BeginColorEdit()
			st:ColorChanged('text', 'danger'); C.step(st)
			st:EndColorEdit()
			st:EndColorEdit()
		end)
		eq(#lines, 1, 'one line for one edit')
	end)
	st.DEBUG = false
	if not ok then error(err, 0) end
end)

test('a color changed again by its own pass runs next frame', function()
	reset()
	local o, again = Obj(), false
	st:FollowColor(o, 'class', 'MAGE', function()
		if not again then again = true; st:ColorChanged('class', 'MAGE') end
	end)
	st:BeginColorEdit()
	st:ColorChanged('class', 'MAGE')
	C.step(st)
	eq(told(), 'class:MAGE')
	check(CO.ticker:IsShown(), 'due again')
	C.step(st)
	eq(told(), 'class:MAGE,class:MAGE')
	st:EndColorEdit()
	st:UnfollowColor(o)
end)

test("the field font takes Text > Normal when /sui's fonts are applied", function()
	reset()
	local normal = st.config.profile.colors.text.normal
	local keep = { normal:GetRGB() }
	normal:SetRGB(0.1, 0.6, 0.3)
	W.GetFont():SetTextColor(0.5, 0.5, 0.5)
	W.UpdateFonts()
	eq(string.format('%.2f,%.2f,%.2f', W.GetFont():GetTextColor()), '0.10,0.60,0.30')
	normal:SetRGB(unpack(keep))
	W.UpdateFonts()
end)

test('an edit ended and another begun inside one due pass, with a single mark: the new edit keeps its mark', function()
	reset()
	local o, done = Obj(), false
	st:FollowColor(o, 'text', 'danger', function()
		if done then return end
		done = true
		st:EndColorEdit()
		st:BeginColorEdit()
		st:ColorChanged('class', 'MAGE')
	end)
	st:BeginColorEdit()
	st:ColorChanged('text', 'danger')
	C.step(st)
	check(CO.ticker:IsShown(), "the new edit's pass is due")
	forget()
	C.step(st)
	eq(told(), 'class:MAGE', 'it runs next frame')
	st:EndColorEdit()
	forget()
	st:BeginColorEdit()
	st:ColorChanged('class', 'MAGE')
	C.step(st)
	eq(told(), 'class:MAGE', 'and again in a later edit')
	st:EndColorEdit()
	st:UnfollowColor(o)
end)

test('an edit ended and another begun inside one due pass: the new edit keeps its mark and its pass runs next frame', function()
	reset()
	local o, done = Obj(), false
	st:FollowColor(o, 'text', 'danger', function()
		if done then return end
		done = true
		st:EndColorEdit()
		st:BeginColorEdit()
		st:ColorChanged('class', 'MAGE')
	end)
	st:BeginColorEdit()
	st:ColorChanged('text', 'danger')
	st:ColorChanged('text', 'muted')
	C.step(st)
	check(st:InColorEdit(), 'the new edit is on')
	check(CO.ticker:IsShown(), 'its pass is due')
	forget()
	C.step(st)
	eq(told(), 'class:MAGE', "the new edit's color passes, and nothing of the old one")
	-- and the color can still be marked in a later edit (its mark was not left set)
	st:EndColorEdit()
	forget()
	st:BeginColorEdit()
	st:ColorChanged('class', 'MAGE')
	C.step(st)
	eq(told(), 'class:MAGE', 'a later edit passes it too')
	st:EndColorEdit()
	st:UnfollowColor(o)
end)
