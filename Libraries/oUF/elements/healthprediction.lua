--[[
# Element: Health Prediction Bars

Handles the visibility and updating of incoming heals and heal/damage absorbs.

## Widget

HealthPrediction - A `table` containing references to sub-widgets and options.

## Sub-Widgets

myBar          - A `StatusBar` used to represent incoming heals from the player.
otherBar       - A `StatusBar` used to represent incoming heals from others.
absorbBar      - A `StatusBar` used to represent damage absorbs.
healAbsorbBar  - A `StatusBar` used to represent heal absorbs.
overAbsorb     - A `Texture` used to signify that the amount of damage absorb is greater than the unit's missing health.
overHealAbsorb - A `Texture` used to signify that the amount of heal absorb is greater than the unit's current health.

## Notes

A default texture will be applied to the StatusBar widgets if they don't have a texture set.
A default texture will be applied to the Texture widgets if they don't have a texture or a color set.

## Options

.maxOverflow - The maximum amount of overflow past the end of the health bar. Set this to 1 to disable the overflow.
               Defaults to 1.05 (number)

## Examples

    -- Position and size
    local myBar = CreateFrame('StatusBar', nil, self.Health)
    myBar:SetPoint('TOP')
    myBar:SetPoint('BOTTOM')
    myBar:SetPoint('LEFT', self.Health:GetStatusBarTexture(), 'RIGHT')
    myBar:SetWidth(200)

    local otherBar = CreateFrame('StatusBar', nil, self.Health)
    otherBar:SetPoint('TOP')
    otherBar:SetPoint('BOTTOM')
    otherBar:SetPoint('LEFT', myBar:GetStatusBarTexture(), 'RIGHT')
    otherBar:SetWidth(200)

    local absorbBar = CreateFrame('StatusBar', nil, self.Health)
    absorbBar:SetPoint('TOP')
    absorbBar:SetPoint('BOTTOM')
    absorbBar:SetPoint('LEFT', otherBar:GetStatusBarTexture(), 'RIGHT')
    absorbBar:SetWidth(200)

    local healAbsorbBar = CreateFrame('StatusBar', nil, self.Health)
    healAbsorbBar:SetPoint('TOP')
    healAbsorbBar:SetPoint('BOTTOM')
    healAbsorbBar:SetPoint('RIGHT', self.Health:GetStatusBarTexture())
    healAbsorbBar:SetWidth(200)
    healAbsorbBar:SetReverseFill(true)

    local overAbsorb = self.Health:CreateTexture(nil, "OVERLAY")
    overAbsorb:SetPoint('TOP')
    overAbsorb:SetPoint('BOTTOM')
    overAbsorb:SetPoint('LEFT', self.Health, 'RIGHT')
    overAbsorb:SetWidth(10)

	local overHealAbsorb = self.Health:CreateTexture(nil, "OVERLAY")
    overHealAbsorb:SetPoint('TOP')
    overHealAbsorb:SetPoint('BOTTOM')
    overHealAbsorb:SetPoint('RIGHT', self.Health, 'LEFT')
    overHealAbsorb:SetWidth(10)

    -- Register with oUF
    self.HealthPrediction = {
        myBar = myBar,
        otherBar = otherBar,
        absorbBar = absorbBar,
        healAbsorbBar = healAbsorbBar,
        overAbsorb = overAbsorb,
        overHealAbsorb = overHealAbsorb,
        maxOverflow = 1.05,
    }
--]]

local _, ns = ...
local oUF = ns.oUF
local myGUID = UnitGUID('player')
local HealComm, ALL_PENDING_HEALS, ALL_OVERTIME_HEALS, HEAL_TICK_INTERVAL
--
--if not oUF.isRetail then
--	HealComm = LibStub("LibHealComm-4.0")
--
--	ALL_PENDING_HEALS = bit.bor(HealComm.DIRECT_HEALS, HealComm.BOMB_HEALS)
--	ALL_OVERTIME_HEALS = bit.bor(HealComm.CHANNEL_HEALS, HealComm.HOT_HEALS)
--	HEAL_TICK_INTERVAL = 3
--end

local function GetHealAmount(targetGUID, currentTime, casterGUID)
    local nextTickTime = currentTime + HEAL_TICK_INTERVAL

    local pendingHeal = HealComm:GetHealAmount(targetGUID, ALL_PENDING_HEALS, nil, casterGUID) or 0
    local overtimeHeal = HealComm:GetHealAmount(targetGUID, ALL_OVERTIME_HEALS, nextTickTime, casterGUID) or 0

    return (pendingHeal + overtimeHeal) * HealComm:GetHealModifier(casterGUID)
end

