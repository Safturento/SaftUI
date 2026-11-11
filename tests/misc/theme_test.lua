-- SaftUI-Misc with SaftUI's themes (SaftUI-Core/theme.lua):
--   - the tooltip's, the skins' and the experience bars' defaults look as their
--     old template names did;
--   - the Experience, Tooltip and Skinning pages offer Theme and Background, not
--     Template;
--   - the buff skin draws each icon's backdrop as an aura, in the Skinning theme,
--     kept in its own table, and a debuff's type border and a weapon enchant's
--     border survive a theme recolor and switch;
--   - the swing timer skin draws its bars as bars, follows a theme switch and the
--     Skinning page at once, and writes nothing onto Blizzard's bars;
--   - the totem bar's element borders survive a theme recolor.
--
-- Real: SaftUI-Misc's config.lua, tooltip.lua, tooltipposition.lua,
-- experience.lua, totembar.lua, totemskin.lua and Skinning/skinning.lua,
-- Blizzard_BuffFrame.lua and Blizzard_SwingTimer.lua, Core's helpers and the
-- theme engine. Blizzard's frames are built as far as the skins read them, and
-- locked (fixtures/locked_widget.lua), so a skin that writes a field onto one fails.
load_core_helpers()
load_test_file('core/options_walk.lua')
local T = load_test_file('lib/theme_helpers.lua')
local drawn = T.watch()
local locked = load_test_file('misc/fixtures/locked_widget.lua')
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
load_saftui('SaftUI-Misc/tooltip.lua')
load_saftui('SaftUI-Misc/tooltipposition.lua')
load_saftui('SaftUI-Misc/experience.lua')
load_saftui('SaftUI-Misc/totembar.lua')
load_saftui('SaftUI-Misc/totemskin.lua')
load_saftui('SaftUI-Misc/Skinning/skinning.lua')
load_saftui('SaftUI-Misc/Skinning/Blizzard_BuffFrame.lua')
load_saftui('SaftUI-Misc/Skinning/Blizzard_SwingTimer.lua')

local st = SaftUI
local profile = st.config.profile
local SK = st:GetModule('Skinning')
st:BindModuleConfig(SK, 'skinning')

-- The old template names these defaults replaced (base commit 7ec1df8).
local OLD = { tooltip = 'thicktransparent', skinning = 'thicktransparent', experience = 'thicktransparent' }

test('misc defaults look as they did', function()
	for key, old in pairs(OLD) do
		T.check_default(profile[key], old, key)
	end
end)

test('each page offers Theme and Background, not Template', function()
	-- Experience: before the bars exist, a change has nothing to apply.
	local XP = st:GetModule('Experience')
	st:BindModuleConfig(XP, 'experience')
	T.check_no_old_names(XP:GetConfigTable(), 'Experience')
	local general = XP:GetConfigTable().args.general
	T.check_options(general, 'Experience')
	eq(general.get({ 'theme' }), 'theme', 'Experience: Theme reads experience.theme')
	general.set({ 'background' }, 'solid')
	eq(profile.experience.background, 'solid', 'Experience: Background writes experience.background')
	profile.experience.background = 'theme'

	-- Tooltip: its holder is SaftUI's, made on enable. Its update reaches
	-- Blizzard's tooltips, so it's counted.
	local TT = st:GetModule('Tooltip')
	st:BindModuleConfig(TT, 'tooltip')
	TT.tooltipHolder = CreateFrame('Frame', nil, UIParent)
	local reskins = 0
	local update = TT.UpdateConfig
	function TT:UpdateConfig() reskins = reskins + 1 end
	general = TT:GetConfigTable().args.general
	T.check_options(general, 'Tooltip')
	eq(general.get({ 'theme' }), 'theme', 'Tooltip: Theme reads tooltip.theme')
	general.set({ 'theme' }, 'thin')
	general.set({ 'background' }, 'solid')
	eq(profile.tooltip.theme .. ',' .. profile.tooltip.background, 'thin,solid', 'Tooltip: both write the profile')
	eq(reskins, 2, 'Tooltip: each re-skins the tooltips')
	TT.UpdateConfig = update
	profile.tooltip.theme, profile.tooltip.background = 'theme', 'theme'

	-- Skinning: each change re-applies the skins.
	general = SK:GetConfigTable().args.general
	T.check_options(general, 'Skinning')
	eq(general.get({ 'theme' }), 'theme', 'Skinning: Theme reads skinning.theme')
	general.set({ 'theme' }, 'thin')
	eq(profile.skinning.theme, 'thin', 'Skinning: Theme writes skinning.theme')
	general.set({ 'theme' }, 'theme')
end)

