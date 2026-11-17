local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')
local S = MicroMenu.S

-- Each bar item's panel, and the box it stands on under the Blizzard theme
-- (micromenu.lua lays the bar out and says what an item is).
--
-- Under the Blizzard theme every item stands on the same box, the one border
-- the theme has everywhere (st.ThemeArt.LayBox, the minimap header button's):
-- the zone, clock, latency, FPS, addon count, expansion, mail, difficulty,
-- queue and search items and each micro button's holder, at the item's own
-- rect, centre shown. The box is textures of SaftUI's panel, kept in the
-- item's entry (micromenu.lua's items) and in this file: nothing is drawn on,
-- or kept on, Blizzard's bar items or its micro menu, whose own frame art
-- stays faded (microbuttons.lua). There is no strip under the micro buttons.

-- From micromenu.lua.
local items = S.items

-- The item's box under Blizzard, laid by ThemeArt.LayBox on its panel, which
-- under Blizzard is the item's rect (a control's inset is 0): the bar's height
-- by the item's width. The pieces are the panel's, kept in the item's entry
-- (boxPieces), made the first time they're needed; under another look they
-- hide (theme and background: the panel's, as UpdateBackdrop resolved them). The panel is one level under the item, so the item's own art, text
-- and hover draw over the box. The panel draws no fill of its own (a control
-- has none), so the box is all there is.
local function UpdateArt(item, theme, background)
    local panel = item.backdrop
    if panel and st:IsBlizzardLook(theme, background) then
        item.boxPieces = item.boxPieces or {}
        st.ThemeArt.LayBox(item.boxPieces, panel, true)
    elseif item.boxPieces then
        st.ThemeArt.HidePieces(item.boxPieces)
    end
end

-- The item's panel: a SaftUI frame kept in its entry, drawn as a control: a
-- small frame under Thick and Thin, and under Blizzard nothing of its own, the
-- box UpdateArt lays on it. st:SetBackdrop would store it on the item as
-- .backdrop (and .thick). It's a child of the item, so it shows and hides with
-- it, one frame level down so it draws under the item's own art. A micro
-- button's holder (theme 'none': under Thick and Thin the button's own panel
-- is its box) has a panel only under Blizzard, where the holder stands on the
-- box like every item and Blizzard's button art stays above it.
local function UpdateBackdrop(button, item)
    local theme, background = item.theme or 'theme', item.background or 'theme'
    if theme == 'none' and item.micro and st:IsBlizzardLook('theme', 'theme') then
        theme, background = 'theme', 'theme'
    end
    if theme == 'none' then
        if item.backdrop then
            st:SetTemplate(item.backdrop, 'none', background, 'control')
            UpdateArt(item, theme, background)
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

    UpdateArt(item, theme, background)
end

-- The item's box pieces under Blizzard (UpdateArt), nil until they're first
-- needed. For tests.
function MicroMenu:GetItemBox(button)
    local item = items[button]
    return item and item.boxPieces
end

-- For micromenu.lua's UpdateButtons.
S.UpdateBackdrop = UpdateBackdrop
