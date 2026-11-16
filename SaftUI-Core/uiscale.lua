local st = SaftUI

-- The scale model: how big SaftUI draws, from the screen and the player's
-- choice, and the tokens every drawn line is measured in.
--
-- The model works in `k`: how many physical pixels one design pixel (a pixel
-- of a 1440p screen) takes. At k 1 a UIParent unit is a pixel, as SaftUI has
-- always drawn it. `st.pixel` is one pixel in UIParent's units (1 / k),
-- `st.lineWeight` how many pixels a line is (a whole number, 1 below k 1.5),
-- and `st.line` a line in UIParent's units. They are read back from UIParent
-- (UIScale:SetTokens), so they are what is drawn.
--
-- The runtime (from UIScale:Start down) sets UIParent's scale from the choice,
-- at login and again after every change, and puts it back when the game moves
-- it. UIParent is Blizzard's: its SetScale is protected in combat (inferred,
-- .agents/taint.md rule 6), so it is called only here, out of combat, and a
-- change in combat waits whole for the end of it.
local UIScale = {}
st.UIScale = UIScale

UIScale.DESIGN_HEIGHT = 1440
UIScale.SNAP = 72 -- pixels either side of a whole multiple of 1440 (5%)
UIScale.FLOOR = 0.75 -- the automatic part's least
UIScale.SIZE = { min = 0.70, max = 1.50, step = 0.05 }
UIScale.MODES = { 'auto', 'pixel', 'game' } -- the Scale select's order
-- The names of the modes, as the Scale select, the Keep prompt and /sui scale say them.
UIScale.MODE_NAMES = { auto = 'Automatic', pixel = 'Pixel for pixel', game = "The game's UI scale" }
UIScale.DEFAULT = { mode = 'auto', size = 1 }

-- Until the first SetTokens: a unit is a pixel and a line is one.
st.pixel, st.lineWeight, st.line = 1, 1, 1

local floor, abs, max, min = math.floor, math.abs, math.max, math.min

local function IsMode(mode)
	for _, known in ipairs(UIScale.MODES) do
		if known == mode then return true end
	end
	return false
end

-- A number rounded to 1e-4, which is far below a pixel at any scale and takes
-- the float noise off a scale read back (3840 x 2160 measures 1.4999999999999998).
local function Trim(value)
	return floor(value * 10000 + 0.5) / 10000
end

-- The screen in physical pixels, { width, height }, or nil when the game
-- doesn't say, or says no width or height (both are needed: the model's units
-- wide come from the width). The one place the model reads the screen (the E1 and E2 seam).
function UIScale.ReadScreen()
	local width, height = GetPhysicalScreenSize()
	if type(width) ~= 'number' or type(height) ~= 'number' or not (width > 0) or not (height > 0) then
		return nil
	end
	return { width = width, height = height }
end

-- A saved choice as { mode, size }: a fresh table, whatever it was. Nothing
-- that isn't a choice is an error, and nothing is written to the table given.
function UIScale.Normalize(choice)
	local mode, size = UIScale.DEFAULT.mode, UIScale.DEFAULT.size
	if type(choice) == 'table' then
		if IsMode(choice.mode) then mode = choice.mode end
		if type(choice.size) == 'number' and choice.size == choice.size then size = choice.size end
	end
	return { mode = mode, size = size }
end

-- How many pixels a line is at k: k rounded to the whole pixel, from 1 up.
function UIScale.LineWeight(k)
	return max(1, floor(Trim(k) + 0.5))
end

-- The size's top for a screen: the largest step at or under 150% and under
-- what keeps the UI as tall as 768 units (H / (auto * 768)).
local function SizeMax(height, auto)
	local limit = min(UIScale.SIZE.max, height / (auto * 768))
	local size = UIScale.SIZE
	local steps = floor((limit - size.min) / size.step + 1e-9)
	return max(size.min, floor((size.min + steps * size.step) * 100 + 0.5) / 100)
