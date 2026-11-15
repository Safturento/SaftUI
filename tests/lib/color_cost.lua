-- What a color pass costs, counted: for the tests of Media/colors.lua's pass
-- and of every reader that follows it (the plan's "A pass only colors": no
-- frame, texture or font string made; no Show, Hide, SetShown, SetParent,
-- SetPoint, ClearAllPoints, SetSize, SetWidth, SetHeight, SetAttribute or
-- SetScript on a frame; no garbage to speak of). A test file loads it with
--
--   local C = load_test_file('lib/color_cost.lua')
--
-- and it makes no global.
--
--   C.measure(fn, runs, ignore) -> { calls = { total, by = { [method] = n } },
--       forbidden = { total, by }, made = n, kb = <garbage over all runs, KB>,
--       ms = <the slowest run, in the stub's ms> }
--       Runs fn(), runs times (default 1), and counts every method of
--       C.SETTERS, C.FORBIDDEN and C.MAKERS on the stub widget types' method
--       tables (as tests/tracker/rows_world.lua's RW.calls counts setters), and
--       the global CreateFrame; the methods are put back after, even when fn
--       errors (then the error is raised again). ignore, optional, is a set of
--       widgets whose calls are not counted (a picker hiding itself as the
--       pass's cause, say). calls counts the setters,
--       forbidden the forbidden methods called on a frame (a texture or a font
--       string may Show, Hide or SetShown; any other forbidden method on one
--       counts), made the makers called.
--   C.step(st)       one frame: fires CO.ticker's OnUpdate while it is shown.
--   C.edit(st, fn)   st:BeginColorEdit(); fn(); st:EndColorEdit().
--   C.print(label, m)  '  <label>: <ms> ms, <calls> calls', shown under -v.

local C = {}

C.FORBIDDEN = { 'Show', 'Hide', 'SetShown', 'SetParent', 'SetPoint', 'ClearAllPoints', 'SetSize',
	'SetWidth', 'SetHeight', 'SetAttribute', 'SetScript' } -- on frames; a texture may Show or Hide
C.MAKERS = { 'CreateFrame', 'CreateTexture', 'CreateFontString' }
C.SETTERS = { 'SetVertexColor', 'SetTextColor', 'SetColorTexture', 'SetStatusBarColor', 'SetGradient',
	'SetBackdropColor', 'SetBackdropBorderColor', 'SetText', 'SetFormattedText' }

-- What a texture or a font string may do without it counting.
local REGION_MAY = { Show = true, Hide = true, SetShown = true }

-- One of each stub widget type, for its method table.
local function samples()
	local out = {
		{ CreateFrame('Frame') }, { CreateFrame('Button') }, { CreateFrame('CheckButton') },
		{ CreateFrame('StatusBar') }, { CreateFrame('EditBox') }, { CreateFrame('ScrollFrame') },
		{ UIParent:CreateTexture(nil, 'ARTWORK'), true }, { UIParent:CreateFontString(nil, 'OVERLAY'), true },
	}
	return out
end

function C.measure(fn, runs, ignore)
	runs = runs or 1
	local calls, forbidden = { total = 0, by = {} }, { total = 0, by = {} }
	local result = { calls = calls, forbidden = forbidden, made = 0, kb = 0, ms = 0 }
	local restore = {}

	local function wrap(methods, name, region)
		local original = rawget(methods, name)
		if not original then return end
		restore[#restore + 1] = { methods, name, original }
		local setter, forbid, maker = C.isSetter[name], C.isForbidden[name] and not (region and REGION_MAY[name]), C.isMaker[name]
		methods[name] = function(self, ...)
			if ignore and ignore[self] then return original(self, ...) end
			if setter then
				calls.total = calls.total + 1
				calls.by[name] = (calls.by[name] or 0) + 1
			end
			if forbid then
				forbidden.total = forbidden.total + 1
				forbidden.by[name] = (forbidden.by[name] or 0) + 1
			end
			if maker then result.made = result.made + 1 end
			return original(self, ...)
		end
	end

	local seen = {}
	for _, sample in ipairs(samples()) do
		local methods = getmetatable(sample[1]).__index
		if type(methods) == 'table' and not seen[methods] then
			seen[methods] = true
			for _, list in ipairs({ C.SETTERS, C.FORBIDDEN, C.MAKERS }) do
				for _, name in ipairs(list) do wrap(methods, name, sample[2]) end
			end
		end
	end
	local realCreateFrame = _G.CreateFrame
	_G.CreateFrame = function(...)
		result.made = result.made + 1
		return realCreateFrame(...)
	end

	-- The tables the counting needs are made before the garbage is read, so the
	-- run's own count is all it adds.
	for _, name in ipairs(C.SETTERS) do calls.by[name] = 0 end
	for _, name in ipairs(C.FORBIDDEN) do forbidden.by[name] = 0 end

	local ok, err = pcall(function()
		collectgarbage(); collectgarbage()
		collectgarbage('stop')
		local before = collectgarbage('count')
		for _ = 1, runs do
			local t0 = debugprofilestop()
			fn()
			local ms = debugprofilestop() - t0
			if ms > result.ms then result.ms = ms end
		end
		result.kb = collectgarbage('count') - before
		collectgarbage('restart')
	end)
	_G.CreateFrame = realCreateFrame
	for _, saved in ipairs(restore) do saved[1][saved[2]] = saved[3] end
	if not ok then
		collectgarbage('restart')
		error(err, 0)
	end
	for name, n in pairs(calls.by) do if n == 0 then calls.by[name] = nil end end
	for name, n in pairs(forbidden.by) do if n == 0 then forbidden.by[name] = nil end end
	return result
end

C.isSetter, C.isForbidden, C.isMaker = {}, {}, {}
for _, name in ipairs(C.SETTERS) do C.isSetter[name] = true end
for _, name in ipairs(C.FORBIDDEN) do C.isForbidden[name] = true end
for _, name in ipairs(C.MAKERS) do C.isMaker[name] = true end

-- One frame of the game's clock for the pass: CO.ticker's OnUpdate, while it is shown.
function C.step(st)
	local ticker = st:GetModule('Colors').ticker
	if ticker:IsShown() then stub.fire_script(ticker, 'OnUpdate', 0.016) end
end

function C.edit(st, fn)
	st:BeginColorEdit()
	fn()
	st:EndColorEdit()
end

function C.print(label, m)
	print(('  %s: %.1f ms, %d calls'):format(label, m.ms, m.calls.total))
end

return C
