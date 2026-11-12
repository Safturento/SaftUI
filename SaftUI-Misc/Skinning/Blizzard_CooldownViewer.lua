local st = SaftUI
local SK = st:GetModule('Skinning')
local CD = SK:NewModule('Blizzard_CooldownViewer')

--[[
	Skins Blizzard's Cooldown Manager (Blizzard_CooldownViewer, on Forever and retail
	alike) so each of its icons looks like one of SaftUI's action buttons, in the
	Skinning page's Theme, Background and font. Skinning -> Cooldown Manager turns it
	off; that, and turning it on again, take a reload.

	The four viewers are Blizzard's Edit Mode systems: EssentialCooldownViewer and
	UtilityCooldownViewer (cooldowns), BuffIconCooldownViewer (tracked buffs as
	icons) and BuffBarCooldownViewer (tracked buffs as bars). Blizzard's edit mode
	places and sizes them, lays their items out and sets the items' scale (Icon
	Size) and spacing (Icon Padding); nothing here moves or sizes a viewer or an
	item. Each viewer makes its items from a frame pool as it lays itself out
	(RefreshLayout: every item released, then one acquired per cooldown), in
	combat too, and hands each to its own OnAcquireItemFrame. That method is
	copied onto the viewer from its mixin, so the viewer's own is post-hooked
	(hooksecurefunc): an item is skinned the first time a viewer hands it out, and
	a reused one is left as it is. Items the viewers made before SaftUI loaded are
	skinned from their pools (EnumerateActive) when it does.

	Each item, as an action button (SaftUI-ActionBars/skin.lua is the look):
	  - a backdrop of SaftUI's, drawn as the action kind through st:SetBackdropIn,
	    filling the item (a bar's: its icon frame), so its size is the button's
	    whole footprint as Blizzard's item size is;
	  - the icon inside the backdrop's border, its round mask taken off and
	    cropped square (st:SkinIcon), and the Cooldown Manager's own frame round
	    it (UI-HUD-CoolDownManager-IconOverlay, a region with no key, found by
	    its atlas) faded out;
	  - the cooldown, its flash and the out of range shadow over the icon, the
	    swipe a flat square (Blizzard's swipe texture is round) in the colors
	    Blizzard keeps setting (dark on a cooldown, gold while a buff is up), and
	    the countdown numbers in Pixel Med on items 36 wide and up, Pixel below, as
	    on SaftUI's action bars;
	  - the charges or stack count in the Skinning font at the icon's bottom
	    right corner;
	  - under the Blizzard theme, the action button's ring (on a frame of
	    SaftUI's one level over the item, as for every frame that isn't
	    SaftUI's) under the cooldown and the count: Blizzard's frames over the
	    icon are raised one level over it, and a bar's stack count, a font
	    string of its icon frame, is moved into a frame of SaftUI's over it.
	A bar item's bar is drawn as SaftUI's bars are (the swing timer's skin): a
	backdrop of SaftUI's drawn as a bar outside it, a flat fill in Blizzard's
	orange, its background art faded, the pip a flat 2px line at the fill's end,
	and its name and duration in the Skinning font.

	Blizzard's debuff border (a tracked debuff's dispel type) is left as Blizzard
	draws it, round the icon. The proc glow and the pandemic glow are Blizzard's.

	Nothing is written onto Blizzard's frames (.agents/taint.md rule 1): SaftUI's
	pieces are kept in tables here keyed by Blizzard's frames, and Blizzard's
	frames and regions only get widget calls. Blizzard never sets the alpha of
	the regions faded here or the level of the frames raised here, and anchors
	the ones placed here only in their templates (the pip once, in OnLoad), so
	the skin holds. The items aren't protected and carry no
	access restrictions or forbidden aspects (unlike the aura containers', rule
	11), so everything here is legal in combat. No cooldown value is read.
]]

local issecretvalue = issecretvalue or function() return false end

local VIEWERS = {
	'EssentialCooldownViewer', 'UtilityCooldownViewer',
	'BuffIconCooldownViewer', 'BuffBarCooldownViewer',
}

-- The Cooldown Manager's frame round each icon (CooldownViewer.xml),
-- lowercased: a client may give an atlas name back in another case.
local OVERLAY_ATLAS = 'ui-hud-cooldownmanager-iconoverlay'

