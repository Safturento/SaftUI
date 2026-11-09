local st = SaftUI

local LT = st:GetModule('Loot')

local roll_buttons = {
	{name = 'Pass', icon_text = 'P', color = 'red',
		icon_texture = [[Interface\ICONS\Spell_Shadow_SacrificialShield]]},
	{name = 'Greed', icon_text = 'G', color = 'yellow',
		icon_texture = [[Interface\ICONS\INV_Misc_Coin_01]]},
	{name = 'Transmog', icon_text = 'DE', color = 'purple',
		icon_texture = [[Interface\ICONS\Spell_Holy_RemoveCurse]]},
	{name = 'Need', icon_text = 'N', color = 'white',
		icon_texture = [[Interface\ICONS\INV_Misc_PunchCards_White]]},
}

-- SaftUI's pieces on Blizzard's roll frames. The frames and what's on them are
-- Blizzard's, so nothing is written onto them (.agents/taint.md rule 1): each
-- skinned frame has an entry here, keyed by the frame, and a Timer's text is
-- found through `timerTexts`, keyed by the Timer (the OnUpdate hook only gets
-- the Timer). An entry is { info = the info frame, iconBox = the frame that
-- holds the icon's backdrop, timerText, buttonText = { [choice] = font string } }.
-- The info frame, icon box and texts are SaftUI's own.
local skins = setmetatable({}, { __mode = 'k' })
local timerTexts = setmetatable({}, { __mode = 'k' })

-- The bar's body, SaftUI's frame that rollinfo.lua puts the tooltip on.
function LT:GetRollInfoFrame(frame)
	local skin = skins[frame]
	return skin and skin.info
end

-- Forever keeps the roll buttons in a LootButtonContainer child; retail has
-- them directly on the roll frame.
local function GetRollButton(frame, name)
	local container = frame.LootButtonContainer or frame
	return container[name..'Button']
end

function LT:SkinRollFrame(frame)
	if skins[frame] then return end
	local skin = { buttonText = {} }
	skins[frame] = skin

	-- Blizzard drops ended rolls from rollFrames, so track every skinned frame
	-- ourselves to keep idle ones in sync with option edits.
	self.skinnedRollFrames = self.skinnedRollFrames or {}
	tinsert(self.skinnedRollFrames, frame)

	st:StripTextures(frame)

	st:SkinIcon(frame.IconFrame.Icon, nil, frame.IconFrame)
	frame.IconFrame:ClearAllPoints()
	frame.IconFrame:SetPoint('LEFT', frame, 0, 0)
	st:Kill(frame.IconFrame.Border)

	st:Kill(frame.Timer.Background)
	st:Kill(_G[frame:GetName()..'NameFrame'])
	st:Kill(_G[frame:GetName()..'Corner'])

	frame.Name:SetParent(frame.Timer)

	st:Kill(frame.IconFrame.Count)

	skin.timerText = frame.Timer:CreateFontString(nil, 'OVERLAY')
	skin.timerText:SetFontObject(GameFontNormal)
	timerTexts[frame.Timer] = skin.timerText

	-- How many have picked each choice (LT:CreateRollCounts). rollinfo.lua
	-- keeps this table, so the counts add no fields to the buttons.
	local counts = {}
	local prev
	for i, info in ipairs(roll_buttons) do
		local button = GetRollButton(frame, info.name)
		if button then
			local text = button:CreateFontString(nil, 'OVERLAY')
			skin.buttonText[info.name] = text
			text:SetFontObject(GameFontNormal)
			text:SetPoint('CENTER', 1, 0)
			text:SetVertexColor(st.config.profile.colors.text[info.color]:GetRGB())
			self:CreateRollCounts(counts, button, info.name)

			prev = button
		end
	end

	self:SecureHookScript(frame, 'OnShow', 'GroupLootFrame_OnShow')
	self:SecureHookScript(frame.Timer, 'OnUpdate', 'GroupLootFrame_OnUpdateTimer')
	self:UpdateRollFrame(frame)
	-- A frame is first skinned after GroupLootContainer_OpenNewFrame has shown
	-- it, so its first roll missed the OnShow hook above. Style that roll now.
	if frame:IsShown() then self:GroupLootFrame_OnShow(frame) end
	-- The live counts and the rolls in the bar's tooltip (rollinfo.lua). After
	-- UpdateRollFrame, which makes the info frame.
	self:AttachRollInfo(frame, counts)
end

function LT:UpdateRollFrame(frame)
	local config = self.config.roll
	local font_obj = st:GetFont(config.font)
	local skin = skins[frame]

	frame:SetSize(config.width, config.height)

	-- Updates run on every live option change, so only create this once.
	if not skin.info then
		skin.info = st:CreateFrame('frame', nil, frame)
		skin.info:SetPoint('BOTTOMRIGHT')
		skin.info:SetPoint('TOPLEFT', frame.IconFrame, 'TOPRIGHT', 7, 0)
		skin.info:SetFrameLevel(1)
	end
	st:SetBackdrop(skin.info, config.template)

	frame.Name:SetFontObject(st:GetFont(config.font))
	frame.Name:ClearAllPoints()
	frame.Name:SetHeight(config.height)
	frame.Name:SetPoint('LEFT', skin.info, 5, 0)
	frame.Name:SetPoint('RIGHT', skin.timerText, 'LEFT', -5, 0)

	-- st:SetBackdrop writes onto the frame it's given, so the icon's backdrop
	-- hangs off a SaftUI frame laid over the icon frame instead. Same frame
	-- level as the icon frame, so the backdrop sits one below it, as before.
	if not skin.iconBox then
		skin.iconBox = st:CreateFrame('frame', nil, frame.IconFrame)
		skin.iconBox:SetAllPoints(frame.IconFrame)
		skin.iconBox:SetFrameLevel(frame.IconFrame:GetFrameLevel())
	end
	st:SetBackdrop(skin.iconBox, config.template)
	frame.IconFrame.Count:SetFontObject(st:GetFont(config.font))
	frame.IconFrame:SetSize(config.height, config.height)

	frame.Timer:SetStatusBarTexture(st.BLANK_TEX)
	frame.Timer:ClearAllPoints()
	frame.Timer:SetPoint('BOTTOMLEFT', frame.IconFrame, 'BOTTOMRIGHT', config.spacing, 0)
	frame.Timer:SetHeight(1)
	frame.Timer:SetWidth(config.width - config.height - config.spacing)

	--st:StripTextures(frame.Timer, true)

	local prev
	for i, info in ipairs(roll_buttons) do
		local button = GetRollButton(frame, info.name)
		if button and button:IsShown() then
			button:ClearAllPoints()
			if i == 1 then
				button:SetPoint('RIGHT', skin.info, 'RIGHT', -2, 0)
			else
				button:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
			end

			skin.buttonText[info.name]:SetFontObject(st:GetFont(config.font))

			button:SetSize(config.height - 4, config.height - 4)
			--st:SetBackdrop(button, config.template)
			prev = button
		end
	end

	skin.timerText:SetFontObject(st:GetFont(config.font))
	skin.timerText:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
	skin.timerText:SetWidth(40)
end

function LT:GroupLootFrame_OnShow(frame)
	local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant, deSkillRequired = GetLootRollItemInfo(frame.rollID);
	-- A queued roll that expired before its turn has no item: Blizzard's own
	-- OnShow has already taken the frame away, so there's nothing to style.
	if not name then return end

	local color = ITEM_QUALITY_COLORS[quality]
	frame.Timer:SetStatusBarColor(color.r, color.g, color.b)
	-- The item's quality color, as Blizzard's own OnShow gives it.
	frame.Name:SetVertexColor(color.r, color.g, color.b)

	local text = ''

	if (quality >= 3) and (not bindOnPickUp) then
		text = 'BoE '
	end

	if count > 1 then
		text = text .. '(' .. count .. ') '
	end

	frame.Name:SetText(text .. name)
end

function LT:GroupLootFrame_OnUpdateTimer(timer, elapsed)
	local text = timerTexts[timer]
	if not text then return end
	local sec = timer:GetValue()

	text:SetText(st.StringFormat:ToClock(sec))

	timer:SetStatusBarColor(st.config.profile.colors.button.blue:GetRGB())

	if sec < 60 then
		text:SetVertexColor(st.config.profile.colors.text.red:GetRGB())
	else
		text:SetVertexColor(1, 1, 1)
	end
end

-- SaftUI owns this anchor; GroupLootContainer is part of Blizzard's managed
-- frame layout, so we never move or size it. Roll frames stay parented where
-- Blizzard puts them and are only anchored to this frame.
function LT:CreateRollAnchor()
	if self.rollAnchor then return self.rollAnchor end
	self.rollAnchor = CreateFrame('frame', st.name .. 'LootRollAnchor', UIParent)
	return self.rollAnchor
end

function LT:ApplyRollAnchor()
	local config = self.config.roll
	local anchor = self:CreateRollAnchor()

	anchor:SetSize(st:RoundToPixel(config.width, anchor), st:RoundToPixel(config.height, anchor))
	anchor:ClearAllPoints()
	anchor:SetPoint(st:UnpackPoint(config.position))
end

function LT:LayoutRollFrames()
	local container = GroupLootContainer
	local anchor = self.rollAnchor
	if not anchor or not container or not container.rollFrames then return end

	local config = self.config.roll
	local prev

	-- Blizzard leaves holes in rollFrames when a roll ends, and walks 1..maxIndex.
	for i = 1, container.maxIndex or 4 do
		local frame = container.rollFrames[i]
		if frame then
			frame:ClearAllPoints()
			if not prev then
				if config.grow_down then
					frame:SetPoint('TOP', anchor)
				else
					frame:SetPoint('BOTTOM', anchor)
				end
			else
				if config.grow_down then
					frame:SetPoint('TOP', prev, 'BOTTOM', 0, -config.spacing)
				else
					frame:SetPoint('BOTTOM', prev, 'TOP', 0, config.spacing)
				end
			end
			prev = frame
		end
	end
end

function LT:GroupLootContainer_Update()
	self:LayoutRollFrames()
	self:UpdateRollPreviewVisibility()
end

function LT:SkinNewRollFrame()
	for _,frame in pairs(GroupLootContainer.rollFrames) do
		self:SkinRollFrame(frame)
	end
end

function LT:InitializeRollFrame()
    if not GroupLootContainer_OpenNewFrame then return end
	self:SecureHook('GroupLootContainer_Update')
	self:SecureHook('GroupLootContainer_OpenNewFrame', 'SkinNewRollFrame')

	for _,frame in pairs(GroupLootContainer.rollFrames) do
		self:SkinRollFrame(frame)
	end

	self:CreateRollAnchor()
	self:UpdateGroupLootConfig()
	self:RegisterRollMover()
end

function LT:RegisterRollMover()
	st:RegisterMover('lootroll', {
		frame = self.rollAnchor,
		label = 'Loot Rolls',
		getPosition = function() return self.config.roll.position end,
		setPosition = function(pos) self.config.roll.position = pos end,
		apply = function() self:UpdateGroupLootConfig() end,
		configPath = { 'Loot', 'roll', 'general' },
	})
end

-- Only SaftUI's anchor and the (unprotected) roll frames are touched, never
-- GroupLootContainer. Everything here hangs off the anchor, so a protected
-- frame (e.g. a unit frame) anchored to any of it makes the anchor protected;
-- in combat the update then waits for the end of combat.
function LT:UpdateGroupLootConfig()
	st:SafeReposition(self:CreateRollAnchor(), 'lootroll', function()
		self:ApplyRollAnchor()
		for _,frame in ipairs(self.skinnedRollFrames or {}) do
			self:UpdateRollFrame(frame)
		end
		self:LayoutRollFrames()
		self:UpdateRollPreviews()
	end)
end

------------------------------------
---- Test mode ---------------------
------------------------------------
-- Preview bars are SaftUI's own frames that copy the look of a skinned roll
-- frame (same size, template, font, spacing, icon, name, timer and buttons).
-- Real Blizzard roll frames are never created, fed fake data or touched; the
-- previews only read whether one is showing. They hide while a real roll is
-- up (the real rolls own the anchor then) and come back when it ends.
-- Each one has sample choices too: counts on its buttons and the rolls in its
-- tooltip, the way rollinfo.lua shows a real roll's.
-- LT.testRolls is a plain field: not saved, off after /reload.

local PREVIEW_FALLBACK_ICON = 134400 -- INV_Misc_QuestionMark
local PREVIEW_DURATION = 300

-- The fallback name and quality are used until the client has the item data.
-- `choices` are made-up players with a state from LT.ROLL_STATE and, for a
-- main spec need, the roll the game makes at once. `me` is you, still to
-- choose, as on any roll bar that's still up. `leader` indexes `choices`.
local PREVIEW_ROLLS = {
	{ itemID = 19019, name = 'Thunderfury, Blessed Blade of the Windseeker', quality = 5,
		count = 1, bindOnPickUp = true, transmog = true, remaining = 250,
		leader = 1, choices = {
			{ name = 'Brightblade', class = 'PALADIN', state = 'NeedMainSpec', roll = 92 },
			{ name = 'Ironhide', class = 'WARRIOR', state = 'NeedMainSpec', roll = 41 },
			{ name = 'Mistweave', class = 'PRIEST', state = 'NeedOffSpec' },
			{ name = 'Quickshot', class = 'HUNTER', state = 'Transmog' },
			{ name = 'Stonefist', class = 'SHAMAN', state = 'Greed' },
			{ name = 'Emberfall', class = 'MAGE', state = 'Pass' },
			{ name = 'Duskwhisper', class = 'ROGUE', state = 'NoRoll' },
			{ me = true, state = 'NoRoll' },
		} },
	{ itemID = 16309, name = 'Drakefire Amulet', quality = 4,
		count = 1, bindOnPickUp = false, transmog = false, remaining = 170,
		choices = {
			{ name = 'Mistweave', class = 'PRIEST', state = 'Greed' },
			{ name = 'Quickshot', class = 'HUNTER', state = 'Greed' },
			{ name = 'Brightblade', class = 'PALADIN', state = 'Pass' },
			{ name = 'Emberfall', class = 'MAGE', state = 'Pass' },
			{ me = true, state = 'NoRoll' },
		} },
	{ itemID = 2589, name = 'Linen Cloth', quality = 1,
		count = 5, bindOnPickUp = false, transmog = true, remaining = 90,
		choices = {
			{ name = 'Emberfall', class = 'MAGE', state = 'Greed' },
			{ name = 'Brightblade', class = 'PALADIN', state = 'Pass' },
			{ name = 'Mistweave', class = 'PRIEST', state = 'Pass' },
			{ name = 'Quickshot', class = 'HUNTER', state = 'Pass' },
			{ name = 'Duskwhisper', class = 'ROGUE', state = 'Pass' },
			{ me = true, state = 'NoRoll' },
		} },
	{ itemID = 1204, name = 'The Green Tower', quality = 2,
		count = 1, bindOnPickUp = false, transmog = false, remaining = 45,
		leader = 1, tied = true, choices = {
			{ name = 'Ironhide', class = 'WARRIOR', state = 'NeedMainSpec', roll = 77 },
			{ name = 'Brightblade', class = 'PALADIN', state = 'NeedMainSpec', roll = 77 },
			{ name = 'Duskwhisper', class = 'ROGUE', state = 'NoRoll' },
			{ me = true, state = 'NoRoll' },
		} },
}

-- A preview's sample choices as a summary in LT:SummarizeDrop's shape, the
-- rolls table that LT:AddRollLines and LT:SetRollCounts take.
local function PreviewRolls(spec)
	local states = LT.ROLL_STATE
	local list = {}
	for i, choice in ipairs(spec.choices) do
		local line = { name = choice.name, class = choice.class, state = states[choice.state], roll = choice.roll }
		if choice.me then
			local _, class = UnitClass('player')
			line.name, line.class, line.isSelf = UnitName('player'), class, true
		end
		list[i] = line
	end
	return { list = list, leader = spec.leader, tied = spec.tied }
end

-- The tooltip on a preview's icon and info frames: the item, then its sample rolls.
local function PreviewTooltip(owner)
	local bar = owner:GetParent()
	return 'SetItemByID', bar.spec.itemID, bar.rolls
end

local function RealRollShowing()
	local container = GroupLootContainer
	if not container or not container.rollFrames then return false end
	for _, frame in pairs(container.rollFrames) do
		if frame:IsShown() then return true end
	end
	return false
end

-- Name, count and icon, the way GroupLootFrame_OnShow builds them.
local function FillPreviewBar(bar)
	local spec = bar.spec
	local name, quality = spec.name, spec.quality
	bar.pending = nil

	local itemName, _, itemQuality = C_Item.GetItemInfo(spec.itemID)
	if itemName and itemQuality then
		name, quality = itemName, itemQuality
	else
		-- Uncached: show the fallback now and fill in once the data arrives.
		bar.pending = true
		if C_Item.RequestLoadItemDataByID then C_Item.RequestLoadItemDataByID(spec.itemID) end
	end

	local text = ''
	if quality >= 3 and not spec.bindOnPickUp then text = 'BoE ' end
	if spec.count > 1 then text = text .. '(' .. spec.count .. ') ' end
	bar.Name:SetText(text .. name)
	local color = ITEM_QUALITY_COLORS[quality]
	if color then bar.Name:SetVertexColor(color.r, color.g, color.b) end

	local icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(spec.itemID)
	bar.Icon:SetTexture(icon or PREVIEW_FALLBACK_ICON)
end

local function SetPreviewTimer(bar)
	local sec = bar.remaining
	bar.Timer:SetValue(sec)
	bar.Timer:SetStatusBarColor(st.config.profile.colors.button.blue:GetRGB())

	local whole = floor(sec)
	if bar.shownSecond ~= whole then
		bar.shownSecond = whole
		bar.Timer.Text:SetText(st.StringFormat:ToClock(sec))
	end

	if sec < 60 then
		bar.Timer.Text:SetVertexColor(st.config.profile.colors.text.red:GetRGB())
	else
		bar.Timer.Text:SetVertexColor(1, 1, 1)
	end
end

local function CreatePreviewBar(parent, spec)
	local bar = CreateFrame('frame', nil, parent)
	local level = bar:GetFrameLevel()
	bar.spec = spec
	bar.remaining = spec.remaining

	bar.IconFrame = st:CreateFrame('frame', nil, bar)
	bar.IconFrame:SetPoint('LEFT', bar)
	bar.Icon = bar.IconFrame:CreateTexture(nil, 'ARTWORK')
	st:SkinIcon(bar.Icon, nil, bar.IconFrame)

	bar.InfoFrame = st:CreateFrame('frame', nil, bar)
	bar.InfoFrame:SetPoint('BOTTOMRIGHT', bar)
	bar.InfoFrame:SetPoint('TOPLEFT', bar.IconFrame, 'TOPRIGHT', 7, 0)
	bar.InfoFrame:SetFrameLevel(level + 1)

	bar.Timer = CreateFrame('StatusBar', nil, bar)
	bar.Timer:SetFrameLevel(level + 2)
	bar.Timer:SetStatusBarTexture(st.BLANK_TEX)
	bar.Timer:SetMinMaxValues(0, PREVIEW_DURATION)
	-- A font is needed before FillPreviewBar sets text (SetText errors on a
	-- font string without one); ApplyPreviewConfig re-applies it with the rest.
	local font = st:GetFont(LT.config.roll.font)
	bar.Timer.Text = bar.Timer:CreateFontString(nil, 'OVERLAY')
	bar.Timer.Text:SetFontObject(font)
	bar.Name = bar.Timer:CreateFontString(nil, 'OVERLAY')
	bar.Name:SetFontObject(font)
	bar.Name:SetJustifyH('LEFT')
	bar.Name:SetWordWrap(false)
	bar.Name:SetVertexColor(1, 1, 1)

	-- Same order as the real buttons: the first one sits at the right edge.
	-- Like Blizzard, a bar has Transmog in place of Greed when the item can
	-- be transmogged.
	bar.buttons = {}
	bar.counts = {}
	for _, info in ipairs(roll_buttons) do
		local skip = (info.name == 'Transmog' and not spec.transmog) or (info.name == 'Greed' and spec.transmog)
		if not skip then
			local button = CreateFrame('frame', nil, bar)
			button:SetFrameLevel(level + 3)
			button.Icon = button:CreateTexture(nil, 'ARTWORK')
			button.Icon:SetAllPoints()
			button.Icon:SetTexture(info.icon_texture)
			st:SkinIcon(button.Icon)
			LT:CreateRollCounts(bar.counts, button, info.name)
			tinsert(bar.buttons, button)
		end
	end

	bar.rolls = PreviewRolls(spec)
	LT:SetRollCounts(bar.counts, bar.rolls)
	LT:SetRollTooltipScripts(bar.IconFrame, PreviewTooltip)
	LT:SetRollTooltipScripts(bar.InfoFrame, PreviewTooltip)

	FillPreviewBar(bar)
	return bar
end

-- The same sizing as UpdateRollFrame, from the live roll config.
local function ApplyPreviewConfig(bar, config)
	local font = st:GetFont(config.font)

	bar:SetSize(config.width, config.height)
	bar.IconFrame:SetSize(config.height, config.height)
	st:SetBackdrop(bar.IconFrame, config.template)
	st:SetBackdrop(bar.InfoFrame, config.template)

	bar.Timer:ClearAllPoints()
	bar.Timer:SetPoint('BOTTOMLEFT', bar.IconFrame, 'BOTTOMRIGHT', config.spacing, 0)
	bar.Timer:SetHeight(1)
	bar.Timer:SetWidth(config.width - config.height - config.spacing)

	local prev
	for i, button in ipairs(bar.buttons) do
		button:SetSize(config.height - 4, config.height - 4)
		button:ClearAllPoints()
		if i == 1 then
			button:SetPoint('RIGHT', bar.InfoFrame, 'RIGHT', -2, 0)
		else
			button:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
		end
		prev = button
	end

	bar.Timer.Text:SetFontObject(font)
	bar.Timer.Text:ClearAllPoints()
	bar.Timer.Text:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
	bar.Timer.Text:SetWidth(40)

	bar.Name:SetFontObject(font)
	bar.Name:ClearAllPoints()
	bar.Name:SetHeight(config.height)
	bar.Name:SetPoint('LEFT', bar.InfoFrame, 5, 0)
	bar.Name:SetPoint('RIGHT', bar.Timer.Text, 'LEFT', -5, 0)

	SetPreviewTimer(bar)
end

function LT:CreateRollPreviews()
	if self.rollPreview then return self.rollPreview end

	local container = CreateFrame('frame', nil, UIParent)
	container:Hide()
	container.bars = {}
	for i, spec in ipairs(PREVIEW_ROLLS) do
		container.bars[i] = CreatePreviewBar(container, spec)
	end

	self.rollPreview = container
	return container
end

-- Re-applies size, template, font, spacing, grow direction and position to the
-- previews (they anchor to rollAnchor like the real rolls do). Runs from
-- UpdateGroupLootConfig, so option edits and edit mode drags both reach it.
function LT:UpdateRollPreviews()
	local container = self.rollPreview
	if not container then return end

	local anchor = self.rollAnchor
	if not self.testRolls or not anchor or RealRollShowing() then
		container.active = false
		container:Hide()
		return
	end

	local config = self.config.roll
	local prev
	for _, bar in ipairs(container.bars) do
		ApplyPreviewConfig(bar, config)

		bar:ClearAllPoints()
		if not prev then
			bar:SetPoint(config.grow_down and 'TOP' or 'BOTTOM', anchor)
		elseif config.grow_down then
			bar:SetPoint('TOP', prev, 'BOTTOM', 0, -config.spacing)
		else
			bar:SetPoint('BOTTOM', prev, 'TOP', 0, config.spacing)
		end
		prev = bar
	end

	container.active = true
	container:Show()
end

-- Cheap check for when a real roll starts or ends.
function LT:UpdateRollPreviewVisibility()
	local container = self.rollPreview
	if not container then return end

	local show = (self.testRolls and not RealRollShowing()) and true or false
	if show ~= (container.active or false) then
		self:UpdateRollPreviews()
	end
end

local function OnPreviewUpdate(driver, elapsed)
	local container = LT.rollPreview
	if not container then return end

	driver.pollTime = (driver.pollTime or 0) + elapsed
	if driver.pollTime >= 0.2 then
		driver.pollTime = 0
		LT:UpdateRollPreviewVisibility()
	end

	if not container.active then return end

	for _, bar in ipairs(container.bars) do
		bar.remaining = bar.remaining - elapsed
		if bar.remaining <= 0 then bar.remaining = PREVIEW_DURATION end
		SetPreviewTimer(bar)

		if bar.pending then
			driver.itemTime = (driver.itemTime or 0) + elapsed
			if driver.itemTime >= 1 then
				driver.itemTime = 0
				FillPreviewBar(bar)
			end
		end
	end
end

function LT:SetTestRolls(enabled)
	enabled = enabled and true or false
	if enabled == (self.testRolls or false) then return end
	if not self.rollAnchor then return end

	self.testRolls = enabled or nil
	self.rollPreviewDriver = self.rollPreviewDriver or CreateFrame('frame')

	if enabled then
		local container = self:CreateRollPreviews()
		for _, bar in ipairs(container.bars) do
			bar.remaining = bar.spec.remaining
			FillPreviewBar(bar)
		end
		self.rollPreviewDriver:SetScript('OnUpdate', OnPreviewUpdate)
	else
		self.rollPreviewDriver:SetScript('OnUpdate', nil)
	end

	self:UpdateRollPreviews()
end
