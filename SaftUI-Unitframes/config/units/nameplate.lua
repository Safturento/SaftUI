local st = SaftUI

-- SaftUI's nameplates (nameplates/nameplates.lua): on by default, with friendly
-- plates, and threat shown in a group only (threat_solo off). The width and
-- height are the plates' size, which every plate takes (the game has one size
-- for all of them).
--
-- The plate's layout, around a health bar that fills the plate (200 by 20):
--   * the name inside it on the left, cut at 150 pixels so it can't run under
--     the health, hostile names coloured, with no level or classification;
--   * the health inside on the right, as a short value (12.5K), never a
--     percent;
--   * the castbar 6 under it, 182 wide (Relative, -18) and 12 tall, its spell
--     name inside, no time, and its 12x12 icon 6 to its left, so the row
--     starts at the bar's left edge (12 + 6 + 182 = 200); a cast that can't be
--     interrupted in grey;
--   * up to 6 of the player's debuffs 6 above the bar, from its left edge
--     growing right (6 x 20 + 5 x 6 = 150 wide), which leaves the space above
--     the bar's right end free for the threat text;
--   * up to 4 buffs the player can purge 6 right of the bar, level with its
--     top (98 wide);
--   * the subtext line (an NPC's title or a player's guild) off, and where it
--     would sit, centred under the castbar's row;
--   * the quest icon 6 left of the bar, and the raid mark centred 6 above the
--     debuff row (6 + 20 + 6 = 32 over the bar).
-- The bar itself, its colours (reaction, class, tapped) and the frame's Theme
-- (None, its bars drawn in SaftUI's theme) are every unit's, as are the
-- elements' other settings.
st.defaults.unitframes.profiles["**"].nameplate = {
    enable = true,
    friendly = true,
    -- Draw enemy plates from the Friendly nameplates page (friendlynameplate.lua).
    -- Never on together with friendlynameplate.use_enemy.
    use_friendly = false,
    threat_solo = false,
    -- The threat text (nameplates/threat.lua): your threat on an enemy as a
    -- percent, small, above the bar's right end, level with the debuffs.
    threat = {
        enable = true,
        font = 'pixel',
        position = { point = 'BOTTOMRIGHT', element = 'Health', rel_point = 'TOPRIGHT', x_off = 0, y_off = 6 },
    },
    -- The subtext under the name (nameplates/subtext.lua): an NPC's title or a
    -- player's guild, grey, centred under the castbar's row (6 + 12 + 6 under
    -- the bar). Enable is always true and not an option on the page
    -- (UF:ElementWanted needs it): the two boxes decide what the tag returns.
    -- Both off for enemies.
    subtext = {
        enable = true,
        npc = false,
        player = false,
        font = 'normal',
        color = { r = 0.8, g = 0.8, b = 0.8 },
        alpha = 1,
        max_width = 200,
        position = { point = 'TOP', element = 'Health', rel_point = 'BOTTOM', x_off = 0, y_off = -24 },
    },
    width = 200,
    height = 20,
    health = {
        text = {
            enable = true,
            short = true,
            percent = false,
            boss_percent = false,
            position = { point = 'RIGHT', element = 'Health', rel_point = 'RIGHT', x_off = -4, y_off = 0 },
        },
    },
    name = {
        showLevel = false,
        show_classification = false,
        color_hostile = true,
        max_width = 150,
        position = { point = 'LEFT', element = 'Health', rel_point = 'LEFT', x_off = 4, y_off = 0 },
    },
    castbar = {
        enable = true,
        theme = 'theme',
        background = 'theme',
        relative_width = true,
        width = -18,
        relative_height = false,
        height = 12,
        position = { point = 'TOPRIGHT', element = 'Health', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -6 },
        colors = {
            -- Keyed like the base default's color (CreateColor), whose r, g and
            -- b GetRGB reads.
            nointerrupt = { r = 0.6, g = 0.6, b = 0.6 },
        },
        text = {
            enable = true,
            font = 'pixel',
            position = { point = 'LEFT', element = 'Castbar', rel_point = 'LEFT', x_off = 4, y_off = 0 },
        },
        time = {
            enable = false,
        },
        icon = {
            enable = true,
            theme = 'theme',
            background = 'theme',
            relative_width = false,
            width = 12,
            relative_height = false,
            height = 12,
            position = { point = 'RIGHT', element = 'Castbar', rel_point = 'LEFT', x_off = -6, y_off = 0 },
        },
    },
    debuffs = {
        enable = true,
        onlyShowPlayer = true,
        size = 20,
        max = 6,
        per_row = 6,
        spacing = 6,
        grow_right = true,
        grow_up = true,
        initial_anchor = 'BOTTOMLEFT',
        position = { point = 'BOTTOMLEFT', element = 'Health', rel_point = 'TOPLEFT', x_off = 0, y_off = 6 },
    },
    buffs = {
        enable = true,
        purgeable = true,
        size = 20,
        max = 4,
        per_row = 4,
        spacing = 6,
        grow_right = true,
        grow_up = false,
        initial_anchor = 'TOPLEFT',
        position = { point = 'TOPLEFT', element = 'Health', rel_point = 'TOPRIGHT', x_off = 6, y_off = 0 },
    },
    questindicator = {
        enable = true,
        size = 16,
        position = { point = 'RIGHT', element = 'Health', rel_point = 'LEFT', x_off = -6, y_off = 0 },
    },
    raidtargetindicator = {
        enable = true,
        size = 16,
        position = { point = 'BOTTOM', element = 'Health', rel_point = 'TOP', x_off = 0, y_off = 32 },
    },
}
