-- An action button as LibActionButton makes one (SecureActionButtonTemplate),
-- under Blizzard, holding an equipped item: in combat its equipped border goes
-- off and on (a bar page change, a weapon swap) and a recolor repaints it. The
-- own-color piece is a texture of the secure button, so nothing may be moved,
-- sized or anchored (ThemeArt.SetBorder's cached path colors and shows only):
-- the stubs refuse those calls on a protected button's region in combat.
local T = load_test_file('lib/theme_helpers.lua')
local st, AB

local function fresh()
	reset_world()
	load_core_helpers()
	st = SaftUI
	load_test_file('actionbars/fixtures/libactionbutton.lua')
	load_saftui('SaftUI-ActionBars/config.lua')
	apply_defaults()
	load_saftui('SaftUI-ActionBars/init.lua')
	load_saftui('SaftUI-ActionBars/shared.lua')
	load_saftui('SaftUI-ActionBars/skin.lua')
	AB = st:GetModule('ActionBars')
	st:BindModuleConfig(AB, 'actionbars')
end

local function button(name, equipped)
	local b = CreateFrame('CheckButton', name, UIParent, 'SecureActionButtonTemplate')
	b:SetSize(40, 40)
	b:SetPoint('CENTER')
	b.icon = b:CreateTexture(nil, 'BACKGROUND')
	b.Flash = b:CreateTexture(nil, 'ARTWORK')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		b[key] = b:CreateFontString(nil, 'OVERLAY')
		b[key]:SetFontObject(GameFontNormal)
	end
	b.cooldown = CreateFrame('Frame', nil, b)
	local countdown = b.cooldown:CreateFontString(nil, 'OVERLAY')
	function b.cooldown:GetCountdownFontString() return countdown end
	b.equipped = equipped
	function b:UpdateConfig(config) self.labConfig = config end
	function b:IsEquipped() return self.equipped end
	AB:SkinButton(b)
	return b
end

test('an equipped border going off and on in combat under Blizzard moves no region of the secure button', function()
	fresh()
	st.config.profile.theme.name = 'blizzard'
	local b = button('ReviewSecureAction', true)
	AB.bars.bar1 = { buttons = { b } }
	AB:StyleBar('bar1')
	local art = st.ThemeArt.Get(b.backdrop)
	check(art and art.own ~= nil, 'the own-color piece was made out of combat')
	eq(art.own:GetParent(), b, 'it is a texture of the secure button')
	stub.blocked = {}
	stub.in_combat = true
	b.equipped = false
	AB:UpdateEquippedBorder(b)
	b.equipped = true
	AB:UpdateEquippedBorder(b)
	-- A theme recolor in combat (st:RecolorThemed -> OnColorsChanged('theme')).
	AB:OnColorsChanged('theme')
	stub.in_combat = false
	local names = {}
	for _, call in ipairs(stub.blocked) do names[#names + 1] = call[2] end
	eq(#stub.blocked, 0, 'nothing refused (blocked: ' .. table.concat(names, ',') .. ')')
	take_errors()
end)
