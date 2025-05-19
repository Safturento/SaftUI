local st = SaftUI

st.defaults.unitframes.profiles["**"].raid40 = {
    spacing = 3,
    growthDirection = 'LEFT',
    template = 'thick',
    maxColumns = 8,
    unitsPerColumn = 5,
    columnSpacing = 3,
    initialAnchor = 'TOP',
    position = { point = 'TOPRIGHT', frame = 'SaftUI_Player', rel_point = 'BOTTOMRIGHT', x_off = -2, y_off = -8 },
    width = 57,
    height = 30,
    -- template = 'thick',
    portrait = {
        enable = false,
    },
    health = {
        height = 0,
        width = 0,
        position = {
            x_off = 0,
            y_off = 0
        },
        text = {
            enable = false,
            hide_full = true,
            deficit = true,
        },
        colorClass = true,
        colorClassNPC = true,
    },
    power = {
        enable = false,
        height = 3,
        relative_height = false,
        position = { point = "BOTTOMRIGHT", rel_point = 'BOTTOMRIGHT' },
        text = { enable = false },
    },
    name = {
        enable = false,
        show_level = false,
        max_length = 8,
    },
    buffs = {
      position = { point = 'BOTTOMLEFT', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = 0}
    },
    debuffs = {
        enable = false,
        template = 'thin',
        per_row = 2,
        max = 2,
        spacing = 3,
        position = {point = 'LEFT', rel_point = 'LEFT', x_off = 4, y_off = 0},
        grow_right = true,
        initial_anchor = 'LEFT',
        framelevel = 50,
        size = 8,
    },
}