end

-- What a choice makes of a screen: { mode, auto, size, k, uiScale, pixel,
-- lineWeight, line, width, height, unitsWide, unitsTall, sizeMax }. nil with
-- no screen, or in 'game' without a positive gameScale (the game's own UI
-- scale). Pure: it reads nothing and writes nothing.
function UIScale.Resolve(choice, screen, gameScale)
	if type(screen) ~= 'table' or type(screen.height) ~= 'number' or not (screen.height > 0)
		or type(screen.width) ~= 'number' or not (screen.width > 0) then
		return nil
	end
	local picked = UIScale.Normalize(choice)
	local mode = picked.mode
	if mode == 'game' and not (type(gameScale) == 'number' and gameScale > 0) then
		return nil
	end
	local height, width = screen.height, screen.width

	-- Near a whole multiple of 1440 high the screen snaps to it, so a screen a
	-- few pixels off 1440 still draws at exactly 1.
	local n = floor(height / UIScale.DESIGN_HEIGHT + 0.5)
	local auto = (n >= 1 and abs(height - n * UIScale.DESIGN_HEIGHT) <= UIScale.SNAP) and n
		or height / UIScale.DESIGN_HEIGHT
	auto = max(auto, UIScale.FLOOR)

	local sizeMax = SizeMax(height, auto)
	local step = UIScale.SIZE.step
	local size = UIScale.SIZE.min + floor((picked.size - UIScale.SIZE.min) / step + 0.5) * step
	size = floor(size * 100 + 0.5) / 100
	size = max(UIScale.SIZE.min, min(size, sizeMax))

	local k, uiScale
	if mode == 'pixel' then
		k = 1
		uiScale = (768 / height) * k
	elseif mode == 'game' then
		k = gameScale * height / 768
		uiScale = gameScale
	else
		k = auto * size
		uiScale = (768 / height) * k
	end

	local pixel = 1 / k
	local lineWeight = UIScale.LineWeight(k)
	local unitsTall = 768 / uiScale
	return {
		mode = mode,
		auto = auto,
		size = size,
		k = k,
		uiScale = uiScale,
		pixel = pixel,
		lineWeight = lineWeight,
		line = lineWeight * pixel,
		width = width,
		height = height,
		unitsWide = width * unitsTall / height,
		unitsTall = unitsTall,
		sizeMax = sizeMax,
	}
end

