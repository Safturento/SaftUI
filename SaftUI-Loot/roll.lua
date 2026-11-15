local st = SaftUI

local LT = st:GetModule('Loot')

-- The roll bars are rollbar.lua's, taken from `LT.rollbar`.
local rollbar = LT.rollbar
local roll_buttons, ROLL_STRATA = rollbar.buttons, rollbar.strata
local CreateBar, SetBarTransmog, LockBar = rollbar.CreateBar, rollbar.SetBarTransmog, rollbar.LockBar
local ColorLocked, ApplyBarConfig, SetBarTimer = rollbar.ColorLocked, rollbar.ApplyBarConfig, rollbar.SetBarTimer

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
	for _, info in ipairs(roll_buttons) do
		local button = GetRollButton(frame, info.name)
		if button then
			local text = button:CreateFontString(nil, 'OVERLAY')
			skin.buttonText[info.name] = text
			text:SetFontObject(GameFontNormal)
			text:SetPoint('CENTER', 1, 0)
			text:SetVertexColor(st:Color('loot', info.color):GetRGB())
			self:CreateRollCounts(counts, button, info.name)
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

	st:ApplyFont(frame.Name, config.font)
	frame.Name:ClearAllPoints()
	frame.Name:SetHeight(config.height)
	frame.Name:SetPoint('LEFT', skin.info, 5, 0)
	frame.Name:SetPoint('RIGHT', skin.timerText, 'LEFT', -5, 0)

	-- st:SetBackdrop writes onto the frame it's given, so the icon's backdrop
	-- hangs off a SaftUI frame laid over the icon frame instead. The box is one
	-- level over the icon frame, which holds Blizzard's icon, so the ring the
	-- Blizzard theme draws as a texture of the box lies over the icon, where
	-- at the same level their order would be undefined. (The frame's count,
	-- which the ring would otherwise cover, is killed above.) The backdrop
	-- sits one below the icon frame, as before, under the icon. The icon
	-- frame is Blizzard's, so its level can be secret: then both stay at the
	-- levels they were made at (the box its child, one over it).
	local iconLevel = frame.IconFrame:GetFrameLevel()
	if issecretvalue(iconLevel) then iconLevel = nil end
	if not skin.iconBox then
		skin.iconBox = st:CreateFrame('frame', nil, frame.IconFrame)
		skin.iconBox:SetAllPoints(frame.IconFrame)
		if iconLevel then skin.iconBox:SetFrameLevel(iconLevel + 1) end
	end
	st:SetBackdrop(skin.iconBox, config.theme, config.background, 'slot')
	if skin.iconBox.backdrop and iconLevel then
		skin.iconBox.backdrop:SetFrameLevel(max(0, iconLevel - 1))
	end
	st:ApplyFont(frame.IconFrame.Count, config.font)
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

			st:ApplyFont(skin.buttonText[info.name], config.font)

			button:SetSize(config.height - 4, config.height - 4)
			--st:SetBackdrop(button, config.theme, config.background, 'small')
			prev = button
		end
	end

	st:ApplyFont(skin.timerText, config.font)
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
			rollID = st.Plain(frame.rollID), texture = texture, text = text .. name,
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

	timer:SetStatusBarColor(st:Color('accent'):GetRGB())

	if sec < 60 then
		text:SetVertexColor(st.config.profile.colors.text.red:GetRGB())
	else
		text:SetVertexColor(1, 1, 1)
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
-- history drop and keeps its counts and tooltip up to date, and finishes it
-- when the drop resolves; it's finished here when its time runs out.
--
-- A finished bar doesn't vanish: it stays in the stack, locked, for
-- FINISHED_HOLD seconds, fades out over FINISHED_FADE, and is then released
-- (LT:ReleaseHeldRoll), which closes its gap. So choosing last on a roll, which
-- resolves at the click, still shows your choice for a moment.

-- How long a finished held bar stays up, and how long it then takes to fade.
local FINISHED_HOLD, FINISHED_FADE = 3, 0.5

local heldParent

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

-- Seconds left on a held bar's timer: run on from the clock, or where it stood
-- when the bar finished.
local function HeldLeft(bar)
	if bar.finishedAt then return bar.finishedLeft end
	return max(0, bar.ends - GetTime())
end

