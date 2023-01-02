local st = SaftUI

st.defaults.unitframes.profiles["**"].target = {
    position = {point = 'TOPLEFT', frame = 'UIParent', rel_point = 'CENTER', x_off = 150, y_off = -150},
    health = {
        position = { rel_point = "TOPLEFT", x_off = "4", point = "TOPLEFT", y_off = "-4" },
    },
    castbar = {
        enable = true,
        icon = {
            enable = true,
            position = {
                point = "TOPRIGHT",
                rel_point = "TOPLEFT",
                x_off = "-6",
                y_off = -2,
                anchor_element = "Castbar",
            },
        }
    },
    auras = {
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
            filter = {
                friend = {
                    whitelist = {
                        enable = true,
                        filters = {
                            auras = false,
                        },
                    },
                    blacklist = {
                        enable = false,
                        filters = {
                            others = true,
                        },
                    },
                },
            },
        },
        debuffs = {
            enable = true,
            self_only = true,
            show_magic = true,
            cooldown = {
                alpha = 1,
            },
        }
    }
}