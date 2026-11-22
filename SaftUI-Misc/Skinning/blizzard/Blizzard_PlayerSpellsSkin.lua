local st = SaftUI
local SK = st:GetModule('Skinning')
local PS = SK:NewModule('Blizzard_PlayerSpellsSkin')

--[[
	Skins WoW Forever's talent window (PlayerSpellsFrame, Blizzard_PlayerSpells,
	Camelot) in SaftUI's look, while Skinning -> Talent window is on and the
	Skinning page's Theme isn't Blizzard. Off, or under the Blizzard theme, the
	window keeps Blizzard's look: every piece below is put back as it was, and
	SaftUI's pieces are hidden. Forever only: OnEnable hooks nothing on retail.

	The spec backgrounds stay Blizzard's: TalentsFrame's .Background,
	.ClassBackground, .OverlayBackgroundRight and .OverlayBackgroundMid (and the
	clouds and particles over them) are never touched. So are the talent buttons
	and the lines between them, the tree headers, the hero talents, the Reset and
	Undo icon buttons, the Maximize button, the Settings and Search options
	dropdown arrows, and the spellbook's page art.

	What changes (the parentKeys of Blizzard's XML, Camelot/Blizzard_PlayerSpellsFrame.xml,
	Camelot/ClassTalents/Blizzard_ClassTalentsFrame.xml and SharedXML's
	PortraitFrameTemplate, read 22 Nov from the forever branch of
	Gethe/wow-ui-source):
	  - PlayerSpellsFrame: SaftUI's panel behind it (st:SetBackdropIn, kind panel,
	    a child one level under it, anchored to the frame's own edges, so it
	    follows the width Blizzard and the compact layout (Blizzard_PlayerSpellsLayout.lua)
	    give the window, placed by the engine and not moved after); .NineSlice, .Bg, .TopTileStreaks and .PortraitContainer
	    (the portrait) faded; .TitleContainer.TitleText in the Window titles font,
	    centered on the window; .CloseButton's four textures faded under a box of
	    SaftUI's (kind close) with a Lucide X, inside the window's top edge (Camelot's
	    button is 28 square and sits 3 above it); .TabSystem's tabs (hidden on Forever,
	    where the tab system isn't available, but skinned all the same).
	  - TalentsFrame (.TalentsFrame): .BackgroundBorder (the gold frame), the two
	    horizontal dividers (.DividerHorizontalLeft and Right, the top bar's
	    ornament) and the two vertical dividers (.DividerVerticalLeft and Right)
	    faded by alpha, never hidden or moved (the compact layout anchors the
	    vertical dividers, the headers and the search box to them), and SaftUI's
	    lines drawn on a frame of its own: a line along the top bar's bottom, and one
	    under each vertical divider's top down to the art's bottom, so a move of the
	    .TabSystem (the spec tabs) as tabs; .SearchBox
	    as an edit box (the border's 20 high, centered in the template's 30 high box);
	    .ClassCurrencyDisplay (Unspent talents) with its .Border
	    faded and a box of SaftUI's where it was; .ApplyButton, .InspectCopyButton
	    and .ActiveSpec.ActivateButton as buttons. .LoadSystem (the loadout menu) is
	    left alone: Camelot hides it.
	  - SpellBookFrame (the same window's other tab): .SearchBox and
	    .CategoryTabSystem's tabs, the same as above. Those are icon tabs in square
	    mode (SetSquareMode), whose art is SquareBackground, SquareBackgroundActive and
	    SquareBackgroundActiveGlow: faded with the rest.
	  Buttons and the edit box are drawn as the color picker's are
	  (Blizzard_ColorPicker.lua): the art faded by alpha, a box of SaftUI's (a child
	  one level under the button) with the interaction states, the Skinning font.
	  A tab is a 'tab' state frame, selected as the tab is (a post-hook on its own
	  SetTabSelected).

	Taint (.agents/taint.md rules 1 to 3, 6, 23). PlayerSpellsFrame is protected on
	Forever: SpellBookFrame.AssistedCombatRotationSpellFrame.Button inherits
	SecureFrameTemplate, and protection spreads to its parents. So nothing is made,
	placed or shown on it in combat: StyleAll, and the styling of a tab the AddTab
	hook would do, wait for the end of combat (st:QueueAfterCombat), whole, so no
	tab is half-skinned. Post-hooks and HookScript only,
	each in xpcall to geterrorhandler() so an error never unwinds Blizzard's own
	code (Guarded); nothing is written onto a Blizzard frame or table (SaftUI's
	state is in weak tables keyed by Blizzard's frames); no function of Blizzard's
	is called but reads (GetAlpha, GetFont..., GetHeight, GetPoint, IsEnabled,
	tab.isSelected, system.tabs); widget calls only on regions whose alpha Blizzard
	never sets (checked in Blizzard_SharedXML's TabSystemTemplates.lua, the
	templates and this window's Lua: they only show and hide the tab pieces).
	Every step is nil-guarded so a region this client lacks skips its step.
	The hooks: hooksecurefunc on each tab system's AddTab (a tab acquired later)
	and on each tab's SetTabSelected; HookScript on the buttons, tabs and boxes'
	OnEnter, OnLeave, OnMouseDown, OnMouseUp, OnEnable, OnDisable and the search
	boxes' OnEditFocusGained and OnEditFocusLost, which only set states on
	SaftUI's own boxes.
]]

