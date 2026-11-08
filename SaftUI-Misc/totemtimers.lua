local st = SaftUI
local TB = st:GetModule('TotemBar')

--[[
	How long each totem has left, above its element button on WoW Forever's totem bar
	(totembar.lua says what the bar is, totemskin.lua how it's skinned). While an element
	has a totem down, its button gets a status bar draining as the time runs out, in the
	element's colour, and a countdown: m:ss from a minute up, whole seconds below, rounded
	up as Blizzard's totem timers are. Both turn the warning colour (the profile's red
	text colour) in the last 10 seconds. Each can be turned off, and with both on the text
	sits above the bar or on it (timer_bar, timer_text, timer_text_position). The bar is
	timer_bar_height tall, and with the text on it never shorter than the text needs.

	One timer per slot button (MultiCastSlotButton1-4), made as its child, so it hides
	with the bar (including under "Hide totem bar"'s hidden parent) and with a slot button
	Blizzard hides for an element that isn't learned. The element is the slot button's
	GetID(), read on every update: MultiCastSlotButton_Update gives each button its slot,
	and the bar re-orders the elements when one is learned.

	Where the time comes from:
	  - The bar: GetTotemDuration(slot), a duration object, handed to the bar's
	    SetTimerDuration, which then drains on its own. It works whether or not the
	    totem's values are secret, with no math in Lua. It's nil for a slot with no
	    totem, which is also how a timer knows to hide in combat (GetTotemInfo is
	    secret there).
	  - The text and the warning colour: plain math on GetTotemInfo's start time and
	    duration while they aren't secret. GetTotemInfo is documented secret while its
	    totem slot is, and secret values can't be compared or added. Then the duration
	    object does it: FormatRemainingDuration with a formatter set up for m:ss, the
	    colours from colour curves evaluated on the time left, and the timer is shown by
	    alpha from the duration's IsActive, as there's nothing to test in Lua. So on
	    that path a timer for an element with no totem down is only see-through, and
	    its 0.1s OnUpdate keeps running.
	GetTotemInfo's first value can be true with no totem down (Blizzard's bar shows a slot
	button wherever it's true), so a totem counts as down while its duration runs.

	PLAYER_TOTEM_UPDATE comes when a totem is dropped, replaced, destroyed, recalled or
	runs out, and refreshes the timer of the slot it names: a new totem restarts its
	timer at its own duration, and a timer with no totem left hides at once. Other
	timers keep the times they read, so one started out of combat stays on its plain
	times through a fight. While a timer shows, a
	throttled OnUpdate (about 0.1s) updates its text and colours. It doesn't run while the
	timer is hidden.

	Blizzard's flyout open arrow appears right above a hovered button, and the flyout
	opens up from the button's top: where the timers are. Blizzard hides the arrow as soon
	as the mouse is over neither the arrow nor its button (MultiCastFlyoutFrameOpenButton_Hide,
	from the buttons' OnLeave; the arrow also hides on its own OnLeave), so moving them up
	past a gap would make the arrow impossible to reach. They grow instead, by the height
	the timers take (TB:GetTimerAreaHeight, set by the settings, not by whether a totem is
	down):
	  - MultiCastFlyoutFrameOpenButton_Show anchors the arrow's BOTTOM to the button's
	    TOP. Afterwards the arrow is made taller, so it still starts at the button and
	    the mouse never leaves it on the way up, and as wide as the button. Its art is at
	    its top (totemskin.lua).
	  - MultiCastFlyoutFrame_ToggleFlyout loads the choices (they set the flyout's height)
	    and anchors the flyout's BOTTOM to the button's TOP. Afterwards the flyout is made
	    taller than Blizzard made it, and its first choice, which the column chains off,
	    is moved up as much. The panel behind the column and the close arrow follow.
	The space over the timers becomes part of the arrow's and the flyout's hover and click
	area. That's fine: the timers take no mouse (EnableMouse(false)), so they never get in
	the way of Blizzard's mouse-over checks either. Only element buttons grow theirs: the
	summon button has no timer under its arrow.

	All of this works in combat. The timers are SaftUI's frames. They're children of the
	slot buttons and anchored to them. The slot buttons are plain CheckButtons, protected
	only through an anchor: the secure recall button is anchored to the last shown one,
	and they chain from there. A protected frame's restrictions spread to its parents and
	to the frames it's anchored to, not to its children or to frames anchored to it. The
	arrow, the flyout and its choices aren't protected: no secure template, no secure
	children, nothing secure anchored to them. Only making the timers waits for the end of
	combat (a /reload in combat, TB:SetupSkinAndTimers). The slot buttons are never moved,
	sized, shown or hidden here, and nothing is written onto Blizzard's frames: SaftUI's
	pieces are in the timers table below, keyed by slot button.
]]

-- The gap between the button's top and the timer.
local TIMER_GAP = 3

-- The gap between the bar and the text above it.
local TEXT_GAP = 2

-- The text's height when the profile's button font can't be read.
local DEFAULT_TEXT_HEIGHT = 10

-- The time left from which the bar and text turn the warning colour.
local WARNING_SECONDS = 10

-- How often a shown timer updates its text and colours, in seconds.
local UPDATE_INTERVAL = 0.1

-- Blizzard's sizes, kept to grow from: the open arrow's height in its XML (Blizzard never
-- resizes it), and how far above the flyout's bottom its first choice sits
-- (MULTI_CAST_FLYOUT_BUTTON_INITIAL_OFFSET, a local in MultiCastActionBarFrame.lua).
local ARROW_HEIGHT = 18
local FIRST_CHOICE_OFFSET = 4

-- Slot button -> its timer: { frame, backdrop, bar, text, slot, endTime, duration, ... }.
-- Kept here, so nothing is written onto Blizzard's frames.
local timers = setmetatable({}, { __mode = 'k' })

-- True once TB:SetupTimers has run, with the hooks in place.
local timersReady = false

-- The flyout's height on its last opening, before it was grown: Blizzard's, corrected for
-- the choices' size (totemskin.lua's SizeChoices, which runs before).
local flyoutBaseHeight

------------------------------------
--- Helpers -------------------------
------------------------------------

-- totemskin.lua's helpers (it loads first): a template's inner border, and
-- hooksecurefunc on a Blizzard global if this client has it.
local TemplateInset, PostHook = TB.TemplateInset, TB.PostHook

-- The text's font: the profile's button font, else SaftUI's pixel font, else one of
-- Blizzard's, so the text always has one (SetText errors without). Also its name, when
-- it's one of SaftUI's fonts.
local function TimerFont()
	local name = st.config.profile.buttons.font
	local font = st:GetFont(name)
	if font then return font, name end
	font = st:GetFont('pixel')
	if font then return font, 'pixel' end
	return NumberFontNormalSmall
end

-- The text's height in its font.
local function TextHeight()
	local font = TimerFont()
	local size = font and select(2, font:GetFont())
	return math.ceil(size or DEFAULT_TEXT_HEIGHT)
end

-- The bar's height with its border: the setting, but always with MIN_FILL of bar inside
-- the template's border (2-4px with 2px of border each side would show none), and with
-- the text on it (onBar) never less than the text inside the border. With the default
-- pixel font (10) and thick template (2 each side) that's 14.
local MIN_FILL = 2
local function BarHeight(onBar)
	local border = 2 * TemplateInset(st.config.profile.buttons.template)
	local height = math.max(TB.config.timer_bar_height, border + MIN_FILL)
	if onBar then
		height = math.max(height, TextHeight() + border)
	end
	return height
end

-- A slot's element colour, or the text colour for a slot without one.
local function ElementColor(slot)
	local r, g, b = TB:GetElementColor(slot)
	if r then return r, g, b end
	return st.config.profile.colors.text.normal:GetRGB()
end

-- Whole seconds rounded up, as m:ss from a minute up and plain seconds below.
local function FormatSeconds(seconds)
	if seconds >= 60 then
		return ('%d:%02d'):format(math.floor(seconds / 60), seconds % 60)
	end
	return tostring(seconds)
end

------------------------------------
--- Secret values -------------------
------------------------------------

-- The text's formatter while a totem's values are secret, made the first time one is:
-- nil until then, false if none could be made.
local formatter

-- Times left the m:ss formatter has to get right, the way FormatSeconds does.
local FORMAT_CHECKS = {
	{ 44.2, '45' },
	{ 59.5, '1:00' },
	{ 64.5, '1:05' },
	{ 251.3, '4:12' },
}

-- A formatter for FormatSeconds' m:ss: the time left rounded up to whole seconds, as
-- seconds below a minute and minutes:seconds from there. Anything over 59 rounds up to at
-- least 60, so the minutes rule starts just above 59. Checked against FORMAT_CHECKS
-- before it's used, as nothing of Blizzard's uses one of these yet: nil if it's wrong.
local function CreateClockFormatter()
	local rounding = Enum.NumericRuleFormatRounding
	local clock = C_StringUtil.CreateNumericRuleFormatter()
	clock:SetBreakpoints({
		{ threshold = 0, step = 1, rounding = rounding.Up, format = '%d' },
		{
			threshold = 59 + 1e-6, step = 1, rounding = rounding.Up, format = '%d:%02d',
			components = {
				{ div = 60, step = 1, rounding = rounding.Down },
				{ mod = 60, step = 1, rounding = rounding.Down },
			},
		},
	})

	local probe = C_DurationUtil.CreateDuration()
	local now = GetTime()
	for _, check in ipairs(FORMAT_CHECKS) do
		probe:SetTimeFromEnd(now + check[1], check[1])
		if probe:FormatRemainingDuration(clock) ~= check[2] then return end
	end
	return clock
end

-- Blizzard's seconds formatter, the closest it has to m:ss ("4m 12s"), if the m:ss one
-- doesn't work.
local function CreateSecondsFormatter()
	local seconds = C_StringUtil.CreateSecondsFormatter()
	seconds:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
	seconds:SetRounding(Enum.SecondsFormatterRounding.RoundUp)
	seconds:SetDesiredUnitCount(2)
	return seconds
end

local function Formatter()
	if formatter == nil then
		local ok, clock = pcall(CreateClockFormatter)
		if ok and clock then
			formatter = clock
		else
			local made, seconds = pcall(CreateSecondsFormatter)
			formatter = made and seconds or false
		end
	end
	return formatter
end

-- A colour curve on the time left: the warning colour up to WARNING_SECONDS, then
-- r, g, b. A step curve's point holds from its own x, so the second point sits just above
-- WARNING_SECONDS to keep 10 itself in the warning colour, as the plain math does.
local function WarningCurve(r, g, b)
	local curve = C_CurveUtil.CreateColorCurve()
	curve:SetType(Enum.LuaCurveType.Step)
	curve:AddPoint(0, st.config.profile.colors.text.red)
	curve:AddPoint(WARNING_SECONDS + 0.001, CreateColor(r, g, b))
	return curve
end

-- The text's curve, and each timer's bar curve for its element. Made when first needed,
-- and again after the settings or the profile change.
local textCurve

local function TextCurve()
	textCurve = textCurve or WarningCurve(st.config.profile.colors.text.normal:GetRGB())
	return textCurve
end

local function BarCurve(timer)
	if not timer.barCurve or timer.curveSlot ~= timer.slot then
		timer.barCurve = WarningCurve(ElementColor(timer.slot))
		timer.curveSlot = timer.slot
	end
	return timer.barCurve
end

-- True once the duration object's text and colours failed: from then on a totem with
-- secret values gets no timer, rather than an error on every update.
local secretFailed = false

-- Centres the time on the visible characters. The pixel font draws a 1px gap after
-- every character, the last one too, so centring the text's box would put the
-- characters half a pixel left, and snapping to whole pixels can make that a whole
-- pixel. So the box's left edge goes on a whole pixel, worked out from the width
-- without that gap. A secret text width (the secret path) falls back to plain centring.
local function PlaceText(timer)
	local text, ref, place = timer.text, timer.textRef, timer.textPlace
	if not (ref and place) then return end
	text:ClearAllPoints()

	-- The Text X / Y offset settings, in whole pixels, on top of the centring.
	local offsetX = st:RoundToPixel(TB.config.timer_text_x or 0, text)
	local offsetY = st:RoundToPixel(TB.config.timer_text_y or 0, text)

	local width, textWidth = ref:GetWidth(), text:GetStringWidth()
	local pixel = st:GetPixelSize(text)
	if pixel and not issecretvalue(width) and not issecretvalue(textWidth) and textWidth > 0 then
		local boxPixels = math.floor(width / pixel + 0.5)
		local letterPixels = math.floor(textWidth / pixel + 0.5) - 1
		local x = math.floor((boxPixels - letterPixels) / 2) * pixel
		text:SetPoint(place.point .. 'LEFT', ref, place.relPoint .. 'LEFT', x + offsetX, place.y + offsetY)
	else
		text:SetPoint(place.point == '' and 'CENTER' or place.point, ref,
			place.relPoint == '' and 'CENTER' or place.relPoint, offsetX, place.y + offsetY)
	end
end

-- Text, colours and visibility from the duration object, for secret values. Nothing is
-- compared or tested: each value goes into a widget setter, which takes secret values,
-- and a colour curve's result only gives its fields back through GetRGB.
-- SetAlphaFromBoolean's own defaults are opaque for true and clear for false.
local function RefreshSecret(timer)
	local duration = timer.duration
	timer.frame:SetAlphaFromBoolean(duration:IsActive())
	local textFormatter = Formatter()
	if textFormatter then
		timer.text:SetText(duration:FormatRemainingDuration(textFormatter))
		PlaceText(timer)
	else
		timer.text:SetText('')
	end
	timer.text:SetTextColor(duration:EvaluateRemainingDuration(TextCurve()):GetRGB())
	timer.bar:SetStatusBarColor(duration:EvaluateRemainingDuration(BarCurve(timer)):GetRGB())
end

------------------------------------
--- Timers --------------------------
------------------------------------

-- The bar and text in the warning colour, or the bar in its element's colour and the
-- text in the text colour.
local function ColorTimer(timer, warning)
	local colors = st.config.profile.colors.text
	if warning then
		timer.text:SetTextColor(colors.red:GetRGB())
		timer.bar:SetStatusBarColor(colors.red:GetRGB())
	else
		timer.text:SetTextColor(colors.normal:GetRGB())
		timer.bar:SetStatusBarColor(ElementColor(timer.slot))
	end
end

-- Text and colours from the plain end time. Only touches them when they change.
local function RefreshPlain(timer)
	local remaining = timer.endTime - GetTime()
	if remaining <= 0 then
		timer.frame:Hide()
		return
	end

	local warning = remaining <= WARNING_SECONDS
	if warning ~= timer.warning then
		timer.warning = warning
		ColorTimer(timer, warning)
	end

	local seconds = math.ceil(remaining)
	if seconds ~= timer.seconds then
		timer.seconds = seconds
		timer.text:SetText(FormatSeconds(seconds))
		PlaceText(timer)
	end
end

local function Refresh(timer)
	if not timer.secret then
		RefreshPlain(timer)
	elseif not secretFailed then
		local ok, err = pcall(RefreshSecret, timer)
		if not ok then
			secretFailed = true
			for _, other in pairs(timers) do
				if other.secret then other.frame:Hide() end
			end
			st:Debug('TotemBar', 'Totem timers stopped for secret values:', err)
		end
	end
end

-- Shows a slot button's timer for the totem in the slot it holds now, or hides it.
local function UpdateTimer(button)
	local timer = timers[button]
	if not timer then return end
	local frame = timer.frame
	local config = TB.config
	local slot = button:GetID()
	if not (config.timer_bar or config.timer_text) or slot < 1 or slot > (NUM_MULTI_CAST_BUTTONS_PER_PAGE or 4) then
		frame:Hide()
		return
	end

	-- No duration object means no totem in the slot. In combat that's the only way to
	-- tell: GetTotemInfo's values are secret there, so haveTotem can't be tested (oUF's
	-- totems element checks the same way).
	local durationObject = GetTotemDuration(slot)
	if not durationObject then
		frame:Hide()
		return
	end

	local haveTotem, _, startTime, duration = GetTotemInfo(slot)
	local secret = issecretvalue(haveTotem) or issecretvalue(startTime) or issecretvalue(duration)
	if secret then
		if secretFailed then
			frame:Hide()
			return
		end
		timer.endTime = nil
	elseif haveTotem and duration and duration > 0 and startTime + duration > GetTime() then
		timer.endTime = startTime + duration
		frame:SetAlpha(1)
	else
		frame:Hide()
		return
	end

	timer.slot = slot
	timer.secret = secret
	timer.warning, timer.seconds = nil, nil
	timer.duration = durationObject
	timer.bar:SetTimerDuration(timer.duration, Enum.StatusBarInterpolation.Immediate, Enum.StatusBarTimerDirection.RemainingTime)
	timer.elapsed = 0
	frame:Show()
	Refresh(timer)
end

-- One slot button's timer: a frame the width of the button, above it, holding the bar
-- (in a backdrop of the profile's button template) and the text, on a frame over the bar
-- so text written on it isn't covered. Hidden until a totem is down. None of it takes the
-- mouse.
local function CreateTimer(button)
	local frame = CreateFrame('Frame', nil, button)
	frame:EnableMouse(false)
	frame:SetPoint('BOTTOMLEFT', button, 'TOPLEFT', 0, TIMER_GAP)
	frame:SetPoint('BOTTOMRIGHT', button, 'TOPRIGHT', 0, TIMER_GAP)
	frame:Hide()

	local backdrop = st:CreateFrame('Frame', nil, frame)
	backdrop:EnableMouse(false)
	backdrop:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, 0)
	backdrop:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 0, 0)

	local bar = CreateFrame('StatusBar', nil, backdrop)
	bar:EnableMouse(false)
	bar:SetStatusBarTexture(st.BLANK_TEX)

	local cover = CreateFrame('Frame', nil, frame)
	cover:EnableMouse(false)
	cover:SetAllPoints(frame)
	cover:SetFrameLevel(bar:GetFrameLevel() + 1)

	local text = cover:CreateFontString(nil, 'OVERLAY')
	text:SetFontObject((TimerFont()))

	local timer = {
		frame = frame,
		backdrop = backdrop,
		bar = bar,
		text = text,
		elapsed = 0,
	}
	timers[button] = timer

	frame:SetScript('OnUpdate', function(_, elapsed)
		timer.elapsed = timer.elapsed + elapsed
		if timer.elapsed >= UPDATE_INTERVAL then
			timer.elapsed = 0
			Refresh(timer)
		end
	end)
end

------------------------------------
--- Flyout and arrow ----------------
------------------------------------

-- How much taller the open arrow and the flyout are on a button: the timers' height on an
-- element button ('slot'), none on the summon button ('page') or when they're closed.
local function Growth(kind)
	return kind == 'slot' and TB:GetTimerAreaHeight() or 0
end

-- After MultiCastFlyoutFrameOpenButton_Show: the arrow as tall as Blizzard's plus the
-- timers, for the button Blizzard just put it on (its type, which it clears on hiding),
-- and as wide as the bar's buttons rather than Blizzard's 28. Blizzard centres it over the
-- button, so it then covers the button's whole top edge, and the mouse can go up from
-- anywhere on the button without leaving both (MultiCastFlyoutFrameOpenButton_Hide).
local function GrowArrow()
	local arrow = MultiCastFlyoutFrameOpenButton
	if arrow then
		arrow:SetSize(TB.config.button_size, ARROW_HEIGHT + Growth(arrow.type))
	end
end

-- The open flyout taller than Blizzard made it by the timers' height, and its column of
-- choices moved up as much. Blizzard anchors the first choice once, when it makes it, so
-- this puts it back where Blizzard has it when there's nothing to grow, or no height of
-- Blizzard's to grow from (one that's secret, or a flyout opened before the timers were
-- made).
local function GrowFlyout()
	local flyout = MultiCastFlyoutFrame
	if not (flyout and flyout:IsShown()) then return end
	local grow = 0
	if flyoutBaseHeight then
		grow = Growth(flyout.type)
		flyout:SetHeight(flyoutBaseHeight + grow)
	end
	local first = flyout.buttons and flyout.buttons[1]
	if first then
		first:SetPoint('BOTTOM', flyout, 'BOTTOM', 0, FIRST_CHOICE_OFFSET + grow)
	end
