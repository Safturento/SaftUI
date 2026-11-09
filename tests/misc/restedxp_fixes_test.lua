-- The RestedXP skin (SaftUI-Misc/Skinning/restedxp.lua): the final review fix
-- wave (final-fix-findings.md, findings 1-6). Migrated from the rxpsim
-- harness's test_fixes.lua.
local H = load_test_file('misc/restedxp_helpers.lua')
local RXP, font, pt, colored = H.RXP, H.font, H.pt, H.colored

-- Fresh world with RestedXP loaded; before(R) runs before the module is enabled.
-- Returns R, RX, and OnEnable's pcall result.
local function setup(before)
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	if before then before(R) end
	local RX = H.get_rx()
	local ok, err = pcall(RX.OnEnable, RX)
	return R, RX, ok, err
end
local function divider(f) return colored(f, 0.3, 0.3, 0.3, 0.5)[1] end
local function highlightOf(f) return colored(f, 0.3, 0.3, 0.3, 0.4)[1] end
-- The SaftUI panel parented to RXPFrame.
local function guidePanel(R)
	for _, c in ipairs({ R:GetChildren() }) do
		if not RXP.is_rxp(c) and c.backdrop then return c end
	end
end
-- The SaftUI panel behind the current steps.
local function stepsPanel(R)
	return H.panels_of(R.CurrentStepFrame)
end
local function footerLine(R)
	for _, t in ipairs({ guidePanel(R):GetRegions() }) do
		local bl = t:GetObjectType() == 'Texture' and pt(t, 'BOTTOMLEFT')
		if bl and bl.rel == R.Footer then return t end
	end
end

------------------------------------------------- 1: the current steps' gap
local function topAnchored(R, name)
	local cur = R.CurrentStepFrame
	local bl, br = pt(cur, 'BOTTOMLEFT'), pt(cur, 'BOTTOMRIGHT')
	check(cur:GetNumPoints() == 2, name .. ': only two points (' .. cur:GetNumPoints() .. ')')
	check(bl and bl.rel == R.GuideName and bl.relPoint == 'TOPLEFT' and bl.x == 0 and bl.y == 9,
		name .. ': BOTTOMLEFT 9 above GuideName (y=' .. tostring(bl and bl.y) .. ')')
	check(br and br.rel == R.GuideName and br.relPoint == 'TOPRIGHT' and br.x == 0 and br.y == 9,
		name .. ': BOTTOMRIGHT 9 above GuideName (y=' .. tostring(br and br.y) .. ')')
end
local function bottomAnchored(R, name)
	local cur = R.CurrentStepFrame
	local tl, tr = pt(cur, 'TOPLEFT'), pt(cur, 'TOPRIGHT')
	check(cur:GetNumPoints() == 2, name .. ': only two points (' .. cur:GetNumPoints() .. ')')
	check(tl and tl.rel == R and tl.relPoint == 'BOTTOMLEFT' and tl.x == 3 and tl.y == -7,
		name .. ': TOPLEFT 7 below RXPFrame (y=' .. tostring(tl and tl.y) .. ')')
	check(tr and tr.rel == R and tr.relPoint == 'BOTTOMRIGHT' and tr.x == -3 and tr.y == -7,
		name .. ': TOPRIGHT 7 below RXPFrame (y=' .. tostring(tr and tr.y) .. ')')
end

test('f1_setup_top', function()
	local R = setup()
	topAnchored(R, 'f1_setup_top')
end)

test('f1_step_advance_top', function()
	local R = setup()
	for _ = 1, 3 do R.SetStepFrameAnchor() end -- updateBottomFrame, each step advance
	topAnchored(R, 'f1_step_advance_top')
end)

test('f1_bottom_setting', function()
	local R = setup()
	R._setting = 'bottom'
	R.SetStepFrameAnchor()
	bottomAnchored(R, 'f1_bottom_setting')
	R.SetStepFrameAnchor()
	bottomAnchored(R, 'f1_bottom_setting again')
end)

test('f1_flips', function()
	local R = setup()
	R.SetStepFrameAnchor('bottom') -- top setting, flipped near the top of the screen
	bottomAnchored(R, 'f1_flips to bottom')
	R._setting = 'bottom'
	R.SetStepFrameAnchor('top') -- bottom setting, flipped near the bottom
	topAnchored(R, 'f1_flips to top')
end)

