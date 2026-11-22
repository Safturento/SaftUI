--[[
	A model of the Spy addon (Spy Forever) as SaftUI's skin
	(SaftUI-Misc/Skinning/addons/spy.lua) sees it. A stand-in, not a copy: it keeps
	the frame names, parentKeys and function names the skin relies on, checked
	2026-11-22 against Spy 1.3.8-forever28 (Widgets.lua, MainWindow.lua,
	Display.lua, SpyStats.xml), and nothing of Spy's logic beyond what moves a
	frame, restyles one or recolors one. Load it with
	`local SpyFix = load_test_file('misc/fixtures/spy_world.lua')` and call
	SpyFix.make(opts) after reset_world() (or use_client), before or after the skin's
	module is enabled.

	What make() builds (every frame and region is locked once Spy has built it:
	lib/locked_widget.lua, so a skin that writes a field onto one or replaces a
	script fails; Spy's own field writes go through rawset):
	  - the global Spy with db.profile, Colors (GetColor), and the functions the skin
	    hooks: CreateMainWindow, CreateRow, SetupBar, SetBar, ManageBarsDisplayed,
	    ResizeMainWindow, ApplyBorderStyle, ShowAlert, CreateKoSButton, SetFontSize,
	    UpdateBarTextures, SetBarTextures (MainWindow.lua: Spy puts its own bar texture on
	    every row again on its texture option and on a profile change).
	    Spy:CreateMainWindow() makes Spy.MainWindow (Spy_MainWindow: Background,
	    TitleBar, Title, CloseButton, LeftButton, RightButton, ClearButton,
	    StatsButton, CountFrame.Text, CountButton, the four Drag* grips, Rows) and
	    Spy.AlertWindow (Icon, Title, Name, Location); make() calls it unless
	    opts.noWindow.
	  - Rows: Spy:CreateRow(n) makes Spy_MainWindow_Bar<n>, protected (a secure
	    button), with StatusBar, LeftText, RightText, ClassIcon and Marker. The window
	    is protected as well (it holds secure rows).
	  - Spy:ApplyBorderStyle() puts the tooltip backdrop on the title bar and, for
	    WindowBorder = 'forever', the gold ForeverBorder (a backdrop frame) on the
	    window and the alert, as Display.lua does.
	  - SpyStatsFrame and its named children (SpyStats.xml), unless opts.noStats.
	  - Spy:CreateKoSButton() makes Spy.KoSButton on the global TargetFrame
	    (Background, Icon, Border, a highlight texture).
	  - SpyPerCharDB = { KOSData = {} }.
	opts.noFamily has the game lack CreateFontFamily (Spy then uses SetFont); opts.invert sets the InvertSpy option.
	opts.renamed drops pieces, as a Spy version that renamed them would: the
	window's StatsButton, the alert's Icon, SpyStatsFrame's TabFrame, the KoS
	button's Border (the CreateMainWindow still builds the rest). opts.noAlert drops
	Spy.AlertWindow itself.

	SpyFix.geometry_calls lists every move, size, show, hide or reparent call made
	on the main window or a row: { frame, method, from_spy }, from_spy true while one
	of Spy's own functions runs and false for a call from anywhere else, which is
	the skin's (the window is secure in combat: .agents/taint.md and the plan's
	Global Constraints). SpyFix.in_spy counts the depth of Spy's own functions.
]]

local lock_widget_raw = load_test_file('lib/locked_widget.lua')
local OWNER = 'Spy'

local SpyFix = {}

local spy_frames = setmetatable({}, { __mode = 'k' })

-- True for a frame or region Spy made, false for one SaftUI made.
function SpyFix.is_spy(widget)
	return spy_frames[widget] == true
end

local function lock_widget(widget, owner)
	spy_frames[widget] = true
	return lock_widget_raw(widget, owner)
end

local GEOMETRY = { 'SetPoint', 'ClearAllPoints', 'SetAllPoints', 'SetSize', 'SetWidth', 'SetHeight', 'Show', 'Hide',
	'SetShown', 'SetParent' }

local FONT = [[Fonts\FRIZQT__.TTF]]

-- Spy writes its fields with rawset, as its own code does on frames it has not
-- locked; the lock stops anyone else.
local function own(widget, key, value)
	rawset(widget, key, value)
	return value
end

