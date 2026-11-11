local st = SaftUI

local LT = st:GetModule('Loot')

-- `atlas` is the art Blizzard's roll button for the choice draws (its
-- NormalTexture in GroupLootFrame.xml, the same on Forever and retail), which
-- SaftUI's own bars draw too.
local roll_buttons = {
	{name = 'Pass', icon_text = 'P', color = 'red', atlas = 'lootroll-toast-icon-pass-up'},
	{name = 'Greed', icon_text = 'G', color = 'yellow', atlas = 'lootroll-toast-icon-greed-up'},
	{name = 'Transmog', icon_text = 'DE', color = 'purple', atlas = 'lootroll-toast-icon-transmog-up'},
	{name = 'Need', icon_text = 'N', color = 'white', atlas = 'lootroll-toast-icon-need-up'},
}

-- SaftUI's pieces on Blizzard's roll frames. The frames and what's on them are
-- Blizzard's, so nothing is written onto them (.agents/taint.md rule 1): each
-- skinned frame has an entry here, keyed by the frame, and a Timer's text is
-- found through `timerTexts`, keyed by the Timer (the OnUpdate hook only gets
-- the Timer). An entry is { info = the info frame, iconBox = the frame that
-- holds the icon's backdrop, timerText, buttonText = { [choice] = font string },
-- shown = what the frame shows of its roll (GroupLootFrame_OnShow) }.
-- The info frame, icon box and texts are SaftUI's own.
local skins = setmetatable({}, { __mode = 'k' })
local timerTexts = setmetatable({}, { __mode = 'k' })

-- The held rolls (below) shown, oldest first; and released ones, kept to show
-- the next held roll.
local held, heldPool = {}, {}

-- A value that isn't secret (.agents/clients.md), else nil.
local function Plain(v)
	if not issecretvalue(v) then return v end
end

