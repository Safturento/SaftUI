local st = SaftUI
local UF = st:GetModule('Unitframes')


local DEBUG = false

local indicators = {
    --{
    --    configKey = 'grouproleindicator',
    --    name = 'GroupRoleIndicator',
    --    postUpdate = function(self, role)
    --        self:SetShown(role == 'HEALER' or role == 'TANK')
    --    end,
    --    debug = function(self)
    --        self:SetTexCoord(GetTexCoordsForRoleSmallCircle('HEALER'))
    --    end
    --},
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
        local indicator = unitframe.TextOverlay:CreateTexture(('%s_%s'):format(unitframe:GetName(), config.name), 'OVERLAY')
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

        unitframe[config.name] = indicator
        return indicator
    end

    local function UpdateConfig(unitframe)
        local indicator = unitframe[config.name]

        indicator.config = unitframe.config[config.configKey]

        if indicator.config.enable == false then
            indicator:Hide()
            return
        else
            indicator:Show()
        end

        indicator:SetSize(indicator.config.size, indicator.config.size)

        indicator:ClearAllPoints()
        local anchor, frame, rel_anchor, x_off, y_off = st:UnpackPoint(indicator.config.position)
        local frame = UF:GetFrame(unitframe, indicator.config.position)
        indicator:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
        indicator:SetAlpha(indicator.config.alpha)
    end

    UF:RegisterElement(config.name, Constructor, UpdateConfig)
end