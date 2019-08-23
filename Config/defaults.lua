local ADDON_NAME, st = ...

st.defaults = {}
st.defaults.fonts = {
	pixel = {
		name = 'Pixel',
		font_name = 'Homespun',
		font_size = 10,
		font_outline = 'MONOCHROMEOUTLINE',
		shadow_offset = {0, 0},
		spacing = 4,
		}
}

st.defaults.templates = {
	thin = {
		name = 'Thin',
		bordercolor = { 0, 0, 0, 1.0 },
		altbordercolor = { 0.0, 0.0, 0.0, 0.0 },
		backdropcolor = { 0.2, 0.2, 0.2, 1 },
		thick = false,
	},
	thick = {
		name = 'Thick',
		bordercolor = { 0.4, 0.4, 0.4, 1.0 },
		altbordercolor = { 0, 0, 0, 1.0 },
		backdropcolor = { 0.2, 0.2, 0.2, 1 },
		thick = true,
	},
}

st.defaults.templates.thintransparent = st.tablecopy(st.defaults.templates.thin, true)
st.defaults.templates.thintransparent.name = 'ThinTransparent'
st.defaults.templates.thintransparent.backdropcolor[4] = 0.5

st.defaults.templates.thicktransparent = st.tablecopy(st.defaults.templates.thick, true)
st.defaults.templates.thicktransparent.name = 'ThickTransparent'
st.defaults.templates.thicktransparent.backdropcolor[4] = 0.5

st.defaults.colors = {
	power = {
		MANA              = {0.31, 0.45, 0.63},
		INSANITY          = {0.40, 0.00, 0.80},
		MAELSTROM         = {0.00, 0.50, 1.00},
		LUNAR_POWER       = {0.93, 0.51, 0.93},
		HOLY_POWER        = {0.95, 0.90, 0.60},
		RAGE              = {0.69, 0.31, 0.31},
		FOCUS             = {0.71, 0.43, 0.27},
		ENERGY            = {0.65, 0.63, 0.35},
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
	},
	class = {
		DEATHKNIGHT = { 0.77, 0.12, 0.24 },
		DRUID       = { 1.00, 0.49, 0.03 },
		HUNTER      = { 0.67, 0.84, 0.45 },
		MAGE        = { 0.41, 0.80, 1.00 },
		PALADIN     = { 0.96, 0.55, 0.73 },
		PRIEST      = { 0.83, 0.83, 0.83 },
		ROGUE       = { 1.00, 0.95, 0.32 },
		SHAMAN      = { 0.16, 0.31, 0.61 },
		WARLOCK     = { 0.58, 0.51, 0.79 },
		WARRIOR     = { 0.78, 0.61, 0.43 },
		MONK        = { 0.00, 1.00, 0.59 },
		DEMONHUNTER = { 0.64, 0.19, 0.79 },
	},
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
		disconnected = { 0.1, 0.1, 0.1 },
		tapped = { 0.1, 0.1, 0.1 },
	},
	roles = {
		TANK = { .2, .5, .8 },
		HEALER = { .5, .8, .2 },
		DAMAGER = {.8, .2, .4 },
	},
	runes = {
		[1] = {0.69, 0.31, 0.31},
		[2] = {0.41, 0.80, 1.00},
		[3] = {0.65, 0.63, 0.35},
	}
}

st.defaults.unitframes = {
	config_unit = 'player',
	config_element = 'general',
	
	units = {
		['**'] = {
			enable = true,
			width = 200,
			height = 30,
			position = {'CENTER', 'UIParent', 'CENTER',  0, 0},
			template = 'none',
			range_alpha = {
				inside = 1,
				outside = 0.3,
			},
			['**'] = {
				enable = true,
				relative_width = true,
				width = 0,
				relative_height = true,
				height = 0,
				position = {'CENTER'},
				framelevel = 0,
			},
			health = {
				position = {'CENTER', 'CENTER', 0, 0},
				framelevel = 15,
				height = -10,
				template = 'thin',
				bg = {
					enable = true,
					alpha = 1,
					multiplier = 0.6,
				},
				text = {
					enable = true,
					hide_full = false,
					percent = false,
					font = 'pixel',
					position = {'RIGHT', 'RIGHT', -3, 0},
				},
				Smooth = true,
				colorTapping = false,
				colorDisconnected = false,
				colorHealth = false,
				colorClass = false,
				colorClassNPC = false,
				colorClassPet = false,
				colorReaction = false,
				colorSmooth = false,
				colorCustom = true,
				customColor = { 0.25, 0.25, 0.25},
			},
			power = {
				position = {'CENTER', 'CENTER', 0, 0},
				framelevel = 10,
				template = 'thin',
				bg = {
					enable = true,
					alpha = 1,
					multiplier = .6,
				},
				text = {
					enable = false,
					hide_full = false,
					percent = false,
					font = 'pixel',
					position = {'LEFT', 'LEFT', 5, 0},
				},
				Smooth = true,
				colorTapping = false,
				colorDisconnected = false,
				colorPower = false,
				colorClass = true,
				colorClassNPC = false,
				colorClassPet = false,
				colorReaction = true,
				colorSmooth = false,
				colorCustom = false,
				customColor = { 0.25, 0.25, 0.25},
			},
			name = {
				enable = true,
				font = 'pixel',
				position = {'LEFT', 'LEFT', 5, 0},
			}
		},
		player = {
			position = {'RIGHT', 'UIParent', 'CENTER', -100, -200},
			name = {
				enable = false,
			},
			power = { 
				text = {
					enable = true,
				},
			},
		},
		target = {
			position = {'LEFT', 'UIParent', 'CENTER', 100, -200},
		},
		targettarget = {
			width = 100,
			position = {'LEFT', 'SaftUI_Target', 'RIGHT', 7, 0},
			name = {
				enable = false,
			},
		}
	}
}