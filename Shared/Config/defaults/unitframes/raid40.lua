local st = SaftUI

st.defaults.unitframes.profiles["**"].raid40 = {
    spacing = 3,
    growthDirection = 'BOTTOM',
    maxColumns = 8,
    unitsPerColumn = 5,
    columnSpacing = 3,
    initialAnchor = 'LEFT',
    position = {point = 'TOP', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = -280},
    width = 50,
    height = 26,
    -- template = 'thick',
    portrait = {
        enable = false,
    },
    health = {
        -- width = -4,
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
        position = { point = "BOTTOMLEFT", rel_point = 'BOTTOMLEFT', 0, 0 },
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