local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Buffs and Debuffs are built on oUF's Auras meta element, which wraps Blizzard's
	AuraContainer. Aura data is no longer exposed to Lua (secret values), so the old
	Lua-side filters (whitelist/blacklist/time) and per-aura styling can't be applied.
	Filtering is done with the aura filter string and candidate filters
	(UF.AuraFilter, aurafilters.lua: Only mine, Only buffs I can purge, a nameplate's
	debuffs), and dispel/stealable coloring with the container's built-in
	dispel textures.

	The group is made once, on the first config update with the area on. Which
	borders its buttons show and whether they get a cooldown are baked into each
	button as the container makes it, so changing them requires a /reload, and
	their /sui options say so (ReloadNote, below, which on the nameplate pages
	says which page's a plate's buttons take). Everything else updates live,
	profile changes included: the filter, the layout (anchor, growth, spacing,
	wrapping), the button styling (theme, count font and spot, cooldown look
	and timer), the max count (through the container,
	SetAuraGroupMaxFrameCount) and the button size (set on each button as it's
	styled: the container has no call for it). A plate's frame draws from
	Enemy or Friendly nameplates by its unit's kind (nameplates.lua), but its
	group is made from the first page that shows the area on it, which is
	Enemy nameplates whenever its area is on (a plate's first update is from
	it), so this is what gives a friend's plate the Friendly page's count and
	size. In combat the buttons can't be touched, so their size waits for the
	end of combat (RestyleButtons). The borders and the cooldown a plate's
	buttons are made with stay that page's, even after a reload: the Friendly
	page's reach friendly plates only while the Enemy page has the area off.
]]

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

-- Every aura container SaftUI has made (Constructor), as keys. A plate's
-- rounding walk (nameplates/pixels.lua) leaves them alone by this, before it
-- calls anything on them: AuraContainer is an XML intrinsic, which the game
-- may not report through IsObjectType.
UF.auraContainers = UF.auraContainers or setmetatable({}, { __mode = 'k' })

-- Rounds a region SaftUI made on a plate's aura button (its backdrop, Thick's
-- line) to whole pixels with the rest of the plate (nameplates/pixels.lua),
-- whose own walk stops at the aura container. Other units' are left as they
-- are.
local function RoundOnPlate(auras, region)
	if region and auras.unitframe and auras.unitframe.isNamePlate and UF.RoundLayout then
		UF.RoundLayout(region, true)
	end
end

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

	-- Its size: oUF's button gets the size its group was made with, which is
	-- the first config's (a plate's: Enemy nameplates' while that page has
	-- the area on, whatever kind it shows now), so it's set from the config in
	-- use, as oUF sets it (SetSize).
	local size = getButtonSize(auras.unitframe, config)
	button:SetSize(size, size)

	st:SetBackdrop(button, config.theme, config.background, 'aura')

	-- On a plate, each button's backdrop, a frame of SaftUI's, is rounded here,
	-- where it's drawn: when the button is made (PostCreateButton) and after
	-- every config update, which can draw new art (a theme switch). The button
	-- and what Blizzard's container puts on it are left alone.
	RoundOnPlate(auras, button.backdrop)

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
				-- SaftUI's texture, though it's on Blizzard's button.
				RoundOnPlate(auras, inner)
			end
		end
		-- Shown only under Thick, so hidden under Blizzard.
		ColorInnerLine(button)
	end

	if button.Count then
		local countConfig = config.count or {}
		st:ApplyFont(button.Count, countConfig.font or config.font)
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
				st:ApplyFont(countdown, 'pixel')
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

	-- Noted as the group's filter, so UF:ApplyAuraFilter changes it only when
	-- the config or the spells the player knows change it.
	local filter, candidateFilters = UF.AuraFilter(unitframe, aura_type, config)
	auras.groupFilter = filter
	auras.groupCandidateFilters = candidateFilters

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

