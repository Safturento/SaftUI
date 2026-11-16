-- The action bars' interaction states (SaftUI-ActionBars/skin.lua, Core's
-- Widgets/states.lua): every action, pet and stance button is an 'icon' of the
-- state helper with game = true, so its own highlight, pushed and checked
-- textures are SaftUI's flat ones, colored from the Accent (the derived hover,
-- pushed and the checked Fill), BLEND, over the icon; a checked button and an
-- equipped item wear the Accent edge on the backdrop. Under Blizzard the state
-- art is Blizzard's. A pass only colors.
--
-- The world is live_colors_test.lua's: the action bars' files, buttons as
-- LibActionButton makes them, skinned by AB:SkinButton and styled by
-- AB:StyleButton. Both clients.
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')
local S = load_test_file('lib/secrets.lua')

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

local st, AB, LAB

local function fresh(client)
	if client then
		T.client(client)
	else
		reset_world()
		load_core_helpers()
	end
	st = SaftUI
	LAB = load_test_file('actionbars/fixtures/libactionbutton.lua')
	load_saftui('SaftUI-ActionBars/config.lua')
	apply_defaults()
	for _, file in ipairs(FILES) do load_saftui(file) end
	AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
	stub.cvars.countdownForCooldowns = '1'
	function LAB:GetSpellFlyoutFrame() end
	AB:ConvertProfile()
end

local function button(name)
	local b = CreateFrame('CheckButton', name, UIParent)
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
	function b:IsEquipped() return self.equipped end
	AB:SkinButton(b)
	return b
end

local function styled(name, theme)
	local b = button(name)
	AB:StyleButton(b, AB:GetBarConfig('bar1'), theme or 'thick', 'solid')
	return b
end

local function edge(b) return SL.bytes({ r = select(1, b.backdrop:GetBackdropBorderColor()), g = select(2, b.backdrop:GetBackdropBorderColor()), b = select(3, b.backdrop:GetBackdropBorderColor()) }) end
local function accent_hex() local r, g, b = st:StateColor('edge'); return SL.bytes({ r = r, g = g, b = b }) end
local function rest_hex(b)
	st:SetBorderColor(b.backdrop)
	return edge(b)
end

test('an action button at rest is drawn as before; an equipped one has the accent edge', function()
	fresh()
	local b = styled('ISRest1')
	local plain = edge(b)
	check(plain ~= accent_hex(), 'the theme border at rest')
	eq(st:GetState(b, 'selected'), false)
	b.equipped = true
	AB:UpdateEquippedBorder(b)
	eq(edge(b), accent_hex(), 'an equipped item: the Accent edge')
	b.equipped = false
	AB:UpdateEquippedBorder(b)
	eq(edge(b), plain, 'unequipped: the theme border again')
	local look = st:StateLook(b)
	eq(look.shape, 'icon')
	eq(look.hover_piece.shown ~= nil, true)
end)

