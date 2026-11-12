-- The subtext line under a nameplate's name (SaftUI-Unitframes/nameplates/
-- subtext.lua): an NPC's title or a player's guild, in angle brackets.
--   - UF.NpcTitle: the tooltip's second line when it is an untyped (None),
--     plain, non-empty line that isn't the level line; anything else, a secret
--     text or type included, gives nil and no error;
--   - UF.PlateSubtext: by the unit's kind and the config's two boxes, with
--     nothing read for a kind whose box is off (no tooltip for an NPC), a
--     secret guild wrapped by the game and a secret UnitIsPlayer giving nil;
--   - the element on a plate: the st:subtext tag run for the config unit the
--     plate draws from, so a plate handed to another unit or kind shows the
--     new unit's line from the new config; its colour, width and place;
--   - the Subtext tab on both plate pages, and the defaults.
--
-- The world is nameplate_world.lua's (see its top): oUF's stand-in binds a tag
-- and never runs it, so a plate's line here is the st:subtext tag run with
-- the config unit its bound tag string names, as oUF runs it (the same as
-- friendly_plate_test.lua does for the name). Secrets are tests/lib/secrets.lua's.
local NP = load_test_file('unitframes/nameplate_world.lua')
local S = load_test_file('lib/secrets.lua')

local TYPE = { None = 0, UnitName = 2, UnitOwner = 16, UnitLevel = 47 }

local restoreSecrets
local function world(client)
	if restoreSecrets then restoreSecrets() end
	local st, UF = NP.world(client or 'forever')
	restoreSecrets = S.install()
	load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionswidgets.lua')
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	load_test_file('core/options_walk.lua')
	st.config.char = {}
	ReloadUI = function() end
	UF:SpawnNameplates()
	return st, UF, UF:GetProfileConfig()
end

-- A unit's tooltip, as C_TooltipInfo.GetUnit gives it: the lines are { type,
-- text } pairs.
local function tooltip(unit, ...)
	local lines = {}
	for i, pair in ipairs({ ... }) do lines[i] = { type = pair[1], leftText = pair[2] } end
	stub.tooltips[unit] = { lines = lines }
end
-- An NPC with its title as the game shows it: name, title, level line.
local function titled(unit, title)
	tooltip(unit, { TYPE.UnitName, 'Bob' }, { TYPE.None, title }, { TYPE.UnitLevel, 'Level 80 Humanoid' })
end

local function npc(unit, friend)
	stub.units[unit] = { name = 'Bob', friend = friend, attackable = not friend, reaction = friend and 5 or 2 }
end
local function player(unit, guild)
	stub.units[unit] = { name = 'Bob', friend = true, attackable = false, reaction = 5, player = true, guild = guild }
end

-- The line a plate shows: the st:subtext tag run as oUF runs the bound tag
-- string, with the config unit it names.
local function line(UF, frame)
	local base = (NP.ouf.tags[frame.Subtext] or ''):match('^%[st:subtext%((.-)%)%]$')
	return UF.oUF.Tags.Methods['st:subtext'](frame.__unit, frame.__unit, base)
end

local BOTH = { npc = true, player = true }

------------------------------------------------------------------ UF.NpcTitle

test("UF.NpcTitle: the tooltip's second line, between the name and the level line", function()
	local st, UF = world()
	titled('nameplate1', 'General Goods Vendor')
	eq(UF.NpcTitle('nameplate1'), 'General Goods Vendor', 'the title')

	-- Review focus 1: no title means the second line is the level line.
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { TYPE.UnitLevel, 'Level 80 Humanoid' })
	eq(UF.NpcTitle('nameplate1'), nil, 'a level line typed UnitLevel')
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { nil, 'Level 80 Humanoid' })
	eq(UF.NpcTitle('nameplate1'), nil, 'a level line with no type, known by its text')
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { TYPE.None, 'Level ?? Boss' })
	eq(UF.NpcTitle('nameplate1'), nil, 'an untyped boss level line')
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { nil, 'Level 80 (Elite) Humanoid' })
	eq(UF.NpcTitle('nameplate1'), nil, 'an untyped elite level line')
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { nil, 'Levelheaded Sage' })
	eq(UF.NpcTitle('nameplate1'), 'Levelheaded Sage', 'a title that only starts with the same letters is one')
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { nil, 'General Goods Vendor' })
	eq(UF.NpcTitle('nameplate1'), 'General Goods Vendor', 'an untyped line (no type at all) is a title')

	-- Review focus 5: a pet or guardian's owner line.
	tooltip('nameplate1', { TYPE.UnitName, 'Rex' }, { TYPE.UnitOwner, "Ann's Pet" }, { TYPE.UnitLevel, 'Level 10 Beast' })
	eq(UF.NpcTitle('nameplate1'), nil, "an owner line, \"Ann's Pet\"")

	tooltip('nameplate1', { TYPE.UnitName, 'Bob' })
	eq(UF.NpcTitle('nameplate1'), nil, 'one line only')
	stub.tooltips.nameplate1 = nil
	eq(UF.NpcTitle('nameplate1'), nil, 'no tooltip data')
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { TYPE.None, '' })
	eq(UF.NpcTitle('nameplate1'), nil, 'an empty second line')
	eq(#take_errors(), 0, 'no error')
end)

