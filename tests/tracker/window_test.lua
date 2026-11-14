-- SaftUI's tracker window (SaftUI-Tracker/window.lua), switched on, on both
-- clients: its holder and edit mode mover, the window and its header, Width,
-- Max height and Grow, the scroll and its bar, Collapsed, Theme and
-- Background, whole pixels, and the one case that with the switch off none of
-- it exists. Quest rows come later; every case here sets the content height by
-- hand (TR:SetContentHeight).
--
-- Real: SaftUI-Tracker's files, Core's helpers, theme engine and edit mode,
-- Misc's config where a case asks. The scroll frame is tracker_world.lua's
-- stand-in (TW.scroll_frame).
local TW = load_test_file('tracker/tracker_world.lua')
local T = load_test_file('lib/theme_helpers.lua')
local P = load_test_file('lib/pixels.lua')

local drawn

local function mouse_on(frame)
	local x, y = frame:GetCenter()
	local scale = frame:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = x * scale, y * scale
end

local function mouse_off()
	stub.cursor_x, stub.cursor_y = -1000, -1000
end

-- A world with the switch on. opts are TW.world's.
local function world(opts)
	opts = opts or {}
	opts.on = true
	mouse_off()
	local before = opts.before
	opts.before = function(st)
		drawn = T.watch()
		if before then before(st) end
	end
	return TW.world(opts)
end

local function tip()
	return stub.state(GameTooltip).texts
end

local function point(frame, n)
	local p, rel, relPoint, x, y = frame:GetPoint(n or 1)
	return p, rel, relPoint, x, y
end

local COUNTS = { inLog = 12, max = 40, watched = 8, watchMax = 25 }

