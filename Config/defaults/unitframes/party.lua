local st = SaftUI

st.defaults.unitframes.profiles["**"].party = {
    spacing = 8,
    growthDirection = 'BOTTOM',
    maxColumns = 1,
    unitsPerColumn = 5,
    columnSpacing = 0,
    initialAnchor = 'TOP',
    width = 200,
    position = {point = 'TOPLEFT', frame = 'SaftUI_Player', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -8},
    raidroleindicator = {
        enable = true,
    },
    raidtargetindicator = {
        enable = true,
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
        enable = false,
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
        position = { point = 'BOTTOMRIGHT', rel_point = 'BOTTOMLEFT', x_off = -8, y_off = 2 },
        horizontal_growth = 'LEFT',
        initial_anchor = 'RIGHT',
        size = 35,
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