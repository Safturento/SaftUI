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
	check(xml:find('category="ADDONS"', 1, true), 'in the ADDONS category')

	local _, TR = TW.world({})
	eq(BINDING_HEADER_SAFTUI, 'SaftUI', 'the header string')
	eq(TR.NEAREST_COMMAND, 'CLICK SaftUITrackerNearestItem:LeftButton', 'the command')
	eq(_G['BINDING_NAME_' .. TR.NEAREST_COMMAND], 'Use the nearest quest item', 'the binding name')
end)

test('off by default: enabling builds no frame, hooks nothing, registers no event or mover', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = TW.world({ client = client, misc = { skinning = true, skin = true, otp = true }, blizzard = true })
		local where = client .. ': '
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
