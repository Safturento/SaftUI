-- The objective tracker skin (SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua):
--   - the tracker's header and every module's: Blizzard's banner (and a
--     module's Shine and Glow) hidden, the title in the header font in
--     Blizzard's color, a 1px line along the bottom; the collapse button's art
--     faded, a box of SaftUI's drawn as a control, a chevron that follows the
--     header's state (a click on the button too);
--   - a block's title and its lines' dashes and texts in the tracker's font,
--     put on before Blizzard measures them, in Blizzard's colors;
--   - a pooled block handed out again: hooked once, still styled, nothing made
--     twice;
--   - progress bars (the stock one, the bonus objective and scenario ones) and
--     timer bars flat, backdrops of SaftUI's drawn as bars, Blizzard's art
--     faded or hidden, their text in the font; the bars' reward icon left;
--   - a quest item button as an action button: the backdrop, the icon inside
--     the border and kept cropped through Blizzard's SetUp, Blizzard's art
--     faded, a hover, the count in the Skinning font; its click still
--     Blizzard's;
--   - everything styled in combat with stub.blocked empty, and an item button
--     the game would count as protected waiting for the end of combat;
--   - the theme switch both ways (Thick, Blizzard, Thick again; Thin), and a
--     tracker updated under Blizzard left as Blizzard's;
--   - Skinning -> Objective tracker off at load hooking nothing and leaving
--     everything Blizzard's, then on and off live;
--   - the tracker's fonts on its page reaching every text;
--   - the addon loading after SaftUI; an error in a hook reported, Blizzard's
--     layout going on;
--   - nothing written onto Blizzard's frames: every frame and region of the
--     fixture is locked (lib/locked_widget.lua).
-- On both clients.
--
-- Real: SaftUI-Misc's config.lua, Skinning/skinning.lua and
-- Skinning/blizzard/Blizzard_ObjectiveTracker.lua, Core's helpers and the theme
-- engine. Blizzard's tracker is fixtures/objective_tracker.lua.
local T = load_test_file('lib/theme_helpers.lua')

local st, drawn, OT, SK, skin, profile

-- A fresh world on client: Misc's Skinning and the skin loaded, the tracker
-- built (before SaftUI's modules are enabled, as the game loads Blizzard's
-- addon first) unless opts.late, the toggle off with opts.off. Then Skinning
-- and its skins are enabled, as at login.
local function world(client, opts)
	opts = opts or {}
	st = T.client(client)
	drawn = T.watch()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	profile = st.config.profile
	if opts.off then profile.skinning.objective_tracker = false end
	if opts.late then stub.installed_addons.Blizzard_ObjectiveTracker = true end
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_ObjectiveTracker.lua')
	SK = st:GetModule('Skinning')
	skin = SK:GetModule('Blizzard_ObjectiveTracker')
	OT = load_test_file('misc/fixtures/objective_tracker.lua')
	if not opts.late then OT.build(opts.build) end
	if opts.before then opts.before() end
	SK:Enable()
end

-- st:ThemeChanged's steps, as Config:UpdateConfig runs them (tests/actionbars/theme_test.lua's switch).
local function switch(name)
	T.theme(name, function()
		SK:UpdateConfig()
		st:ColorsChanged('theme')
	end)
end

