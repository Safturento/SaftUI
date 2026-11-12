local st = SaftUI
local MicroMenu = st:NewModule('MicroMenu')
MicroMenu.Buttons = {}

local BUTTON_SIZE = 25
local BUTTON_SPACING = 8
-- Shared with microbuttons.lua, which sizes Blizzard's micro buttons to the bar
MicroMenu.BUTTON_SIZE = BUTTON_SIZE

-- Taint: most bar items are Blizzard frames (the zone text, the addon
-- compartment, tracking, the expansion button, mail and the queue eye).
-- Nothing here writes a Lua field onto them. Each item's SaftUI data lives in
-- this weak table, its backdrop is a SaftUI frame, and Blizzard regions are
-- only changed through widget methods. Every hook on a Blizzard frame or
-- function is a post-hook (HookScript, hooksecurefunc, SecureHook): Blizzard's
-- own handler runs first and untainted, and SaftUI re-applies its state after.
--
-- Under the Blizzard theme the bar stands on Blizzard's minimap and micro menu
-- art (st.ThemeArt.Control('microbar')). Each item's box is drawn on its panel
-- (UpdateArt): on Forever one of Camelot's atlases (the header button behind
-- the zone, clock, latency and FPS, the addon indicator's square, the tracking
-- button), on retail the grey minimap button kit. On Forever the micro buttons
-- also stand on one strip, the action bar's frame (UpdateStrip). All of it is
-- textures of SaftUI's frames, kept in the items' entries and in this file:
-- nothing is drawn on, or kept on, Blizzard's bar items or its micro menu,
-- whose own frame art stays faded (microbuttons.lua).
local items = setmetatable({}, { __mode = 'k' }) -- bar item -> its settings, its panel and its art

local function LayoutBar()
    MicroMenu:UpdateButtons()
end

