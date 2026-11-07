local st = SaftUI
local AP = st:NewModule('Auras')

--[[
	Makes Blizzard's player BuffFrame and DebuffFrame SaftUI movers, positioned and laid
	out only from the SaftUI profile. Blizzard's frames and aura buttons are kept: they
	still sort the auras, show weapon enchants first, run the collapse button, cancel
	buffs on right-click and draw private auras. The buttons' look (backdrop, dispel
	colors, and their duration and stack count text) is Blizzard_BuffFrame.lua, which reads
	the text settings from this module (GetTextStyle).

	How Blizzard lays them out (Blizzard_BuffFrame, the same on Forever and retail):
	  - Each frame is an Edit Mode system (AuraFrameEditModeTemplate). Its buttons are plain,
	    non-secure Buttons (AuraButtonTemplate), parented to frame.AuraContainer and listed
	    in frame.auraFrames: maxAuras of them (BUFF_MAX_DISPLAY 32, DEBUFF_MAX_DISPLAY 16),
	    then, for DebuffFrame only, six private aura anchors (isAuraAnchor).
	  - The Edit Mode settings Orientation, Icon Wrap, Icon Direction, Icon Limit, Icon Size
	    and Icon Padding only write Lua fields on the AuraContainer (isHorizontal,
	    addIconsToTop, addIconsToRight, iconStride, iconScale, iconPadding).
	  - frame:UpdateGridLayout reads those fields. It scales and sizes every button (30x40,
	    or 60x30 vertical), puts the 30x30 Icon at the button's top, the duration under it,
	    and anchors the buttons in a grid off the container's corner (GridLayoutUtil). The
	    container sits in the frame's corner, next to BuffFrame's 15px collapse button.
	    UpdateSize then sizes the frame for the whole grid.
	  - UpdateGridLayout runs on load, on every Edit Mode layout load or setting change, and
	    when buff consolidation changes. For DebuffFrame it also runs on every aura change:
	    DebuffFrame only anchors shown buttons (doNotAnchorDisabledFrames), so its private
	    aura anchors move up behind the debuffs. BuffFrame lays out all 32 buttons once; its
	    shown buttons are always the first ones (UpdateAuraButtons fills them in order).
	  - Position: EditModeSystemMixin:ApplySystemAnchor places each frame from the layout's
	    anchor (default TOPRIGHT of UIParent at -255,-10 and -270,-155). In BuffFrame's default
	    position StatusTrayManager also re-places it below any GM/ticket status frames. Neither
	    frame is a managed-container child.
	  - The frames' SetPoint and ClearAllPoints are Edit Mode Lua overrides
	    (EditModeSystemMixin:OnSystemLoad) that write Edit Mode state. This file never calls
	    them: it uses the plain widget methods (st:SetPointDirect, st:ClearAllPointsDirect).

	How SaftUI owns them now:
	  - Each frame gets a holder (SaftUIBuffs, SaftUIDebuffs), sized to the grid of max icons
	    and placed from the profile. The mover and the /sui section work on the holder.
	  - The Blizzard frame is anchored over its holder (two corners, so Blizzard's SetSize has
	    no effect), and post-hooks on its ClearAllPoints and SetPoint put it back whenever
	    Blizzard places it again (ApplySystemAnchor, StatusTrayManager, snapping).
	  - A post-hook on each frame's UpdateGridLayout re-lays every button out by SaftUI's
	    settings: scale 1, size x size, the Icon filling the button, anchored to the holder
	    by the grid's first corner. Blizzard's order (frame.auraFrames) is kept. Buffs keep
	    a fixed cell per button, as Blizzard's do; debuffs are laid out again on every aura
	    change, with the private aura anchors after the last debuff shown.
	  - A post-hook on each frame's UpdateAuraButtons hides buttons past the max icons
	    setting (Blizzard has just shown them).
	  - BuffFrame's collapse button is placed before the first icon and turned to point
	    along SaftUI's grow direction (a post-hook on its UpdateOrientation).
	  - Nothing here reads aura data or Blizzard's sizes or positions. Everything is computed
	    from the profile, so no secret values are involved.
	  - None of these frames is protected, so the layout runs in combat, as it must: auras
	    change all the time. If something protected gets anchored to one of them (a user's
	    anchor, a Blizzard Edit Mode snap, maybe a private aura drawn into an anchor), that
	    frame waits for the end of combat instead (st:CanMoveNow, st:SafeReposition).

	Blizzard's Edit Mode boxes on both frames are kept hidden, as with the minimap, so
	Blizzard's Edit Mode can't select or drag them. Its settings dialog for them can then not
	be opened:
	  - Orientation, Icon Wrap, Icon Direction, Icon Limit, Icon Size and Icon Padding are
	    replaced by grow, wrap, perrow, size and spacing_x/spacing_y. They no longer have
	    any effect.
	  - Show Dispel Type (debuffs) isn't replaced. It switches the border art between the
	    plain and dispel-icon versions, which the skin hides and colors by dispel type
	    either way. It also decides whether private auras show their dispel icon. Owning it
	    would mean writing AuraContainer.showDispelType, which taints. Its saved value keeps
	    applying.
	  - Reset To Default Position goes too: positions are SaftUI's.
	The account-level "Buffs and Debuffs" checkbox in Blizzard's Edit Mode still works. It
	fills both frames with example icons, laid out here, which previews the layout. The
	buffDurations, collapseExpandBuffs and consolidateBuffs settings are untouched.

	State lives on this module and in closures. Nothing is written onto Blizzard's frames,
	buttons or tables; their methods are only followed with hooksecurefunc and HookScript.
]]

