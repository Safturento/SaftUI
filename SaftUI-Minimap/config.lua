local st = SaftUI

st.config.profile.minimap = st.tablemerge({
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
}, st.config.profile.minimap)

st.config.profile.micromenu = st.tablemerge({
    position = {
        point = 'TOPLEFT',
        frame = 'UIParent',
        rel_point = 'TOPLEFT',
        x_off = st.CLAMP_INSET,
        y_off = -st.CLAMP_INSET,
    },
}, st.config.profile.micromenu)