test('f1_mouse_up_local_call', function()
	local R = setup()
	R._setting = 'bottom'
	stub.fire_script(R, 'OnMouseUp')
	bottomAnchored(R, 'f1_mouse_up bottom')
	R._setting = 'top'
	stub.fire_script(R, 'OnMouseUp')
	topAnchored(R, 'f1_mouse_up top')
end)

test('f1_setup_in_bottom_mode', function()
	local R = setup(function(R)
		R._setting = 'bottom'
		R.SetStepFrameAnchor() -- RestedXP's login anchor, before SaftUI sets up
	end)
	bottomAnchored(R, 'f1_setup_in_bottom_mode')
	check(pt(R.CurrentStepFrame, 'BOTTOMLEFT') == nil and pt(R.CurrentStepFrame, 'BOTTOMRIGHT') == nil,
		'f1_setup_in_bottom_mode: no bottom points added')
end)

test('f1_other_points_alone', function()
	local R = setup()
	local cur = R.CurrentStepFrame
	cur:ClearAllPoints()
	cur:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 10, 20)
	cur:SetPoint('TOPLEFT', R.GuideName, 'BOTTOMLEFT', 0, 4)
	check(pt(cur, 'BOTTOMLEFT').y == 20, 'f1_other_points_alone: a point on another frame is left as set')
	check(pt(cur, 'TOPLEFT').y == 4, 'f1_other_points_alone: a top point on GuideName is left as set')
end)

-------------------------------------------- 2: chat's live option changes
test('f2_options_setter_restyles', function()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local Chat = H.make_chat()
	local R = RXP.make()
	H.get_rx():OnEnable()
	Chat:SetOption('font', 'pixel')
	check(font(R.Footer.text, 'pixel', 9, 'MONOCHROMEOUTLINE'), 'f2_options_setter_restyles: font follows the setter')
	Chat:SetOption('template', 'thick')
	check(guidePanel(R).backdrop.template == 'thick', 'f2_options_setter_restyles: template follows the setter')
end)

test('f2_profile_change', function()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local Chat = H.make_chat()
	local R = RXP.make()
	H.get_rx():OnEnable()
	SaftUI.config.profile.chat.font = 'pixel'
	Chat:UpdateConfig()
	check(font(R.Footer.text, 'pixel', 9, 'MONOCHROMEOUTLINE'), 'f2_profile_change: UpdateConfig (through ApplyAppearance) restyles')
end)

test('f2_chat_without_apply_appearance', function()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local Chat = SaftUI:NewModule('Chat')
	function Chat:UpdateConfig() end
	RXP.make()
	local RX = H.get_rx()
	local ok, err = pcall(RX.OnEnable, RX)
	check(ok, 'f2_chat_without_apply_appearance: no error' .. (ok and '' or (': ' .. tostring(err))))
	check(RX.frames ~= nil, 'f2_chat_without_apply_appearance: still sets up')
end)

----------------------------------------------- 3: missing hook targets
local targets = {
	{ 'UpdateVisuals', function(R) return R end },
	{ 'UpdateScrollBar', function(R) return R end },
	{ 'UpdateFrame', function(R) return R.BottomFrame end },
	{ 'UpdateText', function(R) return R.CurrentStepFrame end },
}
for _, t in ipairs(targets) do
	local key, owner = t[1], t[2]
	local name = 'f3_missing_' .. key
	test(name, function()
		local R, RX, ok, err = setup(function(R) rawset(owner(R), key, nil) end)
		check(ok, name .. ': no error' .. (ok and '' or (': ' .. tostring(err))))
		check(RX.frames == nil, name .. ': RX.frames nil')
		check(R.GuideName.backdropInfo ~= nil and R.Footer.backdropInfo ~= nil and R.BottomFrame.backdropInfo ~= nil,
			name .. ': no backdrop cleared')
		check(R.GuideName.bg:IsShown() and R.Footer.bg:IsShown(), name .. ': banner left alone')
		check(guidePanel(R) == nil and stepsPanel(R) == nil, name .. ': no panels made')
		check(font(R.GuideName.text, 'GameFontFace', 11, ''), name .. ': title font left alone')
		check(rawget(R.CurrentStepFrame, 'SetPoint') == nil and pt(R.CurrentStepFrame, 'BOTTOMLEFT').y == 2,
			name .. ': current steps left alone')
	end)