local issecretvalue = issecretvalue or function() return false end

local FRAMES = {
	{ key = 'buffs',   frame = 'BuffFrame',   holder = st.name .. 'Buffs',   label = 'Buffs',   fallbackMax = 32 },
	{ key = 'debuffs', frame = 'DebuffFrame', holder = st.name .. 'Debuffs', label = 'Debuffs', fallbackMax = 16 },
}

-- Global names for the duration and count font objects.
local FONT_NAMES = {
	buffs = { duration = st.name .. 'BuffDurationFont', count = st.name .. 'BuffCountFont' },
	debuffs = { duration = st.name .. 'DebuffDurationFont', count = st.name .. 'DebuffCountFont' },
}

-- The edge of Blizzard's aura icon (BuffFrameTemplates.xml: the button's Icon and the
-- private aura anchor's Icon are 30x30). Private aura anchors and the collapse button are
-- scaled from it, the way Blizzard's Icon Size setting scales them.
local BASE_ICON = 30

local HORIZONTAL = { LEFT = true, RIGHT = true }
local VERTICAL = { UP = true, DOWN = true }
-- The holder side a grow (or wrap) direction starts from, and the sign of its offsets.
local START_SIDE = { LEFT = 'RIGHT', RIGHT = 'LEFT', UP = 'BOTTOM', DOWN = 'TOP' }
local STEP = { LEFT = -1, RIGHT = 1, UP = 1, DOWN = -1 }

-- The collapse button's rotation per grow direction, { expanded, collapsed }. Blizzard's
-- CollapseAndExpandButtonMixin:UpdateOrientation, with SaftUI's grow direction as its
-- expand direction.
local COLLAPSE_ROTATION = {
	LEFT = { math.pi, 0 },
	RIGHT = { 0, math.pi },
	DOWN = { 3 * math.pi / 2, math.pi / 2 },
	UP = { math.pi / 2, 3 * math.pi / 2 },
}

local GROW_VALUES = { LEFT = 'Left', RIGHT = 'Right', UP = 'Up', DOWN = 'Down' }
local WRAP_VALUES = {
	horizontal = { DOWN = 'Down', UP = 'Up' },
	vertical = { LEFT = 'Left', RIGHT = 'Right' },
}

