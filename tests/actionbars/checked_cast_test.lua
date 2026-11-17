-- A LibActionButton action button's selected state follows the game's checked
-- state through a cast with a cast time (SaftUI-ActionBars/skin.lua).
--
-- Bars 1-8 are registered with the client (actionButtonUI, C_ActionBar.
-- RegisterActionUIButton), and LibActionButton leaves their
-- ACTIONBAR_UPDATE_STATE to the client (OnEvent walks ActionButtonsNonUI only).
-- A key press runs LibActionButton's PostClick, which calls SetChecked (our
-- post-hook: selected on while the cast runs); the end of the cast is the
-- client's own update, which writes the checked state with no call of the Lua
-- SetChecked, so the hook never hears it. The sequence is modelled with
-- stub.engine_set_checked.
local T = load_test_file('lib/theme_helpers.lua')

local FILES = {
	'SaftUI-ActionBars/init.lua',
	'SaftUI-ActionBars/shared.lua',
	'SaftUI-ActionBars/skin.lua',
	'SaftUI-ActionBars/bars.lua',
	'SaftUI-ActionBars/buttons.lua',
	'SaftUI-ActionBars/petbar.lua',
	'SaftUI-ActionBars/stancebar.lua',
	'SaftUI-ActionBars/bindings.lua',
	'SaftUI-ActionBars/extras.lua',
	'SaftUI-ActionBars/textoptions.lua',
	'SaftUI-ActionBars/options.lua',
}

local st, AB

local function fresh(client)
	if client then
		T.client(client)
	else
		reset_world()
		load_core_helpers()
	end
	st = SaftUI
	load_test_file('actionbars/fixtures/libactionbutton.lua')
	load_saftui('SaftUI-ActionBars/config.lua')
	apply_defaults()
	for _, file in ipairs(FILES) do load_saftui(file) end
	AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
	stub.cvars.countdownForCooldowns = '1'
	AB:ConvertProfile()
end

-- A LibActionButton button: its read-only IsCurrentlyActive and IsAutoRepeat
-- read the game's action state (IsCurrentAction, IsAutoRepeatAction), here the
-- fields current and repeating.
local function button(name)
	local b = CreateFrame('CheckButton', name, UIParent, 'SecureActionButtonTemplate')
	b:SetSize(45, 45)
	b:SetPoint('CENTER')
	b.icon = b:CreateTexture(nil, 'BACKGROUND')
	b.Flash = b:CreateTexture(nil, 'ARTWORK')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		b[key] = b:CreateFontString(nil, 'OVERLAY')
		b[key]:SetFontObject(GameFontNormal)
	end
	b.cooldown = CreateFrame('Cooldown', nil, b)
	function b:UpdateConfig(config) self.labConfig = config end
	function b:IsEquipped() return false end
	function b:IsCurrentlyActive() return self.current == true end
	function b:IsAutoRepeat() return self.repeating == true end
	AB:SkinButton(b)
	AB:StyleButton(b, AB:GetBarConfig('bar1'), 'thick', 'solid')
	return b
end

-- LibActionButton's PostClick: UpdateButtonState, SetChecked from the game's state.
local function post_click(b)
	b:SetChecked(b:IsCurrentlyActive() or b:IsAutoRepeat())
end

-- The client's update at a change of the action state: it sets the check itself.
local function engine_update(b)
	stub.engine_set_checked(b, b:IsCurrentlyActive() or b:IsAutoRepeat())
	stub.fire_event('ACTIONBAR_UPDATE_STATE')
end

