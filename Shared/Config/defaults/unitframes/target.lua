local st = SaftUI

st.defaults.unitframes.profiles["**"].target = {
    position = {point = 'TOPLEFT', frame = 'UIParent', rel_point = 'CENTER', x_off = 150, y_off = -150},
    name = {
        position = {
            rel_point = "TOPLEFT",
            x_off = "5",
            point = "BOTTOMLEFT",
        },
    },
    castbar = {
        enable = true,
        height = 30,
        relative_width = false,
        width = 200,
        relative_height = false,
        position = {
            rel_point = "TOP",
            point = "TOP",
            x_off = "0",
            y_off = "-500",
            anchor_frame = "UIParent",
            frame_type = true,
        },
        icon = {
            height = 30,
            width = 30,
            position = {
                rel_point = "TOPRIGHT",
                point = "TOPLEFT",
                anchor_element = "Castbar",
                x_off = "7",
                frame_type = false,
            },
        },
    },
    auras = {
        buffs = {
            enable = true,
            grow_right = false,
            initial_anchor = 'TOPRIGHT',
            horizontal_growth = 'LEFT',
            position = {
                point = 'TOPRIGHT',
                rel_point = 'BOTTOMRIGHT',
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
        }
    },
    portrait = {
        position = {
            point = 'LEFT',
            rel_point = 'RIGHT',
            x_off = 7,
        },
    },
    health = {
        reverse_fill = true,
        text = {
            percent = false,
            position = {
                point = 'LEFT',
                rel_point = 'LEFT',
                x_off = 5,
            }
        }
    },
    power = {
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
    }
}