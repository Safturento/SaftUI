local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The preview plate at the top of the Enemy and Friendly nameplates pages in
	/sui: a sample plate drawn from the page's settings, every part that is on
	showing at once, with made-up data. The options window gives a pick a band
	under its picker line (a pick's pickerBand, Core's optionswindow.lua) and
	UF.PlatePreviewBand(page) is what a plate page puts in it.

	The frame is SaftUI's own plain one, as the group test previews are
	(grouppreview.lua): no oUF frame, no unit, nothing secure or Blizzard's, so
	it is safe in combat. Its parts are the registered constructors' (the
	aura areas aside, below), placed, sized and themed by
	the real updaters (UF:UpdateElement and each element's UpdateConfig) from
	the same config a real plate of that kind reads (UF.PlateConfigKey: the
	page's, or the source page's while its box is checked), so a setting moves
	a part here as it does on a plate. Only what oUF would fill from a unit is
	filled by hand below, through the same helpers where the real code has
	them (UF.NameParts, UF.FormatName, UF.PlainHealthText).

	The aura areas are plain frames of the preview's own: the real ones are
	Blizzard's AuraContainer, which shows only real auras and whose buttons
	are restricted (.agents/taint.md rule 11). Each holds sample icon buttons,
	plain frames with Icon, Count and Cooldown as a container's buttons have,
	styled by the real StyleButton (UF.StyleAuraButton), the area sized by the
	real sums (UF.AuraAreaSize) and its buttons laid out by the area's Initial
	anchor, Per row, Spacing and growth.

	Styled from the page itself (draw runs on every render of the page, refresh
	in a slider drag), never from UF:UpdateConfig, so a change made in combat
	shows at once. The frame wears neither the target nor the hover border and
	no threat tint.
]]

local BAND_MARGIN = 12 -- above the highest part and below the lowest
local BAND_MIN, BAND_MAX = 120, 200

-- The sample plates. An enemy page's is a hostile elite NPC, a friendly
-- page's the player's own class. Spell icons both clients have.
local SAMPLE = {
	nameplate = {
		name = 'Thornfang Ravager', player = false, reaction = 2, classification = 'elite',
		class = 'WARRIOR', health = 180000, maxHealth = 250000,
		subtext = '<Pack Leader>', subtextBox = 'npc',
		spell = 'Shadow Bolt', icon = 136197, cast = 0.6, time = '1.2',
	},
	friendlynameplate = {
		name = 'Aldric', player = true, reaction = 5, classification = 'normal',
		health = 250000, maxHealth = 250000,
		subtext = '<Emerald Wardens>', subtextBox = 'player',
		spell = 'Flash Heal', icon = 135907, cast = 0.6, time = '1.2',
	},
}
local SAMPLE_THREAT = '87%'
local RAID_MARK = 8 -- skull
local QUEST_TEXTURE = [[Interface\TargetingFrame\PortraitQuestBadge]]

-- The aura areas, which the preview draws by itself (they are Blizzard's
-- AuraContainer on a real plate) instead of building the registered part.
local AURA_AREAS = { Buffs = true, Debuffs = true }

-- Each area's sample icons, and the stacks they show (nil: none).
local AURA_SAMPLE = {
	Debuffs = {
		icons = { 136207, 136118, 136139, 136096, 132155, 132204 },
		counts = { nil, 3, nil, 2, nil, 5 },
		-- A dispel type each, where the area colours by type (the last two
		-- have none).
		types = { 'Magic', 'Curse', 'Disease', 'Poison' },
	},
	Buffs = {
		icons = { 135987, 135932, 136078, 135953 },
		counts = {},
		-- The first is stealable, where the area colours stealable.
		stealable = 1,
	},
}
local DISPEL_COLORS = {
	Magic = { 0.2, 0.6, 1 }, Curse = { 0.6, 0, 1 }, Disease = { 0.6, 0.4, 0 }, Poison = { 0, 0.6, 0 },
}
-- The stealable border is an approximation of Blizzard's art (a plain tint).
local STEALABLE_COLOR = { 0.2, 0.6, 1 }
local AURA_DURATION, AURA_ELAPSED = 30, 10 -- the swipe, part way