local BUTTON_ART = { 'Left', 'Middle', 'Right' }
local BOX_ART = { 'Left', 'Middle', 'Right' } -- InputBoxVisualTemplate's border
local TAB_ART = { 'Left', 'Middle', 'Right', 'LeftActive', 'MiddleActive', 'RightActive',
	'LeftHighlight', 'MiddleHighlight', 'RightHighlight',
	'SquareBackground', 'SquareBackgroundActive', 'SquareBackgroundActiveGlow' } -- the last three: icon tabs (square mode)
local WINDOW_ART = { 'NineSlice', 'Bg', 'TopTileStreaks', 'PortraitContainer' }
-- The gold frame and the dividers' ornaments (TalentsFrame's own regions).
local TALENT_ART = { 'BackgroundBorder', 'DividerHorizontalLeft', 'DividerHorizontalRight',
	'DividerVerticalLeft', 'DividerVerticalRight' }
local CLOSE_STATES = { 'GetNormalTexture', 'GetPushedTexture', 'GetHighlightTexture', 'GetDisabledTexture' }
-- The three state fonts UIPanelButtonNoTooltipTemplate gives a button.
local BUTTON_FONTS = {
	normal = { 'GetNormalFontObject', 'SetNormalFontObject', 'GameFontNormal' },
	highlight = { 'GetHighlightFontObject', 'SetHighlightFontObject', 'GameFontHighlight' },
	disabled = { 'GetDisabledFontObject', 'SetDisabledFontObject', 'GameFontDisable' },
}
local TITLE_DROP = 11 -- the title's center, down from the window's top: the middle of Blizzard's 20 high title bar (less a pixel)
local SEARCH_LEFT = 5 -- Blizzard's search border starts this far left of the box
local SEARCH_HEIGHT = 20 -- and is this high, centered in the template's 30 high box
local CLOSE_INSET = 3 -- the close box in from its 28 square button
local BAR_DROP = 4 -- DividerHorizontalLeft's TOP, down from the border's top (Camelot XML)

-- What SaftUI made or styled, keyed by Blizzard's frames (weak keys).
local weak = { __mode = 'k' }
local panels = setmetatable({}, weak)  -- PlayerSpellsFrame -> its panel (st:SetBackdropIn)
local boxes = setmetatable({}, weak)   -- button, tab, edit box, dropdown or display -> { box }
local alphas = setmetatable({}, weak)  -- region -> the alpha it had before SaftUI faded it
local saved = setmetatable({}, weak)   -- text or button -> the fonts (and color, anchors) Blizzard had
local hooked = setmetatable({}, weak)  -- frame -> true once its hooks are on
local hovered = setmetatable({}, weak) -- button -> true while the mouse is over it
local lines = setmetatable({}, weak)   -- TalentsFrame -> { holder, bar, left, right }

local installed, styled = false, false

local function Profile() return st.config.profile end