local function lock_tree(frame)
	for _, region in ipairs({ frame:GetRegions() }) do lock_widget(region, OWNER) end
	for _, kid in ipairs({ frame:GetChildren() }) do lock_tree(kid) end
	lock_widget(frame, OWNER)
end

-- Notes every geometry call on frame, from Spy's functions or from outside them.
local function record_geometry(frame)
	for _, method in ipairs(GEOMETRY) do
		local original = frame[method]
		rawset(frame, method, function(self, ...)
			SpyFix.geometry_calls[#SpyFix.geometry_calls + 1] = { frame = self, method = method, from_spy = SpyFix.in_spy > 0 }
			return original(self, ...)
		end)
	end
end

-- Spy's own function: runs with SpyFix.in_spy raised, so a geometry call it makes
-- is told from the skin's.
local function spy_fn(fn)
	return function(...)
		SpyFix.in_spy = SpyFix.in_spy + 1
		local results = { n = 0 }
		local function keep(...)
			results.n = select('#', ...)
			for i = 1, results.n do results[i] = (select(i, ...)) end
		end
		keep(pcall(fn, ...))
		SpyFix.in_spy = SpyFix.in_spy - 1
		if not results[1] then error(results[2], 0) end
		return unpack(results, 2, results.n)
	end
end

local function button(parent, name, w, h, textures)
	local b = CreateFrame('Button', name, parent)
	b:SetSize(w, h)
	if textures then
		b:SetNormalTexture(textures[1])
		b:SetPushedTexture(textures[2] or textures[1])
		b:SetHighlightTexture(textures[3] or textures[1])
	end
	return b
end

-- A text on a font object of its own, as Spy's ApplyFont leaves it (never a SetFont,
-- which in game and in the stubs outlives a SetFontObject).
local function text(parent, template)
	local fs = parent:CreateFontString(nil, 'OVERLAY', template or 'GameFontNormal')
	local object = CreateFont()
	object:SetFont(FONT, 12, '')
	fs:SetFontObject(object)
	return fs
end

-- Fonts.lua's alphabet files, and CreateFontFamily: a font object whose roman font is
-- the first member's, remembering the others for GetFontObjectForAlphabet.
local ALPHABET_FILES = {
	korean = [[Fonts\2002.TTF]], simplifiedchinese = [[Fonts\ARKai_T.ttf]],
	traditionalchinese = [[Fonts\BLEI00D.TTF]], russian = [[Fonts\FRIZQT___CYR.TTF]],
}
local function create_font_family(_, members)
	local family = CreateFont()
	local others = {}
	for _, member in ipairs(members) do
		if member.alphabet == 'roman' then
			family:SetFont(member.file, member.height, member.flags)
		else
			local object = CreateFont()
			object:SetFont(member.file, member.height, member.flags)
			others[member.alphabet] = object
		end
	end
	rawset(family, 'GetFontObjectForAlphabet', function(_, alphabet) return others[alphabet] end)
	return family
end

---------------------------------------------------------------- the main window

local TOOLTIP = {
	bgFile = [[Interface\Tooltips\UI-Tooltip-Background]], tile = true, tileSize = 8,
	edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]], edgeSize = 12,
	insets = { left = 2, right = 2, top = 2, bottom = 2 },
}

