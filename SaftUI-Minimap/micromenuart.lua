local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')
local S = MicroMenu.S

-- Each bar item's panel, and the boxes it stands on under the Blizzard theme
-- (micromenu.lua lays the bar out and says what an item is).
--
-- Under the Blizzard theme the bar stands on Blizzard's minimap and micro menu
-- art (st.ThemeArt.Control('microbar')). Each item's box is drawn on its panel
-- (UpdateArt): on Forever one of Camelot's atlases (the header button behind
-- the zone, clock, latency and FPS, the addon indicator's square, the tracking
-- button), on retail the grey minimap button kit. On Forever the micro buttons
-- also stand on one strip, the action bar's frame (UpdateStrip). All of it is
-- textures of SaftUI's frames, kept in the items' entries (micromenu.lua's
-- items) and in this file: nothing is drawn on, or kept on, Blizzard's bar
-- items or its micro menu, whose own frame art stays faded (microbuttons.lua).

-- From micromenu.lua.
local items = S.items

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
        local height = MicroMenu:BarHeight()
        local top = -math.floor((height - art.height) / 2)
        if art.width then
            local left = math.floor((S.ItemWidth(item, height) - art.width) / 2)
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

-- For micromenu.lua's UpdateButtons.
S.UpdateBackdrop = UpdateBackdrop
S.UpdateStrip = UpdateStrip