local function IsPerpendicular(grow, wrap)
	if HORIZONTAL[grow] then
		return VERTICAL[wrap] or false
	end
	return HORIZONTAL[wrap] or false
end

-- The wrap to use after grow changes from oldGrow to newGrow. Within an axis the wrap
-- stays. Across axes it keeps the side of the first icon that the new grow doesn't set,
-- e.g. grow left, wrap down (first icon top right) becomes grow down, wrap left.
local function WrapForGrow(oldGrow, oldWrap, newGrow)
	if IsPerpendicular(newGrow, oldWrap) then
		return oldWrap
	end
	local wrap
	if HORIZONTAL[oldGrow] then
		wrap = HORIZONTAL[newGrow] and oldWrap or oldGrow
	else
		wrap = HORIZONTAL[newGrow] and oldGrow or oldWrap
	end
	if IsPerpendicular(newGrow, wrap) then
		return wrap
	end
	return HORIZONTAL[newGrow] and 'DOWN' or 'LEFT'
end

local function Clamp(value, low, high)
	value = math.floor((tonumber(value) or low) + 0.5)
	return math.max(low, math.min(high, value))
end

-- IsShown, treating a secret answer as shown (not expected; aura buttons are shown from a
-- table lookup, but retail can make frame state secret).
local function IsShown(frame)
	local shown = frame:IsShown()
	if issecretvalue(shown) then
		return true
	end
	return shown
end

local function OutlineFlags(outline)
	if not outline or outline == 'NONE' then
		return ''
	end
	return outline
end

-- The grid for one frame, from its profile settings: sizes rounded to whole pixels, the
-- corner the first icon sits in, the direction each step goes, and the holder's size for
-- max icons. Cached until the settings change (AP:Invalidate).
function AP:GetGeometry(key)
	local geo = self.geometry[key]
	if geo then return geo end

	local config, holder, buttons = self.config[key], self.holders[key], self.maxAuras[key]
	local grow = START_SIDE[config.grow] and config.grow or 'LEFT'
	local horizontal = HORIZONTAL[grow] or false
	local wrap = IsPerpendicular(grow, config.wrap) and config.wrap or (horizontal and 'DOWN' or 'LEFT')
	local xdir = horizontal and grow or wrap
	local ydir = horizontal and wrap or grow

	geo = {
		grow = grow,
		wrap = wrap,
		horizontal = horizontal,
		max = Clamp(config.max, 1, buttons),
		perrow = Clamp(config.perrow, 1, buttons),
		size = math.max(1, st:RoundToPixel(config.size, holder)),
		spacingX = st:RoundToPixel(config.spacing_x or 0, holder),
		spacingY = st:RoundToPixel(config.spacing_y or 0, holder),
		xside = START_SIDE[xdir],
		yside = START_SIDE[ydir],
		xstep = STEP[xdir],
		ystep = STEP[ydir],
	}
	geo.corner = geo.yside .. geo.xside

	-- Icons along the grow direction, and rows (or columns) across it.
	local along = math.min(geo.perrow, geo.max)
	local across = math.ceil(geo.max / geo.perrow)
	local cols = horizontal and along or across
	local rows = horizontal and across or along
	geo.width = st:RoundToPixel(cols * geo.size + (cols - 1) * geo.spacingX, holder)
	geo.height = st:RoundToPixel(rows * geo.size + (rows - 1) * geo.spacingY, holder)

	self.geometry[key] = geo
	return geo
end

function AP:Invalidate(key)
	self.geometry[key] = nil
end

-- The offset of a cell (1 = the first icon) from the grid's first corner.
local function CellOffset(geo, cell, holder)
	local along = (cell - 1) % geo.perrow
	local across = math.floor((cell - 1) / geo.perrow)
	local col, row = along, across
	if not geo.horizontal then
		col, row = across, along
	end
	return st:RoundToPixel(geo.xstep * col * (geo.size + geo.spacingX), holder),
		st:RoundToPixel(geo.ystep * row * (geo.size + geo.spacingY), holder)
