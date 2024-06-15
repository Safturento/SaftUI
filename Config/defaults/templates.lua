local st = SaftUI

st.defaults.templates = {
	highlight = {
		name = 'Highlight',
		bordercolor = { 0.3, 0.3, 0.3, 1 },
		altbordercolor = { 0.0, 0.0, 0.0, 1 },
		backdropcolor = { 0.3, 0.3, 0.3, 0.4 },
		border = false,
		thick = true,
		outer_shadow = {0, 0, 0, 0},
		inner_shadow = {0, 0, 0, 0},
	},
	close = {
		name = 'Close Button',
		bordercolor = { 0.3, 0.3, 0.3, 1 },
		altbordercolor = { 0.0, 0.0, 0.0, 1 },
		backdropcolor = { 0.5, 0.1, 0.1, 0.4 },
		border = false,
		thick = true,
		outer_shadow = {0, 0, 0, 0},
		inner_shadow = {0, 0, 0, 0},
	},
	thin = {
		name = 'Thin',
		bordercolor = { 0, 0, 0, 1.0 },
		altbordercolor = { 0.0, 0.0, 0.0, 0.0 },
		backdropcolor = { 0.2, 0.2, 0.2, 1 },
		border = true,
		thick = false,
		outer_shadow = {0, 0, 0, 0},
		inner_shadow = {0, 0, 0, 0},
	},
	thick = {
		name = 'Thick',
		bordercolor = { 0.3, 0.3, 0.3, 1.0 },
		altbordercolor = { 0.1, 0.1, 0.1, 1.0 },
		backdropcolor = { 0.12, 0.12, 0.12, 1 },
		border = true,
		thick = true,
		outer_shadow = {0, 0, 0, 0},
		inner_shadow = {0, 0, 0, 0},
	}
}

st.defaults.templates.thintransparent = st.tablecopy(st.defaults.templates.thin, true)
st.defaults.templates.thintransparent.name = 'ThinTransparent'
st.defaults.templates.thintransparent.backdropcolor[4] = 0.9

st.defaults.templates.thicktransparent = st.tablecopy(st.defaults.templates.thick, true)
st.defaults.templates.thicktransparent.name = 'ThickTransparent'
st.defaults.templates.thicktransparent.backdropcolor[4] = 0.9