local st = SaftUI
local SK = st:GetModule('Skinning')
local OT = SK:NewModule('Blizzard_ObjectiveTracker')

--[[
	Skins Blizzard's objective tracker (Blizzard_ObjectiveTracker, the same files
	on Forever and retail) in SaftUI's look, while Skinning -> Objective tracker is
	on and the Skinning page's Theme isn't Blizzard. Under the Blizzard theme, or
	with the toggle off, the tracker keeps Blizzard's look: every piece below is
	put back as Blizzard's template had it, and a theme switch or the toggle goes
	between the two live. The tracker's place is Blizzard_ObjectiveTrackerPosition.lua.

	What changes, in the tracker's own fonts (/sui -> Objective Tracker: Font and
	Header font) and the Skinning page's Theme and Background:
	  - Headers (the tracker's own, "All Objectives", and each module's: Quests,
	    Campaign, Scenario, Achievements, ...): Blizzard's banner (Background)
	    and a module header's Shine and Glow hidden, the title in the header
	    font in Blizzard's color, and a 1px line along the header's bottom in
	    the theme's border color.
	  - Collapse buttons (each header's MinimizeButton): Blizzard's art faded,
	    a small box of SaftUI's (kind control) and a chevron, up while the
	    header's contents show and down while they're collapsed, white under
	    the mouse.
	  - Quest titles and objectives (each block's HeaderText, each line's Dash
	    and Text) in the font, in Blizzard's colors. The font goes on the
	    moment Blizzard hands a block or line out (post-hooks on each module's
	    GetBlock and each block's GetLine), before Blizzard sets its text and
	    measures its height (ObjectiveTrackerBlockMixin:SetStringText), so the
	    tracker lays out in SaftUI's font.
	  - A finished objective's line in the Completed color and a failed one's
	    in Failed (/sui -> Objective Tracker: Objective colors). The line's state
	    is read from the color style Blizzard gave its text (colorStyle:
	    OBJECTIVE_TRACKER_COLOR's Complete and Failed), and the color goes on after
	    Blizzard sets its own (post-hooks on each block's AddObjective and
	    UpdateHighlight). Under the mouse a failed line shows Blizzard's brighter
	    red; a completed one, which Blizzard never highlights, stays.
	  - Progress and timer bars: a flat bar in Blizzard's blue with a backdrop
	    of SaftUI's drawn as a bar outside it, Blizzard's border and background
	    art faded, the text in the font. The bonus objective and scenario bars'
	    frame art, flash textures and flares are faded or hidden too; their
	    round reward icon and its ring stay Blizzard's.
	  - Quest item buttons (QuestObjectiveItemButtonTemplate): a backdrop of
	    SaftUI's drawn as an action button, the icon inside its border and
	    cropped square (and kept cropped: Blizzard's SetItemButtonTexture puts
	    the whole texture back on every SetUp), Blizzard's round frame, pushed
	    and highlight art faded, a flat hover in SaftUI's action bars' blue,
	    the count in the Skinning font.

	Left as Blizzard's: the tracker's background (NineSlice, Blizzard's Opacity
	setting), POI and find group buttons, auto quest popups, the scenario's
	stage, challenge mode and proving grounds banners, UI widgets, the reward
	toasts, the bars' reward icons, and every animation.

	Taint (.agents/taint.md). Nothing is written onto Blizzard's frames or
	tables: SaftUI's pieces are kept here, keyed by Blizzard's frames, and made
	as frames of SaftUI's (the backdrops, the boxes) or textures SaftUI makes on
	Blizzard's frames (the lines, chevrons, hovers). Blizzard's frames and
	regions only get widget calls: alpha on regions whose alpha Blizzard never
	sets (the borders, frame art, state textures), Hide and Show on regions it
	never shows or hides itself (the banners, a module header's Shine and Glow,
	whose alpha its AddAnim animates; the bonus bars' flash textures and
	flares), fonts, a bar's texture, an item icon's tex coords and anchors. No
	Blizzard function is called that writes Blizzard state: the tracker isn't
	asked to lay itself out again, so after a theme or font switch the texts
	already shown keep the spacing Blizzard measured until its next update
	(any quest change, collapsing a header). Every hook is a post-hook
	(hooksecurefunc) on the frame's own method, as the XML mixins copy their
	methods onto each frame, and runs in xpcall: the hooks run inside
	Blizzard's layout, which an error would stop half done.

	None of the tracker's frames is secure (no secure template in either
	client's XML): the quest item button and the scenario's spell buttons are
	plain buttons whose own OnClick, Blizzard's, calls the protected function.
	Their clicks stay Blizzard's own (no script is set or hooked on them, and
	no attribute or field they read is touched), and they're styled with widget
	calls only, in combat too. Should the game ever count an item button as
	protected, its styling waits for the end of combat.
]]