end

-- Puts an aura button (or the consolidated buffs button) in a cell: unscaled, square,
-- with the icon filling it. Blizzard's layout sets the button's scale and size and
-- re-anchors its Icon every time, so all three are applied each time. False if the
-- button can't be moved now (see the header).
local function PlaceButton(button, geo, holder, cell)
	if not st:CanMoveNow(button) then return false end
	local x, y = CellOffset(geo, cell, holder)
	button:SetScale(1)
	button:SetSize(geo.size, geo.size)
	button:ClearAllPoints()
	button:SetPoint(geo.corner, holder, geo.corner, x, y)
	local icon = button.Icon
	if icon then
		icon:ClearAllPoints()
		icon:SetAllPoints(button)
	end
	return true
end

-- Puts a private aura anchor in a cell. The game draws the private aura at the size the
-- anchor's Icon had when Blizzard registered it (30x30, read once in SetUnit), so the
-- anchor is scaled to the icon size instead of resized, as Blizzard's Icon Size setting
-- does. Its offsets are in its own scale, hence the division. The Duration frame (where
-- the private aura's time is drawn) follows the duration text settings.
function AP:PlaceAuraAnchor(anchor, geo, holder, cell, key)
	local icon, duration = anchor.Icon, anchor.Duration
	if not (st:CanMoveNow(anchor) and (not icon or st:CanMoveNow(icon))
			and (not duration or st:CanMoveNow(duration))) then
		return false
	end
	local scale = geo.size / BASE_ICON
	local x, y = CellOffset(geo, cell, holder)
	anchor:SetScale(scale)
	anchor:SetSize(BASE_ICON, BASE_ICON)
	anchor:ClearAllPoints()
	anchor:SetPoint(geo.corner, holder, geo.corner, x / scale, y / scale)
	if icon then
		icon:ClearAllPoints()
		icon:SetAllPoints(anchor)
		if duration then
			local point, relativePoint, dx, dy = self:GetTextAnchor(key, 'duration')
			duration:ClearAllPoints()
			duration:SetPoint(point, icon, relativePoint, dx / scale, dy / scale)
		end
	end
	return true
end

-- Lays out every button of one frame (see the header). Runs after each of Blizzard's
-- grid layouts, and in combat.
function AP:Layout(key)
	local frame, holder = self.frames[key], self.holders[key]
	local geo = self:GetGeometry(key)
	local placed = true
	local cell = 0

	-- With buff consolidation on, Blizzard puts its button in the first cell.
	if key == 'buffs' then
		local consolidated = frame.ConsolidatedBuffs
		self.consolidatedShown = consolidated and IsShown(consolidated) or false
		if self.consolidatedShown then
			cell = 1
			placed = PlaceButton(consolidated, geo, holder, cell) and placed
		end
	end

	local lastShown = cell
	for _, button in ipairs(frame.auraFrames) do
		if not button.isAuraAnchor then
			cell = cell + 1
			if IsShown(button) then
				lastShown = cell
			end
			placed = PlaceButton(button, geo, holder, cell) and placed
		end
	end

	-- Private aura anchors (debuffs only) follow the last debuff shown, as in Blizzard's
	-- order. They're never hidden, so with max debuffs shown they run past the grid.
	cell = math.min(lastShown, geo.max)
	for _, anchor in ipairs(frame.auraFrames) do
		if anchor.isAuraAnchor then
			cell = cell + 1
			placed = self:PlaceAuraAnchor(anchor, geo, holder, cell, key) and placed
		end
	end

	if not placed then
		st:QueueAfterCombat('auras_layout_' .. key, function() self:LayoutButtons(key) end)
	end
end

-- Hides the buttons past the max icons setting. Blizzard shows each button with an aura
-- in UpdateAuraButtons, so this follows every one of those.
function AP:ApplyMax(key)
	local max = self:GetGeometry(key).max
	local cell = (key == 'buffs' and self.consolidatedShown) and 1 or 0
	for _, button in ipairs(self.frames[key].auraFrames) do
		if not button.isAuraAnchor then
			cell = cell + 1
			if cell > max and st:CanMoveNow(button) then
				button:Hide()
			end
		end
	end
end

-- Places BuffFrame's collapse button just before the first icon, centered on the first
-- row (or column), and turns its arrow to SaftUI's grow direction. Blizzard places,
-- sizes and turns it from its own settings in UpdateAuraContainerAnchor and
-- UpdateOrientation; both are followed by this.
function AP:ApplyCollapse()
	local button = self.collapse
	if not button then return end
	if not st:CanMoveNow(button) then
		st:QueueAfterCombat('auras_collapse', function() self:ApplyCollapse() end)
		return
	end

	local geo, holder = self:GetGeometry('buffs'), self.holders.buffs
	local scale = geo.size / BASE_ICON
	local half = st:RoundToPixel(geo.size / 2, holder)
	local point, x, y
	-- Blizzard's sizes (UpdateOrientation), in the button's own scale: half an icon wide
	-- and one icon tall once scaled.
	if geo.horizontal then
		button:SetSize(15, 30)
		point = geo.xside == 'RIGHT' and 'LEFT' or 'RIGHT'
		x, y = 0, geo.yside == 'TOP' and -half or half
	else
		button:SetSize(30, 15)
		point = geo.yside == 'TOP' and 'BOTTOM' or 'TOP'
		x, y = geo.xside == 'RIGHT' and -half or half, 0
	end
	button:SetScale(scale)
	button:ClearAllPoints()
	button:SetPoint(point, holder, geo.corner, x / scale, y / scale)

	local expanded = button:GetChecked()
	if issecretvalue(expanded) then expanded = true end
	local rotation = COLLAPSE_ROTATION[geo.grow][expanded and 1 or 2]
	local normal, highlight, pushed = button:GetNormalTexture(), button:GetHighlightTexture(), button:GetPushedTexture()
	if normal then normal:SetRotation(rotation) end
	if highlight then highlight:SetRotation(rotation) end
	if pushed then pushed:SetRotation(rotation) end
end

-- Lays out one frame's buttons and applies the max icons (and, for buffs, the collapse
-- button).
function AP:LayoutButtons(key)
	self:Layout(key)
	self:ApplyMax(key)
	if key == 'buffs' then
		self:ApplyCollapse()
	end
