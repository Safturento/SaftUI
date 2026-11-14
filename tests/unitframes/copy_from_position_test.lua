-- Copy from with Position ticked, when the other unit frame's position can't be
-- this one's: it is anchored to this frame (the game refuses a frame anchored
-- to itself), or to a frame that is anchored to this one. SaftUI-Unitframes/
-- config/config.lua: UF:PositionCopyProblem, UF:CopySettings and the dialog's
-- Position row.
--
-- Real: the same world as copy_from_history_test.lua (the unit frames'
-- defaults, the /sui window, edit mode's history and the dialog), with named
-- frames for the units, as the game's SaftUI_<Unit> ones.
-- Stand-in: UF:UpdateConfig counts its calls.

local UW = load_test_file('unitframes/uf_world.lua')
local st, UF = UW.world({ position = true })
load_saftui('SaftUI-Core/Libraries/Ace3/AceConfig-3.0/AceConfigRegistry-3.0/AceConfigRegistry-3.0.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_options_window()
load_editmode()

local EM, OW, W = st.EditModeFrames, st.OptionsWindow, st.OptionsWidgets
local History = EM.History
local click = stub.click

local updates = 0
function UF:UpdateConfig() updates = updates + 1 end
UF.units, UF.groups, UF.holders = {}, {}, {}
for _, unit in ipairs({ 'player', 'target', 'focus' }) do
	UF.units[unit] = CreateFrame('Frame', 'SaftUI_' .. unit:sub(1, 1):upper() .. unit:sub(2), UIParent)
end

local function config() return UF:GetProfileConfig() end

local function fresh()
	History:SetLimit(50)
	History:Clear()
	stub.in_combat = false
	st.config.profile.unitframes.config_profile = 'SaftUI'
	local P = config()
	for _, unit in ipairs({ 'player', 'target', 'focus' }) do
		UF.units[unit]:ClearAllPoints()
		P[unit].enable = true
	end
	P.player.width, P.target.width, P.focus.width = 250, 300, 275
	P.player.position = { point = 'BOTTOMRIGHT', frame = 'UIParent', rel_point = 'CENTER', x_off = -180, y_off = 181 }
	P.target.position = { point = 'TOPRIGHT', frame = 'SaftUI_Player', rel_point = 'BOTTOMRIGHT', x_off = -2, y_off = -8 }
	P.focus.position = { point = 'LEFT', frame = 'UIParent', rel_point = 'CENTER', x_off = 5, y_off = 6 }
	updates = 0
end

-- Where the frame sits as the position says, as PlaceUnitFrame sets it.
local function place(unit)
	local frame = UF.units[unit]
	frame:ClearAllPoints()
	frame:SetPoint(st:UnpackPoint(config()[unit].position))
end

test("Target anchored to Player, copied onto Player: position is left out, the rest is copied as one step", function()
	fresh()
	local P = config()
	place('target')
	local before = st.tablecopy(P.player.position, true)
	local step, why = UF:CopySettings('player', 'target', { 'position', 'width' })
	eq(why, "Position wasn't copied: Target is anchored to Player.", 'the reason is reported')
	eq(P.player.position.frame, 'UIParent', "Player isn't anchored to itself")
	eq(P.player.position.x_off, before.x_off, 'its position is unchanged')
	eq(P.player.width, 300, 'the other ticked part is copied')
	check(step ~= nil, 'a step')
	eq(#History:Steps(), 1, 'one step')
	eq(#step.changes, 1, 'without position')
	eq(step.changes[1].where.key, 'width', 'only width')
	eq(updates, 1, 'the unit frames were updated once')
	eq(History:Undo(), true, 'Undo')
	eq(P.player.width, 250, 'width is back')
	eq(P.player.position.frame, 'UIParent', 'position was never touched')
	eq(P.player.position.x_off, before.x_off, 'position still the same')
end)

test("only Position ticked: nothing is written or recorded, the reason is still reported", function()
	fresh()
	local step, why = UF:CopySettings('player', 'target', { 'position' })
	eq(step, nil, 'no step')
	eq(#History:Steps(), 0, 'nothing in the history')
	eq(why, "Position wasn't copied: Target is anchored to Player.", 'the reason')
	eq(config().player.position.frame, 'UIParent', 'unchanged')
end)

test("a loop through a third frame is left out, with the validator's reason", function()
	fresh()
	local P = config()
	-- Focus is anchored to Target, which is anchored to Player: Focus's position on Player would loop.
	P.focus.position = { point = 'TOP', frame = 'SaftUI_Target', rel_point = 'BOTTOM', x_off = 0, y_off = -5 }
	place('target')
	place('focus')
	local step, why = UF:CopySettings('player', 'focus', { 'position', 'width' })
	eq(why, "Position wasn't copied: Anchor would create a loop.", 'the reason')
	eq(P.player.position.frame, 'UIParent', 'unchanged')
	eq(#step.changes, 1, 'the rest is one step without position')
end)

test("a frame that doesn't exist is left out", function()
	fresh()
	local P = config()
	P.focus.position = { point = 'TOP', frame = 'SaftUI_NoSuchFrame', rel_point = 'BOTTOM', x_off = 0, y_off = 0 }
	local _, why = UF:CopySettings('player', 'focus', { 'position' })
	eq(why, "Position wasn't copied: Frame doesn't exist.", 'the reason')
	eq(P.player.position.frame, 'UIParent', 'unchanged')
end)

test("a valid position still copies, with no reason", function()
	fresh()
	local P = config()
	place('target')
	local step, why = UF:CopySettings('target', 'focus', { 'position', 'width' })
	eq(why, nil, 'no reason')
	eq(#step.changes, 2, 'both changed')
	eq(P.target.position.x_off, 5, 'copied')
	-- Anchored to another frame that doesn't lead back is fine too.
	UF.units.target:ClearAllPoints()
	P.focus.position = { point = 'TOP', frame = 'SaftUI_Target', rel_point = 'BOTTOM', x_off = 1, y_off = 2 }
	_, why = UF:CopySettings('player', 'focus', { 'position' })
	eq(why, nil, "Player on Target's frame, which isn't anchored to Player now")
	eq(P.player.position.frame, 'SaftUI_Target', 'copied')
end)

-- The dialog's drawn rows, by key.
local function cell(key)
	for _, c in ipairs(OW.GetDialogFrames().body.cells) do
		if c.row.key == key then return c end
	end
end

test("the dialog shows Position disabled, with why, while the chosen unit's can't be copied", function()
	fresh()
	local P = config()
	UF:OpenCopyTable('player')
	eq(cell('position').row.disabled, false, 'no unit chosen: enabled')
	cell('copy_from').widget:Commit('target')
	eq(cell('position').row.disabled, true, 'Target is anchored to Player: disabled')
	eq(cell('position').row.disabledDesc, "Can't copy Position: Target is anchored to Player.", 'with the reason')
	-- All leaves it out, and the copy does too.
	click(cell('toggle_all').widget.frame)
	eq(cell('position').row.disabled, true, 'still disabled after All')
	click(cell('width').widget.frame) -- off
	click(cell('width').widget.frame) -- on again
	click(cell('accept').widget.frame)
	click(W.GetDialogFrames().yes)
	eq(P.player.width, 300, 'the others copied')
	eq(P.player.position.frame, 'UIParent', 'position not copied')
	eq(#History:Steps(), 1, 'one step')
	for _, change in ipairs(History:Steps()[1].changes) do
		check(change.where.key ~= 'position', 'no position in the step')
	end
	-- A unit whose position can be copied leaves it enabled.
	UF:OpenCopyTable('player')
	cell('copy_from').widget:Commit('focus')
	eq(cell('position').row.disabled, false, 'Focus: enabled')
	OW:CloseDialog()
end)
