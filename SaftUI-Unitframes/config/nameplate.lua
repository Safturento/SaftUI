local st = SaftUI

st.defaults.unitframes.profiles["**"].nameplate = {
    height = 30,
    width = 250,
    questindicator = {
        enable = true,
    },
    name = {
        position = { point = 'LEFT', rel_point = 'LEFT', x_off = 10, y_off = 0 },
        max_length = 30,
        color_hostile = true,
    },
    castbar = {
        enable = true,
        height = 14,
    },
    power = {
        text = {
            enable = false,
        },
    },
    debuffs = {
        enable = true,
        size = 30,
        position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 24},
        cooldown = {
            alpha = 1,
        },
        enemy = {
            filter = {
                blacklist = {
                    enable = true,
                    others = true,
                }
            }
        }
    }
}