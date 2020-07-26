local ADDON_NAME, st = ...

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
				questindicator = {
					enable = false,
					size = 16,
					position = {
						point = 'RIGHT',
						rel_point = 'LEFT',
						x_off = -7,
					},
				},
				raidroleindicator = {
					size = 16,
					enable = true,
					position = {
						point = 'CENTER',
						rel_point = 'TOPRIGHT',
						anchor_element = 'Health',
						frame_type = false,
						x_off = 0,
						y_off = 0,
					}
				},
				grouproleindicator = {
					size = 16,
					show_dps = false,
					position = {
						enable = false,
						point = 'CENTER',
						rel_point = 'TOPLEFT',
						anchor_element = 'Portrait',
						frame_type = false,
						x_off = 0,
						y_off = 0,
					}
				},
				raidtargetindicator = {
					size = 16,
					position = {
						enable = true,
						point = 'CENTER',
						rel_point = 'TOP',
						anchor_element = 'Portrait',
						frame_type = false,
						x_off = 0,
						y_off = 0,
					}
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
					relative_height = false,
					height = 4,
					position = {
						point = "TOPLEFT",
						rel_point = "BOTTOMLEFT",
						y_off = "0",
						x_off = "0",
					},
					framelevel = 15,
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
						initial_anchor = 'TOPLEFT',
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
				position = {point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'CENTER', x_off = -150, y_off = -150},
				castbar = {
					enable = true,
					height = 20,
					relative_width = false,
					width = 173,
					relative_height = false,
					position = {
						rel_point = "CENTER",
						point = "TOPLEFT",
						x_off = "-73",
						y_off = "-177",
						anchor_frame = "UIParent",
						frame_type = true,
					},
				},
				raidroleindicator = {
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
				},
				classpower = {
					enable = true,
					relative_width = false,
					relative_height = false,
					width = 200,
					height = 20,
					spacing = 7,
					show_empty = true,
					framelevel = 20,
					template = 'thicktransparent',
					position = {
						point = 'TOPLEFT',
						frame = 'UIParent',
						rel_point = 'CENTER',
						x_off = -100,
						y_off = -150,
					},
				}
			},
			target = {
				position = {point = 'TOPLEFT', frame = 'UIParent', rel_point = 'CENTER', x_off = 150, y_off = -150},
				name = {
					position = {
						rel_point = "TOPLEFT",
						x_off = "5",
						point = "BOTTOMLEFT",
					},
				},
				castbar = {
					enable = true,
					height = 20,
					relative_width = false,
					width = 173,
					relative_height = false,
					position = {
						rel_point = "CENTER",
						point = "TOPRIGHT",
						x_off = "73",
						y_off = "-207",
						anchor_frame = "UIParent",
						frame_type = true,
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
						grow_right = false,
						initial_anchor = 'TOPRIGHT',
						horizontal_growth = 'LEFT',
						position = {
							point = 'TOPRIGHT',
							rel_point = 'BOTTOMRIGHT',
						}
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
				},
				buffs = {
					enable = false,
				},
			},
			focus = {
				position = {
					point = 'BOTTOMRIGHT',
					rel_point = 'CENTER',
					x_off = -300,
					y_off = 120
				}
			},
			focustarget = {
				width = 100,
				position = {point = 'LEFT', frame = 'SaftUI_Focus', rel_point = 'RIGHT', x_off = 7, y_off = 0},
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
			boss = {
				width = 202,
				spacing = 24,
				growthDirection = 'BOTTOM',
				maxColumns = 1,
				unitsPerColumn = 5,
				columnSpacing = 0,
				initialAnchor = 'TOP',
				position = {point = 'TOPLEFT', frame = 'SaftUI_Target', rel_point = 'BOTTOMLEFT', x_off = 0, y_off = -30},
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
				},
				name = {
					position = {
						rel_point = "TOPLEFT",
						x_off = "5",
						point = "BOTTOMLEFT",
					},
				},
				portrait = {
					position = {
						point = 'LEFT',
						rel_point = 'RIGHT',
						x_off = 7,
					},
				},
				auras = {
					buffs = {
						enable = false
					},
					debuffs = {
						enable = false
					},
				},
			},
			pet = {
				width = 100,
				position = {point = 'RIGHT', frame = 'SaftUI_Player_Portrait', rel_point = 'LEFT', x_off = -7, y_off = 0},
				portrait = {
					enable = false,
				},
				power = {
					width = -50,
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
				},
				name = {
					position = {
						rel_point = "TOPLEFT",
						x_off = "5",
						point = "BOTTOMLEFT",
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
				auras = {
					buffs = {
						enable = false,
					},
					debuffs = {
						enable = false,
					}
				}
			},
			pettarget = {
				width = 50,
				enable = false,
				position = {
					point = 'RIGHT',
					frame = 'SaftUI_Pet',
					rel_point = 'LEFT',
					x_off = -7,
					y_off = 0,
				},
				health = {
					text = {
						enable = false,
					},
				},
				power = {
					enable = false,
					text = {
						enable = false,
					},
				},
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
				raidroleindicator = {
					enable = true,
				},
				raidtargetindicator = {
					enable = true,
				},
				auras = {
					buffs = {
						filter = {
							friend = {
								whitelist = {
									filters = {
										auras = false,
									},
								},
								blacklist = {
									enable = true,
									filters = {
										others = true,
									},
								},
							},
						},
					},
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
				raidroleindicator = {
					enable = true,
					show_dps = false,
					position = {
						point = 'CENTER',
						rel_point = 'TOPLEFT',
						x_off = 0,
						y_off = 0,
					}
				},
				health = {
					height = -6,
					text = {
						hide_full = true,
						deficit = true,
					},
				},
				power = {
					enable = false,
				},
				name = {
					enable = false,
				},
				auras = {
					buffs = {
						enable = false,
					},
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
					colorCustom = false,
					colorClass = true,
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
				height = 14,
				width = 140,
				portrait = {
					enable = false,
				},
				questindicator = {
					enable = true,
				},
				power = {
					enable = false,
					height = 8,
					text = {
						enable = false
					}
				},
				health = {
					height = 0,
					text = {
						position = {x_off = -2},
					},
				},
				name = {
					position = {point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 7},
					max_length = 30,
					color_hostile = true,
				},
				castbar = {
					enable = true,
					height = 14,
					position = {
						point = "TOPLEFT",
						rel_point = "BOTTOMLEFT",
						y_off = "-7",
						frame_type = nil,
					},
					icon = {
						enable = false
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
	}
}