local MODULES = {
	'ScenarioObjectiveTracker', 'UIWidgetObjectiveTracker', 'CampaignQuestObjectiveTracker',
	'QuestObjectiveTracker', 'AdventureObjectiveTracker', 'AchievementObjectiveTracker',
	'MonthlyActivitiesObjectiveTracker', 'InitiativeTasksObjectiveTracker', 'ProfessionsRecipeTracker',
	'BonusObjectiveTracker', 'WorldQuestObjectiveTracker',
}

local ITEM_TEMPLATE = 'QuestObjectiveItemButtonTemplate'

-- The bars' texture in Blizzard's templates (<BarTexture file=...>).
local BAR_TEXTURE = [[Interface\TargetingFrame\UI-StatusBar]]

-- Blizzard's font for each kind of text SaftUI restyles, named Fonts (put back
-- by name, never from GetFontObject: .agents/taint.md rule 10).
local BLIZZARD_FONTS = {
	text = 'ObjectiveTrackerLineFont',
	header = 'ObjectiveTrackerHeaderFont',
	label = 'GameFontHighlightMedium',
	count = 'NumberFontNormal',
}

-- A header's art hidden under SaftUI's look.
local HEADER_ART = { 'Background', 'Shine', 'Glow' }

-- The bonus objective and scenario bars' frame art (faded) and flash textures
-- and flares (hidden: Blizzard sets their alpha as they flash).
local BONUS_FADED = { 'BarFrame', 'BarBG' }
local BONUS_HIDDEN = { 'BarFrame2', 'BarFrame3', 'BarGlow', 'Sheen', 'Starburst' }
local BONUS_FLARES = { 'Flare1', 'Flare2', 'SmallFlare1', 'SmallFlare2', 'FullBarFlare1', 'FullBarFlare2' }

local CHEVRON_SIZE = 16 -- Lucide's chevrons are 8 px glyphs in the middle of their 16
local LINE_ALPHA = 0.5 -- the header line, as RestedXP's skin draws its dividers

-- What SaftUI styles, keyed by Blizzard's frames and regions (weak keys).
local weak = { __mode = 'k' }
local texts = setmetatable({}, weak)     -- font string -> its kind (BLIZZARD_FONTS)
local colored = setmetatable({}, weak)   -- a line's Text -> true while SaftUI's status color is on it
local headers = setmetatable({}, weak)   -- header -> { line = texture }
local collapses = setmetatable({}, weak) -- MinimizeButton -> { box, icon, hover, header }
local bars = setmetatable({}, weak)      -- StatusBar -> { faded, hidden, label }
local items = setmetatable({}, weak)     -- item button -> { box, hover }
local cropped = setmetatable({}, weak)   -- an item button's icon -> true once its SetTexCoord is hooked
local hookedBlocks = setmetatable({}, weak)
local hookedModules = setmetatable({}, weak)
local backdrops = setmetatable({}, weak) -- StatusBar -> its backdrop (st:SetBackdropIn)

-- Item buttons waiting for the end of combat (only if one ever counts as protected).
local waiting = setmetatable({}, weak)

local installed = false

-- Bumped by every OT:StyleAll (a profile, theme or font change, the toggle):
-- a bar or item button Blizzard hands out again is styled again only when the
-- look changed since it last was.
local generation = 0

local function Profile() return st.config.profile end

local function Look()
	local config = Profile().skinning
	return config.theme, config.background
end

-- Whether the tracker wears SaftUI's look now: the toggle on and the Skinning
-- page's look not Blizzard's.
local function Active()
	local config = Profile().skinning
	return config.objective_tracker and not st:IsBlizzardLook(config.theme, config.background) or false
end
function OT:IsActive() return Active() end

local function Font(kind)
	local config = Profile().objectivetracker
	if kind == 'header' then return st:GetFont(config.header_font) end
	if kind == 'count' then return st:GetFont(Profile().skinning.font) end
	return st:GetFont(config.font)
end

-- Gives a font string a font, keeping the color it shows: Blizzard colors
-- most of the tracker's text through its own SetTextColor calls (cached on the
-- font string, so it doesn't color it again), the headers through their font.
local function PutFont(fs, font)
	if not font or fs:GetFontObject() == font then return end
	local r, g, b, a = fs:GetTextColor()
	fs:SetFontObject(font)
	if r and not issecretvalue(r) then fs:SetTextColor(r, g, b, a) end
