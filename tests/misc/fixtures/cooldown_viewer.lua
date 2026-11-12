--[[
	Blizzard's Cooldown Manager (Blizzard_CooldownViewer: CooldownViewer.xml and
	CooldownViewer.lua, the same on Forever 1.60.1.70888 and retail 12.1.5.70783
	in everything built here), as far as SaftUI's skin
	(SaftUI-Misc/Skinning/Blizzard_CooldownViewer.lua) reads it. Load it with
	`local CV = load_test_file('misc/fixtures/cooldown_viewer.lua')`, then
	CV.build() makes the viewers, as the game does when the addon loads:

	  - The four viewers, EssentialCooldownViewer, UtilityCooldownViewer,
	    BuffIconCooldownViewer and BuffBarCooldownViewer (CV.Essential,
	    CV.Utility, CV.BuffIcon, CV.BuffBar), UIParent's children.
	  - Each viewer's item pool, itemFramePool. CooldownViewerMixin:OnLoad makes
	    it with CreateFramePool, a secure pool (Blizzard_SharedXMLBase/Pools.lua);
	    here a plain one with the calls Pools.lua's has: Acquire (the last item
	    released, else a new one, which the reset callback gets first, as
	    ObjectPoolBaseMixin:Acquire does), Release, ReleaseAll, EnumerateActive
	    (pairs over the active items) and GetNumActive. Its reset callback is
	    Blizzard's itemResetCallback: hidden, anchors cleared
	    (Pool_HideAndClearAnchors), layoutIndex cleared. Its cooldown data
	    (ResetCooldownData) isn't built.
	  - RefreshLayout(count): every item released, then count acquired, each
	    given its layoutIndex and handed to the viewer's own OnAcquireItemFrame,
	    as CooldownViewerMixin:RefreshLayout does (the real one acquires one per
	    cooldown the player tracks, two at least), then laid out: icons in a
	    row, bars in a column, iconPadding - 4 apart (GetAdditionalPaddingOffset;
	    the bars' is - 2), in place of the GridLayoutFrame's Layout.
	  - OnAcquireItemFrame, a field of each viewer as the XML mixin's methods
	    are, so a post-hook on the viewer reaches it: the item's viewer, its
	    scale (iconScale), its timer (SetTimerShown: the countdown numbers, a
	    bar's duration text) and shown. The bar viewer's own
	    (BuffBarCooldownViewerMixin) also sets the bar's content, icon and name,
	    and its width, 220.
	  - The item templates (CooldownViewerEssentialItemTemplate, ...Utility...,
	    ...BuffIcon..., ...BuffBar...): their regions, sizes, layers, atlases,
	    fonts, anchors and frame levels as the XML has them, and their OnLoad
	    (the countdown font from cooldownFont; the bar's pip on its fill's
	    right end).

	Each viewer, and each item with every frame and region in it (the
	countdown numbers too), is locked once built (fixtures/locked_widget.lua),
	so a skin that writes a field onto one, or SetScripts one, fails. The
	fixture's own writes (Blizzard's) go through rawset.

	The glows Blizzard puts on an item, made as Blizzard makes them:
	CV.show_alert(item), the proc glow (ActionButtonSpellAlertManager's
	GetAlertFrame, Blizzard_ActionBar/Shared/ActionButtonSpellAlerts.lua: a
	frame of the item's with no level of its own, 1.4 times its size, centred,
	kept as item.SpellActivationAlert), and CV.show_pandemic(item), the
	pandemic glow (CooldownViewerMixin:SetupPandemicStateFrameForItem: a frame
	made in the viewer, then SetParent(item), 6 out round it), each locked.

	Not built: the cooldown data and its refresh (spells, auras, charges,
	totems), alerts and the glows' art and animations, the debuff border's atlas,
	the cooldown's timing (SetUseAuraDisplayTime isn't stubbed), tooltips and
	mouse, the edit mode system and the settings window.
]]

