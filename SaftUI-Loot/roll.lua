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

-- Forever keeps the roll buttons in a LootButtonContainer child; retail has
-- them directly on the roll frame.
local function GetRollButton(frame, name)
	local container = frame.LootButtonContainer or frame
	return container[name..'Button']
end

function LT:SkinRollFrame(frame)
	if frame.skinned then return end
	frame.skinned = true

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

	frame.Timer.Text = frame.Timer:CreateFontString(nil, 'OVERLAY')
	frame.Timer.Text:SetFontObject(GameFontNormal)

	local prev
	for i, info in ipairs(roll_buttons) do
		local button = GetRollButton(frame, info.name)
		if button then
			button.Text = button:CreateFontString(nil, 'OVERLAY')
			button.Text:SetFontObject(GameFontNormal)
			button.Text:SetPoint('CENTER', 1, 0)
			button.Text:SetVertexColor(st.config.profile.colors.text[info.color]:GetRGB())

			prev = button
		end
	end

	self:SecureHookScript(frame, 'OnShow', 'GroupLootFrame_OnShow')
	self:SecureHookScript(frame.Timer, 'OnUpdate', 'GroupLootFrame_OnUpdateTimer')
	self:UpdateRollFrame(frame)
end

function LT:UpdateRollFrame(frame)
	local config = self.config.roll
	local font_obj = st:GetFont(config.font)

	frame:SetSize(config.width, config.height)

	-- Updates run on every live option change, so only create this once.
	if not frame.InfoFrame then
		frame.InfoFrame = st:CreateFrame('frame', nil, frame)
		frame.InfoFrame:SetPoint('BOTTOMRIGHT')
		frame.InfoFrame:SetPoint('TOPLEFT', frame.IconFrame, 'TOPRIGHT', 7, 0)
		frame.InfoFrame:SetFrameLevel(1)
	end
	st:SetBackdrop(frame.InfoFrame, config.template)

	frame.Name:SetFontObject(st:GetFont(config.font))
	frame.Name:ClearAllPoints()
	frame.Name:SetHeight(config.height)
	frame.Name:SetPoint('LEFT', frame.InfoFrame, 5, 0)
	frame.Name:SetPoint('RIGHT', frame.Timer.Text, 'LEFT', -5, 0)

	st:SetBackdrop(frame.IconFrame, config.template)
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
				button:SetPoint('RIGHT', frame.InfoFrame, 'RIGHT', -2, 0)
			else
				button:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
			end

			button.Text:SetFontObject(st:GetFont(config.font))

			button:SetSize(config.height - 4, config.height - 4)
			--st:SetBackdrop(button, config.template)
			prev = button
		end
	end

	frame.Timer.Text:SetFontObject(st:GetFont(config.font))
	frame.Timer.Text:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
	frame.Timer.Text:SetWidth(40)
end

function LT:GroupLootFrame_OnShow(frame)
	local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant, deSkillRequired = GetLootRollItemInfo(frame.rollID);

	local color = ITEM_QUALITY_COLORS[quality]
	frame.Timer:SetStatusBarColor(color.r, color.g, color.b)
	frame.Name:SetVertexColor(1, 1, 1)

	local text = ''

	if (quality >= 3) and (not bindOnPickUp) then
		text = 'BoE '
	end

	if count > 1 then
		text = text .. '(' .. count .. ') '
	end

	frame.Name:SetText(text .. name)
end

function LT:GroupLootFrame_OnUpdateTimer(self, elapsed)
	local sec = self:GetValue()

	self.Text:SetText(st.StringFormat:ToClock(sec))

	self:SetStatusBarColor(st.config.profile.colors.button.blue:GetRGB())

	if sec < 60 then
		self.Text:SetVertexColor(st.config.profile.colors.text.red:GetRGB())
	else
		self.Text:SetVertexColor(1, 1, 1)
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
-- LT.testRolls is a plain field: not saved, off after /reload.

local PREVIEW_FALLBACK_ICON = 134400 -- INV_Misc_QuestionMark
local PREVIEW_DURATION = 300

-- The fallback name and quality are used until the client has the item data.
local PREVIEW_ROLLS = {
	{ itemID = 19019, name = 'Thunderfury, Blessed Blade of the Windseeker', quality = 5,
		count = 1, bindOnPickUp = true, transmog = true, remaining = 250 },
	{ itemID = 16309, name = 'Drakefire Amulet', quality = 4,
		count = 1, bindOnPickUp = false, transmog = false, remaining = 170 },
	{ itemID = 2589, name = 'Linen Cloth', quality = 1,
		count = 5, bindOnPickUp = false, transmog = true, remaining = 90 },
	{ itemID = 1204, name = 'The Green Tower', quality = 2,
		count = 1, bindOnPickUp = false, transmog = false, remaining = 45 },
}

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
	bar.buttons = {}
	for _, info in ipairs(roll_buttons) do
		if info.name ~= 'Transmog' or spec.transmog then
			local button = CreateFrame('frame', nil, bar)
			button:SetFrameLevel(level + 3)
			button.Icon = button:CreateTexture(nil, 'ARTWORK')
			button.Icon:SetAllPoints()
			button.Icon:SetTexture(info.icon_texture)
			st:SkinIcon(button.Icon)
			tinsert(bar.buttons, button)
		end
	end

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