end

-- SaftUI's font on a text of kind, or Blizzard's back (only on a text SaftUI
-- styled).
local function StyleText(fs, kind, active)
	if not fs then return end
	if active then
		texts[fs] = kind
		PutFont(fs, Font(kind))
	elseif texts[fs] then
		PutFont(fs, _G[BLIZZARD_FONTS[kind]])
	end
end

-- The color of a header's line: the theme's border color, faint.
local function LineColor()
	local theme, background = Look()
	local look = st:ResolveTheme(theme, background) or st:ResolveTheme()
	local r, g, b = unpack(look.colors.bordercolor)
	return r, g, b, LINE_ALPHA
end

local function ColorCollapse(entry)
	entry.icon:SetVertexColor(Profile().colors.text.grey:GetRGB())
	entry.hover:SetVertexColor(1, 1, 1, 1)
end

------------------------------------------------------------------ headers

-- The chevron for a header's state: up while its contents show, down while
-- they're collapsed.
local function SetChevron(entry, collapsed)
	local icon = collapsed and st.icons.chevronDown or st.icons.chevronUp
	entry.icon:SetTexture(icon)
	entry.hover:SetTexture(icon)
end

local function Collapsed(header)
	local owner = header:GetParent()
	return owner and owner.IsCollapsed and owner:IsCollapsed() or false
end

-- A header's collapse button (MinimizeButton).
local function StyleCollapse(button, header, active)
	local entry = collapses[button]
	if not entry then
		if not active then return end
		entry = { header = header }
		local box = st:CreateFrame('Frame', nil, button)
		local level = button:GetFrameLevel()
		if not issecretvalue(level) then box:SetFrameLevel(math.max(0, level - 1)) end
		box:SetAllPoints(button)
		entry.box = box
		entry.icon = button:CreateTexture(nil, 'OVERLAY')
		entry.hover = button:CreateTexture(nil, 'HIGHLIGHT')
		for _, texture in ipairs({ entry.icon, entry.hover }) do
			texture:SetSize(CHEVRON_SIZE, CHEVRON_SIZE)
			texture:SetPoint('CENTER')
		end
		collapses[button] = entry
	end

	for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture(), button:GetHighlightTexture() }) do
		texture:SetAlpha(active and 0 or 1)
	end
	local theme, background = Look()
	st:SetTemplate(entry.box, active and theme or 'none', background, 'control')
	entry.box:SetShown(active)
	entry.icon:SetShown(active)
	entry.hover:SetShown(active)
	SetChevron(entry, Collapsed(header))
	ColorCollapse(entry)
end

-- A header: the container's or a module's.
local function StyleHeader(header, active)
	local entry = headers[header]
	if not entry then
		if not active then return end
		local line = header:CreateTexture(nil, 'ARTWORK')
		line:SetTexture(st.BLANK_TEX)
		line:SetPoint('BOTTOMLEFT')
		line:SetPoint('BOTTOMRIGHT')
		line:SetHeight(st:GetPixelSize(header) or 1)
		entry = { line = line }
		headers[header] = entry
	end
	for _, key in ipairs(HEADER_ART) do
		local region = header[key]
		if region then region:SetShown(not active) end
	end
	entry.line:SetVertexColor(LineColor())
	entry.line:SetShown(active)
	StyleText(header.Text, 'header', active)
	if header.MinimizeButton then StyleCollapse(header.MinimizeButton, header, active) end
end

-- The header's SetCollapsed, post-hooked: the chevron follows.
local function OnSetCollapsed(header, collapsed)
	local entry = header.MinimizeButton and collapses[header.MinimizeButton]
	if entry then SetChevron(entry, collapsed) end
end

------------------------------------------------------------------ blocks and lines

-- The color a status gets from the tracker's page: 'completed' or 'failed'.
function OT:StatusColor(state)
	local colors = Profile().objectivetracker.status_colors
	return colors and colors[state]
end

-- A line's state, read from the color style Blizzard gave its text (its
-- colorStyle, one of OBJECTIVE_TRACKER_COLOR's tables, which Blizzard hands
-- AddObjective and caches on the font string): Complete is a finished
-- objective, Failed a failed one. FailedHighlight, which Blizzard shows
-- under the mouse, and the other styles are left as Blizzard colors them. Only
-- reads Blizzard's tables.
local function StateOf(fs)
	local style, styles = fs.colorStyle, _G.OBJECTIVE_TRACKER_COLOR
	if not (style and type(styles) == 'table') then return end
	if style == styles.Complete then return 'completed' end
	if style == styles.Failed then return 'failed' end
