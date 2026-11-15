-- The scale model (SaftUI-Core/uiscale.lua) and the pixel helpers beside
-- st:GetPixelSize (SaftUI-Core/api.lua), on the core shell.

local function screen(w, h) return { width = w, height = h } end

local function world()
	reset_world()
	return SaftUI
end

local function close(a, b, tolerance)
	return a ~= nil and b ~= nil and math.abs(a - b) < (tolerance or 1e-9)
end

test('Resolve over the worked values', function()
	local st = world()
	local R = st.UIScale.Resolve
	local auto = { mode = 'auto', size = 1 }
	-- { W, H, k, lineWeight }; the units, uiScale and pixel are checked below
	-- and from k.
	local rows = {
		{ 1366, 768, 0.75, 1 }, { 1920, 1080, 0.75, 1 }, { 1920, 1200, 0.833333333, 1 },
		{ 2560, 1377, 1, 1 }, { 3440, 1440, 1, 1 }, { 2560, 1600, 1.111111111, 1 },
		{ 3024, 1964, 1.363888889, 1 }, { 3456, 2234, 1.551388889, 2 },
		{ 3840, 2160, 1.5, 2 }, { 5120, 2880, 2, 2 },
	}
	for _, row in ipairs(rows) do
		local w, h = row[1], row[2]
		local r = R(auto, screen(w, h))
		local where = ('%dx%d'):format(w, h)
		check(r ~= nil, where .. ' resolves')
		check(close(r.k, row[3], 1e-6), where .. ' k ' .. tostring(r.k))
		check(close(r.uiScale, 768 / h * r.k), where .. ' uiScale is 768 / H * k')
		check(close(r.unitsTall, 768 / r.uiScale), where .. ' unitsTall is 768 / uiScale')
		check(close(r.unitsWide, w * r.unitsTall / h), where .. ' unitsWide')
		check(close(r.pixel, 1 / r.k), where .. ' pixel is 1 / k')
		eq(r.lineWeight, row[4], where .. ' lineWeight')
		check(close(r.line, r.lineWeight * r.pixel), where .. ' line')
		eq(r.width, w, where .. ' width')
		eq(r.height, h, where .. ' height')
		eq(r.mode, 'auto', where .. ' mode')
	end
	local r = R(auto, screen(1366, 768))
	check(close(r.unitsWide, 1821.3333333, 1e-6) and close(r.unitsTall, 1024), '1366x768 units')
	r = R(auto, screen(1920, 1080))
	check(close(r.unitsWide, 2560) and close(r.unitsTall, 1440), '1920x1080 units')
	r = R(auto, screen(1920, 1200))
	check(close(r.unitsWide, 2304) and close(r.unitsTall, 1440), '1920x1200 units')
	r = R(auto, screen(2560, 1377))
	check(close(r.unitsWide, 2560) and close(r.unitsTall, 1377), '2560x1377 units (snapped to 1)')
	r = R(auto, screen(3440, 1440))
	check(close(r.unitsWide, 3440) and close(r.unitsTall, 1440), '3440x1440 units')
	r = R(auto, screen(2560, 1600))
	check(close(r.k, 1.1111111, 1e-6) and close(r.pixel, 0.9, 1e-9), '2560x1600 k and pixel')
	r = R(auto, screen(3024, 1964))
	check(close(r.k, 1.3638889, 1e-6) and close(r.unitsTall, 1964 / 1.3638889, 1e-3), '3024x1964')
	r = R(auto, screen(3456, 2234))
	check(close(r.k, 1.5513889, 1e-6) and close(r.unitsWide, 2227.6, 0.1) and close(r.unitsTall, 1440, 0.5), '3456x2234')
	r = R(auto, screen(3840, 2160))
	check(close(r.k, 1.5) and close(r.unitsWide, 2560) and close(r.unitsTall, 1440), '3840x2160')
	r = R(auto, screen(5120, 2880))
	check(close(r.k, 2) and close(r.unitsWide, 2560) and close(r.unitsTall, 1440), '5120x2880')
end)

