local st = SaftUI
local UF = st:GetModule('Unitframes')


local DEBUG = false

local indicators = {
    {
       configKey = 'grouproleindicator',
       name = 'GroupRoleIndicator',
       postUpdate = function(self, role)
           self:SetShown(self.config.showDps and true or role == 'HEALER' or role == 'TANK')
           self:SetTexCoord(0, 1, 0, 1)
           if role == 'HEALER' then
               self:SetVertexColor(unpack(st.config.profile.colors.text.green))
           elseif role == 'TANK' then
               self:SetVertexColor(unpack(st.config.profile.colors.text.blue))
           else
               self:SetVertexColor(unpack(st.config.profile.colors.text.red))
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
    local function Constructor(unitframe)
        local indicator = UF:AddTextureElement(unitframe, config.name)
--         local indicator = unitframe.TextOverlay:CreateTexture(('%s_%s'):format(unitframe:GetName(), config.name), 'OVERLAY')
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

        if config.postCreate then
            config.postCreate(indicator)
        end

        return indicator
    end

    local function UpdateConfig(unitframe)
        local indicator = unitframe[config.name]

         UF:UpdateElement(indicator)

        indicator:SetSize(indicator.config.size, indicator.config.size)
--
    end

    UF:RegisterElement(config.name, Constructor, UpdateConfig)
end