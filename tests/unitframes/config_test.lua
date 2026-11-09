-- SaftUI-Unitframes/config/config.lua's /sui pieces: the Copy from dialog
-- (UF:OpenCopyTable, drawn by st.OptionsWindow:OpenDialog).
--
-- Real: Core's helpers and profile defaults (load_core_helpers), the unit
-- frames' defaults, filled the way AceDB fills them (apply_defaults), so a
-- unit's settings are made by reading them, as in game; AceConfigRegistry-3.0
-- (the options window listens to it); the options model, widgets, body and
-- window; and config/config.lua.
--
-- Stand-in, for unitframes.lua, which needs oUF: UF:UpdateConfig, which counts
-- its calls. The real one re-applies every unit frame from the profile.
load_core_helpers()
load_saftui('SaftUI-Unitframes/config/default.lua')
apply_defaults()
load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionswidgets.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_saftui('SaftUI-Core/Config/optionswindow.lua')

local st = SaftUI
local OW, W = st.OptionsWindow, st.OptionsWidgets
local UF = st:NewModule('Unitframes')
local updates = 0
function UF:UpdateConfig() updates = updates + 1 end

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
