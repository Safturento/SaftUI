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

-- The bar's default height. The bar's height and its gap between items are
-- the profile's (height, spacing: MicroMenu:BarHeight, MicroMenu:Spacing);
-- micromenuart.lua centres an item's box in the row and microbuttons.lua sizes
-- Blizzard's micro buttons by MicroMenu:BarHeight.
local BUTTON_SIZE = 25
MicroMenu.BUTTON_SIZE = BUTTON_SIZE
-- The heights and gaps the options offer, and that a profile's value is held to
MicroMenu.HEIGHT_MIN, MicroMenu.HEIGHT_MAX = 16, 48
MicroMenu.SPACING_MIN, MicroMenu.SPACING_MAX = 0, 32
-- Blizzard's MainMenuBarMicroButton template is 32x40 on Forever and retail
-- (Blizzard_MicroMenu/Mainline/MainMenuBarMicroButtons.xml). Its buttons keep
-- that shape at the bar's height: 20x25 at the default.
local MICRO_RATIO = 32 / 40

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

local function Clamp(value, low, high, default)
    value = tonumber(value)
    if not value then return default end
    return math.min(math.max(math.floor(value + 0.5), low), high)
end

-- The bar's height: every item's, from the profile, whole pixels.
function MicroMenu:BarHeight()
    local config = self.config
    return Clamp(config and config.height, self.HEIGHT_MIN, self.HEIGHT_MAX, BUTTON_SIZE)
end

-- The gap between two items, from the profile.
function MicroMenu:Spacing()
    local config = self.config
    return Clamp(config and config.spacing, self.SPACING_MIN, self.SPACING_MAX, 8)
end

-- A Blizzard micro button's width at the bar's height (MICRO_RATIO).
function MicroMenu:MicroWidth()
    return st:RoundToPixel(self:BarHeight() * MICRO_RATIO, self.Container)
end

-- Whether the profile keeps an item off the bar (show[key] == false). An
-- item with no key is always on it.
function MicroMenu:IsTurnedOff(button)
    local item = items[button]
    local show = self.config and self.config.show
    return item and item.key and show and show[item.key] == false or false
end

-- The item's width: a micro button's from the bar's height, a text item's
-- from the profile's widths, else its own, else square.
local function ItemWidth(item, height)
    if item.micro then return MicroMenu:MicroWidth() end
    local widths = MicroMenu.config and MicroMenu.config.widths
    local width = item.key and widths and tonumber(widths[item.key])
    if width and width > 0 then return math.floor(width + 0.5) end
    return item.width or height
end
S.ItemWidth = ItemWidth

-- The text items' font, from the profile (a shared font's key or a typeface).
function MicroMenu:TextFont()
    return st:FontObject(self.config and self.config.font or 'pixel')
end

local function LayoutBar()
    MicroMenu:UpdateButtons()
end

-- Adds a frame to the end of the bar. options (all optional): key (the
-- item's name in the profile's show and widths tables), width (default
-- the bar's height, square; a key in widths wins), theme and background (its panel's, by default SaftUI's theme;
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
    local height, spacing = self:BarHeight(), self:Spacing()
    local font = self:TextFont()
    local prev, firstMicro, lastMicro
    local barWidth = 0
    for _, button in ipairs(self.Buttons) do
        -- An item turned off stays concealed where it is (S.Conceal), out of the row
        if button:IsShown() and not self:IsTurnedOff(button) then
            local item = items[button]
            local width = ItemWidth(item, height)
            barWidth = barWidth + width + (prev and spacing or 0)
            -- Reparent only once. Each SetParent that makes a Blizzard item visible runs
            -- its OnShow from SaftUI's call chain, so don't repeat it on every layout.
            if button:GetParent() ~= self.Container then
                button:SetParent(self.Container)
            end
            button:SetSize(width, height)

            local text = item.text
            if text then
                text:SetFontObject(font)
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
                st:SetPointDirect(button, 'TOPLEFT', prev, 'TOPRIGHT', spacing, 0)
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

-- The bar's buttons' labels (the zone text button's, the addon count's: the
-- buttons SkinBarButton skinned) take the text font too. Font objects only,
-- so in combat too. micromenuitems.lua sets it.
S.ApplyButtonFonts = S.ApplyButtonFonts or function() end

-- A font changed (st:FontsChanged): the item texts and the bar buttons' labels
-- take the text font again. A shared font's object is the same object and
-- already shows the change; a typeface is a new object. Font objects only.
function MicroMenu:OnFontsChanged()
    if not self.Container then return end
    local font = self:TextFont()
    for _, button in ipairs(self.Buttons) do
        local text = items[button] and items[button].text
        if text then text:SetFontObject(font) end
    end
    S.ApplyButtonFonts(font)
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
        local height = self:BarHeight()
        local w = math.max(st:RoundToPixel(self.barWidth or 0, self.Container), height)
        self.Container:SetSize(w, height)
    end)