test('the holder is Width by Max height at the saved spot; the mover is the holder, so the outline covers it', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = world({ client = client })
		local where = client .. ': '
		eq(TR.holder:GetName(), 'SaftUITrackerHolder', where .. 'named')
		eq(TR.holder:GetParent(), UIParent, where .. 'on UIParent')
		eq(TR.holder:GetWidth(), 260, where .. 'Width')
		eq(TR.holder:GetHeight(), 560, where .. 'Max height')
		local p, rel, relPoint, x, y = point(TR.holder)
		eq(table.concat({ p, rel:GetName(), relPoint, x, y }, ' '),
			('TOPRIGHT UIParent TOPRIGHT -20 %d'):format(st.forever and -275 or -260), where .. "Blizzard's spot")

		local mover = st.EditModeFrames.movers.tracker
		check(mover, where .. 'the mover is registered')
		eq(mover.def.frame, TR.holder, where .. 'its frame is the holder')
		eq(mover.def.label, 'Tracker', where .. 'label')
		eq(mover.def.module, 'Tracker', where .. 'module')
		eq(table.concat(mover.def.configPath, '.'), 'Tracker.general', where .. 'configPath')
		local overlay = mover.overlay
		eq(overlay:GetWidth(), 260, where .. "the outline is the holder's width")
		eq(overlay:GetHeight(), 560, where .. "and Max height, not the window's")
		eq(overlay:GetTop(), TR.holder:GetTop(), where .. 'from its top')
		eq(mover.def.getSavedPosition(), TR.config.position, where .. 'the saved position is the profile')
		eq(st.EditModeFrames:GetDefaultPosition(mover).y_off, st.forever and -275 or -260, where .. 'Reset goes to the default spot')
		local first, second = mover.def.getDefaultPosition(), mover.def.getDefaultPosition()
		check(first ~= second, where .. 'a fresh table each call')
		eq(st:DefaultTrackerPosition().x_off, -st.CLAMP_INSET, where .. 'the helper')

		-- Width and Max height size the holder at once.
		TR.config.width, TR.config.height = 300, 400
		TR:UpdateConfig()
		eq(TR.holder:GetWidth(), 300, where .. 'a new Width')
		eq(TR.holder:GetHeight(), 400, where .. 'a new Max height')
		eq(overlay:GetHeight(), 400, where .. 'the outline follows')

		-- A drag saves a position into the profile and places the holder.
		local saved = mover.def.getPosition()
		saved.x_off, saved.y_off = -100, -50
		mover.def.setPosition(saved)
		mover.def.apply()
		local _, _, _, hx, hy = point(TR.holder)
		eq(hx .. ',' .. hy, '-100,-50', where .. 'placed from the profile')
		eq(#take_errors(), 0, where .. 'no errors')
	end
end)

test("first position: the skin's saved one when Misc has one, else Blizzard's default spot, saved once", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st, TR = world({ client = client })
		local where = client .. ': '
		local position = st.config.profile.tracker.position
		eq(position.point .. position.frame .. position.rel_point, 'TOPRIGHTUIParentTOPRIGHT', where .. 'a position is saved')
		eq(position.x_off .. ',' .. position.y_off, ('-20,%d'):format(st.forever and -275 or -260), where .. "Blizzard's default spot")
		TR:UpdateConfig()
		eq(st.config.profile.tracker.position, position, where .. 'written once: the same table after an update')

		-- A profile with none (new or reset) is given one again.
		st.config.profile.tracker.position = nil
		TR:UpdateConfig()
		check(st.config.profile.tracker.position ~= nil, where .. 'a profile with none gets one')
		eq(st.config.profile.tracker.position.y_off, st.forever and -275 or -260, where .. 'the default spot')
		eq(#take_errors(), 0, where .. 'no errors')
	end

	-- Misc loaded with a saved position: a copy of it.
	local saved
	local st, TR = world({
		misc = true,
		enabling = function(st)
			saved = { point = 'TOPLEFT', frame = 'UIParent', rel_point = 'TOPLEFT', x_off = 30, y_off = -80 }
			st.config.profile.objectivetracker.position = saved
		end,
	})
	local position = st.config.profile.tracker.position
	check(position ~= saved, "a copy, not the skin's own table")
	eq(position.point .. ',' .. position.x_off .. ',' .. position.y_off, 'TOPLEFT,30,-80', "the skin's saved position")
	position.x_off = 31
	TR:ApplyHolder()
	eq(saved.x_off, 30, "moving the tracker leaves the skin's alone")
	local p, _, _, x, y = point(TR.holder)
	eq(p .. x .. ',' .. y, 'TOPLEFT31,-80', 'the holder is placed there')

	-- Misc loaded with none saved: the default spot.
	local st2 = world({ misc = true })
	eq(st2.config.profile.tracker.position.x_off, -20, 'no saved skin position: the default spot')
	eq(#take_errors(), 0, 'no errors')
end)

test('the window hangs by its top right (Grow down) or bottom right (Grow up), as tall as its contents up to Max height', function()
	local st, TR = world()
	local window = TR.window
	eq(window:GetName(), 'SaftUITracker', 'named')
	eq(window:GetParent(), UIParent, 'on UIParent')
	eq(window:GetFrameStrata(), 'LOW', 'strata LOW')
	eq(window:GetFrameLevel(), 10, 'level 10')
	eq(window:IsProtected(), false, 'never protected')
	eq(TR.holder:IsProtected(), false, 'nor the holder')
	local p, rel, relPoint, x, y = point(window)
	eq(table.concat({ p, rel == TR.holder and 'holder' or '?', relPoint, x, y }, ' '), 'TOPRIGHT holder TOPRIGHT 0 0', 'Grow down')
	eq(window:GetWidth(), 260, 'Width')
	eq(window:GetHeight(), 46, 'empty: padding, header, gap, padding')

	TR:SetContentHeight(100)
	eq(window:GetHeight(), 146, 'as tall as its contents')
	eq(window:GetTop(), TR.holder:GetTop(), 'the top stays put')
	TR:SetContentHeight(2000)
	eq(window:GetHeight(), 560, 'up to Max height')

	TR.config.grow = 'up'
	TR:UpdateConfig()
	TR:SetContentHeight(100)
	p, rel, relPoint, x, y = point(window)
	eq(table.concat({ p, rel == TR.holder and 'holder' or '?', relPoint, x, y }, ' '), 'BOTTOMRIGHT holder BOTTOMRIGHT 0 0', 'Grow up')
	eq(window:GetBottom(), TR.holder:GetBottom(), 'the bottom stays put')
	eq(window:GetHeight(), 146, 'the same height')
	eq(window:GetRight(), TR.holder:GetRight(), 'the right edges meet')

	TR.config.grow = 'down'
	TR:UpdateConfig()
	eq(point(window), 'TOPRIGHT', 'back down')
	eq(#take_errors(), 0, 'no errors')
end)

test('Grow changes no saved position, and in combat the window sizes and moves', function()
	local st, TR = world()
	local before = st.config.profile.tracker.position
	local snapshot = table.concat({ before.point, before.x_off, before.y_off }, ',')
	TR.config.grow = 'up'
	TR:UpdateConfig()
	eq(table.concat({ before.point, before.x_off, before.y_off }, ','), snapshot, 'Grow converts no position')

	TW.combat(true)
	TR.config.width = 300
	TR:UpdateConfig()
	TR:SetContentHeight(300)
	eq(TR.window:GetWidth(), 300, 'Width in combat')
	eq(TR.window:GetHeight(), 346, 'size in combat')
	stub.fire_script(TR.scroll, 'OnMouseWheel', -1)
	TR.config.grow = 'down'
	TR:UpdateConfig()
	eq(point(TR.window), 'TOPRIGHT', 'Grow in combat')
	eq(#stub.blocked, 0, 'nothing was blocked')
	TW.combat(false)
	eq(#take_errors(), 0, 'no errors')
end)

test('the header: Objectives, the count 6 left of the chevron in Text > Grey, a line at 50%; Header off and Count off', function()
	local st, TR = world()
	local header = TR.header
	local grey = st.config.profile.colors.text.grey
	eq(header.title:GetText(), 'Objectives', 'the title')
	eq(header.title:GetFontObject(), st:GetFont(TR.config.header_font), 'in the Header font')
	eq(header:GetHeight(), 24, 'the header is 24 tall')
	eq(header:GetWidth(), 244, 'inside the padding')
	local _, _, _, hx, hy = point(header)
	eq(hx .. ',' .. hy, '8,-8', 'at the padding, by its top left')

	TR:UpdateHeader({ counts = COUNTS })
	eq(header.count:GetText(), '12/40', 'the count: in the log over the most')
	eq(T.rgb(header.count:GetTextColor()), T.rgb(grey:GetRGB()), 'Text > Grey')
	local p, rel, relPoint, x = point(header.count)
	eq(p .. relPoint .. x, 'RIGHTLEFT-6', 'right-aligned 6 left of the chevron')
	eq(rel, header.collapse, 'anchored to the chevron')
	eq(header.count:GetJustifyH(), 'RIGHT', 'right-aligned')

	eq(header.collapse:GetWidth() .. 'x' .. header.collapse:GetHeight(), '16x16', 'the chevron is 16 square')
	eq(header.collapse.icon:GetTexture(), st.icons.chevronUp, 'up while the list shows')
	eq(header.collapse.icon:GetWidth(), 16, 'drawn 16')
	eq(T.rgb(header.collapse.icon:GetVertexColor()), T.rgb(grey:GetRGB()), 'Text > Grey at rest')
	mouse_on(header.collapse)
	stub.fire_script(header.collapse, 'OnEnter', true)
	eq(T.rgb(header.collapse.icon:GetVertexColor()), '1.00,1.00,1.00', 'white under the mouse')
	eq(tip()[1], 'Collapse', "the button's tooltip")
	stub.fire_script(header.collapse, 'OnLeave', true)
	eq(T.rgb(header.collapse.icon:GetVertexColor()), T.rgb(grey:GetRGB()), 'grey again')

	local look = st:ResolveTheme(TR.config.theme, TR.config.background)
	local r, g, b = unpack(look.colors.bordercolor)
	local lr, lg, lb, la = header.line:GetVertexColor()
	eq(T.text(lr, lg, lb, la), T.text(r, g, b, 0.5), "the line: the theme's border color at 50%")
	eq(header.line:GetHeight(), st:GetPixelSize(header) or 1, 'one pixel')
	local lp, lrel, lrp = point(header.line, 1)
	eq(lp .. tostring(lrel == header) .. lrp, 'BOTTOMLEFTtrueBOTTOMLEFT', 'along the header bottom')

	TR.config.count = false
	TR:UpdateConfig()
	eq(header.count:IsShown(), false, 'Count off hides it')
	eq(header:IsShown(), true, 'the header stays')
	TR.config.count = true
	TR.config.header = false
	TR:UpdateConfig()
	eq(header:IsShown(), false, 'Header off hides the header')
	eq(TR.window:GetHeight(), 16, 'and its room: padding twice')
	local _, _, _, sx, sy = point(TR.scroll)
	eq(sx .. ',' .. sy, '8,-8', 'the scroll frame moves up to the padding')
	TR:SetContentHeight(100)
	eq(TR.window:GetHeight(), 116, 'no header: 8 + 100 + 8')
	TR.config.header = true
	TR:UpdateConfig()
	eq(header:IsShown(), true, 'Header back on')
	eq(header.count:IsShown(), true, 'with its count')
	eq(#take_errors(), 0, 'no errors')
end)

test("the header's tooltip: Objectives, then the counts; at the watch limit it says so; the chevron's says Collapse or Expand", function()
	local st, TR = world()
	TR:UpdateHeader({ counts = COUNTS })
	stub.fire_script(TR.header, 'OnEnter', true)
	eq(tip()[1], 'Objectives', 'the title')
	eq(tip()[2], '12 of 40 quests in your quest log, 8 tracked (up to 25).', 'the counts, from the model')
	stub.fire_script(TR.header, 'OnLeave', true)
	eq(GameTooltip:IsShown(), false, 'hidden on leave')

	TR:UpdateHeader({ counts = { inLog = 30, max = 35, watched = 25, watchMax = 25 } })
	stub.fire_script(TR.header, 'OnEnter', true)
	eq(tip()[2], '30 of 35 quests in your quest log, 25 tracked: the most you can track.', 'at the limit')
	stub.fire_script(TR.header, 'OnLeave', true)

	-- A client that can't say some of them: the tooltip says what it can.
	TR:UpdateHeader({ counts = { inLog = 12 } })
	eq(TR.header.count:GetText(), '12', 'no most: only the number')
	stub.fire_script(TR.header, 'OnEnter', true)
	eq(tip()[1], 'Objectives', 'still titled')
	eq(tip()[3], nil, 'no further line')
	stub.fire_script(TR.header, 'OnLeave', true)
	TR:UpdateHeader({ counts = {} })
	eq(TR.header.count:GetText(), '', 'nothing known: no text')
	TR:UpdateHeader(nil)
	eq(TR.header.count:GetText(), '', 'no model: no text')

	-- The chevron: Collapse, then Expand while collapsed.
	stub.fire_script(TR.header.collapse, 'OnEnter', true)
	eq(tip()[1], 'Collapse', 'Collapse')
	stub.click(TR.header.collapse)
	eq(TR:IsCollapsed(), true, 'a click collapses')
	eq(tip()[1], 'Expand', 'the tooltip follows while it is open')
	stub.fire_script(TR.header.collapse, 'OnLeave', true)
	eq(TR.header.collapse.icon:GetTexture(), st.icons.chevronDown, 'down while collapsed')
	stub.click(TR.header.collapse)
	eq(TR:IsCollapsed(), false, 'a second expands')
	eq(TR.header.collapse.icon:GetTexture(), st.icons.chevronUp, 'up again')
	eq(#take_errors(), 0, 'no errors')
end)

test("hover scripts take the game's second argument: each is bound as function(self), never a function with an optional second parameter", function()
	local source = read_saftui_source('SaftUI-Tracker/window.lua')
	local bound = 0
	for line in source:gmatch('[^\n]+') do
		if line:find("SetScript%\('OnEnter'") or line:find("SetScript%\('OnLeave'") then
			bound = bound + 1
			check(line:find("function%\(self%\)", 1), 'bound as function(self): ' .. line)
		end
	end
	check(bound >= 4, 'the header and the chevron bind both (found ' .. bound .. ')')
	-- And they run with the game's second argument.
	local _, TR = world()
	for _, frame in ipairs({ TR.header, TR.header.collapse }) do
		for _, script in ipairs({ 'OnEnter', 'OnLeave' }) do
			check(type(frame:GetScript(script)) == 'function', script .. ' is set')
			check(stub.fire_script(frame, script, true), script .. ' runs with motion')
		end
	end
	eq(#take_errors(), 0, 'no errors')
end)

test("past Max height the list scrolls, with the bar's room kept; the wheel 40 a notch, clamped; the offset kept on resize", function()
	local st, TR = world()
	TR.config.width, TR.config.height = 261, 333
	TR:UpdateConfig()
	TR:SetContentHeight(100)
	eq(TR.window:GetHeight(), 146, 'fits')
	eq(TR.scroll:GetWidth(), 245, 'no bar: the width less the padding')
	eq(TR.scroll:GetHeight(), 100, 'the view is the content')
	eq(TR.content:GetWidth(), 245, 'the child as wide')
	eq(TR.content:GetHeight(), 100, 'the child as tall as its content')

	TR:SetContentHeight(2000)
	eq(TR.window:GetHeight(), 333, 'capped')
	eq(TR.scroll:GetHeight(), 287, 'the view: the window less padding, header and gap')
	eq(TR.scroll:GetWidth(), 231, "the bar's room kept: 261 - 16 - 14")
	eq(TR.content:GetWidth(), 231, 'the child keeps it')
	eq(TR.content:GetHeight(), 2000, 'the child is the content')
	local _, _, _, sx, sy = point(TR.scroll)
	eq(sx .. ',' .. sy, '8,-38', 'under the header: 8 + 24 + 6')

	eq(TR:GetScroll(), 0, 'starts at the top')
	stub.fire_script(TR.scroll, 'OnMouseWheel', -1)
	eq(TR:GetScroll(), 40, 'a notch down is 40')
	stub.fire_script(TR.window, 'OnMouseWheel', -1)
	eq(TR:GetScroll(), 80, 'the wheel over the window scrolls too')
	stub.fire_script(TR.scroll, 'OnMouseWheel', 1)
	stub.fire_script(TR.scroll, 'OnMouseWheel', 1)
	stub.fire_script(TR.scroll, 'OnMouseWheel', 1)
	eq(TR:GetScroll(), 0, 'clamped at the top')
	for _ = 1, 100 do stub.fire_script(TR.scroll, 'OnMouseWheel', -1) end
	eq(TR:GetScroll(), 1713, 'clamped at the end: 2000 - 287')
	eq(TR.scroll:GetVerticalScroll(), 1713, 'the scroll frame is there')

	TR:ScrollTo(100)
	eq(TR:GetScroll(), 100, 'ScrollTo')
	TR:ScrollTo(99999)
	eq(TR:GetScroll(), 1713, 'ScrollTo clamps')
	TR:ScrollTo(-5)
	eq(TR:GetScroll(), 0, 'and at the top')
	TR:ScrollTo(100)
	TR:SetContentHeight(2100)
	eq(TR:GetScroll(), 100, 'the offset is kept when the content grows')
	TR:SetContentHeight(400)
	eq(TR:GetScroll(), 100, 'and when it shrinks but still scrolls')
	TR:ScrollTo(113)
	TR:SetContentHeight(350)
	eq(TR:GetScroll(), 63, 'clamped to the new range: 350 - 287')
	-- The bar's room is read back from the game a hair off: the child's width is
	-- rounded, so it is exactly whole (the whole-pixel walk allows a hair).
	for _, noise in ipairs({ 2 ^ -14, -2 ^ -14 }) do
		stub.size_noise = noise
		TR:SetContentHeight(2001)
		eq(TR.scroll:GetRight() - TR.scroll:GetLeft(), 231, 'the scroll frame is exactly 231 wide, noise ' .. noise)
		eq(TR.content:GetRight() - TR.content:GetLeft(), 231, 'and so is the child')
		stub.size_noise = 0
	end
	TR:SetContentHeight(2000)
	TR:SetContentHeight(100)
	eq(TR:GetScroll(), 0, 'content that fits: back to the top')
	eq(TR.scroll:GetWidth(), 245, 'and the bar room is gone')
	eq(TR:IsScrollLocked(), false, 'not locked (Task 8)')
	eq(#take_errors(), 0, 'no errors')
end)

test('Scroll bar under the mouse only: shown while hovered and 0.3 s after; always with it off', function()
	local st, TR = world()
	TR:SetContentHeight(2000)
	local bar = TR.scroll.ScrollBar
	local watcher = TR.watcher
	check(type(watcher:GetScript('OnUpdate')) == 'function', 'the watcher runs while the rule needs it')
	stub.time = 100
	mouse_off()
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	eq(bar:GetAlpha(), 0, 'away from the window: hidden')
	eq(TR:IsHovered(), false, 'not hovered')

	mouse_on(TR.window)
	stub.time = 101
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	eq(TR:IsHovered(), true, 'the mouse is over the window')
	eq(bar:GetAlpha(), 1, 'shown under the mouse')

	mouse_off()
	stub.time = 101.2
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	eq(bar:GetAlpha(), 1, 'still shown 0.2 s after it leaves')
	stub.time = 101.29
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	eq(bar:GetAlpha(), 1, 'and at 0.29')
	stub.time = 101.31
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	eq(bar:GetAlpha(), 0, 'hidden past 0.3 s')

	-- Back over it before the linger ends keeps it.
	mouse_on(TR.window)
	stub.time = 105
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	mouse_off()
	stub.time = 105.2
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	mouse_on(TR.window)
	stub.time = 105.4
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	mouse_off()
	stub.time = 105.6
	stub.fire_script(watcher, 'OnUpdate', 0.016)
	eq(bar:GetAlpha(), 1, 'the linger counts from the last time it was over')

	-- With it off: always shown, and no OnUpdate runs.
	TR.config.visibility.scrollbar_hover = false
	TR:UpdateConfig()
	eq(bar:GetAlpha(), 1, 'always with it off')
	eq(watcher:GetScript('OnUpdate'), nil, 'and no OnUpdate runs')
	TR.config.visibility.scrollbar_hover = true
	TR:UpdateConfig()
	check(type(watcher:GetScript('OnUpdate')) == 'function', 'on again: it runs')

	-- A hidden window needs none.
	TR.window:Hide()
	eq(watcher:GetScript('OnUpdate'), nil, 'no OnUpdate while the window is hidden')
	TR.window:Show()
	check(type(watcher:GetScript('OnUpdate')) == 'function', 'it runs again when the window shows')
	eq(#take_errors(), 0, 'no errors')
end)

test('collapsed is the header only, per character, kept in a new world with the same st.config.char', function()
	local st, TR = world()
	TR:SetContentHeight(300)
	eq(TR.window:GetHeight(), 346, 'expanded')
	eq(TR:IsCollapsed(), false, 'not collapsed')
	TR:SetCollapsed(true)
	eq(TR:IsCollapsed(), true, 'collapsed')
	eq(TR.window:GetHeight(), 40, 'the header only: 8, 24, 8')
	eq(TR.scroll:IsShown(), false, 'the scroll frame hides')
	eq(TR.header:IsShown(), true, 'the header stays')
	eq(st.config.char.tracker.collapsed, true, 'kept per character')
	eq(st.config.profile.tracker.collapsed, nil, 'not in the profile')
	TR:SetContentHeight(5000)
	eq(TR.window:GetHeight(), 40, 'whatever the content')
	eq(TR.header.collapse.icon:GetTexture(), st.icons.chevronDown, 'the chevron is down')

	-- Header off: no whole-tracker collapse, the saved state is ignored.
	TR.config.header = false
	TR:UpdateConfig()
	eq(TR:IsCollapsed(), false, 'no header: not collapsed')
	eq(TR.window:GetHeight(), 560, 'the list shows, as tall as Max height allows')
	eq(TR.scroll:IsShown(), true, 'the scroll frame shows')
	eq(st.config.char.tracker.collapsed, true, 'and the saved state is kept')
	TR.config.header = true
	TR:UpdateConfig()
	eq(TR:IsCollapsed(), true, 'Header back on: collapsed again')

	-- A new world (a reload) with the same character data.
	local char = st.config.char.tracker
	local _, TR2 = world({ enabling = function(st2) st2.config.char.tracker = char end })
	eq(TR2:IsCollapsed(), true, 'collapsed after a reload')
	eq(TR2.window:GetHeight(), 40, 'built collapsed')
	TR2:SetCollapsed(false)
	eq(TR2.window:GetHeight(), 46, 'expanded')
	eq(TR2:CharData().collapsed, false, 'saved')
	eq(#take_errors(), 0, 'no errors')
end)

test('Theme and Background: a panel in the pair; None draws none; a round trip through Blizzard redraws it', function()
	local st, TR = world()
	local window = TR.window
	eq(drawn(window), 'theme,theme,panel', "the tracker's Theme and Background, as a panel")
	eq(T.inset(window.backdrop), 2, "Thick's border")
	local fill = T.fill(window.backdrop)
	local alpha = select(4, window.backdrop:GetBackdropColor())
	eq(alpha, st.config.profile.theme.transparent and st.config.profile.theme.opacity or 1, "see-through by the theme's Background")

	TR.config.theme, TR.config.background = 'thin', 'transparent'
	TR:UpdateConfig()
	eq(drawn(window), 'thin,transparent,panel', 'a new Theme and Background')
	eq(T.inset(window.backdrop), 1, "Thin's border")

	TR.config.background = 'solid'
	TR:UpdateConfig()
	eq(select(4, window.backdrop:GetBackdropColor()), 1, 'Solid is opaque')

	TR.config.theme = 'none'
	TR:UpdateConfig()
	eq(window.backdrop.backdropInfo, nil, 'None draws none')
	eq(TR.header.line:IsShown(), true, 'the header line stays under None')
	TR.config.theme, TR.config.background = 'theme', 'theme'
	TR:UpdateConfig()
	eq(T.fill(window.backdrop), fill, 'back to its first look')

	local function count()
		local n = 0
		local function walk(f)
			n = n + 1
			for _, child in ipairs({ f:GetChildren() }) do walk(child) end
		end
		walk(window)
		return n
	end
	local before = count()
	local arts = {}
	local function expect(label)
		eq(drawn(window), 'theme,theme,panel', label .. ': still drawn as a panel')
		check(window.backdrop, label .. ': has its backdrop')
		local lr, lg, lb = TR.header.line:GetVertexColor()
		local look = st:ResolveTheme('theme', 'theme')
		eq(T.rgb(lr, lg, lb), T.rgb(unpack(look.colors.bordercolor)), label .. ": the header line wears the theme's border color")
		arts[#arts + 1] = T.art(window.backdrop)
	end
	local function switch(name)
		T.theme(name, function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
	end
	expect('Thick')
	switch('blizzard')
	expect('Blizzard')
	switch('thick')
	expect('Thick again')
	eq(arts[1], '', 'Thick draws no Blizzard art')
	check(arts[2] ~= '', "Blizzard draws its tooltip-border look: " .. arts[2])
	eq(arts[3], '', 'Thick again: the art is gone')
	eq(count(), before, 'a theme change makes no new frame')
	eq(#take_errors(), 0, 'no errors')
end)

test('UpdateConfig and a theme change make no new frame; off, none of this exists', function()
	local st, TR = world()
	-- Every frame under the tracker's own (the window and its backdrop, header,
	-- scroll frame and rows, the holder, the watcher), counted before and after.
	local function tree()
		local n = 0
		local function walk(f)
			n = n + 1
			for _, child in ipairs({ f:GetChildren() }) do walk(child) end
		end
		walk(TR.window)
		walk(TR.holder)
		walk(TR.watcher)
		return n
	end
	local before = tree()
	TR:UpdateConfig()
	TR:UpdateConfig()
	T.theme('blizzard', function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
	T.theme('thin', function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
	TR.config.grow = 'up'
	TR.config.width = 300
	TR:UpdateConfig()
	TR:SetContentHeight(900)
	TR:SetCollapsed(true)
	TR:SetCollapsed(false)
	TR:UpdateHeader({ counts = COUNTS })
	eq(tree(), before, 'no frame made after the build')

	for _, client in ipairs({ 'forever', 'retail' }) do
		local st2, TR2 = TW.world({ client = client })
		eq(TR2.holder, nil, client .. ': no holder')
		eq(TR2.window, nil, client .. ': no window')
		eq(_G.SaftUITracker, nil, client .. ': no global frame')
		eq(_G.SaftUITrackerHolder, nil, client .. ': no global holder')
		eq(st2.EditModeFrames.movers.tracker, nil, client .. ': no mover')
		eq(st2.config.profile.tracker.position, nil, client .. ': no position written')
		TR2:UpdateConfig()
		TR2:SetContentHeight(10)
		TR2:UpdateHeader(nil)
		eq(TW.counts.frames, 0, client .. ': UpdateConfig and the rest make no frame')
	end
	eq(#take_errors(), 0, 'no errors')
end)

test("General's rows: each saves and the tracker follows at once, and each resets by itself", function()
	local st, TR = world()
	local general = TR:GetConfigTable().args.general
	local function set(key, value) general.set({ 'Tracker', 'general', key }, value) end
	local args = general.args
	eq(args.width.min .. '-' .. args.width.max .. '/' .. args.width.step, '180-600/1', 'Width: 180 to 600, step 1')
	eq(args.height.name .. ' ' .. args.height.min .. '-' .. args.height.max .. '/' .. args.height.step, 'Max height 120-1600/1', 'Max height: 120 to 1600')
	eq(args.grow.values.down .. args.grow.values.up, 'DownUp', 'Grow: Down, Up')
	eq(args.grow.sorting[1], 'down', 'Down first')
	eq(args.header_font.name, 'Header font', 'the second font row')
	eq(args.text.type, 'header', 'a Text section')
	eq(args.position.order, 1000, 'Position last')

	set('width', 300)
	eq(TR.holder:GetWidth() .. ',' .. TR.window:GetWidth(), '300,300', 'Width reaches the holder and the window')
	check(args.width.default.differs(), 'Width differs from its default')
	args.width.default.reset()
	eq(TR.config.width .. ',' .. TR.holder:GetWidth() .. ',' .. TR.window:GetWidth(), '260,260,260', 'its reset applies at once')
	set('height', 400)
	eq(TR.holder:GetHeight(), 400, 'Max height reaches the holder')
	set('grow', 'up')
	eq(point(TR.window), 'BOTTOMRIGHT', 'Grow reaches the window')
	args.grow.default.reset()
	eq(point(TR.window), 'TOPRIGHT', 'and its reset')
	set('header', false)
	eq(TR.header:IsShown(), false, 'Header')
	set('count', false)
	eq(TR.header.count:IsShown(), false, 'Count')
	set('theme', 'thin')
	eq(drawn(TR.window), 'thin,theme,panel', 'Theme')
	set('background', 'solid')
	eq(drawn(TR.window), 'thin,solid,panel', 'Background')
	set('header_font', 'pixel')
	eq(TR.header.title:GetFontObject(), st:GetFont('pixel'), 'Header font')
	for _, key in ipairs({ 'theme', 'background', 'width', 'height', 'grow', 'header', 'count', 'hide_empty', 'font', 'header_font' }) do
		check(args[key].default, key .. ' has its own reset')
	end
	eq(args.position.default, nil, "Position resets through the mover's default, not a row")
	eq(#take_errors(), 0, 'no errors')
end)

test('the Position row: reads without saving while off, refuses the tracker and its holder, saves and places while on', function()
	load_test_file('lib/options_walk.lua')
	local st, TR = TW.world({})
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	local row = TR:GetConfigTable().args.general.args.position
	eq(row.type, 'position', 'a position row')
	eq(row.get({}, 'x_off'), -20, 'reads the first position')
	eq(st.config.profile.tracker.position, nil, 'reading it while off writes nothing')
	eq(row.validate({}, 'frame', 'SaftUITracker'), "The tracker's position can't be anchored to the tracker itself.", 'the window by name, off')
	eq(row.validate({}, 'frame', 'SaftUITrackerHolder'), "The tracker's position can't be anchored to the tracker itself.", 'the holder by name, off')
	eq(row.validate({}, 'frame', 'UIParent'), true, 'UIParent is fine')

	local st2, TR2 = world()
	local row2 = TR2:GetConfigTable().args.general.args.position
	eq(row2.validate({}, 'frame', 'SaftUITracker'), "The tracker's position can't be anchored to the tracker itself.", 'the window, on')
	eq(row2.validate({}, 'frame', 'SaftUITrackerHolder'), "The tracker's position can't be anchored to the tracker itself.", 'the holder, on')
	local child = CreateFrame('Frame', 'TrackerTestChild', TR2.content)
	eq(row2.validate({}, 'frame', 'TrackerTestChild') ~= true, true, 'a frame inside the window')
	row2.set({}, 'x_off', -80)
	eq(st2.config.profile.tracker.position.x_off, -80, 'saved')
	local _, _, _, x = point(TR2.holder)
	eq(x, -80, 'and the holder is there')
	eq(#take_errors(), 0, 'no errors')
end)

----------------------------------------------------------------- whole pixels

local THEMES = { 'thick', 'thin', 'blizzard' }
local NOISES = { 2 ^ -14, -2 ^ -14, 0 }

-- Each layout the window makes, as { name, setup(TR) }. Width 261 and Max
-- height 333 are set first: odd, so a half pixel would show.
local LAYOUTS = {
	{ 'expanded, with the header, empty', function(TR) TR:SetContentHeight(0) end },
	{ 'expanded, with the header, content that fits', function(TR) TR:SetContentHeight(100) end },
	{ 'expanded, no header', function(TR) TR.config.header = false; TR:UpdateConfig(); TR:SetContentHeight(100) end },
	{ 'collapsed', function(TR) TR:SetCollapsed(true) end },
	{ 'scrolling: the bar shown', function(TR)
		TR:SetContentHeight(2000)
		TR.config.visibility.scrollbar_hover = false
		TR:UpdateConfig()
	end },
	{ 'scrolling, scrolled', function(TR)
		TR:SetContentHeight(2000)
		TR:ScrollTo(137)
	end },
	{ 'Grow up, fits', function(TR) TR.config.grow = 'up'; TR:UpdateConfig(); TR:SetContentHeight(100) end },
	{ 'Grow up, scrolling', function(TR) TR.config.grow = 'up'; TR:UpdateConfig(); TR:SetContentHeight(2000) end },
	{ 'Grow up, collapsed', function(TR) TR.config.grow = 'up'; TR:UpdateConfig(); TR:SetCollapsed(true) end },
}

test('whole pixels under Thick, Thin and Blizzard, size noise up, down and off, at Width 261 and Max height 333', function()
	local checked = 0
	for _, client in ipairs({ 'forever', 'retail' }) do
		for _, theme in ipairs(THEMES) do
			for _, noise in ipairs(NOISES) do
				for _, layout in ipairs(LAYOUTS) do
					local where = ('%s, %s, noise %g, %s'):format(client, theme, noise, layout[1])
					local st, TR = world({ client = client })
					T.theme(theme, function() TR:UpdateConfig(); st:ColorsChanged('theme') end)
					TR.config.width, TR.config.height = 261, 333
					TR:UpdateConfig()
					stub.size_noise = noise
					layout[2](TR)
					TR:UpdateHeader({ counts = COUNTS })
					-- A pass again, as a refresh makes after the sizes were read back.
					TR:SetContentHeight(TR.contentHeight)
					local off = P.off(TR.window)
					eq(#off, 0, where .. ': ' .. P.report(off))
					off = P.off(TR.holder)
					eq(#off, 0, where .. ' (the holder): ' .. P.report(off))
					stub.size_noise = 0
					checked = checked + 1
				end
			end
		end
	end
	eq(checked, 2 * 3 * 3 * #LAYOUTS, 'every layout ran')
	eq(#take_errors(), 0, 'no errors')
end)
