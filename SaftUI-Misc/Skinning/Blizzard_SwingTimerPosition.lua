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

	With that box hidden, Blizzard's per-bar Show Bar Title, Show Time and Opacity
	settings can't be reached, so /sui owns them (showtitle, showtime, opacity):
	  - Title and time: Blizzard shows/hides TypeLabel, TypeLabelShadow and TimeLabel only
	    through region:SetShown (EditModeSwingTimerSystemMixin:UpdateSystemSettingShowBarTitle
	    and ...ShowTime), so a post-hook on each region's SetShown re-applies the SaftUI
	    value. The shadow stays hidden, as the skin wants.
	  - Opacity: Blizzard sets the bar's own alpha in one place (UpdateSystemSettingOpacity,
	    a SetAlpha on the bar). A post-hook on the bar's SetAlpha puts the SaftUI value
	    back. Range dimming sets the alpha of the bar's Background, Border and StatusBar
	    children (ApplyRangePresentation), never the bar's, so the two multiply and the
	    out-of-range dim stays visible at any opacity.
	  - Visibility (Always / In Combat / Hidden) isn't replaced. ShouldBeShown and the
	    swing event registration read the Lua field bar.visibility, and the show/hide goes
	    through the Edit Mode SetShown/Hide overrides. Owning it would mean writing that
	    field or those methods, which taints. A saved "Hidden" is only detected (a read of
	    bar.visibility) and noted on the bar's edit mode outline.
	  - Scale isn't replaced: width and height cover size. Blizzard's Scale setting now
	    only scales the bar's text, pip and border.
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
local ClearAllPoints, SetPoint, SetAlpha

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
local function TakeOver(bar, holder, key, getConfig)
	local function Reanchor()
		-- A protected frame anchored to the bar makes the bar protected, and it can't
		-- be re-anchored in combat. Wait for the end of combat then.
		if InCombatLockdown() and bar:IsProtected()
			and st:QueueAfterCombat('swingtimer_anchor_' .. key, Reanchor) then
			return
		end
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

	-- Title and time text. Blizzard only ever calls SetShown on these regions, so each
	-- gets a post-hook that puts the SaftUI choice back. Show and Hide are not hooked,
	-- so applying it here doesn't loop. The shadow stays hidden (the skin hides it).
	local statusBar = bar.StatusBar
	local typeLabel, shadow, timeLabel = statusBar.TypeLabel, statusBar.TypeLabelShadow, statusBar.TimeLabel
	local function ApplyTitle()
		if typeLabel then
			if getConfig().showtitle ~= false then typeLabel:Show() else typeLabel:Hide() end
		end
		if shadow then shadow:Hide() end
	end
	local function ApplyTime()
		if timeLabel then
			if getConfig().showtime ~= false then timeLabel:Show() else timeLabel:Hide() end
		end
	end
	if typeLabel then hooksecurefunc(typeLabel, 'SetShown', ApplyTitle) end
	if shadow then hooksecurefunc(shadow, 'SetShown', ApplyTitle) end
	if timeLabel then hooksecurefunc(timeLabel, 'SetShown', ApplyTime) end

	-- Opacity. Blizzard's Edit Mode Opacity setting is a SetAlpha on the bar; put the
	-- SaftUI value back. The widget method is called directly so the hook can't recurse.
	hooksecurefunc(bar, 'SetAlpha', function()
		SetAlpha(bar, getConfig().opacity or 1)
	end)

	return ApplyTitle, ApplyTime
end

-- Applies a bar's title, time and opacity settings.
function STP:ApplyAppearance(key)
	local appearance = self.appearance and self.appearance[key]
	if not appearance then return end
	appearance.title()
	appearance.time()
	SetAlpha(appearance.bar, self.config[key].opacity or 1)
end

-- Notes on a bar's edit mode outline when Blizzard's saved Visibility is Hidden, since
-- the outline would otherwise sit around a bar that never shows. Only reads the
-- bar's visibility field; the outline's label is SaftUI's.
function STP:UpdateMoverLabel(key)
	local info, mover, bar = self.infos[key], self.movers[key], self.bars[key]
	if not (mover and mover.label) then return end
	local visibilities = Enum and Enum.EditModeSwingTimerVisibility
	local hidden = visibilities and bar.visibility == visibilities.Hidden
	mover.label:SetText(info.label .. ' Swing' .. (hidden and ' (hidden by Blizzard setting)' or ''))
end

-- Sizes and places one holder from the profile. Only SaftUI's holder is touched (the
-- bar follows through its anchors). The bar is anchored to the holder, so a protected
-- frame (e.g. a unit frame) anchored to either makes the holder protected; in combat
-- the holder then waits for the end of combat.
function STP:ApplyHolder(key)
	local holder = self.holders[key]
	st:SafeReposition(holder, 'swingtimer_' .. key, function()
		local config = self.config[key]
		holder:SetSize(st:RoundToPixel(config.width, holder), st:RoundToPixel(config.height, holder))

		local point, relative, rel_point, x, y = st:UnpackPoint(config.position)
		holder:ClearAllPoints()
		holder:SetPoint(point, st:ResolveFrame(relative) or UIParent, rel_point, x, y)
	end)
end

-- Re-applies every bar's size and position, e.g. after a profile change. All holders
-- are cleared first: the new profile may chain them in another order, and anchoring
-- one to another that still points back at it would be a loop. A holder that can't
-- move now (st:CanMoveNow) keeps its anchors, and ApplyHolder leaves it for after combat.
function STP:UpdateConfig()
	if not self.holders then return end
	for _, info in ipairs(BARS) do
		local holder = self.holders[info.key]
		if st:CanMoveNow(holder) then
			holder:ClearAllPoints()
		end
	end
	for _, info in ipairs(BARS) do
		self:ApplyHolder(info.key)
		self:ApplyAppearance(info.key)
	end
end

function STP:RegisterBarMover(info)
	local key = info.key
	self.movers[key] = st:RegisterMover('swingtimer_' .. key, {
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
	ClearAllPoints, SetPoint, SetAlpha = methods.ClearAllPoints, methods.SetPoint, methods.SetAlpha

	-- Every holder exists before any is placed, since the defaults chain them by name.
	self.holders = {}
	for _, info in ipairs(BARS) do
		self.holders[info.key] = CreateFrame('Frame', info.holder, UIParent)
	end
	self:UpdateConfig()

	self.bars, self.movers, self.infos, self.appearance = bars, {}, {}, {}
	for _, info in ipairs(BARS) do
		local key, bar = info.key, bars[info.key]
		self.infos[key] = info
		local title, time = TakeOver(bar, self.holders[key], key, function() return self.config[key] end)
		self.appearance[key] = { bar = bar, title = title, time = time }
		self:RegisterBarMover(info)
		self:ApplyAppearance(key)
		self:UpdateMoverLabel(key)

		-- A layout load or change re-runs Blizzard's Visibility handler.
		if bar.UpdateSystemSettingVisibility then
			hooksecurefunc(bar, 'UpdateSystemSettingVisibility', function() self:UpdateMoverLabel(key) end)
		end
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
					self:ApplyAppearance(key)
				end,
				args = {
					width = generators.range(1, 'Width', 50, 1000, 1),
					height = generators.range(2, 'Height', 4, 80, 1),
					showtitle = generators.toggle(3, 'Show bar title', 1),
					showtime = generators.toggle(4, 'Show time', 1),
					opacity = generators.range(5, 'Opacity', 0, 1, 0.05),
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