-- Adds a frame to the end of the bar. options (all optional): width (default
-- BUTTON_SIZE), theme and background (its panel's, by default SaftUI's theme;
-- theme 'none' for no panel), text (a font string to center across the item),
-- art (the box it stands on under Blizzard, a key of Control('microbar'):
-- 'header', 'square' (the default) or 'tracking'), icon (a texture of SaftUI's
-- on the item, hidden while its art has an icon drawn in) and micro (true for
-- a Blizzard micro button's holder, which stands on the strip).
function MicroMenu:AddButton(button, options)
    if not button then return end
    tinsert(self.Buttons, button)
    items[button] = options or {}

    -- The bar closes up around items that come and go. HookScript is a
    -- post-hook: Blizzard's own OnShow/OnHide run first and untainted.
    -- AceHook's HookScript would replace the script with a SaftUI closure, and
    -- Blizzard's handler would then run inside it.
    button:HookScript('OnShow', LayoutBar)
    button:HookScript('OnHide', LayoutBar)
end

-- st:SkinButton's look for a Blizzard button: SaftUI's font, Blizzard's art
-- faded out, and flat hover, pushed and disabled textures. st:SkinButton
-- itself stores those (and a backdrop) on the button as fields, so it's only
-- for SaftUI's own buttons. The bar draws the backdrop.
local skinned = setmetatable({}, { __mode = 'k' })
function MicroMenu:SkinBarButton(button)
    if skinned[button] then return end
    skinned[button] = true

    local font = st:GetFont('pixel')
    if button.SetNormalFontObject then
        button:SetNormalFontObject(font)
        button:SetHighlightFontObject(font)
        button:SetDisabledFontObject(font)
        button:SetPushedTextOffset(0, 0)
    end

    for _, region in pairs({ button:GetRegions() }) do
        if region:GetObjectType() == 'Texture' then
            region:SetAlpha(0)
        end
    end
    button:SetNormalTexture('')

    local colors = st.config.profile.colors.button

    local hover = button:CreateTexture(nil, 'OVERLAY')
    hover:SetTexture(st.BLANK_TEX)
    hover:SetVertexColor(colors.normal:GetRGB())
    hover:SetAllPoints(button)
    button:SetHighlightTexture(hover)

    local pushed = button:CreateTexture(nil, 'OVERLAY')
    pushed:SetTexture(st.BLANK_TEX)
    pushed:SetVertexColor(colors.pushed:GetRGB())
    pushed:SetAllPoints(button)
    button:SetPushedTexture(pushed)

    local disabled = button:CreateTexture(nil, 'OVERLAY')
    disabled:SetTexture(st.BLANK_TEX)
    disabled:SetVertexColor(0, 0, 0, .4)
    disabled:SetAllPoints(button)
    button:SetDisabledTexture(disabled)
end

-- The item's box under Blizzard, on its panel: on Forever one atlas, set whole
-- (the engine slices it), at its own height centred in the row, and either its
-- own width centred on the item or the item's width; on retail the kit, on the
-- panel's rect, which under Blizzard is the item's (a control's inset is 0).
-- The texture and the kit's pieces are the panel's, kept in the item's entry
-- (artTexture, pieces), each made the first time it's needed; whichever isn't
-- drawn hides, and under another look both do. The panel is one level under
-- the item, so the item's own art, text and hover draw over the box. The
-- item's icon hides while the box has its icon drawn in. microbar is
-- Control('microbar'), read once a layout pass (it's a fresh copy each call).
local function UpdateArt(item, microbar)
    local panel = item.backdrop
    local art = panel and st:IsBlizzardLook(item.theme or 'theme', item.background or 'theme')
        and microbar[item.art or 'square']

    if art and art.atlas then
        local texture = item.artTexture
        if not texture then
            texture = panel:CreateTexture(nil, 'ARTWORK')
            item.artTexture = texture
        end
        texture:SetAtlas(art.atlas)
        texture:ClearAllPoints()
        local top = -math.floor((BUTTON_SIZE - art.height) / 2)
        if art.width then
            local left = math.floor(((item.width or BUTTON_SIZE) - art.width) / 2)
            texture:SetSize(art.width, art.height)
            texture:SetPoint('TOPLEFT', panel, 'TOPLEFT', left, top)
        else
            texture:SetPoint('TOPLEFT', panel, 'TOPLEFT', 0, top)
            texture:SetPoint('TOPRIGHT', panel, 'TOPRIGHT', 0, top)
            texture:SetHeight(art.height)
        end
        texture:Show()
    elseif item.artTexture then
        item.artTexture:Hide()
    end

    -- Only ever laid with the kit, so no other border's pieces are left in it
    if art and art.kit then
        item.pieces = item.pieces or {}
        st.ThemeArt.LayBorder(item.pieces, panel, art.kit)
    elseif item.pieces then
        st.ThemeArt.HidePieces(item.pieces)
    end

    if item.icon then
        item.icon:SetShown(not (art and art.icon))
    end
end

-- The item's panel: a SaftUI frame kept in its entry, drawn as a control: a
-- small frame under Thick and Thin, and under Blizzard nothing of its own, the
-- box UpdateArt draws on it. st:SetBackdrop would store it on the item as
-- .backdrop (and .thick). It's a child of the item, so it shows and hides with
-- it, one frame level down so it draws under the item's own art.
local function UpdateBackdrop(button, item, microbar)
    local theme, background = item.theme or 'theme', item.background or 'theme'
    if theme == 'none' then
        if item.backdrop then
            st:SetTemplate(item.backdrop, 'none', background, 'control')
            UpdateArt(item, microbar)
        end
        return
    end

    if not item.backdrop then
        item.backdrop = st:CreateFrame('Frame', nil, button)
    end
    local backdrop = item.backdrop

    local level = button:GetFrameLevel()
    if not issecretvalue(level) then
        backdrop:SetFrameLevel(math.max(0, level - 1))
    end

    st:SetTemplate(backdrop, theme, background, 'control')
    local offset = st:ThemeInset(theme, background, 'control')
    backdrop:ClearAllPoints()
    backdrop:SetPoint('TOPLEFT', button, 'TOPLEFT', -offset, offset)
    backdrop:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', offset, -offset)

    UpdateArt(item, microbar)
end

-- The strip under the micro buttons on Forever, a frame of SaftUI's made the
-- first time it shows, and its two textures (MicroMenu:GetStrip).
local strip, stripFrame, stripBackground

-- Under SaftUI's Blizzard look on Forever (art is Control('microbar').strip,
-- false on retail), the strip shows under the shown micro buttons, from the
-- first one's holder to the last's (first, last), art.pad outside them: the
-- action bar's frame over it all, its icon background art.backgroundInset in.
-- Otherwise, or with no micro button shown, it hides. Blizzard's own art
-- (MicroMenu.BorderArt and BackgroundArt) stays faded: its background
-- overhangs the frame far enough to reach the boxes beside the buttons, and
-- MicroMenu holds Blizzard's buttons. The strip is a child of the bar's
-- Container at the Container's level, so it lies under the holders and under
-- Blizzard's buttons over them. It is deliberately left unprotected: nothing
-- secure is anchored to it or in it, so the game never protects it, and the
-- move, which still goes through st:SafeReposition as the bar's moves do,
-- always runs at once, so the strip follows the buttons in combat too.
local function UpdateStrip(container, first, last, art)
    if not (art and first and st:IsBlizzardLook('theme', 'theme')) then
        if strip then strip:Hide() end
        return
    end

    if not strip then
        strip = CreateFrame('Frame', nil, container)
        stripFrame = strip:CreateTexture(nil, 'BORDER')
        stripFrame:SetAllPoints(strip)
        stripBackground = strip:CreateTexture(nil, 'BACKGROUND')
    end
    stripFrame:SetAtlas(art.frame)
    stripBackground:SetAtlas(art.background)
    local inset = art.backgroundInset
    stripBackground:ClearAllPoints()
    stripBackground:SetPoint('TOPLEFT', strip, 'TOPLEFT', inset, -inset)
    stripBackground:SetPoint('BOTTOMRIGHT', strip, 'BOTTOMRIGHT', -inset, inset)

    local level = container:GetFrameLevel()
    if not issecretvalue(level) then
        strip:SetFrameLevel(level)
    end

    local pad = art.pad
    st:SafeReposition(strip, 'MicroMenu_strip', function()
        strip:ClearAllPoints()
        strip:SetPoint('TOPLEFT', first, 'TOPLEFT', -pad, pad)
        strip:SetPoint('BOTTOMRIGHT', last, 'BOTTOMRIGHT', pad, -pad)
    end)
    strip:Show()
end

function MicroMenu:UpdateButtons()
    -- Read once a pass: Control gives a fresh copy of the art each call
    local microbar = st.ThemeArt.Control('microbar')
    local prev, firstMicro, lastMicro
    local barWidth = 0
    for _, button in ipairs(self.Buttons) do
        if button:IsShown() then
            local item = items[button]
            local width = item.width or BUTTON_SIZE
            barWidth = barWidth + width + (prev and BUTTON_SPACING or 0)
            -- Reparent only once. Each SetParent that makes a Blizzard item visible runs
            -- its OnShow from SaftUI's call chain, so don't repeat it on every layout.
            if button:GetParent() ~= self.Container then
                button:SetParent(self.Container)
            end
            button:SetSize(width, BUTTON_SIZE)

            local text = item.text
            if text then
                text:SetFontObject(st:GetFont('pixel'))
                text:SetJustifyH('CENTER')
                -- Clear Blizzard's anchors (the zone text is LEFT-anchored with a
                -- fixed width) so the text spans the button and centers properly
                text:ClearAllPoints()
                text:SetPoint('LEFT', button, 'LEFT', 4, 0)
                text:SetPoint('RIGHT', button, 'RIGHT', -4, 0)
            end

            UpdateBackdrop(button, item, microbar)

            -- The widget API's own methods: Forever's queue eye is an Edit Mode
            -- system, whose Lua SetPoint/ClearAllPoints write Edit Mode state.
            st:ClearAllPointsDirect(button)
            if prev then
                st:SetPointDirect(button, 'TOPLEFT', prev, 'TOPRIGHT', BUTTON_SPACING, 0)
            else
                st:SetPointDirect(button, 'TOPLEFT', self.Container)
            end

            if item.micro then
                firstMicro = firstMicro or button
                lastMicro = button
            end
            prev = button
        end
    end

    -- Blizzard's micro buttons sit over their holders, laid out above
    self:UpdateBlizzardButtons()
    UpdateStrip(self.Container, firstMicro, lastMicro, microbar.strip)

    self.barWidth = barWidth
    self:SizeContainer()
end

-- Sizes the container to the bar's real extent (from SaftUI's own item widths,
-- not frame geometry), so edit mode's overlay covers the whole bar. The items
-- are anchored to the container's top left corner, so its size moves nothing.
-- A bar item can have a protected Blizzard button anchored to it, which makes
-- the container protected too; then the size waits for the end of combat.
function MicroMenu:SizeContainer()
    st:SafeReposition(self.Container, 'MicroMenu_size', function()
        -- Read when it runs, so a deferred size uses the latest layout. Whole
        -- pixels, and never empty so the overlay can still be grabbed.
        local w = math.max(st:RoundToPixel(self.barWidth or 0, self.Container), BUTTON_SIZE)
        self.Container:SetSize(w, BUTTON_SIZE)
    end)
