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
local items = setmetatable({}, { __mode = 'k' }) -- bar item -> its settings

local function LayoutBar()
    MicroMenu:UpdateButtons()
end

-- Adds a frame to the end of the bar. options (all optional): width (default
-- BUTTON_SIZE), template (the backdrop template, default thicktransparent;
-- 'none' for no backdrop) and text (a font string to center across the item).
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

-- The item's panel: a SaftUI frame kept in its entry. st:SetBackdrop would
-- store it on the item as .backdrop (and .thick). It's a child of the item, so
-- it shows and hides with it, one frame level down so it draws under the
-- item's own art.
local function UpdateBackdrop(button, item)
    local template = item.template or 'thicktransparent'
    if template == 'none' then
        if item.backdrop then st:SetTemplate(item.backdrop, 'none') end
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

    st:SetTemplate(backdrop, template)
    local offset = st.config.profile.templates[template].thick and 2 or 1
    backdrop:ClearAllPoints()
    backdrop:SetPoint('TOPLEFT', button, 'TOPLEFT', -offset, offset)
    backdrop:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', offset, -offset)
end

function MicroMenu:UpdateButtons()
    local prev
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

            UpdateBackdrop(button, item)

            -- The widget API's own methods: Forever's queue eye is an Edit Mode
            -- system, whose Lua SetPoint/ClearAllPoints write Edit Mode state.
            st:ClearAllPointsDirect(button)
            if prev then
                st:SetPointDirect(button, 'TOPLEFT', prev, 'TOPRIGHT', BUTTON_SPACING, 0)
            else
                st:SetPointDirect(button, 'TOPLEFT', self.Container)
            end

            prev = button
        end
    end

    -- Blizzard's micro buttons sit over their holders, laid out above
    self:UpdateBlizzardButtons()

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

function MicroMenu:SkinMailIcon()

    local button = st.retail and MinimapCluster.IndicatorFrame.MailFrame or MiniMapMailFrame

    -- Classic's border and position function; retail and Forever have neither
    if not st.retail then
        st:Kill(MiniMapMailBorder)
        MiniMapMailFrame_UpdatePosition = function() end
    end

    MiniMapMailIcon:SetTexture(st.textures.mailSquare)
    MiniMapMailIcon:SetAllPoints(button)

    return button
end

function MicroMenu:SkinTrackingButton()
    if st.retail then
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
        if trackingButton.StateTexture then
            trackingButton.StateTexture:SetAlpha(0)
            trackingButton.AddTexture:SetAlpha(0)
            hooksecurefunc(trackingButton, 'OnButtonStateChanged', function(self)
                self.AddTexture:Hide()
            end)

            local icon = trackingButton:CreateTexture(nil, 'ARTWORK')
            icon:SetTexture([[Interface\Minimap\Tracking\None]])
            icon:SetPoint('CENTER')
            icon:SetSize(16, 16)

            local hover = trackingButton:CreateTexture(nil, 'OVERLAY')
            hover:SetTexture(st.BLANK_TEX)
            hover:SetVertexColor(st.config.profile.colors.button.hover:GetRGB())
            hover:SetAllPoints(trackingButton)
            trackingButton:SetHighlightTexture(hover)
        end

        return button
    else
        local button = MiniMapTracking
        MiniMapTrackingButton:SetAllPoints(button)
        st:Kill(MiniMapTrackingButtonBorder)
        st:Kill(MiniMapTrackingBackground)
        MiniMapTrackingIcon:ClearAllPoints()
        MiniMapTrackingIcon:SetAllPoints(button)

        local hover = MiniMapTrackingButton:CreateTexture(nil, 'OVERLAY')
        hover:SetTexture(st.BLANK_TEX)
        hover:SetVertexColor(st.config.profile.colors.button.hover:GetRGB())
        hover:SetAllPoints(MiniMapTrackingButton)
        MiniMapTrackingButton:SetHighlightTexture(hover)

        return button
    end
end

-- Places the bar from the profile and lays its buttons out again. Runs on every
-- profile change. Blizzard's micro buttons and bar pieces hang off the bar, so
-- in combat this waits until combat ends.
function MicroMenu:UpdateConfig()
    if not self.Container then return end
    if st:QueueAfterCombat('MicroMenu', function() MicroMenu:UpdateConfig() end) then return end

    self.Container:ClearAllPoints()
    self.Container:SetPoint(st:UnpackPoint(self.config.position))
    self:UpdateButtons()
end

-- The micro menu's section in the /sui tree. Clicking the bar in edit mode
-- selects its General group (the mover's configPath).
function MicroMenu:GetConfigTable()
    -- Getters and setters go through self.config, which a profile change
    -- re-points at the new profile's table.
    local position = st.Config.generators.position(2, true,
        function(key) return self.config.position[key] end,
        function(key, value)
            self.config.position[key] = value
            self:UpdateConfig()
        end,
        self.Container
    )
    position.inline = false -- a tree section, not an inline box
    return {
        name = 'Micro Menu',
        type = 'group',
        category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
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
                },
            },
            position = position,
        },
    }
end

function MicroMenu:OnEnable()
    st:BindModuleConfig(self, 'micromenu')
    self.Container = CreateFrame('Frame', 'SaftUI_MicroMenu', UIParent)
    self.Container:SetPoint(st:UnpackPoint(self.config.position))
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

    st:RegisterMover('micromenu', {
        frame = self.Container,
        label = 'Micro Menu',
        getPosition = function() return self.config.position end,
        setPosition = function(pos) self.config.position = pos end,
        apply = function() MicroMenu:UpdateConfig() end,
        configPath = { 'MicroMenu', 'general' },
    })
end