end

-- After MultiCastFlyoutFrame_ToggleFlyout. Only when that call opened the flyout on
-- parent: the choices loaded, so the height is the one Blizzard just set. A call that
-- closed it, or found no choices for parent, changed nothing to grow.
local function OnToggleFlyout(flyout, _, parent)
	if not (flyout:IsShown() and flyout.parent == parent) then return end
	local height = flyout:GetHeight()
	flyoutBaseHeight = not issecretvalue(height) and height or nil
	GrowFlyout()
end

------------------------------------
--- Module --------------------------
------------------------------------

-- The height the timers take above an element button with the current settings, gap
-- included: 0 with both the bar and the text off. It doesn't change with whether a
-- totem is down, so the arrow and the flyout don't move as totems come and go.
function TB:GetTimerAreaHeight()
	local config = self.config
	local showBar, showText = config.timer_bar, config.timer_text
	if not (showBar or showText) then return 0 end
	-- Text moved up by its Y offset needs that much more room under the arrow.
	local raised = showText and math.max(0, config.timer_text_y or 0) or 0
	if showBar and showText and config.timer_text_position == 'on' then
		return TIMER_GAP + BarHeight(true) + raised
	end

	local height = TIMER_GAP
	if showBar then
		height = height + BarHeight(false)
	end
	if showText then
		height = height + (showBar and TEXT_GAP or 0) + TextHeight()
	end
	return height + raised
