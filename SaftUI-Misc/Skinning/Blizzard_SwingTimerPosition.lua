local st = SaftUI
local STP = st:NewModule('SwingTimer')

--[[
	Makes WoW Forever's three swing timer bars (Blizzard_SwingTimer) SaftUI movers, sized
	and placed only from the SaftUI profile. Retail has no swing timer, so nothing here
	runs and the /sui section doesn't appear. The bars' look is Blizzard_SwingTimer.lua.

	How Blizzard places them (all driven by Blizzard's Edit Mode):
	  - In the default position each bar is a managed frame. BottomManagedFrameContainer
	    reparents it to itself and stacks it (ManagedFrameContainerMixin:UpdateFrame, then
	    Layout) whenever the bar shows or the container updates.
	  - Once moved in Blizzard's Edit Mode, ApplySystemAnchor reparents it to UIParent and
	    anchors it from the saved layout.
	  - Edit Mode's Width and Height settings call SetWidth/SetHeight, and Scale calls
	    SetScale. All of this is re-applied on every layout load or change.

	The bars' SetPoint, ClearAllPoints and SetScale are Lua overrides
	(EditModeSystemMixin:OnSystemLoad) that write Edit Mode state, such as
	EditModeManagerFrame.editModeSystemAnchorDirty. Calling them from addon code would
	taint that state, so this file never does. It calls the plain widget methods
	instead (see Setup), which run no Blizzard Lua.

	Each bar gets a SaftUI holder frame, sized and positioned from the profile. The mover
	and the /sui section work on the holder. The bar is anchored around its holder so the
	bar's StatusBar covers the holder exactly, and post-hooks on the bar's ClearAllPoints
	and SetPoint put it back whenever Blizzard lays it out again. With two opposite
	corners anchored, Blizzard's SetWidth/SetHeight no longer change the bar's size, and
	its Scale setting only scales the bar's insides (text, pip, backdrop edge).

	The bar keeps whatever parent Blizzard gives it. Reparenting it would take it out of
	the managed stack, but every show would then bounce it between Blizzard's container
	and the holder, and a hidden container would turn that into an endless hide/show
	loop. So while a bar is shown, Blizzard's stack still keeps its space, as it does by
	default.

	Blizzard's Edit Mode box on each bar is kept hidden, as with the minimap cluster, so
	Blizzard's Edit Mode can't select or drag them. State lives on this module and in
	closures; nothing is written onto the bars or any Blizzard table.
]]

local BARS = {
	{ key = 'mainhand', frame = 'SwingTimerMainHandFrame', holder = st.name .. 'SwingTimerMainHand', label = 'Main Hand' },
	{ key = 'offhand',  frame = 'SwingTimerOffHandFrame',  holder = st.name .. 'SwingTimerOffHand',  label = 'Off Hand' },
	{ key = 'ranged',   frame = 'SwingTimerRangedFrame',   holder = st.name .. 'SwingTimerRanged',   label = 'Ranged' },
}

-- How far each bar's StatusBar sits inside the bar (Blizzard_SwingTimer.xml: TOPLEFT
-- 5,-4 and BOTTOMRIGHT -5,4). The bar is anchored this far outside its holder so the
-- StatusBar lands on the holder. Both offsets are in the bar's own scale, so they
-- cancel at any Edit Mode Scale.
local INSET_X, INSET_Y = 5, 4

-- The widget API's own methods, called directly so the bars' Lua overrides are skipped.
-- Looked up in Setup, so nothing runs on clients without the bars.
local ClearAllPoints, SetPoint

local function AnchorBar(bar, holder)
	ClearAllPoints(bar)
	SetPoint(bar, 'TOPLEFT', holder, 'TOPLEFT', -INSET_X, INSET_Y)
	SetPoint(bar, 'BOTTOMRIGHT', holder, 'BOTTOMRIGHT', INSET_X, -INSET_Y)
end

