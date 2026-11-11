local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Buffs and Debuffs are built on oUF's Auras meta element, which wraps Blizzard's
	AuraContainer. Aura data is no longer exposed to Lua (secret values), so the old
	Lua-side filters (whitelist/blacklist/time) and per-aura styling can't be applied.
	Filtering is done with the aura filter string (plus a candidate filter for Only
	mine, see AddGroup), and dispel/stealable coloring with the container's
	built-in dispel textures.

	Group options (filter, max count, button size, which borders to show, whether
	buttons get a cooldown) are baked in when the group is created on the first config
	update, so changing them requires a /reload, and their /sui options say so. Layout
	(anchor, growth, spacing, wrapping) and button styling (theme, count font and
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

-- Each button's dark line over its dispel border fill (see StyleButton).
local innerLines = setmetatable({}, { __mode = 'k' })

-- The element each button belongs to.
local buttonElements = setmetatable({}, { __mode = 'k' })

-- Shows a button's dark line while its element's Theme draws Thick, in Thick's
-- outer border color, and hides it otherwise. The line isn't part of the
-- backdrop the theme engine draws, so the engine runs this again after every
-- theme recolor and redraw (st:KeepOwnColors, from PostCreateButton).
local function ColorInnerLine(button)
	local inner, auras = innerLines[button], buttonElements[button]
	if not (inner and auras) then return end
	local look = st:ResolveTheme(auras.config.theme, auras.config.background)
	if look and look.name == 'thick' then
		inner:SetVertexColor(unpack(look.colors.altbordercolor))
		inner:Show()
	else
		inner:Hide()
	end
end

-- Applies the element's current config to one of its buttons. Runs when the
-- button is made and again on every config update, so it only sets things.
local function StyleButton(auras, button)
	local config = auras.config

	st:SetBackdrop(button, config.theme, config.background, 'aura')

	-- The dispel border is tinted by the aura container (PreserveAsset style) with a
	-- secret color, and addons can't read or hook it (.agents/taint.md rule 11), so
	-- SaftUI only restyles and moves it, and never reads its color.
	if button.Border then
		if st:IsBlizzardLook(config.theme, config.background) then
			-- Under Blizzard an aura's inset is 0, so a fill behind the icon would
			-- never show: the color goes on Blizzard's white icon border instead,
			-- over the icon's edge on the whole button, as Blizzard shows an
			-- item's quality. The dark line has nothing to sit on.
			button.Border:SetTexture(st.ThemeArt.ART.aura.border)
			button.Border:SetDrawLayer('OVERLAY')
			button.Border:ClearAllPoints()
			button.Border:SetAllPoints(button)
		else
			-- A flat fill behind the icon that covers our backdrop, so the gap
			-- between the icon and the backdrop's edge shows the dispel color.
			button.Border:SetTexture(st.BLANK_TEX)
			button.Border:SetDrawLayer('BACKGROUND')
			button.Border:ClearAllPoints()
			button.Border:SetAllPoints(button.backdrop)

			-- The fill shows in the whole gap between the icon and the backdrop's edge.
			-- Thick's gap is 2px, its border line and then a dark line, so the color
			-- would be 2px wide. This dark fill over it, 1px in from the edge and
			-- under the icon (BORDER layer), puts the dark line back on top.
			if not innerLines[button] and button.backdrop then
				local inner = button:CreateTexture(nil, 'BACKGROUND', nil, 1)
				inner:SetTexture(st.BLANK_TEX)
				inner:SetPoint('TOPLEFT', button.backdrop, 'TOPLEFT', 1, -1)
				inner:SetPoint('BOTTOMRIGHT', button.backdrop, 'BOTTOMRIGHT', -1, 1)
				innerLines[button] = inner
			end
		end
		-- Shown only under Thick, so hidden under Blizzard.
		ColorInnerLine(button)
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
	-- Blizzard's AuraContainer made the button: the Blizzard theme puts none of its
	-- art on it, but on a holder of SaftUI's. Before its first draw.
	st:MarkForeign(button)
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
	buttonElements[button] = auras
	st:KeepOwnColors(button, ColorInnerLine)

	StyleButton(auras, button)
end

-- Builds the aura group from config. Only runs once per element; see note at top.
local function AddGroup(unitframe, auras, aura_type)
	local config = auras.config

	-- Only mine: Forever leaves sourceUnit nil on other players' auras, and its
	-- PLAYER filter keeps every one of them. The isFromPlayerOrPlayerPet
	-- candidate filter checks each aura's own flag instead; on retail the two agree.
	local filter = AURA_FILTERS[aura_type]
	local candidateFilters
	if config.onlyShowPlayer then
		filter = filter .. '|PLAYER'
		candidateFilters = { isFromPlayerOrPlayerPet = true }
	end

	auras.groupKey = auras:AddGroup(filter, {
		candidateFilters = candidateFilters,
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
	else
		-- oUF copies the spacing into the group's layout only in AddGroup.
		auras:SetAuraGroupLayout(auras.groupKey, {
			elementSpacing = config.spacing,
			lineSpacing = config.spacing,
		})
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
	local function ButtonPosition(order, getPosition, what, name)
		return generators.position(order, false,
			function(index) return getPosition()[index] end,
			function(index, value)
				getPosition()[index] = value
				Update()
			end,
			nil,
			('Where the %s sits on each button: which of its points goes to which point of the button, then moved by X and Y.'):format(what),
			name
		)
	end

	local noun = aura_type == 'Buffs' and 'buffs' or 'debuffs'
	local FRAME_LEVEL = 'Draws the auras over the parts of the unit frame with a lower frame level, and under those with a higher one.'

	local initialAnchor = {
		order = 1,
		name = 'Initial anchor',
		desc = 'Where in the aura area the first button goes.',
		type = 'select',
		values = st.FRAME_ANCHORS,
	}

	local borderInfo = BORDERS[aura_type]
	local border = {
		order = 7,
		name = borderInfo.name,
		desc = borderInfo.desc,
		type = 'toggle',
		size = 'small',
		get = function() return eitherHostility(Config(), borderInfo.key) end,
		set = function(_, value)
			local config = Config()
			config.friend[borderInfo.key] = value
			config.enemy[borderInfo.key] = value
			Update()
		end,
	}

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
			enable = generators.toggle(0, 'Enable', ("Shows the unit's %s."):format(noun), 'small'),
			layout = {
				order = 1,
				name = 'Layout',
				type = 'group',
				inline = true,
				args = {
					initial_anchor = initialAnchor,
					grow_right = generators.toggle(2, 'Grow right', 'Each button goes to the right of the one before. Off, to the left.', 'small'),
					grow_up = generators.toggle(3, 'Grow up', 'Each new row goes above the one before. Off, below.', 'small'),
					per_row = generators.range(4, 'Per row', 1, 40, 1, 'How many buttons fill a row before the next row starts.'),
					spacing = generators.range(5, 'Spacing', 0, 30, 1, 'The gap between one button and the next, and between rows.'),
					framelevel = generators.framelevel(6, FRAME_LEVEL),
					-- Last in Layout.
					position = generators.uf_element_position(1000,
						function(index) return Config().position[index] end,
						function(index, value)
							Config().position[index] = value
							Update()
						end,
						UF:ConfigTarget(unit, aura_type),
						"Where the aura area sits: which of its points goes to which point of what it's attached to, then moved by X and Y."
					),
				},
			},
			buttons = {
				order = 2,
				name = 'Buttons',
				type = 'group',
				inline = true,
				args = {
					theme = generators.theme(1, "Each button's border and background."),
					background = generators.background(1.5),
					alpha = generators.alpha(2, ('How solid the %s are, from see-through to opaque.'):format(noun)),
					size = NeedsReload(generators.range(3, 'Size', 4, 80, 1, "Each button's width and height in pixels.")),
					relative_size = NeedsReload(generators.toggle(4, 'Relative size', "Size is added to the unit frame's height.", 'small')),
					max = NeedsReload(generators.range(5, 'Max', 1, 40, 1, ('The most %s shown.'):format(noun))),
					onlyShowPlayer = NeedsReload(generators.toggle(6, 'Only mine', 'Only auras you cast.', 'small')),
					border = NeedsReload(border),
				},
			},
			cooldown = Section(3, 'Cooldown', function() return Config().cooldown end, {
				enable = NeedsReload(generators.toggle(0, 'Show', 'The swipe over each button.', 'small')),
				reverse = generators.toggle(1, 'Reverse swipe', 'On, the dark part of the swipe shrinks as the aura runs out. Off, it grows.', 'small'),
				alpha = generators.alpha(2, 'How solid the swipe is, from see-through to opaque. The timer text fades with it.'),
				timer = Section(3, 'Timer', function() return Config().cooldown.timer end, {
					enable = generators.toggle(0, 'Enable', 'The time left, as text on each button. Needs the cooldown shown.', 'small'),
					-- Last in Timer.
					position = ButtonPosition(1000, function() return Config().cooldown.timer.position end, 'time left', 'Timer position'),
				}),
			}),
			count = Section(4, 'Count', function() return Config().count end, {
				font = generators.font(1, "The stack count's font."),
				-- Last in Count.
				position = ButtonPosition(1000, function() return Config().count.position end, 'stack count', 'Count position'),
			}),
		},
	}
end

UF:RegisterElement('Buffs', Constructor, UpdateConfig, function(unit) return GetConfigTable(unit, 'Buffs') end)
UF:RegisterElement('Debuffs', Constructor, UpdateConfig, function(unit) return GetConfigTable(unit, 'Debuffs') end)
