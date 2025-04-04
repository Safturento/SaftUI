local st = SaftUI

st.defaults = {
}

st.defaults.misc = {
	icon_trim = 0.065,
	clamp_inset = st.CLAMP_INSET
}

st.defaults.grid = {
	horizontalSpacing = 20,
	verticalSpacing = 20
}

st.defaults.fonts = {
	pixel = {
		name = 'Pixel',
		font_name = 'Semplice',
		font_size = 8,
		font_outline = 'MONOCHROMEOUTLINE',
		shadow_offset = {0, 0},
		spacing = 4,
	},
	normal = {
		name = 'Normal',
		font_name = 'AgencyFB Bold',
		font_size = 16,
		font_outline = 'OUTLINE',
		shadow_offset = {0, 0},
		spacing = 4,
	},
	title = {
		name = 'Colus',
		font_name = 'Colus',
		font_size = 72,
		font_outline = 'OUTLINE',
		shadow_offset = { 0, 0 },
		spacing = 4,
	},
}
st.defaults.fonts.pixel_med = st.tablemerge(st.defaults.fonts.pixel, { name='Pixel Med', font_size = 18 })
st.defaults.fonts.pixel_huge = st.tablemerge(st.defaults.fonts.pixel, { name='Pixel Huge', font_size = 32 })
st.defaults.fonts.normal_med = st.tablemerge(st.defaults.fonts.normal, { name='Normal Med', font_size = 24 })
st.defaults.fonts.subtitle = st.tablemerge(st.defaults.fonts.title, { name='Subtitle', font_size = 24 })

st.defaults.addon_manager = {
	font = 'normal',
	num_rows = 18,
	row_height = 20,
	spacing = 7,
}

st.defaults.headers = {
	height = 31,
	font = 'normal',
}

st.defaults.buttons = {
	font = 'pixel',
	template = 'thicktransparent',
	height = 21,
}

st.defaults.panels = {
	font = 'normal',
	template = 'thicktransparent',
	padding = 20,
	tab_height = 21,
}

st.defaults.maps = {
	minimap = {
		font = 'pixel',
		enable = true,
		template = 'thick',
		size = 250,
		position = {point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -st.CLAMP_INSET, y_off = -st.CLAMP_INSET},
		mail_position = {'TOPRIGHT', 'TOPRIGHT', -5, -2},
	}
}

st.defaults.tooltip = {
	template = 'thicktransparent',
	font = 'normal',
	attach_to_bags = true,
}

st.defaults.chat = {
	position = {'BOTTOMLEFT', 30, 30},
	template = 'thicktransparent',
	font = 'normal',
	padding = 10,
	fontsize = 16,
	linespacing = 5,
	fadetabs = true,
	tabs = {
		height = 25,
		fade = false,
	},
	editbox = {
		height = 25,
	}
}

st.defaults.skinning = {
	font = 'pixel',
	template = 'thicktransparent',
}

st.defaults.experience = {
	width = st.defaults.maps.minimap.size,
	height = 13,
	spacing = 8,
	rest_alpha = 1,
	template = 'thicktransparent',
	position = {'TOPRIGHT', 'Minimap', 'BOTTOMRIGHT', 0, -7},
}

st.defaults.micromenu = {

}