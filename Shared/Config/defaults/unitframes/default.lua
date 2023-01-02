local st = SaftUI

st.defaults.unitframes = {
    config_unit = 'player',
    config_element = 'general',
    config_profile = 'SaftUI',
    profiles = {
        ['**'] = {
            ["**"] = {
                enable = true,
                width = 300,
                height = 30,
                position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 },
                template = 'none',
                range_alpha = {
                    inside = 1,
                    outside = 0.2,
                },
                ['**'] = {
                    enable = true,
                    relative_width = true,
                    width = 0,
                    relative_height = true,
                    height = 0,
                    position = { point = 'CENTER', rel_point = 'CENTER', x_off = 0, y_off = 0 },
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
                        x_off = 0,
                        y_off = 0,
                    }
                },
                portrait = {
                    enable = false,
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
                    height = 15,
                    template = 'thin',
                    position = {
                        point = "BOTTOM",
                        rel_point = "BOTTOM",
                        y_off = "0",
                        x_off = "0",
                    },
                    framelevel = 15,
                    colors = {
                        normal = { .5, .7, .9 },
                        nointerrupt = { .6, .3, .3 },
                    },
                    text = {
                        enable = true,
                        position = {
                            point = "TOPLEFT",
                            rel_point = "BOTTOMLEFT",
                            anchor_element = "Castbar",
                            x_off = "0",
                            y_off = "-3",
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
                            y_off = "0",
                        },
                        font = 'pixel',
                    },
                    icon = {
                        enable = true,
                        position = {
                            point = "TOPLEFT",
                            rel_point = "TOPRIGHT",
                            x_off = "6",
                            y_off = -2,
                            anchor_element = "Castbar",
                        },
                        framelevel = 15,
                        height = -4,
                        relative_height = true,
                        width = -4,
                        relative_width = true,
                        template = 'thick',
                    }
                },
                health = {
                    template = "thin",
                    position = { rel_point = "TOPRIGHT", x_off = "-4", point = "TOPRIGHT", y_off = "-4" },
                    height = -7,
                    relative_height = true,
                    width = -7,
                    relative_width = true,
                    framelevel = 20,
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
                            x_off = -10,
                            y_off = 0,
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
                    customColor = { 0.3, 0.3, 0.3 },
                },
                power = {
                    framelevel = 10,
                    template = "thin",
                    height = 0,
                    relative_height = true,
                    width = 0,
                    relative_width = true,
                    position = {
                        rel_point = "TOPRIGHT",
                        y_off = "0",
                        point = "TOPRIGHT",
                        x_off = "0",
                    },
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
                            point = "LEFT",
                            anchor_element = "Health",
                            rel_point = "LEFT",
                            x_off = 10,
                            y_off = 0,
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
                    customColor = { 0.25, 0.25, 0.25 },
                },
                auras = {
                    ['**'] = {
                        enable = false,
                        size = 15,
                        spacing = 3,
                        per_row = 9,
                        max = 8,
                        framelevel = 15,
                        template = 'thin',
                        font = 'pixel',
                        grow_up = true,
                        grow_right = true,
                        initial_anchor = 'BOTTOMLEFT',
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
                            point = "BOTTOMLEFT",
                            rel_point = "TOPLEFT",
                            x_off = "0",
                            y_off = "3",
                        },
                    },
                    debuffs = {
                        enable = false,
                        border = 'all',
                        position = { point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 3 },
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
                        rel_point = "CENTER",
                        x_off = "0",
                        point = "CENTER",
                        y_off = "0",
                    },
                    tag = '[st:level] [st:name]',
                }
            }
        }
    }
}