end

-- Refreshes the timers from their slot buttons' totems: on PLAYER_TOTEM_UPDATE only the
-- slot it names, otherwise all of them. Leaving the other slots alone keeps a timer
-- that started out of combat on its plain times, rather than re-reading them as secret
-- once combat has started.
function TB:UpdateTimers(event, totemSlot)
	local onlySlot = event == 'PLAYER_TOTEM_UPDATE' and not issecretvalue(totemSlot)
		and type(totemSlot) == 'number' and totemSlot or nil
	for button in pairs(timers) do
		if not onlySlot or button:GetID() == onlySlot then
			UpdateTimer(button)
		end
	end
end

-- Lays the timers out from the profile: whether the bar and the text show, where the text
-- sits, the bar's height, template and colours, the font, and how much the arrow and the
-- flyout grow. Only SaftUI's frames and the unprotected arrow and flyout are touched, so
-- it applies in combat too.
function TB:ApplyTimerLayout()
	if not timersReady then return end

	local config = self.config
	local showBar, showText = config.timer_bar, config.timer_text
	local onBar = showBar and showText and config.timer_text_position == 'on'
	local template = st.config.profile.buttons.template
	local inset = TemplateInset(template)
	local font = TimerFont()
	local height = math.max(1, self:GetTimerAreaHeight() - TIMER_GAP)
	local barHeight = BarHeight(onBar)

	-- The colours may have changed.
	textCurve = nil

	for _, timer in pairs(timers) do
		timer.barCurve = nil
		timer.frame:SetHeight(height)

		local backdrop, bar, text = timer.backdrop, timer.bar, timer.text
		st:SetTemplate(backdrop, template)
		backdrop:SetHeight(barHeight)
		backdrop:SetShown(showBar)
		st:SetInside(bar, inset)

		text:SetFontObject(font)
		-- Where the time sits; PlaceText centres it there on whole pixels. The point
		-- names are the vertical half of the anchor ('' for the middle).
		if onBar then
			timer.textRef, timer.textPlace = bar, { point = '', relPoint = '', y = 0 }
		elseif showBar then
			timer.textRef, timer.textPlace = backdrop, { point = 'BOTTOM', relPoint = 'TOP', y = TEXT_GAP }
		else
			timer.textRef, timer.textPlace = timer.frame, { point = 'BOTTOM', relPoint = 'BOTTOM', y = 0 }
		end
		PlaceText(timer)
		text:SetShown(showText)
	end

	self:UpdateTimers()
	GrowArrow()
	GrowFlyout()
