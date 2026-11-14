--[[
	TEMPORARY DEMO: a window to choose a small-text font, in game. Not a feature.

	/suifonts opens "Small text fonts (demo)": today's two fonts and nine
	candidates, each set at the sizes the real UI uses, with a size slider, an
	outline choice, a shadow toggle and a scale, so the game's own font
	rendering can be judged. Nothing is saved; the window is never shown unless
	the command is typed. The candidates are also in LibSharedMedia as
	"Candidate: <family>", to try on the real UI in Global Settings > Fonts.

	When a font is chosen, delete exactly this:
	  1. this file, SaftUI-Core/Dev/fontdemo.lua, and its folder SaftUI-Core/Dev/
	     (load.xml in it too);
	  2. the line `Dev\load.xml` in SaftUI-Core_Forever.toc and
	     SaftUI-Core_Mainline.toc;
	  3. the folder SaftUI-Core/Media/Fonts/Candidates/ (the unchosen fonts and
	     their OFL.txt files; keep the chosen font and its OFL.txt, moved to
	     Media/Fonts/ and registered in Media/sharedmedia.lua);
	  4. the LibSharedMedia registrations below (the loop over CANDIDATES, in
	     this file, so they go with step 1);
	  5. tests/core/fontdemo_test.lua, and the demo's line in AGENTS.md.
]]

local AddonName, st = ...

local FD = {}
st.FontDemo = FD

-- family: the name in the font picker ("Candidate: <family>"); file: in
-- Media/Fonts/Candidates/. Each is one static weight (the game does not pick a
-- weight from a variable font).
FD.CANDIDATES = {
	{ family = 'Barlow Condensed',        weight = 'SemiBold', file = 'BarlowCondensed-SemiBold.ttf' },
	{ family = 'Barlow Semi Condensed',   weight = 'SemiBold', file = 'BarlowSemiCondensed-SemiBold.ttf' },
	{ family = 'Roboto Condensed',        weight = 'SemiBold', file = 'RobotoCondensed-SemiBold.ttf' },
	{ family = 'Archivo Narrow',          weight = 'SemiBold', file = 'ArchivoNarrow-SemiBold.ttf' },
	{ family = 'Sofia Sans Condensed',    weight = 'Bold',     file = 'SofiaSansCondensed-Bold.ttf' },
	{ family = 'Saira Condensed',         weight = 'SemiBold', file = 'SairaCondensed-SemiBold.ttf' },
	{ family = 'IBM Plex Sans Condensed', weight = 'SemiBold', file = 'IBMPlexSansCondensed-SemiBold.ttf' },
	{ family = 'Fira Sans Condensed',     weight = 'SemiBold', file = 'FiraSansCondensed-SemiBold.ttf' },
	{ family = 'PT Sans Narrow',          weight = 'Bold',     file = 'PTSansNarrow-Bold.ttf' },
}

local function CandidatePath(candidate)
	return st:FontPath('Candidates\\' .. candidate.file)
end

for _, candidate in ipairs(FD.CANDIDATES) do
	st.LSM:Register('font', 'Candidate: ' .. candidate.family, CandidatePath(candidate))
end

-- The game loads a font file the first time something asks for it, and
-- SetFont is false until it has: in game every candidate "failed" on first
-- use, and so did a byte-for-byte copy of a working font, while fonts SaftUI
-- had already used loaded (the /suifonts test, 2026-11-13). So ask for each
-- candidate once here, at load, on a hidden font string, and the demo tries a
-- row again a moment later while it still says it failed (FD:RetryFailed).
local preload = CreateFrame('Frame')
preload:Hide()
for _, candidate in ipairs(FD.CANDIDATES) do
	preload:CreateFontString(nil, 'OVERLAY'):SetFont(CandidatePath(candidate), 12, '')
end

