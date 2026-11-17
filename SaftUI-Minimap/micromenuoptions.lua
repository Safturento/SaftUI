local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')
local generators = st.Config.generators

-- The micro menu's section in the /sui tree. General: the bar's height, the
-- gap between items, the text font, the mouseover fade, and the Position
-- option last. Items: each item on or off, and the text items' widths.
-- Clicking the bar in edit mode selects its General group (the mover's
-- configPath). Every row's reset comes from where it's saved (saved,
-- optionsdefault.lua).

-- The names of the items that aren't Blizzard's micro buttons, by key
-- (micromenu.lua's OnEnable). microbuttons.lua names the micro buttons.
local ITEM_NAMES = {
    zone = 'Zone',
    clock = 'Clock',
    latency = 'Latency',
    fps = 'Frame rate',
    addons = 'Addon count',
    tracking = 'Tracking',
    expansion = 'Expansion summary',
    mail = 'Mail',
    difficulty = 'Instance difficulty',
    queue = 'Queue status',
}
MicroMenu.ITEM_NAMES = ITEM_NAMES

-- Mail, difficulty and the queue eye show only when they apply; turned off
-- they never show.
local SOMETIMES = { mail = true, difficulty = true, queue = true }

-- The text items whose width is a setting, in the bar's order
local WIDTHS = { 'zone', 'clock', 'latency', 'fps' }

local VISIBILITY_VALUES = { always = 'Always', mouseover = 'Faded until moused over' }
local VISIBILITY_ORDER = { 'always', 'mouseover' }

-- The bar's items in its order: { key, name } each, every micro button where
-- Blizzard's sit.
local function ItemList(self)
    local list, micro = {}, false
    for _, button in ipairs(self.Buttons) do
        local item = self.S.items[button]
        local key = item and item.key
        if item and item.micro then
            if not micro then
                micro = true
                for _, entry in ipairs(self:MicroItems()) do list[#list + 1] = entry end
            end
        elseif key then
            list[#list + 1] = { key, ITEM_NAMES[key] or key }
        end
    end
    return list
end

local function ItemsGroup(self)
    local toggles = {
        about = {
            order = 0,
            type = 'description',
            fontSize = 'medium',
            name = 'Turn an item off to take it off the bar. The bar closes up around it. ' ..
                'Mail, instance difficulty and queue status only show when they apply.',
        },
    }
    for i, entry in ipairs(ItemList(self)) do
        local key, name = entry[1], entry[2]
        toggles[key] = {
            order = i,
            name = name,
            desc = SOMETIMES[key] and ('Show ' .. name:lower() .. ' on the bar when it applies.')
                or ('Show ' .. name:lower() .. ' on the bar.'),
            type = 'toggle',
        }
    end

    local widths = {}
    for i, key in ipairs(WIDTHS) do
        widths[key] = generators.range(i, ITEM_NAMES[key], 20, 400, 1,
            'How wide the ' .. ITEM_NAMES[key]:lower() .. ' item is, in pixels.')
    end

    return {
        name = 'Items',
        type = 'group',
        order = 2,
        args = {
            show = {
                order = 1,
                name = 'Show',
                type = 'group',
                inline = true,
                saved = st.Config.SavedIn('micromenu', 'show'),
                get = function(info) return self.config.show[info[#info]] ~= false end,
                -- Only an item turned off is kept: on is the default ('*')
                set = function(info, value)
                    local key = info[#info]
                    if value == false then
                        self.config.show[key] = false
                    else
                        self.config.show[key] = nil
                    end
                    self:UpdateConfig()
                end,
                args = toggles,
            },
            widths = {
                order = 2,
                name = 'Widths',
                type = 'group',
                inline = true,
                saved = st.Config.SavedIn('micromenu', 'widths'),
                get = function(info) return self.config.widths[info[#info]] end,
                set = function(info, value)
                    self.config.widths[info[#info]] = value
                    self:UpdateConfig()
                end,
                args = widths,
            },
        },
    }
end

function MicroMenu:GetConfigTable()
    -- Getters and setters go through self.config, which a profile change
    -- re-points at the new profile's table.
    local position = generators.position(1000, true,
        function(key) return self.config.position[key] end,
        function(key, value)
            self.config.position[key] = value
            self:UpdateConfig()
        end,
        self.Container
    )

    local fade = generators.range(6, 'Faded opacity', 0, 1, 0.05,
        "How visible the bar is while it's faded and the mouse isn't over it.")
    fade.isPercent = true
    fade.hidden = function() return self.config.visibility ~= 'mouseover' end

    return {
        name = 'Micro menu',
        type = 'group',
        category = 'Frames', -- the /sui sidebar's group (optionslayout.lua)
        childGroups = 'tab',
        args = {
            general = {
                name = 'General',
                type = 'group',
                order = 1,
                saved = st.Config.SavedIn('micromenu'),
                get = function(info) return self.config[info[#info]] end,
                set = function(info, value)
                    local key = info[#info]
                    self.config[key] = value
                    if key == 'font' then
                        self:OnFontsChanged()
                    elseif key == 'visibility' or key == 'fade_alpha' then
                        self:UpdateFade()
                    else
                        self:UpdateConfig()
                    end
                end,
                args = {
                    about = {
                        order = 1,
                        type = 'description',
                        fontSize = 'medium',
                        name = 'The bar of info buttons and Blizzard\'s micro menu buttons. ' ..
                            'Use the Position section, or drag it in edit mode, to move it.',
                    },
                    height = generators.range(2, 'Height', self.HEIGHT_MIN, self.HEIGHT_MAX, 1,
                        "How tall every item on the bar is, in pixels. The micro buttons keep their shape."),
                    spacing = generators.range(3, 'Spacing', self.SPACING_MIN, self.SPACING_MAX, 1,
                        'The gap between two items, in pixels.'),
                    font = generators.font(4, 'The font of the zone, clock, latency, frame rate and addon count.'),
                    visibility = {
                        order = 5,
                        name = 'Show',
                        desc = 'Always, or faded until the mouse is over the bar.',
                        type = 'select',
                        values = VISIBILITY_VALUES,
                        sorting = VISIBILITY_ORDER,
                    },
                    fade_alpha = fade,
                    position = position, -- last
                },
            },
            items = ItemsGroup(self),
        },
    }
end
