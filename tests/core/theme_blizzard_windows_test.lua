-- Windows and close buttons under the Blizzard theme (SaftUI-Core/panels.lua,
-- with theme.lua and themeart.lua):
--   - st:CreatePanel draws a window (the metal under Blizzard), whose header
--     and footer keep the profile's header height under every theme, with no
--     strip under Blizzard and their strips again under Thick;
--   - SaftUI's close button (st:CreateCloseButton) wears Blizzard's four
--     textures at the client's size under SaftUI's theme Blizzard, and its own
--     look again under Thick;
--   - on a window it sits in the metal's socket (st:CloseButtonInSocket), at
--     the client's spot from the window's drawn frame, and goes back to the
--     header under Thick; the /sui window's, which isn't a window, keeps its
--     place;
--   - a profile switch from a Blizzard profile to a Thick one (Review Focus 5)
--     takes the art off and gives the close button its own look, with no
--     reload;
--   - a close button made for a frame that isn't SaftUI's writes nothing onto
--     it through a switch.
--
-- Real: Core's helpers, theme.lua and themeart.lua (T.client, on Forever or
-- retail), and for the /sui window and the profile switch, Core's
-- Config/config.lua on a real AceDB-3.0 (core/config_helpers.lua) with the
-- options window. Each case starts from a fresh world.
local T = load_test_file('lib/theme_helpers.lua')
local locked = load_test_file('misc/fixtures/locked_widget.lua')
local text, fill = T.text, T.fill

-- A nine-slice border's shown pieces as T.art lists them.
local function nine(prefix)
	return table.concat({
		'BottomEdge=_' .. prefix .. '-EdgeBottom',
		'BottomLeftCorner=' .. prefix .. '-CornerBottomLeft',
		'BottomRightCorner=' .. prefix .. '-CornerBottomRight',
		'LeftEdge=!' .. prefix .. '-EdgeLeft',
		'RightEdge=!' .. prefix .. '-EdgeRight',
		'TopEdge=_' .. prefix .. '-EdgeTop',
		'TopLeftCorner=' .. prefix .. '-CornerTopLeft',
		'TopRightCorner=' .. prefix .. '-CornerTopRight',
	}, ',')
end
local TOOLTIP, METAL = nine('Tooltip-NineSlice'), nine('UI-Frame-Metal')

-- Thick's header strip: its border color at 0.4.
local THICK_STRIP = '0.30,0.30,0.30,0.40'

