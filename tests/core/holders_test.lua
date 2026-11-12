-- Taking over a Blizzard Edit Mode frame (SaftUI-Core/api.lua):
-- st:HideEditModeSelection keeps a frame's Edit Mode box hidden with a post-hook
-- on its OnShow; st:HoldFrame anchors a Blizzard frame over a holder of
-- SaftUI's and puts it back each time Blizzard places it; st:PlaceHolder sizes
-- and places the holder from the profile, or at the end of combat.
--
-- Real: Core's helpers (api.lua). Blizzard's frames are stand-ins locked with
-- misc/fixtures/locked_widget.lua, so a field written onto one (or onto its
-- Selection) or a SetScript on one fails the case. An Edit Mode system's
-- SetPoint and ClearAllPoints are Lua overrides of Blizzard's
-- (EditModeSystemMixin:OnSystemLoad), which addon code must never call: the
-- stand-in has them, and counts the calls. The stubs can't tell a protected
-- frame (.agents/testing.md), so a test gives one an IsProtected of its own;
-- its moves are then blocked in combat and noted in stub.blocked.
local st = SaftUI
local locked = load_test_file('misc/fixtures/locked_widget.lua')

-- One UIParent unit per physical pixel, so st:RoundToPixel rounds to whole units.
stub.screen_width, stub.screen_height = 1000, 600
UIParent:SetScale(768 / 600)

