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
		local absorbs = st.retail and UnitGetTotalAbsorbs(unit) or 0
		
		if current == max and health.config.text.hide_full then
			health.text:SetText('')
		elseif UnitIsDead(unit) or current == 0 then
			health.text:SetText('Dead')
		elseif health.config.text.deficit then
			health.text:SetText(current - max)
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

local function Constructor(unitframe)
    local health = UF:AddStatusBarElement(unitframe, 'Health')
	UF:AddText(unitframe, health)
	health.PostUpdate = PostUpdateHealth

	return health
end

local function UpdateConfig(unitframe)
    local health = unitframe.Health

    UF:UpdateElement(health)

    local config = health.config
	health.colorTapping		 = config.colorTapping
	health.colorDisconnected = config.colorDisconnected
	health.colorHealth		 = config.colorHealth
	health.colorClass		 = config.colorClass
	health.colorClassNPC	 = config.colorClassNPC
	health.colorClassPet	 = config.colorClassPet
	health.colorReaction	 = config.colorReaction
	health.colorSmooth		 = config.colorSmooth
	health.colorCustom		 = config.colorCustom
	health.customColor 		 = config.customColor
end

UF:RegisterElement('Health', Constructor, UpdateConfig)
