local st = SaftUI

st.defaults.unitframes.profiles["**"].raid10 = {
    spacing = 3,
    growthDirection = 'LEFT',
    maxColumns = 8,
    unitsPerColumn = 5,
    columnSpacing = 3,
    initialAnchor = 'TOP',
    position = { point = 'TOPLEFT', frame = 'SaftUI_Player', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -8 },
    width = 57,
    height = 34
,
    template = 'thick',
    health = {
        height = 0,
        width = 0,
        position = {
            x_off = 0,
            y_off = 0
        },
        colorCustom = false,
        colorClass = true,
        text = {
            enable = false,
            hide_full = true,
            deficit = true,
        },
    },
    power = {
        enable = false,
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
    debuffs = {
        enable = true,
        template = 'thin',
        per_row = 2,
        max = 2,
        spacing = 3,
        position = {point = 'LEFT', rel_point = 'LEFT', x_off = 4, y_off = 0},
        grow_right = true,
        initial_anchor = 'LEFT',
        framelevel = 50,
        size = 8,
    }
}