--[[
	Blizzard's talent window (Blizzard_PlayerSpells), as far as the talent plan
	reads it. Load it with `local PSF = load_test_file('misc/fixtures/player_spells_frame.lua')`,
	then PSF.build(opts) makes what the addon makes when it loads, from the
	trees stub.traits holds (tests/wow/traits.lua, filled by the shaman
	fixture's SH.install, which comes first):

	  - PlayerSpellsFrame (Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.xml,
	    forever and live): 1218 by 708, TOP of UIParent at 0, -41, hidden, with
	    IsInspecting, SetInspecting(unit) and ClearInspectUnit
	    (Blizzard_PlayerSpellsFrame.lua; the state is _inspecting).
	  - .TalentsFrame (Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua,
	    ClassTalentsFrameMixin): 1212 by 681, BOTTOM 0, 4, hidden, with GetTab
	    (TabSystemOwnerMixin: the spec group, _tab, 1) and SetTab, which does
	    nothing while inspecting, as the game's; GetConfigID and GetTalentTreeID
	    (Blizzard_SharedTalentUI/Blizzard_SharedTalentFrame.lua,
	    TalentFrameBaseMixin); GetTalentButtonByNodeID and
	    EnumerateAllTalentButtons (the same file; the game's iterator is a pool's
	    EnumerateActive, which gives each button as its first value), and
	    .ButtonsParent.
	  - One 40 by 40 Button per node of the tree (the trees PSF.build reads), under
	    ButtonsParent, laid in a grid, at frame level 5110, with GetNodeID (_node)
	    and an OnClick that counts PSF.clicks[nodeID] (the game's buttons buy a
	    rank there; the fixture only counts, so a test shows a plan never clicked
	    one).

	Every frame here is locked (lib/locked_widget.lua, owner 'Blizzard'), so a
	talent plan that writes a field onto one, or SetScripts one, fails. The
	fixture's own writes use rawset or a key starting with '_'.

	  PSF.load()    sets stub.loaded_addons.Blizzard_PlayerSpells and fires
	                ADDON_LOADED, as the game does once the addon's files ran.
	  PSF.open()    shows both frames, the way ShowUIPanel and SetTab do.
	  PSF.redraw()  EventRegistry's 'TalentFrameBase.ButtonsUpdated' (the tree id),
	                which TalentFrameBaseMixin:UpdateTreeInfo triggers (line 277).
	  PSF.rebind(button, nodeID)  gives a pooled button another node, as
	                TalentButtonUtil's pool does when it hands one out again.

	PSF.build_chrome() builds a window of its own (no trait stubs needed) with the
	chrome SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsSkin.lua skins,
	under the parentKeys of Blizzard's XML (Camelot/Blizzard_PlayerSpellsFrame.xml,
	Camelot/ClassTalents/Blizzard_ClassTalentsFrame.xml, SharedXML's
	PortraitFrameTemplate, TabSystemButtonArtTemplate, UIPanelButtonTemplate,
	InputBoxVisualTemplate and Blizzard_Menu's WowStyle1DropdownTemplate; checked
	22 Nov against the forever branch of Gethe/wow-ui-source). PSF.specart lists
	the spec backgrounds that must stay as they are, PSF.alphas() their alphas;
	PSF.window, PSF.talents and PSF.book are the three frames.

	Not built: the tab system, the loadout and spec buttons, the other tabs of
	PlayerSpellsFrame, the lines between buttons, the search box, the hero
	talent container, the config's staged changes.
]]
local lock_widget = load_test_file('lib/locked_widget.lua')
local OWNER = 'Blizzard'

local PSF = { clicks = {} }

local COLUMNS = 8
local BUTTON = 40