-- What the controls pick. outline is a key of OUTLINES.
FD.OUTLINES = {
	{ key = 'NONE',     label = 'None',               flags = '' },
	{ key = 'OUTLINE',  label = 'Outline',            flags = 'OUTLINE' },
	{ key = 'THICK',    label = 'Thick outline',      flags = 'THICKOUTLINE' },
	{ key = 'MONO',     label = 'Monochrome',         flags = 'MONOCHROME' },
	{ key = 'MONOLINE', label = 'Monochrome outline', flags = 'MONOCHROME, OUTLINE' },
}
FD.SCALES = { 0.75, 1, 1.55 }
FD.MIN_SIZE, FD.MAX_SIZE = 8, 16

FD.settings = { size = 11, outline = 'OUTLINE', shadow = false, scale = 1 }
FD.starred = {} -- row key -> true; not saved
FD.rows = {}

local WINDOW_WIDTH, NAME_WIDTH, ROW_PAD = 1060, 200, 8
local CONTROLS_HEIGHT = 92
local FADED = { 0.6, 0.6, 0.6 }
local YELLOW = { 0.91, 0.78, 0.29 }
local GREEN = { 0.24, 0.94, 0.24 }
local LIT = { 0, 0.68, 0.94 }

-- Spell icons that exist on both clients (file IDs).
local ICONS = { 136197, 135812, 136048, 136243, 134400 }

local function Flags(outline)
	for _, o in ipairs(FD.OUTLINES) do
		if o.key == outline then return o.flags end
	end
	return ''
end

-- The rows: today's fonts first, then the candidates. fixed is a size and
-- flags that don't follow the controls (Homespun is only crisp at 10).
local function RowDefs()
	local defs = {
		{ key = 'homespun', label = 'Homespun', today = true, path = st:FontPath('homespun.ttf') },
		{ key = 'homespun10', label = 'Homespun at its own size (10, Monochrome outline)', today = true, path = st:FontPath('homespun.ttf'),
			fixed = { size = 10, flags = st.OutlineFlag('MONOCHROMEOUTLINE') } },
		{ key = 'agency', label = 'AgencyFB Bold', today = true, path = st:FontPath('AgencyFB_Bold.ttf') },
	}
	for _, candidate in ipairs(FD.CANDIDATES) do
		defs[#defs + 1] = {
			key = candidate.file,
			label = candidate.family .. ' ' .. candidate.weight,
			path = CandidatePath(candidate),
		}
	end
	return defs
end

local function Box(parent, width, height, fill, edge)
	local box = st:CreateFrame('Frame', nil, parent)
	box:SetSize(width, height)
	box:SetBackdrop({ bgFile = st.BLANK_TEX, edgeFile = st.BLANK_TEX, edgeSize = 1 })
	box:SetBackdropColor(unpack(fill))
	box:SetBackdropBorderColor(unpack(edge or { 0, 0, 0, 1 }))
	return box
end

