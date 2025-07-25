local st = SaftUI

st.defaults.unitframes.profiles["**"].party = {
    spacing = -8,
    growthDirection = 'RIGHT',
    maxColumns = 1,
    unitsPerColumn = 5,
    columnSpacing = 0,
    initialAnchor = 'LEFT',
    width = 80,
    height = 45,
    showPlayer = true,
    position = {point = 'TOP', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = -280},
    grouproleindicator = {
        enable = true,
    },
    raidroleindicator = {
        enable = true,
    },
    raidtargetindicator = {
        enable = true,
    },
    range_alpha = {
        inside = 1,
        outside = 1,
    },
    name = {
        enable = true,
        maxLength = 6,
        position = {
            point = "CENTER",
            element = "Health",
            rel_point = "CENTER",
            x_off = 0,
            y_off = 0,
        },
    },
    power = {
        enable = false,
        text = {
            enable = false,
        },
    },
    health = {
        height = 0,
        width = 0,
        text = {
            enable = false,
        },
        colorClass = true,
        colorClassNPC = true,
        bg = {
            multiplier = 0.4
        }
    },
    buffs = {
        enable = true,
        onlyShowPlayer = true,
        grow_right = true,
        position = { point = 'TOPLEFT', rel_point = 'TOPLEFT', x_off = 3, y_off = -3 },
        horizontal_growth = 'RIGHT',
        initial_anchor = 'LEFT',
        framelevel = 50,
        template = 'thin',
        size = 17,
        cooldown = {
            timer = true,
            alpha = 1,
        },
        friend = {
            filter = {
                time = {
                    enable = true,
                    max = 30,
                },
                whitelist = {
                    enable = true,
                    self = true,
                    spellIds = {
                        [61295] = true, --shaman: riptide
                    }
                },
--                 blacklist = {
--                     enable = true,
--                     auras = true,
--                     others = true,
--                 }
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