local st = SaftUI

-- The derivation of every interaction state from the one Accent
-- (docs/superpowers/specs/2026-11-15-saftui-interaction-states-design.md,
-- section 2): hover, pushed, selected, focus and disabled colors, in three
-- modes (Layers, Tones, Hue-shifted tones), computed in OKLCH, cached, and read
-- through st:StateColor, st:StateSolid, st:StateText, st:StateFade and
-- st:StateAlpha. A plain table, no module: it has no OnColorsChanged of its own.
-- Widgets draw the states through Widgets/states.lua; nothing here draws.
--
-- The pure functions (ST.Oklch ... ST.Derive) read no profile and no frame.
-- Every channel is a number from 0 to 1 (WoW's).
local ST = {}
st.States = ST

local floor, max, min, abs, sqrt, cos, sin, atan2, pi = math.floor, math.max, math.min, math.abs, math.sqrt, math.cos, math.sin, math.atan2, math.pi

-- The text color the pick turns to over a light fill (WCAG contrast decides).
ST.DARK_TEXT = { 17 / 255, 17 / 255, 17 / 255 }
-- A thumb's rest color (Question 1 of the spec: one constant to change).
ST.THUMB_REST = st.BOX_COLORS.edge

ST.MODES = { 'layers', 'tones', 'hue' }
ST.DIRECTIONS = { 'warm', 'cool' }
ST.RANGES = {
	hover = { 0, 0.6 }, pushed = { 0, 0.8 }, selected = { 0, 0.6 }, fade = { 0.1, 1 },
	disabled = { 0.1, 0.9 }, step = { 0.02, 0.2 }, shift = { 0, 60 }, chroma = { 0, 0.3 },
}

local GREY = 1e-7 -- a chroma under this has no hue worth turning

------------------------------------------------------------------ color spaces

local function Clamp01(v)
	if not (v >= 0) then return 0 end -- also a NaN
	if v > 1 then return 1 end
	return v
end

local function Lin(v)
	if v <= 0.04045 then return v / 12.92 end
	return ((v + 0.055) / 1.055) ^ 2.4
end

local function Unlin(v)
	if v <= 0.0031308 then return 12.92 * v end
	return 1.055 * v ^ (1 / 2.4) - 0.055
end

-- x ^ (1/3) keeping the sign: Lua 5.1's ^ gives NaN for a negative base.
local function Cbrt(x)
	if x < 0 then return -((-x) ^ (1 / 3)) end
	return x ^ (1 / 3)
end

-- 0..1 sRGB to OKLCH: L, C and H in radians (-pi to pi).
function ST.Oklch(r, g, b)
	r, g, b = Lin(Clamp01(r)), Lin(Clamp01(g)), Lin(Clamp01(b))
	local l = Cbrt(0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b)
	local m = Cbrt(0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b)
	local s = Cbrt(0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b)
	local L = 0.2104542553 * l + 0.7936177850 * m - 0.0040720468 * s
	local a = 1.9779984951 * l - 2.4285922050 * m + 0.4505937099 * s
	local bb = 0.0259040371 * l + 0.7827717662 * m - 0.8086757660 * s
	return L, sqrt(a * a + bb * bb), atan2(bb, a)
end

-- OKLCH to linear sRGB, unclamped.
local function Linear(L, C, H)
	local a, b = C * cos(H), C * sin(H)
	local l = L + 0.3963377774 * a + 0.2158037573 * b
	local m = L - 0.1055613458 * a - 0.0638541728 * b
	local s = L - 0.0894841775 * a - 1.2914855480 * b
	l, m, s = l * l * l, m * m * m, s * s * s
	return 4.0767416621 * l - 3.3077115913 * m + 0.2309699292 * s,
		-1.2684380046 * l + 2.6097574011 * m - 0.3413193965 * s,
		-0.0041960863 * l - 0.7034186147 * m + 1.7076147010 * s
end

-- OKLCH to sRGB, each channel clamped to 0..1 (no fit).
function ST.Srgb(L, C, H)
	local r, g, b = Linear(L, C, H)
	return Clamp01(Unlin(r)), Clamp01(Unlin(g)), Clamp01(Unlin(b))
end

-- Whether every linear channel of (L, C, H) is in [-0.0005, 1.0005].
function ST.InGamut(L, C, H)
	local r, g, b = Linear(L, C, H)
	return r >= -0.0005 and r <= 1.0005 and g >= -0.0005 and g <= 1.0005 and b >= -0.0005 and b <= 1.0005
end

-- C, or the most chroma at L and H that is in gamut (24 halvings).
function ST.FitChroma(L, C, H)
	if ST.InGamut(L, C, H) then return C end
	local lo, hi = 0, C
	for _ = 1, 24 do
		local mid = (lo + hi) / 2
		if ST.InGamut(L, mid, H) then lo = mid else hi = mid end
	end
	return lo
end

-- x * (1 - a) + y * a per channel, in sRGB (as BLEND draws).
function ST.Mix(r1, g1, b1, r2, g2, b2, a)
	return r1 * (1 - a) + r2 * a, g1 * (1 - a) + g2 * a, b1 * (1 - a) + b2 * a
end

local function Luminance(r, g, b)
	return 0.2126 * Lin(Clamp01(r)) + 0.7152 * Lin(Clamp01(g)) + 0.0722 * Lin(Clamp01(b))
end

-- WCAG 2 contrast of two colors.
function ST.Contrast(r1, g1, b1, r2, g2, b2)
	local y1, y2 = Luminance(r1, g1, b1), Luminance(r2, g2, b2)
	return (max(y1, y2) + 0.05) / (min(y1, y2) + 0.05)
end

-- The text over a composite: Text > Normal (r, g, b given) unless the dark
-- text has the higher contrast. Ties go to the light.
function ST.PickText(lr, lg, lb, r, g, b)
	local dark = ST.DARK_TEXT
	if ST.Contrast(lr, lg, lb, r, g, b) >= ST.Contrast(dark[1], dark[2], dark[3], r, g, b) then
		return lr, lg, lb
	end
	return dark[1], dark[2], dark[3]
end

------------------------------------------------------------------ the tones

local WARM, COOL = 100 * pi / 180, 280 * pi / 180

-- The tone k steps from (r, g, b): k = +1 lighter, -1 darker. settings: mode,
-- step, shift, chroma, direction. Layers returns r, g, b.
function ST.Tone(r, g, b, k, settings)
	if settings.mode == 'layers' or k == 0 then return Clamp01(r), Clamp01(g), Clamp01(b) end
	local L, C, H = ST.Oklch(r, g, b)
	L = Clamp01(L + k * settings.step)
	if settings.mode == 'hue' and C >= GREY then
		local target = ((k > 0) == (settings.direction == 'warm')) and WARM or COOL
		local d = (target - H) % (2 * pi) -- Lua's % is in [0, 2 pi)
		if d > pi then d = d - 2 * pi end
		local rot = min(abs(d), settings.shift * pi / 180 * abs(k))
		H = H + (d > 0 and 1 or d < 0 and -1 or 0) * rot
		C = max(0, C * (1 + (k > 0 and -1 or 1) * settings.chroma * abs(k)))
	end
	return ST.Srgb(L, ST.FitChroma(L, C, H), H)
end

------------------------------------------------------------------ the derived table

-- What every holder makes once and ST.Derive fills in place: the named colors
-- ({ r, g, b, a } each), the tones (light is T+, dark is T-, accent is A) and
-- the strengths (h, p, s, f, d) and mode they came from.
function ST.NewDerived()
	return {
		hover = { 0, 0, 0, 0 }, pushed = { 0, 0, 0, 0 }, fill = { 0, 0, 0, 0 }, fillHover = { 0, 0, 0, 0 },
		edge = { 0, 0, 0, 1 }, edgeHover = { 0, 0, 0, 1 },
		light = { 0, 0, 0 }, dark = { 0, 0, 0 }, accent = { 0, 0, 0 },
		h = 0, p = 0, s = 0, f = 1, d = 1, mode = 'tones',
	}
end

local function Put(c, r, g, b, a)
	c[1], c[2], c[3] = r, g, b
	if a then c[4] = a end
end

-- The named colors for the Accent (r, g, b) under settings, into derived: no
-- table made.
function ST.Derive(r, g, b, settings, derived)
	r, g, b = Clamp01(r), Clamp01(g), Clamp01(b)
	local lr, lg, lb = ST.Tone(r, g, b, 1, settings)
	local dr, dg, db = ST.Tone(r, g, b, -1, settings)
	local h, p, s = settings.hover, settings.pushed, settings.selected
	Put(derived.accent, r, g, b)
	Put(derived.light, lr, lg, lb)
	Put(derived.dark, dr, dg, db)
	Put(derived.hover, lr, lg, lb, h)
	Put(derived.pushed, dr, dg, db, p)
	Put(derived.fill, r, g, b, s)
	Put(derived.fillHover, lr, lg, lb, s)
	Put(derived.edge, r, g, b, 1)
	Put(derived.edgeHover, lr, lg, lb, 1)
	derived.h, derived.p, derived.s, derived.f, derived.d = h, p, s, settings.fade, settings.disabled
	derived.mode = settings.mode
	return derived
end

------------------------------------------------------------------ the settings

local scratch = {} -- the one table Settings reads the profile into

local function Within(value, default, range)
	if type(value) ~= 'number' or value ~= value then return default end
	return min(max(value, range[1]), range[2])
end

local function Word(value, default, words)
	for _, word in ipairs(words) do
		if value == word then return value end
	end
	return default
end

-- The profile's theme.states, clamped into one scratch table (a hand edit, or a
-- later version's mode, never reaches the math). Read it before the next call:
-- it is overwritten.
function ST.Settings()
	local defaults = st.defaults.theme.states
	local profile = st.config and st.config.profile
	local saved = profile and profile.theme and profile.theme.states
	if type(saved) ~= 'table' then saved = defaults end
	for key, range in pairs(ST.RANGES) do
		scratch[key] = Within(saved[key], defaults[key], range)
	end
	scratch.mode = Word(saved.mode, defaults.mode, ST.MODES)
	scratch.direction = Word(saved.direction, defaults.direction, ST.DIRECTIONS)
	return scratch
end

------------------------------------------------------------------ the cache

-- One derived table, current while the Accent's r, g and b, the profile's
-- states table and ST.serial are the ones it was computed from. Every read
-- checks those five and computes again in place when one differs: once per
-- change, whoever changed it (the Accent row, the picker, a profile switch).
ST.cache = ST.NewDerived()
ST.cache.from = { r = nil, g = nil, b = nil, states = nil, serial = nil }
ST.serial = 0

function ST.Current()
	local cache = ST.cache
	local from = cache.from
	local accent = st:Color('accent')
	-- a channel that is NaN (never equal to itself, so the stamp would never hold) reads as 0
	local r, g, b = accent.r, accent.g, accent.b
	if r ~= r then r = 0 end
	if g ~= g then g = 0 end
	if b ~= b then b = 0 end
	local profile = st.config and st.config.profile
	local states = profile and profile.theme and profile.theme.states
	if from.r ~= r or from.g ~= g or from.b ~= b or from.states ~= states or from.serial ~= ST.serial then
		ST.Derive(r, g, b, ST.Settings(), cache)
		from.r, from.g, from.b, from.states, from.serial = r, g, b, states, ST.serial
	end
	return cache
end

-- A derivation setting changed (its set or reset): the cache is stale, and
-- every state follower hears the Accent's group.
function ST.Changed()
	ST.serial = ST.serial + 1
	st:ColorChanged('accent')
end

------------------------------------------------------------------ the readers

local NAMED = { hover = true, pushed = true, fill = true, fillHover = true, edge = true, edgeHover = true }

-- 'hover', 'pushed', 'fill', 'fillHover', 'edge' or 'edgeHover' as r, g, b, a.
-- derived is optional: a preview's own table (ST.Derive filled).
function st:StateColor(name, derived)
	if not NAMED[name] then error('SaftUI: no state color ' .. tostring(name), 2) end
	local c = (derived or ST.Current())[name]
	return c[1], c[2], c[3], c[4]
end

-- A thumb's or knob's whole fill under 'hover' or 'pushed', from its rest color:
-- the tone under Tones and Hue-shifted tones, the Accent mixed in under Layers.
function st:StateSolid(name, r, g, b, derived)
	if name ~= 'hover' and name ~= 'pushed' then error('SaftUI: no state solid ' .. tostring(name), 2) end
	derived = derived or ST.Current()
	if derived.mode == 'layers' then
		local a = derived.accent
		return ST.Mix(r, g, b, a[1], a[2], a[3], name == 'hover' and 0.6 or 0.85)
	end
	local c = name == 'hover' and derived.light or derived.dark
	return c[1], c[2], c[3]
end

-- The color a label takes over a body (r, g, b) under a state's pieces: Text >
-- Normal or the dark text, by contrast over the composite under its start:
-- the body, then the Layer, then the Fill at its strongest. name is 'rest'
-- (the body alone), 'hover', 'pushed', 'fill' (selected) or 'fillHover'
-- (selected + hover: the hover layer, then the hover fill).
function st:StateText(name, r, g, b, derived)
	derived = derived or ST.Current()
	if name == 'hover' then
		local c = derived.hover
		r, g, b = ST.Mix(r, g, b, c[1], c[2], c[3], c[4])
	elseif name == 'pushed' then
		local c = derived.pushed
		r, g, b = ST.Mix(r, g, b, c[1], c[2], c[3], c[4])
	elseif name == 'fill' then
		local c = derived.fill
		r, g, b = ST.Mix(r, g, b, c[1], c[2], c[3], c[4])
	elseif name == 'fillHover' then
		local c = derived.hover
		r, g, b = ST.Mix(r, g, b, c[1], c[2], c[3], c[4])
		c = derived.fillHover
		r, g, b = ST.Mix(r, g, b, c[1], c[2], c[3], c[4])
	elseif name ~= 'rest' then
		error('SaftUI: no state text ' .. tostring(name), 2)
	end
	local normal = st:Color('text', 'normal')
	return ST.PickText(normal.r, normal.g, normal.b, r, g, b)
end

-- The Fill's right texture coordinate: the fade ends 1 / f of the way across.
function st:StateFade(derived)
	return 1 / (derived or ST.Current()).f
end

-- The Disabled opacity.
function st:StateAlpha(derived)
	return (derived or ST.Current()).d
end
