local st = SaftUI

st.defaults.unitframes.profiles["**"].focus = {
    position = {
        point = 'BOTTOMRIGHT',
        rel_point = 'CENTER',
        x_off = -300,
        y_off = 120
    },
    auras = {
        buffs = {
            enable = false,
        },
    },
    castbar = {
        enable = true,
        height = 20,
        position = {
            point = "TOPLEFT",
            rel_point = "BOTTOMLEFT",
            y_off = "-7",
            frame_type = nil,
        },
        icon = {
            enable = false
        }
    },
}