function PSF.build(opts)
	opts = opts or {}
	PSF.clicks = {}
	local buttons, byNode = {}, {}
	PSF.buttons = buttons

	local window = CreateFrame('Frame', 'PlayerSpellsFrame', UIParent)
	window:SetSize(1218, 708)
	window:SetPoint('TOP', UIParent, 'TOP', 0, -41)
	window:Hide()

	local talents = CreateFrame('Frame', nil, window)
	talents:SetSize(1212, 681)
	talents:SetPoint('BOTTOM', window, 'BOTTOM', 0, 4)
	talents:Hide()

	local parent = CreateFrame('Frame', nil, talents)
	parent:SetAllPoints(talents)

	local function configOf(tab)
		return stub.traits.group_configs[tab]
	end

	rawset(window, 'TalentsFrame', talents)
	rawset(window, '_inspecting', nil)
	rawset(window, 'IsInspecting', function(self) return self._inspecting ~= nil end)
	rawset(window, 'SetInspecting', function(self, unit) rawset(self, '_inspecting', unit) end)
	rawset(window, 'ClearInspectUnit', function(self) rawset(self, '_inspecting', nil) end)

	rawset(talents, '_tab', 1)
	rawset(talents, 'GetTab', function(self) return self._tab end)
	rawset(talents, 'SetTab', function(self, tab)
		if window:IsInspecting() then return end
		rawset(self, '_tab', tab)
	end)
	rawset(talents, 'GetConfigID', function(self) return configOf(self._tab) end)
	rawset(talents, 'GetTalentTreeID', function(self)
		local config = configOf(self._tab) or C_ClassTalents.GetActiveConfigID()
		local info = config and C_Traits.GetConfigInfo(config)
		return info and info.treeIDs and info.treeIDs[1]
	end)
	rawset(talents, 'GetTalentButtonByNodeID', function(self, nodeID) return byNode[nodeID] end)
	rawset(talents, 'EnumerateAllTalentButtons', function()
		local i = 0
		return function()
			i = i + 1
			return buttons[i]
		end
	end)
	rawset(talents, 'ButtonsParent', parent)

	-- one button a node, as the tree reads (the first config's tree)
	local config = configOf(1)
	local info = config and C_Traits.GetConfigInfo(config)
	local tree = info and info.treeIDs and info.treeIDs[1]
	for i, nodeID in ipairs(tree and C_Traits.GetTreeNodes(tree) or {}) do
		local button = CreateFrame('Button', nil, parent)
		button:SetSize(BUTTON, BUTTON)
		local row, col = math.floor((i - 1) / COLUMNS), (i - 1) % COLUMNS
		button:SetPoint('TOPLEFT', parent, 'TOPLEFT', 20 + col * (BUTTON + 20), -(20 + row * (BUTTON + 20)))
		button:SetFrameLevel(5110)
		rawset(button, '_node', nodeID)
		rawset(button, 'GetNodeID', function(self) return self._node end)
		button:SetScript('OnClick', function(self)
			PSF.clicks[self._node] = (PSF.clicks[self._node] or 0) + 1
		end)
		buttons[#buttons + 1] = button
		byNode[nodeID] = button
		lock_widget(button, OWNER)
	end

	-- PortraitFrameTemplate's close button (Blizzard_SharedXML ButtonFrameTemplate,
	-- parentKey CloseButton), 28 square at TOPRIGHT 0, 3 (Camelot's
	-- UIPanelCloseButtonDefaultAnchorsMixin:OnLoad).
	local close = CreateFrame('Button', nil, window)
	close:SetSize(28, 28)
	close:SetPoint('TOPRIGHT', window, 'TOPRIGHT', 0, 3)
	rawset(window, 'CloseButton', close)
	lock_widget(close, OWNER)
	PSF.window, PSF.talents, PSF.parent = window, talents, parent
	lock_widget(parent, OWNER)
	lock_widget(talents, OWNER)
	lock_widget(window, OWNER)
	PSF.byNode = byNode
	return window
end

function PSF.load()
	stub.loaded_addons.Blizzard_PlayerSpells = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_PlayerSpells')
end

function PSF.open()
	PSF.window:Show()
	PSF.talents:Show()
end

function PSF.redraw()
	EventRegistry:TriggerEvent('TalentFrameBase.ButtonsUpdated', PSF.talents:GetTalentTreeID())
end

function PSF.rebind(button, nodeID)
	local old = button._node
	if PSF.byNode[old] == button then PSF.byNode[old] = nil end
	rawset(button, '_node', nodeID)
	PSF.byNode[nodeID] = button
end

------------------------------------------------------------------ the chrome

local function texture(parent, key, layer, alpha)
	local t = parent:CreateTexture(nil, layer or 'ARTWORK')
	rawset(parent, key, t)
	if alpha then t:SetAlpha(alpha) end
	return t
end

local function frame(parent, key, kind)
	local f = CreateFrame(kind or 'Frame', nil, parent)
	rawset(parent, key, f)
	return f
end

-- The named fonts the templates use; the stubs have only some (made when the
-- window is, as a fresh world drops the globals).
local function make_fonts()
	for _, name in ipairs({ 'GameFontNormal', 'GameFontHighlight', 'GameFontDisable', 'GameFontHighlightSmall',
			'GameFontDisableSmall' }) do
		if not _G[name] then
			local font = CreateFont(name)
			font:SetFont([[Fonts\FRIZQT__.TTF]], 12, '')
		end
	end
end

-- A TabSystemButtonArtTemplate button: the nine textures, the Text, and
-- SetTabSelected (TabSystemButtonArtMixin), which shows and hides the
-- active and inactive pieces as the game's does.
local TAB_ART = { 'LeftActive', 'MiddleActive', 'RightActive', 'Left', 'Middle', 'Right' }
local TAB_HIGHLIGHT = { 'LeftHighlight', 'MiddleHighlight', 'RightHighlight' }
local function tab_system(parent, key, top)
	local system = frame(parent, key)
	system:SetSize(300, 32)
	rawset(system, 'tabs', {})
	rawset(system, 'AddTab', function(self, text)
		local tab = CreateFrame('Button', nil, self)
		tab:SetSize(100, 32)
		for _, part in ipairs(TAB_ART) do texture(tab, part, 'BACKGROUND') end
		for _, part in ipairs({ 'SquareBackground', 'SquareBackgroundActive', 'SquareBackgroundActiveGlow' }) do
			texture(tab, part, 'ARTWORK'):Hide() -- icon tabs (square mode) show these
		end
		for _, part in ipairs(TAB_HIGHLIGHT) do
			texture(tab, part, 'HIGHLIGHT', 0.4) -- the XML's alpha
		end
		-- the button's own text (ButtonText, parentKey Text); Camelot's spec tabs add
		-- an inline atlas for the check or the lock (ClassTalentsFrameTabMixin:GetTabText)
		rawset(tab, 'Text', tab:CreateFontString(nil, 'OVERLAY', 'GameFontNormal'))
		tab.Text:SetPoint('CENTER', tab, 'CENTER', 0, 0)
		tab.Text:SetText(text)
		rawset(tab, 'isSelected', false)
		rawset(tab, 'isTabOnTop', top or false)
		rawset(tab, 'tabID', #self.tabs + 1)
		rawset(tab, 'SetTabSelected', function(t, selected)
			rawset(t, 'isSelected', selected)
			for _, part in ipairs({ 'Left', 'Middle', 'Right' }) do t[part]:SetShown(not selected) end
			for _, part in ipairs({ 'LeftActive', 'MiddleActive', 'RightActive' }) do t[part]:SetShown(selected) end
			t:SetEnabled(not selected and not t.forceDisabled)
		end)
		rawset(tab, 'forceDisabled', false)
		rawset(tab, 'SetTabEnabled', function(t, enabled)
			rawset(t, 'forceDisabled', not enabled)
			t:SetEnabled(not t.isSelected and enabled)
		end)
		tab:SetNormalFontObject(GameFontNormal)
		rawset(self.tabs, #self.tabs + 1, tab)
		tab:SetTabSelected(false)
		return tab.tabID
	end)
	return system
end

-- A UIPanelButtonTemplate button (Left, Middle, Right, a highlight texture, the
-- three state fonts).
local function panel_button(parent, key, text)
	local button = frame(parent, key, 'Button')
	button:SetSize(164, 22)
	for _, part in ipairs({ 'Left', 'Middle', 'Right' }) do texture(button, part, 'BACKGROUND') end
	button:SetHighlightTexture([[Interface\Buttons\UI-Panel-Button-Highlight]])
	button:SetNormalFontObject(GameFontNormal)
	button:SetHighlightFontObject(GameFontHighlight)
	button:SetDisabledFontObject(GameFontDisable)
	return button
end

-- SearchBoxTemplate (InputBoxInstructionsTemplate): Left, Middle, Right, the
-- magnifier, Instructions.
local function search_box(parent, key)
	local box = frame(parent, key, 'EditBox')
	box:SetSize(184, 30) -- SpellSearchBoxTemplate; the border art is 20 high
	box:SetFontObject(GameFontHighlightSmall)
	for _, part in ipairs({ 'Left', 'Middle', 'Right' }) do texture(box, part, 'BACKGROUND') end
	texture(box, 'searchIcon', 'OVERLAY')
	local instructions = box:CreateFontString(nil, 'ARTWORK', 'GameFontDisableSmall')
	rawset(box, 'Instructions', instructions)
	return box
end

local function lock_tree(f)
	for _, region in ipairs({ f:GetRegions() }) do lock_widget(region, OWNER) end
	for _, kid in ipairs({ f:GetChildren() }) do lock_tree(kid) end
	lock_widget(f, OWNER)
end

function PSF.build_chrome()
	make_fonts()
	local window = CreateFrame('Frame', 'PlayerSpellsFrame', UIParent)
	window:SetSize(1218, 708)
	window:SetPoint('TOP', UIParent, 'TOP', 0, -41)
	window:Hide()
	rawset(window, 'talentsWidth', 1218)
	rawset(window, 'talentTabID', 1)
	rawset(window, 'spellBookTabID', 2)

	-- PortraitFrameTemplate
	local nine = frame(window, 'NineSlice')
	nine:SetAllPoints(window)
	texture(window, 'Bg', 'BACKGROUND')
	texture(window, 'TopTileStreaks', 'BORDER')
	local portrait = frame(window, 'PortraitContainer')
	portrait:SetSize(1, 1)
	portrait:SetPoint('TOPLEFT')
	texture(portrait, 'portrait', 'OVERLAY')
	local title = frame(window, 'TitleContainer')
	title:SetSize(100, 20)
	title:SetPoint('TOPLEFT', 58, -1)
	title:SetPoint('TOPRIGHT', -24, -1)
	local text = title:CreateFontString(nil, 'OVERLAY', 'GameFontNormal')
	text:SetPoint('TOP', 0, -5)
	text:SetPoint('LEFT')
	text:SetPoint('RIGHT')
	text:SetText('Talents')
	rawset(title, 'TitleText', text)
	local close = frame(window, 'CloseButton', 'Button')
	close:SetSize(28, 28) -- Camelot's UIPanelCloseButtonDefaultAnchorsMixin:OnLoad
	close:SetPoint('TOPRIGHT', 0, 3)
	for _, state in ipairs({ 'Normal', 'Pushed', 'Highlight', 'Disabled' }) do
		close['Set' .. state .. 'Texture'](close, [[Interface\Buttons\UI-Panel-MinimizeButton-Up]])
	end
	tab_system(window, 'TabSystem')
	window.TabSystem:SetPoint('TOPLEFT', window, 'BOTTOMLEFT', 22, 2)

	-- ClassTalentsFrameTemplate
	local talents = frame(window, 'TalentsFrame')
	talents:SetSize(1212, 681)
	talents:SetPoint('BOTTOM', window, 'BOTTOM', 0, 4)
	talents:Hide()
	rawset(talents, 'specBackgrounds', {})
	PSF.specart = {}
	local base = texture(talents, 'Background', 'BACKGROUND')
	-- 'Talents-Background-c60': the dark art of the header above and the footer
	-- below the spec art (70 above ClassBackground's top, 36 under its bottom)
	PSF.background = base
	for i, key in ipairs({ 'ClassBackground', 'OverlayBackgroundRight', 'OverlayBackgroundMid' }) do
		local t = texture(talents, key, 'BACKGROUND', i == 1 and 1 or 0)
		talents.specBackgrounds[#talents.specBackgrounds + 1] = t
		PSF.specart[#PSF.specart + 1] = t
	end
	talents.ClassBackground:SetPoint('TOPLEFT', base, 'TOPLEFT', 0, -70)
	talents.ClassBackground:SetPoint('BOTTOMRIGHT', base, 'BOTTOMRIGHT', 0, 36)
	local border = texture(talents, 'BackgroundBorder', 'OVERLAY')
	border:SetPoint('TOPLEFT', talents.ClassBackground, 'TOPLEFT', -2, 4)
	border:SetPoint('BOTTOMRIGHT', talents.ClassBackground, 'BOTTOMRIGHT', 2, -4)
	local hl = texture(talents, 'DividerHorizontalLeft', 'OVERLAY')
	hl:SetSize(380, 20)
	hl:SetPoint('RIGHT', border, 'CENTER')
	hl:SetPoint('TOP', border, 'TOP', 0, -4)
	local hr = texture(talents, 'DividerHorizontalRight', 'OVERLAY')
	hr:SetSize(380, 20)
	hr:SetPoint('LEFT', border, 'CENTER')
	hr:SetPoint('TOP', border, 'TOP', 0, -4)
	for _, key in ipairs({ 'DividerVerticalLeft', 'DividerVerticalRight' }) do
		local v = texture(talents, key, 'OVERLAY')
		v:SetSize(8, 500)
	end
	talents.DividerVerticalLeft:SetPoint('TOP', hl, 'CENTER', 95, -60)
	talents.DividerVerticalRight:SetPoint('TOP', hr, 'CENTER', -95, -60)
	tab_system(talents, 'TabSystem', true)
	talents.TabSystem:SetPoint('BOTTOMLEFT', border, 'TOPLEFT', 70, -4)

	-- RefreshTreeHeaders (Camelot ClassTalentsFrameMixin): the pool hands out the
	-- headers again, each with its small gold Divider (Talents-small-divider-c60,
	-- BOTTOM 60, -20 of the header) at full alpha. 3 trees.
	rawset(talents, 'treeHeaders', {})
	rawset(talents, 'RefreshTreeHeaders', function(self)
		rawset(self, 'treeHeaders', {})
		for i = 1, 3 do
			local header = CreateFrame('Frame', nil, self)
			header:SetSize(48, 48)
			header:SetPoint('CENTER', border, 'TOPLEFT', 140 + (i - 1) * 400, -90)
			local divider = texture(header, 'Divider', 'OVERLAY')
			divider:SetSize(500, 8)
			divider:SetPoint('BOTTOM', header, 'BOTTOM', 60, -20)
			rawset(header, 'Name', header:CreateFontString(nil, 'OVERLAY', 'GameFontNormal'))
			lock_tree(header)
			self.treeHeaders[i] = header
		end
	end)
	talents:RefreshTreeHeaders()

	local currency = frame(talents, 'ClassCurrencyDisplay')
	currency:SetSize(120, 36)
	currency:SetPoint('TOPRIGHT', border, 'TOPRIGHT', -20, -6)
	local cb = texture(currency, 'Border', 'ARTWORK')
	cb:SetSize(64, 36)
	cb:SetPoint('RIGHT')
	-- Camelot's ClassTalentCurrencyDisplayTemplate: the label's RIGHT is the border's
	-- LEFT + 60, the amount's container is the border's RIGHT - 4, the amount in
	-- Game32Font_Shadow2 (the fixture's GameFontNormal stands for it)
	local label = currency:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	label:SetPoint('RIGHT', cb, 'LEFT', 60, 0)
	label:SetText('Unspent Talents')
	rawset(currency, 'UnspentLabel', label)
	local amount = frame(currency, 'CurrentAmountContainer')
	amount:SetSize(48, 36)
	amount:SetPoint('RIGHT', cb, 'RIGHT', -4, 0)
	local number = amount:CreateFontString(nil, 'ARTWORK', 'GameFontNormal')
	number:SetPoint('CENTER')
	number:SetText('1')
	number:SetTextColor(0.1, 1, 0.1)
	rawset(amount, 'CurrencyAmount', number)

	local spec = frame(talents, 'ActiveSpec')
	spec:SetSize(164, 24)
	spec:SetPoint('TOP', border, 'TOP', 0, -20)
	panel_button(spec, 'ActivateButton', 'Activate')

	local load = frame(talents, 'LoadSystem')
	load:SetSize(200, 30)
	load:SetPoint('BOTTOMLEFT', base, 'BOTTOMLEFT', 48, 0)
	local dropdown = frame(load, 'Dropdown', 'Button')
	dropdown:SetSize(180, 24)
	dropdown:SetPoint('LEFT')
	texture(dropdown, 'Background', 'BACKGROUND')
	texture(dropdown, 'Arrow', 'OVERLAY')
	rawset(dropdown, 'Text', dropdown:CreateFontString(nil, 'OVERLAY', 'GameFontHighlightSmall'))

	search_box(talents, 'SearchBox'):SetPoint('BOTTOMRIGHT', border, 'TOPRIGHT', -32, 4)
	panel_button(talents, 'ApplyButton', 'Apply'):SetPoint('BOTTOM', base, 'BOTTOM', 0, 8)
	panel_button(talents, 'InspectCopyButton', 'Copy'):SetPoint('BOTTOM', base, 'BOTTOM', 0, 3)
	for _, key in ipairs({ 'ResetButton', 'UndoButton' }) do
		local icon = frame(talents, key, 'Button')
		icon:SetSize(25, 25)
		texture(icon, 'Icon', 'ARTWORK')
	end

	-- SpellBookFrameTemplate
	local book = frame(window, 'SpellBookFrame')
	book:SetSize(1148, 702)
	book:SetPoint('BOTTOMLEFT', 0, 4)
	book:Hide()
	texture(book, 'BookBGLeft', 'BACKGROUND')
	texture(book, 'BookBGRight', 'BACKGROUND')
	tab_system(book, 'CategoryTabSystem', false)
	search_box(book, 'SearchBox')

	lock_tree(window)
	PSF.window, PSF.talents, PSF.book = window, talents, book
	return window
end

-- The alpha of each region of the spec art, by name.
function PSF.alphas()
	local out = {}
	for _, t in ipairs(PSF.specart) do out[#out + 1] = t:GetAlpha() end
	return out
end

-- Adds a tab to a tab system as the game's TabSystemMixin:AddTab does (the
-- skin hooks the system's own AddTab).
function PSF.add_tab(system, text) return system:AddTab(text) end

return PSF
