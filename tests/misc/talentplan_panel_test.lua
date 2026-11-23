-- SaftUI-Misc/TalentPlan/panel.lua and the wiring in talentplan.lua: the
-- panel docked beside Blizzard's talent window, its rows, its menus, its
-- collapse, and what it leaves alone.
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

-- Twelve of the plan's twenty steps are learned (the waiting one is the
-- second rank of Elemental Weapons, level 22).
local TWELVE = { ['Thundering Strikes'] = 5, ['Mental Dexterity'] = 3, ['Ancestral Knowledge'] = 2,
	['Shamanistic Focus'] = 1, ['Elemental Weapons'] = 1 }

local function open()
	PSF.open()
	stub.run_timers()
end

local function row(i) return TP.panel.rows[i].frame end

local function clean()
	eq(#take_errors(), 0, 'no errors')
	eq(#stub.traits.calls, 0, 'nothing bought, refunded or committed')
end

test('the panel takes the mouse, so a click on its empty space is not the world\'s', function()
	world()
	open()
	check(TP.panel:IsMouseEnabled(), 'mouse enabled')
end)

test('a pending waiting row says staged, not what blocks it', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	local node = stub.traits.nodes[1001][SH.ID['Elemental Weapons']]
	node.ranksPurchased = 2
	node.canPurchaseRank = false -- no points left: the block would read "No talent points to spend."
	stub.traits.staged[1001] = { purchases = { SH.ID['Elemental Weapons'] }, refunds = {} }
	open()
	eq(row(13).tag:GetText(), 'pending')
	stub.fire_script(row(13), 'OnEnter')
	eq(stub.state(GameTooltip).texts[1], 'Staged. Press Apply in the talent window to learn it.')
end)

test('the panel shows with the Talents tab and hides while inspecting', function() -- Review Focus 3
	world()
	check(TP.panel == nil, 'nothing is built before the window shows')
	open()
	check(TP.panel:IsShown(), 'shown with the Talents tab')
	check(TP.panel:GetParent() == PSF.talents, "a child of the talent frame, so it hides with it")
	PSF.window:SetInspecting('target'); stub.run_timers()
	check(not TP.panel:IsShown(), 'hidden while inspecting')
	PSF.window:ClearInspectUnit(); stub.run_timers()
	check(TP.panel:IsShown(), 'shown again after')
	PSF.talents:Hide()
	check(not TP.panel:IsShown(), 'hidden with the Talents tab')
	stub.run_timers()
	check(not TP.panel:IsShown(), 'and it stays hidden')
	clean()
end)

test('the addon already loaded at enable', function() -- Review Focus 3
	world({ before = function() PSF.load() end })
	open()
	check(TP.panel and TP.panel:IsShown(), 'the panel builds on open')
	clean()
end)

test('a window already open when the module enables gets its panel', function()
	world({ before = function() PSF.load(); PSF.open() end })
	stub.run_timers()
	check(TP.panel and TP.panel:IsShown(), 'built at enable')
	clean()
end)

test('a profile with the plan off shows nothing', function()
	world()
	TP.config.enable = false
	open()
	check(TP.panel == nil, 'no panel')
	TP.config.enable = true
	TP:UpdateConfig(); stub.run_timers()
	check(TP.panel:IsShown(), 'on again')
	clean()
end)

test('Side picks the roomier side', function()
	world()
	eq(TP.Layout.Side(300, 1518, 1920, 250), 'RIGHT')
	eq(TP.Layout.Side(1000, 1900, 1920, 250), 'LEFT')
	eq(TP.Layout.Side(100, 1820, 1920, 250), 'RIGHT', 'a tie')
end)

test('it hangs from the window by two points and docks to the left after a drop at the right edge', function()
	world()
	open()
	local names = { [PSF.window] = 'PlayerSpellsFrame' }
	eq(T.anchor(TP.panel, names, 'TOPLEFT'), 'TOPLEFT PlayerSpellsFrame TOPRIGHT 6.00,0.00')
	eq(T.anchor(TP.panel, names, 'BOTTOMLEFT'), 'BOTTOMLEFT PlayerSpellsFrame BOTTOMRIGHT 6.00,0.00')
	eq(TP.panel:GetWidth(), 250)
	check(TP.panel:IsClampedToScreen(), 'clamped to the screen')
	-- a drop: the window is where the drag left it, and Movable's own OnMouseUp hook re-anchors it
	PSF.window:ClearAllPoints()
	PSF.window:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', 1900.7, -41.4)
	stub.fire_script(PSF.window, 'OnMouseUp')
	eq(select(4, PSF.window:GetPoint()), 1900, "Movable's hook ran first and rounded the anchor")
	eq(T.anchor(TP.panel, names, 'TOPLEFT'), 'TOPLEFT PlayerSpellsFrame TOPRIGHT 6.00,0.00', 'the dock waits for the next frame')
	stub.run_timers()
	eq(T.anchor(TP.panel, names), 'TOPRIGHT PlayerSpellsFrame TOPLEFT -17.00,0.00')
	eq(T.anchor(TP.panel, names, 'BOTTOMRIGHT'), 'BOTTOMRIGHT PlayerSpellsFrame BOTTOMLEFT -17.00,0.00')
	clean()
end)

test("rows show the plan's states", function()
	world({ tree = { ranks = TWELVE } })
	local plan = guide_plan()
	open()
	eq(TP.panel.count:GetText(), '12/20')
	eq(TP.view.summary.waiting, 13)
	check(st:GetState(row(13), 'selected'), 'the waiting row is selected')
	check(not st:GetState(row(14), 'selected'), 'the one after is not')
	check(row(1).check:IsShown(), 'a learned row has its check')
	check(not row(13).check:IsShown(), 'the waiting one has none')
	eq(row(14).tag:GetText(), 'R3', 'a node of more ranks says its rank')
	eq(row(1).name:GetText(), 'Thundering Strikes')
	eq(row(1).level:GetText(), '10')
	local muted = st:Color('text', 'muted')
	eq(select(2, row(1).name:GetTextColor()), muted.g, 'a learned name is Text > Muted')
	eq(#TP.panel.rows, 20)
	eq(plan, TP.view.plan)
	clean()
end)

test('a staged row reads pending and a blocked waiting row reads blocked, each with its tooltip', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	local node = stub.traits.nodes[1001][SH.ID['Elemental Weapons']]
	node.ranksPurchased = 2
	stub.traits.staged[1001] = { purchases = { SH.ID['Elemental Weapons'] }, refunds = {} }
	open()
	eq(row(13).tag:GetText(), 'pending')
	eq(TP.view.summary.waiting, 13, 'a staged rank keeps the waiting step where it was')
	stub.fire_script(row(13), 'OnEnter')
	eq(GameTooltip:GetOwner(), row(13))
	eq(stub.state(GameTooltip).texts[1], 'Staged. Press Apply in the talent window to learn it.')
	stub.fire_script(row(13), 'OnLeave')
	check(not GameTooltip:IsShown(), 'the tooltip goes')
	stub.traits.staged[1001] = nil
	node.ranksPurchased = 1
	local third = stub.traits.nodes[1001][SH.ID['Elemental Weapons']]
	third.canPurchaseRank, third.meetsEdgeRequirements = false, false
	TP:Refresh()
	eq(row(13).tag:GetText(), 'blocked')
	stub.fire_script(row(13), 'OnEnter')
	eq(stub.state(GameTooltip).texts[1], 'Needs the talent above it first.')
	clean()
end)

test('missing steps read as missing and can be deleted', function() -- Review Focus 1
	world({ tree = { ranks = TWELVE } })
	local plan = guide_plan()
	plan.steps[#plan.steps + 1] = 999
	open()
	eq(#TP.panel.rows, 21)
	eq(row(21).name:GetText(), 'Missing talent')
	local danger = st:Color('text', 'danger')
	eq(select(1, row(21).name:GetTextColor()), danger.r, 'in Text > Danger')
	eq(TP.view.summary.waiting, 13, 'the waiting row carries on past it')
	eq(TP.panel.count:GetText(), '12/20', 'and it is not counted')
	stub.fire_script(row(21), 'OnEnter')
	eq(stub.state(GameTooltip).texts[1], "This talent isn't in your class's tree any more. Right-click to delete the step.")
	stub.click(row(21), 'RightButton')
	local menu = opened[#opened]
	eq(texts(menu), 'Remove step')
	choose(item(menu, 'Remove step'))
	eq(#plan.steps, 20, 'removed from the plan')
	eq(#TP.panel.rows, 21, 'the pool keeps its frames')
	check(not row(21):IsShown(), 'and hides the spare one')
	clean()
end)

test('a click selects a row, a second click clears it, and the line sits under the row', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	open()
	check(not TP.panel.line:IsShown(), 'no selection at first')
	stub.click(row(5), 'LeftButton')
	eq(TP.selected, 5)
	check(TP.panel.line:IsShown(), 'the line shows')
	eq(T.anchor(TP.panel.line, { [row(5)] = 'row5' }, 'BOTTOMLEFT'), 'BOTTOMLEFT row5 BOTTOMLEFT 0.00,-1.00')
	eq(TP.panel.line:GetHeight(), 2)
	stub.click(row(7), 'LeftButton')
	eq(TP.selected, 7, 'another row moves it')
	stub.click(row(7), 'LeftButton')
	eq(TP.selected, nil, 'the same row clears it')
	check(not TP.panel.line:IsShown())
	stub.click(row(7), 'LeftButton')
	stub.click(row(3), 'RightButton')
	choose(item(opened[#opened], 'Remove step'))
	eq(TP.selected, 6, 'removing a step above moves the selection with its row')
	clean()
end)

test('off-plan line', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	open()
	check(not TP.panel.off:IsShown(), 'hidden at none')
	local flurry = stub.traits.nodes[1001][SH.ID['Tidal Focus']]
	flurry.ranksPurchased = 1
	TP:Refresh()
	check(TP.panel.off:IsShown())
	eq(TP.panel.off:GetText(), '1 point off plan')
	flurry.ranksPurchased = 2
	TP:Refresh()
	eq(TP.panel.off:GetText(), '2 points off plan')
	-- under the mouse it names the talent and lights it on the tree
	check(TP.panel.offHit:IsShown(), 'the line takes the mouse')
	stub.fire_script(TP.panel.offHit, 'OnEnter')
	check(GameTooltip:IsShown() and GameTooltip:IsOwned(TP.panel.offHit), 'a tooltip')
	local texts = table.concat(stub.state(GameTooltip).texts, '|')
	check(texts:find('Tidal Focus', 1, true), 'names the talent: ' .. texts)
	local rights = {}
	for _, r in pairs(stub.state(GameTooltip).rights) do rights[#rights + 1] = r end
	eq(table.concat(rights, '|'), '2 points', 'and its points')
	local lit
	for _, rec in pairs(TP.overlays) do
		if rec.nodeID == SH.ID['Tidal Focus'] then lit = rec.light:IsShown() end
	end
	check(lit, 'the talent is lit on the tree')
	stub.fire_script(TP.panel.offHit, 'OnLeave')
	check(not GameTooltip:IsShown(), 'the tooltip goes')
	for _, rec in pairs(TP.overlays) do check(not rec.light:IsShown(), 'no light left') end
	clean()
end)

test('the title strip gives the plan select the room: no heading, and the name has the width', function()
	world()
	guide_plan()
	open()
	local panel = TP.panel
	eq(panel.heading, nil, 'no "Leveling plan" heading')
	local sl, _, sw = panel.select:GetRect()
	local cl = panel.count:GetRect()
	check(sw >= 150, 'the select is wide enough for a name: ' .. tostring(sw))
	check(sl + sw <= cl, 'and ends before the count')
	local al, _, aw = panel.arrow:GetRect()
	check(sl >= al + aw, 'and starts after the arrow')
	clean()
end)

test('the footer is Plan, Import and the dots, filling the width evenly', function()
	world()
	open()
	local panel = TP.panel
	eq(panel.phasesButton, nil, 'no Phases button')
	local pl, _, pw = panel.planButton:GetRect()
	local il, _, iw = panel.importButton:GetRect()
	local dl, _, dw = panel.dots:GetRect()
	near(pw, iw, 0.01)
	check(il >= pl + pw and dl >= il + iw, 'in order')
	near(il - (pl + pw), dl - (il + iw), 0.01, 'equal gaps')
	local fl, _, fw = panel.footer:GetRect()
	near(pl - fl, fl + fw - (dl + dw), 0.01, 'equal margins')
	clean()
end)

test('empty state and New plan', function()
	world()
	open()
	local text = "No leveling plan for this spec tab. Import a guide's talent order, or press Plan and click talents in the order you'll take them."
	check(TP.panel.empty:IsShown(), 'the empty text shows')
	eq(TP.panel.empty:GetText(), text)
	eq(TP.panel.select.text:GetText(), 'No plan')
	eq(TP.panel.count:GetText(), '')
	stub.click(TP.panel.select, 'LeftButton')
	local menu = opened[#opened]
	eq(texts(menu), '-|New plan', 'no plans yet')
	choose(item(menu, 'New plan'))
	eq(S.Active(1).name, 'New plan')
	check(not TP.panel.empty:IsShown(), 'the empty text is gone')
	eq(TP.panel.select.text:GetText(), 'New plan')
	clean()
end)

test('the Plan button toggles planning and the strip says No plan', function()
	world()
	open()
	eq(TP.StripText(TP.view), 'No plan')
	stub.click(TP.panel.planButton, 'LeftButton')
	check(TP.planning, 'planning on')
	eq(S.Active(1), nil, 'no plan is made until a click plans')
	stub.click(TP.panel.planButton, 'LeftButton')
	check(not TP.planning, 'planning off')
	clean()
end)

test('the plan select menu lists the plans, checks the active one and switches', function()
	world()
	local a, b = S.New('Alpha', 1), S.New('Beta', 1)
	open()
	eq(TP.panel.select.text:GetText(), 'Beta')
	stub.click(TP.panel.select, 'LeftButton')
	local menu = opened[#opened]
	eq(texts(menu), 'Alpha|Beta|-|New plan')
	check(not item(menu, 'Alpha').a(), 'Alpha is not checked')
	check(item(menu, 'Beta').a(), 'Beta is')
	choose(item(menu, 'Alpha'))
	eq(S.Active(1), a)
	eq(TP.panel.select.text:GetText(), 'Alpha')
	-- the other spec tab keeps its own choice
	eq(S.Active(2), nil)
	check(b, 'both exist')
	clean()
end)

test('the dots menu renames, duplicates, deletes and clears', function()
	world({ tree = { ranks = TWELVE } })
	local plan = guide_plan()
	S.New('Other', 2)
	open()
	stub.click(TP.panel.dots, 'LeftButton')
	local menu = opened[#opened]
	eq(texts(menu), 'Rename|Duplicate|Delete plan|Clear steps')

	choose(item(menu, 'Rename'))
	local dialog = W.GetDialogFrames()
	eq(W.ConfirmText(), 'Rename the plan')
	eq(dialog.box:GetText(), 'Enhancement')
	local printed = {}
	local real = print
	_G.print = function(...) printed[#printed + 1] = table.concat({ ... }, ' ') end
	dialog.box:SetText('   ')
	stub.click(dialog.yes, 'LeftButton')
	choose(item(menu, 'Rename'))
	dialog.box:SetText('Other')
	stub.click(dialog.yes, 'LeftButton')
	_G.print = real
	eq(#printed, 2)
	check(printed[1]:find('A plan needs a name.', 1, true), printed[1])
	check(printed[2]:find('There is already a plan with that name.', 1, true), printed[2])
	choose(item(menu, 'Rename'))
	dialog.box:SetText(' Leveling ')
	stub.click(dialog.yes, 'LeftButton')
	eq(plan.name, 'Leveling')
	eq(TP.panel.select.text:GetText(), 'Leveling')

	choose(item(menu, 'Duplicate'))
	eq(S.Active(1).name, 'Leveling copy')
	eq(#S.Active(1).steps, 20)
	S.SetActive(1, plan.id)
	TP:Refresh()

	choose(item(menu, 'Clear steps'))
	eq(W.ConfirmText(), 'Clear every step of "Leveling"?')
	stub.click(dialog.yes, 'LeftButton')
	eq(#plan.steps, 0)
	eq(TP.panel.count:GetText(), '0/0')

	choose(item(menu, 'Delete plan'))
	eq(W.ConfirmText(), 'Delete the plan "Leveling"? This can\'t be undone.')
	stub.click(dialog.no, 'LeftButton')
	eq(S.Active(1), plan, 'No keeps it')
	choose(item(menu, 'Delete plan'))
	stub.click(dialog.yes, 'LeftButton')
	eq(S.Active(1), nil, 'the tab is empty, not broken')
	check(TP.panel.empty:IsShown())
	clean()
end)

test('collapse moves the panel to a header button, per character', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	open()
	local button = TP.expandButton
	check(button and not button:IsShown(), 'no button while the panel is open')
	check(TP.panel:IsShown())
	TP:SetCollapsed(true)
	check(S.Char().collapsed, 'saved for the character')
	check(not TP.panel:IsShown(), 'no strip: the panel is gone')
	check(button:IsShown(), 'the header button shows')
	local point, rel, relPoint = button:GetPoint()
	eq(rel, PSF.window.CloseButton, 'anchored to Blizzard\'s close button')
	eq(point, 'RIGHT'); eq(relPoint, 'LEFT', 'just left of it')
	eq(button:GetParent(), PSF.talents, 'a child of the talents frame, like the panel')
	eq(button:GetName(), 'SaftUI_TalentPlanExpand')
	eq(button:GetFrameLevel(), PSF.window.CloseButton:GetFrameLevel() + 1)
	local r, g, b = button.icon:GetVertexColor()
	eq(r, st:Color('text', 'muted'):GetRGB(), 'the icon is Muted')
	-- the tooltip names the plan and the waiting step
	stub.fire_script(button, 'OnEnter')
	eq(GameTooltip:GetOwner(), button)
	local tip = table.concat(stub.state(GameTooltip).texts, '\n')
	check(tip:find('Enhancement', 1, true), 'the plan: ' .. tip)
	check(tip:find('22 Elemental Weapons R2', 1, true), 'the waiting step: ' .. tip)
	stub.fire_script(button, 'OnLeave')
	check(not GameTooltip:IsShown())
	PSF.talents:Hide(); stub.run_timers()
	check(not button:IsShown(), 'hides with the tab')
	PSF.talents:Show(); stub.run_timers()
	check(button:IsShown() and not TP.panel:IsShown(), 'still collapsed after hiding and showing')
	PSF.window:SetInspecting('target'); stub.run_timers()
	check(not button:IsShown(), 'not while inspecting')
	PSF.window:ClearInspectUnit(); stub.run_timers()
	check(button:IsShown())
	PSF.window:Hide(); stub.run_timers()
	check(not button:IsShown(), 'hides with the window')
	PSF.window:Show(); PSF.talents:Show(); stub.run_timers()
	check(button:IsShown())
	-- a click expands it again
	local scrolls = 0
	TP.ScrollToWaiting = function() scrolls = scrolls + 1 end
	stub.click(button, 'LeftButton')
	check(not S.Char().collapsed)
	check(TP.panel:IsShown() and TP.panel.footer:IsShown() and TP.panel.scroll:IsShown(), 'the body is back')
	check(not button:IsShown(), 'the button goes')
	stub.run_timers()
	eq(scrolls, 1, 'expanding scrolls to the waiting step')
	eq(TP.panel:GetNumPoints(), 2, 'two points')
	clean()
end)

test('the header button is not made when the plan is off', function()
	world()
	TP.config.enable = false
	PSF.open(); stub.run_timers()
	S.Char().collapsed = true
	TP:Refresh()
	check(not TP.expandButton or not TP.expandButton:IsShown())
end)

test('the panel clears the window\'s border on both sides', function()
	world()
	open()
	local b = TP.Layout
	-- PortraitFrameTemplate's corners reach 13 out on the left (x = -13) and 2 on the right (4, less Camelot's -2)
	eq(b.BORDER_LEFT, 13); eq(b.BORDER_RIGHT, 2)
	check(b.GAP >= 3, 'a visible gap past the border')
	eq(TP.side, 'RIGHT')
	local _, _, _, x = TP.panel:GetPoint(1)
	eq(x, b.BORDER_RIGHT + b.GAP)
	PSF.window:ClearAllPoints()
	PSF.window:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', 1900, -41)
	TP:Dock()
	eq(TP.side, 'LEFT')
	_, _, _, x = TP.panel:GetPoint(1)
	eq(x, -(b.BORDER_LEFT + b.GAP))
	clean()
end)

test('under the talent window skin the panel clears SaftUI\'s own panel, and Blizzard\'s border when the skin is off', function()
	world()
	open()
	local b = TP.Layout
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsSkin.lua')
	local SK = st:GetModule('Skinning')
	local skin = SK:GetModule('Blizzard_PlayerSpellsSkin')
	SK:Enable()
	check(skin:IsActive(), 'the skin is on')
	TP:Dock()
	local inset = skin:Inset()
	local _, _, _, x = TP.panel:GetPoint(1)
	eq(x, inset + b.GAP, 'right: the skin\'s inset and the gap')
	PSF.window:ClearAllPoints()
	PSF.window:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', 1900, -41)
	TP:Dock()
	_, _, _, x = TP.panel:GetPoint(1)
	eq(x, -(inset + b.GAP), 'left too')
	-- under the Blizzard theme the skin stands down and Blizzard's border is back
	T.theme('blizzard', function() SK:UpdateConfig() end)
	check(not skin:IsActive(), 'off under Blizzard')
	_, _, _, x = TP.panel:GetPoint(1)
	eq(x, -(b.BORDER_LEFT + b.GAP), 'Blizzard\'s border again')
	clean()
end)

test('the collapse arrow faces the way the panel moves, on either side', function()
	world()
	open()
	eq(TP.panel.arrow.icon:GetTexture(), st.icons.chevronRight)
	PSF.window:ClearAllPoints()
	PSF.window:SetPoint('TOPRIGHT', UIParent, 'TOPLEFT', 1900, -41)
	TP:Dock()
	eq(TP.panel.arrow.icon:GetTexture(), st.icons.chevronLeft)
	clean()
end)

test('a show scrolls to the waiting step, a later refresh does not', function()
	world({ tree = { ranks = TWELVE } })
	guide_plan()
	local scrolls = {}
	open()
	local scroll = TP.panel.scroll
	local real = scroll.SetVerticalScroll
	scroll.SetVerticalScroll = function(self, offset) scrolls[#scrolls + 1] = offset; return real(self, offset) end
	TP:Refresh()
	eq(#scrolls, 0, 'a refresh does not scroll')
	PSF.talents:Hide(); PSF.talents:Show(); stub.run_timers()
	eq(#scrolls, 1, 'a show does, once')
	clean()
end)

test('StepLabel and StripText', function()
	world()
	local rows, summary = M.States({ steps = { 102, 108 } }, {
		[102] = { name = 'Mental Dexterity', maxRanks = 3, committed = 0, staged = 0 },
		[108] = { name = 'Stormstrike', maxRanks = 1, committed = 0, staged = 0 },
	}, nil)
	local nodes = { [102] = { name = 'Mental Dexterity', maxRanks = 3 }, [108] = { name = 'Stormstrike', maxRanks = 1 } }
	eq(TP.StepLabel(rows[1], nodes[102]), '10 Mental Dexterity R1')
	eq(TP.StepLabel(rows[2], nodes[108]), '11 Stormstrike', 'a one rank node has no R')
	eq(TP.StepLabel({ level = 27, rank = 2 }, { name = 'Improved Ghost Wolf', maxRanks = 2 }), '27 Improved Ghost Wolf R2')
	eq(TP.StepLabel(rows[1], nil), 'Missing talent')
	local view = { tree = { nodes = nodes }, plan = {}, rows = rows, summary = summary }
	eq(TP.StripText(view), 'Next: 10 Mental Dexterity R1', 'no level, so none is waiting')
	local learned = M.States({ steps = { 108 } }, { [108] = { committed = 1, staged = 1, maxRanks = 1 } }, 27)
	eq(TP.StripText({ tree = { nodes = nodes }, rows = learned, summary = { learned = 1, total = 1 } }), 'Plan complete')
	eq(TP.StripText({ tree = { nodes = nodes }, rows = {}, summary = { learned = 0, total = 0 } }), 'No plan')
	eq(TP.StripText({}), 'No plan')
	local missing, ms = M.States({ steps = { 999 } }, {}, 27)
	eq(TP.StripText({ tree = { nodes = {} }, rows = missing, summary = ms }), 'No plan', 'only a missing step: nothing to say')
end)

test('ScrollOffset', function()
	world()
	eq(TP.Layout.ScrollOffset(30, 20, 600, 1020), 380)
	eq(TP.Layout.ScrollOffset(1, 20, 600, 1020), 0)
	eq(TP.Layout.ScrollOffset(51, 20, 600, 1020), 420)
	eq(TP.Layout.ScrollOffset(5, 20, 100, 60), 0, 'a list that fits does not scroll')
end)

test('a color change puts the muted, danger and accent colors back', function()
	world({ tree = { ranks = TWELVE } })
	local plan = guide_plan()
	plan.steps[#plan.steps + 1] = 999
	open()
	stub.click(row(5), 'LeftButton')
	st.config.profile.colors.text.muted:SetRGB(0.2, 0.4, 0.6)
	st.config.profile.colors.text.danger:SetRGB(0.9, 0.2, 0.3)
	st.config.profile.theme.accent:SetRGB(0.1, 0.8, 0.5)
	st:ColorsChanged('text')
	st:ColorsChanged('accent')
	eq(select(2, row(1).name:GetTextColor()), 0.4, 'a learned name is the new muted')
	eq(select(1, row(21).name:GetTextColor()), 0.9, 'a missing one the new danger')
	local r, g, b = TP.panel.line:GetVertexColor()
	near(g, 0.8, 'the selection line follows the accent')
	clean()
end)

test("nothing is written onto Blizzard's frames, and nothing is bought", function()
	world({ tree = { ranks = TWELVE } })
	local plan = guide_plan()
	open()
	stub.click(row(2), 'LeftButton')
	stub.click(row(2), 'RightButton')
	choose(item(opened[#opened], 'Remove step'))
	TP:SetCollapsed(true); TP:SetCollapsed(false)
	PSF.redraw(); PSF.window:SetInspecting('target'); PSF.window:ClearInspectUnit()
	PSF.talents:SetTab(2); stub.run_timers()
	check(TP.panel:IsShown(), 'a spec tab with no config still shows')
	eq(TP.panel.count:GetText(), '', 'no plan on that tab')
	PSF.talents:SetTab(1); stub.run_timers()
	PSF.talents:Hide(); PSF.window:Hide(); stub.run_timers()
	eq(#plan.steps, 19)
	eq(next(PSF.clicks), nil, 'no talent button was clicked')
	clean()
end)

test('an out-of-order step shows blocked with its reason', function()
	world({ tree = { shape = true } })
	local plan = S.New('Wrong order', 1)
	-- an import in the wrong order: Flurry (row 2) before its five points
	plan.steps = { SH.ID.Flurry, SH.ID['Thundering Strikes'], SH.ID['Thundering Strikes'] }
	open()
	eq(row(1).tag:GetText(), 'blocked')
	stub.fire_script(row(1), 'OnEnter')
	eq(stub.state(GameTooltip).texts[1], 'Needs 5 points in Enhancement first.')
	stub.fire_script(row(1), 'OnLeave')
	eq(row(2).tag:GetText(), 'R1', 'a legal step is as before')
	eq(row(3).tag:GetText(), 'R2')
	check(TP.view.sim.steps[2].ok and not TP.view.sim.steps[1].ok, 'the simulation says which')
	-- the order mended, nothing is blocked
	plan.steps = { SH.ID['Thundering Strikes'], SH.ID['Thundering Strikes'], SH.ID['Thundering Strikes'],
		SH.ID['Thundering Strikes'], SH.ID['Thundering Strikes'], SH.ID.Flurry }
	TP:Refresh()
	eq(row(6).tag:GetText(), 'R1')
	clean()
end)