local function Look()
	local config = Profile().skinning
	return config.theme, config.background
end

-- Whether the window wears SaftUI's look now: the toggle on and the Skinning
-- page's look not Blizzard's. Forever only.
local function Active()
	if not st.forever then return false end
	local config = Profile().skinning
	return config.talent_window and not st:IsBlizzardLook(config.theme, config.background) or false
end
function PS:IsActive() return installed and Active() end

-- How far the panel behind the window reaches outside it, for the talent plan's
-- panel to stand clear of (it adds its own gap).
function PS:Inset()
	local theme, background = Look()
	return st:ThemeInset(theme, background, 'panel')
end

local function Apply(fn, ...) xpcall(fn, geterrorhandler(), ...) end

-- A hook runs in the middle of Blizzard's own code: an error in it would stop
-- the caller there, so each runs in xpcall to the error handler.
local function Guarded(fn)
	return function(...)
		local a, b, c = ...
		xpcall(function() fn(a, b, c) end, geterrorhandler())
	end
end

local function SkinFont() return st:FontObject(Profile().skinning.font) end
local function TitleFont() return st:FontObject(Profile().headers.font) end

-- A font object read from Blizzard, if it is a named global Font (the only
-- kind safe to set again: rule 10), else nil.
local function Named(font)
	local name = font and font.GetName and font:GetName()
	if name and _G[name] == font then return font end
end

------------------------------------------------------------------ art

