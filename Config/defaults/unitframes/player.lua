local st = SaftUI

st.defaults.unitframes.profiles["**"].player = {
    position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'CENTER', x_off = -157, y_off = -200 },
    additionalpower = {
        enable = true,
        manaAsPrimary = true,
        relative_width = false,
        relative_height = false,
        width = 299,
        height = 9,
        position = { frame_type=true, point ='TOP', frame = 'UIParent', rel_point = 'CENTER', x_off = 0.5, y_off = -200 },
        text = {
            font='pixel_med',
            position = { rel_point = "CENTER", point = "CENTER",  x_off = 0, y_off = 7 },
        }
    },
    power = {
        text = {
            enable = true,
        },
    },
    name = {
        enable = false,
    },
    castbar = {
        enable = true,
        relative_width = false,
        width = 301,
        relative_height = false,
        height = 24,
        template = 'thicktransparent',
        position = { point ='TOP', frame = 'UIParent', rel_point = 'CENTER', x_off = 0.5, y_off = -281 },
        text = {
         position = { point = 'LEFT', rel_point = 'LEFT', x_off = 4, y_off = 0 }
        },
        time = {
         position = { point = 'RIGHT', rel_point = 'RIGHT', x_off = -3, y_off = 0 }
        },
        icon = {
            enable = false,
            height = 40,
            relative_height = false,
            width = 40,
            relative_width = false,
            position = { point = 'TOP', element = 'Castbar', rel_point = 'BOTTOM', x_off = 0, y_off = -20 }
        }
    },
    buffs = {
        enable = true,
        showBar = true,
        friend = {
            filter = {
                time = {
                    enable = true,
                    max = 60,
                },
                blacklist = {
                    enable = true,
                    auras = true,
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
        size = 35,
    },
    classpower = {
        enable = true,
        relative_width = false,
        relative_height = false,
        width = 200,
        height = 20,
        spacing = 7,
        show_empty = true,
        framelevel = 20,
        template = 'thicktransparent',
        position = {
            point = 'TOPLEFT',
            frame = 'UIParent',
            rel_point = 'CENTER',
            x_off = -100,
            y_off = -150,
        },
    }
}