-- Widgets.lua Spy:CreateFrame and MainWindow.lua Spy:CreateMainWindow
local function build_window(opts)
	local profile = Spy.db.profile
	local window = CreateFrame('Frame', 'Spy_MainWindow', UIParent, 'BackdropTemplate')
	window:SetSize(profile.MainWindow.Position.w, 200)
	window:SetPoint('CENTER')
	window:EnableMouse(true)
	window:SetMovable(true)
	own(window, 'IsProtected', function() return true, true end) -- it holds secure rows

	local background = window:CreateTexture(nil, 'BACKGROUND')
	background:SetTexture([[Interface\CHARACTERFRAME\UI-Party-Background]])
	if profile.InvertSpy then -- Widgets.lua
		background:SetPoint('TOPLEFT', window, 'TOPLEFT', 0, -34)
		background:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', 0, 0)
	else
		background:SetPoint('TOPLEFT', window, 'TOPLEFT', 0, -32)
		background:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', 0, 2)
	end
	own(window, 'Background', background)

	local bar = CreateFrame('Frame', 'SpyTitleBarFrame', window, 'BackdropTemplate')
	bar:SetFrameStrata('BACKGROUND')
	if profile.InvertSpy then -- Widgets.lua: the title bar under the window
		bar:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', 0, -21)
		bar:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', 0, -21)
	else
		bar:SetPoint('TOPLEFT', window, 'TOPLEFT', 0, -11)
		bar:SetPoint('TOPRIGHT', window, 'TOPRIGHT', 0, -11)
	end
	bar:SetHeight(22)
	bar:SetBackdrop(TOOLTIP)
	bar:SetBackdropColor(0, 0, 0, 1)
	bar:SetBackdropBorderColor(1, 1, 1, 1)
	own(window, 'TitleBar', bar)

	local title = text(window, 'GameFontNormal')
	title:SetPoint('TOPLEFT', window, 'TOPLEFT', 8, -16)
	title:SetText('Nearby')
	own(window, 'Title', title)

	own(window, 'CloseButton', button(window, nil, 20, 20, {
		[[Interface\Buttons\UI-Panel-MinimizeButton-Up.blp]], [[Interface\Buttons\UI-Panel-MinimizeButton-Down.blp]],
		[[Interface\Buttons\UI-Panel-MinimizeButton-Highlight.blp]] }))
	window.CloseButton:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -4, -12)

	local TEX = [[Interface\AddOns\Spy\Textures\]]
	own(window, 'RightButton', button(window, nil, 16, 16, { TEX .. 'button-right.tga', nil, TEX .. 'button-highlight.tga' }))
	window.RightButton:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -23, -14.5)
	own(window, 'LeftButton', button(window, nil, 16, 16, { TEX .. 'button-left.tga', nil, TEX .. 'button-highlight.tga' }))
	window.LeftButton:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -39, -14.5)
	own(window, 'ClearButton', button(window, nil, 16, 16, { TEX .. 'button-clear.tga', nil, TEX .. 'button-highlight.tga' }))
	window.ClearButton:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -55, -14.5)
	if not opts.renamed then
		own(window, 'StatsButton', button(window, nil, 16, 16, { TEX .. 'button-stats.tga', nil, TEX .. 'button-highlight.tga' }))
		window.StatsButton:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -71, -14.5)
	end

	local count = CreateFrame('Frame', 'CountFrame', window)
	count:SetHeight(profile.MainWindow.RowHeight)
	local count_text = text(count, 'GameFontNormal')
	count_text:SetPoint('RIGHT', window.ClearButton, 'LEFT', -4, 0)
	count_text:SetText('0')
	own(count, 'Text', count_text)
	own(window, 'CountFrame', count)
	own(window, 'CountButton', button(window, nil, 16, 16, { TEX .. 'button-crosshairs.tga' }))
	window.CountButton:SetAlpha(0)

	for _, key in ipairs({ 'DragBottomRight', 'DragBottomLeft', 'DragTopRight', 'DragTopLeft' }) do
		local grip = button(window, nil, 16, 16, { TEX .. 'resize-grip.tga', nil, TEX .. 'resize-grip-highlight.tga' })
		own(window, key, grip)
	end
	window.DragBottomRight:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', 0, 0)
	window.DragBottomLeft:SetPoint('BOTTOMLEFT', window, 'BOTTOMLEFT', 0, 0)
	window.DragTopRight:SetPoint('TOPRIGHT', window, 'TOPRIGHT', 0, 0)
	window.DragTopLeft:SetPoint('TOPLEFT', window, 'TOPLEFT', 0, 0)

	own(window, 'Rows', {})
	own(window, 'CurRows', 0)
	return window
end

-- MainWindow.lua's alert window
local function build_alert(opts)
	local alert = CreateFrame('Frame', 'Spy_AlertWindow', UIParent, 'BackdropTemplate')
	alert:SetHeight(42)
	alert:SetWidth(160)
	alert:SetPoint('TOP', UIParent, 'TOP', 0, -140)
	alert:SetBackdrop(TOOLTIP)
	if not opts.renamed then
		local icon = CreateFrame('Frame', nil, alert, 'BackdropTemplate')
		icon:SetPoint('TOPLEFT', alert, 'TOPLEFT', 6, -5)
		icon:SetSize(32, 32)
		own(alert, 'Icon', icon)
	end
	local title = text(alert, 'GameFontNormal')
	title:SetPoint('TOPLEFT', alert, 'TOPLEFT', 42, -3)
	own(alert, 'Title', title)
	Spy:SetFontSize(title, 12) -- Spy:AddFontString puts its font family on it
	local name = text(alert, 'GameFontNormal')
	name:SetPoint('TOPLEFT', alert, 'TOPLEFT', 42, -15)
	own(alert, 'Name', name)
	Spy:SetFontSize(name, 14) -- Spy:AddFontString puts its font family on it
	local location = text(alert, 'GameFontNormal')
	location:SetPoint('TOPLEFT', alert, 'TOPLEFT', 42, -26)
	own(alert, 'Location', location)
	Spy:SetFontSize(location, 10) -- Spy:AddFontString puts its font family on it
	alert:Hide()
	return alert