end

-- After Blizzard's UpdateAuraButtons. Buffs only need laying out again if the
-- consolidated buffs button came or went (it takes the first cell).
function AP:OnButtonsUpdated(key)
	if key == 'buffs' then
		local consolidated = self.frames.buffs.ConsolidatedBuffs
		if consolidated and IsShown(consolidated) ~= self.consolidatedShown then
			self:LayoutButtons(key)
			return
		end
	end
	self:ApplyMax(key)
end

-- Sizes and places one holder from the profile. Only SaftUI's holder is touched; the
-- frame and its buttons follow through their anchors. In combat a protected holder
-- (something protected anchored to it or its frame) waits for the end of combat.
function AP:ApplyHolder(key)
	local holder = self.holders[key]
	st:SafeReposition(holder, 'auras_' .. key, function()
		local geo = self:GetGeometry(key)
		holder:SetSize(geo.width, geo.height)

		local point, relative, rel_point, x, y = st:UnpackPoint(self.config[key].position)
		holder:ClearAllPoints()
		holder:SetPoint(point, st:ResolveFrame(relative) or UIParent, rel_point, x, y)
	end)
end

-- Applies one frame's settings: holder size and position, then its buttons.
function AP:Refresh(key)
	self:Invalidate(key)
	self:ApplyHolder(key)
	self:LayoutButtons(key)
end

