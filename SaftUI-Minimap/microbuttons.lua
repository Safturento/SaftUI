local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

-- Restyles Blizzard's micro menu and puts its buttons inline in SaftUI's micro
-- menu bar, next to the bar's other items.
--
-- Taint: MicroMenuContainer is an Edit Mode system frame, and MicroMenu and its
-- buttons belong to Blizzard. Nothing here writes a Lua field onto them. Our
-- per-button state lives in local tables, our art lives on frames we create,
-- and Blizzard's regions are only changed through widget methods. Blizzard
-- re-applies its art and layout often, so we re-apply after it with
-- hooksecurefunc and HookScript. No Blizzard Lua function is ever called from
-- here, so nothing Blizzard writes happens under our taint.
--
-- The bar's UpdateButtons reparents every item it lays out into SaftUI's bar,
-- so Blizzard's buttons are never given to it (they stay MicroMenu's, below).
-- Each button gets a SaftUI holder frame instead: the holder is the bar item
-- that takes the button's slot, and the button is anchored over it.
--
-- The buttons stay parented to MicroMenu, so Blizzard's own scripts, alerts,
-- notification pips and vehicle/pet battle handling keep working. Blizzard
-- still runs MicroMenu:Layout, and the post-hook moves the buttons afterwards.
-- So the buttons only draw while whatever Blizzard parents MicroMenu to is on
-- screen. Blizzard moves it into the pet battle frame and, for a skinned
-- vehicle, into OverrideActionBar. SaftUI-ActionBars blocks that bar, so it
-- turns the bar's events off too, which keeps the menu out of it
-- (SaftUI-ActionBars/hideblizzard.lua).

-- The buttons keep the template's 32x40 shape at the bar's height
-- (MicroMenu:BarHeight, MicroMenu:MicroWidth): 20x25 at the default height.
local DEFAULT_HEIGHT = MicroMenu.BUTTON_SIZE
-- Each button's panel follows SaftUI's theme.
local THEME, BACKGROUND = 'theme', 'theme'

-- Blizzard's icon atlases are 32x41, with the glyph (at most 22x28) centered in
-- transparent padding. Drawn at 22x28 the glyph is at most about 15x19, which
-- leaves a 2px margin across a 20px wide button and 3px down a 25px tall one,
-- about the same share of the button as in Blizzard's own 32x40. The texture
-- is a little wider than the button, but only its padding hangs over. Keeping
-- the atlas's own aspect means no texcoord crop, which Blizzard would undo
-- every time it swaps an atlas.
-- Those sizes are at the default height; at another, the icons, the template's
-- art and the guild emblem scale with the bar (IconSize).
local ICON_WIDTH, ICON_HEIGHT = 22, 28
-- The guild emblem sits on the tabard glyph at 12x14; scaled with the icon.
local EMBLEM_WIDTH, EMBLEM_HEIGHT = 8, 10

-- The icon's size at the bar's height, whole pixels, and how far it reaches
-- over the button's top (its padding, centred on the button).
local function IconSize()
    local height = MicroMenu:BarHeight()
    local scale = height / DEFAULT_HEIGHT
    local w, h = math.floor(ICON_WIDTH * scale + 0.5), math.floor(ICON_HEIGHT * scale + 0.5)
    return w, h, math.ceil((h - height) / 2), height
end

local ALERT_ALPHA = 0.5

local buttons = {} -- Blizzard's micro buttons, in Blizzard's order
local arts = setmetatable({}, { __mode = 'k' }) -- button -> whether its art is Blizzard's (StyleArt)
local skins = setmetatable({}, { __mode = 'k' }) -- button -> SaftUI backdrop
local holders = setmetatable({}, { __mode = 'k' }) -- button -> SaftUI holder in the bar

-- Crops a square portrait to width x height, zoomed in a little, with the face
-- slightly above center.
local function GetPortraitCoords(width, height)
    local zoom = 0.8
    local w, h = zoom, zoom
    if width > height then
        h = zoom * height / width
    else
        w = zoom * width / height
    end
    return 0.5 - w / 2, 0.5 + w / 2, 0.45 - h / 2, 0.45 + h / 2
end

local function PlaceIcon(texture, button, width)
    if not texture then return end
    local iconWidth, iconHeight, top = IconSize()
    texture:ClearAllPoints()
    texture:SetPoint('TOPLEFT', button, 'TOPLEFT', math.floor((width - iconWidth) / 2 + 0.5), top)
    texture:SetSize(iconWidth, iconHeight)