------------------------------------ the buff skin

-- Blizzard's color for a weapon enchant's border in the skin (TEMP_ENCHANT_COLOR).
local ENCHANT = '0.60,0.20,0.90,1.00'
local MAGIC = { 0.2, 0.6, 1 }

-- Blizzard's AuraUtil.GetDebuffDisplayInfoTable (Blizzard_FrameXMLUtil/AuraUtil.lua):
-- each dispel type's border atlases and color. Only the two used here.
AuraUtil = { GetDebuffDisplayInfoTable = function()
	return {
		Magic = { color = CreateColor(unpack(MAGIC)), basicAtlas = 'ui-debuff-border-magic-noicon', dispelAtlas = 'ui-debuff-border-magic-icon' },
		None = { color = CreateColor(0.8, 0, 0), basicAtlas = 'ui-debuff-border-default-noicon' },
	}
end }

-- One of Blizzard's aura buttons (AuraButtonTemplate) as far as the skin reads it:
-- its Icon, Duration (anchored under the icon, as Blizzard's layout does) and
-- Count, and a debuff's DebuffBorder or a weapon enchant's TempEnchantBorder.
local function aura_button(parent, kind)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(30, 40)
	button:SetPoint('CENTER')
	button.Icon = button:CreateTexture(nil, 'ARTWORK')
	button.Icon:SetSize(30, 30)
	button.Icon:SetPoint('TOP')
	button.Duration = button:CreateFontString(nil, 'OVERLAY')
	button.Duration:SetFontObject(GameFontNormal)
	button.Duration:SetPoint('TOP', button.Icon, 'BOTTOM')
	button.Count = button:CreateFontString(nil, 'OVERLAY')
	button.Count:SetFontObject(GameFontNormal)
	if kind == 'debuff' then
		button.DebuffBorder = button:CreateTexture(nil, 'OVERLAY')
		button.DebuffBorder:Hide()
	elseif kind == 'enchant' then
		button.TempEnchantBorder = button:CreateTexture(nil, 'OVERLAY')
		button.TempEnchantBorder:Hide()
	end
	locked(button, 'Blizzard aura button')
	locked(button.Icon, 'Blizzard aura icon')
	return button
end

BuffFrame = CreateFrame('Frame', 'BuffFrame', UIParent)
DebuffFrame = CreateFrame('Frame', 'DebuffFrame', UIParent)
local buff, enchant = aura_button(BuffFrame), aura_button(BuffFrame, 'enchant')
local debuff = aura_button(DebuffFrame, 'debuff')
BuffFrame.auraFrames = { buff, enchant }
DebuffFrame.auraFrames = { debuff }
local BF = SK:GetModule('Blizzard_BuffFrame')

-- The SaftUI backdrop behind a button's icon: the button's child with a backdrop.
local function icon_backdrop(button)
	for _, child in ipairs({ button:GetChildren() }) do
		if child.backdropInfo or child.SetBackdrop then return child end
	end
end

-- Where the duration text sits under the icon: its y offset from the icon's bottom.
local function duration_y(button)
	local _, relativeTo, _, _, y = button.Duration:GetPoint(1)
	return relativeTo == button.Icon and y or nil
end

test("the buff skin draws each icon's backdrop as an aura, in the Skinning theme, and writes nothing onto Blizzard's buttons", function()
	BF:SkinFrames()
	for _, button in ipairs({ buff, enchant, debuff }) do
		eq(drawn(button.Icon), 'theme,theme,aura', "the Skinning Theme and Background, as an aura")
		local backdrop = icon_backdrop(button)
		check(backdrop ~= nil, 'a backdrop of its own')
		eq(T.inset(backdrop), 2, "Thick's border")
		eq(T.offset(backdrop, 'TOPLEFT'), '-2.00,2.00', "2px outside the icon")
		eq(backdrop:GetFrameLevel(), button:GetFrameLevel() - 1, 'one level under the button')
	end
	eq(duration_y(buff), -3, "the duration clears Thick's border")
	eq(T.edge(icon_backdrop(buff)), T.text(unpack(profile.templates.thick.bordercolor)), "a buff has the theme's border")
end)

test("a debuff's type border survives a recolor", function()
	local backdrop = icon_backdrop(debuff)
	debuff.DebuffBorder:SetAtlas('ui-debuff-border-magic-noicon')
	debuff.DebuffBorder:Show()
	enchant.TempEnchantBorder:Show()
	local magic = T.text(MAGIC[1], MAGIC[2], MAGIC[3], 1)
	eq(T.edge(backdrop), magic, "the debuff's border is its type's color")
	eq(T.edge(icon_backdrop(enchant)), ENCHANT, "the enchant's border is purple")

	local saved = profile.templates.thick.bordercolor
	for _ = 1, 3 do
		profile.templates.thick.bordercolor = { 0.7, 0.1, 0.1, 1 }
		st:RecolorThemed()
	end
	eq(T.edge(backdrop), magic, "after a recolor the debuff's border is still its type's color")
	eq(T.edge(icon_backdrop(enchant)), ENCHANT, "and the enchant's still purple")
	eq(T.edge(icon_backdrop(buff)), '0.70,0.10,0.10,1.00', 'a buff takes the new border color')

	-- A switch to Thin, as st:ThemeChanged runs it: redrawn, every module's profile
	-- update, then the theme's colors changed.
	profile.templates.thick.bordercolor = saved
	profile.theme.name = 'thin'
	st:RedrawThemed()
	SK:UpdateConfig()
	st:ColorsChanged('theme')
	eq(T.offset(backdrop, 'TOPLEFT'), '-1.00,1.00', "the backdrop moves to Thin's border")
	eq(T.edge(backdrop), magic, 'and keeps the debuff color')
	eq(T.edge(icon_backdrop(enchant)), ENCHANT, 'and the enchant color')
	eq(duration_y(buff), -2, "the duration clears Thin's border")

	debuff.DebuffBorder:Hide()
	eq(T.edge(backdrop), T.text(unpack(profile.templates.thin.bordercolor)), "the debuff gone, Thin's own border")
	enchant.TempEnchantBorder:Hide()
	profile.theme.name = 'thick'
	st:RedrawThemed()
	SK:UpdateConfig()
	st:ColorsChanged('theme')
end)

test('a None Skinning theme draws no backdrop, and Use SaftUI\'s theme brings it back', function()
	profile.skinning.theme = 'none'
	SK:UpdateConfig()
	eq(icon_backdrop(buff).backdropInfo, nil, 'None: bare')
	eq(duration_y(buff), -1, 'the duration right under the icon')
	profile.skinning.theme = 'theme'
	SK:UpdateConfig()
	eq(T.inset(icon_backdrop(buff)), 2, "back to Thick's border")
	eq(T.offset(icon_backdrop(buff), 'TOPLEFT'), '-2.00,2.00', 'outside the icon')
end)

test('under Blizzard the buff duration clears the icon by the aura inset and one', function()
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	SK:UpdateConfig()
	eq(st:ThemeInset('blizzard', 'theme', 'aura'), 0, "Blizzard's aura has no inset")
	eq(duration_y(buff), -1, "the duration clears an aura's no inset by the one")
	profile.theme.name = 'thick'
	st:RedrawThemed()
	SK:UpdateConfig()
	eq(duration_y(buff), -3, "and Thick's border again")
end)

------------------------------------ the swing timer skin

-- One of Forever's swing timer bars (Blizzard_SwingTimer) as far as the skin reads it.
local function swing_bar(name)
	local bar = CreateFrame('Frame', name, UIParent)
	bar:SetSize(426, 30)
	bar:SetPoint('CENTER')
	bar.Background = bar:CreateTexture(nil, 'BACKGROUND')
	bar.Border = bar:CreateTexture(nil, 'BORDER')
	local statusBar = CreateFrame('StatusBar', nil, bar)
	statusBar:SetPoint('TOPLEFT', 5, -4)
	statusBar:SetPoint('BOTTOMRIGHT', -5, 4)
	statusBar.Pip = statusBar:CreateTexture(nil, 'OVERLAY')
	statusBar.TypeLabel = statusBar:CreateFontString(nil, 'OVERLAY')
	statusBar.TypeLabel:SetFontObject(GameFontNormal)
	statusBar.TimeLabel = statusBar:CreateFontString(nil, 'OVERLAY')
	statusBar.TimeLabel:SetFontObject(GameFontNormal)
	statusBar.TypeLabelShadow = statusBar:CreateTexture(nil, 'BACKGROUND')
	bar.StatusBar = statusBar
	locked(bar, 'Blizzard swing timer')
	locked(statusBar, 'Blizzard swing timer')
	return bar
end

test('the swing timer skin draws its bars as bars, and follows a theme switch and the Skinning page at once', function()
	local bar = swing_bar('SwingTimerMainHandFrame')
	local ST = SK:GetModule('Blizzard_SwingTimer')
	ST:SkinFrames()
	local statusBar = bar.StatusBar
	local backdrop = icon_backdrop(statusBar)
	eq(drawn(statusBar), 'theme,theme,bar', 'the Skinning Theme and Background, as a bar')
	check(backdrop ~= nil and backdrop:GetParent() == statusBar, "a backdrop of SaftUI's, a child of the bar")
	eq(T.offset(backdrop, 'TOPLEFT'), '-2.00,2.00', "Thick's border outside the bar")

	profile.theme.name = 'thin'
	st:RedrawThemed()
	eq(T.offset(backdrop, 'TOPLEFT'), '-1.00,1.00', "a switch to Thin moves it to Thin's border")
	profile.theme.name = 'thick'
	st:RedrawThemed()

	profile.skinning.theme, profile.skinning.background, profile.skinning.font = 'thin', 'solid', 'normal'
	SK:UpdateConfig()
	eq(drawn(statusBar), 'thin,solid,bar', 'the Skinning page reaches it at once')
	eq(T.inset(backdrop), 1, "Thin's border")
	eq(statusBar.TypeLabel:GetFontObject(), st:GetFont('normal'), 'and the font')
	profile.skinning.theme, profile.skinning.background, profile.skinning.font = 'theme', 'theme', 'pixel'
	SK:UpdateConfig()
end)

------------------------------------ the totem bar

-- Blizzard's totem slot globals (Blizzard_FrameXMLBase's Constants.lua), and the four
-- slot buttons of Forever's totem bar (MultiCastSlotButton1-4) as far as the skin
-- reads them: their art and their slot (ID). The rest of the bar isn't built: the
-- skin passes over what isn't there.
FIRE_TOTEM_SLOT, EARTH_TOTEM_SLOT, WATER_TOTEM_SLOT, AIR_TOTEM_SLOT = 1, 2, 3, 4
local slots = {}
for i = 1, 4 do
	local button = CreateFrame('Button', 'MultiCastSlotButton' .. i, UIParent)
	button:SetID(i)
	button:SetSize(30, 30)
	button:SetPoint('CENTER')
	button.background = button:CreateTexture(nil, 'BACKGROUND')
	button.overlayTex = button:CreateTexture(nil, 'OVERLAY')
	slots[i] = locked(button, 'Blizzard totem slot')
end

test("the totem bar's element borders survive a recolor", function()
	local TB = st:GetModule('TotemBar')
	st:BindModuleConfig(TB, 'totembar')
	TB:SetupSkin()
	local colors = profile.totembar.colors
	local want = { colors.fire, colors.earth, colors.water, colors.air }
	for i, button in ipairs(slots) do
		eq(T.edge(icon_backdrop(button)), T.text(want[i][1], want[i][2], want[i][3], 1), 'slot ' .. i .. ": its element's color")
	end
	local saved = profile.templates.thick.bordercolor
	for _ = 1, 3 do
		profile.templates.thick.bordercolor = { 0.7, 0.1, 0.1, 1 }
		st:RecolorThemed()
	end
	for i, button in ipairs(slots) do
		eq(T.edge(icon_backdrop(button)), T.text(want[i][1], want[i][2], want[i][3], 1), 'slot ' .. i .. ': after a recolor too')
	end
	profile.templates.thick.bordercolor = saved
	st:RecolorThemed()
end)
