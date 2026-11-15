local st = SaftUI

local LT = st:GetModule('Loot')

-- SaftUI's own roll bars: built here, used by roll.lua (the held rolls) and
-- rolltest.lua (the previews), which take what they use from `LT.rollbar`.

-- `atlas` is the art Blizzard's roll button for the choice draws (its
-- NormalTexture in GroupLootFrame.xml, the same on Forever and retail), which
-- SaftUI's own bars draw too.
local roll_buttons = {
	{name = 'Pass', icon_text = 'P', color = 'pass', atlas = 'lootroll-toast-icon-pass-up'},
	{name = 'Greed', icon_text = 'G', color = 'greed', atlas = 'lootroll-toast-icon-greed-up'},
	{name = 'Transmog', icon_text = 'DE', color = 'transmog', atlas = 'lootroll-toast-icon-transmog-up'},
	{name = 'Need', icon_text = 'N', color = 'need', atlas = 'lootroll-toast-icon-need-up'},
}

------------------------------------
---- SaftUI's own roll bars --------
------------------------------------
-- Copies of a skinned roll bar, SaftUI's own frames: Test mode's previews and
-- the held rolls (roll.lua). Each has the same size, theme, font, spacing, icon,
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
	-- In BORDER, under the ring the Blizzard theme draws over it (a texture of
	-- the frame, in ARTWORK).
	bar.Icon = bar.IconFrame:CreateTexture(nil, 'BORDER')
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
	local font = st:FontObject(LT.config.roll.font)
	bar.Timer.Text = bar.Timer:CreateFontString(nil, 'OVERLAY')
	bar.Timer.Text:SetFontObject(font)
	bar.Name = bar.Timer:CreateFontString(nil, 'OVERLAY')
	bar.Name:SetFontObject(font)
	bar.Name:SetJustifyH('LEFT')
	bar.Name:SetWordWrap(false)
	bar.Name:SetVertexColor(1, 1, 1)
	bar.Choice = bar.Timer:CreateFontString(nil, 'OVERLAY')
	st:ApplyFont(bar.Choice, 'pixel')
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

-- The lit border of a locked bar's chosen button: the accent on its icon's
-- backdrop. Kept through a theme recolor or redraw (st:KeepOwnColors).
local function ColorLit(icon)
	if icon.backdrop then
		st:SetBorderColor(icon.backdrop, st:Color('accent'):GetRGB())
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

-- A locked bar's lit border and label in the current accent.
local function ColorLocked(bar)
	for _, button in ipairs(bar.buttons) do
		if button.choice == bar.choice then ColorLit(button.Icon) end
	end
	bar.Choice:SetTextColor(st:Color('accent'):GetRGB())
end

-- The same sizing as UpdateRollFrame, from the live roll config. A locked bar's
-- chosen button gets a border, lit, on its edges with its art inside; every
-- other button has none, as on Blizzard's bar.
local function ApplyBarConfig(bar, config)
	local font = st:FontObject(config.font)

	bar:SetSize(config.width, config.height)
	bar.IconFrame:SetSize(config.height, config.height)
	st:SetBackdrop(bar.IconFrame, config.theme, config.background, 'slot')
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
		local inset = lit and st:ThemeInset(config.theme, config.background, 'small') or 0
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
	st:ApplyFont(bar.Choice, 'pixel')
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
-- The timer's bar in the accent (the pass calls this on an Accent change).
local function ColorBarTimer(bar)
	bar.Timer:SetStatusBarColor(st:Color('accent'):GetRGB())
end

local function SetBarTimer(bar, sec)
	bar.Timer:SetValue(sec)
	ColorBarTimer(bar)

	local whole = floor(sec)
	if bar.shownSecond ~= whole then
		bar.shownSecond = whole
		bar.Timer.Text:SetText(st.StringFormat:ToClock(sec))
	end

	if sec < 60 then
		bar.Timer.Text:SetVertexColor(st:Color('text', 'danger'):GetRGB())
	else
		bar.Timer.Text:SetVertexColor(st:Color('text', 'strong'):GetRGB())
	end
end

-- Held bars and the previews stand where Blizzard's roll frames do, so they
-- draw at their strata (GroupLootFrame.xml: DIALOG).
local ROLL_STRATA = 'DIALOG'

LT.rollbar = {
	buttons = roll_buttons,
	strata = ROLL_STRATA,
	CreateBar = CreateBar,
	SetBarTransmog = SetBarTransmog,
	LockBar = LockBar,
	ColorLocked = ColorLocked,
	ApplyBarConfig = ApplyBarConfig,
	SetBarTimer = SetBarTimer,
	ColorBarTimer = ColorBarTimer,
}
