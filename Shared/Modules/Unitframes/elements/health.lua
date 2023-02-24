local st = SaftUI
local UF = st:GetModule('Unitframes')

local function getHealthPercentText(current, max, absorbs, precision)
	local perc = current/max*100
	if precision and precision > 0 then
		perc = ('%0.' .. (precision) .. 'f'):format(perc)
	else
		perc = floor(perc)
	end

	if absorbs > 0 then
		return ('%s +%d'):format(perc, floor(absorbs/max*100))
	else
		return perc
	end
end

local function PostUpdateHealth(health, unit, current, max)
	if UF.RMH and UF.RMH.UnitHasHealthData(unit) then
		current, max = UF.RMH.GetUnitHealth(unit)
	end

	if health.text then

		local absorbs = st.is_retail and UnitGetTotalAbsorbs(unit) or 0
		
		if current == max and health.config.text.hide_full then
			health.text:SetText('')
		elseif UnitIsDead(unit) then
			health.text:SetText('Dead')
		elseif health.config.text.deficit then
			health.text:SetText(current-max)
		elseif health.config.text.percent then
			health.text:SetText(getHealthPercentText(current, max, absorbs))
		else
			local text
			if absorbs > 0 then
				text = ('%s +%s'):format(st.StringFormat:ShortFormat(current, 1, 1000), st.StringFormat:ShortFormat(absorbs, 1, 1000))
			else
				text = current < 10000 and current or st.StringFormat:ShortFormat(current, 1, 1000)
			end

			if health.config.text.boss_percent and UnitLevel(unit) == -1 then
				text = ("%s | %s"):format(text, getHealthPercentText(current, max, absorbs, 1))
			end

			health.text:SetText(text)
		end
	end

	if health.config.colorCustom then
		health:SetStatusBarColor(unpack(health.config.customColor))
	end

	if health.config.bg.enable then
		r, g, b = health:GetStatusBarColor()
		local mu = health.config.bg.multiplier or 1
		health.bg:SetVertexColor(r * mu, g * mu, b * mu)
	end
	
end

local function Constructor(self)
    local health = UF:AddStatusBarElement(self, 'Health')
	UF:AddText(self, health)
	health.PostUpdate = PostUpdateHealth
	
	self.Health = health
	return health
end

local function UpdateConfig(self)
	self.Health.config = self.config.health
	local healthConfig = self.config.health
	
    UF:UpdateElementConfig(self.Health, true)

	if healthConfig.colorCustom then
		self.Health:SetStatusBarColor(unpack(healthConfig.customColor))
	end

	self.Health.colorTapping		= healthConfig.colorTapping
	self.Health.colorDisconnected	= healthConfig.colorDisconnected
	self.Health.colorHealth			= healthConfig.colorHealth
	self.Health.colorClass			= healthConfig.colorClass
	self.Health.colorClassNPC		= healthConfig.colorClassNPC
	self.Health.colorClassPet		= healthConfig.colorClassPet
	self.Health.colorReaction		= healthConfig.colorReaction
	self.Health.colorSmooth			= healthConfig.colorSmooth
	self.Health.colorCustom			= healthConfig.colorCustom
	self.Health.customColor 		= healthConfig.customColor
end

UF:RegisterElement('Health', Constructor, UpdateConfig)
