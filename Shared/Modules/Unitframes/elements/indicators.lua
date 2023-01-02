local st = SaftUI
local UF = st:GetModule('Unitframes')


local DEBUG = false

local indicators = {
    {
        configKey = 'grouproleindicator',
        name = 'GroupRoleIndicator',
        postUpdate = function(self, role)
            self:SetShown(role == 'HEALER' or role == 'TANK')
        end,
        debug = function(self)
            self:SetTexCoord(GetTexCoordsForRoleSmallCircle('HEALER'))
        end
    },
    {
        configKey = 'raidroleindicator',
        name = 'RaidRoleIndicator',
        debug = function(self)
            self:SetTexture([[Interface\GROUPFRAME\UI-GROUP-MAINASSISTICON]])
        end
    },
    {
        configKey = 'questindicator',
        name = 'QuestIndicator',
    },
    {
        configKey = 'raidtargetindicator',
        name = 'RaidTargetIndicator',
        debug = function(self)
            SetRaidTargetIconTexture(self, 1)
        end
    },
    {
        configKey = 'readycheckindicator',
        name = 'ReadyCheckIndicator',
        debug = function(self)
            self:SetTexture(self.waitingTexture)
        end
    }
}

for _, config in pairs(indicators) do
    local function Constructor(self)
        local indicator = self.TextOverlay:CreateTexture(self:GetName()..config.name, 'OVERLAY')
        indicator.PostUpdate = function(...)
            if config.postUpdate then
                config.postUpdate(...)
            end

            if DEBUG then
                if config.debug then
                    config.debug(...)
                end
                indicator:Show()
                indicator:SetAlpha(1)
            end
        end

        self[config.name] = indicator
        return indicator
    end

    local function UpdateConfig(self)
        local indicator = self[config.name]

        indicator.config = self.config[config.configKey]

        if indicator.config.enable == false then
            indicator:Hide()
            return
        else
            indicator:Show()
        end

        indicator:SetSize(indicator.config.size, indicator.config.size)

        indicator:ClearAllPoints()
        local anchor, frame, rel_anchor, x_off, y_off = st:UnpackPoint(indicator.config.position)
        local frame = st.CF.get_frame(self, indicator.config.position)
        indicator:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
        indicator:SetAlpha(indicator.config.alpha)
    end

    local function GetConfigTable(unit)
        local ufConfig = st.config.profile.unitframes


        return {
            type = 'group',
            name = config.name,
            get = function(info)
                return ufConfig.profiles[ufConfig.config_profile][unit][config.configKey][info[#info]]
            end,
            set = function(info, value)
                ufConfig.profiles[ufConfig.config_profile][unit][config.configKey][info[#info]] = value
                UF:UpdateConfig(unit, config.name)
            end,
            args = {
                enable = st.CF.generators.enable(0),
                alpha = st.CF.generators.alpha(3),
                size = st.CF.generators.range(4, 'Size', 1, 50),
                position = st.CF.generators.uf_element_position(5,
                    function(index) return
                        ufConfig.profiles[ufConfig.config_profile][unit][config.configKey].position[index]
                    end,
                    function(index, value)
                        ufConfig.profiles[ufConfig.config_profile][unit][config.configKey].position[index] = value
                        UF:UpdateConfig(unit, config.name)
                    end
                ),
            }
        }
    end

    UF:RegisterElement(config.name, Constructor, UpdateConfig, GetConfigTable)
end