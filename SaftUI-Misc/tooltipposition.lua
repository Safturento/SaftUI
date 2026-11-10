local st = SaftUI
local TT = st:GetModule('Tooltip')

--[[
	Where the default tooltip shows: the one Blizzard places with
	GameTooltip_SetDefaultAnchor (units in the world, most of the UI), not
	tooltips anchored to the mouse or to their owner.

	How Blizzard places it (SharedTooltipTemplates.lua, the same on Forever and
	retail): GameTooltip_SetDefaultAnchor reads GameTooltipDefaultContainer's
	first point and anchors that corner of the tooltip to the same corner of the
	container. The container is Blizzard's Edit Mode "HUD Tooltip" system, placed
	from the Edit Mode layout.

	SaftUI never moves the tooltip. It moves the container, the same way as the
	swing timer (Skinning/Blizzard_SwingTimerPosition.lua):
	  - A SaftUI holder, sized like the container and placed from the profile, is
	    the edit mode mover and the /sui Position.
	  - The container is anchored by one corner: to the holder's matching corner
	    normally, or to the left of the bag window or the loot feed while they show
	    (attach_to_bags, attach_to_feed). That corner is the one the tooltip grows
	    from.
	  - Post-hooks on the container's ClearAllPoints and SetPoint put it back
	    whenever Blizzard's Edit Mode lays it out. Those two are Lua overrides
	    (EditModeSystemMixin) that write Edit Mode state, so SaftUI only calls the
	    plain widget methods (st:ClearAllPointsDirect, st:SetPointDirect).
	  - The container's Edit Mode box is kept hidden, so Blizzard's Edit Mode can't
	    move it.
	Nothing is written onto the container or the tooltip. None of these frames is
	protected, so all of it is safe in combat.
]]

local HOLDER_WIDTH, HOLDER_HEIGHT = 250, 150 -- GameTooltipDefaultContainer's size
local SNAP_GAP = 10 -- between the tooltip and the bag window or loot feed

-- The corner of the holder the tooltip grows from: the holder's anchor point if
-- that's a corner, otherwise the corner facing the screen edges it's nearest.
local function GrowthCorner(holder, point)
	if point == 'TOPLEFT' or point == 'TOPRIGHT' or point == 'BOTTOMLEFT' or point == 'BOTTOMRIGHT' then
		return point
	end
	local x, y = holder:GetCenter()
	local cx, cy = UIParent:GetCenter()
	if not (x and cx) then return 'BOTTOMRIGHT' end
	return (y > cy and 'TOP' or 'BOTTOM') .. (x > cx and 'RIGHT' or 'LEFT')
end

-- The bag window or loot feed the tooltip snaps to now, if any.
local function SnapTarget(config)
	if config.attach_to_bags then
		local INV = st:GetModule('Inventory', true)
		local bag = INV and INV.containers and INV.containers.bag
		if bag and bag:IsShown() then return bag end
	end
	if config.attach_to_feed then
		local LT = st:GetModule('Loot', true)
		local feed = LT and LT.feed
		if feed and feed:IsVisible() then
			for _, item in ipairs(feed.items) do
				if item:IsShown() then return feed end
			end
		end
	end
end

-- Puts the container where the tooltip should show now. Runs on every change
-- that can move it: the holder, the snap settings, the bag window or a feed line
-- showing or hiding, and Blizzard laying the container out.
function TT:UpdateTooltipAnchor()
	local container, holder = self.tooltipContainer, self.tooltipHolder
	if not (container and holder) then return end

	st:ClearAllPointsDirect(container)
	local target = SnapTarget(self.config)
	local ok
	if target then
		ok = pcall(st.SetPointDirect, st, container, 'BOTTOMRIGHT', target, 'BOTTOMLEFT', -SNAP_GAP, 0)
	else
		local corner = GrowthCorner(holder, self.config.position.point)
		ok = pcall(st.SetPointDirect, st, container, corner, holder, corner, 0, 0)
	end
	-- Blizzard's code errors on every default tooltip if the container has no
	-- point, e.g. after an anchor loop through a frame typed into Position.
	if not ok then
		st:ClearAllPointsDirect(container)
		st:SetPointDirect(container, 'BOTTOMRIGHT', UIParent, 'BOTTOMRIGHT', -20, 20)
	end
end

-- Sizes and places the holder from the profile, then the container with it.
function TT:ApplyTooltipHolder()
	local holder = self.tooltipHolder
	if not holder then return end
	st:SafeReposition(holder, 'tooltip_holder', function()
		holder:SetSize(st:RoundToPixel(HOLDER_WIDTH, holder), st:RoundToPixel(HOLDER_HEIGHT, holder))
		local point, relative, rel_point, x, y = st:UnpackPoint(self.config.position)
		holder:ClearAllPoints()
		holder:SetPoint(point, st:ResolveFrame(relative) or UIParent, rel_point,
			st:RoundToPixel(x, holder), st:RoundToPixel(y, holder))
	end)
	self:UpdateTooltipAnchor()