-- Anchors the Blizzard frame over its holder and keeps it there, and hooks the layout.
function AP:TakeOver(key)
	local frame, holder = self.frames[key], self.holders[key]

	local function Reanchor()
		-- A protected frame anchored to the frame (e.g. snapped to it in Blizzard's Edit
		-- Mode) makes it protected, and it can't be re-anchored in combat.
		if InCombatLockdown() and frame:IsProtected()
			and st:QueueAfterCombat('auras_anchor_' .. key, Reanchor) then
			return
		end
		st:ClearAllPointsDirect(frame)
		st:SetPointDirect(frame, 'TOPLEFT', holder, 'TOPLEFT')
		st:SetPointDirect(frame, 'BOTTOMRIGHT', holder, 'BOTTOMRIGHT')
	end
	hooksecurefunc(frame, 'ClearAllPoints', Reanchor)
	hooksecurefunc(frame, 'SetPoint', Reanchor)
	Reanchor()

	-- Blizzard's Edit Mode box no longer controls this frame, so keep it hidden.
	-- HookScript only; nothing is written onto the frame.
	local selection = frame.Selection
	if selection then
		selection:HookScript('OnShow', function(self) self:Hide() end)
		selection:Hide()
	end

	hooksecurefunc(frame, 'UpdateGridLayout', function() self:LayoutButtons(key) end)
	hooksecurefunc(frame, 'UpdateAuraButtons', function() self:OnButtonsUpdated(key) end)

	if key == 'buffs' and frame.CollapseAndExpandButton then
		self.collapse = frame.CollapseAndExpandButton
		hooksecurefunc(self.collapse, 'UpdateOrientation', function() self:ApplyCollapse() end)
	end
end

-- Which frame (buffs or debuffs) an aura button belongs to: BuffFrame's and DebuffFrame's
-- own buttons, which are parented to their AuraContainer. nil for every other aura
-- button (external defensives, the consolidated buffs tooltip, the deadly debuff).
function AP:GetButtonKey(button)
	local parent = button:GetParent()
	if parent == nil then return end
	local buffs, debuffs = _G.BuffFrame, _G.DebuffFrame
	if buffs and parent == buffs.AuraContainer then
		return 'buffs'
	elseif debuffs and parent == debuffs.AuraContainer then
		return 'debuffs'
	end
end

local fonts = {} -- 'buffs' / 'debuffs' -> { duration = Font, count = Font }

-- Applies one text's font settings to its font object. Every font string set to the
-- object follows.
function AP:UpdateFont(key, kind)
	local font = fonts[key] and fonts[key][kind]
	if not font then return end
	local config = st.config.profile.auras[key][kind]
	font:SetFont(st.LSM:Fetch('font', config.font), config.size, OutlineFlags(config.outline))
end

function AP:UpdateFonts()
	for _, info in ipairs(FRAMES) do
		self:UpdateFont(info.key, 'duration')
		self:UpdateFont(info.key, 'count')
	end
end

-- The font object for one frame's duration or count text, made the first time.
function AP:GetFont(key, kind)
	fonts[key] = fonts[key] or {}
	local font = fonts[key][kind]
	if not font then
		font = CreateFont(FONT_NAMES[key][kind])
		font:SetTextColor(1, 1, 1)
		font:SetShadowOffset(0, 0)
		fonts[key][kind] = font
		self:UpdateFont(key, kind)
	end
	return font
end

-- One frame's duration or count anchor: the text's point, the icon's point, and the
-- offsets in whole pixels. Read from the profile directly, since the skin asks before
-- this module is enabled.
function AP:GetTextAnchor(key, kind)
	local config = st.config.profile.auras[key][kind]
	return config.point, config.rel_point, st:RoundToPixel(config.x_off or 0), st:RoundToPixel(config.y_off or 0)
end

-- For the aura skin (Blizzard_BuffFrame.lua), which owns the text hooks: the font object
-- and anchor (relative to the icon) for a button's 'duration' or 'count' text, or nil if
-- the button isn't one of BuffFrame's or DebuffFrame's own.
function AP:GetTextStyle(button, kind)
	local key = self:GetButtonKey(button)
	if not key then return end
	return self:GetFont(key, kind), self:GetTextAnchor(key, kind)
