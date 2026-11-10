-- SaftUI-Unitframes/config/config.lua's /sui pieces: the Copy from dialog
-- (UF:OpenCopyTable, drawn by st.OptionsWindow:OpenDialog), the order of the
-- units in the page's picker, and AceConfigRegistry's validation of the table.
--
-- Real: Core's helpers and profile defaults (load_core_helpers), the unit
-- frames' defaults, filled the way AceDB fills them (apply_defaults), so a
-- unit's settings are made by reading them, as in game; AceConfigRegistry-3.0
-- (the options window listens to it); the options model, widgets, body and
-- window; and config/config.lua.
--
-- Stand-ins, for unitframes.lua, which needs oUF:
--   * UF:UpdateConfig counts its calls. The real one re-applies every unit
--     frame from the profile.
--   * What its OnEnable makes, as far as UF:GetConfigTable reads it: UF.units
--     and UF.groups, a frame by config unit (boss is a list of five frames in
--     game), UF.holders for the groups, and UF:GetMoverFrame (unitframes.lua's:
--     the holder, else the unit's frame). No elements: each element's file
--     needs oUF, so the units have no element tabs here.
--   * UF.unit_strings and UF.group_strings, empty: unitframes.lua's name the
--     units (Player, Raid 10, ...), and without them a unit is named by its key.
--
-- AceConfigRegistry validates ace_ready (tests/core/options_walk.lua) of the
-- table: a copy without SaftUI's own fields and Position options.
load_core_helpers()
load_saftui('SaftUI-Unitframes/config/default.lua')
apply_defaults()
load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionswidgets.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_saftui('SaftUI-Core/Config/optionswindow.lua')
load_test_file('core/options_walk.lua')

local st = SaftUI
local OM, OW, W = st.OptionsModel, st.OptionsWindow, st.OptionsWidgets
local AceConfigRegistry = LibStub('AceConfigRegistry-3.0')
local UF = st:NewModule('Unitframes')
local updates = 0
function UF:UpdateConfig() updates = updates + 1 end

UF.units, UF.groups, UF.holders, UF.elements = {}, {}, {}, {}
for _, unit in ipairs({ 'boss', 'focustarget', 'player', 'pettarget', 'target', 'pet', 'targettarget', 'focus' }) do
	UF.units[unit] = CreateFrame('Frame', nil, UIParent)
end
for _, group in ipairs({ 'raid40', 'party', 'raid10' }) do
	UF.groups[group] = CreateFrame('Frame', nil, UIParent)
	UF.holders[group] = CreateFrame('Frame', nil, UIParent)
end
UF.unit_strings, UF.group_strings = {}, {}
function UF:GetMoverFrame(unit) return self.holders[unit] or self.units[unit] end

load_saftui('SaftUI-Unitframes/config/config.lua')

local function click(frame, ...) stub.fire_script(frame, 'OnClick', ...) end

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

	-- Copy from, All and None, a toggle per setting of the unit's, Confirm copy.
	local keys = rows()
	eq(table.concat(keys, ',', 1, 3), 'copy_from,toggle_all,toggle_none', 'the unit to copy from, All, None')
	eq(keys[#keys], 'accept', 'Confirm copy last')
	local expected, got = {}, {}
	for key in pairs(P.player) do expected[#expected + 1] = key end
	for i = 4, #keys - 1 do got[#got + 1] = keys[i] end
	table.sort(expected)
	table.sort(got)
	eq(table.concat(got, ','), table.concat(expected, ','), "a toggle per setting of player's")
	check(#got > 10, 'many of them: ' .. #got)
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
	for i = 4, #keys - 1 do all = all and cell(keys[i]).widget.value end
	check(all, 'All ticks every setting')
	click(cell('toggle_none').widget.frame)
	local none = true
	for i = 4, #keys - 1 do none = none and not cell(keys[i]).widget.value end
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

test('closing the Copy from dialog cancels a prompt or confirm open over it', function()
	local cancelled = 0
	UF:OpenCopyTable('player')
	W.Prompt('Name?', '', function() end, { onCancel = function() cancelled = cancelled + 1 end })
	check(W.PromptBox() ~= nil, 'the prompt is up')
	OW:CloseDialog()
	eq(cancelled, 1, 'the dialog hiding cancelled it')
	eq(W.PromptBox(), nil, 'and closed it')
end)

test('the unit picker lists the units in a fixed order, Player first, and Profile last', function()
	local view = OM.BuildView({ Unitframes = UF:GetConfigTable() }, 'Unitframes')
	local keys = {}
	for i, entry in ipairs(view.picker.values) do keys[i] = entry.key end
	eq(table.concat(keys, ','), 'player,target,targettarget,focus,focustarget,pet,pettarget,boss,party,raid10,raid40,profile',
		'Player, Target, TargetTarget, Focus, FocusTarget, Pet, PetTarget, Boss, Party, Raid 10, Raid 40, then Profile')
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
end)

test("the unit frames' page: picker labelled Unit; boss has Layout without test mode; range alpha on every unit", function()
	local config = UF:GetConfigTable()
	eq(config.pickerLabel, 'Unit', 'the picker is labelled Unit')

	local layout = config.args.boss.args.general.args.layout
	check(layout, 'boss has a Layout group in General')
	for _, key in ipairs({ 'growthDirection', 'spacing', 'unitsPerColumn', 'initialAnchor', 'columnSpacing', 'maxColumns' }) do
		check(layout.args[key], 'boss Layout has ' .. key)
	end
	eq(layout.args.test_mode, nil, 'no test mode for boss')
	eq(layout.args.showPlayer, nil, 'no show player for boss')
	check(config.args.party.args.general.args.layout.args.test_mode, 'party keeps test mode')
	check(config.args.party.args.general.args.layout.args.showPlayer, 'party keeps show player')
	check(config.args.raid10.args.general.args.layout.args.test_mode, 'raid keeps test mode')
	eq(config.args.raid10.args.general.args.layout.args.showPlayer, nil, 'raid has no show player')

	-- A Layout change on boss re-applies boss, as General's other settings do.
	local P = UF:GetProfileConfig()
	local before = updates
	local g = config.args.boss.args.general
	g.set({ 'boss', 'general', 'maxColumns' }, 2)
	eq(P.boss.maxColumns, 2, 'written to the boss config')
	eq(updates, before + 1, 'and boss was updated')
	P.boss.maxColumns = 1

	for unit, group in pairs(config.args) do
		if unit ~= 'profile' then
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
		if #path >= 2 and path[2] ~= 'general' and path[2] ~= 'copy' and path[1] ~= 'profile' then return end
		local where = table.concat(path, '.')
		eq(option.width, nil, where .. ' has no width')
		if option.type ~= 'group' and option.type ~= 'header' and option.type ~= 'description' then
			check(type(option.desc) == 'string' and option.desc ~= '', where .. ' has a desc')
		end
	end)
	eq(config.args.profile.args.new.size, 'small', 'Profile buttons are small')
end)
