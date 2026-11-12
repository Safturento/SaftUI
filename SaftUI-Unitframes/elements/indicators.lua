local st = SaftUI
local UF = st:GetModule('Unitframes')


local DEBUG = false

-- A quest question's answer as a plain boolean: a secret one (restricted
-- content can hand one) counts as no, since it can't be tested.
local function Yes(answer)
    if issecretvalue(answer) then return false end
    return answer and true or false
end

-- The quest icon's update, in place of oUF's, which asks only UnitIsQuestBoss:
-- shown for a unit one of the player's active quests is about, else for a
-- quest boss. Then the PostUpdate wrapper below, which hides the icon when
-- it isn't wanted. An event for another unit is skipped, as oUF's own update
-- does.
local function UpdateQuestIndicator(frame, event, unit)
    if not unit or unit ~= frame.__unit then return end
    local indicator = frame.QuestIndicator
    local shown = Yes(C_QuestLog.UnitIsRelatedToActiveQuest(unit)) or Yes(UnitIsQuestBoss(unit))
    indicator:SetShown(shown)
    if indicator.PostUpdate then
        return indicator:PostUpdate(shown)
    end
end

--[[
    Each indicator is its own element and /sui tab:
    configKey   - its table in the unit config
    name        - its oUF element name
    label       - its tab's name; order sorts the tabs
    desc        - what it shows, on its Enable option
    addOptions  - adds its own options to its tab's args (optional)
    validUnit   - the element's ValidUnit (optional)
    postUpdate, postCreate, debug - optional hooks
    override    - the element's Override, its update in place of oUF's (optional)
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
       end,
       -- A role means nothing on a nameplate.
       validUnit = function(unit)
           return not UF.IsPlateUnit(unit)
       end,
    },
    {
        configKey = 'raidroleindicator',
        name = 'RaidRoleIndicator',
        label = 'Raid role',
        order = 10,
        desc = 'The main tank or main assist icon, in a raid.',
        -- Not on nameplates, as the group role isn't.
        validUnit = function(unit)
            return not UF.IsPlateUnit(unit)
        end,
        debug = function(self)
            self:SetTexture([[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]])
        end
    },
    {
        configKey = 'questindicator',
        name = 'QuestIndicator',
        label = 'Quest',
        order = 13,
        desc = 'A quest icon on units one of your quests is about, and on quest bosses.',
        override = UpdateQuestIndicator,
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
            -- UF:SetElementEnabled only hid one that isn't wanted (off in
            -- its config: a friendly plate's quest icon by default) until now.
            if not UF:ElementWanted(indicator) then
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
        indicator.Override = config.override

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

-- No unit event says a unit's tie to a quest changed: when the quest log does
-- (a quest taken, done or handed in), every frame's quest icon asks again.
-- Only where oUF runs the icon (enabled, and not paused on a plate that shows
-- only widgets) and it's wanted: on in its config (a friend's plate draws from
-- the friendly one, which has it off by default, and disabled then).
local questLog = CreateFrame('Frame')
questLog:RegisterEvent('QUEST_LOG_UPDATE')
questLog:SetScript('OnEvent', function()
    UF:ForEachUnitFrame(function(frame)
        local indicator = frame.QuestIndicator
        if indicator and frame:IsElementEnabled('QuestIndicator') and not frame:IsElementPaused('QuestIndicator')
                and UF:ElementWanted(indicator) then
            indicator:ForceUpdate()
        end
    end)
end)