local lock = load_test_file('misc/fixtures/locked_widget.lua')
local OWNER = 'Blizzard Cooldown Manager'

local CV = {}

-- The atlases and files the templates name.
CV.MASK = 'UI-HUD-CoolDownManager-Mask'
CV.OVERLAY = 'UI-HUD-CoolDownManager-IconOverlay'
CV.SWIPE = [[Interface\HUD\UI-HUD-CoolDownManager-Icon-Swipe]]
CV.EDGE = [[Interface\Cooldown\UI-HUD-ActionBar-SecondaryCooldown]]
CV.BAR = 'UI-HUD-CoolDownManager-Bar'
CV.BAR_BG = 'UI-HUD-CoolDownManager-Bar-BG'
CV.PIP = 'UI-HUD-CoolDownManager-Bar-Pip'
CV.BAR_COLOR = { 1, 0.5, 0.25 }

-- Blizzard's fonts the templates inherit (SharedFonts.xml and Fonts.xml), as
-- far as a font string here needs one: a face, a size and the outline.
local FONTS = {
	GameFontHighlightHugeOutline = { 20, 'OUTLINE' },
	GameFontHighlightOutline = { 12, 'OUTLINE' },
	NumberFontNormal = { 14, 'OUTLINE' },
	NumberFontNormalSmall = { 12, 'OUTLINE' },
}
for name, font in pairs(FONTS) do
	if not _G[name] then
		CreateFont(name):SetFont([[Fonts\ARIALN.TTF]], font[1], font[2])
	end
end

-- An icon filling parent, masked round, with the overlay art out round it by
-- x and y (the overlay has no key: the skin finds it by its atlas).
local function masked_icon(parent, x, y)
	local icon = parent:CreateTexture(nil, 'ARTWORK')
	icon:SetAllPoints()
	local mask = parent:CreateMaskTexture(nil, 'ARTWORK')
	mask:SetAtlas(CV.MASK)
	mask:SetAllPoints()
	icon:AddMaskTexture(mask)
	local overlay = parent:CreateTexture(nil, 'OVERLAY')
	overlay:SetAtlas(CV.OVERLAY)
	overlay:SetPoint('TOPLEFT', -x, y)
	overlay:SetPoint('BOTTOMRIGHT', x, -y)
	return icon
end

-- The cooldown filling the item, with the round swipe in the template's color
-- (<SwipeTexture file=...><Color .../></SwipeTexture>).
local function cooldown(item, r, g, b, a, reverse)
	local cd = CreateFrame('Cooldown', nil, item)
	cd:SetAllPoints()
	cd:SetSwipeTexture(CV.SWIPE)
	cd:SetSwipeColor(r, g, b, a)
	cd:SetEdgeTexture(CV.EDGE)
	if reverse then cd:SetReverse(true) end
	return cd
end

-- A font string in frame, inheriting font, at its bottom right corner.
local function corner_text(frame, font, x, y)
	local text = frame:CreateFontString(nil, 'OVERLAY', font)
	text:SetPoint('BOTTOMRIGHT', x, y)
	return text
end