-- A Blizzard Edit Mode system: its Selection box (made hidden, as its XML has
-- it) and SetPoint and ClearAllPoints overrides that count Blizzard's calls,
-- then locked. Blizzard's own code is secure, so the game lets it move the frame
-- in combat even while it's protected; the stubs can't tell its calls from
-- addon code's, so the overrides step out of combat for their own move. opts:
-- selection = false for a system without a box, protected = true.
local function System(opts)
	opts = opts or {}
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(120, 40)
	frame:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	local calls = { override = 0, direct = 0 }
	if opts.selection ~= false then
		local selection = CreateFrame('Frame', nil, frame)
		selection:SetAllPoints(frame)
		selection:Hide()
		frame.Selection = locked(selection, 'Blizzard Edit Mode box')
	end
	local methods = getmetatable(frame).__index
	for _, name in ipairs({ 'SetPoint', 'ClearAllPoints' }) do
		rawset(frame, name, function(self, ...)
			calls.override = calls.override + 1
			local combat = stub.in_combat
			stub.in_combat = false
			methods[name](self, ...)
			stub.in_combat = combat
		end)
	end
	if opts.protected then
		rawset(frame, 'IsProtected', function() return true, true end)
	end
	locked(frame, 'Blizzard Edit Mode system')
	-- The plain widget method, as the direct helpers reach it (through the
	-- frame's own metatable, which the lock gave it), counted.
	local index = getmetatable(frame).__index
	rawset(index, 'ClearAllPoints', function(self, ...)
		calls.direct = calls.direct + 1
		return methods.ClearAllPoints(self, ...)
	end)
	return frame, calls
end

local function Holder(left, bottom, width, height)
	local holder = CreateFrame('Frame', nil, UIParent)
	holder:SetSize(width or 200, height or 50)
	holder:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', left or 100, bottom or 100)
	return holder
end

local function OnShowHooks(selection)
	return #(stub.state(selection).hooks.OnShow or {})
end

local function Rect(frame)
	local left, bottom, width, height = frame:GetRect()
	return ('%s,%s,%s,%s'):format(left, bottom, width, height)
end

local function Fresh()
	stub.in_combat = false
	stub.blocked = {}
	take_errors()
end

local function EndCombat()
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
end

-- Runs fn(hooked) with the global hooksecurefunc counted: hooked[name] is how
-- many times frame's method name was hooked through it. A post-hook has to go
-- through hooksecurefunc (.agents/taint.md rule 2); a Lua wrapper assigned over
-- the frame's method would replace Blizzard's Edit Mode override, and the lock
-- can't see that, as the key is already on the frame. The global is put back
-- after, even if fn errors.
local function CountingHooks(frame, fn)
	local real = hooksecurefunc
	local hooked = {}
	hooksecurefunc = function(tbl, name, ...)
		if tbl == frame then hooked[name] = (hooked[name] or 0) + 1 end
		return real(tbl, name, ...)
	end
	local ok, err = pcall(fn, hooked)
	hooksecurefunc = real
	if not ok then error(err, 0) end
end

------------------------------------------------------------------ st:HideEditModeSelection

test('HideEditModeSelection: the box stays hidden each time Blizzard shows it', function()
	Fresh()
	local frame = System()
	local selection = frame.Selection
	st:HideEditModeSelection(frame)
	eq(OnShowHooks(selection), 1, 'one OnShow hook on the box')
	check(not selection:IsShown(), 'still hidden')

	-- Blizzard's Edit Mode opening (HighlightSystem: Selection:ShowHighlighted).
	selection:Show()
	check(not selection:IsShown(), 'hidden again when shown')
	selection:Show()
	check(not selection:IsShown(), 'and the next time')
	selection:SetShown(true)
	check(not selection:IsShown(), 'and through SetShown')
	eq(#take_errors(), 0, 'no errors')
end)

test('HideEditModeSelection: a hook only, as AB:HideEditModeSelection was: a box showing now waits for its next show', function()
	Fresh()
	local frame = System()
	local selection = frame.Selection
	selection:Show()
	st:HideEditModeSelection(frame)
	check(selection:IsShown(), 'not hidden now')
	selection:Hide()
	selection:Show()
	check(not selection:IsShown(), 'hidden when it next shows')
end)

test('HideEditModeSelection: called again for a frame, the box keeps one hook', function()
	Fresh()
	local frame = System()
	st:HideEditModeSelection(frame)
	st:HideEditModeSelection(frame)
	st:HideEditModeSelection(frame)
	eq(OnShowHooks(frame.Selection), 1, 'one hook after three calls')

	local other = System()
	st:HideEditModeSelection(other)
	eq(OnShowHooks(other.Selection), 1, 'another frame gets its own')
	eq(OnShowHooks(frame.Selection), 1, 'and the first keeps one')
end)

test('HideEditModeSelection: a nil frame and a frame without a box do nothing', function()
	Fresh()
	st:HideEditModeSelection(nil)
	local bare = System({ selection = false })
	st:HideEditModeSelection(bare)
	eq(#take_errors(), 0, 'no errors')
	eq(#stub.blocked, 0, 'nothing blocked')
end)

test('HideEditModeSelection: in combat the box is hooked at once, on a protected frame too, and nothing waits for the end of combat', function()
	Fresh()
	local frame = System({ protected = true })
	local selection = frame.Selection
	stub.in_combat = true
	st:HideEditModeSelection(frame)
	eq(OnShowHooks(selection), 1, 'hooked in combat')
	selection:Show()
	check(not selection:IsShown(), 'hidden when shown in combat')
	eq(#stub.blocked, 0, 'nothing blocked: the box itself is not protected')
	EndCombat()
	eq(OnShowHooks(selection), 1, 'still one hook after combat')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ st:HoldFrame

test('HoldFrame: the frame covers its holder, placed with the plain widget methods', function()
	Fresh()
	local frame, calls = System()
	local holder = Holder(100, 100, 200, 50)
	CountingHooks(frame, function(hooked)
		st:HoldFrame(frame, holder)
		eq(hooked.ClearAllPoints, 1, 'ClearAllPoints post-hooked once, with hooksecurefunc')
		eq(hooked.SetPoint, 1, 'SetPoint post-hooked once, with hooksecurefunc')
	end)

	eq(frame:GetNumPoints(), 2, 'two anchors')
	local point, relative, relPoint, x, y = frame:GetPoint(1)
	check(point == 'TOPLEFT' and relative == holder and relPoint == 'TOPLEFT' and x == 0 and y == 0,
		'top left on the holder\'s')
	point, relative, relPoint, x, y = frame:GetPoint(2)
	check(point == 'BOTTOMRIGHT' and relative == holder and relPoint == 'BOTTOMRIGHT' and x == 0 and y == 0,
		'bottom right on the holder\'s')
	eq(Rect(frame), Rect(holder), 'the holder\'s rect')
	eq(calls.override, 0, 'never through Blizzard\'s overrides')
	eq(calls.direct, 1, 'cleared once, directly')
end)

test('HoldFrame: an outset puts the frame that far outside its holder on each side', function()
	Fresh()
	local frame = System()
	local holder = Holder(100, 100, 200, 50)
	st:HoldFrame(frame, holder, 5, 4)
	local _, _, _, x, y = frame:GetPoint(1)
	check(x == -5 and y == 4, 'top left 5 out and 4 up')
	_, _, _, x, y = frame:GetPoint(2)
	check(x == 5 and y == -4, 'bottom right 5 out and 4 down')
	eq(Rect(frame), '95,96,210,58', '5 wider each side, 4 taller')
end)

test('HoldFrame: put back after each of Blizzard\'s places, and follows the holder', function()
	Fresh()
	local frame, calls = System()
	local holder = Holder(100, 100, 200, 50)
	st:HoldFrame(frame, holder)

	-- Blizzard clearing the frame's anchors on its own (a snap break, a layout
	-- apply that stops there): put back by the ClearAllPoints hook alone.
	calls.direct = 0
	frame:ClearAllPoints()
	eq(calls.direct, 1, 'put back once after Blizzard\'s ClearAllPoints')
	eq(frame:GetNumPoints(), 2, 'its two anchors again')
	eq(select(2, frame:GetPoint(1)), holder, 'on the holder')
	eq(select(2, frame:GetPoint(2)), holder, 'both corners')

	-- Blizzard's Edit Mode applying a layout (ApplySystemAnchor).
	calls.override = 0
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -255, -10)
	eq(calls.override, 2, 'only Blizzard\'s two calls went through its overrides')
	eq(frame:GetNumPoints(), 2, 'two anchors again')
	eq(select(2, frame:GetPoint(1)), holder, 'back on the holder')
	eq(Rect(frame), Rect(holder), 'at the holder\'s rect')

	holder:ClearAllPoints()
	holder:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 300, 200)
	eq(Rect(frame), Rect(holder), 'follows the holder by its anchors')
	eq(#take_errors(), 0, 'no errors')
end)

test('HoldFrame: called again, one set of hooks, held on the holder it was last given', function()
	Fresh()
	local frame, calls = System()
	local holder = Holder(100, 100, 200, 50)
	local other = Holder(400, 300, 80, 20)
	CountingHooks(frame, function(hooked)
		st:HoldFrame(frame, holder)
		st:HoldFrame(frame, holder)
		eq(hooked.ClearAllPoints, 1, 'ClearAllPoints hooked once after two calls')
		eq(hooked.SetPoint, 1, 'SetPoint hooked once after two calls')
		calls.direct = 0
		frame:SetPoint('CENTER', UIParent, 'CENTER', 10, 10)
		eq(calls.direct, 1, 'one put back for one place by Blizzard')

		st:HoldFrame(frame, other, 2, 2)
		eq(hooked.ClearAllPoints, 1, 'still hooked once after a new holder')
		eq(hooked.SetPoint, 1, 'and SetPoint too')
	end)
	eq(select(2, frame:GetPoint(1)), other, 'moved to the new holder')
	calls.direct = 0
	frame:SetPoint('CENTER', UIParent, 'CENTER', 10, 10)
	eq(calls.direct, 1, 'still one put back')
	eq(select(2, frame:GetPoint(1)), other, 'back on the new holder')
	eq(select(4, frame:GetPoint(1)), -2, 'with its outset')
end)

test('HoldFrame: a frame that is not protected is held in combat too', function()
	Fresh()
	local frame = System()
	local holder = Holder(100, 100, 200, 50)
	stub.in_combat = true
	st:HoldFrame(frame, holder)
	eq(select(2, frame:GetPoint(1)), holder, 'held at once')
	frame:SetPoint('CENTER', UIParent, 'CENTER', 10, 10)
	eq(select(2, frame:GetPoint(1)), holder, 'put back at once after Blizzard places it')
	eq(#stub.blocked, 0, 'nothing blocked')
	EndCombat()
end)

test('HoldFrame: a protected frame in combat is left where Blizzard puts it until combat ends, then held once', function()
	Fresh()
	local frame, calls = System({ protected = true })
	local holder = Holder(100, 100, 200, 50)
	stub.in_combat = true
	st:HoldFrame(frame, holder)
	eq(#stub.blocked, 0, 'no move tried in combat')
	eq(calls.direct, 0, 'nothing cleared')
	eq(select(2, frame:GetPoint(1)), UIParent, 'still where it was')

	-- Blizzard places it in combat, twice (its own code may).
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -255, -10)
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', UIParent, 'TOPRIGHT', -255, -20)
	eq(#stub.blocked, 0, 'still no move tried')
	eq(calls.direct, 0, 'still nothing cleared')
	eq(frame:GetNumPoints(), 1, 'one anchor, Blizzard\'s')
	eq(select(5, frame:GetPoint(1)), -20, 'at Blizzard\'s spot')

	EndCombat()
	eq(calls.direct, 1, 'held once at the end of combat')
	eq(frame:GetNumPoints(), 2, 'two anchors')
	eq(Rect(frame), Rect(holder), 'on the holder')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ st:PlaceHolder

test('PlaceHolder: sizes the holder and places it from the position, offsets in whole pixels', function()
	Fresh()
	local holder = CreateFrame('Frame', nil, UIParent)
	local anchor = CreateFrame('Frame', 'HoldersTestAnchor', UIParent)
	anchor:SetSize(10, 10)
	anchor:SetPoint('CENTER')
	local position = { point = 'TOP', frame = 'HoldersTestAnchor', rel_point = 'BOTTOM', x_off = 10.4, y_off = -20.6 }
	local placed = st:PlaceHolder(holder, 'holders_test', function() return 120, 30 end, function() return position end)
	eq(placed, true, 'placed now')
	eq(holder:GetWidth(), 120, 'width')
	eq(holder:GetHeight(), 30, 'height')
	eq(holder:GetNumPoints(), 1, 'one anchor')
	local point, relative, relPoint, x, y = holder:GetPoint(1)
	check(point == 'TOP' and relative == anchor and relPoint == 'BOTTOM', 'its point, frame and relative point')
	check(x == 10 and y == -21, 'offsets rounded to whole pixels')

	position = { point = 'LEFT', frame = 'NoSuchFrame', x_off = 5 }
	st:PlaceHolder(holder, 'holders_test', function() return 120, 30 end, function() return position end)
	point, relative, relPoint, x, y = holder:GetPoint(1)
	check(point == 'LEFT' and relative == UIParent and relPoint == 'LEFT' and x == 5 and y == 0,
		'an unknown frame is UIParent, a missing relative point the point, a missing offset 0')
	eq(holder:GetNumPoints(), 1, 'the old anchor cleared')
end)

test('PlaceHolder: a protected holder in combat waits, then reads its size and position at the end of combat', function()
	Fresh()
	local holder = CreateFrame('Frame', nil, UIParent)
	holder:SetSize(10, 10)
	holder:SetPoint('CENTER')
	holder.IsProtected = function() return true, true end
	local width, position = 100, { point = 'BOTTOMLEFT', x_off = 1, y_off = 2 }
	local reads = 0
	stub.in_combat = true
	local placed = st:PlaceHolder(holder, 'holders_test_combat',
		function() reads = reads + 1; return width, 20 end,
		function() return position end)
	eq(placed, false, 'not placed now')
	eq(reads, 0, 'nothing read yet')
	eq(#stub.blocked, 0, 'no move tried')
	eq(holder:GetWidth(), 10, 'its size kept')
	eq(holder:GetPoint(1), 'CENTER', 'its anchor kept')

	-- The profile changes before the fight ends.
	width, position = 150, { point = 'TOPLEFT', x_off = 7, y_off = -8 }
	EndCombat()
	eq(reads, 1, 'read once')
	eq(holder:GetWidth(), 150, 'the size it has then')
	local point, _, _, x, y = holder:GetPoint(1)
	check(point == 'TOPLEFT' and x == 7 and y == -8, 'the position it has then')
	eq(#stub.blocked, 0, 'nothing blocked')
end)
