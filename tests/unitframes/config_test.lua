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
-- nameplates/threat.lua (the plates' Threat element and its tab) and
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
--   * UF.unit_strings, empty: unitframes.lua's name the units (Player,
--     Target, ...), and without them a unit is named by its key. UF.group_strings
--     is unitframes.lua's, as the Ready check element's ValidUnit reads it;
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
load_core_helpers()
load_saftui('SaftUI-Unitframes/config/position.lua') -- config/load.xml's order: first
load_saftui('SaftUI-Unitframes/config/default.lua')
-- The nameplates' own defaults (enable, friendly, threat_solo, the threat
-- text, width, height); the other units' come from every unit's.
load_saftui('SaftUI-Unitframes/config/units/nameplate.lua')
apply_defaults()
load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_options_window()
load_test_file('lib/options_walk.lua')
local T = load_test_file('lib/theme_helpers.lua')

local st = SaftUI
local OM, OW, W = st.OptionsModel, st.OptionsWindow, st.OptionsWidgets
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
-- The module by hand, UF:RegisterElement as unitframes.lua's table store
-- (uf_world.lua's UW.module).
local UF = load_test_file('unitframes/uf_world.lua').module()
local updates = 0
function UF:UpdateConfig() updates = updates + 1 end

UF.units, UF.groups, UF.holders = {}, {}, {}
for _, unit in ipairs({ 'boss', 'focustarget', 'player', 'pettarget', 'target', 'pet', 'targettarget', 'focus' }) do
	UF.units[unit] = CreateFrame('Frame', nil, UIParent)
end
for _, group in ipairs({ 'raid40', 'party', 'raid10' }) do
	UF.groups[group] = CreateFrame('Frame', nil, UIParent)
	UF.holders[group] = CreateFrame('Frame', nil, UIParent)
end
UF.unit_strings = {}
UF.group_strings = { party = 'Party', raid10 = 'Raid 10', raid40 = 'Raid 40' }
UF.PLATE_UNITS = { nameplate = true, friendlynameplate = true }
function UF.IsPlateUnit(unit) return UF.PLATE_UNITS[unit] == true end
function UF:GetMoverFrame(unit) return self.holders[unit] or self.units[unit] end

load_saftui('SaftUI-Unitframes/config/profiles.lua')
load_saftui('SaftUI-Unitframes/config/groupoptions.lua')
load_saftui('SaftUI-Unitframes/config/config.lua')
load_saftui('SaftUI-Unitframes/updaters.lua')
load_saftui('SaftUI-Unitframes/nameplates/nameplates.lua')
load_saftui('SaftUI-Unitframes/nameplates/threat.lua')
load_saftui('SaftUI-Unitframes/nameplates/options.lua')
-- elements/elements.xml's order; aurawatch.lua and portrait.lua register nothing.
for _, file in ipairs({ 'name', 'auras', 'power', 'additionalpower', 'health', 'castbar', 'classpower', 'indicators' }) do
	load_saftui('SaftUI-Unitframes/elements/' .. file .. '.lua')
end
-- The name tag (tags.lua), with LibStringFormat-1.0, which init.lua makes
-- st.StringFormat.
UF.oUF = { Tags = { Events = {}, Methods = {} }, colors = { class = st.config.profile.colors.class } }
load_string_format()
load_saftui('SaftUI-Unitframes/tags.lua')

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

test('Copy from opens a SaftUI dialog whose rows come from its table, and copies what was ticked', function()
	local P = UF:GetProfileConfig()
	P.player.width, P.target.width = 1, 123
	P.player.height, P.target.height = 34, 50
	P.player.health.height, P.target.health.height = 0, 7

	UF:OpenCopyTable('player')
	check(OW:IsDialogShown(), 'a SaftUI dialog')
	local d = OW.GetDialogFrames()
	eq(d.title:GetText(), 'Clone player from..', 'its title')

	-- Copy from, All and None, a toggle per setting of the unit's, Confirm copy and Cancel.
	local keys = rows()
	eq(table.concat(keys, ',', 1, 3), 'copy_from,toggle_all,toggle_none', 'the unit to copy from, All, None')
	eq(keys[#keys - 1] .. ',' .. keys[#keys], 'accept,cancel', 'Confirm copy, then Cancel, last')
	local expected, got = {}, {}
	for key in pairs(P.player) do expected[#expected + 1] = key end
	for i = 4, #keys - 2 do got[#got + 1] = keys[i] end
	table.sort(expected)
	table.sort(got)
	eq(table.concat(got, ','), table.concat(expected, ','), "a toggle per setting of player's")
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
		check(not (row:IsShown() and row.text:GetText() == 'player'), 'player is not offered')
		if row:IsShown() and row.text:GetText() == 'target' then
			click(row)
			picked = true
			break
		end
	end
	check(picked, 'target is offered')
	eq(d.title:GetText(), 'Clone player from target', 'the title says so')
	check(not cell('accept').widget:IsDisabled(), 'Confirm copy is on')

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
	eq(W.ConfirmText(), 'Are you sure you want to clone player from target?', 'it asks')
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
	eq(d.title:GetText(), 'Clone target from..', 'a new title')
	for _, key in ipairs(rows()) do
		local c = cell(key)
		if c.row.type == 'toggle' then check(not c.widget.value, key .. ' starts unticked') end
	end
	check(cell('accept').widget:IsDisabled(), 'no unit picked yet')
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
		-- Confirm copy and Cancel carry on the Settings section: one panel, no seam.
		local panels, above = {}, 0
		for _, p in ipairs(d.body.pools.panel.used) do
			if p:IsShown() then panels[#panels + 1] = p end
		end
		for _, c in ipairs(d.body.cells) do
			if c.y < accept.y then above = math.max(above, c.y) end
		end
		eq(#panels, 2, where .. ': a panel for Copy from\'s line and one for the settings and the buttons')
		eq(accept.y, above + 38, where .. ': the buttons directly under the settings, no gap')
		local _, _, _, _, py = panels[#panels]:GetPoint(1)
		eq(-py + panels[#panels]:GetHeight(), accept.y + 38, where .. ': the settings\' panel reaches under the buttons')
	end
end

test("Copy from's label has room: All and None sit at its line's right end; Confirm copy and Cancel in the middle at the bottom", function()
	UF:OpenCopyTable('player')
	check_copy_layout('Thick')
	-- Picking a unit draws it again the same way.
	cell('copy_from').widget:Commit('target')
	eq(OW.GetDialogFrames().title:GetText(), 'Clone player from target', 'picked')
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
	eq(W.ConfirmText(), 'Are you sure you want to clone player from target?', 'Confirm copy asks')
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
	check(offered.target, 'target is offered')
	check(not offered.nameplate, 'the nameplates are not')
	W.CloseList()
	OW:CloseDialog()
	eq(UF:GetConfigTable().args.nameplate.args.copy, nil, 'no Copy from on the Enemy nameplates page')
	check(UF:GetConfigTable().args.player.args.copy ~= nil, "the player's keeps it")
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

test('the unit picker lists the units in a fixed order, Player first, and no Profile (it is the footer control)', function()
	local view = OM.BuildView({ Unitframes = UF:GetConfigTable() }, 'Unitframes')
	local keys = {}
	for i, entry in ipairs(view.picker.values) do keys[i] = entry.key end
	eq(table.concat(keys, ','), 'player,target,targettarget,focus,focustarget,pet,pettarget,boss,party,raid10,raid40,nameplate,friendlynameplate',
		'Player, Target, TargetTarget, Focus, FocusTarget, Pet, PetTarget, Boss, Party, Raid 10, Raid 40, Enemy nameplates, Friendly nameplates')
	eq(view.picker.selected, 'player', 'the page opens on Player')
end)

test("the unit frames' table passes AceConfigRegistry validation, SaftUI's fields aside", function()
	local config = UF:GetConfigTable()
	check(config.category ~= nil, 'it has a category')
	eq(config.args.player.args.general.args.position.type, 'position', 'and Position options')
	local ok, err = pcall(AceConfigRegistry.ValidateOptionsTable, AceConfigRegistry,
		ace_ready({ name = st.name, type = 'group', args = { Unitframes = config } }), st.name)
	check(ok, 'valid: ' .. tostring(err))
	check(config.category ~= nil, 'the table itself keeps its category')
	check(config.footer ~= nil, 'and its footer (SaftUI\'s field, which ace_ready leaves off)')
	-- The footer control's options and the Unit frame profiles dialog's, as groups of their own.
	ok, err = pcall(AceConfigRegistry.ValidateOptionsTable, AceConfigRegistry,
		ace_ready({ name = st.name, type = 'group', args = { footer = config.footer, dialog = UF.GenerateProfileConfigGroup() } }), st.name)
	check(ok, 'the footer and the dialog valid: ' .. tostring(err))
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
	-- The footer control's options and the Unit frame profiles dialog's.
	for where, tree in pairs({ footer = config.footer, dialog = UF.GenerateProfileConfigGroup() }) do
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
	local config = UF:GetConfigTable()
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
		'Buffs,Castbar,Debuffs,Health,Name,QuestIndicator,RaidTargetIndicator,Threat',
		'nameplates have no power, role or ready check, and have the threat text')
end)

test('every element tab: a tooltip on every option, no Ace width, and each Position a block last in its group', function()
	local config = UF:GetConfigTable()
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
	for _, unit in ipairs(UNITS) do
		for tab, group in pairs(element_tabs(config, unit)) do
			position_last(group, unit .. '.' .. tab)
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
	local config = UF:GetConfigTable()
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
	local config = UF:GetConfigTable()
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
				-- Then Custom and its color, together on a line of their own.
				expected[#expected + 1] = 'custom'
				eq(table.concat(in_order(colors), ','), table.concat(expected, ','), where .. "'s colors")
				local custom = colors.args.custom
				if check(custom.type == 'group' and custom.inline and custom.name == '', where .. ': Custom in an untitled group') then
					eq(table.concat(in_order(custom), ','), 'colorCustom,customColor', where .. "'s custom color")
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
	eq(layout(config, 'player', 'Power', 'Colors', true), 'colorCustom:small 1/1, customColor:normal 2',
		'Custom and its color on the next line, untitled, whatever the count above: the color takes the right half')
	eq(layout(config, 'nameplate', 'Health', 'Colors'),
		'colorTapping:small 1/1, colorClass:small 1/2, colorClassNPC:small 2/1, colorClassPet:small 2/2, '
		.. 'colorReaction:small 1/1, colorSmooth:small 1/2, colorHealth:small 2/1',
		"the nameplates' health colors: every one but Disconnected")
end)

test('Health, Power and Additional power: Custom and its color, kept in the shape the profile holds it', function()
	local config = UF:GetConfigTable()
	local P = UF:GetProfileConfig()
	local root = { Unitframes = config }
	for _, case in ipairs({ { 'target', 'Health' }, { 'party', 'Health' }, { 'player', 'Power' }, { 'boss', 'Power' }, { 'player', 'AdditionalPower' } }) do
		local unit, tab = case[1], case[2]
		local where = unit .. '.' .. tab
		local store = P[unit][string.lower(tab)]
		reads_and_writes(config, unit, tab, { 'colors', 'custom', 'colorCustom' }, store, 'colorCustom', not store.colorCustom)

		local option, row = option_at(config, unit, tab, 'colors', 'custom', 'customColor')
		if check(option and option.type == 'color' and option.size == 'small', where .. ' has a small Custom color') then
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

test("every element's alpha has an option, 0 to 1, on the element's config", function()
	local config = UF:GetConfigTable()
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
	local config = UF:GetConfigTable()
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

test('Name: Classification where rare and elite units can show, Class color where players can', function()
	local config = UF:GetConfigTable()
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
local TEXTS = { Name = true, Threat = true }
local function themed_parts(config, P, unit)
	local parts = { { 'general', {}, P[unit] } }
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
	local config = UF:GetConfigTable()
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
				check(type(theme.desc) == 'string' and theme.desc:find('Global Settings > Theme', 1, true) ~= nil,
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
end)

-- The castbar's Bar and Icon sections each have their own Theme and
-- Background, so a section, not a tab, has one Background at most.
test('no element tab shows two settings named Background: the bar\'s own empty-part fill is Bar background', function()
	local config = UF:GetConfigTable()
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
	local config = UF:GetConfigTable()
	local view = OM.BuildView({ Unitframes = config }, 'Unitframes', { pick = 'target', tab = 'Health' })
	-- The unit's Copy from comes first, above every tab; then the tab's own.
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
	eq(view.sections[#view.sections].title, 'Position', 'Position is the last section')
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
