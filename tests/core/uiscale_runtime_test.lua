-- The scale at login and after every change (SaftUI-Core/uiscale.lua's
-- runtime): Start, the check the screen events run on the next frame, Preview,
-- Apply and Revert, and the callbacks that follow a change. The model itself
-- (Resolve, the tokens) is tests/core/uiscale_test.lua's.
--
-- What the game did, as the owner read it in game (.agents/clients.md, "Screen
-- and UI scale"): the engine sets UIParent's scale over SaftUI's on a UI Scale
-- slider change and on a display change, by the time the events arrive, in
-- pairs (E3); an addon's own SetScale fires neither event (E3); scales read
-- back in single precision (E1). The stubs play the first through
-- stub.engine_resets_scale and stub.engine_set_scale (tests/wow/game.lua).
--
-- The world is the core shell (the shell's Config has no UpdateConfig: a test
-- counts the pass through its own) unless a case says it is on the real AceDB.

local CLIENTS = { 'forever', 'retail' }

local st

-- float32, which the game reads scales back in (E1): a 24 bit significand.
local function single(x)
	if x == 0 then return 0 end
	local m, e = math.frexp(x)
	return math.ldexp(math.floor(m * 2 ^ 24 + 0.5) / 2 ^ 24, e)
end

local function read_back_in_single()
	local get, effective = UIParent.GetScale, UIParent.GetEffectiveScale
	UIParent.GetScale = function(self) return single(get(self)) end
	UIParent.GetEffectiveScale = function(self) return single(effective(self)) end
end

-- A fresh world on a client and a screen, the game's scale on it the default's
-- (0.64), as at a login: nothing of SaftUI's has set it yet.
local function world(client, width, height)
	use_client(client or 'forever')
	st = SaftUI
	stub.screen_width, stub.screen_height = width or 2560, height or 1440
	UIParent:SetScale(0.64)
	return st
end

-- Counts the passes (the profile update) and the change callbacks.
local function watch()
	local log = { passes = 0, calls = {} }
	st.Config.UpdateConfig = function() log.passes = log.passes + 1 end
	st.UIScale:OnChanged(function(resolved) log.calls[#log.calls + 1] = resolved end)
	return log
end

-- What SaftUI (and the engine) set UIParent's scale to, in order.
local function count_sets()
	local sets = {}
	local set = UIParent.SetScale
	UIParent.SetScale = function(self, value)
		sets[#sets + 1] = value
		return set(self, value)
	end
	return sets
end

-- The game's next frames, until nothing is due.
local function frames()
	for _ = 1, 20 do
		if stub.run_timers() == 0 then return end
	end
	error('the timers never ran out: a loop')
end

local function near(a, b, tolerance) return a ~= nil and b ~= nil and math.abs(a - b) < (tolerance or 1e-9) end

local function keys(t)
	local list = {}
	for key in pairs(t) do list[#list + 1] = key end
	table.sort(list, function(a, b) return tostring(a) < tostring(b) end)
	return table.concat(list, ',')
end

-- Chat lines SaftUI printed while fn ran.
local function chat(fn)
	local lines, print_ = {}, print
	print = function(...) lines[#lines + 1] = table.concat({ ... }, ' ') end
	local ok, err = pcall(fn)
	print = print_
	if not ok then error(err, 0) end
	return lines
end

------------------------------------------------------------------ login

test('SaftUI:OnEnable makes the AceDB, then starts the scale, before any module', function()
	local source = read_saftui_source('SaftUI-Core/init.lua')
	local enable = source:find('function SaftUI:OnEnable', 1, true)
	local made = source:find("InitializeAceConfig", enable, true)
	local started = source:find('UIScale.Start', enable, true)
	check(enable and made and started and made < started, 'init.lua: InitializeAceConfig, then UIScale.Start, in OnEnable')
	check(source:find('xpcall(st.UIScale.Start, geterrorhandler(), st.UIScale)', 1, true), 'the start runs in xpcall, so an error in it stops no module')
	check(not source:find('SetScale', 1, true), 'init.lua sets no scale')

	-- The same order, run on the real AceDB.
	reset_world()
	stub.screen_width, stub.screen_height = 2560, 1440
	load_test_file('core/config_helpers.lua')
	st = SaftUI
	st.config.global.uiScale = { mode = 'auto', size = 1.25 }
	local seen
	local module = st:NewModule('LoginProbe')
	function module:OnEnable() seen = { pixel = st.pixel, scale = UIParent:GetScale() } end
	xpcall(st.UIScale.Start, geterrorhandler(), st.UIScale)
	module:Enable()
	check(seen and near(seen.scale, 768 / 1440 * 1.25, 1e-12), "a module's enable sees UIParent at 768 / 1440 * 1.25")
	check(seen and near(seen.pixel, 0.8, 1e-9), 'and the pixel 0.8')
	check(near(st.line, 0.8, 1e-9) and st.lineWeight == 1, 'and the line')
end)

test("the owner's screen: UIParent rawequal 768 / 1440, the tokens exactly 1, no pass, no callback", function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local log, sets = watch(), count_sets()
		start_uiscale()
		eq(#sets, 1, client .. ': one SetScale, at login')
		local today = st.UIScale.Resolve({ mode = 'pixel' }, st.UIScale.ReadScreen()).uiScale
		check(rawequal(sets[1], today), client .. ': the same number the old call set')
		check(rawequal(sets[1], 768 / 1440), client .. ': 768 / 1440')
		check(rawequal(UIParent:GetScale(), 768 / 1440), client .. ': and UIParent has it')
		check(rawequal(st.pixel, 1) and rawequal(st.lineWeight, 1) and rawequal(st.line, 1), client .. ': the tokens are exactly 1')
		eq(log.passes, 0, client .. ': Start runs no pass')
		eq(#log.calls, 0, client .. ': and no callback')

		-- The events at login: the check finds everything as it is.
		stub.fire_event('DISPLAY_SIZE_CHANGED')
		stub.fire_event('UI_SCALE_CHANGED')
		frames()
		eq(#sets, 1, client .. ': nothing set again')
		eq(log.passes, 0, client .. ': no pass')
		eq(#log.calls, 0, client .. ': no callback')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("the owner's screen with the game reading scales back in single precision: still nothing set, no pass", function()
	world('forever', 2560, 1440)
	local log, sets = watch(), count_sets()
	read_back_in_single()
	start_uiscale()
	eq(#sets, 1, 'one SetScale')
	check(UIParent:GetScale() ~= 768 / 1440 and near(UIParent:GetScale(), 768 / 1440, 1e-7), 'read back a hair off')
	check(rawequal(st.pixel, 1) and rawequal(st.lineWeight, 1), 'the tokens are still exactly 1 (the pixel snaps)')
	stub.fire_event('UI_SCALE_CHANGED')
	frames()
	eq(#sets, 1, 'the check compares with a tolerance: nothing set')
	eq(log.passes, 0, 'no pass')
	eq(#log.calls, 0, 'no callback')
end)

test('login in combat waits for the end of it (Review Focus 2)', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 1920, 1080)
		local log = watch()
		stub.in_combat = true
		start_uiscale()
		eq(UIParent:GetScale(), 0.64, client .. ": Start leaves the game's scale in combat")
		eq(#stub.blocked, 0, client .. ': nothing tried that the game blocks')
		eq(log.passes, 0, client .. ': no pass')
		eq(#log.calls, 0, client .. ': no callback')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		check(near(UIParent:GetScale(), 768 / 1440, 1e-12), client .. ': 768 / 1440 after combat')
		eq(log.passes, 1, client .. ': one pass')
		eq(#log.calls, 1, client .. ': the callbacks once')
		check(near(st.pixel, 4 / 3, 1e-9), client .. ': the tokens follow')
		eq(#stub.blocked, 0, client .. ': nothing blocked')
		frames()
		eq(log.passes, 1, client .. ': and no more')
	end
end)

test('Start without a screen sets nothing and raises nothing; the events still run a check later', function()
	world('forever', 2560, 1440)
	local log, sets = watch(), count_sets()
	stub.screen_width, stub.screen_height = 0, 0
	start_uiscale()
	eq(#sets, 0, 'nothing set')
	stub.screen_width, stub.screen_height = 1920, 1080
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	frames()
	check(near(UIParent:GetScale(), 768 / 1440, 1e-12), 'the first check with a screen sets it')
	eq(log.passes, 1, 'and runs the pass')
	eq(#take_errors(), 0, 'no error')
end)

test('Start registers the three screen events; a client without the notch event loses only that one', function()
	world('forever', 1920, 1080)
	eq(table.concat(st.UIScale.EVENTS, ','), 'UI_SCALE_CHANGED,DISPLAY_SIZE_CHANGED,NOTCHED_DISPLAY_MODE_CHANGED', 'EVENTS')
	eq(st.UIScale.RECHECK, nil, 'RECHECK: no second timed check (E3)')
	local make = CreateFrame
	CreateFrame = function(...)
		local frame = make(...)
		local register = frame.RegisterEvent
		frame.RegisterEvent = function(self, event, ...)
			if event == 'NOTCHED_DISPLAY_MODE_CHANGED' then error('unknown event ' .. event, 2) end
			return register(self, event, ...)
		end
		return frame
	end
	local ok, err = pcall(start_uiscale)
	CreateFrame = make
	check(ok, 'Start raises nothing: ' .. tostring(err))
	local before = #stub.timers
	stub.fire_event('UI_SCALE_CHANGED')
	eq(#stub.timers, before + 1, 'the other two still ask for a check')
	-- And on a client that has it, all three do.
	for _, event in ipairs(st.UIScale.EVENTS) do
		world('retail', 1920, 1080)
		start_uiscale()
		before = #stub.timers
		stub.fire_event(event)
		eq(#stub.timers, before + 1, event .. ' asks for a check')
	end
end)

------------------------------------------------------------------ the check

test("the check: once a frame however many events; nothing set when equal; nothing set in The game's UI scale", function()
	for _, client in ipairs(CLIENTS) do
		world(client, 1920, 1080)
		local log, sets = watch(), count_sets()
		local margins = 0
		local margin = st.UpdateScreenMargin
		st.UpdateScreenMargin = function(...) margins = margins + 1 return margin(...) end
		start_uiscale()
		eq(#sets, 1, client .. ': login set it')
		local before = #stub.timers
		for _ = 1, 4 do
			stub.fire_event('UI_SCALE_CHANGED')
			stub.fire_event('DISPLAY_SIZE_CHANGED')
			stub.fire_event('NOTCHED_DISPLAY_MODE_CHANGED')
		end
		eq(#stub.timers, before + 1, client .. ': twelve events ask for one check')
		eq(margins, 0, client .. ': and it has not run yet')
		frames()
		eq(margins, 1, client .. ': one check: the margin applied once')
		eq(#sets, 1, client .. ': nothing set when equal')
		eq(log.passes, 0, client .. ': no pass for nothing changed')

		-- The game's UI scale: the check only reads it.
		world(client, 2560, 1440)
		log, sets = watch(), count_sets()
		UIParent:SetScale(0.8)
		start_uiscale({ mode = 'game', size = 1 })
		eq(#sets, 1, client .. ": Start sets nothing in The game's UI scale (the one set is this test's)")
		stub.fire_event('UI_SCALE_CHANGED')
		frames()
		eq(#sets, 1, client .. ': and nor does the check')
		eq(UIParent:GetScale(), 0.8, client .. ': UIParent keeps the game\'s')
		check(near(st.pixel, 1 / (0.8 * 1440 / 768), 1e-9), client .. ': the pixel is measured from it')
		eq(st.lineWeight, 2, client .. ': 0.8 on 1440 is k 1.5: two pixel lines')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('a display change in Automatic: no SetScale, one pass, the callbacks with the new line weight', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local log, sets = watch(), count_sets()
		start_uiscale()
		eq(st.lineWeight, 1, client .. ': one pixel lines at 1440')
		stub.change_display(3840, 2160)
		frames()
		eq(#sets, 1, client .. ': SetScale not called again (a resolution change leaves the scale as it is)')
		eq(st.lineWeight, 2, client .. ': two pixel lines at 2160')
		check(near(st.pixel, 1 / 1.5, 1e-9), client .. ': the pixel')
		eq(log.passes, 1, client .. ': one pass')
		eq(#log.calls, 1, client .. ': the callbacks once')
		eq(log.calls[1].lineWeight, 2, client .. ': with the resolved table, its line weight 2')
		eq(log.calls[1].height, 2160, client .. ': and its screen')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("the engine resets the scale, and SaftUI's own SetScale fires the event: no loop (Review Focus 3)", function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		stub.engine_resets_scale, stub.scale_fires_event = true, true
		stub.default_scale = 0.64
		local log, sets = watch(), count_sets()
		local margins, margin = 0, st.UpdateScreenMargin
		st.UpdateScreenMargin = function(...) margins = margins + 1 return margin(...) end
		start_uiscale()
		eq(#sets, 1, client .. ': login')
		stub.change_display(1920, 1080) -- the engine sets 0.64 over SaftUI's, both events, in pairs
		check(near(UIParent:GetScale(), 0.64, 1e-9), client .. ': the engine has it')
		local mark = #sets
		for _ = 1, 10 do stub.fire_event('UI_SCALE_CHANGED') end -- ten more, in one frame
		eq(#stub.timers, 1, client .. ': one check asked for')
		frames()
		eq(#sets - mark, 1, client .. ': one SetScale back')
		eq(margins, 0, client .. ': one check ran, which did the pass: its own SetScale event asked for no second')
		check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ': and SaftUI has it')
		eq(log.passes, 1, client .. ': one pass (the pixel went from 1 to 1.33)')
		eq(#log.calls, 1, client .. ': one callback')
		frames()
		eq(#sets - mark, 1, client .. ': another frame: nothing')
		eq(log.passes, 1, client .. ': no second pass')
		eq(#stub.timers, 0, client .. ': nothing left asking')
		eq(#take_errors(), 0, client .. ': no error')

		-- The slider while nothing else changed: put back, and redrawn once (I1).
		stub.engine_set_scale(0.9)
		mark = #sets
		frames()
		eq(#sets - mark, 1, client .. ': the slider moved: set back on the next frame')
		check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ': at SaftUI\'s')
		eq(log.passes, 2, client .. ': a set-back is a change: the pass runs once after it (I1)')
	end
end)

test("Blizzard's slider in Automatic and Pixel for pixel: set back on the next frame; in The game's UI scale: followed, its lines measured", function()
	for _, client in ipairs(CLIENTS) do
		for _, mode in ipairs({ 'auto', 'pixel' }) do
			world(client, 2560, 1440)
			local log, sets = watch(), count_sets()
			start_uiscale({ mode = mode, size = 1 })
			stub.cvars.useUiScale, stub.cvars.uiScale = '1', '0.8'
			stub.engine_set_scale(0.8)
			eq(UIParent:GetScale(), 0.8, client .. ' ' .. mode .. ': the game set the slider\'s scale')
			local mark = #sets
			frames()
			eq(#sets - mark, 1, client .. ' ' .. mode .. ': one SetScale on the next frame')
			check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ' ' .. mode .. ': back at SaftUI\'s')
			eq(log.passes, 1, client .. ' ' .. mode .. ': a set-back is a change: one pass after it (I1)')
			check(rawequal(st.pixel, 1), client .. ' ' .. mode .. ': the pixel is 1')
		end

		world(client, 2560, 1440)
		local log, sets = watch(), count_sets()
		UIParent:SetScale(0.64)
		start_uiscale({ mode = 'game', size = 1 })
		stub.cvars.useUiScale, stub.cvars.uiScale = '1', '0.8'
		stub.engine_set_scale(0.8)
		local mark = #sets
		frames()
		eq(#sets, mark, client .. ": The game's UI scale: nothing set back")
		eq(UIParent:GetScale(), 0.8, client .. ': UIParent stays at the slider\'s')
		eq(st.lineWeight, st.UIScale.LineWeight(0.8 * 1440 / 768), client .. ': its lines measured from it')
		check(near(st.pixel, 1 / (0.8 * 1440 / 768), 1e-9), client .. ': and its pixel')
		eq(log.passes, 1, client .. ': one pass')
		eq(#log.calls, 1, client .. ': the callbacks once')
		eq(log.calls[1].mode, 'game', client .. ': in The game\'s UI scale')
		check(near(log.calls[1].k, 1.5, 1e-6), client .. ': k 1.5')
	end
end)

test('a change in combat waits whole for the end of it: no SetScale, no tokens, no pass, no callback', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local log = watch()
		start_uiscale()
		stub.in_combat = true
		stub.change_display(1920, 1080)
		stub.engine_set_scale(0.9) -- the engine, over SaftUI's, in combat
		frames()
		eq(UIParent:GetScale(), 0.9, client .. ': SaftUI sets nothing in combat')
		eq(#stub.blocked, 0, client .. ': and tries nothing the game blocks')
		eq(log.passes, 0, client .. ': no pass in combat')
		eq(#log.calls, 0, client .. ': no callback')
		check(rawequal(st.pixel, 1), client .. ': the tokens are as they were')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ': set after combat')
		eq(log.passes, 1, client .. ': one pass')
		eq(#log.calls, 1, client .. ': one callback set')
		check(near(st.pixel, 4 / 3, 1e-9), client .. ': the pixel for 1080')
		eq(#stub.blocked, 0, client .. ': nothing blocked')
	end
end)

------------------------------------------------------------------ choices

local AUTO_125 = { mode = 'auto', size = 1.25 }

test('Preview, Apply, Revert and Apply(nil): what is saved, and when', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local log = watch()
		start_uiscale()
		local U = st.UIScale
		eq(U:Saved(), nil, client .. ': nothing saved yet')
		eq(U:IsPreviewing(), false, client .. ': not previewing')

		local ok, why = U:Preview(AUTO_125)
		check(ok == true and why == nil, client .. ': Preview(1.25) is ok')
		eq(U:Saved(), nil, client .. ': a preview saves nothing')
		eq(st.config.global.uiScale, nil, client .. ': not in the global table')
		eq(U:IsPreviewing(), true, client .. ': previewing')
		check(near(UIParent:GetScale(), 768 / 1440 * 1.25, 1e-12), client .. ': UIParent at 1.25')
		check(near(st.pixel, 0.8, 1e-9), client .. ': the pixel 0.8')
		eq(log.passes, 1, client .. ': a pass ran at once')
		eq(U:Current().size, 1.25, client .. ': Current is the preview')
		eq(U:Applied().size, 1.25, client .. ': Applied is what the check applied')

		ok = U:Revert()
		check(ok == true, client .. ': Revert is ok')
		eq(U:IsPreviewing(), false, client .. ': not previewing')
		check(rawequal(UIParent:GetScale(), 768 / 1440), client .. ': back, exactly')
		eq(log.passes, 2, client .. ': and a pass')

		ok, why = U:Apply(AUTO_125)
		check(ok == true and why == nil, client .. ': Apply is ok')
		eq(keys(st.config.global.uiScale), 'mode,size', client .. ': what is saved is exactly { mode, size }')
		eq(st.config.global.uiScale.mode, 'auto', client .. ': its mode')
		eq(st.config.global.uiScale.size, 1.25, client .. ': its size')
		eq(U:Saved().size, 1.25, client .. ': Saved gives it')
		check(near(UIParent:GetScale(), 768 / 1440 * 1.25, 1e-12), client .. ': and UIParent has it')

		U:Apply(nil)
		eq(st.config.global.uiScale, nil, client .. ': Apply(nil) removes the save')
		check(rawequal(UIParent:GetScale(), 768 / 1440), client .. ': and puts back exactly what was there')
		U:Apply(AUTO_125)
		U:Apply(U.DEFAULT)
		eq(st.config.global.uiScale, nil, client .. ': Apply(DEFAULT) removes it too')
		U:Apply({ mode = 'pixel', size = 1 })
		eq(st.config.global.uiScale.mode, 'pixel', client .. ': another mode is saved')
		U:Apply({ mode = 'auto', size = 1 })
		eq(st.config.global.uiScale, nil, client .. ': Automatic at 100% is the default: nothing saved')

		-- Apply ends a preview.
		U:Preview(AUTO_125)
		U:Apply({ mode = 'auto', size = 1.5 })
		eq(U:IsPreviewing(), false, client .. ': Apply ends the preview')
		eq(U:Current().size, 1.5, client .. ': at what it saved')
		U:Apply(nil)

		-- Refused: the size and the mode are never fixed up.
		ok, why = U:Preview({ mode = 'auto', size = 2 })
		check(ok == false and why == 'size', client .. ': a size of 200% is refused: ' .. tostring(why))
		ok, why = U:Preview({ mode = 'auto', size = 0.5 })
		check(ok == false and why == 'size', client .. ': and of 50%')
		ok, why = U:Preview({ mode = 'huge' })
		check(ok == false and why == 'mode', client .. ': an unknown mode: ' .. tostring(why))
		ok, why = U:Preview({ mode = 'auto', size = '1.2' })
		check(ok == false and why == 'size', client .. ': a size that is not a number')
		eq(U:IsPreviewing(), false, client .. ': none of them began a preview')
		ok, why = U:Apply({ mode = 'auto', size = 2 })
		check(ok == false and why == 'size', client .. ': Apply refuses them too')
		eq(st.config.global.uiScale, nil, client .. ': and saves nothing')
		stub.screen_width = 0
		ok, why = U:Preview(AUTO_125)
		check(ok == false and why == 'screen', client .. ': no screen: ' .. tostring(why))
		stub.screen_width = 2560
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('Preview, Apply and Revert in combat: refused, saved and waiting, waiting', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local log = watch()
		start_uiscale()
		local U = st.UIScale
		stub.in_combat = true
		local ok, why = U:Preview(AUTO_125)
		check(ok == false and why == 'combat', client .. ': Preview is refused in combat')
		eq(U:IsPreviewing(), false, client .. ': not previewing')
		ok, why = U:Apply(AUTO_125)
		check(ok == true and why == 'combat', client .. ': Apply saves and says the scale waits')
		eq(st.config.global.uiScale.size, 1.25, client .. ': saved')
		check(rawequal(UIParent:GetScale(), 768 / 1440), client .. ': UIParent as it was')
		eq(log.passes, 0, client .. ': no pass')
		eq(#stub.blocked, 0, client .. ': nothing blocked')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		check(near(UIParent:GetScale(), 768 / 1440 * 1.25, 1e-12), client .. ': the scale after combat')
		eq(log.passes, 1, client .. ': one pass')

		-- Reset in combat saves at once too.
		stub.in_combat = true
		ok, why = U:Apply(nil)
		check(ok == true and why == 'combat', client .. ': Apply(nil) in combat')
		eq(st.config.global.uiScale, nil, client .. ': saved at once')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		check(rawequal(UIParent:GetScale(), 768 / 1440), client .. ': and set after combat')
		eq(#stub.blocked, 0, client .. ': nothing blocked')
	end
end)

test('a preview is never saved: the next login comes back at the saved choice (Review Focus 4)', function()
	world('forever', 2560, 1440)
	start_uiscale({ mode = 'auto', size = 1.25 })
	local U = st.UIScale
	local saved = st.config.global.uiScale
	U:Preview({ mode = 'auto', size = 1.5 })
	U:Preview({ mode = 'pixel', size = 1 })
	eq(st.config.global.uiScale, saved, 'the saved table is untouched')
	eq(saved.size, 1.25, 'and still 1.25')
	check(near(UIParent:GetScale(), 768 / 1440, 1e-12), 'the preview is on screen')
	U:Revert()
	check(near(UIParent:GetScale(), 768 / 1440 * 1.25, 1e-12), 'going back returns to the saved choice, not the first preview')

	-- A second change while previewing, then a /reload: the new world has the saved choice.
	U:Preview({ mode = 'auto', size = 1.5 })
	local left = { mode = saved.mode, size = saved.size }
	world('forever', 2560, 1440)
	st.config.global.uiScale = left
	st.UIScale:Start()
	check(near(UIParent:GetScale(), 768 / 1440 * 1.25, 1e-12), 'the next login is at the saved choice')
	eq(st.UIScale:IsPreviewing(), false, 'not previewing')
end)

local T = load_test_file('lib/theme_helpers.lua')

-- A panel drawn in Thick, and what its edge is now: in UIParent's units.
local function panel()
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(36, 36)
	f:SetPoint('CENTER')
	st:SetTemplate(f, 'theme', 'theme', 'panel')
	return f
end

test('I1: the engine moves the scale in combat; frames drawn in the fight and plates added then are redrawn and re-pinned after it', function()
	for _, client in ipairs(CLIENTS) do
		st = T.client(client)
		stub.screen_width, stub.screen_height = 2560, 1440
		st.config.profile.theme.name = 'thick'
		UIParent:SetScale(0.64)
		local log = watch()
		st.Config.UpdateConfig = function() log.passes = log.passes + 1; st:RedrawThemed() end
		local plate = CreateFrame('Frame', nil, UIParent)
		st.UIScale:OnChanged(function() plate:SetIgnoreParentScale(true); plate:SetScale(UIParent:GetEffectiveScale()) end)
		start_uiscale()
		stub.in_combat = true
		stub.engine_set_scale(0.9)
		frames()
		local f = panel() -- drawn in the fight, at the engine's scale
		plate:SetIgnoreParentScale(true); plate:SetScale(UIParent:GetEffectiveScale()) -- a plate added in the fight
		check(f.backdropInfo.edgeSize < 0.7, client .. ': at the engine\'s scale its edge is under a pixel: ' .. f.backdropInfo.edgeSize)
		eq(log.passes, 0, client .. ': no pass in combat')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		eq(log.passes, 1, client .. ': one pass after combat')
		check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ': SaftUI\'s scale is back')
		check(near(f.backdropInfo.edgeSize, st:GetLineSize(f), 1e-9) and near(f.backdropInfo.edgeSize, 1, 1e-6), client .. ': the edge is one whole pixel again: ' .. f.backdropInfo.edgeSize)
		eq(plate:GetEffectiveScale(), UIParent:GetEffectiveScale(), client .. ': the plate is pinned to it')
	end
end)

test('I1: the flicker frame out of combat: a frame drawn between the engine\'s set and the check is redrawn; the pass costs what a profile update costs', function()
	st = T.client('forever')
	stub.screen_width, stub.screen_height = 2560, 1440
	st.config.profile.theme.name = 'thick'
	UIParent:SetScale(0.64)
	local log = watch()
	st.Config.UpdateConfig = function() log.passes = log.passes + 1; st:RedrawThemed() end
	start_uiscale()
	stub.engine_set_scale(0.9)
	local f = panel() -- drawn in the one frame between
	check(f.backdropInfo.edgeSize < 0.7, 'an edge under a pixel at 0.9: ' .. f.backdropInfo.edgeSize)
	frames()
	eq(log.passes, 1, 'one pass after the set-back')
	check(near(f.backdropInfo.edgeSize, 1, 1e-6), 'whole again')
	-- With nothing drawn in between it is the same pass: a flicker is a profile
	-- update's cost (about 900 widget calls on 26 drawn frames), once per slider move or display change.
	stub.engine_set_scale(0.9)
	frames()
	eq(log.passes, 2, 'a second flicker, a second pass')
end)

test('m1: an engine that sets its scale again after every set-back: the check gives up after five in a second, says so once, and recovers', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		stub.timers_wait_a_frame = true
		local log, sets = watch(), count_sets()
		start_uiscale()
		local backs = 0
		local lines = chat(function()
			for _ = 1, 30 do
				stub.engine_set_scale(0.9) -- the engine, over SaftUI's, every frame
				local mark = #sets
				stub.run_timers()
				for i = mark + 1, #sets do
					if near(sets[i], 768 / 1440, 1e-9) then backs = backs + 1 end
				end
			end
		end)
		eq(backs, 5, client .. ': five set-backs, then it stops')
		eq(#lines, 1, client .. ': one chat line')
		check(lines[1] and lines[1]:find('Use UI Scale', 1, true) and lines[1]:find("The game's UI scale", 1, true), client .. ': it says why and what to do: ' .. tostring(lines[1]))
		eq(UIParent:GetScale(), 0.9, client .. ": the engine's scale is left")
		check(near(st.pixel, 1 / (0.9 * 1440 / 768), 1e-9), client .. ': the tokens follow what is on screen')

		-- A change of screen is a new start.
		stub.change_display(1920, 1080)
		stub.run_timers()
		check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ': a new screen: set back again')

		-- The next real change recovers.
		stub.timers_wait_a_frame = false
		stub.engine_set_scale(0.9)
		for _ = 1, 8 do stub.engine_set_scale(0.9); stub.run_timers() end
		lines = chat(function() st.UIScale:Apply(AUTO_125) end)
		check(near(UIParent:GetScale(), 768 / 1440 * 1.25, 1e-12), client .. ': Apply sets it again')
		eq(#lines, 0, client .. ': and says nothing more')
		stub.engine_set_scale(0.9)
		local mark = #sets
		frames()
		check(#sets > mark and near(UIParent:GetScale(), 768 / 1440 * 1.25, 1e-12), client .. ': set-backs work again')

		-- A move every two seconds never trips it.
		world(client, 2560, 1440)
		stub.timers_wait_a_frame = true
		log, sets = watch(), count_sets()
		start_uiscale()
		lines = chat(function()
			for _ = 1, 12 do
				stub.time = stub.time + 2
				stub.engine_set_scale(0.9)
				stub.run_timers()
			end
		end)
		eq(#lines, 0, client .. ': slow moves: no line')
		check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ': each put back')
		stub.timers_wait_a_frame = false
	end
end)

test('I1 (final review): a window dragged through six sizes in a second trips nothing: each screen counts its own set-backs; five on one screen still give up', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		stub.engine_resets_scale, stub.scale_fires_event = true, true
		stub.default_scale = 0.64
		start_uiscale()
		local lines = chat(function()
			for i = 1, 8 do
				stub.change_display(1800 + i * 40, 1000 + i * 20) -- a new size every frame
				frames()
				stub.time = stub.time + 0.1
			end
		end)
		eq(#lines, 0, client .. ': no give-up line')
		check(not st.UIScale:GaveUp(), client .. ': it did not give up')
		check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ": SaftUI's scale is in force at the end")
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('n1: in The game\'s UI scale a burst split across two frames is one pass, at the final scale', function()
	world('forever', 2560, 1440)
	stub.timers_wait_a_frame = true
	local log = watch()
	UIParent:SetScale(0.64)
	start_uiscale({ mode = 'game', size = 1 })
	UIParent:SetScale(1) -- the first pair, at 1
	stub.fire_event('UI_SCALE_CHANGED')
	stub.run_timers()
	UIParent:SetScale(0.8) -- the second, a frame later
	stub.fire_event('UI_SCALE_CHANGED')
	for _ = 1, 4 do stub.run_timers() end
	eq(log.passes, 1, 'one pass')
	eq(log.calls[1].mode, 'game', 'in The game\'s UI scale')
	check(near(log.calls[1].k, 0.8 * 1440 / 768, 1e-6), 'at the final scale')
	stub.timers_wait_a_frame = false
end)

test('m2 (U4): a 5% size step moves UIParent by 0.027, far over the tolerance (1e-5) and far over single precision\'s noise (3e-8)', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local sets = count_sets()
		read_back_in_single()
		start_uiscale()
		local mark = #sets
		check(st.UIScale:Preview({ mode = 'auto', size = 1.05 }), client .. ': Preview 105%')
		eq(#sets - mark, 1, client .. ': the step is set')
		check(near(UIParent:GetScale(), 768 / 1440 * 1.05, 1e-6), client .. ': UIParent follows it')
		check(math.abs(768 / 1440 * 1.05 - 768 / 1440) > 100 * st.UIScale.TOLERANCE, client .. ': the tolerance is far below a step')
		check(st.UIScale.TOLERANCE > 100 * math.abs(single(768 / 1440) - 768 / 1440), client .. ': and far above the read-back noise')
	end
end)

test('m2 (U5): the window at 2560 x 1377 keeps the pixel at 1 but changes UIParent\'s units: the scale is set and the pass runs, by the spec\'s step 4', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local log, sets = watch(), count_sets()
		start_uiscale()
		local mark = #sets
		stub.change_display(2560, 1377)
		frames()
		eq(#sets - mark, 1, client .. ': UIParent set to 768 / 1377')
		check(near(UIParent:GetScale(), 768 / 1377, 1e-9), client .. ': at that')
		check(rawequal(st.pixel, 1), client .. ': the pixel is still 1')
		eq(log.passes, 1, client .. ': the scale differs from the last check\'s: the pass runs (the margin and the layout follow the screen\'s height)')
	end
end)

test('Revert in combat: the preview ends at once, the scale waits for the end of the fight, and OnChanged says when it applied', function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local log = watch()
		start_uiscale()
		local U = st.UIScale
		U:Preview(AUTO_125)
		eq(log.passes, 1, client .. ': the preview passed')
		stub.in_combat = true
		eq(U:Revert(), true, client .. ': Revert in combat is ok')
		eq(U:IsPreviewing(), false, client .. ': the preview is over')
		check(near(UIParent:GetScale(), 768 / 1440 * 1.25, 1e-12), client .. ': UIParent waits')
		eq(#stub.blocked, 0, client .. ': nothing blocked')
		eq(log.passes, 1, client .. ': no pass in combat')
		stub.in_combat = false
		stub.fire_event('PLAYER_REGEN_ENABLED')
		check(rawequal(UIParent:GetScale(), 768 / 1440), client .. ': back after combat')
		eq(log.passes, 2, client .. ': one pass')
		eq(#log.calls, 2, client .. ': and OnChanged: the signal that it applied')
	end
end)

test('m4: Previous is the choice in effect before the first preview, a copy, nil when not previewing', function()
	world('forever', 2560, 1440)
	start_uiscale({ mode = 'auto', size = 1.25 })
	local U = st.UIScale
	eq(U:Previous(), nil, 'not previewing: nil')
	U:Preview({ mode = 'pixel', size = 1 })
	U:Preview({ mode = 'auto', size = 1.5 })
	local previous = U:Previous()
	check(previous and previous.mode == 'auto' and previous.size == 1.25, 'the first preview\'s: the saved choice')
	previous.size = 9
	eq(U:Previous().size, 1.25, 'a copy')
	U:Revert()
	eq(U:Previous(), nil, 'nil after Revert')
	U:Preview({ mode = 'pixel', size = 1 })
	U:Apply({ mode = 'pixel', size = 1 })
	eq(U:Previous(), nil, 'and after Apply')
end)

test('n3: Pixel for pixel and The game\'s UI scale take any valid size; only Automatic holds it to the screen\'s top', function()
	world('forever', 1366, 768) -- the top is 130% on this screen
	local U = st.UIScale
	local over = U:Default().sizeMax + 0.05
	local ok, why = U:Preview({ mode = 'auto', size = over })
	check(ok == false and why == 'size', 'Automatic refuses ' .. over)
	ok, why = U:Preview({ mode = 'pixel', size = over })
	check(ok == true and why == nil, 'Pixel for pixel does not look at it')
	U:Revert()
	ok, why = U:Preview({ mode = 'game', size = over })
	check(ok == true and why == nil, 'nor The game\'s UI scale')
	U:Revert()
	ok, why = U:Preview({ mode = 'pixel', size = 3 })
	check(ok == false and why == 'size', 'a size over 150% is still refused')
end)

test('Describe, by mode', function()
	world('forever', 1920, 1080)
	local U = st.UIScale
	local function describe(choice, width, height, gameScale)
		return U:Describe(U.Resolve(choice, { width = width, height = height }, gameScale))
	end
	eq(describe({ mode = 'auto', size = 1 }, 1920, 1080), 'This screen is 1920 x 1080: SaftUI draws at 75% of its 1440p size, with 1 pixel lines.', 'Automatic')
	eq(describe({ mode = 'pixel' }, 1920, 1080), 'This screen is 1920 x 1080: SaftUI draws pixel for pixel, at 100% of its 1440p size, with 1 pixel lines.', 'Pixel for pixel')
	eq(describe({ mode = 'game' }, 2560, 1440, 0.64), "This screen is 2560 x 1440: the game's UI scale draws SaftUI at 120% of its 1440p size, with 1 pixel lines.", "The game's UI scale")
	eq(describe({ mode = 'auto', size = 1 }, 3456, 2234), 'This screen is 3456 x 2234: SaftUI draws at 155% of its 1440p size, with 2 pixel lines.', 'two pixel lines')
	eq(U:Describe(nil), '', 'nothing resolved: nothing said')
end)

test("The game's UI scale: switching sets UIParent once to GameScale(); later logins set nothing", function()
	for _, client in ipairs(CLIENTS) do
		world(client, 2560, 1440)
		local log, sets = watch(), count_sets()
		start_uiscale()
		local U = st.UIScale
		stub.cvars.useUiScale, stub.cvars.uiScale = '1', '0.9'
		eq(U.GameScale(), 0.9, client .. ": GameScale is the slider's while Use UI Scale is on")
		local mark = #sets
		U:Apply({ mode = 'game', size = 1 })
		eq(#sets - mark, 1, client .. ': the switch sets it once')
		eq(UIParent:GetScale(), 0.9, client .. ": to the slider's")
		eq(log.passes, 1, client .. ': one pass')
		mark = #sets
		U:Start()
		stub.fire_event('UI_SCALE_CHANGED')
		frames()
		eq(#sets, mark, client .. ': a later login (Start again) and its checks set nothing')

		stub.cvars.useUiScale = '0'
		stub.default_scale = 0.64
		eq(U.GameScale(), 0.64, client .. ': Use UI Scale off: the default for the screen')
		U:Apply(nil)
		mark = #sets
		U:Apply({ mode = 'game', size = 1 })
		eq(#sets - mark, 1, client .. ': switching again sets once')
		eq(UIParent:GetScale(), 0.64, client .. ": to the game's default")
	end

	-- A client without GetDefaultScale, Use UI Scale off: nothing set, one chat line.
	world('forever', 2560, 1440)
	local sets = count_sets()
	start_uiscale()
	GetDefaultScale = nil
	eq(st.UIScale.GameScale(), nil, 'GameScale is nil')
	local mark = #sets
	local lines = chat(function() st.UIScale:Apply({ mode = 'game', size = 1 }) end)
	eq(#sets, mark, 'nothing set')
	eq(#lines, 1, 'one chat line')
	check(lines[1] and lines[1]:find('/reload', 1, true), 'it says the size shows after /reload: ' .. tostring(lines[1]))
	lines = chat(function()
		stub.fire_event('UI_SCALE_CHANGED')
		frames()
	end)
	eq(#lines, 0, 'and no more')
end)

test('a malformed save is read, never rewritten (Review Focus 5)', function()
	local malformed = {
		true,
		{ mode = 'huge' },
		{ size = '90' },
		{ size = 5 },
		{ mode = 'game', size = 0 },
	}
	for index, value in ipairs(malformed) do
		world('forever', 1920, 1080)
		local log = watch()
		local before = type(value) == 'table' and keys(value) or nil
		local size = type(value) == 'table' and value.size or nil
		st.config.global.uiScale = value
		local expected = st.UIScale.Normalize(value)
		local current = st.UIScale:Current()
		eq(current.mode, expected.mode, index .. ': Current has the mode Normalize gives')
		eq(current.size, expected.size, index .. ': and the size')
		check(pcall(st.UIScale.Start, st.UIScale), index .. ': Start raises nothing')
		stub.fire_event('UI_SCALE_CHANGED')
		frames()
		check(pcall(st.UIScale.Check, st.UIScale), index .. ': Check raises nothing')
		check(rawequal(st.config.global.uiScale, value), index .. ': the same value in the table')
		if before then
			eq(keys(value), before, index .. ': with the same keys')
			eq(value.size, size, index .. ': and the same size')
		end
		eq(#take_errors(), 0, index .. ': no error')
	end
end)

test('a profile switch, copy or reset leaves the choice and the scale, and runs no scale pass of its own', function()
	reset_world()
	stub.screen_width, stub.screen_height = 2560, 1440
	load_test_file('core/config_helpers.lua')
	st = SaftUI
	local log = { calls = 0 }
	st.UIScale:OnChanged(function() log.calls = log.calls + 1 end)
	local sets = count_sets()
	start_uiscale({ mode = 'auto', size = 1.25 })
	local scale, applied = UIParent:GetScale(), st.UIScale:Applied()
	local mark = #sets
	local original = st.config:GetCurrentProfile()
	st.config:SetProfile('Another')
	st.config:CopyProfile(original)
	st.config:ResetProfile()
	st.config:SetProfile(original)
	frames()
	eq(st.config.global.uiScale.size, 1.25, 'the choice is account wide: unchanged')
	eq(UIParent:GetScale(), scale, 'UIParent unchanged')
	eq(#sets, mark, 'no SetScale')
	eq(log.calls, 0, 'no scale callback')
	check(rawequal(st.UIScale:Applied(), applied), 'what was applied is the same table')
	eq(#take_errors(), 0, 'no error')
end)

test('OnChanged: each fn runs after the pass with the resolved table, in order; one that errors is reported and the rest run', function()
	world('forever', 2560, 1440)
	local order = {}
	local pass = 0
	st.Config.UpdateConfig = function() pass = pass + 1; order[#order + 1] = 'pass' end
	local first
	st.UIScale:OnChanged(function(resolved) first = resolved; order[#order + 1] = 'one' end)
	st.UIScale:OnChanged(function() order[#order + 1] = 'two'; error('the second fails') end)
	st.UIScale:OnChanged(function() order[#order + 1] = 'three' end)
	start_uiscale()
	st.UIScale:Apply(AUTO_125)
	eq(table.concat(order, ','), 'pass,one,two,three', 'the pass first, then each, in the order registered')
	check(first and first.mode == 'auto' and first.size == 1.25 and near(first.k, 1.25), 'with the resolved table')
	local errors = take_errors()
	eq(#errors, 1, 'one error, reported through the error handler')
	check(tostring(errors[1]):find('the second fails', 1, true), 'the failing one: ' .. tostring(errors[1]))

	-- A pass that errors is reported and the callbacks still run.
	order = {}
	st.Config.UpdateConfig = function() order[#order + 1] = 'pass'; error('the pass fails') end
	st.UIScale:Apply({ mode = 'auto', size = 1.5 })
	eq(table.concat(order, ','), 'pass,one,two,three', 'a failing pass stops nothing')
	eq(#take_errors(), 2, 'and both errors are reported')
end)

test('a scale change adds no history step', function()
	reset_world()
	stub.screen_width, stub.screen_height = 2560, 1440
	load_test_file('core/config_helpers.lua')
	st = SaftUI
	start_uiscale()
	local History = st.EditModeFrames.History
	local steps, position = #History:Steps(), History:Position()
	local passes = 0
	st.UIScale:OnChanged(function() passes = passes + 1 end)
	st.UIScale:Apply(AUTO_125) -- the real profile update runs as the pass
	stub.change_display(1920, 1080)
	frames()
	st.UIScale:Apply(nil)
	check(passes >= 2, 'the passes ran: ' .. passes)
	eq(#History:Steps(), steps, 'no step')
	eq(History:Position(), position, 'and the position is where it was')
	eq(#take_errors(), 0, 'no error')
end)

test('Default is Resolve(DEFAULT) on the screen; Applied is nil before anything is applied', function()
	world('forever', 1920, 1080)
	local U = st.UIScale
	eq(U:Applied(), nil, 'nothing applied')
	local default = U:Default()
	check(default and default.mode == 'auto' and near(default.k, 0.75), 'the default on this screen: Automatic, 75%')
	stub.screen_width = 0
	eq(U:Default(), nil, 'nil with no screen')
	stub.screen_width = 1920
	start_uiscale()
	check(U:Applied() and U:Applied().mode == 'auto' and near(U:Applied().k, 0.75), 'Start records what it applied')
	local current = U:Current()
	current.size = 9
	eq(U:Current().size, 1, 'Current is a copy')
end)

------------------------------------------------------------------ the two chat lines (Rulings 16 and 17)

local FIRST_LOGIN = "SaftUI now sizes itself to your screen: here it draws at %d%% of its 1440p size, so it takes the same share of the screen as on the screen it was laid out on. To keep the size it had before, type /sui scale pixel. The choices are in /sui > Global settings > General."
local SLIDER = "SaftUI sets the UI's scale itself. To use the game's UI Scale, choose The game's UI scale in /sui > Global settings > General."

-- The lines that name a UI scale ("[SaftUI]: ..." with the prefix off).
local function said(lines)
	local out = {}
	for _, line in ipairs(lines) do out[#out + 1] = (line:gsub('^%[[^%]]*%]:%s*', '')) end
	return out
end

test("the first login where the automatic size isn't 1: one line, once per account; none with a saved choice; none, and no marker, at k 1", function()
	for _, client in ipairs(CLIENTS) do
		-- 1920 x 1080, nothing saved: the spec's line with 75%.
		world(client, 1920, 1080)
		local lines = said(chat(function() start_uiscale() end))
		eq(#lines, 1, client .. ': one line')
		eq(lines[1], FIRST_LOGIN:format(75), client .. ": the spec's words, 75%")
		eq(st.config.global.uiScaleNotice, 1, client .. ': the marker is 1')
		eq(st.config.global.uiScale, nil, client .. ': nothing saved by it')
		lines = said(chat(function() st.UIScale:Start() end))
		eq(#lines, 0, client .. ': Start again: nothing')
		-- A /reload keeps the marker (account-wide): a new world with the same global table.
		local global = st.config.global
		lines = said(chat(function() st.UIScale:Start() end))
		eq(#lines, 0, client .. ': and the next login')
		eq(st.config.global, global)

		-- 3200 x 1800: 125%.
		world(client, 3200, 1800)
		lines = said(chat(function() start_uiscale() end))
		eq(lines[1], FIRST_LOGIN:format(125), client .. ': 125% on 1800p')

		-- A saved choice: no line, no marker (even Automatic at 100% saved as nothing is a saved nothing).
		world(client, 1920, 1080)
		lines = said(chat(function() start_uiscale({ mode = 'auto', size = 0.9 }) end))
		eq(#lines, 0, client .. ': a saved size: none')
		eq(st.config.global.uiScaleNotice, nil, client .. ': and no marker')
		world(client, 1920, 1080)
		lines = said(chat(function() start_uiscale({ mode = 'pixel', size = 1 }) end))
		eq(#lines, 0, client .. ': Pixel for pixel saved: none')

		-- The owner's screen: none, no marker; the same account on another screen is still told.
		world(client, 2560, 1440)
		lines = said(chat(function() start_uiscale() end))
		eq(#lines, 0, client .. ': k 1: none')
		eq(st.config.global.uiScaleNotice, nil, client .. ': and no marker')
		stub.screen_width, stub.screen_height = 1920, 1080
		lines = said(chat(function() st.UIScale:Start() end))
		eq(#lines, 1, client .. ': on another screen it is shown')

		-- A marker from a version that showed it: none.
		world(client, 1920, 1080)
		st.config.global.uiScaleNotice = 1
		lines = said(chat(function() start_uiscale() end))
		eq(#lines, 0, client .. ': the marker says it was shown')

		-- No screen: nothing, no marker.
		world(client, 0, 0)
		lines = said(chat(function() start_uiscale() end))
		eq(#lines, 0, client .. ': no screen: none')
		eq(st.config.global.uiScaleNotice, nil)
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test("Blizzard's slider: one line a session, only when the setting changed and SaftUI set the scale back (Review Focus 3)", function()
	for _, client in ipairs(CLIENTS) do
		for _, mode in ipairs({ 'auto', 'pixel' }) do
			world(client, 2560, 1440)
			stub.cvars.useUiScale, stub.cvars.uiScale = '0', '1'
			start_uiscale({ mode = mode, size = 1 })
			local lines = said(chat(function()
				-- A display change: the engine resets the scale, the setting is as it was.
				stub.engine_set_scale(0.64)
				frames()
			end))
			eq(#lines, 0, client .. ' ' .. mode .. ': a set-back with the setting unchanged says nothing')
			check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ' ' .. mode .. ': it was set back')

			lines = said(chat(function()
				stub.cvars.useUiScale, stub.cvars.uiScale = '1', '0.8'
				stub.fire_event('UI_SCALE_CHANGED'); stub.fire_event('DISPLAY_SIZE_CHANGED')
				stub.engine_set_scale(0.8)
				frames()
			end))
			eq(#lines, 1, client .. ' ' .. mode .. ': the slider: one line')
			eq(lines[1], SLIDER, client .. ' ' .. mode .. ": the spec's words")
			check(near(UIParent:GetScale(), 768 / 1440, 1e-9), client .. ' ' .. mode .. ': and the scale is back')

			lines = said(chat(function()
				stub.cvars.uiScale = '0.9'
				stub.engine_set_scale(0.9)
				frames()
				stub.cvars.uiScale = '0.7'
				stub.engine_set_scale(0.7)
				frames()
			end))
			eq(#lines, 0, client .. ' ' .. mode .. ': once a session: no second line')
			eq(#take_errors(), 0, client .. ' ' .. mode .. ': no error')
		end

		-- A burst of events for one slider move: one line.
		world(client, 2560, 1440)
		start_uiscale()
		local lines = said(chat(function()
			stub.cvars.useUiScale, stub.cvars.uiScale = '1', '0.8'
			for _ = 1, 6 do stub.fire_event('UI_SCALE_CHANGED'); stub.fire_event('DISPLAY_SIZE_CHANGED') end
			stub.engine_set_scale(0.8)
			frames()
		end))
		eq(#lines, 1, client .. ': ten events in a burst: one line')

		-- The setting moved but the engine left the scale alone: no set-back, no line; the
		-- reading is taken, so a display change after it says nothing either.
		world(client, 2560, 1440)
		start_uiscale()
		lines = said(chat(function()
			stub.cvars.useUiScale, stub.cvars.uiScale = '1', '0.8'
			stub.fire_event('UI_SCALE_CHANGED')
			frames()
			stub.engine_set_scale(0.64)
			frames()
		end))
		eq(#lines, 0, client .. ': nothing set back by the slider: nothing said')

		-- In The game's UI scale the check only reads: no line.
		world(client, 2560, 1440)
		start_uiscale({ mode = 'game', size = 1 })
		lines = said(chat(function()
			stub.cvars.useUiScale, stub.cvars.uiScale = '1', '0.8'
			stub.engine_set_scale(0.8)
			frames()
		end))
		eq(#lines, 0, client .. ": The game's UI scale: no line")

		-- Our own Apply with the setting unchanged is not the slider.
		world(client, 2560, 1440)
		start_uiscale()
		lines = said(chat(function() st.UIScale:Apply({ mode = 'auto', size = 1.25 }); frames() end))
		eq(#lines, 0, client .. ': a change of ours says nothing')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)
