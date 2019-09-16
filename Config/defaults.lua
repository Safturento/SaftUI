local ADDON_NAME, st = ...

st.defaults = {}

st.defaults.misc = {
	icon_trim = 0.03,
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
		font_size = 14,
		font_outline = '',
		shadow_offset = {0, 0},
		spacing = 4,
	}
}

st.defaults.auras = {
	enable = true,
	size = 30,
	font = 'pixel',
	template = 'thick',
	spacing = 8,
	timer_text = {
		enable = true,
		position = {'TOP', 'BOTTOM', 0, -14},
	},
	timer_bar = {
		enable = true,
		template = 'thick',
		position = {'TOP', 'BOTTOM', 0, -7},
		width = 30,
		height = 3,
		color_time = true,
		custom_color = { 0.16, 0.51, 0.91 },
	},
	buffs = {
		growth_direction = 'LEFT',
		position = {'TOPRIGHT', Minimap, 'TOPLEFT', -20, 0},
	},
	debuffs = {
		growth_direction = 'LEFT',
		position = {'BOTTOMRIGHT', Minimap, 'BOTTOMLEFT', -20, 0},
	}
}

st.defaults.loot = {
	roll = {
		height = 20,
		width = 300,
		spacing = 7,
		template = 'thick',
		position = {'BOTTOM', UIParent, 'BOTTOM', 0, 200},
		font = 'pixel',
		grow_down = false,
	}
}
st.defaults.templates = {
	highlight = {
		name = 'Highlight',
		bordercolor = { 0.3, 0.3, 0.3, 1 },
		altbordercolor = { 0.0, 0.0, 0.0, 1 },
		backdropcolor = { 0.3, 0.3, 0.3, 0.4 },
		border = false,
		thick = true,
	},
	close = {
		name = 'Close Button',
		bordercolor = { 0.3, 0.3, 0.3, 1 },
		altbordercolor = { 0.0, 0.0, 0.0, 1 },
		backdropcolor = { 0.5, 0.1, 0.1, 0.4 },
		border = false,
		thick = true,
	},
	thin = {
		name = 'Thin',
		bordercolor = { 0, 0, 0, 1.0 },
		altbordercolor = { 0.0, 0.0, 0.0, 0.0 },
		backdropcolor = { 0.2, 0.2, 0.2, 1 },
		border = true,
		thick = false,
	},
	thick = {
		name = 'Thick',
		bordercolor = { 0.4, 0.4, 0.4, 1.0 },
		altbordercolor = { 0, 0, 0, 1.0 },
		backdropcolor = { 0.15, 0.15, 0.15, 1 },
		border = true,
		thick = true,
	}
}

st.defaults.templates.thintransparent = st.tablecopy(st.defaults.templates.thin, true)
st.defaults.templates.thintransparent.name = 'ThinTransparent'
st.defaults.templates.thintransparent.backdropcolor[4] = 0.75

st.defaults.templates.thicktransparent = st.tablecopy(st.defaults.templates.thick, true)
st.defaults.templates.thicktransparent.name = 'ThickTransparent'
st.defaults.templates.thicktransparent.backdropcolor[4] = 0.75

st.defaults.headers = {
	height = 20,
	font = 'pixel',
}