end

-- Puts a button's art in the look it's drawn in: under Blizzard, the template's
-- own (Blizzard's art shown again, the pushed background and the alert in its
-- atlases, the highlight its mouseover art), and under Thick and Thin today's
-- fades and flat colors. Only widget methods on the template's regions, so
-- nothing is written onto the button, and no Blizzard function is called.
-- Blizzard only shows, hides and fades these regions and re-sets the
-- highlight, so this runs when the look changes, from StyleTextures (every
-- layout and so every theme switch passes it), not on every call.
-- Centers a template region on the button at the icons' size.
local function PlaceArt(region, button)
    local iconWidth, iconHeight = IconSize()
    region:ClearAllPoints()
    region:SetPoint('CENTER', button, 'CENTER')
    region:SetSize(iconWidth, iconHeight)
end

local function StyleArt(button)
    local blizzard = st:IsBlizzardLook(THEME, BACKGROUND)
    if arts[button] == blizzard then return end
    arts[button] = blizzard
    local micro = st.ThemeArt.Control('micro')

    -- Blizzard only Show/Hides these, so alpha sticks
    for _, region in pairs({ button.Background, button.Shadow, button.PushedShadow, button.MainMenuBarPerformanceBar }) do
        region:SetAlpha(blizzard and 1 or 0)
    end
    -- Blizzard draws these at the atlas's size (~32x41), centered on its 32x40
    -- button. On the bar's button they take the icons' size and place
    -- (PlaceIcon: the same 0.69 scale), so they don't overlap the neighbors.
    -- Faded under Thick and Thin, so nothing to put back there.
    if blizzard then
        for _, region in pairs({ button.Background, button.Shadow, button.PushedShadow }) do
            PlaceArt(region, button)
        end
    end

    -- Blizzard shows this while the button's frame is open. The template
    -- centers it at the atlas's size (MainMenuBarMicroButtons.xml); flat, it's
    -- the fade of the state helper over the button (the checked piece).
    local pushed = button.PushedBackground
    if pushed then
        pushed:ClearAllPoints()
        if blizzard then
            -- The flat look's fade left coordinates on this piece (the checked
            -- piece of the state helper), which SetAtlas keeps unless it resets
            -- them: reset them, and set the whole atlas after.
            pushed:SetAtlas(micro.pushedBackground, false, nil, true)
            pushed:SetTexCoord(0, 1, 0, 1)
            PlaceArt(pushed, button)
        else
            -- the Fill: its texture and color are the state helper's (RestyleStates,
            -- the end of StyleTextures)
            pushed:SetAllPoints(button)
        end
    end

    -- The alert pulse (UIFrameFlash) and the journal's new-content notice only
    -- show/hide and fade this, so what it shows sticks. The template has it
    -- over the button's art (OVERLAY). Flat, behind the icon it lights up the
    -- panel; over the portrait it has to stay on top to be seen.
    local flash = button.FlashBorder
    if flash then
        if blizzard then
            flash:SetAtlas(micro.flashBorder)
            flash:SetDrawLayer('OVERLAY', 0)
        else
            local r, g, b = st:Color('text', 'caution'):GetRGB()
            flash:SetColorTexture(r, g, b, ALERT_ALPHA)
            if not button.Portrait then
                flash:SetDrawLayer('BACKGROUND', 1)
            end
        end
    end

    -- Blizzard sets the highlight itself (LoadMicroButtonTextures) and its
    -- atlas swaps leave it be under Blizzard. After a switch to Blizzard it's
    -- set once, to the mouseover art Blizzard gives it: a tint set under
    -- Thick or Thin is still on it, and the character button has none of its
    -- own. The call ends in the SetHighlightAtlas hook, which finds the look
    -- already set.
    if blizzard then
        -- the state helper's colors were on these two (a vertex color outlives an atlas)
        local highlight = button:GetHighlightTexture()
        if highlight then highlight:SetVertexColor(1, 1, 1, 1) end
        if pushed then pushed:SetVertexColor(1, 1, 1, 1) end
    end
    if blizzard and button.textureName then
        button:SetHighlightAtlas(micro.highlight:format(button.textureName), micro.highlightBlend)
    end
