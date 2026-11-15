local st = SaftUI
local UF = st:GetModule('Unitframes')

local function PostUpdatePower(power, unit, current, min, max)
	-- oUF's power update calls element:Show() every time, so Enable = false only
	-- sticks if it's re-applied here, after oUF's update.
	if power.config and power.config.enable == false then
		power:Hide()
		return
	end
	local deficit = issecretvalue(current) and C_StringUtil.TruncateWhenZero(UnitPowerMissing(unit)) or max - current

	if  power.text then
		if power.config.text.hide_full and deficit == 0 then
			power.text:SetText('')
		elseif power.config.text.percent then
			UF:SetPowerPercentText(power.text, unit, current, max)
		else
			-- Short is health's abbreviation, a secret value included. Without
			-- it a secret shows as it is, and a plain value whole under 10000
			-- and shortened from there.
			local text = current
			if power.config.text.short then
				text = UF.ShortNumber(current)
			elseif not issecretvalue(current) and current >= 10000 then
				text = st.StringFormat:ShortFormat(current, 1)
			end
			power.text:SetText(text)
		end
	end

	if not issecretvalue(max) and max == 0 then
		power:SetMinMaxValues(0, 1)
		power:SetValue(1)
	end

	UF:RedrawBarFill(power)
end

-- oUF calls this after it recolors the bar (UF.PostUpdatePowerColor, in
-- updaters.lua). oUF's power element passes the unit first.
local function PostUpdateColor(power, unit, color, r, g, b)
	UF.PostUpdatePowerColor(power, color, r, g, b)
end


local function Constructor(unitframe)
    local power = UF:AddStatusBarElement(unitframe, 'Power')
    UF:AddText(unitframe, power)

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

	-- colorTapping and colorReaction through oUF's setters, so their event
	-- follows them (UF.SetFactionColorFlags).
	UF.SetFactionColorFlags(power, power.config)
	power.colorDisconnected	= power.config.colorDisconnected
	power.colorPower		= power.config.colorPower
	power.colorClass		= power.config.colorClass
	power.colorClassNPC		= power.config.colorClassNPC
	power.colorClassPet		= power.config.colorClassPet
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
		saved = UF.SavedIn(unit, 'power'),
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
			size = UF.GenerateRelativeSizeConfigGroup(8, UF.SavedIn(unit, 'power')),
			colors = UF.GenerateColorsConfigGroup(9, unit, 'power',
				{ 'colorDisconnected', 'colorTapping', 'colorPower', 'colorClass', 'colorClassNPC', 'colorClassPet', 'colorReaction' },
				function() return UnitConfig().power end, Update),
			text = {
				order = 98,
				name = 'Text',
				type = 'group',
				inline = true,
				saved = UF.SavedIn(unit, 'power', 'text'),
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
					short = G.toggle(4.5, 'Short', 'Shortens the power from 1000 up, as 1.5K or 1.2M; without it only from 10000 up. Not with Percent on.', 'small'),
					-- Without it the text keeps its font's color, white.
					customColor = UF.CustomColorOption(5, {
						name = 'Text color',
						desc = 'Colors the power text with this color.',
						offDesc = "Unticked, the text keeps its font's color: white.",
						offText = 'White',
						unit = unit,
						path = { 'power', 'text' },
						config = function() return UnitConfig().power.text end,
						update = Update,
					}),
					-- Last in Text.
					position = G.uf_element_position(1000,
						function(index) return UnitConfig().power.text.position[index] end,
						function(index, value)
							UnitConfig().power.text.position[index] = value
							Update()
						end,
						UF:ConfigTarget(unit, 'Power', 'text'),
						"Where the power text sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
						'Text position', UF.SavedAt(unit, 'power', 'text', 'position')
					),
				},
			},
			bg = {
				order = 99,
				name = 'Bar background',
				type = 'group',
				inline = true,
				saved = UF.SavedIn(unit, 'power', 'bg'),
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
				"Where the power bar sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
				nil, UF.SavedAt(unit, 'power', 'position')
			),
		}
	}
end

-- Nameplates show no power bar.
local function ValidUnit(unit)
	return not UF.IsPlateUnit(unit)
end

UF:RegisterElement('Power', Constructor, UpdateConfig, GetConfigTable, ValidUnit)