end

-- Re-applies the duration and count text: the skin restyles its buttons, and the private
-- aura anchors' duration follows.
function AP:UpdateText()
	local skinning = st:GetModule('Skinning', true)
	local skin = skinning and skinning:GetModule('Blizzard_BuffFrame', true)
	if skin and skin.UpdateText then
		skin:UpdateText()
	end
	if self.holders then
		self:Layout('debuffs')
	end
end

-- Re-applies everything, e.g. after a profile change. Both holders are cleared first: the
-- new profile may chain them the other way round, and anchoring one to the other while
-- that one still points back would be a loop. A holder that can't move now
-- (st:CanMoveNow) keeps its anchors, and ApplyHolder leaves it for after combat.
function AP:UpdateConfig()
	self:UpdateFonts()
	if not self.holders then return end
	for _, info in ipairs(FRAMES) do
		local holder = self.holders[info.key]
		if st:CanMoveNow(holder) then
			holder:ClearAllPoints()
		end
	end
	for _, info in ipairs(FRAMES) do
		self:Refresh(info.key)
	end
	self:UpdateText()
end

function AP:RegisterAuraMover(info)
	local key = info.key
	st:RegisterMover('auras_' .. key, {
		frame = self.holders[key],
		label = info.label,
		getPosition = function() return self.config[key].position end,
		setPosition = function(pos) self.config[key].position = pos end,
		apply = function() self:ApplyHolder(key) end,
		configPath = { 'Auras', key, 'general' },
	})
end

function AP:Setup()
	if self.holders then return end

	local frames = {}
	for _, info in ipairs(FRAMES) do
		local frame = _G[info.frame]
		if not (frame and frame.auraFrames and frame.AuraContainer) then return end
		frames[info.key] = frame
	end

	-- The buttons Blizzard made (maxAuras), the most that can be shown.
	self.frames, self.geometry, self.maxAuras = frames, {}, {}
	for _, info in ipairs(FRAMES) do
		local count = 0
		for _, button in ipairs(frames[info.key].auraFrames) do
			if not button.isAuraAnchor then
				count = count + 1
			end
		end
		self.maxAuras[info.key] = count > 0 and count or info.fallbackMax
	end

	-- Both holders exist before either is placed, since a profile may chain them by name.
	self.holders = {}
	for _, info in ipairs(FRAMES) do
		self.holders[info.key] = CreateFrame('Frame', info.holder, UIParent)
	end
	for _, info in ipairs(FRAMES) do
		self:ApplyHolder(info.key)
	end

	for _, info in ipairs(FRAMES) do
		self:TakeOver(info.key)
		self:RegisterAuraMover(info)
		self:LayoutButtons(info.key)
	end
	self:UpdateText()
end

function AP:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_BuffFrame' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

function AP:OnEnable()
	st:BindModuleConfig(self, 'auras')
	if _G.BuffFrame and BuffFrame.auraFrames then
		self:Setup()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end

