-- RestedXP's timer bars (Timers.lua, LibCandyBar) in SaftUI's look, through
-- SaftUI-Misc/Skinning/restedxp.lua. Migrated from the rxpsim harness's
-- test_timers.lua.
local H = load_test_file('misc/restedxp_helpers.lua')
local RXP, pt = H.RXP, H.pt
local Timers = load_test_file('misc/fixtures/libcandybar.lua')

-- Fresh world: RestedXP with its timers, LibCandyBar registered (unless noCandy).
-- opts.fontSize = RestedXP's guide font size before the skin loads.
local function setup(opts)
	opts = opts or {}
	H.fresh()
	local candy = Timers.make_candy(not opts.noCandy)
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	local T = Timers.add_timers(R, candy)
	if opts.fontSize then R.Footer.text:SetFont('GameFontFace', opts.fontSize, '') end
	local RX = H.get_rx()
	local ok, err = pcall(RX.OnEnable, RX)
	assert(ok, err)
	return R, T, RX, candy
end
-- The SaftUI boxes the skin put on a bar: children that are not LibCandyBar's.
local function boxes(bar)
	local out = {}
	for _, c in ipairs({ bar:GetChildren() }) do
		if c:GetObjectType() == 'Frame' and c ~= bar.candyBarBar then table.insert(out, c) end
	end
	return out
end
local function boxAround(bar, region)
	for _, b in ipairs(boxes(bar)) do
		local tl = pt(b, 'TOPLEFT')
		if tl and tl.rel == region then return b end
	end
end
-- A box is in a (solid) template when it has the template's border width (how
-- far in its background sits) and its backdrop and border colors.
local INSETS = { thick = 2, thin = 1 }
local function inTemplate(box, name)
	local template = SaftUI.config.profile.templates[name]
	local r, g, b, a = box:GetBackdropColor()
	local br, bg, bb, ba = box:GetBackdropBorderColor()
	local bd, bo = template.backdropcolor, template.bordercolor
	return box.backdropInfo and box.backdropInfo.insets.left == INSETS[name]
		and r == bd[1] and g == bd[2] and b == bd[3] and a == bd[4]
		and br == bo[1] and bg == bo[2] and bb == bo[3] and ba == bo[4]
end

test('flight timer gets the look', function()
	local R, T = setup()
	local bar = T.Start(56, 'Sentinel Hill, Westfall')
	check(bar.candyBarBar:GetStatusBarTexture():GetTexture() == SaftUI.BLANK_TEX, 'flat bar texture')
	local r, g, b = bar.candyBarBar:GetStatusBarColor()
	check(r == 0.6 and b == 0.8, "RestedXP's purple kept")
	local _, _, _, bgAlpha = bar.candyBarBackground:GetVertexColor()
	check(bgAlpha == 0, 'own background transparent (box shows through)')
	local face, size, outline = bar.candyBarLabel:GetFont()
	check(face == SaftUI:GetFont('normal'):GetFont() and size == 9 and outline == 'OUTLINE', 'label in chat font at guide size, got ' .. tostring(face) .. ' ' .. tostring(size))
	check(bar.candyBarDuration:GetFont() == SaftUI:GetFont('normal'):GetFont(), 'time in chat font')
	check(bar:GetHeight() == 16, 'size 9 -> RestedXP minimum 16, got ' .. tostring(bar:GetHeight()))
	local barBox, iconBox = boxAround(bar, bar.candyBarBar), boxAround(bar, bar.candyBarIconFrame)
	check(barBox and inTemplate(barBox, 'thin') and barBox:IsShown(), 'bar in a thin box')
	check(iconBox and inTemplate(iconBox, 'thin') and iconBox:IsShown(), 'icon in a thin box')
	check(barBox and barBox:GetFrameLevel() == 99 and iconBox:GetFrameLevel() == 99, 'boxes under the bar (level 99)')
	local tl = pt(barBox, 'TOPLEFT')
	check(tl and tl.x == -1 and tl.y == 1, 'box 1px outside the bar')
	local sb = pt(bar.candyBarBar, 'TOPLEFT')
	check(sb and sb.rel == bar.candyBarIconFrame and sb.relPoint == 'TOPRIGHT' and sb.x == 3, 'gap between icon and bar')
end)

test('bigger font: taller bar and footer', function()
	local R, T = setup({ fontSize = 15 })
	check(R.Footer:GetHeight() == 29, 'footer 21 + 2*4 = 29, got ' .. tostring(R.Footer:GetHeight()))
	local bar = T.Start(56, 'Sentinel Hill')
	check(bar:GetHeight() == 21, 'bar 15 + 2*3 = 21 after RestedXP set 16, got ' .. tostring(bar:GetHeight()))
	check(select(2, bar.candyBarLabel:GetFont()) == 15, 'label at size 15')
	T.Sort()
	check(bar:GetHeight() == 21, 'still 21 after another SortTimers')
	local sb = pt(bar.candyBarBar, 'TOPLEFT')
	check(sb and sb.rel == bar.candyBarIconFrame and sb.x == 3, 'gap survives the re-layout')
end)

test('default footer and list', function()
	local R = setup()
	check(R.Footer:GetHeight() == 24, 'footer 16 + 2*4 = 24, got ' .. tostring(R.Footer:GetHeight()))
	local br = pt(R.ScrollFrame, 'BOTTOMRIGHT')
	check(br and br.rel == R.Footer and br.relPoint == 'TOPRIGHT' and br.x == -20 and br.y == 1, 'list ends at the footer top')
end)

