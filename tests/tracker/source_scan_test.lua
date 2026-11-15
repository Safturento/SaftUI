-- SaftUI-Tracker's source, scanned (comments and strings blanked, as
-- tests/core/theme_kinds_test.lua scans) for anything it must never do to
-- Blizzard's objective tracker, its modules and ObjectiveTrackerManager
-- (.agents/taint.md rule 5, the design's "What SaftUI must never do to
-- Blizzard's tracker"). The list of what's allowed, and nothing else:
--   - on the tracker: the three C methods, through getmetatable(tracker).__index
--     (SetClampedToScreen, ClearAllPoints, SetPoint); the reads GetParent,
--     GetNumPoints, GetPoint, GetEffectiveScale, IsClampedToScreen, IsProtected,
--     GetWidth(true) and GetHeight(true); `.Selection:Hide()`;
--   - post-hooks (hooksecurefunc) on its SetPoint, ClearAllPoints, UpdateHeight
--     and SetAlpha, and on a module's Update;
--   - handing it to st:HideEditModeSelection, st:CanMoveNow and st:CornerOffset;
--   - no writes onto it, no call of one of its own fields, no method of a module
--     or ObjectiveTrackerManager, none of the words the design bans.
-- Every file the TOC loads is scanned. A scan that finds no reference to
-- ObjectiveTrackerFrame at all fails (a renamed global would otherwise pass).
-- The scanner has its own cases: what it flags and what it lets through.
local TW = load_test_file('tracker/tracker_world.lua')
local OT = load_test_file('misc/fixtures/objective_tracker.lua')

------------------------------------------------------------------ the scanner

local function Blank(text) return (text:gsub('[^\n]', ' ')) end

-- source with its comments blanked (code), and with its comments and the
-- contents of its strings blanked (mask). Both keep the length and the newlines.
local function Lex(source)
	local code, mask = {}, {}
	local function add(c, m)
		code[#code + 1], mask[#mask + 1] = c, m or c
	end
	local i, n = 1, #source
	while i <= n do
		local c = source:sub(i, i)
		local long = source:match('^%[(=*)%[', i)
		if source:sub(i, i + 1) == '--' then
			local level = source:match('^%[(=*)%[', i + 2)
			local stop
			if level then
				local _, e = source:find(']' .. level .. ']', i + 2, true)
				stop = e or n
			else
				stop = (source:find('\n', i, true) or (n + 1)) - 1
			end
			add(Blank(source:sub(i, stop)))
			i = stop + 1
		elseif long then
			local open = #long + 2
			local _, e = source:find(']' .. long .. ']', i + open, true)
			e = e or n
			add(source:sub(i, e),
				source:sub(i, i + open - 1) .. Blank(source:sub(i + open, e - open)) .. source:sub(e - open + 1, e))
			i = e + 1
		elseif c == '"' or c == "'" then
			local j = i + 1
			while j <= n do
				local d = source:sub(j, j)
				if d == '\\' then
					j = j + 2
				elseif d == c or d == '\n' then
					break
				else
					j = j + 1
				end
			end
			add(source:sub(i, j), c .. Blank(source:sub(i + 1, j - 1)) .. source:sub(j, j))
			i = j + 1
		else
			local j = source:find('[%-%[\'"]', i + 1) or (n + 1)
			add(source:sub(i, j - 1))
			i = j
		end
	end
	return table.concat(code), table.concat(mask)
end

local function LineAt(text, position)
	local _, newlines = text:sub(1, position):gsub('\n', '')
	return newlines + 1
end

local function Set(list)
	local set = {}
	for _, item in ipairs(list) do set[item] = true end
	return set
end

local C_METHODS = Set({ 'SetClampedToScreen', 'ClearAllPoints', 'SetPoint' })
local READS = Set({ 'GetParent', 'GetNumPoints', 'GetPoint', 'GetEffectiveScale', 'IsClampedToScreen', 'IsProtected' })
local SIZE_READS = Set({ 'GetWidth', 'GetHeight' }) -- with ignoreRect: (true)
local TRACKER_HOOKS = Set({ 'SetPoint', 'ClearAllPoints', 'UpdateHeight', 'SetAlpha' })
local ALLOWED_HELPERS = Set({ 'HideEditModeSelection', 'CanMoveNow', 'CornerOffset' })
local BANNED_WORDS = {
	'ShouldShowMawBuffs', 'UseQuestLogSpecialItem', 'RemoveModule', 'RemoveAllModules', 'SetModuleContainer',
	'SetRolesets', 'AddRoleset',
}
local MODULES = OT.MODULES

-- Every match of pattern in text: fn(start, capture1, capture2, capture3).
local function Each(text, pattern, fn)
	local init = 1
	while true do
		local s, e, a, b, c = text:find(pattern, init)
		if not s then return end
		fn(s, a, b, c)
		init = math.max(e, s) + 1
	end
end

-- The names Blizzard's tracker goes by in source: ObjectiveTrackerFrame
-- itself, and every name assigned from one of them ("local tracker = ...",
-- "self.blizzardFrame = tracker"), by its last component.
local function TrackerNames(mask)
	local names = { ObjectiveTrackerFrame = true }
	for _ = 1, 4 do
		Each(mask, '([%w_%.]+)%s+=%s+([^\n]*)', function(_, left, right)
			local name = left:match('([%w_]+)$')
			if not name or names[name] then return end
			-- Only a plain name or a global's field ("_G.ObjectiveTrackerFrame",
			-- "tracker"): not a call or the frame's metatable.
			local source = right:match('^([%w_%.]+)%s*$')
			if source and names[source:match('([%w_]+)$')] then names[name] = true end
		end)
	end
	return names
end

-- The problems in one file's source, each "line N: what".
local function Scan(source)
	local code, mask = Lex(source)
	local problems = {}
	local function Flag(position, message) problems[#problems + 1] = ('line %d: %s'):format(LineAt(mask, position), message) end

	for _, word in ipairs(BANNED_WORDS) do
		Each(mask, '%f[%w_]' .. word .. '%f[^%w_]', function(s) Flag(s, word .. ' is never named') end)
	end

	local names = TrackerNames(mask)
	-- Names bound to the frame's own metatable methods: "local m = getmetatable(tracker).__index".
	local methods = {}
	for name in pairs(names) do
		Each(mask, '([%w_]+)%s*=%s*getmetatable%(%s*[%w_%.]*' .. name .. '%s*%)%s*%.%s*__index', function(_, bound) methods[bound] = true end)
	end

	for name in pairs(names) do
		local before = '%f[%w_]' .. name
		-- tracker:Method(...)
		Each(mask, before .. '%s*:%s*([%w_]+)%s*%(([^\n]*)', function(s, method, rest)
			if READS[method] then return end
			if SIZE_READS[method] and rest:match('^%s*true%s*[%),]') then return end
			Flag(s, ('%s:%s() is not on the list of what may be called'):format(name, method))
		end)
		-- tracker.field = value, tracker[key] = value
		Each(mask, before .. '%s*%.%s*([%w_]+)%s*=[^=]', function(s, field) Flag(s, ('a field written onto it: %s.%s'):format(name, field)) end)
		Each(mask, before .. '%s*%[[^%]\n]*%]%s*=[^=]', function(s) Flag(s, 'a key written onto it: ' .. name .. '[...]') end)
		-- tracker.field:Method(), tracker.field(...)
		Each(mask, before .. '%s*%.%s*([%w_]+)%s*:%s*([%w_]+)', function(s, field, method)
			if field == 'Selection' and method == 'Hide' then return end
			Flag(s, ('%s.%s:%s() is not on the list of what may be called'):format(name, field, method))
		end)
		Each(mask, before .. '%s*%.%s*([%w_]+)%s*%(', function(s, field)
			Flag(s, ('%s.%s() calls one of its own functions'):format(name, field))
		end)
		-- getmetatable(tracker) is only ever asked for its __index.
		Each(mask, 'getmetatable%(%s*[%w_%.]*' .. name .. '%s*%)(%s*%.?%s*[%w_]*)', function(s, after)
			if not after:match('^%s*%.%s*__index') then Flag(s, 'getmetatable(' .. name .. ') is only for .__index') end
		end)
		Each(mask, 'getmetatable%(%s*[%w_%.]*' .. name .. '%s*%)%s*%.%s*__index%s*%.%s*([%w_]+)', function(s, method)
			if not C_METHODS[method] then Flag(s, method .. ' is not one of the three C methods') end
		end)
		-- handed to Core's helpers: only the three that read or hide the box.
		Each(mask, 'st%s*:%s*([%w_]+)%s*%(%s*' .. name .. '%s*[,%)]', function(s, helper)
			if not ALLOWED_HELPERS[helper] then Flag(s, 'st:' .. helper .. ' is given Blizzard\'s tracker') end
		end)
		-- hooksecurefunc(tracker, 'Method', ...): the named post-hooks only.
		Each(mask, 'hooksecurefunc%(%s*[%w_%.]*' .. name .. '%s*,', function(s)
			local second = code:sub(s):match('^hooksecurefunc%(%s*[%w_%.]*[%w_]+%s*,%s*([^,%)]*)')
			local hooked = second and second:match('^[\'"]([%w_]+)[\'"]$')
			if not (hooked and TRACKER_HOOKS[hooked]) then
				Flag(s, 'a hook on the tracker other than SetPoint, ClearAllPoints, UpdateHeight or SetAlpha')
			end
		end)
	end

	for bound in pairs(methods) do
		Each(mask, '%f[%w_]' .. bound .. '%s*%.%s*([%w_]+)%s*%(', function(s, method)
			if not C_METHODS[method] then Flag(s, method .. ' is not one of the three C methods') end
		end)
		Each(mask, '%f[%w_]' .. bound .. '%s*%.%s*([%w_]+)%s*=[^=]', function(s) Flag(s, 'a method of the frame replaced') end)
	end

	for _, module in ipairs(MODULES) do
		local before = '%f[%w_]' .. module
		Each(mask, before .. '%s*:%s*([%w_]+)', function(s, method)
			Flag(s, ('%s:%s() is a method of one of its modules'):format(module, method))
		end)
		Each(mask, before .. '%s*%.%s*([%w_]+)%s*=[^=]', function(s, field) Flag(s, ('a field written onto %s.%s'):format(module, field)) end)
		Each(mask, before .. '%s*%.%s*([%w_]+)%s*%(', function(s, field) Flag(s, ('%s.%s() calls one of its functions'):format(module, field)) end)
		Each(mask, 'hooksecurefunc%(%s*' .. module .. '%s*,', function(s)
			local second = code:sub(s):match('^hooksecurefunc%(%s*[%w_]+%s*,%s*([^,%)]*)')
			if not (second and second:match('^[\'"]Update[\'"]$')) then Flag(s, 'a hook on a module other than its Update') end
		end)
	end

	-- A module held in a variable: the loop over the tracker's `modules` list, or
	-- `module = _G[<the section's module name>]`. It may be hooked (Update only),
	-- have its fields read (state, hasContents) and be named through the metatable's
	-- C method (`getmetatable(module).__index.GetName`, for the chat line about a
	-- module nobody knows); nothing else, so a plain `module:GetName()` is flagged.
	local modvars = {}
	for name in pairs(names) do
		Each(mask, 'for%s+[%w_]+%s*,%s*([%w_]+)%s+in%s+ipairs%(%s*[%w_%.]*' .. name .. '%s*%.%s*modules%s*%)', function(_, var) modvars[var] = true end)
	end
	Each(mask, '([%w_]+)%s*=%s*_G%s*%[%s*[%w_%.]*module%s*%]', function(_, var) modvars[var] = true end)
	for var in pairs(modvars) do
		local before = '%f[%w_]' .. var
		Each(mask, before .. '%s*:%s*([%w_]+)', function(s, method)
			Flag(s, ('%s:%s() is a method of one of its modules'):format(var, method))
		end)
		Each(mask, before .. '%s*%.%s*([%w_]+)%s*=[^=]', function(s, field) Flag(s, ('a field written onto a module: %s.%s'):format(var, field)) end)
		Each(mask, before .. '%s*%.%s*([%w_]+)%s*%(', function(s, field) Flag(s, ('%s.%s() calls one of a module\'s functions'):format(var, field)) end)
		Each(mask, before .. '%s*%.%s*[%w_]+%s*:%s*([%w_]+)', function(s, method) Flag(s, ('a method of a module\'s part: %s...:%s()'):format(var, method)) end)
		Each(mask, 'hooksecurefunc%(%s*' .. var .. '%s*,', function(s)
			local second = code:sub(s):match('^hooksecurefunc%(%s*[%w_]+%s*,%s*([^,%)]*)')
			if not (second and second:match('^[\'"]Update[\'"]$')) then Flag(s, 'a hook on a module other than its Update') end
		end)
	end
	-- The widget container: its count is a read; nothing else is called or written.
	Each(mask, '%f[%w_]ObjectiveTrackerUIWidgetContainer%s*:%s*([%w_]+)', function(s, method)
		if method ~= 'GetNumWidgetsShowing' then Flag(s, ('ObjectiveTrackerUIWidgetContainer:%s() is not on the list'):format(method)) end
	end)
	Each(mask, '%f[%w_]ObjectiveTrackerUIWidgetContainer%s*%.%s*[%w_]+%s*[=%(]', function(s) Flag(s, 'a write or call on ObjectiveTrackerUIWidgetContainer\'s field') end)

	Each(mask, '%f[%w_]ObjectiveTrackerManager%s*:', function(s) Flag(s, 'a method of ObjectiveTrackerManager') end)
	Each(mask, '%f[%w_]ObjectiveTrackerManager%s*%.%s*[%w_]+%s*%(', function(s) Flag(s, 'a function of ObjectiveTrackerManager') end)
	Each(mask, '%f[%w_]ObjectiveTrackerManager%s*%.%s*[%w_]+%s*=[^=]', function(s) Flag(s, 'a field written onto ObjectiveTrackerManager') end)
	return problems, select(2, mask:gsub('%f[%w_]ObjectiveTrackerFrame%f[^%w_]', ''))
end

------------------------------------------------------------------ cases

test('the files: nothing the tracker must never do to Blizzard\'s tracker, its modules or ObjectiveTrackerManager', function()
	local files = TW.toc_files()
	check(#files >= 8, 'every file the TOC loads: ' .. #files)
	local references, found = 0, {}
	for _, path in ipairs(files) do
		local source = read_saftui_source(path)
		if check(source ~= nil, path .. ' is read') then
			local problems, count = Scan(source)
			references = references + count
			for _, problem in ipairs(problems) do found[#found + 1] = path .. ' ' .. problem end
		end
	end
	eq(table.concat(found, '\n'), '', 'nothing off the list')
	check(references >= 1, 'a scan that finds no ObjectiveTrackerFrame at all would pass anything: found ' .. references)
	-- blizzard.lua is the one that holds it.
	local source = read_saftui_source('SaftUI-Tracker/blizzard.lua')
	check(source ~= nil and select(2, Scan(source)) >= 1, 'blizzard.lua names ObjectiveTrackerFrame')
	local listed = false
	for _, path in ipairs(files) do if path == 'SaftUI-Tracker/blizzard.lua' then listed = true end end
	check(listed, 'blizzard.lua is in the TOC')
end)

test('the scanner flags what is off the list and lets the allowed through', function()
	local function flagged(source) return #(Scan(source)) end
	local prefix = "local tracker = _G.ObjectiveTrackerFrame\n"
	-- Off the list.
	for _, bad in ipairs({
		'tracker:Hide()', 'tracker:Show()', 'tracker:SetShown(true)', 'tracker:SetParent(UIParent)', 'tracker:SetScale(1)',
		'tracker:SetSize(1, 1)', 'tracker:SetWidth(1)', 'tracker:SetAlpha(0)', 'tracker:SetPoint("TOPLEFT")',
		'tracker:ClearAllPoints()', 'tracker:MarkDirty()', 'tracker:Update()', 'tracker:UpdateHeight()',
		'tracker:SetCollapsed(true)', 'tracker:UnregisterAllEvents()', 'tracker:UnregisterEvent("X")', 'tracker:GetRect()',
		'tracker:GetRight()', 'tracker:GetWidth()', 'tracker:GetHeight(false)', 'tracker:IsMouseOver()', 'tracker:SetRolesets("x")',
		'tracker:EnableMouse(false)', 'tracker.foo = 1', 'tracker["foo"] = 1', 'tracker.Update(tracker)', 'tracker.Header:Hide()',
		'tracker.Selection:Show()', 'getmetatable(tracker).__index.Hide(tracker)', 'getmetatable(tracker).__index.SetAlpha(tracker, 0)',
		'local m = getmetatable(tracker).__index\nm.Hide(tracker)', 'local m = getmetatable(tracker).__index\nm.SetParent = nil',
		'getmetatable(tracker).__newindex = nil', 'local t = getmetatable(tracker)',
		'st:SetPointDirect(tracker, "TOPLEFT")', 'st:Kill(tracker)',
		'hooksecurefunc(tracker, "Show", f)', 'hooksecurefunc(tracker, "Update", f)', 'hooksecurefunc(tracker, name, f)',
		'local other = tracker\nother:Hide()', 'self.blizzardFrame = tracker\nself.blizzardFrame:Hide()',
		'ObjectiveTrackerFrame:Hide()', '_G.ObjectiveTrackerFrame:SetParent(nil)',
		'QuestObjectiveTracker:Update()', 'QuestObjectiveTracker:SetCollapsed(true)', 'ScenarioObjectiveTracker.foo = 1',
		'hooksecurefunc(QuestObjectiveTracker, "Show", f)', 'hooksecurefunc(ScenarioObjectiveTracker, "OnLoad", f)',
		'ObjectiveTrackerManager:Init()', 'ObjectiveTrackerManager.Foo()', 'ObjectiveTrackerManager.x = 1',
		'ShouldShowMawBuffs()', 'UseQuestLogSpecialItem(1)', 'tracker:RemoveModule(m)', 'x:SetRolesets("alwaysBlocked")',
		-- a module in a variable, by the loop over the list or by name
		-- the name only through the metatable's C method (a plain call is the module's own function)
		'for _, module in ipairs(tracker.modules) do local name = module:GetName() end',
		'local module = _G[section.module]\nlocal name = module:GetName()',
		'for _, module in ipairs(tracker.modules) do module:Hide() end', 'for i, m in ipairs(tracker.modules) do m:SetCollapsed(true) end',
		'for _, module in ipairs(tracker.modules) do module.state = 1 end', 'for _, module in ipairs(ObjectiveTrackerFrame.modules) do module:Update() end',
		'for _, module in ipairs(tracker.modules) do hooksecurefunc(module, "Show", f) end',
		'for _, module in ipairs(tracker.modules) do hooksecurefunc(module, name, f) end',
		'for _, module in ipairs(tracker.modules) do module.Header:Hide() end', 'for _, module in ipairs(tracker.modules) do module.Update(module) end',
		'local module = _G[section.module]\nmodule:MarkDirty()', 'local module = _G[section.module]\nmodule:UnregisterAllEvents()',
		'ObjectiveTrackerUIWidgetContainer:Hide()', 'ObjectiveTrackerUIWidgetContainer:SetAlpha(1)', 'ObjectiveTrackerUIWidgetContainer.numWidgetsShowing = 0',
	}) do
		check(flagged(prefix .. bad) > 0, 'flags: ' .. bad:gsub('\n', ' / '))
	end
	-- On the list.
	for _, good in ipairs({
		'local methods = getmetatable(tracker).__index\nmethods.SetClampedToScreen(tracker, false)\nmethods.ClearAllPoints(tracker)\nmethods.SetPoint(tracker, "TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)',
		'getmetatable(tracker).__index.SetPoint(tracker, "TOPRIGHT", UIParent, "TOPRIGHT", 0, 0)',
		'local p, r, rp, x, y = tracker:GetPoint(1)\nlocal n = tracker:GetNumPoints()\nlocal parent = tracker:GetParent()',
		'local s = tracker:GetEffectiveScale()\nlocal c = tracker:IsClampedToScreen()\nlocal q = tracker:IsProtected()',
		'local w, h = tracker:GetWidth(true), tracker:GetHeight(true)',
		'if tracker.Selection then tracker.Selection:Hide() end',
		'hooksecurefunc(tracker, "SetPoint", f)\nhooksecurefunc(tracker, "ClearAllPoints", f)\nhooksecurefunc(tracker, "UpdateHeight", f)\nhooksecurefunc(tracker, "SetAlpha", f)',
		'hooksecurefunc(QuestObjectiveTracker, "Update", f)',
		'for _, module in ipairs(tracker.modules) do\nlocal s, h = module.state, module.hasContents\nhooksecurefunc(module, "Update", f)\nend',
		'local module = _G[section.module]\nif module then hooksecurefunc(module, "Update", f) end\nlocal state = module.state',
		'for _, module in ipairs(tracker.modules) do\nlocal getName = getmetatable(module).__index.GetName\nlocal key = getName(module)\nend',
		'local n = ObjectiveTrackerUIWidgetContainer:GetNumWidgetsShowing()', 'local c = ObjectiveTrackerUIWidgetContainer ~= nil',
		'st:HideEditModeSelection(tracker)\nst:CanMoveNow(tracker)\nlocal x, y = st:CornerOffset(tracker, parent, "TOPRIGHT", 1, 2)',
		'if type(tracker.UpdateHeight) == "function" then end',
		'local shown = tracker.Selection ~= nil',
		'return _G.ObjectiveTrackerFrame ~= nil',
		'self.blizzardFrame = tracker\nlocal at = self.blizzardFrame:GetNumPoints()',
		-- a comment or a string naming what is banned is not a call.
		'-- tracker:Hide() and ShouldShowMawBuffs',
		'--[[ tracker:SetParent(x)\nObjectiveTrackerManager:Init() ]]',
		'print("tracker:Hide() RemoveModule")',
		-- SaftUI's own frames and methods share names with Blizzard's.
		'local window = CreateFrame("Frame")\nwindow:Hide()\nwindow:SetParent(UIParent)\nTR:MarkDirty("x")\nTR:Update()',
		'TR.holder:SetPoint("TOPLEFT")\nself.eventFrame:UnregisterEvent("PLAYER_MONEY")',
	}) do
		local problems = Scan(prefix .. good)
		eq(table.concat(problems, '; '), '', 'allows: ' .. good:gsub('\n', ' / '))
	end
	-- A name bound later (a field set from the local) is followed.
	check(flagged(prefix .. 'self.blizzardFrame = tracker\nself.blizzardFrame:SetShown(false)') > 0, 'a name bound from the tracker is followed')
	-- Lines are reported.
	local problems = Scan(prefix .. '\n\ntracker:Hide()')
	eq(problems[1], 'line 4: tracker:Hide() is not on the list of what may be called', 'the line and the call')
	-- Without any reference the count says so.
	eq(select(2, Scan('local x = 1')), 0, 'no ObjectiveTrackerFrame counted where there is none')
	eq(select(2, Scan('return _G.ObjectiveTrackerFrame')), 1, 'and one where there is one')
	eq(select(2, Scan('-- ObjectiveTrackerFrame in a comment')), 0, 'none in a comment')
end)
