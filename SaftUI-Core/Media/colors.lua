local st = SaftUI

local CO = st:NewModule('Colors')

------------------------------------------------------------------ the pass

-- How a color change reaches what draws it. A Colors row's set or reset (and
-- the Accent's) says st:ColorChanged(group, key): the one color that changed.
-- During an edit (the color picker open: st:BeginColorEdit) it only marks the
-- color, and one pass runs on the next frame from CO.ticker, however many
-- changes came; outside an edit it passes at once. A pass runs the followers
-- of that color (st:FollowColor), those of its whole group, then every
-- module's OnColorsChanged(group, key). st:ColorsChanged(group) is the whole
-- pass: every follower of the group, then every module's
-- OnColorsChanged(group) with no key, meaning any color of the group may have
-- changed. An edit's end runs the whole pass of each group it touched, and the
-- profile update runs every group's (config.lua).
--
-- A pass only colors: no frame, texture or font string made, nothing shown,
-- hidden, placed or sized, no table or closure made, so it is safe in combat.
-- Nothing is made per pass here either: the follower tables and the marks are
-- made once and cleared in place, and every call goes through a function made
-- at load (the game's xpcall passes arguments on; the test stub's makes a
-- closure for them).
--
-- group is 'text', 'button', 'class', 'roles', 'reaction', 'renown',
-- 'factions', 'power', 'item_quality', 'loot', 'status', 'threat' or
-- 'objectives', or 'accent' (Theme > Accent, which fires after every 'theme'
-- too); key is the color in it, nil for 'accent' and 'renown'.
st.COLOR_GROUPS = { 'text', 'button', 'class', 'roles', 'reaction', 'renown', 'factions', 'power',
	'item_quality', 'loot', 'status', 'threat', 'objectives', 'accent' }

CO.PASS_BUDGET_MS = 8 -- a pass during an edit over this makes the next wait a frame per this much
CO.MAX_WAIT = 3 -- frames, at most
CO.wait = 0 -- frames the ticker still waits before the due pass

local ALL = '*' -- a follower's key when it follows every color of the group
local KNOWN_GROUP = { theme = true }
for _, group in ipairs(st.COLOR_GROUPS) do KNOWN_GROUP[group] = true end

-- followers[group][key or ALL] = { [object] = paint }, weak on the object, made
-- when a first one registers.
local followers = {}
local function Weak() return setmetatable({}, { __mode = 'k' }) end

local pass = 0 -- how deep the passes run now (a paint may say another color changed)
local pendingObject, pendingGroup, pendingKey, pendingPaint, pending = {}, {}, {}, {}, 0 -- follows made during a pass

local function Follow(object, group, key, paint)
	local byGroup = followers[group]
	if not byGroup then
		byGroup = {}
		followers[group] = byGroup
	end
	key = key == nil and ALL or key
	local list = byGroup[key]
	if paint == nil then
		if list then list[object] = nil end
		return
	end
	if not list then
		list = Weak()
		byGroup[key] = list
	end
	list[object] = paint
end

-- paint(object, key) runs on every pass of that color (key nil: of any color
-- of the group) with the changed key, nil on a whole pass. It reads its colors
-- as it runs, and never closes over object (the table holds the object weakly,
-- and Lua 5.1 has no ephemerons). Nothing paints as it registers: the caller
-- has just colored the object. A follow made during a pass takes effect after
-- it; paint nil forgets this registration.
function st:FollowColor(object, group, key, paint)
	if object == nil or group == nil then error('SaftUI: FollowColor needs an object and a group', 2) end
	-- A typo registers nothing that ever paints, so it is refused: the group is
	-- one of st.COLOR_GROUPS (or 'theme'), the key one the group has (the
	-- default decides, as st:Color does); 'accent' and 'renown' take none.
	if not KNOWN_GROUP[group] then error('SaftUI: FollowColor: no color group ' .. tostring(group), 2) end
	if key ~= nil then
		local from = st.defaults and st.defaults.colors and st.defaults.colors[group]
		if group == 'accent' or group == 'renown' or group == 'theme' or (type(from) == 'table' and from[key] == nil) then
			error('SaftUI: FollowColor: no color ' .. tostring(group) .. '.' .. tostring(key), 2)
		end
	end
	if paint ~= nil and type(paint) ~= 'function' then error('SaftUI: FollowColor paint is not a function', 2) end
	if pass > 0 then
		pending = pending + 1
		pendingObject[pending], pendingGroup[pending], pendingKey[pending], pendingPaint[pending] = object, group, key, paint or false
		return
	end
	Follow(object, group, key, paint)
end

-- Forgets every registration of object (a pool that releases it must call this).
function st:UnfollowColor(object)
	for _, byGroup in pairs(followers) do
		for _, list in pairs(byGroup) do list[object] = nil end
	end
	for i = 1, pending do
		if pendingObject[i] == object then pendingObject[i] = false end
	end
end

local function ApplyPending()
	local n = pending
	pending = 0
	for i = 1, n do
		local object = pendingObject[i]
		if object then Follow(object, pendingGroup[i], pendingKey[i], pendingPaint[i] or nil) end
		pendingObject[i], pendingGroup[i], pendingKey[i], pendingPaint[i] = nil, nil, nil, nil
	end
end

-- What a pass calls goes through these: xpcall takes no arguments in Lua 5.1,
-- and the game's makes nothing for them, but a function made per call would.
local paintObject, paintFn, paintKey
local function CallPaint() return paintFn(paintObject, paintKey) end
local moduleObject, moduleGroup, moduleKey
local function CallModule() return moduleObject:OnColorsChanged(moduleGroup, moduleKey) end

-- Paints every follower in list; one whose paint errors is reported once (by
-- the error handler) and forgotten, so a drag doesn't report it every frame.
-- Clearing the field being walked is allowed.
local function PaintList(list, key)
	for object, paint in pairs(list) do
		paintObject, paintFn, paintKey = object, paint, key
		if not xpcall(CallPaint, geterrorhandler()) then list[object] = nil end
	end
end