end

test('f3_no_backdrop_mixin', function()
	local R, RX, ok, err = setup(function(R)
		for _, k in ipairs(RXP.BACKDROP_METHODS) do rawset(R.BottomFrame, k, nil) end
	end)
	check(ok, 'f3_no_backdrop_mixin: no error' .. (ok and '' or (': ' .. tostring(err))))
	check(RX.frames ~= nil and R.GuideName.backdropInfo == nil and guidePanel(R) ~= nil,
		'f3_no_backdrop_mixin: the rest is skinned')
end)

test('f3_no_setbackdrop', function()
	local R, RX, ok, err = setup(function(R) rawset(R.GuideName, 'SetBackdrop', nil) end)
	check(ok, 'f3_no_setbackdrop: no error' .. (ok and '' or (': ' .. tostring(err))))
	check(R.GuideName.backdropInfo ~= nil, 'f3_no_setbackdrop: a backdrop it cannot keep off is left alone')
	check(R.Footer.backdropInfo == nil, 'f3_no_setbackdrop: the rest is skinned')
end)

test('f3_list_row_without_mixin', function()
	local R = setup()
	R.LoadGuide(2)
	local f = CreateFrame('Frame', nil, R.ScrollChild) -- no BackdropTemplate
	f.text = f:CreateFontString(nil, 'OVERLAY')
	f.text:SetFont('GameFontFace', 9, '')
	f.number = CreateFrame('Frame', nil, f)
	f.number.text = f.number:CreateFontString(nil, 'OVERLAY')
	f.number.text:SetFont('GameFontFace', 8, '')
	R.ScrollChild.framePool[3] = f
	local ok, err = pcall(R.BottomFrame.UpdateFrame)
	check(ok, 'f3_list_row_without_mixin: no error' .. (ok and '' or (': ' .. tostring(err))))
	check(font(f.text, 'normal', 9, 'OUTLINE'), 'f3_list_row_without_mixin: still gets the font')
end)

------------------------------------------------------ 4: sticky highlight
test('f4_leave_into_menu', function()
	local R = setup()
	R.LoadGuide(3)
	local f = R.ScrollChild.framePool[2]
	local h = highlightOf(f)
	H.cursor_on(f)
	stub.fire_script(f, 'OnEnter')
	check(h and h:IsShown(), 'f4_leave_into_menu: shown on enter')
	-- a right-click opens RestedXP's menu at the cursor, over the step: it
	-- covers the cursor, mouse-enabled and above the window
	local menu = CreateFrame('Frame', nil, UIParent)
	menu:SetFrameStrata('FULLSCREEN_DIALOG')
	menu:SetSize(100, 100)
	menu:SetPoint('CENTER', f, 'CENTER', 0, 0)
	menu:EnableMouse(true)
	check(f:IsMouseOver() and not f:IsMouseMotionFocus(), 'f4_leave_into_menu: the step is under the cursor but not its focus')
	stub.fire_script(f, 'OnLeave')
	check(h and not h:IsShown(), 'f4_leave_into_menu: hidden when the menu takes the cursor')
end)

test('f4_fallback_without_api', function()
	local R = setup()
	getmetatable(UIParent).__index.IsMouseMotionFocus = nil -- a client without the API
	R.LoadGuide(3)
	local f = R.ScrollChild.framePool[2]
	local h = highlightOf(f)
	H.cursor_on(f)
	local ok, err = pcall(stub.fire_script, f, 'OnEnter')
	check(ok and h:IsShown(), 'f4_fallback_without_api: IsMouseOver shows it' .. (ok and '' or (': ' .. tostring(err))))
	H.cursor_off()
	stub.fire_script(f, 'OnLeave')
	check(not h:IsShown(), 'f4_fallback_without_api: and hides it')
end)