local frames = {}

local function IsFriendlyPage(page) return page == 'friendlynameplate' end

-- The sample's class: a friendly page's is the player's own.
local function SampleClass(sample)
	if sample.class then return sample.class end
	local class = UnitClassBase and UnitClassBase('player')
	if type(class) ~= 'string' then class = select(2, UnitClass('player')) end
	return type(class) == 'string' and class or 'PRIEST'
end

local function PlainLevel()
	local level = UnitLevel('player')
	return type(level) == 'number' and level or nil
end

-- One sample icon button: a plain frame with what StyleButton styles and the
-- container's buttons have (Icon, Count, Cooldown), and the dispel or stealable
-- border's texture.
local function BuildAuraButton(area)
	local button = CreateFrame('Frame', nil, area)
	button.Icon = button:CreateTexture(nil, 'ARTWORK')
	button.Icon:SetAllPoints(button)
	st:SkinIcon(button.Icon)
	button.Border = button:CreateTexture(nil, 'BACKGROUND')
	button.Cooldown = CreateFrame('Cooldown', nil, button, 'CooldownFrameTemplate')
	button.Cooldown:SetAllPoints(button)
	button.Count = button:CreateFontString(nil, 'OVERLAY')
	return button
end

-- An aura area: a plain frame with the fields UF:UpdateElement and the styling
-- read (config, GetConfig, name, unitframe). It is sized by UF.AuraAreaSize,
-- not by its config's size (noSize), and its buttons are its own: made as the
-- area first needs them.
local function BuildAuraArea(frame, name)
	local area = CreateFrame('Frame', nil, frame)
	local key = string.lower(name)
	area.name = name
	area.unitframe = frame
	area.noSize = true
	area.buttons = {}
	area.GetConfig = function(_, unit) return frame:GetConfig(unit)[key] end
	area.config = area.GetConfig()
	frame[name] = area
	return area
end