-- CooldownViewerEssentialItemTemplate (size 50, overlay 9 by 8 out,
-- GameFontHighlightHugeOutline, NumberFontNormal) and ...UtilityItemTemplate
-- (30, 6 by 5, GameFontHighlightOutline, NumberFontNormalSmall).
local function cooldown_item(viewer, spec)
	local item = CreateFrame('Frame', nil, viewer)
	item:SetSize(spec.size, spec.size)
	rawset(item, 'cooldownFont', spec.cooldownFont)
	rawset(item, 'Icon', masked_icon(item, spec.overlay[1], spec.overlay[2]))
	local outOfRange = item:CreateTexture(nil, 'OVERLAY')
	outOfRange:SetAllPoints()
	outOfRange:SetAtlas('UI-CooldownManager-OORshadow')
	outOfRange:SetVertexColor(1, 1, 1, 0.5)
	outOfRange:Hide()
	rawset(item, 'OutOfRange', outOfRange)
	rawset(item, 'Cooldown', cooldown(item, 1, 1, 1, 1))
	local charges = CreateFrame('Frame', nil, item)
	charges:SetAllPoints()
	rawset(charges, 'Current', corner_text(charges, spec.countFont, -2, 2))
	rawset(item, 'ChargeCount', charges)
	local flash = CreateFrame('Frame', nil, item)
	flash:SetPoint('TOPLEFT', 0, 1)
	flash:SetPoint('BOTTOMRIGHT', 0, 1)
	flash:Hide()
	local flipbook = flash:CreateTexture(nil, 'ARTWORK')
	flipbook:SetAllPoints()
	flipbook:SetAtlas('UI-HUD-ActionBar-GCD-Flipbook')
	flipbook:SetAlpha(0)
	rawset(flash, 'Flipbook', flipbook)
	rawset(item, 'CooldownFlash', flash)
	-- CooldownViewerItemMixin:OnLoad, and the cooldown items' OnCooldownDone.
	item.Cooldown:SetCountdownFont(spec.cooldownFont)
	item.Cooldown:SetScript('OnCooldownDone', function() end)
	return item
end

-- CooldownViewerItemDebuffBorderTemplate on the icon (a texture or a frame),
-- 3 out round it, at level (when given).
local function debuff_border(item, icon, level)
	local border = CreateFrame('Frame', nil, item)
	if level then border:SetFrameLevel(level) end
	border:SetPoint('TOPLEFT', icon, 'TOPLEFT', -3, 3)
	border:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', 3, -3)
	local texture = border:CreateTexture(nil, 'ARTWORK')
	texture:SetAllPoints()
	rawset(border, 'Texture', texture)
	border:Hide()
	return border
end

-- CooldownViewerBuffIconItemTemplate: 40, overlay 8 by 7 out, a reversed
-- cooldown in black at 0.7, the debuff border and the stack count.
local function buff_icon_item(viewer)
	local item = CreateFrame('Frame', nil, viewer)
	item:SetSize(40, 40)
	rawset(item, 'Icon', masked_icon(item, 8, 7))
	rawset(item, 'Cooldown', cooldown(item, 0, 0, 0, 0.7, true))
	rawset(item, 'DebuffBorder', debuff_border(item, item.Icon))
	local applications = CreateFrame('Frame', nil, item)
	applications:SetAllPoints()
	rawset(applications, 'Applications', corner_text(applications, 'NumberFontNormal', -2, 2))
	rawset(item, 'Applications', applications)
	-- CooldownViewerBuffIconItemMixin:OnLoad.
	item.Cooldown:SetScript('OnCooldownDone', function() end)
	return item
end