end

-- Re-anchors the container when one of these SaftUI frames shows or hides.
-- HookScript only, and once per frame.
function TT:WatchSnapFrame(frame)
	self.snapWatched = self.snapWatched or {}
	if not frame or self.snapWatched[frame] then return end
	self.snapWatched[frame] = true
	local update = function() self:UpdateTooltipAnchor() end
	frame:HookScript('OnShow', update)
	frame:HookScript('OnHide', update)
end

function TT:WatchSnapFrames()
	local INV = st:GetModule('Inventory', true)
	self:WatchSnapFrame(INV and INV.containers and INV.containers.bag)

	local LT = st:GetModule('Loot', true)
	local feed = LT and LT.feed
	if feed then
		self:WatchSnapFrame(feed)
		for _, item in ipairs(feed.items) do
			self:WatchSnapFrame(item)
		end
		-- Raising the feed's max lines makes more lines (LT:UpdateLootFeedConfig).
		if not self.feedConfigHooked then
			self.feedConfigHooked = true
			hooksecurefunc(LT, 'UpdateLootFeedConfig', function() self:WatchSnapFrames() end)
		end
	end
end

function TT:SetupTooltipPosition()
	local container = _G.GameTooltipDefaultContainer
	if self.tooltipHolder or not container then return end

	self.tooltipContainer = container
	self.tooltipHolder = CreateFrame('Frame', st.name .. 'TooltipHolder', UIParent)
	-- Blizzard clamps the container; clamp the outline too, so it shows where the
	-- tooltip really goes.
	self.tooltipHolder:SetClampedToScreen(true)
	self:ApplyTooltipHolder()

	-- Blizzard's Edit Mode places the container through these on every layout load
	-- or change; put it back straight after.
	local update = function() self:UpdateTooltipAnchor() end
	hooksecurefunc(container, 'ClearAllPoints', update)
	hooksecurefunc(container, 'SetPoint', update)

	local selection = container.Selection
	if selection then
		selection:HookScript('OnShow', function(box) box:Hide() end)
		selection:Hide()
	end

	-- The bag window and loot feed are built in their own addons' OnEnable, which
	-- runs before this one (SaftUI-Bags and SaftUI-Loot load before SaftUI-Misc).
	-- PLAYER_ENTERING_WORLD catches them if that ever changes.
	self:WatchSnapFrames()
	self:RegisterEvent('PLAYER_ENTERING_WORLD', function()
		self:WatchSnapFrames()
		self:UpdateTooltipAnchor()
	end)

	st:RegisterMover('tooltip', {
		frame = self.tooltipHolder,
		label = 'Tooltip',
		getPosition = function() return self.config.position end,
		setPosition = function(pos) self.config.position = pos end,
		apply = function() self:ApplyTooltipHolder() end,
		configPath = { 'Tooltip', 'general' },
	})
end

-- The Tooltip section in /sui: General (the snap settings, then the Position
-- option).
function TT:GetConfigTable()
	if not self.tooltipHolder then return end
	local generators = st.Config.generators

	local function Toggle(order, name, desc, available)
		local option = generators.toggle(order, name, desc)
		option.hidden = function() return not available() end
		return option
	end
	local function HasBags()
		local INV = st:GetModule('Inventory', true)
		return INV and INV.containers and INV.containers.bag ~= nil
	end
	local function HasFeed()
		local LT = st:GetModule('Loot', true)
		return LT and LT.feed ~= nil
	end

	-- The tooltip anchors to its container, and the container to this holder:
	-- either as the holder's frame would be a loop.
	local position = generators.position(1000, true,
		function(key) return self.config.position[key] end,
		function(key, value)
			self.config.position[key] = value
			self:ApplyTooltipHolder()
		end,
		function() return self.tooltipHolder end
	)
	local validate = position.validate
	position.validate = function(info, part, value)
		if part == 'frame' and (value == 'GameTooltip' or value == 'GameTooltipDefaultContainer') then
			return "The tooltip's position can't be anchored to the tooltip itself."
		end
		return validate(info, part, value)
	end

	return {
		name = 'Tooltip',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionswindow.lua)
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					self.config[info[#info]] = value
					self:UpdateTooltipAnchor()
				end,
				args = {
					attach_to_bags = Toggle(1, 'Next to the bag window',
						'While the bag window is open, the tooltip shows to its left.', HasBags),
					attach_to_feed = Toggle(2, 'Next to the loot feed',
						'While the loot feed shows entries, the tooltip shows to its left. The bag window comes first.', HasFeed),
					position = position,
				},
			},
		},
	}
end