-- Builds one page's frame, with the pieces UF.ConstructUnit gives a plate's
-- frame (minus what oUF drives and the tagging), parented to UIParent until
-- the band draws it.
local function Build(page)
	local frame = CreateFrame('Frame', 'SaftUI_PlatePreview_' .. page, UIParent)
	frame.isNamePlate = true
	frame.friendly = IsFriendlyPage(page)
	frame.base_unit = UF.PlateConfigKey(frame.friendly)
	frame.GetConfig = function(_, unit) return UF:GetProfileConfig()[unit or frame.base_unit] end
	frame.config = frame:GetConfig()
	-- Name's and Subtext's config code tags the text (oUF's): nothing here.
	frame.Tag, frame.Untag, frame.UpdateTags = function() end, function() end, function() end

	local overlay = CreateFrame('Frame', nil, frame)
	overlay:SetFrameLevel(99)
	overlay:SetAllPoints(frame)
	frame.TextOverlay = overlay

	-- Every part a plate has (it is built as nameplate, whichever config it
	-- draws from: UF.ConstructUnit's note), except those not built.
	frame.elements = {}
	for name, funcs in pairs(UF.elements) do
		if (not funcs.ValidUnit) or funcs.ValidUnit('nameplate') then
			if AURA_AREAS[name] then
				frame.elements[name] = BuildAuraArea(frame, name)
			else
				frame.elements[name] = funcs.Constructor(frame, name)
			end
		end
	end
	frame:Hide()
	return frame
end

function UF:PlatePreviewFrame(page)
	local frame = frames[page]
	if not frame then
		frame = Build(page)
		frames[page] = frame
	end
	return frame
end

-- Puts button number index (1-based) of an area where its config says: the
-- first at the Initial anchor, each next one a size plus the spacing along the
-- row, a row on after Per row, in the growth's directions.
local function PlaceAuraButton(area, button, index, size)
	local config = area.config
	local step = size + config.spacing
	local column = (index - 1) % config.per_row
	local row = math.floor((index - 1) / config.per_row)
	local anchor = config.initial_anchor or 'TOPLEFT'
	button:ClearAllPoints()
	button:SetPoint(anchor, area, anchor,
		column * step * (config.grow_right and 1 or -1),
		row * step * (config.grow_up and 1 or -1))
end

local function FillAuraButton(area, button, index, sample)
	local config = area.config
	button.Icon:SetTexture(sample.icons[index])
	local count = sample.counts[index]
	button.Count:SetText(count and tostring(count) or '')
	button.Count:SetShown(count ~= nil)

	-- The border's colour: a type's or the stealable one, only where the area
	-- colours that. StyleButton has drawn it for the theme.
	local color
	if area.name == 'Debuffs' and UF.AuraEither(config, 'colorTypes') then
		local dispel = sample.types[index]
		local oUF = UF.oUF and UF.oUF.colors and UF.oUF.colors.dispel and UF.oUF.colors.dispel[dispel]
		color = oUF and { oUF:GetRGB() } or DISPEL_COLORS[dispel or '']
	elseif area.name == 'Buffs' and index == sample.stealable and UF.AuraEither(config, 'colorStealable') then
		color = STEALABLE_COLOR
	end
	if color then
		button.Border:SetVertexColor(color[1], color[2], color[3])
		button.Border:Show()
	else
		button.Border:Hide()
	end

	-- The swipe part way, held there: a timer text, when it is on, reads the
	-- time left at that point.
	local cooldown = button.Cooldown
	if config.cooldown.enable then
		cooldown:SetCooldown(GetTime() - AURA_ELAPSED, AURA_DURATION)
		if cooldown.Pause then cooldown:Pause() end
		cooldown:Show()
	else
		cooldown:Hide()
	end
end

-- Styles one aura area from its config: placed and shown as UF:UpdateElement
-- does, sized by UF.AuraAreaSize, and its buttons (the sample's count, at most
-- Max) styled, laid out and filled.
local function StyleAuraArea(frame, name)
	local area = frame[name]
	local sample = AURA_SAMPLE[name]
	local enabled = UF:UpdateElement(area)
	local config = area.config
	local width, height = UF.AuraAreaSize(frame, config)
	area:SetSize(width, height)
	if not enabled then return end

	local size = UF.AuraButtonSize(frame, config)
	local wanted = math.min(config.max, #sample.icons)
	for index = 1, #sample.icons do
		local button = area.buttons[index]
		if index <= wanted then
			if not button then
				button = BuildAuraButton(area)
				area.buttons[index] = button
			end
			UF.StyleAuraButton(area, button)
			PlaceAuraButton(area, button, index, size)
			FillAuraButton(area, button, index, sample)
			button:Show()
		elseif button then
			button:Hide()
		end
	end
end

local function FillHealth(frame, sample, class)
	local health = frame.Health
	local config = health.config
	health:SetMinMaxValues(0, sample.maxHealth)
	health:SetValue(sample.health)
	UF.ApplyPreviewHealthColor(health, { player = sample.player, reaction = sample.reaction, class = class })
	if health.text and config.text.enable then
		health.text:SetText(UF.PlainHealthText(config.text, sample.health, sample.maxHealth, false, false))
	end
end

local function FillName(frame, sample, class)
	local name = frame.Name
	local config = name.config
	if not config.enable then return end
	local level = PlainLevel()
	local prefix, suffix = UF.NameParts(config, {
		level = (sample.player and level or level and level + 1), playerLevel = level, classification = sample.classification,
		reaction = sample.reaction, isPlayer = sample.player, isPet = false, class = class,
	})
	name:SetText(UF.FormatName(config, sample.name, prefix, suffix))
end

local function FillCastbar(frame, sample)
	local castbar = frame.Castbar
	local config = castbar.config
	castbar:SetMinMaxValues(0, 1)
	castbar:SetValue(sample.cast)
	-- An interruptible cast (the other colour isn't shown).
	local r, g, b = config.colors.normal:GetRGB()
	castbar:SetStatusBarColor(r, g, b)
	if config.bg and config.bg.enable then UF.SetPowerBackgroundColor(castbar, r, g, b) end
	castbar.Text:SetText(sample.spell)
	castbar.Time:SetText(sample.time)
	castbar.Icon:SetTexture(sample.icon)
end

local function FillOthers(frame, sample)
	local threat = frame.Threat
	if threat then
		threat:SetText(SAMPLE_THREAT)
		threat:SetTextColor(st:Color('text', 'normal'):GetRGB())
	end

	local subtext = frame.Subtext
	if subtext then
		local on = subtext.config[sample.subtextBox]
		subtext:SetText(on and sample.subtext or '')
		if not on then subtext:Hide() end
	end

	if frame.RaidTargetIndicator then
		SetRaidTargetIconTexture(frame.RaidTargetIndicator, RAID_MARK)
	end
	if frame.QuestIndicator then
		frame.QuestIndicator:SetTexture(QUEST_TEXTURE)
	end
end

-- Applies the page's look and the sample data: UF:UpdateUnitFrame's order
-- (the frame's size, each part's UpdateConfig, then the frame's backdrop),
-- then the data. Safe in combat.
function UF:StylePlatePreview(page)
	local frame = self:PlatePreviewFrame(page)
	frame.base_unit = UF.PlateConfigKey(frame.friendly)
	self:RefreshFrameConfig(frame)
	-- The parts are placed one by one: two anchored each way round across
	-- two configs would close a loop against the old points.
	UF.ClearPartPoints(frame)

	local config = frame.config
	st:SetSize(frame, config.width, config.height)
	for name, element in pairs(frame.elements) do
		local update = self.elements[name].UpdateConfig
		if AURA_AREAS[name] then
			StyleAuraArea(frame, name)
		elseif update then
			update(frame, name)
		else
			self:UpdateElement(element)
		end
	end
	st:SetBackdrop(frame, config.theme, config.background, UF.UnitKind(frame.base_unit))

	local sample = SAMPLE[page]
	local class = SampleClass(sample)
	FillHealth(frame, sample, class)
	FillName(frame, sample, class)
	FillCastbar(frame, sample)
	FillOthers(frame, sample)
	return frame
end

-- The parts whose rect counts for the extent: each shown part, with the
-- castbar's texts and icon and the health bar's text.
local function ShownRegions(frame)
	local regions = {}
	local function add(region)
		if region and region:IsShown() then regions[#regions + 1] = region end
	end
	for _, element in pairs(frame.elements) do
		if element ~= frame.Health then
			add(element)
			for _, text in pairs(element.textElements or {}) do add(text) end
			for _, icon in pairs(element.icons or {}) do add(icon) end
			for _, button in ipairs(element.buttons or {}) do add(button) end
		end
	end
	if frame.Health and frame.Health.text then add(frame.Health.text) end
	return regions
end

-- A whole number of pixels, a hair either side of one counting as it.
local function Whole(value)
	return math.ceil(value - 0.001)
end

-- How far the shown parts reach above the health bar's top and below its
-- bottom, in pixels (0 for a side nothing reaches past). A rect the game
-- hasn't laid out is left out.
function UF.PlatePreviewExtent(frame)
	local bar = frame.Health
	local barTop, barBottom = bar:GetTop(), bar:GetBottom()
	if not (barTop and barBottom) then return 0, 0 end
	local above, below = 0, 0
	for _, region in ipairs(ShownRegions(frame)) do
		local top, bottom = region:GetTop(), region:GetBottom()
		if top and bottom then
			-- Whole pixels per region: a text's edges are fractional in the
			-- game, and the bar must land on a whole pixel under them.
			above = math.max(above, Whole(top - barTop))
			below = math.max(below, Whole(barBottom - bottom))
		end
	end
	return above, below
end

-- Anchors the frame (to anything laid out) so its parts have rects to measure.
local function AnchorTemporarily(frame, parent)
	frame:ClearAllPoints()
	frame:SetPoint('TOP', parent, 'TOP', 0, 0)
end

-- Styles the page's frame under parent and measures it: the extent, and where
-- the health bar sits in the frame (its centre's distance from the frame's,
-- its top's below the frame's).
local function Measure(page, parent)
	local frame = UF:StylePlatePreview(page)
	AnchorTemporarily(frame, parent)
	local above, below = UF.PlatePreviewExtent(frame)
	return frame, above, below
end

-- The updaters give a part the absolute level its config names (UF:UpdateElementLevel,
-- about 2 to 7), right on a plate, under the /sui window's own frames here. So
-- once the frame is in the holder every such level is the holder's plus its
-- own, the text overlay goes over the highest of them, and the frame's box is
-- drawn again over them all (ThemeArt.LevelAbove, as on a plate). Real plates
-- are left as they are.
local function RelevelUnder(frame, holder)
	local base = holder:GetFrameLevel()
	frame:SetFrameLevel(base + 1)
	local top = base + 1
	local function raise(part)
		local level = part.config and part.config.framelevel
		if level and part.SetFrameLevel then
			part:SetFrameLevel(base + level)
			top = math.max(top, base + level)
		end
	end
	for _, element in pairs(frame.elements) do
		raise(element)
		for _, icon in pairs(element.icons or {}) do raise(icon) end
		-- An aura area's buttons sit just over their area.
		for _, button in ipairs(element.buttons or {}) do
			button:SetFrameLevel(element:GetFrameLevel() + 1)
			-- The cooldown is a child of the button, one over it.
			top = math.max(top, button:GetFrameLevel() + 1)
		end
	end
	frame.TextOverlay:SetFrameLevel(top + 1)
	local config = frame.config
	st:SetBackdrop(frame, config.theme, config.background, UF.UnitKind(frame.base_unit))
end

local bands = {}

-- The band a plate page carries (SetUpPlatePage): one table per page, since
-- the window reads it from the option tree and keeps its identity.
function UF.PlatePreviewBand(page)
	if bands[page] then return bands[page] end

	local function Place(holder)
		local frame, above = Measure(page, holder)
		frame:SetParent(holder)
		AnchorTemporarily(frame, holder)
		local bar = frame.Health
		local frameTop, barTop = frame:GetTop(), bar:GetTop()
		local frameX = (frame:GetLeft() + frame:GetRight()) / 2
		local barX = (bar:GetLeft() + bar:GetRight()) / 2
		-- The bar's centre goes under the holder's, its top below the margin
		-- and the highest part.
		frame:ClearAllPoints()
		-- The bar's top lands on a whole pixel under the holder's: the margin
		-- and the extent are whole, and the frame's offset to its bar is
		-- taken as it is, so the bar's own fraction cancels.
		local x = frameX - barX
		local y = -(BAND_MARGIN + above) + (frameTop - barTop)
		frame:SetPoint('TOP', holder, 'TOP', x, y)
		RelevelUnder(frame, holder)
		frame:Show()
	end

	bands[page] = {
		-- The window passes the body's width, which a plate's size doesn't
		-- depend on (a wider plate is clipped at the band's edges).
		height = function()
			if UF:NameplateAddon() then return nil end
			local frame, above, below = Measure(page, UIParent)
			local height = above + frame.Health:GetHeight() + below + 2 * BAND_MARGIN
			return Whole(math.min(BAND_MAX, math.max(BAND_MIN, height)))
		end,
		draw = function(holder) Place(holder) end,
		refresh = function(holder) Place(holder) end,
		release = function()
			local frame = frames[page]
			if frame then frame:Hide() end
		end,
	}
	return bands[page]
end