test('hover: the highlight BLEND T+ at 0.16 over the icon; pushed: T- at 0.32; checked: the fade at 0.24', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		fresh(client)
		local b = styled('ISState' .. client)
		local look = st:StateLook(b)
		local where = client .. ': '
		eq(b:GetHighlightTexture(), look.pieces.hover, where .. 'the highlight is the helper\'s hover piece (adopted, none made twice)')
		eq(b:GetPushedTexture(), look.pieces.pushed)
		eq(b:GetCheckedTexture(), look.pieces.checked)
		local h = { st:StateColor('hover') }
		eq(SL.rgb(look.hover_piece), SL.rgb({ r = h[1], g = h[2], b = h[3] }), where .. 'hover is T+')
		eq(look.hover_piece.a, 0.16, where .. 'at 0.16')
		eq(look.hover_piece.blend, 'BLEND', where .. 'BLEND, not ADD')
		eq(look.hover_piece.texture, st.BLANK_TEX)
		eq(look.hover_piece.layer, 'HIGHLIGHT', where .. 'shown only under the mouse')
		check(SL.near(look.hover_piece, '5bc6ff'), where .. 'T+ at the default Accent: ' .. SL.bytes(look.hover_piece))
		eq(look.pushed_piece.a, 0.32, where .. 'pushed at 0.32')
		check(SL.near(look.pushed_piece, '0093cc'), where .. 'T-: ' .. SL.bytes(look.pushed_piece))
		eq(look.pushed_piece.blend, 'BLEND')
		eq(look.checked_piece.texture, st.textures.stateFade, where .. 'the Fill')
		eq(look.checked_piece.a, 0.24, where .. 'at 0.24')
		eq(look.checked_piece.blend, 'BLEND')
		check(math.abs(look.checked_piece.right - 1 / 0.7) < 0.01, where .. 'the fade coordinates')
		for name, piece in pairs({ hover = b:GetHighlightTexture(), pushed = b:GetPushedTexture(), checked = b:GetCheckedTexture() }) do
			eq(T.around(piece, b.icon), '0,0,0,0', where .. name .. ' covers the icon')
		end
		eq(select(1, b:GetPushedTexture():GetDrawLayer()), 'OVERLAY')
		-- the accent decides: a new one reaches the pieces
		st.config.profile.theme.accent:SetRGB(0.9, 0.2, 0.1)
		st:ColorChanged('accent')
		look = st:StateLook(b)
		check(look.hover_piece.r > 0.9 and look.hover_piece.g < 0.6, where .. 'a new Accent reaches the hover: ' .. SL.rgb(look.hover_piece))
		st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
	end
end)

