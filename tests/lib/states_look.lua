-- Reading a state frame's look in a test, and the expected values the interaction
-- states' tests compare it with (SaftUI-Core/Widgets/states.lua's st:StateLook is
-- the seam; Media/states.lua is the cache). Not a test (no _test suffix); it
-- makes no global. Load it, after load_core_helpers() (or T.client), with
--
--   local SL = load_test_file('lib/states_look.lua')
--
--   SL.rgb(t)             '0.36,0.78,1.00': t's r, g and b (a table of StateLook: layer, fill,
--                         edge, text, solid ...) rounded to 2 places
--   SL.bytes(t)           'RRGGBB': each channel floor(v * 255 + 0.5)
--   SL.near(t, 'rrggbb')  whether t's bytes are each within 1 of the hex: for a color derived from the
--                         shipped Accent, CreateColor(0, 0.68, 0.94), which is not #00adf0 to the byte
--                         (its tones are #5bc6ff and #0093cc); the spec's exact vectors set the preset first
--   SL.hover_over(st, body)  'RRGGBB': the cache's hover composited over body (a color table
--                         { r, g, b } or a grey number), for the expected value of a label's
--                         or a body's color under the mouse
--   SL.each_look(fn)      runs fn(name) under Thick, Thin and Blizzard ('thick', 'thin',
--                         'blizzard'): SaftUI's theme switched as the Theme tab switches it
--                         (T.theme: every drawn frame drawn again); left on Thick
local T = load_test_file('lib/theme_helpers.lua')

local SL = {}

function SL.rgb(t) return ('%.2f,%.2f,%.2f'):format(t.r, t.g, t.b) end

local function byte(v) return math.floor(v * 255 + 0.5) end

function SL.bytes(t) return ('%02x%02x%02x'):format(byte(t.r), byte(t.g), byte(t.b)) end

function SL.near(t, hex)
	for i = 1, 5, 2 do
		local want = tonumber(hex:sub(i, i + 1), 16)
		local got = byte(i == 1 and t.r or i == 3 and t.g or t.b)
		if math.abs(got - want) > 1 then return false end
	end
	return true
end

function SL.hover_over(st, body)
	local r, g, b
	if type(body) == 'number' then r, g, b = body, body, body else r, g, b = body[1], body[2], body[3] end
	local h = { st:StateColor('hover') }
	r, g, b = st.States.Mix(r, g, b, h[1], h[2], h[3], h[4])
	return SL.bytes({ r = r, g = g, b = b })
end

function SL.each_look(fn)
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		T.theme(name)
		fn(name)
	end
	T.theme('thick')
end

return SL