for _, client in ipairs({ 'forever', 'retail' }) do
	test('a cast with a cast time started by a key: selected while it casts, off when it ends (' .. client .. ')', function()
		fresh(client)
		local b = button('CCCast_' .. client)
		-- key down: the cast starts, PostClick checks the button
		b.current = true
		post_click(b)
		eq(st:GetState(b, 'selected'), true, 'selected while casting')
		eq(b:GetChecked(), true, 'checked')
		-- the cast ends: the client unchecks it
		b.current = false
		engine_update(b)
		eq(st:GetState(b, 'selected'), false, 'selected follows: off when the cast ends')
		eq(#take_errors(), 0, 'no errors')
	end)

	test('an instant cast is never selected; a cast the button did not start (a macro, the spellbook) shows and clears by the event (' .. client .. ')', function()
		fresh(client)
		local b = button('CCInstant_' .. client)
		-- instant: PostClick finds nothing current
		post_click(b)
		eq(st:GetState(b, 'selected'), false, 'an instant cast is never selected')
		-- a channel, then its end; an interrupted cast ends the same way
		for _ = 1, 2 do
			b.current = true
			engine_update(b)
			eq(st:GetState(b, 'selected'), true, 'selected while it runs')
			b.current = false
			engine_update(b)
			eq(st:GetState(b, 'selected'), false, 'off at its end')
		end
		eq(#take_errors(), 0, 'no errors')
	end)

	test('auto attack and auto shot (a backstop: LibActionButton\'s own StartFlash and StopFlash reach SetChecked): on with the repeat, off when it stops (' .. client .. ')', function()
		fresh(client)
		local b = button('CCAuto_' .. client)
		b.repeating = true
		stub.engine_set_checked(b, true)
		stub.fire_event('START_AUTOREPEAT_SPELL')
		eq(st:GetState(b, 'selected'), true, 'selected while repeating')
		b.repeating = false
		stub.engine_set_checked(b, false)
		stub.fire_event('STOP_AUTOREPEAT_SPELL')
		eq(st:GetState(b, 'selected'), false, 'off when it stops')
		b.current = true
		stub.engine_set_checked(b, true)
		stub.fire_event('PLAYER_ENTER_COMBAT')
		eq(st:GetState(b, 'selected'), true, 'melee auto attack on')
		b.current = false
		stub.engine_set_checked(b, false)
		stub.fire_event('PLAYER_LEAVE_COMBAT')
		eq(st:GetState(b, 'selected'), false, 'and off')
		eq(#take_errors(), 0, 'no errors')
	end)

	test('in combat the sync only sets the state: nothing forbidden, no SetChecked by SaftUI (' .. client .. ')', function()
		fresh(client)
		local b = button('CCCombat_' .. client)
		local calls = 0
		local native = b.SetChecked
		rawset(b, 'SetChecked', function(...) calls = calls + 1; return native(...) end)
		stub.in_combat = true
		b.current = true
		engine_update(b)
		b.current = false
		engine_update(b)
		stub.in_combat = false
		eq(calls, 0, 'SaftUI never calls SetChecked on the button')
		eq(#stub.blocked, 0, 'nothing forbidden on the secure button in combat')
		eq(st:GetState(b, 'selected'), false)
		eq(#take_errors(), 0, 'no errors')
	end)
end

test('the sync reads the game\'s state, not GetChecked: the engine writes nothing, selected still clears', function()
	fresh('forever')
	local b = button('CCNoWrite')
	b.current = true
	post_click(b)
	eq(st:GetState(b, 'selected'), true)
	b.current = false
	stub.fire_event('ACTIONBAR_UPDATE_STATE')
	eq(b:GetChecked(), true, 'nothing unchecked the game button')
	eq(st:GetState(b, 'selected'), false, 'selected follows the game state')
end)

test('the sync leaves the pet, stance and leave vehicle buttons alone', function()
	fresh('forever')
	local active = true
	GetPetActionInfo = function() return 'x', 'Interface\\Icons\\x', false, active, false, false end
	GetShapeshiftFormInfo = function() return 'Interface\\Icons\\x', active, true end
	GetNumShapeshiftForms = function() return 3 end
	IsPetAttackAction = function() return false end
	GetPetActionSlotUsable = function() return true end
	GetPetActionCooldown = function() return 0, 0, 0 end
	GetShapeshiftFormCooldown = function() return 0, 0, 0 end
	local own = {}
	for _, id in ipairs({ 'pet', 'stance' }) do
		local header = CreateFrame('Frame', 'CCOwn' .. id, UIParent)
		header.id, header.buttons = id, {}
		function header:WrapScript() end
		local real = CreateFrame
		function CreateFrame(kind, name, parent, template, frameId)
			local frame = real(kind, name, parent, template and template:find('Secure') and 'SecureActionButtonTemplate' or template, frameId)
			if template and template:find('ActionButtonTemplate') then
				frame.icon = frame:CreateTexture(nil, 'BACKGROUND')
				frame.IconMask = frame:CreateMaskTexture()
				frame.Flash = frame:CreateTexture(nil, 'ARTWORK')
				frame.cooldown = real('Cooldown', nil, frame)
				for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do frame[key] = frame:CreateFontString(nil, 'OVERLAY') end
				frame.AutoCastOverlay = real('Frame', nil, frame)
				function frame.AutoCastOverlay:ShowAutoCastEnabled() end
			end
			return frame
		end
		GetCVarBool = GetCVarBool or function(name) return stub.cvars[name] == '1' end
		local ok, err = pcall(AB.barTypes[id].CreateButtons, header)
		CreateFrame = real
		check(ok, id .. ': the bar made: ' .. tostring(err))
		if ok then
			for _, b in ipairs(header.buttons) do AB:StyleButton(b, AB:GetBarConfig(id), 'thick', 'solid') end
			header.buttons[1]:Refresh()
			own[id] = header.buttons[1]
		end
	end
	for id, b in pairs(own) do eq(st:GetState(b, 'selected'), true, id .. ': selected by its own update') end
	for _, event in ipairs({ 'ACTIONBAR_UPDATE_STATE', 'PLAYER_ENTER_COMBAT', 'PLAYER_LEAVE_COMBAT', 'STOP_AUTOREPEAT_SPELL', 'START_AUTOREPEAT_SPELL' }) do
		stub.fire_event(event)
		for id, b in pairs(own) do eq(st:GetState(b, 'selected'), true, id .. ': still selected after ' .. event) end
	end
	-- the leave vehicle button, skinned with no LibActionButton methods
	local leave = CreateFrame('CheckButton', 'CCLeave', UIParent, 'SecureActionButtonTemplate')
	leave:SetSize(40, 40)
	leave.icon = leave:CreateTexture(nil, 'BACKGROUND')
	leave.Flash = leave:CreateTexture(nil, 'ARTWORK')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		leave[key] = leave:CreateFontString(nil, 'OVERLAY')
		leave[key]:SetFontObject(GameFontNormal)
	end
	leave.cooldown = CreateFrame('Cooldown', nil, leave)
	AB:SkinButton(leave)
	leave:SetChecked(true)
	stub.fire_event('ACTIONBAR_UPDATE_STATE')
	eq(st:GetState(leave, 'selected'), true, 'leave vehicle: still selected')
	eq(#take_errors(), 0, 'no errors')
end)
