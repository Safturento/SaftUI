-- What the theme tests of SaftUI's addons share (tests/<area>/theme_test.lua and
-- Core's theme tests): a fresh world on either client (T.client); watching the
-- Theme, Background and kind SaftUI's draw
-- calls pass; reading a drawn frame back (its colors, inset, where its border
-- sits and its Blizzard art), as text rounded so float drift doesn't decide a
-- check; checking a module
-- default against the old template name it replaced; and checking options for a
-- Theme and Background and for the old template names. Not a test (no _test
-- suffix), so the runner doesn't run it. Load it with
-- `local T = load_test_file('lib/theme_helpers.lua')`, after load_core_helpers()
-- (or core/config_helpers.lua); it makes no globals, and its functions read SaftUI
-- when they run.
local T = {}

------------------------------------------------------------------ clients

local INTERFACE = { forever = 16001, retail = 120000 }

-- A fresh world on one client, 'forever' or 'retail': the world a test file
-- starts in after load_core_helpers(), with stub.interface set to the
-- client's and Core's constants.lua run again for it (it reads the interface
-- when it loads, so st.forever follows). Everything else is as fresh as
-- reset_world() leaves it, so a file can switch clients between cases.
-- Returns SaftUI. Load anything else the case needs, and call T.watch(),
-- after it.
function T.client(name)
	local interface = INTERFACE[name]
	if not interface then
		error(("T.client: no client '%s' (forever or retail)"):format(tostring(name)), 2)
	end
	reset_world()
	stub.interface = interface
	load_saftui('SaftUI-Core/constants.lua')
	load_core_helpers()
	apply_defaults()
	return SaftUI
end

------------------------------------------------------------------ draws

-- Wraps st:SetTemplate, st:SetBackdrop and st:SetBackdropIn so each notes the
-- arguments a frame was last drawn with, since the kind a frame is drawn as
-- changes nothing under Thick and Thin. The real ones still draw. A draw is
-- noted by the frame it's for: the frame given to st:SetTemplate or
-- st:SetBackdrop, and for st:SetBackdropIn the frame the backdrop sits behind.
-- Returns drawn(frame): 'theme,background,kind' ('nil' for what wasn't passed),
-- or nil for a frame not drawn since. Call it before anything draws, and again
-- after a reset_world().
function T.watch()
	local st = SaftUI
	local draws = setmetatable({}, { __mode = 'k' })
	for _, name in ipairs({ 'SetTemplate', 'SetBackdrop' }) do
		local real = st[name]
		st[name] = function(self, frame, theme, background, kind, ...)
			draws[frame] = { theme, background, kind }
			return real(self, frame, theme, background, kind, ...)
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

------------------------------------------------------------------ reading a frame

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

-- How far in a drawn frame's background sits (its border's width: 2 for Thick,
-- 1 for Thin), or nil for a frame drawn with None or never drawn.
function T.inset(f) return f.backdropInfo and f.backdropInfo.insets.left end

-- The x and y of one of a frame's points, as text, or nil.
function T.offset(f, point)
	for i = 1, f:GetNumPoints() do
		local p, _, _, x, y = f:GetPoint(i)
		if p == point then return T.text(x, y) end
	end
end

-- One set of a drawn frame's Blizzard art (st.ThemeArt.Get) as text: each
-- shown piece as 'key=atlas-or-file', sorted and comma-joined; '' for none.
local function Pieces(set)
	local out = {}
	for key, piece in pairs(set or {}) do
		if piece:IsShown() then out[#out + 1] = key .. '=' .. tostring(piece:GetAtlas() or piece:GetTexture()) end
	end
	table.sort(out)
	return table.concat(out, ',')
end

-- The Blizzard art shown on a drawn frame itself (T.art) and over its icon's
-- edge (T.over), as Pieces gives it: '' for a frame with none, or never drawn
-- under Blizzard.
function T.art(f)
	local art = SaftUI.ThemeArt.Get(f)
	return Pieces(art and art.pieces)
end
function T.over(f)
	local art = SaftUI.ThemeArt.Get(f)
	return Pieces(art and art.over)
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

------------------------------------------------------------------ defaults

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

------------------------------------------------------------------ options

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
	eq(Values(theme), "theme:Use SaftUI's theme,thick:Thick,thin:Thin,blizzard:Blizzard,none:None", where .. ": Theme's choices")
	eq(Values(background), "theme:Use SaftUI's theme,solid:Solid,transparent:Transparent", where .. ": Background's choices")
	check(background.order > theme.order, where .. ': Background follows Theme')
	for _, option in ipairs({ theme, background }) do
		check(type(option.desc) == 'string' and option.desc ~= '', where .. ': ' .. option.name .. ' has a desc')
		check(not option.desc:find('[Tt]emplate'), where .. ': ' .. option.name .. "'s desc doesn't say template")
		eq(option.width, nil, where .. ': ' .. option.name .. ' has no Ace width')
	end
end

-- What the old template picker offered and themes never show: the word
-- Template, Highlight, Close Button, and the old names ThickTransparent and
-- ThinTransparent, as a label or as a select's value.
local OLD_LABELS = { 'template', 'highlight', 'close button', 'thicktransparent', 'thintransparent' }
local OLD_VALUES = { template = true, highlight = true, close = true, thicktransparent = true, thintransparent = true }

local function IsOldLabel(text)
	if type(text) ~= 'string' then return false end
	text = text:lower():gsub('^%s+', ''):gsub('%s+$', '')
	for _, label in ipairs(OLD_LABELS) do
		if text == label then return true end
	end
	return false
end

-- Where, under tree (a group), an option offers something the old template
-- picker did: an option or group named Template, Highlight or Close Button, a
-- key 'template' (or one ending in template, like buttontemplate), or a select
-- listing one of them or an old template name as a choice or a value. A list of
-- 'path: what', empty when there's none. Names and values that are functions
-- are called as the options window calls them, with an info table of the path.
function T.old_names(tree)
	assert(each_option, 'load core/options_walk.lua first')
	local found = {}
	local function note(path, what) found[#found + 1] = table.concat(path, '.') .. ': ' .. what end
	local function resolve(value, path)
		if type(value) ~= 'function' then return value end
		local ok, result = pcall(value, path)
		return ok and result or nil
	end
	local function look(option, path)
		if type(option) ~= 'table' then return end
		local key = path[#path]
		if type(key) == 'string' and key:find('template$') then note(path, 'keyed ' .. key) end
		local name = resolve(option.name, path)
		if IsOldLabel(name) then note(path, 'named ' .. tostring(name)) end
		if option.type == 'select' or option.type == 'multiselect' then
			local values = resolve(option.values, path)
			if type(values) == 'table' then
				for value, label in pairs(values) do
					if OLD_VALUES[value] then note(path, 'offers the value ' .. tostring(value)) end
					if IsOldLabel(label) then note(path, 'offers ' .. tostring(label)) end
				end
			end
		end
	end
	look(tree, {})
	each_option(tree, look)
	return found
end

-- Checks that nothing under tree (a group, e.g. a module's GetConfigTable())
-- offers what the old template picker did (T.old_names). Needs
-- core/options_walk.lua loaded.
function T.check_no_old_names(tree, where)
	eq(table.concat(T.old_names(tree), '; '), '', where .. ': no Template, Highlight, Close Button or old template name')
end

return T
