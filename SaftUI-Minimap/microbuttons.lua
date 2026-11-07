local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

-- Restyles Blizzard's micro menu as a second row of SaftUI's micro menu,
-- spanning the bar's width directly under it.
--
-- Taint: MicroMenuContainer is an Edit Mode system frame, and MicroMenu and its
-- buttons belong to Blizzard. Nothing here writes a Lua field onto them. Our
-- per-button state lives in local tables, our art lives on frames we create,
-- and Blizzard's regions are only changed through widget methods. Blizzard
-- re-applies its art and layout often, so we re-apply after it with
-- hooksecurefunc and HookScript. No Blizzard Lua function is ever called from
-- here, so nothing Blizzard writes happens under our taint.
--
-- The buttons stay parented to MicroMenu, so Blizzard's own scripts, alerts,
-- notification pips and vehicle/pet battle handling keep working. Blizzard
-- still runs MicroMenu:Layout, and the post-hook moves the buttons afterwards.

local BUTTON_HEIGHT = MicroMenu.BUTTON_SIZE
local SPACING = MicroMenu.BUTTON_SPACING
local MIN_WIDTH = 20
local TEMPLATE = 'thicktransparent'

-- Blizzard's icon atlases are 32x41, with the glyph (at most 22x28) centered in
-- transparent padding. Drawn at 22x28 the glyph is about 19px tall, which
-- leaves a 3px margin in a 25px button. Keeping the atlas's own aspect means no
-- texcoord crop, which Blizzard would undo every time it swaps an atlas.
local ICON_WIDTH, ICON_HEIGHT = 22, 28
local ICON_TOP = math.ceil((ICON_HEIGHT - BUTTON_HEIGHT) / 2)
-- The guild emblem sits on the tabard glyph at 12x14; scaled with the icon.
local EMBLEM_WIDTH, EMBLEM_HEIGHT = 8, 10

local HOVER_ALPHA = 0.4
local PUSHED_ALPHA = 0.6
local ALERT_ALPHA = 0.5

local buttons = {} -- Blizzard's micro buttons, in Blizzard's order
local shown = {}
local skins = setmetatable({}, { __mode = 'k' }) -- button -> SaftUI backdrop
local widths = setmetatable({}, { __mode = 'k' }) -- button -> width we gave it

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
    local width = widths[button] or BUTTON_HEIGHT

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

local function SkinButton(button)
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

    -- Shown/hidden buttons only re-run MicroMenu:Layout while the menu sits in
    -- its container, not in a vehicle or pet battle bar.
    button:HookScript('OnShow', function() MicroMenu:UpdateBlizzardButtons() end)
    button:HookScript('OnHide', function() MicroMenu:UpdateBlizzardButtons() end)

    StyleTextures(button)
end

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
    end

    -- Layout re-anchors the buttons into Blizzard's grid; UpdateScale follows
    -- Edit Mode's size and the vehicle/pet battle scale override.
    hooksecurefunc(menu, 'Layout', function() self:UpdateBlizzardButtons() end)
    if menu.UpdateScale then
        hooksecurefunc(menu, 'UpdateScale', function() self:UpdateBlizzardButtons() end)
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

-- Lays the shown buttons out in one row under SaftUI's bar, splitting the bar's
-- width between them. Sizes and offsets come from SaftUI's own numbers, never
-- from Blizzard frame geometry; the scale and frame level reads are guarded
-- for secret values.
function MicroMenu:UpdateBlizzardButtons()
    local menu = _G.MicroMenu
    if not (menu and self.barWidth and #buttons > 0) then return end

    wipe(shown)
    for _, button in ipairs(buttons) do
        if button:IsShown() then
            tinsert(shown, button)
        end
    end
    local count = #shown
    if count == 0 then return end

    local available = self.barWidth - SPACING * (count - 1)
    local width = math.floor(available / count)
    local remainder = available - width * count
    if width < MIN_WIDTH then
        width, remainder = MIN_WIDTH, 0
    end

    -- The buttons inherit MicroMenu's scale (Edit Mode size, vehicle override);
    -- cancel it so they match the bar.
    local scale = 1
    local menuScale, barScale = menu:GetEffectiveScale(), self.Container:GetEffectiveScale()
    if not issecretvalue(menuScale) and not issecretvalue(barScale) and menuScale > 0 then
        scale = barScale / menuScale
    end

    local prev
    for i, button in ipairs(shown) do
        local buttonWidth = width + (i <= remainder and 1 or 0)
        widths[button] = buttonWidth

        button:SetScale(scale)
        button:SetSize(buttonWidth, BUTTON_HEIGHT)
        button:ClearAllPoints()
        if prev then
            button:SetPoint('TOPLEFT', prev, 'TOPRIGHT', SPACING, 0)
        else
            button:SetPoint('TOPLEFT', self.Container, 'TOPLEFT', 0, -(BUTTON_HEIGHT + SPACING))
        end

        UpdateSkinLevel(button)
        StyleTextures(button)
        prev = button
    end
end
