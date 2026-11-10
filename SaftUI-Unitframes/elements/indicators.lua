local st = SaftUI
local UF = st:GetModule('Unitframes')


local DEBUG = false

--[[
    Each indicator is its own element and /sui tab:
    configKey   - its table in the unit config
    name        - its oUF element name
    label       - its tab's name; order sorts the tabs
    desc        - what it shows, on its Enable option
    addOptions  - adds its own options to its tab's args (optional)
    validUnit   - the element's ValidUnit (optional)
    postUpdate, postCreate, debug - optional hooks
]]
local indicators = {
    {
       configKey = 'grouproleindicator',
       name = 'GroupRoleIndicator',
       label = 'Group role',
       order = 11,
       desc = 'A corner colored by group role: green for healers, blue for tanks.',
       addOptions = function(args)
           args.showDps = st.Config.generators.toggle(1, 'Show damage dealers',
               'Also shows the corner, in red, on damage dealers and on units without a role.', 'small')
       end,
       postUpdate = function(self)
           -- oUF no longer passes a usable role to PostUpdate (nil on Forever/12.1.5+,
           -- an enum before that), so look up the role string ourselves.
           local unit = self.unitframe and self.unitframe.__unit
           local role = unit and UnitGroupRolesAssigned(unit)
           if issecretvalue(role) then role = nil end

           -- oUF applies its own role atlas on update; restore our corner texture.
           self:SetTexture(st.textures.cornerbr)
           self:SetShown(self.config.showDps and true or role == 'HEALER' or role == 'TANK')
           self:SetTexCoord(0, 1, 0, 1)
           if role == 'HEALER' then
               self:SetVertexColor(st.config.profile.colors.text.green:GetRGB())
           elseif role == 'TANK' then
               self:SetVertexColor(st.config.profile.colors.text.blue:GetRGB())
           else
               self:SetVertexColor(st.config.profile.colors.text.red:GetRGB())
           end
       end,
       postCreate = function(self)
           self:SetTexture(st.textures.cornerbr)
       end,
       debug = function(self)
           self:SetTexCoord(GetTexCoordsForRoleSmallCircle('HEALER'))
       end
    },
    {
        configKey = 'raidroleindicator',
        name = 'RaidRoleIndicator',
        label = 'Raid role',
        order = 10,
        desc = 'The main tank or main assist icon, in a raid.',
        debug = function(self)
            self:SetTexture([[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]])
        end
    },
    {
        configKey = 'questindicator',
        name = 'QuestIndicator',
        label = 'Quest',
        order = 13,
        desc = 'A quest icon on quest bosses.',
    },
    {
        configKey = 'raidtargetindicator',
        name = 'RaidTargetIndicator',
        label = 'Raid target',
        order = 9,
        desc = 'The raid target marker (star, skull, ...) on the unit.',
        debug = function(self)
            SetRaidTargetIconTexture(self, 1)
        end
    },
    {
        configKey = 'readycheckindicator',
        name = 'ReadyCheckIndicator',
        label = 'Ready check',
        order = 12,
        desc = 'Each member\'s answer to a ready check.',
        -- oUF only enables it on party and raid members.
        validUnit = function(unit)
            return UF.group_strings[unit] ~= nil
        end,
        debug = function(self)
            self:SetTexture(self.waitingTexture)
        end
    }
}

for _, config in pairs(indicators) do
    local function Constructor(unitframe)
        local indicator = UF:AddTextureElement(unitframe, config.name)
--         local indicator = unitframe.TextOverlay:CreateTexture(('%s_%s'):format(unitframe:GetName(), config.name), 'OVERLAY')
        indicator.PostUpdate = function(...)
            if config.postUpdate then
                config.postUpdate(...)
            end

            -- oUF shows the indicator by its own rules on every update, so
            -- UF:SetElementEnabled only hid a disabled one until now.
            if not indicator.config.enable then
                indicator:Hide()
            end

            if DEBUG then
                if config.debug then
                    config.debug(...)
                end
                indicator:Show()
                indicator:SetAlpha(1)
            end
        end

        if config.postCreate then
            config.postCreate(indicator)
        end

        return indicator
    end

    local function UpdateConfig(unitframe)
        local indicator = unitframe[config.name]

         UF:UpdateElement(indicator)

        indicator:SetSize(indicator.config.size, indicator.config.size)
        -- The backdrop is SaftUI's frame behind the icon: it takes the Alpha the
        -- icon does.
        if indicator.backdrop then indicator.backdrop:SetAlpha(indicator.config.alpha or 1) end
--
    end

    local function GetConfigTable(unit)
        local generators = st.Config.generators
        -- Looked up on every get/set: a profile change replaces these tables.
        local function Config() return UF:GetProfileConfig()[unit][config.configKey] end
        local function Update() UF:UpdateConfig(unit, config.name) end

        local args = {
            enable = generators.toggle(0, 'Enable', config.desc, 'small'),
            size = generators.range(2, 'Size', 4, 64, 1, "The icon's width and height in pixels."),
            -- UF:UpdateElement puts the backdrop behind the icon (st:SetBackdrop
            -- on a texture), shown and hidden with it.
            theme = generators.theme(3, 'A border and background behind the icon.'),
            background = generators.background(3.5),
            alpha = generators.alpha(4, 'How solid the icon is, from see-through to opaque.'),
            -- Last in the tab.
            position = generators.uf_element_position(1000,
                function(index) return Config().position[index] end,
                function(index, value)
                    Config().position[index] = value
                    Update()
                end,
                UF:ConfigTarget(unit, config.name),
                "Where the icon sits: which of its points goes to which point of what it's attached to, then moved by X and Y."
            ),
        }
        if config.addOptions then
            config.addOptions(args)
        end

        return {
            order = config.order,
            type = 'group',
            name = config.label,
            get = function(info) return Config()[info[#info]] end,
            set = function(info, value)
                Config()[info[#info]] = value
                Update()
            end,
            args = args,
        }
    end

    UF:RegisterElement(config.name, Constructor, UpdateConfig, GetConfigTable, config.validUnit)
end