test('UF.NpcTitle: a secret line text or type gives nil, with no error', function()
	local st, UF = world()
	-- Review focus 2.
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { TYPE.None, S.secret('TEXT') })
	eq(UF.NpcTitle('nameplate1'), nil, 'a secret text')
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { S.secret('TYPE'), 'General Goods Vendor' })
	eq(UF.NpcTitle('nameplate1'), nil, 'a secret type')
	stub.tooltips.nameplate1 = { lines = S.secret('LINES') }
	eq(UF.NpcTitle('nameplate1'), nil, 'secret lines')
	stub.tooltips.nameplate1 = { lines = { {}, S.secret('LINE') } }
	eq(UF.NpcTitle('nameplate1'), nil, 'a secret line')
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ UF.PlateSubtext

test('UF.PlateSubtext: an NPC by the NPC box, and no tooltip read while it is off', function()
	local st, UF = world()
	npc('nameplate1', true)
	titled('nameplate1', 'General Goods Vendor')
	eq(UF.PlateSubtext('nameplate1', BOTH), '<General Goods Vendor>', 'brackets round the title')
	eq(UF.PlateSubtext('nameplate1', { npc = true, player = false }), '<General Goods Vendor>', 'by the NPC box alone')

	-- Review focus 3: with the box off nothing is read.
	local reads = stub.tooltip_reads
	eq(UF.PlateSubtext('nameplate1', { npc = false, player = true }), nil, 'the NPC box off: nothing')
	eq(UF.PlateSubtext('nameplate1', {}), nil, 'no boxes: nothing')
	eq(stub.tooltip_reads, reads, 'and C_TooltipInfo.GetUnit not called')

	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { TYPE.UnitLevel, 'Level 80 Humanoid' })
	eq(UF.PlateSubtext('nameplate1', BOTH), nil, 'an NPC with no title: nothing')
	eq(#take_errors(), 0, 'no error')
end)

