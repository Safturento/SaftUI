local st = SaftUI

st.defaults.unitframes.profiles["**"].raid40 = {
    spacing = 4,
    growthDirection = 'LEFT',
    maxColumns = 8,
    unitsPerColumn = 5,
    columnSpacing = 4,
    initialAnchor = 'TOP',
    position = { point = 'TOPRIGHT', frame = 'SaftUI_Player', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -30 },
    width = 57,
    height = 40,
    -- template = 'thick',
    portrait = {
        enable = false,
    },
    health = {
        height = -3,
        width = 0,
        position = {
            x_off = 0,
            y_off = 0
        },
        text = {
            hide_full = true,
            deficit = true,
        },
    },
    power = {
        enable = true,
        height = 3,
        relative_height = false,
        position = { point = "BOTTOMRIGHT", rel_point = 'BOTTOMRIGHT', 0, 0 },
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