-- With /sui debug on, the timed passes of an edit also say which reader took
-- longest: each module's handler, and the followers of the pass as one. Only
-- while `measuring` (RunDue sets it around one pass, with debug on): a pass
-- with debug off reads no clock here.
local measuring = false
local readerName, readerMs = nil, -1

local function NoteReader(name, ms)
	if ms > readerMs then readerName, readerMs = name, ms end
end

local function NameOf(module)
	return module.moduleName or (module.GetName and module:GetName()) or '?'
end

local function RunModules(group, key)
	for _, module in pairs(st.modules) do
		if module.OnColorsChanged then
			moduleObject, moduleGroup, moduleKey = module, group, key
			if measuring then
				local start = debugprofilestop()
				xpcall(CallModule, geterrorhandler())
				NoteReader(NameOf(module), debugprofilestop() - start)
			else
				xpcall(CallModule, geterrorhandler())
			end
		end
	end
end

-- The pass of one color: its followers, its group's, then the modules.
local function RunPass(group, key)
	pass = pass + 1
	local byGroup = followers[group]
	if byGroup then
		local start = measuring and debugprofilestop()
		if key ~= nil and byGroup[key] then PaintList(byGroup[key], key) end
		if byGroup[ALL] then PaintList(byGroup[ALL], key) end
		if start then NoteReader('followers', debugprofilestop() - start) end
	end
	RunModules(group, key)
	pass = pass - 1
	if pass == 0 and pending > 0 then ApplyPending() end
end

-- The whole pass of a group: every follower of it, then each module with no key.
function st:ColorsChanged(group)
	pass = pass + 1
	local byGroup = followers[group]
	if byGroup then
		for _, list in pairs(byGroup) do PaintList(list, nil) end
	end
	RunModules(group, nil)
	pass = pass - 1
	if pass == 0 and pending > 0 then ApplyPending() end
end

------------------------------------------------------------------ edits

-- The marked colors, in the order marked: parallel arrays and a set per group,
-- cleared in place. markSet[group][key or ALL] says a color is marked already.
local markGroup, markKey, marked = {}, {}, 0
local markSet = {}
for _, group in ipairs(st.COLOR_GROUPS) do markSet[group] = {} end
local touchedList, touchedSet, touched = {}, {}, 0 -- the groups this edit marked, in the order first marked
local endList, endTop = {}, 0 -- the groups an edit's end is running the whole passes of
local editing = false
local editSerial = 0 -- which edit: RunDue tells an edit ended and another begun inside one pass

-- The edit's numbers, one table reset in place at st:BeginColorEdit.
local stats = { passes = 0, total = 0, slowest = 0, slowestGroup = nil, slowestKey = nil, slowestReader = nil, slowestReaderMs = nil, waited = 0 }
function CO.EditStats() return stats end

-- reader and readerMs, with debug on, name the slowest reader of the pass.
local function Record(group, key, ms, reader, readerTime)
	stats.passes = stats.passes + 1
	stats.total = stats.total + ms
	if ms > stats.slowest or stats.slowestGroup == nil then
		stats.slowest, stats.slowestGroup, stats.slowestKey = ms, group, key
		stats.slowestReader, stats.slowestReaderMs = reader, readerTime
	end
end

-- The rest of what Timed's fn returned, its time added to the edit's stats.
local function Timed(group, key, t0, ...)
	Record(group, key, debugprofilestop() - t0)
	return ...
end

-- Runs fn(...) and returns what it returns. While an edit is on its time is
-- one pass in the edit's stats, named group and key (the Theme tab's recolor
-- is timed as 'theme').
function CO.Timed(group, key, fn, ...)
	if not editing then return fn(...) end
	return Timed(group, key, debugprofilestop(), fn(...))
end

-- The due passes, one per color marked when the frame began, in the order
-- marked, each timed; a color marked again while they run is due next frame.
-- The frame's whole cost decides how long the next waits: more than the budget
-- makes it wait a frame for each budget it took, at most MAX_WAIT. An edit
-- that ends inside a pass drops the rest and counts nothing more.
local function RunDue()
	local t0 = debugprofilestop()
	local n, serial = marked, editSerial
	for i = 1, n do
		if serial ~= editSerial or not editing then return end
		local group, key = markGroup[i], markKey[i]
		markSet[group][key == nil and ALL or key] = nil
		measuring = st.DEBUG and true or false
		readerName, readerMs = nil, -1
		local start = debugprofilestop()
		RunPass(group, key)
		measuring = false
		if serial ~= editSerial or not editing then return end
		Record(group, key, debugprofilestop() - start, readerName, readerName and readerMs or nil)
	end
	local rest = marked - n
	for j = 1, rest do
		markGroup[j], markKey[j] = markGroup[n + j], markKey[n + j]
	end
	for j = rest + 1, marked do markGroup[j], markKey[j] = nil, nil end
	marked = rest
	local cost = debugprofilestop() - t0
	CO.wait = cost > CO.PASS_BUDGET_MS and math.min(CO.MAX_WAIT, math.floor(cost / CO.PASS_BUDGET_MS)) or 0
	if marked == 0 then CO.ticker:Hide() end
end

CO.ticker = CreateFrame('Frame')
CO.ticker:Hide()
CO.ticker:SetScript('OnUpdate', function(self)
	if CO.wait > 0 then
		CO.wait = CO.wait - 1
		stats.waited = stats.waited + 1
		return
	end
	self:Hide()
	RunDue()
end)

-- The color picker opens on a color: changes wait for the next frame, one pass
-- for all that came. Nothing happens if an edit is on already.
function st:BeginColorEdit()
	if editing then return end
	editing = true
	editSerial = editSerial + 1
	stats.passes, stats.total, stats.slowest, stats.slowestGroup, stats.slowestKey, stats.waited = 0, 0, 0, nil, nil, 0
	stats.slowestReader, stats.slowestReaderMs = nil, nil
	CO.wait = 0
end

function st:InColorEdit() return editing end

