-- SaftUI-Unitframes/config/config.lua's /sui pieces: the Copy from dialog
-- (UF:OpenCopyTable, drawn by st.OptionsWindow:OpenDialog: its rows, its
-- layout under each theme, Cancel), the order of the
-- units in the page's picker, AceConfigRegistry's validation of the table, and
-- each unit's element tabs (the elements' GetConfigTable).
--
-- Real: Core's helpers and profile defaults (load_core_helpers), the unit
-- frames' defaults, filled the way AceDB fills them (apply_defaults), so a
-- unit's settings are made by reading them, as in game; AceConfigRegistry-3.0
-- (the options window listens to it); the options model, widgets, body and
-- window; config/position.lua, config/profiles.lua, config/groupoptions.lua,
-- config/config.lua, updaters.lua (UF.UnpackColor) and the element files,
-- whose tabs config.lua adds to each unit that has the element;
-- nameplates/nameplates.lua (UF:NameplateAddon, which the nameplate pages
-- read; with no other nameplate addon loaded, SaftUI draws the plates) and
-- nameplates/threat.lua (the plates' Threat element and its tab),
-- nameplates/subtext.lua (their Subtext tab) and
-- nameplates/options.lua (the nameplate pages).
--
-- Stand-ins, for unitframes.lua, which needs oUF:
--   * UF:UpdateConfig counts its calls. The real one re-applies every unit
--     frame from the profile.
--   * UF:RegisterElement, a copy of unitframes.lua's table store, so the
--     element files load: their tabs come from it. The elements themselves
--     (their Constructor and UpdateConfig) need oUF and aren't run here.
--   * What its OnEnable makes, as far as UF:GetConfigTable reads it: UF.units
--     and UF.groups, a frame by config unit (boss is a list of five frames in
--     game), UF.holders for the groups, and UF:GetMoverFrame (unitframes.lua's:
--     the holder, else the unit's frame). The frames have no elements, so an
--     element Position's dropdown lists every registered element.
--   * UF.unit_strings, unitframes.lua's (arena has no page, so no name), and
--     UF.group_strings, which is also unitframes.lua's, as the Ready check element's ValidUnit reads it;
--     so are UF.PLATE_UNITS and UF.IsPlateUnit, which Power's and the role
--     indicators' ValidUnit read.
--   * UF.oUF, as far as tags.lua uses it: oUF's tag tables, where tags.lua
--     registers its st:name tag (oUF calls the tag with the unit, the real
--     unit and the tag's argument, the config unit), and the class colors
--     (oUF's own, into which UF:UpdateColors merges the profile's; here the
--     profile's). The tag reads the unit through the stubbed unit API
--     (stub.units).
--
-- AceConfigRegistry validates ace_ready (tests/lib/options_walk.lua) of the
-- table: a copy without SaftUI's own fields and Position options.
local PW = load_test_file('unitframes/page_world.lua').world()
local T, st, OM, OW, W, UF, AceConfigRegistry, OF = PW.T, PW.st, PW.OM, PW.OW, PW.W, PW.UF, PW.AceConfigRegistry, PW.OF
local updates = 0
-- unitframes.lua's two lines for sharing, as page_world.lua's stand-in has them.
function UF:UpdateConfig(unit, element)
	updates = updates + 1
	if unit == 'all' then return self:PropagateShared(element) end
	if not unit then self:PrepareShared() end
end

local click = stub.click

-- The dialog's drawn rows' keys, in order.
local function rows()
	local out = {}
	for i, c in ipairs(OW.GetDialogFrames().body.cells) do out[i] = c.row.key end
	return out
end

local function cell(key)
	for _, c in ipairs(OW.GetDialogFrames().body.cells) do
		if c.row.key == key then return c end
	end
end

-- The game's nameplate settings (nameplates/cvars.lua, which this world doesn't load): what the Nameplates
-- and Friendly plates rows' sets call, so the walk can set them.
function UF:ApplyNameplateCVars() end
function UF:RestoreNameplateCVars() end

-- Every row of every unit's page has a reset (the kit derives it from where the row is saved), and each
-- derived one round-trips. First, on the profile as it starts: no case before this changes a value.
local R = load_test_file('lib/reset_walk.lua')
-- The walk's round trips compare the whole profile with a copy twice per derived row, so a walk of
-- every unit at once is far over the harness's limit for one case. One cheap walk of every row
-- (probe = false: each has a source, a default, and is at it on this fresh profile), then the
-- round trips for a few units, each its own case.
local function Page(units)
	local tree = UF:GetConfigTable()
	if units then
		local args = {}
		for _, unit in ipairs(units) do args[unit] = tree.args[unit] end
		tree.args = args
	end
	return { Unitframes = tree }
end

test('every unit frame row has a reset', function()
	R.check_page(Page(), 'Unitframes', { probe = false })
end)

for _, unit in ipairs({ 'player', 'target', 'party', 'raid10', 'boss', 'nameplate', 'friendlynameplate' }) do
	test(unit .. "'s derived resets round-trip", function()
		R.check_page(Page({ unit }), 'Unitframes')
	end)
end

test('resets round-trip on a unit frame profile of another name, and only that profile is written', function()
	local profiles = st.config.profile.unitframes.profiles
	local first = st.config.profile.unitframes.config_profile
	local _ = profiles.Healer
	local before = profiles[first].player.health.enable
	st.config.profile.unitframes.config_profile = 'Healer'
	R.check_page(Page({ 'player' }), 'Unitframes')
	eq(st.config.profile.unitframes.config_profile, 'Healer', 'still on Healer')
	st.config.profile.unitframes.config_profile = first
	rawset(profiles, 'Healer', nil)
	eq(profiles[first].player.health.enable, before, "the first profile's value is untouched")
end)

-- The row at path ({ 'Unitframes', 'player', 'Health', 'enable' }) in the options tree root, as the model reads it.
local function RowAt(root, path)
	local group = { args = root }
	for _, key in ipairs(path) do group = OM.SubOption(group, key) end
	return { option = group, path = path, type = group.type, key = path[#path] }
end

test('resets on a unit frame profile of another name write that profile, and leave the first untouched', function()
	local profiles = st.config.profile.unitframes.profiles
	local first = st.config.profile.unitframes.config_profile
	-- A profile made from the '**' defaults, as New makes one.
	local healer = profiles.Healer
	st.config.profile.unitframes.config_profile = 'Healer'
	local root = { Unitframes = UF:GetConfigTable() }
	local row = RowAt(root, { 'Unitframes', 'player', 'Health', 'enable' })
	local _, defaultValue = st:DefaultAt('unitframes', 'profiles', 'Healer', 'player', 'health', 'enable')
	eq(select(3, UF.SavedAt('player', 'health', 'enable')({})), 'Healer', "the row's saved path names the profile in use")
	check(not OM.DefaultDiffers(root, row), 'a fresh Healer profile has the default')
	local firstValue = profiles[first].player.health.enable
	healer.player.health.enable = not defaultValue
	check(OM.DefaultDiffers(root, row), 'Healer differs from the default after a change')
	check(OM.DefaultReset(root, row), 'its reset ran')
	eq(healer.player.health.enable, defaultValue, "the default is back in Healer's profile")
	eq(profiles[first].player.health.enable, firstValue, "the first profile's value is untouched")
	check(not OM.DefaultDiffers(root, row), 'and the row is at its default again')
	st.config.profile.unitframes.config_profile = first
	rawset(profiles, 'Healer', nil)
end)

test("the player's Power position resets though its default X is half a pixel", function()
	local root = { Unitframes = UF:GetConfigTable() }
	local row = RowAt(root, { 'Unitframes', 'player', 'Power', 'bar', 'position' })
	local position = UF:GetProfileConfig().player.power.position
	-- (The walk before has already rounded the profile's own to a whole pixel.)
	eq(select(2, st:DefaultAt('unitframes', 'profiles', UF:GetProfile(), 'player', 'power', 'position', 'x_off')), 0.5, 'the default is the half pixel')
	check(not OM.DefaultDiffers(root, row), 'at the default')
	check(OM.WriteValue(root, row, { point = position.point, rel_point = position.rel_point, frame = position.frame,
		x_off = 3, y_off = position.y_off }), 'moved by 3')
	check(OM.DefaultDiffers(root, row), 'it differs')
	check(OM.DefaultReset(root, row), 'its reset ran')
	check(not OM.DefaultDiffers(root, row), 'it is at its default again, though a set rounds the half pixel')
end)

test("a part's position resets to the merged default: the castbar's Text and Time are anchored to Castbar, target's Buffs sit 7 up", function()
	local root = { Unitframes = UF:GetConfigTable() }
	local P = UF:GetProfileConfig()
	for _, case in ipairs({
		{ { 'Unitframes', 'player', 'Castbar', 'text', 'position' }, function() return P.player.castbar.text.position end, 'Castbar', nil },
		{ { 'Unitframes', 'player', 'Castbar', 'time', 'position' }, function() return P.player.castbar.time.position end, 'Castbar', nil },
		{ { 'Unitframes', 'target', 'Auras', 'Buffs', 'position' }, function() return P.target.buffs.position end, nil, 7 },
	}) do
		local path, position, element, y = case[1], case[2], case[3], case[4]
		local row = RowAt(root, path)
		local label = table.concat(path, '.')
		check(not OM.DefaultDiffers(root, row), label .. ' is at its default on a fresh profile')
		local was = {}
		for key, value in pairs(position()) do was[key] = value end
		-- Move it: another offset, and its anchor put on Global frame.
		check(OM.WriteValue(root, row, { point = was.point, rel_point = was.rel_point, x_off = 11, y_off = 12, frame = 'UIParent' }), label .. ' moved')
		check(OM.DefaultDiffers(root, row), label .. ' differs once moved')
		check(OM.DefaultReset(root, row), label .. ' reset ran')
		check(not OM.DefaultDiffers(root, row), label .. ' is at its default again')
		eq(position().element or false, element or false, label .. ': its element is the default one')
		eq(position().frame or false, was.frame or false, label .. ': no global frame')
		eq(position().x_off, was.x_off, label .. ': X is back')
		eq(position().y_off, was.y_off, label .. ': Y is back')
		if y then eq(position().y_off, y, label .. ': the merged default Y') end
	end
end)

test("the aura borders are saved once per hostility: their reset puts each hostility's own default back", function()
	local root = { Unitframes = UF:GetConfigTable() }
	local P = UF:GetProfileConfig()
	for _, case in ipairs({ { 'Buffs', 'buffs', 'colorStealable', 'enemy' }, { 'Debuffs', 'debuffs', 'colorTypes', 'friend' } }) do
		local tab, key, flag, on = case[1], case[2], case[3], case[4]
		local row = RowAt(root, { 'Unitframes', 'target', 'Auras', tab, 'buttons', 'border' })
		local config = P.target[key]
		check(config[on][flag], tab .. ': ' .. on .. ' has it on by default')
		check(not OM.DefaultDiffers(root, row), tab .. ': at its default')
		check(OM.WriteValue(root, row, false), tab .. ': turned off')
		check(not config.friend[flag] and not config.enemy[flag], tab .. ': off for both')
		check(OM.DefaultDiffers(root, row), tab .. ': differs')
		local before = updates
		check(OM.DefaultReset(root, row), tab .. ': reset')
		check(updates > before, tab .. ': the frames were told, as a set tells them')
		check(config[on][flag], tab .. ': ' .. on .. ' is on again')
		check(not (config.friend[flag] and config.enemy[flag]), tab .. ': only its own hostility, as the default has it')
		check(not OM.DefaultDiffers(root, row), tab .. ': at its default again')
	end
end)

test('Copy from opens a SaftUI dialog whose rows come from its table, and copies what was ticked', function()
	local P = UF:GetProfileConfig()
	P.player.width, P.target.width = 1, 123
	P.player.height, P.target.height = 34, 50
	P.player.health.height, P.target.health.height = 0, 7

	UF:OpenCopyTable('player')
	check(OW:IsDialogShown(), 'a SaftUI dialog')
	local d = OW.GetDialogFrames()
	eq(d.title:GetText(), 'Copy to Player from', 'its title')

	-- Copy from, All and None, a toggle per setting of the unit's, Confirm copy and Cancel.
	local keys = rows()
	eq(table.concat(keys, ',', 1, 3), 'copy_from,toggle_all,toggle_none', 'the unit to copy from, All, None')
	eq(keys[#keys - 1] .. ',' .. keys[#keys], 'accept,cancel', 'Confirm copy, then Cancel, last')
	local got = {}
	for i = 4, #keys - 2 do got[#got + 1] = keys[i] end
	table.sort(got)
	-- Only what player's config has and its page names: not Aura watch, Portrait or
	-- Range (no element reads the first two, a single unit has no Range section) or
	-- Ready check (a group-only element), which would copy nothing.
	eq(table.concat(got, ','), 'additionalpower,background,buffs,castbar,classpower,debuffs,enable,grouproleindicator,health,height,name,position,power,questindicator,raidroleindicator,raidtargetindicator,theme,width', "a toggle per part of player's")
	check(#got > 10, 'many of them: ' .. #got)
	for i = 4, #keys - 2 do
		local size = cell(keys[i]).row.size
		check(size == nil or size == 'normal', keys[i] .. ' is a normal toggle, so its label has half the line: ' .. tostring(size))
	end
	check(cell('accept').widget:IsDisabled(), 'Confirm copy waits for a unit')

	-- Pick target.
	click(cell('copy_from').widget.frame)
	local list, picked = W.GetListFrames(), false
	for _, row in ipairs(list.rows) do
		check(not (row:IsShown() and row.text:GetText() == 'Player'), 'player is not offered')
		if row:IsShown() and row.text:GetText() == 'Target' then
			click(row)
			picked = true
			break
		end
	end
	check(picked, 'target is offered')
	eq(d.title:GetText(), 'Copy to Player from Target', 'the title says so')
	check(not cell('accept').widget:IsDisabled(), 'Confirm copy is on')

	-- Only what Target's page names too is offered now: Additional power and
	-- Class power are Player's alone, and have no value on Target to copy.
	local offered = rows()
	check(#offered < #keys, 'the settings only Player has are gone')
	keys = offered
	check(cell('additionalpower') == nil and cell('classpower') == nil, 'Additional power and Class power are not offered')

	-- All, then None, then width and health.
	click(cell('toggle_all').widget.frame)
	local all = true
	for i = 4, #keys - 2 do all = all and cell(keys[i]).widget.value end
	check(all, 'All ticks every setting')
	click(cell('toggle_none').widget.frame)
	local none = true
	for i = 4, #keys - 2 do none = none and not cell(keys[i]).widget.value end
	check(none, 'None clears them')
	click(cell('width').widget.frame)
	click(cell('health').widget.frame)
	check(cell('width').widget.value and cell('health').widget.value, 'width and health ticked')

	-- Confirm copy asks first, in SaftUI's confirm dialog.
	local before = updates
	click(cell('accept').widget.frame)
	eq(W.ConfirmText(), 'Are you sure you want to copy the ticked settings to Player from Target?', 'it asks')
	eq(P.player.width, 1, 'nothing copied before Yes')
	click(W.GetDialogFrames().yes)
	eq(P.player.width, 123, 'width copied')
	eq(P.player.health.height, 7, 'health copied')
	check(P.player.health ~= P.target.health, 'as a copy, not the same table')
	eq(P.player.height, 34, "height wasn't ticked")
	eq(updates, before + 1, 'the unit frames were updated once')
	check(not OW:IsDialogShown(), 'the dialog closed')
end)

test("opening Copy from again starts over, with the new unit's settings", function()
	UF:OpenCopyTable('target')
	local d = OW.GetDialogFrames()
	eq(d.title:GetText(), 'Copy to Target from', 'a new title')
	for _, key in ipairs(rows()) do
		local c = cell(key)
		if c.row.type == 'toggle' then check(not c.widget.value, key .. ' starts unticked') end
	end
	check(cell('accept').widget:IsDisabled(), 'no unit picked yet')
	OW:CloseDialog()
end)

-- What Copy from calls each setting: the name /sui shows for that part (its
-- tab's, or the option's or section's in General), or, for a part no page
-- names (Aura watch, Portrait), one of its own.
local COPY_LABELS = {
	additionalpower = 'Additional power', aurawatch = 'Aura watch', background = 'Background', buffs = 'Buffs',
	castbar = 'Cast bar', classpower = 'Class power', columnSpacing = 'Column spacing', debuffs = 'Debuffs',
	enable = 'Enable', growthDirection = 'Growth', grouproleindicator = 'Group role', health = 'Health',
	height = 'Height', initialAnchor = 'Column growth', maxColumns = 'Max columns', name = 'Name',
	portrait = 'Portrait', position = 'Position', power = 'Power', questindicator = 'Quest',
	raidroleindicator = 'Raid role', raidtargetindicator = 'Raid target', range_alpha = 'Range',
	readycheckindicator = 'Ready check', showPlayer = 'Show player', spacing = 'Spacing', theme = 'Theme',
	unitsPerColumn = 'Units per column', width = 'Width',
}

local COPY_UNITS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss',
	'party', 'raid10', 'raid40' }

test("Copy from lists only parts the unit has and its page names, and only units that have a page", function()
	for _, unit in ipairs(COPY_UNITS) do
		UF:OpenCopyTable(unit)
		local P = UF:GetProfileConfig()[unit]
		local keys = rows()
		for i = 4, #keys - 2 do
			check(rawget(P, keys[i]) ~= nil, unit .. ': ' .. keys[i] .. ' is in its defaults')
		end
		for _, dead in ipairs({ 'aurawatch', 'portrait', 'auras' }) do
			check(cell(dead) == nil, unit .. ': no ' .. dead .. ' (nothing reads it)')
		end
		if not UF.group_strings[unit] then check(cell('range_alpha') == nil, unit .. ': no Range on a single unit') end
		for _, entry in ipairs(OM.Values(OW.GetDialogFrames().body.root, cell('copy_from').row)) do
			check(UF.unit_strings[entry.key] or UF.group_strings[entry.key], entry.key .. ' has a page and a display name')
			check(entry.name ~= entry.key, entry.key .. ' is not named by its key')
			check(entry.key ~= 'arena', 'arena is not offered')
		end
		OW:CloseDialog()
	end
	check(UF:GetProfileConfig().arena ~= nil, 'arena is in the profile, so this is what leaves it out')
	check(rawget(st.defaults.unitframes.profiles['**'].pettarget, 'auras') == nil, "pet target has no dead auras key")
end)

test("Copy from's settings carry the names /sui shows for them, in sentence case and sorted by name; the title and the list name the units", function()
	for _, unit in ipairs(COPY_UNITS) do
		UF:OpenCopyTable(unit)
		local keys = rows()
		local labels = {}
		for i = 4, #keys - 2 do
			local c = cell(keys[i])
			local want = COPY_LABELS[keys[i]]
			check(want ~= nil, unit .. ': ' .. keys[i] .. ' has a name in the table above')
			eq(c.row.name, want or keys[i], unit .. ': ' .. keys[i])
			eq(c.label:GetText(), c.row.name, unit .. ': drawn as its label')
			check(c.row.name:find('^%u[^%u]*$') ~= nil, unit .. ': ' .. c.row.name .. ' in sentence case')
			labels[#labels + 1] = c.row.name
		end
		local sorted = {}
		for i, label in ipairs(labels) do sorted[i] = label end
		table.sort(sorted, function(a, b) return a:upper() < b:upper() end)
		eq(table.concat(labels, ','), table.concat(sorted, ','), unit .. ': sorted by name')
		OW:CloseDialog()
	end

	UF:OpenCopyTable('player')
	local d = OW.GetDialogFrames()
	eq(d.title:GetText(), 'Copy to Player from', 'the title names the unit as its page does')
	local offered = {}
	for _, entry in ipairs(OM.Values(d.body.root, cell('copy_from').row)) do
		offered[entry.name] = entry.key
		eq(entry.name, UF.unit_strings[entry.key] or UF.group_strings[entry.key] or entry.key, entry.key .. ': named as its page is')
	end
	eq(offered.Target, 'target', 'Target, by its name')
	eq(offered.target, nil, 'not by its key')
	cell('copy_from').widget:Commit('target')
	eq(d.title:GetText(), 'Copy to Player from Target', 'and the unit picked')
	click(cell('toggle_all').widget.frame)
	click(cell('accept').widget.frame)
	eq(W.ConfirmText(), 'Are you sure you want to copy the ticked settings to Player from Target?', 'Confirm copy asks by name')
	click(W.GetDialogFrames().no)
	OW:CloseDialog()
end)

-- Where a drawn cell starts in the dialog's content.
local function left(c)
	local _, _, _, x = c.frame:GetPoint(1)
	return x
end

-- The vertical dividers drawn in the dialog, as their y in the content.
local function divider_ys()
	local ys = {}
	-- Under Blizzard they are OB.LINE's, under Thick and Thin the panel's hairlines.
	local pools = OW.GetDialogFrames().body.pools
	for _, pool in ipairs({ pools.line, pools.hairline }) do
		for _, line in ipairs(pool.used) do
			if line:GetWidth() == 1 then
				local _, _, _, _, y = line:GetPoint(1)
				ys[-y] = true
			end
		end
	end
	return ys
end

-- The first line: Copy from's label and dropdown, then All and None at the
-- right end, with no dividers. The last: Confirm copy and Cancel in the
-- middle, as Blizzard's popup dialogs place their buttons.
local function check_copy_layout(where)
	local d = OW.GetDialogFrames()
	local width = d.content:GetWidth()
	-- Under Thick and Thin the rows sit 14 in from the body's edges (on its panel).
	local pad = st.config.profile.theme.name == 'blizzard' and 0 or 14
	local pick, all, none = cell('copy_from'), cell('toggle_all'), cell('toggle_none')
	eq(pick.label:GetText(), 'Copy from', where .. ': the label')
	eq(pick.label:GetStringWidth(), pick.label:GetUnboundedStringWidth(), where .. ': the label is not cut')
	check(all.y == pick.y and none.y == pick.y, where .. ': All and None on its line')
	eq(left(none) + none.frame:GetWidth(), width - pad, where .. ': None at the right edge, inside the padding')
	eq(left(all) + all.frame:GetWidth() + 12, left(none), where .. ': All 12 before None')
	eq(left(pick), pad, where .. ': the label at the left, inside the padding')
	eq(left(pick) + pick.frame:GetWidth() + 24, left(all), where .. ': the dropdown ends 24 before All')
	local point, rel, relPoint, x = pick.widget.frame:GetPoint(1)
	check(point == 'RIGHT' and rel == pick.frame and relPoint == 'RIGHT' and x == 0, where .. ': the dropdown at its right end')
	check(not divider_ys()[pick.y], where .. ': no divider on the line')

	local accept, cancel = cell('accept'), cell('cancel')
	eq(accept.y, cancel.y, where .. ': Confirm copy and Cancel on one line')
	eq(left(accept) + accept.frame:GetWidth() + 12, left(cancel), where .. ': Confirm copy, then Cancel, 12 apart')
	local room = width - (left(cancel) + cancel.frame:GetWidth())
	check(math.abs(left(accept) - room) <= 1, where .. ': in the middle: ' .. left(accept) .. ' and ' .. room)
	local last = 0
	for _, c in ipairs(d.body.cells) do last = math.max(last, c.y) end
	eq(accept.y, last, where .. ': at the bottom')
	check(not divider_ys()[accept.y], where .. ': no divider on their line')
	if pad > 0 then
		-- Confirm copy and Cancel float under the Settings section's panel, 24
		-- below it, on the dialog's own fill; the dialog ends its side padding
		-- (24) under them, so they sit midway.
		local panels, above = {}, 0
		for _, p in ipairs(d.body.pools.panel.used) do
			if p:IsShown() then panels[#panels + 1] = p end
		end
		for _, c in ipairs(d.body.cells) do
			if c.y < accept.y then above = math.max(above, c.y) end
		end
		eq(#panels, 2, where .. ': a panel for Copy from\'s line and one for the settings')
		eq(accept.y, above + 38 + 24, where .. ': the buttons 24 under the settings\' panel')
		local _, _, _, _, py = panels[#panels]:GetPoint(1)
		eq(-py + panels[#panels]:GetHeight(), accept.y - 24, where .. ': the settings\' panel ends over the buttons')
		eq(accept.frame:GetBottom() - d.frame:GetBottom(), 24, where .. ': the dialog ends 24 under them')
	end
end

test("Copy from's label has room: All and None sit at its line's right end; Confirm copy and Cancel in the middle at the bottom", function()
	UF:OpenCopyTable('player')
	check_copy_layout('Thick')
	-- Picking a unit draws it again the same way.
	cell('copy_from').widget:Commit('target')
	eq(OW.GetDialogFrames().title:GetText(), 'Copy to Player from Target', 'picked')
	check_copy_layout('after a pick')
	OW:CloseDialog()
end)

test('Cancel closes Copy from and copies nothing; Confirm copy still asks and waits for a unit', function()
	local P = UF:GetProfileConfig()
	P.player.width, P.target.width = 1, 123
	local before = updates
	UF:OpenCopyTable('player')
	eq(cell('cancel').row.name, 'Cancel', 'named Cancel')
	check(not cell('cancel').widget:IsDisabled(), 'Cancel works before a unit is picked')
	click(cell('cancel').widget.frame)
	check(not OW:IsDialogShown(), 'Cancel closes it, before a pick')

	UF:OpenCopyTable('player')
	check(cell('accept').widget:IsDisabled(), 'Confirm copy waits for a unit')
	cell('copy_from').widget:Commit('target')
	click(cell('toggle_all').widget.frame)
	check(not cell('accept').widget:IsDisabled(), 'Confirm copy is on once one is picked')
	click(cell('cancel').widget.frame)
	check(not OW:IsDialogShown(), 'Cancel closes it, after a pick and All')
	eq(W.ConfirmText(), nil, 'without asking')
	eq(P.player.width, 1, 'nothing copied')
	eq(updates, before, 'and the unit frames not updated')

	UF:OpenCopyTable('player')
	cell('copy_from').widget:Commit('target')
	click(cell('toggle_all').widget.frame)
	click(cell('accept').widget.frame)
	eq(W.ConfirmText(), 'Are you sure you want to copy the ticked settings to Player from Target?', 'Confirm copy asks')
	click(W.GetDialogFrames().no)
	check(OW:IsDialogShown(), 'No leaves the dialog open')
	eq(P.player.width, 1, 'and copies nothing')
	OW:CloseDialog()
end)

test('closing the Copy from dialog cancels a prompt or confirm open over it', function()
	local cancelled = 0
	UF:OpenCopyTable('player')
	W.Prompt('Name?', '', function() end, { onCancel = function() cancelled = cancelled + 1 end })
	check(W.PromptBox() ~= nil, 'the prompt is up')
	OW:CloseDialog()
	eq(cancelled, 1, 'the dialog hiding cancelled it')
	eq(W.PromptBox(), nil, 'and closed it')
end)

-- A plate is no unit frame: the game places it and sizes every plate alike,
-- Nameplates needs a reload and puts the game's settings back, and its
-- elements are laid out for a thin bar. So the nameplates are left out of
-- Copy from both ways.
test('Copy from leaves the nameplates out: never offered to copy from, and their page has no Copy from', function()
	check(UF:GetProfileConfig().nameplate ~= nil, 'the profile has the nameplates')
	UF:OpenCopyTable('player')
	click(cell('copy_from').widget.frame)
	local offered = {}
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() then offered[row.text:GetText()] = true end
	end
	check(offered.Target, 'target is offered')
	check(not offered.nameplate, 'the nameplates are not')
	W.CloseList()
	OW:CloseDialog()
	eq((function() local out = {} for key in pairs(UF:GetConfigTable().args.nameplate.pickerControl.args) do out[#out + 1] = key end table.sort(out) return table.concat(out, ',') end)(), 'manage,profile', 'the Enemy nameplates page has Profile and Manage, no Copy from')
	check(UF:GetConfigTable().args.player.pickerControl ~= nil, "the player's page has it")
end)

test("Copy from lists a migrated profile's Theme and Background, not its old template", function()
	local P = UF:GetProfileConfig()
	local player, health = P.player, P.player.health
	local kept = { player.theme, player.background, health.theme, health.background }
	-- What the old version saved, as the profile has it before it migrates
	-- (at login or on the profile switch to it).
	player.theme, player.background, player.template = nil, nil, 'thicktransparent'
	health.theme, health.background, health.template = nil, nil, 'thin'
	st:MigrateTemplateKeys(st.config.profile)
	eq(player.theme .. ',' .. player.background, 'thick,transparent', 'the unit: Thick, Transparent')
	eq(health.theme .. ',' .. health.background, 'thin,solid', 'its health bar: Thin, Solid')

	UF:OpenCopyTable('player')
	local listed = {}
	for _, key in ipairs(rows()) do listed[key] = true end
	check(listed.theme and listed.background, 'Theme and Background are settings to copy')
	check(not listed.template, 'template is not')
	OW:CloseDialog()

	player.theme, player.background, health.theme, health.background = unpack(kept)
end)

test('the unit picker lists the units in a fixed order, Player first, and no Profile (it is on each unit page\'s line)', function()
	local view = OM.BuildView({ Unitframes = UF:GetConfigTable() }, 'Unitframes')
	local keys = {}
	for i, entry in ipairs(view.picker.values) do keys[i] = entry.key end
	eq(table.concat(keys, ','), 'all,player,target,targettarget,focus,focustarget,pet,pettarget,boss,party,raid10,raid40,nameplate,friendlynameplate',
		'All units, Player, Target, TargetTarget, Focus, FocusTarget, Pet, PetTarget, Boss, Party, Raid 10, Raid 40, Enemy nameplates, Friendly nameplates')
	eq(view.picker.selected, 'all', 'the page opens on All units, the picker\'s first')
end)

test("the unit frames' table passes AceConfigRegistry validation, SaftUI's fields aside", function()
	local config = UF:GetConfigTable()
	check(config.category ~= nil, 'it has a category')
	eq(config.args.player.args.general.args.position.type, 'position', 'and Position options')
	local ok, err = pcall(AceConfigRegistry.ValidateOptionsTable, AceConfigRegistry,
		ace_ready({ name = st.name, type = 'group', args = { Unitframes = config } }), st.name)
	check(ok, 'valid: ' .. tostring(err))
	check(config.category ~= nil, 'the table itself keeps its category')
	eq(config.footer, nil, 'and no footer: the profile is on the Unit dropdown\'s line')
	-- The line's options (a pick\'s pickerControl, SaftUI\'s field, which ace_ready leaves off)
	-- and the Unit frame profiles dialog's, as groups of their own.
	ok, err = pcall(AceConfigRegistry.ValidateOptionsTable, AceConfigRegistry,
		ace_ready({ name = st.name, type = 'group', args = { line = config.args.player.pickerControl, dialog = UF.GenerateProfileConfigGroup() } }), st.name)
	check(ok, 'the line and the dialog valid: ' .. tostring(err))
end)

test("the unit frames' page: picker labelled Unit; boss has Layout with test mode; range alpha on the groups only", function()
	local config = UF:GetConfigTable()
	eq(config.pickerLabel, 'Unit', 'the picker is labelled Unit')

	local layout = config.args.boss.args.general.args.layout
	check(layout, 'boss has a Layout group in General')
	for _, key in ipairs({ 'growthDirection', 'spacing' }) do
		check(layout.args[key], 'boss Layout has ' .. key)
	end
	for _, key in ipairs({ 'unitsPerColumn', 'initialAnchor', 'columnSpacing', 'maxColumns' }) do
		eq(layout.args[key], nil, 'boss Layout has no ' .. key)
	end
	local kept = {}
	for key in pairs(layout.args) do kept[#kept + 1] = key end
	table.sort(kept)
	eq(table.concat(kept, ','), 'growthDirection,spacing,test_mode', 'Growth, Spacing and Test mode')
	for _, unit in ipairs({ 'party', 'raid10', 'raid40' }) do
		for _, key in ipairs({ 'unitsPerColumn', 'initialAnchor', 'columnSpacing', 'maxColumns' }) do
			check(config.args[unit].args.general.args.layout.args[key], unit .. ' Layout keeps ' .. key)
		end
	end
	-- Boss's Test mode is party's and raid's toggle, with its own tooltip.
	local boss_test, party_test = layout.args.test_mode, config.args.party.args.general.args.layout.args.test_mode
	if check(boss_test, 'boss has test mode') then
		for _, key in ipairs({ 'name', 'type', 'size', 'order' }) do
			eq(boss_test[key], party_test[key], 'boss test mode has party\'s ' .. key)
		end
		eq(boss_test.size, 'small', 'a small toggle')
		eq(boss_test.width, nil, 'no Ace width')
		check(type(boss_test.desc) == 'string' and boss_test.desc:find('boss', 1, true), 'its tooltip speaks of bosses: ' .. tostring(boss_test.desc))
		check(boss_test.desc ~= party_test.desc, "not party's tooltip")
	end
	eq(layout.args.showPlayer, nil, 'no show player for boss')
	check(config.args.party.args.general.args.layout.args.test_mode, 'party keeps test mode')
	check(config.args.party.args.general.args.layout.args.showPlayer, 'party keeps show player')
	check(config.args.raid10.args.general.args.layout.args.test_mode, 'raid keeps test mode')
	eq(config.args.raid10.args.general.args.layout.args.showPlayer, nil, 'raid has no show player')

	-- A Layout change on boss re-applies boss, as General's other settings do.
	local P = UF:GetProfileConfig()
	local before = updates
	local g = config.args.boss.args.general
	g.set({ 'boss', 'general', 'spacing' }, 20)
	eq(P.boss.spacing, 20, 'written to the boss config')
	eq(updates, before + 1, 'and boss was updated')
	P.boss.spacing = 41

	for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss' }) do
		eq(config.args[unit].args.general.args.range_alpha, nil, unit .. " has no range alpha: only group members' frames use it")
	end
	for _, unit in ipairs({ 'party', 'raid10', 'raid40' }) do
		local group = config.args[unit]
		do
			local defaults = P[unit].range_alpha
			check(defaults, unit .. ' has range_alpha defaults')
			local range = group.args.general.args.range_alpha
			check(range, unit .. ' has range alpha options')
			for _, key in ipairs({ 'inside', 'outside' }) do
				local o = range.args[key]
				eq(o.type, 'range', unit .. ' ' .. key)
				eq(o.min, 0); eq(o.max, 1)
				eq(range.get({ [1] = unit, [2] = 'general', [3] = 'range_alpha', [4] = key }), defaults[key], unit .. ' reads ' .. key)
				local n = updates
				range.set({ [1] = unit, [2] = 'general', [3] = 'range_alpha', [4] = key }, 0.25)
				eq(P[unit].range_alpha[key], 0.25, unit .. ' writes ' .. key)
				eq(updates, n + 1, unit .. ' updated')
				P[unit].range_alpha[key] = defaults[key] == 0.25 and 0.4 or defaults[key]
			end
		end
	end
end)

test('every unit-level option has a tooltip and no Ace width', function()
	local config = UF:GetConfigTable()
	each_option(config, function(option, path)
		-- The element tabs are the next task's.
		if #path >= 2 and path[2] ~= 'general' and path[2] ~= 'copy' then return end
		local where = table.concat(path, '.')
		eq(option.width, nil, where .. ' has no width')
		if option.type ~= 'group' and option.type ~= 'header' and option.type ~= 'description' then
			check(type(option.desc) == 'string' and option.desc ~= '', where .. ' has a desc')
		end
	end)
	-- The unit pages' line (Copy from, Profile, Manage), the plates' and the Unit frame profiles dialog's.
	for where, tree in pairs({ line = config.args.player.pickerControl, plates = config.args.nameplate.pickerControl, dialog = UF.GenerateProfileConfigGroup() }) do
		local count = 0
		each_option(tree, function(option, path)
			count = count + 1
			eq(option.width, nil, where .. '.' .. table.concat(path, '.') .. ' has no width')
			check(type(option.desc) == 'string' and option.desc ~= '', where .. '.' .. table.concat(path, '.') .. ' has a desc')
		end)
		check(count > 1, where .. ': its options walked')
	end
	eq(UF.GenerateProfileConfigGroup().args.new.size, 'small', "the dialog's buttons are small")
end)

------------------------------------------------------------------ the element tabs

local UNITS = { 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40', 'nameplate' }
local NO_DESC = { group = true, header = true, description = true }

-- A unit's element tabs: every group of its section but General.
local function element_tabs(config, unit)
	local tabs = {}
	for key, option in pairs(config.args[unit].args) do
		if key ~= 'general' and option.type == 'group' then tabs[key] = option end
	end
	return tabs
end

local function sorted_keys(t)
	local keys = {}
	for key in pairs(t) do keys[#keys + 1] = key end
	table.sort(keys)
	return table.concat(keys, ',')
end

-- The page as it was before the parts were rows: each element a tab of its own
-- key, so the tests of the elements' option tables (their descs, sizes, resets
-- and saved paths, which are the same tables now) read them where they always
-- did. A part drawn as a row becomes its tab again: the row's menu with the
-- Enable the row's box is; Auras' children and Power's bar and Additional power
-- are lifted to the tabs they were. The real page's shape is parts_test.lua's.
local function legacy_config()
	local tree = UF:GetConfigTable()
	for _, page in pairs(tree.args) do
		local args = {}
		for key, option in pairs(page.args) do
			if key == 'Auras' then
				for child, group in pairs(option.args) do args[child] = group end
			elseif key == 'Power' and option.args.bar then
				args.Power = option.args.bar
				args.AdditionalPower = option.args.AdditionalPower
			else
				args[key] = option
			end
		end
		local parts = page.args.general.args.parts
		for partKey, item in pairs(parts and parts.args or {}) do
			local part = UF.PartFor(partKey)
			if not part.sub then
				local group = {}
				for k, v in pairs(item.menu) do group[k] = v end
				group.args = {}
				for k, v in pairs(item.menu.args) do group.args[k] = v end
				group.order = part.element == 'Name' and 5 or 9
				if item.get ~= false then
					group.args.enable = { type = 'toggle', name = 'Enable', desc = item.desc, order = 0, size = 'small',
						get = item.get, set = item.set, saved = item.saved }
				end
				args[part.element] = group
			end
		end
		page.args = args
	end
	return tree
end

-- The option at keys under a unit's tab, and the row OM.Get and OM.Set take for
-- it: they find the get and set it inherits, as the window does.
local function option_at(config, unit, tab, ...)
	local node, path = config.args[unit].args[tab], { 'Unitframes', unit, tab }
	for _, key in ipairs({ ... }) do
		node = node and node.args and node.args[key]
		path[#path + 1] = key
	end
	return node, node and { path = path, option = node }
end

-- A group's args, by order.
local function in_order(group)
	local keys = {}
	for key in pairs(group.args) do keys[#keys + 1] = key end
	table.sort(keys, function(a, b)
		local oa, ob = group.args[a].order or 100, group.args[b].order or 100
		if oa ~= ob then return oa < ob end
		return a < b
	end)
	return keys
end

-- 'key:size col[/quarter]' for a section of a unit's tab, as the window packs
-- it: the section titled title, or with after the untitled one after it.
local function layout(config, unit, tab, title, after)
	local view = OM.BuildView({ Unitframes = config }, 'Unitframes', { pick = unit, tab = tab })
	for i, section in ipairs(view.sections) do
		if section.title == title then
			if after then
				section = view.sections[i + 1]
				if section.title ~= nil then return 'titled ' .. section.title end
			end
			local got = {}
			for _, p in ipairs(st.OptionsBody.LayoutRows(section.rows)) do
				got[#got + 1] = string.format('%s:%s %s%s', p.row.key, p.row.size, tostring(p.col),
					p.quarter and ('/' .. p.quarter) or '')
			end
			return table.concat(got, ', ')
		end
	end
end

-- Reads the option's value, sets it to value, checks the profile key took it and
-- the unit frames were updated, and puts the old value back.
local function reads_and_writes(config, unit, tab, keys, store, key, value)
	local option, row = option_at(config, unit, tab, unpack(keys))
	local where = unit .. '.' .. tab .. '.' .. table.concat(keys, '.')
	if not check(option ~= nil, where .. ' exists') then return end
	local before = store[key]
	eq(OM.Get({ Unitframes = config }, row), before, where .. ' reads ' .. key)
	local n = updates
	check(OM.Set({ Unitframes = config }, row, value), where .. ' sets')
	eq(store[key], value, where .. ' writes ' .. key)
	eq(updates, n + 1, where .. ' updates the unit frames')
	store[key] = before
end

-- The units whose frames can show what each oUF color flag checks for, as
-- oUF's health and power UpdateColor test the unit: offline units
-- (Disconnected), mobs someone else tagged (Tapped), players (Class), units that
-- aren't players (NPC class), and units a player controls that aren't players
-- (Pet class). Player shows you, pet your pet, boss frames bosses, party and
-- raid frames players, and nameplates any unit but an offline player; the
-- others can show anything. The flags not listed (Reaction, Gradient, Health
-- color, Power type) can color any unit.
local ANY = { 'target', 'targettarget', 'focus', 'focustarget', 'pettarget' }
local function any_and(...)
	local set = {}
	for _, unit in ipairs(ANY) do set[unit] = true end
	for _, unit in ipairs({ ... }) do set[unit] = true end
	return set
end
local FLAG_UNITS = {
	colorDisconnected = any_and('party', 'raid10', 'raid40'),
	colorTapping = any_and('boss', 'nameplate'),
	colorClass = any_and('player', 'party', 'raid10', 'raid40', 'nameplate'),
	colorClassNPC = any_and('pet', 'boss', 'nameplate'),
	colorClassPet = any_and('pet', 'nameplate'),
}
-- Mobs: what Tapped needs, and a rare, elite or boss-level (skull) unit too.
local MOB_UNITS = any_and('boss', 'nameplate')

test('each unit has a tab for each element it has', function()
	local config = legacy_config()
	local everywhere = 'Buffs,Debuffs,GroupRoleIndicator,Health,Name,Power,QuestIndicator,RaidRoleIndicator,RaidTargetIndicator'
	eq(sorted_keys(element_tabs(config, 'player')),
		'AdditionalPower,Buffs,Castbar,ClassPower,Debuffs,GroupRoleIndicator,Health,Name,Power,QuestIndicator,RaidRoleIndicator,RaidTargetIndicator',
		'player: every element, additional and class power too')
	eq(sorted_keys(element_tabs(config, 'targettarget')), everywhere, 'a target of a target has no castbar')
	eq(sorted_keys(element_tabs(config, 'boss')),
		'Buffs,Castbar,Debuffs,GroupRoleIndicator,Health,Name,Power,QuestIndicator,RaidRoleIndicator,RaidTargetIndicator',
		'boss has a castbar')
	eq(sorted_keys(element_tabs(config, 'party')),
		'Buffs,Castbar,Debuffs,GroupRoleIndicator,Health,Name,Power,QuestIndicator,RaidRoleIndicator,RaidTargetIndicator,ReadyCheckIndicator',
		'party has the ready check')
	eq(sorted_keys(element_tabs(config, 'nameplate')),
		'Buffs,Castbar,Debuffs,Health,Name,QuestIndicator,RaidTargetIndicator,Subtext,Threat',
		'nameplates have no power, role or ready check, and have the subtext and threat text')
end)

test('every element tab: a tooltip on every option, no Ace width, and each Position a block last in its group', function()
	local config = legacy_config()
	local positions = 0
	local function position_last(group, where)
		for key, option in pairs(group.args) do
			if option.type == 'position' then
				for other, sibling in pairs(group.args) do
					if other ~= key then
						check((sibling.order or 100) < option.order, where .. ': Position is after ' .. other)
					end
				end
			end
		end
	end
	-- A bar's own Position is its tab's second section (the owner's rule, walked by
	-- position_second_test.lua), so these tabs' is not last; a part's menu has its
	-- Position last, and so has every text and section inside a tab.
	local BAR_TABS = { Health = true, Power = true, AdditionalPower = true, Castbar = true, Buffs = true, Debuffs = true }
	for _, unit in ipairs(UNITS) do
		for tab, group in pairs(element_tabs(config, unit)) do
			if not BAR_TABS[tab] then position_last(group, unit .. '.' .. tab) end
			each_option(group, function(option, path)
				local where = unit .. '.' .. tab .. '.' .. table.concat(path, '.')
				eq(option.width, nil, where .. ' has no width')
				if not NO_DESC[option.type] then
					check(type(option.desc) == 'string' and option.desc ~= '', where .. ' has a desc')
				end
				if option.type == 'group' then position_last(option, where) end
				check(path[#path] ~= 'position' or option.type == 'position', where .. ' is a Position block')
				if option.type == 'position' then
					positions = positions + 1
					-- An aura's count and timer sit on each button: no target to pick.
					local spot = path[#path - 1] == 'count' or path[#path - 1] == 'timer'
					eq(option.target, (not spot) and 'select' or nil,
						where .. (spot and ' has no target' or " picks among the unit frame's parts"))
				end
			end)
		end
	end
	check(positions > 100, 'every element and text has a Position: ' .. positions)
end)

test('no element tab has two sections with the same title: a part\'s Position says what it places', function()
	local config = legacy_config()
	local checked, named = 0, {}
	for _, unit in ipairs(UNITS) do
		for tab in pairs(element_tabs(config, unit)) do
			local view = OM.BuildView({ Unitframes = config }, 'Unitframes', { pick = unit, tab = tab })
			local seen = {}
			for _, section in ipairs(view.sections) do
				if section.title then
					check(not seen[section.title], unit .. '.' .. tab .. ' has one section titled ' .. section.title)
					seen[section.title] = true
					named[section.title] = true
				end
			end
			checked = checked + 1
		end
	end
	check(checked > 50, 'every unit\'s tabs: ' .. checked)
	for _, title in ipairs({ 'Text position', 'Spell name position', 'Time position', 'Icon position', 'Count position', 'Timer position' }) do
		check(named[title], title .. ' is a section')
	end
end)

test('Health and Power: the color toggles, small, in a Colors section, in the order oUF checks them, on the units they can color', function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	local FLAGS = {
		Health = { 'colorDisconnected', 'colorTapping', 'colorClass', 'colorClassNPC', 'colorClassPet', 'colorReaction', 'colorSmooth', 'colorHealth' },
		Power = { 'colorDisconnected', 'colorTapping', 'colorPower', 'colorClass', 'colorClassNPC', 'colorClassPet', 'colorReaction' },
	}
	for _, unit in ipairs(UNITS) do
		for tab, flags in pairs(FLAGS) do
			local where = unit .. '.' .. tab
			local colors = option_at(config, unit, tab, 'colors')
			if unit == 'nameplate' and tab == 'Power' then
				-- Nameplates have no power bar (the tabs case above).
				eq(option_at(config, unit, tab), nil, where .. ' has no tab')
			elseif check(colors and colors.type == 'group' and colors.inline and colors.name == 'Colors', where .. ' has a Colors section') then
				local expected = {}
				for _, flag in ipairs(flags) do
					if not FLAG_UNITS[flag] or FLAG_UNITS[flag][unit] then expected[#expected + 1] = flag end
				end
				-- Then Custom: its check box and its color are one row, on a line of its own.
				expected[#expected + 1] = 'custom'
				eq(table.concat(in_order(colors), ','), table.concat(expected, ','), where .. "'s colors")
				local custom = colors.args.custom
				if check(custom.type == 'group' and custom.inline and custom.name == '', where .. ': Custom in an untitled group') then
					eq(table.concat(in_order(custom), ','), 'customColor', where .. "'s custom color, its toggle in the field")
				end
				for i = 1, #expected - 1 do
					local option = colors.args[expected[i]]
					check(option.type == 'toggle' and option.size == 'small', where .. '.' .. expected[i] .. ' is a small toggle')
				end
				local store = P[unit][string.lower(tab)]
				for i = 1, #expected - 1 do
					reads_and_writes(config, unit, tab, { 'colors', expected[i] }, store, expected[i], not store[expected[i]])
				end
			end
		end
	end
	eq(layout(config, 'target', 'Health', 'Colors'),
		'colorDisconnected:small 1/1, colorTapping:small 1/2, colorClass:small 2/1, colorClassNPC:small 2/2, '
		.. 'colorClassPet:small 1/1, colorReaction:small 1/2, colorSmooth:small 2/1, colorHealth:small 2/2',
		"target's health colors, four to a line")
	eq(layout(config, 'player', 'Power', 'Colors'), 'colorPower:small 1/1, colorClass:small 1/2, colorReaction:small 2/1',
		"the player's power colors")
	eq(layout(config, 'player', 'Power', 'Colors', true), 'customColor:normal 1',
		'Custom, one row on the next line, untitled, whatever the count above')
	eq(layout(config, 'nameplate', 'Health', 'Colors'),
		'colorTapping:small 1/1, colorClass:small 1/2, colorClassNPC:small 2/1, colorClassPet:small 2/2, '
		.. 'colorReaction:small 1/1, colorSmooth:small 1/2, colorHealth:small 2/1',
		"the nameplates' health colors: every one but Disconnected")
end)

test('Health, Power and Additional power: Custom and its color are one row, its toggle the saved colorCustom, kept in the shape the profile holds it', function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	local root = { Unitframes = config }
	for _, case in ipairs({ { 'target', 'Health' }, { 'party', 'Health' }, { 'player', 'Power' }, { 'boss', 'Power' }, { 'player', 'AdditionalPower' } }) do
		local unit, tab = case[1], case[2]
		local where = unit .. '.' .. tab
		local store = P[unit][string.lower(tab)]
		check(option_at(config, unit, tab, 'colors', 'custom', 'colorCustom') == nil, where .. ' has no Custom toggle of its own')

		local option, row = option_at(config, unit, tab, 'colors', 'custom', 'customColor')
		if check(option and option.type == 'color' and option.size == 'small', where .. ' has a small Custom color') then
			-- Its check box is the saved colorCustom, written through the same update.
			local toggle = option.toggle
			if check(type(toggle) == 'table', where .. ' has a toggle') then
				local info = { 'Unitframes', unit, tab, 'colors', 'custom', 'customColor' }
				eq(toggle.get(info), store.colorCustom, where .. ' reads colorCustom')
				local n = updates
				local before = store.colorCustom
				toggle.set(info, not before)
				eq(store.colorCustom, not before, where .. ' writes colorCustom')
				eq(toggle.get(info), not before, where .. ' reads what it wrote')
				eq(updates, n + 1, where .. ' updates the unit frames')
				toggle.set(info, false)
				eq(store.colorCustom, false, where .. ' writes it back')
			end
			local list = store.customColor
			local r, g, b = OM.Get(root, row)
			check(near(r, list[1]) and near(g, list[2]) and near(b, list[3]), where .. ' reads the default list')
			local n = updates
			OM.Set(root, row, .1, .2, .3, 1)
			check(store.customColor == list and list.GetRGB == nil, where .. ' keeps the list')
			check(near(list[1], .1) and near(list[2], .2) and near(list[3], .3), where .. ' writes the list')
			eq(updates, n + 1, where .. ' updates the unit frames')
			-- A saved profile can hold a color object; UF.UnpackColor reads its r, g and b.
			local color = CreateColor(.4, .5, .6)
			store.customColor = color
			r, g, b = OM.Get(root, row)
			check(near(r, .4) and near(g, .5) and near(b, .6), where .. ' reads a color object')
			OM.Set(root, row, .7, .8, .9, 1)
			r, g, b = color:GetRGB()
			check(store.customColor == color and near(r, .7) and near(g, .8) and near(b, .9), where .. ' writes the color object')
			store.customColor = list
		end
	end
	local colors = option_at(config, 'player', 'AdditionalPower', 'colors')
	eq(colors and table.concat(in_order(colors), ','), 'colorPower,custom', "additional power's colors: Power type, then Custom")
	reads_and_writes(config, 'player', 'AdditionalPower', { 'colors', 'colorPower' }, P.player.additionalpower, 'colorPower',
		not P.player.additionalpower.colorPower)
end)

-- The tabs' Custom rows and the text colors.
local function row_of(unit, tab, ...)
	local config = legacy_config()
	local option, row = option_at(config, unit, tab, ...)
	return option, row, { Unitframes = config }
end

local function plain_info(unit, tab, ...) return { 'Unitframes', unit, tab, ... } end

test('no Custom check box is left on its own: every Custom is one color row with a toggle, and the unticked word says what the bar falls back to', function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	for _, unit in ipairs(UNITS) do
		for _, tab in ipairs({ 'Health', 'Power', 'AdditionalPower' }) do
			local group = element_tabs(config, unit)[tab]
			if group then
				each_option(group, function(option, path)
					check(path[#path] ~= 'colorCustom', unit .. '.' .. tab .. ' has no colorCustom row of its own')
				end)
				local option = option_at(config, unit, tab, 'colors', 'custom', 'customColor')
				local store = P[unit][string.lower(tab)]
				if check(option and option.toggle, unit .. '.' .. tab .. ' has the merged row') then
					local saved = {}
					for key, value in pairs(store) do if type(value) == 'boolean' then saved[key] = value; store[key] = false end end
					eq(option.toggle.offText(plain_info(unit, tab)), 'Default', unit .. '.' .. tab .. ': with no color above on, Default')
					for key, value in pairs(saved) do store[key] = value end
				end
			end
		end
	end
	-- With a flag on, the first that fits the unit is the word: oUF checks them in this order.
	local function word(unit, tab)
		local option = option_at(legacy_config(), unit, tab, 'colors', 'custom', 'customColor')
		return option.toggle.offText(plain_info(unit, tab))
	end
	local h = P.target.health
	local saved = { h.colorDisconnected, h.colorTapping, h.colorClass, h.colorClassNPC, h.colorClassPet, h.colorReaction, h.colorSmooth, h.colorHealth }
	h.colorDisconnected, h.colorTapping, h.colorClass, h.colorClassNPC, h.colorClassPet, h.colorReaction, h.colorSmooth, h.colorHealth =
		false, false, false, false, false, true, true, false
	eq(word('target', 'Health'), 'Reaction', "Health: the first of the colors on, Reaction")
	h.colorClass = true
	eq(word('target', 'Health'), 'Class or reaction', 'Class first, then Reaction for the NPCs Class does not color')
	P.player.power.colorPower = true
	eq(word('player', 'Power'), 'Power type', "Power: Power type")
	P.player.power.colorPower = false
	P.player.additionalpower.colorPower = true
	eq(word('player', 'AdditionalPower'), 'Power type', "Additional power: Power type")
	h.colorDisconnected, h.colorTapping, h.colorClass, h.colorClassNPC, h.colorClassPet, h.colorReaction, h.colorSmooth, h.colorHealth = unpack(saved)
end)

test("a Custom row's reset: it shows when the color or the check box differs from the default, and puts both back", function()
	local P = UF:GetProfileConfig()
	for _, case in ipairs({ { 'target', 'Health', 'health', 'Class or reaction' }, { 'player', 'Power', 'power', 'Class' }, { 'player', 'AdditionalPower', 'additionalpower', 'Power type' } }) do
		local unit, tab, key = case[1], case[2], case[3]
		local where = unit .. '.' .. tab
		local option, row, root = row_of(unit, tab, 'colors', 'custom', 'customColor')
		local store = P[unit][key]
		-- Earlier tests wrote the colors; the profile at its defaults again.
		store.colorCustom = false
		local d = st.defaults.unitframes.profiles['**']['**'][key].customColor
		store.customColor = { d[1], d[2], d[3] }
		local state = OM.DefaultState(root, row)
		if check(state, where .. ' has a default') then
			eq(state.differs, false, where .. ': at its default, no reset')
			store.colorCustom = true
			eq(OM.DefaultState(root, row).differs, true, where .. ': the check box alone differs')
			store.colorCustom = false
			OM.Set(root, row, 0.9, 0.1, 0.1, 1)
			eq(OM.DefaultState(root, row).differs, false, where .. ': unticked, a color that is not shown is not a difference')
			store.colorCustom = true
			eq(OM.DefaultState(root, row).differs, true, where .. ': ticked, the color differs')
			local n = updates
			check(OM.DefaultReset(root, row), where .. ': a reset runs')
			eq(store.colorCustom, false, where .. ': the check box is back')
			local r, g, b = OM.Get(root, row)
			check(near(r, d[1]) and near(g, d[2]) and near(b, d[3]), where .. ': and the color')
			eq(updates, n + 1, where .. ': the unit frames follow')
			eq(OM.DefaultState(root, row).differs, false, where .. ': no reset again')
			eq(OM.DefaultState(root, row).text, case[4], where .. ': the tooltip names the default as the word, the color the bar takes')
		end
	end
end)

-- The unticked word, per kind of unit, against the order oUF checks the colors in:
-- a color covers the kinds of unit it is for (Class: players; NPC class: NPCs and
-- pets; Pet class: pets), and the word names the colors on, in order, up to the
-- first that covers every kind the unit can show.
test('the unticked word names the colors the bar can really take for that kind of unit', function()
	local P = UF:GetProfileConfig()
	local function word(unit, tab, on)
		local store = P[unit][string.lower(tab)]
		local saved = {}
		for key, value in pairs(store) do if type(value) == 'boolean' and key:find('^color') then saved[key] = value; store[key] = false end end
		for _, key in ipairs(on) do store[key] = true end
		local option = option_at(legacy_config(), unit, tab, 'colors', 'custom', 'customColor')
		local out = option.toggle.offText(plain_info(unit, tab))
		for key, value in pairs(saved) do store[key] = value end
		for _, key in ipairs(on) do if saved[key] == nil then store[key] = nil end end
		return out
	end
	local H = 'Health'
	-- A unit that can be anything: Class for players, Reaction for the rest.
	for _, unit in ipairs({ 'target', 'targettarget', 'focus', 'pettarget', 'nameplate', 'friendlynameplate' }) do
		eq(word(unit, H, { 'colorClass', 'colorReaction' }), 'Class or reaction', unit .. ': Class and Reaction')
		eq(word(unit, H, { 'colorClass' }), 'Class', unit .. ': Class alone')
		eq(word(unit, H, { 'colorReaction' }), 'Reaction', unit .. ': Reaction alone')
		eq(word(unit, H, { 'colorClass', 'colorClassNPC', 'colorReaction' }), 'Class or NPC class', unit .. ': NPC class covers the rest, Reaction is never reached')
		eq(word(unit, H, { 'colorClass', 'colorClassPet', 'colorReaction' }), 'Class or pet class or reaction', unit .. ': Pet class, then Reaction')
		eq(word(unit, H, { 'colorSmooth', 'colorClass' }), 'Class or gradient', unit .. ': Class, then Gradient')
		eq(word(unit, H, { 'colorDisconnected', 'colorTapping' }), 'Default', unit .. ': the greys for a state are not the fallback')
		eq(word(unit, H, {}), 'Default', unit .. ': nothing on')
	end
	-- Players only: Class covers every unit.
	for _, unit in ipairs({ 'player', 'party', 'raid10', 'raid40' }) do
		eq(word(unit, H, { 'colorClass', 'colorReaction' }), 'Class', unit .. ': Class covers them all')
		eq(word(unit, H, { 'colorReaction' }), 'Reaction', unit .. ': Reaction alone')
	end
	-- NPCs only (a pet, a boss): Class is not offered; NPC class or Reaction is.
	for _, unit in ipairs({ 'pet', 'boss' }) do
		eq(word(unit, H, { 'colorClassNPC', 'colorReaction' }), 'NPC class', unit .. ': NPC class covers them all')
		eq(word(unit, H, { 'colorReaction' }), 'Reaction', unit .. ': Reaction')
	end
	-- Power: Power type colors every unit and comes before the class colors.
	eq(word('target', 'Power', { 'colorPower', 'colorClass', 'colorReaction' }), 'Power type', 'target power: Power type first')
	eq(word('target', 'Power', { 'colorClass', 'colorReaction' }), 'Class or reaction', 'target power: Class, then Reaction')
	eq(word('player', 'Power', { 'colorClass', 'colorReaction' }), 'Class', 'player power')
	eq(word('player', 'AdditionalPower', { 'colorPower' }), 'Power type', 'additional power')
	eq(word('player', 'AdditionalPower', {}), 'Default', 'additional power with nothing on')
end)

test("a Custom row's reset: a color that is hidden while unticked does not keep the arrow; a profile without a text color does not break the row", function()
	local P = UF:GetProfileConfig()
	local option, row, root = row_of('target', 'Health', 'colors', 'custom', 'customColor')
	local store = P.target.health
	store.colorCustom, store.customColor = false, { 0.9, 0.1, 0.1 }
	eq(OM.DefaultState(root, row).differs, false, 'unticked, no arrow though the remembered color differs')
	store.colorCustom, store.customColor = true, { 0.25, 0.25, 0.25 }
	local d = st.defaults.unitframes.profiles['**']['**'].health.customColor
	store.customColor = { d[1], d[2], d[3] }
	store.colorCustom = false
	-- A profile from an older export has no text color keys until AceDB fills them.
	local text = P.target.health.text
	local saved = { text.colorCustom, text.customColor }
	text.colorCustom, text.customColor = nil, nil
	local _, trow, troot = row_of('target', 'Health', 'text', 'customColor')
	local r, g, b = OM.Get(troot, trow)
	check(near(r, 1) and near(g, 1) and near(b, 1), 'reads white')
	eq(OM.DefaultState(troot, trow).differs, false, 'at its default')
	text.colorCustom, text.customColor = saved[1], saved[2]
end)

test("UF.DefaultFor: a unit's own default wins over the shared one", function()
	local profiles = st.defaults.unitframes.profiles['**']
	eq(UF.DefaultFor('target', { 'health', 'text' }, 'colorCustom'), false, 'the shared default')
	profiles.target.health = profiles.target.health or {}
	profiles.target.health.text = profiles.target.health.text or {}
	profiles.target.health.text.colorCustom = true
	eq(UF.DefaultFor('target', { 'health', 'text' }, 'colorCustom'), true, "the unit's own")
	eq(UF.DefaultFor('focus', { 'health', 'text' }, 'colorCustom'), false, "another unit's is the shared one")
	profiles.target.health.text.colorCustom = nil
end)

test('Custom rows are found by search: by custom and by the color', function()
	local config = legacy_config()
	local root = { Unitframes = config }
	for _, needle in ipairs({ 'custom', 'Custom color' }) do
		local hits = 0
		for _, hit in ipairs(OM.Search(root, needle)) do
			if hit.name == 'Custom color' and hit.path[2] == 'target' and hit.path[3] == 'Health' then hits = hits + 1 end
		end
		check(hits >= 1, 'target Health: "' .. needle .. '" finds the merged row')
	end
end)

test("every element's alpha has an option, 0 to 1, on the element's config", function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	-- Where each tab keeps it, when not at its top.
	local AT = { Castbar = { 'bar', 'alpha' }, Buffs = { 'buttons', 'alpha' }, Debuffs = { 'buttons', 'alpha' } }
	local seen = 0
	for _, unit in ipairs(UNITS) do
		for tab in pairs(element_tabs(config, unit)) do
			local store = P[unit][string.lower(tab)]
			if store.alpha ~= nil then
				seen = seen + 1
				local keys = AT[tab] or { 'alpha' }
				local option = option_at(config, unit, tab, unpack(keys))
				if check(option and option.type == 'range', unit .. '.' .. tab .. ' has Alpha') then
					eq(option.min, 0); eq(option.max, 1)
				end
				reads_and_writes(config, unit, tab, keys, store, 'alpha', 0.35)
			end
		end
	end
	check(seen > 100, 'every element tab: ' .. seen)
end)

test('Health: Texture on every unit, its text options, and Boss percent only where a skull-level unit can show', function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	for _, unit in ipairs(UNITS) do
		local health = P[unit].health
		local texture, row = option_at(config, unit, 'Health', 'texture')
		if check(texture and texture.type == 'select', unit .. ' has Texture') then
			local names = {}
			for _, entry in ipairs(OM.Values({ Unitframes = config }, row)) do names[entry.key] = entry.name end
			check(names['SaftUI Flat'] == 'SaftUI Flat' and names['SaftUI Gloss'] == 'SaftUI Gloss',
				unit .. ': the status bar textures SaftUI registers')
		end
		reads_and_writes(config, unit, 'Health', { 'texture' }, health, 'texture', 'SaftUI Gloss')
		for _, key in ipairs({ 'enable', 'hide_full', 'deficit', 'percent', 'short' }) do
			reads_and_writes(config, unit, 'Health', { 'text', key }, health.text, key, not health.text[key])
		end
		eq(type(health.text.deficit), 'boolean', unit .. ' has a Deficit default')
		local boss_percent = option_at(config, unit, 'Health', 'text', 'boss_percent')
		if MOB_UNITS[unit] then
			reads_and_writes(config, unit, 'Health', { 'text', 'boss_percent' }, health.text, 'boss_percent', not health.text.boss_percent)
		else
			eq(boss_percent, nil, unit .. " has no Boss percent: it never shows a skull-level unit")
		end
	end
end)

test("Power and Additional power: Short is a small toggle after Percent, as Health's is, and is off by default", function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	for _, unit in ipairs(UNITS) do
		for _, case in ipairs({ { 'Power', 'power' }, { 'AdditionalPower', 'additionalpower' } }) do
			local tab, key = case[1], case[2]
			local text = option_at(config, unit, tab, 'text')
			if text then
				local where = unit .. '.' .. tab
				local short = text.args.short
				if check(short and short.type == 'toggle' and short.size == 'small', where .. ' has a small Short') then
					check(text.args.percent.order < short.order and short.order < text.args.position.order, where .. ': after Percent, before the Position')
					local store = P[unit][key].text
					eq(store.short, false, where .. ': off by default')
					reads_and_writes(config, unit, tab, { 'text', 'short' }, store, 'short', true)
				end
			end
		end
	end
end)

test("Health, Power and Additional power texts: Text color is one color row with its toggle, white when unticked, in the text's own keys", function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	for _, unit in ipairs(UNITS) do
		for _, case in ipairs({ { 'Health', 'health' }, { 'Power', 'power' }, { 'AdditionalPower', 'additionalpower' } }) do
			local tab, key = case[1], case[2]
			local text = option_at(config, unit, tab, 'text')
			if text then
				local where = unit .. '.' .. tab .. ' text'
				check(text.args.colorCustom == nil, where .. ' has no check box of its own for its color')
				local option, row, root = row_of(unit, tab, 'text', 'customColor')
				local store = P[unit][key].text
				if check(option and option.type == 'color' and option.name == 'Text color' and option.toggle, where .. ' has a Text color row with a toggle') then
					eq(store.colorCustom, false, where .. ': off by default')
					local info = plain_info(unit, tab, 'text', 'customColor')
					eq(option.toggle.offText, 'White', where .. ': unticked it is white, the font\'s color')
					-- The toggle is the text's own colorCustom, the color its customColor.
					local n = updates
					option.toggle.set(info, true)
					eq(store.colorCustom, true, where .. ': ticked writes colorCustom')
					eq(updates, n + 1, where .. ': the unit frames follow')
					eq(option.toggle.get(info), true, where .. ': reads it')
					local list = store.customColor
					OM.Set(root, row, 0.1, 0.2, 0.3, 1)
					check(store.customColor == list and near(list[1], 0.1) and near(list[3], 0.3), where .. ': the color is written in the list the profile holds')
					local r, g, b = OM.Get(root, row)
					check(near(r, 0.1) and near(g, 0.2) and near(b, 0.3), where .. ': and read back')
					local color = CreateColor(0.4, 0.5, 0.6)
					store.customColor = color
					OM.Set(root, row, 0.7, 0.8, 0.9, 1)
					local cr, cg, cb = color:GetRGB()
					check(store.customColor == color and near(cr, 0.7) and near(cg, 0.8) and near(cb, 0.9), where .. ': in a color object too')
					store.customColor = list
					-- Its reset: it differs while on or off white, and puts both back.
					eq(OM.DefaultState(root, row).differs, true, where .. ': differs')
					eq(OM.DefaultState(root, row).text, 'White', where .. ': the default named as White')
					check(OM.DefaultReset(root, row), where .. ': a reset runs')
					eq(store.colorCustom, false, where .. ': the toggle is back')
					r, g, b = OM.Get(root, row)
					check(near(r, 1) and near(g, 1) and near(b, 1), where .. ': and the color, white')
					eq(OM.DefaultState(root, row).differs, false, where .. ': at its default again')
				end
			end
		end
	end
end)

test("Copy from carries a text's color with its element: the whole health or power table is copied", function()
	local P = UF:GetProfileConfig()
	-- Additional power is Player's alone (its ValidUnit): Copy from offers only
	-- what both pages name, so it isn't among these.
	for _, key in ipairs({ 'health', 'power' }) do
		P.target[key].text.colorCustom, P.target[key].text.customColor = true, { 0.2, 0.7, 0.4 }
		P.focus[key].text.colorCustom, P.focus[key].text.customColor = false, { 1, 1, 1 }
		UF:CopySettings('focus', 'target', { key })
		eq(P.focus[key].text.colorCustom, true, key .. ': the toggle is copied')
		local copied = P.focus[key].text.customColor
		check(near(copied[1], 0.2) and near(copied[2], 0.7) and near(copied[3], 0.4), key .. ': and the color')
		check(copied ~= P.target[key].text.customColor, key .. ': as a copy')
		P.target[key].text.colorCustom, P.focus[key].text.colorCustom = false, false
		P.target[key].text.customColor, P.focus[key].text.customColor = { 1, 1, 1 }, { 1, 1, 1 }
	end
end)

test('Name: Classification where rare and elite units can show, Class color where players can', function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	for _, unit in ipairs(UNITS) do
		local name = P[unit].name
		for key, units in pairs({ show_classification = MOB_UNITS, colorClass = FLAG_UNITS.colorClass }) do
			local option = option_at(config, unit, 'Name', key)
			if units[unit] then
				if check(option and option.type == 'toggle' and option.size == 'small', unit .. ' has a small ' .. key) then
					reads_and_writes(config, unit, 'Name', { key }, name, key, not name[key])
				end
			else
				eq(option, nil, unit .. ' has no ' .. key)
			end
		end
	end
end)

-- The parts of a unit's section with a Theme and a Background: { tab, the
-- keys of the section they sit in under the tab, the profile table they
-- write }. The unit frame's own are in General; the castbar has the bar's and
-- the icon's; the aura tabs have them in Buttons. Name and the nameplates'
-- threat text have none: they're texts.
local TEXTS = { Name = true, Subtext = true, Threat = true }
local function themed_parts(config, P, unit)
	local parts = { { 'general', UF.IsPlateUnit(unit) and {} or { 'frame' }, P[unit] } }
	for tab in pairs(element_tabs(config, unit)) do
		local store = P[unit][string.lower(tab)]
		if tab == 'Castbar' then
			parts[#parts + 1] = { tab, { 'bar' }, store }
			parts[#parts + 1] = { tab, { 'icon' }, store.icon }
		elseif tab == 'Buffs' or tab == 'Debuffs' then
			parts[#parts + 1] = { tab, { 'buttons' }, store }
		elseif not TEXTS[tab] then
			parts[#parts + 1] = { tab, {}, store }
		end
	end
	return parts
end

-- A select's values as 'key=name' in the order the window lists them.
local function listed(config, row)
	local out = {}
	for _, entry in ipairs(OM.Values({ Unitframes = config }, row)) do out[#out + 1] = entry.key .. '=' .. entry.name end
	return table.concat(out, ';')
end

test('each element tab offers Theme and Background, with descs, and no template', function()
	local config = legacy_config()
	local P = UF:GetProfileConfig()
	local generic = st.Config.generators.theme(1).desc
	local seen = 0
	for _, unit in ipairs(UNITS) do
		for _, part in ipairs(themed_parts(config, P, unit)) do
			local tab, keys, store = part[1], part[2], part[3]
			local where = unit .. '.' .. table.concat({ tab, unpack(keys) }, '.')
			local function at(key)
				local path = { unpack(keys) }
				path[#path + 1] = key
				return path
			end
			seen = seen + 1

			local theme, themeRow = option_at(config, unit, tab, unpack(at('theme')))
			if check(theme and theme.type == 'select' and theme.name == 'Theme', where .. ' has Theme') then
				eq(listed(config, themeRow), "theme=Use SaftUI's theme;thick=Thick;thin=Thin;blizzard=Blizzard;none=None", where .. ": Theme's choices, in order")
				check(type(theme.desc) == 'string' and theme.desc:find('Global settings > Theme', 1, true) ~= nil,
					where .. "'s Theme says what its choices do")
				check(theme.desc ~= generic, where .. "'s Theme says which frames it draws: " .. tostring(theme.desc))
				eq(theme.width, nil, where .. "'s Theme has no Ace width")
				reads_and_writes(config, unit, tab, at('theme'), store, 'theme', 'thin')
			end

			local background, backgroundRow = option_at(config, unit, tab, unpack(at('background')))
			if check(background and background.type == 'select' and background.name == 'Background', where .. ' has Background') then
				eq(listed(config, backgroundRow), "theme=Use SaftUI's theme;solid=Solid;transparent=Transparent",
					where .. ": Background's choices, in order")
				check(type(background.desc) == 'string' and background.desc ~= '', where .. "'s Background has a desc")
				eq(background.order, theme and theme.order + 0.5, where .. ': Background comes right after Theme')
				eq(background.width, nil, where .. "'s Background has no Ace width")
				reads_and_writes(config, unit, tab, at('background'), store, 'background', 'transparent')
			end

			eq(option_at(config, unit, tab, unpack(at('template'))), nil, where .. ' has no Template')
		end
		eq(option_at(config, unit, 'Name', 'theme'), nil, unit .. "'s Name, a text, has no Theme")
	end
	eq(option_at(config, 'nameplate', 'Threat', 'theme'), nil, "the nameplates' threat text, a text, has no Theme")
	-- General, Health, Power, Buffs, Debuffs and four indicators on every unit
	-- frame; the castbar's bar and icon where there's a castbar (all but the
	-- targets of targets); the ready check on the groups; additional and class
	-- power on the player; and the nameplates' General, Health, Buffs,
	-- Debuffs, castbar bar and icon, and quest and raid mark icons.
	eq(seen, 11 * 9 + 8 * 2 + 3 + 2 + 8, 'every part with a Theme')

	-- Nothing in the unit frames' pages is a Template, or offers an old
	-- template, Highlight or Close Button.
	T.check_no_old_names(config, 'Unitframes')
	eq(config.name, 'Unit frames', 'the page is named in sentence case, as the sidebar shows it')
end)

-- The castbar's Bar and Icon sections each have their own Theme and
-- Background, so a section, not a tab, has one Background at most.
test('no element tab shows two settings named Background: the bar\'s own empty-part fill is Bar background', function()
	local config = legacy_config()
	local bars = 0
	for _, unit in ipairs(UNITS) do
		for tab, group in pairs(element_tabs(config, unit)) do
			local where = unit .. '.' .. tab
			local bySection = {}
			each_option(group, function(option, path)
				if option.name ~= 'Background' then return end
				local at = where .. '.' .. table.concat(path, '.')
				check(option.type == 'select' and path[#path] == 'background', at .. ' is the theme override, not ' .. tostring(option.type))
				local section = table.concat(path, '.', 1, #path - 1)
				bySection[section] = (bySection[section] or 0) + 1
			end)
			for section, count in pairs(bySection) do
				eq(count, 1, where .. (section ~= '' and ('.' .. section) or '') .. ' has one Background')
			end
			local bg = group.args.bg
			if bg then
				bars = bars + 1
				eq(bg.type, 'group', where .. "'s bar background is a section")
				eq(bg.name, 'Bar background', where .. "'s empty-part fill is Bar background")
			end
		end
	end
	-- Health and Power on every unit frame, Additional power on the player,
	-- and the nameplates' Health.
	eq(bars, 11 * 2 + 1 + 1, 'every bar with a fill of its own')
end)

test("Health's first section: the toggles four to a line, then the settings two to a line", function()
	local config = legacy_config()
	local view = OM.BuildView({ Unitframes = config }, 'Unitframes', { pick = 'target', tab = 'Health' })
	-- The tab's own first section.
	local first
	for _, section in ipairs(view.sections) do
		if section.rows[1].path[3] == 'Health' then first = section break end
	end
	local got = {}
	for _, p in ipairs(st.OptionsBody.LayoutRows(first.rows)) do
		got[#got + 1] = string.format('%s:%s %s%s', p.row.key, p.row.size, tostring(p.col), p.quarter and ('/' .. p.quarter) or '')
	end
	eq(table.concat(got, ', '),
		'enable:small 1/1, reverse_fill:small 1/2, vertical_fill:small 2/1, Smooth:small 2/2, '
		.. 'theme:normal 1, background:normal 2, texture:normal 1, alpha:normal 2, framelevel:normal 1',
		"Health's first section")
	eq(view.sections[2].title, nil, "the size line follows the bar's rows, untitled")
	eq(view.sections[3].title, 'Position', "Position is the second panel: after the bar's own settings and its size line")
end)

-- 'key:size col[/quarter]' for each row of a unit's tab's first section, in
-- the lines the window packs them in, a line to an entry.
local function first_lines(unit, tab)
	local view = OM.BuildView({ Unitframes = legacy_config() }, 'Unitframes', { pick = unit, tab = tab })
	local lines, byY = {}, {}
	for _, p in ipairs(st.OptionsBody.LayoutRows(view.sections[1].rows)) do
		local line = byY[p.y]
		if not line then line = {}; byY[p.y] = line; lines[#lines + 1] = line end
		line[#line + 1] = string.format('%s:%s %s%s', p.row.key, p.row.size, tostring(p.col), p.quarter and ('/' .. p.quarter) or '')
	end
	for i, line in ipairs(lines) do lines[i] = table.concat(line, ', ') end
	return lines
end

test("a unit's General starts with Enable and Theme, a half each; Background follows; Copy from isn't in it", function()
	for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40' }) do
		local lines = first_lines(unit, 'general')
		eq(lines[1], 'enable:normal 1, theme:normal 2', unit .. ': first line')
		eq(lines[2], 'background:normal 1, width:normal 2', unit .. ': second line')
		eq(lines[3], 'height:normal 1', unit .. ': third line')
		eq(#lines, 3, unit .. ': nothing more in its first section')
		-- The unit's page holds General and the element tabs; Copy from is beside the picker.
		eq(legacy_config().args[unit].args.copy, nil, unit .. ': no Copy from above the tabs')
		eq(legacy_config().args[unit].args.general.args.copy, nil, unit .. ': nor in General')
	end
end)

test("Copy from is beside the Unit dropdown, on every unit's page but the nameplates': it opens the dialog for the unit", function()
	local opened
	local real = UF.OpenCopyTable
	function UF:OpenCopyTable(unit) opened = unit end
	local config = legacy_config()
	for _, unit in ipairs({ 'player', 'target', 'targettarget', 'focus', 'focustarget', 'pet', 'pettarget', 'boss', 'party', 'raid10', 'raid40' }) do
		-- The pick's control (Core's pickerControl field), from every tab.
		local control = config.args[unit].pickerControl
		check(control and control.type == 'group', unit .. ': a control beside the picker')
		local copy = control and control.args.copy
		eq(copy and copy.type, 'execute', unit .. ': a button')
		eq(copy and copy.name, 'Copy from', unit .. ': Copy from')
		check(copy and type(copy.desc) == 'string' and copy.desc ~= '', unit .. ': with its tooltip')
		local view = OM.BuildView({ Unitframes = config }, 'Unitframes', { pick = unit, tab = 'Health' })
		eq(view.picker.control, control, unit .. ': the window draws it on the Health tab too')
		opened = nil
		copy.func()
		eq(opened, unit, unit .. ': it opens the dialog for the unit')
	end
	UF.OpenCopyTable = real
	eq((function() local out = {} for key in pairs(config.args.nameplate.pickerControl.args) do out[#out + 1] = key end table.sort(out) return table.concat(out, ',') end)(), 'manage,profile', 'Profile and Manage, no Copy from, on Enemy nameplates')
	eq((function() local out = {} for key in pairs(config.args.friendlynameplate.pickerControl.args) do out[#out + 1] = key end table.sort(out) return table.concat(out, ',') end)(), 'manage,profile', 'and on Friendly nameplates')
	-- Search finds it on each unit, on the unit's path, which opens its page.
	local results = OM.Search({ Unitframes = config }, 'copy from')
	local found = {}
	for _, result in ipairs(results) do
		if result.name == 'Copy from' then found[#found + 1] = table.concat(result.path, '.') end
	end
	eq(found[1], 'Unitframes.player', "Player's first, on the unit's path")
	eq(#found, 11, 'one per unit, none for the nameplates')
end)

test("the nameplate pages' General keeps its own first lines, with no Copy from", function()
	local enemy = first_lines('nameplate', 'general')
	eq(enemy[1], 'enable:small 1/1, threat_solo:small 1/2, use_friendly:normal 2', 'Enemy: the two toggles and the box')
	eq(enemy[2], 'theme:normal 1, background:normal 2', 'Enemy: Theme and Background')
	local friendly = first_lines('friendlynameplate', 'general')
	eq(friendly[1], 'friendly:small 1/1, use_enemy:normal 2', 'Friendly: its toggle and the box')
end)

-- Every section of the player's Class power menu (a part row of General's Parts: its
-- Enable is the row's box, so the menu starts at Theme), as the window packs it: a
-- line to an entry, and whether it shares the panel above.
test("Class power: its menu's Theme, Background and the rest in lines; Width, Relative, Height and its Relative as four quarters on one line", function()
	local item = UF:GetConfigTable().args.player.args.general.args.parts.args.classpower
	local view = OM.BuildView(OM.MenuRoot(item), OM.MENU_KEY)
	local got = {}
	for i, section in ipairs(view.sections) do
		got[i] = {}
		for _, p in ipairs(st.OptionsBody.LayoutRows(section.rows)) do
			got[i][#got[i] + 1] = string.format('%s:%s %s%s y%d', p.row.key, p.row.size, tostring(p.col), p.quarter and ('/' .. p.quarter) or '', p.y)
		end
		got[i] = table.concat(got[i], ', ')
	end
	eq(got[1], 'theme:normal 1 y0, background:normal 2 y0, alpha:normal 1 y34, framelevel:normal 2 y34, spacing:normal 1 y68',
		'five rows in three lines: the box took Enable out')
	eq(got[2], 'width:small 1/1 y0, relative_width:small 1/2 y0, height:small 2/1 y0, relative_height:small 2/2 y0',
		"Width and its Relative in the left half, Height and its Relative the right: an untitled line of its own")
	eq(got[3], 'position:wide full y0', 'Position after it: the menu holds the size line as the tab did, so Position is its third section')
	eq(#got, 3)
	eq(view.sections[2].title, nil, 'the size row is untitled')
	eq(view.sections[3].title, 'Position', 'then the Position block')
end)

test("the name tag marks rare (R), rare elite (R+), elite (+) and world boss (B) units with Classification on", function()
	local P = UF:GetProfileConfig()
	local tag = UF.oUF.Tags.Methods['st:name']
	local name = P.target.name
	check(name.enable and name.showLevel and name.show_classification, "target's name shows its level and classification by default")
	-- What the tag gives the level part: the level and the mark, colored, then a space.
	local function level_part(text) return (text:match('^|cff%x%x%x%x%x%x(.-)|r ')) end
	local MARKS = { normal = '', rare = 'R', rareelite = 'R+', elite = '+', worldboss = 'B' }
	for classification, mark in pairs(MARKS) do
		stub.units.target = { name = 'Mob', level = 22, class = 'WARRIOR', classification = classification, reaction = 2 }
		local text = tag('target', 'target', 'target')
		eq(level_part(text), '22' .. mark, classification .. ' gets ' .. (mark == '' and 'no mark' or mark))
		check(text:sub(-3) == 'Mob', classification .. ': then the name')
	end
	name.show_classification = false
	stub.units.target = { name = 'Mob', level = 22, class = 'WARRIOR', classification = 'rareelite', reaction = 2 }
	eq(level_part(tag('target', 'target', 'target')), '22', 'no mark with Classification off')
	name.show_classification = true
	stub.units.target = nil
end)

test("the name tag's Class color colors a player's name by class, and leaves a secret class alone", function()
	local P = UF:GetProfileConfig()
	local tag = UF.oUF.Tags.Methods['st:name']
	local name = P.target.name
	stub.units.target = { name = 'Jaina', level = 20, class = 'MAGE', player = true, reaction = 5 }
	local hex = st.StringFormat:ToHex(st.config.profile.colors.class.MAGE:GetRGB())
	check(not tag('target', 'target', 'target'):find('|cff' .. hex .. 'Jaina', 1, true), 'not colored with Class color off')
	name.colorClass = true
	check(tag('target', 'target', 'target'):find('|cff' .. hex .. 'Jaina|r', 1, true), "colored in the mage color")
	-- On retail the class can be secret: it can't index the class colors.
	local secret = newproxy(true)
	local meta = getmetatable(secret)
	local function refuse() error('attempt to use a secret value', 2) end
	meta.__index, meta.__newindex, meta.__call, meta.__len, meta.__concat = refuse, refuse, refuse, refuse, refuse
	local real = issecretvalue
	issecretvalue = function(v) return v == secret end
	stub.units.target.class = secret
	local ok, text = pcall(tag, 'target', 'target', 'target')
	check(ok, 'no error with a secret class: ' .. tostring(text))
	check(ok and text:sub(-5) == 'Jaina' and not text:find('|cff' .. hex .. 'Jaina', 1, true), 'the name left uncolored')
	issecretvalue = real
	name.colorClass = false
	stub.units.target = nil
end)

-- Last, since it switches SaftUI's theme.
test('Copy from draws under Thin, Blizzard and Thick, its buttons in each look', function()
	for _, name in ipairs({ 'thin', 'blizzard', 'thick' }) do
		T.theme(name)
		UF:OpenCopyTable('player')
		check_copy_layout(name)
		for _, key in ipairs({ 'toggle_all', 'toggle_none', 'accept', 'cancel' }) do
			eq(cell(key).widget.blizzard or false, name == 'blizzard', name .. ': ' .. key .. " is the look's button")
		end
		OW:CloseDialog()
	end
	eq(#take_errors(), 0, 'no errors')
end)

test("at half: the Health and Power tabs' note wraps to the body, clear of the rows, whole pixels under every look", function()
	local OB = st.OptionsBody
	local P = load_test_file('lib/pixels.lua')
	local N = load_test_file('lib/halfnotes.lua')
	local config, seen = legacy_config(), 0
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		st.config.profile.theme.name = look
		local width = look == 'blizzard' and 368 or 388
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			for _, unit in ipairs({ 'player', 'target' }) do
				for _, tab in ipairs({ 'Health', 'Power' }) do
					local content = CreateFrame('Frame', nil, UIParent)
					content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
					content:SetSize(width, 4000)
					local body = OB.New(content, { Unitframes = config }, nil, 774)
					body:SetWidth(width, true)
					body:Draw(OM.BuildView({ Unitframes = config }, 'Unitframes', { pick = unit, tab = tab }).sections)
					local where = look .. ' ' .. unit .. ' ' .. tab .. ' noise ' .. noise
					seen = seen + N.check(body, where)
					local off = P.off(content)
					eq(#off, 0, where .. ': ' .. P.report(off))
					body:Release()
				end
			end
		end
	end
	stub.size_noise = 0
	st.config.profile.theme.name = 'thick'
	check(seen >= 3 * 3 * 4, 'the tabs have notes (' .. seen .. ' checked)')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ All units, and the members' shares (S1)

-- The profile converted to shared settings for the cases below, and put back after (the world is one for the
-- whole file): the members' shared rows have the share source, All units' rows are derived.
local function convert()
	UF:PrepareShared()
	assert(UF:SharedReady(), 'the profile did not convert')
end
local function unconvert()
	local profile = UF:GetProfileConfig()
	rawset(profile, 'all', nil)
	rawset(profile, 'backup', nil)
	for _, unit in ipairs(UF.SHARE_MEMBERS) do rawset(profile[unit], 'own', nil) end
	UF:UpdateConfig()
end

test('every unit frame row has a reset, All units included: fourteen picks, shared rows by their share, the rest derived', function()
	convert()
	local tree = UF:GetConfigTable()
	local picks = 0
	for _ in pairs(tree.args) do picks = picks + 1 end
	eq(picks, 14, 'fourteen picks')
	R.check_page(Page(), 'Unitframes', { probe = false, fresh = false })
	-- Each shared row of a member (and its part row) says its source is the share; All units' rows are derived.
	local root = { Unitframes = tree }
	local shared, derived = 0, 0
	each_option({ args = root }, function(option, path)
		if type(option) ~= 'table' or type(option.type) ~= 'string' then return end
		if path[2] == 'party' and option.share ~= nil and path[#path] == 'font' then
			local row = { option = option, path = path, type = option.type, key = path[#path] }
			if path[3] == 'general' then
				-- A part menu's row is read through its menu root.
				return
			end
			eq(OM.DefaultSource(root, row), 'share', 'party ' .. table.concat(path, '/'))
			shared = shared + 1
		end
	end)
	check(shared > 0, 'party has shared rows on its tabs')
	unconvert()
end)

test("All units' derived resets round-trip, reaching every follower", function()
	convert()
	local tree = UF:GetConfigTable()
	local root = { Unitframes = { type = 'group', name = tree.name, childGroups = tree.childGroups, args = { all = tree.args.all } } }
	-- A row's set copies into the followers: allow every member's copy of the entry's paths.
	local allow = {}
	local name = UF:GetProfile()
	each_option({ args = root }, function(option, path)
		if type(option) ~= 'table' or option.share == nil or option.share.own ~= nil then return end
		local keys = {}
		local joined = table.concat(path, '.')
		-- The entry of the row, found by the paths its share was made from: every entry it could be.
		for _, entry in ipairs(UF.SHARED) do
			for _, member in ipairs(UF.SHARE_MEMBERS) do
				for _, entry_path in ipairs(entry.paths) do
					keys[#keys + 1] = 'unitframes.profiles.' .. name .. '.' .. member .. '.' .. table.concat(entry_path, '.')
				end
			end
		end
		allow[joined] = keys
	end)
	R.check_page(root, 'Unitframes', { fresh = false, allow = allow })
	unconvert()
end)

test('the part rows of every member walk as share rows, and each unit page keeps its own rows derived', function()
	convert()
	local tree = UF:GetConfigTable()
	local root = { Unitframes = tree }
	for _, unit in ipairs({ 'player', 'party', 'boss' }) do
		for _, part in ipairs(UF.UnitParts(unit)) do
			local item = tree.args[unit].args.general.args.parts and tree.args[unit].args.general.args.parts.args[part.key]
			if item and UF.PartShare(unit, part) then
				eq(OM.DefaultSource(root, { option = item, path = { 'Unitframes', unit, 'general', 'parts', part.key }, type = 'item', key = part.key }),
					'share', unit .. ' ' .. part.key)
			end
		end
	end
	unconvert()
end)