end

-- Places the bar from the profile and lays its buttons out again. Runs on every
-- profile change. Blizzard's micro buttons and bar pieces hang off the bar, so
-- in combat this waits until combat ends.
function MicroMenu:UpdateConfig()
    if not self.Container then return end
    if st:QueueAfterCombat('MicroMenu', function() MicroMenu:UpdateConfig() end) then return end

    st:PlaceAtPosition(self.Container, self.config.position)
    self:UpdateConcealed()
    self:UpdateButtons()
    S.ApplyButtonFonts(self:TextFont())
    self:UpdateFade()
end

-- Conceals the items the profile turns off and shows the rest again
-- (micromenuart.lua's S.Conceal). Out of combat only: UpdateConfig, which
-- waits for the end of combat, and OnEnable call it.
function MicroMenu:UpdateConcealed()
    for _, button in ipairs(self.Buttons) do
        S.Conceal(button, items[button], self:IsTurnedOff(button))
    end
end

-- A color changed (st:ColorChanged): Blizzard's micro buttons' alert flash (Text >
-- Caution: MicroMenu:ColorMicroButtons), and the instance difficulty badge's (Item
-- quality 1, 3 and 4). Every item's states (hover, pushed, the open window) are
-- the state helper's, which follows the Accent itself. Color only: it runs in
-- combat.
function MicroMenu:OnColorsChanged(group, key)
    if group == 'text' then
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
    self.Container:SetSize(self:BarHeight(), self:BarHeight())
    -- No-op to ignore Layout calls for buttons like mail icon
    self.Container.Layout = function() end

    -- Each item under its key in the profile's show and widths tables
    local function Add(key, button, options)
        if not button then return end
        options = options or {}
        options.key = key
        self:AddButton(button, options)
    end

    self:KillBlizz()
    Add('zone', self:SkinZoneTextButton())
    Add('clock', self:SkinTimeManagerClockButton())
    Add('latency', self:CreateLatencyButton())
    Add('fps', self:CreateFramerateButton())
    -- Adds a holder per Blizzard micro button at this spot. The items before
    -- them don't come and go, so the micro buttons stay put while mail, the
    -- queue eye and the like appear after them.
    self:SkinBlizzardMicroMenu()
    Add('addons', self:SkinAddonCompartmentFrame())
    Add('tracking', self:SkinTrackingButton())
    Add('expansion', self:SkinExpansionButton())
    Add('mail', self:SkinMailIcon())
    Add('difficulty', self:SkinInstanceDifficulty())
    Add('queue', self:SkinQueueButton())

    -- Forever's MinimapCluster:SetHeaderUnderneath (run by Blizzard's Edit
    -- Mode) re-anchors the zone text and the addon compartment to the cluster,
    -- which pulls them out of the bar. Put them back after it.
    if MinimapCluster.SetHeaderUnderneath then
        hooksecurefunc(MinimapCluster, 'SetHeaderUnderneath', LayoutBar)
    end

    self:UpdateConcealed()
    self:UpdateButtons()
    S.ApplyButtonFonts(self:TextFont())
    self:UpdateFade()
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

--- Turning items off -----------------------------------------------------------

-- An item the profile turns off is concealed, never hidden: most items are
-- Blizzard's, and Hide or SetParent would run their OnHide in SaftUI's call
-- chain (.agents/taint.md, rules 4 and 8). Concealed, it draws nothing and
-- takes no mouse, but keeps its shown state, its parent and its scripts:
-- alpha 0 and the mouse off on it and on its children that took the mouse,
-- through the widget methods (getmetatable(frame).__index), so Blizzard's
-- frames get nothing written onto them. Each frame's own mouse state is kept
-- here and put back when the item shows again. A micro button's holder has no
-- art of its own: its Blizzard button is concealed by microbuttons.lua
-- (S.ConcealMicro). Out of combat only (MicroMenu:UpdateConcealed). An item
-- turned off at login is concealed before the bar's first layout, so it's
-- never reparented into the bar and stays where Blizzard keeps it, unseen;
-- turned on, the next layout takes it in. The mouse comes back with
-- EnableMouse(true), clicks and motion both (no bar item takes only one).
-- item -> { mouse = { [frame] = its mouse was on }, alpha = its alpha before }
local concealed = setmetatable({}, { __mode = 'k' })