local function Update(self, event, unit)
	if(self.unit ~= unit) then return end

	local element = self.HealthPrediction

	--[[ Callback: HealthPrediction:PreUpdate(unit)
	Called before the element has been updated.

	* self - the HealthPrediction element
	* unit - the unit for which the update has been triggered (string)
	--]]
	if(element.PreUpdate) then
		element:PreUpdate(unit)
	end

	local guid = UnitGUID(unit)
	local currentTime = GetTime()
	local isSmoothedEvent = event == "UNIT_MAXHEALTH" or event == "UNIT_HEALTH_FREQUENT" or event == "UNIT_HEALTH"
	local myIncomingHeal = not oUF.isRetail and GetHealAmount(guid, currentTime, myGUID) or UnitGetIncomingHeals(unit, 'player') or 0
	local allIncomingHeal = not oUF.isRetail and GetHealAmount(guid, currentTime, nil) or UnitGetIncomingHeals(unit) or 0
	local absorb = oUF.isRetail and UnitGetTotalAbsorbs(unit) or 0
	local healAbsorb = oUF.isRetail and UnitGetTotalHealAbsorbs(unit) or 0
	local health, maxHealth = UnitHealth(unit), UnitHealthMax(unit)
	local otherIncomingHeal = 0
	local hasOverHealAbsorb = false

	if(healAbsorb > allIncomingHeal) then
		healAbsorb = healAbsorb - allIncomingHeal
		allIncomingHeal = 0
		myIncomingHeal = 0

		if(health < healAbsorb) then
			hasOverHealAbsorb = true
			healAbsorb = health
		end
	else
		allIncomingHeal = allIncomingHeal - healAbsorb
		healAbsorb = 0

		if(health + allIncomingHeal > maxHealth * element.maxOverflow) then
			allIncomingHeal = maxHealth * element.maxOverflow - health
		end

		if(allIncomingHeal < myIncomingHeal) then
			myIncomingHeal = allIncomingHeal
		else
			otherIncomingHeal = allIncomingHeal - myIncomingHeal
		end
	end

	local hasOverAbsorb = false
	if(health + allIncomingHeal + absorb >= maxHealth) then
		if(absorb > 0) then
			hasOverAbsorb = true
		end

		absorb = math.max(0, maxHealth - health - allIncomingHeal)
	end

	if(element.myBar) then
		if element.smoothing then
            element.myBar:SetMinMaxSmoothedValue(0, maxHealth)
            element.myBar:SetSmoothedValue(myIncomingHeal)
        end

		if not element.smoothing or not isSmoothedEvent then
            element.myBar:SetMinMaxValues(0, maxHealth)
            element.myBar:SetValue(myIncomingHeal)
        end

        element.myBar:Show()
	end

	if(element.otherBar) then
		if element.smoothing then
            element.otherBar:SetMinMaxSmoothedValue(0, maxHealth)
            element.otherBar:SetSmoothedValue(otherIncomingHeal)
        end

		if not element.smoothing or not isSmoothedEvent then
            element.otherBar:SetMinMaxValues(0, maxHealth)
            element.otherBar:SetValue(otherIncomingHeal)
        end

        element.otherBar:Show()
	end

	if(element.absorbBar) then
		element.absorbBar:SetMinMaxValues(0, maxHealth)
		element.absorbBar:SetValue(absorb)
		element.absorbBar:Show()
	end

	if(element.healAbsorbBar) then
		element.healAbsorbBar:SetMinMaxValues(0, maxHealth)
		element.healAbsorbBar:SetValue(healAbsorb)
		element.healAbsorbBar:Show()
	end

	if(element.overAbsorb) then
		if(hasOverAbsorb) then
			element.overAbsorb:Show()
		else
			element.overAbsorb:Hide()
		end
	end

	if(element.overHealAbsorb) then
		if(hasOverHealAbsorb) then
			element.overHealAbsorb:Show()
		else
			element.overHealAbsorb:Hide()
		end
	end

	--[[ Callback: HealthPrediction:PostUpdate(unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb)
	Called after the element has been updated.

	* self              - the HealthPrediction element
	* unit              - the unit for which the update has been triggered (string)
	* myIncomingHeal    - the amount of incoming healing done by the player (number)
	* otherIncomingHeal - the amount of incoming healing done by others (number)
	* absorb            - the amount of damage the unit can absorb without losing health (number)
	* healAbsorb        - the amount of healing the unit can absorb without gaining health (number)
	* hasOverAbsorb     - indicates if the amount of damage absorb is higher than the unit's missing health (boolean)
	* hasOverHealAbsorb - indicates if the amount of heal absorb is higher than the unit's current health (boolean)
	--]]
	if(element.PostUpdate) then
		return element:PostUpdate(unit, myIncomingHeal, otherIncomingHeal, absorb, healAbsorb, hasOverAbsorb, hasOverHealAbsorb)
	end
end