end

-- The item's box under Blizzard (UpdateArt): its atlas texture and its kit's
-- pieces, each nil until it's first needed. For tests.
function MicroMenu:GetItemArt(button)
    local item = items[button]
    if not item then return nil end
    return item.artTexture, item.pieces
end

-- The strip under the micro buttons (UpdateStrip), nil until it first shows,
-- with its frame texture and its background. For tests.
function MicroMenu:GetStrip()
    return strip, stripFrame, stripBackground
end

function MicroMenu:SkinMailIcon()

    local button = MinimapCluster.IndicatorFrame.MailFrame

    MiniMapMailIcon:SetTexture(st.textures.mailSquare)
    MiniMapMailIcon:SetAllPoints(button)

    return button
end

function MicroMenu:SkinTrackingButton()
    local button = MinimapCluster.TrackingFrame or MinimapCluster.Tracking
    button.Button:SetAllPoints()

    for _,texture in pairs({
        button.Button:GetNormalTexture(),
        button.Button:GetPushedTexture(),
        button.Button:GetHighlightTexture()
    }) do
        texture:ClearAllPoints()
        texture:SetPoint("CENTER")
        texture:SetSize(16, 16)
    end

    -- Forever draws the icon as a single atlas with a gold ring baked in, and
    -- re-applies it on every button state change. Hide it and its hover copy,
    -- and draw a plain magnifier instead.
    local trackingButton = button.Button
    local icon
    if trackingButton.StateTexture then
        trackingButton.StateTexture:SetAlpha(0)
        trackingButton.AddTexture:SetAlpha(0)
        hooksecurefunc(trackingButton, 'OnButtonStateChanged', function(self)
            self.AddTexture:Hide()
        end)

        icon = trackingButton:CreateTexture(nil, 'ARTWORK')
        icon:SetTexture([[Interface\Minimap\Tracking\None]])
        icon:SetPoint('CENTER')
        icon:SetSize(16, 16)

        local hover = trackingButton:CreateTexture(nil, 'OVERLAY')
        hover:SetTexture(st.BLANK_TEX)
        hover:SetVertexColor(st.config.profile.colors.button.hover:GetRGB())
        hover:SetAllPoints(trackingButton)
        trackingButton:SetHighlightTexture(hover)
    end

    -- Under Blizzard it stands on Blizzard's tracking button (UpdateArt).
    -- Forever's has the magnifier drawn in, so SaftUI's hides there. Live
    -- has no magnifier of SaftUI's: Blizzard's own icon shows on its box.
    return button, { art = 'tracking', icon = icon }
