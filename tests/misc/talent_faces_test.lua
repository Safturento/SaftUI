-- SaftUI-Misc/Skinning/blizzard/Blizzard_TalentFaces.lua: a SaftUI face on every
-- talent button (and, while a plan source gives displays, a Blizzard-art face
-- under the Blizzard look):
--   - a face per button, in SaftUI's border, over the button, never taking the
--     mouse; the icon, the rank and the colors of the button's real state;
--   - Blizzard's numbers faded by alpha and put back (skin off, Theme Blizzard,
--     planning off, window hidden), and nothing else of Blizzard's written;
--   - hooks that only queue a draw, once per button; a re-bound or released
--     button; a choice node with no face;
--   - the plan source driving the face (the planned count, the real rank faded,
--     the simulated state);
--   - hover, combat (no face made), retail (nothing hooked).
-- Real: Core's helpers and theme engine, Misc's config.lua, the Skinning module
-- and the talent window skin (whose IsActive the look follows), the faces module.
-- Blizzard's window and buttons are fixtures/player_spells_frame.lua's build
-- (every frame and region locked: a field written onto one fails the case).
local T = load_test_file('lib/theme_helpers.lua')
local SH = load_test_file('misc/fixtures/talentplan_shaman.lua')
local PSF = load_test_file('misc/fixtures/player_spells_frame.lua')

local st, SK, TF, profile

local function J(list) return table.concat(list, ',') end

-- A fresh world on client: Blizzard's talent window (the shaman's tree) built,
-- the skin and the faces module loaded and enabled with the addon already loaded.
local function world(opts)
	opts = opts or {}
	st = T.client(opts.client or 'forever')
	stub.class, stub.level = 'SHAMAN', 27
	st.config.global, st.config.char = {}, {}
	_G.PlayerSpellsFrame = nil
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	profile.skinning.theme = 'thick'
	if opts.off then profile.skinning.talent_window = false end
	SH.install()
	PSF.build()
	stub.installed_addons.Blizzard_PlayerSpells = true
	stub.loaded_addons.Blizzard_PlayerSpells = true
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsSkin.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_TalentFaces.lua')
	SK = st:GetModule('Skinning')
	TF = st:GetModule('TalentFaces')
	if opts.before then opts.before() end
	SK:Enable()
	TF:Enable()
end

-- Skinning's Theme, as its page sets it.
local function look(theme)
	profile.skinning.theme = theme
	SK:UpdateConfig()
end

local function open()
	PSF.open()
	stub.run_timers()
end

local function shown(button)
	local rec = TF.faces[button]
	return rec ~= nil and rec.face:IsShown()
end

