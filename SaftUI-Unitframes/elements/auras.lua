local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Buffs and Debuffs are built on oUF's Auras meta element, which wraps Blizzard's
	AuraContainer. Aura data is no longer exposed to Lua (secret values), so the old
	Lua-side filters (whitelist/blacklist/time) and per-aura styling can't be applied.
	Filtering is done with the aura filter string, and dispel/stealable coloring with
	the container's built-in dispel textures.

	Group options (filter, max count, button size, which borders to show, whether
	buttons get a cooldown) are baked in when the group is created on the first config
	update, so changing them requires a /reload, and their /sui options say so. Layout
	(anchor, growth, spacing, wrapping) and button styling (template, count font and
	spot, cooldown look and timer) update live, profile changes included.
]]

local AURA_FILTERS = {
	Buffs = 'HELPFUL',
	Debuffs = 'HARMFUL',
}

local function getButtonSize(unitframe, config)
	return config.relative_size
		and unitframe.config.height + config.size
		or config.size
end

local function eitherHostility(config, key)
	return (config.friend and config.friend[key]) or (config.enemy and config.enemy[key]) or false
end

-- Every button each aura element has made, so a config update can restyle them.
local buttonsByElement = setmetatable({}, { __mode = 'k' })

-- Applies the element's current config to one of its buttons. Runs when the
-- button is made and again on every config update, so it only sets things.
local function StyleButton(auras, button)
	local config = auras.config

	st:SetBackdrop(button, config.template)

	-- The dispel border is tinted by the aura container (PreserveAsset style) with a
	-- secret color, so instead of Blizzard's border art we make it a flat fill behind
	-- the icon that covers our backdrop, recoloring the SaftUI border by dispel type.
	if button.Border then
		button.Border:SetTexture(st.BLANK_TEX)
		button.Border:SetDrawLayer('BACKGROUND')
		button.Border:ClearAllPoints()
		button.Border:SetAllPoints(button.backdrop)
	end

	if button.Count then
		local countConfig = config.count or {}
		button.Count:SetFontObject(st:GetFont(countConfig.font or config.font))
		if countConfig.position then
			local point, _, relPoint, x, y = st:UnpackPoint(countConfig.position)
			button.Count:ClearAllPoints()
			button.Count:SetPoint(point, button, relPoint, x, y)
		end
	end

	local cooldown = button.Cooldown
	if cooldown then
		local showTimer = config.cooldown.timer.enable

		cooldown.noOCC = not showTimer
		cooldown.noCooldownCount = not showTimer
		cooldown:SetReverse(not config.cooldown.reverse)
		cooldown:SetAlpha(config.cooldown.alpha)
		cooldown:SetDrawEdge(false)
		cooldown:SetHideCountdownNumbers(not showTimer)

		local countdown = cooldown.GetCountdownFontString and cooldown:GetCountdownFontString()
		if countdown then
			cooldown.Duration = countdown
			if showTimer then
				countdown:SetAlpha(1)
				countdown:SetFontObject(st:GetFont('pixel'))
				countdown:ClearAllPoints()
				local point, _, relPoint, x, y = st:UnpackPoint(config.cooldown.timer.position)
				countdown:SetPoint(point, button, relPoint, x, y)
			else
				countdown:SetAlpha(0)
			end
		end
	end
end

local function PostCreateButton(auras, button)
	st:SkinIcon(button.Icon)

	local cooldown = button.Cooldown
	if cooldown then
		-- The aura container re-enables countdown numbers when it binds the
		-- cooldown, so force them back off whenever that happens while the
		-- timer is disabled. Reads the config at call time, so it follows
		-- config updates.
		hooksecurefunc(cooldown, 'SetHideCountdownNumbers', function(self, hide)
			if not hide and not auras.config.cooldown.timer.enable then
				self:SetHideCountdownNumbers(true)
			end
		end)
	end

	buttonsByElement[auras] = buttonsByElement[auras] or {}
	tinsert(buttonsByElement[auras], button)

	StyleButton(auras, button)