-- A text of a row: set to the normal font first so it can hold its text even
-- if the row's font fails to load; the row's font replaces that (ApplyRow).
-- mult scales the size (the cooldown number is 1.7 times the hotkey's).
local function Text(row, parent, text, mult, color)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(st:GetFont('normal'))
	fs:SetText(text)
	if color then fs:SetTextColor(color[1], color[2], color[3]) end
	row.texts[#row.texts + 1] = { fs = fs, mult = mult or 1 }
	return fs
end

-- A group of the specimens: a frame and its caption. measure() sizes the
-- pieces (from the texts' widths where they depend on them) and returns the
-- group's width and height.
local function Group(row, parent, caption)
	local group = CreateFrame('Frame', nil, parent)
	local label = group:CreateFontString(nil, 'OVERLAY')
	label:SetFontObject(st:GetFont('pixel'))
	label:SetText(caption)
	label:SetTextColor(unpack(FADED))
	label:SetPoint('BOTTOM', group, 'BOTTOM', 0, 0)
	group.caption = label
	return group
end

local CAPTION_ROOM = 16

local function ActionButtons(row, parent)
	local group = Group(row, parent, 'ACTION BUTTONS')
	local specs = {
		{ hotkey = 'SQ' },
		{ hotkey = 'CE', count = '34' },
		{ hotkey = 'F', cooldown = '3m' },
		{ hotkey = 'C2', count = '8', cooldown = '12' },
	}
	for i, spec in ipairs(specs) do
		local button = Box(group, 45, 45, { 0.1, 0.1, 0.1, 1 }, { 0.3, 0.3, 0.3, 1 })
		button:SetPoint('TOPLEFT', group, 'TOPLEFT', (i - 1) * 48, 0)
		local icon = button:CreateTexture(nil, 'ARTWORK')
		icon:SetTexture(ICONS[i])
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon:SetPoint('TOPLEFT', button, 'TOPLEFT', 1, -1)
		icon:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -1, 1)
		Text(row, button, spec.hotkey):SetPoint('TOPRIGHT', button, 'TOPRIGHT', -2, -3)
		if spec.count then Text(row, button, spec.count):SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -2, 3) end
		if spec.cooldown then Text(row, button, spec.cooldown, 1.7):SetPoint('CENTER', button, 'CENTER', 0, 0) end
	end
	group.measure = function() return 4 * 48 - 3, 45 + CAPTION_ROOM end
	return group
end

local function BagSlots(row, parent)
	local group = Group(row, parent, 'BAG SLOTS')
	local colors = { { 0.64, 0.21, 0.93 }, { 0.12, 1, 0 } }
	for i, count in ipairs({ '20', '147' }) do
		local c = colors[i]
		local slot = Box(group, 38, 38, { 0.1, 0.1, 0.1, 1 }, { c[1], c[2], c[3], 1 })
		slot:SetPoint('TOPLEFT', group, 'TOPLEFT', (i - 1) * 41, 0)
		local icon = slot:CreateTexture(nil, 'ARTWORK')
		icon:SetTexture(ICONS[i + 3])
		icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
		icon:SetPoint('TOPLEFT', slot, 'TOPLEFT', 1, -1)
		icon:SetPoint('BOTTOMRIGHT', slot, 'BOTTOMRIGHT', -1, 1)
		Text(row, slot, count):SetPoint('BOTTOMRIGHT', slot, 'BOTTOMRIGHT', -2, 2)
	end
	group.measure = function() return 2 * 41 - 3, 38 + CAPTION_ROOM end
	return group
end

local function MicroMenu(row, parent)
	local group = Group(row, parent, 'MICRO MENU')
	local items = {
		{ 'Southshore', YELLOW }, { '7:38' }, { '40ms', GREEN }, { '144fps' },
	}
	local boxes = {}
	for i, item in ipairs(items) do
		local box = Box(group, 40, 24, { 0.12, 0.12, 0.12, 1 })
		local fs = Text(row, box, item[1], 1, item[2])
		fs:SetPoint('CENTER', box, 'CENTER', 0, 0)
		boxes[i] = { box = box, fs = fs }
	end
	group.measure = function()
		local x = 0
		for _, b in ipairs(boxes) do
			local width = math.max(40, math.ceil(b.fs:GetStringWidth()) + 16)
			b.box:SetWidth(width)
			b.box:ClearAllPoints()
			b.box:SetPoint('TOPLEFT', group, 'TOPLEFT', x, 0)
			x = x + width + 3
		end
		return x - 3, 24 + CAPTION_ROOM
	end
	return group
end

local function ChatTabs(row, parent)
	local group = Group(row, parent, 'CHAT TABS')
	local tabs = {}
	for i, name in ipairs({ 'General', 'Combat Log', 'Guild' }) do
		tabs[i] = Text(row, group, name, 1, YELLOW)
	end
	group.measure = function()
		local x = 0
		for _, fs in ipairs(tabs) do
			fs:ClearAllPoints()
			fs:SetPoint('TOPLEFT', group, 'TOPLEFT', x, -4)
			x = x + math.ceil(fs:GetStringWidth()) + 18
		end
		return x - 18, 24 + CAPTION_ROOM
	end
	return group
end

local function RaidFrames(row, parent)
	local group = Group(row, parent, 'RAID')
	local specs = { { 'Aldr', { 0.63, 0.5, 0.36 }, 0.7 }, { 'Maer', { 0.78, 0.49, 0.62 }, 0.45 } }
	for i, spec in ipairs(specs) do
		local frame = Box(group, 62, 30, { 0.11, 0.11, 0.11, 1 })
		frame:SetPoint('TOPLEFT', group, 'TOPLEFT', (i - 1) * 65, 0)
		local bar = frame:CreateTexture(nil, 'ARTWORK')
		bar:SetColorTexture(spec[2][1], spec[2][2], spec[2][3], 1)
		bar:SetPoint('TOPLEFT', frame, 'TOPLEFT', 1, -1)
		bar:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 1, 1)
		bar:SetWidth(60 * spec[3])
		Text(row, frame, spec[1]):SetPoint('CENTER', frame, 'CENTER', 0, 0)
	end
	group.measure = function() return 2 * 65 - 3, 30 + CAPTION_ROOM end
	return group
