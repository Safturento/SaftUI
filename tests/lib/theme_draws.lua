-- What the module theme tests share (tests/<addon>/theme_test.lua): watching the
-- Theme, Background and kind SaftUI's draw calls pass, reading a drawn frame back,
-- checking a module default against the old template name it replaced, and
-- checking an options group's Theme and Background. Not a test (no _test suffix).
-- Load it with `local T = load_test_file('lib/theme_draws.lua')`, after
-- load_core_helpers(); its functions read SaftUI when they run.

local T = {}

-- Wraps st:SetTemplate, st:SetBackdrop and st:SetBackdropIn so each notes the
-- arguments a frame was last drawn with. The real ones still draw. A draw is
-- noted by the frame it's for: the frame given to st:SetTemplate or
-- st:SetBackdrop, and for st:SetBackdropIn the frame the backdrop sits behind.
-- Returns drawn(frame): 'theme,background,kind' ('nil' for what wasn't passed),
-- or nil for a frame not drawn since. Again after a reset_world().
function T.watch()
	local st = SaftUI
	local draws = setmetatable({}, { __mode = 'k' })
	for _, name in ipairs({ 'SetTemplate', 'SetBackdrop' }) do
		local real = st[name]
		st[name] = function(self, frame, theme, background, kind)
			draws[frame] = { theme, background, kind }
			return real(self, frame, theme, background, kind)
		end
	end
	local realIn = st.SetBackdropIn
	st.SetBackdropIn = function(self, backdrops, frame, theme, background, kind)
		draws[frame] = { theme, background, kind }
		return realIn(self, backdrops, frame, theme, background, kind)
	end
	return function(frame)
		local d = draws[frame]
		if not d then return nil end
		return ('%s,%s,%s'):format(tostring(d[1]), tostring(d[2]), tostring(d[3]))
	end
end

-- Numbers as text, rounded so float drift doesn't decide a check.
function T.text(...)
	local out = {}
	for i = 1, select('#', ...) do out[i] = string.format('%.2f', (select(i, ...))) end
	return table.concat(out, ',')
end

-- A drawn frame's border and fill colors, as text.
function T.edge(f) return T.text(f:GetBackdropBorderColor()) end
function T.fill(f) return T.text(f:GetBackdropColor()) end

-- How far in a drawn frame's background sits (its border's width: 2 for Thick,
-- 1 for Thin), or nil for a frame drawn bare.
function T.inset(f) return f.backdropInfo and f.backdropInfo.insets.left end

-- The x and y of one of a frame's points, as text, or nil.
function T.offset(f, point)
	for i = 1, f:GetNumPoints() do
		local p, _, _, x, y = f:GetPoint(i)
		if p == point then return T.text(x, y) end
	end
end

-- A look as text: its theme, inset and opacity, or 'none'.
local function Describe(look)
	if not look then return 'none' end
	return ('%s/%d/%.2f'):format(look.name, look.inset, look.alpha)
end

-- Checks that config (a module's defaults, as the profile has them) has a
-- Theme and Background and no template, and that they draw what the old
-- template name drew: the same theme (so its colors), inset and opacity, or
-- nothing for none.
function T.check_default(config, old, where)
	local st = SaftUI
	eq(rawget(config, 'template'), nil, where .. ': no template key')
	check(config.theme ~= nil, where .. ': has a Theme')
	local now, was = st:ResolveTheme(config.theme, config.background), st:ResolveLegacyTemplate(old)
	eq(Describe(now), Describe(was), where .. ' (' .. tostring(config.theme) .. ', ' .. tostring(config.background)
		.. ') looks as ' .. old .. ' did')
end

-- The values of a select, by value, in its order: 'theme:Use SaftUI's theme,...'.
local function Values(option)
	local out = {}
	for _, value in ipairs(option.sorting or {}) do out[#out + 1] = value .. ':' .. tostring(option.values[value]) end
	return table.concat(out, ',')
end

-- Checks that an options group offers Theme then Background, from Core's
-- builders (with their choices, a desc and no Ace width), and no Template.
function T.check_options(group, where)
	local args = group.args
	eq(args.template, nil, where .. ': no Template')
	local theme, background = args.theme, args.background
	check(theme ~= nil and background ~= nil, where .. ': Theme and Background')
	if not (theme and background) then return end
	eq(theme.type .. ':' .. theme.name, "select:Theme", where .. ': Theme is a select')
	eq(background.type .. ':' .. background.name, 'select:Background', where .. ': Background is a select')
	eq(Values(theme), "theme:Use SaftUI's theme,thick:Thick,thin:Thin,none:None", where .. ": Theme's choices")
	eq(Values(background), "theme:Use SaftUI's theme,solid:Solid,transparent:Transparent", where .. ": Background's choices")
	check(background.order > theme.order, where .. ': Background follows Theme')
	for _, option in ipairs({ theme, background }) do
		check(type(option.desc) == 'string' and option.desc ~= '', where .. ': ' .. option.name .. ' has a desc')
		check(not option.desc:find('[Tt]emplate'), where .. ': ' .. option.name .. "'s desc doesn't say template")
		eq(option.width, nil, where .. ': ' .. option.name .. ' has no Ace width')
	end
end

return T
