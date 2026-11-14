-- The world SaftUI-Tracker's row tests run in (rows_test.lua, refresh_test.lua):
-- tracker_world.lua's, switched on, with the quest log helpers and what a test
-- of the rows reads and counts. Not a test (no _test suffix); a test loads it
-- with `local RW = load_test_file('tracker/rows_world.lua')`.
--
--   RW.TW, RW.Q          tracker_world.lua and quest_log.lua
--   RW.world(opts)       TW.world with the switch on and the mouse away; the
--                        first refresh (the build's) already run
--   RW.both(name, fn)    one case per client: fn(st, TR, client); fails on an
--                        error the game would have reported
--   RW.later(seconds)    time passes: stub.time moves on, due timers run
--   RW.counter()         { frames, texts } made and set from now on, by
--                        wrapping CreateFrame and the font strings' SetText:
--                        c.frames, c.texts, c.reset(), c.stop()
--   RW.rows(TR, kind)    the rows in use of a kind, in the order they sit
--   RW.zone(TR, key), RW.quest(TR, id)   one row
--   RW.text(fs)          a font string's text, '' for none
--   RW.color(fs)         'r g b' of its text color, to two decimals
--   RW.rgb(color)        the same for a Color object or an { r, g, b } table
--   RW.rect(frame)       'left top width height' of a frame, to the pixel
--   RW.mouse_on(frame), RW.mouse_off()
--   RW.log(entries, watched, extra)   Q.set, then the tracker's next refresh
local TW = load_test_file('tracker/tracker_world.lua')
local Q = load_test_file('tracker/quest_log.lua')

local RW = { TW = TW, Q = Q }

function RW.mouse_off()
	stub.cursor_x, stub.cursor_y = -1000, -1000
end

function RW.mouse_on(frame)
	local x, y = frame:GetCenter()
	local scale = frame:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = x * scale, y * scale
end

function RW.world(opts)
	opts = opts or {}
	opts.on = true
	RW.mouse_off()
	local st, TR = TW.world(opts)
	-- The build's own refresh, on the next frame.
	stub.time = 0
	stub.run_timers()
	return st, TR
end

function RW.both(name, fn)
	for _, client in ipairs({ 'forever', 'retail' }) do
		test(name .. ' [' .. client .. ']', function()
			local st, TR = RW.world({ client = client })
			fn(st, TR, client)
			eq(#take_errors(), 0, client .. ': no error reported')
		end)
	end
end

function RW.later(seconds)
	stub.time = stub.time + seconds
	return stub.run_timers()
end

function RW.counter()
	local counter = { frames = 0, texts = 0 }
	local create = CreateFrame
	local methods = getmetatable(UIParent:CreateFontString(nil, 'OVERLAY')).__index
	local set_text = methods.SetText
	local active = true
	CreateFrame = function(...)
		if active then counter.frames = counter.frames + 1 end
		return create(...)
	end
	methods.SetText = function(self, ...)
		if active then counter.texts = counter.texts + 1 end
		return set_text(self, ...)
	end
	function counter.reset() counter.frames, counter.texts = 0, 0 end
	function counter.stop()
		active = false
		CreateFrame = create
		methods.SetText = set_text
	end
	return counter
end

function RW.rows(TR, kind)
	local rows = {}
	for _, row in ipairs(TR.pools[kind].rows) do
		if row.inUse then rows[#rows + 1] = row end
	end
	table.sort(rows, function(a, b)
		return (select(5, a:GetPoint(1)) or 0) > (select(5, b:GetPoint(1)) or 0)
	end)
	return rows
end

function RW.zone(TR, key) return TR:GetRow('zone', key) end
function RW.quest(TR, id) return TR:GetQuestRow(id) end

function RW.text(fs)
	return fs:GetText() or ''
end

function RW.color(fs)
	local r, g, b = fs:GetTextColor()
	return ('%.2f %.2f %.2f'):format(r, g, b)
end

function RW.rgb(color)
	if color.GetRGB then return ('%.2f %.2f %.2f'):format(color:GetRGB()) end
	return ('%.2f %.2f %.2f'):format(color.r, color.g, color.b)
end

function RW.rect(frame)
	local left, top = frame:GetLeft(), frame:GetTop()
	return ('%.0f %.0f %.0f %.0f'):format(left, top, frame:GetWidth(), frame:GetHeight())
end

function RW.log(entries, watched, extra)
	Q.set(entries, watched, extra)
end

return RW
