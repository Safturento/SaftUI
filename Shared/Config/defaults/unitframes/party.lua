local st = SaftUI

st.defaults.unitframes.profiles["**"].party = {
    spacing = 48,
    growthDirection = 'BOTTOM',
    maxColumns = 1,
    unitsPerColumn = 5,
    columnSpacing = 0,
    initialAnchor = 'TOP',
    position = {point = 'TOPLEFT', frame = 'SaftUI_Player', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -41},
    raidroleindicator = {
        enable = true,
    },
    raidtargetindicator = {
        enable = true,
    },
    auras = {
        buffs = {
            enable = true,
--             friend = {
--                 filter = {
--                     blacklist = {
--                         enable = true,
--                         others = true,
--                         auras = true,
--                     },
--                 },
--             },
        },
        debuffs = {
            enable = true,
            grow_right = false,
            position = {point = 'RIGHT',rel_point = 'LEFT', x_off = -8, y_off = 0},
            horizontal_growth = 'LEFT',
            initial_anchor = 'RIGHT',
            size = 25,
            friend = {
                filter = {
                    whitelist = {
                        filters = {
                            yours = false,
                            auras = false,
                        },
                    },
                },
            },
            enemy = {
                filter = {
                    whitelist = {
                        enable = false,
                    },
                },
            },
        }
    }
}