-- Reads the tokens back from UIParent, so they are what is drawn (never what
-- was chosen: a set can wait for combat), and puts one line on st.BACKDROP
-- (Core's backdrop table, which stays a table: its edge and its four insets).
-- Left as they are with no screen.
function UIScale:SetTokens()
	local pixel = st:GetPixelSize(UIParent)
	if not pixel then return st.pixel, st.lineWeight, st.line end
	st.pixel = pixel
	st.lineWeight = UIScale.LineWeight(1 / pixel)
	st.line = st.lineWeight * pixel
	-- The table the bags' loading overlay (and anything else that takes it whole)
	-- draws with: one line, as every border is.
	local backdrop = st.BACKDROP
	if backdrop then
		backdrop.edgeSize = st.line
		for _, side in ipairs({ 'left', 'right', 'top', 'bottom' }) do backdrop.insets[side] = st.line end
	end
	return st.pixel, st.lineWeight, st.line
end

------------------------------------------------------------------ the runtime

-- The events that say the screen or the scale may have changed. The third is
-- registered in pcall: a client without it loses only that event.
UIScale.EVENTS = { 'UI_SCALE_CHANGED', 'DISPLAY_SIZE_CHANGED', 'NOTCHED_DISPLAY_MODE_CHANGED' }
-- Seconds to a second check after an event, nil for none. E3: the engine's own
-- set of UIParent's scale is done by the time the events arrive, on the frame
-- after them at the latest, and stays: one check on the next frame is enough.
UIScale.RECHECK = nil

-- How far UIParent's scale may be from the wanted one and count as it. A scale
-- read back in single precision is off by about 3e-8 (relative 6e-8), and the
-- smallest step the player can ask for, 5% of the size, moves it by 0.02 or
-- more: 1e-5 is a few hundred times over the one and two thousand times under
-- the other.
UIScale.TOLERANCE = 1e-5
local TOLERANCE = UIScale.TOLERANCE

-- A guard against an engine that sets its own scale again after every set-back
-- (E3 saw it set once, at the event): after SETBACKS set-backs within WINDOW
-- seconds on one screen the check leaves the engine's scale and says so once.
-- Set-backs are counted per screen, so a window dragged through sizes trips nothing.
local SETBACKS, WINDOW = 5, 1
local setbacks = {} -- the times of the latest set-backs, all on one screen
local setbackKey -- the screen those set-backs were on
local gaveUp -- the screen the check gave up on ('width x height'), or nil
local warned
local settling -- The game's UI scale: the scale a changed reading is waiting to repeat
local lastCvars -- the game's UI Scale setting as the last check read it ('useUiScale|uiScale')
local sliderTold -- Blizzard's slider line, said once a session

local preview -- the choice being tried, or nil
local previous -- the choice in effect before the first preview, for the Keep prompt's Go back
local applied -- the resolved table of the last finished check (or Start)
local lastScale, lastPixel, lastWeight -- UIParent's scale, the pixel and the line weight the last check ended with
local callbacks = {}
local events, scheduled

local function Copy(choice) return { mode = choice.mode, size = choice.size } end

-- The player's saved choice: { mode, size }, or nil when nothing is saved (or
-- what is saved isn't a table). Never writes.
function UIScale:Saved()
	local global = st.config and st.config.global
	local saved = global and global.uiScale
	if type(saved) == 'table' then return UIScale.Normalize(saved) end
	return nil
end

-- The choice in effect: a preview, else the saved one, else the default. A copy.
function UIScale:Current()
	if preview then return Copy(preview) end
	return UIScale:Saved() or UIScale.Normalize(UIScale.DEFAULT)
end

-- What the default makes of this screen (nil with no screen).
function UIScale:Default()
	return UIScale.Resolve(UIScale.DEFAULT, UIScale.ReadScreen())
end

-- What the last finished check applied (nil before one), and whether a choice
-- is being tried without being saved.
function UIScale:Applied() return applied end

-- The choice in effect before the first preview (a copy), nil when not
-- previewing: what the Keep prompt's Go back means.
function UIScale:Previous()
	if previous then return Copy(previous) end
	return nil
end
function UIScale:IsPreviewing() return preview ~= nil end

-- Whether the check has stopped setting the scale back on this screen (the
-- guard's): until a Preview, Apply or Revert or another screen, UIParent has
-- the engine's scale, not the choice's.
function UIScale:GaveUp() return gaveUp ~= nil end

-- The game's own UI scale: Blizzard's slider while Use UI Scale is on, else the
-- default for the screen where the client has one (E1: both read on WoW
-- Forever; the slider is read from the settings, never written). nil when the
-- game doesn't say.
function UIScale.GameScale()
	local use, slider = C_CVar.GetCVar('useUiScale'), C_CVar.GetCVar('uiScale')
	if use == '1' and tonumber(slider) and tonumber(slider) > 0 then return tonumber(slider) end
	if GetDefaultScale then
		local default = GetDefaultScale()
		if type(default) == 'number' and default > 0 then return default end
	end
	return nil
end

-- The game's UI Scale setting as one string: Use UI Scale and the slider.
local function ReadCvars()
	return tostring(C_CVar.GetCVar('useUiScale')) .. '|' .. tostring(C_CVar.GetCVar('uiScale'))
end

UIScale.FIRST_LOGIN = "SaftUI now sizes itself to your screen: here it draws at %d%% of its 1440p size, so it takes the same share of the screen as on the screen it was laid out on. To keep the size it had before, type /sui scale pixel. The choices are in /sui > Global settings > General."
UIScale.SLIDER_LINE = "SaftUI sets the UI's scale itself. To use the game's UI Scale, choose The game's UI scale in /sui > Global settings > General."
-- What st.config.global.uiScaleNotice is set to once the first login line has been shown.
UIScale.NOTICE_VERSION = 1

-- What a choice makes of the screen as it is now; in The game's UI scale the
-- scale is whatever UIParent has.
local function ResolveNow(choice)
	return UIScale.Resolve(choice, UIScale.ReadScreen(), UIParent:GetScale())
end

-- Records what is on screen: the tokens measured from UIParent, and its scale.
local function Record()
	UIScale:SetTokens()
	lastScale, lastPixel, lastWeight = UIParent:GetScale(), st.pixel, st.lineWeight
end

local function Safely(fn, ...)
	xpcall(fn, geterrorhandler(), ...)
end

-- Registers fn(resolved) to run after every pass, in the order registered.
function UIScale:OnChanged(fn)
	callbacks[#callbacks + 1] = fn
end

-- What follows a real change: the profile update (the pass: every themed frame
-- drawn again, every module laid out again, the margin applied, an open /sui
-- rebuilt), where Config has one, then the callbacks.
local function Pass(resolved)
	local config = st.Config
	if config and config.UpdateConfig then Safely(function() config:UpdateConfig() end) end
	for _, fn in ipairs(callbacks) do Safely(fn, resolved) end
end

-- The scale at login: the saved choice on this screen. In Automatic and Pixel
-- for pixel UIParent is set to it, out of combat; in The game's UI scale
-- nothing is set. In combat the check waits for the end of it. It records the
-- tokens and what it applied, runs no pass and no callback (nothing is built
-- yet), and listens for the screen events. Nothing with no screen.
function UIScale:Start()
	local resolved = ResolveNow(UIScale:Current())
	if resolved then
		if resolved.mode == 'game' then
			applied = resolved
		elseif InCombatLockdown() then
			st:QueueAfterCombat('UIScale', function() UIScale:Check() end)
		else
			UIParent:SetScale(resolved.uiScale)
			applied = resolved
		end
	end
	Record()
	lastCvars = ReadCvars()

	-- The first login after the update: once per account, with nothing saved,
	-- where Automatic isn't pixel for pixel. It is a version number, set only
	-- when the line is shown, so the owner's screen (k 1) is never told and
	-- would still be told on another screen.
	local global = st.config and st.config.global
	if resolved and global and not UIScale:Saved() and abs(resolved.k - 1) > 1e-6
		and (tonumber(global.uiScaleNotice) or 0) < UIScale.NOTICE_VERSION then
		global.uiScaleNotice = UIScale.NOTICE_VERSION
		st:Print(UIScale.FIRST_LOGIN:format(floor(resolved.k * 100 + 0.5)))
	end

	if not events then
		events = CreateFrame('Frame')
		events:SetScript('OnEvent', function() UIScale:ScheduleCheck() end)
		events:RegisterEvent(UIScale.EVENTS[1])
		events:RegisterEvent(UIScale.EVENTS[2])
		pcall(events.RegisterEvent, events, UIScale.EVENTS[3])
	end
end

-- Asks for one check on the next frame, however many events come in this one
-- (they come in pairs, and the first can read a scale the engine hasn't set
-- yet: E3). Events that arrive during the check are its own (its SetScale, on
-- a client where that fires one), so they ask for nothing.
function UIScale:ScheduleCheck()
	if scheduled then return end
	scheduled = true
	C_Timer.After(0, function()
		Safely(UIScale.Check, UIScale)
		scheduled = false
	end)
	if UIScale.RECHECK then
		C_Timer.After(UIScale.RECHECK, function() Safely(UIScale.Check, UIScale) end)
	end
end

-- Sets UIParent back to the wanted scale, unless the engine has taken it away
-- SETBACKS times within WINDOW seconds: then it stays as it is and chat says
-- why, once. Returns whether it set it.
local function SetBack(resolved)
	local key = resolved.width .. ' x ' .. resolved.height
	-- Another screen is a new start: a window dragged through many sizes is not
	-- an engine fighting SaftUI on one. Only repeats on one screen count.
	if setbackKey ~= key then gaveUp, setbacks, setbackKey = nil, {}, key end
	if gaveUp then return false end
	local now, recent = GetTime(), {}
	for _, time in ipairs(setbacks) do
		if now - time < WINDOW then recent[#recent + 1] = time end
	end
	setbacks = recent
	if #setbacks >= SETBACKS then
		gaveUp = key
		if not warned then
			warned = true
			st:Print("The game keeps setting its own UI scale, so SaftUI stopped setting it back. Untick Use UI Scale in the game's graphics options, or choose The game's UI scale in SaftUI.")
		end
		return false
	end
	setbacks[#setbacks + 1] = now
	UIParent:SetScale(resolved.uiScale)
	return true
end

-- The check: is UIParent where the choice says, and did anything the UI is
-- drawn in change? Never in combat: it waits whole for the end of it. Setting
-- UIParent back counts as a change: whatever was drawn while the engine's
-- scale was in force (in a fight, or in the frame before this check) is drawn
-- again by the pass, and the plates pinned again.
function UIScale:Check()
	local resolved = ResolveNow(UIScale:Current())
	if not resolved then return end
	if st:QueueAfterCombat('UIScale', function() UIScale:Check() end) then return end

	local movedBack, own = false, false
	if resolved.mode == 'game' then
		-- Just switched to it: take the game's own scale once. After that SaftUI
		-- only reads it.
		if applied and applied.mode ~= 'game' then
			local game = UIScale.GameScale()
			if game then
				UIParent:SetScale(game)
				own = true
				resolved = ResolveNow(UIScale:Current()) or resolved
			else
				st:Print("SaftUI can't read the game's UI scale here. It shows after /reload.")
			end
		end
	elseif abs(UIParent:GetScale() - resolved.uiScale) > TOLERANCE then
		movedBack = SetBack(resolved)
		-- Blizzard's slider (Ruling 16): the engine's scale was put back and the
		-- game's setting reads differently from the last check, which tells the
		-- player's move from a display change. Once a session.
		if movedBack and not sliderTold and lastCvars and ReadCvars() ~= lastCvars then
			sliderTold = true
			st:Print(UIScale.SLIDER_LINE)
		end
	else
		gaveUp = nil
	end

	lastCvars = ReadCvars()
	UIScale:SetTokens()
	local scale = UIParent:GetScale()
	local changed = movedBack or lastScale == nil or abs(scale - lastScale) > TOLERANCE
		or st.pixel ~= lastPixel or st.lineWeight ~= lastWeight
	if resolved.mode == 'game' and changed and not own then
		-- The engine's events come in pairs, the first able to read a scale the
		-- second then changes, and E3 saw both at one timestamp; a pair split across
		-- two frames would pass twice. A changed reading has to repeat on the next
		-- frame to count.
		if not settling or abs(settling - scale) > TOLERANCE then
			settling = scale
			C_Timer.After(0, function() Safely(UIScale.Check, UIScale) end)
			return
		end
	end
	settling = nil
	applied = resolved
	lastScale, lastPixel, lastWeight = scale, st.pixel, st.lineWeight
	if changed then
		Pass(resolved)
	else
		st:UpdateScreenMargin()
	end
end

-- Whether choice is one a preview or a save may take, with why not: 'mode' (an
-- unknown mode), 'size' (not a number, or outside 70% to what the screen holds)
-- or 'screen' (no screen). A size left out is the default's. Only what is saved
-- is ever fixed up (Normalize), never what is asked for.
local function Refused(choice)
	if type(choice) ~= 'table' or not IsMode(choice.mode) then return 'mode' end
	local size = choice.size
	if size ~= nil and (type(size) ~= 'number' or size ~= size) then return 'size' end
	local screen = UIScale.ReadScreen()
	if not screen then return 'screen' end
	if size ~= nil then
		-- Only Automatic's size is held to what the screen holds (sizeMax); the
		-- other modes ignore it, and take any size in 70% to 150%.
		local top = UIScale.SIZE.max
		if choice.mode == 'auto' then top = UIScale.Resolve({ mode = 'auto', size = size }, screen).sizeMax end
		if size < UIScale.SIZE.min - 1e-9 or size > top + 1e-9 then return 'size' end
	end
	return nil
end

-- Tries a choice on screen without saving it: ok, or false and why ('combat',
-- 'mode', 'size' or 'screen'). The choice in effect before the first preview is
-- kept for Go back; Revert returns to the saved one.
function UIScale:Preview(choice)
	if InCombatLockdown() then return false, 'combat' end
	local why = Refused(choice)
	if why then return false, why end
	if not preview then previous = UIScale:Current() end
	preview = UIScale.Normalize(choice)
	gaveUp, setbacks, setbackKey = nil, {}, nil
	UIScale:Check()
	return true
end

-- Saves a choice and puts it on screen (it ends a preview). nil, or the
-- default, removes the save. Saved in combat too (it only writes a table); the
-- scale then follows the end of the fight: true, 'combat'.
function UIScale:Apply(choice)
	if choice ~= nil then
		local why = Refused(choice)
		if why and why ~= 'screen' then return false, why end
	end
	local picked = choice ~= nil and UIScale.Normalize(choice) or nil
	local global = st.config and st.config.global
	if global then
		if picked and not (picked.mode == UIScale.DEFAULT.mode and picked.size == UIScale.DEFAULT.size) then
			global.uiScale = { mode = picked.mode, size = picked.size }
		else
			global.uiScale = nil
		end
	end
	preview, previous = nil, nil
	gaveUp, setbacks, setbackKey = nil, {}, nil
	UIScale:Check()
	if InCombatLockdown() then return true, 'combat' end
	return true
end

-- Ends a preview: back to the saved choice, else the default.
function UIScale:Revert()
	preview, previous = nil, nil
	gaveUp, setbacks, setbackKey = nil, {}, nil
	UIScale:Check()
	return true
end

-- /sui scale reset, the way out of any size: Automatic at 100% at once, with no
-- question (Apply(nil)), and one line saying so. In combat the save is at once
-- and the scale follows the fight. It lives here, not in the Keep prompt's
-- file, so it works with that file missing.
function UIScale:Reset()
	UIScale:Apply(nil)
	local text = ('Automatic at %d%%'):format(floor(UIScale.DEFAULT.size * 100 + 0.5))
	if InCombatLockdown() then
		st:Print(('UI scale goes back to %s when combat ends.'):format(text))
	else
		st:Print(('UI scale back to %s.'):format(text))
	end
end

-- The plain line /sui shows for what a choice made of the screen.
function UIScale:Describe(resolved)
	if not resolved then return '' end
	local percent = floor(resolved.k * 100 + 0.5)
	local lines = resolved.lineWeight .. ' pixel lines'
	local screen = ('This screen is %d x %d: '):format(resolved.width, resolved.height)
	if resolved.mode == 'pixel' then
		return ('%sSaftUI draws pixel for pixel, at %d%% of its 1440p size, with %s.'):format(screen, percent, lines)
	elseif resolved.mode == 'game' then
		return ("%sthe game's UI scale draws SaftUI at %d%% of its 1440p size, with %s."):format(screen, percent, lines)
	end
	return ('%sSaftUI draws at %d%% of its 1440p size, with %s.'):format(screen, percent, lines)
end
