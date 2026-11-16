-- The micro menu's stats and alert flash in the state colors: the latency text
-- runs from Text > Success through Caution to Warning (SaftUI-Minimap/stats.lua),
-- and the flat alert flash on a micro button is Text > Caution
-- (microbuttons.lua). Every case runs with the three at values that are not
-- their defaults, so a reader that drew a color of its own fails.
--
-- Real: stats.lua on a stand-in MicroMenu module, and Core's gradient
-- (st:ColorGradient, Utilities/utilities.lua).
load_core_helpers()
load_saftui('SaftUI-Core/Utilities/utilities.lua')
local T = load_test_file('lib/theme_helpers.lua')
local st = SaftUI
local MicroMenu = st:NewModule('MicroMenu')
load_saftui('SaftUI-Minimap/stats.lua')

local colors = st.config.profile.colors.text
local GOOD, OKAY, BAD = { 0.1, 0.8, 0.3 }, { 0.7, 0.7, 0.2 }, { 0.9, 0.4, 0.1 }
colors.success:SetRGB(unpack(GOOD)); colors.caution:SetRGB(unpack(OKAY)); colors.warning:SetRGB(unpack(BAD))

local function fontstring()
	local fs = CreateFrame('Frame', nil, UIParent):CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(GameFontNormal)
	return fs
end

test('the latency text runs from Success (fast) through Caution to Warning (slow), at odd values', function()
	local latency = { text = fontstring() }
	local cases = { { 0, GOOD, 'no delay: Success' }, { 300, OKAY, 'half of the worst: Caution' }, { 600, BAD, 'the worst: Warning' } }
	for _, case in ipairs(cases) do
		_G.GetNetStats = function() return 0, 0, case[1], case[1] end
		latency.lastUpdate = nil
		MicroMenu:UpdateLatency(latency)
		eq(T.rgb(latency.text:GetTextColor()), T.rgb(unpack(case[2])), case[3])
	end
end)

test('a changed color is the next reading', function()
	local latency = { text = fontstring() }
	colors.success:SetRGB(0.2, 0.2, 0.9)
	_G.GetNetStats = function() return 0, 0, 0, 0 end
	MicroMenu:UpdateLatency(latency)
	eq(T.rgb(latency.text:GetTextColor()), T.rgb(0.2, 0.2, 0.9), 'Success changed')
	colors.success:SetRGB(unpack(GOOD))
end)