-- SaftUI's theme switched and every drawn frame drawn again, as the Theme tab
-- does it (the profile update's first step).
local function switch(st, name)
	st.config.profile.theme.name = name
	st:RedrawThemed()
end

-- A region's first anchor as text, 'POINT relative RELPOINT x,y', relative
-- named from names (region -> name).
local function anchor(region, names)
	local point, rel, relPoint, x, y = region:GetPoint(1)
	return ('%s %s %s %s'):format(tostring(point), names[rel] or tostring(rel), tostring(relPoint), text(x, y))
end

-- A state texture's atlas, 'none' for no texture.
local function atlas(texture)
	return texture and tostring(texture:GetAtlas()) or 'none'
end

-- A state texture showing nothing: none at all, or one with no atlas and no file.
local function clear(texture)
	return texture == nil or (texture:GetAtlas() == nil and texture:GetTexture() == nil)
end

-- Checks a close button wears Blizzard's look at size.
local function blizzardLook(close, size, where)
	eq(atlas(close:GetNormalTexture()), 'RedButton-Exit', where .. ': the normal atlas')
	eq(atlas(close:GetPushedTexture()), 'RedButton-exit-pressed', where .. ': pushed')
	eq(atlas(close:GetHighlightTexture()), 'RedButton-Highlight', where .. ': highlight')
	eq(close:GetHighlightTexture() and close:GetHighlightTexture():GetBlendMode(), 'ADD', where .. ': the highlight is additive')
	eq(atlas(close:GetDisabledTexture()), 'RedButton-Exit-Disabled', where .. ': disabled')
	eq(text(close:GetSize()), text(size, size), where .. ": the client's size")
	eq(close:GetNormalTexture() and T.around(close:GetNormalTexture(), close), '0,0,0,0', where .. ': the art fills the button')
	check(not close.icon:IsShown(), where .. ': its own X hidden')
	check(not close.outline:IsShown(), where .. ': its dark line hidden')
	eq(close.backdropInfo, nil, where .. ': its own backdrop off')
end

-- Checks a close button wears its own look (today's).
local function ownLook(st, close, where)
	eq(text(close:GetSize()), '24.00,24.00', where .. ': 24 square')
	check(close.icon:IsShown(), where .. ': its X shown')
	check(close.outline:IsShown(), where .. ': its dark line shown')
	eq(fill(close), text(unpack(st.BOX_COLORS.field)), where .. ': the field fill')
	eq(T.edge(close), text(unpack(st.BOX_COLORS.edge)), where .. ': the edge border')
	check(clear(close:GetNormalTexture()), where .. ': its normal texture clear')
	check(clear(close:GetPushedTexture()), where .. ': pushed clear')
	check(clear(close:GetHighlightTexture()), where .. ': highlight clear')
	check(clear(close:GetDisabledTexture()), where .. ': disabled clear')
end

local function panel(st, name)
	local p = st:CreatePanel(name, 200, 100)
	p:SetPoint('CENTER')
	return p
end

------------------------------------------------------------------ windows

test('st:CreatePanel draws a window', function()
	local st = T.client('forever')
	local drawn = T.watch()
	local p = panel(st, 'Window test')
	eq(drawn(p), 'theme,theme,window', 'panels.theme and panels.background, as a window')
	eq(st:DrawnKind(p), 'window', 'the engine records it as a window')
	switch(st, 'blizzard')
	eq(T.art(p.backdrop), METAL, 'under Blizzard it wears the metal')
end)

test("under Blizzard a window's header keeps its height and draws nothing; under Thick it has its strip again", function()
	local st = T.client('forever')
	local p = panel(st, 'Header test')
	st:CreateFooter(p)
	local content = st:CreateFrame('Frame', nil, p)
	content:SetPoint('TOPLEFT', p.header, 'BOTTOMLEFT', 5, -5)
	content:SetPoint('BOTTOMRIGHT', p, 'BOTTOMRIGHT', -5, 5)
	local function rect(f) return text(f:GetLeft(), f:GetTop(), f:GetRight(), f:GetBottom()) end
	local window, inside, header = rect(p), rect(content), rect(p.header)

	local function expect(name, strip)
		eq(p.header:GetHeight(), 31, name .. ": the header is the profile's 31 tall")
		eq(p.footer:GetHeight(), 31, name .. ': the footer too')
		eq(rect(p), window, name .. ': the window keeps its place and size')
		eq(rect(p.header), header, name .. ': the header keeps its points')
		eq(rect(content), inside, name .. ": the window's content keeps its points")
		if strip then
			eq(fill(p.header), strip, name .. ': the header strip')
			eq(fill(p.footer), strip, name .. ': the footer strip')
		else
			eq(p.header.backdropInfo, nil, name .. ': no strip')
			eq(p.footer.backdropInfo, nil, name .. ': none on the footer')
			eq(T.art(p.header), '', name .. ': no art on the header')
		end
	end
	expect('Thick', THICK_STRIP)
	switch(st, 'blizzard')
	expect('Blizzard', nil)
	eq(T.art(p.backdrop), METAL, 'Blizzard: the window wears the metal')
	switch(st, 'thick')
	expect('Thick again', THICK_STRIP)
	eq(T.art(p.backdrop), '', 'Thick again: no art')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the close button

test("SaftUI's close button under Blizzard: Blizzard's four atlases at the client's size; under Thick its own look again", function()
	for _, case in ipairs({ { 'forever', 28 }, { 'retail', 24 } }) do
		local client, size = case[1], case[2]
		local st = T.client(client)
		local frame = st:CreateFrame('Frame', nil, UIParent)
		frame:SetSize(200, 100)
		frame:SetPoint('CENTER')
		local close = st:CreateCloseButton(frame)
		ownLook(st, close, client .. ', Thick')

		switch(st, 'blizzard')
		blizzardLook(close, size, client .. ', Blizzard')
		-- Its own hover look stays off: Blizzard's highlight shows the hover.
		stub.fire_script(close, 'OnEnter')
		eq(close.backdropInfo, nil, client .. ': hovered, its own backdrop stays off')
		check(not close.icon:IsShown(), client .. ': and its X hidden')
		stub.fire_script(close, 'OnLeave')
		st:RecolorThemed()
		blizzardLook(close, size, client .. ', after a recolor')

		switch(st, 'thick')
		ownLook(st, close, client .. ', Thick again')
		stub.fire_script(close, 'OnEnter')
		eq(T.edge(close), text(st.config.profile.colors.text.red:GetRGB()) .. ',1.00', client .. ': hovered under Thick, its red border')
		stub.fire_script(close, 'OnLeave')
		eq(T.edge(close), text(unpack(st.BOX_COLORS.edge)), client .. ': and back')

		-- A close button made while the theme is Blizzard has Blizzard's look at once.
		switch(st, 'blizzard')
		local other = st:CreateFrame('Frame', nil, UIParent)
		other:SetSize(200, 100)
		other:SetPoint('CENTER')
		local made = st:CreateCloseButton(other)
		blizzardLook(made, size, client .. ', made under Blizzard')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('on a window the close button sits in the socket, and goes back', function()
	for _, case in ipairs({ { 'forever', 0, 3 }, { 'retail', 1, 0 } }) do
		local client, x, y = case[1], case[2], case[3]
		local st = T.client(client)
		local p = panel(st, 'Socket test')
		local close = st:GetCloseButton(p)
		local names = { [p.header] = 'header', [p.backdrop] = 'backdrop', [p] = 'window' }
		local home = 'RIGHT header RIGHT -10.00,0.00'

		eq(anchor(close, names), home, client .. ', Thick: at the right of the header')
		eq(st:CloseButtonInSocket(p), false, client .. ', Thick: not in the socket')

		switch(st, 'blizzard')
		eq(close:GetNumPoints(), 1, client .. ', Blizzard: one point')
		eq(anchor(close, names), 'TOPRIGHT backdrop TOPRIGHT ' .. text(x, y),
			client .. ", Blizzard: at TOPRIGHT of the window's drawn frame, in the metal's socket")
		eq(st:CloseButtonInSocket(p), true, client .. ', Blizzard: in the socket')
		check(close:GetBottom() > p.header:GetBottom(), client .. ': above the header row, on the title bar')
		check(close:GetFrameLevel() > p.backdrop:GetFrameLevel(), client .. ': over the metal')

		st:RecolorThemed()
		eq(anchor(close, names), 'TOPRIGHT backdrop TOPRIGHT ' .. text(x, y), client .. ': a recolor leaves it in the socket')

		switch(st, 'thick')
		eq(close:GetNumPoints(), 1, client .. ', Thick again: one point')
		eq(anchor(close, names), home, client .. ', Thick again: back at the right of the header')
		eq(st:CloseButtonInSocket(p), false, client .. ', Thick again: out of the socket')

		switch(st, 'thin')
		eq(anchor(close, names), home, client .. ', Thin: at the right of the header')
		eq(st:CloseButtonInSocket(p), false, client .. ', Thin: out of the socket')

		-- A window made while the theme is Blizzard has it in the socket at once.
		switch(st, 'blizzard')
		local made = panel(st, 'Socket made')
		eq(st:CloseButtonInSocket(made), true, client .. ': a window made under Blizzard has it in the socket')
		eq(anchor(st:GetCloseButton(made), { [made.backdrop] = 'backdrop' }), 'TOPRIGHT backdrop TOPRIGHT ' .. text(x, y),
			client .. ': at the socket')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test("a close button made for a frame that isn't SaftUI's writes nothing onto it through a switch", function()
	local st = T.client('forever')
	local tooltip = CreateFrame('Frame', nil, UIParent) -- Blizzard's (an item tooltip)
	tooltip:SetSize(200, 100)
	tooltip:SetPoint('CENTER')
	locked(tooltip, 'Blizzard')
	local ok, err = pcall(st.CreateCloseButton, st, tooltip)
	check(ok, 'made without writing onto the frame: ' .. tostring(err))
	switch(st, 'blizzard')
	st:RecolorThemed()
	switch(st, 'thick')
	local errors = take_errors()
	eq(#errors, 0, 'nothing written through two switches and a recolor: ' .. tostring(errors[1]))
	eq(st:CloseButtonInSocket(tooltip), false, 'not a window: never in the socket')
end)

------------------------------------------------------------------ /sui and profiles

local OW

-- The world /sui is built in: Core's real Config/config.lua on a real
-- AceDB-3.0, with the options window. Forever.
local function configWorld()
	reset_world()
	load_test_file('core/config_helpers.lua')
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_saftui('SaftUI-Core/Config/optionswidgets.lua')
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_saftui('SaftUI-Core/Config/optionswindow.lua')
	OW = SaftUI.OptionsWindow
	return SaftUI
end

test("the /sui window's close button keeps its place under Blizzard", function()
	local st = configWorld()
	st.Config:Open()
	local window = OW.GetFrames().window
	local close = st:GetCloseButton(window)
	local names = { [window] = 'window' }
	local place = 'TOPRIGHT window TOPRIGHT -16.00,-14.00'
	eq(anchor(close, names), place, 'Thick: its place')

	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	close = st:GetCloseButton(window)
	eq(st:DrawnKind(window), 'panel', 'the /sui window is a panel, not a window')
	eq(close:GetNumPoints(), 1, 'Blizzard: one point')
	eq(anchor(close, names), place, 'Blizzard: its place kept')
	eq(st:CloseButtonInSocket(window), false, 'Blizzard: not in a socket')
	blizzardLook(close, 28, 'Blizzard')

	st.config.profile.theme.name = 'thick'
	st:ThemeChanged()
	eq(anchor(close, names), place, 'Thick again: its place')
	ownLook(st, close, 'Thick again')
	st.Config:Close()
	eq(#take_errors(), 0, 'no errors')
end)

test('a profile switch from a Blizzard profile to a Thick one', function()
	local st = configWorld()
	local thick = st.config:GetCurrentProfile()
	SaftUI_DB.profiles.WindowsTestBlizzard = { theme = { name = 'blizzard' } }
	st.config:SetProfile('WindowsTestBlizzard')

	-- Drawn in the Blizzard profile.
	local p = panel(st, 'Profile test')
	local tip = st:CreateFrame('Frame', nil, UIParent)
	tip:SetSize(100, 50)
	tip:SetPoint('CENTER')
	st:SetBackdrop(tip, 'theme', 'theme', 'tooltip')
	local close = st:GetCloseButton(p)
	eq(T.art(p.backdrop), METAL, 'Blizzard profile: the window wears the metal')
	eq(T.art(tip.backdrop), TOOLTIP, 'Blizzard profile: the tooltip its border')
	eq(p.header:GetHeight(), 31, 'Blizzard profile: the header is 31 tall')
	eq(p.header.backdropInfo, nil, 'Blizzard profile: no strip')
	eq(st:CloseButtonInSocket(p), true, "Blizzard profile: the close button in the metal's socket")
	blizzardLook(close, 28, 'Blizzard profile')

	st.config:SetProfile(thick)
	eq(T.art(p.backdrop), '', 'Thick profile: no art on the window')
	eq(T.art(tip.backdrop), '', 'Thick profile: none on the tooltip')
	eq(p.header:GetHeight(), 31, 'Thick profile: the header is 31 tall')
	eq(fill(p.header), THICK_STRIP, 'Thick profile: with its strip')
	eq(st:CloseButtonInSocket(p), false, 'Thick profile: out of the socket')
	eq(anchor(close, { [p.header] = 'header' }), 'RIGHT header RIGHT -10.00,0.00', 'Thick profile: back at the right of the header')
	ownLook(st, close, 'Thick profile')
	eq(#take_errors(), 0, 'no errors')
end)
