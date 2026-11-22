-- SaftUI-Misc/TalentPlan/overlays.lua: the light, glow, dim and catcher over
-- Blizzard's talent buttons, and planning by clicking. The world is the panel
-- test's (see it for what is real and what is made by hand).
--
-- Real: Misc's TalentPlan files, Core's helpers and theme engine, the options
-- window's dialogs (Confirm and Prompt), movable.lua (so the window's own
-- OnMouseUp hook is there when the panel docks). Made by hand: Blizzard's talent
-- window (misc/fixtures/player_spells_frame.lua, every frame locked, so a
-- field or a SetScript written onto one fails), the trait stubs
-- (tests/wow/traits.lua, filled by the shaman fixture), the game's menu
-- (MenuUtil, which records the generator's items so a test chooses them) and
-- ScrollFrameTemplate's scroll bar (as tests/bags/scrollframe_test.lua).
local T = load_test_file('lib/theme_helpers.lua')
local SH = load_test_file('misc/fixtures/talentplan_shaman.lua')
local PSF = load_test_file('misc/fixtures/player_spells_frame.lua')
local GUIDE = read_test_source('misc/fixtures/talentplan_guide_enhancement.txt')

local st, TP, S, M, W
local opened

-- The game's menu: CreateContextMenu(owner, generator) calls the generator
-- with a root; its items are kept in order in opened[i] = { owner, list }.
local function menu_stand_in()
	opened = {}
	_G.MenuUtil = {
		CreateContextMenu = function(owner, generator)
			local root = { owner = owner, list = {} }
			local function add(kind, text, a, b)
				local item = { kind = kind, text = text, a = a, b = b }
				root.list[#root.list + 1] = item
				return item
			end
			local description = {}
			function description:CreateButton(text, onClick) return add('button', text, onClick) end
			function description:CreateRadio(text, isSelected, setSelected) return add('radio', text, isSelected, setSelected) end
			function description:CreateDivider() return add('divider') end
			generator(owner, description)
			opened[#opened + 1] = root
			return root
		end,
	}
end

local function item(root, text)
	for _, entry in ipairs(root.list) do
		if entry.text == text then return entry end
	end
	error('no menu item ' .. text, 2)
end

local function texts(root)
	local out = {}
	for i, entry in ipairs(root.list) do out[i] = entry.kind == 'divider' and '-' or entry.text end
	return table.concat(out, '|')
end

local function choose(entry)
	if entry.kind == 'radio' then entry.b() else entry.a() end
end

-- A fresh world: the forever client with Core's helpers, the options window's
-- widgets, Misc's defaults, the talent plan's files, the shaman's tree,
-- Blizzard's talent window and the module enabled. opts.before runs between
-- the window's making and the module's enabling (the addon already loaded).
local function world(opts)
	opts = opts or {}
	st = T.client('forever')
	stub.class, stub.level = 'SHAMAN', 27
	st.config.global, st.config.char = {}, {}
	load_options_widgets()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	st.SkinScrollBar = function() end
	local create = CreateFrame
	_G.CreateFrame = function(frameType, name, parent, template, ...)
		if template ~= 'ScrollFrameTemplate' then return create(frameType, name, parent, template, ...) end
		local frame = create(frameType, name, parent, nil, ...)
		local bar = create('Frame', nil, frame)
		bar:SetWidth(8)
		bar:SetPoint('TOPLEFT', frame, 'TOPRIGHT', 6, -2)
		bar:SetPoint('BOTTOMLEFT', frame, 'BOTTOMRIGHT', 6, 5)
		bar.SetHideIfUnscrollable = function() end
		frame.ScrollBar = bar
		return frame
	end
	load_saftui('SaftUI-Core/Widgets/scrollframe.lua')
	if not _G.GameTooltip then create('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	for _, file in ipairs({ 'talentplan', 'model', 'simulate', 'parser', 'store', 'data', 'drag', 'panel', 'import', 'overlays' }) do
		load_saftui('SaftUI-Misc/TalentPlan/' .. file .. '.lua')
	end
	load_saftui('SaftUI-Misc/movable.lua')
	TP = st:GetModule('TalentPlan')
	S, M, W = TP.Store, TP.Model, st.OptionsWidgets
	TP.Data.ResetSnapshots()
	SH.install(opts.tree)
	create('Frame', 'SettingsPanel', UIParent)
	create('Frame', 'AddonList', UIParent)
	PSF.build()
	menu_stand_in()
	if opts.before then opts.before() end
	if opts.faces then -- the skin and the faces module, enabled before the plan (TP:OnEnable gives the faces its source)
		st.config.profile.skinning.theme = 'thick'
		stub.installed_addons.Blizzard_PlayerSpells = true
		load_saftui('SaftUI-Misc/Skinning/skinning.lua')
		load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsSkin.lua')
		load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_TalentFaces.lua')
		st:GetModule('Skinning'):Enable()
		st:GetModule('TalentFaces'):Enable()
	end
	st:GetModule('Movable'):Enable() -- made first, so enabled first (AceAddon's module order)
	TP:Enable()
	if not opts.before then PSF.load() end
end

-- The owner's guide's first 20 steps as the active plan of spec tab 1.
local function guide_plan()
	local plan = S.New('Enhancement', 1)
	local steps = TP.Parse(GUIDE, SH.NAMES).steps
	for i = 1, 20 do plan.steps[i] = steps[i] end
	return plan
end

local TWELVE = { ['Thundering Strikes'] = 5, ['Mental Dexterity'] = 3, ['Ancestral Knowledge'] = 2,
	['Shamanistic Focus'] = 1, ['Elemental Weapons'] = 1 }

local function open()
	PSF.open()
	stub.run_timers()
end

local function J(list) return table.concat(list, ',') end
local function row(i) return TP.panel.rows[i].frame end
local function rec(name) return TP.overlays[PSF.byNode[SH.ID[name]]] end

local function clean()
	eq(#take_errors(), 0, 'no errors')
	eq(#stub.traits.calls, 0, 'nothing bought, refunded or committed')
end

local function steps_of(plan, name)
	local out = {}
	for i, id in ipairs(plan.steps) do if id == SH.ID[name] then out[#out + 1] = i end end
	return out
end

test('catchers cover their buttons only while planning', function()
	world()
	open()
	local count = 0
	for button, r in pairs(TP.overlays) do
		count = count + 1
		check(not r.catcher:IsShown(), 'hidden')
		check(not r.catcher:IsMouseEnabled(), 'and mouse-disabled')
	end
	check(count >= 23, 'a record per button')
	TP:SetPlanning(true)
	for button, r in pairs(TP.overlays) do
		check(r.catcher:IsShown() and r.catcher:IsMouseEnabled(), 'shown and mouse-enabled')
		eq(r.catcher:GetFrameLevel(), button:GetFrameLevel() + 10)
		eq(J({ r.catcher:GetRect() }), J({ button:GetRect() }), 'the same rect')
		for _, part in ipairs({ r.light, r.glow, r.dim }) do check(not part:IsMouseEnabled(), 'overlays take no mouse') end
		eq(r.dim:GetFrameLevel(), button:GetFrameLevel() + 4)
		eq(r.glow:GetFrameLevel(), button:GetFrameLevel() + 5)
		eq(r.light:GetFrameLevel(), button:GetFrameLevel() + 6)
	end
	check(TP.panel.hint:IsShown(), 'the planning line shows')
	TP:SetPlanning(false)
	for _, r in pairs(TP.overlays) do check(not r.catcher:IsShown(), 'hidden again') end
	clean()
end)

test('a planning click plans and never reaches Blizzard\'s button', function()
	world()
	open()
	TP:SetPlanning(true)
	local flurry = rec('Flurry')
	stub.click(flurry.catcher, 'LeftButton')
	stub.click(flurry.catcher, 'LeftButton')
	local plan = S.Active(1)
	eq(J(plan.steps), J({ SH.ID.Flurry, SH.ID.Flurry }))
	eq(TP.view.rows[2].rank, 2)
	stub.click(flurry.catcher, 'RightButton')
	eq(#plan.steps, 1)
	eq(TP:PlanClick(SH.ID.Mindfulness, 'RightButton'), nil, 'nothing to remove')
	eq(PSF.clicks[SH.ID.Flurry], nil, 'Blizzard never saw a click')
	clean()
end)

test('a click goes after the selected row', function()
	world()
	local plan = S.New('P', 1)
	local a, b = SH.ID['Stormstrike'], SH.ID['Spirit Weapons']
	plan.steps = { a, b, b }
	open()
	TP:SetPlanning(true)
	stub.click(row(1), 'LeftButton')
	eq(TP.selected, 1)
	stub.click(rec('Flurry').catcher, 'LeftButton')
	eq(TP.selected, 2, 'the selection moves to the new step')
	stub.click(rec('Mindfulness').catcher, 'LeftButton')
	eq(J(plan.steps), J({ a, SH.ID.Flurry, SH.ID.Mindfulness, b, b }))
	clean()
end)

test('a maxed node does nothing and says so', function()
	world()
	open()
	TP:SetPlanning(true)
	local focus = rec('Shamanistic Focus')
	eq(TP:PlanClick(SH.ID['Shamanistic Focus'], 'LeftButton'), 'added')
	eq(TP:PlanClick(SH.ID['Shamanistic Focus'], 'LeftButton'), 'maxed')
	eq(#S.Active(1).steps, 1)
	local lines = TP.CatcherLines(S.Active(1), SH.ID['Shamanistic Focus'], TP.view.tree.nodes[SH.ID['Shamanistic Focus']])
	eq(lines[1], 'Shamanistic Focus')
	eq(lines[2], 'Rank 1 at level 10')
	eq(lines[#lines], 'All 1 ranks are planned.')
	local open_lines = TP.CatcherLines(S.Active(1), SH.ID.Flurry, TP.view.tree.nodes[SH.ID.Flurry])
	eq(J(open_lines), 'Flurry,Click: add the next rank. Right-click: remove the last one.')
	stub.fire_script(focus.catcher, 'OnEnter')
	eq(GameTooltip:GetOwner(), focus.catcher)
	eq(stub.state(GameTooltip).texts[#stub.state(GameTooltip).texts], 'All 1 ranks are planned.')
	stub.fire_script(focus.catcher, 'OnLeave')
	check(not GameTooltip:IsShown())
	clean()
end)

test('glow on the waiting node, dim on unplanned ones, light on hover', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	open()
	local waiting = TP.view.rows[TP.view.summary.waiting].nodeID
	for button, r in pairs(TP.overlays) do
		eq(r.glow:IsShown(), r.nodeID == waiting, 'glow only on the waiting node')
		eq(r.dim:IsShown(), TP.view.tree.nodes[r.nodeID] ~= nil and M.PlannedRanks(TP.view.plan, r.nodeID) == 0, 'dim on the unplanned')
		check(not r.light:IsShown(), 'no light yet')
	end
	check(rec('Improved Lightning Shield').dim:IsShown())
	check(not rec('Thundering Strikes').dim:IsShown())
	TP.config.dim = false
	TP:Refresh()
	check(not rec('Improved Lightning Shield').dim:IsShown(), 'dim off')
	TP.config.dim = true
	TP:Refresh()
	stub.fire_script(row(1), 'OnEnter')
	check(rec('Thundering Strikes').light:IsShown(), 'light on the row node')
	check(not rec('Flurry').light:IsShown())
	stub.fire_script(row(1), 'OnLeave')
	check(not rec('Thundering Strikes').light:IsShown())
	clean()
end)

test('an empty plan dims nothing', function()
	world()
	S.New('Empty', 1)
	open()
	for _, r in pairs(TP.overlays) do check(not r.dim:IsShown()) end
	clean()
end)

test('overlays follow a re-bound button', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	open()
	local a, b = PSF.byNode[SH.ID.Flurry], PSF.byNode[SH.ID['Elemental Weapons']]
	local oldA, oldB = a._node, b._node
	PSF.rebind(a, oldB)
	PSF.rebind(b, oldA)
	PSF.redraw(); stub.run_timers()
	local waiting = TP.view.rows[TP.view.summary.waiting].nodeID
	eq(waiting, SH.ID['Elemental Weapons'])
	check(TP.overlays[a].glow:IsShown(), 'the waiting node moved to a, and so did its glow')
	check(not TP.overlays[b].glow:IsShown(), 'and left b')
	check(TP.overlays[a].glow:IsShown() == (a._node == waiting), 'glow follows the node, not the button')
	check(TP.overlays[b].glow:IsShown() == (b._node == waiting))
	eq(TP.overlays[a].nodeID, oldB)
	check(TP.overlays[a].dim:IsShown() == (M.PlannedRanks(TP.view.plan, oldB) == 0))
	check(TP.overlays[b].dim:IsShown() == (M.PlannedRanks(TP.view.plan, oldA) == 0))
	clean()
end)

test('a button redraw redraws the overlays through the one callback', function()
	local seen = {}
	world({ before = function()
		local register = EventRegistry.RegisterCallback
		EventRegistry.RegisterCallback = function(self, event, func, owner, ...)
			local key = event .. '/' .. tostring(owner)
			seen[key] = (seen[key] or 0) + 1
			return register(self, event, func, owner, ...)
		end
		PSF.load()
	end })
	open()
	for key, n in pairs(seen) do eq(n, 1, key .. ' is registered once (a second one with the same owner would replace the first)') end
	check(seen['TalentFrameBase.ButtonsUpdated/' .. tostring(TP)], 'the module registered it')
	local plan = S.New('P', 1)
	plan.steps = { SH.ID.Flurry }
	PSF.redraw(); stub.run_timers()
	check(not rec('Flurry').dim:IsShown() and rec('Mindfulness').dim:IsShown(), 'the overlays were redrawn')
	clean()
end)

test('hiding the panel clears the view and ends planning', function()
	world()
	open()
	TP:SetPlanning(true)
	PSF.window:SetInspecting('target'); stub.run_timers()
	eq(TP.view, nil, 'the view is cleared')
	check(not TP.planning, 'planning is off')
	for _, r in pairs(TP.overlays) do check(not r.catcher:IsShown() and not r.dim:IsShown() and not r.glow:IsShown()) end
	clean()
end)

test('collapsing the panel ends planning, so no catcher swallows a tree click', function()
	world()
	open()
	TP:SetPlanning(true)
	check(TP.planning, 'planning is on')
	TP:SetCollapsed(true)
	check(not TP.planning, 'planning is off')
	for _, r in pairs(TP.overlays) do
		check(not r.catcher:IsShown() and not r.catcher:IsMouseEnabled(), 'no catcher takes the mouse')
	end
	clean()
end)

test('planning turns off when the window hides', function()
	world()
	open()
	TP:SetPlanning(true)
	PSF.talents:Hide()
	check(not TP.planning)
	for _, r in pairs(TP.overlays) do check(not r.catcher:IsShown(), 'catcher hidden') end
	PSF.talents:Show(); PSF.window:Hide(); stub.run_timers()
	check(not TP.planning)
	clean()
end)

test('a missing step has no overlay and the waiting node still glows', function() -- Review Focus 1
	world({ tree = { ranks = TWELVE } })
	local plan = guide_plan()
	table.insert(plan.steps, 3, 999999)
	open()
	for _, r in pairs(TP.overlays) do check(r.nodeID ~= 999999, 'no record for the missing node') end
	local row = TP.view.rows[TP.view.summary.waiting]
	check(TP.view.tree.nodes[row.nodeID], 'waiting is a real node')
	check(PSF.byNode[row.nodeID] and TP.overlays[PSF.byNode[row.nodeID]].glow:IsShown(), 'glow on its button')
	clean()
end)

test('a released pool button is not lit', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	open()
	local button = PSF.byNode[SH.ID['Thundering Strikes']]
	for i, b in ipairs(PSF.buttons) do if b == button then table.remove(PSF.buttons, i) break end end
	PSF.redraw(); stub.run_timers()
	eq(TP.overlays[button].nodeID, nil, 'a released button names no node')
	stub.fire_script(row(1), 'OnEnter')
	check(not TP.overlays[button].light:IsShown(), 'not lit')
	check(not TP.overlays[button].glow:IsShown() and not TP.overlays[button].dim:IsShown())
	clean()
end)

-- The waiting node's highlight: a glow under the Blizzard theme, the border
-- under Thick and Thin. The theme is the panel's (config.panels.theme: 'theme'
-- follows SaftUI's, or an override).
local function edges_shown(part)
	for _, texture in ipairs(part.edges) do
		if texture:IsShown() then return true end
	end
	return false
end

local function waiting_glow()
	local waiting = TP.view.rows[TP.view.summary.waiting].nodeID
	for _, r in pairs(TP.overlays) do
		if r.nodeID == waiting then return r.glow end
	end
end

test('under the Blizzard theme the waiting node glows and has no border', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	st.config.profile.theme.name = 'blizzard'
	open()
	local glow = waiting_glow()
	check(glow:IsShown())
	check(glow.glowTexture and glow.glowTexture:IsShown(), 'the glow texture shows')
	eq(glow.glowTexture:GetBlendMode(), 'ADD', 'added light, as the game draws its own')
	check(glow.glowTexture:GetAtlas(), 'Blizzard art')
	check(not edges_shown(glow), 'the border edges are hidden')
	for _, r in pairs(TP.overlays) do
		check(not r.glow.glowTexture or not r.glow.glowTexture:IsShown() or r.glow == glow or not r.glow:IsShown())
	end
	clean()
end)

test('under Thick and Thin the waiting node keeps its border and has no glow texture', function()
	for _, name in ipairs({ 'thick', 'thin' }) do
		world({ tree = { ranks = TWELVE } })
		guide_plan()
		st.config.profile.theme.name = name
		open()
		local glow = waiting_glow()
		check(glow:IsShown(), name)
		check(edges_shown(glow), name .. ': the border shows')
		check(not (glow.glowTexture and glow.glowTexture:IsShown()), name .. ': no glow texture')
		clean()
	end
end)

test('switching the theme changes the highlight at once, back and forth', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	open()
	local glow = waiting_glow()
	check(edges_shown(glow) and not (glow.glowTexture and glow.glowTexture:IsShown()), 'Thick: border')
	T.theme('blizzard', function() st:ColorsChanged('theme') end)
	check(not edges_shown(glow) and glow.glowTexture:IsShown(), 'Blizzard: glow, on the colors callback')
	T.theme('thin', function() st:ColorsChanged('theme') end)
	check(edges_shown(glow) and not glow.glowTexture:IsShown(), 'Thin: border again')
	st.config.profile.theme.name = 'blizzard'
	TP:UpdateConfig() -- what Config:UpdateConfig runs for the module
	stub.run_timers()
	check(not edges_shown(glow) and glow.glowTexture:IsShown(), 'Blizzard through the profile update')
	clean()
end)

test("the panel's own Theme override decides, not SaftUI's", function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	st.config.profile.theme.name = 'thick'
	st.config.profile.panels.theme = 'blizzard'
	open()
	local glow = waiting_glow()
	check(glow.glowTexture and glow.glowTexture:IsShown() and not edges_shown(glow), 'override Blizzard: glow')
	st.config.profile.panels.theme = 'theme'
	st.config.profile.theme.name = 'blizzard'
	st.config.profile.panels.theme = 'thin'
	TP:PaintOverlays()
	check(edges_shown(glow) and not glow.glowTexture:IsShown(), 'override Thin under Blizzard: border')
	clean()
end)

test('the glow pulses with an animation', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	st.config.profile.theme.name = 'blizzard'
	open()
	local glow = waiting_glow()
	check(glow.glowAnim and glow.glowAnim:IsPlaying(), 'the pulse plays')
	T.theme('thick', function() st:ColorsChanged('theme') end)
	check(not glow.glowAnim:IsPlaying(), 'and stops with the border')
	clean()
end)

test("the glow takes the atlas of the button's own Glow, the circle's without one", function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	st.config.profile.theme.name = 'blizzard'
	local waiting_button
	open()
	local glow = waiting_glow()
	eq(glow.glowTexture:GetAtlas(), 'talents-node-circle-greenglow', 'no Glow on the button: circle')
	for button, r in pairs(TP.overlays) do
		if r.glow == glow then waiting_button = button end
	end
	local holder = CreateFrame('Frame')
	local own = holder:CreateTexture()
	own:SetAtlas('talents-node-square-greenglow')
	rawset(waiting_button, 'Glow', own)
	TP:DrawOverlays(TP.view)
	eq(glow.glowTexture:GetAtlas(), 'talents-node-square-greenglow', 'a square button: the square glow')
	own:SetAtlas('talents-node-choice-greenglow')
	TP:DrawOverlays(TP.view)
	eq(glow.glowTexture:GetAtlas(), 'talents-node-choice-greenglow', 'a choice button: the choice glow')
	clean()
end)

test('the glow art is made only for the glow that shows', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	st.config.profile.theme.name = 'blizzard'
	open()
	local glow, made = waiting_glow(), 0
	for _, r in pairs(TP.overlays) do
		if r.glow.glowTexture then made = made + 1 end
		if r.glow ~= glow then check(not r.glow.glowAnim, 'no animation on a node that does not glow') end
	end
	eq(made, 1, 'one glow texture, on the waiting node')
	clean()
end)

test('hiding the glow stops its pulse and showing it plays again', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	st.config.profile.theme.name = 'blizzard'
	open()
	local glow = waiting_glow()
	check(glow.glowAnim:IsPlaying(), 'plays')
	glow:Hide()
	check(not glow.glowAnim:IsPlaying(), 'hiding stops it')
	TP:DrawOverlays(TP.view) -- the waiting node's glow is shown again
	check(glow:IsShown() and glow.glowAnim:IsPlaying(), 'and a draw that shows it plays it again')
	TP:HideOverlays()
	check(not glow:IsShown() and not glow.glowAnim:IsPlaying(), 'the panel going stops it')
	clean()
end)

------------------------------------------------------------ the tree's rules

local function click_n(name, n)
	for _ = 1, n do eq(TP:PlanClick(SH.ID[name], 'LeftButton'), 'added') end
end

local function last_line(tip) local t = stub.state(tip).texts; return t[#t] end

test('a planning click the tree forbids is refused', function()
	world({ tree = { shape = true } })
	open()
	TP:SetPlanning(true)
	local flurry = rec('Flurry') -- Enhancement, row 2: five points in Enhancement first
	stub.fire_script(flurry.catcher, 'OnEnter')
	stub.click(flurry.catcher, 'LeftButton')
	eq(S.Active(1), nil, 'no plan was made')
	eq(last_line(GameTooltip), 'Needs 5 points in Enhancement first.')
	local result, reason = TP:PlanClick(SH.ID.Flurry, 'LeftButton')
	eq(result, 'refused'); eq(reason, 'Needs 5 points in Enhancement first.')
	-- a point in another group doesn't count for it
	eq(TP:PlanClick(SH.ID['Call of Flame'], 'LeftButton'), 'added')
	eq(TP:PlanClick(SH.ID.Flurry, 'LeftButton'), 'refused')
	-- five row 1 points in Enhancement, then row 2
	click_n('Thundering Strikes', 5)
	eq(TP:PlanClick(SH.ID.Flurry, 'LeftButton'), 'added')
	eq(#S.Active(1).steps, 7)
	stub.fire_script(flurry.catcher, 'OnLeave')
	clean()
	eq(next(PSF.clicks), nil, 'Blizzard never saw a click')
end)

test('the refusal is in the tooltip in Danger and goes with the next good click', function()
	world({ tree = { shape = true } })
	open()
	TP:SetPlanning(true)
	local c = rec('Flurry').catcher
	stub.fire_script(c, 'OnEnter')
	check(last_line(GameTooltip) ~= 'Needs 5 points in Enhancement first.', 'not before a click')
	stub.click(c, 'LeftButton')
	local lines = stub.state(GameTooltip).texts
	eq(lines[#lines], 'Needs 5 points in Enhancement first.')
	local danger = { st:Color('text', 'danger'):GetRGB() }
	local color = stub.state(GameTooltip).colors[#lines]
	eq(J({ color[1], color[2], color[3] }), J(danger), 'in Text > Danger')
	TP:PlanClick(SH.ID['Thundering Strikes'], 'LeftButton')
	stub.fire_script(c, 'OnEnter')
	check(last_line(GameTooltip) ~= 'Needs 5 points in Enhancement first.', 'gone')
	local pure = TP.CatcherLines(nil, SH.ID.Flurry, { name = 'Flurry', maxRanks = 5 }, 'Why.')
	eq(pure[#pure], 'Why.')
	eq(TP.CatcherLines(nil, SH.ID.Flurry, { name = 'Flurry', maxRanks = 5 })[3], nil, 'no refusal, no line')
	clean()
end)

test('a node whose prerequisite is a choice node is never available', function()
	world({ tree = { shape = true } })
	open()
	TP:SetPlanning(true)
	-- Totemic Focus (Restoration, row 2) has the choice node as its parent
	local ok = TP:PlanClick(SH.ID['Totemic Focus'], 'LeftButton')
	eq(ok, 'refused')
	clean()
end)

test('a right-click a later step needs is refused', function()
	world({ tree = { shape = true } })
	open()
	TP:SetPlanning(true)
	click_n('Thundering Strikes', 5)
	click_n('Flurry', 1)
	local before = J(S.Active(1).steps)
	local result, reason = TP:PlanClick(SH.ID['Thundering Strikes'], 'RightButton')
	eq(result, 'refused'); eq(reason, 'Other planned talents need this rank.')
	eq(J(S.Active(1).steps), before, 'nothing changed')
	eq(TP:PlanClick(SH.ID.Flurry, 'RightButton'), 'removed')
	eq(TP:PlanClick(SH.ID['Thundering Strikes'], 'RightButton'), 'removed', 'free once Flurry is gone')
	eq(#S.Active(1).steps, 4)
	eq(TP:PlanClick(SH.ID.Mindfulness, 'RightButton'), nil, 'a node not in the plan: nothing to remove')
	clean()
end)

test('a right-click removes the step the rules judged, the last of the node', function()
	world({ tree = { shape = true } })
	open()
	TP:SetPlanning(true)
	click_n('Thundering Strikes', 5)
	local plan = S.Active(1)
	table.insert(plan.steps, 2, SH.ID['Mental Dexterity']) -- TS, MD, TS, TS, TS, TS
	TP:Refresh()
	eq(TP:PlanClick(SH.ID['Thundering Strikes'], 'RightButton'), 'removed')
	eq(J(plan.steps), J({ SH.ID['Thundering Strikes'], SH.ID['Mental Dexterity'], SH.ID['Thundering Strikes'],
		SH.ID['Thundering Strikes'], SH.ID['Thundering Strikes'] }), 'the last Thundering Strikes went')
	clean()
end)

test('planning shows the plan, not the real tree', function()
	world({ tree = { shape = true, ranks = { Flurry = 5 } }, faces = true })
	open()
	local flurry = PSF.byNode[SH.ID.Flurry]
	PSF.set_state(flurry, 6, '5') -- Blizzard's real: maxed, 5
	stub.run_timers()
	eq(TP:PlanDisplay(SH.ID.Flurry), nil, 'not planning: the real state')
	local face = st:GetModule('TalentFaces').faces[flurry]
	check(not face.overlay:IsShown(), 'the real state: maxed, no dim')
	TP:SetPlanning(true)
	stub.run_timers()
	local d = TP:PlanDisplay(SH.ID.Flurry)
	eq(d.state, 'gated'); eq(d.planned, 0)
	local ts = TP:PlanDisplay(SH.ID['Thundering Strikes'])
	eq(ts.state, 'selectable'); eq(ts.planned, 0)
	eq(face.overlay:GetAlpha(), 0.7, 'the face shows the plan: gated')
	eq(face.rank:GetAlpha(), 0.3, 'the real rank faded')
	eq(face.rank:GetText(), '5')
	local tsface = st:GetModule('TalentFaces').faces[PSF.byNode[SH.ID['Thundering Strikes']]]
	check(tsface.planned:IsShown(), 'a selectable node shows its planned 0')
	eq(tsface.planned:GetText(), '0')
	click_n('Thundering Strikes', 5)
	click_n('Flurry', 2)
	stub.run_timers()
	d = TP:PlanDisplay(SH.ID.Flurry)
	eq(d.state, 'selectable', "Blizzard's order: can take another rank beats partial"); eq(d.planned, 2)
	eq(face.planned:GetText(), '2')
	eq(TP:PlanDisplay(130).state, 'disabled', 'the choice node is in the shape, never plannable')
	eq(TP:PlanDisplay(999), nil, 'a node the shape does not know shows its real state')
	TP:SetPlanning(false)
	stub.run_timers()
	eq(TP:PlanDisplay(SH.ID.Flurry), nil)
	check(not face.overlay:IsShown(), 'planning off: the real maxed again')
	check(not face.planned:IsShown())
	clean()
end)

test('a one rank node shows no planned number when the tree hides them', function()
	world({ tree = { shape = true } })
	stub.traits.tree_info[501] = { hideSingleRankNumbers = true }
	open()
	TP:SetPlanning(true)
	local focus = SH.ID['Shamanistic Focus'] -- one rank, row 1 of Enhancement
	eq(TP:PlanDisplay(focus).state, 'selectable')
	eq(TP:PlanDisplay(focus).planned, nil, 'no number for a one rank node')
	eq(TP:PlanDisplay(SH.ID['Thundering Strikes']).planned, 0, 'a tiered node keeps it')
	clean()
end)

test('the node of a group the tree does not list counts the tree', function()
	world({ tree = { shape = true } })
	stub.traits.nodes[1001][SH.ID.Flurry].groupIDs = { 999 }
	open()
	TP:SetPlanning(true)
	-- five points anywhere: Flurry's gate counts the whole tree
	click_n('Call of Flame', 3)
	eq(TP:PlanClick(SH.ID.Flurry, 'LeftButton'), 'refused')
	click_n('Elemental Devastation', 2)
	eq(TP:PlanClick(SH.ID.Flurry, 'LeftButton'), 'added')
	clean()
end)

test('the window total', function()
	world({ tree = { shape = true } })
	open()
	check(TP.total == nil or not TP.total:IsShown(), 'nothing outside planning')
	TP:SetPlanning(true)
	eq(TP.total:GetText(), 'Planned: 0 points\nElemental 0 · Enhancement 0 · Restoration 0')
	click_n('Thundering Strikes', 5)
	click_n('Flurry', 1)
	eq(TP.total:GetText(), 'Planned: 6 points\nElemental 0 · Enhancement 6 · Restoration 0')
	check(TP.total:IsShown())
	local point, relative = TP.total:GetPoint(1)
	eq(point, 'TOPLEFT'); eq(relative, TP:TalentsFrame())
	TP:SetPlanning(false)
	check(not TP.total:IsShown(), 'hidden when planning ends')
	TP:SetPlanning(true)
	check(TP.total:IsShown())
	PSF.talents:Hide()
	check(not TP.total:IsShown(), 'and with the window')
	clean()
end)

test('the window total with no groups is the tree total only', function()
	world()
	open()
	TP:SetPlanning(true)
	click_n('Flurry', 2)
	eq(TP.total:GetText(), 'Planned: 2 points')
	clean()
end)

test('no plan dim while planning', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	open()
	check(rec('Improved Lightning Shield').dim:IsShown(), 'the dim in normal mode')
	TP:SetPlanning(true)
	for _, r in pairs(TP.overlays) do check(not r.dim:IsShown(), 'off while planning') end
	TP:SetPlanning(false)
	check(rec('Improved Lightning Shield').dim:IsShown(), 'and back')
	clean()
end)

test('the catcher\'s hover lights the face', function()
	world({ tree = { shape = true }, faces = true })
	open()
	TP:SetPlanning(true)
	stub.run_timers()
	local face = st:GetModule('TalentFaces').faces[PSF.byNode[SH.ID.Flurry]]
	local c = rec('Flurry').catcher
	stub.fire_script(c, 'OnEnter')
	check(st:GetState(face.face, 'hover'), 'hover on')
	stub.fire_script(c, 'OnLeave')
	check(not st:GetState(face.face, 'hover'), 'hover off')
	clean()
end)

test('SetPlanning asks the faces for a draw and the module gives them its source', function()
	world({ tree = { shape = true }, faces = true })
	open()
	local TF = st:GetModule('TalentFaces')
	local face = TF.faces[PSF.byNode[SH.ID.Flurry]]
	check(not face.planned:IsShown())
	TP:SetPlanning(true)
	stub.run_timers()
	eq(face.overlay:GetAlpha(), 0.7)
	clean()
end)

test('the plan check lists a node where the rules and the game disagree', function()
	world({ tree = { shape = true, ranks = { ['Thundering Strikes'] = 5 } } })
	-- the game's word on the gates: five points are in Enhancement only
	for _, info in pairs(stub.traits.nodes[1001]) do
		local spent = info.groupIDs and info.groupIDs[1] == SH.GROUP.Enhancement and 5 or 0
		for _, cond in ipairs(info.conditionIDs) do
			info.isAvailable = spent >= stub.traits.conditions[cond].spentAmountRequired
		end
	end
	-- and it says Flurry (row 2) is not available although five points are in Enhancement
	stub.traits.nodes[1001][SH.ID.Flurry].isAvailable = false
	-- Stormstrike's parent, Spirit Weapons, is not maxed: the game agrees
	stub.traits.nodes[1001][SH.ID.Stormstrike].meetsEdgeRequirements = false
	stub.traits.nodes[1001][SH.ID['Improved Stormstrike']].meetsEdgeRequirements = false
	stub.traits.nodes[1001][SH.ID['Totemic Focus']].meetsEdgeRequirements = false -- its parent is a choice node
	open()
	local said = {}
	local print_ = st.Print
	st.Print = function(_, ...) said[#said + 1] = table.concat({ ... }, ' ') end
	TP:RunCheck()
	st.Print = print_
	check(said[1]:find('Flurry', 1, true), 'names the node: ' .. tostring(said[1]))
	-- and when they agree
	stub.traits.nodes[1001][SH.ID.Flurry].isAvailable = true
	said = {}
	st.Print = function(_, ...) said[#said + 1] = table.concat({ ... }, ' ') end
	TP:RunCheck()
	st.Print = print_
	eq(said[1], "The plan's rules agree with the game.")
	clean()
end)