end

local function EditModeLabel(row, parent)
	local group = Group(row, parent, 'EDIT MODE')
	local box = Box(group, 110, 34, { 0, 0, 0, 0.5 }, { 1, 1, 1, 1 })
	box:SetPoint('TOPLEFT', group, 'TOPLEFT', 0, 0)
	Text(row, box, 'Bar 3'):SetPoint('CENTER', box, 'CENTER', 0, 0)
	group.measure = function() return 110, 34 + CAPTION_ROOM end
	return group
end

local GROUPS = { ActionButtons, BagSlots, MicroMenu, ChatTabs, RaidFrames, EditModeLabel }

-- Sets every text of a row to its font, at the controls' size, flags and
-- shadow. SetFont is false when the game can't load the file: the row then
-- says so in the normal font instead of its specimens.
function FD:ApplyRow(row)
	local s = self.settings
	local fixed = row.def.fixed
	local size = fixed and fixed.size or s.size
	local flags = fixed and fixed.flags or Flags(s.outline)
	local loaded = true
	for _, text in ipairs(row.texts) do
		if not text.fs:SetFont(row.def.path, size * text.mult, flags) then loaded = false end
		text.fs:SetShadowColor(0, 0, 0, 1)
		if s.shadow then text.fs:SetShadowOffset(1, -1) else text.fs:SetShadowOffset(0, 0) end
	end
	row.failed = not loaded
	row.specimen:SetShown(loaded)
	row.failure:SetShown(not loaded)
	if not loaded then self:RetryFailed() end
end

-- A font asked for the first time isn't loaded yet (see the preload above):
-- try the rows that failed again shortly, a few times, then leave the row
-- saying so.
local RETRIES, RETRY_DELAY = 10, 0.5
function FD:RetryFailed()
	if self.retryPending or (self.retries or 0) >= RETRIES or not (C_Timer and C_Timer.After) then return end
	self.retryPending = true
	C_Timer.After(RETRY_DELAY, function()
		self.retryPending = nil
		self.retries = (self.retries or 0) + 1
		for _, row in ipairs(self.rows or {}) do
			if row.failed then self:ApplyRow(row) end
		end
		local any = false
		for _, row in ipairs(self.rows or {}) do any = any or row.failed end
		if not any then self.retries = 0; self:Layout() end
	end)
end