-- CooldownViewerBuffBarItemTemplate: 220 by 30, the icon a frame of its own at
-- level 512 holding the masked icon, the overlay and the stack count; the
-- debuff border at 520; the bar at 511, 19 tall, from 2 right of the icon to
-- the item's right, its fill the bar atlas in orange over its background,
-- the pip, the name and the duration.
local function buff_bar_item(viewer)
	local item = CreateFrame('Frame', nil, viewer)
	item:SetSize(220, 30)
	local iconFrame = CreateFrame('Frame', nil, item)
	iconFrame:SetFrameLevel(512)
	iconFrame:SetPoint('LEFT')
	iconFrame:SetSize(30, 30)
	rawset(iconFrame, 'Icon', masked_icon(iconFrame, 6, 5))
	local applications = iconFrame:CreateFontString(nil, 'OVERLAY', 'NumberFontNormalSmall')
	applications:SetJustifyH('RIGHT')
	applications:SetSize(32, 10)
	applications:SetPoint('BOTTOMRIGHT', -5, 5)
	rawset(iconFrame, 'Applications', applications)
	rawset(item, 'Icon', iconFrame)
	rawset(item, 'DebuffBorder', debuff_border(item, iconFrame, 520))

	local bar = CreateFrame('StatusBar', nil, item)
	bar:SetFrameLevel(511)
	bar:SetHeight(19)
	bar:SetPoint('LEFT', iconFrame, 'RIGHT', 2, 0)
	bar:SetPoint('RIGHT', 0, 0)
	local fill = bar:CreateTexture(nil, 'ARTWORK')
	fill:SetAtlas(CV.BAR)
	fill:SetVertexColor(unpack(CV.BAR_COLOR))
	bar:SetStatusBarTexture(fill)
	local background = bar:CreateTexture(nil, 'BACKGROUND')
	background:SetAtlas(CV.BAR_BG)
	background:SetPoint('TOPLEFT', -2, 2)
	background:SetPoint('BOTTOMRIGHT', 4, -7)
	rawset(bar, 'BarBG', background)
	local pip = bar:CreateTexture(nil, 'OVERLAY')
	pip:SetAtlas(CV.PIP, true)
	rawset(bar, 'Pip', pip)
	local name = bar:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	name:SetJustifyH('LEFT')
	name:SetJustifyV('MIDDLE')
	name:SetPoint('TOPLEFT', 5, 0)
	name:SetPoint('BOTTOMRIGHT', -25, 0)
	rawset(bar, 'Name', name)
	local duration = bar:CreateFontString(nil, 'OVERLAY', 'NumberFontNormal')
	duration:SetJustifyH('LEFT')
	duration:SetPoint('RIGHT', -8, 0)
	rawset(bar, 'Duration', duration)
	rawset(item, 'Bar', bar)
	-- CooldownViewerBuffBarItemMixin:OnLoad: the pip on the fill's right end.
	pip:ClearAllPoints()
	pip:SetPoint('CENTER', bar:GetStatusBarTexture(), 'RIGHT', 0, -1)
	return item
end

-- Locks widget and every frame and region in it.
local function lock_all(widget)
	lock(widget, OWNER)
	if widget.GetRegions then
		for _, region in ipairs({ widget:GetRegions() }) do lock(region, OWNER) end
	end
	if widget.GetChildren then
		for _, child in ipairs({ widget:GetChildren() }) do lock_all(child) end
	end
	if widget.GetCountdownFontString then lock(widget:GetCountdownFontString(), OWNER) end
end

-- A frame pool as Pools.lua's: see the top of this file.
local function frame_pool(create, reset)
	local active, inactive, count = {}, {}, 0
	local pool = {}
	function pool:Acquire()
		local object = table.remove(inactive)
		local new = object == nil
		if new then
			object = create()
			reset(pool, object, new)
		end
		active[object] = true
		count = count + 1
		return object, new
	end
	function pool:Release(object)
		if not active[object] then return false end
		reset(pool, object)
		active[object] = nil
		count = count - 1
		table.insert(inactive, object)
		return true
	end
	function pool:ReleaseAll()
		for object in pairs(active) do pool:Release(object) end
	end
	function pool:EnumerateActive() return pairs(active) end
	function pool:GetNumActive() return count end
	return pool
end

-- CooldownViewerMixin:OnLoad's itemResetCallback.
local function reset_item(pool, item)
	item:Hide()
	item:ClearAllPoints()
	rawset(item, 'layoutIndex', nil)
end

-- CooldownViewerMixin:OnAcquireItemFrame.
local function on_acquire(self, item)
	rawset(item, 'viewerFrame', self)
	item:SetScale(self.iconScale)
	if item.Cooldown then item.Cooldown:SetHideCountdownNumbers(not self.timerShown) end
	if item.Bar then item.Bar.Duration:SetShown(self.timerShown) end
	item:Show()
end

-- BuffBarCooldownViewerMixin:OnAcquireItemFrame: the base one, then the bar's
-- content (Enum.CooldownViewerBarContent.IconAndName) and width.
local function on_acquire_bar(self, item)
	on_acquire(self, item)
	item.Icon:Show()
	item.Bar.Name:Show()
	item.Bar:SetPoint('LEFT', item.Icon, 'RIGHT', 2, 0)
	item:SetWidth(220)
