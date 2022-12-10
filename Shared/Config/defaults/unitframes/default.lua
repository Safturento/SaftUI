local st = SaftUI

st.defaults.unitframes = {
    config_unit = 'player',
    config_element = 'general',
    config_profile = 'SaftUI',
    profiles = {
        ['**'] = {
            ["**"] = {
                enable = true,
                width = 201,
                height = 28,
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
                    customColor = { 0.3, 0.3, 0.3 },
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
                    customColor = { 0.25, 0.25, 0.25 },
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
                        position = { point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 0, y_off = 31 },
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
            }
        }
    }
}