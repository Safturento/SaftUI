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
	no ScrollBox. The two clients differ only in the gamepad pieces (Forever's
	FrameGlow and jump hints, its `acquiredFromItem` and smart navigation code),
	which the skin never touches.
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
	  - Each row: a card of SaftUI's (kind panel) in place of .NameFrame,
	    .BorderFrame, .QualityStripe and the click textures, all faded; the card's
	    border takes the accent while the mouse is over the row. The icon in a
	    slot of SaftUI's (st:SetBackdropIn on .Item, kind slot) whose border is the
	    item's quality color (st:QualityColor), with .IconBorder, the normal and
	    pushed textures faded, the icon cropped by Icon zoom and its round mask
	    taken off. The texts (.Text, .QualityText, the count) in the Loot window's
	    Font.
	Left as Blizzard's: the scroll bar, the shadows at the scroll box's edges,
	the quest and profession overlays on an icon, a row's text color (Blizzard's
	quality color, put on in Init), the gamepad pieces and where the window is.

	Taint (.agents/taint.md). Loot buttons are clicked in combat all the time and
	the window is Blizzard's, so it is only looked at: nothing is written onto
	LootFrame, its rows or their regions (SaftUI's pieces live in weak tables
	here, keyed by Blizzard's frames, or are frames and textures SaftUI made), no
	script is set or replaced, and none of Blizzard's functions that write run from
	here (the one Blizzard function called is the row's GetQuality, a read).
	Blizzard's widgets get C method calls only: alpha on regions whose alpha
	Blizzard never sets (the NineSlice, Bg, the card, the click textures, the
	icon's border and normal and pushed textures, the close button's textures),
	fonts (SetFontObject, which is not a protected function:
	.agents/taint.md rule 1), tex coords and masks on the icon, and the made
	child frames and textures. The hooks are post-hooks only: `hooksecurefunc` on
	the scroll box's Update (which Blizzard calls after it has acquired a row
	for any reason) and on each row's Init (which Blizzard calls again on
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
	quality = 'GameFontWhiteTiny2',    -- QualityText
	count = 'NumberFontNormal',        -- ItemButton's Count
}

-- The close button's four state textures (Button's C getters).
local CLOSE_TEXTURES = { 'GetNormalTexture', 'GetPushedTexture', 'GetDisabledTexture', 'GetHighlightTexture' }
local CLOSE_ICON = 20 -- Lucide's x is a 10 px cross in the middle of its 20

-- What SaftUI made or changed, keyed by Blizzard's frames and regions (weak
-- keys: nothing is written onto them to remember it).
local weak = { __mode = 'k' }
local panels = setmetatable({}, weak)   -- LootFrame -> SaftUI's panel (st:SetBackdropIn)
local cards = setmetatable({}, weak)    -- element -> the holder of its card (SaftUI's frame, drawn with st:SetBackdrop)
local slots = setmetatable({}, weak)    -- .Item -> its slot's backdrop (st:SetBackdropIn)
local closes = setmetatable({}, weak)   -- .ClosePanelButton -> { frame, icon }, SaftUI's cross
local hooked = setmetatable({}, weak)   -- frame -> true once its hooks are on
local styled = setmetatable({}, weak)   -- element -> the generation it was last styled in
local hovering = setmetatable({}, weak) -- element -> true while the mouse is over its .Item
-- What Blizzard had before the first restyle, read then and put back by a
-- restore: a region's alpha, a text's font, an icon's tex coords and masks.
local alphas = setmetatable({}, weak)
local fonts = setmetatable({}, weak)
local coords = setmetatable({}, weak)
local masks = setmetatable({}, weak)

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

-- SaftUI's font on a font string, or what Blizzard had back.
local function PutFont(target, kind, active, font)
	if not target or not target.SetFontObject then return end
	if active then
		if fonts[target] == nil then
			fonts[target] = { font = Named(target.GetFontObject and target:GetFontObject()) }
		end
		if font then target:SetFontObject(font) end
	elseif fonts[target] then
		local original = fonts[target].font or _G[BLIZZARD_FONTS[kind]]
		if original then target:SetFontObject(original) end
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

------------------------------------------------------------------ the window

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
	PutFont(title, 'title', active, st:FontObject(st.config.profile.headers.font))
	StyleClose(frame, active)
end

------------------------------------------------------------------ the rows

-- The quality of an item row, nil for a money row. GetQuality is Blizzard's
-- (the element data's), a read.
local function ElementQuality(element)
	if not element.QualityText or type(element.GetQuality) ~= 'function' then return end
	local ok, quality = pcall(element.GetQuality, element)
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

-- The card's border, the accent while the mouse is over the row.
local function ColorCard(element)
	local holder = cards[element]
	local backdrop = holder and holder.backdrop
	if not backdrop then return end
	if hovering[element] then
		st:SetBorderColor(backdrop, st:Color('accent'):GetRGB())
	else
		st:SetBorderColor(backdrop)
	end
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
		-- it, so the border reaches the row's edge and no further.
		local inset = st:ThemeInset(theme, background, 'panel')
		holder:ClearAllPoints()
		holder:SetPoint('TOPLEFT', element, 'TOPLEFT', inset, -inset)
		holder:SetPoint('BOTTOMRIGHT', element, 'BOTTOMRIGHT', -inset, inset)
		-- One level under the row, so its own texts and the icon lie over the
		-- card; the card's backdrop is made one under that, and under the slot's.
		SetLevel(holder, element, -1)
	end
	st:SetBackdrop(holder, active and theme or 'none', background, 'panel')
	holder:SetShown(active)
	if active then
		Round(holder)
		Round(holder.backdrop)
		ColorCard(element)
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
	if active and not slots[item] then st:MarkForeign(item) end
	st:SetBackdropIn(slots, item, active and theme or 'none', background, 'slot')
	local backdrop = slots[item]
	if backdrop then
		backdrop:SetShown(active)
		if active then
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

local function StyleElement(element, active)
	if not element.Item then return end -- a row with no item (an empty slot's)
	local font = st:FontObject(Config().font)

	Fade(element.NameFrame, active)
	Fade(element.BorderFrame, active)
	Fade(element.QualityStripe, active)
	Fade(element.HighlightNameFrame, active)
	Fade(element.PushedNameFrame, active)

	StyleCard(element, active)
	StyleSlot(element, active)

	PutFont(element.Text, 'name', active, font)
	PutFont(element.QualityText, 'quality', active, font)
	PutFont(element.Item.Count, 'count', active, font)
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
			if Active() and cards[element] then Apply(ColorCard, element) end
		end)
		item:HookScript('OnLeave', function()
			hovering[element] = nil
			if Active() and cards[element] then Apply(ColorCard, element) end
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
			styled[element] = generation
			Apply(HookElement, element)
			Apply(StyleElement, element, active)
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
	frame:HookScript('OnShow', function() Apply(Sweep) end)
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
-- slot's quality border, a card's hover and the close cross.
function LT:ColorPopup(group)
	if not installed or not Active() then return end
	if group ~= 'theme' and group ~= 'item_quality' and group ~= 'accent' and group ~= 'text' then return end
	local frame = _G.LootFrame
	if not frame then return end
	for _, element in ipairs(Elements(frame)) do
		if styled[element] and element.Item then
			Apply(ColorSlot, element)
			Apply(ColorCard, element)
		end
	end
	local cross = frame.ClosePanelButton and closes[frame.ClosePanelButton]
	if cross then cross.icon:SetVertexColor(CloseColor(false)) end
end

-- A font setting changed: the texts take it, and so does the window's title.
function LT:OnFontsChanged()
	self:UpdatePopup()
end