local function Path(self, event, ...)
	--[[ Override: HealthPrediction.Override(self, event, unit)
	Used to completely override the internal update function.

	* self  - the parent object
	* event - the event triggering the update (string)
	* unit  - the unit accompanying the event
	--]]

    if not oUF.isRetail and self:IsVisible() then
        for i = 1, select('#', ...) do
            if self.unit and UnitGUID(self.unit) == (UnitGUID(select(i, ...)) or select(i, ...)) then
                return (self.HealthPrediction.Override or Update) (self, event, self.unit)
            end
        end
	else
		return (self.HealthPrediction.Override or Update) (self, event, ...)
    end
end

local function ForceUpdate(element)
	return Path(element.__owner, 'ForceUpdate', element.__owner.unit)
end

local function Enable(self)
	local element = self.HealthPrediction
	if(element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		if oUF.isRetail then
			self:RegisterEvent('UNIT_HEALTH', Path)
			self:RegisterEvent('UNIT_HEAL_PREDICTION', Path)
			self:RegisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
			self:RegisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
		else
			self:RegisterEvent('UNIT_HEALTH_FREQUENT', Path)

			local function UpdateHeal(event, casterGUID, spellID, healType, _, ...)
				Path(self, event, ...)
			end

			local function UpdateModifier(event, guid)
				Path(self, event, guid)
			end

			HealComm.RegisterCallback(self, "HealComm_HealStarted", UpdateHeal)
			HealComm.RegisterCallback(self, "HealComm_HealUpdated", UpdateHeal)
			HealComm.RegisterCallback(self, "HealComm_HealDelayed", UpdateHeal)
			HealComm.RegisterCallback(self, "HealComm_HealStopped", UpdateHeal)
			HealComm.RegisterCallback(self, "HealComm_ModifierChanged", UpdateModifier)
			HealComm.RegisterCallback(self, "HealComm_GUIDDisappeared", UpdateModifier)
		end

		self:RegisterEvent('UNIT_MAXHEALTH', Path)

		if(not element.maxOverflow) then
			element.maxOverflow = 1.05
		end

		if(element.myBar) then
			if(element.smoothing) then
                element.myBar.SetSmoothedValue = SmoothStatusBarMixin.SetSmoothedValue
                element.myBar.SetMinMaxSmoothedValue = SmoothStatusBarMixin.SetMinMaxSmoothedValue
            end

			if(element.myBar:IsObjectType('StatusBar') and not element.myBar:GetStatusBarTexture()) then
				element.myBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.otherBar) then
			if(element.smoothing) then
                element.otherBar.SetSmoothedValue = SmoothStatusBarMixin.SetSmoothedValue
                element.otherBar.SetMinMaxSmoothedValue = SmoothStatusBarMixin.SetMinMaxSmoothedValue
            end

			if(element.otherBar:IsObjectType('StatusBar') and not element.otherBar:GetStatusBarTexture()) then
				element.otherBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.absorbBar) then
			if(element.absorbBar:IsObjectType('StatusBar') and not element.absorbBar:GetStatusBarTexture()) then
				element.absorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.healAbsorbBar) then
			if(element.healAbsorbBar:IsObjectType('StatusBar') and not element.healAbsorbBar:GetStatusBarTexture()) then
				element.healAbsorbBar:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
			end
		end

		if(element.overAbsorb) then
			if(element.overAbsorb:IsObjectType('Texture') and not element.overAbsorb:GetTexture()) then
				element.overAbsorb:SetTexture([[Interface\RaidFrame\Shield-Overshield]])
				element.overAbsorb:SetBlendMode('ADD')
			end
		end

		if(element.overHealAbsorb) then
			if(element.overHealAbsorb:IsObjectType('Texture') and not element.overHealAbsorb:GetTexture()) then
				element.overHealAbsorb:SetTexture([[Interface\RaidFrame\Absorb-Overabsorb]])
				element.overHealAbsorb:SetBlendMode('ADD')
			end
		end

		return true
	end
end

local function Disable(self)
	local element = self.HealthPrediction
	if(element) then
		if(element.myBar) then
			element.myBar:Hide()
		end

		if(element.otherBar) then
			element.otherBar:Hide()
		end

		if(element.absorbBar) then
			element.absorbBar:Hide()
		end

		if(element.healAbsorbBar) then
			element.healAbsorbBar:Hide()
		end

		if(element.overAbsorb) then
			element.overAbsorb:Hide()
		end

		if(element.overHealAbsorb) then
			element.overHealAbsorb:Hide()
		end

		self:UnregisterEvent('UNIT_HEALTH', Path)
		self:UnregisterEvent('UNIT_MAXHEALTH', Path)
		self:UnregisterEvent('UNIT_HEAL_PREDICTION', Path)
		self:UnregisterEvent('UNIT_ABSORB_AMOUNT_CHANGED', Path)
		self:UnregisterEvent('UNIT_HEAL_ABSORB_AMOUNT_CHANGED', Path)
	end
end

oUF:AddElement('HealthPrediction', Path, Enable, Disable)
