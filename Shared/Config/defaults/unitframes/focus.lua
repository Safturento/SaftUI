local st = SaftUI

st.defaults.unitframes.profiles["**"].focus = {
    position = {
        point = 'BOTTOMRIGHT',
        rel_point = 'CENTER',
        x_off = -150,
        y_off = 151
    },
    health = {
        position = { rel_point = "BOTTOMRIGHT", x_off = "-4", point = "BOTTOMRIGHT", y_off = "4" },
    },
    castbar = {
        enable = true,
    },
    health = {
        reverse_fill = true,
    },
    auras = {
        debuffs = {
            enable = true,
            position = {point = 'RIGHT',rel_point = 'LEFT', x_off = -54, y_off = 0},
            grow_right = true,
            initial_anchor = 'RIGHT',
            size = 28,
            filter = {
                friend = {
                    grow_right = false,
                }
            }
        }
    },
}