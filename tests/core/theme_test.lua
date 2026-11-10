-- SaftUI's theme engine (SaftUI-Core/theme.lua):
--   - st:ResolveTheme, which turns a Theme and a Background override into the
--     look a frame is drawn with, and st:ResolveLegacyTemplate and
--     st:ThemeInset, which read the old template names;
--   - the draw calls st:SetTemplate, st:SetBackdrop and st:SetBackdropIn, with
--     a kind, and with none (the transition mode, where the theme argument is
--     an old template name and draws as it did before themes);
--   - st:RecolorThemed and st:RedrawThemed, which bring every drawn frame up to
--     a changed theme.
--
-- Real: theme.lua, with Core's helpers it's loaded with (load_core_helpers) and
-- the profile's defaults. Each case starts from a fresh world, since cases
-- change the profile's theme.

local function fresh()
	reset_world()
	load_core_helpers()
	return SaftUI
end

-- Numbers as text, rounded so float drift doesn't decide a check.
local function text(...)
	local out = {}
	for i = 1, select('#', ...) do out[i] = string.format('%.2f', (select(i, ...))) end
	return table.concat(out, ',')
end

local function frame(st)
	local f = st:CreateFrame('Frame', nil, UIParent)
	f:SetSize(100, 50)
	f:SetPoint('CENTER')
	return f
end

-- The x and y of one of a frame's points, as text.
local function offset(f, point)
	for i = 1, f:GetNumPoints() do
		local p, _, _, x, y = f:GetPoint(i)
		if p == point then return text(x, y) end
	end
end

local function fill(f) return text(f:GetBackdropColor()) end
local function edge(f) return text(f:GetBackdropBorderColor()) end
local function inset(f) return f.backdropInfo and f.backdropInfo.insets.left end

-- Whether Thick's outer lines (the dark ones either side of the border) show.
local function outerShown(f)
	if not f.altborder then return false end
	for _, line in pairs(f.altborder) do
		if not line:IsShown() then return false end
	end
	return true
end

-- A frame with no backdrop and no outer lines: what None draws.
local function bare(f)
	return f.backdropInfo == nil and not outerShown(f)
end

test('the theme follows the profile: thick, transparent at 0.9 by default', function()
	local st = fresh()
	local theme = st.config.profile.theme
	check(theme.name == 'thick' and theme.transparent == true and theme.opacity == 0.9, "the profile's theme defaults to today's thicktransparent")

	local look = st:ResolveTheme('theme', 'theme')
	eq(look.name, 'thick', 'name')
	eq(look.inset, 2, 'inset')
	eq(text(look.alpha), '0.90', 'alpha')
	check(look.colors == st.config.profile.templates.thick, "the colors are the profile's Thick colors")

	look = st:ResolveTheme('thin', 'solid')
	eq(look.name, 'thin', 'thin: name')
	eq(look.inset, 1, 'thin: inset')
	eq(look.alpha, 1, 'thin solid: alpha')
	check(look.colors == st.config.profile.templates.thin, "thin: the profile's Thin colors")

	eq(st:ResolveTheme('none', 'transparent'), nil, 'None draws nothing')

	look = st:ResolveTheme()
	check(look.name == 'thick' and text(look.alpha) == '0.90', 'no arguments follow the theme')
	look = st:ResolveTheme('unknown', 'unknown')
	check(look.name == 'thick' and text(look.alpha) == '0.90', 'an unknown theme and background read as the theme')
end)

test('an explicit Transparent uses the stored opacity while the toggle is off', function()
	local st = fresh()
	st.config.profile.theme.transparent = false
	st.config.profile.theme.opacity = 0.7
	eq(text(st:ResolveTheme('theme', 'transparent').alpha), '0.70', 'Transparent override')
	eq(st:ResolveTheme('theme', 'theme').alpha, 1, "the theme's background is solid")
	eq(st:ResolveTheme('thin', 'solid').alpha, 1, 'Solid override')
end)