test("the owner's 1440p is today's float: uiScale rawequal 768 / 1440, k the integer 1, pixel and line exactly 1", function()
	local st = world()
	local r = st.UIScale.Resolve({ mode = 'auto', size = 1 }, screen(2560, 1440))
	check(rawequal(r.uiScale, 768 / 1440), 'uiScale is 768 / 1440 to the bit')
	check(rawequal(r.k, 1), 'k is 1')
	check(rawequal(r.pixel, 1) and rawequal(r.line, 1) and rawequal(r.lineWeight, 1), 'pixel, lineWeight and line are 1')
	eq(math.floor(r.k), r.k, 'k stays an integer value')
end)

test('Pixel for pixel is k 1 and 768 / H on any screen, to the bit', function()
	local st = world()
	for _, h in ipairs({ 768, 1080, 1200, 1377, 1440, 1600, 1964, 2160, 2234, 2880 }) do
		local r = st.UIScale.Resolve({ mode = 'pixel', size = 1.3 }, screen(h * 2, h))
		check(rawequal(r.k, 1), h .. ': k 1 whatever the size')
		check(rawequal(r.uiScale, 768 / h), h .. ': uiScale 768 / H')
		check(rawequal(r.pixel, 1) and rawequal(r.line, 1), h .. ': one pixel, one line')
		eq(r.mode, 'pixel', h .. ': mode')
	end
end)

test('the snap band in whole pixels: 1367 and 1513 unsnapped, 1368 and 1512 at 1, 2808 and 2952 at 2, 2807 unsnapped', function()
	local st = world()
	local function auto(h) return st.UIScale.Resolve({ mode = 'auto', size = 1 }, screen(h * 2, h)).k end
	check(close(auto(1367), 1367 / 1440), '1367 unsnapped')
	check(close(auto(1513), 1513 / 1440), '1513 unsnapped')
	check(rawequal(auto(1368), 1), '1368 snaps to 1')
	check(rawequal(auto(1512), 1), '1512 snaps to 1')
	check(rawequal(auto(2808), 2), '2808 snaps to 2')
	check(rawequal(auto(2952), 2), '2952 snaps to 2')
	check(close(auto(2807), 2807 / 1440), '2807 unsnapped')
end)

test('the floor: 768 and 900 high are 0.75', function()
	local st = world()
	eq(st.UIScale.Resolve({ mode = 'auto', size = 1 }, screen(1366, 768)).k, 0.75, '768')
	eq(st.UIScale.Resolve({ mode = 'auto', size = 1 }, screen(1600, 900)).k, 0.75, '900 (0.625 floored)')
	eq(st.UIScale.Resolve({ mode = 'auto', size = 1 }, screen(1600, 900)).auto, 0.75, 'its automatic part')
end)

test('the UI size: 0.69 is 0.70, 1.6 is 1.50, 0.93 is 0.95; sizeMax 1.30 at 768 high, 1.45 at 863, 1.50 at 864 and 1080', function()
	local st = world()
	local R = st.UIScale.Resolve
	local function size(s, h) return R({ mode = 'auto', size = s }, screen(h * 2, h)).size end
	check(close(size(0.69, 1440), 0.70), '0.69 is 0.70')
	check(close(size(1.6, 1440), 1.5), '1.6 is 1.50')
	check(close(size(0.93, 1440), 0.95), '0.93 is 0.95')
	check(close(size(1, 1440), 1), '1 stays')
	local function max(h) return R({ mode = 'auto', size = 1 }, screen(h * 2, h)).sizeMax end
	check(close(max(768), 1.30), 'sizeMax 1.30 at 768')
	check(close(max(863), 1.45), 'sizeMax 1.45 at 863')
	check(close(max(864), 1.50), 'sizeMax 1.50 at 864')
	check(close(max(1080), 1.50), 'sizeMax 1.50 at 1080')
	check(close(size(1.5, 768), 1.30), 'a size over the screen\'s max is held to it')
	check(close(R({ mode = 'auto', size = 0.75 }, screen(2560, 1440)).k, 0.75), 'k is auto * size')
end)

