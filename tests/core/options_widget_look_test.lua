-- SaftUI-Core/Config/optionslook.lua, the look the options window's controls
-- share: the execute button's and the toggle's Blizzard art, a disabled
-- execute button and a multiselect row's hover under Blizzard, and the window's
-- fonts.
--
-- Real: the model (optionsmodel.lua) the widgets read and write through, the
-- widgets, panels.lua and the helpers it needs (config_helpers.lua, with a real
-- AceConfigRegistry-3.0). Synthetic AceConfig option tables stand for the
-- options. The mouse and the keyboard are played by firing the frames' scripts
-- (stub.fire_script), and SaftUI's color picker through its own boxes
-- and buttons (options_widgets_helpers.lua's pick_color). The world and the helpers are
-- options_widgets_helpers.lua's.
local H = load_test_file('core/options_widgets_helpers.lua')
local st = SaftUI
local W = st.OptionsWidgets
local shown_textures, parent, panel_of, around, rgba = H.shown_textures, H.parent, H.panel_of, H.around, H.rgba
local bind, atlases_of, opt = H.bind, H.atlases_of, H.opt

------------------------------------------------------------------ under the Blizzard theme

test("/sui's execute button and toggle take Blizzard's art under Blizzard, their own under Thick", function()
	local checked = true
	local selected = { a = true }
	local e = bind('execute', 'go', opt('execute', 'Go', { func = function() end }))
	local t = bind('toggle', 'on', opt('toggle', 'On', {
		get = function() return checked end, set = function(_, v) checked = v end,
	}))
	local m = bind('multiselect', 'pick', opt('multiselect', 'Pick', {
		values = { a = 'A', b = 'B' },
		get = function(_, key) return selected[key] end, set = function(_, key, v) selected[key] = v end,
	}))
	-- Placed as the window places them, so their edges can be read.
	parent:SetSize(800, 600)
	parent:SetPoint('CENTER')
	e:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	t:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -50)
	m:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -90)
	local function rebind(w) w:Bind(w.root, w.row, w.onChanged) end
	local function boxes() return { toggle = t.frame, rowA = m.rows[1].box, rowB = m.rows[2].box } end
	local FIELD, EDGE = rgba(unpack(st.BOX_COLORS.field)), rgba(unpack(st.BOX_COLORS.edge))

	-- Under Thick: the window's own look, as before.
	eq(panel_of(e.frame), '', 'Thick: the execute button is no panel button')
	check(e.frame.backdropInfo ~= nil, "Thick: the execute button's own box")
	eq(atlases_of(t.frame), '', 'Thick: the toggle has no Blizzard art')

	st.config.profile.theme.name = 'blizzard'
	for _, w in ipairs({ e, t, m }) do rebind(w) end -- the window re-renders after a theme change

	-- The execute button: Blizzard's panel button, inside its own rect.
	local button = e.frame
	local states, pieces = panel_of(button)
	eq(states, 'Left=Up,Middle=Up,Right=Up', "Blizzard: the execute button is Blizzard's panel button")
	eq(button.backdropInfo, nil, 'its own box off')
	check(not button.outline:IsShown(), 'and its dark line')
	eq(button:GetHeight(), 26, 'it keeps its height')
	eq(e:GetWidth(), button:GetWidth(), 'and its width')
	eq(pieces.Left and around(pieces.Left, button):match('^0,0,'), '0,0,', 'the left end on its left edge, its full height')
	eq(pieces.Right and around(pieces.Right, button):match(',0,0,0$'), ',0,0,0', 'the right end on its right edge')
	eq(pieces.Left and pieces.Left:GetWidth(), 14, "the ends 12/22 of its 26")
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	eq((panel_of(button)), 'Left=Down,Middle=Down,Right=Down', 'pressed: -Down')
	stub.fire_script(button, 'OnMouseUp', 'LeftButton')
	eq((panel_of(button)), 'Left=Up,Middle=Up,Right=Up', 'let go: -Up')

	-- The toggle and the multiselect's rows: the Settings panel's check box,
	-- inside the box's own 18 square.
	for name, box in pairs(boxes()) do
		eq(box.backdropInfo, nil, name .. ': its own box off')
		check(not box.outline:IsShown(), name .. ': and its dark line')
		check(not box.mark:IsShown(), name .. ': no blue mark')
		eq(box:GetWidth() .. 'x' .. box:GetHeight(), '18x18', name .. ': it keeps its size')
		-- The art's own size and place are pinned by the test of the check boxes' size.
		check(#shown_textures(box) > 0, name .. ': it is drawn')
	end
	eq(atlases_of(t.frame), 'checkbox-minimal,checkbox-minimal,checkmark-minimal', 'the toggle, checked: the box, its highlight and the check')
	eq(atlases_of(m.rows[1].box), 'checkbox-minimal,checkbox-minimal,checkmark-minimal', 'a checked row too')
	eq(atlases_of(m.rows[2].box), 'checkbox-minimal,checkbox-minimal', 'an unchecked row: no check')
	stub.fire_script(t.frame, 'OnClick')
	eq(checked, false, 'a click still sets')
	eq(atlases_of(t.frame), 'checkbox-minimal,checkbox-minimal', 'and the check goes')
	t:SetDisabled(true)
	checked = true
	t:Refresh()
	eq(atlases_of(t.frame), 'checkbox-minimal,checkbox-minimal,checkmark-minimal-disabled', 'disabled and checked: the grey check')
	t:SetDisabled(false)

	-- Thick again: the window's own look.
	st.config.profile.theme.name = 'thick'
	for _, w in ipairs({ e, t, m }) do rebind(w) end
	eq(panel_of(button), '', 'Thick: no panel button')
	check(button.outline:IsShown(), 'Thick: its dark line again')
	eq(rgba(button:GetBackdropColor()), rgba(unpack(st.BOX_COLORS.bg)), "Thick: the execute button's own fill")
	for name, box in pairs(boxes()) do
		eq(atlases_of(box), '', name .. ': no Blizzard art')
		eq(rgba(box:GetBackdropColor()), FIELD, name .. ': its own box again')
		eq(rgba(box:GetBackdropBorderColor()), EDGE, name .. ': its own edge')
		check(box.outline:IsShown(), name .. ': its dark line')
	end
	check(t.frame.mark:IsShown(), 'the checked toggle shows its blue mark')
	check(m.rows[1].box.mark:IsShown(), 'and the checked row')
	check(not m.rows[2].box.mark:IsShown(), 'not the unchecked row')
	for _, w in ipairs({ e, t, m }) do w:Release() end
	eq(#take_errors(), 0, 'no errors')
end)

test("/sui under Blizzard: a disabled execute button is -Disabled, and a multiselect row lights its box under the mouse", function()
	local e = bind('execute', 'go', opt('execute', 'Go', { func = function() end }))
	local m = bind('multiselect', 'pick', opt('multiselect', 'Pick', {
		values = { a = 'A' }, get = function() return false end, set = function() end,
	}))
	e:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -10)
	m:SetPoint('TOPLEFT', parent, 'TOPLEFT', 10, -90)
	local function rebind(w) w:Bind(w.root, w.row, w.onChanged) end
	-- What the row draws over its box while the mouse is on the row, as
	-- 'atlas blend', '' for nothing: a texture of the box's own, in its
	-- OVERLAY layer, which the row's OnEnter shows (the row takes the mouse,
	-- the box doesn't, so the box's own HIGHLIGHT layer never shows). The
	-- game draws a frame's regions under its children's, so a texture of the
	-- row's would lie under the box's art.
	local function row_highlight(row)
		local out = {}
		stub.fire_script(row, 'OnEnter')
		for _, region in ipairs(shown_textures(row.box)) do
			if select(1, region:GetDrawLayer()) == 'OVERLAY' and region:GetBlendMode() == 'ADD' then
				out[#out + 1] = tostring(region:GetAtlas()) .. ' ' .. region:GetBlendMode()
				check(region:GetParent() == row.box, 'the hover is a texture of the box')
				eq(around(region, row.box), '0,2,5,-2', 'the hover lies over the box, at the art\'s size')
			end
		end
		for _, region in ipairs(shown_textures(row)) do
			check(select(1, region:GetDrawLayer()) ~= 'HIGHLIGHT', 'and none of the row\'s own')
		end
		stub.fire_script(row, 'OnLeave')
		for _, region in ipairs(shown_textures(row.box)) do
			check(region:GetBlendMode() ~= 'ADD' or select(1, region:GetDrawLayer()) ~= 'OVERLAY', 'OnLeave hides it')
		end
		return table.concat(out, ',')
	end

	-- Under Thick: as before, dimmed with its own box, and a row whose scripts light the box's edge.
	e:SetDisabled(true)
	eq(e.frame:GetAlpha(), 0.4, 'Thick: a disabled execute button is dimmed')
	eq((panel_of(e.frame)), '', 'Thick: no panel button')
	check(e.frame.backdropInfo ~= nil, 'Thick: its own box')
	e:SetDisabled(false)
	eq(row_highlight(m.rows[1]), '', 'Thick: the row draws no hover art')
	stub.fire_script(m.rows[1], 'OnEnter')
	eq(rgba(m.rows[1].box:GetBackdropBorderColor()), rgba(st.config.profile.theme.accent.r, st.config.profile.theme.accent.g, st.config.profile.theme.accent.b, 1), 'Thick: hovering the row lights the box blue')
	stub.fire_script(m.rows[1], 'OnLeave')

	st.config.profile.theme.name = 'blizzard'
	rebind(e)
	rebind(m)
	eq((panel_of(e.frame)), 'Left=Up,Middle=Up,Right=Up', 'Blizzard: enabled, -Up')
	e:SetDisabled(true)
	eq((panel_of(e.frame)), 'Left=Disabled,Middle=Disabled,Right=Disabled', 'Blizzard: disabled, -Disabled')
	e:SetDisabled(false)
	eq((panel_of(e.frame)), 'Left=Up,Middle=Up,Right=Up', 'Blizzard: enabled again, -Up')
	-- Bound disabled: the window binds a disabled row's widget so.
	e.row.disabled = true
	rebind(e)
	eq((panel_of(e.frame)), 'Left=Disabled,Middle=Disabled,Right=Disabled', 'Blizzard: bound disabled, -Disabled')
	e.row.disabled = nil
	rebind(e)
	eq(row_highlight(m.rows[1]), 'checkbox-minimal ADD', "Blizzard: the row's hover draws the box's highlight over it, additive")

	st.config.profile.theme.name = 'thick'
	rebind(e)
	rebind(m)
	eq((panel_of(e.frame)), '', 'Thick again: no panel button')
	eq(row_highlight(m.rows[1]), '', 'Thick again: no hover art')
	for _, w in ipairs({ e, m }) do w:Release() end
	eq(#take_errors(), 0, 'no errors')
end)

------------------------------------------------------------------ /sui's other controls under the Blizzard theme

test("the window's fonts draw a profile outline of None with no font flags", function()
	local fonts = st.config.profile.fonts
	-- The titles take Heading's outline, the field font Text's.
	local old = { fonts.normal.font_outline, fonts.heading.font_outline }
	local OB = st.OptionsBody
	for _, case in ipairs({
		{ 'NONE', '' }, { 'OUTLINE', 'OUTLINE' }, { 'MONOCHROMETHICKOUTLINE', 'MONOCHROMETHICKOUTLINE' },
	}) do
		fonts.normal.font_outline, fonts.heading.font_outline = case[1], case[1]
		W.UpdateFonts()
		local _, _, flags = W.GetFont():GetFont()
		eq(flags, case[2], case[1] .. ': the field font')
		local font = OB.Font('title')
		OB.UpdateFonts()
		_, _, flags = font:GetFont()
		eq(flags, case[2], case[1] .. ': the title font')
	end
	fonts.normal.font_outline, fonts.heading.font_outline = old[1], old[2]
	OB.UpdateFonts()
	eq(#take_errors(), 0, 'no errors')
end)
