local st = SaftUI

st.defaults.unitframes.profiles["**"].party = {
    spacing = 8,
    growthDirection = 'BOTTOM',
    maxColumns = 1,
    unitsPerColumn = 5,
    columnSpacing = 0,
    initialAnchor = 'TOP',
    showPlayer = false,
    width = 200,
    position = {point = 'TOPLEFT', frame = 'SaftUI_Player', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -8},
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
    },
    power = {
        enable = true,
        text = {
            enable = false,
        },
    },
    health = {
        text = {
            enable = true,
            deficit = true,
        },
        colorClass = false,
        colorClassNPC = true,
        bg = {
            multiplier = 0.4
        }
    },
    buffs = {
        enable = true,
        onlyShowPlayer = true,
        grow_right = true,
        position = { point = 'TOPLEFT', rel_point = 'TOPRIGHT', x_off = 7, y_off = 0 },
        horizontal_growth = 'RIGHT',
        initial_anchor = 'LEFT',
        framelevel = 50,
        cooldown = {
            timer = {
                enable = true,
            },
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
                        [61295] = true, -- Shaman: Riptide
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
        position = { point = 'TOPRIGHT', rel_point = 'TOPLEFT', x_off = -7, y_off = 0 },
        horizontal_growth = 'LEFT',
        initial_anchor = 'RIGHT',
        framelevel = 50,
        spacing = 1,
        friend = {
           filter = {
               blacklist = {
                   enable = true,
                   spellIds = {
                       ['Sated'] = true,
                       ['Exhaustion'] = true,
                       ['Temporal Displacement'] = true,
                   }
               },
           },
        },
    }
}