-- The RestedXP skin (SaftUI-Misc/Skinning/restedxp.lua), part 2: the step list
-- and the scroll bar. Migrated from the rxpsim harness's test_task2.lua.
--
-- Hovering a step uses the stubs' cursor: H.cursor_on(frame) puts it in the
-- step, and the skin's IsMouseMotionFocus / IsMouseOver then answer from the
-- steps' real rectangles.
local H = load_test_file('misc/restedxp_helpers.lua')
local RXP, near, font, pt, colored = H.RXP, H.near, H.font, H.pt, H.colored

local function setup()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	H.get_rx():OnEnable()
	return R
end
local function pool(R) return R.ScrollChild.framePool end

test('list_frames_skinned', function()
	local R = setup()
	R.LoadGuide(5)
	check(#pool(R) == 5, 'list_frames_skinned: five frames')
	for i, f in ipairs(pool(R)) do
		check(f.backdropInfo == nil, 'list_frames_skinned: backdrop cleared ' .. i)
		check(font(f.text, 'normal', 9, 'OUTLINE'), 'list_frames_skinned: text font ' .. i)
		check(font(f.number.text, 'normal', 8, 'OUTLINE'), 'list_frames_skinned: number font ' .. i)
		local r, g, b = f.number.text:GetTextColor()
		check(H.is_grey(r, g, b), 'list_frames_skinned: number grey ' .. i)
	end
end)

test('list_dividers', function()
	local R = setup()
	R.LoadGuide(5)
	for i, f in ipairs(pool(R)) do
		local ds = colored(f, 0.3, 0.3, 0.3, 0.5)
		if i == 1 then
			check(#ds == 0, 'list_dividers: frame 1 has none')
		else
			check(#ds == 1, 'list_dividers: one on frame ' .. i)
			local d = ds[1]
			local bl, br = d and pt(d, 'BOTTOMLEFT'), d and pt(d, 'BOTTOMRIGHT')
			check(bl and bl.rel == f and bl.relPoint == 'TOPLEFT' and bl.y == 1, 'list_dividers: BOTTOMLEFT ' .. i)
			check(br and br.rel == f and br.relPoint == 'TOPRIGHT' and br.y == 1, 'list_dividers: BOTTOMRIGHT ' .. i)
		end
	end
end)

test('hidden_step_divider_fades', function()
	local R = setup()
	R.LoadGuide(3)
	local f = pool(R)[2]
	local d = colored(f, 0.3, 0.3, 0.3, 0.5)[1]
	check(d:GetParent() == f, 'hidden_step_divider_fades: region of its step')
	check(d:GetEffectiveAlpha() > 0, 'hidden_step_divider_fades: visible at first')
	f:SetAlpha(0)
	check(d:GetEffectiveAlpha() == 0, 'hidden_step_divider_fades: fades with the step')
end)

local function highlightOf(f)
	return colored(f, 0.3, 0.3, 0.4 * 0 + 0.3, 0.4)[1]
end

test('hover_highlight', function()
	local R = setup()
	R.LoadGuide(3)
	local f = pool(R)[2]
	local h = highlightOf(f)
	check(h ~= nil, 'hover_highlight: highlight texture exists')
	check(h and h:GetDrawLayer() == 'BACKGROUND', 'hover_highlight: BACKGROUND layer')
	check(h and not h:IsShown(), 'hover_highlight: hidden at rest')
	H.cursor_on(f)
	stub.fire_script(f, 'OnEnter')
	check(h and h:IsShown(), 'hover_highlight: shown on enter')
	H.cursor_off()
	stub.fire_script(f, 'OnLeave')
	check(h and not h:IsShown(), 'hover_highlight: hidden on leave')
end)

test('reload_guide_keeps_skin', function()
	local R = setup()
	local counts = H.count_hooks(function()
		R.LoadGuide(5)
		R.LoadGuide(7)
	end)
	check(#pool(R) == 7, 'reload_guide_keeps_skin: seven frames')
	for i, f in ipairs(pool(R)) do
		check(f.backdropInfo == nil, 'reload_guide_keeps_skin: backdrop ' .. i)
		check(font(f.text, 'normal', 9, 'OUTLINE'), 'reload_guide_keeps_skin: font ' .. i)
		check(counts[f] and counts[f].SetBackdropColor == 1 and counts[f].SetBackdrop == 1,
			'reload_guide_keeps_skin: hooked once ' .. i)
		check(#colored(f, 0.3, 0.3, 0.3, 0.5) == (i == 1 and 0 or 1), 'reload_guide_keeps_skin: one divider ' .. i)
	end
	local f = pool(R)[6]
	local h = highlightOf(f)
	H.cursor_on(f)
	stub.fire_script(f, 'OnEnter')
	check(h and h:IsShown(), 'reload_guide_keeps_skin: hover works after reload')
end)

test('scrollbar_flat', function()
	local R = setup()
	R.UpdateScrollBar()
	local bar = R.ScrollFrame.ScrollBar
	for _, name in ipairs({ 'ScrollUpButton', 'ScrollDownButton' }) do
		check(bar[name]:GetAlpha() == 0 and bar[name]:IsMouseEnabled() == false, 'scrollbar_flat: ' .. name .. ' hidden and inert')
	end
	local thumb = bar:GetThumbTexture()
	check(thumb:GetTexture() == SaftUI.BLANK_TEX, 'scrollbar_flat: blank thumb')
	check(thumb:GetWidth() == 4 and thumb:GetHeight() == 32, 'scrollbar_flat: thumb 4x32')
	local r, g, b = thumb:GetVertexColor()
	check(H.is_grey(r, g, b), 'scrollbar_flat: thumb grey')
	local track
	for _, t in ipairs({ bar:GetRegions() }) do
		if t ~= thumb and H.color_of(t) and t:GetDrawLayer() == 'BACKGROUND' then track = t end
	end
	check(track ~= nil, 'scrollbar_flat: track texture')
	check(track and track:GetWidth() == 4 and near(H.color_of(track)[4], 0.5) and H.color_of(track)[1] == 0, 'scrollbar_flat: track look')
	local shown = 0
	for _, t in ipairs({ bar:GetRegions() }) do if t:IsShown() then shown = shown + 1 end end
	check(shown == 2, 'scrollbar_flat: only thumb and track shown (' .. shown .. ')')
	local tl, bl = pt(bar, 'TOPLEFT'), pt(bar, 'BOTTOMLEFT')
	check(tl and tl.rel == R.ScrollFrame and tl.relPoint == 'TOPRIGHT' and tl.x == 6 and tl.y == 0, 'scrollbar_flat: TOPLEFT')
	check(bl and bl.rel == R.ScrollFrame and bl.relPoint == 'BOTTOMRIGHT' and bl.x == 6 and bl.y == 0, 'scrollbar_flat: BOTTOMLEFT')
	check(bar:GetWidth() == 8, 'scrollbar_flat: width 8')
end)

test('scrollbar_skinned_at_setup', function()
	local R = setup()
	check(R.ScrollFrame.ScrollBar:GetWidth() == 8, 'scrollbar_skinned_at_setup: skinned without waiting for a hook')
end)

test('config_recolours', function()
	local R = setup()
	R.LoadGuide(3)
	local RX = H.get_rx()
	-- The highlight is SaftUI's header strip: the theme's border color, faint.
	-- The divider is the chat panel's border color, here Thin's.
	local templates = SaftUI.config.profile.templates
	templates.thick.bordercolor = { 0.1, 0.2, 0.3, 1 }
	templates.thin.bordercolor = { 0.5, 0.2, 0.2, 1 }
	SaftUI.config.profile.chat.template = 'thin'
	RX:UpdateConfig()
	local h = colored(pool(R)[2], 0.1, 0.2, 0.3, 0.4)[1]
	check(h ~= nil, 'config_recolours: highlight follows profile')
	check(#colored(pool(R)[2], 0.5, 0.2, 0.2, 0.5) == 1, 'config_recolours: list divider follows template')
end)
