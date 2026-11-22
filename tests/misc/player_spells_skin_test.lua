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
		talents.Background, talents.BackgroundBorder, talents.DividerHorizontalLeft, talents.DividerHorizontalRight,
		talents.DividerVerticalLeft, talents.DividerVerticalRight, talents.ClassCurrencyDisplay.Border,
		talents.SearchBox.Left, talents.SearchBox.Middle, talents.SearchBox.Right,
		book.SearchBox.Left,
	}
	for _, header in ipairs(talents.treeHeaders) do out[#out + 1] = header.Divider end
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
					'LeftHighlight', 'MiddleHighlight', 'RightHighlight', 'SquareBackground', 'SquareBackgroundActive',
					'SquareBackgroundActiveGlow' }) do
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
			talents.SearchBox, book.SearchBox, talents.ClassCurrencyDisplay,
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
	eq(#before, 3, 'the class art and its two overlays; the header and footer art is not spec art')
	eq(before[1], 1)
	eq(before[2], 0)
	eq(before[3], 0)
	for _, t in ipairs(PSF.specart) do check(t:IsShown(), 'shown') end
	-- through a theme switch and back
	T.theme('blizzard', function() SK:UpdateConfig() end)
	T.theme('thick', function() SK:UpdateConfig() end)
	local after = PSF.alphas()
	for i = 1, #before do eq(after[i], before[i], 'spec art ' .. i) end
end)

-- SaftUI's lines: a holder over TalentsFrame with the bar and the bottom line, and
-- a clip frame (one frame in it, holding the two vertical lines).
local function line_set()
	for _, kid in ipairs({ talents:GetChildren() }) do
		if kid:GetFrameLevel() >= talents:GetFrameLevel() and kid:GetNumRegions() == 2 and kid:GetNumChildren() == 1 then
			local clip = kid:GetChildren()
			local host = clip:GetChildren()
			local bar, bottom = kid:GetRegions()
			local left, right = host:GetRegions()
			return { holder = kid, bar = bar, bottom = bottom, clip = clip, host = host, left = left, right = right }
		end
	end
end

local function points_of(region)
	local out = {}
	for i = 1, region:GetNumPoints() do
		local point, relative, relpoint, x, y = region:GetPoint(i)
		out[point] = { relative = relative, relpoint = relpoint, x = x or 0, y = y or 0 }
	end
	return out
end

test('on: the header and footer art is faded, the spec art is not, and the headers\' gold dividers are faded', function()
	world('forever')
	eq(talents.Background:GetAlpha(), 0, 'the dark header and footer art')
	eq(talents.ClassBackground:GetAlpha(), 1, 'the class art stays')
	for i, header in ipairs(talents.treeHeaders) do eq(header.Divider:GetAlpha(), 0, 'header ' .. i .. '\'s divider') end
	eq(talents.treeHeaders[1].Name:GetAlpha(), 1, 'the header\'s name stays')
end)

test('on: a header the pool hands out again has its divider faded too, and off puts them back', function()
	world('forever')
	talents:RefreshTreeHeaders()
	for i, header in ipairs(talents.treeHeaders) do eq(header.Divider:GetAlpha(), 0, 'header ' .. i) end
	T.theme('blizzard', function() SK:UpdateConfig() end)
	for i, header in ipairs(talents.treeHeaders) do eq(header.Divider:GetAlpha(), 1, 'back ' .. i) end
	eq(talents.Background:GetAlpha(), 1)
	T.theme('thick', function() SK:UpdateConfig() end)
	for i, header in ipairs(talents.treeHeaders) do eq(header.Divider:GetAlpha(), 0, 'again ' .. i) end
end)

test('on: the top and bottom lines are the spec art\'s own top and bottom edges, so the art fills exactly between them', function()
	world('forever')
	local set = line_set()
	check(set, 'a frame of SaftUI\'s holds the lines')
	local art = talents.ClassBackground
	local bar, bottom = points_of(set.bar), points_of(set.bottom)
	eq(bar.TOPLEFT.relative, art)
	eq(bar.TOPLEFT.relpoint, 'TOPLEFT')
	eq(bar.TOPLEFT.y, 0)
	eq(bar.TOPRIGHT.relative, art)
	eq(bar.TOPRIGHT.relpoint, 'TOPRIGHT')
	eq(bottom.BOTTOMLEFT.relative, art)
	eq(bottom.BOTTOMLEFT.relpoint, 'BOTTOMLEFT')
	eq(bottom.BOTTOMLEFT.y, 0)
	eq(bottom.BOTTOMRIGHT.relative, art)
	eq(bottom.BOTTOMRIGHT.relpoint, 'BOTTOMRIGHT')
	check(set.bar:GetHeight() > 0 and set.bottom:GetHeight() > 0, 'both have a thickness')
	eq(set.bar:IsShown(), true)
	eq(set.bottom:IsShown(), true)
end)

