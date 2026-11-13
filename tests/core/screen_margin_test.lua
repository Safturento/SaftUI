-- The screen edge margin (misc.clamp_inset, Global Settings > General) on every
-- frame the user can move: st:KeepInScreenMargin and st:UpdateScreenMargin
-- (SaftUI-Core/api.lua), which clamp a frame to the screen with the margin's
-- insets and re-apply them; the frames given to them (edit mode's movers,
-- st:RegisterMover in EditMode/editmode.lua; windows with a header,
-- st:CreateHeader in panels.lua; /sui's window and its dialog,
-- Config/optionswindow.lua and optionssmalldialog.lua); what re-applies the
-- margin (the General tab's row, a profile switch, the end of combat);
-- Blizzard frames SaftUI moves, which it never clamps (st:EnableMoving's,
-- and a mover on a Blizzard frame); and edit mode drags and nudges
-- (EditMode/mover.lua), which stop at the margin and start from where the
-- game's clamp shows a frame (st:GetClampShift).
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua), with
-- Core's helpers and edit mode; the options model, widgets, body and window.
-- The stubs remember a frame's clamp settings but don't clamp it (.agents/
-- testing.md), so a test that needs the game's clamp has a frame report the
-- rect the game would show it at, through its own GetLeft and the like.

load_test_file('core/config_helpers.lua')
local st = SaftUI
local EM = st.EditModeFrames
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_options_window()
local OM, OW = st.OptionsModel, st.OptionsWindow

-- A 1000 x 600 screen at the scale SaftUI sets at login: one UIParent unit per
-- physical pixel, so UIParent is 1000 x 600 too.
stub.screen_width, stub.screen_height = 1000, 600
UIParent:SetScale(768 / 600)

