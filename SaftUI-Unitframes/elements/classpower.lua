local st = SaftUI
local UF = st:GetModule('Unitframes')

-- point -> { empty, filled }: the textures of SaftUI's that draw a point in
-- Blizzard's art (.agents/taint.md: kept here, never in a field on a frame).
local pointArt = setmetatable({}, { __mode = 'k' })

-- classPower -> the last { powerType, cur, charged = { [index] = true } } oUF
-- passed PostUpdate, so a config or theme change can draw the points again
-- before the next power event.
local lastState = setmetatable({}, { __mode = 'k' })

-- How tall each point is: config.height, or with Relative on the unit frame's
-- height plus it (UF:ElementSize, which also sizes the row).
local function PointHeight(classPower)
	local _, height = UF:ElementSize(classPower)
	return height
end

-- point -> the kind it was last drawn as, so a power type change draws it
-- again only when its kind changes.
local pointKind = setmetatable({}, { __mode = 'k' })

-- The kind a point draws as: a control where Blizzard has art for the power
-- type (the art is drawn by ApplyArt), a small frame's 1px line where it has
-- none (retail's soul fragments, icicles, tip of the spear). A control until
-- the first power event says the type.
local function PointKind(classPower)
	local state = lastState[classPower]
	if state and state.powerType
		and not st.ThemeArt.ClassPower(state.powerType, 1, st.my_class, false) then
		return 'small'
	end
	return 'control'
end

local function DrawPoint(classPower, point)
	local kind = PointKind(classPower)
	local config = classPower.config
	st:SetBackdrop(point, config.theme, config.background, kind)
	pointKind[point] = kind
end

local function PointArt(point)
	local set = pointArt[point]
	if not set then
		local empty = point:CreateTexture(nil, 'BACKGROUND')
		local filled = point:CreateTexture(nil, 'ARTWORK', nil, 1)
		for _, texture in ipairs({ empty, filled }) do
			-- Centred, so the point's width (set on every power update) doesn't
			-- change it.
			texture:SetPoint('CENTER')
			texture:Hide()
		end
		set = { empty = empty, filled = filled }
		pointArt[point] = set
	end
	return set
end

-- Draws every point as its Theme says: Blizzard's empty art behind and its
-- filled art while the point is full (the charged art for a charged point),
-- the flat fill hidden; the flat bar for Thick, Thin and a power type with no
-- art.
local function ApplyArt(classPower)
	local config = classPower.config
	local height = PointHeight(classPower)
	local blizzard = st:IsBlizzardLook(config.theme, config.background)
	local state = lastState[classPower]
	local powerType = state and state.powerType
	local kind = PointKind(classPower)
	for i = 1, #classPower do
		local point = classPower[i]
		if pointKind[point] ~= kind then DrawPoint(classPower, point) end
		local empty, filled
		if blizzard and powerType then
			empty, filled = st.ThemeArt.ClassPower(powerType, i, st.my_class, state.charged[i])
		end
		local fill = point:GetStatusBarTexture()
		if empty then
			local set = PointArt(point)
			set.empty:SetAtlas(empty)
			set.filled:SetAtlas(filled)
			st:SetSize(set.empty, height, height)
			st:SetSize(set.filled, height, height)
			set.empty:Show()
			-- Every power type with art gives an integer cur; only demon hunter
			-- soul fragments are fractional, and they have no art, so they keep
			-- the flat bar with its partial fill.
			set.filled:SetShown(state.cur ~= nil and i <= state.cur)
			-- Alpha, not Hide: the StatusBar owns its fill's shown state.
			if fill then fill:SetAlpha(0) end
		else
			local set = pointArt[point]
			if set then
				set.empty:Hide()
				set.filled:Hide()
			end
			if fill then fill:SetAlpha(1) end
		end
	end
end

local function PostUpdateClassPower(classPower, cur, max, hasCurChanged, hasMaxChanged, powerType, ...)
	-- oUF passes no max only when the element itself is disabled. When class
	-- power turns off with the power type (e.g. a druid leaving cat form), oUF
	-- hides the points itself without calling this; the container has no
	-- backdrop, so nothing is left on screen. Otherwise class power is on, and
	-- the container follows Enable.
	if not max then classPower:Hide() return end
	classPower:SetShown(classPower.config.enable and true or false)
	local width = (classPower:GetWidth() - (classPower.config.spacing * (max - 1))) / max
	for i = 1, max do
		classPower[i]:SetWidth(width)
	end
	-- The charged points' indices come after the power type.
	local charged = {}
	for n = 1, select('#', ...) do
		charged[select(n, ...)] = true
	end
	lastState[classPower] = { powerType = powerType, cur = cur, charged = charged }
	ApplyArt(classPower)
end

local function Constructor(unitframe)
	if not (unitframe.base_unit == 'player') then return end

	local classPower = UF:AddElement('Frame', unitframe, 'ClassPower')
	for i = 1, 10 do
		classPower[i] =  CreateFrame('StatusBar', nil, classPower)
	end

	classPower.PostUpdate = PostUpdateClassPower
	return classPower
end

local function UpdateConfig(unitframe)
    local classPower = unitframe.ClassPower
    -- Draws no backdrop on the row (updaters.lua's BARE_ELEMENTS): each point
    -- is drawn below.
    UF:UpdateElement(classPower)

	local height = PointHeight(classPower)
	local prev
	for i=1, 10 do
		local point = classPower[i]
		-- A control (nothing under Blizzard, whose art ApplyArt draws), or a
		-- small line for a power type with no art.
		DrawPoint(classPower, point)

		point:SetStatusBarTexture(st.BLANK_TEX)
		point:ClearAllPoints()
		if prev then
			point:SetPoint('LEFT', prev, 'RIGHT', classPower.config.spacing, 0)
		else
			point:SetPoint('LEFT')
		end
		point:SetHeight(height)
		prev = point
	end
	ApplyArt(classPower)
end

local function GetConfigTable(unit)
	local generators = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function Config() return UF:GetProfileConfig()[unit].classpower end
	local function Update() UF:UpdateConfig(unit, 'ClassPower') end

	-- Width, Relative | Height, Relative: the shared line, with the row's own
	-- words for Width and Height.
	local size = UF.GenerateRelativeSizeConfigGroup(5)
	size.args.width.desc = "The whole row's width in pixels, shared out among the points. With Relative on, it's added to the unit frame's width: 0 is as wide as the unit frame."
	size.args.height.desc = "Each point's height in pixels. With Relative on, it's added to the unit frame's height: 0 is as tall as the unit frame, -4 is 4 shorter."

	return {
		order = 4,
		type = 'group',
		name = 'Class power',
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			Update()
		end,
		args = {
			-- A half, so Theme sits beside it with no empty quarter between.
			enable = generators.enable(0, 'Shows your combo points, holy power, chi, soul shards and the like, as a row of points.'),
			theme = generators.theme(1, "Each point's border and background."),
			background = generators.background(1.5),
			alpha = generators.alpha(2, 'How solid the points are, from see-through to opaque.'),
			framelevel = generators.framelevel(3, 'Draws the points over the parts of the unit frame with a lower frame level, and under those with a higher one.'),
			spacing = generators.range(4, 'Spacing', 0, 20, 1, 'The gap between one point and the next.'),
			size = size,
			-- Last in the tab.
			position = generators.uf_element_position(1000,
				function(index) return Config().position[index] end,
				function(index, value)
					Config().position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'ClassPower'),
				"Where the row sits: which of its anchor points goes to which point of what it's attached to, then moved by X and Y."
			),
		},
	}
end

local function ValidUnit(unit)
	return unit == 'player'
end

UF:RegisterElement('ClassPower', Constructor, UpdateConfig, GetConfigTable, ValidUnit)