local function clean()
	eq(#take_errors(), 0, 'no errors')
	eq(#stub.traits.calls, 0, 'nothing bought, refunded or committed')
end

-- Every region of a button Blizzard's alpha the faces may fade.
local function fadeable(button)
	local out = { button.SpendText, button.Shadow, button.SelectableIcon }
	for _, shadow in ipairs(button.spendTextShadows) do out[#out + 1] = shadow end
	return out
end

local function rgb(r, g, b) return ('%.2f,%.2f,%.2f'):format(r, g, b) end

test('the state table, the paint and the Blizzard art are the spec\'s', function()
	world()
	eq(TF.STATE[1], 'partial')
	eq(TF.STATE[2], 'gated')
	eq(TF.STATE[3], 'disabled')
	eq(TF.STATE[4], 'locked')
	eq(TF.STATE[5], 'selectable')
	eq(TF.STATE[6], 'maxed')
	eq(TF.STATE[7], nil, 'Invisible hides')
	eq(TF.STATE[8], 'error')
	eq(TF.STATE[9], 'error')
	local gated, locked, disabled = TF.Paint('gated'), TF.Paint('locked'), TF.Paint('disabled')
	eq(gated.overlay, 0.7)
	eq(locked.overlay, 0.25)
	eq(disabled.overlay, 0.25)
	check(gated.desaturate and locked.desaturate and disabled.desaturate, 'dimmed states are grey')
	eq(gated.border, nil, 'the theme\'s own border')
	eq(J(gated.text), 'text,muted')
	eq(J(TF.Paint('selectable').border), 'text,success')
	eq(J(TF.Paint('selectable').text), 'text,success')
	eq(TF.Paint('selectable').overlay, nil)
	eq(J(TF.Paint('partial').border), 'text,caution')
	eq(TF.Paint('maxed').border, 'accent')
	eq(J(TF.Paint('maxed').text), 'text,caution')
	local err = TF.Paint('error')
	eq(err.overlay, 0.3)
	check(err.red and not err.desaturate, 'tinted red, not grey')
	eq(J(err.border), 'text,danger')
	eq(TF.Paint('hidden'), nil)
	eq(TF.BlizzardArt('selectable'), 'selectable')
	eq(TF.BlizzardArt('partial'), 'normal')
	eq(TF.BlizzardArt('maxed'), 'maxed')
	eq(TF.BlizzardArt('gated'), 'locked')
	eq(TF.BlizzardArt('locked'), 'disabled')
	eq(TF.BlizzardArt('disabled'), 'disabled')
	eq(TF.BlizzardArt('error'), 'displayError')
end)

test('a face per button, in SaftUI\'s border', function()
	world()
	open()
	check(#PSF.buttons >= 23, 'the tree has its buttons')
	for _, b in ipairs(PSF.buttons) do
		local r = TF.faces[b]
		check(r, 'a face')
		check(r.face:IsShown(), 'shown')
		eq(J({ r.face:GetRect() }), J({ b:GetRect() }), 'the button\'s rect')
		eq(r.face:GetFrameLevel(), b:GetFrameLevel() + 2)
		check(not r.face:IsMouseEnabled(), 'takes no mouse')
		eq(r.icon:GetTexture(), b.Icon:GetTexture(), 'the button\'s icon')
		eq(st:DrawnKind(r.face), 'action', 'drawn as an action button')
		eq(r.nodeID, b:GetNodeID())
	end
	eq(TF:Look(), 'saftui')
	clean()
end)

test('the real state, as Blizzard\'s button says', function()
	world()
	open()
	local b = PSF.buttons[1]
	local r = TF.faces[b]
	PSF.set_state(b, 2, '')
	stub.run_timers()
	check(r.overlay:IsShown(), 'the overlay shows')
	eq(r.overlay:GetAlpha(), 0.7)
	check(r.icon:IsDesaturated(), 'grey')
	PSF.set_state(b, 5, '0')
	stub.run_timers()
	eq(r.rank:GetText(), '0')
	local sr, sg, sb = st:Color('text', 'success'):GetRGB()
	eq(rgb(r.rank:GetTextColor()), rgb(sr, sg, sb), 'Text > Success')
	check(not r.overlay:IsShown(), 'no overlay')
	check(not r.icon:IsDesaturated(), 'in color')
	PSF.set_state(b, 6, '1')
	stub.run_timers()
	local ar, ag, ab = st:Color('accent'):GetRGB()
	eq(rgb(r.face:GetBackdropBorderColor()), rgb(ar, ag, ab), 'the Accent border')
	PSF.set_state(b, 8, '1')
	stub.run_timers()
	eq(r.overlay:GetAlpha(), 0.3)
	local vr, vg, vb = r.icon:GetVertexColor()
	check(vr > vg and vr > vb, 'tinted red')
	PSF.set_state(b, 7, '')
	stub.run_timers()
	check(not r.face:IsShown(), 'Invisible hides the face')
	clean()
end)

test('Blizzard\'s numbers are faded, and put back', function()
	world()
	-- an alpha of Blizzard's own, to see it kept
	local b = PSF.buttons[1]
	b.SpendText:SetAlpha(0.8)
	open()
	for _, button in ipairs(PSF.buttons) do
		for _, region in ipairs(fadeable(button)) do eq(region:GetAlpha(), 0, 'faded under a face') end
		eq(button:GetAlpha(), 1, 'the button itself untouched')
		eq(button.StateBorderHover:GetAlpha(), 1, 'the hover border untouched')
	end
	PSF.set_state(b, 2, '')
	stub.run_timers()
	eq(b.DisabledOverlay:GetAlpha(), 0.7,'Blizzard\'s overlay is Blizzard\'s')
	-- the skin off: the next look change puts every alpha back
	profile.skinning.talent_window = false
	SK:UpdateConfig()
	stub.run_timers()
	eq(b.SpendText:GetAlpha(), 0.8, 'the alpha Blizzard had')
	for _, button in ipairs(PSF.buttons) do
		if button ~= b then
			for _, region in ipairs(fadeable(button)) do eq(region:GetAlpha(), 1, 'put back') end
		end
		check(not shown(button), 'no face')
	end
	-- the Blizzard theme
	profile.skinning.talent_window = true
	look('thick')
	stub.run_timers()
	check(shown(PSF.buttons[2]), 'on again')
	look('blizzard')
	stub.run_timers()
	for _, button in ipairs(PSF.buttons) do
		check(not shown(button), 'no face under Blizzard')
		for _, region in ipairs(fadeable(button)) do
			if button ~= b then eq(region:GetAlpha(), 1, 'put back under Blizzard') end
		end
	end
	-- the window hidden
	look('thick')
	stub.run_timers()
	check(shown(PSF.buttons[2]), 'on again')
	PSF.talents:Hide()
	stub.run_timers()
	for _, button in ipairs(PSF.buttons) do
		check(not shown(button), 'hidden with the window')
		if button ~= b then
			for _, region in ipairs(fadeable(button)) do eq(region:GetAlpha(), 1, 'put back on hide') end
		end
	end
	clean()
end)

test('a hook only queues, and each button is hooked once', function()
	world()
	local hooks = {}
	local real = hooksecurefunc
	_G.hooksecurefunc = function(target, name, fn)
		if type(target) == 'table' then
			local key = tostring(target) .. ':' .. name
			hooks[key] = (hooks[key] or 0) + 1
		end
		return real(target, name, fn)
	end
	open()
	TF:Draw()
	TF:Draw()
	_G.hooksecurefunc = real
	local b = PSF.buttons[1]
	for _, name in ipairs({ 'ApplyVisualState', 'UpdateSpendText' }) do
		eq(hooks[tostring(b) .. ':' .. name], 1, name .. ' hooked once')
	end
	local r = TF.faces[b]
	check(not r.overlay:IsShown())
	b:ApplyVisualState(4)
	check(not r.overlay:IsShown(), 'nothing drawn inside Blizzard\'s call')
	stub.run_timers()
	check(r.overlay:IsShown(), 'drawn on the next frame')
	eq(r.overlay:GetAlpha(), 0.25, 'locked')
	clean()
end)

test('faces follow a re-bound button, and a released one shows none', function()
	world()
	open()
	local b = PSF.buttons[1]
	PSF.rebind(b, 424242)
	b.Icon:SetTexture(777)
	PSF.redraw()
	stub.run_timers()
	local r = TF.faces[b]
	eq(r.nodeID, 424242, 'the new node')
	eq(r.icon:GetTexture(), 777, 'the new node\'s icon')
	-- a choice node (Enum.TraitNodeType.Selection) has no face
	rawset(b, '_nodeType', 2)
	PSF.redraw()
	stub.run_timers()
	check(not shown(b), 'no face on a choice node')
	for _, region in ipairs(fadeable(b)) do eq(region:GetAlpha(), 1, 'its numbers are Blizzard\'s') end
	rawset(b, '_nodeType', 0)
	PSF.redraw()
	stub.run_timers()
	check(shown(b), 'and a face again on a plain node')
	-- released: the pool no longer hands it out
	table.remove(PSF.buttons, 1)
	PSF.redraw()
	stub.run_timers()
	check(not shown(b), 'a released button shows none')
	for _, region in ipairs(fadeable(b)) do eq(region:GetAlpha(), 1, 'put back') end
	clean()
end)

test('the plan source drives the face', function()
	world()
	open()
	local b = PSF.buttons[1]
	local r = TF.faces[b]
	PSF.set_state(b, 5, '3')
	stub.run_timers()
	eq(r.rank:GetAlpha(), 1)
	TF:SetPlanSource(function() return { state = 'gated', planned = 2 } end)
	stub.run_timers()
	eq(TF:Look(), 'saftui')
	check(r.planned:IsShown(), 'the planned count shows')
	eq(r.planned:GetText(), '2')
	local point, relative = r.planned:GetPoint(1)
	eq(point, 'TOPLEFT')
	eq(relative, r.face, 'in the face\'s top left corner')
	eq(r.rank:GetText(), '3', 'the real rank stays')
	eq(r.rank:GetAlpha(), 0.3, 'faded')
	eq(r.overlay:GetAlpha(), 0.7, 'the simulated state\'s dim')
	check(r.icon:IsDesaturated(), 'and its grey')
	-- a node the source doesn't know shows its real state
	TF:SetPlanSource(function(id) if id ~= b:GetNodeID() then return { state = 'locked', planned = 0 } end end)
	stub.run_timers()
	check(not r.planned:IsShown(), 'no planned count')
	eq(r.rank:GetAlpha(), 1)
	check(not r.overlay:IsShown(), 'the real state: selectable')
	local other = TF.faces[PSF.buttons[2]]
	eq(other.overlay:GetAlpha(), 0.25, 'another node: the simulated state')
	check(not other.planned:IsShown(), 'a planned 0 on a locked node shows no number')
	-- no source: the real state again
	TF:SetPlanSource(nil)
	stub.run_timers()
	check(not other.overlay:IsShown())
	check(not other.planned:IsShown())
	clean()
end)

test('a Blizzard-art face while planning only', function()
	world()
	look('blizzard')
	open()
	local b = PSF.buttons[1]
	check(not shown(b), 'no face under the Blizzard look, not planning')
	eq(TF:Look(), nil)
	for _, region in ipairs(fadeable(b)) do eq(region:GetAlpha(), 1) end
	b.IconMask:Show()
	b.IconMask:SetAtlas('talents-node-circle-mask')
	TF:SetPlanSource(function() return { state = 'selectable', planned = 1 } end)
	stub.run_timers()
	eq(TF:Look(), 'blizzard')
	local r = TF.faces[b]
	check(r and r.face:IsShown(), 'a face')
	check(r.art:IsShown(), 'with the state border')
	eq(r.art:GetAtlas(), b.artSet.selectable)
	local _, relative = r.art:GetPoint(1)
	eq(relative, b.StateBorder, 'anchored to Blizzard\'s border')
	eq(r.mask:GetAtlas(), 'talents-node-circle-mask', 'the button\'s mask')
	check(r.icon:GetNumMaskTextures() == 1, 'on the icon')
	eq(r.icon:GetTexture(), b.Icon:GetTexture())
	eq(r.planned:GetText(), '1')
	for _, region in ipairs(fadeable(b)) do eq(region:GetAlpha(), 0, 'Blizzard\'s numbers faded') end
	TF:SetPlanSource(function() return { state = 'partial', planned = 1 } end)
	stub.run_timers()
	eq(r.art:GetAtlas(), b.artSet.normal)
	-- cleared: gone, and the fades back
	TF:SetPlanSource(nil)
	stub.run_timers()
	check(not shown(b), 'no face')
	eq(TF:Look(), nil)
	for _, region in ipairs(fadeable(b)) do eq(region:GetAlpha(), 1, 'put back') end
	clean()
end)

test('hover', function()
	world()
	open()
	local b = PSF.buttons[1]
	local r = TF.faces[b]
	eq(st:GetState(r.face, 'hover'), false)
	stub.fire_script(b, 'OnEnter')
	eq(st:GetState(r.face, 'hover'), true, 'the button\'s OnEnter')
	stub.fire_script(b, 'OnLeave')
	eq(st:GetState(r.face, 'hover'), false, 'its OnLeave')
	TF:Hover(b:GetNodeID(), true)
	eq(st:GetState(r.face, 'hover'), true, 'TF:Hover')
	TF:Hover(b:GetNodeID(), false)
	eq(st:GetState(r.face, 'hover'), false)
	TF:Hover(nil, true)
	clean()
end)

test('no face is made in combat, an existing one still updates', function()
	world()
	stub.in_combat = true
	open()
	for _, b in ipairs(PSF.buttons) do check(not shown(b), 'none made in combat') end
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	stub.run_timers()
	for _, b in ipairs(PSF.buttons) do check(shown(b), 'made after combat') end
	stub.in_combat = true
	local b = PSF.buttons[1]
	PSF.set_state(b, 4, '')
	stub.run_timers()
	eq(TF.faces[b].overlay:GetAlpha(), 0.25, 'an existing face updates in combat')
	stub.in_combat = false
	clean()
end)

test('nothing on retail', function()
	local hooks, registered = 0, 0
	local real = hooksecurefunc
	world({ client = 'retail', before = function()
		_G.hooksecurefunc = function(...) hooks = hooks + 1; return real(...) end
		local register = EventRegistry.RegisterCallback
		EventRegistry.RegisterCallback = function(...) registered = registered + 1; return register(...) end
	end })
	open()
	_G.hooksecurefunc = real
	eq(hooks, 0, 'no hooks')
	eq(registered, 0, 'no callbacks')
	check(next(TF.faces) == nil, 'no faces')
	for _, b in ipairs(PSF.buttons) do
		for _, region in ipairs(fadeable(b)) do eq(region:GetAlpha(), 1, 'untouched') end
	end
end)

test('an Invisible button has no face, even in planning', function()
	world()
	open()
	local b = PSF.buttons[1]
	TF:SetPlanSource(function() return { state = 'selectable', planned = 1 } end)
	stub.run_timers()
	check(shown(b), 'a face with a display')
	PSF.set_state(b, 7, '')
	stub.run_timers()
	check(not shown(b), 'Invisible wins over the plan')
	for _, region in ipairs(fadeable(b)) do eq(region:GetAlpha(), 1, 'put back') end
	clean()
end)

test('a released button\'s face and fades go at once', function()
	world()
	open()
	local b = PSF.buttons[1]
	check(shown(b))
	PSF.talents:ReleaseTalentButton(b)
	check(not shown(b), 'hidden by the post-hook, no timer')
	for _, region in ipairs(fadeable(b)) do eq(region:GetAlpha(), 1, 'put back') end
	clean()
end)

test('the mask goes on once, and on the hover piece too', function()
	world()
	look('blizzard')
	open()
	local b = PSF.buttons[1]
	b.IconMask:Show()
	b.IconMask:SetAtlas('talents-node-circle-mask')
	TF:SetPlanSource(function() return { state = 'selectable', planned = 1 } end)
	stub.run_timers()
	TF:Draw()
	local r = TF.faces[b]
	eq(r.icon:GetNumMaskTextures(), 1)
	eq(r.overlay:GetNumMaskTextures(), 1)
	eq(r.hover:GetNumMaskTextures(), 1, 'the hover is cut round too')
	clean()
end)

test('nothing is made or drawn in combat, and retail never draws', function()
	world()
	open()
	local drawn = 0
	local template, restyle = st.SetTemplate, st.RestyleStates
	st.SetTemplate = function(...) drawn = drawn + 1; return template(...) end
	st.RestyleStates = function(...) drawn = drawn + 1; return restyle(...) end
	stub.in_combat = true
	PSF.set_state(PSF.buttons[1], 4, '')
	stub.run_timers()
	eq(drawn, 0, 'no backdrop and no states in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	stub.run_timers()
	check(drawn > 0, 'drawn after combat')
	st.SetTemplate, st.RestyleStates = template, restyle

	world({ client = 'retail' })
	TF:Draw()
	TF:Queue()
	stub.run_timers()
	check(next(TF.faces) == nil, 'no faces on retail')
end)
