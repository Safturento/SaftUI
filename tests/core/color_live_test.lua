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

-- Runs fn with the stand-in the only module: the modules' own handlers are
-- measured by their own tests (Edit mode's looks at its bar again on every
-- group until Task 2 of live colors).
local function alone(fn)
	local modules = st.modules
	st.modules = { LiveProbe = M }
	local ok, err = pcall(fn)
	st.modules = modules
	if not ok then error(err, 0) end
end

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
		for _, case in ipairs({ { 20, 2 }, { 40, 3 }, { 5, 0 } }) do
			local cost, waits = case[1], case[2]
			local o, count = Obj(), 0
			st:FollowColor(o, 'text', 'danger', function() count = count + 1; move(cost) end)
			st:BeginColorEdit()
			st:ColorChanged('text', 'danger')
			C.step(st)
			eq(count, 1, cost .. ' ms: the pass ran')
			local stats = CO.EditStats()
			eq(stats.passes, 1); eq(stats.slowest, cost); eq(stats.slowestGroup, 'text'); eq(stats.slowestKey, 'danger')
			eq(stats.waited, waits, cost .. ' ms waits ' .. waits)
			st:ColorChanged('text', 'danger')
			for step = 1, waits do
				C.step(st)
				eq(count, 1, 'step ' .. step .. ': still waiting')
			end
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
			check(lines[1]:find('<DEBUG:Colors> 3 passes, slowest [%d.]+ ms %(class MAGE%), mean [%d.]+ ms, 0 frames waited%.'),
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

test('a pass makes nothing and allocates nothing: 1000 followers, 100 passes', function()
	reset()
	local objects = {}
	-- A paint that only counts: the stub's color setters keep a table per call,
	-- which is the stub's garbage, not the pass's.
	local function paint(object) object.n = object.n + 1 end
	for i = 1, 1000 do
		objects[i] = { n = 0 }
		st:FollowColor(objects[i], 'text', 'danger', paint)
	end
	local m
	alone(function() m = C.measure(function() st:ColorChanged('text', 'danger') end, 100) end)
	eq(m.made, 0, 'nothing made')
	eq(m.forbidden.total, 0, 'nothing shown, hidden, placed or sized')
	eq(objects[1].n .. ',' .. objects[1000].n, '100,100', 'every follower painted, every pass')
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
	alone(function()
		m = C.measure(function() stub.fire_script(F.frame, 'OnEvent', 'PLAYER_REGEN_DISABLED') end, 1,
			{ [F.frame] = true, [F.keys] = true, [F.square] = true, [F.hue] = true, [F.alpha] = true, [F.drag] = true, [CO.ticker] = true })
	end)
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
	local normal = st.config.profile.colors.text.normal
	local keep = { normal:GetRGB() }
	local function color() return string.format('%.2f,%.2f,%.2f', W.GetFont():GetTextColor()) end
	normal:SetRGB(0.1, 0.6, 0.3)
	W.GetFont():SetTextColor(0.5, 0.5, 0.5)
	st.Config:OnColorsChanged('text', 'danger')
	eq(color(), '0.50,0.50,0.50', 'Danger is not Normal')
	st.Config:OnColorsChanged('class', 'MAGE')
	eq(color(), '0.50,0.50,0.50', 'nor is another group')
	st.Config:OnColorsChanged('text', 'normal')
	eq(color(), '0.10,0.60,0.30', 'Normal is')
	W.GetFont():SetTextColor(0.5, 0.5, 0.5)
	st.Config:OnColorsChanged('text')
	eq(color(), '0.10,0.60,0.30', 'and a whole pass of Text')
	normal:SetRGB(unpack(keep))
	st.Config:OnColorsChanged('text')
end)