test("The game's UI scale: 0.64 at 1440 high is k 1.2 with 1 pixel lines; 1.15 at 2160 is k 3.234 with 3; no game scale is nil", function()
	local st = world()
	local R = st.UIScale.Resolve
	local r = R({ mode = 'game', size = 1 }, screen(2560, 1440), 0.64)
	check(close(r.k, 1.2) and r.lineWeight == 1, '0.64 at 1440')
	check(close(r.uiScale, 0.64), "uiScale is the game's")
	check(close(r.pixel, 1 / 1.2), 'pixel')
	r = R({ mode = 'game', size = 1 }, screen(3840, 2160), 1.15)
	check(close(r.k, 3.234375) and r.lineWeight == 3, '1.15 at 2160')
	check(close(r.uiScale, 1.15), "uiScale is the game's")
	eq(R({ mode = 'game', size = 1 }, screen(2560, 1440)), nil, 'no game scale is nil')
	eq(R({ mode = 'game', size = 1 }, screen(2560, 1440), 0), nil, 'a game scale of 0 is nil')
	eq(R({ mode = 'game', size = 1 }, screen(2560, 1440), -1), nil, 'a negative game scale is nil')
	check(R({ mode = 'auto', size = 1 }, screen(2560, 1440)) ~= nil, 'auto needs no game scale')
end)

test('a malformed choice (Review Focus 5)', function()
	local st = world()
	local U = st.UIScale
	for _, bad in ipairs({ true, 'auto', 5 }) do
		local n = U.Normalize(bad)
		eq(n.mode, 'auto', tostring(bad) .. ': mode')
		eq(n.size, 1, tostring(bad) .. ': size')
	end
	local n = U.Normalize(nil)
	check(n.mode == 'auto' and n.size == 1, 'nil is the default')
	eq(U.Normalize({ mode = 'huge' }).mode, 'auto', 'an unknown mode is auto')
	eq(U.Normalize({ size = '90' }).size, 1, 'a size that is not a number is 1')
	eq(U.Normalize({ mode = 'game' }).mode, 'game', 'a known mode stays')
	local a, b = U.Normalize(nil), U.Normalize(nil)
	check(a ~= b and a ~= U.DEFAULT, 'a fresh table each time')
	local r = U.Resolve({ size = 5 }, screen(2560, 1440))
	check(close(r.size, 1.5), 'size 5 is held to 1.5')
	r = U.Resolve({ mode = 'game', size = 0 }, screen(2560, 1440), 0.64)
	check(close(r.size, 0.7), 'size 0 is held to 0.7')

	local choice = { mode = 'huge', size = '90', extra = 1 }
	U.Normalize(choice)
	U.Resolve(choice, screen(2560, 1440))
	local keys = 0
	for _ in pairs(choice) do keys = keys + 1 end
	check(keys == 3 and choice.mode == 'huge' and choice.size == '90' and choice.extra == 1, 'the table passed in is unchanged')
end)

test('a screen with no height: ReadScreen and Resolve give nil, Start and SetTokens leave everything as it is', function()
	local st = world()
	local U = st.UIScale
	stub.screen_width, stub.screen_height = 3200, 1800
	UIParent:SetScale(0.9)
	st.pixel, st.lineWeight, st.line = 1.25, 2, 2.5
	stub.screen_height = nil
	eq(U.ReadScreen(), nil, 'ReadScreen gives nil')
	eq(U.Resolve({ mode = 'auto', size = 1 }, U.ReadScreen()), nil, 'Resolve gives nil')
	eq(U.Resolve({ mode = 'auto', size = 1 }, {}), nil, 'and for a table with no height')
	U:Start()
	eq(UIParent:GetScale(), 0.9, 'Start leaves the scale')
	U:SetTokens()
	check(st.pixel == 1.25 and st.lineWeight == 2 and st.line == 2.5, 'SetTokens leaves the tokens')
	stub.screen_height = 0
	eq(U.ReadScreen(), nil, 'a height of 0 is nil too')
end)

test('the line weight at its edges, from the choice and from UIParent read back (Review Focus 1)', function()
	local st = world()
	local U = st.UIScale
	eq(U.LineWeight(1.4999999999999998), 2, '1.4999999999999998')
	eq(U.LineWeight(1.49), 1, '1.49')
	eq(U.LineWeight(2.49999), 3, '2.49999')
	eq(U.LineWeight(0.525), 1, '0.525')
	eq(U.Resolve({ mode = 'auto', size = 0.75 }, screen(5120, 2880)).lineWeight, 2, '5120x2880 at 75% (k 1.5)')
	eq(U.Resolve({ mode = 'auto', size = 1 }, screen(3840, 2160)).lineWeight, 2, '3840x2160 at 100%')
	stub.screen_width, stub.screen_height = 3840, 2160
	UIParent:SetScale((768 / 2160) * 1.5)
	U:SetTokens()
	eq(st.lineWeight, 2, 'a world at 3840x2160 read back from UIParent')
end)

