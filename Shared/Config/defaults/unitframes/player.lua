local st = SaftUI

st.defaults.unitframes.profiles["**"].player = {
    position = {point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'CENTER', x_off = -150, y_off = -150},
    castbar = {
        enable = true,
    },
    health = {
        reverse_fill = true
    },
    auras = {
        debuffs = {
            enable = true,
            position = {point = 'BOTTOMRIGHT', rel_point = 'TOPRIGHT', x_off = 0, y_off = 3},
            initial_anchor = 'RIGHT',
        }
    },
    classpower = {
        enable = true,
        relative_width = false,
        relative_height = false,
        width = 200,
        height = 20,
        spacing = 7,
        show_empty = true,
        framelevel = 20,
        template = 'thicktransparent',
        position = {
            point = 'TOPLEFT',
            frame = 'UIParent',
            rel_point = 'CENTER',
            x_off = -100,
            y_off = -150,
        },
    }
}