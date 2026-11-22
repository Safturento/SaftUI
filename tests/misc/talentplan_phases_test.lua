-- Phases and the drag in SaftUI-Misc/TalentPlan/panel.lua and drag.lua: the
-- Phases button, the headers and their menu, the level colors, and a handle's
-- drag. The world is the panel test's (see talentplan_panel_test.lua), with a
-- menu stand-in that has submenus.
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
			local function describe(list)
				local description = {}
				function description:CreateButton(text, onClick)
					local entry = { kind = 'button', text = text, a = onClick, list = {} }
					list[#list + 1] = entry
					entry.CreateRadio = function(_, t, a, b) local r = { kind = 'radio', text = t, a = a, b = b }; entry.list[#entry.list + 1] = r; return r end
					return entry
				end
				function description:CreateRadio(text, isSelected, setSelected) return add('radio', text, isSelected, setSelected) end
				function description:CreateDivider() return add('divider') end
				return description
			end
			generator(owner, describe(root.list))
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
	for _, file in ipairs({ 'talentplan', 'model', 'parser', 'store', 'data', 'drag', 'panel' }) do
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

local function plan20()
	local plan = S.New('Enhancement', 1)
	local steps = TP.Parse(GUIDE, SH.NAMES).steps
	for i = 1, 20 do plan.steps[i] = steps[i] end
	return plan
end

local function answer(text)
	W.PromptBox():SetText(text)
	stub.click(W.GetDialogFrames().yes, 'LeftButton')
end

local function entry(i) return TP.panel.entries[i].frame end

-- A handle dragged onto a frame's upper or lower half, the mouse held between.
local function drag(from, onto, lower)
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(entry(from).handle, 'OnMouseDown', 'LeftButton')
	if onto then
		local l, b, width, h = onto:GetRect()
		local scale = onto:GetEffectiveScale()
		stub.cursor_x = (l + width / 2) * scale
		stub.cursor_y = (b + (lower and 0.25 or 0.75) * h) * scale
	else
		stub.cursor_x, stub.cursor_y = 0, 0
	end
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(entry(from).handle, 'OnMouseUp', 'LeftButton')
end

test('the Phases button adds a named, colored header at the selection', function()
	world()
	local plan = plan20()
	open()
	TP.selected = 3
	stub.click(TP.panel.phasesButton, 'LeftButton')
	eq(W.ConfirmText(), 'Name the phase')
	eq(W.PromptBox():GetText(), 'Phase 1')
	answer('Core')
	eq(#plan.phases, 1)
	eq(plan.phases[1].at, 3); eq(plan.phases[1].name, 'Core'); eq(plan.phases[1].color, 'blue')
	local header = TP.panel.headers[1]
	check(header:IsShown(), 'the header shows')
	eq(header.name:GetText(), 'Core')
	eq(header.range:GetText(), '12-29')
	eq(header.pos, 3, 'between step 2 and step 3')
	eq(header.dot:GetWidth(), 8)
	eq(#TP.panel.entries, 21)
	clean()
end)

test('the Phases button with no selection starts at step 1, and with no plan does nothing', function()
	world()
	open()
	stub.click(TP.panel.phasesButton, 'LeftButton')
	eq(W.PromptBox(), nil, 'no plan, no prompt')
	local plan = plan20()
	TP:Refresh()
	stub.click(TP.panel.phasesButton, 'LeftButton')
	answer('First')
	eq(plan.phases[1].at, 1)
	stub.click(TP.panel.phasesButton, 'LeftButton')
	eq(W.PromptBox():GetText(), 'Phase 2')
	answer('Second')
	eq(plan.phases[2].color, 'orange', 'the next color not in use')
	eq(TP.panel.headers[1].range:GetText(), '', 'an empty phase reads blank')
	eq(TP.panel.headers[2].range:GetText(), '10-29')
	clean()
end)

test("a phase's rows wear its color on the level", function()
	world()
	local plan = plan20()
	plan.phases[1] = { at = 3, name = 'Core', color = 'blue' }
	open()
	local blue = M.PHASE_RGB.blue
	local r, g, b = row(3).level:GetTextColor()
	eq(r, blue[1]); eq(g, blue[2]); eq(b, blue[3])
	r, g, b = row(20).level:GetTextColor()
	eq(r, blue[1], 'to the end')
	local normal = st:Color('text', 'normal')
	eq(select(1, row(2).level:GetTextColor()), normal.r, 'before the phase: Text > Normal')

	clean()
end)

test('the header menu renames, recolors and removes', function()
	world()
	local plan = plan20()
	plan.phases[1] = { at = 3, name = 'Core', color = 'blue' }
	open()
	stub.click(TP.panel.headers[1], 'RightButton')
	local menu = opened[#opened]
	eq(texts(menu), 'Rename|Color|Remove phase')
	choose(item(menu, 'Rename'))
	eq(W.PromptBox():GetText(), 'Core')
	answer('Main')
	eq(plan.phases[1].name, 'Main'); eq(TP.panel.headers[1].name:GetText(), 'Main')
	local colors = item(menu, 'Color')
	eq(#colors.list, 5)
	eq(colors.list[1].text, 'Blue'); eq(colors.list[5].text, 'Green')
	check(colors.list[1].a(), 'blue is the current one')
	colors.list[4].b()
	eq(plan.phases[1].color, 'red')
	local red = M.PHASE_RGB.red
	eq(select(1, row(5).level:GetTextColor()), red[1], 'the rows follow')
	choose(item(menu, 'Remove phase'))
	eq(#plan.phases, 0)
	check(not TP.panel.headers[1]:IsShown(), 'the header is gone')
	eq(#plan.steps, 20, 'the steps stay')
	clean()
end)

test('dragging a row reorders the plan, the ghost and the line show, and the header regroups', function()
	world()
	local plan = plan20()
	plan.phases[1] = { at = 3, name = 'Core', color = 'blue' }
	open()
	-- entries: s1 s2 H s3 ...; step 1 to just under step 3 (entry 4)
	local first, third = plan.steps[1], plan.steps[3]
	stub.mouse_buttons.LeftButton = true
	stub.fire_script(entry(1).handle, 'OnMouseDown', 'LeftButton')
	local w = TP.dragWidget
	check(w.drag ~= nil, 'a drag starts')
	check(w.ghost:IsShown(), 'the ghost shows')
	eq(w.ghost.text:GetText(), TP.StepLabel(TP.view.rows[1], TP.view.tree.nodes[first]))
	local l, b, width, h = entry(4):GetRect()
	local scale = entry(4):GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = (l + width / 2) * scale, (b + 0.25 * h) * scale
	TP:DrawDrag()
	check(w.insert:IsShown(), 'the insert line shows')
	stub.mouse_buttons.LeftButton = nil
	stub.fire_script(entry(1).handle, 'OnMouseUp', 'LeftButton')
	check(not w.ghost:IsShown() and not w.insert:IsShown(), 'both gone')
	eq(plan.steps[3], first, 'step 1 now third')
	eq(plan.steps[2], third)
	eq(plan.phases[1].at, 2, 'the header stays before the old third step')
	stub.run_timers()
	eq(TP.panel.headers[1].pos, 2)
	-- the header dragged to the top
	drag(2, entry(1), false)
	eq(plan.phases[1].at, 1)
	-- a step dropped at the very end leaves the headers sensible
	drag(1, entry(#TP.panel.entries), true)
	clean()
end)

test('a drag release with nothing under the cursor changes nothing', function()
	world()
	local plan = plan20()
	open()
	local before = table.concat(plan.steps, ',')
	drag(3, nil)
	eq(table.concat(plan.steps, ','), before)
	check(TP.dragWidget.drag == nil, 'the drag is over')
	-- a drop on its own place changes nothing either
	drag(3, entry(3), true); drag(3, entry(3), false)
	eq(table.concat(plan.steps, ','), before)
	clean()
end)

test('a drag does not start while the panel is hidden', function()
	world()
	plan20()
	open()
	local handle = entry(2).handle
	PSF.talents:Hide()
	stub.fire_script(handle, 'OnMouseDown', 'LeftButton')
	check(TP.dragWidget.drag == nil, 'no drag')
	clean()
end)

test('moving the selected step moves the selection with it', function()
	world()
	plan20()
	open()
	TP.selected = 1
	drag(1, entry(4), true)
	eq(TP.selected, 4)
	clean()
end)
