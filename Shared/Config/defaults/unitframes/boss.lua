local st = SaftUI

st.defaults.unitframes.profiles["**"].boss = {
    spacing = 23,
    growthDirection = 'DOWN',
    maxColumns = 1,
    unitsPerColumn = 5,
    columnSpacing = 0,
    initialAnchor = 'TOP',
    position = {point = 'TOPLEFT', frame = 'SaftUI_Target', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -25},
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
            initial_anchor = 'TOPRIGHT',
            position = {
                point = "BOTTOMRIGHT",
                rel_point = "TOPRIGHT",
                x_off = "0",
                y_off = "3",
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
}