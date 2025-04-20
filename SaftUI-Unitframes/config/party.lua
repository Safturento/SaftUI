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
        colorClassNPC = true,
    },
    buffs = {
        enable = true,
        onlyShowPlayer = true,
        grow_right = false,
        position = { point = 'TOPRIGHT', rel_point = 'TOPLEFT', x_off = -7, y_off = 0 },
        horizontal_growth = 'LEFT',
        initial_anchor = 'RIGHT',
        size = 17,
        friend = {
            filter = {
                time = {
                    enable = true,
                    max = 30,
                },
                whitelist = {
                    enable = true,
                    self = true,
                },
                blacklist = {
                    enable = true,
                    auras = true,
                    others = true,
                }
            }
        },
    },
    debuffs = {
        enable = true,
        grow_right = false,
        position = { point = 'BOTTOMRIGHT', rel_point = 'BOTTOMLEFT', x_off = -7, y_off = 0 },
        horizontal_growth = 'LEFT',
        initial_anchor = 'RIGHT',
        size = 17,
        --friend = {
        --    filter = {
        --        whitelist = {
        --            filters = {
        --                yours = false,
        --                auras = false,
        --            },
        --        },
        --    },
        --},
        --enemy = {
        --    filter = {
        --        whitelist = {
        --            enable = false,
        --        },
        --    },
        --},
    }
}