test("a checked button's edge from the post-hook; unchecked: the equipped accent or the theme's; a secret counts as unchecked", function()
	fresh()
	local b = styled('ISChecked1')
	local plain = edge(b)
	b:SetChecked(true)
	eq(st:GetState(b, 'selected'), true, 'selected while checked')
	eq(edge(b), accent_hex(), 'a checked button has the Accent edge')
	b:SetChecked(false)
	eq(st:GetState(b, 'selected'), false)
	eq(edge(b), plain, 'unchecked: the theme border')
	-- checked and equipped; unchecked, the equipped one keeps its accent
	b.equipped = true
	AB:UpdateEquippedBorder(b)
	b:SetChecked(true)
	b:SetChecked(false)
	eq(edge(b), accent_hex(), 'unchecked and equipped: still the Accent')
	b.equipped = false
	AB:UpdateEquippedBorder(b)
	eq(edge(b), plain, 'neither')
	-- a secret value counts as unchecked
	local restore = S.install()
	b:SetChecked(true)
	b:SetChecked(S.secret('active'))
	eq(st:GetState(b, 'selected'), false, 'a secret is unchecked')
	eq(edge(b), plain)
	restore()
	-- a checked button's edge survives a theme recolor
	b:SetChecked(true)
	st:RecolorThemed()
	st:ColorsChanged('theme')
	eq(edge(b), accent_hex(), 'through a recolor')
	-- and a changed Accent reaches it in a pass
	st.config.profile.theme.accent:SetRGB(0.3, 0.9, 0.6)
	st:ColorChanged('accent')
	eq(edge(b), accent_hex(), 'through an Accent pass')
	check(edge(b) ~= plain)
	st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
	eq(#take_errors(), 0, 'no errors')
end)

test('pet and stance buttons the same: they are skinned by the same call and call SetChecked', function()
	fresh()
	-- the pet and stance buttons' own Refresh and update call SetChecked on the skinned button
	local pet = styled('ISPet1')
	local stance = styled('ISStance1')
	for _, b in ipairs({ pet, stance }) do
		eq(st:StateLook(b).shape, 'icon')
		b:SetChecked(true)
		eq(edge(b), accent_hex())
		eq(st:StateLook(b).checked_piece.a, 0.24)
		b:SetChecked(false)
		check(edge(b) ~= accent_hex())
	end
end)

test('under Blizzard: the state art, untinted; no SaftUI piece shows (T.round_trip)', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		fresh(client)
		st.config.profile.theme.name = 'thick'
		local b, hover, pushed, checked
		-- a round trip as st:ThemeChanged runs it, with the bars' restyle
		local function trip(label, expect)
			expect(label .. ', Thick')
			for _, name in ipairs({ 'blizzard', 'thick' }) do
				T.theme(name)
				expect(label .. (name == 'blizzard' and ', Blizzard' or ', Thick again'))
			end
		end
		trip(client, function(label)
			b = b or styled('ISBlizz' .. client, 'theme')
			AB:StyleButton(b, AB:GetBarConfig('bar1'), 'theme', 'solid')
			hover, pushed, checked = b:GetHighlightTexture(), b:GetPushedTexture(), b:GetCheckedTexture()
			local look = st:StateLook(b)
			if label:find('Blizzard') then
				eq(look.blizzard, true, label)
				eq(hover:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', label .. ': hover is Blizzard\'s')
				eq(pushed:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Down', label)
				for name, region in pairs({ hover = hover, pushed = pushed, checked = checked }) do
					eq(T.text(region:GetVertexColor()), '1.00,1.00,1.00,1.00', label .. ': ' .. name .. ' untinted')
					eq(region:GetAlpha(), 1, label .. ': ' .. name .. ' not faded')
				end
				-- a pass leaves them alone
				st:ColorChanged('accent')
				eq(T.text(hover:GetVertexColor()), '1.00,1.00,1.00,1.00', label .. ': a pass leaves the art')
				b:SetChecked(true)
				check(edge(b) ~= accent_hex(), label .. ': a checked button has no SaftUI edge, Blizzard draws it')
				b:SetChecked(false)
			else
				eq(look.blizzard, false, label)
				eq(hover:GetAtlas(), nil, label .. ': flat')
				eq(hover:GetBlendMode(), 'BLEND', label)
				eq(look.hover_piece.a, 0.16, label)
			end
		end)
	end
end)

test('in combat a pass only colors; SetChecked and the Accent too (Review Focus 2)', function()
	fresh()
	local buttons = {}
	for i = 1, 6 do buttons[i] = styled('ISCombat' .. i) end
	buttons[1].equipped = true
	AB:UpdateEquippedBorder(buttons[1])
	buttons[2]:SetChecked(true)
	stub.in_combat = true
	st.config.profile.theme.accent:SetRGB(0.8, 0.4, 0.1)
	local m = C.measure(function() st:ColorChanged('accent') end, 1)
	eq(m.forbidden.total, 0, 'nothing forbidden on any button')
	eq(m.made, 0, 'nothing made')
	for name in pairs(m.calls.by) do
		check(name == 'SetVertexColor' or name == 'SetTexCoord' or name == 'SetAlpha' or name == 'SetBackdropBorderColor',
			'only a color setter: ' .. name)
	end
	local c = C.measure(function() buttons[3]:SetChecked(true); buttons[3]:SetChecked(false) end)
	eq(c.forbidden.total, 0, 'SetChecked in combat: nothing forbidden')
	eq(c.made, 0)
	stub.in_combat = false
	eq(#stub.blocked, 0, 'nothing blocked')
end)

test('a pass over 164 buttons: under 700 calls, nothing made, under 4 KB', function()
	fresh()
	local buttons = {}
	for i = 1, 164 do buttons[i] = styled('ISCrowd' .. i) end
	st.config.profile.theme.accent:SetRGB(0.3, 0.9, 0.6)
	local m = C.measure(function() st:ColorChanged('accent') end)
	check(m.calls.total < 700, 'calls in one pass: ' .. m.calls.total)
	eq(m.forbidden.total, 0)
	eq(m.made, 0)
	local k = C.measure(function() st:ColorChanged('accent') end, 100)
	check(k.kb < 4, 'garbage over 100 passes: ' .. k.kb .. ' KB')
	eq(m.calls.by.SetVertexColor, 164 * 3, 'three pieces a button')
	C.print('action bars, accent over 164 buttons', m)
	-- the call count is pinned: 4 a button at rest (3 colors and the Fill's coordinates), none else
	eq(m.calls.total, 164 * 4, 'pinned')
end)

-- The pet and stance buttons through their own update (PetButton:Refresh, StanceButton:Refresh),
-- made by their bars' own CreateButtons: the stubs have no ActionButtonTemplate, so a secure
-- button's regions are made by hand as the Cooldown numbers test does.
local function own_bar(id)
	local header = CreateFrame('Frame', 'ISOwn' .. id, UIParent)
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
	check(ok, tostring(err))
	for _, b in ipairs(header.buttons) do AB:StyleButton(b, AB:GetBarConfig(id), 'thick', 'solid') end
	return header
end

test("L2: pet and stance buttons through their own update: checked is the helper's selected, a secret counts as unchecked", function()
	fresh()
	local restore = S.install()
	local active, secret = false, false
	GetPetActionInfo = function() return 'x', 'Interface\\Icons\\x', false, secret and S.secret('isActive') or active, false, false end
	GetShapeshiftFormInfo = function() return 'Interface\\Icons\\x', secret and S.secret('isActive') or active, true end
	GetNumShapeshiftForms = function() return 3 end
	IsPetAttackAction = function() return false end
	GetPetActionSlotUsable = function() return true end
	GetPetActionCooldown = function() return 0, 0, 0 end
	GetShapeshiftFormCooldown = function() return 0, 0, 0 end
	for _, id in ipairs({ 'pet', 'stance' }) do
		local ok, header = pcall(own_bar, id)
		check(ok, id .. ': the bar made: ' .. tostring(header))
		if ok then
			local b = header.buttons[1]
			local plain = edge(b)
			active, secret = true, false
			b:Refresh()
			eq(st:GetState(b, 'selected'), true, id .. ': an active one is selected')
			eq(edge(b), accent_hex(), id .. ': with the Accent edge')
			eq(st:StateLook(b).checked_piece.a, 0.24, id .. ': and the fade')
			active, secret = false, true
			b:Refresh()
			eq(st:GetState(b, 'selected'), false, id .. ': a secret is unchecked')
			eq(edge(b), plain, id .. ': the theme border')
			active, secret = false, false
			b:Refresh()
			eq(st:GetState(b, 'selected'), false, id .. ': an inactive one is not')
		end
	end
	restore()
end)

test('L3: a checked, unequipped button under Blizzard is given no SaftUI edge color, also after an equipped item leaves it', function()
	fresh()
	st.config.profile.theme.name = 'thick'
	local b = styled('ISBlizzEdge', 'theme')
	T.theme('blizzard')
	AB:StyleButton(b, AB:GetBarConfig('bar1'), 'theme', 'solid')
	eq(st:StateLook(b).blizzard, true, 'the Blizzard look')
	-- what PaintEdge hands the backdrop: a color, or none (the theme's own)
	local given = {}
	local real = st.SetBorderColor
	st.SetBorderColor = function(self, frame, r, ...) if frame == b.backdrop then given[#given + 1] = r and 'color' or 'none' end return real(self, frame, r, ...) end
	b:SetChecked(true)
	AB:PaintEdge(b)
	eq(given[#given], 'none', 'checked under Blizzard: no color, Blizzard draws it')
	-- an equipped item that is checked, then leaves: the path where PaintEdge is asked with no color
	b.equipped = true
	AB:UpdateEquippedBorder(b)
	eq(given[#given], 'color', 'an equipped item is colored')
	b.equipped = false
	AB:UpdateEquippedBorder(b)
	eq(given[#given], 'none', 'unequipped and still checked: no color again')
	st.SetBorderColor = real
end)

test('L3: an Accent pass paints an equipped and checked button once, not twice', function()
	fresh()
	local b = styled('ISBoth')
	b.equipped = true
	AB:UpdateEquippedBorder(b)
	b:SetChecked(true)
	local painted = 0
	local real = AB.PaintEdge
	AB.PaintEdge = function(...) painted = painted + 1; return real(...) end
	st.config.profile.theme.accent:SetRGB(0.3, 0.9, 0.6)
	st:ColorChanged('accent')
	AB.PaintEdge = real
	eq(painted, 1, 'once in a pass (the helper paints a selected edge; the module only an equipped, unselected one)')
	eq(edge(b), accent_hex())
	st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
end)
