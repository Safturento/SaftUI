local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	We can override the altPower functionality to force the main power bar
	to stay as mana for shaman/druid/priest with additionalPower. This will
	be used in conjunction the additional power overridden to show mana
	when both config.additionalpower.enable and config.additionalpower.manaAsPrimary
	are set as true
]]
local function GetDisplayPower(element)
	local unit = element.__owner.__unit

	if unit == 'player' then
		return Enum.PowerType.Mana, 0
	end
end

local function PostUpdatePower(power, unit, current, min, max)
	-- oUF's power update calls element:Show() every time, so Enable = false only
	-- sticks if it's re-applied here, after oUF's update.
	if power.config and power.config.enable == false then
		power:Hide()
		return
	end
	local deficit = issecretvalue(current) and C_StringUtil.TruncateWhenZero(UnitPowerMissing(unit)) or max - current
	local percent = issecretvalue(current) and UnitPowerPercent(unit) or current / max * 100

	if  power.text then
		if power.config.text.hide_full and deficit == 0 then
			power.text:SetText('')
		elseif power.config.text.percent then
			UF:SetPowerPercentText(power.text, unit, current, max)
		else
			if issecretvalue(current) then
				power.text:SetText(current)
			else
				power.text:SetFormattedText(current < 10000 and current or st.StringFormat:ShortFormat(current, 1))
			end
		end
	end

	if not issecretvalue(max) and max == 0 then
		power:SetMinMaxValues(0, 1)
		power:SetValue(1)
	end

	power:SetStatusBarTexture(st.BLANK_TEX)
	power.bg:SetTexture(st.BLANK_TEX)
end

-- oUF calls this after it recolors the bar (any color flag), so a custom color
-- set earlier or in PostUpdate would be overwritten. The custom color comes
-- from the config, so it is never secret.
local function PostUpdateColor(power, unit, color, r, g, b)
	if power.config.colorCustom then
		r, g, b = UF.UnpackColor(power.config.customColor)
		power:SetStatusBarColor(r, g, b)
		UF.SetPowerBackgroundColor(power, r, g, b)
		return
	end
	if not st.retail then return end
	if color then
		r, g, b = color:GetRGB()
	end
	if r and g and b then
		UF.SetPowerBackgroundColor(power, r, g, b)
	end
end


local function Constructor(unitframe)
    local power = UF:AddStatusBarElement(unitframe, 'Power')
    UF:AddText(unitframe, power)

	power.GetDisplayPower = GetDisplayPower
	power.PostUpdate = PostUpdatePower
	power.PostUpdateColor = PostUpdateColor

	return power
end

local function UpdateConfig(unitframe)
    local power = unitframe.Power

	-- Only the player has the AdditionalPower element (its ValidUnit), though
	-- a copied unit config can carry these settings.
	if unitframe.AdditionalPower
			and unitframe.config.additionalpower
			and unitframe.config.additionalpower.enable
			and unitframe.config.additionalpower.manaAsPrimary
			and UnitPowerMax('player', 0) > 0 then
		UF:UpdateElement(power, unitframe.AdditionalPower:GetConfig())
	else
		UF:UpdateElement(power)
	end

	power.colorTapping		= power.config.colorTapping
	power.colorDisconnected	= power.config.colorDisconnected
	power.colorPower		= power.config.colorPower
	power.colorClass		= power.config.colorClass
	power.colorClassNPC		= power.config.colorClassNPC
	power.colorClassPet		= power.config.colorClassPet
	power.colorReaction		= power.config.colorReaction
	-- oUF calls it colorPowerSmooth; it needs colorPower on as well.
	power.colorPowerSmooth	= power.config.colorSmooth
	power.colorCustom		= power.config.colorCustom
	power.customColor 		= power.config.customColor
	power.smoothing			= UF:GetSmoothing(power.config.Smooth)
end

local function GetConfigTable(unit)
	local G = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function UnitConfig() return UF:GetProfileConfig()[unit] end
	local function Update() UF:UpdateConfig(unit, 'Power') end

	return {
		type = 'group',
		name = 'Power',
		order = 2,
		get = function(info)
			return UnitConfig().power[info[#info]]
		end,
		set = function(info, value)
			UnitConfig().power[info[#info]] = value
			Update()
		end,
		args = {
			enable = G.toggle(0, 'Enable', 'Shows the power bar: mana, rage, energy and the like.', 'small'),
			reverse_fill = G.toggle(1, 'Reverse fill', 'Fills the bar from the other end: right to left, or top down when vertical.', 'small'),
			vertical_fill = G.toggle(2, 'Vertical fill', 'Fills the bar from the bottom up instead of from left to right.', 'small'),
			Smooth = G.toggle(3, 'Smooth', 'Slides the bar to each new value instead of jumping to it.', 'small'),
			theme = G.theme(4, "The power bar's border and background."),
			background = G.background(4.5),
			alpha = G.alpha(5, 'How solid the power bar is, from see-through to opaque.'),
			framelevel = G.framelevel(6, 'Draws the bar over the parts of the unit frame with a lower frame level, and under those with a higher one.'),
			size = UF.GenerateRelativeSizeConfigGroup(8),
			colors = UF.GenerateColorsConfigGroup(9, unit,
				{ 'colorDisconnected', 'colorTapping', 'colorPower', 'colorClass', 'colorClassNPC', 'colorClassPet', 'colorReaction' },
				function() return UnitConfig().power end, Update),
			text = {
				order = 98,
				name = 'Text',
				type = 'group',
				inline = true,
				get = function(info)
					return UnitConfig().power.text[info[#info]]
				end,
				set = function(info, value)
					UnitConfig().power.text[info[#info]] = value
					Update()
				end,
				args = {
					enable = G.toggle(0, 'Enable', 'Shows the power as text on the unit frame.', 'small'),
					hide_full = G.toggle(1, 'Hide full', 'Hides the text while power is full.', 'small'),
					font = G.font(2, "The power text's font."),
					percent = G.toggle(3, 'Percent', 'Shows the power as a percent instead of the number.', 'small'),
					-- Last in Text.
					position = G.uf_element_position(1000,
						function(index) return UnitConfig().power.text.position[index] end,
						function(index, value)
							UnitConfig().power.text.position[index] = value
							Update()
						end,
						UF:ConfigTarget(unit, 'Power', 'text'),
						"Where the power text sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
						'Text position'
					),
				},
			},
			bg = {
				order = 99,
				name = 'Bar background',
				type = 'group',
				inline = true,
				get = function(info)
					return UnitConfig().power.bg[info[#info]]
				end,
				set = function(info, value)
					UnitConfig().power.bg[info[#info]] = value
					Update()
				end,
				args = {
					enable = G.toggle(0, 'Enable', "Shows a background in the bar's empty part, a darker shade of the bar's color.", 'small'),
					multiplier = G.range(1, 'Brightness', 0, 1, 0.05, "How light the shade is: 0 is black, 1 is the bar's own color."),
					alpha = G.alpha(2, 'How solid the background is, from see-through to opaque.'),
				},
			},
			-- Last in the tab, after Text and Bar background.
			position = G.uf_element_position(1000,
				function(index) return UnitConfig().power.position[index] end,
				function(index, value)
					UnitConfig().power.position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'Power'),
				"Where the power bar sits: which of its points goes to which point of what it's attached to, then moved by X and Y."
			),
		}
	}
end

UF:RegisterElement('Power', Constructor, UpdateConfig, GetConfigTable)