-- The totem bar's interaction states (SaftUI-Misc/totemskin.lua, Core's
-- Widgets/states.lua): a skinned totem button is an 'icon' with game = true over
-- Blizzard's secure button's own highlight, pushed and checked textures (SaftUI's
-- flat ones): the derived hover T+ at 0.16 (it was the full Accent, additive),
-- pushed T-, checked the Fill, all BLEND. No edge on a checked totem button and no
-- hook on Blizzard's secure buttons. The attack flash is unchanged. Under
-- Blizzard the state art is Blizzard's. A pass only colors, in combat too.
--
-- The world is totem_state_colors_test.lua's live one (totembar, totemlayout,
-- totemposition, totemoptions, totemskin and totemtimers over Blizzard's buttons
-- as locked widgets: a field written onto one fails).
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')
local locked = load_test_file('lib/locked_widget.lua')

local function live_world()
	local st = T.client('forever')
	load_editmode()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	for _, file in ipairs({ 'totembar', 'totemlayout', 'totemposition', 'totemoptions', 'totemskin', 'totemtimers' }) do
		load_saftui('SaftUI-Misc/' .. file .. '.lua')
	end
	GetTotemDuration = function() end
	FIRE_TOTEM_SLOT, EARTH_TOTEM_SLOT, WATER_TOTEM_SLOT, AIR_TOTEM_SLOT = 1, 2, 3, 4
	for i = 1, 4 do
		local button = CreateFrame('Button', 'MultiCastSlotButton' .. i, UIParent)
		button:SetID(i)
		button:SetSize(30, 30)
		button:SetPoint('CENTER')
		button.background = button:CreateTexture(nil, 'BACKGROUND')
		button.overlayTex = button:CreateTexture(nil, 'OVERLAY')
		locked(button, 'Blizzard totem slot')
	end
	local function totem_button(name, container)
		local button = CreateFrame('CheckButton', name, UIParent)
		button:SetSize(30, 30)
		button:SetPoint('CENTER')
		button.icon = button:CreateTexture(nil, 'BACKGROUND')
		button.Flash = button:CreateTexture(nil, 'ARTWORK', nil, 1)
		local parent = button
		if container then
			button.TextOverlayContainer = CreateFrame('Frame', nil, button)
			parent = button.TextOverlayContainer
		end
		button.Count = parent:CreateFontString(nil, 'ARTWORK')
		button.HotKey = parent:CreateFontString(nil, 'OVERLAY')
		button.Name = button:CreateFontString(nil, 'OVERLAY')
		return locked(button, 'Blizzard totem button')
	end
	local buttons = { totem_button('MultiCastSummonSpellButton') }
	for i = 1, 12 do buttons[#buttons + 1] = totem_button('MultiCastActionButton' .. i, true) end
	local flyout = CreateFrame('Frame', 'MultiCastFlyoutFrame', UIParent)
	flyout.top = flyout:CreateTexture(nil, 'ARTWORK')
	flyout.middle = flyout:CreateTexture(nil, 'ARTWORK')
	locked(flyout, 'Blizzard totem flyout')
	for _, name in ipairs({ 'MultiCastFlyoutFrameOpenButton', 'MultiCastFlyoutFrameCloseButton' }) do
		local arrow = CreateFrame('Button', name, flyout)
		arrow:SetSize(30, 16)
		arrow:SetNormalTexture(arrow:CreateTexture(nil, 'ARTWORK'))
		arrow:SetHighlightTexture(arrow:CreateTexture(nil, 'HIGHLIGHT'))
		locked(arrow, 'Blizzard totem arrow')
	end
	local TB = st:GetModule('TotemBar')
	st:BindModuleConfig(TB, 'totembar')
	TB:SetupSkin()
	TB:SetupTimers()
	return st, TB, buttons
end

test('totem buttons: hover, pushed, the checked fill; no edge; the flash unchanged; nothing hooked', function()
	local st, TB, buttons = live_world()
	local b = buttons[2]
	local look = st:StateLook(b)
	eq(look.shape, 'icon')
	eq(b:GetHighlightTexture(), look.pieces.hover, 'the highlight is the hover piece')
	eq(b:GetPushedTexture(), look.pieces.pushed)
	eq(b:GetCheckedTexture(), look.pieces.checked)
	eq(SL.rgb(look.hover_piece), SL.rgb({ r = st:StateColor('hover'), g = select(2, st:StateColor('hover')), b = select(3, st:StateColor('hover')) }), 'hover is T+')
	check(SL.near(look.hover_piece, '5bc6ff'), 'T+ at the default Accent: ' .. SL.bytes(look.hover_piece))
	eq(look.hover_piece.a, 0.16, 'at 0.16, not the full Accent')
	eq(look.hover_piece.blend, 'BLEND', 'BLEND, not ADD')
	check(SL.near(look.pushed_piece, '0093cc'), 'pushed is T-: ' .. SL.bytes(look.pushed_piece))
	eq(look.pushed_piece.a, 0.32); eq(look.pushed_piece.blend, 'BLEND')
	eq(look.checked_piece.texture, st.textures.stateFade, 'checked is the Fill')
	eq(look.checked_piece.a, 0.24); eq(look.checked_piece.blend, 'BLEND')
	for name, piece in pairs({ hover = b:GetHighlightTexture(), pushed = b:GetPushedTexture(), checked = b:GetCheckedTexture() }) do
		eq(T.around(piece, b.icon), '0,0,0,0', name .. ' covers the icon')
	end
	-- the flash is as before: Buttons > Danger at 0.4
	local f = stub.state(b.Flash).color_texture
	eq(T.rgb(f[1], f[2], f[3]) .. ' ' .. string.format('%.2f', f[4]), T.rgb(st:Color('button', 'danger'):GetRGB()) .. ' 0.40', 'the flash')
	-- no edge on check, no hook on a secure button's SetChecked
	check(look.edge == nil, 'no edge')
	check(not stub.hook_wrappers[rawget(b, 'SetChecked') or false], 'SetChecked is not hooked')
	check(rawget(b, 'SetChecked') == nil, 'no field written onto the button')
	b:SetChecked(true)
	eq(st:GetState(b, 'selected'), false, 'a checked totem button is not selected: no edge')
	-- the flyout choices have no checked piece
	eq(#take_errors(), 0)
end)

test('totem buttons under Blizzard: the state art, untinted; the Accent reaches nothing', function()
	local st, TB, buttons = live_world()
	st.config.profile.theme.name = 'blizzard'
	st:RedrawThemed()
	TB:ApplySkin()
	local b = buttons[2]
	local hover = b:GetHighlightTexture()
	eq(st:StateLook(b).blizzard, true)
	eq(hover:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', "hover is Blizzard's")
	eq(T.text(hover:GetVertexColor()), '1.00,1.00,1.00,1.00', 'untinted')
	local m = C.measure(function() st:ColorChanged('accent') end)
	eq(m.calls.total, 0, 'a pass colors nothing')
	-- and back
	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	TB:ApplySkin()
	eq(hover:GetAtlas(), nil)
	eq(hover:GetBlendMode(), 'BLEND')
	eq(hover:GetTexture(), st.BLANK_TEX)
	eq(T.text(hover:GetVertexColor()), T.text(st:StateColor('hover')))
	eq(#take_errors(), 0)
end)

test('a pass over the totem bar: 4 calls a button (3 colors and the Fill\'s coordinates), nothing made or forbidden, in combat too', function()
	local st, TB, buttons = live_world()
	st.config.profile.theme.accent:SetRGB(0.3, 0.9, 0.6)
	local m = C.measure(function() st:ColorChanged('accent') end)
	eq(m.forbidden.total, 0); eq(m.made, 0)
	eq(m.calls.total, #buttons * 4, 'pinned: 13 buttons, 4 calls each')
	local hover = stub.state(buttons[2]:GetHighlightTexture()).vertex_color
	eq(T.rgb(hover[1], hover[2], hover[3]), T.rgb(st:StateColor('hover')), 'a new Accent reaches the hover')
	stub.in_combat = true
	local k = C.measure(function() st:ColorChanged('accent') end, 100)
	eq(k.forbidden.total, 0, 'in combat')
	for name in pairs(k.calls.by) do
		check(name == 'SetVertexColor' or name == 'SetTexCoord', 'only a color or a coordinate: ' .. name)
	end
	check(k.kb < 4, 'garbage over 100 passes: ' .. k.kb .. ' KB')
	C.print('totem bar, accent', m)
	stub.in_combat = false
	eq(#stub.blocked, 0)
end)
