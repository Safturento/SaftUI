-- SaftUI-Misc/TalentPlan/import.lua: TP:ApplyImport (replace or new) and the
-- import dialog's summary and Import button. Real: Misc's TalentPlan files,
-- Core's helpers and widgets, movable.lua. Made by hand: Blizzard's talent
-- window (misc/fixtures/player_spells_frame.lua), the trait stubs, the game's
-- menu and ScrollFrameTemplate's scroll bar, as talentplan_panel_test.lua does.
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
		-- InputBoxTemplate isn't in the stubs: a plain edit box with the font string it gives
		if template == 'InputBoxTemplate' then
			local box = create(frameType, name, parent, nil, ...)
			box:CreateFontString(nil, 'OVERLAY')
			return box
		end
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
	load_saftui('SaftUI-Core/Widgets/editbox.lua')
	load_saftui('SaftUI-Core/Widgets/radiogroup.lua')
	if not _G.GameTooltip then create('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	for _, file in ipairs({ 'talentplan', 'model', 'parser', 'store', 'data', 'panel', 'import' }) do
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


local function open()
	PSF.open()
	stub.run_timers()
end

local function guide() return TP.Parse(GUIDE, SH.NAMES) end

test('replace keeps the plan and clears phases', function()
	world()
	open()
	local before = S.New('Enhancement', 1)
	before.phases = { { name = 'Phase 1', level = 20 } }
	local plan = TP:ApplyImport(guide(), 'replace', '', 1)
	eq(plan.id, before.id)
	eq(#plan.steps, 51)
	eq(#plan.phases, 0)
	eq(#take_errors(), 0, 'no errors')
end)

test('new makes a named, active plan', function()
	world()
	open()
	local r = guide()
	local one = TP:ApplyImport(r, 'new', '', 1)
	eq(one.name, 'Imported')
	eq(S.Active(1), one, 'active')
	eq(#one.steps, 51)
	eq(TP:ApplyImport(r, 'new', '', 1).name, 'Imported 2')
	eq(TP:ApplyImport(r, 'new', 'Mine', 1).name, 'Mine')
end)

test('replace with no plan makes one', function()
	world()
	open()
	local plan = TP:ApplyImport(guide(), 'replace', '', 1)
	eq(plan.name, 'Imported')
	eq(S.Active(1), plan)
	eq(#plan.steps, 51)
end)

test('the summary text the dialog shows', function()
	world()
	open()
	TP:OpenImport()
	local f = TP.importFrame
	check(f:IsShown(), 'shown')
	eq(f:GetFrameStrata(), 'DIALOG')
	check(not f.import:IsEnabled(), 'Import is off with an empty box')
	eq(f.hint:IsShown(), true, 'the hint shows while empty')
	f.box:SetText(GUIDE)
	stub.fire_script(f.box, 'OnTextChanged', true)
	eq(f.summary:GetText():match('^[^\n]*'), '51 steps, levels 10 to 60.')
	check(f.import:IsEnabled(), 'Import is on')
	eq(f.hint:IsShown(), false, 'the hint hides')
	f.box:SetText('')
	stub.fire_script(f.box, 'OnTextChanged', true)
	check(not f.import:IsEnabled(), 'Import is off again')
	eq(f.summary:GetText(), 'No talents found.')
	eq(#take_errors(), 0, 'no errors')
end)

test('Import applies to a new plan when none is active, and closes', function()
	world()
	open()
	TP:OpenImport()
	local f = TP.importFrame
	eq(f.mode, 'new', 'New plan is chosen without an active plan')
	f.box:SetText(GUIDE)
	stub.fire_script(f.box, 'OnTextChanged', true)
	stub.click(f.import)
	check(not f:IsShown(), 'closed')
	local plan = S.Active(1)
	eq(plan.name, 'Imported')
	eq(#plan.steps, 51)
	eq(#take_errors(), 0, 'no errors')
end)

test('Import replaces the active plan when one exists; Cancel and hiding close', function()
	world()
	open()
	local before = S.New('Enhancement', 1)
	TP:OpenImport()
	local f = TP.importFrame
	eq(f.mode, 'replace')
	f.box:SetText(GUIDE)
	stub.fire_script(f.box, 'OnTextChanged', true)
	stub.click(f.import)
	eq(S.Active(1), before)
	eq(#before.steps, 51)
	TP:OpenImport()
	check(f:IsShown(), 'reopened')
	eq(f.box:GetText(), '', 'with an empty box')
	stub.click(f.cancel)
	check(not f:IsShown(), 'Cancel closes')
	TP:OpenImport()
	PSF.talents:Hide()
	check(not f:IsShown(), 'closes when the talent window hides')
	eq(#take_errors(), 0, 'no errors')
end)

test('the Esc catcher propagates keys once built and once closed, and the box scrolls to its end', function()
	world()
	open()
	TP:OpenImport()
	local f = TP.importFrame
	check(stub.state(f.keys).propagate_keyboard, 'propagates when built')
	f.box:ClearFocus()
	stub.fire_script(f.keys, 'OnKeyDown', 'ESCAPE')
	check(not f:IsShown(), 'Esc closes')
	check(stub.state(f.keys).propagate_keyboard, 'propagates again once closed')
	TP:OpenImport()
	f.box:SetText(GUIDE)
	eq(f.scroll.ScrollChild:GetHeight(), f.box:GetHeight(), 'the scroll content follows the box')
	eq(#take_errors(), 0, 'no errors')
end)