-- Places the rows: starred first, then in order, each row's specimens flowing
-- to a new line when they would run past the window's width.
function FD:Layout()
	local ordered = {}
	for _, row in ipairs(self.rows) do ordered[#ordered + 1] = row end
	table.sort(ordered, function(a, b)
		local sa, sb = self.starred[a.def.key] and 0 or 1, self.starred[b.def.key] and 0 or 1
		if sa ~= sb then return sa < sb end
		return a.index < b.index
	end)

	local scale = self.settings.scale
	local room = (WINDOW_WIDTH - 2 * ROW_PAD - NAME_WIDTH - 24) / scale
	local y = 0
	for _, row in ipairs(ordered) do
		local x, line, lineHeight = 0, 0, 0
		for _, group in ipairs(row.groups) do
			local w, h = group.measure()
			group:SetSize(w, h)
			if x > 0 and x + w > room then
				line, x, lineHeight = line + lineHeight + 8, 0, 0
			end
			group:ClearAllPoints()
			group:SetPoint('TOPLEFT', row.specimen, 'TOPLEFT', x, -line)
			x = x + w + 24
			lineHeight = math.max(lineHeight, h)
		end
		local height = line + lineHeight
		row.specimen:SetScale(scale)
		row.specimen:SetSize(room, math.max(height, 1))
		row.specimen:ClearAllPoints()
		row.specimen:SetPoint('TOPLEFT', row.frame, 'TOPLEFT', NAME_WIDTH / scale, -ROW_PAD / scale)
		local rowHeight = math.max(34, height * scale) + 2 * ROW_PAD
		row.frame:SetSize(WINDOW_WIDTH - 2 * ROW_PAD - 24, rowHeight)
		row.frame:ClearAllPoints()
		row.frame:SetPoint('TOPLEFT', self.content, 'TOPLEFT', 0, -y)
		row.marker:SetShown(self.starred[row.def.key] and true or false)
		y = y + rowHeight + 4
	end
	self.content:SetSize(WINDOW_WIDTH - 2 * ROW_PAD - 24, math.max(y, 1))
	self.scroll:UpdateScrollChildRect()
	self.ordered = ordered
end

function FD:Refresh()
	if not self.window then return end
	for _, row in ipairs(self.rows) do self:ApplyRow(row) end
	self:Layout()
	self:LightControls()
end

function FD:SetSize(size)
	size = math.min(self.MAX_SIZE, math.max(self.MIN_SIZE, math.floor(size + 0.5)))
	self.settings.size = size
	self:Refresh()
end

function FD:SetOutline(key)
	self.settings.outline = key
	self:Refresh()
end

function FD:SetShadow(on)
	self.settings.shadow = on and true or false
	self:Refresh()
end

function FD:SetScale(scale)
	self.settings.scale = scale
	self:Refresh()
end

-- Clicking a row's name stars it (or takes the star off); starred rows sort to
-- the top.
function FD:ToggleStar(key)
	self.starred[key] = not self.starred[key] or nil
	self:Layout()
end

local function BuildRow(self, def, index)
	local row = { def = def, index = index, texts = {}, groups = {} }
	local frame = Box(self.content, 100, 60, { 0, 0, 0, 0.45 }, { 1, 1, 1, 0.12 })
	if def.today then frame:SetBackdropBorderColor(0.88, 0.63, 0.25, 1) end
	row.frame = frame

	local name = CreateFrame('Button', nil, frame)
	name:SetSize(NAME_WIDTH - 12, 34)
	name:SetPoint('TOPLEFT', frame, 'TOPLEFT', 6, -ROW_PAD)
	local marker = frame:CreateTexture(nil, 'OVERLAY')
	marker:SetColorTexture(1, 0.82, 0, 1)
	marker:SetSize(6, 6)
	marker:SetPoint('TOPLEFT', frame, 'TOPLEFT', 6, -ROW_PAD - 4)
	marker:Hide()
	row.marker = marker
	local label = name:CreateFontString(nil, 'OVERLAY')
	label:SetFontObject(st:GetFont('normal'))
	label:SetText(def.label .. (def.today and ' (today)' or ''))
	label:SetJustifyH('LEFT')
	label:SetJustifyV('TOP')
	label:SetPoint('TOPLEFT', name, 'TOPLEFT', 10, 0)
	label:SetPoint('RIGHT', name, 'RIGHT', 0, 0)
	name:SetScript('OnClick', function() FD:ToggleStar(def.key) end)
	row.name = name

	row.specimen = CreateFrame('Frame', nil, frame)
	row.failure = frame:CreateFontString(nil, 'OVERLAY')
	row.failure:SetFontObject(st:GetFont('normal'))
	row.failure:SetText('failed to load')
	row.failure:SetTextColor(1, 0.3, 0.3)
	row.failure:SetPoint('LEFT', frame, 'LEFT', NAME_WIDTH, 0)
	row.failure:Hide()

	for _, build in ipairs(GROUPS) do
		row.groups[#row.groups + 1] = build(row, row.specimen)
	end
	return row
end

-- A small button of Core's that lights while it is the choice.
local function Choice(parent, text, width, onClick)
	local button = st:CreateButton(nil, parent, text)
	button:SetSize(width, 22)
	button:SetScript('OnClick', onClick)
	return button
end

local function Label(parent, text)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(st:GetFont('normal'))
	fs:SetText(text)
	return fs
end

-- Lights the button of the current choice, and dims the others.
local function Light(buttons, picked)
	for key, button in pairs(buttons) do
		local on = key == picked
		st:SetButtonPressed(button, on)
		if on then button.text:SetTextColor(unpack(LIT)) else button.text:SetTextColor(1, 1, 1) end
	end
end

function FD:LightControls()
	local s = self.settings
	Light(self.outlineButtons, s.outline)
	Light(self.shadowButtons, s.shadow and 'on' or 'off')
	Light(self.scaleButtons, s.scale)
	self.sizeValue:SetText(tostring(s.size))
end

local function BuildControls(self, parent)
	local bar = CreateFrame('Frame', nil, parent)
	bar:SetHeight(CONTROLS_HEIGHT)

	-- Size.
	local sizeLabel = Label(bar, 'Size')
	sizeLabel:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, -4)
	local slider = CreateFrame('Slider', nil, bar)
	slider:SetOrientation('HORIZONTAL')
	slider:SetSize(220, 16)
	slider:SetPoint('LEFT', sizeLabel, 'RIGHT', 14, 0)
	slider:EnableMouse(true)
	local track = slider:CreateTexture(nil, 'BACKGROUND')
	track:SetColorTexture(0.25, 0.25, 0.25, 1)
	track:SetPoint('LEFT', slider, 'LEFT', 0, 0)
	track:SetPoint('RIGHT', slider, 'RIGHT', 0, 0)
	track:SetHeight(4)
	slider:SetThumbTexture(st.BLANK_TEX)
	slider:GetThumbTexture():SetSize(8, 16)
	slider:SetMinMaxValues(self.MIN_SIZE, self.MAX_SIZE)
	slider:SetValueStep(1)
	slider:SetObeyStepOnDrag(true)
	slider:SetValue(self.settings.size)
	slider:SetScript('OnValueChanged', function(_, value)
		local size = math.floor(value + 0.5)
		if size ~= FD.settings.size then FD:SetSize(size) end
	end)
	self.slider = slider
	self.sizeValue = Label(bar, '')
	self.sizeValue:SetPoint('LEFT', slider, 'RIGHT', 12, 0)

	-- Shadow.
	local shadowLabel = Label(bar, 'Shadow')
	shadowLabel:SetPoint('LEFT', self.sizeValue, 'RIGHT', 60, 0)
	self.shadowButtons = {}
	local previous = shadowLabel
	for _, choice in ipairs({ { 'off', 'Off', false }, { 'on', 'Shadow', true } }) do
		local button = Choice(bar, choice[2], 60, function() FD:SetShadow(choice[3]) end)
		button:SetPoint('LEFT', previous, 'RIGHT', 10, 0)
		self.shadowButtons[choice[1]] = button
		previous = button
	end

	-- Outline.
	local outlineLabel = Label(bar, 'Outline')
	outlineLabel:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, -34)
	self.outlineButtons = {}
	previous = outlineLabel
	for _, o in ipairs(self.OUTLINES) do
		local button = Choice(bar, o.label, 120, function() FD:SetOutline(o.key) end)
		button:SetPoint('LEFT', previous, 'RIGHT', previous == outlineLabel and 14 or 4, 0)
		self.outlineButtons[o.key] = button
		previous = button
	end

	-- Scale.
	local scaleLabel = Label(bar, 'Scale')
	scaleLabel:SetPoint('TOPLEFT', bar, 'TOPLEFT', 0, -64)
	self.scaleButtons = {}
	previous = scaleLabel
	for _, scale in ipairs(self.SCALES) do
		local button = Choice(bar, tostring(scale), 60, function() FD:SetScale(scale) end)
		button:SetPoint('LEFT', previous, 'RIGHT', previous == scaleLabel and 14 or 4, 0)
		self.scaleButtons[scale] = button
		previous = button
	end
	local note = bar:CreateFontString(nil, 'OVERLAY')
	note:SetFontObject(st:GetFont('pixel'))
	note:SetText('Scale resizes the specimens only. Click a name to star it. Mouse wheel scrolls. The second Homespun row stays at 10.')
	note:SetTextColor(unpack(FADED))
	note:SetPoint('LEFT', previous, 'RIGHT', 20, 0)
	return bar
