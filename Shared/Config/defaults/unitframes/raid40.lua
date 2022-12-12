local st = SaftUI

st.defaults.unitframes.profiles["**"].raid40 = {
    spacing = 5,
    growthDirection = 'RIGHT',
    maxColumns = 8,
    unitsPerColumn = 5,
    columnSpacing = 5,
    initialAnchor = 'TOP',
    position = { point = 'TOPRIGHT', frame = 'SaftUI_Player', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -30 },
    width = 70,
    height = 26,
    -- template = 'thick',
    portrait = {
        enable = false,
    },
    health = {
        text = {
            hide_full = true,
            deficit = true,
        },
    },
    power = {
        enable = true,
        --height = 2,
        --relative_height = false,
        --position = { point = "BOTTOMLEFT", rel_point = 'BOTTOMLEFT', 0, 0 },
        text = { enable = false },
    },
    name = {
        enable = false,
        show_level = false,
        max_length = 8,
    },
    auras = {
        buffs ={ enable = false},
        debuffs = {
            template = 'thin',
            per_row = 2,
            max = 2,
            spacing = 3,
            enable = true,
            position = {point = 'LEFT', rel_point = 'LEFT', x_off = 4, y_off = 0},
            grow_right = true,
            initial_anchor = 'LEFT',
            framelevel = 50,
            size = 8,
        },
    }
}