-- One color changed (a Colors row's set or reset, the Accent's).
function st:ColorChanged(group, key)
	if not editing then
		RunPass(group, key)
		return
	end
	local set = markSet[group]
	if not set then
		set = {}
		markSet[group] = set
	end
	if not touchedSet[group] then
		touchedSet[group] = true
		touched = touched + 1
		touchedList[touched] = group
	end
	local id = key == nil and ALL or key
	if set[id] then return end
	set[id] = true
	marked = marked + 1
	markGroup[marked], markKey[marked] = group, key
	CO.ticker:Show()
end

-- The picker closed: a pass still due is dropped, the whole pass of each group
-- the edit touched runs in the order first touched (it covers what a held-back
-- pass or a reader that filters by key missed), and with /sui debug on one line
-- says what the edit cost.
function st:EndColorEdit()
	if not editing then return end
	editing = false
	CO.ticker:Hide()
	CO.wait = 0
	for i = 1, marked do
		local key = markKey[i]
		markSet[markGroup[i]][key == nil and ALL or key] = nil
		markGroup[i], markKey[i] = nil, nil
	end
	marked = 0
	-- The touched groups are taken out first, into a scratch stretch of
	-- endList, so an edit a handler begins meanwhile keeps its own (and an end
	-- inside this one uses the stretch after).
	local n, base = touched, endTop
	for i = 1, n do
		local group = touchedList[i]
		endList[base + i] = group
		touchedSet[group] = nil
		touchedList[i] = nil
	end
	touched = 0
	endTop = base + n
	for i = 1, n do st:ColorsChanged(endList[base + i]) end
	for i = 1, n do endList[base + i] = nil end
	endTop = base
	if st.DEBUG and stats.passes > 0 then
		local name = stats.slowestKey == nil and stats.slowestGroup or (stats.slowestGroup .. ' ' .. tostring(stats.slowestKey))
		if stats.slowestReader then
			name = ('%s, slowest reader %s %.1f ms'):format(name, stats.slowestReader, stats.slowestReaderMs)
		end
		st:Debug('Colors', ('%d passes, slowest %.1f ms (%s), mean %.1f ms, %d frames waited.'):format(
			stats.passes, stats.slowest, name, stats.total / stats.passes, stats.waited))
	end
end

-- The color for an item quality: the profile's, else Blizzard's, else nil.
-- Either object has r, g and b.
function st:QualityColor(quality)
	if quality == nil then return nil end
	return st.config.profile.colors.item_quality[quality] or (ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality])
end

------------------------------------------------------------------ the accessor

-- The color for a group and key, as an object with r, g, b and a. The default
-- decides what exists: st.defaults.colors[group][key] (for 'accent', which
-- takes no key, st.defaults.theme.accent), or the read raises
-- 'SaftUI: no color <group>.<key>' at the caller of st:Color, whatever the
-- profile holds. The value is the active profile's own object, read now (so a
-- profile switch reaches the new one), else the default's: a profile that has
-- no config yet, or a group or color that isn't a table, reads as the default.
local function Resolve(group, key, level)
	local defaults = st.defaults
	local default
	if group == 'accent' then
		default = defaults and defaults.theme and defaults.theme.accent
	else
		local from = defaults and defaults.colors and defaults.colors[group]
		if type(from) == 'table' then
			if key == nil then
				-- Only a default that is itself a color has no key (renown).
				if type(from.r) == 'number' then default = from end
			else
				default = from[key]
			end
		end
	end
	if type(default) ~= 'table' then
		local name = group == 'accent' and 'accent' or (tostring(group) .. '.' .. tostring(key))
		error('SaftUI: no color ' .. name, level)
	end

	local profile = st.config and st.config.profile
	if type(profile) ~= 'table' then return default end
	local saved
	if group == 'accent' then
		saved = type(profile.theme) == 'table' and profile.theme.accent
	else
		local colors = profile.colors
		local holder = type(colors) == 'table' and colors[group]
		if key == nil then saved = holder elseif type(holder) == 'table' then saved = holder[key] end
	end
	-- Every color AceDB fills has the methods; a bare table (a hand edit, or a
	-- migration's write into a group that wasn't a table) reads as the default.
	-- A channel that is no number (only a hand edit of the saved file makes
	-- one) reads as the default, so no reader meets it.
	if type(saved) == 'table' and saved.GetRGB and type(saved.r) == 'number' and type(saved.g) == 'number'
		and type(saved.b) == 'number' and (saved.a == nil or type(saved.a) == 'number') then
		return saved
	end
	return default
end

function st:Color(group, key)
	return Resolve(group, key, 3)
end

-- r, g, b and the alpha a reader draws: its strength times the color's own
-- opacity (a color with no a is fully opaque).
function st:ColorRGBA(group, key, strength)
	local c = Resolve(group, key, 3)
	return c.r, c.g, c.b, (strength or 1) * (c.a or 1)
end

------------------------------------------------------------------ the migration

-- Today's shipped value of every retired key, frozen (AceDB saves only the
-- channels that differ from a default; once a default is gone, the rest come
-- from here). Never edited after it lands: the one edit made since is
-- text.grey, below. A key's value here is the default in effect when its step
-- ships and the key retires.
CO.OLD_COLORS = {
	-- 180, not the 150 Text > Grey first shipped with: its default became
	-- #b4b4b4 (decision 49) after this table was written and before step 3
	-- (the step that retires it) shipped, so 180 is the default a profile that
	-- never changed it had been drawing. This one edit is allowed because step 3
	-- had not shipped. A grey saved at exactly 150 is a customized color.
	['text.grey'] = { r = 180/255, g = 180/255, b = 180/255 },
	['text.white'] = { r = 1, g = 1, b = 1 },
	['text.red'] = { r = 220/255, g = 100/255, b = 100/255 },
	['text.orange'] = { r = 220/255, g = 150/255, b = 100/255 },
	['text.yellow'] = { r = 200/255, g = 200/255, b = 100/255 },
	['text.green'] = { r = 60/255, g = 240/255, b = 60/255 },
	['text.blue'] = { r = 0, g = 0.68, b = 0.94, a = 1 },
	['text.purple'] = { r = 197/255, g = 128/255, b = 255/255 },
	['text.cyan'] = { r = 120/255, g = 202/255, b = 250/255 },
	['button.red'] = { r = 0.6, g = 0.1, b = 0.1, a = 0.8 },
	['button.green'] = { r = 0.1, g = 0.6, b = 0.1, a = 0.8 },
	['button.blue'] = { r = 0, g = 0.68, b = 0.94, a = 0.8 },
	['button.yellow'] = { r = 0.6, g = 0.6, b = 0.1, a = 0.8 },
	['button.grey'] = { r = 150/255, g = 150/255, b = 150/255 },
	-- The four state colors, retired at step 7 (the states are the Accent's now,
	-- derived by Media/states.lua): the defaults they shipped with.
	['button.normal'] = { r = 0.1, g = 0.1, b = 0.1, a = 1 },
	['button.hover'] = { r = 0.3, g = 0.5, b = 0.7, a = 1 },
	['button.pushed'] = { r = 0.3, g = 0.4, b = 0.5, a = 1 },
	['button.checked'] = { r = 0.3, g = 0.5, b = 0.7, a = 1 },
}

