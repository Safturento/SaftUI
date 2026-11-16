local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The Keep prompt and /sui scale (st.UIScalePrompt). A UI size is tried
	first (st.UIScale:Preview) and then kept (Apply) or given up (Revert):
	"Keep this UI size?", counting down from 15 s, with Keep and Go back.
	Go back, Esc and the countdown's end go back; only Keep keeps (Enter
	does nothing). It loads after general.lua, and the /sui window's rows
	(Task 7) and /sui scale ask through KP:Ask.

	It is a frame of Core's of its own, not the kit's confirm dialog: that one
	is modal, answers No to a click outside, closes with /sui and needs
	SetPropagateKeyboardInput, which is protected in combat. This one:
	  - is the way back from any size, so it ignores its parent's scale and is
	    drawn at the automatic size of this screen at 100%, whatever is
	    previewed (the tiny or the huge UI never makes it tiny or huge);
	  - sits at FULLSCREEN_DIALOG, level KP.LEVEL, over /sui and edit mode;
	  - has no click catcher: a click outside it reaches what is under it, and
	    it stays when /sui closes;
	  - takes Esc only, out of combat (every other key goes on to the game).
	    In combat it takes no key: its keyboard is off, and
	    SetPropagateKeyboardInput is never called;
	  - has the kit's W.Button for Keep and Go back, as the kit draws it.

	If combat starts while it shows, it stays. If its time ends in combat,
	the revert waits for the end of it (UIScale:Revert queues the check): the
	line reads "Goes back when combat ends.", the buttons hide, and it hides
	once the revert has applied (UIScale:OnChanged, and the end of combat
	for a revert that changes nothing).
]]

local KP = {}
st.UIScalePrompt = KP

KP.SECONDS = 15
KP.LEVEL = 9900 -- FULLSCREEN_DIALOG: over /sui, the edit mode bar (9500), the label (9600) and the History list (9700)

KP.KEEP_DELAY = 0.5 -- seconds after it shows that Keep takes no click (the second click of a double-click)
KP.TITLE = 'Keep this UI size?'
KP.COMBAT_LINE = 'Goes back when combat ends.'
KP.MODE_NAMES = { auto = 'Automatic', pixel = 'Pixel for pixel', game = "The game's UI scale" }

local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min

local WIDTH = 320
local TOP, GAP, BOTTOM, BUTTON_GAP = 16, 6, 14, 12

local ui -- { frame, title, line, keep, back }, built on the first ask
local ticker, deadline
local waiting -- going back after combat: the buttons are hidden
local shows = 0 -- counts the asks, so an old Keep delay never enables a newer ask's button

local function CountdownText(seconds)
	return ('Going back in %d s.'):format(seconds)
end

local function Percent(size)
	return floor(size * 100 + 0.5)
end

------------------------------------------------------------------ the frame

-- The frame's height: the title, the line and the buttons, as the kit's
-- confirm dialog stacks its text and buttons.
local function Height()
	local lineHeight = floor(Kit.FIELD_FONT_SIZE * 1.3)
	return TOP + lineHeight + GAP + lineHeight + TOP + 26 + BOTTOM
end

-- The frame at the automatic size of this screen at 100%, drawn in the theme
-- on the options Background and centred on the screen, its size and its
-- corner on whole pixels of its own scale (W.PlaceCentred places by units,
-- which are pixels only at 1 pixel to the unit).
local function Fit()
	local frame = ui.frame
	local default = st.UIScale:Default()
	if default then frame:SetScale(default.uiScale) end
	local width, height = st:RoundToPixel(WIDTH, frame), st:RoundToPixel(Height(), frame)
	frame:SetSize(width, height)
	st:SetTemplate(frame, 'theme', 'options', 'panel')
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', UIParent, 'CENTER', -st:RoundToPixel(width / 2, frame), st:RoundToPixel(height / 2, frame))
	-- Each time it shows (and after a change while it is up) the muted line takes
	-- the color now, and the buttons the look now: a later color or theme change
	-- reaches the next prompt.
	ui.line:SetTextColor(st:Color('text', 'muted'):GetRGB())
	local blizzard = W.BlizzardLook()
	W.LookControl(ui.keep, blizzard)
	W.LookControl(ui.back, blizzard)