test('the tokens: 1, 1, 1 at load and at k 1; at 0.75 pixel 4/3 and line == pixel; at 1.55 line == 2 * pixel', function()
	local st = world()
	check(st.pixel == 1 and st.lineWeight == 1 and st.line == 1, 'after the shell loads')
	use_scale(1)
	local pixel, weight, line = st.UIScale:SetTokens()
	check(pixel == 1 and weight == 1 and line == 1, 'at k 1: returned')
	check(st.pixel == 1 and st.lineWeight == 1 and st.line == 1, 'at k 1: set')
	use_scale(0.75)
	check(close(st.pixel, 4 / 3) and st.lineWeight == 1 and close(st.line, st.pixel), 'at 0.75')
	use_scale(1.55)
	check(close(st.pixel, 1 / 1.5513888889, 1e-6) and st.lineWeight == 2 and close(st.line, 2 * st.pixel), 'at 1.55')
	eq(st.UIScale.DESIGN_HEIGHT, 1440, 'the design height')
	eq(st.UIScale.SNAP, 72, 'the snap')
	eq(st.UIScale.FLOOR, 0.75, 'the floor')
	eq(st.UIScale.SIZE.min, 0.70, 'the least size')
	eq(st.UIScale.SIZE.max, 1.50, 'the most size')
	eq(st.UIScale.SIZE.step, 0.05, 'the step')
	eq(table.concat(st.UIScale.MODES, ','), 'auto,pixel,game', 'the modes')
	check(st.UIScale.DEFAULT.mode == 'auto' and st.UIScale.DEFAULT.size == 1, 'the default')
end)

test("the helpers at 0.75 and on a frame with a scale of its own; at k 1 every one is today's whole number", function()
	local st = world()
	use_scale(0.75)
	local pixel = 4 / 3
	check(close(st:GetLineSize(UIParent), pixel), 'GetLineSize(UIParent)')
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetScale(0.8)
	check(close(st:GetLineSize(frame), pixel / 0.8), 'GetLineSize on a frame at 0.8')
	local function near4(a, b) return close(a, b, 1e-4) end
	check(near4(st:RoundToPixel(0.3), 0), 'RoundToPixel(0.3) is 0')
	eq(st:RoundToPixel(0.3), 0, 'a whole 0, no -0')
	check(near4(st:RoundToPixel(0.3, nil, 1), pixel), 'RoundToPixel(0.3, nil, 1)')
	eq(st:RoundToPixel(0, nil, 1), 0, 'zero stays zero under a minimum')
	check(near4(st:RoundToPixel(-0.3, nil, 1), -pixel), 'RoundToPixel(-0.3, nil, 1) keeps its sign')
	check(near4(st:RoundToPixel(2.2, nil, 1), 2 * pixel), 'a value over its minimum is as before')
	check(near4(st:FloorToPixel(2), pixel), 'FloorToPixel(2)')
	check(near4(st:CeilToPixel(2), 2 * pixel), 'CeilToPixel(2)')
	check(near4(st:FloorToPixel(8 / 3 - 1e-9), 8 / 3), 'FloorToPixel just under a pixel stays on it')
	check(near4(st:CeilToPixel(8 / 3 + 1e-9), 8 / 3), 'CeilToPixel just over a pixel stays on it')
	check(near4(st:EvenPixels(45), 34 * pixel), 'EvenPixels(45) is 34 pixels')
	check(near4(st:EvenPixels(2 * pixel * 3), 3 * 2 * pixel), 'an even count stays')
	check(near4(st:EvenPixels(pixel), 2 * pixel), 'one pixel goes to two')
	check(near4(st:FloorToPixel(-0.5), -pixel), 'Floor of a negative goes down')

	use_scale(1)
	eq(st:EvenPixels(45), 46, 'k 1: EvenPixels(45)')
	eq(st:EvenPixels(44), 44, 'k 1: EvenPixels(44)')
	check(rawequal(st:RoundToPixel(5), 5), 'k 1: RoundToPixel(5)')
	check(rawequal(st:FloorToPixel(5), 5), 'k 1: FloorToPixel(5)')
	check(rawequal(st:CeilToPixel(5), 5), 'k 1: CeilToPixel(5)')
	eq(st:RoundToPixel(0.3, nil, 1), 1, 'k 1: a minimum of a pixel')
	eq(st:GetLineSize(UIParent), 1, 'k 1: the line')
	stub.screen_height = nil
	eq(st:GetLineSize(UIParent), nil, 'no screen: GetLineSize is nil')
	eq(st:FloorToPixel(7), 7, 'no screen: the value as it is')
	eq(st:EvenPixels(7), 7, 'no screen: EvenPixels as it is')
end)

