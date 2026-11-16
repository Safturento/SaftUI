-- SaftUI-Core/Config/uiscaleprompt.lua: the Keep prompt (st.UIScalePrompt) and
-- /sui scale. A UI size is tried (st.UIScale:Preview) and then kept or given
-- up: "Keep this UI size?" counting down from 15 s, with Keep and Go back; Esc
-- and the end of the time go back; Enter keeps nothing; it ignores its
-- parent's scale, sits over /sui and edit mode, takes no key in combat, and in
-- combat waits to go back until the fight ends.
--
-- Real: Core's Config/config.lua on a real AceDB (the world of
-- options_window_helpers.lua: the model, the kit's widgets, the body and the
-- window), edit mode with its bar (load_editmode_bar), and st.UIScale's
-- runtime (uiscale.lua, tests/core/uiscale_runtime_test.lua). The game's clock
-- is stub.time and stub.run_timers; the keys and clicks are fired scripts.

local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
load_editmode_bar()
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
load_saftui('SaftUI-Core/Config/uiscaleprompt.lua')
local KP, UIScale, EM = st.UIScalePrompt, st.UIScale, st.EditModeFrames
local W = st.OptionsWidgets

local function near(a, b, tolerance) return a ~= nil and b ~= nil and math.abs(a - b) < (tolerance or 1e-9) end