end

---------------------------------------------------------------- the stats window

-- The named children of SpyStats.xml, as far as a skin styles them.
local function build_stats(opts)
	local frame = CreateFrame('Frame', 'SpyStatsFrame', UIParent)
	frame:SetSize(1100, 610)
	frame:SetPoint('CENTER')
	frame:SetMovable(true)
	frame:EnableMouse(true)
	frame:Hide()

	local header = frame:CreateTexture('SpyStatsFrame_Header', 'ARTWORK')
	header:SetTexture([[Interface\DialogFrame\UI-DialogBox-Header]])
	header:SetSize(300, 64)
	header:SetPoint('TOP', 0, 14)
	local title = frame:CreateFontString('SpyStatsFrame_Title', 'ARTWORK', 'GameFontNormal')
	title:SetFont(FONT, 12, '')
	title:SetPoint('TOP')
	title:SetText('Statistics')
	local texts = {}
	for _, key in ipairs({ 'FilterText', 'ShowOnlyText' }) do
		local fs = frame:CreateFontString('SpyStatsFrame' .. key, 'ARTWORK', 'GameFontNormal')
		fs:SetFont(FONT, 12, '')
		texts[key] = fs
	end
	for _, key in ipairs({ 'SpyStatsHonorKillsText', 'SpyStatsPvPDeathsText' }) do
		local fs = frame:CreateFontString(key, 'ARTWORK', 'GameFontNormal')
		fs:SetFont(FONT, 12, '')
	end

	local icon = CreateFrame('Frame', 'SpyStatsFrameIcon', frame)
	icon:SetSize(80, 80)
	local close = CreateFrame('Button', 'SpyStatsFrameTopCloseButton', frame)
	close:SetSize(32, 32)
	close:SetNormalTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Up]])
	close:SetPushedTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Down]])
	close:SetHighlightTexture([[Interface\Buttons\UI-Panel-MinimizeButton-Highlight]])
	close:SetPoint('TOPRIGHT', -6, -8)

	if not opts.renamed then
		local tabs = CreateFrame('Frame', 'SpyStatsTabFrame', frame)
		tabs:SetPoint('TOPLEFT', 12, -12)
		tabs:SetPoint('BOTTOMRIGHT', -12, 34)
		local tab1 = CreateFrame('Button', 'SpyStatsTabFrameTab1', tabs)
		tab1:Hide()

		local refresh = CreateFrame('Button', 'SpyStatsRefreshButton', tabs)
		refresh:SetSize(80, 22)
		for _, part in ipairs({ 'Left', 'Middle', 'Right' }) do
			own(refresh, part, refresh:CreateTexture(nil, 'BACKGROUND'))
		end
		refresh:SetHighlightTexture([[Interface\Buttons\UI-Panel-Button-Highlight]])
		refresh:SetNormalFontObject(GameFontNormal)

		local content = CreateFrame('Frame', 'SpyStatsTabFrameTabContentFrame', tabs, 'BackdropTemplate')
		content:SetAllPoints()
		local scroll = CreateFrame('ScrollFrame', 'SpyStatsTabFrameTabContentFrameScrollFrame', content)
		scroll:SetPoint('TOPLEFT', 8, -30)
		scroll:SetPoint('BOTTOMRIGHT', -26, 8)
		local scrollbar = CreateFrame('Slider', 'SpyStatsTabFrameTabContentFrameScrollFrameScrollBar', scroll)
		own(scroll, 'ScrollBar', scrollbar)
		for _, name in ipairs({ 'ScrollUpButton', 'ScrollDownButton' }) do
			own(scrollbar, name, CreateFrame('Button', nil, scrollbar))
		end

		local history = CreateFrame('Frame', 'SpyStatsPlayerHistoryFrame', content)
		history:SetAllPoints()
		local headers = CreateFrame('Frame', 'SpyStatsPlayerHistoryFrameHeaderFrame', history)
		for _, key in ipairs({ 'Name', 'Level', 'Rank', 'Class', 'Guild', 'Wins', 'Loses', 'Reason' }) do
			local sort = CreateFrame('Button', 'SpyStatsPlayers' .. key .. 'Sort', headers)
			sort:SetNormalFontObject(GameFontNormal)
		end
		for _, key in ipairs({ 'List', 'Time', 'Zone' }) do
			local sort = CreateFrame('Button', 'SpyStats' .. key .. 'Sort', headers)
			sort:SetNormalFontObject(GameFontNormal)
		end
		local list = CreateFrame('Frame', 'SpyStatsPlayerHistoryFrameListFrame', history)
		for i = 1, 34 do
			local line = CreateFrame('Button', 'SpyStatsPlayerHistoryFrameListFrameLine' .. i, list)
			line:SetHeight(16)
			line:SetHighlightTexture([[Interface\QuestFrame\UI-QuestTitleHighlight]])
			local row = CreateFrame('Frame', nil, line)
			row:SetAllPoints()
			for _, key in ipairs({ 'Name', 'Level', 'Rank', 'Class', 'Guild', 'Wins', 'Loses', 'Reason', 'Zone', 'List', 'Time' }) do
				local fs = row:CreateFontString(line:GetName() .. key, 'ARTWORK', 'GameFontHighlightSmall')
				fs:SetFont(FONT, 10, '')
			end
		end

		local filter = CreateFrame('EditBox', 'SpyStatsFilterBox', frame)
		filter:SetSize(150, 26)
		filter:SetAutoFocus(false)
		for _, key in ipairs({ 'Kos', 'Realm', 'WinsLoses', 'Reason' }) do
			local check = CreateFrame('CheckButton', 'SpyStats' .. key .. 'Checkbox', frame)
			check:SetSize(26, 26)
			local label = frame:CreateFontString('SpyStats' .. key .. 'CheckboxText', 'ARTWORK', 'GameFontHighlight')
			label:SetFont(FONT, 12, '')
		end
	end
	lock_tree(frame)
	return frame
