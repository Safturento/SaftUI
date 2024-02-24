
local st = SaftUI

st.defaults.unitframes.profiles["**"].boss = {
    spacing = 41,
    growthDirection = 'DOWN',
    maxColumns = 1,
    unitsPerColumn = 5,
    columnSpacing = 0,
    initialAnchor = 'TOP',
    width = 200,
    position = {point = 'TOPRIGHT', frame = 'SaftUI_Target', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = -40},
    castbar = {
        enable = true,
        icon = {
            enable = false,
            position = {
                point = "TOPRIGHT",
                rel_point = "TOPLEFT",
                x_off = "-6",
                y_off = -2,
                element = "Castbar",
            },
        }
    },
    power = {
        text = {
            enable = false,
        },
    },
    health = {
        text = {
            enable = false,
        },
    },
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
        position = {point = 'BOTTOMLEFT',rel_point = 'BOTTOMRIGHT', x_off = 7, y_off = 2},
        grow_right = true,
        initial_anchor = 'LEFT',
        size = 25,
        filter = {
            whitelist = {
                enable = true,
                filters = {
                  yours = true,
                  others = false
                }
            }
        }
    }
}