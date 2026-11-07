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

local BUTTON_HEIGHT = MicroMenu.BUTTON_SIZE
-- Blizzard's MainMenuBarMicroButton template is 32x40 on Forever and retail
-- (Blizzard_MicroMenu/Mainline/MainMenuBarMicroButtons.xml). The buttons keep
-- that shape at the bar's height: 20x25.
local BUTTON_RATIO = 32 / 40
local TEMPLATE = 'thicktransparent'

-- Blizzard's icon atlases are 32x41, with the glyph (at most 22x28) centered in
-- transparent padding. Drawn at 22x28 the glyph is at most about 15x19, which
-- leaves a 2px margin across a 20px wide button and 3px down a 25px tall one,
-- about the same share of the button as in Blizzard's own 32x40. The texture
-- is a little wider than the button, but only its padding hangs over. Keeping
-- the atlas's own aspect means no texcoord crop, which Blizzard would undo
-- every time it swaps an atlas.
local ICON_WIDTH, ICON_HEIGHT = 22, 28
local ICON_TOP = math.ceil((ICON_HEIGHT - BUTTON_HEIGHT) / 2)
-- The guild emblem sits on the tabard glyph at 12x14; scaled with the icon.
local EMBLEM_WIDTH, EMBLEM_HEIGHT = 8, 10

local HOVER_ALPHA = 0.4
local PUSHED_ALPHA = 0.6
local ALERT_ALPHA = 0.5

local buttons = {} -- Blizzard's micro buttons, in Blizzard's order
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
    texture:ClearAllPoints()
    texture:SetPoint('TOPLEFT', button, 'TOPLEFT', math.floor((width - ICON_WIDTH) / 2 + 0.5), ICON_TOP)
    texture:SetSize(ICON_WIDTH, ICON_HEIGHT)
end

-- Re-applies everything Blizzard resets: icon anchors (SetNormalAtlas and
-- friends), the highlight (SetNormal/SetPushed swap its atlas, blend and
-- alpha), and the portrait (Character's SetNormal/SetPushed re-anchor it).
local function StyleTextures(button)
    local holder = holders[button]
    local width = holder and holder.width or BUTTON_HEIGHT

    PlaceIcon(button:GetNormalTexture(), button, width)
    PlaceIcon(button:GetPushedTexture(), button, width)
    PlaceIcon(button:GetDisabledTexture(), button, width)
    PlaceIcon(button.FlashContent, button, width)

    local highlight = button:GetHighlightTexture()
    if highlight then
        local r, g, b = st.config.profile.colors.button.hover:GetRGB()
        highlight:SetColorTexture(r, g, b, HOVER_ALPHA)
        -- LoadMicroButtonTextures tints it for a guild tabard
        highlight:SetVertexColor(1, 1, 1)
        highlight:SetBlendMode('BLEND')
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
        portrait:SetTexCoord(GetPortraitCoords(width - inset * 2, BUTTON_HEIGHT - inset * 2))
    end
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
end

-- The bar item that takes the button's slot. The button's own panel (below)
-- draws under its art, so the holder has no backdrop and only reserves space.
local function CreateHolder(button)
    local holder = CreateFrame('Frame', nil, MicroMenu.Container)
    holder.width = st:RoundToPixel(BUTTON_HEIGHT * BUTTON_RATIO, MicroMenu.Container)
    holder:SetShown(button:IsShown())
    holders[button] = holder
    return holder
end

local function SkinButton(button)
    CreateHolder(button)

    local offset = st.config.profile.templates[TEMPLATE].thick and 2 or 1
    local skin = st:CreateFrame('Frame', nil, button)
    skin:SetPoint('TOPLEFT', button, 'TOPLEFT', -offset, offset)
    skin:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', offset, -offset)
    -- Blizzard halves a disabled button's alpha; dim the icon, not the panel
    skin:SetIgnoreParentAlpha(true)
    st:SetTemplate(skin, TEMPLATE)
    skins[button] = skin
    UpdateSkinLevel(button)

    -- Blizzard only Show/Hides these, so alpha 0 sticks
    for _, region in pairs({ button.Background, button.Shadow, button.PushedShadow, button.MainMenuBarPerformanceBar }) do
        region:SetAlpha(0)
    end

    -- Blizzard shows this while the button's frame is open; reuse it as a flat fill
    if button.PushedBackground then
        local r, g, b = st.config.profile.colors.button.pushed:GetRGB()
        button.PushedBackground:SetColorTexture(r, g, b, PUSHED_ALPHA)
        button.PushedBackground:ClearAllPoints()
        button.PushedBackground:SetAllPoints(button)
    end

    -- The alert pulse (UIFrameFlash) and the journal's new-content notice only
    -- show/hide and fade this, so a flat color sticks. Behind the icon it lights
    -- up the panel; over the portrait it has to stay on top to be seen.
    if button.FlashBorder then
        local r, g, b = st.config.profile.colors.text.yellow:GetRGB()
        button.FlashBorder:SetColorTexture(r, g, b, ALERT_ALPHA)
        if not button.Portrait then
            button.FlashBorder:SetDrawLayer('BACKGROUND', 1)
        end
    end

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

    -- Every Blizzard atlas swap (LoadMicroButtonTextures, SetNormal/SetPushed,
    -- the game menu button's once-a-second streaming update) ends here.
    hooksecurefunc(button, 'SetHighlightAtlas', StyleTextures)

    -- Blizzard hides the icon on hover because its mouseover art redraws it;
    -- our highlight is a tint, so keep the icon.
    button:HookScript('OnEnter', function(self)
        local normal = self:GetNormalTexture()
        if normal then normal:SetAlpha(1) end
    end)

    -- Blizzard re-runs MicroMenu:Layout on show/hide only while the menu sits
    -- in its container, not in a vehicle or pet battle bar.
    button:HookScript('OnShow', Refresh)
    button:HookScript('OnHide', Refresh)

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

    -- Forever's frame art around the whole menu
    if menu.BorderArt then menu.BorderArt:SetAlpha(0) end
    if menu.BackgroundArt then menu.BackgroundArt:SetAlpha(0) end

    for _, button in ipairs(buttons) do
        SkinButton(button)
        local holder = holders[button]
        self:AddButton(holder, { width = holder.width, template = 'none' })
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
    if MicroMenuContainer and MicroMenuContainer.Selection then
        MicroMenuContainer.Selection:HookScript('OnShow', function(selection)
            selection:Hide()
        end)
    end
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
    for _, button in ipairs(buttons) do
        local holder = holders[button]
        if holder then
            button:SetScale(scale)
            button:SetSize(holder.width, BUTTON_HEIGHT)
            button:ClearAllPoints()
            button:SetPoint('TOPLEFT', holder, 'TOPLEFT')

            UpdateSkinLevel(button)
            StyleTextures(button)
        end
    end
end