-- A roll timer's value in seconds. Blizzard's roll timer runs from the roll's
-- length (START_LOOT_ROLL's rollTime, its max) down to 0 by GetLootRollTimeLeft.
-- The two share a unit (GroupLootFrame_OnUpdate clamps one to the other), and
-- GetLootRollTimeLeft is documented in milliseconds. A length over 1000 is taken
-- as milliseconds, anything else as seconds: no roll lasts under a second or
-- over 1000 seconds.
function LT.RollSeconds(value, length)
	if type(length) == 'number' and length > 1000 then return value / 1000 end
	return value
end

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
	st:SetBackdrop(skin.info, config.theme, config.background, 'bar')

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
	st:SetBackdrop(skin.iconBox, config.theme, config.background, 'small')
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
			--st:SetBackdrop(button, config.theme, config.background, 'small')
			prev = button
		end
	end

	skin.timerText:SetFontObject(st:GetFont(config.font))
	skin.timerText:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
	skin.timerText:SetWidth(40)
end

function LT:GroupLootFrame_OnShow(frame)
	local texture, name, count, quality, bindOnPickUp, canNeed, canGreed, canDisenchant, reasonNeed, reasonGreed, reasonDisenchant, deSkillRequired, canTransmog = GetLootRollItemInfo(frame.rollID);
	-- A queued roll that expired before its turn has no item: Blizzard's own
	-- OnShow has already taken the frame away, so there's nothing to style.
	if not name then return end

	-- The item's quality color, as Blizzard's own OnShow gives it.
	local color = st:QualityColor(quality)
	if color then
		frame.Timer:SetStatusBarColor(color.r, color.g, color.b)
		frame.Name:SetVertexColor(color.r, color.g, color.b)
	end

	local text = ''

	if (quality >= 3) and (not bindOnPickUp) then
		text = 'BoE '
	end

	if count > 1 then
		text = text .. '(' .. count .. ') '
	end

	frame.Name:SetText(text .. name)

	-- What the bar shows of its roll, for the held bar that takes its place if
	-- you choose on it (LT:HoldRoll).
	local skin = skins[frame]
	if skin then
		skin.shown = {
			rollID = Plain(frame.rollID), texture = texture, text = text .. name,
			color = color, transmog = canTransmog == true,
		}
	end
end

function LT:GroupLootFrame_OnUpdateTimer(timer, elapsed)
	local text = timerTexts[timer]
	if not text then return end
	local _, length = timer:GetMinMaxValues()
	local sec = LT.RollSeconds(timer:GetValue(), length)

	text:SetText(st.StringFormat:ToClock(sec))

	timer:SetStatusBarColor(st.config.profile.colors.button.blue:GetRGB())

	if sec < 60 then
		text:SetVertexColor(st.config.profile.colors.text.red:GetRGB())
	else
		text:SetVertexColor(1, 1, 1)
	end
end

------------------------------------
---- SaftUI's own roll bars --------
------------------------------------
-- Copies of a skinned roll bar, SaftUI's own frames: Test mode's previews and
-- the held rolls (below). Each has the same size, theme, font, spacing, icon,
-- name, timer and buttons as a skinned bar, the buttons with their counts.

-- The alpha of a locked bar's other buttons: Blizzard's for a roll button it
-- disables.
local LOCKED_ALPHA = 0.35

-- A bar with all four roll buttons, in the real buttons' order (the first sits
-- at the right edge), Greed or Transmog hidden by SetBarTransmog. The buttons
-- draw Blizzard's roll button art, and are plain frames that take no mouse:
-- nothing on a bar can be clicked. `Choice` is the label a locked bar names your
-- choice with.
local function CreateBar(parent)
	local bar = CreateFrame('frame', nil, parent)
	local level = bar:GetFrameLevel()

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
	-- A font is needed before text is set (SetText errors on a font string
	-- without one); ApplyBarConfig re-applies it with the rest.
	local font = st:GetFont(LT.config.roll.font)
	bar.Timer.Text = bar.Timer:CreateFontString(nil, 'OVERLAY')
	bar.Timer.Text:SetFontObject(font)
	bar.Name = bar.Timer:CreateFontString(nil, 'OVERLAY')
	bar.Name:SetFontObject(font)
	bar.Name:SetJustifyH('LEFT')
	bar.Name:SetWordWrap(false)
	bar.Name:SetVertexColor(1, 1, 1)
	bar.Choice = bar.Timer:CreateFontString(nil, 'OVERLAY')
	bar.Choice:SetFontObject(st:GetFont('pixel'))
	bar.Choice:Hide()

	bar.buttons = {}
	bar.counts = {}
	for _, info in ipairs(roll_buttons) do
		local button = CreateFrame('frame', nil, bar)
		button.choice = info.name
		button:SetFrameLevel(level + 3)
		button:EnableMouse(false)
		button.Icon = button:CreateTexture(nil, 'ARTWORK')
		button.Icon:SetAllPoints()
		button.Icon:SetAtlas(info.atlas)
		LT:CreateRollCounts(bar.counts, button, info.name)
		tinsert(bar.buttons, button)
	end
	return bar
end

-- Like Blizzard, a bar has Transmog in place of Greed when the item can be
-- transmogged.
local function SetBarTransmog(bar, transmog)
	for _, button in ipairs(bar.buttons) do
		if button.choice == 'Greed' then
			button:SetShown(not transmog)
		elseif button.choice == 'Transmog' then
			button:SetShown(transmog and true or false)
		end
	end
end

-- The lit border of a locked bar's chosen button: Buttons > Blue on its icon's
-- backdrop. Kept through a theme recolor or redraw (st:KeepOwnColors).
local function ColorLit(icon)
	if icon.backdrop then
		icon.backdrop:SetBackdropBorderColor(st.config.profile.colors.button.blue:GetRGB())
	end
end