end

-- A line's text in its state's color, or Blizzard's back (the color of its
-- style, which Blizzard's own cache still names). Only a text SaftUI styled
-- (StyleText), and a color only, so a hover Blizzard gives the line stays its.
local function ColorLine(line, active)
	local fs = line.Text
	if not (fs and texts[fs]) then return end
	local color = active and OT:StatusColor(StateOf(fs))
	if color then
		colored[fs] = true
		fs:SetTextColor(color[1], color[2], color[3])
	elseif colored[fs] then
		colored[fs] = nil
		local style = fs.colorStyle
		if style then fs:SetTextColor(style.r, style.g, style.b) end
	end
end

local function StyleLine(line, active)
	StyleText(line.Text, 'text', active)
	StyleText(line.Dash, 'text', active)
	ColorLine(line, active)
end

local function OnGetLine(block, objectiveKey)
	local line = block.usedLines and block.usedLines[objectiveKey]
	if line then StyleLine(line, Active()) end
end

local function TryOnGetLine(block, objectiveKey)
	xpcall(OnGetLine, geterrorhandler(), block, objectiveKey)
end

-- AddObjective sets the line's text color after GetLine, from the style it's
-- given, so the status color goes on after it.
local function TryOnAddObjective(block, objectiveKey)
	xpcall(function()
		local line = block.usedLines and block.usedLines[objectiveKey]
		if line then ColorLine(line, Active()) end
	end, geterrorhandler())
end