------------------------------------------------------------------ live colors
-- A pick on the Colors tab reaches the micro menu at once
-- (MicroMenu:OnColorsChanged, and the items' own followers): Blizzard's micro
-- buttons' highlight and pushed Fill (the derived states: the Accent) and their
-- alert flash (Text > Caution at 0.5), under Thick and Thin only; the instance difficulty badge (Item quality 1, 3 and 4); and the bar
-- items' and the tracking, queue and expansion buttons' hover. Only colors, in
-- combat too.
--
-- Real: micromenu.lua, micromenuart.lua, micromenuitems.lua,
-- micromenuoptions.lua, microbuttons.lua, instancedifficulty.lua,
-- queuebutton.lua, expansionbutton.lua, Core's helpers and the theme engine.
-- Stand-ins: Blizzard's micro buttons (as theme_test.lua builds them), the
-- minimap cluster's frames, the queue eye and the expansion button.
local C = load_test_file('lib/color_cost.lua')
local locked = load_test_file('lib/locked_widget.lua')

local MM

local function world(client, theme)
	st = T.client(client)
	CreateFrame('Frame', 'Minimap', UIParent)
	load_saftui('SaftUI-Minimap/minimap.lua')
	load_saftui('SaftUI-Minimap/config.lua')
	apply_defaults()
	for _, file in ipairs({ 'micromenu', 'micromenuart', 'micromenuitems', 'micromenuoptions', 'microbuttons',
			'instancedifficulty', 'queuebutton', 'expansionbutton' }) do
		load_saftui('SaftUI-Minimap/' .. file .. '.lua')
	end
	MM = st:GetModule('MicroMenu')
	MM.Container = CreateFrame('Frame', nil, UIParent)
	MM.Container:SetPoint('TOPLEFT')
	st.config.profile.theme.name = theme or 'thick'
	st:RedrawThemed()
	st.config.profile.colors.text.caution:SetRGB(0.7, 0.7, 0.2)
	return st
end

local function micro_button(index, textureName)
	local menu = _G.MicroMenu
	if not menu then
		menu = CreateFrame('Frame', 'MicroMenu', UIParent)
		function menu:Layout() end
	end
	local button = CreateFrame('Button', nil, menu)
	button.layoutIndex, button.textureName = index, textureName
	button.Background = button:CreateTexture(nil, 'BACKGROUND')
	button.PushedBackground = button:CreateTexture(nil, 'BACKGROUND')
	button.FlashBorder = button:CreateTexture(nil, 'OVERLAY')
	button.Shadow = button:CreateTexture(nil, 'BORDER')
	button.PushedShadow = button:CreateTexture(nil, 'OVERLAY')
	button.MainMenuBarPerformanceBar = button:CreateTexture(nil, 'ARTWORK')
	button.Emblem = button:CreateTexture(nil, 'ARTWORK')
	button.HighlightEmblem = button:CreateTexture(nil, 'ARTWORK')
	button.NotificationOverlay = CreateFrame('Frame', nil, button)
	button.NotificationOverlay:CreateTexture(nil, 'OVERLAY')
	button:SetNormalTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetPushedTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetHighlightTexture(button:CreateTexture(nil, 'HIGHLIGHT'))
	button.SetHighlightAtlas = function(self, atlas, blend)
		local highlight = self:GetHighlightTexture()
		highlight:SetAtlas(atlas)
		highlight:SetBlendMode(blend or 'BLEND')
	end
	return locked(button, 'Blizzard micro button')
end

local function color_of(region)
	local c = stub.state(region).color_texture
	return c and (T.rgb(c[1], c[2], c[3]) .. ' ' .. string.format('%.2f', c[4])) or 'none'
end

local function micro_world(theme, count)
	world('forever', theme)
	local buttons = {}
	for i = 1, count or 12 do buttons[i] = micro_button(i, 'Tex' .. i) end
	MM:SkinBlizzardMicroMenu()
	return buttons
end

test("the Accent: the micro buttons' highlight (T+) and pushed Fill, vertex colors on white textures, under Thick and Thin only", function()
	for _, theme in ipairs({ 'thick', 'thin' }) do
		local buttons = micro_world(theme)
		st.config.profile.theme.accent:SetRGB(0.2, 0.9, 0.3)
		local m = C.measure(function() st:ColorChanged('accent') end)
		eq(m.calls.by.SetColorTexture, nil, theme .. ': no color texture is set again')
		eq(m.calls.by.SetVertexColor, 24, theme .. ': the highlight and the Fill of each')
		eq(m.calls.by.SetTexCoord, 12, theme .. ": the Fill's coordinates")
		eq(m.calls.total, 36, theme .. ': 3 calls a button')
		eq(m.forbidden.total, 0, theme .. ': nothing forbidden')
		eq(m.made, 0)
		local h = stub.state(buttons[5]:GetHighlightTexture()).vertex_color
		eq(T.rgb(h[1], h[2], h[3]) .. ' ' .. string.format('%.2f', h[4]), T.rgb(st:StateColor('hover')) .. ' ' .. string.format('%.2f', select(4, st:StateColor('hover'))), theme .. ': T+ at 0.16')
		local f = stub.state(buttons[5].PushedBackground).vertex_color
		eq(T.rgb(f[1], f[2], f[3]), T.rgb(0.2, 0.9, 0.3), theme .. ': the Fill is the Accent')
		eq(stub.state(buttons[5]:GetHighlightTexture()).texture, st.BLANK_TEX, theme .. ': a white texture, set once')
		-- the Buttons colors reach nothing here any more
		m = C.measure(function() st:ColorChanged('button', 'hover'); st:ColorChanged('button', 'pushed') end)
		eq(m.calls.total, 0, theme .. ': Buttons > Hover and Pushed reach no micro button')
		st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
	end
	local buttons = micro_world('blizzard')
	local m = C.measure(function() st:ColorChanged('accent'); st:ColorChanged('text', 'caution') end)
	eq(m.calls.by.SetColorTexture, nil, "Blizzard: its own art, nothing colored")
	eq(m.calls.by.SetVertexColor, nil)
	eq(m.forbidden.total, 0)
	eq(color_of(buttons[1].PushedBackground), 'none')
end)

test('Text > Caution: the alert flash at 0.5', function()
	local buttons = micro_world('thick')
	st.config.profile.colors.text.caution:SetRGB(0.9, 0.5, 0.1)
	local m = C.measure(function() st:ColorChanged('text', 'caution') end)
	eq(m.calls.by.SetColorTexture, 12, 'the alert flash of each')
	eq(m.forbidden.total, 0)
	eq(color_of(buttons[3].FlashBorder), T.rgb(0.9, 0.5, 0.1) .. ' 0.50', 'Caution at 0.5')
end)

test('Item quality 1, 3 and 4 by key: the difficulty badge (retail, which has one)', function()
	world('retail', 'thick')
	local m

	MinimapCluster = CreateFrame('Frame', 'MinimapCluster', UIParent)
	MinimapCluster.InstanceDifficulty = CreateFrame('Frame', nil, MinimapCluster)
	function MinimapCluster.InstanceDifficulty:Update() end
	local badge = MM:SkinInstanceDifficulty()
	local info = { difficultyID = 23, mythic = true }
	GetInstanceInfo = function() return 'Dungeon', 'party', info.difficultyID, '', 5, 0, false, 1, 5, 0 end
	GetDifficultyInfo = function() return '', 'party', false, false, false, info.mythic, 0 end
	MM:UpdateDungeonDifficulty()
	local function bg() return T.rgb(stub.state(badge.Bg).vertex_color[1], stub.state(badge.Bg).vertex_color[2], stub.state(badge.Bg).vertex_color[3]) end
	local quality = st.config.profile.colors.item_quality
	eq(bg(), T.rgb(quality[4]:GetRGB()), 'Mythic: Item quality 4')
	quality[4]:SetRGB(0.1, 0.9, 0.9)
	m = C.measure(function() st:ColorChanged('item_quality', 4) end)
	eq(bg(), T.rgb(0.1, 0.9, 0.9), 'a pick of 4 reaches it at once')
	eq(m.forbidden.total, 0); eq(m.made, 0)
	quality[1]:SetRGB(0.9, 0.9, 0.1)
	st:ColorChanged('item_quality', 1)
	eq(bg(), T.rgb(0.1, 0.9, 0.9), 'a pick of 1 leaves a Mythic badge alone')
	info.difficultyID, info.mythic = 2, false
	GetDifficultyInfo = function() return '', 'party', true, false, true, false, 0 end
	MM:UpdateDungeonDifficulty()
	quality[3]:SetRGB(0.9, 0.1, 0.5)
	st:ColorChanged('item_quality', 3)
	eq(bg(), T.rgb(0.9, 0.1, 0.5), 'Heroic: a pick of Item quality 3')
	quality[3]:SetRGB(0.5, 0.1, 0.9)
	st:ColorsChanged('item_quality')
	eq(bg(), T.rgb(0.5, 0.1, 0.9), 'and on a whole pass')
	GetDifficultyInfo = function() return '', 'party', false, false, false, false, 0 end
	MM:UpdateDungeonDifficulty()
	eq(bg(), T.rgb(0.9, 0.9, 0.1), 'Normal: Item quality 1')
	eq(#take_errors(), 0)
end)

test('the bar items and the tracking, queue and expansion buttons follow the Accent', function()
	world('forever')
	local bar = CreateFrame('Button', nil, UIParent)
	bar:SetSize(60, 20)
	MM:SkinBarButton(bar)
	check(bar:GetHighlightTexture() == nil, "a bar item has no texture of the game's highlight: the Layer is the helper's")

	MinimapCluster = CreateFrame('Frame', 'MinimapCluster', UIParent)
	local tracking = CreateFrame('Frame', nil, MinimapCluster)
	MinimapCluster.Tracking = tracking
	tracking.Button = CreateFrame('Button', nil, tracking)
	for _, setter in ipairs({ 'SetNormalTexture', 'SetPushedTexture', 'SetHighlightTexture' }) do
		tracking.Button[setter](tracking.Button, tracking.Button:CreateTexture())
	end
	tracking.Button.StateTexture = tracking.Button:CreateTexture()
	tracking.Button.AddTexture = tracking.Button:CreateTexture()
	tracking.Button.OnButtonStateChanged = function() end
	MM:SkinTrackingButton()
	local trackingHover = tracking.Button:GetHighlightTexture()

	QueueStatusButton = CreateFrame('Button', 'QueueStatusButton', UIParent)
	QueueStatusButton.Eye = QueueStatusButton:CreateTexture()
	MM:SkinQueueButton()
	local queueHover = QueueStatusButton:GetHighlightTexture()

	ExpansionLandingPageMinimapButton = CreateFrame('Button', 'ExpansionLandingPageMinimapButton', UIParent)
	ExpansionLandingPageMinimapButton:SetNormalTexture(ExpansionLandingPageMinimapButton:CreateTexture())
	ExpansionLandingPageMinimapButton:SetPushedTexture(ExpansionLandingPageMinimapButton:CreateTexture())
	ExpansionLandingPageMinimapButton.UpdateIcon = function() end
	MM:SkinExpansionButton()
	MM:UpdateExpansionLandingPageButton()
	local expansionHover = ExpansionLandingPageMinimapButton:GetHighlightTexture()

	local function vertex(region)
		local c = stub.state(region).vertex_color
		return T.rgb(c[1], c[2], c[3]) .. ' ' .. string.format('%.2f', c[4])
	end
	st.config.profile.theme.accent:SetRGB(0.9, 0.3, 0.1)
	local m = C.measure(function() st:ColorChanged('accent') end)
	local want = T.rgb(st:StateColor('hover')) .. ' ' .. string.format('%.2f', select(4, st:StateColor('hover')))
	eq(vertex(trackingHover), want, 'the tracking button: the derived hover')
	eq(vertex(queueHover), want, 'the queue eye')
	eq(vertex(expansionHover), want, 'the expansion button')
	for name, region in pairs({ tracking = trackingHover, queue = queueHover, expansion = expansionHover }) do
		eq(stub.state(region).blend_mode, 'BLEND', name .. ': BLEND, as the game would not have it by default')
	end
	eq(m.calls.by.SetVertexColor, 3, 'one color a button')
	eq(m.forbidden.total, 0); eq(m.made, 0)
	-- Blizzard's pushed art on the expansion button is left as it is
	eq(ExpansionLandingPageMinimapButton:GetPushedTexture() ~= nil, true)
	check(stub.state(ExpansionLandingPageMinimapButton:GetPushedTexture()).vertex_color == nil
		or vertex(ExpansionLandingPageMinimapButton:GetPushedTexture()) == '1.00,1.00,1.00 1.00', "its pushed art is Blizzard's")
	-- Blizzard's UpdateIcon puts an atlas on the highlight: it is flat white again after
	expansionHover:SetAtlas('some-atlas')
	MM:UpdateExpansionLandingPageButton()
	eq(expansionHover:GetAtlas(), nil, 'the flat texture is back')
	eq(stub.state(expansionHover).texture, st.BLANK_TEX)
	eq(vertex(expansionHover), want)
	-- the bar item: the Layer
	stub.fire_script(bar, 'OnEnter')
	local look = st:StateLook(bar)
	eq(look.layer.shown, true, 'a bar item shows the hover Layer under the mouse')
	eq(look.layer.blend, 'BLEND')
	eq(string.format('%.2f', look.layer.a), '0.16')
	stub.fire_script(bar, 'OnMouseDown', 'LeftButton')
	eq(string.format('%.2f', st:StateLook(bar).layer.a), '0.32', 'pushed: T-')
	stub.fire_script(bar, 'OnMouseUp', 'LeftButton')
	stub.fire_script(bar, 'OnLeave')
	eq(st:StateLook(bar).layer.shown, false)
	bar:Disable()
	eq(st:GetState(bar, 'disabled'), true, 'disabled when the game disables it')
	eq(st:StateLook(bar).alpha, st:StateAlpha(), 'at 40%')
	bar:Enable()
	eq(st:GetState(bar, 'disabled'), false)
	eq(st:StateLook(bar).alpha, 1)
	st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
	eq(#take_errors(), 0)
end)

test('in combat a pick reaches the micro buttons with no forbidden call and almost no garbage (Review Focus 4)', function()
	local buttons = micro_world('thick')
	for _, button in ipairs(buttons) do
		button.FlashBorder:SetColorTexture(1, 1, 1, 1)
	end
	stub.in_combat = true
	local m = C.measure(function()
		st:ColorChanged('accent')
		st:ColorChanged('text', 'caution')
	end, 100)
	eq(m.forbidden.total, 0, 'nothing forbidden in combat')
	eq(m.made, 0)
	check(m.kb < 4, 'garbage over 100 passes: ' .. m.kb .. ' KB')
	C.print('micro buttons, accent + caution', m)
	stub.in_combat = false
	eq(#stub.blocked, 0)
end)
