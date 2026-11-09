-- The RestedXP skin (SaftUI-Misc/Skinning/restedxp.lua), part 3: the current
-- steps and the tip window. Migrated from the rxpsim harness's test_task3.lua.
local H = load_test_file('misc/restedxp_helpers.lua')
local RXP, near, font, pt, colored = H.RXP, H.near, H.font, H.pt, H.colored

local function setup()
	H.fresh()
	stub.loaded_addons.RXPGuides = true
	local R = RXP.make()
	H.get_rx():OnEnable()
	return R
end
local function divider(f) return colored(f, 0.3, 0.3, 0.3, 0.5)[1] end
-- SaftUI panels a frame owns: children with a template set
local function panelsOf(f)
	return H.panels_of(f, true)
end
local function allPoints(p)
	return pt(p, 'TOPLEFT') and pt(p, 'BOTTOMRIGHT')
end
local function pool(R) return R.CurrentStepFrame.framePool end

test('steps_panel', function()
	local R = setup()
	local cur = R.CurrentStepFrame
	local ps = panelsOf(cur)
	check(#ps == 1, 'steps_panel: one panel on CurrentStepFrame')
	local p = ps[1]
	check(p and p:GetParent() == cur and allPoints(p), 'steps_panel: parented, all points')
	check(p and p.backdrop.template == 'thicktransparent', 'steps_panel: template')
	local bl, br = pt(cur, 'BOTTOMLEFT'), pt(cur, 'BOTTOMRIGHT')
	check(bl and bl.rel == R.GuideName and bl.relPoint == 'TOPLEFT' and bl.y == 9, 'steps_panel: BOTTOMLEFT')
	check(br and br.rel == R.GuideName and br.relPoint == 'TOPRIGHT' and br.y == 9, 'steps_panel: BOTTOMRIGHT')
end)

test('steps_panel_hidden_when_empty', function()
	local R = setup()
	local p = panelsOf(R.CurrentStepFrame)[1]
	R.AddCurrentStep({ elements = 2 })
	R.CurrentStepFrame.UpdateText()
	check(R.CurrentStepFrame:GetHeight() > 2 and p:IsShown(), 'steps_panel_hidden_when_empty: shown with steps')
	R.ClearCurrentSteps()
	R.CurrentStepFrame.UpdateText()
	check(R.CurrentStepFrame:GetHeight() <= 2 and not p:IsShown(), 'steps_panel_hidden_when_empty: hidden when empty')
	R.AddCurrentStep({ elements = 1 })
	R.CurrentStepFrame.UpdateText()
	check(p:IsShown(), 'steps_panel_hidden_when_empty: shown again')
end)

local function three()
	local R = setup()
	for i = 1, 3 do R.AddCurrentStep({ elements = 2 }) end
	R.CurrentStepFrame.UpdateText()
	return R
end

test('current_steps_skinned', function()
	local R = three()
	check(#pool(R) == 3, 'current_steps_skinned: three frames')
	for i, f in ipairs(pool(R)) do
		check(f.backdropInfo == nil and f.number.backdropInfo == nil, 'current_steps_skinned: backdrops ' .. i)
		for j, el in ipairs(f.elements) do
			check(font(el.text, 'normal', 11, 'OUTLINE'), 'current_steps_skinned: element font ' .. i .. '.' .. j)
			check(font(el.icon, 'GameFontFace', 9, ''), 'current_steps_skinned: icon left alone ' .. i .. '.' .. j)
		end
		local t = f.number.text
		local r, g, b = t:GetTextColor()
		check(near(r, 0.59) and near(g, 0.59) and near(b, 0.59), 'current_steps_skinned: number grey ' .. i)
		local p = pt(t, 'TOPRIGHT')
		check(p and p.rel == f and p.relPoint == 'TOPRIGHT' and p.x == -5 and p.y == -1, 'current_steps_skinned: number anchor ' .. i)
		check(t:GetNumPoints() == 1, 'current_steps_skinned: number single anchor ' .. i)
		check(t:GetJustifyH() == 'RIGHT', 'current_steps_skinned: number right ' .. i)
		check(font(t, 'normal', 9, 'OUTLINE'), 'current_steps_skinned: number font ' .. i)
	end
end)

test('current_dividers', function()
	local R = three()
	for i, f in ipairs(pool(R)) do
		local d = divider(f)
		check(d ~= nil, 'current_dividers: exists ' .. i)
		check(d and d:IsShown() == (i > 1), 'current_dividers: shown only for later steps ' .. i)
		local bl, br = d and pt(d, 'BOTTOMLEFT'), d and pt(d, 'BOTTOMRIGHT')
		check(bl and bl.rel == f and bl.relPoint == 'TOPLEFT' and bl.y == 2, 'current_dividers: BOTTOMLEFT ' .. i)
		check(br and br.rel == f and br.relPoint == 'TOPRIGHT' and br.y == 2, 'current_dividers: BOTTOMRIGHT ' .. i)
	end
end)

test('tip_frame_switches_role', function()
	local R = setup()
	R.AddCurrentStep({ elements = 1 })
	R.AddCurrentStep({ elements = 1, tip = true })
	R.CurrentStepFrame.UpdateText()
	local tip = pool(R)[2]
	local ps = panelsOf(tip)
	check(#ps == 1 and ps[1]:GetParent() == tip and allPoints(ps[1]), 'tip_frame_switches_role: tip panel')
	check(ps[1] and ps[1].backdrop.template == 'thicktransparent', 'tip_frame_switches_role: tip template')
	check(ps[1] and ps[1]:IsShown(), 'tip_frame_switches_role: tip panel shown')
	check(not divider(tip):IsShown(), 'tip_frame_switches_role: tip divider hidden')
	check(#panelsOf(pool(R)[1]) == 0, 'tip_frame_switches_role: no panel on a normal step')
	R.ClearCurrentSteps()
	R.AddCurrentStep({ elements = 1 })
	R.AddCurrentStep({ elements = 1 })
	R.CurrentStepFrame.UpdateText()
	check(not ps[1]:IsShown(), 'tip_frame_switches_role: panel hidden after role change')
	check(divider(tip):IsShown(), 'tip_frame_switches_role: divider shown after role change')
	R.ClearCurrentSteps()
	R.AddCurrentStep({ elements = 1 })
	R.AddCurrentStep({ elements = 1, tip = true })
	R.CurrentStepFrame.UpdateText()
	check(#panelsOf(tip) == 1 and ps[1]:IsShown(), 'tip_frame_switches_role: panel reused')
end)

test('theme_reapply_current', function()
	local R = three()
	R._theme = {}
	R.CurrentStepFrame.UpdateText()
	for i, f in ipairs(pool(R)) do
		check(f.backdropInfo == nil and f.number.backdropInfo == nil, 'theme_reapply_current: ' .. i)
	end
end)

test('hooked_once', function()
	local R = setup()
	local counts = H.count_hooks(function()
		for i = 1, 2 do R.AddCurrentStep({ elements = 2 }) end
		R.CurrentStepFrame.UpdateText()
		R.CurrentStepFrame.UpdateText()
	end)
	for i, f in ipairs(pool(R)) do
		check(counts[f] and counts[f].SetBackdrop == 1, 'hooked_once: frame ' .. i)
		check(counts[f.elements[1].text] and counts[f.elements[1].text].SetFont == 1, 'hooked_once: element ' .. i)
		check(#colored(f, 0.3, 0.3, 0.3, 0.5) == 1, 'hooked_once: one divider ' .. i)
	end
end)

test('config_current', function()
	local R = setup()
	R.AddCurrentStep({ elements = 1 })
	R.AddCurrentStep({ elements = 1, tip = true })
	R.CurrentStepFrame.UpdateText()
	local RX = H.get_rx()
	SaftUI.config.profile.chat.template = 'thick'
	RX:UpdateConfig()
	check(panelsOf(R.CurrentStepFrame)[1].backdrop.template == 'thick', 'config_current: steps panel')
	check(panelsOf(pool(R)[2])[1].backdrop.template == 'thick', 'config_current: tip panel')
end)
