local st = SaftUI

st.defaults.unitframes.profiles["**"].pet = {
    width = 100,
    position = {point = 'RIGHT', frame = 'SaftUI_Player_Portrait', rel_point = 'LEFT', x_off = -7, y_off = 0},
    portrait = {
        enable = false,
    },
    power = {
        width = -50,
        reverse_fill = true,
        position = {
            point = 'BOTTOMRIGHT',
            rel_point = 'BOTTOMRIGHT',
            x_off = -7
        },
        text = {
            position = {
                point = 'LEFT',
                rel_point = 'LEFT',
                x_off = 2,
            },
        }
    },
    name = {
        position = {
            rel_point = "TOPLEFT",
            x_off = "5",
            point = "BOTTOMLEFT",
        },
    },
    health = {
        reverse_fill = true,
        text = {
            position = {
                point = 'LEFT',
                rel_point = 'LEFT',
                x_off = 5,
            }
        }
    },
    auras = {
        buffs = {
            enable = false,
        },
        debuffs = {
            enable = false,
        }
    }
}