end

local function StopTicker()
	if ticker then
		ticker:Cancel()
		ticker = nil
	end
end

local function Hide()
	StopTicker()
	waiting = false
	if ui then ui.frame:Hide() end
end

local function SetKeys()
	local frame = ui.frame
	frame:EnableKeyboard(frame:IsShown() and not waiting and not InCombatLockdown())
end

-- Going back after combat: the line says so, the buttons go, and it hides
-- once the revert has applied.
local function Wait()
	StopTicker()
	waiting = true
	ui.line:SetText(KP.COMBAT_LINE)
	ui.keep:Hide()
	ui.back:Hide()
	SetKeys()
end

local function Tick()
	if not (ui and ui.frame:IsShown()) or waiting then return end
	if not st.UIScale:IsPreviewing() then
		-- Something else ended the preview (a save, a reset): nothing to ask.
		Hide()
		return
	end
	local left = ceil(deadline - GetTime() - 1e-9)
	if left <= 0 then
		KP:GoBack()
		return
	end
	ui.line:SetText(CountdownText(left))
end

local function Build()
	local frame = st:CreateFrame('Frame', nil, UIParent)
	frame:SetFrameStrata('FULLSCREEN_DIALOG')
	frame:SetFrameLevel(KP.LEVEL)
	frame:SetIgnoreParentScale(true)
	frame:SetWidth(WIDTH)
	frame:EnableMouse(true) -- clicks on it stop at it; clicks beside it go through
	frame:Hide()

	local title = Kit.NewText(frame, 'CENTER')
	title:SetText(KP.TITLE)
	title:SetPoint('TOP', frame, 'TOP', 0, -TOP)
	local line = Kit.NewText(frame, 'CENTER')
	line:SetTextColor(st:Color('text', 'muted'):GetRGB())
	line:SetPoint('TOP', title, 'BOTTOM', 0, -GAP)

	local keep = W.Button(frame, 'Keep', function() KP:Keep() end)
	keep:SetPoint('BOTTOMRIGHT', frame, 'BOTTOM', -(BUTTON_GAP / 2), BOTTOM)
	local back = W.Button(frame, 'Go back', function() KP:GoBack() end)
	back:SetPoint('BOTTOMLEFT', frame, 'BOTTOM', BUTTON_GAP / 2, BOTTOM)

	-- Esc goes back and every other key goes on to the game. Out of combat only:
	-- SetPropagateKeyboardInput is protected in combat, where the keyboard is off.
	frame:SetScript('OnKeyDown', function(self, key)
		if InCombatLockdown() then return end
		self:SetPropagateKeyboardInput(key ~= 'ESCAPE')
		if key == 'ESCAPE' and not waiting then KP:GoBack() end
	end)
	frame:SetScript('OnShow', SetKeys)
	frame:SetScript('OnHide', function(self) self:EnableKeyboard(false) end)

	frame:RegisterEvent('PLAYER_REGEN_DISABLED')
	frame:RegisterEvent('PLAYER_REGEN_ENABLED')
	frame:SetScript('OnEvent', function(_, event)
		if not ui.frame:IsShown() then return end
		SetKeys()
		if event == 'PLAYER_REGEN_ENABLED' and waiting then
			-- The queued revert runs on this event; the frame after it, the prompt
			-- has nothing left to wait for, even when the revert changed nothing.
			C_Timer.After(0, function()
				if waiting and not InCombatLockdown() then Hide() end
			end)
		end
	end)

	ui = { frame = frame, title = title, line = line, keep = keep, back = back }
end

-- The scale changed (a revert that waited, the engine, a display change):
-- while the prompt waits for its revert, that was it; otherwise it is drawn
-- again at the automatic size of the screen as it is now.
st.UIScale:OnChanged(function()
	if not (ui and ui.frame:IsShown()) then return end
	if waiting and not InCombatLockdown() then
		Hide()
	else
		Fit()
	end
end)

------------------------------------------------------------------ the prompt