test("use_scale(k): each k gives its screen and Resolve's k, without resetting the world; another k errors", function()
	local st = world()
	st.marker = true
	local expect = { [0.75] = { 1920, 1080, 0.75 }, [1] = { 1920, 1080, 1 }, [1.25] = { 3200, 1800, 1.25 }, [1.55] = { 3456, 2234, 1.5513888889 } }
	for k, row in pairs(expect) do
		local r = use_scale(k)
		eq(stub.screen_width, row[1], k .. ': width')
		eq(stub.screen_height, row[2], k .. ': height')
		check(close(r.k, row[3], 1e-6), k .. ': k')
		check(close(UIParent:GetScale(), r.uiScale), k .. ': UIParent')
		check(close(st.pixel, r.pixel, 1e-9), k .. ': tokens')
		eq(st.marker, true, k .. ': the world is not reset')
	end
	eq(SCALE_SCREENS[1][3], 'pixel', 'k 1 is Pixel for pixel')
	eq(SCALE_SCREENS[0.75][3], 'auto', 'k 0.75 is automatic')
	check(not pcall(use_scale, 2), 'another k is an error')
	check(not pcall(use_scale, nil), 'nil is an error')
end)

test("the game hands scales back in single precision: tokens at a whole k are exactly whole (Fix round 1, I1)", function()
	local st = world()
	-- 768 / 1440 as the game reads it back, rounded to the nearest single
	-- (0.53333336, a pixel of 0.99999995, k a hair over 1), and the single
	-- below it (0.5333333, k a hair under 1): both sides of a whole k snap.
	for _, single in ipairs({ 0.5333333611488342, 0.53333330154419 }) do
		stub.screen_width, stub.screen_height = 2560, 1440
		UIParent.GetEffectiveScale = function() return single end
		st.pixel, st.lineWeight, st.line = 9, 9, 9
		st.UIScale:SetTokens()
		local where = tostring(single) .. ': '
		check(rawequal(st.pixel, 1) and rawequal(st.lineWeight, 1) and rawequal(st.line, 1), where .. 'the tokens are exactly 1 1 1: ' .. tostring(st.pixel))
		check(rawequal(st:GetPixelSize(UIParent), 1), where .. 'GetPixelSize is exactly 1')
		check(rawequal(st:GetLineSize(UIParent), 1), where .. 'GetLineSize is exactly 1')
		check(rawequal(st:RoundToPixel(25), 25), where .. 'a helper gives 25 for 25 units, not 24.999998')
		check(rawequal(st:FloorToPixel(25), 25) and rawequal(st:CeilToPixel(25), 25), where .. 'and Floor and Ceil')
		-- k 2, from 5120 x 2880 with the same scale.
		stub.screen_width, stub.screen_height = 5120, 2880
		st.UIScale:SetTokens()
		check(rawequal(st.pixel, 0.5) and rawequal(st.lineWeight, 2) and rawequal(st.line, 1), where .. 'k 2: 0.5, 2, 1: ' .. tostring(st.pixel))
		-- A k that is not whole keeps what is measured.
		stub.screen_width, stub.screen_height = 1920, 1080
		st.UIScale:SetTokens()
		check(close(st.pixel, 4 / 3, 1e-6) and not rawequal(st.pixel, 4 / 3), where .. 'k 0.75 is as measured')
	end
end)