test('old names read as LEGACY', function()
	local st = fresh()
	local look = st:ResolveLegacyTemplate('thicktransparent')
	check(look.name == 'thick' and look.inset == 2 and text(look.alpha) == '0.90', 'thicktransparent is Thick at 0.9')
	look = st:ResolveLegacyTemplate('thick')
	check(look.name == 'thick' and look.alpha == 1, 'thick is Thick and solid')
	look = st:ResolveLegacyTemplate('thintransparent')
	check(look.name == 'thin' and look.inset == 1 and text(look.alpha) == '0.90', 'thintransparent is Thin at 0.9')
	look = st:ResolveLegacyTemplate('thin')
	check(look.name == 'thin' and look.alpha == 1, 'thin is Thin and solid')
	eq(st:ResolveLegacyTemplate('none'), nil, 'none draws nothing')
	eq(st:ResolveLegacyTemplate(nil), nil, 'no name draws nothing, as before')
	eq(st:ResolveLegacyTemplate(''), nil, 'an empty name draws nothing, as before')

	look = st:ResolveLegacyTemplate('highlight')
	check(look.name == 'thick' and text(look.alpha) == '0.90', 'highlight follows the theme')
	st.config.profile.theme.name = 'thin'
	st.config.profile.theme.transparent = false
	look = st:ResolveLegacyTemplate('highlight')
	check(look.name == 'thin' and look.alpha == 1, 'highlight follows a changed theme')
	look = st:ResolveLegacyTemplate('close')
	check(look.name == 'thin' and look.alpha == 1, 'close follows the theme')
	look = st:ResolveLegacyTemplate('thicktransparent')
	check(look.name == 'thick' and text(look.alpha) == '0.90', "an old name keeps its own look whatever the theme")
end)

test('a call with no kind draws an old name exactly as today', function()
	local st = fresh()
	local f = frame(st)

	st:SetTemplate(f, 'thick')
	eq(edge(f), '0.30,0.30,0.30,1.00', 'thick: border color')
	eq(fill(f), '0.12,0.12,0.12,1.00', 'thick: background, solid')
	eq(inset(f), 2, 'thick: background 2px in')
	check(outerShown(f), 'thick: the outer lines show')
	eq(text(f.altborder.LEFT:GetVertexColor()), '0.10,0.10,0.10,1.00', "thick: the outer lines in Thick's outer border color")

	st:SetTemplate(f, 'thicktransparent')
	eq(fill(f), '0.12,0.12,0.12,0.90', 'thicktransparent: background alpha 0.9')
	eq(edge(f), '0.30,0.30,0.30,1.00', 'thicktransparent: border color')

	st:SetTemplate(f, 'thin')
	eq(edge(f), '0.00,0.00,0.00,1.00', 'thin: border color')
	eq(fill(f), '0.20,0.20,0.20,1.00', 'thin: background')
	eq(inset(f), 1, 'thin: background 1px in')
	check(not outerShown(f), 'thin: no outer lines')

	st:SetTemplate(f, 'thintransparent')
	eq(fill(f), '0.20,0.20,0.20,0.90', 'thintransparent: background alpha 0.9')

	st:SetTemplate(f, 'none')
	check(bare(f), 'none: no backdrop, no outer lines')

	-- An old name is drawn as it was, whatever the theme says.
	st.config.profile.theme.name = 'thin'
	st.config.profile.theme.transparent = false
	st:SetTemplate(f, 'thicktransparent')
	check(inset(f) == 2 and outerShown(f) and fill(f) == '0.12,0.12,0.12,0.90', 'thicktransparent stays Thick at 0.9 under a Thin, solid theme')

	-- st:SetBackdrop: the backdrop sits the template's thickness outside the
	-- frame, and the frame and backdrop keep the fields unconverted code reads.
	local p = frame(st)
	st:SetBackdrop(p, 'thintransparent')
	eq(offset(p.backdrop, 'TOPLEFT'), '-1.00,1.00', 'SetBackdrop thin: 1px out')
	eq(offset(p.backdrop, 'BOTTOMRIGHT'), '1.00,-1.00', 'SetBackdrop thin: 1px out (bottom right)')
	eq(p.thick, false, 'SetBackdrop thin: frame.thick is false')
	eq(p.backdrop.template, 'thintransparent', 'SetBackdrop: backdrop.template is the old name')
	eq(fill(p.backdrop), '0.20,0.20,0.20,0.90', 'SetBackdrop thintransparent: background')
	st:SetBackdrop(p, 'thick')
	eq(offset(p.backdrop, 'TOPLEFT'), '-2.00,2.00', 'SetBackdrop thick: 2px out')
	eq(p.thick, true, 'SetBackdrop thick: frame.thick is true')
	st:SetBackdrop(p, 'none')
	check(bare(p.backdrop), 'SetBackdrop none: the backdrop is cleared')

	-- st:SetBackdropIn keeps its backdrop in the caller's table and writes
	-- nothing onto the frame.
	local backdrops = setmetatable({}, { __mode = 'k' })
	local b = frame(st)
	local made = st:SetBackdropIn(backdrops, b, 'thick')
	check(made ~= nil and made == backdrops[b], "SetBackdropIn returns the backdrop it keeps in the caller's table")
	eq(offset(made, 'TOPLEFT'), '-2.00,2.00', 'SetBackdropIn thick: 2px out')
	eq(made.template, 'thick', 'SetBackdropIn: backdrop.template is the old name')
	check(b.backdrop == nil and b.thick == nil and b.altborder == nil, 'SetBackdropIn writes nothing onto the frame')
	eq(st:SetBackdropIn(backdrops, b, 'none'), nil, 'SetBackdropIn none returns nil')
	check(bare(made), 'SetBackdropIn none: the backdrop is cleared')
	local other = frame(st)
	eq(st:SetBackdropIn(backdrops, other, 'none'), nil, 'SetBackdropIn none on a new frame makes nothing')
	eq(backdrops[other], nil, 'SetBackdropIn none on a new frame keeps nothing')
end)