end

-- Makes the timers and hooks Blizzard's updates (see the top of this file). Once, from
-- TB:SetupSkinAndTimers, in combat too: the timers are SaftUI's own frames, children of
-- the slot buttons, and nothing here moves or resizes a protected frame. These hooks
-- touch nothing the skin's hooks do, so it doesn't matter which run first.
function TB:SetupTimers()
	if timersReady then return end
	timersReady = true

	for i = 1, NUM_MULTI_CAST_BUTTONS_PER_PAGE or 4 do
		local button = _G['MultiCastSlotButton' .. i]
		if button then CreateTimer(button) end
	end

	self:RegisterEvent('PLAYER_TOTEM_UPDATE', 'UpdateTimers')
	self:RegisterEvent('PLAYER_ENTERING_WORLD', 'UpdateTimers')

	-- A slot button's element changes here (its ID), when the bar updates.
	PostHook('MultiCastSlotButton_Update', UpdateTimer)
	PostHook('MultiCastFlyoutFrameOpenButton_Show', GrowArrow)
	PostHook('MultiCastFlyoutFrame_ToggleFlyout', OnToggleFlyout)

	-- A size change to the timers' font in /sui -> Fonts changes their height, and so how
	-- far the arrow and the flyout grow. SaftUI's own Fonts module, so a plain post-hook.
	-- With no font name it updates every font, calling itself for each one.
	local fonts = st:GetModule('Fonts', true)
	if fonts and type(fonts.UpdateFontConfig) == 'function' then
		hooksecurefunc(fonts, 'UpdateFontConfig', function(_, fontName)
			if fontName and fontName == select(2, TimerFont()) then
				self:ApplyTimerLayout()
			end
		end)
	end

	self:ApplyTimerLayout()
end
