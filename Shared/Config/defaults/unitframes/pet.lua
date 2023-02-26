local st = SaftUI

st.defaults.unitframes.profiles["**"].pet = {
    width = 100,
    position = {point = 'RIGHT', frame = 'SaftUI_Player', rel_point = 'LEFT', x_off = -7, y_off = 0},
    power = {
        text = {
            enable = false
        }
    },
    name = {
        enable = false,
    },
    health = {
        position = { rel_point = "TOPLEFT", x_off = "4", point = "TOPLEFT", y_off = "-4" },
    },
    debuffs = {
        enable = false,
    }
}