local ADDON_NAME, st = ...

st.defaults = {}

st.defaults.misc = {
	icon_trim = 0.065,
}

st.defaults.fonts = {
	pixel_huge = {
		name = 'Pixel Huge',
		font_name = 'Homespun',
		font_size = 32,
		font_outline = 'MONOCHROMEOUTLINE',
		shadow_offset = {0, 0},
		spacing = 4,
	},
	pixel_med = {
		name = 'Pixel med',
		font_name = 'Homespun',
		font_size = 32,
		font_outline = 'MONOCHROMEOUTLINE',
		shadow_offset = {0, 0},
		spacing = 4,
	},
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
		font_outline = 'NONE',
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
		position = {'TOP', 'BOTTOM', 0, -6},
	},
	timer_bar = {
		enable = false,
		template = 'thick',
		position = {'TOP', 'BOTTOM', 0, -7},
		width = 30,
		height = 3,
		color_time = true,
		custom_color = { 0.16, 0.51, 0.91 },
	},
	buffs = {
		growth_direction = 'LEFT',
		position = {'TOPRIGHT', 'Minimap', 'TOPLEFT', -20, 0},
	},
	debuffs = {
		growth_direction = 'LEFT',
		position = {'BOTTOMRIGHT', 'Minimap', 'BOTTOMLEFT', -20, 0},
	}
}

st.defaults.loot = {
	popup = {
		template = 'thick',
		font = 'pixel',
		name_wrap = true,
		width = 200,
		button_height = 30,
		spacing = 7,
	},
	roll = {
		height = 30,
		width = 400,
		spacing = 7,
		template = 'thick',
		position = {'BOTTOMLEFT', 'UIParent', 'LEFT', 20, -300},
		font = 'pixel',
		grow_down = false,
	}
}

st.defaults.addon_skins = {
	font = 'pixel',
	template = 'thicktransparent',
}

