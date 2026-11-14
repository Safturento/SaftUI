-- SaftUI-Tracker's switch (tracker.enable, off by default):
--   - the TOC (both clients, Core required, Misc optional), every file it
--     lists, Bindings.xml and the binding's strings;
--   - off: enabling builds no frame, hooks nothing, registers no event or
--     mover; Blizzard's tracker, its skin and its mover as they are without
--     the addon;
--   - the switch is read once: set in /sui it saves, asks for a reload and
--     builds nothing now; on at login stays on whatever the profile says later;
--   - another tracker addon loaded: on builds nothing, and the page says which;
--   - a profile whose switch differs says once in chat that it changes after a
--     reload, and not again on a theme change;
--   - Level's default: on on Forever, off on retail.
-- On both clients where it matters.
--
-- Real: SaftUI-Tracker's files, Core's helpers and edit mode, the options
-- kit's dialog (the reload question), and Misc's config, skin and mover.
local TW = load_test_file('tracker/tracker_world.lua')

local function printed(fn)
	local real, lines = print, {}
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

local function chat_lines(lines)
	local n = 0
	for _, line in ipairs(lines) do
		if line:find("SaftUI's tracker changes after a reload.", 1, true) then n = n + 1 end
	end
	return n
end

test('the TOC: both clients, Core required, Misc first, every listed file exists; Bindings.xml and its strings', function()
	local toc = read_saftui_source('SaftUI-Tracker/SaftUI-Tracker.toc')
	check(toc, 'the TOC is there')
	local header = {}
	for line in toc:gmatch('(##[^\n]*)') do header[#header + 1] = line end
	eq(table.concat(header, '\n'), table.concat({
		'## Interface: 120000, 16001',
		'## Version: 1.0',
		'## Title: |cff00adefSaftUI Tracker|r',
		'## RequiredDeps: SaftUI-Core',
		'## OptionalDeps: SaftUI-Misc',
		'## Group: SaftUI-Core',
	}, '\n'), 'the TOC header')
	local files = TW.toc_files()
	eq(files[1], 'SaftUI-Tracker/config.lua', 'config first')
	eq(files[2], 'SaftUI-Tracker/init.lua', 'then init')
	eq(files[#files], 'SaftUI-Tracker/options.lua', 'options last')
	for _, file in ipairs(files) do
		check(read_saftui_source(file) ~= nil, file .. ' exists')
	end

	local xml = read_saftui_source('SaftUI-Tracker/Bindings.xml')
	check(xml, 'Bindings.xml is there')
	check(xml:find('name="CLICK SaftUITrackerNearestItem:LeftButton"', 1, true), 'the CLICK binding')
	check(xml:find('header="SAFTUI"', 1, true), 'under the SAFTUI header')
	check(xml:find('category="BINDING_HEADER_SAFTUI"', 1, true), "in SaftUI's own category: the game titles a section by _G[category]")

	local _, TR = TW.world({})
	eq(BINDING_HEADER_SAFTUI, 'SaftUI', 'the header string')
	eq(TR.NEAREST_COMMAND, 'CLICK SaftUITrackerNearestItem:LeftButton', 'the command')
	eq(_G['BINDING_NAME_' .. TR.NEAREST_COMMAND], 'Use the nearest quest item', 'the binding name')
end)

test('off by default: enabling builds no frame, hooks nothing, registers no event or mover', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local before, timers
		local st, TR = TW.world({ client = client, misc = { skinning = true, skin = true, otp = true }, blizzard = true,
			enabling = function() before, timers = TW.snapshot(ObjectiveTrackerFrame), #stub.timers end })
		local where = client .. ': '
		eq(TW.snapshot(ObjectiveTrackerFrame), before, where .. "Blizzard's tracker: points, shown, parent, alpha and scripts as before")
		eq(TW.counts.scripts, 0, where .. 'no script set')
		eq(TW.counts.timers, 0, where .. 'no timer')
		eq(#stub.timers, timers, where .. 'no timer pending')
		eq(st.config.profile.tracker.enable, false, where .. 'the switch defaults off')
		eq(TW.counts.frames, 0, where .. 'no frame')
		eq(TW.counts.hooks, 0, where .. 'no hook')
		eq(TW.counts.events, 0, where .. 'no event')
		eq(TW.counts.secure, 0, where .. 'no secure frame')
		eq(st.EditModeFrames.movers.tracker, nil, where .. 'no mover')
		eq(TR:IsOn(), false, where .. 'off')
		check(not TR.built, where .. 'not built')
		eq(#take_errors(), 0, where .. 'no errors')
		check(TW.OTP and TW.OTP.holder, where .. "Blizzard's tracker keeps its mover")
	end
end)

test('the switch is read once: set on in /sui it saves, asks to reload, and builds nothing now', function()
	local st, TR = TW.world({})
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	local W = st.OptionsWidgets
	local general = TR:GetConfigTable().args.general
	general.args.enable.set({ 'Tracker', 'general', 'enable' }, true)
	eq(st.config.profile.tracker.enable, true, 'saved')
	eq(W.ConfirmText(), "SaftUI's tracker changes after a reload. Reload now?", 'asks for a reload')
	eq(TR:IsOn(), false, 'still off this session')
	check(not TR.built, 'nothing built')
	eq(TW.counts.frames, 0, 'no frame')
	W.CancelConfirm()
	eq(#take_errors(), 0, 'no errors')
end)

test('on at login, IsOn stays on whatever the profile says later', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = TW.world({ client = client, on = true })
		eq(TR:IsOn(), true, client .. ': on')
		check(TR.built, client .. ': built')
		st.config.profile.tracker.enable = false
		eq(TR:IsOn(), true, client .. ': still on')
		local st2, TR2 = TW.world({ client = client })
		eq(TR2:IsOn(), false, client .. ': off')
		st2.config.profile.tracker.enable = true
		eq(TR2:IsOn(), false, client .. ': still off')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('another tracker addon: on builds nothing; the page is disabled with the line naming it; each folder has its label', function()
	local labels = {
		['!KalielsTracker'] = "Kaliel's Tracker", EQObjectiveTracker = 'EQ Objective Tracker',
		KaLiQuest = 'KaLi Quest', AuraQuestor = 'Aura Questor', ForeverQuestTracker = 'ForeverQuestTracker',
	}
	local order = {}
	local _, TR0 = TW.world({})
	for i, entry in ipairs(TR0.TRACKER_ADDONS) do order[i] = entry.addon end
	eq(table.concat(order, ','), '!KalielsTracker,EQObjectiveTracker,KaLiQuest,AuraQuestor,ForeverQuestTracker', "Ruling 22's order")
	for addon, label in pairs(labels) do
		local st, TR = TW.world({ on = true, addons = { addon } })
		eq(TR:TrackerAddon(), label, addon .. "'s label")
		eq(TR:IsOn(), false, addon .. ': off')
		check(not TR.built, addon .. ': not built')
		eq(TW.counts.frames, 0, addon .. ': no frame')
		eq(TW.counts.hooks, 0, addon .. ': no hook')
		local page = TR:GetConfigTable()
		eq(page.disabled(), true, addon .. ': the page is disabled')
		eq(page.args.tracked_by.name, ('Quests are tracked by %s. Turn it off to use SaftUI\'s.'):format(label), addon .. ': the line')
		eq(page.args.tracked_by.disabled, false, addon .. ': the line is read at full strength')
	end
	-- Two of them: the first in the list is named.
	local _, TR = TW.world({ on = true, addons = { 'AuraQuestor', 'EQObjectiveTracker' } })
	eq(TR:TrackerAddon(), 'EQ Objective Tracker', 'the first in the list')
	-- None loaded: no line, and a page not disabled.
	local _, TR2 = TW.world({ on = true })
	local page = TR2:GetConfigTable()
	eq(page.disabled, nil, 'the page is not disabled')
	eq(page.args.tracked_by, nil, 'no line')
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile whose switch differs says once in chat that it changes after a reload, not again on a theme change', function()
	local st, TR = TW.world({})
	local profile = st.config.profile
	eq(chat_lines(printed(function() TR:UpdateConfig() end)), 0, 'the same switch says nothing')
	profile.tracker.enable = true
	eq(chat_lines(printed(function() TR:UpdateConfig() end)), 1, 'a different one says so')
	eq(chat_lines(printed(function() TR:UpdateConfig() end)), 0, 'a theme change does not repeat it')
	eq(chat_lines(printed(function() TR:UpdateConfig() end)), 0, 'nor another')
	profile.tracker.enable = false
	eq(chat_lines(printed(function() TR:UpdateConfig() end)), 0, 'back to the session value says nothing')
	profile.tracker.enable = true
	eq(chat_lines(printed(function() TR:UpdateConfig() end)), 1, 'a different one again says so')

	-- On at login, a profile with it off.
	local st2, TR2 = TW.world({ on = true })
	st2.config.profile.tracker.enable = false
	eq(chat_lines(printed(function() TR2:UpdateConfig() end)), 1, 'the other way round too')
	eq(chat_lines(printed(function() TR2:UpdateConfig() end)), 0, 'once')
	eq(#take_errors(), 0, 'no errors')
end)

test('Level is on on Forever and off on retail', function()
	local st = TW.world({ client = 'forever' })
	eq(st.defaults.tracker.quests.level, true, 'Forever')
	eq(st.config.profile.tracker.quests.level, true, 'Forever profile')
	local st2 = TW.world({ client = 'retail' })
	eq(st2.defaults.tracker.quests.level, false, 'retail')
	eq(st2.config.profile.tracker.quests.level, false, 'retail profile')
end)

test('CharData: per character, made on first use', function()
	local st, TR = TW.world({})
	local data = TR:CharData()
	eq(data.collapsed, false)
	check(type(data.zones) == 'table' and next(data.zones) == nil, 'no zones')
	eq(st.config.char.tracker, data, 'kept in st.config.char.tracker')
	data.zones.Elwynn = true
	eq(TR:CharData().zones.Elwynn, true, 'the same table')
end)

test("the world loads as the game does: the Tracker module exists when Misc's tracker mover enables, with the switch and combat already set", function()
	local seen
	local st = TW.world({
		on = true, combat = true, misc = { skinning = true, skin = true, otp = true }, blizzard = true,
		before = function(st)
			local OTP = st:GetModule('ObjectiveTracker')
			local OnEnable = OTP.OnEnable
			OTP.OnEnable = function(self, ...)
				local TR = st:GetModule('Tracker', true)
				seen = {
					module = TR ~= nil, bound = TR and TR.config ~= nil,
					config = st.config ~= nil, enable = st.config and st.config.profile.tracker and st.config.profile.tracker.enable,
					combat = stub.in_combat,
				}
				-- Misc asks before TR:OnEnable has run (Ruling 5).
				seen.answer = TR and TR:IsOn()
				return OnEnable(self, ...)
			end
		end,
	})
	check(seen, "Misc's mover enabled")
	eq(seen.module, true, 'the Tracker module exists')
	eq(seen.bound, false, 'its OnEnable has not run')
	eq(seen.config, true, 'st.config exists by then')
	eq(seen.enable, true, 'opts.on is applied before any module enables')
	eq(seen.combat, true, 'opts.combat too')
	eq(seen.answer, true, 'IsOn answers before OnEnable, and the same after')
	eq(st:GetModule('Tracker'):IsOn(), true)
	eq(#take_errors(), 0, 'no errors')
end)

test('the files load before the profile exists: a file-scope read of st.config fails, as at login', function()
	local seen
	TW.world({ before = function(st) seen = function() return st.config end end })
	check(seen, 'ran')
	-- A tracker file that reads the profile while it loads errors in the world.
	local real = read_saftui_source
	local seen_config
	TW.world({ before = function(st)
		local NewModule = st.NewModule
		st.NewModule = function(self, name, ...)
			if name == 'Tracker' then seen_config = st.config end
			return NewModule(self, name, ...)
		end
	end })
	eq(seen_config, nil, "st.config isn't there while init.lua loads")
end)

test('the TOC reader fails loudly on a line it does not understand', function()
	local real = read_saftui_source
	read_saftui_source = function(path)
		if path == 'SaftUI-Tracker/SaftUI-Tracker.toc' then return '## Interface: 1\n\nconfig.lua\nmodel.xml\n' end
		return real(path)
	end
	local ok, err = pcall(TW.toc_files)
	read_saftui_source = real
	eq(ok, false, 'an XML line is not skipped')
	check(tostring(err):find('model.xml', 1, true), 'it names the line')
end)

test('an installed addon that is not loaded does not stand the tracker down', function()
	local _, TR = TW.world({ on = true, before = function() stub.installed_addons['!KalielsTracker'] = true end })
	eq(TR:TrackerAddon(), nil, 'not loaded: no label')
	eq(TR:IsOn(), true, 'on')
	check(TR.built, 'built')
end)

test('answering No to the reload question: a later theme change does not say it again', function()
	local st, TR = TW.world({})
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	local W = st.OptionsWidgets
	local enable = TR:GetConfigTable().args.general.args.enable
	local lines = printed(function()
		enable.set({}, true)
		eq(W.ConfirmText(), "SaftUI's tracker changes after a reload. Reload now?", 'asked')
		W.CancelConfirm()
		TR:UpdateConfig() -- a theme change
		TR:UpdateConfig()
	end)
	eq(chat_lines(lines), 0, 'no chat line for a value the player just set and declined')
	-- A profile whose switch differs for another reason still says it, once.
	st.config.profile.tracker.enable = false
	eq(chat_lines(printed(function() TR:UpdateConfig() end)), 0, 'back to the session value: nothing')
	-- Unticked at login-on: set false, decline, theme change.
	local st2, TR2 = TW.world({ on = true })
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	local enable2 = TR2:GetConfigTable().args.general.args.enable
	local lines2 = printed(function()
		enable2.set({}, false)
		st2.OptionsWidgets.CancelConfirm()
		TR2:UpdateConfig()
	end)
	eq(chat_lines(lines2), 0, 'the same unticking an on switch')
end)

test("the switch's reset asks about a reload as ticking does, and says nothing after", function()
	local st, TR = TW.world({ on = true })
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	local enable = TR:GetConfigTable().args.general.args.enable
	check(enable.default.differs(), 'on differs from the default')
	local lines = printed(function()
		enable.default.reset()
		eq(st.config.profile.tracker.enable, false, 'reset to off')
		eq(st.OptionsWidgets.ConfirmText(), "SaftUI's tracker changes after a reload. Reload now?", 'asked')
		st.OptionsWidgets.CancelConfirm()
		TR:UpdateConfig()
	end)
	eq(chat_lines(lines), 0, 'no chat line')
end)

test('standing down: the chat line and the tabs say it is for that addon', function()
	local st, TR = TW.world({ on = true, addons = { '!KalielsTracker' } })
	st.config.profile.tracker.enable = false
	local lines = printed(function() TR:UpdateConfig() end)
	eq(chat_lines(lines), 0, 'no "changes after a reload"')
	local named = 0
	for _, line in ipairs(lines) do
		if line:find("stands down for Kaliel's Tracker", 1, true) then named = named + 1 end
	end
	eq(named, 1, 'it names the addon, once')
	eq(#printed(function() TR:UpdateConfig() end), 0, 'not again')
	local tab = TR.Tab(2, 'Quests', {})
	eq(tab.disabledDesc(), "Quests are tracked by Kaliel's Tracker. Turn it off to use SaftUI's.", "the tabs' hover text")
	local _, TR2 = TW.world({})
	eq(TR2.Tab(2, 'Quests', {}).disabledDesc(), "Turn on SaftUI's tracker (General) and reload.", 'no addon: the switch')
end)