-- Chat lines printed while fn ran.
local function chat(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

local function said(lines, text)
	for _, line in ipairs(lines) do
		if line:find(text, 1, true) then return true end
	end
	return false
end

-- The game's next second: the clock on one, and the frame's timers.
local function second(n)
	for _ = 1, n or 1 do
		stub.time = stub.time + 1
		for _ = 1, 20 do if stub.run_timers() == 0 then break end end
	end
end

-- Past the half second Keep takes no click for.
local function ready()
	stub.time = stub.time + 0.6
	for _ = 1, 20 do if stub.run_timers() == 0 then break end end
end

local function frames()
	for _ = 1, 20 do if stub.run_timers() == 0 then return end end
end

-- A world on a screen with the scale started: nothing saved, nothing previewed,
-- no prompt, out of combat, no /sui.
local function world(width, height)
	H.close_all()
	KP:Dismiss()
	UIScale:Revert()
	stub.in_combat = false
	stub.screen_width, stub.screen_height = width or 2560, height or 1440
	UIParent:SetScale(0.64)
	st.config.global.uiScale = nil
	start_uiscale()
	frames()
	stub.blocked = {}
	take_errors()
end

local function ui() return KP:GetFrames() end

local function auto(size) return { mode = 'auto', size = size } end

------------------------------------------------------------------ the prompt

test('Ask: the preview at once, then the prompt: "Keep this UI size?", "Going back in 15 s.", Keep and Go back', function()
	world()
	eq(KP:IsShown(), false, 'nothing shows before an ask')
	eq(ui(), nil, 'and nothing is built')
	local ok, why = KP:Ask(auto(0.9))
	eq(ok, true, 'asked')
	eq(why, nil, 'with no refusal')
	check(near(UIParent:GetScale(), 768 / 1440 * 0.9, 1e-9), 'UIParent is at 90% at once')
	eq(UIScale:IsPreviewing(), true, 'a preview, not a save')
	eq(st.config.global.uiScale, nil, 'nothing saved')
	check(KP:IsShown(), 'the prompt shows')
	local f = ui()
	eq(f.title:GetText(), 'Keep this UI size?', 'the title')
	eq(f.line:GetText(), 'Going back in 15 s.', 'the line')
	eq(f.keep.label, 'Keep', 'a Keep button')
	eq(f.back.label, 'Go back', 'and a Go back button')
	check(f.keep:IsShown() and f.back:IsShown(), 'both shown')
	check(f.keep:GetObjectType() == 'Button' and f.keep.boxed, 'the kit\'s W.Button')
	eq(KP.SECONDS, 15, 'SECONDS')
	eq(KP.LEVEL, 9900, 'LEVEL')
	eq(f.frame:GetFrameStrata(), 'FULLSCREEN_DIALOG', 'strata')
	eq(f.frame:GetFrameLevel(), 9900, 'level')

	-- A refusal is passed on, and shows no prompt.
	KP:Dismiss()
	UIScale:Revert()
	local ok2, why2 = KP:Ask(auto(5))
	eq(ok2, false, 'a size out of range is refused')
	eq(why2, 'size', 'with its why')
	eq(KP:IsShown(), false, 'no prompt for it')
	eq(#take_errors(), 0, 'no errors')
end)

test('the countdown ticks each second, and at 0 it goes back: hidden, the scale as saved', function()
	world()
	KP:Ask(auto(0.9))
	second()
	eq(ui().line:GetText(), 'Going back in 14 s.', 'one second on')
	second(5)
	eq(ui().line:GetText(), 'Going back in 9 s.', 'six on')
	second(8)
	eq(ui().line:GetText(), 'Going back in 1 s.', 'fourteen on')
	check(KP:IsShown(), 'still up at 1 s')
	second()
	eq(KP:IsShown(), false, 'at 0 it is gone')
	eq(UIScale:IsPreviewing(), false, 'the preview ended')
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'UIParent is back at 100%')
	eq(st.config.global.uiScale, nil, 'nothing was saved')
	eq(#take_errors(), 0, 'no errors')
end)

test('Keep saves the previewed choice; Go back restores the saved one', function()
	world()
	KP:Ask(auto(0.9))
	ready(); stub.click(ui().keep)
	eq(KP:IsShown(), false, 'Keep hides it')
	eq(st.config.global.uiScale.mode, 'auto', 'saved: the mode')
	eq(st.config.global.uiScale.size, 0.9, 'and the size')
	eq(UIScale:IsPreviewing(), false, 'the preview is over')
	check(near(UIParent:GetScale(), 768 / 1440 * 0.9, 1e-9), 'UIParent stays at 90%')
	second(20)
	check(near(UIParent:GetScale(), 768 / 1440 * 0.9, 1e-9), 'and the old countdown goes back to nothing')

	KP:Ask(auto(1.2))
	check(near(UIParent:GetScale(), 768 / 1440 * 1.2, 1e-9), 'at 120% while asked')
	stub.click(ui().back)
	eq(KP:IsShown(), false, 'Go back hides it')
	check(near(UIParent:GetScale(), 768 / 1440 * 0.9, 1e-9), 'back at the saved 90%')
	eq(st.config.global.uiScale.size, 0.9, 'the save is as it was')

	-- Keep through the pixel and game modes too.
	KP:Ask({ mode = 'pixel', size = 0.9 })
	ready(); stub.click(ui().keep)
	eq(st.config.global.uiScale.mode, 'pixel', 'Pixel for pixel kept')
	eq(#take_errors(), 0, 'no errors')
end)

test('Esc goes back, and every other key goes on to the game; Enter keeps nothing', function()
	world()
	KP:Ask(auto(0.9))
	local frame = ui().frame
	check(frame:IsKeyboardEnabled(), 'it has the keyboard while it shows')

	stub.fire_script(frame, 'OnKeyDown', 'W')
	eq(frame:GetPropagateKeyboardInput(), true, 'W goes on to the game')
	check(KP:IsShown(), 'and the prompt stays')
	stub.fire_script(frame, 'OnKeyDown', 'ENTER')
	eq(frame:GetPropagateKeyboardInput(), true, 'Enter goes on too')
	check(KP:IsShown(), 'and does not answer')
	eq(st.config.global.uiScale, nil, 'nothing is kept')
	eq(UIScale:IsPreviewing(), true, 'the preview goes on')
	stub.fire_script(frame, 'OnKeyDown', 'SPACE')
	check(KP:IsShown(), 'space does nothing either')

	stub.fire_script(frame, 'OnKeyDown', 'ESCAPE')
	eq(frame:GetPropagateKeyboardInput(), false, 'Esc is taken')
	eq(KP:IsShown(), false, 'and goes back')
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'the scale as saved')
	eq(frame:IsKeyboardEnabled(), false, 'the keyboard is given back when it hides')
	eq(#take_errors(), 0, 'no errors')
end)

test('a second change restarts it for the new choice; going back then returns to the saved choice', function()
	world()
	st.config.global.uiScale = auto(0.8)
	UIScale:Revert()
	check(near(UIParent:GetScale(), 768 / 1440 * 0.8, 1e-9), 'saved at 80%')
	KP:Ask(auto(0.9))
	second(7)
	eq(ui().line:GetText(), 'Going back in 8 s.', 'seven seconds in')
	KP:Ask(auto(1.2))
	eq(ui().line:GetText(), 'Going back in 15 s.', 'a second change restarts the time')
	check(near(UIParent:GetScale(), 768 / 1440 * 1.2, 1e-9), 'at 120%')
	local prior = UIScale:Previous()
	eq(prior.size, 0.8, 'the before is the saved choice, not the first preview')
	second(14)
	check(KP:IsShown(), 'the old countdown did not end it: 14 s into the new one')
	eq(ui().line:GetText(), 'Going back in 1 s.', 'one second left')
	second()
	eq(KP:IsShown(), false, 'the new countdown ends it')
	check(near(UIParent:GetScale(), 768 / 1440 * 0.8, 1e-9), 'back at the saved 80%, not the 90% before it')

	KP:Ask(auto(0.9))
	KP:Ask(auto(1.1))
	stub.click(ui().back)
	check(near(UIParent:GetScale(), 768 / 1440 * 0.8, 1e-9), 'Go back after two changes: the saved 80%')
	eq(#take_errors(), 0, 'no errors')
end)

test('the engine changing the scale while it is up: the preview wins, the time runs on, the prompt follows the screen', function()
	world()
	KP:Ask(auto(0.9))
	second(3)
	stub.screen_width, stub.screen_height = 1920, 1080
	UIParent:SetScale(0.64) -- the engine's own, over SaftUI's
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	stub.fire_event('UI_SCALE_CHANGED')
	frames()
	check(near(UIParent:GetScale(), 768 / 1080 * 0.75 * 0.9, 1e-9), 'SaftUI set the 90% back, on the new screen')
	check(KP:IsShown(), 'the prompt stays')
	eq(ui().line:GetText(), 'Going back in 12 s.', 'and its time is the one it had')
	check(near(ui().frame:GetEffectiveScale(), UIScale:Default().uiScale, 1e-9), 'drawn at the new screen\'s automatic size')
	stub.click(ui().back)
	check(near(UIParent:GetScale(), 768 / 1080 * 0.75, 1e-9), 'Go back: 100% of the new screen')
	eq(#take_errors(), 0, 'no errors')
end)

test('a /reload or logout with the prompt up saves nothing: the next login is the choice before the preview', function()
	world()
	st.config.global.uiScale = auto(0.8)
	KP:Ask(auto(1.2))
	eq(st.config.global.uiScale.size, 0.8, 'the saved table is the 80% still')
	-- The next login, on the same saved table.
	UIParent:SetScale(0.64)
	UIScale:Revert()
	check(near(UIParent:GetScale(), 768 / 1440 * 0.8, 1e-9), 'comes back at 80%')
end)

------------------------------------------------------------------ combat

test('the prompt through combat', function()
	world()
	KP:Ask(auto(0.9))
	local frame = ui().frame
	local propagated = 0
	frame.SetPropagateKeyboardInput = function(self, ...)
		propagated = propagated + 1
		return getmetatable(self).__index.SetPropagateKeyboardInput(self, ...)
	end

	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	check(KP:IsShown(), 'combat starts: it stays')
	eq(frame:IsKeyboardEnabled(), false, 'with its keyboard off')
	stub.fire_script(frame, 'OnKeyDown', 'ESCAPE')
	eq(propagated, 0, 'a key in combat never calls SetPropagateKeyboardInput')
	check(KP:IsShown(), 'and Esc does nothing in combat')

	-- The time ends in combat.
	second(15)
	check(KP:IsShown(), 'its time ends: it is still up')
	eq(ui().line:GetText(), 'Goes back when combat ends.', 'saying it goes back when combat ends')
	check(not ui().keep:IsShown() and not ui().back:IsShown(), 'with no buttons')
	check(near(UIParent:GetScale(), 768 / 1440 * 0.9, 1e-9), 'UIParent unchanged in combat')
	eq(UIScale:IsPreviewing(), false, 'the preview is over, the revert waits')
	eq(propagated, 0, 'still no SetPropagateKeyboardInput')
	second(5)
	check(KP:IsShown(), 'it waits as long as combat does')

	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	frames()
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'the revert applied once combat ended')
	eq(KP:IsShown(), false, 'and the prompt is gone')
	eq(#stub.blocked, 0, 'nothing protected was called in combat')
	eq(propagated, 0, 'and no key was ever caught in combat')
	eq(#take_errors(), 0, 'no errors')
end)

test('combat starts while it shows, and Go back or Keep are clicked in combat', function()
	world()
	KP:Ask(auto(0.9))
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	stub.click(ui().back)
	eq(ui().line:GetText(), 'Goes back when combat ends.', 'Go back in combat waits')
	check(KP:IsShown() and not ui().back:IsShown(), 'with its buttons hidden')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	frames()
	eq(KP:IsShown(), false, 'gone after combat')
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'at the saved scale')

	-- Keep in combat saves at once and the scale stays.
	world()
	KP:Ask(auto(0.9))
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	ready(); stub.click(ui().keep)
	eq(KP:IsShown(), false, 'Keep in combat closes it')
	eq(st.config.global.uiScale.size, 0.9, 'and saves')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	frames()
	check(near(UIParent:GetScale(), 768 / 1440 * 0.9, 1e-9), 'the 90% stays')
	eq(#stub.blocked, 0, 'nothing blocked')

	-- A change in combat is refused, with no prompt.
	world()
	stub.in_combat = true
	local ok, why = KP:Ask(auto(0.9))
	eq(ok, false, 'no ask in combat')
	eq(why, 'combat', 'because of combat')
	eq(KP:IsShown(), false, 'no prompt')
	stub.in_combat = false
end)

test('a revert that changes nothing still hides the prompt when combat ends', function()
	-- The previewed choice and the saved one make the same scale (Pixel for
	-- pixel and Automatic on a 1440 screen): nothing changes, so no OnChanged.
	world()
	KP:Ask({ mode = 'pixel', size = 1 })
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	second(15)
	eq(ui().line:GetText(), 'Goes back when combat ends.', 'waiting')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	frames()
	eq(KP:IsShown(), false, 'hidden at the end of combat')
end)

------------------------------------------------------------------ where and how big

local function physical_edges(frame)
	local height = select(2, GetPhysicalScreenSize())
	local pixel = (768 / height)
	local k = frame:GetEffectiveScale() / pixel
	return frame:GetLeft() * k, frame:GetRight() * k, frame:GetTop() * k, frame:GetBottom() * k
end

scaled_test('it draws at the automatic size of this screen at 100%, whatever is previewed; whole pixels, centred', function()
	use_scale(test_scale())
	local width, height = GetPhysicalScreenSize()
	st.config.global.uiScale = nil
	start_uiscale()
	frames()
	local default = UIScale:Default()
	for _, size in ipairs({ 0.7, 1.5, 1, 0.7 }) do
		eq(KP:Ask(auto(size)), true, 'asked at ' .. size)
		local frame = ui().frame
		check(near(UIParent:GetScale(), (768 / height) * default.auto * size, 1e-9), 'previewed: UIParent at ' .. size)
		check(near(frame:GetEffectiveScale(), default.uiScale, 1e-9), 'the prompt stays at the default\'s scale at ' .. size)
		check(frame:IsIgnoringParentScale(), 'ignoring its parent\'s scale')
		local left, right, top, bottom = physical_edges(frame)
		for name, value in pairs({ left = left, right = right, top = top, bottom = bottom }) do
			check(math.abs(value - math.floor(value + 0.5)) < 1e-3, name .. ' on a whole pixel at ' .. size .. ': ' .. value)
		end
		-- Centred: its middle is the screen's, within a pixel.
		check(math.abs((left + right) / 2 - width / 2) <= 1, 'centred across at ' .. size)
		check(math.abs((top + bottom) / 2 - height / 2) <= 1, 'and down at ' .. size)
		-- On screen, whole.
		check(left >= 0 and right <= width and bottom >= 0 and top <= height, 'on the screen at ' .. size)
	end
	KP:Dismiss()
	UIScale:Revert()
	eq(#take_errors(), 0, 'no errors')
end)

test('over /sui, the edit mode bar and the History list; in the theme on the options Background', function()
	world()
	local calls = {}
	local set = st.SetTemplate
	st.SetTemplate = function(self, frame, ...)
		calls[#calls + 1] = { frame = frame, args = { ... } }
		return set(self, frame, ...)
	end
	KP:Ask(auto(0.9))
	st.SetTemplate = set
	local frame = ui().frame
	local drawn
	for _, call in ipairs(calls) do
		if call.frame == frame then drawn = call.args end
	end
	check(drawn ~= nil, 'drawn by st:SetTemplate')
	eq(table.concat(drawn or {}, ','), 'theme,options,panel', 'the theme, on the options Background, as a panel')

	st.Config:Open()
	local window = H.frames().window
	eq(window:GetFrameStrata(), 'FULLSCREEN_DIALOG', '/sui is in FULLSCREEN_DIALOG')
	check(window:GetFrameLevel() < KP.LEVEL, '/sui is under it')
	local bar, barWindow, history = EM:GetBar(), EM:GetBarWindow(), EM:GetHistoryList()
	for name, other in pairs({ bar = bar, ['the floating window'] = barWindow, ['the History list'] = history }) do
		eq(other:GetFrameStrata(), 'FULLSCREEN_DIALOG', name .. ' strata')
		check(other:GetFrameLevel() < KP.LEVEL, name .. ' is under it: ' .. other:GetFrameLevel())
	end
	check(EM.HISTORY.LEVEL < KP.LEVEL and EM.BAR.LEVEL < KP.LEVEL, 'and the numbers say so')
	check(9600 < KP.LEVEL, 'the Coordinates label (9600) too')
	KP:Dismiss()
	UIScale:Revert()
	eq(#take_errors(), 0, 'no errors')
end)

test('it stays when /sui closes, and a click outside it reaches what is under it', function()
	world()
	st.Config:Open()
	KP:Ask(auto(0.9))
	st.Config:Close()
	check(KP:IsShown(), 'it stays when /sui closes')
	local frame = ui().frame
	check(frame:IsMouseEnabled(), 'it takes the mouse on itself, so a click on it stops there')
	-- No catcher: nothing but the prompt's own frame (and its children) takes the screen.
	for _, child in ipairs({ UIParent:GetChildren() }) do
		if child:IsShown() and child:GetFrameLevel() >= KP.LEVEL and child ~= frame then
			local w, h = child:GetWidth(), child:GetHeight()
			check(not (child:IsMouseEnabled() and w >= UIParent:GetWidth() and h >= UIParent:GetHeight()), 'no full-screen catcher')
		end
	end
	check(frame:GetWidth() < UIParent:GetWidth() / 2 or frame:GetEffectiveScale() ~= UIParent:GetEffectiveScale(), 'a small frame, not the whole screen')
	KP:Dismiss()
	UIScale:Revert()
end)

test('a preview at a scale where /sui no longer fits: the prompt is still there, and Go back is the way', function()
	world(2560, 768)
	st.Config:Open()
	check(KP:Ask(auto(1.0)), 'asked on a 768 high screen')
	check(KP:IsShown(), 'shown')
	stub.click(ui().back)
	check(near(UIParent:GetScale(), 0.75, 1e-9), 'back at the 768 high screen\'s automatic 75%')
	eq(KP:IsShown(), false, 'hidden')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ /sui scale

test('/sui scale: the line', function()
	world()
	local lines = chat(function() SlashCmdList.SAFTUI('scale') end)
	check(said(lines, 'UI scale: Automatic at 100%.'), 'the mode and the size: ' .. table.concat(lines, ' | '))
	check(said(lines, 'This screen is 2560 x 1440: SaftUI draws at 100% of its 1440p size, with 1 pixel lines.'), 'and what the screen makes of it')
	eq(KP:IsShown(), false, 'no prompt')

	st.config.global.uiScale = auto(0.9)
	UIScale:Revert()
	lines = chat(function() SlashCmdList.SAFTUI('  SCALE  ') end)
	check(said(lines, 'UI scale: Automatic at 90%.'), 'at 90% saved, in any case: ' .. table.concat(lines, ' | '))
	st.config.global.uiScale = { mode = 'pixel', size = 1 }
	UIScale:Revert()
	lines = chat(function() SlashCmdList.SAFTUI('scale') end)
	check(said(lines, 'UI scale: Pixel for pixel.'), 'Pixel for pixel names no size: ' .. table.concat(lines, ' | '))
	check(said(lines, 'draws pixel for pixel'), 'and Describe')
end)

test('/sui scale reset: at once with no prompt, in combat after it, and it ends a preview', function()
	world()
	st.config.global.uiScale = auto(1.5)
	UIScale:Revert()
	check(near(UIParent:GetScale(), 768 / 1440 * 1.5, 1e-9), 'at 150%')
	local lines = chat(function() SlashCmdList.SAFTUI('scale reset') end)
	check(said(lines, 'UI scale back to Automatic at 100%.'), 'says so: ' .. table.concat(lines, ' | '))
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'at once')
	eq(st.config.global.uiScale, nil, 'the save is gone')
	eq(KP:IsShown(), false, 'with no prompt')

	st.config.global.uiScale = auto(0.7)
	UIScale:Revert()
	SlashCmdList.SAFTUI('scale reset')
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'from 70% too')

	-- In combat: saved at once, the scale follows the fight.
	st.config.global.uiScale = auto(1.5)
	UIScale:Revert()
	stub.in_combat = true
	lines = chat(function() SlashCmdList.SAFTUI('scale reset') end)
	check(said(lines, 'UI scale goes back to Automatic at 100% when combat ends.'), 'in combat: ' .. table.concat(lines, ' | '))
	eq(st.config.global.uiScale, nil, 'saved at once')
	check(near(UIParent:GetScale(), 768 / 1440 * 1.5, 1e-9), 'the scale waits')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	frames()
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'and follows when combat ends')
	eq(#stub.blocked, 0, 'nothing blocked')

	-- During a preview: it ends it and hides the prompt.
	world()
	KP:Ask(auto(1.2))
	check(KP:IsShown() and UIScale:IsPreviewing(), 'a preview with a prompt')
	SlashCmdList.SAFTUI('scale reset')
	eq(KP:IsShown(), false, 'the prompt is hidden')
	eq(UIScale:IsPreviewing(), false, 'the preview is over')
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'at the default')
	second(20)
	eq(#take_errors(), 0, 'no errors')
end)

test('/sui scale <n>: 90 and 90%, held to the range, rounded to the steps, on this screen', function()
	world()
	for _, form in ipairs({ 'scale 90', 'scale 90%' }) do
		KP:Dismiss()
		UIScale:Revert()
		local lines = chat(function() SlashCmdList.SAFTUI(form) end)
		eq(#lines, 0, form .. ': says nothing, the prompt asks')
		check(KP:IsShown(), form .. ': the prompt shows')
		check(near(UIParent:GetScale(), 768 / 1440 * 0.9, 1e-9), form .. ': previewed at 90%')
		eq(UIScale:Current().mode, 'auto', form .. ': Automatic')
	end
	for _, case in ipairs({ { '200', 1.5 }, { '10', 0.7 }, { '0', 0.7 }, { '92', 0.9 }, { '148', 1.5 }, { '72.5', 0.75 } }) do
		KP:Dismiss()
		UIScale:Revert()
		SlashCmdList.SAFTUI('scale ' .. case[1])
		check(near(UIScale:Current().size, case[2], 1e-9), case[1] .. ' is held to ' .. case[2] .. ', got ' .. UIScale:Current().size)
		check(KP:IsShown(), case[1] .. ': prompt')
	end

	-- A 768 high screen: 150 is held to 130 (what the screen holds).
	world(1366, 768)
	KP:Dismiss()
	SlashCmdList.SAFTUI('scale 150')
	check(near(UIScale:Current().size, 1.3, 1e-9), '150 on a 768 high screen is held to 130, got ' .. UIScale:Current().size)
	check(KP:IsShown(), 'with the prompt')
	KP:Dismiss()
	UIScale:Revert()
	eq(#take_errors(), 0, 'no errors')
end)

test('/sui scale auto, pixel and game: that mode, with the prompt, at the size already chosen', function()
	world()
	st.config.global.uiScale = auto(0.8)
	UIScale:Revert()
	for _, mode in ipairs({ 'pixel', 'auto', 'game' }) do
		KP:Dismiss()
		UIScale:Revert()
		local lines = chat(function() SlashCmdList.SAFTUI('scale ' .. mode) end)
		eq(#lines, 0, mode .. ': no chat line')
		check(KP:IsShown(), mode .. ': the prompt shows')
		eq(UIScale:Current().mode, mode, mode .. ': previewed')
		eq(UIScale:Current().size, 0.8, mode .. ': at the chosen size')
	end
	eq(st.config.global.uiScale.mode, 'auto', 'none was saved')
	KP:Dismiss()
	UIScale:Revert()
	eq(#take_errors(), 0, 'no errors')
end)

test('/sui scale with anything else gives the forms; in combat it says it can\'t change', function()
	world()
	local forms = 'Type /sui scale, then reset, auto, pixel, game or a size from 70 to 150 (a number under 5, like 1.25, is a factor: 125%).'
	for _, bad in ipairs({ 'scale big', 'scale -5', 'scale 90 100', 'scale 9x', 'scale %', 'scale 1e2', 'scale pixels' }) do
		local lines = chat(function() SlashCmdList.SAFTUI(bad) end)
		check(said(lines, forms), bad .. ' gives the forms: ' .. table.concat(lines, ' | '))
		eq(KP:IsShown(), false, bad .. ': no prompt')
		eq(UIScale:IsPreviewing(), false, bad .. ': no preview')
	end
	-- "scale" is only its own word: another command is not it.
	check(not said(chat(function() SlashCmdList.SAFTUI('scales') end), forms), '"scales" is not "scale"')

	stub.in_combat = true
	local lines = chat(function() SlashCmdList.SAFTUI('scale 90') end)
	check(said(lines, "The UI size can't change in combat."), 'in combat: ' .. table.concat(lines, ' | '))
	eq(KP:IsShown(), false, 'no prompt')
	eq(UIScale:IsPreviewing(), false, 'no preview')
	lines = chat(function() SlashCmdList.SAFTUI('scale pixel') end)
	check(said(lines, "The UI size can't change in combat."), 'pixel too')
	-- /sui scale with no argument still works in combat.
	lines = chat(function() SlashCmdList.SAFTUI('scale') end)
	check(said(lines, 'UI scale: Automatic at 100%.'), 'the line in combat')
	stub.in_combat = false
	eq(#take_errors(), 0, 'no errors')
end)

test('Keep with a choice the screen no longer holds goes back and says so', function()
	world()
	KP:Ask(auto(1.5))
	-- A display change to a screen that holds 130% at most while the prompt is up.
	stub.screen_width, stub.screen_height = 1366, 768
	stub.fire_event('DISPLAY_SIZE_CHANGED')
	frames()
	ready()
	local lines = chat(function() stub.click(ui().keep) end)
	eq(KP:IsShown(), false, 'closed')
	check(said(lines, "doesn't fit this screen"), 'says so: ' .. table.concat(lines, ' | '))
	eq(st.config.global.uiScale, nil, 'nothing saved')
	eq(UIScale:IsPreviewing(), false, 'no preview left')
end)

test('/sui scale is parsed before the commands, as edit and debug are', function()
	local source = read_saftui_source('SaftUI-Core/Config/config.lua')
	local scale = source:find("command == 'scale'", 1, true)
	local find = source:find('local entry = FindCommand(command)', 1, true)
	check(scale and find and scale < find, 'config.lua tests for scale before FindCommand')
	local xml = read_saftui_source('SaftUI-Core/Config/load.xml')
	local general, prompt = xml:find('general.lua', 1, true), xml:find('uiscaleprompt.lua', 1, true)
	check(general and prompt and general < prompt, 'load.xml loads uiscaleprompt.lua after general.lua')
end)

------------------------------------------------------------------ the review's round

test('Keep takes no click for half a second and looks disabled; Go back and Esc work at once', function()
	world()
	KP:Ask(auto(0.9))
	local f = ui()
	eq(f.keep.disabled, true, 'Keep looks disabled (the kit\'s disabled button)')
	eq(f.keep:GetAlpha(), 0.4, 'at the kit\'s disabled alpha')
	stub.click(f.keep) -- the same frame as the ask
	check(KP:IsShown() and st.config.global.uiScale == nil, 'a click in the same frame keeps nothing')
	stub.time = stub.time + 0.2
	frames()
	stub.click(f.keep)
	check(KP:IsShown() and st.config.global.uiScale == nil, 'a click at 0.2 s keeps nothing')
	stub.time = stub.time + 0.4
	frames()
	eq(f.keep.disabled, false, 'at 0.6 s Keep is enabled')
	eq(f.keep:GetAlpha(), 1, 'and drawn so')
	stub.click(f.keep)
	eq(st.config.global.uiScale and st.config.global.uiScale.size, 0.9, 'a click at 0.6 s keeps')

	-- Go back and Esc at once.
	KP:Ask(auto(1.2))
	stub.click(ui().back)
	eq(KP:IsShown(), false, 'Go back works at once')
	KP:Ask(auto(1.2))
	stub.fire_script(ui().frame, 'OnKeyDown', 'ESCAPE')
	eq(KP:IsShown(), false, 'Esc works at once')

	-- A second ask starts the delay again; the first ask's timer does not end it.
	KP:Ask(auto(1.1))
	stub.time = stub.time + 0.4
	KP:Ask(auto(1.2))
	stub.time = stub.time + 0.2
	frames()
	eq(ui().keep.disabled, true, 'the first ask\'s timer (0.5 s) did not enable the new ask\'s Keep at 0.2 s')
	stub.time = stub.time + 0.4
	frames()
	eq(ui().keep.disabled, false, 'and its own does, at 0.6 s')
	KP:Dismiss()
	UIScale:Revert()
	eq(#take_errors(), 0, 'no errors')
end)

test('a preview ended by something else hides the prompt on its next tick', function()
	world()
	KP:Ask(auto(0.9))
	UIScale:Apply(auto(0.9)) -- a save from elsewhere (a row in /sui, the setup dialog)
	check(KP:IsShown(), 'not before the tick')
	second()
	eq(KP:IsShown(), false, 'gone on the tick')
	eq(st.config.global.uiScale.size, 0.9, 'the save stands')
	second(20)
	check(near(UIParent:GetScale(), 768 / 1440 * 0.9, 1e-9), 'and the old countdown goes back to nothing')
	-- Reverted elsewhere too.
	KP:Ask(auto(1.2))
	UIScale:Revert()
	second()
	eq(KP:IsShown(), false, 'a revert from elsewhere hides it too')
end)

test('a waiting prompt hides from the scale change itself, with no frame after the end of combat', function()
	world()
	KP:Ask(auto(0.9))
	stub.in_combat = true
	stub.fire_event('PLAYER_REGEN_DISABLED')
	second(15)
	eq(ui().line:GetText(), 'Goes back when combat ends.', 'waiting')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED') -- no timer has run
	check(near(UIParent:GetScale(), 768 / 1440, 1e-9), 'the revert applied')
	eq(KP:IsShown(), false, 'and OnChanged hid it, before any timer')
end)

test('the muted line and the buttons take the colors and look of now, each time it shows', function()
	world()
	KP:Ask(auto(0.9))
	local color = st.Color
	local looks = 0
	local look = W.LookControl
	W.LookControl = function(...) looks = looks + 1; return look(...) end
	st.Color = function(self, group, key, ...)
		if group == 'text' and key == 'muted' then return { GetRGB = function() return 0.1, 0.2, 0.3 end } end
		return color(self, group, key, ...)
	end
	KP:Ask(auto(1.1))
	st.Color = color
	W.LookControl = look
	local r, g, b = ui().line:GetTextColor()
	check(near(r, 0.1, 1e-6) and near(g, 0.2, 1e-6) and near(b, 0.3, 1e-6), 'the line has the color now: ' .. tostring(r) .. ',' .. tostring(g) .. ',' .. tostring(b))
	check(looks >= 2, 'both buttons wear the look now')
	KP:Dismiss()
	UIScale:Revert()
end)

test('/sui scale 1.25 is 125%: a number under 5 is a factor', function()
	world()
	for _, case in ipairs({ { '1.25', 1.25 }, { '1.25%', 1.25 }, { '1', 1 }, { '0.9', 0.9 }, { '4', 1.5 }, { '5', 0.7 } }) do
		KP:Dismiss()
		UIScale:Revert()
		SlashCmdList.SAFTUI('scale ' .. case[1])
		check(near(UIScale:Current().size, case[2], 1e-9), case[1] .. ' is ' .. case[2] .. ', got ' .. UIScale:Current().size)
	end
	KP:Dismiss()
	UIScale:Revert()
end)
