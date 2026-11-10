-- The RestedXP skin (SaftUI-Misc/Skinning/restedxp.lua), part 1: module,
-- setup, fonts, the guide panel's frame. Migrated from the rxpsim harness's
-- test_task1.lua.
local H = load_test_file('misc/restedxp_helpers.lua')
local RXP, near, font, pt = H.RXP, H.near, H.font, H.pt

-- Fresh world with RestedXP loaded and the module enabled.
local function setup()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	local RX = H.get_rx()
	RX:OnEnable()
	return R, RX
end
-- The SaftUI panel parented to RXPFrame.
local function findPanel(R)
	for _, c in ipairs({ R:GetChildren() }) do
		if not RXP.is_rxp(c) and c.backdrop then return c end
	end
end
local function dividers(panel)
	local out = {}
	for _, r in ipairs({ panel:GetRegions() }) do
		if r:GetObjectType() == 'Texture' and H.color_of(r) then table.insert(out, r) end
	end
	return out
end

test('no_rxp_no_error', function()
	H.fresh()
	local RX = H.get_rx()
	local ok, err = pcall(RX.OnEnable, RX)
	check(ok, 'no_rxp_no_error: OnEnable runs without error' .. (ok and '' or (': ' .. tostring(err))))
	check(RX.frames == nil, 'no_rxp_no_error: no frames collected')
	-- the late-load event still can't set anything up
	stub.fire_event('ADDON_LOADED', 'RXPGuides')
	check(#take_errors() == 0, 'no_rxp_no_error: stray ADDON_LOADED is silent')
end)

test('silent_when_frame_missing', function()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	rawset(R, 'Footer', nil)
	local RX = H.get_rx()
	local ok, err = pcall(RX.OnEnable, RX)
	check(ok, 'silent_when_frame_missing: no error' .. (ok and '' or (': ' .. tostring(err))))
	check(RX.frames == nil, 'silent_when_frame_missing: setup skipped')
end)

test('late_load_sets_up', function()
	H.fresh()
	local RX = H.get_rx()
	RX:OnEnable()
	local R = RXP.make()
	stub.fire_event('ADDON_LOADED', 'SomeOtherAddon')
	check(R.GuideName.bg:IsShown(), 'late_load_sets_up: other addon does nothing')
	stub.fire_event('ADDON_LOADED', 'RXPGuides')
	check(not R.GuideName.bg:IsShown() and not R.GuideName.icon:IsShown()
		and not R.GuideName.classIcon:IsShown() and not R.Footer.bg:IsShown(),
		'late_load_sets_up: banner textures hidden')
	-- The event is unregistered: a later one no longer reaches the handler.
	local calls = 0
	local handler = RX.ADDON_LOADED
	RX.ADDON_LOADED = function(...) calls = calls + 1; return handler(...) end
	stub.fire_event('ADDON_LOADED', 'RXPGuides')
	check(calls == 0, 'late_load_sets_up: event unregistered')
end)

test('chrome_skinned', function()
	local R = setup()
	check(R.GuideName.backdropInfo == nil and R.Footer.backdropInfo == nil and R.BottomFrame.backdropInfo == nil,
		'chrome_skinned: backdrops cleared')
	local panel = findPanel(R)
	check(panel ~= nil, 'chrome_skinned: guide panel exists')
	check(panel and H.drawn(panel) == 'theme,theme,panel', "chrome_skinned: chat's Theme and Background, as a panel")
	local tl, br = pt(panel, 'TOPLEFT'), pt(panel, 'BOTTOMRIGHT')
	check(tl and tl.rel == R.GuideName and tl.relPoint == 'TOPLEFT', 'chrome_skinned: TOPLEFT to GuideName TOPLEFT')
	check(br and br.rel == R.Footer and br.relPoint == 'BOTTOMRIGHT', 'chrome_skinned: BOTTOMRIGHT to Footer BOTTOMRIGHT')
	check(panel:GetFrameLevel() == R:GetFrameLevel() + 1, 'chrome_skinned: panel level is RXPFrame + 1')
	check(panel:GetParent() == R, 'chrome_skinned: parented to RXPFrame')
end)

test('title_font', function()
	local R = setup()
	-- The face the skin applies is SaftUI's title font's, not RestedXP's or the chat font's.
	check(SaftUI:GetFont('title'):GetFont() ~= SaftUI:GetFont('normal'):GetFont(), 'title_font: the title face is its own')
	check(font(R.GuideName.text, 'title', 14, 'OUTLINE'), 'title_font: Colus at 11+3')
	R.GuideName.text:SetFont('GameFontFace', 13, '')
	check(font(R.GuideName.text, 'title', 16, 'OUTLINE'), 'title_font: follows RestedXP size change (13 -> 16)')
end)

test('footer_font', function()
	local R = setup()
	check(font(R.Footer.text, 'normal', 9, 'OUTLINE'), 'footer_font: AgencyFB at 9')
end)

test('font_waits_for_first_setfont', function()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	-- a FontString RestedXP hasn't given a font yet
	local R = RXP.make({ footer_font = false })
	local RX = H.get_rx()
	RX:OnEnable()
	check(R.Footer.text:GetFont() == nil, 'font_waits_for_first_setfont: untouched without a font')
	R.Footer.text:SetFont('GameFontFace', 10, '')
	check(font(R.Footer.text, 'normal', 10, 'OUTLINE'), 'font_waits_for_first_setfont: styled on first SetFont')
end)

test('title_recentred', function()
	local R = setup()
	local l, r = pt(R.GuideName.text, 'LEFT'), pt(R.GuideName.text, 'RIGHT')
	check(l and r and l.rel == R.GuideName and r.rel == R.GuideName, 'title_recentred: anchored to GuideName')
	check(l and r and l.x == 4 and r.x == -4 and l.y == 0 and r.y == 0, 'title_recentred: equal insets')
end)

test('scroll_below_title', function()
	local R = setup()
	local tl, br = pt(R.ScrollFrame, 'TOPLEFT'), pt(R.ScrollFrame, 'BOTTOMRIGHT')
	check(tl and tl.rel == R.GuideName and tl.relPoint == 'BOTTOMLEFT' and tl.x == 5 and tl.y == 0,
		'scroll_below_title: TOPLEFT under GuideName')
	check(br and br.rel == R.Footer and br.relPoint == 'TOPRIGHT' and br.x == -20 and br.y == 1, 'scroll_below_title: BOTTOMRIGHT at the footer top')
end)

test('dividers_title_footer', function()
	local R = setup()
	local ds = dividers(findPanel(R))
	check(#ds == 2, 'dividers_title_footer: two dividers')
	local title, foot
	for _, d in ipairs(ds) do
		local tl = pt(d, 'TOPLEFT')
		if tl and tl.rel == R.GuideName and tl.relPoint == 'BOTTOMLEFT' then title = d end
		local bl = pt(d, 'BOTTOMLEFT')
		if bl and bl.rel == R.Footer and bl.relPoint == 'TOPLEFT' then foot = d end
	end
	check(title and pt(title, 'TOPRIGHT').rel == R.GuideName and pt(title, 'TOPRIGHT').relPoint == 'BOTTOMRIGHT',
		'dividers_title_footer: under the guide name')
	check(foot and pt(foot, 'BOTTOMRIGHT').rel == R.Footer and pt(foot, 'BOTTOMRIGHT').relPoint == 'TOPRIGHT',
		'dividers_title_footer: at the footer top')
	for _, d in ipairs(ds) do
		local c = H.color_of(d)
		check(near(c[1], 0.3) and near(c[2], 0.3) and near(c[3], 0.3) and near(c[4], 0.5), 'dividers_title_footer: colour')
		check(d:GetHeight() == 1, 'dividers_title_footer: 1px tall')
	end
end)

test('theme_reapply_stays_skinned', function()
	local R = setup()
	R:UpdateVisuals()
	check(R.GuideName.backdropInfo == nil and R.Footer.backdropInfo == nil and R.BottomFrame.backdropInfo == nil,
		'theme_reapply_stays_skinned: backdrops still nil')
	check(not R.GuideName.bg:IsShown() and not R.GuideName.icon:IsShown()
		and not R.GuideName.classIcon:IsShown() and not R.Footer.bg:IsShown(),
		'theme_reapply_stays_skinned: banner textures still hidden')
end)

test('v2_hides_guide_panel', function()
	local R = setup()
	local panel = findPanel(R)
	check(panel:IsShown(), 'v2_hides_guide_panel: shown with GuideName at start')
	R.GuideName:Hide()
	check(not panel:IsShown(), 'v2_hides_guide_panel: hides with GuideName')
	R.GuideName:Show()
	check(panel:IsShown(), 'v2_hides_guide_panel: shows again')
end)

test('v2_hidden_at_setup', function()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	R.GuideName:Hide()
	local RX = H.get_rx()
	RX:OnEnable()
	check(not findPanel(R):IsShown(), 'v2_hidden_at_setup: panel starts hidden')
end)

test('config_follows_chat', function()
	local R, RX = setup()
	local chat = SaftUI.config.profile.chat
	-- Thin's own border color, so the divider shows it follows the chat's Theme.
	SaftUI.config.profile.templates.thin.bordercolor = { 0.5, 0.2, 0.2, 1 }
	chat.font, chat.theme, chat.background = 'pixel', 'thin', 'solid'
	RX:UpdateConfig()
	check(font(R.Footer.text, 'pixel', 9, 'MONOCHROMEOUTLINE'), 'config_follows_chat: font')
	check(H.drawn(findPanel(R)) == 'thin,solid,panel', 'config_follows_chat: Theme and Background')
	local c = H.color_of(dividers(findPanel(R))[1])
	check(near(c[1], 0.5) and near(c[2], 0.2) and near(c[4], 0.5), 'config_follows_chat: divider colour')
	SaftUI.config.profile.chat = nil
	local t, b, f = RX:GetStyle()
	check(t == 'theme' and b == 'theme' and f == 'normal', 'config_follows_chat: defaults when chat config is missing')
end)

test('chat_update_hooked', function()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local Chat = H.make_chat() -- UpdateConfig ends in ApplyAppearance, as SaftUI-Chat's does
	RXP.make()
	local RX = H.get_rx()
	local calls = 0
	function RX:UpdateConfig() calls = calls + 1 end
	RX:OnEnable()
	Chat:UpdateConfig()
	check(calls == 1, 'chat_update_hooked: Chat:UpdateConfig triggers RX:UpdateConfig')
end)
