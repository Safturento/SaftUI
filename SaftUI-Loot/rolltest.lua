local st = SaftUI

local LT = st:GetModule('Loot')

-- Test mode's previews. The bars they use are rollbar.lua's; `held` is
-- roll.lua's table of the held bars (read only here).
local rollbar = LT.rollbar
local CreateBar, SetBarTransmog, LockBar = rollbar.CreateBar, rollbar.SetBarTransmog, rollbar.LockBar
local ApplyBarConfig, SetBarTimer = rollbar.ApplyBarConfig, rollbar.SetBarTimer
local ROLL_STRATA = rollbar.strata
local held = LT:GetHeldRolls()

------------------------------------
---- Test mode ---------------------
------------------------------------
-- Preview bars are SaftUI's own bars (CreateBar) that copy the look of a
-- skinned roll frame. Real Blizzard roll frames are never created, fed fake
-- data or touched; the previews only read whether one is showing. They hide
-- while a real roll is up or held (the real rolls own the anchor then) and come
-- back when it ends.
-- Each one has sample choices too: counts on its buttons and the rolls in its
-- tooltip, the way rollinfo.lua shows a real roll's. One is locked on your
-- choice, as a held roll is.
-- LT.testRolls is a plain field: not saved, off after /reload.

local PREVIEW_FALLBACK_ICON = 134400 -- INV_Misc_QuestionMark
local PREVIEW_DURATION = 300

-- The fallback name and quality are used until the client has the item data.
-- `choices` are made-up players with a state from LT.ROLL_STATE and, for a
-- main spec need, the roll the game makes at once. `me` is you: still to
-- choose, as on any roll bar that's still up, or on a `locked` one, the roll
-- button you chose (it's held). `leader` indexes `choices`.
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
		locked = 'Greed', choices = {
			{ name = 'Mistweave', class = 'PRIEST', state = 'Greed' },
			{ name = 'Quickshot', class = 'HUNTER', state = 'Greed' },
			{ name = 'Brightblade', class = 'PALADIN', state = 'Pass' },
			{ name = 'Emberfall', class = 'MAGE', state = 'Pass' },
			{ me = true, state = 'Greed' },
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

-- A real roll is up, or held.
local function RealRollShowing()
	if held[1] then return true end
	local container = GroupLootContainer
	if not container or not container.rollFrames then return false end
	for _, frame in pairs(container.rollFrames) do
		if frame:IsShown() then return true end
	end
	return false
end

-- Whether a real roll is up or held, for the roll mover's hidden check (roll.lua).
function LT:RealRollShowing()
	return RealRollShowing()
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
	local color = st:QualityColor(quality)
	if color then bar.Name:SetVertexColor(color.r, color.g, color.b) end

	local icon = C_Item.GetItemIconByID and C_Item.GetItemIconByID(spec.itemID)
	bar.Icon:SetTexture(icon or PREVIEW_FALLBACK_ICON)
end

local function CreatePreviewBar(parent, spec)
	local bar = CreateBar(parent)
	bar.spec = spec
	bar.remaining = spec.remaining
	bar.Timer:SetMinMaxValues(0, PREVIEW_DURATION)
	SetBarTransmog(bar, spec.transmog)
	LockBar(bar, spec.locked)

	bar.rolls = PreviewRolls(spec)
	LT:SetRollCounts(bar.counts, bar.rolls)
	LT:SetRollTooltipScripts(bar.IconFrame, PreviewTooltip)
	LT:SetRollTooltipScripts(bar.InfoFrame, PreviewTooltip)

	FillPreviewBar(bar)
	return bar
end

function LT:CreateRollPreviews()
	if self.rollPreview then return self.rollPreview end

	local container = CreateFrame('frame', nil, UIParent)
	container:SetFrameStrata(ROLL_STRATA)
	container:Hide()
	container.bars = {}
	for i, spec in ipairs(PREVIEW_ROLLS) do
		container.bars[i] = CreatePreviewBar(container, spec)
	end

	self.rollPreview = container
	return container
end

-- Re-applies size, theme, font, spacing, grow direction and position to the
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
		ApplyBarConfig(bar, config)
		SetBarTimer(bar, bar.remaining)

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
		SetBarTimer(bar, bar.remaining)

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