-- Fades a region by alpha (Blizzard never sets these regions' alpha), or puts
-- back the alpha it had.
local function Fade(region, active)
	if not region or not region.SetAlpha then return end
	if active then
		if alphas[region] == nil then
			local alpha = region.GetAlpha and region:GetAlpha()
			if alpha == nil or issecretvalue(alpha) then alpha = 1 end
			alphas[region] = alpha
		end
		region:SetAlpha(0)
	elseif alphas[region] ~= nil then
		region:SetAlpha(alphas[region])
	end
end

local function FadeAll(parent, keys, active)
	if not parent then return end
	for _, key in ipairs(keys) do Fade(parent[key], active) end
end

-- SaftUI's font on a font string or edit box (anything with SetFontObject), or
-- what Blizzard had back. keepColor puts the color the text has now back after
-- the change (a font object's own color would replace it: a placeholder's grey,
-- or the enabled and disabled colors Blizzard gives a box), never a color read
-- earlier.
local function PutFont(target, active, title, keepColor, fallback)
	if not target or not target.SetFontObject then return end
	local r, g, b, a
	if keepColor and target.GetTextColor then
		r, g, b, a = target:GetTextColor()
		if issecretvalue(r) then r = nil end
	end
	if active then
		if not saved[target] then
			saved[target] = { font = Named(target.GetFontObject and target:GetFontObject()) }
		end
		local font = title and TitleFont() or SkinFont()
		if font then target:SetFontObject(font) end
	elseif saved[target] then
		local font = saved[target].font or (fallback and _G[fallback])
		if font then target:SetFontObject(font) end
	end
	if r then target:SetTextColor(r, g, b, a) end
end

------------------------------------------------------------------ boxes

-- SaftUI's box for a Blizzard frame: a frame of SaftUI's, the target's child one
-- level under it, so the target's own texts and icons lie over it, with the
-- interaction states of shape ('box' or 'tab', not wired: the hooks below say
-- when the mouse is over). Kept in the weak table, nothing written onto target.
local function GetBox(target, shape, opts)
	local entry = boxes[target]
	if entry then return entry end
	local box = st:CreateFrame('Frame', nil, target)
	local level = target:GetFrameLevel()
	if not issecretvalue(level) then box:SetFrameLevel(math.max(0, level - 1)) end
	entry = { box = box }
	boxes[target] = entry
	local states = { wire = false }
	if shape == 'box' then states.edge = 'theme' end
	for key, value in pairs(opts or {}) do states[key] = value end
	if shape == 'tab' then
		st:AddStates(box, 'tab', states)
	else
		st:AddStates(box, 'box', states)
	end
	return entry
end

-- Draws target's box in the Skinning look as kind, placed by place(box), or
-- hides it. Returns the entry (nil when there is none to hide).
local function DrawBox(target, active, shape, kind, place, opts)
	local entry = boxes[target]
	if not entry then
		if not active then return end
		entry = GetBox(target, shape, opts)
	end
	local theme, background = Look()
	st:SetTemplate(entry.box, active and theme or 'none', background, kind)
	entry.box:SetShown(active)
	if active then
		entry.box:ClearAllPoints()
		place(entry.box)
	end
	-- after the theme drew the box: the states read its look again
	st:RestyleStates(entry.box)
	return entry
end

local function SetHover(target)
	local entry = boxes[target]
	if not entry or st:GetState(entry.box, 'hover') == nil then return end
	st:SetState(entry.box, 'hover', Active() and hovered[target] or false)
end

local function SetPushed(target, on)
	local entry = boxes[target]
	if not entry or st:GetState(entry.box, 'pushed') == nil then return end
	st:SetState(entry.box, 'pushed', on and Active() or false)
end

-- Hover and press on target's box, post-hooks that only set states on SaftUI's
-- own frame (the game passes a motion argument to OnEnter and OnLeave).
local function HookMouse(target, pressed)
	if hooked[target] or not target.HookScript then return end
	hooked[target] = true
	target:HookScript('OnEnter', Guarded(function(self) hovered[self] = true; SetHover(self) end))
	target:HookScript('OnLeave', Guarded(function(self) hovered[self] = nil; SetHover(self) end))
	if pressed then
		target:HookScript('OnMouseDown', Guarded(function(self, mouse)
			if mouse == nil or mouse == 'LeftButton' then SetPushed(self, true) end
		end))
		target:HookScript('OnMouseUp', Guarded(function(self) SetPushed(self, false) end))
	end
end

local function Fill(target)
	return function(box)
		box:SetPoint('TOPLEFT', target, 'TOPLEFT', 0, 0)
		box:SetPoint('BOTTOMRIGHT', target, 'BOTTOMRIGHT', 0, 0)
	end
end

------------------------------------------------------------------ the pieces

-- A UIPanelButtonTemplate button (Apply, Copy, Activate): the art faded, a box
-- of SaftUI's inside it, the three state fonts in the Skinning font, and the
-- box dimmed while the button is disabled.
local function SyncDisabled(button)
	local entry = boxes[button]
	if entry and st:GetState(entry.box, 'disabled') ~= nil then
		st:SetState(entry.box, 'disabled', Active() and button.IsEnabled and not button:IsEnabled() or false)
	end
end

local function StyleButton(button, active)
	if not button then return end
	if not boxes[button] and not active then return end
	local entry = DrawBox(button, active, 'box', 'control', Fill(button))
	if entry and active and not saved[button] then
		local fonts = {}
		for state, methods in pairs(BUTTON_FONTS) do
			if button[methods[1]] then fonts[state] = Named(button[methods[1]](button)) end
		end
		saved[button] = fonts
	end
	if active and not hooked[button] and button.HookScript then
		HookMouse(button, true)
		button:HookScript('OnEnable', Guarded(SyncDisabled))
		button:HookScript('OnDisable', Guarded(SyncDisabled))
	end
	hovered[button] = hovered[button] and active or nil
	if not active then SetPushed(button, false) end
	SetHover(button)
	SyncDisabled(button)
	FadeAll(button, BUTTON_ART, active)
	local highlight = button.GetHighlightTexture and button:GetHighlightTexture()
	Fade(highlight, active)
	for state, methods in pairs(BUTTON_FONTS) do
		if button[methods[2]] then
			local font = active and SkinFont() or (saved[button] and saved[button][state]) or _G[methods[3]]
			if font then button[methods[2]](button, font) end
		end
	end
end

-- A tab (TabSystemButtonArtTemplate): its nine pieces of art faded, a tab-shaped
-- box in the Skinning look that shows the tab's own selected flag, put on by
-- SetTabSelected's post-hook.
local function SyncTab(tab)
	local entry = boxes[tab]
	if not entry or st:GetState(entry.box, 'selected') == nil then return end
	local selected = Active() and tab.isSelected == true or false
	st:SetState(entry.box, 'selected', selected)
	-- A tab the game disabled (a locked spec) is dimmed and takes no hover; a
	-- selected tab is disabled too, but is the one that shows selected.
	st:SetState(entry.box, 'disabled', Active() and not selected and tab.IsEnabled and not tab:IsEnabled() or false)
end

local function StyleTab(tab, active)
	if not tab then return end
	if not boxes[tab] and not active then return end
	DrawBox(tab, active, 'tab', 'control', Fill(tab))
	if active and not hooked[tab] and tab.SetTabSelected then
		hooksecurefunc(tab, 'SetTabSelected', Guarded(SyncTab))
	end
	if active and not hooked[tab] and tab.SetTabEnabled then
		hooksecurefunc(tab, 'SetTabEnabled', Guarded(SyncTab))
	end
	if active then HookMouse(tab, false) end
	hovered[tab] = hovered[tab] and active or nil
	SetHover(tab)
	SyncTab(tab)
	FadeAll(tab, TAB_ART, active)
end

local function StyleTabs(system, active)
	if not system or type(system.tabs) ~= 'table' then return end
	for _, tab in ipairs(system.tabs) do Apply(StyleTab, tab, active) end
end

-- A tab acquired after the skin: the system's own AddTab, post-hooked once.
local function HookTabSystem(system)
	if not system or hooked[system] or not system.AddTab then return end
	hooked[system] = true
	hooksecurefunc(system, 'AddTab', Guarded(function(self)
		if not Active() or type(self.tabs) ~= 'table' then return end
		if PS:Deferred() then return end
		StyleTab(self.tabs[#self.tabs], true)
	end))
end

-- An edit box (SearchBoxTemplate): the border faded, a box of SaftUI's behind it
-- (the Accent edge while it has focus), the Skinning font on its text and its
-- placeholder.
local function SetFocus(box, on)
	local entry = boxes[box]
	if entry and st:GetState(entry.box, 'focus') ~= nil then
		st:SetState(entry.box, 'focus', on and Active() or false)
	end
end

local function StyleSearchBox(box, active)
	if not box then return end
	if not boxes[box] and not active then return end
	DrawBox(box, active, 'box', 'control', function(frame)
		local height = box.GetHeight and box:GetHeight()
		local drop = height and not issecretvalue(height) and math.max(0, (height - SEARCH_HEIGHT) / 2) or 0
		frame:SetPoint('TOPLEFT', box, 'TOPLEFT', -SEARCH_LEFT, -drop)
		frame:SetPoint('BOTTOMRIGHT', box, 'BOTTOMRIGHT', 0, drop)
	end)
	if active and not hooked[box] and box.HookScript then
		hooked[box] = true
		box:HookScript('OnEditFocusGained', Guarded(function(self) SetFocus(self, true) end))
		box:HookScript('OnEditFocusLost', Guarded(function(self) SetFocus(self, false) end))
	end
	FadeAll(box, BOX_ART, active)
	PutFont(box, active, false, true, 'GameFontHighlightSmall')
	PutFont(box.Instructions, active, false, true, 'GameFontDisableSmall')
	SetFocus(box, active and box.HasFocus and box:HasFocus() or false)
end

-- Unspent talents: its Border (a texture) faded, a box where it was.
local function StyleCurrency(display, active)
	if not display then return end
	local border = display.Border
	if not boxes[display] and not active then return end
	if active and not border then return end
	DrawBox(display, active, 'box', 'control', function(frame)
		frame:SetPoint('TOPLEFT', border, 'TOPLEFT', 0, 0)
		frame:SetPoint('BOTTOMRIGHT', border, 'BOTTOMRIGHT', 0, 0)
	end)
	Fade(border, active)
end

-- The close button: its four textures faded, a box of SaftUI's (kind close) with
-- Lucide's X in the muted text color, tinted by the states.
local closeGlyphs = setmetatable({}, weak)
local function StyleClose(button, active)
	if not button then return end
	if not boxes[button] and not active then return end
	local entry = boxes[button]
	if not entry and active then
		entry = GetBox(button, 'box')
		local x = entry.box:CreateTexture(nil, 'OVERLAY')
		x:SetTexture(st.icons.x)
		x:SetSize(20, 20) -- Lucide's x is a 10 px cross in the middle of its 20
		x:SetPoint('CENTER', 0, 0)
		closeGlyphs[button] = x
		st:AddStates(entry.box, 'box', { glyph = x, glyphRest = function() return st:Color('text', 'muted'):GetRGB() end })
	end
	-- Camelot's button is 28 square and sits 3 above the window's top: the box is
	-- the part inside it, 3 in from the other sides, so it stays inside the panel.
	DrawBox(button, active, 'box', 'close', function(frame)
		frame:SetPoint('TOPLEFT', button, 'TOPLEFT', CLOSE_INSET, -CLOSE_INSET)
		frame:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -CLOSE_INSET, CLOSE_INSET)
	end)
	if active then HookMouse(button, true) end
	hovered[button] = hovered[button] and active or nil
	SetHover(button)
	if closeGlyphs[button] then closeGlyphs[button]:SetShown(active) end
	for _, getter in ipairs(CLOSE_STATES) do
		Fade(button[getter] and button[getter](button), active)
	end
end

-- The title: Window titles' font, centered on the window (the portrait it left
-- room for is gone). Blizzard's three anchors are read once and put back.
local function StyleTitle(window, active)
	local container = window.TitleContainer
	local text = container and container.TitleText
	if not text then return end
	PutFont(text, active, true, false, 'GameFontNormal')
	if not text.GetPoint then return end
	if active then
		if not saved[text] then return end
		if not saved[text].points then
			local points = {}
			for i = 1, text:GetNumPoints() do points[i] = { text:GetPoint(i) } end
			saved[text].points = points
		end
		text:ClearAllPoints()
		text:SetPoint('CENTER', window, 'TOP', 0, -TITLE_DROP)
	elseif saved[text] and saved[text].points then
		text:ClearAllPoints()
		for _, point in ipairs(saved[text].points) do text:SetPoint(unpack(point)) end
	end
end

local function StyleWindow(window, active)
	local theme, background = Look()
	st:SetBackdropIn(panels, window, active and theme or 'none', background, 'panel')
	local panel = panels[window]
	if panel then
		panel:SetShown(active)
	end
	FadeAll(window, WINDOW_ART, active)
	StyleTitle(window, active)
	StyleClose(window.CloseButton, active)
	StyleTabs(window.TabSystem, active)
end

------------------------------------------------------------------ dividers

local function BorderColor()
	local theme = Look()
	return st:ThemeBorderColor(theme)
end

local function PaintLines(set)
	local r, g, b = BorderColor()
	if not r then return end
	for _, key in ipairs({ 'bar', 'left', 'right' }) do
		if set[key] then set[key]:SetColorTexture(r, g, b, 1) end
	end
end

-- SaftUI's lines where the ornaments were: a flat line along the top bar's
-- bottom, and one along each vertical divider (anchored to the divider, so the compact layout's move of it moves the line).
local function StyleLines(talents, active)
	local set = lines[talents]
	if not set then
		if not active then return end
		local border = talents.BackgroundBorder
		if not border then return end
		local holder = st:CreateFrame('Frame', nil, talents)
		holder:SetAllPoints(talents)
		set = { holder = holder }
		lines[talents] = set
		for _, key in ipairs({ 'bar', 'left', 'right' }) do
			set[key] = holder:CreateTexture(nil, 'ARTWORK')
		end
	end
	set.holder:SetShown(active)
	if not active then return end
	local border = talents.BackgroundBorder
	local line = st:DrawLineSize(set.holder)
	local height = talents.DividerHorizontalLeft and talents.DividerHorizontalLeft.GetHeight and talents.DividerHorizontalLeft:GetHeight()
	if not height or issecretvalue(height) then height = 24 end
	local y = -(BAR_DROP + height / 2)
	set.bar:ClearAllPoints()
	set.bar:SetPoint('TOPLEFT', border, 'TOPLEFT', 0, y)
	set.bar:SetPoint('TOPRIGHT', border, 'TOPRIGHT', 0, y)
	set.bar:SetHeight(line)
	for key, divider in pairs({ left = talents.DividerVerticalLeft, right = talents.DividerVerticalRight }) do
		local texture = set[key]
		texture:ClearAllPoints()
		if divider then
			-- both points on the divider, so the line is on its x (the compact
			-- layout moves the divider), and as tall as its art
			texture:SetPoint('TOP', divider, 'TOP', 0, 0)
			texture:SetPoint('BOTTOM', divider, 'BOTTOM', 0, 0)
			texture:SetWidth(line)
			texture:Show()
		else
			texture:Hide()
		end
	end
	PaintLines(set)
end

local function StyleTalents(talents, active)
	FadeAll(talents, TALENT_ART, active)
	StyleLines(talents, active)
	StyleTabs(talents.TabSystem, active)
	StyleSearchBox(talents.SearchBox, active)
	StyleCurrency(talents.ClassCurrencyDisplay, active)
	StyleButton(talents.ApplyButton, active)
	StyleButton(talents.InspectCopyButton, active)
	local spec = talents.ActiveSpec
	StyleButton(spec and spec.ActivateButton, active)
end

local function StyleSpellBook(book, active)
	StyleSearchBox(book.SearchBox, active)
	StyleTabs(book.CategoryTabSystem, active)
end

------------------------------------------------------------------ all of it

-- In combat the window is protected (see the header): says so and queues a
-- whole pass for the end of combat.
function PS:Deferred()
	local window = _G.PlayerSpellsFrame
	if InCombatLockdown() and window and window.IsProtected and window:IsProtected() then
		st:QueueAfterCombat('playerspellsskin', function() PS:StyleAll() end)
		return true
	end
	return false
end

-- Puts the look on the window, or Blizzard's back (only once SaftUI has styled
-- it: with the toggle off at load, or under the Blizzard theme, it is never
-- touched). Widget calls only, on frames that aren't protected.
function PS:StyleAll()
	local window = _G.PlayerSpellsFrame
	if not window then return end
	local active = Active()
	if not active and not styled then return end
	if self:Deferred() then return end
	styled = true
	Apply(StyleWindow, window, active)
	if window.TalentsFrame then Apply(StyleTalents, window.TalentsFrame, active) end
	if window.SpellBookFrame then Apply(StyleSpellBook, window.SpellBookFrame, active) end
end

-- Hooks the tab systems (a tab acquired later is skinned as it is made), then
-- styles.
function PS:Install()
	local window = _G.PlayerSpellsFrame
	if installed or not window then return end
	installed = true
	HookTabSystem(window.TabSystem)
	if window.TalentsFrame then HookTabSystem(window.TalentsFrame.TabSystem) end
	if window.SpellBookFrame then HookTabSystem(window.SpellBookFrame.CategoryTabSystem) end
	self:StyleAll()
end

-- A profile change, the Skinning page's Theme, Background or font: the look
-- again, or Blizzard's, at once. The toggle itself takes a reload.
function PS:UpdateConfig()
	if installed then
		self:StyleAll()
		self:PlaceTalentPlan()
	end
end

-- The talent plan's panel stands clear of the window's border (PS:Inset under the
-- skin, Blizzard's art otherwise): it places itself again after a look change.
function PS:PlaceTalentPlan()
	local ok, TP = pcall(st.GetModule, st, 'TalentPlan')
	if ok and TP and TP.panel and TP.Place and not (InCombatLockdown() and TP.panel:IsProtected()) then
		Apply(TP.Place, TP)
	end
end

-- A theme recolor: the lines take the border color again.
function PS:OnColorsChanged(group)
	if not installed or not styled or group ~= 'theme' or not Active() then return end
	for _, set in pairs(lines) do PaintLines(set) end
end

-- A shared font or a font setting changed: the title and the texts take it again.
function PS:OnFontsChanged()
	if installed then self:StyleAll() end
end

-- Off (Skinning -> Talent window), and on retail, nothing is hooked or touched:
-- Blizzard's look stays until a reload with it on.
function PS:OnEnable()
	if not st.forever then return end
	if not Profile().skinning.talent_window then return end
	st:OnBlizzardAddon('Blizzard_PlayerSpells', function() self:Install() end)
end