test('header and close draw their own looks from the theme', function()
	local st = fresh()
	local h = frame(st)
	st:SetTemplate(h, 'none', 'solid', 'header') -- the theme and background are ignored
	eq(fill(h), '0.30,0.30,0.30,0.40', "header: the theme's border color at 0.4")
	eq(text(select(4, h:GetBackdropBorderColor())), '0.00', 'header: no border line')
	check(not outerShown(h), 'header: no outer lines')
	eq(inset(h), 0, 'header: the fill covers the frame')

	local c = frame(st)
	st:SetTemplate(c, 'thin', 'transparent', 'close')
	eq(fill(c), '0.50,0.10,0.10,0.40', "close: the close button's red")
	eq(text(select(4, c:GetBackdropBorderColor())), '0.00', 'close: no border line')
	check(not outerShown(c), 'close: no outer lines')

	-- Both sit the theme's thickness outside a SetBackdrop'd frame.
	local hb = frame(st)
	st:SetBackdrop(hb, 'none', 'transparent', 'header')
	eq(offset(hb.backdrop, 'TOPLEFT'), '-2.00,2.00', "header backdrop: Thick's 2px out")
	eq(hb.thick, true, 'header backdrop: frame.thick follows the theme')
	local cb = frame(st)
	st:SetBackdrop(cb, 'thin', 'solid', 'close')
	eq(offset(cb.backdrop, 'TOPLEFT'), '-2.00,2.00', "close backdrop: Thick's 2px out")

	st.config.profile.templates.thick.bordercolor = { 1, 0, 0, 1 }
	st:RedrawThemed()
	eq(fill(h), '1.00,0.00,0.00,0.40', "header: a changed border color, at 0.4")
	eq(fill(c), '0.50,0.10,0.10,0.40', 'close: unchanged')

	st.config.profile.theme.name = 'thin'
	st:RedrawThemed()
	eq(fill(h), '0.00,0.00,0.00,0.40', "header: Thin's border color at 0.4")
	eq(offset(hb.backdrop, 'TOPLEFT'), '-1.00,1.00', "header backdrop: Thin's 1px out")
	eq(hb.thick, false, 'header backdrop: frame.thick follows the theme')
	eq(offset(cb.backdrop, 'TOPLEFT'), '-1.00,1.00', "close backdrop: Thin's 1px out")

	eq(table.concat({ st:ThemeHeaderColor() }, ','), '0,0,0,0.4', "ThemeHeaderColor: the theme's border color at 0.4")
end)

