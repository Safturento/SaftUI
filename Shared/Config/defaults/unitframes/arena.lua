local st = SaftUI

st.defaults.unitframes.profiles["**"].arena = {
    width = 202,
    spacing = 24,
    growthDirection = 'DOWN',
    maxColumns = 1,
    unitsPerColumn = 5,
    columnSpacing = 0,
    initialAnchor = 'TOP',
    position = {point = 'TOPLEFT', frame = 'SaftUI_Target', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -30},
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
    },
    name = {
        position = {
            rel_point = "TOPLEFT",
            x_off = "5",
            point = "BOTTOMLEFT",
        },
    },
    portrait = {
        position = {
            point = 'LEFT',
            rel_point = 'RIGHT',
            x_off = 7,
        },
    },
    auras = {
        buffs = {
            filter = {
                enemy = {
                    whitelist = {
                        enable = false,
                    }
                }
            }
        },
        debuffs = {
            enable = true,
            position = {point = 'LEFT', rel_point = 'RIGHT', x_off = 4, y_off = 0},
            horizontal_growth = 'LEFT',
            initial_anchor = 'LEFT',
            size = 28,
            filter = {
                friend = {
                    whitelist = {
                        filters = {
                            yours = false,
                            auras = false,
                        },
                    },
                },
                enemy = {
                    whitelist = {
                        enable = false,
                    },
                },
            },
        }
    },
}