local st = SaftUI

st.defaults.unitframes.profiles["**"].focus = {
    width = 250,
    position = {
        point = 'BOTTOMRIGHT',
        rel_point = 'CENTER',
        x_off = -180,
        y_off = 181
    },
    health = {
        position = { rel_point = "BOTTOMRIGHT", x_off = "-4", point = "BOTTOMRIGHT", y_off = "4" },
    },
    castbar = {
        position = { point = 'BOTTOM', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 180 },
        enable = true,
        relative_width = false,
        width = 300,
        relative_height = false,
        height = 30,
        template = 'thicktransparent',
        colors = {
            normal = { .5, .9, .7 },
        },
        text = {
         position = { point = 'LEFT', rel_point = 'LEFT', x_off = 4, y_off = 0 }
        },
        time = {
         position = { point = 'RIGHT', rel_point = 'RIGHT', x_off = -3, y_off = 0 }
        },
        icon = {
            height = 40,
            relative_height = false,
            width = 40,
            relative_width = false,
            position = { point = 'BOTTOM', element = 'Castbar', rel_point = 'TOP', x_off = 0, y_off = 20 }
        }
    },
    health = {
        reverse_fill = true,
    },
    buffs = {
        enable = true,
    },
    debuffs = {
        enable = true,
        position = {point = 'BOTTOMRIGHT',rel_point = 'BOTTOMLEFT', x_off = -7, y_off = 2},
        grow_right = false,
        initial_anchor = 'RIGHT',
        size = 25,
    }
}