st.defaults.maps = {
	minimap = {
		enable = true,
		template = 'thick',
		size = 160,
		position = {'TOPRIGHT', -20, -20},
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
	fontsize = 15,
	linespacing = 4,
	fadetabs = true,
	tabs = {
		height = 25,
		fade = true,
	},
	editbox = {
		height = 25,
	}
}

st.defaults.skinning = {
	addons = {
		weakauras = {
			template = 'thick',
		},
		dominos = {
			template = 'thin',
		}
	}
}

st.defaults.experience = {
	width = st.defaults.maps.minimap.size,
	height = 14,
	spacing = 8,
	rest_alpha = 1,
	template = 'thicktransparent',
	position = {'TOP', 'Minimap', 'BOTTOM', 0, -8},
}

st.defaults.inventory = {
	enable = true,
	buttontemplate = 'thicktransparent',
	template = 'thicktransparent',
	padding = 10,
	buttonsize = 30,
	buttonspacing = 7,
	categoryspacing = 10,
	autorepair = true,
	autovendor = true,
	fonts = {
		titles = 'pixel',
		icons = 'pixel',
	},
	bag = {
		position = {'BOTTOMRIGHT', -20, 20},
		perrow = 8,
	},
	bank = {
		position = {'TOPLEFT', 200, -200},
		perrow = 10,
	}
}

st.defaults.actionbars = {
	template = 'none',
	font = 'pixel',
	hide_empty = true,

	['**'] = {
		enable = true,
		template = 'thicktransparent',
		padding_y = 0,
		padding_x = 0,
		spacing = 8,
		size = 30,
		alpha = 1,
		ooc_alpha = 1,
		total = 12,
		perrow = 12,
	},
	[1] = {
		position = {'BOTTOM', UIParent, 'BOTTOM', 0, 20},
	},
	[2] = {
		position = {'BOTTOM', ADDON_NAME..'ActionBar1', 'TOP', 0, 8},
	},
	[3] = {
		position = {'BOTTOM',  ADDON_NAME..'ActionBar2', 'TOP', 0, 8},
	},
	[4] = {
		position = {'RIGHT',  UIParent, 'RIGHT', -20, 0},
		perrow = 1,
	},
	[5] = {
		position = {'RIGHT',  ADDON_NAME..'ActionBar4', 'LEFT', -8, 0},
		perrow = 1,
	}
}

st.defaults.colors = {
	text = {
		normal		= { 0.9, 0.9, 0.8, 1.0 },
		red			= { 220/255, 100/255, 100/255 },
		orange 		= { 220/255, 150/255, 100/255 },
		yellow		= { 200/255, 200/255, 100/255 }, 
		green			= { 60/255, 240/255,  60/255 }, 
		grey			= { 150/255, 150/255,  150/255 }, 
	},
	button = {
		normal		= { 0.1, 0.1, 0.1, 0.6 },
		hover 		= { 0.3, 0.5, 0.7, 0.8 },
		red			= { 0.6, 0.1, 0.1, 0.8 },
		green			= { 0.1, 0.6, 0.1, 0.8 },
		blue			= { 0.0, 0.68, 0.94, 0.1 },
		yellow		= { 0.6, 0.6, 0.1, 0.8 },
	},
	experience = {
		normal = { 0.6, 0.3, 0.8, 1.0 },
		rested = { 0.3, 0.6, 0.8, 1.0 },
	},
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
		-- DEATHKNIGHT = { 0.77, 0.12, 0.24 },
		DRUID       = { 1.00, 0.49, 0.03 },
		HUNTER      = { 0.67, 0.84, 0.45 },
		MAGE        = { 0.41, 0.80, 1.00 },
		PALADIN     = { 0.96, 0.55, 0.73 },
		PRIEST      = { 0.83, 0.83, 0.83 },
		ROGUE       = { 1.00, 0.95, 0.32 },
		SHAMAN      = { 0.16, 0.51, 0.91 },
		WARLOCK     = { 0.58, 0.51, 0.79 },
		WARRIOR     = { 0.78, 0.61, 0.43 },
		MONK        = { 0.00, 1.00, 0.59 },
		-- DEMONHUNTER = { 0.64, 0.19, 0.79 },
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
			width = 201,
			height = 30,
			position = {'CENTER', 'UIParent', 'CENTER',  0, 0},
			template = 'thick',
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
				position = {'CENTER', 'CENTER', 0, 0},
				framelevel = 0,
				template = 'none',
			},
			portrait = {
				alpha = 0.1,
				framelevel = 20,
				height = -10
			},
			castbar = {
				enable = false,
				position = {'BOTTOM', 'BOTTOM', 0, 0},
				framelevel = 15,
				height = 4,
				relative_width = true,
				width = 0,
				relative_height = false,
				template = 'thin',
				colors = {
					normal = { .3, .4, .6 },
					nointerrupt = { .6, .3, .3 },
				},
				text = {
					enable = true,
					position = {'TOPLEFT', 'BOTTOMLEFT', 0, -5},
					font = 'pixel',
				},
				time = {
					enable = true,
					position = {'TOPRIGHT', 'BOTTOMRIGHT', 4, -5},
					font = 'pixel',
				},
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
			auras = {
				['**'] = {
					enable = false,
					size = 19,
					spacing = 6,
					template = 'thick',
					font = 'pixel',
					max = 8,
					per_row = 8,
					self_only = false,
					vertical_growth = 'TOP',
					horizontal_growth = 'RIGHT',
					initial_anchor = 'BOTTOMLEFT',
				},
				buffs = {
					position = {'BOTTOM', 'TOP', 0, 6},
				},
				debuffs = {
					position = {'BOTTOM', 'TOP', 0, 31},
				}
			},
			name = {
				enable = true,
				max_length = 30,
				show_level = true,
				show_samelevel = true,
				show_classification = true,
				font = 'pixel',
				position = {'LEFT', 'LEFT', 5, 0},
			}
		},
		player = {
			position = {'RIGHT', 'UIParent', 'CENTER', -150, -150},
			castbar = {
				enable = true,
			},
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
			position = {'LEFT', 'UIParent', 'CENTER', 150, -150},
			castbar = {
				enable = true,
			},
			buffs = {
				enable = true,
			},
			debuffs = {
				enable = true,
			}
		},
		targettarget = {
			width = 100,
			position = {'LEFT', 'SaftUI_Target', 'RIGHT', 7, 0},
			name = {
				enable = false,
			},
		},
		party = {
			spacing = 7,
			growthDirection = 'BOTTOM',
			maxColumns = 1,
			unitsPerColumn = 5,
			columnSpacing = 0,
			initialAnchor = 'TOP',
			position = {'TOP', 'SaftUI_Player', 'BOTTOM', 0, -30}
		}
	}
}