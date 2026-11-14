--[[
	Blizzard's objective tracker (Blizzard_ObjectiveTracker), as far as SaftUI's
	skin (SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua) and its
	mover (Blizzard_ObjectiveTrackerPosition.lua) read and drive it. Load it with
	`local OT = load_test_file('misc/fixtures/objective_tracker.lua')`, then
	OT.build() makes what the game makes when the addon loads (both clients have
	the same files; checked 2026-11-13 against the forever and live branches of
	Gethe/wow-ui-source):

	  - ObjectiveTrackerFrame (Blizzard_ObjectiveTracker.xml): 260 wide, LOW
	    strata, kept on screen by its own clamp (EditModeSystemTemplate's
	    clampedToScreen; its AnchorSelectionFrame never sets insets), its Edit
	    Mode box (Selection, hidden), its NineSlice, and its Header
	    (ObjectiveTrackerContainerHeaderTemplate: Background, Text in
	    ObjectiveTrackerHeaderFont, an 18 by 19 MinimizeButton with the
	    collapse-all atlases, and SetCollapsed swapping them). Edit Mode's
	    SetPoint and ClearAllPoints overrides (EditModeSystemMixin:OnSystemLoad)
	    count Blizzard's calls in OT.calls. UpdateHeight is Blizzard's
	    (ObjectiveTrackerContainerMixin): in the default position the parent's
	    height plus its first point's y offset, at least 20; moved in Blizzard's
	    Edit Mode its Height setting, else 800. Its topPadding is 15 on Forever
	    and 0 on retail (the XML's KeyValues).
	  - RightManagedFrameContainer (Blizzard_ManagedFrameSystem): placed at
	    TOPRIGHT -5, -260 (EditModeUtil:GetRightContainerAnchor with no right
	    action bars shown) and as tall as UIParent less the MinimapCluster
	    (OT.MINIMAP) less 100 (ManageRightFrameContainer's fixedHeight). Its
	    Layout puts the tracker, while it's shown and in its default position,
	    at its own top right less the tracker's topPadding, as
	    LayoutMixin:LayoutChildren does.
	  - The eleven modules (ObjectiveTrackerManager:Init's list), each a frame
	    with its Header (ObjectiveTrackerModuleHeaderTemplate: Background, Text,
	    Shine, Glow, a 16 by 16 MinimizeButton whose OnClick toggles the module,
	    SetCollapsed), its ContentsFrame and ObjectiveTrackerModuleMixin's
	    GetBlock, GetProgressBar, GetTimerBar, GetRightEdgeFrame and
	    AcquireFrame as fields (the XML mixin copies them onto the frame). The
	    quest module's block and line templates, the bonus and scenario
	    modules' progress bar templates, and the scenario module's fixed
	    ObjectivesBlock are theirs.
	  - The frame pools (ObjectiveTrackerManager:AcquireFrame, one pool per
	    template across modules): a released frame is hidden, its anchors
	    cleared, and handed out again before a new one is made; a new one gets
	    its template in frame.template.
	  - The templates: blocks (HeaderText in ObjectiveTrackerLineFont, Init,
	    Reset, GetLine, SetHeader, AddObjective, AddProgressBar, AddTimerBar,
	    AddRightEdgeFrame); lines (Dash and Text in ObjectiveTrackerLineFont);
	    ObjectiveTrackerProgressBarTemplate (its Bar's BorderLeft, BorderRight,
	    BorderMid and keyless background, the bar texture, Label);
	    BonusTrackerProgressBarTemplate and ScenarioProgressBarTemplate (BarFrame,
	    IconBG, BarFrame2 and 3, BarBG, Icon, BarGlow, Sheen, Starburst, Label,
	    and the flare frames); ObjectiveTrackerTimerBarTemplate (its Bar's
	    borders and background, its own Label); QuestObjectiveItemButtonTemplate
	    (icon, Count, HotKey, Cooldown, Glow, NormalTexture, pushed and highlight
	    textures, and SetUp: the attributes, then SetItemButtonTexture, which
	    sets the icon and resets its tex coords to the whole texture). With
	    OT.build{ protect_items = true } each item button counts as
	    protected, the worst case (none is secure in either client's XML).
	  - Blizzard's fonts the templates inherit.

	The drivers run Blizzard's own code paths:
	  - OT.layout(module, quests): a module's layout (BeginLayout,
	    LayoutContents, EndLayout): a block per quest (GetBlock, SetHeader),
	    a line per objective (AddObjective, which measures the text with
	    SetStringText once GetLine returns: OT.measured[fontString] is the font
	    it was measured in), and a progress bar, a timer bar or an item button
	    where the quest asks for one; then everything not used again is
	    released. Returns the blocks in order.
	  - OT.show(), OT.manage(), OT.apply_layout() and OT.break_snap(): the
	    tracker showing in its default position (ManagedFrameMixin:OnShow,
	    ManagedFrameContainerMixin:UpdateFrame), ManageRightFrameContainer, an
	    Edit Mode layout apply (ApplySystemAnchor), and a snap break
	    (BreakFrameSnap, then UpdateSystemAnchorInfo recording the first point
	    into OT.recorded with its frame's name, and leaving the default
	    position).
	Blizzard's code is secure: the game lets it move a protected frame in
	combat, which the stubs can't tell from addon code, so its own calls on the
	tracker and on the item buttons (moving, showing, hiding, reparenting, an
	attribute) step out of combat for that call only.

	Every Blizzard frame and region here is locked once built
	(lib/locked_widget.lua), so a skin that writes a field onto one, or
	SetScripts one, fails. Blizzard's plain tables are locked too (each module's
	questItemButtonSettings, usedBlocks and its per-template tables,
	usedProgressBars, usedTimerBars, usedRightEdgeFrames, and each block's
	usedLines): a key written into one fails. The fixture's own writes
	(Blizzard's) use rawset. OT.is_blizzard(widget) tells them from the frames
	and textures SaftUI made.

	The tracker and every module have MarkDirty, Update, SetCollapsed and
	UpdateHeight, Blizzard's state-writing Lua, which SaftUI must never call.
	The drivers below (and OT.as_blizzard(fn, ...), for a test standing in for
	Blizzard, and a header button's click) run Blizzard's own calls; one made
	outside them is SaftUI's, and is listed in OT.stray ('tracker:UpdateHeight').

	OT.watch_size() counts the size reads on the tracker and every module, by
	form: OT.size_reads.plain['GetHeight'] and OT.size_reads.ignore['GetHeight']
	(GetWidth, GetHeight and GetSize with ignoreRect true, which skips the rect
	resolve that could run a pending OnSizeChanged inside the caller).

	Not built: the quest log and its events, the dirty updates and the
	container's module stacking, heights (every text measures 12), POI and
	find group buttons, the auto quest popups, the scenario's stage, challenge
	mode and proving grounds blocks, sliding, animations, tooltips, the
	gamepad navigation (Forever) and the rest of Edit Mode.
]]

local lock_widget = load_test_file('lib/locked_widget.lua')
local OWNER = 'Blizzard objective tracker'

local OT = {}
OT.stray = {}

-- Blizzard's own call chains: while one runs, a call of its state-writing
-- methods is Blizzard's, not SaftUI's. Depth, as drivers call each other.
local driving = 0
local function drive(fn, ...)
	driving = driving + 1
	local results = { pcall(fn, ...) }
	driving = driving - 1
	if not results[1] then error(results[2], 0) end
	return unpack(results, 2, table.maxn(results))
end
OT.as_blizzard = drive

-- Wraps frame[name] so a call from outside Blizzard's drivers is recorded.
local function guard(frame, label, name)
	local fn = frame[name]
	rawset(frame, name, function(self, ...)
		if driving == 0 then OT.stray[#OT.stray + 1] = label .. ':' .. name end
		return fn(self, ...)
	end)
end
local GUARDED = { 'MarkDirty', 'Update', 'SetCollapsed', 'UpdateHeight' }

-- A plain table of Blizzard's, locked: a key written into it errors. The
-- fixture's own writes use rawset.
local function lock_table(t, what)
	return setmetatable(t, {
		__newindex = function(_, key)
			error(('skin wrote key "%s" into Blizzard\'s %s'):format(tostring(key), what), 2)
		end,
	})
end

-- Every frame and region of Blizzard's built here, locked.
local blizzard = setmetatable({}, { __mode = 'k' })
local function lock(widget, owner)
	blizzard[widget] = true
	return lock_widget(widget, owner)
end

-- Whether widget is one of Blizzard's (built here), not one SaftUI made.
function OT.is_blizzard(widget) return blizzard[widget] == true end

OT.MODULES = {
	'ScenarioObjectiveTracker', 'UIWidgetObjectiveTracker', 'CampaignQuestObjectiveTracker',
	'QuestObjectiveTracker', 'AdventureObjectiveTracker', 'AchievementObjectiveTracker',
	'MonthlyActivitiesObjectiveTracker', 'InitiativeTasksObjectiveTracker', 'ProfessionsRecipeTracker',
	'BonusObjectiveTracker', 'WorldQuestObjectiveTracker',
}
OT.ITEM_TEMPLATE = 'QuestObjectiveItemButtonTemplate'
OT.BAR_TEXTURE = [[Interface\TargetingFrame\UI-StatusBar]]
OT.MINIMAP = 200 -- MinimapCluster's height, for the right container's
OT.CONTAINER_TOP = -260 -- RIGHT_CONTAINER_OFFSET_Y

-- Blizzard's fonts the templates inherit, with the color each gives its text.
local FONTS = {
	ObjectiveTrackerLineFont = { 12, '', { 0.8, 0.8, 0.8 } },
	ObjectiveTrackerHeaderFont = { 14, '', { 1, 0.82, 0 } },
	GameFontHighlightMedium = { 14, '', { 1, 1, 1 } },
	NumberFontNormal = { 14, 'OUTLINE', { 1, 1, 1 } },
	NumberFontNormalSmallGray = { 12, 'OUTLINE', { 0.6, 0.6, 0.6 } },
}
for name, font in pairs(FONTS) do
	if not _G[name] then
		local object = CreateFont(name)
		object:SetFont([[Fonts\FRIZQT__.TTF]], font[1], font[2])
		object:SetTextColor(unpack(font[3]))
	end
end

-- Runs one of Blizzard's own calls on its frames: secure code, which the game
-- lets move a protected frame in combat.
local function secure(fn, ...)
	local combat = stub.in_combat
	stub.in_combat = false
	local results = { fn(...) }
	stub.in_combat = combat
	return unpack(results)
end

-- Locks frame and every region on it.
local function lock_all(frame)
	for _, region in ipairs({ frame:GetRegions() }) do lock(region, OWNER) end
	return lock(frame, OWNER)
end

-- A button with Blizzard's three state textures (their atlases, as the
-- templates' NormalTexture, PushedTexture and HighlightTexture make them).
local function state_button(parent, width, height, normal, pushed, highlight)
	local button = CreateFrame('Button', nil, parent)
	button:SetSize(width, height)
	local n = button:CreateTexture(nil, 'ARTWORK')
	n:SetAtlas(normal, true)
	button:SetNormalTexture(n)
	local p = button:CreateTexture(nil, 'ARTWORK')
	p:SetAtlas(pushed, true)
	button:SetPushedTexture(p)
	local h = button:CreateTexture(nil, 'HIGHLIGHT')
	h:SetAtlas(highlight, true)
	button:SetHighlightTexture(h, 'ADD')
	return button
end

-- A header: the container's (ObjectiveTrackerContainerHeaderTemplate) or a
-- module's (ObjectiveTrackerModuleHeaderTemplate, with its Shine and Glow).
local HEADERS = {
	container = {
		height = 32, background = 'ui-questtracker-primary-objective-header', button = { 18, 19, -1 },
		collapse = 'ui-questtrackerbutton-collapse-all', expand = 'ui-questtrackerbutton-expand-all',
		highlight = 'ui-questtrackerbutton-red-highlight',
	},
	module = {
		height = 26, background = 'UI-QuestTracker-Secondary-Objective-Header', button = { 16, 16, 1 },
		collapse = 'ui-questtrackerbutton-secondary-collapse', expand = 'ui-questtrackerbutton-secondary-expand',
		highlight = 'ui-questtrackerbutton-yellow-highlight',
	},
}

local function header(parent, kind)
	local spec = HEADERS[kind]
	local frame = CreateFrame('Frame', nil, parent)
	frame:SetSize(260, spec.height)
	frame:SetPoint('TOPLEFT')
	local background = frame:CreateTexture(nil, 'BACKGROUND')
	background:SetAtlas(spec.background, true)
	background:SetPoint('CENTER')
	rawset(frame, 'Background', background)
	local text = frame:CreateFontString(nil, 'ARTWORK', 'ObjectiveTrackerHeaderFont')
	text:SetPoint('LEFT', 7, 0)
	rawset(frame, 'Text', text)
	if kind == 'module' then
		local shine = frame:CreateTexture(nil, 'ARTWORK')
		shine:SetAtlas('UI-QuestTracker-OBJFX-Shine', true)
		shine:SetAlpha(0)
		rawset(frame, 'Shine', shine)
		local glow = frame:CreateTexture(nil, 'OVERLAY')
		glow:SetAtlas('UI-QuestTracker-OBJFX-BarGlow', true)
		glow:SetAlpha(0)
		rawset(frame, 'Glow', glow)
	end
	local width, height, x = unpack(spec.button)
	local button = state_button(frame, width, height, spec.collapse, spec.collapse .. '-pressed', spec.highlight)
	button:SetPoint('RIGHT', x, 0)
	rawset(frame, 'MinimizeButton', button)
	-- ObjectiveTracker*HeaderMixin:SetCollapsed: the atlases only.
	rawset(frame, 'SetCollapsed', function(self, collapsed)
		local atlas = collapsed and spec.expand or spec.collapse
		self.MinimizeButton:GetNormalTexture():SetAtlas(atlas, true)
		self.MinimizeButton:GetPushedTexture():SetAtlas(atlas .. '-pressed', true)
	end)
	-- OnLoad: the button toggles its owner (OnToggle), whose SetCollapsed
	-- calls the header's.
	button:SetScript('OnClick', function()
		local owner = frame:GetParent()
		drive(owner.SetCollapsed, owner, not owner:IsCollapsed())
	end)
	frame:SetCollapsed(false)
	lock_all(button)
	return lock_all(frame)
end

------------------------------------------------------------------ pools

local TEMPLATES = {}
local pools = {}

-- ObjectiveTrackerManager:AcquireFrame: one pool per template.
local function acquire(template)
	local pool = pools[template]
	if not pool then
		pool = {}
		pools[template] = pool
	end
	local frame = table.remove(pool)
	if frame then return frame, false end
	frame = TEMPLATES[template]()
	rawset(frame, 'template', template)
	OT.made[#OT.made + 1] = frame
	return frame, true
end

local function release(frame)
	secure(frame.Hide, frame)
	secure(frame.ClearAllPoints, frame)
	table.insert(pools[frame.template], frame)
end

------------------------------------------------------------------ lines and blocks

local function set_string_text(fontString, text, color)
	fontString:SetHeight(0)
	fontString:SetText(text)
	OT.measured[fontString] = fontString:GetFontObject()
	if fontString.colorStyle ~= color then
		fontString:SetTextColor(color[1], color[2], color[3])
		rawset(fontString, 'colorStyle', color)
	end
	return 12
end

OT.NORMAL = { 0.8, 0.8, 0.8 }
OT.HEADER = { 1, 0.82, 0 }

local function line_template()
	local line = CreateFrame('Frame', nil, UIParent)
	line:Hide()
	local dash = line:CreateFontString(nil, 'ARTWORK', 'ObjectiveTrackerLineFont')
	dash:SetPoint('TOPLEFT', 0, 1)
	dash:SetText('- ')
	rawset(line, 'Dash', dash)
	local text = line:CreateFontString(nil, 'ARTWORK', 'ObjectiveTrackerLineFont')
	text:SetPoint('TOP')
	text:SetPoint('LEFT', dash, 'RIGHT')
	text:SetPoint('RIGHT')
	rawset(line, 'Text', text)
	return lock_all(line)
end
for _, name in ipairs({ 'ObjectiveTrackerLineTemplate', 'ObjectiveTrackerAnimLineTemplate', 'QuestObjectiveLineTemplate' }) do
	TEMPLATES[name] = line_template
end

local BLOCK = {}

function BLOCK:Init()
	rawset(self, 'usedLines', lock_table({}, 'block.usedLines'))
	rawset(self, 'rightEdgeOffset', 0)
end

function BLOCK:Reset()
	rawset(self, 'used', false)
	rawset(self, 'height', 0)
	rawset(self, 'lastRegion', nil)
	rawset(self, 'rightEdgeFrame', nil)
	for _, line in pairs(self.usedLines) do rawset(line, 'used', nil) end
end

function BLOCK:GetLine(objectiveKey, optTemplate)
	local template = optTemplate or self.parentModule.lineTemplate
	local line = self.usedLines[objectiveKey]
	if line and line.template ~= template then
		self.usedLines[objectiveKey] = nil
		release(line)
		line = nil
	end
	if not line then
		line = acquire(template)
		line:SetParent(self)
		line:Show()
	end
	rawset(self.usedLines, objectiveKey, line)
	rawset(line, 'objectiveKey', objectiveKey)
	rawset(line, 'parentBlock', self)
	rawset(line, 'used', true)
	return line
end

function BLOCK:FreeUnusedLines()
	for key, line in pairs(self.usedLines) do
		if not line.used then
			self.usedLines[key] = nil
			release(line)
		end
	end
end

function BLOCK:SetHeader(text)
	rawset(self, 'height', set_string_text(self.HeaderText, text, OT.HEADER))
end

function BLOCK:AddObjective(objectiveKey, text)
	local line = self:GetLine(objectiveKey)
	local anchor = self.lastRegion or self.HeaderText
	line:SetPoint('TOPLEFT', anchor, 'BOTTOMLEFT', 0, -4)
	line:SetPoint('RIGHT', self.rightEdgeOffset, 0)
	local height = set_string_text(line.Text, text, OT.NORMAL)
	line:SetHeight(height)
	rawset(self, 'lastRegion', line)
	return line
end

function BLOCK:AddProgressBar(id)
	local line = self.lastRegion
	if not line then return end
	local bar = self.parentModule:GetProgressBar(line, id)
	bar:SetPoint('TOPLEFT', line, 'BOTTOMLEFT', 0, -4)
	rawset(self, 'lastRegion', bar)
	return bar
end

function BLOCK:AddTimerBar(duration, startTime)
	local line = self.lastRegion
	if not line then return end
	local bar = self.parentModule:GetTimerBar(line)
	bar:SetPoint('TOPLEFT', line, 'BOTTOMLEFT', 0, -4)
	bar.Bar:SetMinMaxValues(0, duration)
	rawset(bar, 'duration', duration)
	rawset(bar, 'startTime', startTime)
	rawset(self, 'lastRegion', bar)
	return bar
end

function BLOCK:AddRightEdgeFrame(settings, identifier)
	local frame = self.parentModule:GetRightEdgeFrame(settings, identifier)
	secure(frame.ClearAllPoints, frame)
	secure(frame.SetPoint, frame, 'TOPRIGHT', self, settings.offsetX, settings.offsetY)
	frame:SetUp(identifier)
	rawset(self, 'rightEdgeFrame', frame)
	return frame
end

local function block_template()
	local block = CreateFrame('Frame', nil, UIParent)
	block:Hide()
	local text = block:CreateFontString(nil, 'ARTWORK', 'ObjectiveTrackerLineFont')
	text:SetPoint('TOPLEFT')
	text:SetPoint('RIGHT')
	rawset(block, 'HeaderText', text)
	local headerButton = CreateFrame('Button', nil, block)
	headerButton:SetPoint('TOPLEFT', text)
	headerButton:SetPoint('BOTTOMRIGHT', text)
	rawset(block, 'HeaderButton', lock(headerButton, OWNER))
	for name, fn in pairs(BLOCK) do rawset(block, name, fn) end
	return lock_all(block)
end
for _, name in ipairs({ 'ObjectiveTrackerBlockTemplate', 'ObjectiveTrackerAnimBlockTemplate',
		'ObjectiveTrackerQuestPOIBlockTemplate', 'BonusObjectiveTrackerBlockTemplate' }) do
	TEMPLATES[name] = block_template
end

------------------------------------------------------------------ bars

-- A StatusBar of Blizzard's: its fill texture, its color and a keyless
-- background in BACKGROUND (<Color r="0.04" g="0.07" b="0.18"/>).
local function status_bar(parent, width, height)
	local bar = CreateFrame('StatusBar', nil, parent)
	bar:SetSize(width, height)
	bar:SetStatusBarTexture(OT.BAR_TEXTURE)
	bar:SetStatusBarColor(0.26, 0.42, 1)
	bar:SetMinMaxValues(0, 100)
	return bar
end

local function bordered(bar, borderHeight)
	for _, key in ipairs({ 'BorderLeft', 'BorderRight', 'BorderMid' }) do
		local border = bar:CreateTexture(nil, 'ARTWORK')
		border:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-Skills-BarBorder]])
		border:SetHeight(borderHeight)
		rawset(bar, key, border)
	end
	bar.BorderLeft:SetPoint('LEFT', -3, 0)
	bar.BorderRight:SetPoint('RIGHT', 3, 0)
	bar.BorderMid:SetPoint('TOPLEFT', bar.BorderLeft, 'TOPRIGHT')
	bar.BorderMid:SetPoint('BOTTOMRIGHT', bar.BorderRight, 'BOTTOMLEFT')
	local background = bar:CreateTexture(nil, 'BACKGROUND', nil, -1)
	background:SetColorTexture(0.04, 0.07, 0.18)
	background:SetAllPoints()
end

-- ObjectiveTrackerProgressBarTemplate.
TEMPLATES.ObjectiveTrackerProgressBarTemplate = function()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(192, 25)
	frame:Hide()
	local bar = status_bar(frame, 180, 15)
	bar:SetPoint('RIGHT', 15, 0)
	bordered(bar, 22)
	local label = bar:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightMedium')
	label:SetPoint('CENTER', 0, -1)
	rawset(bar, 'Label', label)
	rawset(frame, 'Bar', lock_all(bar))
	return lock_all(frame)
end

-- BonusTrackerProgressBarTemplate and ScenarioProgressBarTemplate: the same
-- bar, its art and its flares.
local BONUS_ALPHA = { 'BarFrame2', 'BarFrame3', 'BarGlow', 'Sheen', 'Starburst' }
OT.FLARES = { 'Flare1', 'Flare2', 'SmallFlare1', 'SmallFlare2', 'FullBarFlare1', 'FullBarFlare2' }
local function bonus_bar()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(192, 38)
	frame:Hide()
	local bar = status_bar(frame, 191, 17)
	bar:SetPoint('LEFT', 10, 0)
	local barFrame = bar:CreateTexture(nil, 'ARTWORK')
	barFrame:SetAtlas('bonusobjectives-bar-frame-5', true)
	barFrame:SetPoint('LEFT', -8, -1)
	rawset(bar, 'BarFrame', barFrame)
	local iconBG = bar:CreateTexture(nil, 'ARTWORK')
	iconBG:SetAtlas('bonusobjectives-bar-ring', true)
	iconBG:SetPoint('RIGHT', barFrame, 0, 0)
	rawset(bar, 'IconBG', iconBG)
	local label = bar:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightMedium')
	label:SetPoint('CENTER', -1, -1)
	rawset(bar, 'Label', label)
	for _, key in ipairs(BONUS_ALPHA) do
		local texture = bar:CreateTexture(nil, 'OVERLAY')
		texture:SetAtlas('bonusobjectives-bar-glow', true)
		texture:SetAlpha(0)
		rawset(bar, key, texture)
	end
	local barBG = bar:CreateTexture(nil, 'BACKGROUND', nil, -1)
	barBG:SetColorTexture(0.04, 0.07, 0.18)
	barBG:SetAllPoints()
	rawset(bar, 'BarBG', barBG)
	local icon = bar:CreateTexture(nil, 'BACKGROUND', nil, -1)
	icon:SetSize(32, 32)
	icon:SetPoint('RIGHT', 33, 2)
	rawset(bar, 'Icon', icon)
	for _, key in ipairs(OT.FLARES) do
		local flare = CreateFrame('Frame', nil, frame)
		flare:SetSize(1, 1)
		rawset(frame, key, lock(flare, OWNER))
	end
	rawset(frame, 'Bar', lock_all(bar))
	return lock_all(frame)
end
TEMPLATES.BonusTrackerProgressBarTemplate = bonus_bar
TEMPLATES.ScenarioProgressBarTemplate = bonus_bar

-- ObjectiveTrackerTimerBarTemplate.
TEMPLATES.ObjectiveTrackerTimerBarTemplate = function()
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(192, 20)
	frame:Hide()
	local label = frame:CreateFontString(nil, 'ARTWORK', 'GameFontHighlightMedium')
	label:SetPoint('LEFT')
	rawset(frame, 'Label', label)
	local bar = status_bar(frame, 128, 10)
	bar:SetPoint('RIGHT', -4, 0)
	bordered(bar, 14)
	rawset(frame, 'Bar', lock_all(bar))
	return lock_all(frame)
end

------------------------------------------------------------------ the item button

OT.ICON = 133940

-- QuestObjectiveItemButtonTemplate, a plain Button (no secure template) whose
-- OnClick, Blizzard's, calls UseQuestLogSpecialItem.
TEMPLATES.QuestObjectiveItemButtonTemplate = function()
	local button = CreateFrame('Button', nil, UIParent)
	button:SetSize(26, 26)
	button:Hide()
	local glow = button:CreateTexture(nil, 'BACKGROUND')
	glow:SetAtlas('UI-QuestTrackerButton-QuestItem-Frame-Glow', true)
	glow:Hide()
	rawset(button, 'Glow', glow)
	local hotKey = button:CreateFontString(nil, 'ARTWORK', 'NumberFontNormalSmallGray')
	hotKey:SetPoint('TOPRIGHT', 16, -2)
	rawset(button, 'HotKey', hotKey)
	-- No anchors in the XML: a texture with none fills its frame.
	local icon = button:CreateTexture(nil, 'BORDER')
	icon:SetAllPoints()
	rawset(button, 'icon', icon)
	local count = button:CreateFontString(nil, 'BORDER', 'NumberFontNormal')
	count:SetPoint('BOTTOMRIGHT', -3, 2)
	count:Hide()
	rawset(button, 'Count', count)
	local cooldown = CreateFrame('Cooldown', nil, button)
	cooldown:SetAllPoints()
	rawset(button, 'Cooldown', lock(cooldown, OWNER))
	local normal = button:CreateTexture(nil, 'ARTWORK')
	normal:SetAtlas('UI-QuestTrackerButton-QuestItem-Frame')
	normal:SetSize(42, 42)
	normal:SetPoint('CENTER')
	button:SetNormalTexture(normal)
	rawset(button, 'NormalTexture', normal)
	local pushed = button:CreateTexture(nil, 'ARTWORK')
	pushed:SetAtlas('UI-QuestTrackerButton-QuestItem-Frame')
	button:SetPushedTexture(pushed)
	local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
	highlight:SetTexture([[Interface\Buttons\ButtonHilight-Square]])
	button:SetHighlightTexture(highlight, 'ADD')
	button:SetScript('OnClick', function(self) OT.used[#OT.used + 1] = self:GetAttribute('questLogIndex') end)
	if OT.protect_items then
		-- The worst case, for a test: one the game counts as protected.
		rawset(button, 'IsProtected', function() return true, true end)
	end
	-- QuestObjectiveItemButtonMixin:SetUp: the attributes, then
	-- SetItemButtonTexture (the icon, its tex coords reset) and the count.
	rawset(button, 'SetUp', function(self, questLogIndex)
		secure(self.SetAttribute, self, 'questLogIndex', questLogIndex)
		self.icon:Show()
		self.icon:SetTexture(OT.ICON)
		self.icon:SetTexCoord(0, 1, 0, 1)
		self.Count:Hide()
	end)
	return lock_all(button)
end

------------------------------------------------------------------ modules

local MODULE = {}

function MODULE:IsCollapsed() return self.isCollapsed end

function MODULE:SetCollapsed(collapsed)
	rawset(self, 'isCollapsed', collapsed)
	self.ContentsFrame:SetShown(not collapsed)
	self.Header:SetCollapsed(collapsed)
end

-- ObjectiveTrackerModuleMixin's state writers, as far as the fixture goes: only
-- a call from SaftUI matters (OT.stray).
function MODULE:MarkDirty() rawset(self, 'dirty', true) end
function MODULE:Update() rawset(self, 'updated', true) end
function MODULE:UpdateHeight() rawset(self, 'heightUpdated', true) end

function MODULE:AcquireFrame(template)
	local frame, isNew = acquire(template)
	secure(frame.SetParent, frame, self.ContentsFrame)
	return frame, isNew
end

function MODULE:GetBlock(id, optTemplate)
	local template = optTemplate or self.blockTemplate
	if not self.usedBlocks[template] then
		rawset(self.usedBlocks, template, lock_table({}, 'module.usedBlocks[template]'))
	end
	local block = self.usedBlocks[template][id]
	if not block then
		local isNew
		block, isNew = self:AcquireFrame(template)
		rawset(block, 'parentModule', self)
		if isNew then block:Init() end
		rawset(self.usedBlocks[template], id, block)
		rawset(block, 'id', id)
	end
	block:Reset()
	block:ClearAllPoints()
	block:SetPoint('TOP', self.ContentsFrame, 'TOP', 0, -10)
	block:SetPoint('LEFT', 20, 0)
	block:SetPoint('RIGHT')
	return block
end

function MODULE:GetProgressBar(key)
	local bar = self.usedProgressBars[key]
	if not bar then
		bar = self:AcquireFrame(self.progressBarTemplate)
		rawset(self.usedProgressBars, key, bar)
		bar:Show()
	end
	rawset(bar, 'used', true)
	return bar
end

function MODULE:GetTimerBar(key)
	local bar = self.usedTimerBars[key]
	if not bar then
		bar = self:AcquireFrame('ObjectiveTrackerTimerBarTemplate')
		rawset(self.usedTimerBars, key, bar)
		bar:Show()
	end
	rawset(bar, 'used', true)
	return bar
end

function MODULE:GetRightEdgeFrame(settings, identifier)
	local key = tostring(settings) .. identifier
	local frame = self.usedRightEdgeFrames[key]
	if not frame then
		frame = self:AcquireFrame(settings.template)
		secure(frame.Show, frame)
		rawset(self.usedRightEdgeFrames, key, frame)
	end
	rawset(frame, 'used', true)
	return frame
end

local SETTINGS = {
	QuestObjectiveTracker = { lineTemplate = 'QuestObjectiveLineTemplate', blockTemplate = 'ObjectiveTrackerQuestPOIBlockTemplate' },
	CampaignQuestObjectiveTracker = { lineTemplate = 'ObjectiveTrackerAnimLineTemplate', blockTemplate = 'ObjectiveTrackerQuestPOIBlockTemplate' },
	BonusObjectiveTracker = { progressBarTemplate = 'BonusTrackerProgressBarTemplate', lineTemplate = 'ObjectiveTrackerAnimLineTemplate', blockTemplate = 'BonusObjectiveTrackerBlockTemplate' },
	ScenarioObjectiveTracker = { progressBarTemplate = 'ScenarioProgressBarTemplate', lineTemplate = 'ObjectiveTrackerAnimLineTemplate' },
	AchievementObjectiveTracker = { blockTemplate = 'ObjectiveTrackerAnimBlockTemplate', lineTemplate = 'ObjectiveTrackerAnimLineTemplate' },
}

local function module(name, tracker)
	local frame = CreateFrame('Frame', name, tracker)
	frame:SetSize(260, 10)
	frame:SetPoint('TOPLEFT')
	frame:Hide()
	rawset(frame, 'Header', header(frame, 'module'))
	local contents = CreateFrame('Frame', nil, frame)
	contents:SetPoint('TOP', frame.Header, 'BOTTOM')
	contents:SetPoint('LEFT')
	contents:SetPoint('RIGHT')
	contents:SetPoint('BOTTOM')
	rawset(frame, 'ContentsFrame', lock(contents, OWNER))
	rawset(frame, 'blockTemplate', 'ObjectiveTrackerBlockTemplate')
	rawset(frame, 'lineTemplate', 'ObjectiveTrackerLineTemplate')
	rawset(frame, 'progressBarTemplate', 'ObjectiveTrackerProgressBarTemplate')
	rawset(frame, 'questItemButtonSettings', lock_table({ template = OT.ITEM_TEMPLATE, offsetX = 0, offsetY = 0 },
		'module.questItemButtonSettings'))
	for key, value in pairs(SETTINGS[name] or {}) do rawset(frame, key, value) end
	rawset(frame, 'isCollapsed', false)
	rawset(frame, 'usedBlocks', lock_table({}, 'module.usedBlocks'))
	rawset(frame, 'usedProgressBars', lock_table({}, 'module.usedProgressBars'))
	rawset(frame, 'usedTimerBars', lock_table({}, 'module.usedTimerBars'))
	rawset(frame, 'usedRightEdgeFrames', lock_table({}, 'module.usedRightEdgeFrames'))
	for key, fn in pairs(MODULE) do rawset(frame, key, fn) end
	for _, name in ipairs(GUARDED) do guard(frame, 'module ' .. frame:GetName(), name) end
	if name == 'ScenarioObjectiveTracker' then
		-- Its fixed ObjectivesBlock (an ObjectiveTrackerBlockTemplate, Init
		-- and Reset in InitModule).
		local block = block_template()
		block:SetParent(contents)
		rawset(block, 'parentModule', frame)
		block:Init()
		block:Reset()
		rawset(frame, 'ObjectivesBlock', block)
	end
	return lock(frame, OWNER)
end

------------------------------------------------------------------ the tracker

local TRACKER = {}

-- st.forever, read at call time (the world's client).
local function IsForever() return SaftUI.forever end

function TRACKER:IsInDefaultPosition() return self.systemInfo.isInDefaultPosition end
function TRACKER:IsCollapsed() return self.isCollapsed end
function TRACKER:SetCollapsed(collapsed)
	rawset(self, 'isCollapsed', collapsed)
	self.Header:SetCollapsed(collapsed)
end

-- ObjectiveTrackerContainerMixin:MarkDirty (what its OnSizeChanged runs) and
-- Update, as far as the fixture goes.
function TRACKER:MarkDirty() rawset(self, 'dirty', true) end
function TRACKER:Update() rawset(self, 'updated', true) end

-- ObjectiveTrackerContainerMixin:UpdateHeight.
function TRACKER:UpdateHeight()
	if not self:IsInDefaultPosition() then
		secure(self.SetHeight, self, math.max(self.editModeHeight or 800, 0))
		return
	end
	local _, _, _, _, offsetY = self:GetPoint(1)
	if offsetY then
		secure(self.SetHeight, self, math.max(self:GetParent():GetHeight() + offsetY, 20))
	end
end

function OT.build(opts)
	opts = opts or {}
	OT.made, OT.measured, OT.used, OT.recorded = {}, setmetatable({}, { __mode = 'k' }), {}, nil
	OT.protect_items = opts.protect_items
	OT.calls = { SetPoint = 0, ClearAllPoints = 0 }
	OT.stray = {}
	OT.size_reads = nil
	for key in pairs(pools) do pools[key] = nil end

	local container = CreateFrame('Frame', 'RightManagedFrameContainer', UIParent)
	container:SetWidth(260)
	OT.container = container

	local tracker = CreateFrame('Frame', 'ObjectiveTrackerFrame', UIParent)
	tracker:SetSize(260, 32)
	tracker:SetFrameStrata('LOW')
	tracker:SetClampedToScreen(true)
	tracker:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 0, 0)
	local selection = CreateFrame('Frame', nil, tracker)
	selection:SetPoint('TOPLEFT', tracker, 'TOPLEFT', -30, 0)
	selection:SetPoint('BOTTOMRIGHT')
	selection:Hide()
	rawset(tracker, 'Selection', lock(selection, 'Blizzard Edit Mode box'))
	local nineSlice = CreateFrame('Frame', nil, tracker)
	nineSlice:SetPoint('TOPLEFT', -30, 0)
	nineSlice:SetPoint('TOPRIGHT', 5, 0)
	rawset(tracker, 'NineSlice', lock(nineSlice, OWNER))
	rawset(tracker, 'Header', header(tracker, 'container'))
	rawset(tracker, 'isCollapsed', false)
	rawset(tracker, 'topPadding', IsForever() and 15 or 0)
	rawset(tracker, 'systemInfo', { isInDefaultPosition = opts.moved == nil })
	rawset(tracker, 'editModeHeight', opts.height)
	rawset(tracker, 'anchorInfo', opts.moved)
	for key, fn in pairs(TRACKER) do rawset(tracker, key, fn) end
	for _, name in ipairs(GUARDED) do guard(tracker, 'tracker', name) end
	-- Edit Mode's overrides (SetPointOverride, ClearAllPointsOverride), which
	-- addon code must never call. Blizzard's code calls them, as secure code.
	local methods = getmetatable(tracker).__index
	rawset(tracker, 'SetPoint', function(self, ...)
		OT.calls.SetPoint = OT.calls.SetPoint + 1
		secure(methods.SetPoint, self, ...)
	end)
	rawset(tracker, 'ClearAllPoints', function(self)
		OT.calls.ClearAllPoints = OT.calls.ClearAllPoints + 1
		secure(methods.ClearAllPoints, self)
	end)
	if opts.protected then
		rawset(tracker, 'IsProtected', function() return true, true end)
	end
	OT.modules = {}
	for _, name in ipairs(OT.MODULES) do
		OT.modules[name] = module(name, tracker)
	end
	OT.tracker = lock(tracker, OWNER)

	-- The container's Layout (LayoutMixin:LayoutChildren, the tracker its one
	-- child, aligned right).
	rawset(container, 'Layout', function(self)
		if tracker:IsShown() and tracker:IsInDefaultPosition() and tracker:GetParent() == self then
			tracker:ClearAllPoints()
			tracker:SetPoint('TOPRIGHT', 0, -tracker.topPadding)
		end
	end)
	OT.container = lock(container, OWNER)
	OT.manage()
	OT.apply_layout()
	return OT.tracker
end

-- ManageRightFrameContainer, then the tracker's height (ManageFramePositions).
function OT.manage(x)
	return drive(function()
		local container = OT.container
		secure(function()
			container:ClearAllPoints()
			container:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', x or -5, OT.CONTAINER_TOP)
			container:SetHeight(UIParent:GetHeight() - OT.MINIMAP - 100)
		end)
		container:Layout()
		if OT.tracker:IsShown() then OT.tracker:UpdateHeight() end
	end)
end

-- The tracker showing in its default position: ManagedFrameMixin:OnShow,
-- AddManagedFrame, UpdateFrame.
function OT.show()
	return drive(function()
		local tracker = OT.tracker
		if not tracker:IsInDefaultPosition() then return end
		tracker:ClearAllPoints()
		secure(tracker.SetParent, tracker, OT.container)
		OT.container:Layout()
		tracker:UpdateHeight()
	end)
end

-- An Edit Mode layout apply (EditModeSystemMixin:ApplySystemAnchor).
function OT.apply_layout()
	return drive(function()
		local tracker = OT.tracker
		if tracker:IsInDefaultPosition() then
			OT.show()
			return
		end
		secure(tracker.SetParent, tracker, UIParent)
		tracker:ClearAllPoints()
		local a = tracker.anchorInfo
		tracker:SetPoint(a.point, UIParent, a.relativePoint, a.offsetX, a.offsetY)
		tracker:UpdateHeight()
	end)
end

-- Blizzard's Edit Mode moving the tracker (a layout apply naming a spot for
-- it): it leaves its default position and is placed at anchor, { point,
-- relativePoint, offsetX, offsetY } on UIParent.
function OT.edit_mode_moves(anchor)
	return drive(function()
		rawset(OT.tracker, 'anchorInfo', anchor)
		OT.tracker.systemInfo.isInDefaultPosition = false
		OT.apply_layout()
	end)
end

-- A snap break (BreakFrameSnap: the tracker put at its own top left on
-- UIParent, then OnSystemPositionChange recording its first point, which a
-- layout save keeps, and leaving its default position).
function OT.break_snap()
	return drive(function()
		local tracker = OT.tracker
		local top, left = tracker:GetTop(), tracker:GetLeft()
		tracker:ClearAllPoints()
		tracker:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', left, top - UIParent:GetHeight())
		local point, relativeTo, relativePoint, x, y = tracker:GetPoint(1)
		OT.recorded = { point = point, relativeTo = relativeTo and relativeTo:GetName(), relativePoint = relativePoint, x = x, y = y }
		tracker.systemInfo.isInDefaultPosition = false
		rawset(tracker, 'anchorInfo', { point = point, relativePoint = relativePoint, offsetX = x, offsetY = y })
	end)
end

-- A module's layout (BeginLayout, LayoutContents, EndLayout). quests: a list
-- of { id, title, objectives = { text, ... }, progress = true, timer = true,
-- item = questLogIndex }. Returns the blocks, in order.
local layout_inner
function OT.layout(module, quests)
	return drive(layout_inner, module, quests)
end

function layout_inner(module, quests)
	for _, blocks in pairs(module.usedBlocks) do
		for _, block in pairs(blocks) do rawset(block, 'used', nil) end
	end
	for _, list in ipairs({ module.usedProgressBars, module.usedTimerBars, module.usedRightEdgeFrames }) do
		for _, frame in pairs(list) do rawset(frame, 'used', nil) end
	end

	local out = {}
	for _, quest in ipairs(quests) do
		local block = module:GetBlock(quest.id)
		block:SetHeader(quest.title or ('Quest ' .. quest.id))
		if quest.item then block:AddRightEdgeFrame(module.questItemButtonSettings, quest.item) end
		for i, text in ipairs(quest.objectives or {}) do block:AddObjective(i, text) end
		if quest.progress then block:AddProgressBar(quest.id) end
		if quest.timer then block:AddTimerBar(60, 0) end
		rawset(block, 'used', true)
		block:Show()
		block:FreeUnusedLines()
		out[#out + 1] = block
	end

	for template, blocks in pairs(module.usedBlocks) do
		for id, block in pairs(blocks) do
			if not block.used then
				for key, line in pairs(block.usedLines) do
					block.usedLines[key] = nil
					release(line)
				end
				blocks[id] = nil
				release(block)
			end
		end
	end
	for _, list in ipairs({ module.usedProgressBars, module.usedTimerBars, module.usedRightEdgeFrames }) do
		for key, frame in pairs(list) do
			if not frame.used then
				list[key] = nil
				release(frame)
			end
		end
	end
	module:Show()
	return out
end

-- Counts the size reads on the tracker and every module from now on, by form
-- (see the top of this file). Call it after OT.build.
function OT.watch_size()
	local counts = { plain = {}, ignore = {} }
	OT.size_reads = counts
	local frames = { OT.tracker }
	for _, name in ipairs(OT.MODULES) do frames[#frames + 1] = OT.modules[name] end
	for _, frame in ipairs(frames) do
		for _, name in ipairs({ 'GetWidth', 'GetHeight', 'GetSize' }) do
			local read = frame[name]
			rawset(frame, name, function(self, ignoreRect, ...)
				local form = ignoreRect and counts.ignore or counts.plain
				form[name] = (form[name] or 0) + 1
				return read(self, ignoreRect, ...)
			end)
		end
	end
end

-- Every frame the pools made with template, in the order made.
function OT.made_with(template)
	local out = {}
	for _, frame in ipairs(OT.made) do
		if frame.template == template then out[#out + 1] = frame end
	end
	return out
end

return OT
