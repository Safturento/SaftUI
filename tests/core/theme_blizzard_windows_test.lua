-- Windows and close buttons under the Blizzard theme (SaftUI-Core/panels.lua,
-- with theme.lua and themeart.lua), on both clients:
--   - st:CreatePanel draws a window (the metal under Blizzard);
--   - under Blizzard a window's header sits in the metal's title bar
--     (st:HeaderInTitleBar): the title bar's strip, its bottom on the
--     window's top, with no strip of its own, the title centred on it and the
--     window's content starting right under it; its buttons are the strip
--     less 4 (st:HeaderButtonSize). Under Thick it's back at the window's top
--     at the profile's height, with its strip. A window made under Blizzard
--     has it there at once; Title bar height reaches the footer and, under
--     Thick, the header again. The rule is Core's: a window with no close
--     button follows it, and a window or SaftUI's theme in another look than
--     Blizzard keeps its header in the window;
--   - SaftUI's close button (st:CreateCloseButton) wears Blizzard's four
--     textures at the client's size under SaftUI's theme Blizzard, and its own
--     look again under Thick;
--   - on a window it sits in the metal's socket (st:CloseButtonInSocket), at
--     the client's spot from the window's drawn frame, and goes back to the
--     header under Thick; the /sui window, a window in no header, places its
--     own in the socket under Blizzard and back under Thick;
--   - a profile switch from a Blizzard profile to a Thick one (Review Focus 5)
--     takes the art off and gives the close button its own look, with no
--     reload; in combat, on a window whose frame, header and footer are
--     protected (as a bag window's are), the switch and Title bar height
--     touch none of them (stub.blocked) and the header moves when combat
--     ends;
--   - a close button made for a frame that isn't SaftUI's writes nothing onto
--     it through a switch.
--
-- Real: Core's helpers, theme.lua and themeart.lua (T.client, on Forever or
-- retail), and for the /sui window and the profile switch, Core's
-- Config/config.lua on a real AceDB-3.0 (core/config_helpers.lua) with the
-- options window. Each case starts from a fresh world.
local T = load_test_file('lib/theme_helpers.lua')
local locked = load_test_file('lib/locked_widget.lua')
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
local METAL = nine('UI-Frame-Metal')

-- The box's eight pieces as T.art lists them on Forever: each cut from the
-- minimap header button's file (8026705).
local BOX = table.concat({
	'BottomEdge=8026705', 'BottomLeftCorner=8026705', 'BottomRightCorner=8026705', 'LeftEdge=8026705',
	'RightEdge=8026705', 'TopEdge=8026705', 'TopLeftCorner=8026705', 'TopRightCorner=8026705',
}, ',')

-- Thick's header strip: its border color at 0.4.
local THICK_STRIP = '0.30,0.30,0.30,0.40'

-- A region's first anchor as text, 'POINT relative RELPOINT x,y', relative
-- named from names (region -> name).
local anchor = T.anchor

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

-- A region's rect on screen, 'left,top,right,bottom'.
local function rect(f) return text(f:GetLeft(), f:GetTop(), f:GetRight(), f:GetBottom()) end

-- A region's vertical centre on screen.
local function middle(f) return (f:GetTop() + f:GetBottom()) / 2 end

-- The title bar's strip a window's header sits in under Blizzard, as
-- themeart.lua gives it: 20 on both clients (Blizzard's TitleContainer).
local STRIP = 20

-- Checks a window's header sits in its metal's title bar: STRIP tall, its
-- bottom on the window's top and as wide as the window, inside the drawn
-- frame's top (on retail 1 below it, where Blizzard's TitleContainer starts;
-- on Forever at it), drawn over the metal, with no strip, and the title
-- centred on it.
local function inTitleBar(st, p, client, where)
	eq(st:HeaderInTitleBar(p), true, where .. ': the header is in the title bar')
	eq(p.header:GetHeight(), STRIP, where .. ": the title bar's strip tall")
	eq(T.around(p.header, p), ('0,%d,0,%d'):format(STRIP, p:GetHeight()),
		where .. ": its bottom on the window's top, as wide as the window")
	local rim = client == 'retail' and 1 or 0
	eq(text(p.backdrop:GetTop() - p.header:GetTop()), text(rim), where .. ": its top at the drawn frame's top, less retail's 1px rim")
	eq(text(st.ThemeArt.TitleHeight() - rim), text(STRIP), where .. ': so it fills the title bar below the rim')
	check(p.header:GetFrameLevel() > p.backdrop:GetFrameLevel(), where .. ': over the metal')
	eq(p.header.backdropInfo, nil, where .. ': no strip')
	eq(T.art(p.header), '', where .. ': no art on it')
	if p.title then
		eq(text(middle(p.title)), text(middle(p.header)), where .. ': the title centred on it')
	end
	eq(st:HeaderButtonSize(p), STRIP - 4, where .. ': its buttons the strip less 4')
