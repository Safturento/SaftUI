local st = SaftUI

-- SaftUI's friendly nameplates (nameplates/nameplates.lua): the plates of
-- units you can't attack, on their own page in /sui beside the enemy
-- nameplates'.
--
-- The plate's look, a name and nothing else:
--   * no health bar and no health text, the frame's Theme None (every unit's);
--   * the name centred on the frame, cut at 150 pixels, coloured by class
--     for a player, by reaction for an NPC (color_friendly, color_hostile),
--     with no level or classification. It is anchored to the frame itself
--     (element = false, the position's "Unit frame"), not to the health bar
--     that isn't there;
--   * the subtext, an NPC's title or a player's guild in grey brackets, centred
--     2 under the name (both on);
--   * the raid mark 16 square, its bottom 4 above the name's top;
--   * the castbar, the debuffs, the buffs and the quest icon off, and set as
--     the enemy plates' are (nameplates.lua's file) for whoever turns them on.
-- The other elements' settings are every unit's.
st.defaults.unitframes.profiles["**"].friendlynameplate = {
    -- Draw enemy plates from this page too: Enemy nameplates' counterpart box
    -- is use_friendly. Never both (the page keeps one off).
    use_enemy = false,
    -- The subtext under the name (nameplates/subtext.lua): an NPC's title or a
    -- player's guild, grey, centred 2 under the name. Enable is always true and
    -- not an option on the page (UF:ElementWanted needs it): the two boxes
    -- decide what the tag returns.
    subtext = {
        enable = true,
        npc = true,
        player = true,
        font = 'normal',
        color = { r = 0.8, g = 0.8, b = 0.8 },
        alpha = 1,
        max_width = 150,
        position = { point = 'TOP', element = 'Name', rel_point = 'BOTTOM', x_off = 0, y_off = -2 },
    },
    width = 150,
    height = 16,
    health = {
        enable = false,
        text = {
            enable = false,
            short = true,
            percent = false,
            boss_percent = false,
            position = { point = 'RIGHT', element = 'Health', rel_point = 'RIGHT', x_off = -4, y_off = 0 },
        },
    },
    name = {
        enable = true,
        showLevel = false,
        show_classification = false,
        colorClass = true,
        color_friendly = true,
        color_hostile = true,
        max_width = 150,
        position = { point = 'CENTER', element = false, rel_point = 'CENTER', x_off = 0, y_off = 0 },
    },
    castbar = {
        enable = false,
        theme = 'theme',
        background = 'theme',
        relative_width = true,
        width = -18,
        relative_height = false,
        height = 12,
        position = { point = 'TOPRIGHT', element = 'Health', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -6 },
        colors = {
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
        enable = false,
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
        enable = false,
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
        enable = false,
        size = 16,
        position = { point = 'RIGHT', element = 'Health', rel_point = 'LEFT', x_off = -6, y_off = 0 },
    },
    raidtargetindicator = {
        enable = true,
        size = 16,
        position = { point = 'BOTTOM', element = 'Name', rel_point = 'TOP', x_off = 0, y_off = 4 },
    },
}
