-- SaftUI-Misc/TalentPlan/options.lua: the talent plan's page in /sui. The world
-- is the overlays test's (see it for what is real and what is made by hand).
local T = load_test_file('lib/theme_helpers.lua')
local SH = load_test_file('misc/fixtures/talentplan_shaman.lua')
local PSF = load_test_file('misc/fixtures/player_spells_frame.lua')

local st, TP, R

local FILES = { 'talentplan', 'model', 'parser', 'store', 'data', 'drag', 'panel', 'import', 'overlays' }

local function world(client)
	st = T.client(client or 'forever')
	stub.class, stub.level = 'SHAMAN', 27
	st.config.global, st.config.char = {}, {}
	load_test_file('lib/options_walk.lua') -- after the fresh world: it defines a global
	load_options_widgets()
	R = load_test_file('lib/reset_walk.lua') -- it keeps the SaftUI it finds
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
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
	for _, file in ipairs(FILES) do load_saftui('SaftUI-Misc/TalentPlan/' .. file .. '.lua') end
	load_saftui('SaftUI-Misc/TalentPlan/options.lua') -- load.xml's last file
	load_saftui('SaftUI-Misc/movable.lua')
	TP = st:GetModule('TalentPlan')
	TP.Data.ResetSnapshots()
	if (client or 'forever') ~= 'forever' then return end
	SH.install()
	create('Frame', 'SettingsPanel', UIParent)
	create('Frame', 'AddonList', UIParent)
	PSF.build()
	st:GetModule('Movable'):Enable()
	TP:Enable()
	PSF.load()
end

test('the page reads and writes its keys and resets', function()
	world()
	local page = TP:GetConfigTable()
	eq(page.category, 'Info')
	R.check_page({ TalentPlan = page }, 'TalentPlan')
	local general = page.args.general
	eq(general.args.enable.order, 1)
	eq(general.args.dim.order, 2)
	eq(general.args.compact.order, 3)
	eq(general.args.compact.name, 'Compact talent window')

	PSF.open()
	stub.run_timers()
	eq(general.get({ 'general', 'dim' }), true)
	general.set({ 'general', 'dim' }, false)
	eq(st.config.profile.talentplan.dim, false)
	eq(TP.refreshQueued, true, 'one refresh queued')
	stub.run_timers()
	eq(TP.refreshQueued, false)
	eq(#take_errors(), 0)
end)

test('the compact switch is saved in talentwindow, not talentplan', function()
	world()
	local compact = TP:GetConfigTable().args.general.args.compact
	eq(compact.get(), true)
	compact.set({ 'general', 'compact' }, false)
	eq(st.config.profile.talentwindow.compact, false)
	eq(st.config.profile.talentplan.compact, nil)
end)

test('Enable off hides the panel and overlays', function()
	world()
	PSF.open()
	stub.run_timers()
	check(TP.panel:IsShown(), 'the panel shows')
	TP:SetPlanning(true)
	local general = TP:GetConfigTable().args.general
	general.set({ 'general', 'enable' }, false)
	stub.run_timers()
	check(not TP.panel:IsShown(), 'the panel is hidden')
	eq(TP.planning, false, 'planning is off')
	eq(TP.view, nil)
	for _, r in pairs(TP.overlays) do
		check(not r.catcher:IsShown(), 'no catcher')
		check(not r.light:IsShown() and not r.glow:IsShown() and not r.dim:IsShown(), 'no overlay')
	end
	general.set({ 'general', 'enable' }, true)
	stub.run_timers()
	check(TP.panel:IsShown(), 'on again, the panel is back')
	eq(#take_errors(), 0)
end)

test('no page on retail', function()
	world('retail')
	eq(TP:GetConfigTable(), nil)
end)