local function own_regions(frame)
	local out = {}
	for _, region in ipairs({ frame:GetRegions() }) do
		if not OT.is_blizzard(region) then out[#out + 1] = region end
	end
	return out
end

local function own_children(frame)
	local out = {}
	for _, child in ipairs({ frame:GetChildren() }) do
		if not OT.is_blizzard(child) then out[#out + 1] = child end
	end
	return out
end

-- The one frame of SaftUI's on a Blizzard frame (a box or a backdrop).
local function box_of(frame)
	local children = own_children(frame)
	return #children == 1 and children[1] or nil, #children
end

-- No error, and nothing of Blizzard's state-writing Lua (MarkDirty, Update,
-- SetCollapsed, UpdateHeight) run from SaftUI's code, which would run the
-- tracker's layout tainted (.agents/taint.md rule 5).
local function clean()
	eq(#take_errors(), 0, 'no errors')
	eq(table.concat(OT.stray, ','), '', "SaftUI ran none of the tracker's state-writing methods")
end

local function rgb(fs) return T.rgb(fs:GetTextColor()) end

local QUESTS = {
	{ id = 101, title = 'The First Quest', objectives = { 'Kill 0/8 boars', 'Collect 0/5 tusks' } },
	{ id = 102, title = 'The Second Quest', objectives = { 'Talk to the guard' } },
}

local function quest_module() return OT.modules.QuestObjectiveTracker end

local function headers()
	local out = { { OT.tracker.Header, 'the tracker' } }
	for _, name in ipairs(OT.MODULES) do out[#out + 1] = { OT.modules[name].Header, name } end
	return out
end

------------------------------------------------------------------ checks

local function check_header(header, where)
	local font = st:GetFont(profile.objectivetracker.header_font)
	check(not header.Background:IsShown(), where .. ": Blizzard's banner hidden")
	if header.Shine then
		check(not header.Shine:IsShown() and not header.Glow:IsShown(), where .. ': the Shine and Glow hidden')
	end
	eq(header.Text:GetFontObject(), font, where .. ': the title in the header font')
	eq(rgb(header.Text), T.rgb(1, 0.82, 0), where .. ": in Blizzard's color")
	local lines = own_regions(header)
	eq(#lines, 1, where .. ': one texture of SaftUI\'s on it')
	local line = lines[1]
	if line then
		check(line:IsShown(), where .. ': the line shows')
		eq(T.anchor(line, { [header] = 'header' }, 'BOTTOMLEFT'), 'BOTTOMLEFT header BOTTOMLEFT 0.00,0.00', where .. ': along the bottom')
		eq(line:GetHeight(), 1, where .. ': 1px tall')
	end
	local button = header.MinimizeButton
	for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture(), button:GetHighlightTexture() }) do
		eq(texture:GetAlpha(), 0, where .. ": the collapse button's art faded")
	end
	local box = box_of(button)
	check(box ~= nil, where .. ': a box of SaftUI\'s behind the collapse button')
	if box then
		eq(drawn(box), 'theme,theme,control', where .. ': drawn in the Skinning look as a control')
		eq(T.around(box, button), '0,0,0,0', where .. ': as big as the button')
		eq(box:GetFrameLevel(), button:GetFrameLevel() - 1, where .. ': one level under it')
	end
	local icons = own_regions(button)
	eq(#icons, 2, where .. ': a chevron and its hover')
	for _, icon in ipairs(icons) do
		eq(icon:GetTexture(), st.icons.chevronUp, where .. ': the chevron points up while the header is open')
	end
end

local function check_header_blizzard(header, where)
	check(header.Background:IsShown(), where .. ": Blizzard's banner back")
	if header.Shine then
		check(header.Shine:IsShown(), where .. ": a module header's Shine back")
		check(header.Glow:IsShown(), where .. ": a module header's Glow back")
	end
	eq(header.Text:GetFontObject(), ObjectiveTrackerHeaderFont, where .. ": the title in Blizzard's font")
	eq(rgb(header.Text), T.rgb(1, 0.82, 0), where .. ": in Blizzard's color")
	for _, region in ipairs(own_regions(header)) do
		check(not region:IsShown(), where .. ': the line hidden')
	end
	local button = header.MinimizeButton
	for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture(), button:GetHighlightTexture() }) do
		eq(texture:GetAlpha(), 1, where .. ": the collapse button's art back")
	end
	local box = box_of(button)
	if box then
		check(not box:IsShown(), where .. ': the box hidden')
		eq(drawn(box), 'none,theme,control', where .. ': and cleared')
	end
	for _, region in ipairs(own_regions(button)) do
		check(not region:IsShown(), where .. ': the chevron hidden')
	end
end

-- A block's texts in font. Measured in it too, unless stale: a text already
-- showing when the font changed keeps Blizzard's measure until Blizzard lays
-- it out again.
local function check_texts(block, font, where, stale)
	eq(block.HeaderText:GetFontObject(), font, where .. ': the title in the font')
	if not stale then eq(OT.measured[block.HeaderText], font, where .. ': and Blizzard measured it in that font') end
	eq(rgb(block.HeaderText), T.rgb(unpack(OT.HEADER)), where .. ": the title in Blizzard's color")
	for key, line in pairs(block.usedLines) do
		eq(line.Text:GetFontObject(), font, where .. ' line ' .. key .. ': the text in the font')
		if not stale then eq(OT.measured[line.Text], font, where .. ' line ' .. key .. ': measured in it') end
		eq(line.Dash:GetFontObject(), font, where .. ' line ' .. key .. ': the dash too')
		eq(rgb(line.Text), T.rgb(unpack(OT.NORMAL)), where .. ' line ' .. key .. ": in Blizzard's color")
	end
end

-- A stock bar (ObjectiveTrackerProgressBarTemplate, ObjectiveTrackerTimerBarTemplate).
local function check_stock_bar(status, label, where)
	for _, key in ipairs({ 'BorderLeft', 'BorderRight', 'BorderMid' }) do
		eq(status[key]:GetAlpha(), 0, where .. ': ' .. key .. ' faded')
	end
	for _, region in ipairs({ status:GetRegions() }) do
		if region:IsObjectType('Texture') and region ~= status:GetStatusBarTexture() then
			eq(region:GetAlpha(), 0, where .. ": every texture of Blizzard's but the fill faded")
		end
	end
	eq(status:GetStatusBarTexture():GetTexture(), st.BLANK_TEX, where .. ': a flat fill')
	eq(T.rgb(status:GetStatusBarColor()), T.rgb(0.26, 0.42, 1), where .. ": in Blizzard's blue")
	local backdrop = box_of(status)
	check(backdrop ~= nil and backdrop:IsShown(), where .. ": a backdrop of SaftUI's")
	eq(drawn(status), 'theme,theme,bar', where .. ': drawn in the Skinning look as a bar')
	if backdrop then eq(T.offset(backdrop, 'TOPLEFT'), '-2.00,2.00', where .. ": Thick's border outside the bar") end
	eq(label:GetFontObject(), st:GetFont(profile.objectivetracker.font), where .. ': its text in the font')
end

local function check_stock_bar_blizzard(status, label, where)
	for _, region in ipairs({ status:GetRegions() }) do
		if region:IsObjectType('Texture') then eq(region:GetAlpha(), 1, where .. ": Blizzard's art back") end
	end
	eq(status:GetStatusBarTexture():GetTexture(), OT.BAR_TEXTURE, where .. ": Blizzard's bar texture back")
	local backdrop = box_of(status)
	if backdrop then check(not backdrop:IsShown(), where .. ': the backdrop hidden') end
	eq(drawn(status), 'none,theme,bar', where .. ': and cleared')
	eq(label:GetFontObject(), GameFontHighlightMedium, where .. ": its text in Blizzard's font")
end

-- A bonus objective or scenario bar under Blizzard's look: its frame art
-- unfaded, its flash textures and flares shown again, the reward icon as ever.
local function check_bonus_bar_blizzard(bar, where)
	local status = bar.Bar
	eq(status.BarFrame:GetAlpha(), 1, where .. ": the bar's frame art back")
	eq(status.BarBG:GetAlpha(), 1, where .. ': its background back')
	for _, key in ipairs({ 'BarFrame2', 'BarFrame3', 'BarGlow', 'Sheen', 'Starburst' }) do
		check(status[key]:IsShown(), where .. ': ' .. key .. ' shown again')
	end
	for _, key in ipairs(OT.FLARES) do check(bar[key]:IsShown(), where .. ': ' .. key .. ' shown again') end
	check(status.Icon:IsShown() and status.IconBG:IsShown(), where .. ': the reward icon and its ring still shown')
	eq(status:GetStatusBarTexture():GetTexture(), OT.BAR_TEXTURE, where .. ": Blizzard's bar texture back")
	eq(status.Label:GetFontObject(), GameFontHighlightMedium, where .. ": its text in Blizzard's font")
	eq(drawn(status), 'none,theme,bar', where .. ': and its backdrop cleared')
end

local function crop()
	local trim = profile.misc.icon_trim
	return T.text(trim, 1 - trim, trim, 1 - trim)
end
local function coords(icon)
	local l, t, _, b, r = icon:GetTexCoord()
	return T.text(l, r, t, b)
end

local function check_item(button, inset, where)
	local backdrop = box_of(button)
	check(backdrop ~= nil and backdrop:IsShown(), where .. ": a backdrop of SaftUI's")
	if backdrop then
		eq(drawn(backdrop), 'theme,theme,action', where .. ': drawn in the Skinning look as an action button')
		eq(T.around(backdrop, button), '0,0,0,0', where .. ': as big as the button')
		eq(backdrop:GetFrameLevel(), button:GetFrameLevel() - 1, where .. ': one level under it')
	end
	local n = string.format('%d', inset)
	local m = string.format('%d', -inset)
	eq(T.around(button.icon, button), table.concat({ n, m, m, n }, ','), where .. ': the icon inside the border')
	eq(coords(button.icon), crop(), where .. ': cropped as SaftUI crops icons')
	for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture(), button:GetHighlightTexture() }) do
		eq(texture:GetAlpha(), 0, where .. ": Blizzard's art faded")
	end
	local hovers = own_regions(button)
	eq(#hovers, 1, where .. ': a hover of SaftUI\'s')
	if hovers[1] then
		eq(hovers[1]:GetDrawLayer(), 'HIGHLIGHT', where .. ': shown under the mouse only')
		check(hovers[1]:IsShown(), where .. ': the hover is on')
		eq(hovers[1]:GetAlpha(), 1, where .. ': the hover shows (its alpha is not Blizzard\'s faded art\'s)')
	end
	local highlight = button:GetHighlightTexture()
	check(OT.is_blizzard(highlight), where .. ": the button's highlight texture is still Blizzard's, not SaftUI's hover")
	if hovers[1] then
		check(highlight ~= hovers[1], where .. ': and the hover is not it')
	end
	eq(button.Count:GetFontObject(), st:GetFont(profile.skinning.font), where .. ': the count in the Skinning font')
end

local function check_item_blizzard(button, where)
	local backdrop = box_of(button)
	if backdrop then check(not backdrop:IsShown(), where .. ': the backdrop hidden') end
	eq(T.around(button.icon, button), '0,0,0,0', where .. ': the icon fills the button again')
	eq(coords(button.icon), T.text(0, 1, 0, 1), where .. ': the whole texture')
	for _, texture in ipairs({ button:GetNormalTexture(), button:GetPushedTexture(), button:GetHighlightTexture() }) do
		eq(texture:GetAlpha(), 1, where .. ": Blizzard's art back")
	end
	for _, region in ipairs(own_regions(button)) do check(not region:IsShown(), where .. ': the hover off') end
	eq(button.Count:GetFontObject(), NumberFontNormal, where .. ": the count in Blizzard's font")
end

------------------------------------------------------------------ cases

for _, client in ipairs({ 'forever', 'retail' }) do
	test(client .. ': every header restyled, its collapse button a small box with a chevron', function()
		world(client)
		for _, h in ipairs(headers()) do check_header(h[1], h[2]) end
		clean()
	end)

	test(client .. ": a block's title and lines take the font before Blizzard measures them", function()
		world(client)
		local blocks = OT.layout(quest_module(), QUESTS)
		local font = st:GetFont(profile.objectivetracker.font)
		for i, block in ipairs(blocks) do check_texts(block, font, 'quest ' .. i) end
		-- The scenario's fixed objectives block, which no GetBlock hands out.
		local scenario = OT.modules.ScenarioObjectiveTracker
		local line = scenario.ObjectivesBlock:AddObjective(1, 'Defeat the boss')
		eq(OT.measured[line.Text], font, 'the scenario objective measured in the font')
		clean()
	end)

	test(client .. ': progress bars, timer bars and quest item buttons', function()
		world(client)
		local blocks = OT.layout(quest_module(), {
			{ id = 1, objectives = { 'Fill the bar' }, progress = true, item = 7 },
		})
		local block = blocks[1]
		local quest = quest_module()
		check_stock_bar(block.lastRegion.Bar, block.lastRegion.Bar.Label, 'the quest progress bar')
		check_item(block.rightEdgeFrame, 2, 'the item button')

		-- Blizzard's SetUp again (a later layout) puts the whole texture back.
		OT.layout(quest, { { id = 1, objectives = { 'Fill the bar' }, progress = true, item = 7 } })
		eq(coords(block.rightEdgeFrame.icon), crop(), 'the icon is cropped again after SetUp')
		-- The click is Blizzard's own, and reads Blizzard's attribute.
		stub.click(block.rightEdgeFrame)
		eq(OT.used[1], 7, 'the click uses the quest item')

		local achievements = OT.modules.AchievementObjectiveTracker
		local timed = OT.layout(achievements, { { id = 9, objectives = { 'Before time runs out' }, timer = true } })
		local timer = timed[1].lastRegion
		check_stock_bar(timer.Bar, timer.Label, 'the timer bar')

		for _, name in ipairs({ 'BonusObjectiveTracker', 'ScenarioObjectiveTracker' }) do
			local module = OT.modules[name]
			local done = OT.layout(module, { { id = 5, objectives = { 'Clear the area' }, progress = true } })
			local bar = done[1].lastRegion
			local status = bar.Bar
			eq(status.BarFrame:GetAlpha(), 0, name .. ": the bar's frame art faded")
			eq(status.BarBG:GetAlpha(), 0, name .. ": its background faded")
			for _, key in ipairs({ 'BarFrame2', 'BarFrame3', 'BarGlow', 'Sheen', 'Starburst' }) do
				check(not status[key]:IsShown(), name .. ': ' .. key .. ' hidden')
			end
			for _, key in ipairs(OT.FLARES) do check(not bar[key]:IsShown(), name .. ': ' .. key .. ' hidden') end
			check(status.Icon:IsShown() and status.IconBG:IsShown(), name .. ": the reward icon and its ring left as Blizzard's")
			eq(status.IconBG:GetAlpha(), 1, name .. ': the ring not faded')
			eq(status:GetStatusBarTexture():GetTexture(), st.BLANK_TEX, name .. ': a flat fill')
			eq(drawn(status), 'theme,theme,bar', name .. ': drawn as a bar')
			eq(status.Label:GetFontObject(), st:GetFont(profile.objectivetracker.font), name .. ': its text in the font')
		end
		clean()
	end)

	test(client .. ': a collapse button follows its header, by a click or by Blizzard', function()
		world(client)
		local header = quest_module().Header
		local icons = own_regions(header.MinimizeButton)
		-- (the fixture leaves the module frame hidden: press the button unchecked)
		stub.click_unchecked(header.MinimizeButton)
		check(quest_module():IsCollapsed(), 'the click collapses the module')
		for _, icon in ipairs(icons) do eq(icon:GetTexture(), st.icons.chevronDown, 'the chevron points down') end
		OT.as_blizzard(quest_module().SetCollapsed, quest_module(), false)
		for _, icon in ipairs(icons) do eq(icon:GetTexture(), st.icons.chevronUp, 'and up again') end
		OT.as_blizzard(OT.tracker.SetCollapsed, OT.tracker, true)
		for _, icon in ipairs(own_regions(OT.tracker.Header.MinimizeButton)) do
			eq(icon:GetTexture(), st.icons.chevronDown, "the tracker's own chevron follows it")
		end
		clean()
	end)

	test(client .. ': the theme switch both ways', function()
		world(client)
		local QUEST = { { id = 1, objectives = { 'One', 'Two' }, progress = true, item = 3 } }
		local block = OT.layout(quest_module(), QUEST)[1]
		local bar = block.lastRegion
		local item = block.rightEdgeFrame
		local font = st:GetFont(profile.objectivetracker.font)
		local bonus = {}
		for _, name in ipairs({ 'BonusObjectiveTracker', 'ScenarioObjectiveTracker' }) do
			bonus[name] = OT.layout(OT.modules[name], { { id = 5, objectives = { 'Clear the area' }, progress = true } })[1].lastRegion
		end

		switch('blizzard')
		for _, h in ipairs(headers()) do check_header_blizzard(h[1], h[2] .. ', Blizzard') end
		for name, done in pairs(bonus) do check_bonus_bar_blizzard(done, name .. ', Blizzard') end
		check_texts(block, ObjectiveTrackerLineFont, 'Blizzard', true)
		check_stock_bar_blizzard(bar.Bar, bar.Bar.Label, 'the bar, Blizzard')
		check_item_blizzard(item, 'the item, Blizzard')
		-- Blizzard's next layout measures them in its own font again, and its
		-- SetUp leaves the whole texture.
		OT.layout(quest_module(), QUEST)
		check_texts(block, ObjectiveTrackerLineFont, 'Blizzard, laid out again')
		eq(coords(item.icon), T.text(0, 1, 0, 1), 'SetUp under Blizzard: the whole texture')
		-- A block Blizzard makes under Blizzard is left Blizzard's.
		local fresh = OT.layout(quest_module(), { { id = 2, objectives = { 'New' } } })[1]
		eq(fresh.HeaderText:GetFontObject(), ObjectiveTrackerLineFont, "a new block under Blizzard keeps Blizzard's font")

		switch('thick')
		for _, h in ipairs(headers()) do check_header(h[1], h[2] .. ', Thick again') end
		check_texts(fresh, font, 'the new block, Thick again', true)

		block = OT.layout(quest_module(), QUEST)[1]
		check_texts(block, font, 'Thick again, laid out again')
		check_item(item, 2, 'the item, Thick again')
		check_stock_bar(bar.Bar, bar.Bar.Label, 'the bar, Thick again')
		for name, done in pairs(bonus) do
			check(not done.Bar.BarFrame2:IsShown() and not done.Bar.Sheen:IsShown() and not done.FullBarFlare1:IsShown(),
				name .. ': its flash art and flares hidden again, Thick again')
			eq(done.Bar.BarFrame:GetAlpha(), 0, name .. ': its frame art faded again')
		end
		for _, h in ipairs(headers()) do
			if h[1].Shine then check(not h[1].Shine:IsShown() and not h[1].Glow:IsShown(), h[2] .. ': Shine and Glow hidden again') end
		end

		switch('thin')
		check_item(item, 1, 'the item, Thin')
		check(box_of(bar.Bar) ~= nil, 'the bar keeps its backdrop under Thin')
		eq(T.offset(box_of(bar.Bar), 'TOPLEFT'), '-1.00,1.00', "Thin's border outside the bar")
		clean()
	end)

	test(client .. ': off at load: nothing hooked, everything Blizzard\'s; then on and off live', function()
		local hooked = 0
		local real = hooksecurefunc
		world(client, { off = true, before = function()
			hooksecurefunc = function(tbl, ...)
				if OT.is_blizzard(tbl) then hooked = hooked + 1 end
				return real(tbl, ...)
			end
		end })
		-- A profile change or the page re-applying the skins while it's off
		-- hooks nothing either.
		skin:UpdateConfig()
		SK:UpdateConfig()
		local blocks = OT.layout(quest_module(), { { id = 1, objectives = { 'One' }, progress = true, item = 3 } })
		hooksecurefunc = real
		eq(hooked, 0, "nothing of Blizzard's is hooked, at load or by UpdateConfig")
		local block = blocks[1]
		eq(block.HeaderText:GetFontObject(), ObjectiveTrackerLineFont, "the title keeps Blizzard's font")
		eq(#own_children(block.rightEdgeFrame), 0, 'nothing of SaftUI\'s on the item button')
		eq(#own_regions(OT.tracker.Header), 0, 'nothing on the header')
		check(OT.tracker.Header.Background:IsShown(), "Blizzard's banner shows")

		profile.skinning.objective_tracker = true
		SK:UpdateConfig()
		check_header(OT.tracker.Header, 'on live')
		check_texts(block, st:GetFont(profile.objectivetracker.font), 'on live', true)
		check_item(block.rightEdgeFrame, 2, 'the item, on live')

		profile.skinning.objective_tracker = false
		SK:UpdateConfig()
		check_header_blizzard(OT.tracker.Header, 'off live')
		check_texts(block, ObjectiveTrackerLineFont, 'off live', true)
		check_item_blizzard(block.rightEdgeFrame, 'the item, off live')
		clean()
	end)
end

test("SaftUI reads no size of the tracker or its modules, whatever it restyles", function()
	world('forever', { before = function() OT.watch_size() end })
	local QUEST = { { id = 1, objectives = { 'One', 'Two' }, progress = true, item = 3 } }
	OT.layout(quest_module(), QUEST)
	OT.layout(OT.modules.BonusObjectiveTracker, { { id = 2, objectives = { 'Two' }, progress = true } })
	switch('blizzard')
	switch('thick')
	profile.objectivetracker.font = 'pixel'
	skin:UpdateConfig()
	OT.layout(quest_module(), QUEST)
	local reads = {}
	for _, form in ipairs({ 'plain', 'ignore' }) do
		for name, count in pairs(OT.size_reads[form]) do reads[#reads + 1] = form .. ' ' .. name .. '=' .. count end
	end
	eq(table.concat(reads, ','), '', 'no GetWidth, GetHeight or GetSize on the tracker or a module')
	clean()
end)

test('a pooled block handed out again is hooked once and stays styled', function()
	world('forever')
	local hooks = 0
	local real = hooksecurefunc
	hooksecurefunc = function(tbl, name, ...)
		if name == 'GetLine' then hooks = hooks + 1 end
		return real(tbl, name, ...)
	end
	local first = OT.layout(quest_module(), { { id = 1, objectives = { 'One' }, item = 3 } })[1]
	local item = first.rightEdgeFrame
	OT.layout(quest_module(), {})
	local again = OT.layout(quest_module(), { { id = 2, objectives = { 'Two', 'Three' }, item = 4 } })[1]
	hooksecurefunc = real
	check(again == first, 'Blizzard handed the same block out again')
	eq(#OT.made_with('ObjectiveTrackerQuestPOIBlockTemplate'), 1, 'one block made')
	eq(hooks, 1, 'its GetLine hooked once')
	check_texts(again, st:GetFont(profile.objectivetracker.font), 'the reused block')
	check(again.rightEdgeFrame == item, 'the same item button handed out again')
	local _, boxes = box_of(item)
	eq(boxes, 1, 'one backdrop on it')
	eq(#own_regions(item), 1, 'one hover on it')
	clean()
end)

test('in combat: everything is styled with nothing blocked; a protected item button waits', function()
	world('forever')
	stub.in_combat, stub.blocked = true, {}
	local blocks = OT.layout(quest_module(), { { id = 1, objectives = { 'One' }, progress = true, item = 3 } })
	check_texts(blocks[1], st:GetFont(profile.objectivetracker.font), 'in combat')
	check_item(blocks[1].rightEdgeFrame, 2, 'the item, in combat')
	switch('blizzard')
	check_item_blizzard(blocks[1].rightEdgeFrame, 'the item, Blizzard in combat')
	switch('thick')
	eq(#stub.blocked, 0, 'nothing blocked')

	stub.in_combat = false
	clean()

	-- The worst case: item buttons the game counts as protected, made in combat.
	world('forever', { build = { protect_items = true } })
	stub.in_combat, stub.blocked = true, {}
	local item = OT.layout(quest_module(), { { id = 4, objectives = { 'Four' }, item = 5 } })[1].rightEdgeFrame
	check(item:IsProtected(), 'the item button counts as protected')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(item:GetNormalTexture():GetAlpha(), 1, "it keeps Blizzard's look in combat")
	eq(#own_children(item), 0, 'nothing of SaftUI\'s made on it yet')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	check_item(item, 2, 'the protected button, after combat')
	clean()
end)

test("the tracker's fonts on its page reach every text at once", function()
	world('forever')
	local block = OT.layout(quest_module(), { { id = 1, objectives = { 'One' }, progress = true } })[1]
	profile.objectivetracker.font = 'pixel'
	profile.objectivetracker.header_font = 'pixel_med'
	skin:UpdateConfig()
	check_texts(block, st:GetFont('pixel'), 'the font changed', true)
	block = OT.layout(quest_module(), { { id = 1, objectives = { 'One' }, progress = true } })[1]
	check_texts(block, st:GetFont('pixel'), 'the font changed, laid out again')
	eq(OT.tracker.Header.Text:GetFontObject(), st:GetFont('pixel_med'), 'the header font changed')
	eq(block.lastRegion.Bar.Label:GetFontObject(), st:GetFont('pixel'), "the bar's text too")
	clean()
end)

test('the addon loading after SaftUI', function()
	world('forever', { late = true })
	OT.build()
	stub.loaded_addons.Blizzard_ObjectiveTracker = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_ObjectiveTracker')
	check_header(OT.tracker.Header, 'loaded late')
	local block = OT.layout(quest_module(), QUESTS)[1]
	check_texts(block, st:GetFont(profile.objectivetracker.font), 'loaded late')
	clean()
end)

test("an error in a hook is reported, and Blizzard's layout goes on", function()
	world('forever')
	local real = st.SetBackdropIn
	st.SetBackdropIn = function() error('a broken backdrop') end
	local block = OT.layout(quest_module(), { { id = 1, objectives = { 'One' }, progress = true } })[1]
	st.SetBackdropIn = real
	local errors = take_errors()
	eq(#errors, 1, 'one error reported')
	check(tostring(errors[1]):find('a broken backdrop', 1, true) ~= nil, 'the hook\'s error')
	local bar = block.lastRegion
	check(bar ~= block.usedLines[1] and bar.Bar ~= nil, 'Blizzard still added the bar')
	eq(bar:GetNumPoints(), 1, "and placed it")
	check(block.used, "and finished the block's layout")
end)

test("a font that names nothing draws Text on every text, and a typeface reaches them through the skin's update", function()
	world('forever')
	local block = OT.layout(quest_module(), { { id = 1, objectives = { 'One' }, progress = true } })[1]
	for _, value in ipairs({ 'gone', 17, false }) do
		profile.objectivetracker.font, profile.objectivetracker.header_font, profile.skinning.font = value, value, value
		skin:UpdateConfig()
		check_texts(block, st:GetFont('normal'), 'Text for ' .. tostring(value), true)
		eq(OT.tracker.Header.Text:GetFontObject(), st:GetFont('normal'), 'the header: Text for ' .. tostring(value))
	end
	local face = { font_name = 'Colus', font_size = 12, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
	profile.objectivetracker.font, profile.objectivetracker.header_font = face, face
	skin:UpdateConfig()
	check_texts(block, st:FontObject(face), 'a typeface', true)
	eq(OT.tracker.Header.Text:GetFontObject(), st:FontObject(face), 'the header in the typeface')
	clean()
end)
