local st = SaftUI

st.defaults.unitframes.profiles["**"].target = {
    position = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'CENTER', x_off = 150, y_off = -150 },
    castbar = {
        position = { point = 'BOTTOM', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 120 },
        enable = true,
        relative_width = false,
        width = 300,
        relative_height = false,
        height = 30,
        template = 'thicktransparent',
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
    buffs = {
        enable = true,
        grow_right = false,
        border = 'all',
        initial_anchor = 'TOPRIGHT',
        position = {
            point = "BOTTOMRIGHT",
            rel_point = "TOPRIGHT",
            x_off = "-2",
        },
    },
    debuffs = {
        enable = true,
        cooldown = {
            alpha = 1,
        },
    }
}