local st = SaftUI

st.defaults.unitframes.profiles["**"].raid10 = {
    spacing = 3,
    growthDirection = 'BOTTOM',
    maxColumns = 8,
    unitsPerColumn = 5,
    columnSpacing = 3,
    initialAnchor = 'LEFT',
    position = {point = 'TOPLEFT', frame = 'SaftUI_Player', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -30},
    width = 99,
    height = 26,
    -- template = 'thick',
    portrait = {
        enable = false,
    },
    raidroleindicator = {
        enable = true,
        show_dps = false,
        position = {
            point = 'CENTER',
            rel_point = 'TOPLEFT',
            x_off = 0,
            y_off = 0,
        }
    },
    health = {
        height = -6,
        text = {
            hide_full = true,
            deficit = true,
        },
        colorCustom = false,
        colorClass = true,
    },
    power = {
        enable = false,
        height = 1,
        position = {point = 'BOTTOMLEFT', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = 7},
        text = {enable = false}
    },
    name = {
        enable = true,
        position = {point = 'LEFT', rel_point = 'LEFT', x_off = 4, y_off = 3},
        max_length = 8,
    },
    auras = {
        buffs = {
            enable = false,
        },
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