end

-- CooldownViewerMixin:RefreshLayout: see the top of this file.
local function refresh_layout(self, count)
	self.itemFramePool:ReleaseAll()
	local items = {}
	for i = 1, count do
		local item = self.itemFramePool:Acquire()
		rawset(item, 'layoutIndex', i)
		self:OnAcquireItemFrame(item)
		items[i] = item
	end
	local offset = 0
	for _, item in ipairs(items) do
		if self.isBars then
			item:SetPoint('TOPLEFT', self, 'TOPLEFT', 0, -offset)
			offset = offset + item:GetHeight() + self.iconPadding - 2
		else
			item:SetPoint('TOPLEFT', self, 'TOPLEFT', offset, 0)
			offset = offset + item:GetWidth() + self.iconPadding - 4
		end
	end
	return items
end

local SPECS = {
	Essential = { name = 'EssentialCooldownViewer', y = -100, padding = 2,
		make = function(v) return cooldown_item(v, { size = 50, overlay = { 9, 8 },
			cooldownFont = 'GameFontHighlightHugeOutline', countFont = 'NumberFontNormal' }) end },
	Utility = { name = 'UtilityCooldownViewer', y = -160, padding = 2,
		make = function(v) return cooldown_item(v, { size = 30, overlay = { 6, 5 },
			cooldownFont = 'GameFontHighlightOutline', countFont = 'NumberFontNormalSmall' }) end },
	BuffIcon = { name = 'BuffIconCooldownViewer', y = 0, padding = 5, make = buff_icon_item },
	BuffBar = { name = 'BuffBarCooldownViewer', y = 100, padding = 5, make = buff_bar_item, bars = true },
}
CV.KEYS = { 'Essential', 'Utility', 'BuffIcon', 'BuffBar' }

-- The four viewers, made as the addon's XML makes them, each locked.
function CV.build()
	for _, key in ipairs(CV.KEYS) do
		local spec = SPECS[key]
		local viewer = CreateFrame('Frame', spec.name, UIParent)
		viewer:SetSize(400, 50)
		viewer:SetPoint('CENTER', UIParent, 'CENTER', 0, spec.y)
		viewer.iconScale, viewer.iconPadding, viewer.timerShown = 1, spec.padding, true
		viewer.isBars = spec.bars or nil
		viewer.itemFramePool = frame_pool(function()
			local item = spec.make(viewer)
			lock_all(item)
			return item
		end, reset_item)
		viewer.OnAcquireItemFrame = spec.bars and on_acquire_bar or on_acquire
		viewer.RefreshLayout = refresh_layout
		lock(viewer, OWNER)
		CV[key] = viewer
	end
end

-- The proc glow on item, as ActionButtonSpellAlertManager makes it.
function CV.show_alert(item)
	local frame = item.SpellActivationAlert
	if not frame then
		frame = CreateFrame('Frame', nil, item)
		local width, height = item:GetSize()
		frame:SetSize(width * 1.4, height * 1.4)
		frame:SetPoint('CENTER', item, 'CENTER', 0, 0)
		rawset(item, 'SpellActivationAlert', frame)
		lock(frame, OWNER)
	end
	frame:Show()
	return frame
end

-- The pandemic glow on item, as its viewer's pool hands one out.
function CV.show_pandemic(item)
	local frame = CreateFrame('Frame', nil, item.viewerFrame)
	frame:SetParent(item)
	frame:SetPoint('TOPLEFT', item, 'TOPLEFT', -6, 6)
	frame:SetPoint('BOTTOMRIGHT', item, 'BOTTOMRIGHT', 6, -6)
	rawset(item, 'PandemicIcon', frame)
	lock(frame, OWNER)
	frame:Show()
	return frame
end

-- The items a viewer shows now, by layoutIndex.
function CV.items(viewer)
	local items = {}
	for item in viewer.itemFramePool:EnumerateActive() do items[item.layoutIndex] = item end
	return items
end

return CV