end

-- Re-applies everything Blizzard resets: icon anchors (SetNormalAtlas and
-- friends), the highlight (SetNormal/SetPushed swap its atlas, blend and
-- alpha), and the portrait (Character's SetNormal/SetPushed re-anchor it).
local function StyleTextures(button)
    StyleArt(button)
    local blizzard = st:IsBlizzardLook(THEME, BACKGROUND)
    local width = MicroMenu:MicroWidth()
    local height = MicroMenu:BarHeight()

    PlaceIcon(button:GetNormalTexture(), button, width)
    PlaceIcon(button:GetPushedTexture(), button, width)
    PlaceIcon(button:GetDisabledTexture(), button, width)
    PlaceIcon(button.FlashContent, button, width)

    -- Under Blizzard the highlight is Blizzard's art, as it sets it, at the
    -- icons' size and place. Blizzard's atlas swaps may reset them, so this is
    -- every pass.
    if blizzard then
        local blizzardHighlight = button:GetHighlightTexture()
        if blizzardHighlight then PlaceArt(blizzardHighlight, button) end
    end
    local highlight = not blizzard and button:GetHighlightTexture()
    if highlight then
        highlight:ClearAllPoints()
        highlight:SetAllPoints(button)
    end

    local portrait = button.Portrait
    if portrait then
        -- Pushed (character frame open) insets the portrait so the pushed
        -- fill shows around it.
        local inset = button:GetButtonState() == 'PUSHED' and 2 or 0
        portrait:ClearAllPoints()
        portrait:SetPoint('TOPLEFT', button, 'TOPLEFT', inset, -inset)
        portrait:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -inset, inset)
        portrait:SetTexCoord(GetPortraitCoords(width - inset * 2, height - inset * 2))
    end

    -- Last in the look: Blizzard's atlas swaps put its own art back on the
    -- highlight (the game's color, atlas and blend, and a guild tabard's tint),
    -- so the state helper puts the white texture, BLEND and the derived colors
    -- on again (under Blizzard it leaves Blizzard's art alone); then the state
    -- the swap says.
    st:RestyleStates(button)
    MicroMenu.OnButtonState(button)
end

-- A color changed (MicroMenu:OnColorsChanged): the alert flash (Text > Caution at
-- ALERT_ALPHA) takes it, on the buttons drawn flat (Thick and Thin), where SaftUI
-- colored that region. The highlight and the pushed fill follow the Accent
-- through the state helper (st:AddStates in SkinButton: a pass of its own, which
-- sets a vertex color on a white texture). Only the region's color: nothing is
-- laid out, so it runs in combat too.
function MicroMenu:ColorMicroButtons(key)
    if not (key == nil or key == 'caution') then return end
    for _, button in ipairs(buttons) do
        if arts[button] == false then
            local flash = button.FlashBorder
            if flash then
                local r, g, b = st:Color('text', 'caution'):GetRGB()
                flash:SetColorTexture(r, g, b, ALERT_ALPHA)
            end
        end
    end
end

-- A micro button whose window is open is selected (the Fill, which Blizzard
-- shows, and the panel's Accent edge). Blizzard's SetPushed sets the button's
-- state before it swaps the highlight, which SaftUI's post-hooks follow
-- (StyleTextures), so this reads the state there: no hook of its own on
-- SetButtonState. Only colors a frame of SaftUI's, so it runs in combat.
function MicroMenu.OnButtonState(button)
    local pushed = button:GetButtonState() == 'PUSHED'
    if st:GetState(button, 'selected') == pushed then return end
    st:SetState(button, 'selected', pushed)
end

-- Blizzard's SetNormal and SetPushed set the highlight's alpha (1, 0.5 while the
-- window is open) after the atlas swap the SetHighlightAtlas hook restyles. In
-- the client a texture may keep one alpha for SetAlpha and its vertex color, and
-- then that write undoes the hover's strength: the hover drew as an opaque block
-- on the buttons whose SetNormal and SetPushed write that alpha after the swap,
-- Professions to Shop (2026-11-16). The character button's have no such write, and
-- the game menu button is repainted by its OnUpdate, which swaps the atlas again
-- (at once under the mouse: OnEnter zeroes its updateInterval). So the state colors
-- go on again after both. Colors only (st:PaintStates), so in combat too.
-- The one-alpha model is unverified: docs/followups.md, "Micro buttons' hover".
local function PaintButton(button)
    st:PaintStates(button)
end

-- Keeps the backdrop (a child of the button) drawing under the button's own art
local function UpdateSkinLevel(button)
    local level = button:GetFrameLevel()
    if not issecretvalue(level) then
        skins[button]:SetFrameLevel(math.max(0, level - 1))
    end
end

-- Shows each holder while its button is shown, so the bar closes up around
-- buttons Blizzard hides (game rules, level, region). A holder's OnShow/OnHide
-- lays the bar out again (MicroMenu:AddButton hooks every bar item). This reads
-- the shown flag, not visibility, so the slots don't come and go when Blizzard
-- moves MicroMenu to a vehicle or pet battle bar.
local function UpdateHolders()
    for _, button in ipairs(buttons) do
        local holder = holders[button]
        if holder then
            holder:SetShown(button:IsShown())
        end
    end
end

-- After any Blizzard layout, scale or show/hide change. Every button is
-- checked, not just the one that changed: a button Blizzard hid while the menu
-- was out of sight fired no OnHide of its own.
local function Refresh()
    UpdateHolders()
    MicroMenu:UpdateBlizzardButtons()
    MicroMenu:ReapplyFade()
end

-- The bar item that takes the button's slot. The button's own panel (below)
-- draws under its art, so the holder has no backdrop and only reserves space.
-- Under Blizzard each holder stands on the bar's box (micromenuart.lua's
-- UpdateBackdrop), under Blizzard's button art.
local buttonOf = setmetatable({}, { __mode = 'k' }) -- holder -> its button

local function CreateHolder(button)
    local holder = CreateFrame('Frame', nil, MicroMenu.Container)
    holder:SetShown(button:IsShown())
    holders[button] = holder
    buttonOf[holder] = button
    return holder
end

-- Buttons the profile turns off (MicroMenu:IsTurnedOff): button -> the alpha
-- Blizzard last gave it, put back when it shows again.
local concealed = setmetatable({}, { __mode = 'k' })

-- After Blizzard's OnEnable or OnDisable set the alpha: kept, and 0 again
local function KeepConcealed(button)
    if concealed[button] then
        concealed[button] = button:GetAlpha()
        getmetatable(button).__index.SetAlpha(button, 0)
    end
end

local function IsBlizzardLook()
    return st:IsBlizzardLook(THEME, BACKGROUND)
end

local function SkinButton(button)
    CreateHolder(button)

    -- The button's panel, a control: a small frame under Thick and Thin, and
    -- nothing under Blizzard, whose micro button art (StyleArt) is the
    -- button's own. Made here, where its level is read safely
    -- (UpdateSkinLevel), and drawn with st:SetBackdropIn, which keeps it the
    -- theme's border outside the button through a theme switch.
    local skin = st:CreateFrame('Frame', nil, button)
    -- Blizzard halves a disabled button's alpha; dim the icon, not the panel
    skin:SetIgnoreParentAlpha(true)
    skins[button] = skin
    UpdateSkinLevel(button)
    st:SetBackdropIn(skins, button, THEME, BACKGROUND, 'control')

    -- Notification pip, a badge on the top right corner instead of a 21px
    -- diamond over the top edge
    local pip = button.NotificationOverlay and button.NotificationOverlay:GetRegions()
    if pip then
        pip:ClearAllPoints()
        pip:SetPoint('CENTER', button, 'TOPRIGHT', -4, -4)
        pip:SetSize(14, 14)
    end

    for _, emblem in pairs({ button.Emblem, button.HighlightEmblem }) do
        emblem:SetSize(EMBLEM_WIDTH, EMBLEM_HEIGHT)
    end

    if button.Portrait then
        if button.PortraitMask then
            button.Portrait:RemoveMaskTexture(button.PortraitMask)
        end
        -- The character button has no highlight of its own
        if not button:GetHighlightTexture() then
            button:SetHighlightTexture(button:CreateTexture(nil, 'HIGHLIGHT'))
        end
        hooksecurefunc(button, 'SetNormal', StyleTextures)
        hooksecurefunc(button, 'SetPushed', StyleTextures)
    end

    -- The highlight is the hover piece and the pushed background (shown by
    -- Blizzard while the button's frame is open) the Fill: Blizzard's two regions,
    -- colored only, never handed or shown. The panel is the edge, the Accent
    -- while the window is open. Under Blizzard the helper leaves both alone.
    st:AddStates(button, 'icon', {
        pieces = { hover = button:GetHighlightTexture(), checked = button.PushedBackground },
        edge = 'theme',
        blizzard = IsBlizzardLook,
    })

    -- Every Blizzard atlas swap (LoadMicroButtonTextures, SetNormal/SetPushed,
    -- the game menu button's once-a-second streaming update) ends here.
    hooksecurefunc(button, 'SetHighlightAtlas', StyleTextures)
    -- ... and the highlight's alpha Blizzard sets after it (PaintButton). The
    -- character button's own SetNormal and SetPushed hooks end in the colors already.
    if not button.Portrait then
        for _, method in ipairs({ 'SetNormal', 'SetPushed' }) do
            if type(button[method]) == 'function' then hooksecurefunc(button, method, PaintButton) end
        end
    end

    -- Blizzard hides the icon on hover because its mouseover art redraws it;
    -- our highlight is a tint, so keep the icon (Blizzard's own art stays so
    -- under Blizzard).
    button:HookScript('OnEnter', function(self)
        if st:IsBlizzardLook(THEME, BACKGROUND) then return end
        local normal = self:GetNormalTexture()
        if normal then normal:SetAlpha(1) end
    end)

    -- Blizzard re-runs MicroMenu:Layout on show/hide only while the menu sits
    -- in its container, not in a vehicle or pet battle bar.
    button:HookScript('OnShow', Refresh)
    button:HookScript('OnHide', Refresh)

    -- Blizzard's OnEnable and OnDisable set the button's alpha (1, or 0.5);
    -- a button the profile turns off stays concealed after them (ConcealMicro).
    button:HookScript('OnEnable', KeepConcealed)
    button:HookScript('OnDisable', KeepConcealed)

    StyleTextures(button)
end

-- Skins Blizzard's micro buttons and adds a holder for each to SaftUI's bar
-- with AddButton, so MicroMenu:OnEnable calls this at the spot in the bar's
-- order where the buttons go.
function MicroMenu:SkinBlizzardMicroMenu()
    local menu = _G.MicroMenu
    if not menu then return end

    -- The buttons Blizzard added to its menu (game rules skip some), in its order
    for _, child in ipairs({ menu:GetChildren() }) do
        if child.layoutIndex and child:IsObjectType('Button') then
            tinsert(buttons, child)
        end
    end
    table.sort(buttons, function(a, b) return a.layoutIndex < b.layoutIndex end)
    if #buttons == 0 then return end

    -- Forever's frame art around the whole menu, faded in every look. Under
    -- Blizzard each holder stands on a box of the bar's instead
    -- (micromenuart.lua), so this stays where Blizzard put it.
    if menu.BorderArt then menu.BorderArt:SetAlpha(0) end
    if menu.BackgroundArt then menu.BackgroundArt:SetAlpha(0) end

    for _, button in ipairs(buttons) do
        SkinButton(button)
        local holder = holders[button]
        self:AddButton(holder, { key = MicroMenu.MicroKey(button), theme = 'none', micro = true })
    end

    -- Layout re-anchors the buttons into Blizzard's grid; UpdateScale follows
    -- Edit Mode's size and the vehicle/pet battle scale override.
    hooksecurefunc(menu, 'Layout', Refresh)
    if menu.UpdateScale then
        hooksecurefunc(menu, 'UpdateScale', Refresh)
    end
    -- It sets a guild tabard's color after the atlas swap we hook per button
    if LoadMicroButtonTextures then
        hooksecurefunc('LoadMicroButtonTextures', function(button)
            if skins[button] then StyleTextures(button) end
        end)
    end

    -- Blizzard's Edit Mode box for the micro menu no longer moves or sizes the
    -- buttons, so keep it hidden. HookScript only; nothing is written onto it.
    st:HideEditModeSelection(MicroMenuContainer)
end

-- Puts each button over its holder in SaftUI's bar (UpdateButtons places the
-- holders). Sizes come from SaftUI's own numbers, never from Blizzard frame
-- geometry; the scale and frame level reads are guarded for secret values.
function MicroMenu:UpdateBlizzardButtons()
    local menu = _G.MicroMenu
    if not (menu and #buttons > 0) then return end

    -- The buttons inherit MicroMenu's scale (Edit Mode size, vehicle override);
    -- cancel it so they match the bar.
    local scale = 1
    local menuScale, barScale = menu:GetEffectiveScale(), self.Container:GetEffectiveScale()
    if not issecretvalue(menuScale) and not issecretvalue(barScale) and menuScale > 0 then
        scale = barScale / menuScale
    end

    -- Hidden buttons too, so one Blizzard shows later is already in its slot
    local width, height = self:MicroWidth(), self:BarHeight()
    local emblemScale = height / DEFAULT_HEIGHT
    for _, button in ipairs(buttons) do
        local holder = holders[button]
        if holder then
            button:SetScale(scale)
            button:SetSize(width, height)
            for _, emblem in pairs({ button.Emblem, button.HighlightEmblem }) do
                emblem:SetSize(math.floor(EMBLEM_WIDTH * emblemScale + 0.5), math.floor(EMBLEM_HEIGHT * emblemScale + 0.5))
            end
            button:ClearAllPoints()
            button:SetPoint('TOPLEFT', holder, 'TOPLEFT')

            UpdateSkinLevel(button)
            StyleTextures(button)
        end
    end
end

--- Turning buttons off, the fade, and their names ----------------------------------

-- The button's key in the profile's show table: 'micro_' and its global name
-- without MicroButton (micro_Character), or its place in Blizzard's order.
function MicroMenu.MicroKey(button)
    local name = button:GetName()
    name = name and name:gsub('MicroButton$', '') or ('button' .. tostring(button.layoutIndex))
    return 'micro_' .. name
end

-- Names for the buttons whose global names say little. Any other button is
-- named from its key, its words split (QuestLog: Quest log).
local MICRO_NAMES = {
    micro_LFD = 'Group finder',
    micro_EJ = 'Adventure guide',
    micro_MainMenu = 'Game menu',
    micro_Store = 'Shop',
    micro_PlayerSpells = 'Talents and spellbook',
    micro_Profession = 'Professions',
    micro_Achievement = 'Achievements',
    micro_Guild = 'Guild and communities',
}

local function MicroName(key)
    if MICRO_NAMES[key] then return MICRO_NAMES[key] end
    local words = key:gsub('^micro_', ''):gsub('(%l)(%u)', '%1 %2')
    return words:sub(1, 1) .. words:sub(2):lower()
end

-- The micro buttons Blizzard gave the menu, in its order: { key, name } each.
-- For the options page.
function MicroMenu:MicroItems()
    local list = {}
    for _, button in ipairs(buttons) do
        local key = MicroMenu.MicroKey(button)
        list[#list + 1] = { key, MicroName(key) }
    end
    return list
end

-- Conceals the holder's Blizzard button, or shows it again (micromenu.lua's
-- S.Conceal): alpha 0 and no mouse through the widget methods, and its panel
-- hidden (a frame of SaftUI's, which ignores the button's alpha). The
-- OnEnable and OnDisable hooks keep the alpha at 0 after Blizzard's own. Shown
-- again, it takes the alpha Blizzard last gave it (halved while disabled).
-- Out of combat only (MicroMenu:UpdateConcealed).
function MicroMenu.S.ConcealMicro(holder, off)
    local button = buttonOf[holder]
    if not button or (concealed[button] ~= nil) == off then return end
    local widget = getmetatable(button).__index
    if off then
        concealed[button] = button:GetAlpha()
        widget.SetAlpha(button, 0)
    else
        widget.SetAlpha(button, concealed[button])
        concealed[button] = nil
    end
    widget.EnableMouse(button, not off)
    if skins[button] then skins[button]:SetShown(not off) end
    -- The holder (SaftUI's) keeps its shown state but draws nothing either,
    -- so a box laid on it under Blizzard doesn't show in the closed-up row
    holder:SetAlpha(off and 0 or 1)
end

function MicroMenu.S.IsMicroConcealed(holder)
    local button = buttonOf[holder]
    return button and concealed[button] ~= nil or false
end

-- The bar's mouseover fade (micromenu.lua): the panels ignore their button's
-- alpha, so each takes the bar's. SaftUI's frames only, so in combat too.
function MicroMenu.S.FadeMicro(alpha)
    for _, button in ipairs(buttons) do
        if skins[button] then skins[button]:SetAlpha(alpha) end
    end
end
