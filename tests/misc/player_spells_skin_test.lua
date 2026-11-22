-- The talent window skin (SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsSkin.lua):
--   - on (Forever, Skinning -> Talent window): the window's border, portrait, title
--     bar art, the gold frame, the dividers, the tabs' art, the buttons', search
--     box's and dropdown's art faded by alpha; SaftUI's panel behind the window on
--     the window's own edges (so it follows its width); boxes behind the buttons,
--     tabs and boxes; SaftUI's lines where the dividers were;
--   - each spec's background art left exactly as Blizzard has it;
--   - off, under the Blizzard theme, and on retail: nothing touched, nothing
--     hooked, Blizzard's alphas and fonts back;
--   - a tab acquired later skinned, a selected tab shown selected;
--   - an error in a hook reported to the error handler, never into Blizzard's call;
--   - nothing written onto Blizzard's tables (every frame and region is locked:
--     lib/locked_widget.lua), no script replaced.
-- Real: Core's helpers and theme engine, Misc's config.lua and the Skinning module
-- and skin. Blizzard's window is fixtures/player_spells_frame.lua's build_chrome.
local T = load_test_file('lib/theme_helpers.lua')
local PSF = load_test_file('misc/fixtures/player_spells_frame.lua')

local st, SK, skin, profile, window, talents, book

