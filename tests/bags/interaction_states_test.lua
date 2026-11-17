-- The bags' interaction states (the states plan's Task 5): the windows' header
-- buttons and view switch, item and bank slots, the bag bar's slots, the
-- Categories list, the rule editor's NOT box, links and Caught now tint, the
-- category filter check and the bare checks, each drawn by the states helper
-- (SaftUI-Core/Widgets/states.lua) and nothing hand-rolled.
--
-- Real: bags/categories_world.lua's world (the views world with Core's config,
-- the options window and SaftUI-Bags' options, ruleeditor and categories tab),
-- and containers/bag.lua, bank.lua and combinedbank.lua.
local CW = load_test_file('bags/categories_world.lua')
local H = load_test_file('bags/container_helpers.lua')
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
local SL = load_test_file('lib/states_look.lua')

local st, INV, B, OW, W
local VIEWS = { 'onebag', 'multibag', 'compact', 'rows' }

local function world(client)
	local container
	container, st, INV, B, OW, _, W = CW.world(client)
	load_string_format()
	_G.BankFrame = { BankPanel = { SetBankType = function() end } }
	Enum.BankType = { Character = 0, Account = 2 }
	string.trim = string.trim or function(s) return (s:gsub('^%s+', ''):gsub('%s+$', '')) end
	for _, file in ipairs({ 'containers/bag.lua', 'containers/combinedbank.lua', 'containers/bank.lua' }) do
		load_saftui('SaftUI-Bags/' .. file)
	end
	return container
end