end

-- Builds the aura group from config. Only runs once per element; see note at top.
local function AddGroup(unitframe, auras, aura_type)
	local config = auras.config

	local filter = AURA_FILTERS[aura_type]
	if config.onlyShowPlayer then
		filter = filter .. '|PLAYER'
	end

	auras:AddGroup(filter, {
		maxFrameCount = config.max,
		size = getButtonSize(unitframe, config),
		showCount = true,
		showDebuffBorder = aura_type == 'Debuffs' and eitherHostility(config, 'colorTypes'),
		dispelBorderStyle = Enum.CustomAuraButtonDispelTypeTextureStyle.PreserveAsset,
		showStealableBorder = aura_type == 'Buffs' and eitherHostility(config, 'colorStealable'),
		disableCooldown = not config.cooldown.enable,
		tooltipAnchor = 'ANCHOR_TOPLEFT',
	})

	auras.hasGroup = true
end

local function UpdateConfig(unitframe, aura_type)
	local auras = unitframe[aura_type]
	local enabled = UF:UpdateElement(auras)

	auras:SetEnabled(enabled and true or false)
	if not enabled then return end

	local config = auras.config
	local size = getButtonSize(unitframe, config)
	local num_rows = ceil(config.max / config.per_row)
	local width = config.per_row * size + (config.per_row - 1) * config.spacing

	auras:SetHeight(num_rows * size + (num_rows - 1) * config.spacing)
	auras:SetWidth(width)
	st:SetBackdrop(auras, 'none')

	auras.elementSpacing = config.spacing
	auras.lineSpacing = config.spacing

	auras:SetFlowLayoutAnchorPoint(config.initial_anchor or 'TOPLEFT')
	auras:SetFlowLayoutMaximumLineSize(width)
	auras:SetFlowLayoutGrowthDirection(
		config.grow_right and 1 or -1,
		config.grow_up and 1 or -1
	)

	if not auras.hasGroup then
		AddGroup(unitframe, auras, aura_type)
	end

	for _, button in ipairs(buttonsByElement[auras] or {}) do
		StyleButton(auras, button)
	end
end

local function Constructor(unitframe, aura_type)
	local auras = unitframe:CreateAuras()

	auras.config = unitframe.config[string.lower(aura_type)]
	auras.GetConfig = function() return unitframe:GetConfig()[string.lower(aura_type)] end
	auras.name = aura_type
	auras.unitframe = unitframe
	auras.PostCreateButton = PostCreateButton

	unitframe[aura_type] = auras

	return auras
end

local RELOAD = 'Reload to apply (/reload): aura groups are built once, when the unit frame is set up.'

-- The border each aura type can show (AddGroup). Either hostility's setting
-- turns it on (eitherHostility), so the option sets both.
local BORDERS = {
	Buffs = { key = 'colorStealable', name = 'Stealable border', desc = 'A border on buffs you can steal.' },
	Debuffs = { key = 'colorTypes', name = 'Dispel type border', desc = "Colors each debuff's border by its dispel type." },
}

