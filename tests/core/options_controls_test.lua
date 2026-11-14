-- SaftUI-Core/Config/optionscontrols.lua: the kit's standalone controls
-- (W.Button, W.IconButton, W.IconLink, W.SelectFace, W.NumberBox), the nudge
-- pair they and the Position block share (Kit.NudgePair, Kit.LookNudges), and
-- what they share: W.SetOn, W.SetEnabled, W.SetCompact, W.LookControl and the
-- tooltip (W.ShowTip, W.HideTip).
--
-- Real: the model, the widget files and the theme. The mouse and the keyboard
-- are played by firing the frames' scripts (stub.fire_script, stub.click); the
-- game's second argument to OnEnter and OnLeave, motion, is passed as true.
-- The world and the helpers are options_widgets_helpers.lua's.
local H = load_test_file('core/options_widgets_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit
local click, theme, size_of, atlases_of = H.click, H.theme, H.size_of, H.atlases_of
local panel_of = H.panel_of

if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

local function colors() return st.config.profile.colors end
local function color_of(c) return string.format('%.2f,%.2f,%.2f', c:GetRGB()) end
local function rgb(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local BLUE = function() return color_of(colors().button.blue) end
local GREY = function() return color_of(colors().text.grey) end
local NORMAL = function() return color_of(colors().text.normal) end
local function vertex(texture) return rgb(texture:GetVertexColor()) end
local function edge_of(frame) return rgb(frame:GetBackdropBorderColor()) end
local function edge_rgb(c) return rgb(c[1], c[2], c[3]) end
local function new_parent()
	local f = CreateFrame('Frame', nil, UIParent)
	f:SetSize(400, 200)
	f:SetPoint('CENTER')
	return f
end

-- A control placed on screen (a frame with no anchor has no rect to measure).
local function put(control)
	control:SetPoint('CENTER', UIParent, 'CENTER', 0, 0)
	return control
end

local function tip(button) return 'Exit', { 'Leaves edit mode.', { text = 'Unsaved.', red = true } } end

-- Where the tooltip's lines and their colors go: AddLine records them.
local lines
local realAddLine = GameTooltip.AddLine
GameTooltip.AddLine = function(self, text, r, g, b, wrap)
	lines[#lines + 1] = { text = text, color = r and rgb(r, g, b) or nil }
	return realAddLine(self, text, r, g, b, wrap)
end
local function reset_lines() lines = {} end

test("W.Button is the window's button: 26 tall, 80 at least, the field font, an accent edge under the mouse", function()
	theme('thick')
	local b = put(W.Button(new_parent(), 'Reload UI', function() end))
	eq(b:GetHeight(), 26, '26 tall')
	eq(b:GetWidth(), math.max(80, math.ceil(b.text:GetStringWidth()) + 28), 'the text and 28, 80 at least')
	eq(b.text:GetText(), 'Reload UI', 'its label')
	eq(b.label, 'Reload UI', 'kept as button.label')
	check(not b.text:CanWordWrap(), 'word wrap off')
	check(b.backdropInfo ~= nil, 'a Box')
	eq(edge_of(b), edge_rgb(st.BOX_COLORS.edge), 'its edge at rest')
	stub.fire_script(b, 'OnEnter', true)
	eq(edge_of(b), BLUE(), 'accent under the mouse')
	stub.fire_script(b, 'OnLeave', true)
	eq(edge_of(b), edge_rgb(st.BOX_COLORS.edge), 'and the edge again once it leaves')
	local _, _, _, _, y = b.text:GetPoint(1)
	eq(y, 0, 'the label centred')
	stub.fire_script(b, 'OnMouseDown')
	_, _, _, _, y = b.text:GetPoint(1)
	eq(y, -1, 'the label 1 down while pressed')
	stub.fire_script(b, 'OnMouseUp')
	_, _, _, _, y = b.text:GetPoint(1)
	eq(y, 0, 'and back')
	local wide = W.Button(new_parent(), 'A rather long button label indeed', function() end)
	eq(wide:GetWidth(), math.ceil(wide.text:GetStringWidth()) + 28, 'a long label sets the width')
	local clicked = 0
	local c = W.Button(new_parent(), 'Go', function() clicked = clicked + 1 end)
	click(c)
	eq(clicked, 1, 'a click runs it')
	eq(#P.off(b), 0, 'on whole pixels: ' .. P.report(P.off(b)))
end)

test('W.IconButton: a 26 square with its 16 icon in the middle, grey; it needs its tooltip', function()
	theme('thick')
	local ok, err = pcall(W.IconButton, new_parent(), st.icons.magnet)
	check(not ok and tostring(err):find('W.IconButton needs its tooltip', 1, true), 'without a tooltip it errors')
	local host = new_parent()
	local b = put(W.IconButton(host, st.icons.magnet, tip))
	eq(size_of(b), '26x26', 'a 26 square')
	eq(size_of(b.icon), '16x16', 'a 16 icon')
	eq(b.icon:GetTexture(), st.icons.magnet, 'the given icon')
	local point, rel, relPoint = b.icon:GetPoint(1)
	check(point == 'CENTER' and rel == b and relPoint == 'CENTER', 'centred on the button')
	eq(H.insets(b.icon, b), '5,5,5,5', 'its edges at 5 and 21')
	eq(vertex(b.icon), GREY(), 'Text > Grey')
	eq(#P.off(b), 0, 'on whole pixels: ' .. P.report(P.off(b)))
	reset_lines()
	stub.fire_script(b, 'OnEnter', true)
	check(GameTooltip:IsOwned(b) and GameTooltip:IsShown(), 'a tooltip over it')
	eq(stub.state(GameTooltip).anchor, 'ANCHOR_BOTTOM', 'under it')
	eq(lines[1].text .. '|' .. lines[1].color, 'Exit|1.00,1.00,1.00', 'the title white')
	eq(lines[2].text .. '|' .. lines[2].color, 'Leaves edit mode.|' .. NORMAL(), 'a line in Text > Normal')
	eq(lines[3].text .. '|' .. lines[3].color, 'Unsaved.|' .. color_of(colors().text.red), 'a red line in Text > Red')
	eq(edge_of(b), BLUE(), 'accent under the mouse')
	stub.fire_script(b, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'gone when it leaves')
	local clicks = 0
	b.onClick = function() clicks = clicks + 1 end
	click(b)
	eq(clicks, 1, 'a click runs button.onClick')
end)

test('W.IconButton takes a size and an icon size: the close X\'s 24 with a 20 icon, the icon 1 lower while pressed', function()
	theme('thick')
	local b = put(W.IconButton(new_parent(), st.icons.chevronRight, tip, 24, 20))
	eq(size_of(b), '24x24', 'the size given')
	eq(size_of(b.icon), '20x20', 'the icon size given')
	eq(H.insets(b.icon, b), '2,2,2,2', 'centred, an even margin of 2')
	eq(#P.off(b), 0, 'on whole pixels: ' .. P.report(P.off(b)))
	local default = put(W.IconButton(new_parent(), st.icons.eye, tip, nil, nil))
	eq(size_of(default) .. ' ' .. size_of(default.icon), '26x26 16x16', 'nil sizes: the defaults')
	-- A press moves the icon, never the size.
	for _, button in ipairs({ b, default }) do
		local before = H.insets(button.icon, button)
		local width, height = button:GetWidth(), button:GetHeight()
		stub.fire_script(button, 'OnMouseDown')
		local top = button:GetTop() - button.icon:GetTop()
		local was = tonumber(before:match('^%d+,(%d+)'))
		eq(top, was + 1, 'the icon 1 lower while pressed')
		eq(size_of(button), width .. 'x' .. height, 'the size never changes')
		eq(#P.off(button), 0, 'whole while pressed')
		stub.fire_script(button, 'OnMouseUp')
		eq(H.insets(button.icon, button), before, 'back when let go')
	end
	-- A disabled button does not move its icon.
	W.SetEnabled(b, false)
	stub.fire_script(b, 'OnMouseDown')
	eq(H.insets(b.icon, b), '2,2,2,2', 'disabled: it does not press')
	stub.fire_script(b, 'OnMouseUp')
	-- The margin must be whole.
	local ok, err = pcall(W.IconButton, new_parent(), st.icons.eye, tip, 25, 16)
	check(not ok and tostring(err):find('whole', 1, true), 'an odd margin is refused: ' .. tostring(err))
	ok, err = pcall(W.IconButton, new_parent(), st.icons.eye, tip, 24, 'big')
	check(not ok, 'a size that is no number is refused')
	ok, err = pcall(W.IconButton, new_parent(), st.icons.eye, tip, 24, function() end)
	check(not ok and tostring(err):find('takes no click', 1, true), 'a function where a click used to go is still refused')
end)

test('W.IconLink: an icon with no box on a square that takes the mouse, grey and then accent; it needs its tooltip', function()
	theme('thick')
	local ok, err = pcall(W.IconLink, new_parent(), st.icons.search, 14)
	check(not ok and tostring(err):find('W.IconLink needs its tooltip', 1, true), 'without a tooltip it errors')
	local link = put(W.IconLink(new_parent(), st.icons.search, 14, tip))
	eq(size_of(link), '14x14', 'size square')
	check(link:IsMouseEnabled(), 'takes the mouse')
	eq(link.backdropInfo, nil, 'no box')
	eq(link.icon:GetTexture(), st.icons.search, 'the icon')
	eq(vertex(link.icon), GREY(), 'grey at rest')
	reset_lines()
	stub.fire_script(link, 'OnEnter', true)
	eq(vertex(link.icon), BLUE(), 'accent under the mouse')
	check(GameTooltip:IsOwned(link), 'and its tip')
	stub.fire_script(link, 'OnLeave', true)
	eq(vertex(link.icon), GREY(), 'grey again')
	W.SetEnabled(link, false)
	stub.fire_script(link, 'OnEnter', true)
	eq(vertex(link.icon), GREY(), 'disabled: stays grey')
	check(GameTooltip:IsOwned(link), 'but still shows its tip')
	stub.fire_script(link, 'OnLeave', true)
	W.LookControl(link, true)
	eq(link.backdropInfo, nil, 'no box under Blizzard either')
	W.HideTip(link)
	eq(#P.off(link), 0, 'on whole pixels')
end)

test('W.SetOn: an accent edge that stays after the mouse leaves and an accent icon; under Blizzard the icon (or label) alone', function()
	theme('thick')
	local b = W.IconButton(new_parent(), st.icons.eye, tip)
	W.SetOn(b, true)
	eq(b.on, true, 'button.on')
	eq(edge_of(b), BLUE(), 'on: the accent edge')
	eq(vertex(b.icon), BLUE(), 'and the accent icon')
	stub.fire_script(b, 'OnEnter', true)
	stub.fire_script(b, 'OnLeave', true)
	eq(edge_of(b), BLUE(), 'kept when the mouse leaves')
	W.SetOn(b, false)
	eq(edge_of(b), edge_rgb(st.BOX_COLORS.edge), 'off: the edge')
	eq(vertex(b.icon), GREY(), 'and the grey icon')

	theme('blizzard')
	W.LookControl(b, true)
	eq(panel_of(b), 'Left=Up,Middle=Up,Right=Up', "Blizzard's panel button")
	eq(b.backdropInfo, nil, 'no box under it')
	eq(vertex(b.icon), GREY(), 'off: grey')
	W.SetOn(b, true)
	eq(vertex(b.icon), BLUE(), 'on: the icon in accent')
	check(b.icon:GetDrawLayer() == 'OVERLAY', 'the icon over the panel art')
	local t = W.Button(new_parent(), 'Edit mode', function() end)
	W.LookControl(t, true)
	W.SetOn(t, true)
	eq(color_of(CreateColor(t.text:GetTextColor())), BLUE(), 'a text button on: its label in accent')
	W.SetOn(t, false)
	eq(color_of(CreateColor(t.text:GetTextColor())), NORMAL(), 'off: its label back')

	theme('thick')
	W.LookControl(b, false)
	W.LookControl(t, false)
	eq(edge_of(b), BLUE(), 'back under Thick: still on, the edge lit again')
	eq(panel_of(b), '', 'no panel button')
	eq(color_of(CreateColor(t.text:GetTextColor())), NORMAL(), 'a text button under Thick keeps its label, on or off')
	W.SetOn(b, false)
	eq(edge_of(b), edge_rgb(st.BOX_COLORS.edge), 'off again')
end)

test('W.SetEnabled: a disabled control at 0.4 runs no click and still shows its tooltip', function()
	theme('thick')
	local clicked = 0
	local b = W.Button(new_parent(), 'Exit', function() clicked = clicked + 1 end, { icon = st.icons.logOut, tip = tip })
	W.SetEnabled(b, false)
	eq(b.disabled, true, 'button.disabled')
	eq(b:GetAlpha(), 0.4, 'at 0.4')
	click(b)
	eq(clicked, 0, 'a click runs nothing')
	reset_lines()
	stub.fire_script(b, 'OnEnter', true)
	check(GameTooltip:IsOwned(b) and GameTooltip:IsShown(), 'its tooltip shows')
	eq(edge_of(b), edge_rgb(st.BOX_COLORS.edge), 'no accent edge')
	stub.fire_script(b, 'OnLeave', true)
	W.SetEnabled(b, true)
	eq(b.disabled, false, 'enabled again')
	eq(b:GetAlpha(), 1, 'at full alpha')
	click(b)
	eq(clicked, 1, 'a click runs')
	stub.fire_script(b, 'OnEnter', true)
	eq(edge_of(b), BLUE(), 'and the edge lights')
	stub.fire_script(b, 'OnLeave', true)

	local on = W.IconButton(new_parent(), st.icons.eye, tip)
	W.SetOn(on, true)
	W.SetEnabled(on, false)
	eq(on:GetAlpha(), 0.4, 'on and disabled: dimmed')
	eq(on.on, true, 'on still')

	theme('blizzard')
	W.LookControl(b, true)
	eq(b:GetAlpha(), 1, 'Blizzard: enabled, full alpha')
	W.SetEnabled(b, false)
	W.LookControl(b, true)
	eq(b:GetAlpha(), 0.4, 'Blizzard: disabled keeps its 0.4')
	theme('thick')
	W.LookControl(b, false)
	eq(b:GetAlpha(), 0.4, 'and back under Thick')
end)

test('W.SetCompact: a button with an icon drops its label for a 26 square', function()
	theme('thick')
	local b = put(W.Button(new_parent(), 'Exit', function() end, { icon = st.icons.logOut, iconWithLabel = true, tip = tip }))
	local width = math.max(80, 16 + 6 + math.ceil(b.text:GetStringWidth()) + 28)
	eq(b:GetWidth(), width, 'the icon, 6, the label and 28, 80 at least')
	check(b:GetWidth() >= 80, 'at least 80')
	eq(size_of(b.icon), '16x16', 'a 16 icon')
	check(b.icon:IsShown() and b.text:IsShown(), 'both shown')
	check(b.icon:GetRight() <= b.text:GetLeft() + 0.001 and b.text:GetLeft() - b.icon:GetRight() >= 5.999, 'the icon before the label')
	eq(math.floor(b.text:GetLeft() - b.icon:GetRight() + 0.5), 6, '6 apart')
	local pairLeft, pairRight = b.icon:GetLeft() - b:GetLeft(), b:GetRight() - (b.icon:GetLeft() + 16 + 6 + math.ceil(b.text:GetStringWidth()))
	check(math.abs(pairLeft - pairRight) <= 1, 'the pair centred')
	eq(#P.off(b), 0, 'on whole pixels: ' .. P.report(P.off(b)))

	eq(W.SetCompact(b, true), 26, 'compact: 26')
	eq(size_of(b), '26x26', 'a 26 square')
	check(not b.text:IsShown(), 'the label hidden')
	check(b.icon:IsShown(), 'the icon shown')
	eq(H.insets(b.icon, b), '5,5,5,5', 'in the middle')
	eq(#P.off(b), 0, 'compact on whole pixels')
	eq(W.SetCompact(b, false), width, 'not compact: its width again')
	check(b.text:IsShown(), 'the label back')

	local plain = W.Button(new_parent(), 'Reload UI', function() end, { icon = st.icons.logOut, tip = tip })
	eq(plain:GetWidth(), math.max(80, math.ceil(plain.text:GetStringWidth()) + 28), 'iconWithLabel false: just the label')
	check(not plain.icon:IsShown(), 'its icon is for compact only')
	eq(W.SetCompact(plain, true), 26, 'compact shows the icon alone')
	check(plain.icon:IsShown() and not plain.text:IsShown(), 'icon, no label')

	local noIcon = W.Button(new_parent(), 'Close', function() end)
	local w0 = noIcon:GetWidth()
	eq(W.SetCompact(noIcon, true), w0, 'a button with no icon is unchanged')
	local noTip = W.Button(new_parent(), 'Exit', function() end, { icon = st.icons.logOut })
	local ok, err = pcall(W.SetCompact, noTip, true)
	check(not ok and tostring(err):find('tooltip', 1, true), 'compact without a tooltip errors')
end)

test('W.ShowTip and W.HideTip: the owner, the anchor, a white title and Text > Normal or Red lines', function()
	local owner = W.IconButton(new_parent(), st.icons.eye, tip)
	reset_lines()
	W.ShowTip(owner, 'Title', { 'one', { text = 'two', red = true } }, 'ANCHOR_RIGHT')
	check(GameTooltip:IsOwned(owner) and GameTooltip:IsShown(), 'owned and shown')
	eq(stub.state(GameTooltip).anchor, 'ANCHOR_RIGHT', 'the anchor given')
	eq(#lines, 3, 'a title and two lines')
	W.HideTip(owner)
	check(not GameTooltip:IsShown(), 'hidden')
	local other = new_parent()
	W.ShowTip(owner, 'Title')
	W.HideTip(other)
	check(GameTooltip:IsShown(), 'only its owner hides it')
	W.HideTip(owner)
end)

test('W.NumberBox: typed whole numbers clamped, Esc and focus loss put the old one back, the arrows step', function()
	theme('thick')
	local value = 32
	local box = put(W.NumberBox(new_parent(), { width = 54, min = 8, max = 128, step = 4,
		get = function() return value end, set = function(v) value = v end, tip = function() return 'Grid size', { 'The grid.' } end }))
	eq(box:GetWidth(), 54, '54 wide, the pair inside it')
	eq(size_of(box.edit), '41x22', 'the edit box is width - 13 by 22')
	eq(size_of(box.pair), '14x22', 'the pair 14 by 22')
	local _, rel, relPoint, x, y = box.pair:GetPoint(1)
	check(rel == box.edit and relPoint == 'TOPRIGHT' and x == -1 and y == 0, "overlapping the edit box's right edge by 1")
	eq(box.edit:GetText(), '32', 'it shows get()')
	eq(box.edit:GetJustifyH(), 'CENTER', 'centred text')
	box.edit:SetText('30.6'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 31, 'a whole number')
	eq(box.edit:GetText(), '31', 'shown')
	box.edit:SetText('500'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 128, 'clamped to max')
	box.edit:SetText('1'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 8, 'and to min')
	box.edit:SetText('128'); stub.fire_script(box.edit, 'OnEnterPressed')
	box.edit:SetText('abc'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 128, 'not a number: unchanged')
	eq(box.edit:GetText(), '128', 'and shown again')
	box.edit:SetText('9'); stub.fire_script(box.edit, 'OnEscapePressed')
	eq(value, 128, 'Esc: unchanged')
	eq(box.edit:GetText(), '128', 'and the old one back')
	box.edit:SetText('9'); stub.fire_script(box.edit, 'OnEditFocusLost')
	eq(box.edit:GetText(), '128', 'losing focus puts it back')
	box.edit:SetText('  64 '); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 64, 'spaces around a number are fine')

	click(box.pair.down)
	eq(value, 60, 'down steps by 4')
	click(box.pair.up); click(box.pair.up)
	eq(value, 68, 'up steps by 4')
	value = 126
	click(box.pair.up)
	eq(value, 128, 'the arrows clamp')
	box:Refresh()
	eq(box.edit:GetText(), '128', 'Refresh shows get()')

	-- Hover: the edit box's edge and the tip.
	reset_lines()
	stub.fire_script(box.edit, 'OnEnter', true)
	check(GameTooltip:IsOwned(box) or GameTooltip:IsOwned(box.edit), 'its tip shows')
	eq(edge_of(box.edit), BLUE(), 'accent edge under the mouse')
	stub.fire_script(box.edit, 'OnLeave', true)
	eq(edge_of(box.edit), edge_rgb(st.BOX_COLORS.edge), 'and gone')
	check(not GameTooltip:IsShown(), 'the tip too')

	-- Disabled: the arrows change nothing, the edit box takes no focus.
	value = 64
	W.SetEnabled(box, false)
	eq(box.disabled, true, 'box.disabled')
	eq(box:GetAlpha(), 0.4, 'dimmed')
	click(box.pair.up)
	eq(value, 64, 'a click on up changes nothing')
	box.edit:SetFocus()
	check(not box.edit:HasFocus(), 'the edit box takes no focus')
	box.edit:SetText('99'); stub.fire_script(box.edit, 'OnEnterPressed')
	eq(value, 64, 'and no text')
	stub.fire_script(box.pair.up, 'OnEnter', true)
	check(GameTooltip:IsShown(), 'the tip shows on an arrow')
	stub.fire_script(box.pair.up, 'OnLeave', true)
	W.SetEnabled(box, true)
	click(box.pair.up)
	eq(value, 68, 'enabled again')
	eq(#P.off(box), 0, 'on whole pixels: ' .. P.report(P.off(box)))
end)

test('W.LookNumberBox: Box or the input art, and the steppers', function()
	theme('thick')
	local value = 5
	local box = W.NumberBox(new_parent(), { width = 54, min = 0, max = 9, get = function() return value end,
		set = function(v) value = v end, tip = function() return 'N', {} end })
	W.LookNumberBox(box, false)
	H.check_box(box.edit, 'Thick: the edit box', nil, true)
	eq(atlases_of(box.pair.up), '', 'no art on the steppers')
	W.LookNumberBox(box, true)
	eq(atlases_of(box.edit), H.INPUT_ART, "Blizzard's input art")
	eq(atlases_of(box.pair.up), 'minimal-scrollbar-arrow-top', "Blizzard's up stepper")
	eq(atlases_of(box.pair.down), 'minimal-scrollbar-arrow-bottom', 'and the down one')
	click(box.pair.up)
	eq(value, 6, 'a stepper steps')
	W.LookNumberBox(box, false)
	eq(atlases_of(box.edit), '', 'Thick again')
	check(box.pair.up.arrow:IsShown(), 'the chevron back')
	theme('thick')
end)

test('the nudge pair draws Lucide chevrons, on whole pixels, and Blizzard steppers under Blizzard', function()
	theme('thick')
	local owner = { disabled = false, tips = {} }
	function owner:Tip(on) self.tips[#self.tips + 1] = on end
	local ups, downs = 0, 0
	local host = new_parent()
	local pair, up, down = Kit.NudgePair(owner, host, function() ups = ups + 1 end, function() downs = downs + 1 end)
	put(pair)
	eq(size_of(pair), '14x22', 'a 14 by 22 pair')
	eq(size_of(up), '14x11', 'the up half')
	eq(size_of(down), '14x11', 'the down half')
	check(pair.up == up and pair.down == down, 'pair.up and pair.down')
	eq(up.arrow:GetTexture(), st.icons.chevronUp, 'up: the up chevron')
	eq(down.arrow:GetTexture(), st.icons.chevronDown, 'down: the down chevron')
	eq(size_of(up.arrow), '12x12', 'up: 12 by 12')
	eq(size_of(down.arrow), '12x12', 'down: 12 by 12')
	check(up.arrows == nil, 'the three rows are gone')
	eq(H.insets(up.arrow, up), '1,-1,1,0', 'up: a whole pixel in, 1 above its half, its middle 5 down it')
	eq(H.insets(down.arrow, down), '1,-1,1,0', 'down: the same')
	local top = pair:GetTop()
	local divider = (top - pair.divider:GetTop() + top - pair.divider:GetBottom()) / 2
	local upMid = top - (up.arrow:GetTop() + up.arrow:GetBottom()) / 2
	local downMid = top - (down.arrow:GetTop() + down.arrow:GetBottom()) / 2
	eq(divider - upMid, downMid - divider, 'the chevrons as far from the divider as each other')
	eq(vertex(up.arrow), GREY(), 'Text > Grey')
	eq(#P.off(pair), 0, 'on whole pixels: ' .. P.report(P.off(pair)))
	stub.fire_script(up, 'OnEnter', true)
	eq(vertex(up.arrow), NORMAL(), 'Text > Normal under the mouse')
	eq(owner.tips[#owner.tips], true, 'the owner shows its tip')
	stub.fire_script(up, 'OnLeave', true)
	eq(vertex(up.arrow), GREY(), 'grey again')
	eq(owner.tips[#owner.tips], false, 'and hides it')
	click(up); click(down); click(down)
	eq(ups .. downs, '12', 'each half runs its own')
	owner.disabled = true
	click(up)
	eq(ups, 1, 'disabled: nothing')
	stub.fire_script(up, 'OnEnter', true)
	eq(vertex(up.arrow), GREY(), 'disabled: stays grey under the mouse')
	stub.fire_script(up, 'OnLeave', true)
	owner.disabled = false

	theme('blizzard')
	Kit.LookNudges({ pair }, true)
	eq(atlases_of(up), 'minimal-scrollbar-arrow-top', 'Blizzard: the top arrow on up')
	eq(atlases_of(down), 'minimal-scrollbar-arrow-bottom', 'the bottom arrow on down')
	check(not up.arrow:IsShown() and not down.arrow:IsShown(), 'the chevrons hidden')
	check(pair.divider and not pair.divider:IsShown(), 'and the divider')
	theme('thick')
	Kit.LookNudges({ pair }, false)
	eq(atlases_of(up), '', 'Thick again: no art')
	check(up.arrow:IsShown() and down.arrow:IsShown(), 'the chevrons back')
	check(pair.divider:IsShown(), 'and the divider')
end)

test('W.SelectFace: the dropdown face with its caret; under Blizzard the Settings dropdown', function()
	theme('thick')
	local picked = 0
	local face = put(W.SelectFace(new_parent(), 150, function() picked = picked + 1 end))
	eq(size_of(face), '150x24', '150 wide, 24 tall')
	check(face.backdropInfo ~= nil, 'a Box')
	check(face.caret[1]:GetTexture() == st.icons.chevronDown, "Kit.Caret's chevron")
	face.text:SetText('Layout')
	local _, _, _, lx = face.text:GetPoint(1)
	eq(lx, 8, 'the text 8 in')
	local _, _, _, rx = face.text:GetPoint(2)
	eq(rx, -22, 'and 22 from the right')
	click(face)
	eq(picked, 1, 'a click runs onClick')
	stub.fire_script(face, 'OnEnter', true)
	eq(edge_of(face), BLUE(), 'accent under the mouse')
	stub.fire_script(face, 'OnLeave', true)
	W.SetEnabled(face, false)
	click(face)
	eq(picked, 1, 'disabled: no click')
	W.SetEnabled(face, true)

	-- Hiding it closes a list it owns.
	W.OpenList(face, { { key = 'a', label = 'A' } }, 'a', function() end)
	eq(W.ListOwner(), face, 'its list is open')
	face:Hide()
	eq(W.ListOwner(), nil, 'hiding it closes it')
	face:Show()

	theme('blizzard')
	W.LookSelectFace(face, true)
	eq(atlases_of(face), 'common-dropdown-c-button', "Blizzard's dropdown face")
	check(not face.caret[1]:IsShown(), 'no caret')
	theme('thick')
	W.LookSelectFace(face, false)
	check(face.caret[1]:IsShown(), 'the caret back')
	eq(#P.off(face), 0, 'on whole pixels: ' .. P.report(P.off(face)))
end)

test('W.LookControl: a button is Box or the panel button, with its on and disabled put on again', function()
	theme('thick')
	local b = put(W.Button(new_parent(), 'Exit', function() end))
	local check_box = H.check_box
	check_box(b, 'Thick: the button', H.BG_RGBA, true)
	theme('blizzard')
	W.LookControl(b, true)
	eq(panel_of(b), 'Left=Up,Middle=Up,Right=Up', "Blizzard's panel button")
	H.check_no_box(b, 'Blizzard: the button')
	theme('thick')
	W.LookControl(b, false)
	eq(panel_of(b), '', 'no panel button')
	check_box(b, 'Thick again: the button', H.BG_RGBA, true)
	eq(#P.off(b), 0, 'on whole pixels')
end)

test('a press moves the label only: the button keeps its size; a disabled one does not even move it', function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		theme(look)
		local b = put(W.Button(new_parent(), 'Edit mode', function() end))
		W.LookControl(b, look == 'blizzard')
		b:SetSize(88, 24) -- as the sidebar sizes its buttons
		stub.fire_script(b, 'OnMouseDown', 'LeftButton')
		eq(size_of(b), '88x24', look .. ': the size while pressed')
		local _, _, _, _, y = b.text:GetPoint(1)
		eq(y, -1, look .. ': the label 1 down')
		stub.fire_script(b, 'OnMouseUp', 'LeftButton')
		eq(size_of(b), '88x24', look .. ': the size once let go')
		_, _, _, _, y = b.text:GetPoint(1)
		eq(y, 0, look .. ': the label back')
		W.SetEnabled(b, false)
		stub.fire_script(b, 'OnMouseDown', 'LeftButton')
		_, _, _, _, y = b.text:GetPoint(1)
		eq(y, 0, look .. ': disabled: the label stays put')
		stub.fire_script(b, 'OnMouseUp', 'LeftButton')
	end
	theme('thick')
end)

test('a press moves the label 1 down in the icon-with-label layout too, the icon staying', function()
	theme('thick')
	local b = put(W.Button(new_parent(), 'Exit', function() end, { icon = st.icons.logOut, iconWithLabel = true, tip = tip }))
	local left = b.icon:GetLeft()
	local function label_y() local _, rel, _, _, y = b.text:GetPoint(1); check(rel == b.icon, 'anchored to the icon'); return y end
	eq(label_y(), 0, 'at rest')
	stub.fire_script(b, 'OnMouseDown', 'LeftButton')
	eq(label_y(), -1, 'pressed: 1 down')
	eq(b.icon:GetLeft(), left, 'the icon stays')
	eq(size_of(b), math.max(80, 16 + 6 + math.ceil(b.text:GetStringWidth()) + 28) .. 'x26', 'and the size')
	stub.fire_script(b, 'OnMouseUp', 'LeftButton')
	eq(label_y(), 0, 'let go: back')
end)

test("a label keeps the colour its caller gave it through hover, and one with none follows the font object", function()
	for _, look in ipairs({ 'thick', 'blizzard' }) do
		theme(look)
		local blizzard = look == 'blizzard'
		local green = st.config.profile.colors.text.green
		local b = put(W.Button(new_parent(), 'Edit mode', function() end))
		W.LookControl(b, blizzard)
		b.text:SetTextColor(green:GetRGB())
		stub.fire_script(b, 'OnEnter', true)
		stub.fire_script(b, 'OnLeave', true)
		eq(color_of(CreateColor(b.text:GetTextColor())), color_of(green), look .. ': the caller\'s colour survives a hover')
		b:Hide(); b:Show()
		eq(color_of(CreateColor(b.text:GetTextColor())), color_of(green), look .. ': and a hide')
		-- Lit under Blizzard, then put back as it was.
		W.SetOn(b, true)
		eq(color_of(CreateColor(b.text:GetTextColor())), blizzard and BLUE() or color_of(green), look .. ': on')
		W.SetOn(b, false)
		eq(color_of(CreateColor(b.text:GetTextColor())), color_of(green), look .. ': off: the caller\'s colour again')

		local plain = put(W.Button(new_parent(), 'Close', function() end))
		W.LookControl(plain, blizzard)
		stub.fire_script(plain, 'OnEnter', true)
		stub.fire_script(plain, 'OnLeave', true)
		local font = W.GetFont()
		local r, g, bl, a = font:GetTextColor()
		font:SetTextColor(0.1, 0.2, 0.3)
		eq(color_of(CreateColor(plain.text:GetTextColor())), '0.10,0.20,0.30', look .. ': no colour of its own: it follows the font object')
		font:SetTextColor(r, g, bl, a)
	end
	theme('thick')
end)

test('W.SetOn under Blizzard lights a button whose icon is for compact only, by its label', function()
	theme('blizzard')
	local b = put(W.Button(new_parent(), 'Options', function() end, { icon = st.icons.settings, tip = tip }))
	W.LookControl(b, true)
	W.SetOn(b, true)
	eq(color_of(CreateColor(b.text:GetTextColor())), BLUE(), 'not compact: its label is lit')
	W.SetCompact(b, true)
	W.SetOn(b, true)
	eq(color_of(CreateColor(b.text:GetTextColor())), color_of(colors().text.normal), 'compact: the icon shows it, the label is put back')
	eq(vertex(b.icon), BLUE(), 'the icon lit')
	theme('thick')
end)

test('W.SetEnabled paints a Blizzard dropdown face disabled at once', function()
	theme('blizzard')
	local face = put(W.SelectFace(new_parent(), 150, function() end))
	W.LookSelectFace(face, true)
	eq(atlases_of(face), 'common-dropdown-c-button', 'enabled')
	W.SetEnabled(face, false)
	eq(atlases_of(face), 'common-dropdown-c-button-disabled', 'disabled, before the mouse passes')
	theme('thick')
end)

test('W.IconButton and W.IconLink refuse a click in place of the tooltip', function()
	local ok, err = pcall(W.IconButton, new_parent(), st.icons.eye, function() end, tip)
	check(not ok and tostring(err):find('takes no click', 1, true), 'an extra argument is refused')
	ok, err = pcall(W.IconLink, new_parent(), st.icons.eye, 14, 'a tip')
	check(not ok and tostring(err):find('takes no click', 1, true), 'a tip that is no function is refused')
end)

test('a number box that has focus drops it when disabled', function()
	local box = put(W.NumberBox(new_parent(), { width = 54, get = function() return 1 end, set = function() end,
		tip = function() return 'N', {} end }))
	box.edit:SetFocus()
	check(box.edit:HasFocus(), 'it has focus')
	W.SetEnabled(box, false)
	check(not box.edit:HasFocus(), 'and drops it when disabled')
end)

-- Every control on whole pixels under Thick, Thin and Blizzard, with sizes read
-- back a hair off, unpressed and pressed (the repo's convention for a layout).
test('every control is on whole pixels, under each look and with sizes read back a hair off', function()
	local HAIR = 2 ^ -14
	for _, look in ipairs({ 'thick', 'thin', 'blizzard' }) do
		for _, noise in ipairs({ 0, HAIR, -HAIR }) do
			stub.size_noise = noise
			theme(look)
			local blizzard = look == 'blizzard'
			local where = look .. ' noise ' .. noise .. ': '
			local p = CreateFrame('Frame', nil, UIParent)
			p:SetSize(400, 400)
			p:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 10, -10)
			local controls = {
				button = W.Button(p, 'Reload UI', function() end),
				long = W.Button(p, 'A rather long button label indeedy', function() end),
				withIcon = W.Button(p, 'Exit', function() end, { icon = st.icons.logOut, iconWithLabel = true, tip = tip }),
				withIconLong = W.Button(p, 'Options and more', function() end, { icon = st.icons.settings, iconWithLabel = true, tip = tip }),
				compact = W.Button(p, 'Options', function() end, { icon = st.icons.settings, tip = tip }),
				iconButton = W.IconButton(p, st.icons.magnet, tip),
				link = W.IconLink(p, st.icons.rotateCcw, 14, tip),
				face = W.SelectFace(p, 150, function() end),
				box = W.NumberBox(p, { width = 54, min = 8, max = 128, step = 4, get = function() return 32 end, set = function() end, tip = tip }),
			}
			W.SetCompact(controls.compact, true)
			local y = 0
			for _, name in ipairs({ 'button', 'long', 'withIcon', 'withIconLong', 'compact', 'iconButton', 'link', 'face', 'box' }) do
				local c = controls[name]
				if name == 'face' then W.LookSelectFace(c, blizzard)
				elseif name == 'box' then W.LookNumberBox(c, blizzard)
				else W.LookControl(c, blizzard) end
				c:ClearAllPoints()
				c:SetPoint('TOPLEFT', p, 'TOPLEFT', 0, -y)
				y = y + 30
				local off = P.off(c)
				eq(#off, 0, where .. name .. ': ' .. P.report(off))
				stub.fire_script(c, 'OnMouseDown', 'LeftButton')
				off = P.off(c)
				eq(#off, 0, where .. name .. ' pressed: ' .. P.report(off))
				stub.fire_script(c, 'OnMouseUp', 'LeftButton')
			end
			p:Hide()
		end
	end
	stub.size_noise = 0
	theme('thick')
end)