end

-- Checks a window's header is back at the window's top at height, with
-- Thick's strip.
local function inWindow(st, p, height, where)
	eq(st:HeaderInTitleBar(p), false, where .. ': the header is in the window')
	eq(p.header:GetHeight(), height, where .. ": the profile's height")
	eq(T.around(p.header, p), ('0,0,0,%d'):format(p:GetHeight() - height), where .. ": at the window's top")
	eq(fill(p.header), THICK_STRIP, where .. ': with its strip')
	eq(st:HeaderButtonSize(p), height - 8, where .. ': its buttons its height less 8')
end

------------------------------------------------------------------ windows

test('st:CreatePanel draws a window', function()
	local st = T.client('forever')
	local drawn = T.watch()
	local p = panel(st, 'Window test')
	eq(drawn(p), 'theme,theme,window', 'panels.theme and panels.background, as a window')
	eq(st:DrawnKind(p), 'window', 'the engine records it as a window')
	T.theme('blizzard')
	eq(T.art(p.backdrop), METAL, 'under Blizzard it wears the metal')
end)

test("under Blizzard a window's header sits in the metal's title bar, with no strip; under Thick it goes back with its strip", function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st = T.client(client)
		local p = panel(st, 'Header test')
		st:CreateFooter(p)
		-- The window's content, as a window places it: under its header.
		local content = st:CreateFrame('Frame', nil, p)
		content:SetPoint('TOPLEFT', p.header, 'BOTTOMLEFT', 5, -5)
		content:SetPoint('BOTTOMRIGHT', p, 'BOTTOMRIGHT', -5, 5)
		local window, header, footer, inside = rect(p), rect(p.header), rect(p.footer), rect(content)

		local function thick(name)
			inWindow(st, p, 31, name)
			eq(rect(p.header), header, name .. ': the header where it was')
			eq(rect(content), inside, name .. ': the content under it, where it was')
			eq(text(p:GetTop() - content:GetTop()), '36.00', name .. ': 31 and 5 under the window top')
			eq(fill(p.footer), THICK_STRIP, name .. ': the footer strip')
		end

		thick(client .. ', Thick')
		T.theme('blizzard')
		local name = client .. ', Blizzard'
		eq(T.art(p.backdrop), METAL, name .. ': the window wears the metal')
		inTitleBar(st, p, client, name)
		eq(text(p:GetTop() - content:GetTop()), '5.00', name .. ": the content starts right under the title bar")
		eq(rect(p), window, name .. ': the window keeps its place and size')
		eq(rect(p.footer), footer, name .. ': the footer keeps its place and height')
		eq(p.footer.backdropInfo, nil, name .. ': no strip on the footer')
		st:RecolorThemed()
		inTitleBar(st, p, client, name .. ', after a recolor')
		st:RedrawThemed()
		inTitleBar(st, p, client, name .. ', after a redraw')

		T.theme('thick')
		thick(client .. ', Thick again')
		eq(T.art(p.backdrop), '', client .. ', Thick again: no art')
		eq(rect(p), window, client .. ', Thick again: the window where it was')

		T.theme('thin')
		eq(st:HeaderInTitleBar(p), false, client .. ', Thin: the header in the window')
		eq(rect(p.header), header, client .. ', Thin: where it was')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test('a window made under Blizzard has its header in the title bar at once', function()
	for _, client in ipairs({ 'forever', 'retail' }) do
		local st = T.client(client)
		T.theme('blizzard')
		local p = panel(st, 'Made under Blizzard')
		inTitleBar(st, p, client, client)
		T.theme('thick')
		inWindow(st, p, 31, client .. ', Thick')
		eq(#take_errors(), 0, client .. ': no errors')
	end
end)

test("Title bar height reaches the footer under Blizzard, where the header keeps the strip's height, and both again under Thick", function()
	local st = T.client('forever')
	local p = panel(st, 'Height test')
	st:CreateFooter(p)
	T.theme('blizzard')
	st.config.profile.headers.height = 40
	st:UpdateHeader() -- as General -> Title bar height does
	inTitleBar(st, p, 'forever', 'Blizzard, 40')
	eq(p.footer:GetHeight(), 40, 'Blizzard: the footer takes it')
	T.theme('thick')
	inWindow(st, p, 40, 'Thick, 40')
	eq(p.footer:GetHeight(), 40, 'Thick: the footer too')
	st.config.profile.headers.height = 31
	st:UpdateHeader()
	inWindow(st, p, 31, 'Thick, 31')
	eq(#take_errors(), 0, 'no errors')
end)

test("the rule is Core's: a window with no close button follows it, and a window not in the metal keeps its header", function()
	local st = T.client('retail')
	-- A window of SaftUI's with a header and no close button.
	local bare = st:CreateFrame('Frame', 'SaftUIBareWindow', UIParent)
	bare:SetSize(200, 100)
	bare:SetPoint('CENTER')
	st:SetBackdrop(bare, 'theme', 'theme', 'window')
	st:CreateHeader(bare, 'Bare')
	eq(st:GetCloseButton(bare), nil, 'it has no close button')
	inWindow(st, bare, 31, 'Thick')
	T.theme('blizzard')
	inTitleBar(st, bare, 'retail', 'Blizzard')

	-- A window drawn in a look of its own, as a module's Theme draws it, then
	-- its header updated (st:UpdateHeader), as the bags do after drawing it.
	st:SetBackdrop(bare, 'thick', 'theme', 'window')
	st:UpdateHeader(bare.header)
	eq(T.art(bare.backdrop), '', "its own Thick under SaftUI's Blizzard: no metal")
	eq(st:HeaderInTitleBar(bare), false, 'so the header goes back into the window')
	eq(T.around(bare.header, bare), '0,0,0,69', "at the window's top")
	eq(bare.header.backdropInfo, nil, "with SaftUI's theme's strip: none under Blizzard")

	-- Its own Blizzard under SaftUI's Thick: the metal, and the header and
	-- its strip stay with SaftUI's theme, in the window.
	T.theme('thick')
	st:SetBackdrop(bare, 'blizzard', 'theme', 'window')
	st:UpdateHeader(bare.header)
	eq(T.art(bare.backdrop), METAL, "its own Blizzard under SaftUI's Thick: the metal")
	inWindow(st, bare, 31, "its own Blizzard under SaftUI's Thick")

	-- Its own theme followed again, SaftUI's Blizzard: into the title bar.
	st:SetBackdrop(bare, 'theme', 'theme', 'window')
	T.theme('blizzard')
	inTitleBar(st, bare, 'retail', "SaftUI's Blizzard again")
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

		T.theme('blizzard')
		blizzardLook(close, size, client .. ', Blizzard')
		-- Its own hover look stays off: Blizzard's highlight shows the hover.
		stub.fire_script(close, 'OnEnter')
		eq(close.backdropInfo, nil, client .. ': hovered, its own backdrop stays off')
		check(not close.icon:IsShown(), client .. ': and its X hidden')
		stub.fire_script(close, 'OnLeave')
		st:RecolorThemed()
		blizzardLook(close, size, client .. ', after a recolor')

		T.theme('thick')
		ownLook(st, close, client .. ', Thick again')
		stub.fire_script(close, 'OnEnter')
		eq(T.edge(close), text(st.config.profile.colors.text.danger:GetRGB()) .. ',1.00', client .. ': hovered under Thick, its red border')
		stub.fire_script(close, 'OnLeave')
		eq(T.edge(close), text(unpack(st.BOX_COLORS.edge)), client .. ': and back')

		-- A close button made while the theme is Blizzard has Blizzard's look at once.
		T.theme('blizzard')
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

		T.theme('blizzard')
		eq(close:GetNumPoints(), 1, client .. ', Blizzard: one point')
		eq(anchor(close, names), 'TOPRIGHT backdrop TOPRIGHT ' .. text(x, y),
			client .. ", Blizzard: at TOPRIGHT of the window's drawn frame, in the metal's socket")
		eq(st:CloseButtonInSocket(p), true, client .. ', Blizzard: in the socket')
		check(close:GetFrameLevel() > p.backdrop:GetFrameLevel(), client .. ': over the metal')
		-- The header is in the title bar with it (st:HeaderInTitleBar): the
		-- button sits at its right end, over it, reaching st:SocketReach in.
		check(close:GetFrameLevel() > p.header:GetFrameLevel(), client .. ': over the header in the title bar')
		check(close:GetTop() >= p.header:GetTop() and close:GetRight() >= p.header:GetRight(),
			client .. ": at the title bar's right end")
		eq(st:SocketReach(p), client == 'forever' and 26 or 21, client .. ': 28 - 0 - 2 on Forever, 24 - 1 - 2 on retail')
		eq(text(p.header:GetRight() - close:GetLeft()), text(st:SocketReach(p)), client .. ": that far in from the header's right edge")

		st:RecolorThemed()
		eq(anchor(close, names), 'TOPRIGHT backdrop TOPRIGHT ' .. text(x, y), client .. ': a recolor leaves it in the socket')

		T.theme('thick')
		eq(close:GetNumPoints(), 1, client .. ', Thick again: one point')
		eq(anchor(close, names), home, client .. ', Thick again: back at the right of the header')
		eq(st:CloseButtonInSocket(p), false, client .. ', Thick again: out of the socket')

		T.theme('thin')
		eq(anchor(close, names), home, client .. ', Thin: at the right of the header')
		eq(st:CloseButtonInSocket(p), false, client .. ', Thin: out of the socket')

		-- A window made while the theme is Blizzard has it in the socket at once.
		T.theme('blizzard')
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
	T.theme('blizzard')
	st:RecolorThemed()
	T.theme('thick')
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
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	OW = SaftUI.OptionsWindow
	return SaftUI
end

test("the /sui window's close button sits in the metal's socket under Blizzard, and back under Thick", function()
	local st = configWorld()
	st.Config:Open()
	local window = OW.GetFrames().window
	local close = st:GetCloseButton(window)
	local names = { [window] = 'window' }
	local place = 'TOPRIGHT window TOPRIGHT -16.00,-14.00'
	eq(anchor(close, names), place, 'Thick: its place')
	-- The window lays itself out again on its next frame after a theme change.
	local tick = tick_options_window

	st.config.profile.theme.name = 'blizzard'
	st:ThemeChanged()
	tick()
	close = st:GetCloseButton(window)
	eq(st:DrawnKind(window), 'window', 'the /sui window is a window')
	eq(close:GetNumPoints(), 1, 'Blizzard: one point')
	eq(anchor(close, names), 'TOPRIGHT window TOPRIGHT 0.00,3.00', "Blizzard: in the metal's socket")
	blizzardLook(close, 28, 'Blizzard')

	st.config.profile.theme.name = 'thick'
	st:ThemeChanged()
	tick()
	eq(close:GetNumPoints(), 1, 'Thick again: one point')
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
	eq(T.art(tip.backdrop), BOX, 'Blizzard profile: the tooltip its box')
	inTitleBar(st, p, 'forever', 'Blizzard profile')
	eq(st:CloseButtonInSocket(p), true, "Blizzard profile: the close button in the metal's socket")
	blizzardLook(close, 28, 'Blizzard profile')

	st.config:SetProfile(thick)
	eq(T.art(p.backdrop), '', 'Thick profile: no art on the window')
	eq(T.art(tip.backdrop), '', 'Thick profile: none on the tooltip')
	inWindow(st, p, 31, 'Thick profile')
	eq(st:CloseButtonInSocket(p), false, 'Thick profile: out of the socket')
	eq(anchor(close, { [p.header] = 'header' }), 'RIGHT header RIGHT -10.00,0.00', 'Thick profile: back at the right of the header')
	ownLook(st, close, 'Thick profile')
	eq(#take_errors(), 0, 'no errors')
end)

-- The calls the game blocked (stub.blocked), as 'method,method'.
local function blocked()
	local out = {}
	for i, call in ipairs(stub.blocked) do out[i] = call[2] end
	return table.concat(out, ',')
end

-- A bag window is protected in combat: Blizzard's item buttons hang from its
-- scroll frame, which is anchored under its header, and the search box,
-- anchored to the header too, is its footer's child, so the window, its
-- header and its footer are all protected (.agents/taint.md, rule 6). A
-- profile switch in combat runs st:UpdateHeader at once (Config:UpdateConfig,
-- step 4), and so does Title bar height: neither may touch them until combat
-- ends, nor forget that the header has yet to move.
test("in combat a protected window's header and footer wait for the end of combat: a profile switch and Title bar height", function()
	local st = configWorld()
	local thick = st.config:GetCurrentProfile()
	SaftUI_DB.profiles.WindowsTestCombat = { theme = { name = 'blizzard' } }
	st.config:SetProfile('WindowsTestCombat')
	local p = panel(st, 'Combat test')
	st:CreateFooter(p)
	inTitleBar(st, p, 'forever', 'Blizzard profile')
	for _, frame in ipairs({ p, p.header, p.footer }) do
		function frame:IsProtected() return true, true end
	end
	local header = rect(p.header)

	stub.in_combat = true
	st.config:SetProfile(thick)
	eq(blocked(), '', 'a profile switch in combat: no call on the window blocked')
	eq(st:HeaderInTitleBar(p), true, 'the header still in the title bar, where it is')
	eq(rect(p.header), header, 'not moved')
	st.config.profile.headers.height = 40
	st:UpdateHeader() -- as General -> Title bar height does
	eq(blocked(), '', 'Title bar height in combat: none blocked')
	eq(p.footer:GetHeight(), 31, 'the footer waits too')

	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(blocked(), '', 'none blocked after combat')
	inWindow(st, p, 40, 'when combat ends, the Thick profile at 40')
	eq(p.footer:GetHeight(), 40, 'the footer takes 40')
	eq(st:CloseButtonInSocket(p), false, 'the close button out of the socket')
	eq(#take_errors(), 0, 'no errors')
end)
