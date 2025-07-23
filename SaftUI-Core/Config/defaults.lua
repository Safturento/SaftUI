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
		font_name = 'Homespun',
		font_size = 10,
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

st.defaults.experience = {
	width = st.defaults.maps.minimap.size,
	height = 13,
	spacing = 8,
	rest_alpha = 1,
	template = 'thicktransparent',
	position = {'TOPRIGHT', 'Minimap', 'BOTTOMRIGHT', 0, -7},
}

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

st.defaults.colors = {
	text = {
		normal		= { 0.9, 0.9, 0.8 },
		red			= { 220/255, 100/255, 100/255 },
		orange 		= { 220/255, 150/255, 100/255 },
		yellow		= { 200/255, 200/255, 100/255 },
		green		= {  60/255, 240/255,  60/255 },
		grey		= { 150/255, 150/255, 150/255 },
		purple		= { 197/255, 128/255, 255/255 },
		cyan        = { 120/255, 202/255, 250/255 },
		white		= { 1, 1, 1 },
	},
	button = {
		normal		= { 0.1, 0.1, 0.1, 0.6 },
		hover 		= { 0.3, 0.5, 0.7, 0.8 },
		pushed		= { 0.3, 0.4, 0.5, 0.8 },
		red			= { 0.6, 0.1, 0.1, 0.8 },
		green			= { 0.1, 0.6, 0.1, 0.8 },
		blue			= { 0.0, 0.68, 0.94, 0.8 },
		yellow		= { 0.6, 0.6, 0.1, 0.8 },
		grey			= { 150/255, 150/255,  150/255 },
	},
	experience = {
		normal = { 0.6, 0.3, 0.8, 1.0 },
		rested = { 0.3, 0.6, 0.8, 1.0 },
	},
	item_quality = {
		[0] = {0.61, 0.61, 0.61},
		[1] = {1, 1, 1},
		[2] = {90/255, 200/255, 75/255},
		[3] = {58/255, 133/255, 207/255},
		[4] = {160/255, 99/255, 201/255},
		[5] = {209/255, 142/255, 61/255},
	},
	power = {
		MANA              = {0.31, 0.45, 0.63},
		RAGE              = {0.69, 0.31, 0.31},
		FOCUS             = {0.71, 0.43, 0.27},
		ENERGY            = {0.65, 0.63, 0.35},
		INSANITY          = {0.40, 0.00, 0.80},
		MAELSTROM         = {0.00, 0.50, 1.00},
		LUNAR_POWER       = {0.93, 0.51, 0.93},
		HOLY_POWER        = {0.95, 0.90, 0.60},
		CHI               = {0.71, 1.00, 0.92},
		RUNES             = {0.55, 0.57, 0.61},
		SOUL_SHARDS       = {0.50, 0.32, 0.55},
		FURY              = {0.78, 0.26, 0.99},
		PAIN              = {1.00, 0.61, 0.00},
		RUNIC_POWER       = {0.00, 0.82, 1.00},
		AMMOSLOT          = {0.80, 0.60, 0.00},
		FUEL              = {0.00, 0.55, 0.50},
		POWER_TYPE_STEAM  = {0.55, 0.57, 0.61},
		POWER_TYPE_PYRITE = {0.60, 0.09, 0.17},
		ALTPOWER          = {0.00, 1.00, 1.00},
		ARCANE_CHARGES	  = {0.00, 0.67, 1.94},
		COMBO_POINTS	  = {1.00, 0.95, 0.32},
	},
	class = {
		DRUID       = { 1.00, 0.49, 0.03 },
		HUNTER      = { 0.67, 0.84, 0.45 },
		MAGE        = { 0.41, 0.80, 1.00 },
		PALADIN     = { 0.96, 0.55, 0.73 },
		PRIEST      = { 0.83, 0.83, 0.83 },
		ROGUE       = { 1.00, 0.95, 0.32 },
		SHAMAN      = { 0.16, 0.51, 0.91 },
		WARLOCK     = { 0.58, 0.51, 0.79 },
		WARRIOR     = { 0.78, 0.61, 0.43 },
		--DEATHKNIGHT = {},
		--DEMONHUNTER = {},
		--MONK = {},
	},
	renown = { 0.00, 0.70, 0.90 }, -- Renown
	reaction = {
		[1] = { 0.87, 0.37, 0.37 }, -- Hated
		[2] = { 0.87, 0.37, 0.37 }, -- Hostile
		[3] = { 0.87, 0.37, 0.37 }, -- Unfriendly
		[4] = { 0.85, 0.77, 0.36 }, -- Neutral
		[5] = { 0.29, 0.67, 0.30 }, -- Friendly
		[6] = { 0.29, 0.67, 0.30 }, -- Honored
		[7] = { 0.29, 0.67, 0.30 }, -- Revered
		[8] = { 0.29, 0.67, 0.30 }, -- Exalted
	},
	status = {
		disconnected = { 0.6, 0.6, 0.6 },
		tapped = { 0.6, 0.6, 0.6 },
	}
}