-- Tries choice and asks about it: ok, or false and why (UIScale:Preview's: 'combat',
-- 'mode', 'size', 'screen'). A prompt that is up starts again for the new choice,
-- going back to the choice saved before the first.
function KP:Ask(choice)
	local ok, why = st.UIScale:Preview(choice)
	if not ok then return false, why end
	if not ui then Build() end
	waiting = false
	StopTicker()
	deadline = GetTime() + KP.SECONDS
	ui.title:SetText(KP.TITLE)
	ui.line:SetText(CountdownText(KP.SECONDS))
	ui.keep:Show()
	ui.back:Show()
	-- Keep looks disabled (the kit's) and takes no click for KEEP_DELAY, so the
	-- second click of a double-click on what asked cannot keep. Go back and Esc
	-- work at once.
	shows = shows + 1
	local mine = shows
	W.SetEnabled(ui.keep, false)
	C_Timer.After(KP.KEEP_DELAY, function()
		if mine == shows and ui then W.SetEnabled(ui.keep, true) end
	end)
	Fit()
	ui.frame:Show()
	SetKeys()
	ticker = C_Timer.NewTicker(1, Tick)
	return true
end

-- Saves the choice being tried and closes. A choice the screen no longer
-- holds (a display change while it was up) goes back instead, and says so.
function KP:Keep()
	local ok = st.UIScale:Apply(st.UIScale:Current())
	Hide()
	if not ok then
		st.UIScale:Revert()
		st:Print("That UI size doesn't fit this screen any more, so it went back.")
	end
end

-- Goes back to the saved choice and closes; in combat the revert waits for the end of it.
function KP:GoBack()
	if not ui then return end
	local combat = InCombatLockdown()
	if combat then Wait() else Hide() end
	st.UIScale:Revert()
end

-- Closes with nothing to revert (a reset ended the preview).
function KP:Dismiss()
	Hide()
end

function KP:IsShown()
	return ui ~= nil and ui.frame:IsShown()
end

-- { frame, title, line, keep, back }, or nil until the first ask. For tests.
function KP:GetFrames()
	return ui
end

------------------------------------------------------------------ /sui scale

local FORMS = 'Type /sui scale, then reset, auto, pixel, game or a size from 70 to 150 (a number under 5, like 1.25, is a factor: 125%).'

local function ModeLine(choice)
	local name = KP.MODE_NAMES[choice.mode]
	if choice.mode == 'auto' then return ('UI scale: %s at %d%%.'):format(name, Percent(choice.size)) end
	return ('UI scale: %s.'):format(name)
end

-- A typed size held to what this screen takes, on the model's 5% steps.
local function TypedSize(percent)
	local SIZE = st.UIScale.SIZE
	local default = st.UIScale:Default()
	local top = default and default.sizeMax or SIZE.max
	local size = max(SIZE.min, min(percent / 100, top))
	size = SIZE.min + floor((size - SIZE.min) / SIZE.step + 0.5) * SIZE.step
	return min(floor(size * 100 + 0.5) / 100, top)
end

local REFUSED = {
	combat = "The UI size can't change in combat.",
	screen = "SaftUI can't read this screen's size here.",
}

-- /sui scale and its forms (Config/config.lua hands them the rest of the line).
function KP:Command(argument)
	argument = strtrim(argument or ''):lower()
	local UIScale = st.UIScale

	if argument == '' then
		st:Print(ModeLine(UIScale:Current()))
		local line = UIScale:Describe(UIScale:Applied())
		if line ~= '' then st:Print(line) end
		return
	end

	if argument == 'reset' then
		KP:Dismiss()
		UIScale:Reset()
		return
	end

	local choice
	if argument == 'auto' or argument == 'pixel' or argument == 'game' then
		choice = { mode = argument, size = UIScale:Current().size }
	else
		local number = argument:match('^(%d+%.?%d*)%%?$')
		if not number then
			st:Print(FORMS)
			return
		end
		local percent = tonumber(number)
		if percent < 5 then percent = percent * 100 end -- 1.25 means 125%
		choice = { mode = 'auto', size = TypedSize(percent) }
	end

	local ok, why = KP:Ask(choice)
	if not ok then st:Print(REFUSED[why] or FORMS) end
end