-- UpdateHighlight sets every line's color again as the mouse goes on and off
-- the block (a failed line's too): SaftUI's goes back on after it.
local function TryOnUpdateHighlight(block)
	xpcall(function()
		local active = Active()
		for _, line in pairs(block.usedLines or {}) do ColorLine(line, active) end
	end, geterrorhandler())
end

local function StyleBlock(block, active)
	StyleText(block.HeaderText, 'text', active)
	if block.usedLines then
		for _, line in pairs(block.usedLines) do StyleLine(line, active) end
	end
end

-- A block's GetLine is post-hooked once, the first time SaftUI sees it.
local function HookBlock(block)
	if hookedBlocks[block] or type(block.GetLine) ~= 'function' then return end
	hookedBlocks[block] = true
	hooksecurefunc(block, 'GetLine', TryOnGetLine)
	if type(block.AddObjective) == 'function' then hooksecurefunc(block, 'AddObjective', TryOnAddObjective) end
	if type(block.UpdateHighlight) == 'function' then hooksecurefunc(block, 'UpdateHighlight', TryOnUpdateHighlight) end
end

------------------------------------------------------------------ bars

-- A bar's StatusBar and its text: flat in SaftUI's look, Blizzard's art back
-- otherwise. A bonus objective or scenario bar has its frame art (BarFrame);
-- the others have Blizzard's skill bar border, every texture on the bar but
-- its fill.
local function StyleBar(status, label, owner, active)
	if not status then return end
	local entry = bars[status]
	if not entry then
		if not active then return end
		entry = { faded = {}, hidden = {}, label = label }
		if status.BarFrame then
			for _, key in ipairs(BONUS_FADED) do entry.faded[#entry.faded + 1] = status[key] end
			for _, key in ipairs(BONUS_HIDDEN) do entry.hidden[#entry.hidden + 1] = status[key] end
			for _, key in ipairs(BONUS_FLARES) do entry.hidden[#entry.hidden + 1] = owner[key] end
		else
			local fill = status:GetStatusBarTexture()
			for _, region in ipairs({ status:GetRegions() }) do
				if region ~= fill and region:IsObjectType('Texture') then
					entry.faded[#entry.faded + 1] = region
				end
			end
		end
		bars[status] = entry
	elseif entry.generation == generation then
		return
	end
	entry.generation = generation

	for _, region in ipairs(entry.faded) do region:SetAlpha(active and 0 or 1) end
	for _, region in ipairs(entry.hidden) do region:SetShown(not active) end
	status:SetStatusBarTexture(active and st.BLANK_TEX or BAR_TEXTURE)
	local theme, background = Look()
	st:SetBackdropIn(backdrops, status, active and theme or 'none', background, 'bar')
	if backdrops[status] then backdrops[status]:SetShown(active) end
	StyleText(entry.label, 'label', active)
end

local function StyleProgressBar(bar, active)
	local status = bar and bar.Bar
	if status then StyleBar(status, status.Label, bar, active) end
end

local function StyleTimerBar(bar, active)
	if bar and bar.Bar then StyleBar(bar.Bar, bar.Label, bar, active) end
end

------------------------------------------------------------------ item buttons

-- The crop SaftUI gives an item's icon: Icon zoom off each edge.
local function Crop(icon)
	local left, right, top, bottom = st:IconTexCoords(Profile().misc.icon_trim)
	icon:SetTexCoord(left, right, top, bottom)
end

-- Blizzard's SetItemButtonTexture puts the whole texture back on every SetUp;
-- while SaftUI's look is on the crop goes back on. Our own SetTexCoord runs
-- this again, with the crop, so it stops there.
local function KeepCrop(icon)
	if cropped[icon] then return end
	cropped[icon] = true
	hooksecurefunc(icon, 'SetTexCoord', function(self, left, right, top, bottom)
		if not Active() then return end
		local l, r, t, b = st:IconTexCoords(Profile().misc.icon_trim)
		if left == l and right == r and top == t and bottom == b then return end
		Crop(self)
	end)
end

local function ColorItem(entry)
	entry.hover:SetVertexColor(Profile().colors.button.blue:GetRGB())
end

local function StyleItem(button, active)
	local icon = button.icon
	if not icon then return end
	if InCombatLockdown() and button:IsProtected() then
		waiting[button] = true
		st:QueueAfterCombat('objectivetracker_items', function()
			for frame in pairs(waiting) do
				waiting[frame] = nil
				StyleItem(frame, Active())
			end
		end)
		return
	end

	local entry = items[button]
	if not entry then
		if not active then return end
		entry = {}
		local box = st:CreateFrame('Frame', nil, button)
		local level = button:GetFrameLevel()
		if not issecretvalue(level) then box:SetFrameLevel(math.max(0, level - 1)) end
		box:SetAllPoints(button)
		entry.box = box
		entry.hover = button:CreateTexture(nil, st.ThemeArt.HOVER_LAYER)
		entry.hover:SetTexture(st.BLANK_TEX)
		entry.hover:SetBlendMode('ADD')
		items[button] = entry
		KeepCrop(icon)
	elseif entry.generation == generation then
		return
	end
	entry.generation = generation

	for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture(), button:GetHighlightTexture() }) do
		texture:SetAlpha(active and 0 or 1)
	end
	local theme, background = Look()
	st:SetTemplate(entry.box, active and theme or 'none', background, 'action')
	entry.box:SetShown(active)
	icon:ClearAllPoints()
	if active then
		local inset = st:ThemeInset(theme, background, 'action')
		icon:SetPoint('TOPLEFT', button, 'TOPLEFT', inset, -inset)
		icon:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -inset, inset)
		entry.hover:ClearAllPoints()
		entry.hover:SetPoint('TOPLEFT', icon)
		entry.hover:SetPoint('BOTTOMRIGHT', icon)
		Crop(icon)
	else
		icon:SetAllPoints(button)
		icon:SetTexCoord(0, 1, 0, 1)
	end
	entry.hover:SetShown(active)
	ColorItem(entry)
	StyleText(button.Count, 'count', active)
end

------------------------------------------------------------------ the module hooks

local function OnGetBlock(module, id, optTemplate)
	local blocks = module.usedBlocks and module.usedBlocks[optTemplate or module.blockTemplate]
	local block = blocks and blocks[id]
	if not block then return end
	HookBlock(block)
	StyleBlock(block, Active())
end

local function OnGetProgressBar(module, key)
	local bar = module.usedProgressBars and module.usedProgressBars[key]
	if bar then StyleProgressBar(bar, Active()) end
end

local function OnGetTimerBar(module, key)
	local bar = module.usedTimerBars and module.usedTimerBars[key]
	if bar then StyleTimerBar(bar, Active()) end
end

-- The frame Blizzard just handed out is one of the module's right edge frames;
-- every quest item button among them is styled (once, then only when the look
-- changes).
local function OnGetRightEdgeFrame(module, settings)
	if not (settings and settings.template == ITEM_TEMPLATE and module.usedRightEdgeFrames) then return end
	for _, frame in pairs(module.usedRightEdgeFrames) do
		if frame.template == ITEM_TEMPLATE then StyleItem(frame, Active()) end
	end
end

-- Each module method is post-hooked through xpcall (see the top of this file).
local MODULE_HOOKS = {
	GetBlock = OnGetBlock,
	GetProgressBar = OnGetProgressBar,
	GetTimerBar = OnGetTimerBar,
	GetRightEdgeFrame = OnGetRightEdgeFrame,
}

local function Guarded(fn)
	return function(...) xpcall(fn, geterrorhandler(), ...) end
end
local GUARDED = {}
for name, fn in pairs(MODULE_HOOKS) do GUARDED[name] = Guarded(fn) end
local TryOnSetCollapsed = Guarded(OnSetCollapsed)

local function HookHeader(header)
	if header and type(header.SetCollapsed) == 'function' then
		hooksecurefunc(header, 'SetCollapsed', TryOnSetCollapsed)
	end
end

local function HookModule(module)
	if hookedModules[module] then return end
	hookedModules[module] = true
	HookHeader(module.Header)
	for name, hook in pairs(GUARDED) do
		if type(module[name]) == 'function' then hooksecurefunc(module, name, hook) end
	end
	-- The scenario's objectives block is fixed, not handed out by GetBlock.
	if module.ObjectivesBlock then HookBlock(module.ObjectivesBlock) end
end

local function EachModule(fn)
	for _, name in ipairs(MODULES) do
		local module = _G[name]
		if module then fn(module) end
	end
end

------------------------------------------------------------------ all of it

-- Puts the look on everything the tracker shows now and everything SaftUI has
-- styled before (pooled frames Blizzard isn't using now included), each in
-- xpcall so one that errors leaves the rest.
local function Apply(fn, ...) xpcall(fn, geterrorhandler(), ...) end

function OT:StyleAll()
	generation = generation + 1
	local active = Active()
	local tracker = _G.ObjectiveTrackerFrame
	if tracker and tracker.Header then Apply(StyleHeader, tracker.Header, active) end
	EachModule(function(module)
		if module.Header then Apply(StyleHeader, module.Header, active) end
		if module.ObjectivesBlock then Apply(StyleBlock, module.ObjectivesBlock, active) end
		for _, blocks in pairs(module.usedBlocks or {}) do
			for _, block in pairs(blocks) do
				HookBlock(block)
				Apply(StyleBlock, block, active)
			end
		end
		for _, bar in pairs(module.usedProgressBars or {}) do Apply(StyleProgressBar, bar, active) end
		for _, bar in pairs(module.usedTimerBars or {}) do Apply(StyleTimerBar, bar, active) end
		for _, frame in pairs(module.usedRightEdgeFrames or {}) do
			if frame.template == ITEM_TEMPLATE then Apply(StyleItem, frame, active) end
		end
	end)
	for header in pairs(headers) do Apply(StyleHeader, header, active) end
	for fs, kind in pairs(texts) do Apply(StyleText, fs, kind, active) end
	for status, entry in pairs(bars) do
		Apply(StyleBar, status, entry.label, nil, active)
	end
	for button in pairs(items) do Apply(StyleItem, button, active) end
end

-- Hooks the tracker once, then styles what it shows.
function OT:Install()
	if installed or not _G.ObjectiveTrackerFrame then return end
	installed = true
	HookHeader(_G.ObjectiveTrackerFrame.Header)
	EachModule(HookModule)
	self:StyleAll()
end

-- A profile change, the Skinning page, the tracker's fonts or Skinning ->
-- Objective tracker: on, the tracker is hooked if it wasn't and takes the
-- look; off or under the Blizzard theme, Blizzard's look goes back on. Widget
-- calls only, so it runs in combat too.
function OT:UpdateConfig()
	if installed then
		self:StyleAll()
	elseif Profile().skinning.objective_tracker then
		self:Install()
	end
end

-- A theme recolor or a color change: the header lines, the chevrons and the
-- item buttons' hover take the colors again.
function OT:OnColorsChanged()
	for _, entry in pairs(headers) do entry.line:SetVertexColor(LineColor()) end
	for _, entry in pairs(collapses) do ColorCollapse(entry) end
	for _, entry in pairs(items) do ColorItem(entry) end
end

-- Off (Skinning -> Objective tracker), nothing is hooked or touched until it's
-- turned on.
function OT:OnEnable()
	if not Profile().skinning.objective_tracker then return end
	if _G.ObjectiveTrackerFrame then
		self:Install()
	elseif C_AddOns.DoesAddOnExist('Blizzard_ObjectiveTracker') then
		st:OnBlizzardAddon('Blizzard_ObjectiveTracker', function() self:Install() end)
	end
end