-- One step per change of the colors' keys, run in order on a profile saved
-- before it. A step is { copy, retire, opacity, seed }: copy lists { source,
-- destination, ...} (a customized source's color goes into each destination),
-- retire the paths that leave, opacity the colors whose saved opacity goes back
-- to the default's, seed lists { source, destination } for a color that is
-- not retired (so OLD_COLORS holds no value for it): a source saved differently
-- from its default today (to the byte, opacity too) is copied whole into the
-- destination, which takes the source's default until then. A path is 'group.key' under profile.colors. The steps are
-- never edited once shipped; each change appends one.
CO.MIGRATION_STEPS = {
	{
		copy = {
			{ 'text.white', 'loot.need' },
			{ 'text.yellow', 'loot.greed', 'factions.Neutral' },
			{ 'text.purple', 'loot.transmog' },
			{ 'text.red', 'loot.pass', 'roles.DAMAGER', 'factions.Horde' },
			{ 'text.green', 'roles.HEALER' },
			{ 'text.blue', 'roles.TANK', 'factions.Alliance' },
			{ 'button.yellow', 'loot.mount' },
		},
		retire = { 'text.purple', 'button.yellow' },
	},
	{
		-- Blue leaves the Colors tab for the theme's one accent. The accent
		-- takes Buttons > Blue, never Text > Blue (that went to Tank and
		-- Alliance at step 1; a change made after it goes nowhere).
		copy = { { 'button.blue', 'accent' } },
		retire = { 'button.blue', 'text.blue', 'button.green' },
	},
	{
		-- Text > Grey becomes Text > Muted, and Buttons > Grey (the combined
		-- bank's visibility toggle and the edit mode picker's hint line, the
		-- same grey) folds into it: a customized Buttons > Grey is dropped, as
		-- Text > Grey is the one color that was Muted already.
		copy = { { 'text.grey', 'text.muted' } },
		retire = { 'text.grey', 'button.grey' },
	},
	{
		-- The state colors take their roles' names: White is Strong, Red
		-- Danger, Orange Warning, Yellow Caution, Green Success and Cyan
		-- Shared, and Buttons > Red is Buttons > Danger. Each keeps its hue,
		-- never an alpha. Step 1 read text.white, yellow, red and green for
		-- the Loot, Roles and Factions groups before this; a change made after
		-- it reaches only these.
		copy = {
			{ 'text.white', 'text.strong' },
			{ 'text.red', 'text.danger' },
			{ 'text.orange', 'text.warning' },
			{ 'text.yellow', 'text.caution' },
			{ 'text.green', 'text.success' },
			{ 'text.cyan', 'text.shared' },
			{ 'button.red', 'button.danger' },
		},
		retire = {
			'text.white', 'text.red', 'text.orange', 'text.yellow', 'text.green', 'text.cyan', 'button.red',
		},
	},
	{
		-- The Buttons colors' opacity is drawn now, as each reader's strength
		-- times it. No opacity was ever drawn before, so a saved one (the
		-- slider was there, and did nothing) goes back to 100%, once: the
		-- defaults are 100% and a chosen opacity from here on is kept. The
		-- colors themselves are untouched.
		opacity = { 'button.normal', 'button.hover', 'button.pushed', 'button.danger' },
	},
	{
		-- Hover is the highlight under the mouse (buttons, check boxes, bar items) and a checked check box has a
		-- color of its own, Buttons > Checked. A checked box read Hover, so a
		-- Hover the owner changed is Checked's too, and the box looks as it
		-- did; Hover keeps its value, and a button's highlight reads it from
		-- here on. An untouched Hover leaves Checked at its default (the same).
		seed = { { 'button.hover', 'button.checked' } },
	},
	{
		-- Every interaction state (hover, pushed, selected, focus, disabled) is
		-- derived from the Accent now (Media/states.lua; spec
		-- 2026-11-15-saftui-interaction-states-design.md): Buttons > Normal,
		-- Hover, Pushed and Checked are dropped, a change made to one with
		-- them. Buttons > Danger stays (a meaning, not a state). Their
		-- defaults stay in st.defaults until the last readers are converted, so
		-- a live profile reads them at the default (RunStep puts it back in
		-- place); a raw profile loses the key.
		retire = { 'button.normal', 'button.hover', 'button.pushed', 'button.checked' },
	},
}

-- 'group.key' under profile.colors, or 'accent' for profile.theme.accent
-- (which has no group: nil, 'accent').
local function SplitPath(path)
	local group, key = path:match('^([^.]+)%.(.+)$')
	if group then return group, key end
	return nil, path
end

local function Byte(v) return math.floor(v * 255 + 0.5) end

-- The color a source was customized to, as { r, g, b }, or nil when it was
-- not: no saved table, or a color that is its old value to the byte (the
-- Colors tab's SameColor). A channel saved as anything but a number takes the
-- old value's.
local function CustomizedColor(profile, path)
	local group, key = SplitPath(path)
	local holder = group and profile.colors[group]
	local saved = type(holder) == 'table' and holder[key]
	local old = CO.OLD_COLORS[path]
	if type(saved) ~= 'table' or not old then return nil end
	local c = {}
	for _, channel in ipairs({ 'r', 'g', 'b' }) do
		c[channel] = type(saved[channel]) == 'number' and saved[channel] or old[channel]
	end
	if Byte(c.r) == Byte(old.r) and Byte(c.g) == Byte(old.g) and Byte(c.b) == Byte(old.b) then return nil end
	return c
end

-- Puts c's r, g and b (never an alpha) into a destination. A color table that
-- is there is written into in place, so the active profile's keeps its
-- methods; else a plain one is made, and its group first when that isn't a
-- table.
local function WriteColor(profile, path, c)
	local group, key = SplitPath(path)
	local holder
	if group then
		holder = profile.colors[group]
		if type(holder) ~= 'table' then
			holder = {}
			profile.colors[group] = holder
		end
	else
		holder = profile.theme
		if type(holder) ~= 'table' then
			holder = {}
			profile.theme = holder
		end
	end
	local dest = holder[key]
	if type(dest) == 'table' then
		dest.r, dest.g, dest.b = c.r, c.g, c.b
	else
		holder[key] = { r = c.r, g = c.g, b = c.b }
	end
end

-- A source that is saved and differs from its default (to the byte, opacity
-- too) is written whole into the destination, in place when there is a table
-- (the live profile has one: AceDB gives it its defaults). A channel that is no
-- number takes the default's. A source that is no table, or no default, seeds
-- nothing, and neither does a destination that is already customized.
local function Customized(profile, path)
	local group, key = SplitPath(path)
	local holder = group and profile.colors[group]
	local saved = type(holder) == 'table' and holder[key]
	local defaults = st.defaults and st.defaults.colors and group and st.defaults.colors[group]
	local default = type(defaults) == 'table' and defaults[key]
	if type(saved) ~= 'table' or type(default) ~= 'table' then return nil end
	local c, differs = {}, false
	for _, channel in ipairs({ 'r', 'g', 'b', 'a' }) do
		local fallback = default[channel] or 1
		c[channel] = type(saved[channel]) == 'number' and saved[channel] or fallback
		if Byte(c[channel]) ~= Byte(fallback) then differs = true end
	end
	return differs and c or nil
end

local function SeedColor(profile, source, destination)
	local c = Customized(profile, source)
	-- A destination already saved differently from its default is the owner's: left alone.
	if not c or Customized(profile, destination) then return end
	WriteColor(profile, destination, c)
	local dgroup, dkey = SplitPath(destination)
	profile.colors[dgroup][dkey].a = c.a
end

local function RunStep(profile, step)
	for _, copy in ipairs(step.copy or {}) do
		local c = CustomizedColor(profile, copy[1])
		if c then
			for i = 2, #copy do WriteColor(profile, copy[i], c) end
		end
	end
	for _, path in ipairs(step.retire or {}) do
		local group, key = SplitPath(path)
		local holder = group and profile.colors[group]
		if type(holder) == 'table' then
			-- A key that still has a default (its readers and its Colors row not
			-- converted yet: step 7's) is put back to that default in place on the
			-- live profile's table (AceDB gave it its methods), never nil: the rows
			-- that index it keep working. Anywhere else the key is dropped.
			local default = st.defaults and st.defaults.colors and st.defaults.colors[group]
			default = type(default) == 'table' and default[key]
			local color = holder[key]
			if type(default) == 'table' and type(color) == 'table' and color.GetRGB then
				color.r, color.g, color.b, color.a = default.r, default.g, default.b, default.a
			else
				holder[key] = nil
			end
		end
	end
	for _, pair in ipairs(step.seed or {}) do SeedColor(profile, pair[1], pair[2]) end
	for _, path in ipairs(step.opacity or {}) do
		local group, key = SplitPath(path)
		local holder = group and profile.colors[group]
		local color = type(holder) == 'table' and holder[key]
		if type(color) == 'table' then
			-- In place, never nil, and no table made: a color that was saved
			-- keeps its own channels, and an unsaved one already reads the
			-- default's opacity.
			local default = st.defaults and st.defaults.colors and st.defaults.colors[group]
			default = type(default) == 'table' and default[key]
			color.a = type(default) == 'table' and default.a or 1
		end
	end
end

-- Brings a profile's colors up to the last step: every step after the
-- profile's colors.version runs, then the version is the last step's. A
-- version only rises (a number at or above the last step runs nothing and
-- stays; anything else counts as 0). Table writes only, so it runs in combat,
-- and running it again changes nothing. A profile with no colors table is left
-- alone. Called at login and on every profile change, copy and reset
-- (Config:UpdateConfig).
function st:MigrateColors(profile)
	if type(profile) ~= 'table' or type(profile.colors) ~= 'table' then return end
	local colors = profile.colors
	local from = type(colors.version) == 'number' and colors.version or 0
	local last = #CO.MIGRATION_STEPS
	for n = 1, last do
		if n > from then RunStep(profile, CO.MIGRATION_STEPS[n]) end
	end
	if last > from then colors.version = last end
end

-- The Colors tab's sections, in order. A section is { key, name, note,
-- hasAlpha, colors }: key is its group's key, note shows under its title,
-- hasAlpha gives its swatches an opacity slider. A color is { group, key,
-- name, desc }: group is the profile key st:ColorChanged takes, key the
-- subkey of st.config.profile.colors[group] (nil for renown, which is that
-- key's color itself).
local function Colors(group, list)
	local out = {}
	for i, entry in ipairs(list) do
		out[i] = { group = group, key = entry[1], name = entry[2], desc = entry[3] }
	end
	return out
end

local function Reaction(name)
	return ("The experience bar's reputation bar and the loot feed bar while your standing is %s, and unit frames and the unit tooltip's name and border of NPCs that are %s to you."):format(name, name)
end

CO.SECTIONS = {
	{
		key = 'text', name = 'Text',
		colors = Colors('text', {
			{ 'normal', 'Text', "Ordinary text: the options window, totem timers, the flyout arrow on the totem bar's summon button, and an enemy nameplate's threat text while your threat on it is fine." },
			{ 'muted', 'Muted', "Dimmed text and icons: the options window's hints, captions, section titles and disabled controls, and the diff icon beside a setting that differs; edit mode's hint lines; the bag categories' counts and their edited and yours marker, and the combined bank's visibility toggle; SaftUI's objective tracker's zone headers, counts and chevrons; and a unit frame's level tag for a far lower level." },
			{ 'strong', 'Strong', "Plain item levels and counts in bags, item levels on the character frame, a bank slot's price you can afford, the options window's share line under the mouse, loot roll timer text over a minute, and SaftUI's objective tracker's progress percent and the chevron under the mouse (in the skinned Blizzard tracker too)." },
			{ 'danger', 'Danger', "Errors and refusals: status lines, why a control is disabled, edit mode's refusals, the bank's combat line and a price you can't afford, and the chat's Error prefix and DEBUG label. Also urgency (loot roll timers under a minute, expiring totems, a tracker item out of range), remove icons and the close button under the mouse, hostile names, a unit frame's level tag for a much higher level, and a durability under 20% in the durability figure's tooltip." },
			{ 'warning', 'Warning', "A unit frame's level tag for a somewhat higher level, the poor end of the micro menu's stats, the bag rule editor's OR groups and its Caught now highlight, and a durability from 20% to 49% in the durability figure's tooltip." },
			{ 'caution', 'Caution', "A unit frame's level tag near your level, unfriendly names, the micro menu's alert flash and the middle of its stats, and Caught by: in a bag item's tooltip." },
			{ 'success', 'Success', "Good things: a lower level's tag, bag item levels for a Bind on Equip item, the reagent marker and count, the winner's roll in the loot feed's roll tooltip, and the good end of the micro menu's stats. Also a durability from 50% up in the durability figure's tooltip." },
			{ 'shared', 'Shared', 'Warbound item levels, account-wide currency counts and the warband bank count in bags.' },
		}),
	},
	{
		key = 'button', name = 'Buttons', note = "Opacity sets how strongly it is drawn: 100% is SaftUI's own.", hasAlpha = true,
		colors = Colors('button', {
			{ 'danger', 'Danger', "Locked bank slots, and the flash on an action bar or totem button." },
		}),
	},
	{
		key = 'class', name = 'Class',
		colors = Colors('class', {
			{ 'DEATHKNIGHT', 'Death Knight' }, { 'DEMONHUNTER', 'Demon Hunter' }, { 'DRUID', 'Druid' },
			{ 'EVOKER', 'Evoker' }, { 'HUNTER', 'Hunter' }, { 'MAGE', 'Mage' }, { 'MONK', 'Monk' },
			{ 'PALADIN', 'Paladin' }, { 'PRIEST', 'Priest' }, { 'ROGUE', 'Rogue' }, { 'SHAMAN', 'Shaman' },
			{ 'WARLOCK', 'Warlock' }, { 'WARRIOR', 'Warrior' },
		}),
	},
	{
		key = 'roles', name = 'Roles',
		colors = Colors('roles', {
			{ 'TANK', 'Tank', "The role corner of a tank on unit frames, and in the group test previews." },
			{ 'HEALER', 'Healer', "The role corner of a healer on unit frames, and in the group test previews." },
			{ 'DAMAGER', 'Damage', "The role corner of a damage dealer, or of a unit with no role, on unit frames and in the group test previews: shown with Show damage dealers." },
		}),
	},
	{
		key = 'reaction', name = 'Reputation',
		colors = (function()
			local list = Colors('reaction', {
				{ 1, 'Hated' }, { 2, 'Hostile' }, { 3, 'Unfriendly' }, { 4, 'Neutral' },
				{ 5, 'Friendly' }, { 6, 'Honored' }, { 7, 'Revered' }, { 8, 'Exalted' },
			})
			for _, color in ipairs(list) do
				color.desc = Reaction(color.name:lower())
			end
			list[#list + 1] = { group = 'renown', key = nil, name = 'Renown',
				desc = "The experience bar's reputation bar and the loot feed's bar for a renown (major faction) track." }
			return list
		end)(),
	},
	{
		key = 'factions', name = 'Factions',
		colors = Colors('factions', {
			{ 'Alliance', 'Alliance', "Alliance on the zone text and the world map's zone names: a zone the Alliance holds." },
			{ 'Horde', 'Horde', "Horde on the zone text and the world map's zone names: a zone the Horde holds." },
			{ 'Neutral', 'Neutral', "Neutral on the zone text and the world map's zone names: a contested zone or a sanctuary." },
		}),
	},
	{
		key = 'power', name = 'Power',
		colors = Colors('power', {
			{ 'MANA', 'Mana' }, { 'RAGE', 'Rage' }, { 'FOCUS', 'Focus' }, { 'ENERGY', 'Energy' },
			{ 'RUNIC_POWER', 'Runic power' }, { 'COMBO_POINTS', 'Combo points' }, { 'HOLY_POWER', 'Holy power' },
			{ 'CHI', 'Chi' }, { 'SOUL_SHARDS', 'Soul shards' }, { 'LUNAR_POWER', 'Astral power' },
			{ 'INSANITY', 'Insanity' }, { 'MAELSTROM', 'Maelstrom' }, { 'FURY', 'Fury' }, { 'PAIN', 'Pain' },
			{ 'ARCANE_CHARGES', 'Arcane charges' },
			{ 'AMMOSLOT', 'Ammo' }, { 'FUEL', 'Fuel' }, { 'POWER_TYPE_STEAM', 'Steam' },
			{ 'POWER_TYPE_PYRITE', 'Pyrite' },
		}),
	},
	{
		key = 'item_quality', name = 'Item quality',
		colors = Colors('item_quality', {
			{ 0, 'Poor' }, { 1, 'Common' }, { 2, 'Uncommon' }, { 3, 'Rare' }, { 4, 'Epic' }, { 5, 'Legendary' },
			{ 6, 'Artifact' }, { 7, 'Heirloom' }, { 8, 'WoW Token' },
		}),
	},
	{
		key = 'loot', name = 'Loot',
		colors = Colors('loot', {
			{ 'need', 'Need', "Need on loot rolls: the Need button's letter, and Need in the loot feed's roll tooltip." },
			{ 'greed', 'Greed', "Greed on loot rolls: the Greed button's letter, the roll counts of Greed and its line in the loot feed's roll tooltip." },
			{ 'transmog', 'Transmog', "Transmog on loot rolls: the Transmog button's letter, the roll counts of Transmog and its line in the loot feed's roll tooltip." },
			{ 'pass', 'Pass', "Pass on loot rolls: the Pass button's letter, and All passed (on the feed line and in its roll tooltip) and Pass: in the loot feed's roll tooltip." },
			{ 'mount', 'Mount', "A fresh mount's entry in the loot feed: its border and fill, and its icon's border." },
		}),
	},
	{
		key = 'status', name = 'Status',
		colors = Colors('status', {
			{ 'disconnected', 'Disconnected', 'Unit frame health bars of party and raid members who are offline.' },
			{ 'tapped', 'Tapped', 'Unit frame health bars of enemies that another player has tagged.' },
		}),
	},
	{
		key = 'threat', name = 'Threat',
		colors = Colors('threat', {
			{ 'warning', 'Warning', "An enemy nameplate's health bar and threat text when you're about to pull it as damage or healing, or about to lose it as a tank." },
			{ 'bad', 'Bad', "An enemy nameplate's health bar and threat text when it's attacking you as damage or healing, or someone else while you tank." },
		}),
	},
	{
		key = 'objectives', name = 'Objectives',
		colors = Colors('objectives', {
			{ 'completed', 'Completed', "The line of a finished objective in SaftUI's objective tracker, and in Blizzard's tracker while Skinning -> Objective tracker is on. Blizzard's own is a plain grey; a line you haven't finished keeps its normal color." },
			{ 'failed', 'Failed', "The line of a failed objective in SaftUI's objective tracker, and in Blizzard's tracker while Skinning -> Objective tracker is on. Under the mouse Blizzard brightens a failed quest line, as it does its unfinished lines." },
		}),
	},
}

-- Colors whose readers are generic share a sentence per section.
local GENERIC_DESC = {
	class = "The %s class color on unit frames, name tags and raid frames, and the unit tooltip's name and border.",
	power = 'The %s power bar on unit frames.',
	item_quality = "The %s item color: item names in the loot feed and loot rolls, and item and currency borders in bags.",
}
-- Power colors that SaftUI shows on the player frame's class power points
-- rather than a power bar, with where each exists: combo points (rogues, cat
-- form druids, vehicles), chi (windwalker monks), and on retail only holy power
-- (paladins), soul shards (warlocks) and arcane charges (arcane mages). The
-- bundled oUF builds paladin and warlock class power only from Cataclysm on
-- (GameCompatibility.Cataclysm) and arcane charges only on Midnight, so
-- Forever shows those three nowhere.
local CLASS_POWER_POINTS = {
	COMBO_POINTS = '', CHI = '',
	HOLY_POWER = ' Retail only.', SOUL_SHARDS = ' Retail only.', ARCANE_CHARGES = ' Retail only.',
}
-- The minimap's difficulty badge, shown in any instance, reads Common for
-- normal, Rare for heroic and Epic for mythic.
local DIFFICULTY_BADGE = { [1] = 'normal instances', [3] = 'heroic ones', [4] = 'mythic ones' }
for _, section in ipairs(CO.SECTIONS) do
	local pattern = GENERIC_DESC[section.key]
	for _, color in ipairs(section.colors) do
		if not color.desc and section.key == 'power' and CLASS_POWER_POINTS[color.key] then
			color.desc = ("The %s color on the player frame's class power points."):format(color.name:lower()) .. CLASS_POWER_POINTS[color.key]
		elseif not color.desc and pattern then
			color.desc = pattern:format(color.name)
			if section.key == 'item_quality' and DIFFICULTY_BADGE[color.key] then
				color.desc = color.desc .. " It also colors the minimap's difficulty badge for " .. DIFFICULTY_BADGE[color.key] .. '.'
			end
		end
	end
end

-- The profile's color for a row: st.config.profile.colors[group][key], read
-- at call time so a profile switch reaches the new profile's table.
local function ProfileColor(color)
	local group = st.config.profile.colors[color.group]
	if color.key == nil then return group end
	return group[color.key]
end

-- SaftUI's default for a row: st.defaults.colors[group][key], as ProfileColor.
local function DefaultColor(color)
	local from = st.defaults.colors[color.group]
	if color.key == nil then return from end
	return from[color.key]
end

-- Whether two colors look the same where the Colors tab shows them: each
-- channel as a whole 0-255 (the swatch's hex), and with an opacity (hasAlpha)
-- its whole percent.
local function SameColor(a, b, hasAlpha)
	local function byte(v) return math.floor((v or 0) * 255 + 0.5) end
	if byte(a.r) ~= byte(b.r) or byte(a.g) ~= byte(b.g) or byte(a.b) ~= byte(b.b) then return false end
	return not hasAlpha or math.floor((a.a or 1) * 100 + 0.5) == math.floor((b.a or 1) * 100 + 0.5)
end

-- A color's own reset (the options kit's default field, optionsmodel.lua): a
-- reset icon by the color's swatch while it differs from SaftUI's default; it
-- puts that back, alpha too, and says the color changed (st:ColorChanged).
local function ColorDefault(section, color)
	return {
		differs = function() return not SameColor(ProfileColor(color), DefaultColor(color), section.hasAlpha) end,
		reset = function()
			local from, c = DefaultColor(color), ProfileColor(color)
			c.r, c.g, c.b, c.a = from.r, from.g, from.b, from.a
			st:ColorChanged(color.group, color.key)
		end,
		value = function()
			local from = DefaultColor(color)
			return from.r, from.g, from.b, from.a
		end,
	}
end

-- The color picker's preview of each row that has one (optionspreview.lua):
-- 'group.key' to a kind's name, or to the kind with its own fields. A row
-- with none opens the picker with no preview.
local TEXT_PREVIEW = 'text'
local PREVIEWS = {
	['factions.Alliance'] = { kind = 'text', sample = '(Alliance territory)' },
	['factions.Horde'] = { kind = 'text', sample = '(Horde territory)' },
	['factions.Neutral'] = { kind = 'text', sample = '(Contested territory)' },
	['loot.need'] = TEXT_PREVIEW, ['loot.greed'] = TEXT_PREVIEW,
	['loot.transmog'] = TEXT_PREVIEW, ['loot.pass'] = TEXT_PREVIEW,
	['objectives.completed'] = { kind = 'text', sample = '8/8 Things slain' },
	['objectives.failed'] = { kind = 'text', sample = 'Escort failed' },
}

-- A color's preview that names its key or its label is one table per color,
-- kept (the picker reads it as constants); the rows name what their bar or
-- slot shows.
local POINT_POWERS = { COMBO_POINTS = true, CHI = true, HOLY_POWER = true, SOUL_SHARDS = true, ARCANE_CHARGES = true }
local STATUS_LABELS = { disconnected = 'Offline', tapped = 'Tapped' }
local ROLES_PREVIEW = { kind = 'bar', style = 'role' }
local POINTS_PREVIEW = { kind = 'bar', style = 'points' }
local QUALITY_PREVIEW = { kind = 'border', style = 'slot' }
local MOUNT_PREVIEW = { kind = 'border', style = 'entry' }
local THREAT_PREVIEW = { kind = 'bar', style = 'plate', threat = true }
local DANGER_PREVIEW = 'danger'
local KEPT = {}
local function Kept(color, make)
	local id = color.group .. '.' .. tostring(color.key)
	KEPT[id] = KEPT[id] or make()
	return KEPT[id]
end

local function PreviewOf(color)
	local group = color.group
	if group == 'text' then return TEXT_PREVIEW end
	if group == 'button' then return DANGER_PREVIEW end
	if group == 'class' then
		return Kept(color, function() return { kind = 'bar', style = 'unit', label = color.name } end)
	end
	if group == 'roles' then return ROLES_PREVIEW end
	if group == 'reaction' then
		return Kept(color, function() return { kind = 'bar', style = 'reputation', label = color.name } end)
	end
	if group == 'renown' then
		-- Only the experience bar (and the feed's renown line) wears Renown: no NPC bar or tooltip.
		return Kept(color, function() return { kind = 'bar', style = 'reputation', label = color.name, npc = false, tooltip = false } end)
	end
	if group == 'power' then
		if POINT_POWERS[color.key] then return POINTS_PREVIEW end
		return Kept(color, function() return { kind = 'bar', style = 'power', label = color.name } end)
	end
	if group == 'item_quality' then return QUALITY_PREVIEW end
	if group == 'loot' and color.key == 'mount' then return MOUNT_PREVIEW end
	if group == 'status' then
		-- Status colors only color health: no tooltip.
		return Kept(color, function() return { kind = 'bar', style = 'unit', label = STATUS_LABELS[color.key], tooltip = false } end)
	end
	if group == 'threat' then return THREAT_PREVIEW end
	return PREVIEWS[group .. '.' .. tostring(color.key)]
end

local function SectionGroup(section, index)
	local args = {}
	for i, color in ipairs(section.colors) do
		args[tostring(color.key or color.group)] = {
			type = 'color',
			preview = PreviewOf(color),
			size = 'small',
			order = i,
			name = color.name,
			desc = color.desc,
			hasAlpha = section.hasAlpha or nil,
			get = function()
				return ProfileColor(color):GetRGBA()
			end,
			set = function(_, r, g, b, a)
				local c = ProfileColor(color)
				c.r, c.g, c.b = r, g, b
				if section.hasAlpha then c.a = a end
				st:ColorChanged(color.group, color.key)
			end,
			default = ColorDefault(section, color),
		}
	end
	return {
		type = 'group',
		inline = true,
		order = index,
		name = section.name,
		desc = section.note,
		args = args,
	}
end

------------------------------------------------------------------ the accent

-- The profile's own accent object, the one a set and a reset write into: the
-- active profile's theme.accent (AceDB's filled color, with its methods), made
-- when a profile has none. Never the default's object.
local function ProfileAccent()
	local theme = st.config.profile.theme
	local c = theme.accent
	if type(c) ~= 'table' or not c.GetRGB then
		c = CreateColor(st.defaults.theme.accent.r, st.defaults.theme.accent.g, st.defaults.theme.accent.b)
		theme.accent = c
	end
	return c
end

-- The Accent row of Global settings > Theme (Media/theme.lua places it): one
-- color for every theme, with no opacity and its own reset. A set or a reset
-- says st:ColorChanged('accent'), which what draws in the accent listens for.
function CO:AccentOption(order)
	return {
		type = 'color',
		preview = 'states',
		size = 'small',
		order = order,
		name = 'Accent',
		desc = "SaftUI's accent under every theme: what is on, picked or current, a field you type in, links and marks, fills that show progress, and the chat prefix. Hover, pushed and selected are made from it; the dots set how.",
		get = function()
			return st:Color('accent'):GetRGB()
		end,
		set = function(_, r, g, b)
			local c = ProfileAccent()
			c.r, c.g, c.b = r, g, b
			st:ColorChanged('accent')
		end,
		default = {
			differs = function() return not SameColor(st:Color('accent'), st.defaults.theme.accent) end,
			reset = function()
				local from, c = st.defaults.theme.accent, ProfileAccent()
				c.r, c.g, c.b = from.r, from.g, from.b
				st:ColorChanged('accent')
			end,
			value = function()
				local from = st.defaults.theme.accent
				return from.r, from.g, from.b
			end,
		},
	}
end

-- The Colors tab of Global settings: one inline section per color group, a
-- color swatch per color, each with its own reset by it while it differs
-- from SaftUI's default (no section Reset). Each row's get and set are bound
-- to its own color, so they read no info.
function CO:GetConfigTable()
	local args = {}
	for i, section in ipairs(CO.SECTIONS) do
		args[section.key] = SectionGroup(section, i)
	end
	args.intro = { type = 'description', order = 0, name = 'A change shows everywhere as you pick it. This window takes it when the picker closes.' }
	return { type = 'group', name = 'Colors', order = 2, args = args }
end
