local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')

-- The micro menu's section in the /sui tree: General, with the Position
-- option last. Clicking the bar in edit mode selects its General group (the
-- mover's configPath).
function MicroMenu:GetConfigTable()
    -- Getters and setters go through self.config, which a profile change
    -- re-points at the new profile's table.
    local position = st.Config.generators.position(1000, true,
        function(key) return self.config.position[key] end,
        function(key, value)
            self.config.position[key] = value
            self:UpdateConfig()
        end,
        self.Container
    )
    return {
        name = 'Micro Menu',
        type = 'group',
        category = 'Frames', -- the /sui sidebar's group (optionslayout.lua)
        childGroups = 'tab',
        args = {
            general = {
                name = 'General',
                type = 'group',
                order = 1,
                args = {
                    about = {
                        order = 1,
                        type = 'description',
                        fontSize = 'medium',
                        name = 'The bar of info buttons and Blizzard\'s micro menu buttons. ' ..
                            'Use the Position section, or drag it in edit mode, to move it.',
                    },
                    position = position,
                },
            },
        },
    }
end
