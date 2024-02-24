local st = SaftUI

local questindicator = {
    enable = false,
    size = 16,
    position = {
        point = 'RIGHT',
        rel_point = 'LEFT',
        x_off = -7,
    },
}

local raidroleindicator = {
    size = 16,
    enable = true,
    position = {
        point = 'CENTER',
        rel_point = 'TOPRIGHT',
        element = 'Health',
        x_off = 0,
        y_off = 0,
    }
}

local grouproleindicator = {
    size = 16,
    show_dps = false,
    position = {
        enable = false,
        point = 'CENTER',
        rel_point = 'TOPLEFT',
        element = 'Health',
        x_off = 0,
        y_off = 0,
    }
}

local readycheckindicator = {
    size = 16,
    enable = true,
    position = {
        point = 'BOTTOMRIGHT',
        rel_point = 'BOTTOMRIGHT',
        element = 'Health',
        x_off = 0,
        y_off = 0,
    }
}

local raidtargetindicator = {
    enable = true,
    size = 16,
    position = {
        point = 'CENTER',
        rel_point = 'TOP',
        element = 'Portrait',
        x_off = 0,
        y_off = 0,
    }
}

local portrait = {
    enable = true,
    alpha = 0.1,
    framelevel = 20,
    template = "none",
    height = -4,
    width = -4,
    position = {
        rel_point = "CENTER",
        point = "CENTER",
        x_off = "0",
        element = "Health",
        y_off = "0",
    },
}

local castbar = {
    enable = false,
    relative_height = false,
    height = 15,
    template = 'thin',
    bg = {
        enable = false,
    },
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
        font = 'normal',
        position = {
            frame_type = false,
            point = "TOPLEFT",
            rel_point = "BOTTOMLEFT",
            element = "Castbar",
            x_off = "0",
            y_off = "-3",
        },
    },
    time = {
        enable = true,
        font = 'normal',
        position = {
            frame_type=false,
            rel_point = "RIGHT",
            point = "RIGHT",
            element = "Castbar",
            x_off = "-5",
            y_off = "0",
        },
    },
    icon = {
        enable = false,
        position = {
            point = "LEFT",
            rel_point = "RIGHT",
            x_off = -3,
            y_off = 0,
            frame_type = true,
            element = "Castbar",
        },
        framelevel = 15,
        height = -4,
        relative_height = true,
        width = -4,
        relative_width = true,
        template = 'thick',
    }
}

local health = {
    template = "thin",
    position = { rel_point = "TOPRIGHT", x_off = "-2", point = "TOPRIGHT", y_off = "-2" },
    height = -4,
    relative_height = true,
    width = -4,
    relative_width = true,
    framelevel = 20,
    reverse_fill = false,
    vertical_fill = false,
    text = {
        enable = true,
        hide_full = false,
        percent = false,
        boss_percent = true,
        font = 'normal',
        position = {
            point = "RIGHT",
            element = "Health",
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
}

local power = {
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
        enable = false,
        hide_full = false,
        percent = false,
        font = 'normal',
        position = {
            point = "LEFT",
            element = "Health",
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
}


local additionalpower = {
    enable = false,
    framelevel = 10,
    template = "thick",
    height = -4,
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
        font = 'normal',
        position = {
            point = "LEFT",
            frame_type=false,
            element = "AdditionalPower",
            rel_point = "LEFT",
            x_off = 10,
            y_off = 0,
        },
    },
    colorPower = false,
    colorClass = true,
    colorCustom = false,
    customColor = { 0.25, 0.25, 0.25 },
}


local auras = {
    enable = false,
    size = 24,
    spacing = 3,
    per_row = 9,
    max = 8,
    framelevel = 15,
    template = 'thick',
    font = 'normal',
    grow_up = true,
    grow_right = true,
    initial_anchor = 'BOTTOMLEFT',
    cooldown = {
        enable = true,
        timer = false,
        reverse = true,
        alpha = 0.7
    },
    ['**'] = {
        filter = {
            whitelist = {
                enable = false,
                yours = true,
                others = true,
                stealable = true,
                auras = true,
                boss = true
            },
            blacklist = {
                enable = false,
                yours = false,
                others = false,
                stealable = false,
                auras = false,
                boss = false,
            },
            time = {
                enable = false,
                min = 0,
                max = 60,
            }
        },
    }
}

local buffs = st.tablemerge(auras, {
    enable = false,
    enemy = {
        colorStealable = true,
    },
    position = {
        point = "BOTTOMLEFT",
        rel_point = "TOPLEFT",
        x_off = "2",
        y_off = "7",
    },
})

local debuffs = st.tablemerge(auras, {
    enable = false,
    friend = {
        colorTypes = true,
    },
    enemy = {
        desaturateOthers = true,
    },
    position = { point = 'BOTTOMLEFT', rel_point = 'TOPLEFT', x_off = 2, y_off = 7 },
})

local name = {
    enable = true,
    max_length = 30,
    show_level = true,
    all_caps = false,
    show_samelevel = false,
    show_classification = true,
    font = 'normal',
    position = {
        rel_point = "LEFT",
        x_off = "11",
        point = "LEFT",
        y_off = "0",
    },
    tag = '[st:level][st:name]',
}

local widget = {
    enable = true,
    width = -2,
    relative_width = true,
    height = 20,
    relative_height = false,
    framelevel = 10,
    position = { point = 'TOP', rel_point = 'BOTTOM', x_off = 0, y_off = -5 },
    template = 'thick',
    text = {
        enable = true,
        font = 'normal',
        position = {
            frame_type = false,
            point = "CENTER",
            element = 'Widget',
            rel_point = "CENTER",
            x_off = 0,
            y_off = 0,
        },
    },
}

st.defaults.unitframes = {
    config_unit = 'player',
    config_element = 'general',
    config_profile = 'SaftUI',
    profiles = {
        ['**'] = {
            ["**"] = {
                enable = true,
                width = 301,
                height = 39,
                position = { point = 'CENTER', frame = 'UIParent', rel_point = 'CENTER', x_off = 0, y_off = 0 },
                template = 'none',
                range_alpha = {
                    inside = 1,
                    outside = 0.4,
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
                name = name,
                buffs = buffs,
                debuffs = debuffs,
                power = power,
                additionalpower = additionalpower,
                health = health,
                castbar = castbar,
                portrait = portrait,
                widget = widget,
                questindicator = questindicator,
                raidroleindicator = raidroleindicator,
                grouproleindicator = grouproleindicator,
                readycheckindicator = readycheckindicator,
                raidtargetindicator = raidtargetindicator,
            }
        }
    }
}