--------------------------------------------------- 5: the footer divider
test('f5_footer_line_follows_list', function()
	local R = setup()
	local line = footerLine(R)
	check(line and line:IsShown(), 'f5_footer_line_follows_list: shown with the list')
	R.BottomFrame:Hide()
	check(line and not line:IsShown(), 'f5_footer_line_follows_list: hidden with the list')
	R.BottomFrame:Show()
	check(line and line:IsShown(), 'f5_footer_line_follows_list: shown again')
end)

test('f5_list_hidden_at_setup', function()
	local R = setup(function(R) R.BottomFrame:Hide() end)
	local line = footerLine(R)
	check(line and not line:IsShown(), 'f5_list_hidden_at_setup: starts hidden')
end)

------------------------------------- 6: dividers follow the visible steps
local function current(R, steps)
	R.ClearCurrentSteps()
	for _, s in ipairs(steps) do R.AddCurrentStep(s) end
	R.CurrentStepFrame.UpdateText()
	return R.CurrentStepFrame.framePool
end

test('f6_hidden_first_current_step', function()
	local R = setup()
	local pool = current(R, { { elements = 1, hidden = true }, { elements = 2 }, { elements = 2 } })
	check(not divider(pool[1]):IsShown(), 'f6_hidden_first_current_step: none on the hidden step')
	check(not divider(pool[2]):IsShown(), 'f6_hidden_first_current_step: none on the first visible step')
	check(divider(pool[3]):IsShown(), 'f6_hidden_first_current_step: one on the next')
	check(stepsPanel(R):IsShown(), 'f6_hidden_first_current_step: panel shown')
end)

test('f6_hidden_middle_current_step', function()
	local R = setup()
	local pool = current(R, { { elements = 1 }, { elements = 1, hidden = true }, { elements = 1 } })
	check(not divider(pool[2]):IsShown(), 'f6_hidden_middle_current_step: none on the hidden step')
	check(divider(pool[3]):IsShown(), 'f6_hidden_middle_current_step: one on the step after it')
end)

test('f6_all_stacked_hidden', function()
	local R = setup()
	current(R, { { elements = 1, hidden = true }, { elements = 1, hidden = true } })
	check(R.CurrentStepFrame:GetHeight() > 2, 'f6_all_stacked_hidden: RestedXP leaves a 7px frame (' .. R.CurrentStepFrame:GetHeight() .. ')')
	check(not stepsPanel(R):IsShown(), 'f6_all_stacked_hidden: panel hidden')
	current(R, { { elements = 1, hidden = true }, { elements = 1, tip = true } })
	check(not stepsPanel(R):IsShown(), 'f6_all_stacked_hidden: a tip alone does not show it')
	current(R, { { elements = 1 } })
	check(stepsPanel(R):IsShown(), 'f6_all_stacked_hidden: shown again with a visible step')
end)

test('f6_login_flash', function()
	local R = setup()
	check(R.CurrentStepFrame:GetHeight() == 25, 'f6_login_flash: RestedXP starts the frame at 25')
	check(not stepsPanel(R):IsShown(), 'f6_login_flash: panel hidden before any step')
end)

test('f6_fewer_steps', function()
	local R = setup()
	current(R, { { elements = 1 }, { elements = 1 }, { elements = 1 } })
	local pool = current(R, { { elements = 1 } })
	check(stepsPanel(R):IsShown(), 'f6_fewer_steps: panel shown')
	check(not divider(pool[2]):IsShown() and not divider(pool[3]):IsShown(), 'f6_fewer_steps: unused frames show no line')
end)

test('f6_hidden_first_list_row', function()
	local R = setup()
	R.BottomFrame.hiddenSteps[1] = true
	R.LoadGuide(3)
	local pool = R.ScrollChild.framePool
	check(not divider(pool[2]):IsShown(), 'f6_hidden_first_list_row: none under the title for row 2')
	check(divider(pool[3]):IsShown(), 'f6_hidden_first_list_row: row 3 keeps its line')
	R.BottomFrame.hiddenSteps[1] = nil
	R.BottomFrame.UpdateFrame()
	check(divider(pool[2]):IsShown(), 'f6_hidden_first_list_row: back once row 1 shows')
	R.BottomFrame.hiddenSteps[2] = true
	R.BottomFrame.UpdateFrame()
	check(divider(pool[3]):IsShown(), 'f6_hidden_first_list_row: a hidden row 2 leaves row 3 its line')
end)