-- The General tab's margin row, read and written as the options window does.
local function Row(key)
	local root = st.Config:GetOptionsTable()
	for _, section in ipairs(OM.BuildView(root, 'Fonts', { tab = 'general' }).sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return root, row end
		end
	end
	error('no row ' .. key)
end
local function Set(value) local root, row = Row('clamp_inset'); return OM.Set(root, row, value) end

-- A frame's clamp insets as 'left,right,top,bottom' (-0 written as 0).
local function Insets(frame)
	local out = { frame:GetClampRectInsets() }
	for i, v in ipairs(out) do out[i] = tostring(v == 0 and 0 or v) end
	return table.concat(out, ',')
end

-- Kept m in from each edge: the game keeps the frame's rect, grown by these, on screen.
local function Margin(m)
	return Insets({ GetClampRectInsets = function() return -m, m, m, -m end })
end

-- A SaftUI frame of width x height, placed from its position table.
local function Place(frame, position)
	frame:ClearAllPoints()
	frame:SetPoint(position.point, UIParent, position.rel_point or position.point, position.x_off, position.y_off)
end

local function Frame(width, height, name)
	local frame = CreateFrame('Frame', name, UIParent)
	frame:SetSize(width or 100, height or 40)
	return frame
end

-- Registers a mover for frame, as a module would: its position lives in a
-- table of its own, and apply places the frame from it. extra fields go on the def.
local count = 0
local function Mover(frame, position, extra)
	count = count + 1
	position = position or { point = 'BOTTOMLEFT', x_off = 100, y_off = 100 }
	local def = {
		frame = frame,
		getPosition = function() return position end,
		setPosition = function(pos) position = pos end,
		apply = function() Place(frame, position) end,
	}
	for k, v in pairs(extra or {}) do def[k] = v end
	def.apply()
	return st:RegisterMover('margin_test_' .. count, def), position
end

------------------------------------------------------------------ who gets it

test("every edit mode mover's frame is kept the margin in from the screen's edges, holders included", function()
	-- A SaftUI frame that is its own mover (an action bar's header), and a
	-- holder with a Blizzard frame anchored to it (buffs, swing timers).
	local bar = Frame()
	local holder = Frame()
	local blizzard = CreateFrame('Frame', nil, UIParent) -- stands in for Blizzard's frame on the holder
	blizzard:SetAllPoints(holder)
	Mover(bar)
	Mover(holder)
	for name, frame in pairs({ bar = bar, holder = holder }) do
		check(frame:IsClampedToScreen(), name .. ' is clamped to the screen')
		eq(Insets(frame), Margin(20), name .. ' is kept the default margin in')
	end
	-- SaftUI never clamps the Blizzard frame: it follows its holder.
	check(not blizzard:IsClampedToScreen(), 'the Blizzard frame on the holder is left alone')
	eq(Insets(blizzard), '0,0,0,0')
	eq(#take_errors(), 0, 'no errors')
end)

test('a mover whose frame is Blizzard\'s own (the Minimap) is never clamped by SaftUI', function()
	-- Any clamp call on it is recorded: SaftUI must leave a Blizzard frame's clamp alone.
	local minimap = Frame(140, 140, 'Minimap') -- stands in for Blizzard's Minimap
	local calls = {}
	function minimap:SetClampedToScreen() calls[#calls + 1] = 'SetClampedToScreen' end
	function minimap:SetClampRectInsets() calls[#calls + 1] = 'SetClampRectInsets' end
	Mover(minimap, nil, { blizzardFrame = true })
	st:UpdateScreenMargin()
	Set(30)
	Set(20)
	local first = st.config:GetCurrentProfile()
	st.config:SetProfile('MarginBlizzard')
	st.config:SetProfile(first)
	eq(table.concat(calls, ','), '', 'no clamp call on registering, a margin change or a profile switch')
	eq(#take_errors(), 0, 'no errors')
end)

test('st:EnableMoving makes a Blizzard frame draggable without the margin', function()
	-- Its callers (SaftUI-Misc/movable.lua, the world map skin, the clock's time
	-- manager) all move Blizzard's UI panels, whose clamp is Blizzard's.
	local panel = Frame(300, 200, 'SettingsPanel') -- stands in for Blizzard's
	st:EnableMoving(panel)
	check(panel:IsClampedToScreen(), 'kept on screen, as before')
	eq(Insets(panel), '0,0,0,0', 'with no margin')
	Set(30)
	eq(Insets(panel), '0,0,0,0', 'nor after a margin change')
	Set(20)
end)

------------------------------------------------------------------ when it's applied

test("the General tab's margin reaches every frame kept in it at once: movers, windows with a header, /sui and its dialog", function()
	local moved = Frame()
	Mover(moved)
	local panel = st:CreatePanel('Margin test', 200, 100) -- a window with a header (the bags)
	st.Config:Open()
	local window = OW:GetFrame()
	OW:OpenDialog('Margin', { type = 'group', name = 'Margin', args = {
		on = { order = 1, type = 'toggle', name = 'On', get = function() return true end, set = function() end },
	} })
	local dialog = OW.GetDialogFrames().frame
	local frames = { mover = moved, header = panel, window = window, dialog = dialog }

	for name, frame in pairs(frames) do
		check(frame:IsClampedToScreen(), name .. ' is clamped to the screen')
		eq(Insets(frame), Margin(20), name .. ' has the default margin')
	end
	Set(-10)
	eq(st.config.profile.misc.clamp_inset, -10, 'the profile')
	for name, frame in pairs(frames) do
		eq(Insets(frame), Margin(-10), name .. ': below 0, it can go that far past the edges')
	end
	Set(20)
	for name, frame in pairs(frames) do
		eq(Insets(frame), Margin(20), name .. ' and back')
	end
	OW:CloseDialog()
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)

test("a profile switch gives every frame the new profile's margin", function()
	local moved = Frame()
	Mover(moved)
	local panel = st:CreatePanel('Margin profiles', 200, 100)
	local first = st.config:GetCurrentProfile()
	Set(0)
	eq(Insets(moved), Margin(0))

	st.config:SetProfile('MarginTwo')
	eq(st.config.profile.misc.clamp_inset, 20, "the new profile's margin")
	eq(Insets(moved), Margin(20), 'the mover takes it')
	eq(Insets(panel), Margin(20), 'and the window')

	st.config:SetProfile(first)
	eq(Insets(moved), Margin(0), "the first profile's again")
	eq(Insets(panel), Margin(0))
	Set(20)
	eq(#take_errors(), 0, 'no errors')
end)

test('a frame whose art reaches past its edges keeps the art inside the margin, read each time it is applied', function()
	local frame = Frame()
	local reach = { 8, 2, 16, 4 } -- left, right, top, bottom, as /sui's metal under Blizzard
	st:KeepInScreenMargin(frame, function() return unpack(reach) end)
	eq(Insets(frame), '-28,22,36,-24', 'the margin plus the reach on each side')
	Set(-10)
	eq(Insets(frame), '2,-8,6,6', "a new margin: the art that far past the screen's edges")
	reach = { 0, 0, 0, 0 }
	st:KeepInScreenMargin(frame)
	eq(Insets(frame), Margin(-10), 'given again: the reach read again')
	Set(20)
	eq(Insets(frame), Margin(20))
	eq(#take_errors(), 0, 'no errors')
end)

test('in combat a protected frame keeps its margin until combat ends; one re-apply then does them all', function()
	-- Stub frames are never protected; these say they are, as a secure unit
	-- frame or action bar, or a holder one is anchored to, is in game.
	local function Protected()
		local frame = Frame()
		function frame:IsProtected() return true, true end
		return frame
	end
	local secureA, secureB, free = Protected(), Protected(), Frame()
	for _, frame in ipairs({ secureA, secureB, free }) do st:KeepInScreenMargin(frame) end

	stub.in_combat = true
	st.config.profile.misc.clamp_inset = 5
	st:UpdateScreenMargin() -- what the General tab and a profile switch run
	eq(Insets(free), Margin(5), 'a frame that is not protected, at once')
	eq(Insets(secureA), Margin(20), 'a protected one keeps its margin in combat')
	eq(Insets(secureB), Margin(20))
	-- A protected frame given in combat (a mover registered after a /reload in combat) waits too.
	local late = Protected()
	st:KeepInScreenMargin(late)
	check(not late:IsClampedToScreen(), 'one given in combat waits')

	local real, runs = st.UpdateScreenMargin, 0
	st.UpdateScreenMargin = function(self, ...) runs = runs + 1; return real(self, ...) end
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	st.UpdateScreenMargin = real
	eq(runs, 1, 'one re-apply after combat')
	for name, frame in pairs({ secureA = secureA, secureB = secureB, late = late }) do
		check(frame:IsClampedToScreen(), name .. ' is clamped after combat')
		eq(Insets(frame), Margin(5), name .. ' takes the margin when combat ends')
	end

	st.config.profile.misc.clamp_inset = 20
	st:UpdateScreenMargin()
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ edit mode drags and nudges

-- Drags the mover's overlay by dx, dy (UIParent units) and lets go.
local function Drag(mover, dx, dy)
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = 500 * scale, 300 * scale
	EM:StartDrag(mover)
	stub.cursor_x, stub.cursor_y = (500 + dx) * scale, (300 + dy) * scale
	EM:UpdateDrag(mover)
	EM:StopDrag(mover)
end

local function At(position) return position.x_off .. ',' .. position.y_off end

test('EM.MarginCorrection keeps a moved rect inside the margin', function()
	local rect = { left = 100, right = 200, bottom = 100, top = 140 }
	local function Correct(dx, dy, inset)
		local mx, my = EM.MarginCorrection(rect, dx, dy, 1000, 600, inset)
		return (mx == 0 and 0 or mx) .. ',' .. (my == 0 and 0 or my)
	end
	eq(Correct(10, -10, 20), '0,0', 'a move that stays inside')
	eq(Correct(-500, -500, 20), '420,420', 'pulled back to 20 in from the left and bottom')
	eq(Correct(2000, 2000, 20), '-1220,-1560', 'and from the right (980) and top (580)')
	eq(Correct(-500, 0, -10), '390,0', 'below 0, it can go that far past')
	-- Too wide or tall for the room: the left and top edges stay inside.
	local wide = { left = 0, right = 1200, bottom = 0, top = 700 }
	local mx, my = EM.MarginCorrection(wide, 0, 0, 1000, 600, 20)
	eq(mx .. ',' .. my, '20,-120', 'left at 20, top at 580')
end)

test("a drag stops at the margin, on every edge, and at the margin's new value", function()
	local frame = Frame(100, 40)
	local mover, position = Mover(frame, { point = 'BOTTOMLEFT', x_off = 300, y_off = 300 })
	Drag(mover, -10, 10)
	eq(At(position), '290,310', 'a drag inside the margin goes where it is dragged')
	Drag(mover, -1000, -1000)
	eq(At(position), '20,20', 'stops 20 in from the left and bottom')
	eq(frame:GetLeft() .. ',' .. frame:GetBottom(), '20,20', 'the frame is placed there')
	Drag(mover, 5000, 5000)
	eq(At(position), '880,540', 'and 20 in from the right and top')
	Drag(mover, 3, 0)
	eq(At(position), '880,540', "can't be pushed further in")

	Set(-10)
	Drag(mover, 5000, 0)
	eq(At(position), '910,540', 'below 0, it goes that far past the edge')
	Set(20)
	eq(#take_errors(), 0, 'no errors')
end)

test('a drag pulls a frame left inside the margin back out of it', function()
	-- Placed 5 in from the top right (a position typed in /sui, or saved before the margin).
	local frame = Frame(100, 40)
	local mover, position = Mover(frame, { point = 'TOPRIGHT', x_off = -5, y_off = -5 })
	Drag(mover, -1, 0)
	eq(At(position), '-20,-20', 'kept 20 in from the right and top')
end)

test("nudges stop at the margin too", function()
	local frame = Frame(100, 40)
	local mover, position = Mover(frame, { point = 'BOTTOMLEFT', x_off = 20, y_off = 25 })
	EM:Nudge(mover, 'LEFT', false)
	eq(At(position), '20,25', "a nudge can't go into the margin")
	EM:Nudge(mover, 'RIGHT', false)
	eq(At(position), '21,25', 'away from it, it moves a pixel')
	EM:Nudge(mover, 'DOWN', true)
	eq(At(position), '21,20', 'Shift+arrow stops at the margin, not 10 past it')
end)

test("a Blizzard frame's mover still keeps to the margin when dragged", function()
	local minimap = Frame(140, 140)
	local mover, position = Mover(minimap, { point = 'TOPRIGHT', x_off = -20, y_off = -20 }, { blizzardFrame = true })
	Drag(mover, 100, 100)
	eq(At(position), '-20,-20', 'the drag stops at the margin')
	check(not minimap:IsClampedToScreen(), 'though SaftUI never clamps it')
end)

test('EM.MarginCorrection takes a margin per side', function()
	local rect = { left = 100, right = 200, bottom = 100, top = 140 }
	local margin = { left = 32, right = 25, top = 60, bottom = 32 } -- ChatFrame1's own clamp
	local mx, my = EM.MarginCorrection(rect, -500, -500, 1000, 600, margin)
	eq(mx .. ',' .. my, '432,432', 'pulled back to 32 in from the left and bottom')
	mx, my = EM.MarginCorrection(rect, 2000, 2000, 1000, 600, margin)
	eq(mx .. ',' .. my, '-1225,-1600', 'and to 25 in from the right (975) and 60 from the top (540)')
end)

------------------------------------------------------------------ holders with a Blizzard frame on them

-- A Blizzard Edit Mode system as the game makes it: clamped to the screen
-- (EditModeSystemTemplate's XML), with the insets its Edit Mode sets from its
-- Selection box (UpdateClampOffsets; none for a box on the frame's edges).
local function ClampedSystem(insets)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetClampedToScreen(true)
	frame:SetClampRectInsets(unpack(insets or { 0, 0, 0, 0 }))
	return frame
end

test("st:GetScreenMargin is the margin plus a frame's reach on each side; a frame SaftUI doesn't keep gets the margin", function()
	local frame = Frame()
	st:KeepInScreenMargin(frame, function() return 8, 2, 16, 4 end)
	eq(table.concat({ st:GetScreenMargin(frame) }, ','), '28,22,36,24', 'left, right, top, bottom')
	eq(table.concat({ st:GetScreenMargin(Frame()) }, ','), '20,20,20,20', 'the margin alone')
end)

test("a held Blizzard frame's own clamp keeps its holder in: a bar 5 and 4 outside its holder stops at the screen's edge with it", function()
	-- A swing timer bar (st:HoldFrame with its 5, 4) is kept on screen by its own
	-- clamp. A holder the margin let reach the edge would leave the bar 5 and 4
	-- short of where it sits around the holder, and the outline past it.
	local holder = Frame(100, 20)
	local mover, position = Mover(holder, { point = 'BOTTOMLEFT', x_off = 300, y_off = 300 })
	local bar = ClampedSystem()
	st:HoldFrame(bar, holder, 5, 4)
	Set(0)
	Drag(mover, -1000, -1000)
	eq(At(position), '5,4', 'the holder stops 5 and 4 in')
	eq(bar:GetLeft() .. ',' .. bar:GetBottom(), '0,0', 'so the bar, around it, reaches the edge and no further')
	eq(Insets(holder), '-5,5,4,-4', "the holder's clamp keeps it there too")
	Set(20)
	Drag(mover, -1000, -1000)
	eq(At(position), '20,20', "a margin wider than the bar's clamp is the margin")
	eq(Insets(holder), Margin(20))
	eq(#take_errors(), 0, 'no errors')
end)

test("below a 0 margin a held frame's holder stops at the edge, where the frame's clamp stops the frame (the buffs)", function()
	local holder = Frame(200, 40)
	local mover, position = Mover(holder, { point = 'TOPRIGHT', x_off = -300, y_off = -300 })
	local buffs = ClampedSystem({ 0, -15, 0, 0 }) -- BuffFrame's box leaves out its collapse button
	st:HoldFrame(buffs, holder)
	Set(-10)
	Drag(mover, 0, 1000)
	eq(At(position), '-300,0', 'stops at the top edge, with the buffs')
	Drag(mover, 1000, 0)
	eq(At(position), '10,0', "15 past the right edge, as far as the buffs' clamp lets them go; the margin's 10 is less")
	Set(20)
	eq(#take_errors(), 0, 'no errors')
end)

test("a held frame's holder takes the frame's clamp again each time Blizzard's Edit Mode sets it", function()
	local holder = Frame()
	Mover(holder)
	local frame = ClampedSystem()
	local insets = { 0, 0, 0, 0 }
	-- EditModeSystemMixin:UpdateClampOffsets, from the box (layout apply, Edit Mode enter).
	function frame:UpdateClampOffsets() self:SetClampRectInsets(unpack(insets)) end
	st:HoldFrame(frame, holder)
	eq(Insets(holder), Margin(20), 'the margin')
	insets = { -32, 25, 60, -32 }
	frame:UpdateClampOffsets()
	eq(Insets(holder), '-32,25,60,-32', "the frame's clamp, where it's wider than the margin")
	eq(#take_errors(), 0, 'no errors')
end)

test('st:GetClampShift, and a drag starts where the game shows the frame, not where its anchor says', function()
	-- Anchored 5 in from the left; the game shows it at the margin, 20 in. The
	-- stubs don't clamp, so the frame reports the rect the game would show.
	local frame = Frame(100, 40)
	local mover, position = Mover(frame, { point = 'BOTTOMLEFT', x_off = 5, y_off = 300 })
	local sx, sy = st:GetClampShift(frame)
	eq(sx .. ',' .. sy, '0,0', 'no shift while it shows where its anchor puts it')
	function frame:GetLeft() return 20 end
	function frame:GetRight() return 120 end
	sx, sy = st:GetClampShift(frame)
	eq(sx .. ',' .. sy, '15,0', 'shown 15 right of where its anchor puts it')

	Drag(mover, 3, 0)
	eq(At(position), '23,300', 'dragged 3 right from where it shows (20), not from its anchor (5)')
	frame.GetLeft, frame.GetRight = nil, nil
	sx, sy = st:GetClampShift(frame)
	eq(sx .. ',' .. sy, '0,0', 'and now its anchor puts it where it shows')
	eq(#take_errors(), 0, 'no errors')
end)

test('st:GetClampShift is nil for a frame with no anchor or an edge it cannot read', function()
	local loose = CreateFrame('Frame', nil, UIParent)
	eq(st:GetClampShift(loose), nil, 'no anchor')
	local SECRET = {}
	local realSecret = issecretvalue
	issecretvalue = function(v) return v == SECRET or realSecret(v) end
	local secret = Frame()
	secret:SetPoint('CENTER')
	function secret:GetRight() return SECRET end -- as Blizzard's Minimap can on retail
	eq(st:GetClampShift(secret), nil, 'a secret edge')
	issecretvalue = realSecret
end)