test('font size change while a timer runs', function()
	local R, T = setup()
	local bar = T.Start(56, 'Sentinel Hill')
	R.Footer.text:SetFont('GameFontFace', 14, '') -- RestedXP's UpdateGuideFontSize
	check(R.Footer:GetHeight() == 28, 'footer refit to 28, got ' .. tostring(R.Footer:GetHeight()))
	check(bar:GetHeight() == 20, 'bar refit to 20, got ' .. tostring(bar:GetHeight()))
	check(select(2, bar.candyBarLabel:GetFont()) == 14, 'bar font refit to 14')
end)

test('timers sit inside the footer', function()
	local R, T = setup()
	T.Start(56, 'Sentinel Hill')
	local c = R.BarContainer
	local tl, br = pt(c, 'TOPLEFT'), pt(c, 'BOTTOMRIGHT')
	check(tl and tl.rel == R.Footer and tl.x == 5 and tl.y == -4, 'TOPLEFT inset (5, -4)')
	check(br and br.rel == R.Footer and br.x == -5 and br.y == 4, 'BOTTOMRIGHT inset (-5, 4)')
end)

test('inset before any timer starts', function()
	local R = setup()
	local tl = pt(R.BarContainer, 'TOPLEFT')
	check(tl and tl.x == 5 and tl.y == -4, 'load-time points re-placed')
end)

test('bottom orientation stacks above the title, clear of the panel', function()
	local R, T = setup()
	rawset(R.CurrentStepFrame, 'anchor', 'BOTTOM')
	T.Start(56, 'A')
	T.Start(40, 'B')
	local bl, br = pt(R.BarContainer, 'BOTTOMLEFT'), pt(R.BarContainer, 'BOTTOMRIGHT')
	check(bl and bl.rel == R.GuideName and bl.x == 0 and bl.y == 7, 'BOTTOMLEFT 7 above the title')
	check(br and br.rel == R.GuideName and br.x == 0 and br.y == 7, 'BOTTOMRIGHT 7 above the title')
end)

test('stopped bar handed to another addon is plain', function()
	local R, T, _, candy = setup()
	local bar = T.Start(56, 'Sentinel Hill')
	T.StopTimer('Sentinel Hill')
	for _, b in ipairs(boxes(bar)) do check(not b:IsShown(), 'box hidden on stop') end
	local other = candy:New('bigwigs-tex', 200, 20)
	check(other == bar, 'LibCandyBar recycled the same bar')
	other:SetIcon('boss-icon')
	other:SetHeight(20)
	other:Start()
	other:SetHeight(24)
	check(other:GetHeight() == 24, "other addon's height kept, got " .. tostring(other:GetHeight()))
	check(other.candyBarBar:GetStatusBarTexture():GetTexture() == 'bigwigs-tex', "other addon's texture kept")
	for _, b in ipairs(boxes(other)) do check(not b:IsShown(), 'no SaftUI box on the other bar') end
	local sb = pt(other.candyBarBar, 'TOPLEFT')
	check(sb and sb.x == 0, 'no SaftUI gap on the other bar')
	check(select(1, other.candyBarLabel:GetFont()) == 'GameFontHighlightSmallOutline', 'LibCandyBar font back')
end)

test('flight ends (hidden, not stopped) and the bar is reused', function()
	local R, T = setup({ fontSize = 15 })
	local bar = T.Start(56, 'Sentinel Hill')
	bar:Hide() -- PLAYER_CONTROL_GAINED
	check(next(R.BarContainer.bars) == nil, 'RestedXP dropped it from bars')
	local again = T.Start(80, 'Lakeshire')
	check(again == bar, 'RestedXP reused its pooled bar')
	check(again:GetHeight() == 21, 'reused bar skinned again')
	local barBox = boxAround(again, again.candyBarBar)
	check(barBox and barBox:IsShown(), 'box shown again')
end)

test('v2 window: timers left alone', function()
	local R, T = setup()
	local bar = T.Start(56, 'Sentinel Hill')
	R.GuideName:Hide() -- DisableLegacyGuideWindow
	T.v2 = CreateFrame('Frame', nil, UIParent)
	T.Sort()
	for _, b in ipairs(boxes(bar)) do check(not b:IsShown(), 'boxes hidden for v2') end
	local tl = pt(R.BarContainer, 'TOPLEFT')
	check(tl and tl.rel == T.v2 and tl.x == 0 and tl.y == 0, "v2 footer's points untouched")
	bar:SetHeight(30)
	check(bar:GetHeight() == 30, 'height not forced under v2')
end)

test('no LibCandyBar: timers untouched, no errors', function()
	local R, T = setup({ noCandy = true })
	local bar = T.Start(56, 'Sentinel Hill')
	check(bar.candyBarBar:GetStatusBarTexture():GetTexture() == 'Interface\\CHARACTERFRAME\\BarFill', "RestedXP's texture kept")
	check(#boxes(bar) == 0, 'no boxes')
	check(bar:GetHeight() == 16, '16px')
end)

test('chat font change follows', function()
	local R, T, RX = setup()
	local bar = T.Start(56, 'Sentinel Hill')
	SaftUI.config.profile.chat.font = 'pixel'
	RX:UpdateConfig()
	check(bar.candyBarLabel:GetFont() == SaftUI:GetFont('pixel'):GetFont(), 'timer follows chat font, got ' .. tostring(bar.candyBarLabel:GetFont()))
end)