test('the snap band is narrow: the tightest real k that is not whole is left as measured (Fix round 1, r2)', function()
	local st = world()
	-- Automatic at 3323 high and 130%: k 2.99993, 2.3e-5 from 3.
	local r = st.UIScale.Resolve({ mode = 'auto', size = 1.3 }, screen(5907, 3323))
	check(close(r.k, 2.99993, 1e-5), 'k is just under 3: ' .. tostring(r.k))
	stub.screen_width, stub.screen_height = 5907, 3323
	UIParent:SetScale(r.uiScale)
	check(close(st:GetPixelSize(UIParent), 1 / r.k, 1e-12) and not rawequal(st:GetPixelSize(UIParent), 1 / 3), 'Automatic 3323 at 130%: not snapped to 1/3')
	-- The game's UI scale at 3167 high and 0.97: k 3.99998698, 3.2e-6 from 4.
	r = st.UIScale.Resolve({ mode = 'game' }, screen(5630, 3167), 0.97)
	check(close(r.k, 3.99998698, 1e-7), 'k is just under 4: ' .. tostring(r.k))
	stub.screen_width, stub.screen_height = 5630, 3167
	UIParent:SetScale(r.uiScale)
	check(close(st:GetPixelSize(UIParent), 1 / r.k, 1e-12) and not rawequal(st:GetPixelSize(UIParent), 0.25), "the game's UI scale 3167 at 0.97: not snapped to 1/4")
end)

test('minPixels raises any non-zero value under it, its sign kept (Fix round 1, I2)', function()
	local st = world()
	use_scale(0.75)
	local pixel = 4 / 3
	local function near4(a, b) return close(a, b, 1e-4) end
	check(near4(st:RoundToPixel(1.2 * pixel, nil, 2), 2 * pixel), '1.2 pixels with a minimum of 2 is 2')
	check(near4(st:RoundToPixel(-1.2 * pixel, nil, 2), -2 * pixel), 'negative: -2')
	check(near4(st:RoundToPixel(0.3, nil, 3), 3 * pixel), 'under half a pixel with a minimum of 3 is 3')
	check(near4(st:RoundToPixel(3.4 * pixel, nil, 2), 3 * pixel), 'a value over it is as before')
	eq(st:RoundToPixel(0, nil, 2), 0, 'zero stays zero')
	check(near4(st:RoundToPixel(1.2 * pixel), pixel), 'no minimum: as before')
end)

test('Start sets Pixel for pixel on a screen, in every size (Fix round 1, m1)', function()
	local st = world()
	for _, h in ipairs({ 1080, 1440, 2160 }) do
		stub.screen_width, stub.screen_height = h * 16 / 9, h
		UIParent:SetScale(1)
		st.pixel, st.lineWeight, st.line = 9, 9, 9
		st.UIScale:Start()
		check(rawequal(UIParent:GetScale(), 768 / h), h .. ': UIParent is 768 / H, not Automatic')
		check(st.pixel == 1 and st.lineWeight == 1 and st.line == 1, h .. ': the tokens are 1')
	end
end)

test('GetLineSize where lines are two pixels (Fix round 1, m2)', function()
	local st = world()
	use_scale(1.55)
	eq(st.lineWeight, 2, 'a two pixel line')
	check(close(st:GetLineSize(UIParent), 2 * st.pixel), 'GetLineSize(UIParent)')
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetScale(0.8)
	check(close(st:GetLineSize(frame), 2 * st.pixel / 0.8), 'on a frame at 0.8')
end)

test('the nits: NaN, a width of 0, the trims, the line weight floor and EvenPixels on a negative count (Fix round 1)', function()
	local st = world()
	local U = st.UIScale
	eq(U.Normalize({ size = 0 / 0 }).size, 1, 'a NaN size is 1')
	eq(U.Resolve({ mode = 'auto' }, { width = 100, height = 0 / 0 }), nil, 'a NaN height is nil')
	eq(U.Resolve({ mode = 'auto' }, { width = 0 / 0, height = 100 }), nil, 'a NaN width is nil')
	local read = GetPhysicalScreenSize
	GetPhysicalScreenSize = function() return 100, 0 / 0 end
	eq(U.ReadScreen(), nil, 'ReadScreen: a NaN height')
	GetPhysicalScreenSize = function() return 0, 1440 end
	eq(U.ReadScreen(), nil, 'ReadScreen: a width of 0')
	GetPhysicalScreenSize = read
	check(rawequal(U.Resolve({ mode = 'auto', size = 0.8 }, screen(2560, 1440)).size, 0.8), 'the size is trimmed to two decimals')
	eq(U.LineWeight(0.3), 1, 'the line weight is at least 1')
	use_scale(0.75)
	eq(st:EvenPixels(45), 45.3333, 'EvenPixels is trimmed')
	use_scale(1)
	eq(st:EvenPixels(-45), -46, 'an odd negative count goes away from zero')
	eq(st:EvenPixels(-44), -44, 'an even one stays')
end)