local function Widget(frame, method, ...)
    return getmetatable(frame).__index[method](frame, ...)
end

local function TakeMouse(frame, kept)
    if Widget(frame, 'IsMouseEnabled') then
        kept[frame] = true
        Widget(frame, 'EnableMouse', false)
    end
    for _, child in ipairs({ frame:GetChildren() }) do
        TakeMouse(child, kept)
    end
end

function S.Conceal(button, item, off)
    if not item then return end
    if item.micro then
        if S.ConcealMicro then S.ConcealMicro(button, off) end
        return
    end
    local kept = concealed[button]
    if off and not kept then
        kept = { mouse = {}, alpha = button:GetAlpha() }
        concealed[button] = kept
        Widget(button, 'SetAlpha', 0)
        TakeMouse(button, kept.mouse)
    elseif not off and kept then
        concealed[button] = nil
        Widget(button, 'SetAlpha', kept.alpha)
        for frame in pairs(kept.mouse) do
            Widget(frame, 'EnableMouse', true)
        end
    end
end

-- Whether the item is concealed (S.Conceal). For tests.
function MicroMenu:IsConcealed(button)
    local item = items[button]
    if item and item.micro then return S.IsMicroConcealed and S.IsMicroConcealed(button) or false end
    return concealed[button] ~= nil
end

--- Mouseover fade --------------------------------------------------------------

-- Visibility 'mouseover': the bar sits at fade_alpha and goes to full while
-- the mouse is over it, the whole way in FADE_TIME, as the action bars'
-- (SaftUI-ActionBars/bars.lua). The bar is the Container (its items are its
-- children) and Blizzard's micro buttons, which stay Blizzard's MicroMenu's
-- children: MicroMenu takes the same alpha while it's in its own container
-- (not a vehicle or pet battle bar), and each button's panel, which ignores
-- the button's alpha, takes it too (S.FadeMicro, microbuttons.lua). Blizzard
-- never sets MicroMenu's alpha (Blizzard_MicroMenu). Alpha only, so in combat
-- too.
local FADE_TIME = 0.2
local fader = CreateFrame('Frame')
fader:Hide()
MicroMenu.Fader = fader -- for tests

local function FadeAlpha(config)
    local alpha = tonumber(config and config.fade_alpha) or 0
    return math.min(math.max(alpha, 0), 1)
end

local function IsHovered()
    return MicroMenu.Container:IsMouseOver()
end

-- Puts alpha on the bar: the Container, MicroMenu while it's in its own
-- container, and the micro buttons' panels.
local function SetBarAlpha(alpha)
    MicroMenu.Container:SetAlpha(alpha)
    -- In a vehicle or pet battle bar the micro buttons are drawn whole
    local menu = _G.MicroMenu
    local home = not (menu and MicroMenuContainer) or menu:GetParent() == MicroMenuContainer
    if menu then menu:SetAlpha(home and alpha or 1) end
    if S.FadeMicro then S.FadeMicro(home and alpha or 1) end
end

-- Blizzard moved its micro menu (into or out of a pet battle or vehicle bar:
-- microbuttons.lua's Refresh, after its Layout): the bar's alpha again, so
-- the buttons follow where they now are. Alpha only, so in combat too.
function MicroMenu:ReapplyFade()
    if self.Container then SetBarAlpha(self.Container:GetAlpha()) end
end

fader:SetScript('OnUpdate', function(_, elapsed)
    local target = IsHovered() and 1 or MicroMenu.fadedAlpha
    local alpha = MicroMenu.Container:GetAlpha()
    local step = elapsed / FADE_TIME
    if alpha < target - 0.001 then
        SetBarAlpha(math.min(alpha + step, target))
    elseif alpha > target + 0.001 then
        SetBarAlpha(math.max(alpha - step, target))
    end
end)

-- Starts or stops the fade from the profile. A bar that starts fading goes
-- straight to faded unless the mouse is over it. Alpha only.
function MicroMenu:UpdateFade()
    if not self.Container then return end
    if self.config.visibility == 'mouseover' then
        local faded = FadeAlpha(self.config)
        if not self.fadedAlpha then
            SetBarAlpha(IsHovered() and 1 or faded)
        end
        self.fadedAlpha = faded
        fader:Show()
    else
        self.fadedAlpha = nil
        fader:Hide()
        SetBarAlpha(1)
    end
end
