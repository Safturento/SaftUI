local st = SaftUI
local UF = st:GetModule('Unitframes')

local function getHealthPercentText(perc, precision)
	if precision and precision > 0 then
		return ('%0.' .. (precision) .. 'f'):format(perc)
	end

	return floor(perc)
end

local function PostUpdateHealth(health, unit, current, max)
	local deficit = issecretvalue(current) and C_StringUtil.TruncateWhenZero(UnitHealthMissing(unit)) or max - current
	local percent = issecretvalue(current) and UnitHealthPercent(unit) or current / max * 100

	if health.text then
		if health.config.text.hide_full and deficit == 0 then
			health.text:SetText('')
		elseif UnitIsDead(unit) then
			health.text:SetText('Dead')
		elseif health.config.text.deficit then
			if st.retail then
				health.text:SetText(C_StringUtil.WrapString(deficit, '-'))
			else
				if deficit <= 0 then
					health.text:SetText('')
				else
					health.text:SetText('-' .. st.StringFormat:ShortFormat(deficit))
				end
			end
		elseif health.config.text.percent then
			health.text:SetText(getHealthPercentText(percent))
		else
			local text
			text = current

			if health.config.text.boss_percent and UnitLevel(unit) == -1 then
				text = ("%s | %s"):format(text, getHealthPercentText(percent, 1))
			end

			health.text:SetText(text)
		end
	end

	if health.config.bg.enable then
		r, g, b = health:GetStatusBarColor()
		local mu = health.config.bg.multiplier or 1
		health.bg:SetVertexColor(mu, mu, mu)
	end
end

-- oUF's Path runs Update (PostUpdate) and then ColorPath, which recolors the
-- bar for any color flag; PostUpdateColor is the callback after that.
local function PostUpdateColor(health)
	if health.config.colorCustom then
		health:SetStatusBarColor(UF.UnpackColor(health.config.customColor))
	end
end

local function Constructor(unitframe)
    local health = UF:AddStatusBarElement(unitframe, 'Health')

	UF:AddText(unitframe, health)
	health.PostUpdate = PostUpdateHealth
	health.PostUpdateColor = PostUpdateColor

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
	health.smoothing		 = UF:GetSmoothing(config.Smooth)
end



-- The status bar textures LibSharedMedia has, by name (SaftUI's and any other
-- addon's), as st:GetStatusBarTexture looks them up.
local function StatusBarTextures()
	local textures = {}
	for _, name in ipairs(st.LSM:List('statusbar')) do
		textures[name] = name
	end
	return textures
end

local function GetConfigTable(unit)
	local G = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function UnitConfig() return UF:GetProfileConfig()[unit] end
	local function Update() UF:UpdateConfig(unit, 'Health') end

	local text = {
		enable = G.toggle(0, 'Enable', "Shows the health as text on the unit frame.", 'small'),
		hide_full = G.toggle(1, 'Hide full', 'Hides the text while health is full.', 'small'),
		font = G.font(2, "The health text's font."),
		deficit = G.toggle(3, 'Deficit', 'Shows how much health is missing, as -1234, instead of the health.', 'small'),
		percent = G.toggle(4, 'Percent', 'Shows the health as a percent instead. Deficit wins when both are on.', 'small'),
		-- Last in Text.
		position = G.uf_element_position(1000,
			function(index) return UnitConfig().health.text.position[index] end,
			function(index, value)
				UnitConfig().health.text.position[index] = value
				Update()
			end,
			UF:ConfigTarget(unit, 'Health', 'text'),
			"Where the health text sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
			'Text position'
		),
	}
	-- PostUpdateHealth adds it for a unit whose level is -1 (a skull).
	if UF.CanShow(unit, 'mobs') then
		text.boss_percent = G.toggle(5, 'Boss percent',
			'On a skull-level unit, such as a boss, adds the health percent after the health: 1234567 | 45.6. Not with Deficit or Percent on.', 'small')
	end

	return {
		type = 'group',
		name = 'Health',
		order = 1,
		get = function(info)
			return UnitConfig().health[info[#info]]
		end,
		set = function(info, value)
			UnitConfig().health[info[#info]] = value
			Update()
		end,
		args = {
			enable = G.toggle(0, 'Enable', "Shows the health bar.", 'small'),
			reverse_fill = G.toggle(1, 'Reverse fill', 'Fills the bar from the other end: right to left, or top down when vertical.', 'small'),
			vertical_fill = G.toggle(2, 'Vertical fill', 'Fills the bar from the bottom up instead of from left to right.', 'small'),
			Smooth = G.toggle(3, 'Smooth', 'Slides the bar to each new value instead of jumping to it.', 'small'),
			theme = G.theme(4, "The health bar's border and background."),
			background = G.background(4.5),
			texture = {
				order = 5,
				name = 'Texture',
				desc = 'What the bar is filled with.',
				type = 'select',
				values = StatusBarTextures,
			},
			alpha = G.alpha(6, 'How solid the health bar is, from see-through to opaque.'),
			framelevel = G.framelevel(7, 'Draws the bar over the parts of the unit frame with a lower frame level, and under those with a higher one.'),
			size = UF.GenerateRelativeSizeConfigGroup(8),
			colors = UF.GenerateColorsConfigGroup(9, unit,
				{ 'colorDisconnected', 'colorTapping', 'colorClass', 'colorClassNPC', 'colorClassPet', 'colorReaction', 'colorSmooth', 'colorHealth' },
				function() return UnitConfig().health end, Update),
			text = {
				order = 98,
				name = 'Text',
				type = 'group',
				inline = true,
				get = function(info)
					return UnitConfig().health.text[info[#info]]
				end,
				set = function(info, value)
					UnitConfig().health.text[info[#info]] = value
					Update()
				end,
				args = text,
			},
			bg = {
				order = 99,
				name = 'Background',
				type = 'group',
				inline = true,
				get = function(info)
					return UnitConfig().health.bg[info[#info]]
				end,
				set = function(info, value)
					UnitConfig().health.bg[info[#info]] = value
					Update()
				end,
				args = {
					enable = G.toggle(0, 'Enable', "Shows a grey background in the bar's empty part.", 'small'),
					multiplier = G.range(1, 'Brightness', 0, 1, 0.05, 'How light the grey is: 0 is black, 1 is white.'),
					alpha = G.alpha(2, 'How solid the background is, from see-through to opaque.'),
				},
			},
			-- Last in the tab, after Text and Background.
			position = G.uf_element_position(1000,
				function(index)
					return UnitConfig().health.position[index]
				end,
				function(index, value)
					UnitConfig().health.position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'Health'),
				"Where the health bar sits: which of its points goes to which point of what it's attached to, then moved by X and Y."
			),
		}
	}
end

UF:RegisterElement('Health', Constructor, UpdateConfig, GetConfigTable)