-- Anchors the bar to its holder and keeps it there. Every Blizzard path that places a
-- bar (managed-stack layout, ApplySystemAnchor, the Scale setting's SetScale override)
-- goes through its ClearAllPoints or SetPoint, so these post-hooks undo each one
-- straight after. They only touch the bar (not protected), so they're safe when
-- Blizzard lays a bar out in combat.
local function TakeOver(bar, holder)
	local function Reanchor()
		AnchorBar(bar, holder)
	end

	hooksecurefunc(bar, 'ClearAllPoints', Reanchor)
	hooksecurefunc(bar, 'SetPoint', Reanchor)

	-- Blizzard's Edit Mode box no longer controls this bar, so keep it hidden.
	-- HookScript only; nothing is written onto the frame.
	local selection = bar.Selection
	if selection then
		selection:HookScript('OnShow', function(self) self:Hide() end)
		selection:Hide()
	end

	Reanchor()
end

-- Sizes and places one holder from the profile. Only SaftUI's holder is touched (the
-- bar follows through its anchors), so this is safe in combat.
function STP:ApplyHolder(key)
	local holder = self.holders[key]
	local config = self.config[key]
	holder:SetSize(st:RoundToPixel(config.width, holder), st:RoundToPixel(config.height, holder))

	local point, relative, rel_point, x, y = st:UnpackPoint(config.position)
	holder:ClearAllPoints()
	holder:SetPoint(point, st:ResolveFrame(relative) or UIParent, rel_point, x, y)
end

-- Re-applies every bar's size and position, e.g. after a profile change. All holders
-- are cleared first: the new profile may chain them in another order, and anchoring
-- one to another that still points back at it would be a loop.
function STP:UpdateConfig()
	if not self.holders then return end
	for _, info in ipairs(BARS) do
		self.holders[info.key]:ClearAllPoints()
	end
	for _, info in ipairs(BARS) do
		self:ApplyHolder(info.key)
	end
end

function STP:RegisterBarMover(info)
	local key = info.key
	st:RegisterMover('swingtimer_' .. key, {
		frame = self.holders[key],
		label = info.label .. ' Swing',
		getPosition = function() return self.config[key].position end,
		setPosition = function(pos) self.config[key].position = pos end,
		apply = function() self:ApplyHolder(key) end,
		configPath = { 'SwingTimer', key, 'general' },
	})
end

function STP:Setup()
	if self.holders then return end

	local bars = {}
	for _, info in ipairs(BARS) do
		bars[info.key] = _G[info.frame]
		if not bars[info.key] then return end
	end

	-- The shared Frame method table (the bars are plain Frames, like UIParent).
	local methods = getmetatable(UIParent).__index
	ClearAllPoints, SetPoint = methods.ClearAllPoints, methods.SetPoint

	-- Every holder exists before any is placed, since the defaults chain them by name.
	self.holders = {}
	for _, info in ipairs(BARS) do
		self.holders[info.key] = CreateFrame('Frame', info.holder, UIParent)
	end
	self:UpdateConfig()

	for _, info in ipairs(BARS) do
		TakeOver(bars[info.key], self.holders[info.key])
		self:RegisterBarMover(info)
	end
end

function STP:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_SwingTimer' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:Setup()
end

function STP:OnEnable()
	st:BindModuleConfig(self, 'swingtimer')
	if _G.SwingTimerMainHandFrame then
		self:Setup()
	elseif st.forever then
		self:RegisterEvent('ADDON_LOADED')
	end
end

function STP:GetBarOptions(info, order)
	local generators = st.Config.generators
	local key = info.key
	local apply = function() self:ApplyHolder(key) end

	-- Every SetPoint parameter is editable, the relative frame included. Passing the
	-- holder makes a typed frame go through st:ValidateAnchor, which rejects anchoring
	-- it to itself, to its own bar, or to anything anchored back to it (e.g. the bars
	-- chained below it).
	local position = generators.position(2, true,
		function(k) return self.config[key].position[k] end,
		function(k, value)
			self.config[key].position[k] = value
			apply()
		end,
		self.holders[key]
	)
	position.inline = false -- a tree section, not an inline box

	return {
		name = info.label,
		type = 'group',
		order = order,
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(i) return self.config[key][i[#i]] end,
				set = function(i, value)
					self.config[key][i[#i]] = value
					apply()
				end,
				args = {
					width = generators.range(1, 'Width', 50, 1000, 1),
					height = generators.range(2, 'Height', 4, 80, 1),
				},
			},
			position = position,
		},
	}
end

-- The Swing Timer section in the /sui tree: Main Hand, Off Hand and Ranged, each with
-- General and Position. Clicking a bar in edit mode selects its General group (the
-- mover's configPath). Absent until the bars exist, so never shown on retail.
function STP:GetConfigTable()
	if not self.holders then return end
	local args = {}
	for i, info in ipairs(BARS) do
		args[info.key] = self:GetBarOptions(info, i)
	end
	return {
		name = 'Swing Timer',
		type = 'group',
		args = args,
	}
end