-- Locks a bar on your choice (a roll button's name), or unlocks it (nil): the
-- chosen button stays bright and the others dim, and the label names it.
-- ApplyBarConfig gives the chosen button its lit border.
local function LockBar(bar, choice)
	bar.choice = choice
	for _, button in ipairs(bar.buttons) do
		button:SetAlpha((choice == nil or button.choice == choice) and 1 or LOCKED_ALPHA)
	end
	bar.Choice:SetText(choice or '')
	bar.Choice:SetShown(choice ~= nil)
end

-- A locked bar's lit border and label in the current Buttons > Blue.
local function ColorLocked(bar)
	for _, button in ipairs(bar.buttons) do
		if button.choice == bar.choice then ColorLit(button.Icon) end
	end
	bar.Choice:SetTextColor(st.config.profile.colors.button.blue:GetRGB())
end

-- The same sizing as UpdateRollFrame, from the live roll config. A locked bar's
-- chosen button gets a border, lit, on its edges with its art inside; every
-- other button has none, as on Blizzard's bar.
local function ApplyBarConfig(bar, config)
	local font = st:GetFont(config.font)

	bar:SetSize(config.width, config.height)
	bar.IconFrame:SetSize(config.height, config.height)
	st:SetBackdrop(bar.IconFrame, config.theme, config.background, 'small')
	st:SetBackdrop(bar.InfoFrame, config.theme, config.background, 'bar')

	bar.Timer:ClearAllPoints()
	bar.Timer:SetPoint('BOTTOMLEFT', bar.IconFrame, 'BOTTOMRIGHT', config.spacing, 0)
	bar.Timer:SetHeight(1)
	bar.Timer:SetWidth(config.width - config.height - config.spacing)

	local prev
	for _, button in ipairs(bar.buttons) do
		button:SetSize(config.height - 4, config.height - 4)
		button:ClearAllPoints()
		if button:IsShown() then
			if not prev then
				button:SetPoint('RIGHT', bar.InfoFrame, 'RIGHT', -2, 0)
			else
				button:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
			end
			prev = button
		end

		local lit = bar.choice ~= nil and button.choice == bar.choice
		local inset = lit and st:ThemeInset(config.theme, config.background) or 0
		button.Icon:ClearAllPoints()
		button.Icon:SetPoint('TOPLEFT', button, 'TOPLEFT', inset, -inset)
		button.Icon:SetPoint('BOTTOMRIGHT', button, 'BOTTOMRIGHT', -inset, inset)
		if lit then
			st:SetBackdrop(button.Icon, config.theme, config.background, 'small')
			st:KeepOwnColors(button.Icon, ColorLit)
		elseif button.Icon.backdrop then
			-- Lit for an earlier choice (a held bar is reused).
			st:SetBackdrop(button.Icon, 'none')
			st:KeepOwnColors(button.Icon, nil)
		end
	end

	bar.Timer.Text:SetFontObject(font)
	bar.Timer.Text:ClearAllPoints()
	bar.Timer.Text:SetPoint('RIGHT', prev, 'LEFT', -2, 0)
	bar.Timer.Text:SetWidth(40)

	-- The label sits before the timer, and the name before it.
	local nameEnd = bar.Timer.Text
	bar.Choice:SetFontObject(st:GetFont('pixel'))
	bar.Choice:ClearAllPoints()
	if bar.choice then
		bar.Choice:SetPoint('RIGHT', bar.Timer.Text, 'LEFT', -2, 0)
		nameEnd = bar.Choice
	end

	bar.Name:SetFontObject(font)
	bar.Name:ClearAllPoints()
	bar.Name:SetHeight(config.height)
	bar.Name:SetPoint('LEFT', bar.InfoFrame, 5, 0)
	bar.Name:SetPoint('RIGHT', nameEnd, 'LEFT', -5, 0)

	-- The lit border, and the label.
	if bar.choice then ColorLocked(bar) end
end

-- The timer at `sec` seconds left, as GroupLootFrame_OnUpdateTimer shows a
-- skinned bar's.
local function SetBarTimer(bar, sec)
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

------------------------------------
---- Held rolls --------------------
------------------------------------
-- When you choose on a roll, Blizzard takes its bar away (CANCEL_LOOT_ROLL ->
-- GroupLootFrame_Remove; a main spec Need after its dice animation). Keeping it
-- would mean replacing Blizzard's code (.agents/taint.md rule 2), so SaftUI
-- shows a bar of its own in its place instead, locked on your choice, until
-- the roll ends. rollinfo.lua says when (LT:HoldRoll), matches it to its loot
-- history drop and keeps its counts and tooltip up to date, and takes it away
-- when the drop resolves; it goes here when its time runs out.

local heldParent

-- Held bars and the previews stand where Blizzard's roll frames do, so they
-- draw at their strata (GroupLootFrame.xml: DIALOG).
local ROLL_STRATA = 'DIALOG'

-- The held bars shown, oldest first. Read only.
function LT:GetHeldRolls()
	return held
end

-- A held bar's tooltip: its item, then its drop's rolls (none without a drop).
local function HeldTooltip(owner)
	local bar = owner:GetParent()
	return 'SetHyperlink', bar.link, bar.rolls
end

-- Every frame while a roll is held.
local function OnHeldUpdate()
	LT:UpdateHeldRolls()
end

-- Counts each held roll's time down, and takes away those whose time is up.
function LT:UpdateHeldRolls()
	local now = GetTime()
	local ended
	for _, bar in ipairs(held) do
		local left = bar.ends - now
		if left > 0 then
			SetBarTimer(bar, left)
		else
			ended = ended or {}
			tinsert(ended, bar)
		end
	end
	for _, bar in ipairs(ended or {}) do
		self:ReleaseHeldRoll(bar)
	end
end

-- SaftUI's roll stack, from the anchor out: Blizzard's roll frames ({ frame,
-- rollID }) and the held bars ({ bar }). LayoutRollFrames keeps it.
local stack = {}

-- Holds the roll `frame` showed, after you chose on it: a held bar, locked on
-- your choice, takes the frame's place in the stack. `roll` is rollinfo.lua's:
-- { rollID, choice (a roll button's name), ends (the GetTime its time runs
-- out), length (the roll's, in seconds), link, item, itemID, dropID, rolls }.
-- The choice 'Disenchant' (an addon's RollOnLoot; no bar has its button) lights
-- whichever of Greed and Transmog the bar shows. Returns the bar, or nil when
-- there's nothing to hold: the frame didn't show that roll, or it has under a
-- second left. (A choice is noted at the click, before a bind on pickup
-- confirmation, so declining it and letting the roll time out would otherwise
-- hold it for an instant.)
function LT:HoldRoll(frame, roll)
	local skin = skins[frame]
	local shown = skin and skin.shown
	if not shown or shown.rollID == nil or shown.rollID ~= roll.rollID then return end
	if roll.ends - GetTime() < 1 then return end
	local choice = roll.choice
	if choice == 'Disenchant' then choice = shown.transmog and 'Transmog' or 'Greed' end

	if not heldParent then
		heldParent = CreateFrame('frame', nil, UIParent)
		heldParent:SetFrameStrata(ROLL_STRATA)
	end
	local bar = tremove(heldPool)
	if not bar then
		bar = CreateBar(heldParent)
		self:SetRollTooltipScripts(bar.IconFrame, HeldTooltip)
		self:SetRollTooltipScripts(bar.InfoFrame, HeldTooltip)
	end
	bar.holding = true
	bar.rollID, bar.from = roll.rollID, frame
	bar.ends, bar.length = roll.ends, roll.length
	bar.link, bar.item, bar.itemID = roll.link, roll.item, roll.itemID
	bar.dropID, bar.rolls = roll.dropID, roll.rolls
	bar.shownSecond = nil

	bar.Icon:SetTexture(shown.texture)
	bar.Name:SetText(shown.text)
	local color = shown.color
	if color then
		bar.Name:SetVertexColor(color.r, color.g, color.b)
	else
		bar.Name:SetVertexColor(1, 1, 1)
	end
	SetBarTransmog(bar, shown.transmog)
	LockBar(bar, choice)
	self:SetRollCounts(bar.counts, bar.rolls)
	bar.Timer:SetMinMaxValues(0, roll.length)
	ApplyBarConfig(bar, self.config.roll)
	SetBarTimer(bar, roll.ends - GetTime())

	local entry = { bar = bar }
	for i, other in ipairs(stack) do
		if other.frame == frame then
			stack[i], entry = entry, nil
			break
		end
	end
	if entry then tinsert(stack, entry) end

	tinsert(held, bar)
	bar:Show()
	heldParent:SetScript('OnUpdate', OnHeldUpdate)
	self:LayoutRollFrames()
	self:UpdateRollPreviewVisibility()
	return bar
end

-- Takes a held bar away (its roll ended), and closes the gap.
function LT:ReleaseHeldRoll(bar)
	if not bar.holding then return end
	for i, other in ipairs(held) do
		if other == bar then
			tremove(held, i)
			break
		end
	end
	bar.holding = nil
	bar:Hide()
	bar.rollID, bar.from, bar.link, bar.item, bar.itemID = nil, nil, nil, nil, nil
	bar.dropID, bar.rolls = nil, nil
	for _, button in ipairs(bar.buttons) do
		st:KeepOwnColors(button.Icon, nil)
	end
	tinsert(heldPool, bar)
	if not held[1] then heldParent:SetScript('OnUpdate', nil) end

	self:LayoutRollFrames()
	self:UpdateRollPreviewVisibility()
end

------------------------------------
---- Anchor and layout -------------
------------------------------------

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

-- Stacks Blizzard's roll frames and the held rolls from the anchor, with no
-- gaps. A held bar stays where its roll's frame was. A new roll goes last, so a
-- roll starting never moves a bar on screen; only a roll ending closes its gap.
-- Rolls new at once go in the order of their slots in rollFrames (Blizzard
-- leaves holes there when a roll ends, puts a new roll in the first hole, and
-- walks 1..maxIndex).
function LT:LayoutRollFrames()
	local anchor = self.rollAnchor
	if not anchor then return end
	local container = GroupLootContainer
	local config = self.config.roll

	local slots = {}
	if container and container.rollFrames then
		for i = 1, container.maxIndex or 4 do
			local frame = container.rollFrames[i]
			if frame then slots[frame] = i end
		end
	end

	-- A frame a held bar has taken the place of, until it shows another roll
	-- (Blizzard takes it out of rollFrames just after it hides).
	local heldFrom = {}
	for _, bar in ipairs(held) do
		if bar.from then heldFrom[bar.from] = bar.rollID end
	end

	-- What's gone: a roll Blizzard took away, a frame that shows another roll
	-- now, a held bar that went.
	for i = #stack, 1, -1 do
		local entry = stack[i]
		local keep
		if entry.frame then
			keep = slots[entry.frame] ~= nil and Plain(entry.frame.rollID) == entry.rollID
			if keep then slots[entry.frame] = nil end
		else
			keep = entry.bar.holding
		end
		if not keep then tremove(stack, i) end
	end

	local new = {}
	for frame, slot in pairs(slots) do
		local rollID = Plain(frame.rollID)
		if heldFrom[frame] == nil or heldFrom[frame] ~= rollID then
			tinsert(new, { frame = frame, rollID = rollID, slot = slot })
		end
	end
	table.sort(new, function(a, b) return a.slot < b.slot end)
	for _, entry in ipairs(new) do
		tinsert(stack, entry)
	end

	local prev
	for _, entry in ipairs(stack) do
		local frame = entry.frame or entry.bar
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
	-- Every roll cancelled at once (rollinfo.lua).
	self:RegisterEvent('CANCEL_ALL_LOOT_ROLLS', 'OnCancelAllLootRolls')
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

-- Only SaftUI's anchor, its own bars and the (unprotected) roll frames are
-- touched, never GroupLootContainer. Everything here hangs off the anchor, so a
-- protected frame (e.g. a unit frame) anchored to any of it makes the anchor
-- protected; in combat the update then waits for the end of combat.
-- A Buttons color change (st:ColorsChanged('button'), through LT:OnColorsChanged):
-- a locked bar's lit border and label take the new blue at once. A theme recolor
-- or redraw keeps the lit border through st:KeepOwnColors.
function LT:ColorRollBars(group)
	if group ~= 'button' then return end
	for _, bar in ipairs(held) do
		ColorLocked(bar)
	end
	for _, bar in ipairs(self.rollPreview and self.rollPreview.bars or {}) do
		if bar.choice then ColorLocked(bar) end
	end
end

function LT:UpdateGroupLootConfig()
	st:SafeReposition(self:CreateRollAnchor(), 'lootroll', function()
		self:ApplyRollAnchor()
		for _,frame in ipairs(self.skinnedRollFrames or {}) do
			self:UpdateRollFrame(frame)
		end
		for _, bar in ipairs(held) do
			ApplyBarConfig(bar, self.config.roll)
			SetBarTimer(bar, max(0, bar.ends - GetTime()))
		end
		self:LayoutRollFrames()
		self:UpdateRollPreviews()
	end)
end

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
