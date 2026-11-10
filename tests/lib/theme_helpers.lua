-- Readers the theme tests of SaftUI's addons share: how a frame drawn by the
-- theme engine (SaftUI-Core/theme.lua) looks and where its border sits, as
-- text, rounded so float drift doesn't decide a check. Not a test (no _test
-- suffix), so the runner doesn't run it. A test file loads it with
-- local T = load_test_file('lib/theme_helpers.lua'); it makes no globals.
local T = {}

-- Numbers as text, to two places: '1.00,0.50'.
function T.text(...)
	local out = {}
	for i = 1, select('#', ...) do out[i] = string.format('%.2f', (select(i, ...))) end
	return table.concat(out, ',')
end

-- A drawn frame's background and border color, 'r,g,b,a'.
function T.fill(f) return T.text(f:GetBackdropColor()) end
function T.edge(f) return T.text(f:GetBackdropBorderColor()) end

-- The border color of a drawn frame without its alpha, 'r,g,b'.
function T.edge_rgb(f)
	local r, g, b = f:GetBackdropBorderColor()
	return T.text(r, g, b)
end

-- How far in a drawn frame's border reaches (its backdrop's inset), nil for a
-- frame drawn with None or never drawn.
function T.inset(f) return f.backdropInfo and f.backdropInfo.insets.left end

-- The x and y of one of a frame's points, as text.
function T.offset(f, point)
	for i = 1, f:GetNumPoints() do
		local p, _, _, x, y = f:GetPoint(i)
		if p == point then return T.text(x, y) end
	end
end

-- Watches st's draw calls (st:SetTemplate and st:SetBackdrop, which still
-- draw), since the kind a frame is drawn as changes nothing under Thick and
-- Thin. Returns drawn(frame): 'theme,background,kind' frame was last drawn
-- with ('nil' for what wasn't passed), or nil if it wasn't. Call it before
-- anything draws.
function T.watch_draws(st)
	local draws = setmetatable({}, { __mode = 'k' })
	for _, name in ipairs({ 'SetTemplate', 'SetBackdrop' }) do
		local real = st[name]
		st[name] = function(self, frame, theme, background, kind)
			draws[frame] = { theme, background, kind }
			return real(self, frame, theme, background, kind)
		end
	end
	return function(frame)
		local d = draws[frame]
		if not d then return nil end
		return ('%s,%s,%s'):format(tostring(d[1]), tostring(d[2]), tostring(d[3]))
	end
end

-- Where outer's edges sit from inner's on screen: 'left,top,right,bottom',
-- each as outer's minus inner's, in whole pixels. A border 1px around a
-- region reads '-1,1,1,-1'; one lying on its edges '0,0,0,0'.
function T.around(outer, inner)
	local function px(a, b) return string.format('%d', math.floor(a - b + 0.5)) end
	return table.concat({
		px(outer:GetLeft(), inner:GetLeft()), px(outer:GetTop(), inner:GetTop()),
		px(outer:GetRight(), inner:GetRight()), px(outer:GetBottom(), inner:GetBottom()),
	}, ',')
end

return T