end

-- Esc closes the window, through a keyboard catcher of ours (not Blizzard's
-- UISpecialFrames, which this repo doesn't write to). It is a child of the
-- window, so it only gets keys while the window is shown; any other key goes
-- on to the game.
local function EscapeKeys(window)
	local keys = CreateFrame('Frame', nil, window)
	keys:EnableKeyboard(true)
	keys:SetScript('OnKeyDown', function(self, key)
		if InCombatLockdown() then return end
		if GetCurrentKeyBoardFocus() then
			self:SetPropagateKeyboardInput(true)
			return
		end
		local escape = key == 'ESCAPE'
		self:SetPropagateKeyboardInput(not escape)
		if escape then window:Hide() end
	end)
	return keys
end

function FD:Build()
	local height = math.min(900, math.floor(UIParent:GetHeight()) - 60)
	local window = st:CreatePanel('Small text fonts (demo)', WINDOW_WIDTH, height)
	window:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	window:SetFrameStrata('DIALOG')
	window:EnableMouse(true)
	window:Hide()
	self.window = window
	EscapeKeys(window)

	local top = st:HeaderRoom(window) + ROW_PAD
	local controls = BuildControls(self, window)
	controls:SetPoint('TOPLEFT', window, 'TOPLEFT', ROW_PAD + 4, -top)
	controls:SetPoint('TOPRIGHT', window, 'TOPRIGHT', -ROW_PAD - 4, -top)

	local scroll = CreateFrame('ScrollFrame', nil, window)
	scroll:SetPoint('TOPLEFT', controls, 'BOTTOMLEFT', -4, -4)
	scroll:SetPoint('BOTTOMRIGHT', window, 'BOTTOMRIGHT', -ROW_PAD, ROW_PAD)
	scroll:EnableMouseWheel(true)
	scroll:SetScript('OnMouseWheel', function(self, delta)
		local target = self:GetVerticalScroll() - delta * 60
		local range = math.max(0, FD.content:GetHeight() - self:GetHeight())
		self:SetVerticalScroll(math.max(0, math.min(range, target)))
	end)
	local content = CreateFrame('Frame', nil, scroll)
	content:SetSize(WINDOW_WIDTH - 2 * ROW_PAD - 24, 1)
	scroll:SetScrollChild(content)
	self.scroll, self.content = scroll, content

	for index, def in ipairs(RowDefs()) do
		self.rows[#self.rows + 1] = BuildRow(self, def, index)
	end
	self:Refresh()
end

function FD:Toggle()
	if not self.window then self:Build() end
	if self.window:IsShown() then self.window:Hide() else self.window:Show() end
end

-- TEMPORARY DIAGNOSTIC (2026-11-13): in game every candidate failed to load
-- after a full restart, though the files are sound and on disk. "/suifonts test"
-- prints what SetFont returns for the same font file under different folders and
-- names, to tell a folder problem from a name problem from a file problem.
-- Delete this block and the four test files it names once that is known.
local DIAG = {
	{ 'a working font, as a control', 'AgencyFB_Bold.ttf' },
	{ 'an OLD file nothing has used (visitor2)', 'visitor2.ttf' },
	{ 'an OLD file nothing has used, in a folder (FiraCode Light)', 'FiraCode\\FiraCode-Light.ttf' },
	{ 'a copy of the working font, in Candidates', 'Candidates\\agencycopy.ttf' },
	{ 'a candidate, in Candidates, its own name', 'Candidates\\BarlowCondensed-SemiBold.ttf' },
	{ 'the same candidate, in Candidates, a plain name', 'Candidates\\barlowtest.ttf' },
	{ 'the same candidate, beside the working fonts, its own name', 'BarlowCondensed-SemiBold.ttf' },
	{ 'the same candidate, beside the working fonts, a plain name', 'barlowtest.ttf' },
}

-- Each test: a shown font string with text (in case the game only loads a
-- font it has to draw), SetFont's result now, and again 2 and 10 seconds
-- later; then the same path on a font object (CreateFont), which is how
-- SaftUI's own fonts are set.
function FD:Diagnose()
	local holder = self.diagHolder
	if not holder then
		holder = CreateFrame('Frame', nil, UIParent)
		holder:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 4, 4)
		holder:SetSize(10, 10)
		holder:SetAlpha(0.02)
		self.diagHolder = holder
	end
	self.diagRun = (self.diagRun or 0) + 1
	local run = self.diagRun
	print('|cff00adefSaftUI font test|r run ' .. run .. ' (true = loaded). Wait ten seconds for the two later lines.')
	local strings, objects = {}, {}
	for i, test in ipairs(DIAG) do
		local path = st:FontPath(test[2])
		local fs = holder:CreateFontString(nil, 'OVERLAY')
		fs:SetPoint('BOTTOMLEFT', holder, 'BOTTOMLEFT', 0, 0)
		local ok = fs:SetFont(path, 12, '')
		if ok then fs:SetText('Test 123') end
		strings[i] = fs
		local object = CreateFont('SaftUIFontTest' .. run .. '_' .. i)
		local okObject = object:SetFont(path, 12, '')
		objects[i] = object
		print(('%d. %s: string %s, font object %s'):format(i, test[1], tostring(ok), tostring(okObject)))
		print('   ' .. path)
	end
	local function Again(label)
		local a, b = {}, {}
		for i, test in ipairs(DIAG) do
			local path = st:FontPath(test[2])
			a[i] = tostring(strings[i]:SetFont(path, 12, ''))
			b[i] = tostring(objects[i]:SetFont(path, 12, ''))
		end
		print('|cff00adefSaftUI font test|r ' .. label .. ': strings ' .. table.concat(a, ', '))
		print('   font objects ' .. table.concat(b, ', '))
	end
	if C_Timer and C_Timer.After then
		C_Timer.After(2, function() Again('2 seconds later') end)
		C_Timer.After(10, function() Again('10 seconds later') end)
	end
end

SLASH_SAFTUIFONTS1 = '/suifonts'
SlashCmdList['SAFTUIFONTS'] = function(msg)
	if msg and msg:lower():match('^%s*test') then FD:Diagnose() else FD:Toggle() end
end
