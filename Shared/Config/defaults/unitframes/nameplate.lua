local st = SaftUI

st.defaults.unitframes.profiles["**"].nameplate = {
    height = 14,
    width = 140,
    portrait = {
        enable = false,
    },
    questindicator = {
        enable = true,
    },
    raidtargetindicator = {
        position = {
            enable = true,
            point = 'CENTER',
            rel_point = 'BOTTOMLEFT',
            anchor_element = 'Health',
            frame_type = false,
            x_off = 0,
            y_off = 0,
        }
    },
    power = {
        enable = true,
        height = 3,
        text = {
            enable = false
        }
    },
    health = {
        height = 0,
        text = {
            position = {x_off = -2},
        },
    },
    name = {
        position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 7},
        max_length = 30,
        color_hostile = true,
    },
    castbar = {
        enable = true,
        height = 14,
        position = {
            point = "TOPLEFT",
            rel_point = "BOTTOMLEFT",
            y_off = "-7",
            frame_type = nil,
        },
        icon = {
            enable = false
        }
    },
    auras = {
        buffs = {
            enable = false,
        },
        debuffs = {
            enable = true,
            position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 24},
            self_only = true,
            show_magic = true,
            cooldown = {
                alpha = 1,
            },
        }
    },
}