end

-- Places the bar from the profile and lays its buttons out again. Runs on every
-- profile change. Blizzard's micro buttons and bar pieces hang off the bar, so
-- in combat this waits until combat ends.
function MicroMenu:UpdateConfig()
    if not self.Container then return end
    if st:QueueAfterCombat('MicroMenu', function() MicroMenu:UpdateConfig() end) then return end

    st:PlaceAtPosition(self.Container, self.config.position)
    self:UpdateButtons()
end

-- The micro menu's section in the /sui tree: General, with the Position
-- option last. Clicking the bar in edit mode selects its General group (the
-- mover's configPath).
function MicroMenu:GetConfigTable()
    -- Getters and setters go through self.config, which a profile change
    -- re-points at the new profile's table.
    local position = st.Config.generators.position(1000, true,
        function(key) return self.config.position[key] end,
        function(key, value)
            self.config.position[key] = value
            self:UpdateConfig()
        end,
        self.Container
    )
    return {
        name = 'Micro Menu',
        type = 'group',
        category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
        childGroups = 'tab',
        args = {
            general = {
                name = 'General',
                type = 'group',
                order = 1,
                args = {
                    about = {
                        order = 1,
                        type = 'description',
                        fontSize = 'medium',
                        name = 'The bar of info buttons and Blizzard\'s micro menu buttons. ' ..
                            'Use the Position section, or drag it in edit mode, to move it.',
                    },
                    position = position,
                },
            },
        },
    }
end

function MicroMenu:OnEnable()
    st:BindModuleConfig(self, 'micromenu')
    self.Container = CreateFrame('Frame', 'SaftUI_MicroMenu', UIParent)
    st:PlaceAtPosition(self.Container, self.config.position)
    -- Sized to the bar by UpdateButtons
    self.Container:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    -- No-op to ignore Layout calls for buttons like mail icon
    self.Container.Layout = function() end

    self:KillBlizz()
    self:AddButton(self:SkinZoneTextButton())
    self:AddButton(self:SkinTimeManagerClockButton())
    self:AddButton(self:CreateLatencyButton())
    self:AddButton(self:CreateFramerateButton())
    -- Adds a holder per Blizzard micro button at this spot. The items before
    -- them don't come and go, so the micro buttons stay put while mail, the
    -- queue eye and the like appear after them.
    self:SkinBlizzardMicroMenu()
    self:AddButton(self:SkinAddonCompartmentFrame())
    self:AddButton(self:SkinTrackingButton())
    self:AddButton(self:SkinExpansionButton())
    self:AddButton(self:SkinMailIcon())
    self:AddButton(self:SkinInstanceDifficulty())
    self:AddButton(self:SkinQueueButton())

    -- Forever's MinimapCluster:SetHeaderUnderneath (run by Blizzard's Edit
    -- Mode) re-anchors the zone text and the addon compartment to the cluster,
    -- which pulls them out of the bar. Put them back after it.
    if MinimapCluster.SetHeaderUnderneath then
        hooksecurefunc(MinimapCluster, 'SetHeaderUnderneath', LayoutBar)
    end

    self:UpdateButtons()
    self:SetupMinimapButtons()

    st:RegisterConfigMover(self.Container, {
        key = 'micromenu',
        label = 'Micro Menu',
        config = function() return self.config end,
        apply = function() MicroMenu:UpdateConfig() end,
        configPath = { 'MicroMenu', 'general' },
    })
end