test('UF.PlateSubtext: a player by the player box, with no guild, an empty one or a secret one', function()
	local st, UF = world()
	player('nameplate1', 'Some Guild')
	titled('nameplate1', 'Not A Title')
	eq(UF.PlateSubtext('nameplate1', { player = true }), '<Some Guild>', 'brackets round the guild')

	local reads = stub.tooltip_reads
	eq(UF.PlateSubtext('nameplate1', { player = false, npc = true }), nil, 'the player box off: nothing, not an NPC title either')
	eq(stub.tooltip_reads, reads, 'and C_TooltipInfo.GetUnit not called')
	eq(UF.PlateSubtext('nameplate1', BOTH), '<Some Guild>', 'a player never reads the tooltip')
	eq(stub.tooltip_reads, reads, 'even with both boxes on')

	-- Review focus 5: a guildless player.
	player('nameplate2')
	eq(UF.PlateSubtext('nameplate2', BOTH), nil, 'no guild (nil)')
	player('nameplate2', '')
	eq(UF.PlateSubtext('nameplate2', BOTH), nil, 'an empty guild name')

	-- Review focus 2: a secret guild is wrapped by the game, not read.
	local guild = S.secret('GUILD')
	player('nameplate3', guild)
	local wrapped = UF.PlateSubtext('nameplate3', BOTH)
	eq(wrapped.wrapped, guild, 'the secret guild wrapped')
	eq(wrapped.prefix .. wrapped.suffix, '<>', 'in its brackets')
	eq(UF.PlateSubtext('nameplate3', { player = false, npc = true }), nil, 'a secret guild with the box off: nothing')

	-- Review focus 2: a secret UnitIsPlayer.
	local real = UnitIsPlayer
	UnitIsPlayer = function() return S.secret('ISPLAYER') end
	reads = stub.tooltip_reads
	eq(UF.PlateSubtext('nameplate1', BOTH), nil, 'a secret UnitIsPlayer: nothing')
	eq(stub.tooltip_reads, reads, 'and no tooltip read')
	UnitIsPlayer = real
	eq(#take_errors(), 0, 'no error')
end)

test('the st:subtext tag: the line, or an empty string, and a secret one handed back as it is', function()
	local st, UF = world()
	local tag = UF.oUF.Tags.Methods['st:subtext']
	eq(UF.oUF.Tags.Events['st:subtext'], 'UNIT_NAME_UPDATE PLAYER_GUILD_UPDATE', 'its events')
	npc('nameplate1', true)
	titled('nameplate1', 'General Goods Vendor')
	eq(tag('nameplate1', 'nameplate1', 'friendlynameplate'), '<General Goods Vendor>', 'by the friendly config')
	eq(tag('nameplate1', 'nameplate1', 'nameplate'), '', "'' by the enemy config, whose boxes are off")
	eq(tag('nameplate1', 'nameplate1', 'nosuchunit'), '', "'' for a config unit that isn't there")
	local P = UF:GetProfileConfig()
	P.friendlynameplate.subtext = nil
	eq(tag('nameplate1', 'nameplate1', 'friendlynameplate'), '', "'' for a config with no subtext")
	P.friendlynameplate.subtext = { npc = true, player = true }
	player('nameplate2', S.secret('GUILD'))
	eq(tag('nameplate2', 'nameplate2', 'friendlynameplate').prefix, '<', 'a secret line goes back wrapped')
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ the element on a plate

test('a plate: a friendly NPC shows its title by default, an enemy NPC nothing and no tooltip read', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF = world(client)
		npc('nameplate1', true)
		titled('nameplate1', 'General Goods Vendor')
		local frame = NP.add('nameplate1')
		eq(frame.base_unit, 'friendlynameplate', client .. ': a friendly plate')
		eq(NP.ouf.tags[frame.Subtext], '[st:subtext(friendlynameplate)]', client .. ': the tag names the friendly config')
		eq(line(UF, frame), '<General Goods Vendor>', client .. ': the title in brackets')
		eq(frame.Subtext:IsShown(), true, client .. ': shown')

		npc('nameplate2', false)
		titled('nameplate2', 'General Goods Vendor')
		local reads = stub.tooltip_reads
		local enemy = NP.add('nameplate2')
		eq(enemy.base_unit, 'nameplate', client .. ': an enemy plate')
		eq(NP.ouf.tags[enemy.Subtext], '[st:subtext(nameplate)]', client .. ': the tag names the enemy config')
		eq(line(UF, enemy), '', client .. ': an empty line with the default settings')
		eq(stub.tooltip_reads, reads, client .. ': no tooltip read for it')
		eq(enemy.Subtext:IsShown(), true, client .. ': shown (an empty line)')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('a plate handed to another unit shows the new unit\'s line, never the old one\'s', function()
	local st, UF = world()
	npc('nameplate1', true)
	titled('nameplate1', 'General Goods Vendor')
	local frame = NP.add('nameplate1', { plate = nil })
	eq(line(UF, frame), '<General Goods Vendor>', 'the NPC first')
	NP.remove('nameplate1')

	player('nameplate2', 'Some Guild')
	local again = NP.add('nameplate2', { plate = 1 })
	eq(again, frame, 'the same frame')
	eq(line(UF, again), '<Some Guild>', "a guilded player's guild, not the vendor's title")
	NP.remove('nameplate2')

	npc('nameplate3', true)
	tooltip('nameplate3', { TYPE.UnitName, 'Bob' }, { TYPE.UnitLevel, 'Level 80 Humanoid' })
	again = NP.add('nameplate3', { plate = 1 })
	eq(again, frame, 'the same frame again')
	eq(line(UF, again), '', 'a titleless NPC: nothing')
	NP.remove('nameplate3')

	player('nameplate4')
	again = NP.add('nameplate4', { plate = 1 })
	eq(line(UF, again), '', 'a guildless player: nothing')
	eq(#take_errors(), 0, 'no error')
end)

test("a plate that turns hostile reads the enemy config, and a friendly one with 'use enemy' reads the enemy page", function()
	local st, UF, P = world()
	-- Review focus 4.
	npc('nameplate1', true)
	titled('nameplate1', 'General Goods Vendor')
	local frame = NP.add('nameplate1')
	eq(line(UF, frame), '<General Goods Vendor>', 'friendly: its title')

	P.nameplate.subtext.npc = true
	npc('nameplate1', false)
	stub.fire_event('UNIT_FACTION', 'nameplate1')
	eq(frame.base_unit, 'nameplate', 'now an enemy')
	eq(NP.ouf.tags[frame.Subtext], '[st:subtext(nameplate)]', 'the tag bound again, to the enemy config')
	eq(line(UF, frame), '<General Goods Vendor>', "the enemy unit's title, from the enemy config's box")

	P.nameplate.subtext.npc = false
	eq(line(UF, frame), '', "the enemy box off: nothing, whatever the friendly config says")
	P.nameplate.subtext.npc = true

	npc('nameplate1', true)
	stub.fire_event('UNIT_FACTION', 'nameplate1')
	eq(frame.base_unit, 'friendlynameplate', 'friendly again')
	eq(NP.ouf.tags[frame.Subtext], '[st:subtext(friendlynameplate)]', 'bound back')

	-- The box: a friendly plate drawn from the Enemy page.
	P.friendlynameplate.use_enemy = true
	P.nameplate.subtext.npc = false
	UF:UpdateConfig('nameplate')
	eq(frame.base_unit, 'nameplate', 'the box: drawn from the enemy page')
	eq(line(UF, frame), '', "a friendly plate reads the enemy page's boxes (npc off)")
	P.nameplate.subtext.npc = true
	eq(line(UF, frame), '<General Goods Vendor>', "and its box on")
	eq(#take_errors(), 0, 'no error')
end)

test("the font string: the config's colour, a width with no word wrap, and its place under the name", function()
	local st, UF, P = world()
	npc('nameplate1', true)
	local frame = NP.add('nameplate1')
	local text = frame.Subtext
	eq(table.concat({ text:GetTextColor() }, ','), '0.8,0.8,0.8,1', 'the config colour')
	eq(text:GetWidth(), 150, 'its width the friendly max width')
	eq(text:CanWordWrap(), false, 'one line')
	local point, relative, relPoint, x, y = text:GetPoint(1)
	eq(point, 'TOP', 'its TOP')
	eq(relative, frame.Name, 'on the name')
	eq(relPoint, 'BOTTOM', "to the name's BOTTOM")
	eq(x .. ',' .. y, '0,-2', 'at 0, -2')

	-- The enemy one.
	npc('nameplate2', false)
	local enemy = NP.add('nameplate2')
	local ePoint, eRelative, eRelPoint, ex, ey = enemy.Subtext:GetPoint(1)
	eq(ePoint .. eRelPoint .. ex .. ',' .. ey, 'TOPBOTTOM0,-24', "an enemy's: TOP to BOTTOM at 0, -24")
	eq(eRelative, enemy.Health, "of the health bar's")
	eq(enemy.Subtext:GetWidth(), 200, 'its width the enemy max width')

	-- A change applies.
	P.friendlynameplate.subtext.color = { r = 1, g = 0, b = 0 }
	P.friendlynameplate.subtext.max_width = 0
	UF:UpdateConfig('friendlynameplate', 'Subtext')
	eq(table.concat({ text:GetTextColor() }, ','), '1,0,0,1', 'a new colour')
	eq(text:CanWordWrap(), true, 'max width 0: wrapping again')
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ fix round 1

test('UF.NpcTitle: a secret line type is never compared, not even with the enum', function()
	local st, UF = world()
	local enum = Enum.TooltipDataLineType
	Enum.TooltipDataLineType = setmetatable({}, { __index = function(_, k) error('compared a secret type with ' .. k) end })
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { S.secret('TYPE'), 'General Goods Vendor' })
	local ok, title = pcall(UF.NpcTitle, 'nameplate1')
	Enum.TooltipDataLineType = enum
	eq(ok, true, 'no error')
	eq(title, nil, 'and no title')
end)

test("UF.NpcTitle: the level pattern is anchored, and a global string with no text of its own builds none", function()
	local st, UF = world()
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { nil, 'Master of Level Design' })
	eq(UF.NpcTitle('nameplate1'), 'Master of Level Design', 'a title that has "Level" inside it is a title')

	TOOLTIP_UNIT_LEVEL = '%s'
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { nil, 'General Goods Vendor' })
	eq(UF.NpcTitle('nameplate1'), 'General Goods Vendor', "a '%s' format matches nothing, so an untyped title still comes back")
	TOOLTIP_UNIT_LEVEL = nil
	eq(UF.NpcTitle('nameplate1'), 'General Goods Vendor', 'and with no global string at all')
	TOOLTIP_UNIT_LEVEL = 'Level %s'
	tooltip('nameplate1', { TYPE.UnitName, 'Bob' }, { nil, 'Level 80 Humanoid' })
	eq(UF.NpcTitle('nameplate1'), nil, 'the real format still finds the level line')
	eq(#take_errors(), 0, 'no error')
end)

test("the tag bound to the other kind's config unit reads nothing: a hand-off's updates before the rebinding", function()
	local st, UF, P = world()
	-- An enemy unit, the tag still bound to the Friendly page (npc on there, off on the Enemy page).
	npc('nameplate1', false)
	titled('nameplate1', 'General Goods Vendor')
	local tag = UF.oUF.Tags.Methods['st:subtext']
	local reads = stub.tooltip_reads
	eq(tag('nameplate1', 'nameplate1', 'friendlynameplate'), '', "an enemy unit under the Friendly binding: ''")
	eq(stub.tooltip_reads, reads, 'and no tooltip read')
	eq(tag('nameplate1', 'nameplate1', 'nameplate'), '', 'under its own binding the Enemy box is off: nothing either')
	eq(stub.tooltip_reads, reads, 'and no tooltip read')

	-- The mirror: a friendly unit bound to the Enemy page, whose boxes are on and the Friendly ones off.
	P.nameplate.subtext.npc = true
	P.friendlynameplate.subtext.npc = false
	npc('nameplate2', true)
	titled('nameplate2', 'General Goods Vendor')
	eq(tag('nameplate2', 'nameplate2', 'nameplate'), '', "a friendly unit under the Enemy binding: ''")
	eq(stub.tooltip_reads, reads, 'and no tooltip read')

	-- With the boxes' "use the other page" settings the binding that counts follows them.
	P.friendlynameplate.use_enemy = true
	eq(tag('nameplate2', 'nameplate2', 'nameplate'), '<General Goods Vendor>', "use_enemy: the friendly unit's plate draws from the Enemy page")
	eq(tag('nameplate2', 'nameplate2', 'friendlynameplate'), '', 'and the Friendly binding is the stale one')
	eq(#take_errors(), 0, 'no error')
end)

test('a plate that draws from the other page: an enemy NPC with nameplate.use_friendly shows its title from the Friendly boxes', function()
	local st, UF, P = world()
	P.nameplate.use_friendly = true
	UF:UpdateConfig('nameplate')
	npc('nameplate1', false)
	titled('nameplate1', 'General Goods Vendor')
	local frame = NP.add('nameplate1')
	eq(frame.base_unit, 'friendlynameplate', 'drawn from the Friendly page')
	eq(P.nameplate.subtext.npc, false, 'the Enemy box is off')
	eq(NP.ouf.tags[frame.Subtext], '[st:subtext(friendlynameplate)]', 'bound to the Friendly page')
	eq(line(UF, frame), '<General Goods Vendor>', 'its title, by the Friendly npc box')
	eq(#take_errors(), 0, 'no error')
end)

test("a rebind updates the tags at once, with the new binding in place", function()
	local st, UF, P = world()
	npc('nameplate1', true)
	local frame = NP.add('nameplate1')
	local seen = {}
	frame.UpdateTags = function(self) seen[#seen + 1] = NP.ouf.tags[self.Subtext] end
	P.friendlynameplate.use_enemy = true
	UF:UpdateConfig('nameplate')
	eq(frame.base_unit, 'nameplate', 'the plate draws from the Enemy page now')
	eq(seen[#seen], '[st:subtext(nameplate)]', 'the last UpdateTags came after the new binding')
	local count = #seen
	UF:UpdateConfig('nameplate')
	eq(#seen, count, 'and an update that changes nothing rebinds nothing')
	eq(#take_errors(), 0, 'no error')
end)

------------------------------------------------------------------ the page and the defaults

test('the Subtext tab on both plate pages, its options in order, and the box that hides it', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, UF, P = world(client)
		for _, unit in ipairs({ 'nameplate', 'friendlynameplate' }) do
			local root = { Unitframes = UF:GetConfigTable() }
			local group = root.Unitframes.args[unit].args.Subtext
			check(group ~= nil, client .. ': ' .. unit .. ' has a Subtext group')
			eq(group.name, 'Subtext', client .. ': ' .. unit .. ': named')
			local view = SaftUI.OptionsModel.BuildView(root, 'Unitframes', { pick = unit, tab = 'Subtext' })
			eq(view.tab, 'Subtext', client .. ': ' .. unit .. ': opens')
			local keys = {}
			for _, section in ipairs(view.sections) do
				for _, row in ipairs(section.rows) do keys[#keys + 1] = row.key end
			end
			eq(table.concat(keys, ','), 'npc,player,font,color,alpha,max_width,position', client .. ': ' .. unit .. ': its options')
			eq(group.args.npc.name, 'NPC titles', client .. ': the NPC box named')
			eq(group.args.npc.desc, "Shows an NPC's title, such as General Goods Vendor, under its name.", client .. ': its desc')
			eq(group.args.player.name, 'Player guilds', client .. ': the player box named')
			eq(group.args.player.desc, "Shows a player's guild under their name.", client .. ': its desc')
			eq(group.args.enable, nil, client .. ': ' .. unit .. ': no Enable option')
			eq(group.order, root.Unitframes.args[unit].args.Name.order + 0.5, client .. ': right after Name')
			check(group.order < root.Unitframes.args[unit].args.Castbar.order, client .. ': before Castbar')
		end

		-- The Friendly page: setting npc off clears a shown title.
		npc('nameplate1', true)
		titled('nameplate1', 'General Goods Vendor')
		local frame = NP.add('nameplate1')
		eq(line(UF, frame), '<General Goods Vendor>', client .. ': shown')
		local updates = frame.__updates
		local root = { Unitframes = UF:GetConfigTable() }
		local view = SaftUI.OptionsModel.BuildView(root, 'Unitframes', { pick = 'friendlynameplate', tab = 'Subtext' })
		local row
		for _, section in ipairs(view.sections) do
			for _, r in ipairs(section.rows) do if r.key == 'npc' then row = r end end
		end
		SaftUI.OptionsModel.Set(root, row, false)
		eq(P.friendlynameplate.subtext.npc, false, client .. ': the Friendly config written')
		eq(P.nameplate.subtext.npc, false, client .. ': the enemy config untouched')
		check(frame.__updates > updates, client .. ': the plate updated, which runs the tag again')
		eq(line(UF, frame), '', client .. ': the title cleared')

		-- The box hides the tab with the rest of the page.
		P.friendlynameplate.use_enemy = true
		root = { Unitframes = UF:GetConfigTable() }
		view = SaftUI.OptionsModel.BuildView(root, 'Unitframes', { pick = 'friendlynameplate', tab = 'general' })
		local tabs = {}
		for i, tab in ipairs(view.tabs) do tabs[i] = tab.key end
		eq(table.concat(tabs, ','), 'general', client .. ': only General while the Friendly box is checked')
		P.friendlynameplate.use_enemy = false
		P.nameplate.use_friendly = true
		root = { Unitframes = UF:GetConfigTable() }
		view = SaftUI.OptionsModel.BuildView(root, 'Unitframes', { pick = 'nameplate', tab = 'general' })
		tabs = {}
		for i, tab in ipairs(view.tabs) do tabs[i] = tab.key end
		eq(table.concat(tabs, ','), 'general,Threat', client .. ': no Subtext while the Enemy box is checked')
		eq(#take_errors(), 0, client .. ': no error')
	end
end)

test('the defaults: both boxes on for friendly plates, off for enemy ones, in a fresh profile', function()
	local st, UF, P = world()
	eq(P.friendlynameplate.subtext.npc, true, 'friendly npc')
	eq(P.friendlynameplate.subtext.player, true, 'friendly player')
	eq(P.nameplate.subtext.npc, false, 'enemy npc')
	eq(P.nameplate.subtext.player, false, 'enemy player')
	eq(P.friendlynameplate.subtext.enable, true, 'always enabled: the boxes decide')
	eq(P.nameplate.subtext.enable, true, 'always enabled: the boxes decide')
	eq(P.friendlynameplate.subtext.font, P.friendlynameplate.name.font, "the name's font")
	eq(P.nameplate.subtext.font, P.nameplate.name.font, "the name's font")
	eq(P.friendlynameplate.subtext.max_width .. ',' .. P.nameplate.subtext.max_width, '150,200', 'max widths')
	eq(P.nameplate.subtext.position.y_off, -24, "the enemy's place under the castbar's row")
	eq(restoreSecrets ~= nil, true, 'secrets installed')
	restoreSecrets()
	restoreSecrets = nil
end)
