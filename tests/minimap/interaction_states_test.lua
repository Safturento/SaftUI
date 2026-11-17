-- The micro menu's and the minimap's interaction states (SaftUI-Minimap, Core's
-- Widgets/states.lua): Blizzard's micro buttons are 'icon's whose pieces are
-- their highlight (hover T+ at 0.16, BLEND) and pushed background (the Fill,
-- shown by Blizzard while the button's window is open), with the panel's Accent
-- edge from the existing post-hooks; the bar's items are boxes (Layer for hover
-- and pushed, Alpha 40% when disabled); the tracking, queue and expansion
-- buttons' highlight is T+, BLEND. Blizzard's buttons are locked widgets
-- (lib/locked_widget.lua): a field written onto one fails.
--
-- Real: micromenu.lua, micromenuart.lua, micromenuitems.lua, microbuttons.lua,
-- queuebutton.lua, expansionbutton.lua, Core's helpers and the theme engine.
-- Stand-ins: Blizzard's micro buttons (theme_test.lua's), the minimap
-- cluster's frames, the queue eye and the expansion button.
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')
local locked = load_test_file('lib/locked_widget.lua')

local st, MM

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
	button.PushedBackground:SetAtlas('UI-HUD-MicroMenu-ButtonBG-Down', true)
	button.PushedBackground:Hide()
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
	-- Blizzard's SetPushed: the button state first, then the highlight swap, then
	-- the highlight's alpha (MainMenuBarMicroButtonMixin, forever and live: 0.5
	-- pushed, 1 normal), after the swap SaftUI's SetHighlightAtlas hook follows
	button.SetPushed = function(self)
		self:SetButtonState('PUSHED', true); self:SetHighlightAtlas('UI-HUD-MicroMenu-x-Mouseover', 'BLEND')
		self:GetHighlightTexture():SetAlpha(0.5)
	end
	button.SetNormal = function(self)
		self:SetButtonState('NORMAL'); self:SetHighlightAtlas('UI-HUD-MicroMenu-x-Mouseover', 'BLEND')
		self:GetHighlightTexture():SetAlpha(1)
	end
	return locked(button, 'Blizzard micro button')
end

local function micro_world(theme, count)
	world('forever', theme)
	local buttons = {}
	for i = 1, count or 12 do buttons[i] = micro_button(i, 'Tex' .. i) end
	MM:SkinBlizzardMicroMenu()
	return buttons
end

local function panel_of(button)
	for _, child in ipairs({ button:GetChildren() }) do
		if child ~= button.NotificationOverlay then return child end
	end
end

local function rgba(t) return T.text(t.r, t.g, t.b, t.a) end

test("micro buttons: the highlight T+ at 0.16; a window open: the fade and the panel's accent edge, off again when it closes", function()
	for _, theme in ipairs({ 'thick', 'thin' }) do
		local buttons = micro_world(theme)
		local button = buttons[3]
		local look = st:StateLook(button)
		eq(look.shape, 'icon', theme)
		local h = look.hover_piece
		eq(T.text(h.r, h.g, h.b, h.a), T.text(st:StateColor('hover')), theme .. ': T+ at 0.16')
		check(SL.near(h, '5bc6ff'), theme .. ': at the default Accent ' .. SL.bytes(h))
		eq(h.blend, 'BLEND'); eq(h.texture, st.BLANK_TEX, theme .. ': a white texture')
		eq(look.pieces.checked, button.PushedBackground, theme .. ': the pushed background is the Fill piece')
		eq(look.checked_piece.texture, st.textures.stateFade); eq(look.checked_piece.a, 0.24)
		eq(look.checked_piece.blend, 'BLEND')

		local panel = panel_of(button)
		local rest = T.edge(panel)
		button:SetPushed()
		eq(st:GetState(button, 'selected'), true, theme .. ': selected while its window is open')
		eq(T.edge(panel), T.text(st:StateColor('edge')), theme .. ": the panel's edge is the Accent")
		button:SetNormal()
		eq(st:GetState(button, 'selected'), false, theme .. ': off when it closes')
		eq(T.edge(panel), rest, theme .. ": the panel's own edge again")
		-- a theme recolor while open keeps the edge
		button:SetPushed()
		st:RecolorThemed()
		eq(T.edge(panel), T.text(st:StateColor('edge')), theme .. ': through a recolor')
		button:SetNormal()
	end
end)

