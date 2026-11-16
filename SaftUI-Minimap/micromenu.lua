local st = SaftUI
local MicroMenu = st:NewModule('MicroMenu')
MicroMenu.Buttons = {}

-- The micro menu's files load in the TOC's order: this one (the module, the
-- bar's items and their entries, laying the bar out, a profile change and
-- OnEnable), micromenuart.lua (each item's panel and its art under the
-- Blizzard theme, and Forever's strip under the micro buttons),
-- micromenuitems.lua (SkinBarButton, and the mail and tracking items),
-- micromenuoptions.lua (the /sui page), then microbuttons.lua and the other
-- items' files.

local BUTTON_SIZE = 25
local BUTTON_SPACING = 8
-- Shared with micromenuart.lua, which centres an item's box in the row, and
-- microbuttons.lua, which sizes Blizzard's micro buttons to the bar
MicroMenu.BUTTON_SIZE = BUTTON_SIZE

-- Taint: most bar items are Blizzard frames (the zone text, the addon
-- compartment, tracking, the expansion button, mail and the queue eye).
-- Nothing in these files writes a Lua field onto them. Each item's SaftUI data
-- lives in this weak table, its backdrop is a SaftUI frame, and Blizzard
-- regions are only changed through widget methods. Every hook on a Blizzard
-- frame or function is a post-hook (HookScript, hooksecurefunc, SecureHook):
-- Blizzard's own handler runs first and untainted, and SaftUI re-applies its
-- state after.
local items = setmetatable({}, { __mode = 'k' }) -- bar item -> its settings, its panel and its art

-- MicroMenu.S: what the micro menu's files share with each other and nothing
-- else; not an API. items is set here (a table that is only filled), and
-- micromenuart.lua sets UpdateBackdrop and UpdateStrip, which UpdateButtons
-- calls through S as it runs.
local S = { items = items }
MicroMenu.S = S

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

            S.UpdateBackdrop(button, item, microbar)

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
    S.UpdateStrip(self.Container, firstMicro, lastMicro, microbar.strip)

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

-- Places the bar from the profile and lays its buttons out again. Runs on every
-- profile change. Blizzard's micro buttons and bar pieces hang off the bar, so
-- in combat this waits until combat ends.
function MicroMenu:UpdateConfig()
    if not self.Container then return end
    if st:QueueAfterCombat('MicroMenu', function() MicroMenu:UpdateConfig() end) then return end

    st:PlaceAtPosition(self.Container, self.config.position)
    self:UpdateButtons()
end

-- A color changed (st:ColorChanged): Blizzard's micro buttons' hover, pushed fill and
-- alert flash (Buttons > Hover and Pushed, Text > Caution: MicroMenu:ColorMicroButtons),
-- and the instance difficulty badge's (Item quality 1, 3 and 4). The other
-- items' textures are followers (st:FollowColor). Color only: it runs in combat.
function MicroMenu:OnColorsChanged(group, key)
    if group == 'button' then
        if key == nil or key == 'hover' or key == 'pushed' then
            self:ColorMicroButtons(key)
        end
    elseif group == 'text' then
        if key == nil or key == 'caution' then
            self:ColorMicroButtons(key)
        end
    elseif group == 'item_quality' then
        if key == nil or key == 1 or key == 3 or key == 4 then
            self:ColorDifficulty()
        end
    end
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

    self:RegisterMicroMenuMover()
end

-- The bar's edit mode mover: a method of its own so the tests' reset walk
-- registers the real one.
function MicroMenu:RegisterMicroMenuMover()
    st:RegisterConfigMover(self.Container, {
        key = 'micromenu',
        label = 'Micro Menu',
        config = function() return self.config end,
        apply = function() MicroMenu:UpdateConfig() end,
        configPath = { 'MicroMenu', 'general' },
        module = 'Minimap',
        defaults = function() return st.defaults.micromenu end,
    })
end