end

---------------------------------------------------------------- the world

-- Makes the world Spy builds. opts.noStats, opts.renamed, opts.noWindow: see the
-- header. opts.border sets the profile's WindowBorder ('classic' by default).
function SpyFix.make(opts)
	opts = opts or {}
	-- The named fonts Spy's templates use; the stubs have only some, and a world
	-- reset removes the ones made earlier.
	for _, name in ipairs({ 'GameFontNormal', 'GameFontHighlight', 'GameFontHighlightSmall', 'GameFontDisable' }) do
		if not _G[name] then
			local font = CreateFont(name)
			font:SetFont([[Fonts\FRIZQT__.TTF]], 12, '')
		end
	end
	SpyFix.geometry_calls = {}
	SpyFix.in_spy = 0

	local plain = { x = 0, y = 0, w = 160 }
	Spy = {
		renamed = opts.renamed,
		db = { profile = {
			MainWindow = { RowHeight = 14, RowSpacing = 0, TextHeight = 12, Position = plain },
			ResizeSpyLimit = 10, ShowKoSButton = true, WindowBorder = opts.border or 'classic', InvertSpy = opts.invert or false,
		} },
		ListAmountDisplayed = 0,
		Colors = {},
	}
	SpyPerCharDB = { KOSData = {} }
	TargetFrame = CreateFrame('Frame', 'TargetFrame', UIParent)
	TargetFrame:SetSize(180, 60)
	rawset(TargetFrame, 'Update', function() end)

	-- The colors Spy's alert takes, set by ShowAlert's kind (Colors.lua).
	Spy.Colors.table = { Alert = { Background = { r = 0, g = 0, b = 0, a = 0.8 }, ['KOS Border'] = { r = 1, g = 0, b = 0, a = 1 },
		['KOS Guild Border'] = { r = 1, g = 0.5, b = 0, a = 1 }, ['Other Border'] = { r = 0, g = 0.7, b = 1, a = 1 } } }
	function Spy.Colors:GetColor(branch, name)
		return self.table[branch] and self.table[branch][name]
	end
	-- Colors.lua: RegisterBorder puts a registered color on a frame's backdrop border.
	function Spy.Colors:RegisterBorder(branch, name, frame)
		local c = self:GetColor(branch, name)
		frame:SetBackdropBorderColor(c.r, c.g, c.b, c.a)
	end

	-- Display.lua: Spy:SetFontSize(fontString, size) keeps the face, asks for the size.
	-- Fonts.lua: Spy:ApplyFont builds a font family around the face (roman and the
	-- four alphabets' files) and sets it with SetFontObject; with no CreateFontFamily
	-- it falls back to SetFont. opts.noFamily has the game lack CreateFontFamily.
	if not opts.noFamily then CreateFontFamily = create_font_family else CreateFontFamily = nil end
	function Spy:ApplyFont(fs, file, height, flags)
		if not CreateFontFamily then return fs:SetFont(file, height, flags) end
		local members = { { alphabet = 'roman', file = file, height = height, flags = flags } }
		for alphabet, alternate in pairs(ALPHABET_FILES) do
			members[#members + 1] = { alphabet = alphabet, file = alternate, height = height, flags = flags }
		end
		local r, g, b, a = fs:GetTextColor()
		fs:SetFontObject(CreateFontFamily('SpyFontFamily', members))
		if r then fs:SetTextColor(r, g, b, a) end
	end
	-- MainWindow.lua: Spy:SetFontSize keeps the face and flags, asks for the size.
	function Spy:SetFontSize(fs, size)
		local face, _, flags = fs:GetFont()
		Spy:ApplyFont(fs, face or FONT, size, flags)
	end

	function Spy:CreateMainWindow()
		if Spy.MainWindow then return end
		local window = own(Spy, 'MainWindow', build_window(opts))
		if not opts.noAlert then own(Spy, 'AlertWindow', build_alert(opts)) end
		record_geometry(window)
		lock_tree(window)
		if Spy.AlertWindow then lock_tree(Spy.AlertWindow) end
		for i = 1, Spy.db.profile.ResizeSpyLimit do Spy:CreateRow(i) end
		Spy:ApplyBorderStyle()
	end
	Spy.CreateMainWindow = spy_fn(Spy.CreateMainWindow)

	-- MainWindow.lua Spy:CreateRow and Spy:SetupBar (Forever's SetupRowExtras adds
	-- the class icon and the marker)
	function Spy:SetupBar(row)
		local profile = Spy.db.profile.MainWindow
		local status = CreateFrame('StatusBar', nil, row)
		status:SetAllPoints(row)
		status:SetStatusBarTexture([[Interface\TargetingFrame\UI-StatusBar]])
		status:SetStatusBarColor(0.5, 0.5, 0.5, 0.8)
		status:SetMinMaxValues(0, 100)
		status:SetValue(100)
		own(row, 'StatusBar', status)
		local left = text(status, 'GameFontHighlightSmall')
		left:SetPoint('LEFT', status, 'LEFT', 2, 0)
		left:SetHeight(profile.TextHeight)
		own(row, 'LeftText', left)
		Spy:SetFontSize(left, math.max(profile.RowHeight * 0.75, profile.RowHeight - 3))
		local right = text(status, 'GameFontHighlightSmall')
		right:SetPoint('RIGHT', status, 'RIGHT', -2, 0)
		own(row, 'RightText', right)
		Spy:SetFontSize(right, math.max(profile.RowHeight * 0.65, profile.RowHeight - 12))
		local icon = status:CreateTexture(nil, 'ARTWORK')
		-- The game resets a texture's coordinates when an atlas is set (Display.lua's
		-- setClassIcon calls SetTexCoord, then SetAtlas), with no SetTexCoord call to hook.
		local set_atlas = icon.SetAtlas
		rawset(icon, 'SetAtlas', function(self, ...)
			local result = set_atlas(self, ...)
			stub.state(self).tex_coord = nil
			return result
		end)
		own(row, 'ClassIcon', icon)
		own(row, 'Marker', status:CreateTexture(nil, 'OVERLAY'))
		lock_tree(status)
	end
	Spy.SetupBar = spy_fn(Spy.SetupBar)

	function Spy:CreateRow(num)
		if num < 1 or Spy.MainWindow.Rows[num] then return end
		local profile = Spy.db.profile.MainWindow
		local row = CreateFrame('Button', 'Spy_MainWindow_Bar' .. num, Spy.MainWindow, 'SecureActionButtonTemplate')
		row:SetPoint('TOPLEFT', Spy.MainWindow, 'TOPLEFT', 2, -34 - (profile.RowHeight + profile.RowSpacing) * (num - 1))
		row:SetHeight(profile.RowHeight)
		row:SetWidth(Spy.MainWindow:GetWidth() - 4)
		Spy:SetupBar(row)
		record_geometry(row)
		lock_widget(row, OWNER)
		Spy.MainWindow.Rows[num] = row
		row:Hide()
		own(row, 'id', num)
	end
	Spy.CreateRow = spy_fn(Spy.CreateRow)

	-- MainWindow.lua: the rows' bar texture again, from the profile's BarTexture.
	function Spy:UpdateBarTextures()
		for _, row in pairs(Spy.MainWindow.Rows) do
			row.StatusBar:SetStatusBarTexture([[Interface\AddOns\Spy\Textures\flat]])
		end
	end
	Spy.UpdateBarTextures = spy_fn(Spy.UpdateBarTextures)

	function Spy:SetBarTextures(handle)
		Spy.db.profile.BarTexture = handle
		for _, row in pairs(Spy.MainWindow.Rows) do
			row.StatusBar:SetStatusBarTexture([[Interface\AddOns\Spy\Textures\flat]])
		end
	end
	Spy.SetBarTextures = spy_fn(Spy.SetBarTextures)

	function Spy:SetBar(num, name, desc, value, colorgroup, colorclass)
		local row = Spy.MainWindow and Spy.MainWindow.Rows[num]
		if not row then return end
		row.LeftText:SetText(name)
		row.RightText:SetText(desc)
		row.StatusBar:SetValue(value or 100)
		local color = colorclass and RAID_CLASS_COLORS and RAID_CLASS_COLORS[colorclass]
		-- Display.lua's setClassIcon: the coordinates, then the atlas
		row.ClassIcon:SetTexCoord(0, 1, 0, 1)
		row.ClassIcon:SetAtlas('classicon-' .. tostring(colorclass or 'unknown'):lower())
		row.StatusBar:SetStatusBarColor(color and color.r or 0.5, color and color.g or 0.5, color and color.b or 0.5, 0.8)
		row:Show()
	end
	Spy.SetBar = spy_fn(Spy.SetBar)

	function Spy:ManageBarsDisplayed()
		local window = Spy.MainWindow
		local profile = Spy.db.profile
		local bars = math.min(Spy.ListAmountDisplayed, profile.ResizeSpyLimit,
			math.floor((window:GetHeight() - 34) / (profile.MainWindow.RowHeight + profile.MainWindow.RowSpacing)))
		window.CurRows = bars
		if not InCombatLockdown() then
			for i, row in pairs(window.Rows) do
				if i <= bars then row:Show() else row:Hide() end
			end
		end
	end
	Spy.ManageBarsDisplayed = spy_fn(Spy.ManageBarsDisplayed)

	function Spy:ResizeMainWindow()
		local window = Spy.MainWindow
		window.Title:SetWidth(window:GetWidth() - 4 - 75)
		for _, row in pairs(window.Rows) do row:SetWidth(window:GetWidth() - 4) end
		Spy:ManageBarsDisplayed()
	end
	Spy.ResizeMainWindow = spy_fn(Spy.ResizeMainWindow)

	-- Display.lua's border: the title bar's tooltip backdrop, and the gold edge as
	-- ForeverBorder (a frame of Spy's on the window, the alert and the title bar).
	local function forever_border(frame)
		local border = frame.ForeverBorder
		if not border then
			border = CreateFrame('Frame', nil, frame, 'BackdropTemplate')
			border:SetBackdrop({ edgeFile = [[Interface\DialogFrame\UI-DialogBox-Gold-Border]], edgeSize = 16, tileEdge = true })
			own(frame, 'ForeverBorder', border)
			lock_widget(border, OWNER)
		end
		border:SetPoint('TOPLEFT', frame, 'TOPLEFT', -4, 4)
		border:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 4, -4)
		return border
	end

	local function apply_border(frame, style, bg)
		frame:SetBackdrop({ bgFile = TOOLTIP.bgFile, tile = true, tileSize = 8,
			edgeFile = style == 'classic' and TOOLTIP.edgeFile or nil, edgeSize = style == 'classic' and 12 or nil,
			insets = TOOLTIP.insets })
		frame:SetBackdropColor(bg[1], bg[2], bg[3], bg[4])
		if style == 'classic' then frame:SetBackdropBorderColor(1, 1, 1, 1) end
		local border = style == 'forever' and forever_border(frame) or frame.ForeverBorder
		if border then border:SetShown(style == 'forever') end
	end

	function Spy:ApplyBorderStyle()
		local style = Spy.db.profile.WindowBorder
		local window = Spy.MainWindow
		if window and window.TitleBar then
			apply_border(window.TitleBar, style, { 0, 0, 0, 1 })
			if window.TitleBar.ForeverBorder then window.TitleBar.ForeverBorder:Hide() end
			if style == 'forever' then
				forever_border(window):Show()
			elseif window.ForeverBorder then
				window.ForeverBorder:Hide()
			end
		end
		local alert = Spy.AlertWindow
		if alert then
			local c = Spy.Colors:GetColor('Alert', 'Background')
			apply_border(alert, style, { c.r, c.g, c.b, c.a or 1 })
		end
	end
	Spy.ApplyBorderStyle = spy_fn(Spy.ApplyBorderStyle)

	-- MainWindow.lua's ShowAlert: each alert kind sets the alert's border color,
	-- the icon and the texts.
	local KINDS = { kos = 'KOS Border', kosguild = 'KOS Guild Border', other = 'Other Border' }
	function Spy:ShowAlert(kind, name, source, location)
		local alert = Spy.AlertWindow
		if not alert then return end
		Spy.Colors:RegisterBorder('Alert', KINDS[kind] or 'Other Border', alert)
		if alert.Icon then alert.Icon:SetBackdrop({ bgFile = [[Interface\Icons\Ability_Creature_Cursed_02]] }) end
		alert.Title:SetText(kind)
		alert.Name:SetText(name)
		alert.Location:SetText(location or '')
		alert:Show()
	end
	Spy.ShowAlert = spy_fn(Spy.ShowAlert)

	function Spy:CreateKoSButton()
		if Spy.KoSButton then return end
		local kos = CreateFrame('Button', 'Spy_KoSButton', TargetFrame)
		kos:Hide()
		kos:SetSize(22, 22)
		kos:SetPoint('TOPLEFT', TargetFrame, 'BOTTOMLEFT', 141, 44)
		kos:SetHighlightTexture([[Interface\Minimap\UI-Minimap-ZoomButton-Highlight]])
		local background = kos:CreateTexture('KoSButtonBackground', 'BACKGROUND')
		background:SetTexture([[Interface\Minimap\UI-Minimap-Background]])
		background:SetSize(12, 12)
		background:SetPoint('CENTER')
		own(kos, 'Background', background)
		local icon = kos:CreateTexture('KoSButtonIcon', 'ARTWORK')
		icon:SetSize(14, 14)
		icon:SetPoint('CENTER', 2, -1)
		own(kos, 'Icon', icon)
		if not opts.renamed then
			local border = kos:CreateTexture('KoSButtonBorder', 'OVERLAY')
			border:SetTexture([[Interface\Minimap\MiniMap-TrackingBorder]])
			border:SetSize(44, 44)
			border:SetPoint('CENTER', 11, -12)
			own(kos, 'Border', border)
		end
		lock_tree(kos)
		own(Spy, 'KoSButton', kos)
	end
	Spy.CreateKoSButton = spy_fn(Spy.CreateKoSButton)

	-- Spy:ToggleKOSPlayer(add, name): the KoS list's add or remove (the click handler's call).
	function Spy:ToggleKOSPlayer(add, name)
		SpyPerCharDB.KOSData[name] = add and true or nil
	end
	Spy.ToggleKOSPlayer = spy_fn(Spy.ToggleKOSPlayer)

	-- Forever.lua's Spy:EnemyPlayerName(unit): the unit's name when it is an enemy player, nil
	-- when it is not or when the client keeps its name, kind or hostility secret (stub.units).
	function Spy:EnemyPlayerName(unit)
		local u = stub.units[unit]
		if not u then return nil end
		for _, v in ipairs({ u.player or false, u.enemy or false, u.name or '' }) do
			if issecretvalue and issecretvalue(v) then return nil end
		end
		if u.player and u.enemy and type(u.name) == 'string' then return u.name end
	end

	if not opts.noStats then build_stats(opts) end
	if not opts.noWindow then
		Spy:CreateMainWindow()
		Spy:CreateKoSButton()
	end
	stub.loaded_addons.Spy = true
	return Spy
end

return SpyFix
