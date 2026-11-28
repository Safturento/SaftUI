local st = SaftUI
local UF = st:GetModule('Unitframes')

-- The health text of a plain (not secret) health: Hide full, Dead, Deficit,
-- Percent, then the value, with the percent after it on a boss when asked. The
-- nameplate preview shows its sample health through this too.
function UF.PlainHealthText(config, current, max, dead, isBoss)
	if config.hide_full and max - current == 0 then
		return ''
	elseif dead then
		return 'Dead'
	elseif config.deficit then
		-- Blank at zero, as the game's TruncateWhenZero is.
		local deficit = max - current
		return deficit == 0 and '' or '-' .. deficit
	elseif config.percent then
		return ('%.0f'):format(current / max * 100)
	end
	local text = current
	if config.short then
		text = UF.ShortNumber(current)
	end
	if config.boss_percent and isBoss then
		text = ('%s | %s'):format(text, ('%.1f'):format(current / max * 100))
	end
	return tostring(text)
end

-- A secret health (enemy nameplates in restricted content) can't be
-- subtracted, divided or compared here: the game works out what the text
-- shows, and only the text that's shown is worked out.
local function PostUpdateHealth(health, unit, current, max)
	if health.text then
		local config = health.config.text
		local secret = issecretvalue(current) or issecretvalue(max)
		if not secret then
			-- A secret level can't be compared with -1: no percent then.
			local level = config.boss_percent and UnitLevel(unit)
			local isBoss = level and not issecretvalue(level) and level == -1
			health.text:SetText(UF.PlainHealthText(config, current, max, UnitIsDead(unit), isBoss))
		else
			-- No game function tells an addon whether a secret deficit is zero,
			-- so Hide full applies to a plain health only: a secret health
			-- shows its text.
			if UnitIsDead(unit) then
				health.text:SetText('Dead')
			elseif config.deficit then
				-- The game blanks a zero deficit.
				local deficit = C_StringUtil.TruncateWhenZero(UnitHealthMissing(unit))
				health.text:SetText(C_StringUtil.WrapString(deficit, '-'))
			elseif config.percent then
				-- The game rounds a secret percent and Lua can't floor it.
				health.text:SetFormattedText('%.0f', UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
			else
				local text = current
				if config.short then
					text = UF.ShortNumber(current)
				end

				local level = config.boss_percent and UnitLevel(unit)
				if level and not issecretvalue(level) and level == -1 then
					health.text:SetFormattedText('%s | %.1f', text, UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
				else
					health.text:SetText(text)
				end
			end
		end
	end

	if health.config.bg.enable then
		local r, g, b = health:GetStatusBarColor()
		local mu = health.config.bg.multiplier or 1
		health.bg:SetVertexColor(mu, mu, mu)
	end
end

-- oUF's Path runs Update (PostUpdate) and then ColorPath, which recolors the
-- bar for any color flag; PostUpdateColor is the callback after that. An enemy
-- nameplate's threat tint (nameplates/threat.lua, frame.threatState) comes
-- last, so it wins over every color each time oUF colors the bar.
local function PostUpdateColor(health)
	if health.config.colorCustom then
		health:SetStatusBarColor(UF.UnpackColor(health.config.customColor))
	end
	local state = health.unitframe.threatState
	if state == 'warning' or state == 'bad' then
		local color = st.config.profile.colors.threat[state]
		health:SetStatusBarColor(color.r, color.g, color.b)
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

	-- colorTapping and colorReaction through oUF's setters, so their event
	-- follows them (UF.SetFactionColorFlags).
	UF.SetFactionColorFlags(health, config)
	health.colorDisconnected = config.colorDisconnected
	health.colorHealth		 = config.colorHealth
	health.colorClass		 = config.colorClass
	health.colorClassNPC	 = config.colorClassNPC
	health.colorClassPet	 = config.colorClassPet
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
		max_width = G.max_width(2.4, 'health text'),
		justify = G.justify(2.5, 'health text', function() return UnitConfig().health.text.max_width end),
		deficit = G.toggle(3, 'Deficit', 'Shows how much health is missing, as -1234, instead of the health.', 'small'),
		percent = G.toggle(4, 'Percent', 'Shows the health as a percent instead. Deficit wins when both are on.', 'small'),
		short = G.toggle(4.5, 'Short', 'Shortens the health, as 12.5K or 1.2M. Not with Deficit or Percent on.', 'small'),
		-- Without it the text keeps its font's color, white.
		customColor = UF.CustomColorOption(6, {
			name = 'Text color',
			desc = 'Colors the health text with this color.',
			offDesc = "Unticked, the text keeps its font's color: white.",
			offText = 'White',
			unit = unit,
			path = { 'health', 'text' },
			config = function() return UnitConfig().health.text end,
			update = Update,
		}),
		-- Last in Text.
		position = G.uf_element_position(1000,
			function(index) return UnitConfig().health.text.position[index] end,
			function(index, value)
				UnitConfig().health.text.position[index] = value
				Update()
			end,
			UF:ConfigTarget(unit, 'Health', 'text'),
			"Where the health text sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
			'Text position', UF.SavedAt(unit, 'health', 'text', 'position')
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
		saved = UF.SavedIn(unit, 'health'),
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
			colors = UF.GenerateColorsConfigGroup(9, unit, 'health',
				{ 'colorDisconnected', 'colorTapping', 'colorClass', 'colorClassNPC', 'colorClassPet', 'colorReaction', 'colorSmooth', 'colorHealth' },
				function() return UnitConfig().health end, Update),
			text = {
				order = 98,
				name = 'Text',
				type = 'group',
				inline = true,
				saved = UF.SavedIn(unit, 'health', 'text'),
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
				name = 'Bar background',
				type = 'group',
				inline = true,
				saved = UF.SavedIn(unit, 'health', 'bg'),
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
			-- The tab's second panel: after the bar's own settings and its size line (the first section), before Colors, Text and Bar background.
			position = G.uf_element_position(8.5,
				function(index)
					return UnitConfig().health.position[index]
				end,
				function(index, value)
					UnitConfig().health.position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'Health'),
				"Where the health bar sits: which of its points goes to which point of what it's attached to, then moved by X and Y.",
				nil, UF.SavedAt(unit, 'health', 'position')
			),
		}
	}
end

UF:RegisterElement('Health', Constructor, UpdateConfig, GetConfigTable)