-- One text's options (duration or count), inline in the Text section.
function AP:GetTextOptions(key, kind, name, order)
	local generators = st.Config.generators
	local fontsModule = st:GetModule('Fonts', true)
	return {
		name = name,
		type = 'group',
		inline = true,
		order = order,
		get = function(i) return self.config[key][kind][i[#i]] end,
		set = function(i, value)
			self.config[key][kind][i[#i]] = value
			self:UpdateFont(key, kind)
			self:UpdateText()
		end,
		args = {
			font = {
				order = 1,
				name = 'Font',
				type = 'select',
				dialogControl = 'LSM30_Font',
				values = st.LSM:HashTable('font'),
				width = 0.75,
			},
			size = generators.range(2, 'Size', 6, 40, 1, 0.75),
			outline = {
				order = 3,
				name = 'Outline',
				type = 'select',
				values = fontsModule and fontsModule.outlines or { NONE = 'None', OUTLINE = 'Outline' },
				width = 0.75,
			},
			point = {
				order = 4,
				name = 'Text point',
				desc = 'The point of the text that is anchored.',
				type = 'select',
				values = st.FRAME_ANCHORS,
				width = 0.75,
			},
			rel_point = {
				order = 5,
				name = 'Icon point',
				desc = 'The point of the icon the text is anchored to.',
				type = 'select',
				values = st.FRAME_ANCHORS,
				width = 0.75,
			},
			x_off = generators.range(6, 'X offset', -50, 50, 1, 0.75),
			y_off = generators.range(7, 'Y offset', -50, 50, 1, 0.75),
		},
	}
end

function AP:GetFrameOptions(info, order)
	local generators = st.Config.generators
	local key = info.key
	local buttons = self.maxAuras[key]

	-- Every SetPoint parameter is editable, the relative frame included. Passing the
	-- holder makes a typed frame go through st:ValidateAnchor, which rejects anchoring it
	-- to itself, to its own Blizzard frame, or to anything anchored back to it.
	local position = generators.position(3, true,
		function(k) return self.config[key].position[k] end,
		function(k, value)
			self.config[key].position[k] = value
			self:ApplyHolder(key)
		end,
		self.holders[key]
	)
	position.inline = false -- a tree section, not an inline box

	local perrow = generators.range(6, 'Icons per row', 1, buttons, 1)
	perrow.name = function()
		return self:GetGeometry(key).horizontal and 'Icons per row' or 'Icons per column'
	end
	perrow.desc = "How many icons before wrapping, like Blizzard's Icon Limit."

	local max = generators.range(7, 'Max icons shown', 1, buttons, 1)
	max.desc = ('Up to the %d buttons Blizzard makes. Auras past this are not shown.'):format(buttons)

	return {
		name = info.label,
		type = 'group',
		order = order,
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(i)
					local option = i[#i]
					if option == 'wrap' or option == 'grow' then
						return self:GetGeometry(key)[option] -- the values in use
					end
					return self.config[key][option]
				end,
				set = function(i, value)
					local config, option = self.config[key], i[#i]
					if option == 'grow' then
						local geo = self:GetGeometry(key)
						config.wrap = WrapForGrow(geo.grow, geo.wrap, value)
					end
					config[option] = value
					self:Refresh(key)
				end,
				args = {
					size = generators.range(1, 'Icon size', 10, 80, 1),
					spacing_x = generators.range(2, 'Horizontal spacing', 0, 50, 1),
					spacing_y = generators.range(3, 'Vertical spacing', 0, 50, 1),
					grow = {
						order = 4,
						name = 'Grow direction',
						desc = 'The direction icons are added in.',
						type = 'select',
						values = GROW_VALUES,
						width = 0.75,
					},
					wrap = {
						order = 5,
						name = 'Wrap direction',
						desc = 'The direction new rows (or columns) go.',
						type = 'select',
						values = function()
							return self:GetGeometry(key).horizontal and WRAP_VALUES.horizontal or WRAP_VALUES.vertical
						end,
						width = 0.75,
					},
					perrow = perrow,
					max = max,
				},
			},
			text = {
				name = 'Text',
				type = 'group',
				order = 2,
				args = {
					duration = self:GetTextOptions(key, 'duration', 'Duration', 1),
					count = self:GetTextOptions(key, 'count', 'Stack count', 2),
				},
			},
			position = position,
		},
	}
end

-- The Auras section in the /sui tree: Buffs and Debuffs, each with General, Text and
-- Position. Clicking a frame in edit mode selects its General group (the mover's
-- configPath). Absent until Blizzard's frames exist.
function AP:GetConfigTable()
	if not self.holders then return end
	local args = {}
	for i, info in ipairs(FRAMES) do
		args[info.key] = self:GetFrameOptions(info, i)
	end
	return {
		name = 'Auras',
		type = 'group',
		args = args,
	}
end
