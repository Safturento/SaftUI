local st = SaftUI

st.defaults.unitframes.profiles["**"].targettarget = {
    enable = true,
    width = 120,
    position = {
        point = 'TOPLEFT',
        frame = 'SaftUI_Target',
        rel_point = 'TOPRIGHT',
        x_off = 6,
        y_off = 0
    },
    name = {
        enable = false,
    },
    power = {
        text = {
            enable = false
        }
    },
}