-- Finishes a held bar (`why` says for the debug print: its drop resolved, or
-- its time ran out): it stays up locked for FINISHED_HOLD seconds, then fades
-- (LT:UpdateHeldRolls), then is released. It takes no drop from then on
-- (rollinfo.lua leaves finished bars out), so a new roll of the same item
-- matches as if it weren't there. Its timer stops: empty when its time ran
-- out, otherwise where it was. `rolls` is the drop's last summary, if it could
-- be read; without it the bar keeps the counts it had. It remembers the drop
-- it finished on (`finalDropID`), only to show later results for it
-- (LT:UpdateRollBars): a time-out's auto-passes and winner can arrive inside
-- the linger.
function LT:FinishHeldRoll(bar, why, rolls)
	if not bar.holding or bar.finishedAt then return end
	bar.finishedLeft = why == 'time' and 0 or HeldLeft(bar)
	bar.finishedAt = GetTime()
	bar.finalDropID, bar.dropID = bar.dropID, nil
	if rolls then
		bar.rolls = rolls
		self:SetRollCounts(bar.counts, rolls)
	end
	SetBarTimer(bar, bar.finishedLeft)
	if st.DEBUG then
		-- What the result was, to tell a real one from a misread drop (a winner
		-- set before the roll ends): how many are still waiting, and who won.
		local summary = rolls or bar.rolls
		local waiting = 0
		for _, line in ipairs(summary and summary.list or {}) do
			if line.state == self.ROLL_STATE.NoRoll then waiting = waiting + 1 end
		end
		st:Debug('Loot', 'held roll finished:', bar.rollID, why, 'waiting', waiting,
			summary and (summary.allPassed and 'all passed' or summary.winner and 'winner' or 'no winner') or 'no summary')
	end
end

-- Counts each held roll's time down, finishes those whose time is up, and fades
-- and releases the finished ones. The only per-frame work: it prints nothing
-- except as a bar finishes or goes.
function LT:UpdateHeldRolls()
	local now = GetTime()
	local gone
	for _, bar in ipairs(held) do
		if bar.finishedAt then
			local over = now - bar.finishedAt - FINISHED_HOLD
			if over >= FINISHED_FADE then
				gone = gone or {}
				tinsert(gone, bar)
			elseif over > 0 then
				bar:SetAlpha(1 - over / FINISHED_FADE)
			end
		else
			local left = bar.ends - now
			if left > 0 then
				SetBarTimer(bar, left)
			else
				self:FinishHeldRoll(bar, 'time')
			end
		end
	end
	for _, bar in ipairs(gone or {}) do
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
	if not shown or shown.rollID == nil or shown.rollID ~= roll.rollID then
		if st.DEBUG then st:Debug('Loot', 'hold', roll.rollID, 'skipped: the frame did not show that roll') end
		return
	end
	if roll.ends - GetTime() < 1 then
		if st.DEBUG then st:Debug('Loot', 'hold', roll.rollID, 'skipped: under a second left') end
		return
	end
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
	bar.finishedAt, bar.finishedLeft, bar.finalDropID = nil, nil, nil
	bar:SetAlpha(1)
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
	if st.DEBUG then st:Debug('Loot', 'held roll', bar.rollID, 'choice', choice, 'seconds left', ('%.1f'):format(roll.ends - GetTime())) end
	return bar
end

-- Takes a held bar away (its linger is over, or every roll was cancelled), and
-- closes the gap.
function LT:ReleaseHeldRoll(bar)
	if not bar.holding then return end
	if st.DEBUG then st:Debug('Loot', 'held roll released:', bar.rollID) end
	for i, other in ipairs(held) do
		if other == bar then
			tremove(held, i)
			break
		end
	end
	bar.holding = nil
	bar.finishedAt, bar.finishedLeft, bar.finalDropID = nil, nil, nil
	bar:SetAlpha(1)
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
	st:PlaceAtPosition(anchor, config.position)
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
			keep = slots[entry.frame] ~= nil and st.Plain(entry.frame.rollID) == entry.rollID
			if keep then slots[entry.frame] = nil end
		else
			keep = entry.bar.holding
		end
		if not keep then tremove(stack, i) end
	end

	local new = {}
	for frame, slot in pairs(slots) do
		local rollID = st.Plain(frame.rollID)
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

-- True while a roll bar is on screen: a real or held roll (rolltest.lua's
-- RealRollShowing), or Test mode's previews. Only reads.
local function AnyRollBarShown(self)
	if self.RealRollShowing and self:RealRollShowing() then return true end
	return (self.rollPreview and self.rollPreview:IsShown()) == true
end

function LT:RegisterRollMover()
	st:RegisterConfigMover(self.rollAnchor, {
		key = 'lootroll',
		label = 'Loot Rolls',
		config = function() return self.config.roll end,
		apply = function() self:UpdateGroupLootConfig() end,
		configPath = { 'Loot', 'roll', 'general' },
		module = 'Loot',
		isHidden = function() return not AnyRollBarShown(self) end,
		defaults = function() return st.defaults.loot.roll end,
	})
end

-- Only SaftUI's anchor, its own bars and the (unprotected) roll frames are
-- touched, never GroupLootContainer. Everything here hangs off the anchor, so a
-- protected frame (e.g. a unit frame) anchored to any of it makes the anchor
-- protected; in combat the update then waits for the end of combat.
-- An accent change (st:ColorsChanged('accent'), through LT:OnColorsChanged):
-- a locked bar's lit border and label take the new accent at once. A theme
-- recolor or redraw keeps the lit border through st:KeepOwnColors.
function LT:ColorRollBars(group)
	if group ~= 'accent' then return end
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
			SetBarTimer(bar, HeldLeft(bar))
		end
		self:LayoutRollFrames()
		self:UpdateRollPreviews()
	end)
end