st.defaults.addon_manager = {
	font = 'normal',
	num_rows = 18,
	row_height = 20,
	spacing = 7,
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
		bordercolor = { 0.4, 0.4, 0.4, 1.0 },
		altbordercolor = { 0, 0, 0, 1.0 },
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

st.defaults.headers = {
	height = 21,
	font = 'normal',
}

st.defaults.buttons = {
	font = 'pixel',
	template = 'thick',
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
		size = 160,
		position = {point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -20, y_off = -20},
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
	fontsize = 14,
	linespacing = 5,
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
	font = 'pixel',
	template = 'thicktransparent',
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
	buttonheight = 20,
	buttonwidth = 30,
	buttonspacing = 7,
	categoryspacing = 10,
	autorepair = true,
	autovendor = true,
	fonts = {
		titles = 'normal',
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
	font = 'pixel',
	hide_empty = true,

	['**'] = {
		enable = true,
		template = 'thicktransparent',
		padding_y = 7,
		padding_x = 7,
		spacing = 8,
		height = 20,
		width = 30,
		alpha = 1,
		ooc_alpha = 1,
		total = 12,
		perrow = 12,
		backdrop = {
			enable = false,
			conform = true,
			template = 'thick',
			width = 12,
			height = 1,
			padding = 6,
			anchor = 'BOTTOMLEFT',
		}
	},
	[1] = {
		position = {point = 'BOTTOM', frame = 'UIParent', rel_point = 'BOTTOM', x_off = 0, y_off = 20},
		backdrop = {
			enable = true,
			height = 3,
		}
	},
	[2] = {
		position = {point = 'BOTTOM', frame = ADDON_NAME..'ActionBar1', rel_point = 'TOP', x_off = 0, y_off = 8},
	},
	[3] = {
		position = {point = 'BOTTOM', frame = ADDON_NAME..'ActionBar2', rel_point = 'TOP', x_off = 0, y_off = 8},
	},
	[4] = {
		position = {point = 'RIGHT', frame = 'UIParent', rel_point = 'RIGHT', x_off = -20, y_off = 0},
		perrow = 1,
	},
	[5] = {
		position = {point = 'RIGHT', frame = ADDON_NAME..'ActionBar4', rel_point = 'LEFT', x_off = -8, y_off = 0},
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
		white			= { 1, 1, 1, 1 },
	},
	button = {
		normal		= { 0.1, 0.1, 0.1, 0.6 },
		hover 		= { 0.3, 0.5, 0.7, 0.8 },
		red			= { 0.6, 0.1, 0.1, 0.8 },
		green			= { 0.1, 0.6, 0.1, 0.8 },
		blue			= { 0.0, 0.68, 0.94, 0.1 },
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
		disconnected = { 0.6, 0.6, 0.6 },
		tapped = { 0.6, 0.6, 0.6 },
	}
}

st.defaults.unitframes = {
	config_unit = 'player',
	config_element = 'general',
	config_profile = 'SaftUI',
	profiles = {
		['**'] = {
			['**'] = {
				enable = true,
				width = 201,
				height = 28,
				position = {point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER',  x_off = 0, y_off = 0},
				template = 'none',
				range_alpha = {
					inside = 1,
					outside = 0.6,
				},
				['**'] = {
					enable = true,
					relative_width = true,
					width = 0,
					relative_height = true,
					height = 0,
					position = {point = 'CENTER', rel_point = 'CENTER', x_off = 0, y_off = 0},
					framelevel = 0,
					template = 'none',
					alpha = 1,
				},
				portrait = {
					alpha = 1,
					framelevel = 20,
					template = "thick",
					height = 0,
					relative_width = false,
					width = 40,
					position = {
						rel_point = "TOPLEFT",
						point = "TOPRIGHT",
						x_off = "-7",
						anchor_element = "Health",
						y_off = "0",
					},
				},
				castbar = {
					enable = false,
					position = {
						rel_point = "CENTER",
						point = "TOPLEFT",
						y_off = "-200",
						x_off = "-85",
						anchor_frame = "UIParent",
						anchor_element = "Health",
						frame_type = true,
					},
					framelevel = 15,
					height = 20,
					relative_width = false,
					width = 200,
					relative_height = false,
					template = 'thicktransparent',
					colors = {
						normal = { .3, .4, .6 },
						nointerrupt = { .6, .3, .3 },
					},
					text = {
						enable = true,
						position = {
							rel_point = "LEFT",
							point = "LEFT",
							anchor_element = "Castbar",
							x_off = "7",
							frame_type = false,
							y_off = "0",
						},
						font = 'pixel',
					},
					time = {
						enable = true,
						position = {
							rel_point = "RIGHT",
							point = "RIGHT",
							anchor_element = "Castbar",
							x_off = "-5",
							frame_type = false,
							y_off = "0",
						},
						font = 'pixel',
					},
					icon = {
						enable = true,
						position = {
							rel_point = "TOPLEFT",
							point = "TOPRIGHT",
							frame_type = false,
							x_off = "-7",
							anchor_element = "Castbar",
						},
						framelevel = 15,
						height = 20,
						relative_height = false,
						width = 20,
						relative_width = false,
						template = 'thick',
					}
				},
				health = {
					template = "thick",
					position = { rel_point = "TOPLEFT", x_off = "0", point = "TOPLEFT", y_off = "0" },
					height = -8,
					framelevel = 10,
					reverse_fill = false,
					vertical_fill = false,
					text = {
						enable = true,
						hide_full = false,
						percent = false,
						font = 'pixel',
						position = {
							point = "RIGHT",
							anchor_element = "Health",
							rel_point = "RIGHT",
							x_off = -5,
							y_off = 0,
							frame_type = false,
						},
						tags = 'deficit'
					},
					bg = {
						enable = true,
						alpha = 1,
						multiplier = 0.6,
					},
					Smooth = true,
					colorTapping = true,
					colorDisconnected = true,
					colorHealth = false,
					colorClass = false,
					colorClassNPC = false,
					colorClassPet = false,
					colorReaction = false,
					colorSmooth = false,
					colorCustom = true,
					customColor = { 0.3, 0.3, 0.3},
				},
				power = {
					relative_height = false,
					framelevel = 16,
					template = "thick",
					width = "-70",
					position = {
						rel_point = "BOTTOMLEFT",
						y_off = "0",
						anchor_element = "Health",
						point = "BOTTOMLEFT",
						x_off = "7",
					},
					height = "13",
					reverse_fill = false,
					vertical_fill = false,
					bg = {
						enable = true,
						alpha = 1,
						multiplier = .6,
					},
					text = {
						enable = true,
						hide_full = false,
						percent = false,
						font = 'pixel',
						position = {
							rel_point = "RIGHT",
							point = "RIGHT",
							y_off = 1,
							anchor_element = "Power",
							frame_type = false,
							x_off = 0,
						},
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
						spacing = 7,
						template = 'thick',
						font = 'pixel',
						max = 8,
						per_row = 8,
						grow_up = true,
						grow_right = true,
						initial_anchor = 'BOTTOMLEFT',
						framelevel = 50,
						cooldown = {
							enable = true,
							timer = false,
							reverse = true,
							alpha = 0.7
						},
						filter = {
							['**'] = {
								whitelist = {
									enable = true,
									filters = {
										yours = true,
										others = false,
										dispellable = true,
										auras = true,
									}
								},
								blacklist = {
									enable = false,
									filters = {
										yours = false,
										others = false,
										dispellable = false,
										auras = true,
									}
								},
							},
						}
					},
					buffs = {
						enable = true,
						position = {
							rel_point = "BOTTOMLEFT",
							point = "TOPLEFT",
							anchor_element = "Power",
							frame_type = false,
							x_off = "0",
							y_off = "-3",
						},
						size = 13,
						spacing = 3,
						per_row = 9,
						framelevel = 15,
					},
					debuffs = {
						enable = false,
						border = 'all',
						position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 31},
					}
				},
				name = {
					enable = true,
					max_length = 30,
					show_level = true,
					all_caps = false,
					show_samelevel = true,
					show_classification = true,
					font = 'pixel',
					position = {
						rel_point = "TOPRIGHT",
						x_off = "-4",
						point = "BOTTOMRIGHT",
						y_off = "6",
					},
					tag = '[st:level] [st:name]',
				}
			},
			player = {
				width = 202,
				position = {point = 'RIGHT', frame = 'UIParent', rel_point = 'CENTER', x_off = -150, y_off = -150},
				castbar = {
					enable = true,
				},
				name = {
					enable = true,
				},
				health = {
					text = {
						hide_full = true,
						deficit = true,
					},
				},
				power = { 
					text = {
						enable = true,
					},
				},
				auras = {
					debuffs = {
						enable = true,
						position = {point = 'RIGHT', rel_point = 'LEFT', x_off = -7, y_off = 0},
						horizontal_growth = 'LEFT',
						initial_anchor = 'RIGHT',
						size = 30,
						filter = {
							friend = {
								grow_right = false,
							}
						}
					}
				}
			},
			target = {
				position = {point = 'LEFT', frame = 'UIParent', rel_point = 'CENTER', x_off = 150, y_off = -150},
				name = {
					position = {
						rel_point = "TOPLEFT",
						x_off = "5",
						point = "BOTTOMLEFT",
					},
				},
				castbar = {
					enable = true,
					position = {
						point = 'TOPRIGHT',
						y_off = -227,
						x_off = 88,
					},
					icon = {
						position = {
							rel_point = "TOPRIGHT",
							point = "TOPLEFT",
							anchor_element = "Castbar",
							x_off = "7",
							frame_type = false,
						},
					},
				},
				auras = {
					buffs = {
						enable = true,
					},
					debuffs = {
						enable = true,
					}
				},
				portrait = {
					position = {
						point = 'LEFT',
						rel_point = 'RIGHT',
						x_off = 7,
					},
				},
				health = {
					reverse_fill = true,
					text = {
						position = {
							point = 'LEFT',
							rel_point = 'LEFT',
							x_off = 5,
						}
					}
				},
				power = {
					reverse_fill = true,
					position = {
						point = 'BOTTOMRIGHT',
						rel_point = 'BOTTOMRIGHT',
						x_off = -7
					},
					text = {
						position = {
							point = 'LEFT',
							rel_point = 'LEFT',
							x_off = 2,
						},
					}
				}
			},
			targettarget = {
				width = 100,
				position = {point = 'LEFT', frame = 'SaftUI_Target_Portrait', rel_point = 'RIGHT', x_off = 7, y_off = 0},
				name = {
					enable = false,
				},
				power = {
					width = -50,
				},
				portrait = {
					enable = false
				}
			},
			party = {
				width = 202,
				spacing = 24,
				growthDirection = 'BOTTOM',
				maxColumns = 1,
				unitsPerColumn = 5,
				columnSpacing = 0,
				initialAnchor = 'TOP',
				position = {point = 'TOPLEFT', frame = 'SaftUI_Player', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -30},
				health = {
					text = {
						hide_full = true,
						deficit = true,
					},
				},
				auras = {
					debuffs = {
						enable = true,
						horizontal_growth = 'LEFT',
						initial_anchor = 'RIGHT',
						size = 30,
						filter = {
							friend = {
								whitelist = {
									filters = {
										yours = false,
										auras = false,
									},
								},
							},
							enemy = {
								whitelist = {
									enable = false,
								},
							},
						},
					}
				}
			},
			raid10 = {
				spacing = 3,
				growthDirection = 'BOTTOM',
				maxColumns = 8,
				unitsPerColumn = 5,
				columnSpacing = 3,
				initialAnchor = 'LEFT',
				position = {point = 'TOPLEFT', frame = 'SaftUI_Player', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -30},
				width = 99,
				height = 26,
				-- template = 'thick',
				portrait = {
					enable = false,
				},
				health = {
					height = -6,
					text = {
						hide_full = true,
						deficit = true,
					},
				},
				power = {
					-- template = 'thin',
				},
				name = {
					enable = false,
				},
				auras = {
					debuffs = {
						template = 'thin',
						per_row = 2,
						max = 2, 
						spacing = 3,
						enable = true,
						position = {point = 'LEFT', rel_point = 'LEFT', x_off = 4, y_off = 0},
						horizontal_growth = 'RIGHT',
						initial_anchor = 'LEFT',
						framelevel = 50,
						size = 8,
					},
				}
			},
			raid40 = {
				spacing = 3,
				growthDirection = 'BOTTOM',
				maxColumns = 8,
				unitsPerColumn = 5,
				columnSpacing = 3,
				initialAnchor = 'LEFT',
				position = {point = 'TOP', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = -250},
				width = 50,
				height = 26,
				-- template = 'thick',
				portrait = {
					enable = false,
				},
				health = {
					-- width = -4,
					height = -6,
					text = {
						hide_full = true,
						deficit = true,
					},
				},
				power = {
					-- template = 'thin',
				},
				name = {
					enable = false,
					show_level = false,
					max_length = 8,
				},
				auras = {
					debuffs = {
						template = 'thin',
						per_row = 2,
						max = 2, 
						spacing = 3,
						enable = true,
						position = {point = 'LEFT', rel_point = 'LEFT', x_off = 4, y_off = 0},
						horizontal_growth = 'RIGHT',
						initial_anchor = 'LEFT',
						framelevel = 50,
						size = 8,
					},
				}
			},
			nameplate = {
				height = 20,
				width = 140,
				portrait = {
					enable = false,
				},
				power = {
					height = 8,
					text = {
						enable = false
					}
				},
				health = {
					height = -6,
					text = {
						position = {x_off = -2},
					},
				},
				name = {
					position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 7},
					max_length = 15,
				},
				castbar = {
					enable = true,
					height = 20,
					icon = {
						width = 20,
						height = 20
					}
				},
				auras = {
					buffs = {
						enable = false,
					},
					debuffs = {
						enable = true,
						position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 24},
						self_only = true,
						show_magic = true,
						cooldown = {
							alpha = 1,
						},
					}
				},
			}
		},
		["SaftUI"] = {
			["party"] = {
				["portrait"] = {
					["relative_width"] = false,
					["template"] = "thick",
					["alpha"] = 1,
					["width"] = "40",
					["position"] = {
						["rel_point"] = "TOPLEFT",
						["point"] = "TOPRIGHT",
						["x_off"] = "-7",
						["anchor_element"] = "Health",
						["y_off"] = "0",
					},
					["height"] = "0",
				},
				["auras"] = {
					["debuffs"] = {
						["filter"] = {
							["friend"] = {
								["whitelist"] = {
									["filters"] = {
										["yours"] = false,
										["auras"] = false,
									},
								},
							},
							["enemy"] = {
								["whitelist"] = {
									["enable"] = false,
								},
							},
						},
					},
					["buffs"] = {
						["enable"] = true,
						["per_row"] = 9,
						["framelevel"] = 15,
						["position"] = {
							["rel_point"] = "BOTTOMLEFT",
							["point"] = "TOPLEFT",
							["anchor_element"] = "Power",
							["frame_type"] = false,
							["x_off"] = "0",
							["y_off"] = "-3",
						},
						["filter"] = {
							["friend"] = {
								["whitelist"] = {
									["filters"] = {
										["dispellable"] = false,
										["auras"] = false,
									},
								},
								["blacklist"] = {
									["enable"] = true,
									["filters"] = {
										["others"] = true,
									},
								},
							},
							["friendly"] = {
								["whitelist"] = {
									["filters"] = {
										["dispellable"] = false,
										["auras"] = false,
									},
								},
							},
							["enemy"] = {
								["whitelist"] = {
									["enable"] = false,
								},
							},
						},
						["spacing"] = 3,
						["size"] = 13,
					},
				},
				["template"] = "none",
				["castbar"] = {
					["relative_width"] = false,
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["rel_point"] = "LEFT",
							["point"] = "LEFT",
							["y_off"] = "0",
							["x_off"] = "5",
							["frame_type"] = false,
							["anchor_element"] = "Castbar",
						},
					},
					["framelevel"] = 10,
					["time"] = {
						["position"] = {
							["rel_point"] = "RIGHT",
							["point"] = "RIGHT",
							["y_off"] = "0",
							["x_off"] = "-5",
							["frame_type"] = false,
							["anchor_element"] = "Castbar",
						},
					},
					["position"] = {
						["rel_point"] = "CENTER",
						["y_off"] = "-200",
						["frame_type"] = true,
						["anchor_element"] = "Health",
						["x_off"] = "-85",
						["anchor_frame"] = "UIParent",
						["point"] = "TOPLEFT",
					},
					["height"] = "20",
					["icon"] = {
						["relative_height"] = false,
						["template"] = "thicktransparent",
						["position"] = {
							["rel_point"] = "TOPLEFT",
							["point"] = "TOPRIGHT",
							["anchor_element"] = "Castbar",
							["frame_type"] = false,
							["x_off"] = "-7",
						},
						["height"] = "20",
						["width"] = "20",
					},
					["width"] = "200",
				},
				["width"] = "202",
				["health"] = {
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["y_off"] = "0",
							["anchor_element"] = "Health",
							["x_off"] = "-5",
							["frame_type"] = false,
						},
					},
					["position"] = {
						["rel_point"] = "TOPLEFT",
						["x_off"] = "0",
						["point"] = "TOPLEFT",
						["y_off"] = "0",
					},
					["height"] = "-8",
					["framelevel"] = 10,
				},
				["position"] = {
					["y_off"] = "-24",
				},
				["height"] = "28",
				["power"] = {
					["relative_height"] = false,
					["framelevel"] = 16,
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["rel_point"] = "RIGHT",
							["point"] = "RIGHT",
							["y_off"] = "1",
							["anchor_element"] = "Power",
							["frame_type"] = false,
							["x_off"] = "0",
						},
						["enable"] = true,
					},
					["width"] = "-70",
					["position"] = {
						["rel_point"] = "BOTTOMLEFT",
						["y_off"] = "0",
						["anchor_element"] = "Health",
						["point"] = "BOTTOMLEFT",
						["x_off"] = "7",
					},
					["height"] = "13",
				},
				["name"] = {
					["position"] = {
						["rel_point"] = "TOPRIGHT",
						["x_off"] = "-4",
						["point"] = "BOTTOMRIGHT",
						["y_off"] = "6",
					},
				},
			},
			["raid40"] = {
				["portrait"] = {
				},
				["power"] = {
					["relative_height"] = false,
					["framelevel"] = 15,
					["template"] = "thick",
					["width"] = "-20",
					["position"] = {
						["rel_point"] = "BOTTOMRIGHT",
						["x_off"] = "-5",
						["point"] = "BOTTOMRIGHT",
						["y_off"] = "2",
					},
					["height"] = "4",
				},
				["width"] = "50",
				["castbar"] = {
				},
				["name"] = {
				},
				["position"] = {
					["y_off"] = "-260",
				},
				["height"] = "24",
				["auras"] = {
					["debuffs"] = {
						["position"] = {
							["rel_point"] = "TOPLEFT",
							["x_off"] = "2",
							["point"] = "TOPLEFT",
							["y_off"] = "-2",
						},
					},
				},
				["health"] = {
					["framelevel"] = 10,
					["text"] = {
						["position"] = {
							["rel_point"] = "TOPRIGHT",
							["x_off"] = "-2",
							["point"] = "TOPRIGHT",
							["y_off"] = "-3",
						},
					},
					["height"] = "0",
				},
			},
			["target"] = {
				["portrait"] = {
					["relative_width"] = false,
					["template"] = "thick",
					["alpha"] = 1,
					["width"] = "40",
					["position"] = {
						["rel_point"] = "TOPRIGHT",
						["point"] = "TOPLEFT",
						["x_off"] = "7",
						["anchor_element"] = "Health",
						["y_off"] = "0",
					},
					["height"] = "0",
				},
				["castbar"] = {
					["relative_width"] = false,
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["rel_point"] = "LEFT",
							["point"] = "LEFT",
							["y_off"] = "0",
							["x_off"] = "7",
							["frame_type"] = false,
							["anchor_element"] = "Castbar",
						},
					},
					["framelevel"] = 10,
					["time"] = {
						["position"] = {
							["rel_point"] = "RIGHT",
							["point"] = "RIGHT",
							["y_off"] = "0",
							["x_off"] = "-5",
							["frame_type"] = false,
							["anchor_element"] = "Castbar",
						},
					},
					["position"] = {
						["rel_point"] = "CENTER",
						["y_off"] = "-227",
						["frame_type"] = true,
						["anchor_element"] = "Health",
						["x_off"] = "88",
						["anchor_frame"] = "UIParent",
						["point"] = "TOPRIGHT",
					},
					["height"] = "20",
					["icon"] = {
						["relative_height"] = false,
						["template"] = "thicktransparent",
						["position"] = {
							["rel_point"] = "TOPRIGHT",
							["point"] = "TOPLEFT",
							["anchor_element"] = "Castbar",
							["x_off"] = "7",
							["frame_type"] = false,
						},
						["height"] = "20",
						["width"] = "20",
					},
					["width"] = "200",
				},
				["auras"] = {
					["debuffs"] = {
						["filter"] = {
							["friend"] = {
								["grow_right"] = false,
								["desaturate"] = true,
							},
						},
						["position"] = {
							["rel_point"] = "BOTTOMLEFT",
							["y_off"] = "-7",
							["x_off"] = "0",
							["anchor_element"] = "Buffs",
							["frame_type"] = false,
							["point"] = "TOPLEFT",
						},
						["initial_anchor"] = "LEFT",
						["horizontal_growth"] = "LEFT",
					},
					["buffs"] = {
						["position"] = {
							["rel_point"] = "BOTTOMLEFT",
							["y_off"] = "-7",
							["point"] = "TOPLEFT",
						},
						["initial_anchor"] = "TOPLEFT",
						["grow_up"] = false,
						["filter"] = {
							["friend"] = {
								["whitelist"] = {
									["enable"] = false,
								},
							},
						},
					},
				},
				["health"] = {
					["framelevel"] = 10,
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["rel_point"] = "LEFT",
							["y_off"] = "0",
							["x_off"] = "5",
							["anchor_element"] = "Health",
							["frame_type"] = false,
							["point"] = "LEFT",
						},
						["deficit"] = false,
					},
					["reverse_fill"] = true,
					["position"] = {
						["rel_point"] = "TOPLEFT",
						["x_off"] = "0",
						["point"] = "TOPLEFT",
						["y_off"] = "0",
					},
					["height"] = "-8",
				},
				["position"] = {
					["point"] = "BOTTOMLEFT",
				},
				["height"] = "28",
				["power"] = {
					["relative_height"] = false,
					["framelevel"] = 16,
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["y_off"] = "1",
							["frame_type"] = false,
							["x_off"] = "2",
							["anchor_element"] = "Power",
						},
						["enable"] = true,
					},
					["reverse_fill"] = true,
					["position"] = {
						["rel_point"] = "BOTTOMRIGHT",
						["y_off"] = "0",
						["anchor_element"] = "Health",
						["point"] = "BOTTOMRIGHT",
						["x_off"] = "-7",
					},
					["height"] = "13",
					["width"] = "-70",
				},
				["name"] = {
					["position"] = {
						["rel_point"] = "TOPLEFT",
						["y_off"] = "5",
						["anchor_element"] = "Health",
						["x_off"] = "5",
						["frame_type"] = false,
						["point"] = "BOTTOMLEFT",
					},
				},
				["template"] = "none",
			},
			["targettarget"] = {
				["template"] = "none",
				["power"] = {
					["relative_height"] = false,
					["framelevel"] = 15,
					["template"] = "thick",
					["text"] = {
						["font"] = "pixel_med",
						["position"] = {
							["y_off"] = "2",
							["x_off"] = "0",
							["anchor_element"] = "Power",
							["frame_type"] = true,
							["point"] = "RIGHT",
						},
					},
					["width"] = "-40",
					["position"] = {
						["rel_point"] = "BOTTOMLEFT",
						["x_off"] = "5",
						["point"] = "BOTTOMLEFT",
					},
					["height"] = "13",
				},
				["auras"] = {
					["debuffs"] = {
						["horizontal_growth"] = "LEFT",
						["position"] = {
							["rel_point"] = "LEFT",
							["x_off"] = -7,
							["point"] = "RIGHT",
							["y_off"] = 0,
						},
						["initial_anchor"] = "RIGHT",
						["filter"] = {
							["enemy"] = {
								["desaturate"] = false,
							},
						},
						["size"] = 30,
					},
				},
				["castbar"] = {
					["position"] = {
						["frame_type"] = true,
					},
					["icon"] = {
						["position"] = {
							["anchor_element"] = "Castbar",
						},
						["enable"] = false,
					},
				},
				["name"] = {
					["max_length"] = 10,
					["enable"] = true,
					["position"] = {
						["rel_point"] = "TOPLEFT",
						["x_off"] = "4",
						["point"] = "BOTTOMLEFT",
						["y_off"] = "5",
					},
					["show_level"] = false,
				},
				["position"] = {
					["y_off"] = "0",
					["x_off"] = "58",
				},
				["height"] = "28",
				["width"] = "100",
				["health"] = {
					["template"] = "thick",
					["text"] = {
						["deficit"] = false,
						["position"] = {
							["x_off"] = "5",
							["point"] = "LEFT",
							["y_off"] = "2",
						},
						["enable"] = false,
						["font"] = "pixel_med",
					},
					["position"] = {
						["rel_point"] = "TOP",
						["point"] = "TOP",
					},
					["height"] = "-8",
					["framelevel"] = 10,
				},
				["portrait"] = {
					["enable"] = false,
				},
			},
			["player"] = {
				["template"] = "none",
				["castbar"] = {
					["relative_width"] = false,
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["rel_point"] = "LEFT",
							["point"] = "LEFT",
							["anchor_element"] = "Castbar",
							["x_off"] = "7",
							["frame_type"] = false,
							["y_off"] = "0",
						},
					},
					["framelevel"] = 10,
					["time"] = {
						["position"] = {
							["rel_point"] = "RIGHT",
							["point"] = "RIGHT",
							["anchor_element"] = "Castbar",
							["x_off"] = "-5",
							["frame_type"] = false,
							["y_off"] = "0",
						},
					},
					["position"] = {
						["rel_point"] = "CENTER",
						["point"] = "TOPLEFT",
						["y_off"] = "-200",
						["x_off"] = "-85",
						["anchor_frame"] = "UIParent",
						["anchor_element"] = "Health",
						["frame_type"] = true,
					},
					["height"] = "20",
					["icon"] = {
						["relative_height"] = false,
						["template"] = "thicktransparent",
						["position"] = {
							["rel_point"] = "TOPLEFT",
							["point"] = "TOPRIGHT",
							["frame_type"] = false,
							["x_off"] = "-7",
							["anchor_element"] = "Castbar",
						},
						["height"] = "20",
						["width"] = "20",
					},
					["width"] = "200",
				},
				["auras"] = {
					["debuffs"] = {
						["filter"] = {
							["friend"] = {
								["whitelist"] = {
									["filters"] = {
										["yours"] = false,
										["auras"] = false,
									},
								},
							},
							["enemy"] = {
								["whitelist"] = {
									["enable"] = false,
								},
							},
						},
					},
					["buffs"] = {
						["enable"] = true,
						["per_row"] = 9,
						["framelevel"] = 15,
						["filter"] = {
							["friendly"] = {
								["whitelist"] = {
									["filters"] = {
										["dispellable"] = false,
										["auras"] = false,
									},
								},
							},
							["friend"] = {
								["whitelist"] = {
									["filters"] = {
										["dispellable"] = false,
										["auras"] = false,
									},
								},
								["blacklist"] = {
									["enable"] = true,
									["filters"] = {
										["others"] = true,
									},
								},
							},
							["enemy"] = {
								["whitelist"] = {
									["enable"] = false,
								},
							},
						},
						["spacing"] = 3,
						["position"] = {
							["rel_point"] = "BOTTOMLEFT",
							["point"] = "TOPLEFT",
							["anchor_element"] = "Power",
							["frame_type"] = false,
							["x_off"] = "0",
							["y_off"] = "-3",
						},
						["size"] = 13,
					},
				},
				["power"] = {
					["relative_height"] = false,
					["framelevel"] = 16,
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["rel_point"] = "RIGHT",
							["point"] = "RIGHT",
							["x_off"] = "0",
							["anchor_element"] = "Power",
							["frame_type"] = false,
							["y_off"] = "1",
						},
					},
					["width"] = "-70",
					["position"] = {
						["rel_point"] = "BOTTOMLEFT",
						["y_off"] = "0",
						["x_off"] = "7",
						["anchor_element"] = "Health",
						["point"] = "BOTTOMLEFT",
					},
					["height"] = "13",
				},
				["name"] = {
					["position"] = {
						["rel_point"] = "TOPRIGHT",
						["x_off"] = "-4",
						["point"] = "BOTTOMRIGHT",
						["y_off"] = "6",
					},
				},
				["position"] = {
					["point"] = "BOTTOMRIGHT",
				},
				["height"] = "28",
				["health"] = {
					["template"] = "thick",
					["text"] = {
						["position"] = {
							["y_off"] = "0",
							["x_off"] = "-5",
							["frame_type"] = false,
							["anchor_element"] = "Health",
						},
					},
					["position"] = {
						["rel_point"] = "TOPLEFT",
						["x_off"] = "0",
						["point"] = "TOPLEFT",
						["y_off"] = "0",
					},
					["height"] = "-8",
					["framelevel"] = 10,
				},
				["portrait"] = {
					["relative_width"] = false,
					["template"] = "thick",
					["alpha"] = 1,
					["width"] = "40",
					["position"] = {
						["rel_point"] = "TOPLEFT",
						["y_off"] = "0",
						["x_off"] = "-7",
						["point"] = "TOPRIGHT",
						["anchor_element"] = "Health",
					},
					["height"] = "0",
				},
				["width"] = "202",
			},
		},
	}
}