test('on: the vertical lines start where Blizzard\'s dividers do (under the tree headers) and are clipped to the art', function()
	world('forever')
	local set = line_set()
	eq(set.clip:DoesClipChildren(), true, 'a clip frame stops anything past the art')
	local clip = points_of(set.clip)
	eq(clip.TOPLEFT.relative, talents.ClassBackground)
	eq(clip.BOTTOMRIGHT.relative, talents.ClassBackground)
	for key, divider in pairs({ left = talents.DividerVerticalLeft, right = talents.DividerVerticalRight }) do
		local points = points_of(set[key])
		eq(points.TOP.relative, divider, key .. ': on the divider\'s x and top')
		eq(points.TOP.relpoint, 'TOP')
		eq(points.TOP.y, 0, key .. ': from the top of Blizzard\'s divider, not the top bar')
		eq(points.BOTTOM, nil, key .. ': no end on the divider: the clip ends it at the bottom line')
		check(set[key]:GetHeight() >= talents.ClassBackground:GetHeight(), key .. ': long enough to reach the bottom line')
	end
end)

test('on: a vertical line follows its divider when the compact layout moves it', function()
	world('forever')
	local set = line_set()
	talents.DividerVerticalLeft:ClearAllPoints()
	talents.DividerVerticalLeft:SetPoint('TOP', talents.BackgroundBorder, 'TOPLEFT', 262, -74)
	eq(points_of(set.left).TOP.relative, talents.DividerVerticalLeft, 'still on it')
end)

