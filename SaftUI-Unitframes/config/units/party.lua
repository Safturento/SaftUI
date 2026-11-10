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
    position = {
        point = 'TOPLEFT',
        frame = 'SaftUI_Player',
        rel_point = 'BOTTOMLEFT',
        x_off = 0,
        y_off = -7
    },

    grouproleindicator = {
        enable = true,
    },
    raidroleindicator = {
        enable = true,
    },
    raidtargetindicator = {
        enable = true,
    },
    power = {
        enable = false,
        text = {
            enable = false,
        },
    },
    health = {
        text = {
            enable = false,
            deficit = true,
        },
        colorClass = true,
        colorClassNPC = true,
    },
    name = {
        enable = true,
        showLevel = false,
        maxLength = 4,
        position = { point = 'CENTER', rel_point = 'CENTER', x_off = 0, y_off = 0 },
    },
    buffs = {
        enable = true,
        onlyShowPlayer = true,
        grow_right = true,
        position = { point = 'TOPLEFT', rel_point = 'TOPRIGHT', x_off = 7, y_off = 0 },
        horizontal_growth = 'RIGHT',
        initial_anchor = 'LEFT',
        size = 34,
        framelevel = 50,
        theme = 'theme',
        background = 'solid',
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
            }
        },
    },
    debuffs = {
        enable = true,
        grow_right = false,
        position = { point = 'BOTTOMRIGHT', rel_point = 'BOTTOMLEFT', x_off = -7, y_off = 0 },
        horizontal_growth = 'LEFT',
        initial_anchor = 'RIGHT',
        size = 34,
        framelevel = 50,
        --spacing = 1,
        friend = {
           filter = {
--                whitelist = {
--                    enable = true,
--                    boss = true,
--                },
               blacklist = {
                   enable = true,
--                    others = true,
                   spellIds = {
                       ['Sated'] = true,
                       ['Exhaustion'] = true,
                       ['Ethereal Exhaustion'] = true,
                       ['Temporal Displacement'] = true,
                       ['Challenger\'s Burden'] = true,

                   }
               },
           },
        },
    }
}