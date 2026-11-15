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
	skinned from their pools (EnumerateActive) when it does. The hook runs in the
	middle of Blizzard's RefreshLayout, before it sets the items' data and lays
	them out, so each item is skinned in xpcall: an error is reported, Blizzard's
	layout still completes, and the item is tried again the next time it's
	handed out.

	Each item, as an action button (SaftUI-ActionBars/skin.lua is the look), by
	.agents/taint.md rule 1's recipe for one of Blizzard's buttons (as the totem
	bar's skin, SaftUI-Misc/totemskin.lua, does it):
	  - a backdrop of SaftUI's, the item's child one level under it, 2px inside
	    the item (a bar's: its icon frame). Blizzard's round icon sat that far
	    inside, and Blizzard lays the items out Icon Padding less 4 apart so
	    those icons touch (GetAdditionalPaddingOffset): with the backdrop there,
	    neighbours are Icon Padding apart, 2px at Blizzard's default. It's drawn
	    as the action kind with st:SetTemplate naming the item as host, so under
	    the Blizzard theme the ring is a texture of the item, over the icon and
	    under Blizzard's frames on it (the cooldown, the count, the debuff
	    border, the proc and pandemic glows) and a bar's stack count;
	  - the icon inside the backdrop's border, moved to BACKGROUND (the ring is
	    in ARTWORK), its round mask taken off and cropped square (st:SkinIcon),
	    and the Cooldown Manager's own frame round it
	    (UI-HUD-CoolDownManager-IconOverlay, a region with no key, found by its
	    atlas) and its round out of range shadow faded out (Blizzard also tints
	    the icon red out of range, which is how SaftUI's action bars show it);
	  - the cooldown and its flash over the icon, the swipe a flat square
	    (Blizzard's swipe texture is round) in the colors Blizzard keeps setting
	    (dark on a cooldown, gold while a buff is up), and the countdown numbers
	    in Pixel Med on items 36 wide and up, Pixel below, as on SaftUI's action
	    bars;
	  - the charges or stack count in the Skinning font at the icon's bottom
	    right corner, a bar's (which Blizzard makes 10 tall) as tall as the font.
	A bar item's bar is drawn as SaftUI's bars are (the swing timer's skin): a
	backdrop of SaftUI's drawn as a bar outside it, a flat fill in Blizzard's
	orange, its background art faded, the pip a flat 2px line at the fill's end,
	and its name and duration in the Skinning font.

	Blizzard's debuff border (a tracked debuff's dispel type) is left as Blizzard
	draws it, round the icon. The proc glow and the pandemic glow are Blizzard's.

	Nothing is written onto Blizzard's frames (.agents/taint.md rule 1): SaftUI's
	pieces are kept in tables here keyed by Blizzard's frames, and Blizzard's
	frames and regions only get widget calls; under the Blizzard theme the ring
	is a texture made on the item, as the totem bar's is (rule 12). Blizzard
	never sets the alpha of the regions faded here or the icon's draw layer, and
	anchors the ones placed here only in their templates (the pip once, in
	OnLoad), so the skin holds. The items aren't protected and carry no access
	restrictions or forbidden aspects (unlike the aura containers', rule 11), so
	everything here is legal in combat. No cooldown value is read.
]]

local VIEWERS = {
	'EssentialCooldownViewer', 'UtilityCooldownViewer',
	'BuffIconCooldownViewer', 'BuffBarCooldownViewer',
}

-- The Cooldown Manager's frame round each icon (CooldownViewer.xml),
-- lowercased: a client may give an atlas name back in another case.
local OVERLAY_ATLAS = 'ui-hud-cooldownmanager-iconoverlay'

-- How far inside the item (a bar's icon frame) SaftUI's backdrop sits: where
-- Blizzard's round icon sat (see the top of this file).
local ITEM_INSET = 2

-- The bar's fill: Blizzard's own orange (its BarTexture's color), flat.
local BAR_COLOR = { 1, 0.5, 0.25 }
local PIP_WIDTH = 2

-- The parts Blizzard lays over the whole item, put over the icon instead.
local OVER_ICON = { 'cooldown', 'flash' }

-- item -> its parts the skin styles, { holder, icon, count, cooldown, flash,
-- outOfRange, bar }, once it's skinned. The holder is the frame the icon fills
-- (the item, or a bar item's icon frame).
local skinned = setmetatable({}, { __mode = 'k' })

-- A holder or a bar -> SaftUI's backdrop behind it: a holder's made here
-- (Backdrop), a bar's by st:SetBackdropIn.
local backdrops = setmetatable({}, { __mode = 'k' })

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

-- The backdrop behind a holder, made the first time: a frame of SaftUI's, the
-- holder's child one level under it, ITEM_INSET inside it.
local function Backdrop(holder)
	local backdrop = backdrops[holder]
	if not backdrop then
		backdrop = st:CreateFrame('Frame', nil, holder)
		local level = holder:GetFrameLevel()
		if not issecretvalue(level) then backdrop:SetFrameLevel(math.max(0, level - 1)) end
		backdrop:SetPoint('TOPLEFT', holder, 'TOPLEFT', ITEM_INSET, -ITEM_INSET)
		backdrop:SetPoint('BOTTOMRIGHT', holder, 'BOTTOMRIGHT', -ITEM_INSET, ITEM_INSET)
		backdrops[holder] = backdrop
	end
	return backdrop
end

-- The countdown numbers' font: Pixel Med on a large item (st.LARGE_COUNTDOWN_SIZE
-- wide or more), Pixel on a small one, or Pixel when its width can't be read.
-- The Essential items are 50 wide, the tracked buffs' 40 and the Utility items 30.
local function CountdownFont(holder)
	local width = holder:GetWidth()
	local large = not issecretvalue(width) and width >= st.LARGE_COUNTDOWN_SIZE
	return st:FontObject(large and 'pixel_med' or 'pixel')
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
	local font = st:FontObject(st.config.profile.skinning.font)
	local holder, icon = parts.holder, parts.icon

	-- The backdrop is drawn on itself, with the holder as the host of the
	-- Blizzard theme's ring. Under None it's cleared.
	st:SetTemplate(Backdrop(holder), theme, background, 'action', holder)

	-- The icon inside the border, in BACKGROUND under the ring, cropped once it
	-- has its size.
	local inset = ITEM_INSET + st:ThemeInset(theme, background, 'action')
	icon:SetDrawLayer('BACKGROUND', 0)
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
		-- A bar's count is a fixed 32 by 10 (Blizzard's template), which a
		-- taller font wouldn't fit: it's made as tall as the font.
		if parts.bar and font then
			local _, size = font:GetFont()
			if size and not issecretvalue(size) then count:SetHeight(size) end
		end
	end

	if parts.bar then StyleBar(parts.bar, theme, background, font) end
end

-- Skins an item the first time a viewer hands it out; a reused one is left.
-- It's marked skinned only once it's styled, so one that errored is tried
-- again (everything here is safe to run twice: Backdrop makes one backdrop).
local function SkinItem(item)
	if not item or skinned[item] then return end
	local parts = Parts(item)
	if not (parts and parts.holder and parts.icon) then return end
	FadeOverlay(parts.holder)
	if parts.outOfRange then parts.outOfRange:SetAlpha(0) end
	Style(item, parts)
	skinned[item] = parts
end

-- Skins an item in xpcall: inside Blizzard's RefreshLayout an error would stop
-- its layout half done, so it's reported instead (see the top of this file).
local function TrySkinItem(item)
	xpcall(SkinItem, geterrorhandler(), item)
end

-- The viewer's own OnAcquireItemFrame, post-hooked.
local function OnAcquireItemFrame(viewer, item)
	TrySkinItem(item)
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
					TrySkinItem(item)
				end
			end
		end
	end
end

-- A profile change or the Skinning page: every skinned item takes the
-- profile's Theme, Background and font, each in xpcall so one that errors
-- leaves the rest. It draws SaftUI's backdrops and makes only widget calls on
-- Blizzard's frames and regions, as the hook does, so it runs in combat too.
function CD:UpdateConfig()
	for item, parts in pairs(skinned) do
		xpcall(Style, geterrorhandler(), item, parts)
	end
end

-- A shared font or a font setting changed (st:FontsChanged): the items take the
-- Skinning font again (a typeface's object is not the shared font's).
function CD:OnFontsChanged()
	self:UpdateConfig()
end

-- Off (Skinning -> Cooldown Manager), nothing is hooked or touched: Blizzard's
-- look stays until a reload with it on.
function CD:OnEnable()
	if not st.config.profile.skinning.cooldown_manager then return end

	if _G.EssentialCooldownViewer then
		self:SkinViewers()
	else
		st:OnBlizzardAddon('Blizzard_CooldownViewer', function() self:SkinViewers() end)
	end
end
