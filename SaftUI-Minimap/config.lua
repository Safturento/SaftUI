local st = SaftUI

st.defaults.minimap = {
    font = 'pixel',
    enable = true,
    template = 'thick',
    size = 250,
    position = {
        point = 'TOPRIGHT',
        frame = 'UIParent',
        rel_point = 'TOPRIGHT',
        x_off = -st.CLAMP_INSET,
        y_off = -st.CLAMP_INSET
    },
}

st.defaults.micromenu = {
    position = {
        point = 'TOPLEFT',
        frame = 'UIParent',
        rel_point = 'TOPLEFT',
        x_off = st.CLAMP_INSET,
        y_off = -st.CLAMP_INSET,
    },
}