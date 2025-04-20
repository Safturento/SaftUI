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
    debuffs = {
        enable = true,
        position = {point = 'BOTTOMRIGHT',rel_point = 'BOTTOMLEFT', x_off = -7, y_off = 2},
        grow_right = false,
        initial_anchor = 'RIGHT',
        size = 25,
    }
}