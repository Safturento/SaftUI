local st = SaftUI

st.defaults.unitframes.profiles["**"].nameplate = {
    height = 26,
    width = 200,
    questindicator = {
        enable = true,
    },
    name = {
        position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 7},
        max_length = 30,
        color_hostile = true,
    },
    castbar = {
        enable = true,
        height = 14,
    },
    auras = {
        buffs = {
            enable = false,
        },
        debuffs = {
            enable = true,
            size = 30,
            position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 24},
            self_only = true,
            show_magic = true,
            cooldown = {
                alpha = 1,
            },
        }
    },
}