-- Every faded region, by where it is.
local function art()
	local out = {
		window.NineSlice, window.Bg, window.TopTileStreaks, window.PortraitContainer,
		talents.BackgroundBorder, talents.DividerHorizontalLeft, talents.DividerHorizontalRight,
		talents.DividerVerticalLeft, talents.DividerVerticalRight, talents.ClassCurrencyDisplay.Border,
		talents.LoadSystem.Dropdown.Background, talents.SearchBox.Left, talents.SearchBox.Middle, talents.SearchBox.Right,
		book.SearchBox.Left,
	}
	for _, getter in ipairs({ 'GetNormalTexture', 'GetPushedTexture', 'GetHighlightTexture', 'GetDisabledTexture' }) do
		out[#out + 1] = window.CloseButton[getter](window.CloseButton)
	end
	for _, button in ipairs({ talents.ApplyButton, talents.InspectCopyButton, talents.ActiveSpec.ActivateButton }) do
		for _, part in ipairs({ 'Left', 'Middle', 'Right' }) do out[#out + 1] = button[part] end
		out[#out + 1] = button:GetHighlightTexture()
	end
	for _, system in ipairs({ window.TabSystem, talents.TabSystem, book.CategoryTabSystem }) do
		for _, tab in ipairs(system.tabs) do
			for _, part in ipairs({ 'Left', 'Middle', 'Right', 'LeftActive', 'MiddleActive', 'RightActive',
					'LeftHighlight', 'MiddleHighlight', 'RightHighlight' }) do
				out[#out + 1] = tab[part]
			end
		end
	end
	return out
end

local function alphas_of(list)
	local out = {}
	for i, region in ipairs(list) do out[i] = region:GetAlpha() end
	return out
end

-- A fresh world on client: the window built (as the game loads Blizzard's addon
-- first) with three tabs on each tab system, the skin loaded, and the module
-- enabled with the addon already loaded, unless opts.late (it loads after).
local function world(client, opts)
	opts = opts or {}
	st = T.client(client)
	_G.PlayerSpellsFrame = nil
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.off then profile.skinning.talent_window = false end
	if opts.theme then profile.skinning.theme = opts.theme end
	window = PSF.build_chrome()
	talents, book = window.TalentsFrame, window.SpellBookFrame
	-- The tabs the game adds as the window loads (the bottom tab system's own
	-- tabs, the spec groups' and the spellbook's categories).
	for _, system in ipairs({ window.TabSystem, talents.TabSystem, book.CategoryTabSystem }) do
		-- (the fixture's frames are locked: the game's own code makes the tabs)
		system:AddTab('One')
		system:AddTab('Two')
		system.tabs[2]:SetTabSelected(true)
	end
	if not opts.late then stub.installed_addons.Blizzard_PlayerSpells = true; stub.loaded_addons.Blizzard_PlayerSpells = true end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_PlayerSpellsSkin.lua')
	SK = st:GetModule('Skinning')
	skin = SK:GetModule('Blizzard_PlayerSpellsSkin')
	SK:Enable()
end

test('on: the art is faded', function()
	world('forever')
	for i, region in ipairs(art()) do
		eq(region:GetAlpha(), 0, 'region ' .. i)
	end
	eq(window.TitleContainer.TitleText:GetAlpha(), 1, 'the title stays')
end)

test('on: SaftUI backdrops are behind the window, the buttons, the tabs and the boxes', function()
	world('forever')
	local function child_of(frame)
		local out = {}
		for _, kid in ipairs({ frame:GetChildren() }) do
			if kid:GetFrameLevel() < frame:GetFrameLevel() then out[#out + 1] = kid end
		end
		return out
	end
	local panel = child_of(window)[1]
	check(panel, 'the window has a panel under it')
	check(panel:IsShown(), 'shown')
	for _, frame in ipairs({ talents.ApplyButton, talents.InspectCopyButton, talents.ActiveSpec.ActivateButton, window.CloseButton,
			talents.LoadSystem.Dropdown, talents.SearchBox, book.SearchBox, talents.ClassCurrencyDisplay,
			talents.TabSystem.tabs[1], window.TabSystem.tabs[1], book.CategoryTabSystem.tabs[1] }) do
		check(child_of(frame)[1] and child_of(frame)[1]:IsShown(), 'a box under ' .. tostring(frame:GetObjectType()))
	end
end)

test('on: the panel follows the window\'s edges, so its width', function()
	world('forever')
	local panel
	for _, kid in ipairs({ window:GetChildren() }) do
		if kid:GetFrameLevel() < window:GetFrameLevel() then panel = kid end
	end
	for i = 1, panel:GetNumPoints() do
		local _, relative = panel:GetPoint(i)
		eq(relative, window, 'anchored to the window, never a fixed width')
	end
	window:SetWidth(780)
	check(panel:GetWidth() >= 780 and panel:GetWidth() < 800, 'follows a narrower window')
end)

test('on: the spec backgrounds stay as Blizzard has them', function()
	world('forever')
	local before = PSF.alphas()
	eq(before[1], 1)
	eq(before[2], 1)
	eq(before[3], 0)
	for _, t in ipairs(PSF.specart) do check(t:IsShown(), 'shown') end
	-- through a theme switch and back
	T.theme('blizzard', function() SK:UpdateConfig() end)
	T.theme('thick', function() SK:UpdateConfig() end)
	local after = PSF.alphas()
	for i = 1, #before do eq(after[i], before[i], 'spec art ' .. i) end
end)

test('on: lines stand where the dividers were, anchored to them', function()
	world('forever')
	local holder
	for _, kid in ipairs({ talents:GetChildren() }) do
		if kid:GetFrameLevel() >= talents:GetFrameLevel() and kid:GetNumRegions() == 3 then holder = kid end
	end
	check(holder, 'a frame of SaftUI\'s holds the lines')
	local anchored = {}
	for _, region in ipairs({ holder:GetRegions() }) do
		for i = 1, region:GetNumPoints() do
			local _, relative = region:GetPoint(i)
			anchored[relative] = true
		end
	end
	check(anchored[talents.DividerVerticalLeft], 'a line follows the left divider')
	check(anchored[talents.DividerVerticalRight], 'a line follows the right divider')
	check(anchored[talents.BackgroundBorder], 'the top bar line follows the border')
end)

test('on: the title is in the Window titles font and centered', function()
	world('forever')
	local text = window.TitleContainer.TitleText
	eq(text:GetFontObject(), st:FontObject(profile.headers.font))
	eq(text:GetNumPoints(), 1)
end)

test('on: buttons take the Skinning font', function()
	world('forever')
	local font = st:FontObject(profile.skinning.font)
	eq(talents.ApplyButton:GetNormalFontObject(), font)
	eq(talents.ApplyButton:GetDisabledFontObject(), font)
end)

test('on: a selected tab is shown selected, and follows SetTabSelected', function()
	world('forever')
	local tab = talents.TabSystem.tabs[2]
	local function selected()
		for _, kid in ipairs({ tab:GetChildren() }) do
			if kid:GetFrameLevel() < tab:GetFrameLevel() then return st:GetState(kid, 'selected') end
		end
	end
	eq(selected(), true)
	tab:SetTabSelected(false)
	eq(selected(), false)
	tab:SetTabSelected(true)
	eq(selected(), true)
end)

test('on: a tab added later is skinned', function()
	world('forever')
	talents.TabSystem:AddTab('Three')
	local tab = talents.TabSystem.tabs[3]
	eq(tab.Left:GetAlpha(), 0)
	local box
	for _, kid in ipairs({ tab:GetChildren() }) do box = kid end
	check(box and box:IsShown(), 'a box under it')
	eq(tab.LeftHighlight:GetAlpha(), 0)
end)

test('on: the addon loading after SaftUI is skinned when it loads', function()
	world('forever', { late = true })
	eq(talents.BackgroundBorder:GetAlpha(), 1, 'not yet')
	PSF.load()
	eq(talents.BackgroundBorder:GetAlpha(), 0)
end)

test('off: nothing is touched, hooked or made', function()
	world('forever', { off = true })
	local list = art()
	for i, region in ipairs(list) do check(region:GetAlpha() > 0, 'region ' .. i) end
	eq(talents.TabSystem.tabs[1].Left:GetAlpha(), 1)
	eq(talents.TabSystem.tabs[1].LeftHighlight:GetAlpha(), 0.4)
	eq(window.TitleContainer.TitleText:GetNumPoints(), 3)
	eq(window:GetNumChildren(), 7, 'no panel')
	talents.TabSystem:AddTab('Three')
	eq(talents.TabSystem.tabs[3].Left:GetAlpha(), 1)
	check(not stub.hook_wrappers[rawget(talents.TabSystem, 'AddTab')], 'AddTab not hooked')
	check(not stub.hook_wrappers[rawget(talents.TabSystem.tabs[1], 'SetTabSelected')], 'SetTabSelected not hooked')
end)

test('retail: nothing is touched or hooked', function()
	world('retail')
	for i, region in ipairs(art()) do check(region:GetAlpha() > 0, 'region ' .. i) end
	eq(window:GetNumChildren(), 7, 'no panel')
	check(not stub.hook_wrappers[rawget(talents.TabSystem, 'AddTab')], 'AddTab not hooked')
	check(not skin:IsActive(), 'inactive')
	-- the page has no row for it
	local page = SK:GetConfigTable()
	eq(page.args.general.args.talent_window, nil)
end)

test('forever: the Skinning page has the switch, on by default, needing a reload', function()
	world('forever')
	local row = SK:GetConfigTable().args.general.args.talent_window
	check(row, 'a row')
	eq(row.type, 'toggle')
	eq(profile.skinning.talent_window, true)
end)

test('Blizzard theme: Blizzard\'s look comes back, then the skin again', function()
	world('forever')
	local before = alphas_of(art())
	T.theme('blizzard', function() SK:UpdateConfig() end)
	for i, region in ipairs(art()) do check(region:GetAlpha() > 0, 'put back ' .. i) end
	eq(talents.TabSystem.tabs[1].LeftHighlight:GetAlpha(), 0.4, 'the XML alpha, not 1')
	eq(window.TitleContainer.TitleText:GetNumPoints(), 3, 'the title\'s anchors')
	eq(window.TitleContainer.TitleText:GetFontObject(), _G.GameFontNormal)
	eq(talents.ApplyButton:GetNormalFontObject(), _G.GameFontNormal)
	for _, kid in ipairs({ window:GetChildren() }) do
		if kid:GetFrameLevel() < window:GetFrameLevel() then check(not kid:IsShown(), 'panel hidden') end
	end
	T.theme('thick', function() SK:UpdateConfig() end)
	local after = alphas_of(art())
	for i = 1, #before do eq(after[i], before[i], 'region ' .. i) end
end)

test('a hook error is reported and never reaches Blizzard\'s call', function()
	world('forever')
	local real = st.SetTemplate
	st.SetTemplate = function() error('boom') end
	local ok, err = pcall(function() return talents.TabSystem:AddTab('Three') end)
	st.SetTemplate = real
	check(ok, 'Blizzard\'s AddTab returned: ' .. tostring(err))
	local errors = take_errors()
	eq(#errors, 1, 'reported once')
	check(tostring(errors[1]):find('boom'), 'the error is the hook\'s')
	eq(#talents.TabSystem.tabs, 3, 'and Blizzard\'s own work was done')
end)

test('a script hook error is reported and the script goes on', function()
	world('forever')
	local real = st.SetState
	st.SetState = function() error('bang') end
	local ok = pcall(stub.fire_script, talents.ApplyButton, 'OnEnter', true)
	st.SetState = real
	check(ok, 'the script ran')
	eq(#take_errors(), 1)
end)

test('hover and press set states on SaftUI\'s box only', function()
	world('forever')
	local button = talents.ApplyButton
	local box
	for _, kid in ipairs({ button:GetChildren() }) do box = kid end
	stub.fire_script(button, 'OnEnter', true)
	eq(st:GetState(box, 'hover'), true)
	stub.fire_script(button, 'OnLeave', true)
	eq(st:GetState(box, 'hover'), false)
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	eq(st:GetState(box, 'pushed'), true)
	stub.fire_script(button, 'OnMouseUp', 'LeftButton')
	eq(st:GetState(box, 'pushed'), false)
end)
