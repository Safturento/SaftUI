-- Fading and hiding SaftUI's tracker (SaftUI-Tracker/visibility.lua; design:
-- "Fading and hiding"): the six triggers (in combat, out of combat, mouse off,
-- in instances, boss fights, Mythic+) and what each does (Show, Fade, Hide):
--   - TR.Visibility.Driver, Applies and Resolve (pure): the strongest trigger
--     wins, Show fully under the mouse turns Fade into Show and never Hide,
--     Hide quest items with the tracker off keeps the buttons at full alpha, on
--     fades them never under 25% and hides them by the layer's driver (combat,
--     out of combat, boss) or directly (instances, Mythic+, boss), Mouse off
--     never hides;
--   - the applier in the world: the window by alpha and Hide, faded-to-0 rows
--     and the wheel taking no input, the panel under the mouse only, the item
--     layer's driver set out of combat or queued, the nearest button left alone
--     (its driver is the pet battle's alone), Blizzard's tracker during a
--     handover (Hide conceals it, Fade holds its alpha through Blizzard's own
--     SetAlpha), the events, the fade's pace and what runs while nothing
--     changes;
--   - the Visibility tab.
-- On both clients. Real: SaftUI-Tracker's files, the quest, section and secure
-- button stubs, and Blizzard's tracker from the Misc fixture. The stubs evaluate
-- no macro condition, so what a driver does is read from the string set.
local RW = load_test_file('tracker/rows_world.lua')
local TW, Q = RW.TW, RW.Q

------------------------------------------------------------------ the world

local function item_of(id) return { link = 'item:' .. (1000 + id), texture = 134400 + id, charges = 0 } end

local function log(ids, with_items)
	local entries = { Q.header('Elwynn Forest') }
	for _, id in ipairs(ids) do
		entries[#entries + 1] = Q.quest(id, { item = with_items and item_of(id) or nil, objectives = { { text = '1/2 Wolves', type = 'monster' } } })
	end
	Q.set(entries, ids)
end

-- A world with the switch on. opts: client, ids, items (quests have items,
-- default true), visibility (settings), nearest, blizzard (Blizzard's tracker),
-- mode ('beside'), combat, config(st).
local function world(opts)
	opts = opts or {}
	stub.instance, stub.encounter = nil, false
	stub.probes = { watched_tasks = {}, world = {}, world_watches = 0, task_info = {}, tasks = {}, tracked = {}, achievements = {} }
	local st, TR = RW.world({
		client = opts.client, blizzard = opts.blizzard, screen = { 1000, 600 }, combat = opts.combat,
		enabling = function(st)
			log(opts.ids or { 1, 2 }, opts.items ~= false)
			local tracker = st.config.profile.tracker
			for key, value in pairs(opts.visibility or {}) do tracker.visibility[key] = value end
			if opts.nearest then tracker.items.nearest = true end
			if opts.mode then tracker.blizzard.mode = opts.mode end
			if opts.config then opts.config(st) end
		end,
	})
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	return st, TR, TW.OT
end

local function both(name, fn, opts)
	for _, client in ipairs({ 'forever', 'retail' }) do
		test(name .. ' [' .. client .. ']', function()
			local o = {}
			for key, value in pairs(opts or {}) do o[key] = value end
			o.client = client
			local st, TR, OT = world(o)
			fn(st, TR, OT, client)
			eq(#take_errors(), 0, client .. ': no error reported')
			eq(#stub.blocked, 0, client .. ': nothing blocked')
		end)
	end
end

-- Saves settings and runs the update a /sui change runs.
local function set(TR, settings)
	for key, value in pairs(settings) do TR.config.visibility[key] = value end
	TR:UpdateConfig()
end

-- The fade, run to its end.
local function fade_done(TR)
	local script = TR.fader and TR.fader:GetScript('OnUpdate')
	if not script then return end
	for _ = 1, 20 do stub.fire_script(TR.fader, 'OnUpdate', 0.05) end
end

local function near(a, b) return math.abs(a - b) <= 0.001 end

local function items_shown(TR)
	local n = 0
	for _, button in ipairs(TR.itemButtons or {}) do if button.questID and button:IsShown() then n = n + 1 end end
	return n
end

local function min_item_alpha(TR)
	local least
	for _, button in ipairs(TR.itemButtons or {}) do
		if button.questID and button:IsShown() and (not least or button:GetAlpha() < least) then least = button:GetAlpha() end
	end
	return least
end

local function layer_driver(TR)
	return stub.state(TR.itemLayer).state_drivers['state-visibility']
end

local function scenario(on)
	stub.probes.scenario = on and { stages = 3, stage = 1 } or { stages = 0 }
	stub.fire_event('SCENARIO_UPDATE')
end

local function settle_probes(seconds) RW.later(seconds or 0.1) end

------------------------------------------------------------------ the pure parts

test('TR.Visibility.Driver: the pet battle always, the combat conditions only with Hide quest items on', function()
	local st = RW.world({})
	local TR = st.Tracker
	local function v(t) return setmetatable(t, { __index = st.defaults.tracker.visibility }) end
	eq(TR.Visibility.Driver(v{}), '[petbattle] hide; show')
	eq(TR.Visibility.Driver(v{ items = true, combat = 'hide' }), '[petbattle] hide; [combat] hide; show')
	eq(TR.Visibility.Driver(v{ items = true, nocombat = 'hide', boss = 'hide' }), '[petbattle] hide; [nocombat] hide; [@boss1,exists] hide; show')
	eq(TR.Visibility.Driver(v{ combat = 'hide' }), '[petbattle] hide; show', 'buttons stay with Hide quest items off')
	eq(TR.Visibility.Driver(v{ items = true, combat = 'hide', nocombat = 'hide', boss = 'hide' }), '[petbattle] hide; [combat] hide; [nocombat] hide; [@boss1,exists] hide; show', 'all three, in this order')
	eq(TR.Visibility.Driver(v{ items = true, instance = 'hide', mythic = 'hide', mouseoff = 'fade', combat = 'fade' }), '[petbattle] hide; show', 'instances and Mythic+ start out of combat: hidden directly; fades and Mouse off are alpha')
	eq(TR.ITEM_DRIVER, '[petbattle] hide; show', 'the constant is the pet battle\'s alone')
	eq(#take_errors(), 0, 'no errors')
end)

local function applies(t)
	local a = { combat = false, nocombat = false, mouseoff = false, instance = false, boss = false, mythic = false }
	for key, value in pairs(t) do a[key] = value end
	return a
end

test('TR.Visibility.Resolve: each trigger and choice alone, the strongest wins, hover turns Fade into Show and never Hide', function()
	local st = RW.world({})
	local TR = st.Tracker
	local R = TR.Visibility.Resolve
	local function v(t) return setmetatable(t, { __index = st.defaults.tracker.visibility }) end
	local function window(a, s, hovered)
		local r = R(applies(a), s, hovered or false)
		return r.window .. ' ' .. r.alpha
	end
	-- Defaults: every trigger is Show.
	eq(window({ nocombat = true }, v{}), 'show 1', 'nothing set: shown')
	for _, key in ipairs({ 'combat', 'nocombat', 'mouseoff', 'instance', 'boss', 'mythic' }) do
		eq(window({ [key] = true }, v{ [key] = 'fade' }), 'fade 0.3', key .. ' Fade: the faded opacity')
		eq(window({}, v{ [key] = 'fade' }), 'show 1', key .. ' Fade, not applying: shown')
		if key ~= 'mouseoff' then eq(window({ [key] = true }, v{ [key] = 'hide' }), 'hide 1', key .. ' Hide') end
	end
	eq(window({ mouseoff = true }, v{ mouseoff = 'hide' }), 'fade 0.3', 'Mouse off is Show or Fade: a saved Hide is a Fade (a hidden window can\'t be hovered)')
	eq(window({ combat = true }, v{ combat = 'fade', fade_alpha = 0.55 }), 'fade 0.55', 'the faded opacity is the setting')
	eq(window({ combat = true }, v{ combat = 'fade', fade_alpha = 0 }), 'fade 0', 'and may be 0')
	eq(window({ combat = true }, v{ combat = 'fade', fade_alpha = 7 }), 'fade 1', 'clamped')
	-- The strongest wins: Hide over Fade over Show, whatever the order.
	eq(window({ combat = true, instance = true }, v{ combat = 'fade', instance = 'hide' }), 'hide 1', 'Hide over Fade')
	eq(window({ combat = true, instance = true }, v{ combat = 'hide', instance = 'fade' }), 'hide 1', 'Hide over Fade, the other way')
	eq(window({ combat = true, boss = true }, v{ combat = 'show', boss = 'fade' }), 'fade 0.3', 'Fade over Show')
	eq(window({ combat = true, boss = true, mythic = true }, v{ combat = 'fade', boss = 'show', mythic = 'hide' }), 'hide 1', 'three apply')
	eq(window({ nocombat = true, mouseoff = true }, v{ nocombat = 'show', mouseoff = 'fade' }), 'fade 0.3', 'one Show does not hold back a Fade')
	-- Show fully under the mouse: Fade becomes Show, Hide never does.
	eq(window({ combat = true }, v{ combat = 'fade' }, true), 'show 1', 'hovered: Fade shows')
	eq(window({ combat = true }, v{ combat = 'fade', hover = false }, true), 'fade 0.3', 'with the setting off it stays faded')
	eq(window({ combat = true }, v{ combat = 'hide' }, true), 'hide 1', 'a hidden tracker can\'t be hovered: Hide stays')
	eq(window({ combat = true, instance = true }, v{ combat = 'fade', instance = 'hide' }, true), 'hide 1', 'Hide beside a Fade, hovered')
	eq(#take_errors(), 0, 'no errors')
end)

test('TR.Visibility.Resolve: the item buttons: off, Fade at 25% at the least, Hide by the driver or directly, Mouse off never', function()
	local st = RW.world({})
	local TR = st.Tracker
	local R = TR.Visibility.Resolve
	local function v(t) return setmetatable(t, { __index = st.defaults.tracker.visibility }) end
	local function items(a, s, hovered)
		local r = R(applies(a), s, hovered or false)
		return ('%s %s %s'):format(r.items, r.itemAlpha, tostring(r.hideItemsDirectly))
	end
	-- Hide quest items with the tracker off: full alpha whatever the window does.
	eq(items({ combat = true }, v{ combat = 'fade', fade_alpha = 0 }), 'show 1 false', 'off: faded window, full buttons')
	eq(items({ instance = true }, v{ instance = 'hide' }), 'show 1 false', 'off: hidden window, buttons stay')
	-- On.
	eq(items({ combat = true }, v{ items = true, combat = 'fade', fade_alpha = 0 }), 'fade 0.25 false', 'on: Fade at 25%, never under (Ruling 31)')
	eq(items({ combat = true }, v{ items = true, combat = 'fade', fade_alpha = 0.1 }), 'fade 0.25 false', '10% is 25%')
	eq(items({ combat = true }, v{ items = true, combat = 'fade', fade_alpha = 0.6 }), 'fade 0.6 false', 'above the least it is the setting')
	eq(items({ combat = true }, v{ items = true, combat = 'fade', fade_alpha = 0 }, true), 'show 1 false', 'hovered: full')
	eq(items({ combat = true }, v{ items = true, combat = 'hide' }), 'hide 1 false', 'In combat Hide: the driver does it, in combat too')
	eq(items({ nocombat = true }, v{ items = true, nocombat = 'hide' }), 'hide 1 false', 'Out of combat Hide: the driver')
	eq(items({ boss = true }, v{ items = true, boss = 'hide' }), 'hide 1 true', 'Boss fights Hide: the driver in combat, directly out of it (boss1 may not exist)')
	eq(items({ instance = true }, v{ items = true, instance = 'hide' }), 'hide 1 true', 'In instances Hide: directly')
	eq(items({ mythic = true }, v{ items = true, mythic = 'hide' }), 'hide 1 true', 'Mythic+ Hide: directly')
	eq(items({ combat = true, instance = true }, v{ items = true, combat = 'hide', instance = 'show' }), 'hide 1 false', 'a Hide the driver does is not direct')
	eq(items({ mouseoff = true }, v{ items = true, mouseoff = 'fade', fade_alpha = 0 }), 'fade 0.25 false', 'Mouse off fades the buttons')
	eq(items({ mouseoff = true }, v{ items = true, mouseoff = 'hide' }), 'fade 0.3 false', 'and never hides them')
	-- The background.
	local function background(hovered, s) return R(applies({}), s, hovered).background end
	eq(background(false, v{}), true, 'the panel shows')
	eq(background(false, v{ background_hover = true }), false, 'Background under the mouse only: away, gone')
	eq(background(true, v{ background_hover = true }), true, 'under the mouse, there')
	eq(#take_errors(), 0, 'no errors')
end)

test('TR.Visibility.Applies: what the game says, read where the functions exist', function()
	local st, TR = world({})
	local A = TR.Visibility.Applies
	local function line(a)
		return ('%s %s %s %s %s %s'):format(tostring(a.combat), tostring(a.nocombat), tostring(a.mouseoff), tostring(a.instance), tostring(a.boss), tostring(a.mythic))
	end
	RW.mouse_on(TR.window)
	eq(line(A()), 'false true false false false false', 'out of combat, hovered, in the world')
	RW.mouse_off()
	eq(line(A()), 'false true true false false false', 'mouse off')
	TW.combat(true)
	eq(line(A()), 'true false true false false false', 'in combat')
	TW.combat(false)
	stub.instance = { name = 'Deadmines', type = 'party' }
	stub.encounter = true
	stub.probes.challenge = true
	eq(line(A()), 'false true true true true true', 'an instance, a boss fight, Mythic+')
	eq(line(A(true)), 'false true false true true true', 'hovered as it is told')
	stub.instance, stub.encounter, stub.probes.challenge = nil, false, false
	local real = C_ChallengeMode
	C_ChallengeMode = nil
	local real_encounter = IsEncounterInProgress
	IsEncounterInProgress = nil
	eq(line(A()), 'false true true false false false', 'a client without Mythic+ or the encounter call: no error, not applying')
	C_ChallengeMode, IsEncounterInProgress = real, real_encounter
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the window

both('each trigger by the game\'s own events: combat, instance, boss fight, Mythic+, out of combat', function(st, TR)
	-- In combat.
	set(TR, { combat = 'fade' })
	fade_done(TR)
	eq(TR.window:GetAlpha(), 1, 'out of combat: shown')
	TW.combat(true)
	fade_done(TR)
	check(near(TR.window:GetAlpha(), 0.3), 'in combat: faded to 30%: ' .. TR.window:GetAlpha())
	TW.combat(false)
	fade_done(TR)
	eq(TR.window:GetAlpha(), 1, 'combat over: back')
	-- Hide in combat hides the window in combat (it is not protected).
	set(TR, { combat = 'hide' })
	check(TR.window:IsShown(), 'out of combat: shown')
	TW.combat(true)
	check(not TR.window:IsShown(), 'in combat: hidden, in combat')
	TW.combat(false)
	check(TR.window:IsShown(), 'out of combat: back')
	set(TR, { combat = 'show' })
	-- Out of combat.
	set(TR, { nocombat = 'hide' })
	check(not TR.window:IsShown(), 'Out of combat Hide: hidden now')
	TW.combat(true)
	check(TR.window:IsShown(), 'shown in combat')
	TW.combat(false)
	check(not TR.window:IsShown(), 'hidden again')
	set(TR, { nocombat = 'show' })
	check(TR.window:IsShown(), 'and back when the setting is')
	-- In instances.
	set(TR, { instance = 'hide' })
	stub.instance = { name = 'Deadmines', type = 'party' }
	stub.fire_event('PLAYER_ENTERING_WORLD')
	check(not TR.window:IsShown(), 'in an instance: hidden')
	stub.instance = nil
	stub.fire_event('PLAYER_ENTERING_WORLD')
	check(TR.window:IsShown(), 'out of it: back')
	set(TR, { instance = 'show' })
	-- Boss fights.
	set(TR, { boss = 'fade' })
	stub.encounter = true
	stub.fire_event('ENCOUNTER_START', 1, 'Boss', 1, 5)
	fade_done(TR)
	check(near(TR.window:GetAlpha(), 0.3), 'a boss fight: faded')
	stub.fire_event('ENCOUNTER_END', 1, 'Boss', 1, 5, 1)
	-- (the game may still say the fight is in progress inside ENCOUNTER_END: the event rules)
	fade_done(TR)
	eq(TR.window:GetAlpha(), 1, 'the fight ends: back, whatever IsEncounterInProgress says at that moment')
	stub.encounter = false
	set(TR, { boss = 'show' })
	-- Mythic+.
	set(TR, { mythic = 'hide' })
	stub.probes.challenge = true
	stub.fire_event('CHALLENGE_MODE_START')
	check(not TR.window:IsShown(), 'a key: hidden')
	stub.probes.challenge = false
	stub.fire_event('CHALLENGE_MODE_COMPLETED')
	RW.later(0.1)
	check(TR.window:IsShown(), 'the key ends: back')
end)

both('combat starting: the game runs the handlers before lockdown, so the rules go by the event\'s word', function(st, TR)
	set(TR, { combat = 'hide' })
	check(TR.window:IsShown(), 'out of combat: shown')
	stub.fire_event('PLAYER_REGEN_DISABLED') -- stub.in_combat is still false, as in the game
	check(not TR.window:IsShown(), 'combat starts: hidden at once, before lockdown')
	stub.fire_event('PLAYER_REGEN_ENABLED')
	check(TR.window:IsShown(), 'and back when it ends')
	-- A loading screen forgets the events\' word: the game's own answers stand.
	stub.fire_event('PLAYER_REGEN_DISABLED')
	stub.fire_event('PLAYER_ENTERING_WORLD')
	check(TR.window:IsShown(), 'after a loading screen: not in combat by the game\'s answer')
end)

test('a /reload in combat with In combat Hide and the buttons on: the window is hidden at once, the layer and its driver are made when combat ends', function()
	local st, TR = world({ combat = true, visibility = { combat = 'hide', items = true } })
	check(not TR.window:IsShown(), 'hidden at once')
	check(TR.itemLayer == nil, 'no secure frame in combat')
	eq(#stub.blocked, 0, 'nothing blocked')
	TW.combat(false)
	RW.later(0.5)
	check(TR.window:IsShown(), 'combat over: shown')
	check(TR.itemLayer ~= nil, 'the layer is made')
	eq(layer_driver(TR), '[petbattle] hide; [combat] hide; show', 'with the driver the settings give')
	eq(items_shown(TR), 2, 'and the buttons')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

both('the panel under the mouse only: the panel by alpha, the text always', function(st, TR)
	set(TR, { background_hover = true })
	fade_done(TR)
	local backdrop = TR.window.backdrop
	check(backdrop ~= nil, 'the window has a panel')
	eq(backdrop:GetAlpha(), 0, 'away from the mouse the panel is gone')
	eq(TR.window:GetAlpha(), 1, 'the window is not faded')
	eq(TR.header.title:GetAlpha(), 1, 'the text is there')
	check(TR.header.title:IsVisible(), 'and shows')
	RW.mouse_on(TR.window)
	check(TR.fader:GetScript('OnUpdate') ~= nil, 'the mouse is watched while the setting is on')
	stub.fire_script(TR.fader, 'OnUpdate', 0.05)
	check(backdrop:GetAlpha() > 0, 'the mouse arrives: the panel comes back')
	fade_done(TR)
	eq(backdrop:GetAlpha(), 1, 'whole')
	RW.mouse_off()
	fade_done(TR)
	eq(backdrop:GetAlpha(), 0, 'the mouse leaves: gone')
	set(TR, { background_hover = false })
	fade_done(TR)
	eq(backdrop:GetAlpha(), 1, 'the setting off: the panel is always there')
	check(TR.fader:GetScript('OnUpdate') == nil, 'and nothing is watched')
end)

both('a faded-to-0 window takes no clicks and no wheel; the mouse brings it back; a hidden one is hidden', function(st, TR)
	log({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30 }, false)
	TR.config.height = 200
	TR:UpdateConfig()
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	local row = TR:GetQuestRow(1)
	check(row:IsMouseEnabled(), 'the row takes the mouse')
	check(TR.header.collapse:IsMouseEnabled() and TR.header:IsMouseEnabled(), 'and the header and its chevron')
	check(TR.window:IsMouseWheelEnabled() and TR.scroll:IsMouseWheelEnabled(), 'and the list the wheel (it scrolls)')
	set(TR, { mouseoff = 'fade', fade_alpha = 0 })
	fade_done(TR)
	eq(TR.window:GetAlpha(), 0, 'away: faded out')
	check(not row:IsMouseEnabled(), 'its rows take no mouse: a click goes through to the world')
	check(not TR.header:IsMouseEnabled() and not TR.header.collapse:IsMouseEnabled(), 'nor the header')
	check(not TR:GetQuestRow(30).slot:IsMouseEnabled(), 'nor a row\'s slot')
	check(not TR.window:IsMouseWheelEnabled() and not TR.scroll:IsMouseWheelEnabled(), 'and the wheel goes to the camera')
	-- A row made while faded takes none.
	log({ 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, 25, 26, 27, 28, 29, 30, 31 }, false)
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	check(TR:GetQuestRow(31) ~= nil and not TR:GetQuestRow(31):IsMouseEnabled(), 'a new row takes none either')
	-- The mouse over it: it comes back, input first (it can be clicked as it fades in).
	RW.mouse_on(TR.window)
	stub.fire_script(TR.fader, 'OnUpdate', 0.016)
	check(row:IsMouseEnabled() and TR.header:IsMouseEnabled(), 'the mouse arrives: it takes input again')
	check(TR.window:IsMouseWheelEnabled(), 'and the wheel')
	fade_done(TR)
	eq(TR.window:GetAlpha(), 1, 'and is shown')
	RW.mouse_off()
	fade_done(TR)
	check(not row:IsMouseEnabled(), 'gone again')
	-- A faded window that is not 0 stays clickable: it is visible.
	set(TR, { fade_alpha = 0.3 })
	fade_done(TR)
	check(row:IsMouseEnabled(), 'at 30% the rows are clickable')
	-- Hidden: hidden, and its mouse follows the frames.
	set(TR, { mouseoff = 'show', nocombat = 'hide' })
	check(not TR.window:IsShown(), 'hidden by Hide')
	check(not row:IsVisible(), 'and so are its rows')
	set(TR, { nocombat = 'show' })
	check(row:IsMouseEnabled() and TR.window:IsMouseWheelEnabled(), 'back: rows and wheel on')
end, { ids = { 1 } })

both('one throttle, no work while nothing changes: the fader runs only to move an alpha or to watch the mouse', function(st, TR)
	check(TR.fader == nil or TR.fader:GetScript('OnUpdate') == nil, 'default settings: nothing runs')
	set(TR, { combat = 'fade' })
	check(TR.fader:GetScript('OnUpdate') == nil, 'a trigger that does not apply and needs no mouse: nothing runs')
	set(TR, { mouseoff = 'fade' })
	check(TR.fader:GetScript('OnUpdate') ~= nil, 'Mouse off needs the mouse watched')
	fade_done(TR)
	set(TR, { mouseoff = 'show' })
	fade_done(TR)
	check(TR.fader:GetScript('OnUpdate') == nil, 'and stops when it does not')
	-- A fade takes FADE_TIME, from faded to full, alpha only.
	eq(TR.FADE_TIME, 0.2, 'FADE_TIME')
	set(TR, { combat = 'fade', fade_alpha = 0 })
	TW.combat(true)
	fade_done(TR)
	eq(TR.window:GetAlpha(), 0, 'faded out')
	TW.combat(false)
	check(TR.window:GetAlpha() == 0, 'the fade in has not moved yet')
	stub.fire_script(TR.fader, 'OnUpdate', 0.1)
	check(near(TR.window:GetAlpha(), 0.5), 'half way after half the time: ' .. TR.window:GetAlpha())
	stub.fire_script(TR.fader, 'OnUpdate', 0.1)
	check(near(TR.window:GetAlpha(), 1), 'full after FADE_TIME: ' .. TR.window:GetAlpha())
	check(TR.fader:GetScript('OnUpdate') == nil, 'and it stops')
	-- Setting the same thing again moves nothing.
	local sets = 0
	local methods = getmetatable(TR.window).__index
	local set_alpha = methods.SetAlpha
	methods.SetAlpha = function(self, ...) if self == TR.window then sets = sets + 1 end return set_alpha(self, ...) end
	for _ = 1, 20 do TR:ApplyVisibility() end
	methods.SetAlpha = set_alpha
	eq(sets, 0, 'twenty applies with nothing changed set no alpha')
end)

test('with the switch off nothing is made: no fader, no events, nothing applied', function()
	TW.counts.frames = 0
	local st, TR = TW.world({ on = false })
	check(TR.fader == nil, 'no fader')
	TR:ApplyVisibility()
	TR:UpdateConfig()
	check(TR.fader == nil and TR.visibility == nil, 'and none after an apply')
	eq(TW.counts.frames, 0, 'no frame made')
	eq(TW.counts.events, 0, 'no event registered')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the item buttons

both('Hide quest items off: the buttons keep full alpha whatever the window does, and hang where they were when it is hidden', function(st, TR)
	eq(items_shown(TR), 2, 'two buttons')
	local top = TR:GetItemButton(1).placedTop
	set(TR, { combat = 'fade', nocombat = 'fade', fade_alpha = 0 })
	fade_done(TR)
	eq(TR.window:GetAlpha(), 0, 'the window is faded out')
	eq(min_item_alpha(TR), 1, 'the buttons are not')
	check(TR:GetItemButton(1):IsShown(), 'and shown')
	set(TR, { nocombat = 'hide', combat = 'show' })
	check(not TR.window:IsShown(), 'the window is hidden')
	eq(items_shown(TR), 2, 'the buttons are not: quest items stay usable')
	eq(TR:GetItemButton(1).placedTop, top, 'where their rows were')
	eq(min_item_alpha(TR), 1, 'at full alpha')
	-- A refresh with the window hidden leaves them be.
	stub.fire_event('QUEST_LOG_UPDATE')
	RW.later(1)
	eq(items_shown(TR), 2, 'a refresh keeps them')
	eq(TR:GetItemButton(1).placedTop, top, 'in place')
	set(TR, { nocombat = 'show' })
	check(TR.window:IsShown(), 'the window is back')
	eq(items_shown(TR), 2, 'and the buttons follow its rows again')
	eq(layer_driver(TR), '[petbattle] hide; show', 'the layer\'s driver is only the pet battle\'s')
end)

both('Hide quest items on: Fade never under 25%, a button never invisible while it can be clicked', function(st, TR)
	set(TR, { items = true, nocombat = 'fade', fade_alpha = 0 })
	fade_done(TR)
	eq(TR.window:GetAlpha(), 0, 'the window is faded out')
	eq(min_item_alpha(TR), 0.25, 'its buttons are at 25%')
	for _, button in ipairs(TR.itemButtons) do
		if button:IsShown() then check(button:GetAlpha() >= TR.BUTTON_MIN_ALPHA, 'a shown button is never under 25%') end
	end
	set(TR, { fade_alpha = 0.6 })
	fade_done(TR)
	check(near(min_item_alpha(TR), 0.6), 'at the faded opacity above it: ' .. min_item_alpha(TR))
	-- A dimmed button (its row moved in combat) keeps the floor.
	TR:SetItemAlpha(TR:GetItemButton(1), TR.DIM_ALPHA)
	check(TR:GetItemButton(1):GetAlpha() >= TR.BUTTON_MIN_ALPHA, 'a dimmed button is not under 25% either')
	TR:SetItemAlpha(TR:GetItemButton(1), 1)
	RW.mouse_on(TR.window)
	stub.fire_script(TR.fader, 'OnUpdate', 0.016)
	fade_done(TR)
	eq(min_item_alpha(TR), 1, 'the mouse over the tracker: the buttons come back with it')
	RW.mouse_off()
	fade_done(TR)
	check(near(min_item_alpha(TR), 0.6), 'and fade again')
end)

both('Hide quest items on: the driver by the settings, set out of combat; in combat it waits with nothing blocked', function(st, TR)
	eq(layer_driver(TR), '[petbattle] hide; show', 'to start with')
	set(TR, { items = true, combat = 'hide' })
	eq(layer_driver(TR), '[petbattle] hide; [combat] hide; show', 'In combat Hide with the buttons on')
	set(TR, { nocombat = 'hide', boss = 'hide' })
	eq(layer_driver(TR), '[petbattle] hide; [combat] hide; [nocombat] hide; [@boss1,exists] hide; show', 'all three')
	set(TR, { combat = 'show', nocombat = 'show', boss = 'show' })
	eq(layer_driver(TR), '[petbattle] hide; show', 'and back')
	-- A change made in combat is queued, as 'tracker_items'.
	TW.combat(true)
	set(TR, { combat = 'hide' })
	eq(layer_driver(TR), '[petbattle] hide; show', 'in combat the driver is not touched')
	eq(#stub.blocked, 0, 'nothing is blocked: no state driver is registered in combat')
	TW.combat(false)
	RW.later(0.1)
	eq(layer_driver(TR), '[petbattle] hide; [combat] hide; show', 'the end of combat sets it')
	set(TR, { items = false })
	eq(layer_driver(TR), '[petbattle] hide; show', 'Hide quest items off: the buttons are the pet battle\'s alone again')
end)

both('Hide quest items on, In instances and Mythic+ Hide: the buttons are hidden directly, out of combat; in combat they wait', function(st, TR)
	set(TR, { items = true, instance = 'hide', mythic = 'hide' })
	eq(items_shown(TR), 2, 'shown to start with')
	stub.instance = { name = 'Deadmines', type = 'party' }
	stub.fire_event('PLAYER_ENTERING_WORLD')
	check(not TR.window:IsShown(), 'the window is hidden')
	eq(items_shown(TR), 0, 'and the buttons, by Hide')
	stub.instance = nil
	stub.fire_event('PLAYER_ENTERING_WORLD')
	RW.later(0.2)
	check(TR.window:IsShown(), 'out: the window')
	eq(items_shown(TR), 2, 'and the buttons are back')
	-- Mythic+ starting in combat (a game that starts it so): the window goes, the buttons wait.
	TW.combat(true)
	stub.probes.challenge = true
	stub.fire_event('CHALLENGE_MODE_START')
	check(not TR.window:IsShown(), 'in combat: the window is hidden')
	eq(items_shown(TR), 2, 'but the buttons can\'t be hidden in combat: still there, not invisible')
	check(min_item_alpha(TR) >= TR.BUTTON_MIN_ALPHA, 'at 25% or more')
	TW.combat(false)
	RW.later(0.2)
	eq(items_shown(TR), 0, 'combat over: hidden')
	stub.probes.challenge = false
	stub.fire_event('CHALLENGE_MODE_COMPLETED')
	RW.later(0.2)
	eq(items_shown(TR), 2, 'and back when it ends')
end)

both('the nearest button is an action button: no trigger, no Hide quest items and no fade touch it; a pet battle hides it by its driver', function(st, TR)
	local button = TR.nearestButton
	check(button ~= nil and button:IsShown(), 'the nearest button shows')
	local driver = stub.state(TR.nearestDriver).state_drivers['state-visibility']
	eq(driver, '[petbattle] hide; show', 'its driver is the pet battle\'s')
	set(TR, { items = true, combat = 'hide', nocombat = 'fade', instance = 'hide', boss = 'hide', mythic = 'hide', mouseoff = 'fade', fade_alpha = 0 })
	fade_done(TR)
	check(button:IsShown(), 'out of combat under Out of combat Fade: shown')
	eq(button:GetAlpha(), 1, 'at full alpha')
	eq(stub.state(TR.nearestDriver).state_drivers['state-visibility'], driver, 'its driver is the same')
	TW.combat(true)
	check(button:IsShown() and button:GetAlpha() == 1, 'in combat under In combat Hide: shown')
	TW.combat(false)
	stub.instance = { name = 'Deadmines', type = 'party' }
	stub.fire_event('PLAYER_ENTERING_WORLD')
	check(button:IsShown() and button:GetAlpha() == 1, 'in an instance under Hide: shown')
	stub.encounter = true
	stub.fire_event('ENCOUNTER_START')
	stub.probes.challenge = true
	stub.fire_event('CHALLENGE_MODE_START')
	RW.later(0.5)
	check(button:IsShown() and button:GetAlpha() == 1, 'in a boss fight and a key: shown')
	eq(stub.state(TR.nearestDriver).state_drivers['state-visibility'], driver, 'its driver never changed')
	eq(stub.state(TR.itemLayer).state_drivers['state-visibility'], '[petbattle] hide; [combat] hide; [@boss1,exists] hide; show', 'the layer\'s did')
	eq(TR.NearestDriver(), '[petbattle] hide; show', 'the nearest driver is the constant\'s pet battle part alone')
	-- Replacing the constant: the nearest driver keeps its pet battle part, set out of combat.
	local real = TR.ITEM_DRIVER
	TR.ITEM_DRIVER = '[petbattle] hide; [vehicleui] hide; show'
	eq(TR.NearestDriver(), '[petbattle] hide; show', 'only the pet battle part of it')
	TR.ITEM_DRIVER = real
end, { nearest = true })

------------------------------------------------------------------ Blizzard's tracker

both('during a handover Hide conceals Blizzard\'s tracker and Fade holds its alpha, put back after Blizzard\'s own', function(st, TR, OT)
	scenario(true)
	settle_probes()
	eq(TR.handoverState, 'blizzard', 'handed over, in SaftUI\'s place')
	check(OT.tracker:GetRight() > UIParent:GetLeft(), 'Blizzard\'s tracker shows')
	eq(OT.tracker:GetAlpha(), 1, 'at full alpha')
	-- Fade.
	set(TR, { mouseoff = 'fade', fade_alpha = 0.4 })
	fade_done(TR)
	check(near(OT.tracker:GetAlpha(), 0.4), 'faded to 40%: ' .. OT.tracker:GetAlpha())
	-- Blizzard's own call (the right column fades its frames in and out) is put back.
	OT.tracker:SetAlpha(1)
	check(near(OT.tracker:GetAlpha(), 0.4), 'Blizzard\'s SetAlpha(1) is put back after it: ' .. OT.tracker:GetAlpha())
	OT.tracker:SetAlpha(0)
	check(near(OT.tracker:GetAlpha(), 0.4), 'and its 0')
	-- Hover is read from SaftUI's holder, never Blizzard's frame.
	RW.mouse_on(TR.holder)
	stub.fire_script(TR.fader, 'OnUpdate', 0.016)
	fade_done(TR)
	eq(OT.tracker:GetAlpha(), 1, 'the mouse over its place: full')
	OT.tracker:SetAlpha(0.5)
	eq(OT.tracker:GetAlpha(), 0.5, 'while shown Blizzard\'s own alpha stands')
	RW.mouse_off()
	fade_done(TR)
	check(near(OT.tracker:GetAlpha(), 0.4), 'the mouse leaves: faded again')
	-- Hide conceals it.
	set(TR, { mouseoff = 'show', nocombat = 'hide' })
	check(near(OT.tracker:GetRight(), UIParent:GetLeft() - 100), 'Hide: concealed, 100 left of the screen')
	eq(OT.tracker:IsClampedToScreen(), false, 'the clamp is off')
	check(OT.tracker:IsShown(), 'never hidden')
	eq(TR.handoverState, 'blizzard', 'the handover state is still its own')
	check(not TR.window:IsShown(), 'SaftUI\'s window stays away: one place decides')
	set(TR, { nocombat = 'show' })
	check(near(OT.tracker:GetRight(), TR.holder:GetRight()), 'the trigger ends: back in SaftUI\'s place')
	check(not TR.window:IsShown(), 'with the window still hidden by the handover')
	eq(OT.tracker:GetAlpha(), 1, 'at full alpha')
	-- It never took Show, Hide, SetShown or SetScale.
	eq(OT.calls.Show + OT.calls.Hide + OT.calls.SetShown + OT.calls.SetScale, 0, 'Show, Hide, SetShown and SetScale never called on it')
	eq(table.concat(OT.stray, ','), '', 'no state-writing method')
end, { blizzard = true })

both('a concealed Blizzard tracker is never given an alpha; it comes back at the alpha the trigger gives', function(st, TR, OT)
	set(TR, { nocombat = 'fade', fade_alpha = 0.3 })
	fade_done(TR)
	eq(OT.tracker:GetAlpha(), 1, 'in SaftUI\'s own state it is off screen and untouched')
	scenario(true)
	settle_probes()
	fade_done(TR)
	check(near(OT.tracker:GetAlpha(), 0.3), 'revealed: faded')
	scenario(false)
	settle_probes(TR.HOLD + 1)
	eq(TR.handoverState, 'own', 'the need is over')
	check(near(OT.tracker:GetRight(), UIParent:GetLeft() - 100), 'concealed')
	check(TR.window:IsShown(), 'SaftUI\'s window is back')
	set(TR, { nocombat = 'show' })
	fade_done(TR)
	scenario(true)
	settle_probes()
	eq(OT.tracker:GetAlpha(), 1, 'the next reveal is at full alpha: the hold was released')
end, { blizzard = true })

both('beside SaftUI\'s: hover is read from the beside spot\'s numbers', function(st, TR, OT)
	set(TR, { mouseoff = 'fade', fade_alpha = 0.2 })
	scenario(true)
	settle_probes()
	eq(TR.handoverState, 'both', 'beside')
	check(TR.window:IsShown(), 'SaftUI\'s window shows as well')
	fade_done(TR)
	check(near(OT.tracker:GetAlpha(), 0.2) and near(TR.window:GetAlpha(), 0.2), 'both faded')
	-- The mouse over Blizzard's tracker's spot (the numbers, never its frame).
	RW.mouse_on(OT.tracker)
	stub.fire_script(TR.fader, 'OnUpdate', 0.016)
	fade_done(TR)
	eq(OT.tracker:GetAlpha(), 1, 'over its spot: Blizzard\'s is full')
	eq(TR.window:GetAlpha(), 1, 'and SaftUI\'s with it')
	RW.mouse_off()
	fade_done(TR)
	check(near(OT.tracker:GetAlpha(), 0.2), 'away: faded')
	-- Hide: both go.
	set(TR, { mouseoff = 'show', nocombat = 'hide' })
	check(not TR.window:IsShown(), 'the window is hidden')
	check(near(OT.tracker:GetRight(), UIParent:GetLeft() - 100), 'and Blizzard\'s is concealed')
end, { blizzard = true, mode = 'beside' })

------------------------------------------------------------------ the options

test('the Visibility tab: the six triggers, Mythic+ only where the client has it, the five options', function()
	local TWO = load_test_file('tracker/tracker_world.lua')
	load_test_file('lib/options_walk.lua')
	for _, with in ipairs({ true, false }) do
		local st, TR = TWO.world({ on = true })
		load_saftui('SaftUI-Core/Config/optionsmodel.lua')
		load_options_widgets()
		local real = C_ChallengeMode
		if not with then C_ChallengeMode = nil end
		local page = TR:GetConfigTable()
		local tab = page.args.visibility
		eq(tab.name, 'Visibility', 'named')
		eq(tab.order, 4, 'fourth')
		local args = tab.args
		local order = { 'combat', 'nocombat', 'mouseoff', 'instance', 'boss', 'mythic' }
		for index, key in ipairs(order) do
			local option = args[key]
			check(option ~= nil and option.type == 'select', key .. ' is a select')
			if option then
				eq(option.order, index, key .. "'s place")
				if key == 'mouseoff' then
					eq(table.concat(option.sorting, ','), 'show,fade', 'Mouse off is Show or Fade')
				else
					eq(table.concat(option.sorting, ','), 'show,fade,hide', key .. ' is Show, Fade or Hide')
				end
				check(type(option.default) == 'table', key .. ' resets itself')
			end
		end
		local hidden = args.mythic.hidden
		eq(type(hidden) == 'function' and hidden() or false, not with, 'Mythic+ is hidden where the function is missing (' .. tostring(with) .. ')')
		eq(args.fade_alpha.type, 'range', 'faded opacity')
		eq(args.fade_alpha.isPercent, true, 'in percent')
		eq(args.hover.type, 'toggle', 'Show fully under the mouse')
		eq(args.background_hover.type, 'toggle', 'Background under the mouse only')
		eq(args.scrollbar_hover.type, 'toggle', 'Scroll bar under the mouse only')
		eq(args.items.type, 'toggle', 'Hide quest items with the tracker')
		eq(args.items.name, 'Hide quest items with the tracker', 'named')
		-- The sentence-case names.
		eq(args.combat.name, 'In combat', 'sentence case')
		eq(args.nocombat.name, 'Out of combat')
		eq(args.mouseoff.name, 'Mouse off')
		eq(args.instance.name, 'In instances')
		eq(args.boss.name, 'Boss fights')
		eq(args.mythic.name, 'Mythic+')
		-- A change saves and applies.
		tab.set({ 'visibility', 'combat' }, 'fade')
		eq(TR.config.visibility.combat, 'fade', 'saved')
		eq(tab.get({ 'visibility', 'combat' }), 'fade', 'and read back')
		args.fade_alpha.default.reset()
		eq(TR.config.visibility.fade_alpha, 0.3, 'a reset')
		C_ChallengeMode = real
		eq(#take_errors(), 0, 'no errors')
	end
end)