local function GetConfigTable(unit, aura_type)
	local generators = st.Config.generators
	local key = string.lower(aura_type)
	-- Looked up on every get/set: a profile change replaces these tables.
	local function Config() return UF:GetProfileConfig()[unit][key] end
	local function Update() UF:UpdateConfig(unit, aura_type) end

	-- An option StyleButton can't apply: it goes into AddGroup.
	local function NeedsReload(option)
		option.desc = option.desc and (option.desc .. ' ' .. RELOAD) or RELOAD
		return option
	end

	-- The settings in the table getTable returns.
	local function Section(order, name, getTable, args)
		return {
			order = order,
			name = name,
			type = 'group',
			inline = true,
			get = function(info) return getTable()[info[#info]] end,
			set = function(info, value)
				getTable()[info[#info]] = value
				Update()
			end,
			args = args,
		}
	end

	-- A spot on each button (its count, its timer), which StyleButton always
	-- anchors to the button: only the points and offsets are read.
	local function ButtonPosition(order, getPosition)
		return generators.position(order, false,
			function(index) return getPosition()[index] end,
			function(index, value)
				getPosition()[index] = value
				Update()
			end
		)
	end

	local initialAnchor = {
		order = 1,
		name = 'Initial anchor',
		desc = 'Where in the aura area the first button goes.',
		type = 'select',
		values = st.FRAME_ANCHORS,
		width = 0.75,
	}

	local relativeSize = generators.toggle(3, 'Relative size', 1)
	relativeSize.desc = "Size is added to the unit frame's height."
	local onlyShowPlayer = generators.toggle(5, 'Only mine', 1)
	onlyShowPlayer.desc = 'Only auras you cast.'

	local borderInfo = BORDERS[aura_type]
	local border = {
		order = 6,
		name = borderInfo.name,
		desc = borderInfo.desc,
		type = 'toggle',
		width = 1,
		get = function() return eitherHostility(Config(), borderInfo.key) end,
		set = function(_, value)
			local config = Config()
			config.friend[borderInfo.key] = value
			config.enemy[borderInfo.key] = value
			Update()
		end,
	}

	local showCooldown = generators.toggle(0, 'Show', 0.5)
	showCooldown.desc = 'The swipe over each button.'
	local showTimer = generators.enable(0)
	showTimer.desc = 'The time left, as text on each button. Needs the cooldown shown.'

	return {
		order = aura_type == 'Buffs' and 7 or 8,
		type = 'group',
		name = aura_type,
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			Update()
		end,
		args = {
			enable = generators.enable(0),
			layout = {
				order = 1,
				name = 'Layout',
				type = 'group',
				inline = true,
				args = {
					initial_anchor = initialAnchor,
					grow_right = generators.toggle(2, 'Grow right', 0.6),
					grow_up = generators.toggle(3, 'Grow up', 0.6),
					per_row = generators.range(4, 'Per row', 1, 40, 1),
					spacing = generators.range(5, 'Spacing', 0, 30, 1),
					framelevel = generators.framelevel(6),
					position = generators.uf_element_position(50,
						function(index) return Config().position[index] end,
						function(index, value)
							Config().position[index] = value
							Update()
						end,
						UF:ConfigTarget(unit, aura_type)
					),
				},
			},
			buttons = {
				order = 2,
				name = 'Buttons',
				type = 'group',
				inline = true,
				args = {
					template = generators.template(1),
					size = NeedsReload(generators.range(2, 'Size', 4, 80, 1)),
					relative_size = NeedsReload(relativeSize),
					max = NeedsReload(generators.range(4, 'Max', 1, 40, 1)),
					onlyShowPlayer = NeedsReload(onlyShowPlayer),
					border = NeedsReload(border),
				},
			},
			cooldown = Section(3, 'Cooldown', function() return Config().cooldown end, {
				enable = NeedsReload(showCooldown),
				reverse = generators.toggle(1, 'Reverse swipe', 1),
				alpha = generators.alpha(2),
				timer = Section(3, 'Timer', function() return Config().cooldown.timer end, {
					enable = showTimer,
					position = ButtonPosition(1, function() return Config().cooldown.timer.position end),
				}),
			}),
			count = Section(4, 'Count', function() return Config().count end, {
				font = generators.font(1),
				position = ButtonPosition(2, function() return Config().count.position end),
			}),
		},
	}
end

UF:RegisterElement('Buffs', Constructor, UpdateConfig, function(unit) return GetConfigTable(unit, 'Buffs') end)
UF:RegisterElement('Debuffs', Constructor, UpdateConfig, function(unit) return GetConfigTable(unit, 'Debuffs') end)
