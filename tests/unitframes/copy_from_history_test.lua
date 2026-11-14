-- Copy from as one step of edit mode's history (SaftUI-Unitframes/config/
-- config.lua: UF:CopySettings and the 'ufsetting' kind; config/profiles.lua:
-- the history clears wherever the unit frame profile is switched).
--
-- Real: the unit frames' world (unitframes/uf_world.lua: Core's helpers, the
-- unit frames' defaults filled the way AceDB fills them, the module's own files
-- and the elements), the /sui window (the model, widgets, body and window, as
-- unitframes/config_test.lua loads them) and edit mode's files, so the real
-- history store and the real dialog are used.
-- Stand-in: UF:UpdateConfig counts its calls (the real one re-applies every
-- spawned frame and needs oUF).

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
for _, unit in ipairs({ 'player', 'target', 'focus' }) do UF.units[unit] = CreateFrame('Frame', nil, UIParent) end

local function config() return UF:GetProfileConfig() end

local function fresh()
	History:SetLimit(50)
	History:Clear()
	stub.in_combat = false
	st.config.profile.unitframes.config_profile = 'SaftUI'
	local P = config()
	P.target.width, P.focus.width = 300, 250
	P.target.health.height, P.focus.health.height = 7, 0
	P.target.position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 40, y_off = -20 }
	P.focus.position = { point = 'BOTTOMRIGHT', frame = 'UIParent', rel_point = 'CENTER', x_off = -180, y_off = 181 }
	P.focus.enable, P.target.enable = false, true
	updates = 0
end

