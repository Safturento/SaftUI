local st = SaftUI

st.defaults = {
}

st.defaults.misc = {
	icon_trim = 0.065,
	clamp_inset = st.CLAMP_INSET
}

-- Edit mode's alignment grid and snapping (see EditMode/grid.lua, snap.lua).
-- grid_size is in UIParent units, which are physical pixels at SaftUI's scale.
st.defaults.editmode = {
	grid = false,
	grid_size = 32,
	snap_grid = false,
	snap_frames = false,
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

st.defaults.headers = {
	height = 31,
	font = 'normal',
}

-- Buttons and panels follow SaftUI's theme (theme.lua): Theme and Background
-- 'theme'. Nothing in the options sets them yet.
st.defaults.buttons = {
	font = 'pixel',
	theme = 'theme',
	background = 'theme',
}

st.defaults.panels = {
	font = 'normal',
	theme = 'theme',
	background = 'theme',
	tab_height = 21,
}

st.defaults.experience = {
	width = 250, -- the minimap's default size
	height = 13,
	spacing = 8,
	rest_alpha = 0.4, -- the rested part past the fill, in the fill's color
	template = 'thicktransparent',
	position = {'TOPRIGHT', 'Minimap', 'BOTTOMRIGHT', 0, -7},
}

-- SaftUI's theme (SaftUI-Core/theme.lua): Thick or Thin, and whether
-- backgrounds are see-through, at opacity, where a module doesn't say.
st.defaults.theme = {
	name = 'thick',
	transparent = true,
	opacity = 0.9,
}

-- Each theme's colors, by its name, and the close button's fill. Thick draws
-- its border between two lines of altbordercolor.
st.defaults.templates = {
	close = {
		backdropcolor = { 0.5, 0.1, 0.1, 0.4 },
	},
	thin = {
		bordercolor = { 0, 0, 0, 1.0 },
		altbordercolor = { 0.0, 0.0, 0.0, 0.0 },
		backdropcolor = { 0.2, 0.2, 0.2, 1 },
	},
	thick = {
		bordercolor = { 0.3, 0.3, 0.3, 1.0 },
		altbordercolor = { 0.1, 0.1, 0.1, 1.0 },
		backdropcolor = { 0.12, 0.12, 0.12, 1 },
	}
}

st.defaults.colors = {
	text = {
		normal		= CreateColor(0.9, 0.9, 0.8),
		red			= CreateColor(220/255, 100/255, 100/255),
		orange 		= CreateColor(220/255, 150/255, 100/255),
		yellow		= CreateColor(200/255, 200/255, 100/255),
		green		= CreateColor( 60/255, 240/255,  60/255),
		grey		= CreateColor(150/255, 150/255, 150/255),
		blue		= CreateColor(0.0, 0.68, 0.94, 1),
		purple		= CreateColor(197/255, 128/255, 255/255),
		cyan        = CreateColor(120/255, 202/255, 250/255),
		white		= CreateColor(1, 1, 1),
	},
	button = {
		normal		=  CreateColor(0.1, 0.1, 0.1, 0.6),
		hover 		=  CreateColor(0.3, 0.5, 0.7, 0.8),
		pushed		=  CreateColor(0.3, 0.4, 0.5, 0.8),
		red			=  CreateColor(0.6, 0.1, 0.1, 0.8),
		green		=  CreateColor(0.1, 0.6, 0.1, 0.8),
		blue		=  CreateColor(0.0, 0.68, 0.94, 0.8),
		yellow		=  CreateColor(0.6, 0.6, 0.1, 0.8),
		grey		=  CreateColor(st.normalizeRGB(150, 150,  150)),
	},
	experience = {
		normal = CreateColor(0.6, 0.3, 0.8, 1.0),
		rested = CreateColor(0.3, 0.6, 0.8, 1.0),
	},
	item_quality = {
		[0] = CreateColor(0.61, 0.61, 0.61),
		[1] = CreateColor(1, 1, 1),
		[2] = CreateColor(90/255, 200/255, 75/255),
		[3] = CreateColor(58/255, 133/255, 207/255),
		[4] = CreateColor(160/255, 99/255, 201/255),
		[5] = CreateColor(209/255, 142/255, 61/255),
		[6] = CreateColor(240/255, 212/255, 137/255),
		[7] = CreateColor(0, 0.8, 1), -- Heirloom
		[8] = CreateColor(0, 0.8, 1), -- WoW Token
	},
	power = {
		MANA              = CreateColor(0.31, 0.45, 0.63),
		RAGE              = CreateColor(0.69, 0.31, 0.31),
		FOCUS             = CreateColor(0.71, 0.43, 0.27),
		ENERGY            = CreateColor(0.65, 0.63, 0.35),
		INSANITY          = CreateColor(0.40, 0.00, 0.80),
		MAELSTROM         = CreateColor(0.00, 0.50, 1.00),
		LUNAR_POWER       = CreateColor(0.93, 0.51, 0.93),
		HOLY_POWER        = CreateColor(0.95, 0.90, 0.60),
		CHI               = CreateColor(0.71, 1.00, 0.92),
		RUNES             = CreateColor(0.55, 0.57, 0.61),
		SOUL_SHARDS       = CreateColor(0.50, 0.32, 0.55),
		FURY              = CreateColor(0.78, 0.26, 0.99),
		PAIN              = CreateColor(1.00, 0.61, 0.00),
		RUNIC_POWER       = CreateColor(0.00, 0.82, 1.00),
		AMMOSLOT          = CreateColor(0.80, 0.60, 0.00),
		FUEL              = CreateColor(0.00, 0.55, 0.50),
		POWER_TYPE_STEAM  = CreateColor(0.55, 0.57, 0.61),
		POWER_TYPE_PYRITE = CreateColor(0.60, 0.09, 0.17),
		ALTPOWER          = CreateColor(0.00, 1.00, 1.00),
		ARCANE_CHARGES	  = CreateColor(0.00, 0.67, 0.94),
		COMBO_POINTS	  = CreateColor(1.00, 0.95, 0.32),
	},
	class = {
		DEATHKNIGHT = CreateColor(st.normalizeRGB(125, 49,  61 )),
		DEMONHUNTER = CreateColor(st.normalizeRGB(137, 79,  156)),
		DRUID       = CreateColor(st.normalizeRGB(181, 107, 51 )),
		EVOKER      = CreateColor(st.normalizeRGB(61,  145, 116)),
		HUNTER      = CreateColor(st.normalizeRGB(134, 163, 95 )),
		MAGE        = CreateColor(st.normalizeRGB(131, 191, 201)),
		MONK        = CreateColor(st.normalizeRGB(113, 199, 172)),
		PALADIN     = CreateColor(st.normalizeRGB(199, 125, 158)),
		PRIEST      = CreateColor(st.normalizeRGB(169, 169, 169)),
		ROGUE       = CreateColor(st.normalizeRGB(173, 170, 75 )),
		SHAMAN      = CreateColor(st.normalizeRGB(50,  95,  150)),
		WARLOCK     = CreateColor(st.normalizeRGB(148, 130, 201)),
		WARRIOR     = CreateColor(st.normalizeRGB(161, 128, 93 )),
	},
	renown = CreateColor(0.00, 0.70, 0.90), -- Renown
	reaction = {
		[1] = CreateColor(st.normalizeRGB(135, 81, 81)), -- Hated
		[2] = CreateColor(st.normalizeRGB(135, 81, 81)), -- Hostile
		[3] = CreateColor(st.normalizeRGB(135, 81, 81)), -- Unfriendly
		[4] = CreateColor(st.normalizeRGB(135, 132, 81)), -- Neutral
		[5] = CreateColor(st.normalizeRGB(81, 135, 85)), -- Friendly
		[6] = CreateColor(st.normalizeRGB(81, 135, 85)), -- Honored
		[7] = CreateColor(st.normalizeRGB(81, 135, 85)), -- Revered
		[8] = CreateColor(st.normalizeRGB(81, 135, 85)), -- Exalted
	},
	status = {
		disconnected = CreateColor(0.6, 0.6, 0.6),
		tapped = CreateColor(0.6, 0.6, 0.6),
	}
}
