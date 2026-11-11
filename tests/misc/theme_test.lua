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
-- The skin treats this atlas as a secret value (the stubs can't make one, and
-- SetAtlas takes only a name): read when the skin loads.
local SECRET_ATLAS = 'a-secret-atlas'
local real_issecretvalue = issecretvalue
function issecretvalue(v) return v == SECRET_ATLAS or (real_issecretvalue and real_issecretvalue(v)) or false end
load_saftui('SaftUI-Misc/Skinning/Blizzard_BuffFrame.lua')
load_saftui('SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua')
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
-- BuffFrame's and DebuffFrame's own buttons are parented to their aura
-- containers, which is how the Auras module knows whose icon size a button has
-- (and gives it its text settings: these are for the border sizes only).
BuffFrame.AuraContainer = CreateFrame('Frame', nil, BuffFrame)
DebuffFrame.AuraContainer = CreateFrame('Frame', nil, DebuffFrame)
local owned_enchant = aura_button(BuffFrame.AuraContainer, 'enchant')
local owned_debuff = aura_button(DebuffFrame.AuraContainer, 'debuff')
BuffFrame.auraFrames = { buff, enchant, owned_enchant }
DebuffFrame.auraFrames = { debuff, owned_debuff }
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

test("under Blizzard the buff skin shows Blizzard's debuff and enchant borders around the icon and colors nothing", function()
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	SK:UpdateConfig()
	st:ColorsChanged('theme')
	for _, button in ipairs({ debuff, owned_debuff }) do
		button.DebuffBorder:SetAtlas('ui-debuff-border-magic-noicon')
		button.DebuffBorder:Show()
	end
	enchant.TempEnchantBorder:Show()
	owned_enchant.TempEnchantBorder:Show()

	local function placed(border, button)
		local point, relativeTo = border:GetPoint(1)
		return border:GetNumPoints() == 1 and point == 'CENTER' and relativeTo == button.Icon
	end
	local function size(border) return T.text(border:GetSize()) end
	local debuffBorder, enchantBorder = owned_debuff.DebuffBorder, owned_enchant.TempEnchantBorder
	for _, border in ipairs({ debuffBorder, enchantBorder, debuff.DebuffBorder, enchant.TempEnchantBorder }) do
		eq(border:GetAlpha(), 1, 'a border shows, at alpha 1')
	end
	check(placed(debuffBorder, owned_debuff), "the debuff's border is centred on the icon")
	check(placed(enchantBorder, owned_enchant), "the enchant's border is centred on the icon")
	check(placed(debuff.DebuffBorder, debuff), "a button the Auras settings don't size: centred too")
	eq(size(debuff.DebuffBorder), '0.00,0.00', "and left at the size Blizzard gave it")
	eq(size(debuffBorder), '40.00,40.00', "the debuff's border is 4/3 of a 30 icon")
	eq(size(enchantBorder), '32.00,32.00', "the enchant's border is 16/15 of a 30 icon")
	eq(select(1, debuffBorder:GetDrawLayer()), 'OVERLAY', "Blizzard's layer, over the icon")

	-- Nothing of SaftUI's colors a border: no own-color piece, a debuff or not.
	for _, button in ipairs({ debuff, enchant, buff, owned_debuff, owned_enchant }) do
		local art = st.ThemeArt.Get(icon_backdrop(button))
		check(not (art and art.own and art.own:IsShown()), 'no own-color piece on the backdrop')
	end

	-- The Auras settings' icon size: 4/3 and 16/15 of it.
	profile.auras.debuffs.size = 45
	profile.auras.buffs.size = 45
	BF:UpdateText()
	eq(size(debuffBorder), '60.00,60.00', 'a 45 icon: 60')
	eq(size(enchantBorder), '48.00,48.00', 'a 45 icon: 48')
	profile.auras.debuffs.size, profile.auras.buffs.size = 30, 30
	BF:UpdateText()

	-- A secret atlas shows Blizzard's border all the same.
	debuffBorder:SetAtlas(SECRET_ATLAS)
	eq(debuffBorder:GetAlpha(), 1, 'a secret atlas: the border shows')
	check(placed(debuffBorder, owned_debuff), 'and is centred on the icon')

	-- A recolor and a redraw change none of it.
	st:RecolorThemed()
	st:RedrawThemed()
	SK:UpdateConfig()
	eq(debuffBorder:GetAlpha(), 1, 'after a redraw: still shown')
	eq(size(debuffBorder), '40.00,40.00', 'and still 40')
	local art = st.ThemeArt.Get(icon_backdrop(owned_debuff))
	check(not (art and art.own and art.own:IsShown()), 'and the backdrop still shows no own-color piece')

	-- Under Thick the borders are hidden again and the border color comes back.
	profile.theme.name = 'thick'
	st:RedrawThemed()
	SK:UpdateConfig()
	st:ColorsChanged('theme')
	debuffBorder:SetAtlas('ui-debuff-border-magic-noicon')
	eq(debuffBorder:GetAlpha(), 0, "Thick: the debuff's border is hidden")
	eq(enchantBorder:GetAlpha(), 0, "Thick: the enchant's border is hidden")
	eq(T.edge(icon_backdrop(owned_debuff)), T.text(MAGIC[1], MAGIC[2], MAGIC[3], 1), "Thick: the debuff's type color is back")
	eq(T.edge(icon_backdrop(owned_enchant)), ENCHANT, 'Thick: and the enchant purple')
	debuffBorder:SetAtlas(SECRET_ATLAS)
	eq(debuffBorder:GetAlpha(), 1, "Thick: a secret atlas still falls back on Blizzard's border")
	debuffBorder:SetAtlas('ui-debuff-border-magic-noicon')
	eq(debuffBorder:GetAlpha(), 0, 'Thick: and a known one hides it again')
	for _, button in ipairs({ debuff, owned_debuff }) do button.DebuffBorder:Hide() end
	enchant.TempEnchantBorder:Hide()
	owned_enchant.TempEnchantBorder:Hide()
	eq(#take_errors(), 0, 'no errors')
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

-- The summon button and the first action button, as the totem bar's templates
-- make them as far as the skin reads them: the icon in BACKGROUND, and the
-- texts where Blizzard's templates put them (the count in ARTWORK, the hotkey
-- and the name in OVERLAY), then the template's flash. The skin writes nothing
-- onto them, so a field it adds fails. The summon and recall buttons get
-- backdrops (and so a ring); the action buttons, on top of the slot buttons,
-- don't.
-- An action button's hotkey and count are on a frame over it at level 500
-- (ActionButtonTemplate's TextOverlayContainer: the element buttons inherit it),
-- which texts = 'container' builds.
local function totem_button(name, texts)
	local button = CreateFrame('CheckButton', name, UIParent)
	button:SetSize(30, 30)
	button:SetPoint('CENTER')
	button.icon = button:CreateTexture(nil, 'BACKGROUND')
	button.Flash = button:CreateTexture(nil, 'ARTWORK', nil, 1)
	local parent = button
	if texts == 'container' then
		button.TextOverlayContainer = CreateFrame('Frame', nil, button)
		button.TextOverlayContainer:SetFrameLevel(500)
		parent = button.TextOverlayContainer
	end
	button.Count = parent:CreateFontString(nil, texts == 'container' and 'OVERLAY' or 'ARTWORK')
	button.HotKey = parent:CreateFontString(nil, 'OVERLAY')
	button.Name = button:CreateFontString(nil, 'OVERLAY')
	return locked(button, 'Blizzard totem button')
end
local summon = totem_button('MultiCastSummonSpellButton')
-- Stacked on slot button 1 (the first of the four, MultiCastSlotButton1, in the fire slot),
-- a higher frame, as Blizzard's is.
local action = totem_button('MultiCastActionButton1', 'container')
action:SetFrameLevel(slots[1]:GetFrameLevel() + 2)

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

-- Where a region draws among its button's regions, as one number: the layer,
-- then the sublevel.
local LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }
local function depth(region)
	local layer, sublevel = region:GetDrawLayer()
	return LAYERS[layer] * 100 + (sublevel or 0)
end

test("under Blizzard the totem buttons take Blizzard's state art", function()
	local TB = st:GetModule('TotemBar')
	local flat = st.BLANK_TEX
	-- Out of the earlier cases' state: Thick, the look the bar's buttons have.
	profile.theme.name = 'thick'
	st:RedrawThemed()
	TB:ApplySkin()
	local hover, pushed, checked = summon:GetHighlightTexture(), summon:GetPushedTexture(), summon:GetCheckedTexture()
	eq(hover:GetTexture(), flat, 'Thick: the flat hover')
	eq(T.around(hover, summon.icon), '0,0,0,0', 'Thick: over the icon')
	eq(depth(pushed), 400, 'Thick: pushed in OVERLAY, as before')

	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	TB:ApplySkin()
	local backdrop = icon_backdrop(summon)
	eq(hover:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', "hover is Blizzard's")
	eq(pushed:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Down', "pushed is Blizzard's")
	eq(checked:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', "checked is Blizzard's")
	eq(checked:GetBlendMode(), st.forever and 'ADD' or 'BLEND', 'checked blends as the template does on this client')
	eq(summon.Flash:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Flash', "the flash is Blizzard's")
	for name, region in pairs({ hover = hover, pushed = pushed, checked = checked, flash = summon.Flash }) do
		eq(T.text(region:GetVertexColor()), '1.00,1.00,1.00,1.00', name .. ' has no tint')
		eq(T.around(region, summon), '0,0,0,0', name .. " covers the button, the ring's footprint")
	end

	-- The ring and the own-color piece are textures of the button, over the icon,
	-- so the texts, which a frame over the button would cover, stay readable.
	st:SetBorderColor(backdrop, 1, 0, 0)
	local art = st.ThemeArt.Get(backdrop)
	local ring, own = art.over.Ring, art.own
	eq(ring:GetParent(), summon, "the ring is a texture of the button's own")
	eq(own:GetParent(), summon, "so is the own-color piece")
	check(own:IsShown(), 'the own-color piece shows')
	check(depth(ring) > depth(summon.icon), 'the ring draws over the icon')
	check(depth(own) > depth(ring), 'the own-color piece draws over the ring')
	for _, text in ipairs({ summon.Count, summon.HotKey, summon.Name }) do
		check(depth(text) > depth(ring), 'a font string draws over the ring')
		check(depth(text) > depth(own), 'a font string draws over the own-color piece')
	end
	for name, region in pairs({ hover = hover, pushed = pushed, checked = checked }) do
		check(depth(region) > depth(ring), name .. ' draws over the ring')
		check(depth(region) > depth(summon.icon), name .. ' draws over the icon')
		for _, text in ipairs({ summon.Count, summon.HotKey, summon.Name }) do
			check(depth(region) < depth(text), name .. ' draws under the texts')
		end
	end
	check(depth(summon.Flash) > depth(ring), 'the flash draws over the ring')
	check(depth(summon.Flash) < depth(summon.Name), 'and under the texts')

	-- A button with no backdrop of its own takes the state art too.
	eq(action:GetHighlightTexture():GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', "an action button's hover")
	eq(action:GetPushedTexture():GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Down', "an action button's pushed")

	-- The element's ring and colour on the stacked action button: the slot button's
	-- own, under its opaque icon, show nothing there. Both are on a holder of
	-- SaftUI's over the action button's icon and under its texts (the frame at
	-- level 500), and nothing is written onto the locked Blizzard button.
	TB:OnColorsChanged('theme')
	local ringFrame = icon_backdrop(action)
	check(ringFrame ~= nil and ringFrame ~= action.TextOverlayContainer, 'the action button has a ring frame of its own')
	local elementArt = st.ThemeArt.Get(ringFrame)
	local elementRing, elementOwn = elementArt.over.Ring, elementArt.own
	check(elementRing:IsShown(), "the element's ring shows")
	check(elementOwn ~= nil and elementOwn:IsShown(), "the element's border shows")
	local fire = profile.totembar.colors.fire
	eq(T.text(elementOwn:GetVertexColor()), T.text(fire[1], fire[2], fire[3], 1), 'in the fire colour')
	local holder = elementRing:GetParent()
	eq(elementOwn:GetParent(), holder, 'on the same holder')
	check(holder ~= action and holder:GetParent() == ringFrame, "a frame of SaftUI's, not the button")
	check(holder:GetFrameLevel() > action:GetFrameLevel(), 'the holder is over the action button, and so its icon')
	check(holder:GetFrameLevel() < action.TextOverlayContainer:GetFrameLevel(), 'and under its texts')
	check(holder:GetFrameLevel() > slots[1]:GetFrameLevel(), "and over the slot button's own ring")
	eq(drawn(action), 'theme,theme,action', 'drawn as an action button')

	-- Under Thick the slot button's border is the element's and the action button
	-- shows nothing of its own.
	profile.theme.name = 'thick'
	st:RedrawThemed()
	TB:ApplySkin()
	check(not elementRing:IsShown() and not elementOwn:IsShown(), 'Thick: no ring over the action button')
	eq(ringFrame.backdropInfo, nil, 'Thick: no border on it either')
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	TB:ApplySkin()
	check(elementRing:IsShown() and elementOwn:IsShown(), 'Blizzard again: ring and colour are back')

	-- Set out of combat, as before: a profile change in combat waits.
	stub.in_combat = true
	profile.theme.name = 'thick'
	st:RedrawThemed()
	TB:ApplySkin()
	eq(hover:GetAtlas(), 'UI-HUD-ActionBar-IconFrame-Mouseover', 'in combat the state art is left as it is')
	stub.in_combat = false
	TB:ApplySkin()
	eq(hover:GetTexture(), flat, 'out of combat: the flat hover again')
	eq(hover:GetAtlas(), nil, 'no atlas')
	eq(T.around(hover, summon.icon), '0,0,0,0', 'over the icon')
	eq(T.text(hover:GetVertexColor()), T.text(profile.colors.button.blue:GetRGB()) .. ',1.00', 'blue')
	eq(summon.Flash:GetAtlas(), nil, 'Thick: no flash atlas')
	eq(select(4, summon.Flash:GetVertexColor()) ~= nil, true, 'the flat flash')
	eq(art.over.Ring:IsShown(), false, 'Thick: no ring')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ a skinned Blizzard panel

-- The metal's shown pieces, as T.art lists them.
local METAL = table.concat({
	'BottomEdge=_UI-Frame-Metal-EdgeBottom',
	'BottomLeftCorner=UI-Frame-Metal-CornerBottomLeft',
	'BottomRightCorner=UI-Frame-Metal-CornerBottomRight',
	'LeftEdge=!UI-Frame-Metal-EdgeLeft',
	'RightEdge=!UI-Frame-Metal-EdgeRight',
	'TopEdge=_UI-Frame-Metal-EdgeTop',
	'TopLeftCorner=UI-Frame-Metal-CornerTopLeft',
	'TopRightCorner=UI-Frame-Metal-CornerTopRight',
}, ',')

-- Blizzard's panel as far as SK:SkinBlizzardPanel reads it: named (the skin
-- finds its parts by name), 400 by 500, with its close button. Not locked:
-- the skin's st:CreateHeader still writes its header onto it
-- (docs/followups.md, "st:CreateHeader writes fields onto the frame it's given").
local function blizzard_panel(name)
	local panel = CreateFrame('Frame', name, UIParent)
	panel:SetSize(400, 500)
	panel:SetPoint('CENTER')
	CreateFrame('Button', name .. 'CloseButton', panel)
	return panel
end

-- Skins panel, and returns the frame its window was drawn behind.
local function skin_panel(panel, options)
	local windows = {}
	local draw = st.SetBackdrop
	st.SetBackdrop = function(self, frame, theme, background, kind)
		if kind == 'window' then windows[#windows + 1] = frame end
		return draw(self, frame, theme, background, kind)
	end
	SK:SkinBlizzardPanel(panel, options)
	st.SetBackdrop = draw
	eq(#windows, 1, 'one window drawn')
	return windows[1]
end

-- SK:SkinBlizzardPanel draws a window. With fix_padding the window is the
-- panel's padded area, a frame of SaftUI's the engine places the window's
-- backdrop around, so the metal's title bar lies above the panel's header
-- and its fill starts at the header, as on every window. Nothing calls the
-- skin today.
test("a skinned Blizzard panel is a window; with fix_padding the metal's title bar sits above its header", function()
	local plain = blizzard_panel('SaftUIThemeTestPlainPanel')
	local window = skin_panel(plain, { title = 'Plain' })
	eq(window, plain, 'without fix_padding the window is drawn behind the panel')
	eq(drawn(plain), 'theme,theme,window', 'panels.theme and panels.background, as a window')
	eq(T.around(plain.backdrop, plain), '-2,2,2,-2', "Thick: the backdrop 2px outside the panel")

	local padded = blizzard_panel('SaftUIThemeTestPaddedPanel')
	local area = skin_panel(padded, { fix_padding = true, title = 'Padded' })
	check(area ~= nil and area ~= padded, "with fix_padding the window is drawn behind a frame of SaftUI's")
	if not area then return end
	eq(drawn(area), 'theme,theme,window', 'as a window')
	local backdrop, header = area.backdrop, padded.header
	eq(T.around(backdrop, padded), '10,-10,-30,74', 'Thick: the backdrop where fix_padding put it before')
	eq(T.around(header, padded):match('^(%-?%d+,%-?%d+,%-?%d+)'), '12,-12,-32', 'the header 2px inside it')

	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	local title = st.ThemeArt.TitleHeight()
	eq(T.art(backdrop), METAL, 'Blizzard: the metal')
	eq(T.around(backdrop, padded), '10,' .. (title - 12) .. ',-30,74', "Blizzard: the title bar's height above the padded area")
	local insets = backdrop.backdropInfo and backdrop.backdropInfo.insets or {}
	eq(T.text(backdrop:GetTop() - (insets.top or 0)), T.text(header:GetTop()), 'the fill starts at the top of the header')
	eq(T.text(backdrop:GetTop() - title), T.text(header:GetTop()), "the title bar lies above the header, over none of it")
	eq(T.art(plain.backdrop), METAL, 'the plain panel wears the metal too')
	eq(T.around(plain.backdrop, plain), '-2,' .. title .. ',2,-2', "its title bar above it")

	profile.theme.name = 'thick'
	st:RedrawThemed()
	eq(T.around(backdrop, padded), '10,-10,-30,74', 'Thick again: where it was')
	eq(T.art(backdrop), '', 'Thick again: no art')
	eq(#take_errors(), 0, 'no errors')
end)
