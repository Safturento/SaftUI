local st = SaftUI

st.defaults.unitframes.profiles["**"].raid10 = {
    spacing = 3,
    growthDirection = 'LEFT',
    maxColumns = 8,
    unitsPerColumn = 5,
    columnSpacing = 3,
    initialAnchor = 'TOP',
    position = { point = 'TOP', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = -236 },
    width = 80,
    height = 50,
    template = 'thick',
    health = {
        height = 0,
        width = 0,
        position = {
            x_off = 0,
            y_off = 0
        },
        colorCustom = false,
        colorClass = true,
        colorClassNPC = true,
        text = {
            enable = false,
            hide_full = true,
            deficit = true,
        },
    },
    power = {
        enable = false,
        height = 3,
        relative_height = false,
        position = { point = "BOTTOMRIGHT", rel_point = 'BOTTOMRIGHT', 0, 0 },
        text = { enable = false },
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
        position = { point = 'TOPLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 0 },
        horizontal_growth = 'RIGHT',
        initial_anchor = 'LEFT',
        framelevel = 50,
        template = 'thin',
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
        template = 'thin',
        per_row = 2,
        max = 2,
        spacing = 3,
        position = {point = 'BOTTOMLEFT', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = 0},
        grow_right = true,
        initial_anchor = 'LEFT',
        framelevel = 50,
        size = 12,
    }
}