test('a recolor changes colors, not places, and calls ColorsChanged theme once', function()
	local st = fresh()
	local panel = frame(st)
	st:SetBackdrop(panel, 'theme', 'theme', 'panel')
	local thin = frame(st)
	st:SetTemplate(thin, 'thin', 'solid', 'small')
	local legacy = frame(st)
	st:SetTemplate(legacy, 'thicktransparent')

	local before = offset(panel.backdrop, 'TOPLEFT')
	local moves = 0
	panel.backdrop.ClearAllPoints = function() moves = moves + 1 end
	panel.backdrop.SetPoint = function() moves = moves + 1 end
	local groups = {}
	st.ColorsChanged = function(_, group) groups[#groups + 1] = tostring(group) end

	local thick = st.config.profile.templates.thick
	thick.bordercolor = { 1, 0, 0, 1 }
	thick.altbordercolor = { 0, 1, 0, 1 }
	thick.backdropcolor = { 0, 0, 1, 1 }
	st.config.profile.theme.opacity = 0.5
	st:RecolorThemed()

	eq(moves, 0, 'nothing was moved')
	eq(offset(panel.backdrop, 'TOPLEFT'), before, 'the backdrop keeps its points')
	eq(edge(panel.backdrop), '1.00,0.00,0.00,1.00', 'the border takes the new color')
	eq(fill(panel.backdrop), '0.00,0.00,1.00,0.50', 'the background takes the new color and opacity')
	eq(text(panel.backdrop.altborder.LEFT:GetVertexColor()), '0.00,1.00,0.00,1.00', 'the outer lines take the new color')
	eq(edge(thin), '0.00,0.00,0.00,1.00', "a Thin frame keeps Thin's border color")
	eq(fill(thin), '0.20,0.20,0.20,1.00', "a Thin frame keeps Thin's background")
	eq(fill(legacy), '0.00,0.00,1.00,0.50', 'a frame drawn with an old name follows its colors and the opacity too')
	eq(table.concat(groups, ','), 'theme', "ColorsChanged('theme') once")
end)

test('a redraw moves backdrops to the new inset and keeps None bare', function()
	local st = fresh()
	local f = frame(st)
	st:SetBackdrop(f, 'theme', 'theme', 'panel')
	eq(offset(f.backdrop, 'TOPLEFT'), '-2.00,2.00', 'Thick: 2px out')
	local backdrops = setmetatable({}, { __mode = 'k' })
	local b = frame(st)
	local made = st:SetBackdropIn(backdrops, b, 'theme', 'theme', 'tooltip')
	-- A backdrop drawn again on its own (as action buttons do after a green
	-- equipped border) still moves with its frame.
	local s = frame(st)
	st:SetBackdrop(s, 'theme', 'theme', 'slot')
	st:SetTemplate(s.backdrop, 'theme', 'theme', 'slot')

	st.config.profile.theme.name = 'thin'
	st:RedrawThemed()
	eq(offset(f.backdrop, 'TOPLEFT'), '-1.00,1.00', 'SetBackdrop: Thin, 1px out')
	eq(offset(f.backdrop, 'BOTTOMRIGHT'), '1.00,-1.00', 'SetBackdrop: Thin, 1px out (bottom right)')
	eq(f.thick, false, 'frame.thick follows')
	eq(inset(f.backdrop), 1, "the background sits Thin's 1px in")
	check(not outerShown(f.backdrop), 'no outer lines under Thin')
	eq(edge(f.backdrop), '0.00,0.00,0.00,1.00', "Thin's border color")
	eq(offset(made, 'TOPLEFT'), '-1.00,1.00', 'SetBackdropIn: Thin, 1px out')
	check(b.thick == nil and b.backdrop == nil, 'SetBackdropIn: still nothing written onto the frame')
	eq(offset(s.backdrop, 'TOPLEFT'), '-1.00,1.00', 'a backdrop drawn again on its own: Thin, 1px out')

	-- None stays bare: frames drawn None, including ones drawn with a theme first.
	local n = frame(st)
	st:SetTemplate(n, 'theme', 'theme', 'small')
	st:SetTemplate(n, 'none', 'theme', 'small')
	local nb = frame(st)
	st:SetBackdrop(nb, 'theme', 'theme', 'panel')
	st:SetBackdrop(nb, 'none', 'theme', 'panel')
	local ni = frame(st)
	local nmade = st:SetBackdropIn(backdrops, ni, 'theme', 'theme', 'tooltip')
	st:SetBackdropIn(backdrops, ni, 'none', 'transparent', 'tooltip')
	local function allBare() return bare(n) and bare(nb.backdrop) and bare(nmade) end
	check(allBare(), 'drawn None')
	st:RedrawThemed()
	check(allBare(), 'None after a redraw')
	st.config.profile.theme.transparent = false
	st:RedrawThemed()
	check(allBare(), 'None after the toggle is turned off and a redraw')
	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	check(allBare(), 'None after a switch back to Thick and a redraw')
	eq(offset(f.backdrop, 'TOPLEFT'), '-2.00,2.00', 'and the panel is back to 2px out')
end)

test('ThemeInset', function()
	local st = fresh()
	eq(st:ThemeInset('theme'), 2, 'the theme under Thick')
	eq(st:ThemeInset('thin'), 1, 'Thin')
	eq(st:ThemeInset('thick', 'solid'), 2, 'Thick')
	eq(st:ThemeInset('none'), 0, 'None')
	eq(st:ThemeInset('thicktransparent'), 2, 'old thicktransparent')
	eq(st:ThemeInset('thintransparent'), 1, 'old thintransparent')
	st.config.profile.theme.name = 'thin'
	eq(st:ThemeInset('theme'), 1, 'the theme under Thin')
	eq(st:ThemeInset('thicktransparent'), 2, 'an old name keeps its thickness under Thin')
end)

test('every override combination resolves by the rule', function()
	local st = fresh()
	local profile = st.config.profile
	profile.theme.opacity = 0.6
	local f = frame(st)
	for _, name in ipairs({ 'thick', 'thin' }) do
		for _, toggle in ipairs({ true, false }) do
			profile.theme.name = name
			profile.theme.transparent = toggle
			for _, theme in ipairs({ 'theme', 'thick', 'thin', 'none' }) do
				for _, background in ipairs({ 'theme', 'solid', 'transparent' }) do
					local label = ('%s/%s under %s, transparent %s'):format(theme, background, name, tostring(toggle))
					local look = st:ResolveTheme(theme, background)
					st:SetTemplate(f, theme, background, 'panel')
					if theme == 'none' then
						eq(look, nil, label .. ': nil')
						check(bare(f), label .. ': drawn bare')
					else
						local want = theme == 'theme' and name or theme
						local clear = background == 'transparent' or (background == 'theme' and toggle)
						local colors = profile.templates[want]
						eq(look.name, want, label .. ': name')
						eq(look.inset, want == 'thick' and 2 or 1, label .. ': inset')
						eq(look.alpha, clear and 0.6 or 1, label .. ': alpha')
						check(look.colors == colors, label .. ': colors')
						eq(inset(f), look.inset, label .. ': drawn inset')
						eq(outerShown(f), want == 'thick', label .. ': outer lines')
						eq(edge(f), text(unpack(colors.bordercolor)), label .. ': drawn border')
						eq(fill(f), text(colors.backdropcolor[1], colors.backdropcolor[2], colors.backdropcolor[3], colors.backdropcolor[4] * look.alpha), label .. ': drawn background')
					end
				end
			end
		end
	end
end)

test('old highlight and close names still draw their own looks', function()
	local st = fresh()
	local h = frame(st)
	st:SetTemplate(h, 'highlight')
	eq(fill(h), '0.30,0.30,0.30,0.40', 'highlight: the strip fill')
	eq(text(select(4, h:GetBackdropBorderColor())), '0.00', 'highlight: no border line')
	check(not outerShown(h), 'highlight: no outer lines')
	eq(inset(h), 0, 'highlight: the fill covers the frame')

	local c = frame(st)
	st:SetTemplate(c, 'close')
	eq(fill(c), '0.50,0.10,0.10,0.40', 'close: the red fill')
	eq(text(select(4, c:GetBackdropBorderColor())), '0.00', 'close: no border line')

	local cb = frame(st)
	st:SetBackdrop(cb, 'close')
	eq(offset(cb.backdrop, 'TOPLEFT'), '-2.00,2.00', "close backdrop: Thick's 2px out, as before")
	eq(cb.thick, true, 'close backdrop: frame.thick as before')
	eq(cb.backdrop.template, 'close', 'close backdrop: backdrop.template as before')
	eq(fill(cb.backdrop), '0.50,0.10,0.10,0.40', 'close backdrop: the red fill')
end)

test('THEME_KINDS has the nine kinds, and a draw with another kind errors', function()
	local st = fresh()
	local kinds = {}
	for kind in pairs(st.THEME_KINDS) do kinds[#kinds + 1] = kind end
	table.sort(kinds)
	eq(table.concat(kinds, ','), 'action,aura,bar,close,header,panel,slot,small,tooltip', 'the kinds')
	local ok = pcall(st.SetTemplate, st, frame(st), 'theme', 'theme', 'button')
	eq(ok, false, 'an unknown kind errors')
end)

-- Every anchor of a frame, as text, in a fixed order.
local function anchors(f)
	local out = {}
	for i = 1, f:GetNumPoints() do
		local p, rel, rp, x, y = f:GetPoint(i)
		out[#out + 1] = table.concat({ p, tostring(rel), rp, text(x, y) }, ' ')
	end
	table.sort(out)
	return table.concat(out, '; ')
end

test('a redraw keeps the anchors of a backdrop its caller placed itself, and still recolors it', function()
	local st = fresh()
	-- With a kind: an action button's backdrop, made to fill its button.
	local a = frame(st)
	st:SetBackdrop(a, 'theme', 'theme', 'action')
	a.backdrop:ClearAllPoints()
	a.backdrop:SetAllPoints(a)
	-- With a kind, through st:SetBackdropIn, placed further out.
	local backdrops = setmetatable({}, { __mode = 'k' })
	local t = frame(st)
	local tb = st:SetBackdropIn(backdrops, t, 'theme', 'theme', 'tooltip')
	tb:ClearAllPoints()
	tb:SetPoint('TOPLEFT', t, 'TOPLEFT', -5, 5)
	tb:SetPoint('BOTTOMRIGHT', t, 'BOTTOMRIGHT', 5, -5)
	-- With no kind: a Blizzard close button's backdrop (st:CreateHeader), a
	-- strip that follows the theme, and an old name placed by its caller.
	local c = frame(st)
	st:SetBackdrop(c, 'close')
	c.backdrop:SetAllPoints()
	local h = frame(st)
	st:SetBackdrop(h, 'highlight')
	h.backdrop:SetAllPoints()
	local l = frame(st)
	st:SetBackdrop(l, 'thicktransparent')
	l.backdrop:ClearAllPoints()
	l.backdrop:SetPoint('TOPLEFT', l, 'TOPLEFT', -4, 4)
	l.backdrop:SetPoint('BOTTOMRIGHT', l, 'BOTTOMRIGHT', 4, -4)

	local before = {}
	for _, b in ipairs({ a.backdrop, tb, c.backdrop, h.backdrop, l.backdrop }) do before[b] = anchors(b) end

	st.config.profile.templates.thick.bordercolor = { 1, 0, 0, 1 }
	st.config.profile.theme.name = 'thin'
	st:RedrawThemed()

	eq(anchors(a.backdrop), before[a.backdrop], 'action backdrop: the anchors its caller set')
	eq(edge(a.backdrop), '0.00,0.00,0.00,1.00', "action backdrop: Thin's border color")
	eq(inset(a.backdrop), 1, "action backdrop: Thin's 1px border")
	eq(a.thick, false, 'action backdrop: frame.thick follows the theme')
	eq(anchors(tb), before[tb], 'SetBackdropIn backdrop: the anchors its caller set')
	eq(edge(tb), '0.00,0.00,0.00,1.00', "SetBackdropIn backdrop: Thin's border color")
	check(t.thick == nil and t.backdrop == nil, 'SetBackdropIn: still nothing written onto the frame')
	eq(anchors(c.backdrop), before[c.backdrop], 'old close backdrop: the anchors its caller set')
	eq(fill(c.backdrop), '0.50,0.10,0.10,0.40', 'old close backdrop: the red fill')
	eq(anchors(h.backdrop), before[h.backdrop], 'old highlight backdrop: the anchors its caller set')
	eq(fill(h.backdrop), '0.00,0.00,0.00,0.40', "old highlight backdrop: Thin's border color at 0.4")
	eq(anchors(l.backdrop), before[l.backdrop], 'old thicktransparent backdrop: the anchors its caller set')
	eq(edge(l.backdrop), '1.00,0.00,0.00,1.00', "old thicktransparent backdrop: Thick's changed border color")
	eq(inset(l.backdrop), 2, 'old thicktransparent backdrop: still Thick')
end)

test('a redraw moves a backdrop that still sits where it was drawn', function()
	local st = fresh()
	local f = frame(st)
	st:SetBackdrop(f, 'theme', 'theme', 'panel')
	local backdrops = setmetatable({}, { __mode = 'k' })
	local t = frame(st)
	local tb = st:SetBackdropIn(backdrops, t, 'theme', 'theme', 'tooltip')
	st.config.profile.theme.name = 'thin'
	st:RedrawThemed()
	eq(offset(f.backdrop, 'TOPLEFT'), '-1.00,1.00', 'SetBackdrop: 1px out under Thin')
	eq(offset(f.backdrop, 'BOTTOMRIGHT'), '1.00,-1.00', 'SetBackdrop: 1px out under Thin (bottom right)')
	eq(offset(tb, 'TOPLEFT'), '-1.00,1.00', 'SetBackdropIn: 1px out under Thin')
	-- Placed by the redraw, it moves again on the next one.
	st.config.profile.theme.name = 'thick'
	st:RedrawThemed()
	eq(offset(f.backdrop, 'TOPLEFT'), '-2.00,2.00', 'SetBackdrop: back to 2px out under Thick')
	eq(offset(tb, 'TOPLEFT'), '-2.00,2.00', 'SetBackdropIn: back to 2px out under Thick')
end)

test('a redraw draws each recorded frame once, with its own arguments', function()
	local st = fresh()
	-- Two backdrops recorded for one frame: the first is replaced, the second
	-- made in its place with other arguments.
	local f = frame(st)
	st:SetBackdrop(f, 'theme', 'theme', 'panel')
	local first = f.backdrop
	f.backdrop = nil
	st:SetBackdrop(f, 'thin', 'solid', 'panel')
	local second = f.backdrop
	check(first ~= second, 'two backdrop frames')

	local draws = { [first] = 0, [second] = 0 }
	for b in pairs(draws) do
		local real = b.SetBackdrop
		b.SetBackdrop = function(self, ...)
			draws[self] = draws[self] + 1
			return real(self, ...)
		end
	end

	st.config.profile.theme.name = 'thin'
	st.config.profile.theme.transparent = true
	st:RedrawThemed()
	eq(draws[first], 1, 'the first backdrop is drawn once')
	eq(draws[second], 1, 'the second backdrop is drawn once')
	eq(fill(first), '0.20,0.20,0.20,0.90', "the first keeps its own arguments: the theme's, transparent")
	eq(fill(second), '0.20,0.20,0.20,1.00', 'the second keeps its own arguments: Thin, solid')
	eq(offset(first, 'TOPLEFT'), '-1.00,1.00', 'the first moves to the new inset')
end)
