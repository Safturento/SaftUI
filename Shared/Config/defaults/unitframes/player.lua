local st = SaftUI

st.defaults.unitframes.profiles["**"].player = {
    width = 202,
    position = {point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'CENTER', x_off = -150, y_off = -150},
    castbar = {
        enable = true,
        height = 20,
        relative_width = false,
        width = 248,
        relative_height = false,
        position = {
            rel_point = "CENTER",
            point = "TOP",
            x_off = "13",
            y_off = "-256",
            anchor_frame = "UIParent",
            frame_type = true,
        },
    },
    raidroleindicator = {
        enable = true,
    },
    name = {
        enable = true,
    },
    health = {
        text = {
            hide_full = true,
            deficit = true,
        },
    },
    power = {
        text = {
            enable = true,
        },
    },
    auras = {
        debuffs = {
            enable = true,
            position = {point = 'RIGHT',rel_point = 'LEFT', x_off = -54, y_off = 0},
            grow_right = false,
            initial_anchor = 'RIGHT',
            size = 28,
            filter = {
                friend = {
                    grow_right = false,
                }
            }
        }
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