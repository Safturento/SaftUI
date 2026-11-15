-- What a color pass costs, counted: for the tests of Media/colors.lua's pass
-- and of every reader that follows it (the plan's "A pass only colors": no
-- frame, texture or font string made; no Show, Hide, SetShown, SetParent,
-- SetPoint, ClearAllPoints, SetSize, SetWidth, SetHeight, SetAttribute or
-- SetScript on a frame; no re-skinning; no garbage to speak of). A test file
-- loads it with
--
--   local C = load_test_file('lib/color_cost.lua')
--
-- and it makes no global. tests/lib/color_cost_test.lua tests it.
--
--   C.measure(fn, runs, ignore) -> { calls = { total, by = { [method] = n } },
--       forbidden = { total, by }, made = n, kb = <garbage over all runs, KB>,
--       ms = <the slowest run, in the stub's ms> }
--       Runs fn(), runs times (default 1), and counts every method of
--       C.SETTERS, C.FORBIDDEN and C.MAKERS on the method tables of every
--       widget type the stubs have (Frame, Button, CheckButton, StatusBar,
--       EditBox, ScrollFrame, Slider, Cooldown, GameTooltip, Texture,
--       MaskTexture, FontString, Font), on the stubs' backdrop functions
--       (stub.backdrop: Mixin copies the backdrop methods onto each frame, so
--       there they are counted one level down) and the global CreateFrame, as
--       tests/tracker/rows_world.lua's RW.calls counts setters. They are put
--       back after, even when fn errors (then the error is raised again).
--       calls counts the setters (st:SetBorderColor is SetBackdropBorderColor
--       under Thick and Thin), forbidden the forbidden methods (a texture or a
--       font string may Show, Hide or SetShown; any other forbidden method on
--       one counts), made the makers called. The stubs' color setters make no
--       garbage, so kb is the reader's own. CO.ticker's own Show and Hide are
--       never counted.
--       ignore, optional, is a set of widgets whose forbidden calls and makes
--       are left out: only the frames that are the cause of the pass (the
--       picker hiding itself as combat cancels it), never a frame the reader
--       paints. Their setter calls still count, so it cannot hide a painting.
--       A reader's cost case measures st:ColorChanged(group, key) outside an
--       edit, which passes at once: around C.edit and C.step the stub's
--       fire_script adds garbage of its own.
--   C.step(st)       one frame: fires CO.ticker's OnUpdate while it is shown.
--   C.edit(st, fn)   st:BeginColorEdit(); fn(); st:EndColorEdit(); the edit is
--                    ended when fn errors too (the error is raised again).
--   C.print(label, m)  '  <label>: <ms> ms, <calls> calls', shown under -v.

local C = {}

C.FORBIDDEN = { 'Show', 'Hide', 'SetShown', 'SetParent', 'SetPoint', 'ClearAllPoints', 'SetSize',
	'SetWidth', 'SetHeight', 'SetAttribute', 'SetScript', -- on frames; a texture may Show or Hide
	'SetTexture', 'SetAtlas', 'SetBackdrop', 'SetFont', 'SetTextInsets' } -- re-skinning, on anything
C.MAKERS = { 'CreateFrame', 'CreateTexture', 'CreateFontString' }
C.SETTERS = { 'SetVertexColor', 'SetTextColor', 'SetColorTexture', 'SetStatusBarColor', 'SetGradient',
	'SetBackdropColor', 'SetBackdropBorderColor', 'SetText', 'SetFormattedText' }

C.isSetter, C.isForbidden, C.isMaker = {}, {}, {}
for _, name in ipairs(C.SETTERS) do C.isSetter[name] = true end
for _, name in ipairs(C.FORBIDDEN) do C.isForbidden[name] = true end
for _, name in ipairs(C.MAKERS) do C.isMaker[name] = true end

-- What a texture or a font string may do without it counting.
local REGION_MAY = { Show = true, Hide = true, SetShown = true }

-- One widget of each stub type, for its method table, made once per world (a
-- reset_world makes new method tables).
local cache, cached_for
local function samples()
	if cached_for == _G.CreateFrame then return cache end
	cache = {
		{ CreateFrame('Frame') }, { CreateFrame('Button') }, { CreateFrame('CheckButton') },
		{ CreateFrame('StatusBar') }, { CreateFrame('EditBox') }, { CreateFrame('ScrollFrame') },
		{ CreateFrame('Slider') }, { CreateFrame('Cooldown') }, { CreateFrame('GameTooltip') },
		{ UIParent:CreateTexture(nil, 'ARTWORK'), true }, { UIParent:CreateMaskTexture(), true },
		{ UIParent:CreateFontString(nil, 'OVERLAY'), true }, { CreateFont('SaftUI_ColorCostSampleFont') },
	}
	cached_for = _G.CreateFrame
	return cache
end

-- The mechanism's own frame, never counted: a reader's cost case isn't about it.
local colors, colors_for
local function ticker()
	if colors_for ~= SaftUI then
		colors, colors_for = SaftUI:GetModule('Colors', true), SaftUI
	end
	return colors and colors.ticker
end
samples() -- before any test file can replace the stubs
ticker()

function C.measure(fn, runs, ignore)
	runs = runs or 1
	local calls, forbidden = { total = 0, by = {} }, { total = 0, by = {} }
	local result = { calls = calls, forbidden = forbidden, made = 0, kb = 0, ms = 0 }
	local restore = {}
	local own = ticker()

	local function wrap(methods, name, region)
		local original = rawget(methods, name)
		if not original then return end
		restore[#restore + 1] = { methods, name, original }
		local setter, maker = C.isSetter[name], C.isMaker[name]
		local forbid = C.isForbidden[name] and not (region and REGION_MAY[name])
		methods[name] = function(self, ...)
			if setter then
				calls.total = calls.total + 1
				calls.by[name] = (calls.by[name] or 0) + 1
			end
			if (forbid or maker) and self ~= own and not (ignore and ignore[self]) then
				if forbid then
					forbidden.total = forbidden.total + 1
					forbidden.by[name] = (forbidden.by[name] or 0) + 1
				end
				if maker then result.made = result.made + 1 end
			end
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
	-- Mixin copies the backdrop methods onto each frame; the copies call these.
	if stub.backdrop then
		for _, name in ipairs({ 'SetBackdropColor', 'SetBackdropBorderColor', 'SetBackdrop' }) do
			wrap(stub.backdrop, name, false)
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

-- One frame of the game's clock for the pass: CO.ticker's OnUpdate, while it is shown.
function C.step(st)
	local frame = ticker()
	if frame and frame:IsShown() then stub.fire_script(frame, 'OnUpdate', 0.016) end
end

function C.edit(st, fn)
	st:BeginColorEdit()
	local ok, err = pcall(fn)
	st:EndColorEdit()
	if not ok then error(err, 0) end
end

function C.print(label, m)
	print(('  %s: %.1f ms, %d calls'):format(label, m.ms, m.calls.total))
end

return C
