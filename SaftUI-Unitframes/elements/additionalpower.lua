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

	local G = generators
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
			enable = G.toggle(0, 'Enable',
				"Your mana, shown while your power bar shows a power the game pairs with mana (e.g. a shadow priest's insanity).", 'small'),
			reverse_fill = G.toggle(1, 'Reverse fill', 'Fills the bar from the other end: right to left, or top down when vertical.', 'small'),
			vertical_fill = G.toggle(2, 'Vertical fill', 'Fills the bar from the bottom up instead of from left to right.', 'small'),
			Smooth = G.toggle(3, 'Smooth', 'Slides the bar to each new value instead of jumping to it.', 'small'),
			theme = G.theme(4, "The mana bar's border and background."),
			background = G.background(4.5),
			alpha = G.alpha(5, 'How solid the mana bar is, from see-through to opaque.'),
			framelevel = G.framelevel(6, 'Draws the bar over the parts of the unit frame with a lower frame level, and under those with a higher one.'),
			size = UF.GenerateRelativeSizeConfigGroup(8),
			-- oUF's AdditionalPower knows only colorPower.
			colors = UF.GenerateColorsConfigGroup(9, unit, { 'colorPower' }, Config, Update, {
				colorPower = 'Colors the bar and its background in the mana color. With this and Custom both off, nothing colors them: they keep the last color they had.',
			}),
			text = Section(98, 'Text', 'text', {
				enable = G.toggle(0, 'Enable', 'Shows your mana as text, while the bar shows.', 'small'),
				hide_full = G.toggle(1, 'Hide full', 'Hides the text while your mana is full.', 'small'),
				font = G.font(2, "The mana text's font."),
				percent = G.toggle(3, 'Percent', 'Shows your mana as a percent instead of the number.', 'small'),
				-- Last in Text.
				position = G.uf_element_position(1000,
					function(index) return Config().text.position[index] end,
					function(index, value)
						Config().text.position[index] = value
						Update()
					end,
					UF:ConfigTarget(unit, 'AdditionalPower', 'text'),
					"Where the mana text sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
					'Text position'
				),
			}),
			bg = Section(99, 'Background', 'bg', {
				enable = G.toggle(0, 'Enable', "Shows a background in the bar's empty part, a darker shade of the bar's color.", 'small'),
				multiplier = G.range(1, 'Brightness', 0, 1, 0.05, "How light the shade is: 0 is black, 1 is the bar's own color."),
				alpha = G.alpha(2, 'How solid the background is, from see-through to opaque.'),
			}),
			-- Last in the tab, after Text and Background.
			position = G.uf_element_position(1000,
				function(index) return Config().position[index] end,
				function(index, value)
					Config().position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'AdditionalPower'),
				"Where the mana bar sits: which of its points goes to which point of what it's attached to, then moved by X and Y."
			),
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