-- From this item width up the countdown numbers are Pixel Med, below it Pixel
-- (SaftUI-ActionBars/skin.lua's LARGE_COUNTDOWN_SIZE). The Essential items are
-- 50 wide, the tracked buffs' 40 and the Utility items 30.
local LARGE_COUNTDOWN_SIZE = 36

-- The bar's fill: Blizzard's own orange (its BarTexture's color), flat.
local BAR_COLOR = { 1, 0.5, 0.25 }
local PIP_WIDTH = 2

-- The parts Blizzard lays over the whole item, put over the icon instead.
local OVER_ICON = { 'cooldown', 'flash', 'outOfRange' }

-- An icon item's frames over its icon. Under the Blizzard theme the action
-- button's ring is on a frame of SaftUI's one level over the item (ThemeArt's
-- holder), the level these are made at, so they go one level higher: the
-- swipe, the numbers and the count lie over the ring, as on SaftUI's own
-- action buttons, whichever the game draws first at one level.
local OVER_RING = { 'Cooldown', 'CooldownFlash', 'ChargeCount', 'Applications', 'DebuffBorder' }

-- item -> its parts the skin styles, { holder, icon, count, cooldown, flash,
-- outOfRange, bar }, once it's skinned. The holder is the frame the icon fills
-- (the item, or a bar item's icon frame).
local skinned = setmetatable({}, { __mode = 'k' })

-- A holder or a bar -> SaftUI's backdrop behind it (st:SetBackdropIn).
local backdrops = setmetatable({}, { __mode = 'k' })

-- A bar item's icon frame -> the frame of SaftUI's its stack count is moved
-- into (CountFrame).
local countFrames = setmetatable({}, { __mode = 'k' })

-- The viewers whose OnAcquireItemFrame is hooked.
local hooked = setmetatable({}, { __mode = 'k' })

-- The Skinning page's Theme and Background, read at use time.
local function SkinningLook()
	local config = st.config.profile.skinning
	return config.theme, config.background
end

-- An item's parts, or nil for a frame that isn't one of the templates'.
local function Parts(item)
	if item.Bar then
		-- CooldownViewerBuffBarItemTemplate: the icon is a frame of its own.
		local holder = item.Icon
		return holder and {
			holder = holder,
			icon = holder.Icon,
			count = holder.Applications,
			bar = item.Bar,
		}
	end
	local count = item.ChargeCount and item.ChargeCount.Current
		or item.Applications and item.Applications.Applications
	return {
		holder = item,
		icon = item.Icon,
		count = count,
		cooldown = item.Cooldown,
		flash = item.CooldownFlash,
		outOfRange = item.OutOfRange,
	}
end

-- Fades the Cooldown Manager's frame round the icon, a region of frame's with
-- no key.
local function FadeOverlay(frame)
	for _, region in ipairs({ frame:GetRegions() }) do
		local atlas = region.GetAtlas and region:GetAtlas()
		if atlas and not issecretvalue(atlas) and type(atlas) == 'string' and atlas:lower() == OVERLAY_ATLAS then
			region:SetAlpha(0)
		end
	end
end

-- The countdown numbers' font: Pixel Med on a large item, Pixel on a small one,
-- or Pixel when its width can't be read.
local function CountdownFont(holder)
	local width = holder:GetWidth()
	local large = not issecretvalue(width) and width >= LARGE_COUNTDOWN_SIZE
	return st:GetFont(large and 'pixel_med' or 'pixel')
end

-- The bar of a bar item, as SaftUI's bars: see the top of this file.
local function StyleBar(bar, theme, background, font)
	st:SetBackdropIn(backdrops, bar, theme, background, 'bar')

	bar:SetStatusBarTexture(st.BLANK_TEX)
	bar:SetStatusBarColor(unpack(BAR_COLOR))
	if bar.BarBG then bar.BarBG:SetAlpha(0) end

	-- The pip on the fill's right end, the bar's height: Blizzard anchored its
	-- art's centre there once, in OnLoad.
	local fill, pip = bar:GetStatusBarTexture(), bar.Pip
	if pip and fill then
		pip:SetTexture(st.BLANK_TEX)
		pip:SetVertexColor(1, 1, 1, 1)
		pip:ClearAllPoints()
		pip:SetPoint('TOP', fill, 'TOPRIGHT')
		pip:SetPoint('BOTTOM', fill, 'BOTTOMRIGHT')
		pip:SetWidth(PIP_WIDTH)
	end

	if font then
		for _, text in ipairs({ bar.Name, bar.Duration }) do
			text:SetFontObject(font)
		end
	end
end

-- Puts the profile's look on a skinned item. Safe to run again: it makes
-- nothing new after the first time (the backdrops).
local function Style(item, parts)
	local theme, background = SkinningLook()
	local font = st:GetFont(st.config.profile.skinning.font)
	local holder, icon = parts.holder, parts.icon

	-- The backdrop fills the holder, as an action button's fills the button.
	-- Under None it's cleared, or not made yet.
	st:SetBackdropIn(backdrops, holder, theme, background, 'action')
	local backdrop = backdrops[holder]
	if backdrop then
		backdrop:ClearAllPoints()
		backdrop:SetAllPoints(holder)
	end

	-- The icon inside the border, cropped once it has its size.
	local inset = st:ThemeInset(theme, background, 'action')
	icon:ClearAllPoints()
	icon:SetPoint('TOPLEFT', holder, 'TOPLEFT', inset, -inset)
	icon:SetPoint('BOTTOMRIGHT', holder, 'BOTTOMRIGHT', -inset, inset)
	st:SkinIcon(icon)

	for _, key in ipairs(OVER_ICON) do
		local region = parts[key]
		if region then
			region:ClearAllPoints()
			region:SetAllPoints(icon)
		end
	end

	local cooldown = parts.cooldown
	if cooldown then
		cooldown:SetSwipeTexture(st.BLANK_TEX)
		local numbers = cooldown:GetCountdownFontString()
		local countdownFont = CountdownFont(holder)
		if numbers and countdownFont then numbers:SetFontObject(countdownFont) end
	end

	local count = parts.count
	if count then
		if font then count:SetFontObject(font) end
		count:ClearAllPoints()
		count:SetPoint('BOTTOMRIGHT', icon, 'BOTTOMRIGHT', -1, 1)
	end

	if parts.bar then StyleBar(parts.bar, theme, background, font) end
end

-- Raises an icon item's frames over its icon one level over the ring's holder
-- (OVER_RING). A level that can't be read leaves them where they are.
local function RaiseOverRing(item)
	local level = item:GetFrameLevel()
	if issecretvalue(level) then return end
	for _, key in ipairs(OVER_RING) do
		local frame = item[key]
		if frame and frame.SetFrameLevel then frame:SetFrameLevel(level + 2) end
	end
end

-- A bar item's stack count is a font string of its icon frame (level 512),
-- which the ring's holder, a frame over that one, would cover under the
-- Blizzard theme. So it's moved into a frame of SaftUI's one level over the
-- holder, a child of the icon frame, so it shows and hides with the icon as
-- Blizzard's bar content setting has it. Blizzard only sets its text.
local function CountFrame(holder)
	local frame = countFrames[holder]
	if not frame then
		frame = CreateFrame('Frame', nil, holder)
		frame:SetAllPoints(holder)
		countFrames[holder] = frame
		local level = holder:GetFrameLevel()
		if not issecretvalue(level) then frame:SetFrameLevel(level + 2) end
	end
	return frame
end

-- Skins an item the first time a viewer hands it out; a reused one is left.
local function SkinItem(item)
	if not item or skinned[item] then return end
	local parts = Parts(item)
	if not (parts and parts.holder and parts.icon) then return end
	skinned[item] = parts
	FadeOverlay(parts.holder)
	if parts.holder == item then
		RaiseOverRing(item)
	elseif parts.count then
		parts.count:SetParent(CountFrame(parts.holder))
	end
	Style(item, parts)
end

-- The viewer's own OnAcquireItemFrame, post-hooked.
local function OnAcquireItemFrame(viewer, item)
	SkinItem(item)
end

-- Hooks each viewer that exists, once, and skins the items it shows already.
function CD:SkinViewers()
	for _, name in ipairs(VIEWERS) do
		local viewer = _G[name]
		if viewer and not hooked[viewer] and type(viewer.OnAcquireItemFrame) == 'function' then
			hooked[viewer] = true
			hooksecurefunc(viewer, 'OnAcquireItemFrame', OnAcquireItemFrame)
			local pool = viewer.itemFramePool
			if pool then
				for item in pool:EnumerateActive() do
					SkinItem(item)
				end
			end
		end
	end
end

-- A profile change or the Skinning page: every skinned item takes the
-- profile's Theme, Background and font. It draws SaftUI's backdrops and makes
-- only widget calls on Blizzard's frames and regions, as the hook does, so it
-- runs in combat too.
function CD:UpdateConfig()
	for item, parts in pairs(skinned) do
		Style(item, parts)
	end
end

function CD:ADDON_LOADED(event, addon)
	if addon ~= 'Blizzard_CooldownViewer' then return end
	self:UnregisterEvent('ADDON_LOADED')
	self:SkinViewers()
end

-- Off (Skinning -> Cooldown Manager), nothing is hooked or touched: Blizzard's
-- look stays until a reload with it on.
function CD:OnEnable()
	if not st.config.profile.skinning.cooldown_manager then return end

	if _G.EssentialCooldownViewer then
		self:SkinViewers()
	else
		self:RegisterEvent('ADDON_LOADED')
	end
end
