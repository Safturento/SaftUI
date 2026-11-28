local st = SaftUI
local LT = st:GetModule('Loot')

--[[
	Skins Blizzard's loot window (LootFrame: the window that lists what a
	corpse or a chest holds) in SaftUI's look, while Loot -> Loot window ->
	Enable is on and its Theme is Thick or Thin. Under the Blizzard theme, under
	None and with the toggle off, the window keeps Blizzard's own art: every
	piece below is put back as Blizzard had it, and a theme switch, a profile
	change or the toggle goes between the two live (LT:UpdatePopup).

	The window (checked 2026-11-15 against both branches of Gethe/wow-ui-source,
	`forever` and `live`: Blizzard_UIPanels_Game/Mainline/LootFrame.xml and .lua,
	ScrollingFlatPanel.xml and .lua): both clients have the same scroll box
	window. The classic one (LootButton1 to LootButton4 and paging) is on
	neither, so this skin has nothing for it and does nothing where LootFrame has
	no ScrollBox. The clients differ in the gamepad code and in two pieces the skin
	touches: Forever's ItemButton has a round Mask on its icon (retail's has none,
	so a restore adds one mask on Forever and none on retail) and its close button
	is 28 x 28 (24 x 24 on retail). LootFrame is also an Edit Mode system, whose
	SetPoint, Hide and the like are Lua overrides the skin never calls.
	  - LootFrame is a DefaultPanelFlatTemplate (.NineSlice, .Bg,
	    .TitleContainer.TitleText) with a .ClosePanelButton, a .ScrollBox and a
	    .ScrollBar. Blizzard sizes it itself (ScrollingFlatPanelMixin:Resize from
	    the rows' count and its panelWidth and panelMaxHeight keys), places it
	    (at the cursor with Blizzard's own setting, or by Edit Mode), and fades it
	    in and out with its ShowAnim and HideAnim. The skin changes none of that.
	  - Each row is an element frame in the scroll box's .ScrollTarget (an item
	    or currency one, LootFrameItemElementTemplate, and a money one,
	    LootFrameMoneyElementTemplate), 46 tall, pooled and handed out again as
	    the window scrolls, with .Item (an ItemButton), .NameFrame and .BorderFrame
	    (the card), .HighlightNameFrame and .PushedNameFrame, .Text, and on item
	    rows .QualityStripe and .QualityText. Blizzard colors .Text and
	    .NameFrame by quality in the element's Init.

	What changes under Thick and Thin:
	  - LootFrame: SaftUI's panel behind it (st:SetBackdropIn, kind panel), with
	    .NineSlice and .Bg faded; the title in the Window titles font; the close
	    button's four textures faded and a Lucide cross of SaftUI's over it.
	  - The compact layout (Layout, after every Resize): the scroll box scaled to
	    ROW_SCALE and anchored again by its own offsets over the scale, the window
	    WINDOW_WIDTH wide (plus the scroll bar's 16 when the rows overflow) and as
	    tall as its scaled rows, up to Blizzard's panelMaxHeight; the scroll bar
	    shown when they overflow. Blizzard's row height is the view's element
	    extent, a Lua field LootFrame:Open reads before Edit Mode's
	    ApplySystemAnchor, so it is never written; scaling the box is a C call.
	  - Each row: a card of SaftUI's (kind panel) in place of .NameFrame,
	    .BorderFrame, .QualityStripe, .QualityText and the click textures, all
	    faded; the card runs from ICON_GAP right of the icon to the row's right
	    edge, as tall as the icon (as a roll bar's), and is scaled back up by
	    1 / ROW_SCALE, as is the slot, so their borders stay on whole pixels; it
	    tints (the states' hover) while the mouse is over the row; its border
	    stays the theme's. The name (.Text) is anchored across the card on one
	    line (no wrap, cut short with an ellipsis), and the item button's hit
	    rect reaches over the card. The icon in a
	    slot of SaftUI's (st:SetBackdropIn on .Item, kind slot) whose border is the
	    item's quality color (st:QualityColor), with .IconBorder, the normal and
	    pushed textures faded, the icon cropped by Icon zoom and its round mask
	    taken off. The texts (.Text, the count) in the Loot window's Font made
	    larger by 1 / ROW_SCALE (SaftUILootPopupFont, a font object of SaftUI's),
	    so they draw at the font's own size in the scaled rows.
	Left as Blizzard's: the scroll bar, the shadows at the scroll box's edges,
	the quest and profession overlays on an icon, a row's text color (Blizzard's
	quality color, put on in Init and put back after the font), the gamepad pieces
	and where the window is.

	Taint (.agents/taint.md). Loot buttons are clicked in combat all the time and
	the window is Blizzard's, so it is only looked at: nothing is written onto
	LootFrame, its rows or their regions (SaftUI's pieces live in weak tables
	here, keyed by Blizzard's frames, or are frames and textures SaftUI made), no
	script is set or replaced, and none of Blizzard's functions that write run from
	here (the Blizzard Lua called is the row's GetSlotIndex and, as a fallback,
	GetQuality, both reads of the element data; the C reads are GetLootSlotInfo
	and C_CurrencyInfo.GetCurrencyContainerInfo, for a slot's quality).
	Blizzard's widgets get C method calls only: alpha on regions whose alpha
	Blizzard never sets (the NineSlice, Bg, the card, the click textures, the
	icon's border and normal and pushed textures, the close button's textures),
	fonts (SetFontObject, which is not a protected function:
	.agents/taint.md rule 1), tex coords and masks on the icon, the compact
	layout's geometry (the scroll box's scale, anchors and width, the window's
	width and height, never its anchors, the scroll bar's shown state, a name's
	anchors, size, wrap and justify, an item button's hit rect), and the made
	child frames and textures. The hooks are post-hooks only: `hooksecurefunc` on
	the scroll box's Update (which Blizzard calls after it has acquired a row
	for any reason), on LootFrame's Resize (every open) and on each row's Init (which Blizzard calls again on
	LOOT_SLOT_CHANGED), and HookScript on LootFrame's OnShow and on each row's
	.Item (OnEnter, OnLeave) and the close button (OnEnter, OnLeave). Every step
	runs in xpcall, so an error stops nothing of Blizzard's. Nothing here is
	protected: neither LootFrame nor a row nor an ItemButton uses a secure
	template, and `st:CanMoveNow` is asked on LootFrame first, so a window some
	other addon made protected through an anchor is styled after combat, not in it.

	Timing: LootFrame lives in Blizzard_UIPanels_Game, which loads at login before
	SaftUI (st:OnBlizzardAddon waits for it where it doesn't). Nothing is hooked
	while the toggle is off; turning it on installs the hooks, and turning it off
	puts every piece back and leaves the hooks, which then do nothing.
]]

-- Blizzard's font for each text, by its named font: the fallback for a font that
-- can't be put back from what was read (.agents/taint.md rule 10).
local BLIZZARD_FONTS = {
	title = 'GameFontNormal',          -- DefaultPanelBaseTemplate's TitleText
	name = 'GameFontNormal',           -- LootFrameItemElementTemplate's and the money one's Text
	count = 'NumberFontNormal',        -- ItemButton's Count
}

-- The close button's four state textures (Button's C getters).
local CLOSE_TEXTURES = { 'GetNormalTexture', 'GetPushedTexture', 'GetDisabledTexture', 'GetHighlightTexture' }
local CLOSE_ICON = 20 -- Lucide's x is a 10 px cross in the middle of its 20

-- The compact layout (owner's ask, 2026-11-28: shorter rows, a wider window, the
-- name on one line to the right edge, no quality word, the icon outside the card
-- as on the roll bars). Blizzard's row height is the view's element extent, a
-- Lua field that LootFrame:Open reads before Edit Mode's ApplySystemAnchor, so
-- it is never written: the scroll box is scaled down instead (a C call on a
-- plain frame), and SaftUI's own pieces in it are scaled back up, so their
-- borders stay on whole pixels and the texts take a font made larger by the same
-- factor.
local ROW_SCALE = 0.75
local WINDOW_WIDTH = 300     -- Blizzard's panelWidth is 220
-- Blizzard's own numbers (LootFrame.lua's locals, ScrollingFlatPanel.lua's and
-- .xml's), read 2026-11-28 on Gethe/wow-ui-source `forever`.
local ROW_EXTENT, ROW_SPACING, ROW_PAD = 46, 2, 6
local SCROLLBAR_WIDTH = 16
local BOX_LEFT, BOX_TOP, BOX_BOTTOM = 4, -22, 4 -- the scroll box's anchors
local CHROME = 26 + 20       -- Resize's anchors and extra: the title and the margins
local ICON_RIGHT = 5 + 37    -- the item button's left offset and width in a row
local ICON_GAP = 7           -- between the icon's frame and the card's, as rollbar.lua's
local TEXT_PAD = 5           -- the name's inset in the card, as rollbar.lua's

-- What SaftUI made or changed, keyed by Blizzard's frames and regions (weak
-- keys: nothing is written onto them to remember it).
local weak = { __mode = 'k' }
local panels = setmetatable({}, weak)   -- LootFrame -> SaftUI's panel (st:SetBackdropIn)
local cards = setmetatable({}, weak)    -- element -> the holder of its card (SaftUI's frame, drawn with st:SetBackdrop)
LT.PopupCards = cards                     -- read-only for /run probes (docs/followups.md, the loot window's opaque hover): element -> holder
local slots = setmetatable({}, weak)    -- .Item -> its slot's backdrop (st:SetBackdropIn)
local closes = setmetatable({}, weak)   -- .ClosePanelButton -> { frame, icon }, SaftUI's cross
local hooked = setmetatable({}, weak)   -- frame -> true once its hooks are on
local failed = setmetatable({}, weak)   -- element -> the generation its styling last errored in (reported once)
local styled = setmetatable({}, weak)   -- element -> the generation it was last styled in
local hovering = setmetatable({}, weak) -- element -> true while the mouse is over its .Item
-- What Blizzard had before the first restyle, read then and put back by a
-- restore: a region's alpha, a text's font, an icon's tex coords and masks.
local alphas = setmetatable({}, weak)
local fonts = setmetatable({}, weak)
local coords = setmetatable({}, weak)
local masks = setmetatable({}, weak)
-- The geometry Blizzard had before the compact layout, put back by a restore:
-- the scroll box's scale and anchors, a text's anchors, size, wrap and vertical
-- justify, an item button's hit rect.
local boxes = setmetatable({}, weak)
local texts = setmetatable({}, weak)
local hits = setmetatable({}, weak)

local installed = false
-- Bumped by every change of the skin's settings, so a row styled before is
-- styled again the next time the scroll box updates.
local generation = 0

local function Config() return LT.config and LT.config.popup end

-- Whether the window wears SaftUI's look now: the toggle on and a Theme and
-- Background that draw Thick or Thin (not Blizzard's art, not None).
local function Active()
	local config = Config()
	if not config or not config.enable then return false end
	local look = st:ResolveTheme(config.theme, config.background)
	return look ~= nil and look.name ~= 'blizzard'
end

local function Apply(fn, ...) xpcall(fn, geterrorhandler(), ...) end

-- A font object read from Blizzard, if it is a named global Font (the only
-- kind safe to set again: rule 10), else nil.
local function Named(font)
	local name = font and font.GetName and font:GetName()
	if name and _G[name] == font then return font end
end

-- A font object resets a text's own color (st:ApplyFont's note), and Blizzard
-- colors each name by quality in Init (SetVertexColor, which on a font string is
-- the text's color), so the color read before the change is put back after it,
-- as the objective tracker skin does. A secret color is left alone.
local function KeepColor(target, change)
	local r, g, b, a
	if target.GetTextColor then r, g, b, a = target:GetTextColor() end
	change()
	if r and not issecretvalue(r) then target:SetTextColor(r, g, b, a) end
end

-- SaftUI's font on a font string, or what Blizzard had back. With keepColor
-- (the names, quality labels and counts) the text's color stays what it was
-- through each change; without it (the title) the font's own color shows, and a
-- restore puts back the color read before the first change.
local function PutFont(target, kind, active, font, keepColor)
	if not target or not target.SetFontObject then return end
	if active then
		if fonts[target] == nil then
			local entry = { font = Named(target.GetFontObject and target:GetFontObject()) }
			if target.GetTextColor then
				local r, g, b, a = target:GetTextColor()
				if r and not issecretvalue(r) then entry.color = { r, g, b, a } end
			end
			fonts[target] = entry
		end
		if font then
			if keepColor then KeepColor(target, function() target:SetFontObject(font) end) else target:SetFontObject(font) end
		end
	elseif fonts[target] then
		local original = fonts[target].font or _G[BLIZZARD_FONTS[kind]]
		if original then
			if keepColor then
				KeepColor(target, function() target:SetFontObject(original) end)
			else
				target:SetFontObject(original)
				local color = fonts[target].color
				if color then target:SetTextColor(unpack(color)) end
			end
		end
	end
end

-- Fades a region of Blizzard's (alpha 0), or puts back the alpha it had. Only
-- for regions whose alpha Blizzard never sets.
local function Fade(region, active)
	if not region or not region.SetAlpha then return end
	if active then
		if alphas[region] == nil then
			local alpha = region:GetAlpha()
			alphas[region] = not issecretvalue(alpha) and alpha or 1
		end
		region:SetAlpha(0)
	elseif alphas[region] ~= nil then
		region:SetAlpha(alphas[region])
	end
end

-- Has the game keep SaftUI's frame on whole pixels in screen space: the window
-- sits at the cursor, on no pixel grid. Only SaftUI's own frames.
local function Round(frame)
	if frame and frame.SetRoundLayoutToNearestPixel then frame:SetRoundLayoutToNearestPixel(true) end
end

local function Look()
	local config = Config()
	return config.theme, config.background
end

-- Puts frame `delta` levels from reference's. Blizzard's levels can be secret
-- (never here today): the frame then stays at the level it was made at.
local function SetLevel(frame, reference, delta)
	local level = reference:GetFrameLevel()
	if level ~= nil and not issecretvalue(level) then frame:SetFrameLevel(max(0, level + delta)) end
end

-- A region's anchors as GetPoint gives them, to put back.
local function ReadPoints(region)
	local list = {}
	for i = 1, region:GetNumPoints() do list[i] = { region:GetPoint(i) } end
	return list
end

local function PutPoints(region, list)
	region:ClearAllPoints()
	for _, point in ipairs(list) do region:SetPoint(unpack(point)) end
end

-- The Loot window's font, made larger by the rows' scale so a text in the scaled
-- scroll box draws at the font's own size: a font object of SaftUI's, set from
-- the chosen one each time it is asked for.
local scaledFont
local function ScaledFont()
	local base = st:FontObject(Config().font)
	scaledFont = scaledFont or CreateFont('SaftUILootPopupFont')
	scaledFont:SetFontObject(base)
	local path, size, flags = base:GetFont()
	if path and type(size) == 'number' then scaledFont:SetFont(path, size / ROW_SCALE, flags) end
	return scaledFont
end
LT.PopupFont = function() return scaledFont end -- for tests and /run probes

------------------------------------------------------------------ the window

-- The number of rows the window holds now (the scroll box's data provider, a
-- read of Blizzard's Lua).
local function RowCount(frame)
	local ok, count = pcall(frame.ScrollBox.GetDataProviderSize or error, frame.ScrollBox)
	return ok and type(count) == 'number' and count or 0
end

-- The window's size and the scroll box's scale, as Resize leaves them (Blizzard's
-- sums from its own constants), or the compact layout's: rows scaled by
-- ROW_SCALE in a window WINDOW_WIDTH wide, no taller than Blizzard's
-- panelMaxHeight. Only C calls on plain frames (SetScale, SetPoint, SetWidth,
-- SetHeight, SetShown): LootFrame's SetPoint is Edit Mode's override, so the
-- window itself is never anchored, only sized (neither is overridden).
local function Layout(frame, active)
	local box = frame.ScrollBox
	if not box or not box.SetScale then return end
	if not active and not boxes[box] then return end
	-- A closed window is sized by its next open's Resize, and Edit Mode gives
	-- the window its own height (UpdateShownState): neither is laid out here.
	if active and (not frame:IsShown() or frame.isInEditMode) then return end
	local count = RowCount(frame)
	local rows = math.max(count * ROW_EXTENT + math.max(count - 1, 0) * ROW_SPACING, ROW_EXTENT)
	local maxHeight = type(frame.panelMaxHeight) == 'number' and frame.panelMaxHeight or 290
	local panelWidth = type(frame.panelWidth) == 'number' and frame.panelWidth or 220
	local scale, width, height
	if active then
		if not boxes[box] then boxes[box] = { scale = box:GetScale(), points = ReadPoints(box) } end
		scale, width = ROW_SCALE, WINDOW_WIDTH
		height = (rows + 2 * ROW_PAD) * scale + CHROME - 2 * ROW_PAD
		box:SetScale(scale)
		box:ClearAllPoints()
		box:SetPoint('TOPLEFT', frame, 'TOPLEFT', BOX_LEFT / scale, BOX_TOP / scale)
		box:SetPoint('BOTTOM', frame, 'BOTTOM', 0, BOX_BOTTOM / scale)
	else
		local saved = boxes[box]
		boxes[box] = nil
		scale, width = saved.scale or 1, panelWidth
		height = rows + CHROME
		box:SetScale(scale)
		PutPoints(box, saved.points)
	end
	-- The rows overflow when they and the paddings, scaled, are taller than the
	-- scroll box the window leaves them (its height less the box's anchors).
	height = math.min(height, maxHeight)
	local scrolls = (rows + 2 * ROW_PAD) * scale > height + BOX_TOP - BOX_BOTTOM
	frame:SetHeight(height)
	frame:SetWidth(width + (scrolls and SCROLLBAR_WIDTH or 0))
	box:SetWidth((width - ROW_PAD) / scale)
	if frame.ScrollBar and frame.ScrollBar.SetShown then frame.ScrollBar:SetShown(scrolls) end
end

local function CloseColor(hover)
	if hover then return st:Color('text', 'danger'):GetRGB() end
	return st:Color('text', 'muted'):GetRGB()
end

local function StyleClose(frame, active)
	local button = frame.ClosePanelButton
	if not button then return end
	for _, getter in ipairs(CLOSE_TEXTURES) do
		if button[getter] then Fade(button[getter](button), active) end
	end
	local cross = closes[button]
	if not cross and active then
		cross = {}
		cross.frame = st:CreateFrame('Frame', nil, button)
		cross.frame:SetAllPoints(button)
		cross.icon = cross.frame:CreateTexture(nil, 'OVERLAY')
		cross.icon:SetTexture(st.icons.x)
		cross.icon:SetSize(CLOSE_ICON, CLOSE_ICON)
		cross.icon:SetPoint('CENTER')
		closes[button] = cross
		if button.HookScript then
			button:HookScript('OnEnter', function()
				if closes[button] then closes[button].icon:SetVertexColor(CloseColor(true)) end
			end)
			button:HookScript('OnLeave', function()
				if closes[button] then closes[button].icon:SetVertexColor(CloseColor(false)) end
			end)
		end
	end
	if cross then
		cross.frame:SetShown(active)
		if active then cross.icon:SetVertexColor(CloseColor(false)) end
	end
end

local function StyleWindow(frame, active)
	local theme, background = Look()
	st:SetBackdropIn(panels, frame, active and theme or 'none', background, 'panel')
	local panel = panels[frame]
	if panel then
		panel:SetShown(active)
		if active then Round(panel) end
	end
	Fade(frame.NineSlice, active)
	Fade(frame.Bg, active)

	local title = frame.TitleContainer and frame.TitleContainer.TitleText
	PutFont(title, 'title', active, st:FontObject(st.config.profile.headers.font), false)
	StyleClose(frame, active)
	Layout(frame, active)
end

------------------------------------------------------------------ the rows

-- The quality of an item row, nil for a money row. Read the way Blizzard's
-- Init reads it, from GetLootSlotInfo for the row's slot: the element data's
-- quality (GetQuality) is made when the loot opens and is not replaced when a
-- slot changes (LOOT_SLOT_CHANGED runs Init again), so it can be stale. A
-- currency slot's quality is its container's, which Init takes from
-- CurrencyContainerUtil's wrapper of C_CurrencyInfo.GetCurrencyContainerInfo:
-- that C read is made here (guarded: both clients have it). The only Blizzard
-- Lua called is the row's GetSlotIndex, and GetQuality as the fallback, both
-- reads of the element data.
local function ElementQuality(element)
	if not element.QualityText then return end
	local ok, index = pcall(element.GetSlotIndex or error, element)
	if ok and type(index) == 'number' and GetLootSlotInfo then
		local _, _, quantity, currencyID, quality = GetLootSlotInfo(index)
		if currencyID and C_CurrencyInfo and C_CurrencyInfo.GetCurrencyContainerInfo then
			local info = C_CurrencyInfo.GetCurrencyContainerInfo(currencyID, quantity)
			if info and type(info.quality) == 'number' then return info.quality end
		elseif not currencyID then
			if type(quality) == 'number' then return quality end
			return Enum and Enum.ItemQuality and Enum.ItemQuality.Common or 1
		end
	end
	local quality
	ok, quality = pcall(element.GetQuality or error, element)
	if ok and type(quality) == 'number' then return quality end
end

-- The slot's border in the item's quality color, or the theme's own.
local function ColorSlot(element)
	local item = element.Item
	local backdrop = item and slots[item]
	if not backdrop then return end
	local color = st:QualityColor(ElementQuality(element))
	if color then
		st:SetBorderColor(backdrop, color.r, color.g, color.b)
	else
		st:SetBorderColor(backdrop)
	end
end

-- The card's tint while the mouse is over the row (the states' hover Layer; the
-- border stays the theme's). The holder takes no mouse of its own, so the row's
-- own enter and leave set it.
local function HoverCard(element)
	local holder = cards[element]
	if not holder or st:GetState(holder, 'hover') == nil then return end
	st:SetState(holder, 'hover', hovering[element] and true or false)
end

local function StyleCard(element, active)
	local holder = cards[element]
	if not holder then
		if not active then return end
		holder = st:CreateFrame('Frame', nil, element)
		cards[element] = holder
	end
	local theme, background = Look()
	if active then
		-- The holder is the card's inside: the theme's border is drawn outside
		-- it. It runs from ICON_GAP right of the icon to the row's right edge
		-- (its border inside the row), as tall as the icon, as a roll bar's
		-- does. Scaled back up from the rows' scale, so its offsets and border
		-- are in the window's own pixels.
		local inset = st:ThemeInset(theme, background, 'panel')
		holder:SetScale(1 / ROW_SCALE)
		holder:ClearAllPoints()
		holder:SetPoint('TOPLEFT', element.Item, 'TOPRIGHT', ICON_GAP, 0)
		holder:SetPoint('BOTTOMLEFT', element.Item, 'BOTTOMRIGHT', ICON_GAP, 0)
		holder:SetPoint('RIGHT', element, 'RIGHT', -inset, 0)
		-- One level under the row, so its own texts and the icon lie over the
		-- card; the card's backdrop is made one under that, and under the slot's.
		SetLevel(holder, element, -1)
	end
	st:SetBackdrop(holder, active and theme or 'none', background, 'panel')
	holder:SetShown(active)
	if active then
		Round(holder)
		Round(holder.backdrop)
		-- A row of states, the edge the theme's, no scripts (the holder takes no
		-- mouse); registered after the draw, which a later one restyles.
		st:AddStates(holder, 'row', { edge = false, wire = false })
		HoverCard(element)
	elseif st:GetState(holder, 'hover') ~= nil then
		st:SetState(holder, 'hover', false)
	end
end

local function StyleIcon(item, active)
	local icon = item.icon or item.Icon
	if not icon or not icon.SetTexCoord then return end
	if active then
		if not coords[icon] then
			coords[icon] = { icon:GetTexCoord() }
		end
		if not masks[icon] and icon.GetNumMaskTextures then
			local list = {}
			for i = 1, icon:GetNumMaskTextures() do list[i] = icon:GetMaskTexture(i) end
			masks[icon] = list
			for _, mask in ipairs(list) do icon:RemoveMaskTexture(mask) end
		end
		local width, height = icon:GetSize()
		local trim = st.config.profile.misc.icon_trim
		if issecretvalue(width) or issecretvalue(height) then width, height = nil, nil end
		icon:SetTexCoord(st:IconTexCoords(trim, width, height))
	else
		if coords[icon] then icon:SetTexCoord(unpack(coords[icon])) end
		if masks[icon] then
			for _, mask in ipairs(masks[icon]) do icon:AddMaskTexture(mask) end
			masks[icon] = nil
		end
	end
end

local function StyleSlot(element, active)
	local item = element.Item
	if not item then return end
	local theme, background = Look()
	st:SetBackdropIn(slots, item, active and theme or 'none', background, 'slot')
	local backdrop = slots[item]
	if backdrop then
		backdrop:SetShown(active)
		if active then
			-- In the window's own pixels, as the card (StyleCard).
			backdrop:SetScale(1 / ROW_SCALE)
			-- Over the card's, under the icon (the item's own level).
			SetLevel(backdrop, item, -1)
			Round(backdrop)
		end
	end
	if active then ColorSlot(element) end

	Fade(item.IconBorder, active)
	if item.GetNormalTexture then Fade(item:GetNormalTexture(), active) end
	if item.GetPushedTexture then Fade(item:GetPushedTexture(), active) end
	StyleIcon(item, active)
end

-- The name on one line from the card's left to its right, cut short with an
-- ellipsis when it is still too long; Blizzard's anchors, size, wrap and
-- vertical justify put back by a restore. The offsets are in the scaled row's
-- units, so TEXT_PAD is divided by the scale.
local function PlaceName(element, active)
	local text, holder = element.Text, cards[element]
	if not text or not text.SetPoint then return end
	if active and holder then
		if not texts[text] then
			local width, height = text:GetSize()
			texts[text] = {
				points = ReadPoints(text), width = width, height = height,
				wrap = text.CanWordWrap and text:CanWordWrap(), justify = text:GetJustifyV(),
			}
		end
		text:ClearAllPoints()
		text:SetPoint('LEFT', holder, 'LEFT', TEXT_PAD / ROW_SCALE, 0)
		text:SetPoint('RIGHT', holder, 'RIGHT', -TEXT_PAD / ROW_SCALE, 0)
		text:SetWordWrap(false)
		text:SetJustifyV('MIDDLE')
	elseif not active and texts[text] then
		local saved = texts[text]
		texts[text] = nil
		PutPoints(text, saved.points)
		text:SetSize(saved.width, saved.height)
		text:SetWordWrap(saved.wrap ~= false)
		text:SetJustifyV(saved.justify)
	end
end

-- The item button's click area over the whole card (Blizzard's reaches 157 past
-- the icon, its row's width less the icon in a 220 window), or Blizzard's back.
local function PlaceHit(element, active)
	local item = element.Item
	if not item.SetHitRectInsets then return end
	if active then
		if not hits[item] then hits[item] = { item:GetHitRectInsets() } end
		local row = (WINDOW_WIDTH - ROW_PAD) / ROW_SCALE - 2 * ROW_PAD
		item:SetHitRectInsets(0, -(row - ICON_RIGHT), 0, 0)
	elseif hits[item] then
		item:SetHitRectInsets(unpack(hits[item]))
		hits[item] = nil
	end
end

local function StyleElement(element, active)
	if not element.Item then return end -- a row with no item (an empty slot's)
	local font = active and ScaledFont() or nil

	Fade(element.NameFrame, active)
	Fade(element.BorderFrame, active)
	Fade(element.QualityStripe, active)
	Fade(element.QualityText, active)
	Fade(element.HighlightNameFrame, active)
	Fade(element.PushedNameFrame, active)

	StyleCard(element, active)
	StyleSlot(element, active)
	PlaceName(element, active)
	PlaceHit(element, active)

	PutFont(element.Text, 'name', active, font, true)
	PutFont(element.Item.Count, 'count', active, font, true)
end

local function HookElement(element)
	if hooked[element] then return end
	hooked[element] = true
	-- Blizzard runs Init again for a slot that changed (LOOT_SLOT_CHANGED): the
	-- quality, and so the border, may be different.
	if type(element.Init) == 'function' then
		hooksecurefunc(element, 'Init', function()
			if Active() and styled[element] then Apply(ColorSlot, element) end
		end)
	end
	local item = element.Item
	if item and item.HookScript then
		item:HookScript('OnEnter', function()
			hovering[element] = true
			if Active() and cards[element] then Apply(HoverCard, element) end
		end)
		item:HookScript('OnLeave', function()
			hovering[element] = nil
			if Active() and cards[element] then Apply(HoverCard, element) end
		end)
	end
end

-- The rows the scroll box holds now, shown or in its pool: its scroll target's
-- children, a C call.
local function Elements(frame)
	local target = frame.ScrollBox and frame.ScrollBox.ScrollTarget
	if not target or not target.GetChildren then return {} end
	return { target:GetChildren() }
end

------------------------------------------------------------------ the sweep

-- Styles the window and every row not yet styled this generation. Runs after
-- every Update of the scroll box (which is when a row is handed out or the
-- window scrolls), on the window's OnShow and on every change of a setting.
local function Sweep()
	local frame = _G.LootFrame
	if not frame or not frame.ScrollBox then return end
	-- A window some other addon made protected (through an anchor) is styled
	-- when combat ends.
	if not st:CanMoveNow(frame) then
		st:QueueAfterCombat('LootPopup', Sweep)
		return
	end
	local active = Active()
	if styled[frame] ~= generation then
		styled[frame] = generation
		Apply(StyleWindow, frame, active)
	end
	for _, element in ipairs(Elements(frame)) do
		if styled[element] ~= generation then
			-- A row first seen while the skin is off is not hooked (the hooks
			-- would do nothing): it is when the skin comes on. Marked styled
			-- only once it is, so a row whose styling errored is tried again.
			if active then Apply(HookElement, element) end
			local ok, err = xpcall(StyleElement, function(message) return message end, element, active)
			if ok then
				styled[element] = generation
				failed[element] = nil
			elseif failed[element] ~= generation then
				-- Tried again on the next update, reported once a generation.
				failed[element] = generation
				geterrorhandler()(err)
			end
		end
	end
end

local function Install()
	if installed then return end
	local frame = _G.LootFrame
	local scrollBox = frame and frame.ScrollBox
	-- Where the window has no scroll box (the classic one, on neither client
	-- today) there is nothing to skin.
	if not scrollBox or not scrollBox.ScrollTarget or type(scrollBox.Update) ~= 'function' then return end
	installed = true
	hooksecurefunc(scrollBox, 'Update', function() Apply(Sweep) end)
	-- Blizzard sizes the window in Resize (on every open) from its own row
	-- height: the compact layout sizes it again after.
	if type(frame.Resize) == 'function' then
		hooksecurefunc(frame, 'Resize', function()
			if not Active() then return end
			if not st:CanMoveNow(frame) then
				st:QueueAfterCombat('LootPopupLayout', function() Apply(Layout, frame, Active()) end)
				return
			end
			Apply(Layout, frame, true)
		end)
	end
	frame:HookScript('OnShow', function()
		Apply(Sweep)
		-- Laid out again whenever it shows (Layout skips a hidden window).
		if Active() and st:CanMoveNow(frame) then Apply(Layout, frame, true) end
	end)
end

------------------------------------------------------------------ the module

-- Puts the skin on, or Blizzard's window back, as the settings say now: on the
-- toggle, a theme, a profile or a font change.
function LT:UpdatePopup()
	if not Config() then return end
	generation = generation + 1
	if Config().enable then Install() end
	if installed then Apply(Sweep) end
end

-- Waits for Blizzard's window, then follows the settings (OnEnable).
function LT:InitializeLootFrame()
	st:OnBlizzardAddon('Blizzard_UIPanels_Game', function() self:UpdatePopup() end)
end

-- Colors of SaftUI's put again after a recolor or redraw took them off: a
-- slot's quality border and the close cross. A card's tint follows the Accent in
-- the states' own pass, so the Accent group isn't one of them.
function LT:ColorPopup(group)
	-- The group first: Active() resolves the theme, which makes a table.
	if group ~= 'theme' and group ~= 'item_quality' and group ~= 'text' then return end
	if not installed or not Active() then return end
	local frame = _G.LootFrame
	if not frame then return end
	for _, element in ipairs(Elements(frame)) do
		if styled[element] and element.Item then
			Apply(ColorSlot, element)
		end
	end
	local cross = frame.ClosePanelButton and closes[frame.ClosePanelButton]
	if cross then cross.icon:SetVertexColor(CloseColor(false)) end
end

-- A font setting changed: the texts take it, and so does the window's title.
function LT:OnFontsChanged()
	self:UpdatePopup()
end