-- Asks the container to lay the group's buttons out again, with the config's
-- spacing (oUF copies the spacing into the group's layout only in AddGroup).
-- The container lays them out only when something marks its layout dirty, as
-- this does (CustomAuraContainerSharedMixin:SetAuraGroupLayout, both clients),
-- never because a button changed size.
local function LayOutGroup(auras)
	auras:SetAuraGroupLayout(auras.groupKey, {
		elementSpacing = auras.config.spacing,
		lineSpacing = auras.config.spacing,
	})
end

-- Styles every button the element has made again, from a config update.
-- Blizzard's container restricts each button once PostCreateButton has styled
-- it: while aura data is secret (in combat), addon code can't touch the button
-- or anything on it, its backdrop included (.agents/taint.md rule 11). So in
-- combat this waits for the end of combat, once per element, and then has the
-- group laid out again, since the buttons' size may have changed since the
-- update laid it out. A frame made in combat gets its first update then
-- (UF.InitUnit), whose new buttons PostCreateButton has just styled.
local function RestyleButtons(auras, afterCombat)
	local secret = C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()
	if issecretvalue(secret) or secret or InCombatLockdown() then
		st:QueueAfterCombat(auras, function() RestyleButtons(auras, true) end)
		return
	end
	for _, button in ipairs(buttonsByElement[auras] or {}) do
		StyleButton(auras, button)
	end
	if afterCombat and auras.hasGroup then LayOutGroup(auras) end
end

local function UpdateConfig(unitframe, aura_type)
	local auras = unitframe[aura_type]
	local enabled = UF:UpdateElement(auras)

	-- On or off as its config says (UF:ElementWanted; a friendly plate's is
	-- the friendly config, nameplates.lua).
	auras:SetEnabled(UF:ElementWanted(auras))
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
		LayOutGroup(auras)
		-- Max, without a reload, and a plate's kind's: the container's own
		-- call (both clients), which does nothing for the count it has, and
		-- touches no button, so in combat too.
		auras:SetAuraGroupMaxFrameCount(auras.groupKey, config.max)
		-- Only mine and Only buffs I can purge, without a reload.
		UF:ApplyAuraFilter(auras)
	end

	RestyleButtons(auras)
end

local function Constructor(unitframe, aura_type)
	local auras = unitframe:CreateAuras()
	UF.auraContainers[auras] = true

	auras.config = unitframe.config[string.lower(aura_type)]
	auras.GetConfig = function(_, unit) return unitframe:GetConfig(unit)[string.lower(aura_type)] end
	auras.name = aura_type
	auras.unitframe = unitframe
	auras.PostCreateButton = PostCreateButton

	unitframe[aura_type] = auras

	return auras
end

local RELOAD = 'Reload to apply (/reload): aura groups are built once, when the unit frame is set up.'

-- The note an aura area's Border and Cooldown -> Show end with on a unit's
-- page. On the two nameplate pages a plate's group is made on the frame's
-- first update with the area on, and that first update is always from Enemy
-- nameplates, whatever the plate's unit (nameplates.lua). So while the Enemy
-- page has the area on, its settings make every plate's buttons, friendly
-- ones too, and the Friendly page's reach friendly plates only while it has
-- the area off (ruling N2, docs/followups.md). Other units' say to reload.
local function ReloadNote(unit, aura_type)
	if unit == 'nameplate' then
		return ("Reload to apply (/reload): a plate's buttons are made once, with the settings of the first page that shows them on it, which is this one whenever its %s are on, for friendly plates too."):format(aura_type)
	elseif unit == 'friendlynameplate' then
		return ("Reaches friendly plates only while Enemy nameplates has its %s off, and then after a reload (/reload): a plate's buttons are made once, with the settings of the first page that shows them on it, which is Enemy nameplates whenever its %s are on."):format(aura_type, aura_type)
	end
	return RELOAD
end

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
	local note = ReloadNote(unit, aura_type)
	local function NeedsReload(option)
		option.desc = option.desc and (option.desc .. ' ' .. note) or note
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
					-- Size and Max apply without a reload (StyleButton, the
					-- container's max count); a size set in combat once it ends.
					size = generators.range(3, 'Size', 4, 80, 1, "Each button's width and height in pixels."),
					relative_size = generators.toggle(4, 'Relative size', "Size is added to the unit frame's height.", 'small'),
					max = generators.range(5, 'Max', 1, 40, 1, ('The most %s shown.'):format(noun)),
					-- The filter applies without a reload (UF:ApplyAuraFilter).
					onlyShowPlayer = generators.toggle(6, 'Only mine', 'Only auras you cast.', 'small'),
					purgeable = aura_type == 'Buffs' and generators.toggle(6.5, 'Only buffs I can purge', "Shows only buffs you can take off the unit with a spell you know: a purge, a dispel or a steal. If you know none, no buffs show.", 'small') or nil,
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
