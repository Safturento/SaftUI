local st = SaftUI
local UF = st:GetModule('Unitframes')

local function Update(unitframe, event, unit, powerType)
	if(unitframe.__unit ~= unit) then return end
	local additionalPower = unitframe.AdditionalPower

	if(additionalPower.PreUpdate) then
		additionalPower:PreUpdate(unit)
	end

	--TODO: Override powertype to maelstrom for ele/enh shamans in ghost wolf

	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	additionalPower:SetMinMaxValues(0, max)
	additionalPower:SetValue(cur)

	additionalPower.cur = cur
	additionalPower.max = max

	if(additionalPower.PostUpdate) then
		additionalPower:PostUpdate(cur, max)
	end
end

-- oUF calls this after it recolors the bar (see power.lua's PostUpdateColor).
local function PostUpdateColor(power, color, r, g, b)
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

-- The bar always shows mana, so a secret percent is mana's.
local function PostUpdate(additionalPower, curr, max)
	local config = additionalPower.config.text
	local text = additionalPower.text
	if config.hide_full and not issecretvalue(curr) and not issecretvalue(max) and curr >= max then
		text:SetText('')
	elseif config.percent then
		UF:SetPowerPercentText(text, additionalPower.__owner.unit, curr, max, Enum.PowerType.Mana)
	else
		text:SetText(curr)
	end
end

-- oUF shows the bar only while the player's power bar shows a power the game
-- pairs with mana (ALT_POWER_BAR_PAIR_DISPLAY_INFO), and tells PostVisibility
-- after each change. A disabled bar stays hidden whatever oUF shows. The text
-- sits on the unit frame's text overlay, not on the bar, so it's shown and
-- hidden with the bar here.
local function ApplyVisibility(additionalPower)
	local config = additionalPower.config
	local shown = additionalPower.shownByOUF and config.enable or false
	additionalPower:SetShown(shown)
	additionalPower.text:SetShown(shown and config.text.enable or false)
end

local function PostVisibility(additionalPower, enabled)
	additionalPower.shownByOUF = enabled
	ApplyVisibility(additionalPower)
end

local function Constructor(self)
    local additionalPower = UF:AddStatusBarElement(self, 'AdditionalPower')
    UF:AddText(self, additionalPower)
	additionalPower.PostVisibility = PostVisibility
	additionalPower.PostUpdate = PostUpdate
	additionalPower.PostUpdateColor = PostUpdateColor

	return additionalPower
end

local function UpdateConfig(unitframe)
    local additionalPower = unitframe.AdditionalPower

	additionalPower:SetStatusBarTexture(st.BLANK_TEX)
	additionalPower.bg:SetTexture(st.BLANK_TEX)

	if unitframe.config.additionalpower
			and unitframe.config.additionalpower.enable
			and unitframe.config.additionalpower.manaAsPrimary
			and UnitPowerMax('player', 0) > 0 then
    	UF:UpdateElement(additionalPower, unitframe.Power:GetConfig())
	else
		UF:UpdateElement(additionalPower)
	end

	-- Read after UpdateElement, which points it at the current profile.
	local config = additionalPower.config

	--additionalPower.Override       = config.manaAsPrimary and Update or nil
	additionalPower.colorPower     = config.colorPower
	additionalPower.colorCustom    = config.colorCustom
	additionalPower.customColor    = config.customColor
	additionalPower.smoothing      = UF:GetSmoothing(config.Smooth)

	-- UpdateElement showed the bar and its text from the config alone.
	ApplyVisibility(additionalPower)
end

local function GetConfigTable(unit)
	local generators = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function Config() return UF:GetProfileConfig()[unit].additionalpower end
	local function Update() UF:UpdateConfig(unit, 'AdditionalPower') end

	-- The settings in additionalpower[key].
	local function Section(order, name, key, args)
		return {
			order = order,
			name = name,
			type = 'group',
			inline = true,
			get = function(info) return Config()[key][info[#info]] end,
			set = function(info, value)
				Config()[key][info[#info]] = value
				Update()
			end,
			args = args,
		}
	end

	local enable = generators.enable(0)
	enable.desc = "Your mana, shown while your power bar shows a power the game pairs with mana (e.g. a shadow priest's insanity)."
	local colorPower = generators.toggle(6, 'Color by power type', 1)
	colorPower.desc = "Colors the bar and its background with the mana color. Nothing else colors them: with this off they keep the last color they had, white if this was never on."

	return {
		order = 3,
		type = 'group',
		name = 'Additional power',
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			Update()
		end,
		args = {
			enable = enable,
			framelevel = generators.framelevel(1),
			template = generators.template(2),
			size = UF.GenerateRelativeSizeConfigGroup(3),
			reverse_fill = generators.toggle(4, 'Reverse Fill', 1),
			vertical_fill = generators.toggle(5, 'Vertical Fill', 1),
			Smooth = generators.toggle(5.5, 'Smooth', 1),
			colorPower = colorPower,
			position = generators.uf_element_position(50,
				function(index) return Config().position[index] end,
				function(index, value)
					Config().position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'AdditionalPower')
			),
			text = Section(98, 'Text', 'text', {
				enable = generators.enable(0),
				font = generators.font(1),
				hide_full = generators.toggle(1.2, 'Hide full'),
				percent = generators.toggle(1.4, 'Percent'),
				position = generators.uf_element_position(2,
					function(index) return Config().text.position[index] end,
					function(index, value)
						Config().text.position[index] = value
						Update()
					end,
					UF:ConfigTarget(unit, 'AdditionalPower', 'text')
				),
			}),
			bg = Section(99, 'Status Bar BG', 'bg', {
				enable = generators.enable(0),
				multiplier = generators.range(2, 'Multiplier', 0, 1, 0.05),
				alpha = generators.alpha(3),
			}),
		},
	}
end

-- oUF only enables it on the player.
local function ValidUnit(unit)
	return unit == 'player'
end

if st.retail then
	UF:RegisterElement('AdditionalPower', Constructor, UpdateConfig, GetConfigTable, ValidUnit)
end