local function slots_of(container)
	local out = {}
	for _, category in pairs(container.categories) do
		for _, slot in pairs(category.slots) do
			if slot:IsShown() then out[#out + 1] = slot end
		end
	end
	return out
end

-- A view glyph piece's colour texture, as text (white vertex colour: nothing tints it).
local function glyph(piece)
	local c = stub.state(piece).color_texture
	return T.text(c[1], c[2], c[3])
end
local function vertex(t) return T.text(t:GetVertexColor()) end
local function state_color(name) return T.text(st:StateColor(name)) end
local function rgb3(r, g, b) return T.text(r, g, b) end

------------------------------------------------------------------ at rest

test('every bag widget at rest is drawn as before: the glyphs in Text > Normal, the slots untinted, rows plain', function()
	local container = world()
	local normal = rgb3(st:Color('text', 'normal'):GetRGB())
	for _, view in ipairs(VIEWS) do
		local button = container.viewButtons[view]
		local look = st:StateLook(button)
		check(not look.hover and not look.pushed and not look.layer.shown, view .. ': no tint at rest')
		for _, piece in ipairs(button.glyph) do eq(glyph(piece), normal, view .. ': a glyph piece is Text > Normal') end
	end
	check(#slots_of(container) > 0, 'slots exist')
	for _, slot in ipairs(slots_of(container)) do
		local look = st:StateLook(slot)
		check(not look.hover and not look.pushed, 'a slot at rest has no state')
	end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the view buttons

test('view buttons: hover tints; the current view has the accent edge and the fade; under Blizzard the pressed art', function()
	local container = world()
	local compact, rows = container.viewButtons.compact, container.viewButtons.rows
	local look = st:StateLook(compact)
	check(look.selected, 'the current view is selected')
	check(look.fill.shown, 'with the fade')
	eq(rgb3(look.edge.r, look.edge.g, look.edge.b), rgb3(st:Color('accent'):GetRGB()), 'the accent edge, exactly')
	-- the helper is given no glyph: the current view's icon is Text > Normal still
	local normal = rgb3(st:Color('text', 'normal'):GetRGB())
	for _, piece in ipairs(compact.glyph) do eq(glyph(piece), normal, 'the current view\'s glyph is Text > Normal') end
	check(not st:StateLook(rows).selected, 'another view is not')

	-- hover: the body tint, and the glyph in the lighter tone
	stub.fire_script(rows, 'OnEnter', true)
	local hovered = st:StateLook(rows)
	check(hovered.hover and hovered.layer.shown, 'hover tints the body')
	eq(rgb3(hovered.layer.r, hovered.layer.g, hovered.layer.b), rgb3(st:StateColor('hover')), 'in T+')
	for _, piece in ipairs(rows.glyph) do eq(glyph(piece), normal, 'hovered: the glyph stays Text > Normal') end
	stub.fire_script(rows, 'OnLeave', true)
	for _, piece in ipairs(rows.glyph) do eq(glyph(piece), normal, 'and after the mouse leaves') end

	-- a click lights the other and puts the first back
	INV:SetView('bag', 'rows')
	check(st:StateLook(rows).selected and not st:StateLook(compact).selected, 'the selection moves')
	for _, view in ipairs(VIEWS) do
		for _, piece in ipairs(container.viewButtons[view].glyph) do eq(glyph(piece), normal, view .. ': every glyph stays Text > Normal') end
	end
	INV:SetView('bag', 'compact')

	-- every look, a button hovered as the theme switches: the helper holds off under Blizzard,
	-- the panel button is pressed (SetButtonPressed), and no icon is ever anything but Text > Normal
	stub.fire_script(rows, 'OnEnter', true)
	SL.each_look(function(name)
		local l = st:StateLook(container.viewButtons.compact)
		eq(l.blizzard, name == 'blizzard', name .. ': the helper reads the look')
		check(l.selected, name .. ': selected in every look')
		for _, view in ipairs(VIEWS) do
			for _, piece in ipairs(container.viewButtons[view].glyph) do
				eq(glyph(piece), normal, name .. ' ' .. view .. ': a glyph is Text > Normal')
			end
		end
	end)
	stub.fire_script(rows, 'OnLeave', true)
	for _, piece in ipairs(rows.glyph) do eq(glyph(piece), normal, 'the mouse left: still Text > Normal') end
	eq(#take_errors(), 0, 'no errors')
end)

test("the Edit toggle's label is white at rest and after a hover (the 'button' check style's textRest)", function()
	local container = world()
	local edit = container.header.filterButton or INV:CreateEditToggle(container)
	check(edit and edit.text, 'the Edit toggle and its label')
	edit.text:SetTextColor(0.3, 0.4, 0.5) -- a color the label is not left in
	st:RestyleStates(edit)
	edit.text:SetTextColor(1, 1, 1)
	stub.fire_script(edit, 'OnEnter', true)
	stub.fire_script(edit, 'OnLeave', true)
	eq(rgb3(edit.text:GetTextColor()), rgb3(1, 1, 1), 'white after a hover')
	stub.fire_script(edit, 'OnMouseDown', 'LeftButton')
	stub.fire_script(edit, 'OnMouseUp', 'LeftButton')
	eq(rgb3(edit.text:GetTextColor()), rgb3(1, 1, 1), 'and after a press')
	st.config.profile.colors.text.normal:SetRGB(0.2, 0.6, 0.4)
	stub.fire_script(edit, 'OnEnter', true)
	stub.fire_script(edit, 'OnLeave', true)
	eq(rgb3(edit.text:GetTextColor()), rgb3(1, 1, 1), 'not Text > Normal, whatever it is')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ slots

test('item slots: a 16% tint under the mouse in BLEND; a 32% darker tint while pressed (new); bank and tab slots alike', function()
	local container = world()
	local slot = slots_of(container)[1]
	local hover, pushed = slot:GetHighlightTexture(), slot:GetPushedTexture()
	eq(vertex(hover), state_color('hover'), 'the hover is T+ of the accent at the Hover strength')
	eq(select(4, hover:GetVertexColor()), 0.16, '16%')
	eq(hover:GetBlendMode(), 'BLEND', 'in BLEND')
	-- the pushed art stays under Thick and Thin, and tints 32% darker
	eq(pushed:GetTexture(), st.BLANK_TEX, 'the pushed art is kept (it was cleared under Thick and Thin)')
	eq(vertex(pushed), state_color('pushed'), 'T- of the accent')
	eq(select(4, pushed:GetVertexColor()), 0.32, '32%')
	for _, name in ipairs({ 'thin', 'thick' }) do
		T.theme(name)
		INV:StyleSlot(slot, slot:GetParent(), container)
		eq(vertex(slot:GetPushedTexture()), state_color('pushed'), name .. ': pushed still shows')
	end

	-- the accent changes: the pass colors the pieces, T+ of the new accent
	local accent = st.config.profile.theme.accent
	accent:SetRGB(0.9, 0.2, 0.4)
	st:ColorChanged('accent')
	eq(vertex(slot:GetHighlightTexture()), state_color('hover'), 'T+ follows the accent')
	accent:SetRGB(0, 0.68, 0.94)
	st:ColorChanged('accent')

	-- a bank tab's slot is the same icon
	_G.ItemLocation = { CreateFromBagAndSlot = function(_, bag, slot) return { bag = bag, slot = slot } end }
	_G.C_Item = { DoesItemExist = function() return false end }
	_G.C_Bank = {
		FetchMaxNumBankTabs = function() return 4 end,
		FetchNumPurchasedBankTabs = function() return 2 end,
		FetchPurchasedBankTabData = function() return { [1] = {}, [2] = {} } end,
		FetchNextPurchasableBankTabData = function() return { tabCost = 1000, canAfford = true } end,
	}
	local bar = st:CreateFrame('Frame', 'SaftUIInteractionTestBankBar', UIParent)
	bar.slots, bar.purchaseButton = {}, CreateFrame('Button', nil, bar)
	bar.purchaseButton.text = bar.purchaseButton:CreateFontString(nil, 'OVERLAY')
	INV:UpdateBankBagSlots(bar)
	local tab = bar.slots[2]
	eq(vertex(tab:GetHighlightTexture()), state_color('hover'), "a tab's hover")
	eq(vertex(tab:GetPushedTexture()), state_color('pushed'), "a tab's pushed")
	eq(tab:GetHighlightTexture():GetBlendMode(), 'BLEND', "a tab's hover in BLEND")
	-- the unbought slot keeps Danger at 0.3
	local locked = bar.slots[3]
	eq(vertex(locked.locked), T.text(st:ColorRGBA('button', 'danger')), 'the unbought tint keeps Buttons > Danger')
	eq(string.format('%.2f', locked.locked:GetAlpha()), '0.30', 'at 30%')
	-- the Buy label keeps its own rest color after a hover
	local buy = bar.purchaseButton
	buy.text:SetTextColor(st:Color('text', 'danger'):GetRGB())
	st:SkinButton(buy, 'theme', 'theme')
	buy.text:SetTextColor(st:Color('text', 'danger'):GetRGB())
	stub.fire_script(buy, 'OnEnter', true)
	stub.fire_script(buy, 'OnLeave', true)
	eq(rgb3(buy.text:GetTextColor()), rgb3(st:Color('text', 'danger'):GetRGB()), "the Buy label's own color survives a hover")
	eq(#take_errors(), 0, 'no errors')
end)

test("the bag bar's slots: BLEND after Blizzard's UpdateTextures, colored by the helper", function()
	world()
	local names = { 'CharacterBag0Slot', 'CharacterBag1Slot', 'CharacterBag2Slot', 'CharacterBag3Slot', 'CharacterReagentBag0Slot' }
	for _, name in ipairs(names) do
		local slot = CreateFrame('Button', name, UIParent)
		slot:SetSize(37, 37)
		slot.icon = slot:CreateTexture(name .. 'IconTexture', 'BORDER')
		_G[name .. 'IconTexture'] = slot.icon
		slot.IconBorder = slot:CreateTexture(nil, 'OVERLAY')
		slot.SlotHighlightTexture = slot:CreateTexture(nil, 'OVERLAY')
		slot:SetNormalTexture(st.BLANK_TEX)
		slot.UpdateTextures = function(self)
			self:GetHighlightTexture():SetTexture('Interface\\Blizzard')
			self:GetHighlightTexture():SetBlendMode('ADD')
			self:GetHighlightTexture():SetVertexColor(1, 1, 1)
		end
		_G[name] = slot
	end
	MainMenuBarBackpackButton = CreateFrame('Button', nil, UIParent)
	BagBarExpandToggle = CreateFrame('Button', nil, UIParent)
	INV:InitializePlayerBagSlots()
	local slot = _G.CharacterBag0Slot
	slot:UpdateTextures()
	eq(slot:GetHighlightTexture():GetBlendMode(), 'BLEND', 'BLEND, not ADD')
	eq(vertex(slot:GetHighlightTexture()), state_color('hover'), 'T+ of the accent')
	eq(vertex(slot:GetPushedTexture()), state_color('pushed'), 'pushed T-')
	check(st:StateLook(slot).hover_piece ~= nil, 'registered as an icon with the two pieces')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the Categories list

test('the Categories list: hover tints; selected has a 2-line bar and the fade (was 3 and flat)', function()
	world()
	CW.open()
	local w = CW.tab()
	local selected, other
	for _, row in ipairs(w.rows) do
		if SaftUI:GetState(row.frame, 'selected') then selected = row elseif not other and row.id ~= CW.MISC then other = row end
	end
	check(selected and other, 'a selected row and another')
	local look = st:StateLook(selected.frame)
	check(look.bar.shown and look.fill.shown, 'the bar and the fade')
	eq(look.bar.width, 2 * st:GetLineSize(selected.frame), 'two lines wide')
	stub.fire_script(other.frame, 'OnEnter', true)
	local hovered = st:StateLook(other.frame)
	check(hovered.hover and hovered.layer.shown, 'hover tints the row')
	eq(rgb3(hovered.layer.r, hovered.layer.g, hovered.layer.b), rgb3(st:StateColor('hover')), 'in T+')
	check(not other.frame.hover:IsShown(), "no flat accent tint of its own (TINT_ROW is gone from the list)")
	stub.fire_script(other.frame, 'OnLeave', true)
	check(not st:StateLook(other.frame).layer.shown, 'gone when the mouse leaves')
	-- the + New category link: the accent at rest, Text > Strong under the mouse
	local add = w.addButton
	eq(rgb3(add.text:GetTextColor()), rgb3(st:Color('accent'):GetRGB()), 'the link rests in the accent')
	stub.fire_script(add, 'OnEnter', true)
	eq(rgb3(add.text:GetTextColor()), rgb3(st:Color('text', 'strong'):GetRGB()), 'Strong under the mouse')
	stub.fire_script(add, 'OnLeave', true)
	eq(rgb3(add.text:GetTextColor()), rgb3(st:Color('accent'):GetRGB()), 'and the accent again')
	eq(add.text:GetAlpha(), 1, 'its alpha is never touched')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ the rule editor

test('the rule editor: NOT on has the edge and fade, its label Text > Normal; links Strong under the mouse; Caught now Warning 25%', function()
	world()
	INV.categoryEditor.selected = CW.SELL
	CW.open()
	local w = CW.tab()
	local editor = w:EditorCell('rule').widget
	check(editor and editor.rows and #editor.rows > 0, 'the rule editor has rows')
	local row
	for _, r in ipairs(editor.rows) do
		if r.notBox then row = r break end
	end
	check(row, 'a row with a NOT box')
	local box = row.notBox
	eq(box.on and true or false, false, 'NOT is off')
	eq(rgb3(box.text:GetTextColor()), rgb3(st:Color('text', 'muted'):GetRGB()), 'its label is Muted off')
	stub.fire_script(box, 'OnEnter', true)
	check(st:StateLook(box).layer.shown, 'hover tints it')
	stub.fire_script(box, 'OnLeave', true)
	stub.click(box)
	editor = CW.tab():EditorCell('rule').widget
	for _, r in ipairs(editor.rows) do
		if r.notBox and r.notBox.on then box = r.notBox end
	end
	local look = st:StateLook(box)
	check(box.on and look.selected, 'NOT on is selected')
	check(look.fill.shown, 'with the fade')
	eq(rgb3(look.edge.r, look.edge.g, look.edge.b), rgb3(st:Color('accent'):GetRGB()), 'and the accent edge')
	check(rgb3(box.text:GetTextColor()) ~= rgb3(st:Color('accent'):GetRGB()), 'its label is no longer the accent (it is Text > Normal)')

	-- links: + Block and + Group
	local add
	for _, r in ipairs(editor.rows) do
		if r.fields and r.fields.addBlock then add = r.fields.addBlock break end
	end
	check(add, 'an add row')
	eq(rgb3(add.text:GetTextColor()), rgb3(st:Color('accent'):GetRGB()), '+ Block rests in the accent')
	stub.fire_script(add, 'OnEnter', true)
	eq(rgb3(add.text:GetTextColor()), rgb3(st:Color('text', 'strong'):GetRGB()), 'Strong under the mouse')
	stub.fire_script(add, 'OnLeave', true)
	eq(add.text:GetAlpha(), 1, 'its alpha is untouched')

	-- the Caught now tint keeps Text > Warning at its own 25%
	local warning = st:Color('text', 'warning')
	local tinted
	for _, r in ipairs(editor.rows) do
		local c = stub.state(r.tint).color_texture
		if c then
			tinted = c
			break
		end
	end
	check(tinted, 'a tint exists')
	eq(rgb3(tinted[1], tinted[2], tinted[3]), rgb3(warning:GetRGB()), 'in Text > Warning')
	eq(tinted[4], 0.25, 'at 25%')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ checks

test('the filter check (8): edge, a 6 square mark, the fade when ticked; bare checks keep their own checked look', function()
	local container = world()
	local category
	for _, c in pairs(container.categories) do
		if c.filterCheckbox then category = c break end
	end
	check(category, 'a category with a filter check')
	local box = category.filterCheckbox
	box:SetSize(8, 8)
	box:Show()
	box:SetChecked(true)
	st:RestyleStates(box)
	st:SetState(box, 'selected', true)
	local look = st:StateLook(box)
	check(look.selected and look.fill.shown, 'ticked: the fade')
	eq(rgb3(look.edge.r, look.edge.g, look.edge.b), rgb3(st:Color('accent'):GetRGB()), 'the accent edge')
	check(look.mark.shown, 'the mark shows')
	local mark = look.pieces.mark
	local _, _, _, x, y = mark:GetPoint(1)
	eq(x, st:RoundToPixel(1, box), 'the mark is 1 in from the left (floor(8 / 6): a 6 square on the 8 box)')
	eq(y, -st:RoundToPixel(1, box), 'and from the top')

	-- a bare check keeps its own checked look and gets the hover only
	local bare = st:CreateCheckButton(nil, UIParent, 'bare')
	bare:SetSize(14, 14)
	local checked = bare:GetCheckedTexture()
	checked:SetVertexColor(0.3, 0.8, 0.2, 0.7)
	bare:SetChecked(true)
	check(not st:StateLook(bare).selected, 'a bare check is never selected')
	eq(T.text(checked:GetVertexColor()), T.text(0.3, 0.8, 0.2, 0.7), 'its checked look is its own')
	stub.fire_script(bare, 'OnEnter', true)
	check(st:StateLook(bare).layer.shown, 'the hover tints it')
	stub.fire_script(bare, 'OnLeave', true)
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ rest colors after a hover

test("an off row's name rests Muted after a hover; an on row's Normal; a selected row's name is Normal", function()
	world()
	INV:SetCategoryEnabled('Quest', false)
	INV.categoryEditor.selected = 'Consumables'
	CW.open()
	local w = CW.tab()
	local off, on, selected = CW.row_of(w, 'Quest'), CW.row_of(w, 'Armor'), CW.row_of(w, 'Consumables')
	local muted, normal = rgb3(st:Color('text', 'muted'):GetRGB()), rgb3(st:Color('text', 'normal'):GetRGB())
	eq(rgb3(off.name:GetTextColor()), muted, 'off: Muted at rest')
	stub.fire_script(off.frame, 'OnLeave', true)
	stub.fire_script(off.frame, 'OnEnter', true)
	eq(rgb3(off.name:GetTextColor()), normal, 'off, hovered: Normal (the strike line says off)')
	stub.fire_script(off.frame, 'OnLeave', true)
	eq(rgb3(off.name:GetTextColor()), muted, 'off: Muted again after the hover')
	stub.fire_script(on.frame, 'OnEnter', true)
	stub.fire_script(on.frame, 'OnLeave', true)
	eq(rgb3(on.name:GetTextColor()), normal, 'on: Normal after a hover')
	-- the pick: over the fade the name is the helper's text (a name registered with the row)
	local look = st:StateLook(selected.frame)
	check(look.selected and look.text ~= nil, 'the selected row registered its name')
	eq(rgb3(look.text.r, look.text.g, look.text.b), rgb3(selected.name:GetTextColor()), 'the name is what the helper picked')
	eq(rgb3(selected.name:GetTextColor()), normal, 'Normal over the accent fade at the defaults')
	eq(#take_errors(), 0, 'no errors')
end)

test("the NOT box rests Muted after a hover when off", function()
	world()
	INV.categoryEditor.selected = CW.SELL
	CW.open()
	local editor = CW.tab():EditorCell('rule').widget
	local box
	for _, r in ipairs(editor.rows) do
		if r.notBox and not r.notBox.on then box = r.notBox break end
	end
	check(box, 'a NOT box that is off')
	local muted = rgb3(st:Color('text', 'muted'):GetRGB())
	stub.fire_script(box, 'OnEnter', true)
	stub.fire_script(box, 'OnLeave', true)
	eq(rgb3(box.text:GetTextColor()), muted, 'Muted after a hover')
	stub.fire_script(box, 'OnMouseDown', 'LeftButton')
	stub.fire_script(box, 'OnMouseUp', 'LeftButton')
	eq(rgb3(box.text:GetTextColor()), muted, 'and after a press')
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ cost

test('a pass of the Accent with about 700 more slots: two setters a slot, nothing made or forbidden, under 4 KB', function()
	local container = world()
	st:ColorChanged('accent') -- every first color made once
	local base = C.measure(function() st:ColorChanged('accent') end, 100)
	local made = 0
	for _ = 1, 700 do
		if pcall(function() INV:CreateSlot(container, 'Miscellaneous') end) then made = made + 1 end
	end
	eq(made, 700, '700 slots made')
	st:ColorChanged('accent')
	local m = C.measure(function() st:ColorChanged('accent') end, 100)
	C.print('bags, accent, 700 more slots', m)
	eq(m.forbidden.total, 0, 'nothing forbidden')
	eq(m.made, 0, 'nothing made')
	check(m.kb < 4, 'under 4 KB over 100 passes: ' .. m.kb)
	-- a slot's hover and its pushed texture are its two setters: the helper's, nothing else
	eq((m.calls.total - base.calls.total) / 100, 2 * 700, 'two setters a slot: the hover and the pushed texture')
	check(m.calls.total / 100 < 1500 + base.calls.total / 100, 'under 1,500 calls a pass for the slots')
	eq(#take_errors(), 0, 'no errors')
end)