test('Copy from is one step that a single Undo takes back whole, and Redo does again', function()
	fresh()
	local P = config()
	local oldPosition = st.tablecopy(P.focus.position, true)
	local step = UF:CopySettings('focus', 'target', { 'health', 'position', 'width' })
	check(step ~= nil, 'a step')
	eq(#History:Steps(), 1, 'one step')
	eq(step.kind, 'bulk', 'a bulk step')
	eq(History.Label(step), 'Copied Target to Focus', 'its label names both units')
	eq(#step.changes, 3, 'a change per differing key')
	eq(updates, 1, 'the unit frames were updated once')
	eq(P.focus.width, 300, 'copied: width')
	eq(P.focus.health.height, 7, 'copied: health')
	eq(P.focus.position.x_off, 40, 'copied: position')
	check(P.focus.health ~= P.target.health and P.focus.position ~= P.target.position, 'as copies, not the same tables')

	local ok = History:Undo()
	eq(ok, true, 'Undo')
	eq(P.focus.width, 250, 'width is back')
	eq(P.focus.health.height, 0, 'health is back, deep')
	eq(P.focus.position.point .. P.focus.position.x_off .. P.focus.position.y_off .. P.focus.position.rel_point, 'BOTTOMRIGHT-180181CENTER', 'position is back, every field')
	eq(P.focus.position.x_off, oldPosition.x_off, 'exactly')
	eq(updates, 2, 'the unit frames were updated by the Undo')
	eq(P.target.width, 300, 'the source is untouched')

	ok = History:Redo()
	eq(ok, true, 'Redo')
	eq(P.focus.width, 300, 'copied again: width')
	eq(P.focus.health.height, 7, 'health')
	eq(P.focus.position.x_off, 40, 'position')
	eq(updates, 3, 'updated again')
end)

test('a key equal on both is not listed; none differing records no step', function()
	fresh()
	local P = config()
	P.focus.width = P.target.width
	local step = UF:CopySettings('focus', 'target', { 'health', 'width' })
	eq(#step.changes, 1, 'only the differing key')
	eq(step.changes[1].where.key, 'health', 'health')
	History:Undo()
	History:Clear()
	local before = updates
	P.focus.health = st.tablecopy(P.target.health, true)
	P.focus.width = P.target.width
	eq(UF:CopySettings('focus', 'target', { 'health', 'width' }), nil, 'nothing differs: no step')
	eq(#History:Steps(), 0, 'none recorded')
	eq(updates, before + 1, 'the copy still updates the frames, as it did')
	eq(UF:CopySettings('focus', 'focus', { 'width' }), nil, 'a unit onto itself: no step')
	eq(UF:CopySettings('focus', 'target', {}), nil, 'no keys: no step')
end)

test('false is exact: a copy that turns an Enable on is undone to false, and one that turns it off to true', function()
	fresh()
	local P = config()
	eq(rawget(P.focus, 'enable'), false, 'focus starts false')
	UF:CopySettings('focus', 'target', { 'enable' })
	eq(P.focus.enable, true, 'copied: true')
	eq(History:Undo(), true, 'Undo works (not stale)')
	eq(rawget(P.focus, 'enable'), false, 'false stays false')
	eq(History:Redo(), true, 'Redo works')
	eq(P.focus.enable, true, 'true again')
	-- A copy from a unit that has the value false, onto one that has true.
	History:Clear()
	P.target.enable, P.focus.enable = false, true
	UF:CopySettings('focus', 'target', { 'enable' })
	eq(rawget(P.focus, 'enable'), false, 'copied: false')
	History:Undo()
	eq(rawget(P.focus, 'enable'), true, 'undone to true')
end)

test("an Undo is refused, and the step dropped, once the unit frame profile is not the one it was made in", function()
	fresh()
	UF:CopySettings('focus', 'target', { 'width' })
	st.config.profile.unitframes.config_profile = 'Healer' -- switched without the clear
	local ok, why = History:Undo()
	eq(ok, false, 'refused')
	eq(why, 'The unit frame profile changed since.', 'with the reason')
	eq(config().focus.width ~= nil, true, "Healer's focus is untouched")
	eq(#History:Steps(), 0, 'the step is dropped')
	st.config.profile.unitframes.config_profile = 'SaftUI'
	eq(st.config.profile.unitframes.profiles.SaftUI.focus.width, 300, "and SaftUI's still has the copy")
end)

test("an Undo and a Redo each refresh /sui once, after the unit frames", function()
	fresh()
	local refreshed = 0
	local real = st.Config.Refresh
	function st.Config:Refresh() refreshed = refreshed + 1 end
	UF:CopySettings('focus', 'target', { 'width' })
	History:Undo()
	eq(refreshed, 1, 'Undo: /sui refreshed once')
	History:Redo()
	eq(refreshed, 2, 'Redo: once more')
	st.Config.Refresh = real
end)

test("the kind stores copies: an edit made in /sui after an Undo is not the step's data, Redo is refused as stale and the edit survives", function()
	fresh()
	local P = config()
	local step = UF:CopySettings('focus', 'target', { 'health' })
	eq(History:Undo(), true, 'Undo')
	local change = step.changes[1]
	check(P.focus.health ~= change.old and P.focus.health ~= change.new, "the stored table is neither of the step's")
	eq(change.old.height, 0, "the step's old is untouched")
	P.focus.health.height = 55 -- an edit in /sui
	eq(change.old.height, 0, "and an edit never reaches the step's old")
	local ok, why = History:Redo()
	eq(ok, false, 'Redo is refused: the setting changed since')
	eq(why, 'Focus was changed since; its earlier steps are dropped.', 'with the history\'s message')
	eq(P.focus.health.height, 55, 'the edit survives')
	eq(#History:Steps(), 0, 'and the step is dropped')
	-- And after a Redo, an edit to the copied value is not the step's new.
	fresh()
	step = UF:CopySettings('focus', 'target', { 'health' })
	P.focus.health.height = 66
	eq(step.changes[1].new.height, 7, "an edit after the copy never reaches the step's new")
	eq(History:Undo(), false, 'and Undo is refused as stale')
	eq(P.focus.health.height, 66, 'the edit survives')
end)

-- The dialog's drawn rows, by key.
local function cell(key)
	for _, c in ipairs(OW.GetDialogFrames().body.cells) do
		if c.row.key == key then return c end
	end
end

test("the dialog's Confirm copy records the step; a unit frame profile switch clears the history", function()
	fresh()
	local P = config()
	UF:OpenCopyTable('focus')
	cell('copy_from').widget:Commit('target')
	click(cell('width').widget.frame)
	click(cell('health').widget.frame)
	click(cell('accept').widget.frame)
	eq(W.ConfirmText(), 'Are you sure you want to copy the ticked settings to Focus from Target?', 'it asks first')
	eq(#History:Steps(), 0, 'nothing recorded before Yes')
	click(W.GetDialogFrames().yes)
	eq(#History:Steps(), 1, 'one step')
	eq(History.Label(History:Steps()[1]), 'Copied Target to Focus', 'named')
	eq(P.focus.width, 300, 'copied')
	check(not OW:IsDialogShown(), 'the dialog closed')
	eq(History:Undo(), true, 'Undo takes it back')
	eq(P.focus.width, 250, 'width')
	eq(P.focus.health.height, 0, 'and health')
	eq(P.focus.position.x_off, -180, 'the unticked one never changed')

	-- The profile footer's dropdown.
	History:Redo()
	local _ = st.config.profile.unitframes.profiles.Healer -- reading makes it
	eq(#History:Steps(), 1, 'a step before the switch')
	local footer = UF:GetConfigTable().footer.args.current
	footer.set({}, 'Healer')
	eq(st.config.profile.unitframes.config_profile, 'Healer', 'switched')
	eq(#History:Steps(), 0, 'the history is empty after the switch')
	footer.set({}, 'SaftUI')
end)

test('every way to change the unit frame profile clears the history, a pick of the same one does not', function()
	fresh()
	UF:CopySettings('focus', 'target', { 'width' }) -- the kind is registered by now
	local function step()
		History:Push({ kind = 'bulk', label = 'x', changes = { { kind = 'ufsetting',
			where = { profile = UF:GetProfile(), unit = 'focus', key = 'width' }, old = 1, new = 2 } } })
		return #History:Steps()
	end
	local _ = st.config.profile.unitframes.profiles.Healer
	local footer = UF:GetConfigTable().footer.args.current

	check(step() >= 1, 'a step')
	footer.set({}, 'SaftUI')
	check(#History:Steps() >= 1, 'picking the profile already in use clears nothing')
	footer.set({}, 'Healer')
	eq(#History:Steps(), 0, 'the footer dropdown clears')

	step()
	UF:SetProfile('SaftUI')
	eq(#History:Steps(), 0, 'UF:SetProfile clears')
	step()
	UF:SetProfile('SaftUI')
	check(#History:Steps() >= 1, 'UF:SetProfile to the current one clears nothing')

	-- The dialog's dropdown is the same select.
	local dialog = UF.GenerateProfileConfigGroup().args.current
	dialog.set({}, 'Healer')
	eq(#History:Steps(), 0, "the dialog's dropdown clears")
	dialog.set({}, 'SaftUI')

	-- New, Copy, Rename (the prompts) and Delete.
	local function prompt(text)
		local box = W.PromptBox()
		box:SetText(text)
		stub.fire_script(box, 'OnEnterPressed')
	end
	local group = UF.GenerateProfileConfigGroup().args
	step()
	group.new.func()
	prompt('Fresh')
	eq(st.config.profile.unitframes.config_profile, 'Fresh', 'New switched to it')
	eq(#History:Steps(), 0, 'New clears')
	step()
	group.rename.func()
	prompt('Renamed')
	eq(st.config.profile.unitframes.config_profile, 'Renamed', 'Rename switched to it')
	eq(#History:Steps(), 0, 'Rename clears')
	step()
	group.delete.func()
	click(W.GetDialogFrames().yes)
	eq(#History:Steps(), 0, 'Delete clears')
	st.config.profile.unitframes.config_profile = 'SaftUI'
	OW:CloseDialog()
end)