-- One alpha for a texture: SetAlpha and the vertex color's alpha write and read the
-- same value. The stubs keep two (a region alpha and a vertex alpha, multiplied);
-- the in-game opaque hover of 2026-11-16 (micro buttons from Professions to Shop,
-- the highlight T+ at full strength right after Blizzard's SetNormal) is what one
-- value gives. Unverified in the client (the report's /run line decides), so it is
-- put on the one texture a case names, never on the stubs.
local function one_alpha(texture)
	local methods = getmetatable(texture).__index
	local setAlpha, setColor = methods.SetAlpha, methods.SetVertexColor
	texture.SetAlpha = function(self, a)
		setAlpha(self, a)
		local r, g, b = self:GetVertexColor()
		setColor(self, r, g, b, self:GetAlpha())
	end
	texture.SetVertexColor = function(self, r, g, b, a)
		setColor(self, r, g, b, a or self:GetAlpha())
		setAlpha(self, select(4, self:GetVertexColor()))
	end
	return texture
end

test("micro buttons: Blizzard's SetNormal and SetPushed set the highlight's alpha after the swap; the hover's strength is put back after them", function()
	for _, theme in ipairs({ 'thick', 'thin' }) do
		local buttons = micro_world(theme)
		local hoverAlpha = select(4, st:StateColor('hover'))
		-- one alpha a texture: the hover's own 16% after each, never Blizzard's 1 or 0.5
		local button = buttons[3]
		local highlight = one_alpha(button:GetHighlightTexture())
		button:SetNormal()
		eq(('%.2f'):format(select(4, highlight:GetVertexColor())), ('%.2f'):format(hoverAlpha),
			theme .. ', one alpha: after SetNormal (UpdateMicroButtons) the hover is a tint, not a solid block')
		local hr, hg, hb = st:StateColor('hover')
		local r, g, b = highlight:GetVertexColor()
		eq(T.text(r, g, b), T.text(hr, hg, hb), theme .. ': its color is the hover tone')
		button:SetPushed()
		eq(('%.2f'):format(select(4, highlight:GetVertexColor())), ('%.2f'):format(hoverAlpha), theme .. ', one alpha: after SetPushed too')
		button:SetNormal()
		eq(('%.2f'):format(select(4, highlight:GetVertexColor())), ('%.2f'):format(hoverAlpha), theme .. ', one alpha: and closed again')
		-- two alphas (the stubs'): what shows is Blizzard's alpha times the hover's, as before
		local other = buttons[4]:GetHighlightTexture()
		buttons[4]:SetNormal()
		eq(('%.2f'):format(other:GetAlpha() * select(4, other:GetVertexColor())), ('%.2f'):format(hoverAlpha),
			theme .. ', two alphas: the hover at its strength after SetNormal')
		eq(#stub.blocked, 0)
	end
end)

test('bar items: Layer for hover and pushed, 40% when disabled; tracking, queue and expansion: BLEND hover at 0.16', function()
	world('forever')
	local item = CreateFrame('Button', nil, UIParent)
	item:SetSize(60, 20)
	MM:SkinBarButton(item)
	stub.fire_script(item, 'OnEnter')
	local look = st:StateLook(item)
	eq(look.layer.shown, true); eq(look.layer.blend, 'BLEND')
	eq(rgba(look.layer), T.text(st:StateColor('hover')), 'hover: T+')
	stub.fire_script(item, 'OnMouseDown', 'LeftButton')
	eq(rgba(st:StateLook(item).layer), T.text(st:StateColor('pushed')), 'pushed: T-')
	stub.fire_script(item, 'OnMouseUp', 'LeftButton')
	stub.fire_script(item, 'OnLeave')
	eq(st:StateLook(item).layer.shown, false)
	item:Disable()
	eq(st:StateLook(item).alpha, 0.4, 'disabled: 40%')
	stub.fire_script(item, 'OnEnter')
	eq(st:StateLook(item).layer.shown, false, 'no hover while disabled')
	item:Enable()
	eq(st:StateLook(item).alpha, 1)
	local off = CreateFrame('Button', nil, UIParent)
	off:Disable()
	MM:SkinBarButton(off)
	eq(st:StateLook(off).alpha, 0.4, 'a button disabled before it is skinned')

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
	QueueStatusButton = CreateFrame('Button', 'QueueStatusButton', UIParent)
	QueueStatusButton.Eye = QueueStatusButton:CreateTexture()
	MM:SkinQueueButton()
	ExpansionLandingPageMinimapButton = CreateFrame('Button', 'ExpansionLandingPageMinimapButton', UIParent)
	ExpansionLandingPageMinimapButton:SetNormalTexture(ExpansionLandingPageMinimapButton:CreateTexture())
	local pushedArt = ExpansionLandingPageMinimapButton:CreateTexture()
	pushedArt:SetAtlas('expansion-pushed')
	ExpansionLandingPageMinimapButton:SetPushedTexture(pushedArt)
	ExpansionLandingPageMinimapButton.UpdateIcon = function() end
	MM:SkinExpansionButton()
	MM:UpdateExpansionLandingPageButton()
	for name, b in pairs({ tracking = tracking.Button, queue = QueueStatusButton, expansion = ExpansionLandingPageMinimapButton }) do
		local hover = b:GetHighlightTexture()
		eq(st:StateLook(b).pieces.hover, hover, name .. ': the highlight is the hover piece')
		eq(T.text(hover:GetVertexColor()), T.text(st:StateColor('hover')), name .. ': T+ at 0.16')
		eq(hover:GetBlendMode(), 'BLEND', name .. ': BLEND, not the game\'s additive default')
		eq(st:StateLook(b).pushed_piece, nil, name .. ': no pushed piece of ours')
	end
	eq(pushedArt:GetAtlas(), 'expansion-pushed', "the expansion button's pushed art is Blizzard's")
	eq(T.text(pushedArt:GetVertexColor()), '1.00,1.00,1.00,1.00', 'untinted')
end)

test("under Blizzard: Blizzard's highlight and pushed art, untinted and left alone by a pass", function()
	local buttons = micro_world('blizzard')
	local button = buttons[2]
	local hover, pushed = button:GetHighlightTexture(), button.PushedBackground
	eq(st:StateLook(button).blizzard, true)
	eq(hover:GetAtlas(), 'UI-HUD-MicroMenu-Tex2-Mouseover', "Blizzard's highlight")
	eq(pushed:GetAtlas(), 'UI-HUD-MicroMenu-ButtonBG-Down', "Blizzard's pushed background")
	eq(T.text(hover:GetVertexColor()), '1.00,1.00,1.00,1.00'); eq(T.text(pushed:GetVertexColor()), '1.00,1.00,1.00,1.00')
	st.config.profile.theme.accent:SetRGB(0.9, 0.2, 0.1)
	local m = C.measure(function() st:ColorChanged('accent') end)
	eq(m.calls.total, 0, 'a pass touches nothing')
	button:SetPushed()
	eq(T.text(pushed:GetVertexColor()), '1.00,1.00,1.00,1.00', 'a window open: still untinted')
	eq(hover:GetAtlas(), 'UI-HUD-MicroMenu-x-Mouseover', "Blizzard's own swap stays")
	st.config.profile.theme.accent:SetRGB(0, 0.68, 0.94)
	-- and to Thick and back
	T.theme('thick'); MM:UpdateButtons()
	eq(hover:GetAtlas(), nil, 'Thick: flat'); eq(hover:GetTexture(), st.BLANK_TEX)
	T.theme('blizzard'); MM:UpdateButtons()
	eq(T.text(hover:GetVertexColor()), '1.00,1.00,1.00,1.00', 'untinted again')
	eq(pushed:GetAtlas(), 'UI-HUD-MicroMenu-ButtonBG-Down')
end)

test('a pass: under 60 calls over the micro menu and its items, nothing made or forbidden', function()
	local buttons = micro_world('thick')
	local items = {}
	for i = 1, 4 do
		items[i] = CreateFrame('Button', nil, UIParent)
		items[i]:SetSize(40, 20)
		MM:SkinBarButton(items[i])
	end
	st.config.profile.theme.accent:SetRGB(0.3, 0.9, 0.6)
	local m = C.measure(function() st:ColorChanged('accent') end)
	check(m.calls.total < 60, 'calls in one pass: ' .. m.calls.total)
	eq(m.calls.total, 12 * 3, "3 a micro button (the highlight, the Fill and its coordinates), none for the items at rest")
	eq(m.forbidden.total, 0); eq(m.made, 0)
	stub.in_combat = true
	local k = C.measure(function() st:ColorChanged('accent') end, 100)
	eq(k.forbidden.total, 0, 'in combat too')
	check(k.kb < 4, 'garbage over 100 passes: ' .. k.kb .. ' KB')
	-- a window opening in combat: the selected state only colors (the swap's own re-styling, the
	-- point and texture calls Blizzard's art swap needs, was there before and is not this state)
	local c = C.measure(function()
		buttons[1]:SetButtonState('PUSHED', true); MM.OnButtonState(buttons[1])
		buttons[1]:SetButtonState('NORMAL'); MM.OnButtonState(buttons[1])
	end)
	eq(c.forbidden.total, 0, 'the selected state in combat: nothing forbidden')
	eq(c.made, 0)
	stub.in_combat = false
	C.print('micro menu, accent', m)
	eq(#stub.blocked, 0)
end)