test('on: the loadout menu is left alone (Camelot hides it)', function()
	world('forever')
	local dropdown = talents.LoadSystem.Dropdown
	eq(dropdown.Background:GetAlpha(), 1)
	eq(dropdown:GetNumChildren(), 0)
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

-- In combat PlayerSpellsFrame is protected (a secure button of the spellbook's,
-- and protection spreads to its parents): nothing is made or placed on it then.
local function protect(frame)
	rawset(frame, 'IsProtected', function() return true, true end)
end

test('protected window in combat: StyleAll waits for the end of combat, whole', function()
	world('forever', { off = true })
	profile.skinning.talent_window = true
	protect(window)
	stub.in_combat = true
	skin:Install()
	eq(window:GetNumChildren(), 7, 'nothing made in combat')
	for i, region in ipairs(art()) do check(region:GetAlpha() > 0, 'region ' .. i) end
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	check(window:GetNumChildren() > 7, 'the pass ran at the end of combat')
	for i, region in ipairs(art()) do eq(region:GetAlpha(), 0, 'region ' .. i) end
end)

test('protected window in combat: a tab added then is skinned with the rest after, none half-skinned', function()
	world('forever')
	protect(window)
	stub.in_combat = true
	talents.TabSystem:AddTab('Three')
	local tab = talents.TabSystem.tabs[3]
	eq(tab.Left:GetAlpha(), 1, 'untouched in combat')
	eq(tab:GetNumChildren(), 0, 'no box in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(tab.Left:GetAlpha(), 0)
	eq(tab:GetNumChildren(), 1)
	check(tab:GetChildren():IsShown(), 'its box')
end)

test('an unprotected window is styled in combat at once', function()
	world('forever')
	stub.in_combat = true
	talents.TabSystem:AddTab('Three')
	eq(talents.TabSystem.tabs[3].Left:GetAlpha(), 0)
	stub.in_combat = false
end)

test('a locked tab is dimmed and takes no hover; the selected one is not dimmed', function()
	world('forever')
	local tab = talents.TabSystem.tabs[1]
	local box = tab:GetChildren()
	tab:SetTabEnabled(false)
	eq(st:GetState(box, 'disabled'), true)
	stub.fire_script(tab, 'OnEnter', true)
	eq(st:GetState(box, 'hover'), false, 'no hover while disabled')
	tab:SetTabEnabled(true)
	eq(st:GetState(box, 'disabled'), false)
	local selected = talents.TabSystem.tabs[2]
	eq(st:GetState(selected:GetChildren(), 'disabled'), false, 'a selected tab (disabled by the game) is not dimmed')
	eq(st:GetState(selected:GetChildren(), 'selected'), true)
end)

test('the search box keeps the color it has through the font change', function()
	world('forever', { late = true })
	talents.SearchBox.Instructions:SetTextColor(0.2, 0.3, 0.4)
	PSF.load()
	local r, g, b = talents.SearchBox.Instructions:GetTextColor()
	check(near(r, 0.2) and near(g, 0.3) and near(b, 0.4), 'the color Blizzard had')
end)

test('the search box\'s box is the border\'s 20 high, centered in the 30 high box; the close box sits inside the window', function()
	world('forever')
	local function box_of(frame)
		for _, kid in ipairs({ frame:GetChildren() }) do
			if kid:GetFrameLevel() < frame:GetFrameLevel() then return kid end
		end
	end
	local b = box_of(talents.SearchBox)
	local _, _, _, _, y1 = b:GetPoint(1)
	local _, _, _, _, y2 = b:GetPoint(2)
	eq(y1, -5)
	eq(y2, 5)
	local c = box_of(window.CloseButton)
	local _, _, _, x1, cy1 = c:GetPoint(1)
	eq(cy1, -3, 'its top is the window\'s top, not above it')
	eq(x1, 3)
end)

test('on: Unspent Talents: the box holds the label and the number, inside the window, on the search box\'s right edge', function()
	world('forever')
	local display = talents.ClassCurrencyDisplay
	local box
	for _, kid in ipairs({ display:GetChildren() }) do
		if kid:GetFrameLevel() < display:GetFrameLevel() then box = kid end
	end
	check(box and box:IsShown(), 'a box under the display')
	local points = points_of(box)
	-- its left is the label's left (the label is wider than the border art), not the border's
	eq(points.TOPLEFT.relative, display.UnspentLabel, 'starts at the label')
	check(points.TOPLEFT.x < 0, 'with room before the label')
	-- its right is the search box's right edge: an edge frame on the border's right, in by what Blizzard's XML puts between them (32 - 20)
	local edge = points.BOTTOMRIGHT.relative
	local edgePoint = points_of(edge)
	eq(edgePoint.RIGHT.relative, display.Border)
	eq(edgePoint.RIGHT.relpoint, 'RIGHT')
	eq(edgePoint.RIGHT.x, -12, 'the search box ends 12 left of the border\'s right: SearchBox -32, display -20')
	-- symmetric about the label's middle line, so neither text is cut
	eq(points.TOPLEFT.y, -points.BOTTOMRIGHT.y)
	check(points.TOPLEFT.y > 0, 'taller than the text')
end)

test('on: the Unspent Talents number is in SaftUI\'s font, keeps its color, and Blizzard\'s font is back off', function()
	world('forever')
	local number = talents.ClassCurrencyDisplay.CurrentAmountContainer.CurrencyAmount
	local font = st:FontObject(profile.skinning.font)
	eq(number:GetFontObject(), font)
	eq(talents.ClassCurrencyDisplay.UnspentLabel:GetFontObject(), font)
	local r, g, b = number:GetTextColor()
	check(near(r, 0.1) and near(g, 1) and near(b, 0.1), 'the green Blizzard set for points to spend')
	T.theme('blizzard', function() SK:UpdateConfig() end)
	eq(number:GetFontObject(), GameFontNormal, 'the font it had')
end)

-- A spec tab (ClassTalentsFrameTabMixin): its text carries the check or the lock as
-- an inline atlas, so Blizzard's centered text is the word and the icon together.
test('on: the spec tab\'s word is centered on the tab, the check or lock hangs after it', function()
	world('forever')
	local tab = talents.TabSystem.tabs[1]
	tab.Text:SetText('Primary |A:Talents-Checkmark-c60:15:20|a')
	tab:SetTabSelected(true)
	local box = tab:GetChildren()
	local label, icon
	for _, region in ipairs({ box:GetRegions() }) do
		if region:GetObjectType() == 'FontString' then label = region end
		if region:GetObjectType() == 'Texture' and region:GetAtlas() == 'Talents-Checkmark-c60' then icon = region end
	end
	check(label, 'a label of SaftUI\'s')
	eq(label:GetText(), 'Primary', 'the word alone')
	eq(tab.Text:GetAlpha(), 0, 'Blizzard\'s text (word and icon) is faded')
	local points = points_of(label)
	eq(points.CENTER.relative, box, 'the word is centered on the tab\'s box')
	eq(points.CENTER.x, 0)
	check(icon and icon:IsShown(), 'the check')
	local ip = points_of(icon)
	eq(ip.LEFT.relative, label)
	eq(ip.LEFT.relpoint, 'RIGHT')
	check(ip.LEFT.x > 0, 'after the word')
	eq(label:GetFontObject(), st:FontObject(profile.skinning.font))
end)

test('on: the spec tab\'s label follows the text: a lock for a locked tab, no icon for a plain one, markup and color codes dropped', function()
	world('forever')
	local tab = talents.TabSystem.tabs[2]
	local box = tab:GetChildren()
	local function parts()
		local label, icon
		for _, region in ipairs({ box:GetRegions() }) do
			if region:GetObjectType() == 'FontString' then label = region end
			if region:GetObjectType() == 'Texture' and region:GetAtlas() ~= nil then icon = region end
		end
		return label, icon
	end
	tab.Text:SetText('|cff808080Secondary|r |A:Talents-lock-c60:14:10|a')
	tab:SetTabEnabled(false)
	local label, icon = parts()
	eq(label:GetText(), 'Secondary')
	eq(icon:GetAtlas(), 'Talents-lock-c60')
	check(icon:IsShown(), 'the lock')
	tab.Text:SetText('Secondary')
	tab:SetTabEnabled(true)
	label, icon = parts()
	eq(label:GetText(), 'Secondary')
	check(not icon or not icon:IsShown(), 'no icon')
	-- the other tab systems keep Blizzard's text
	eq(window.TabSystem.tabs[1].Text:GetAlpha(), 1)
	eq(book.CategoryTabSystem.tabs[1].Text:GetAlpha(), 1)
	T.theme('blizzard', function() SK:UpdateConfig() end)
	eq(tab.Text:GetAlpha(), 1, 'Blizzard\'s text back')
	check(not label:IsShown(), 'ours hidden')
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
