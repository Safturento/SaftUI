local st = SaftUI

--[[
	SaftUI's action bars (SaftUI-ActionBars). One table per bar, keyed 'bar1'..'bar8',
	'pet' and 'stance' (see AB.BAR_IDS in init.lua). Every key of a bar:
	  - enable: a disabled bar is hidden, and its keys do nothing (bindings.lua).
	  - buttons: how many of its buttons are shown: 12 on bars 1-8, 10 on the pet
	    and stance bars. The stance bar shows no more than the class has forms.
	    The keys of the others do nothing.
	  - perrow: buttons per row. 1 makes a column.
	  - size: the edge of a button, its border included. The icon sits inside the
	    border, so bars fit together on a size + spacing grid.
	  - spacing: the gap between buttons, and in the default layout between bars.
	  - position: { point, frame, rel_point, x_off, y_off }, as everywhere in SaftUI.
	  - visibility: 'always', 'combat' (shown only in combat) or 'mouseover'
	    (faded to fade_alpha until the mouse is over it). See bars.lua.
	  - fade_alpha: the opacity of a 'mouseover' bar while the mouse isn't on it.
	  - text: hotkey, stack count and macro name. Each has show, font (a
	    LibSharedMedia font name), size, outline (a Fonts outline name, 'NONE' for
	    none), point and rel_point (the text's point and the button's), and
	    x_off / y_off from there. The pet and stance buttons only have a hotkey;
	    their count and macro name keep the shape and go unused.
	template is the backdrop template every button uses.

	The default layout, at 45px buttons 3px apart (a 48px pitch):
	  - Bars 1-3 are rows of 12 at the bottom centre. Bar 1 is 20px up from the
	    bottom edge (st.CLAMP_INSET, the minimap's gap), and bars 2 and 3 stack above
	    it, 3px apart. Each row is 573px wide and 45px high.
	  - Bars 4 and 5 are columns of 12, side by side, centred vertically. Bar 4 is
	    20px in from the right edge and bar 5 is 3px to its left, the way Blizzard's
	    Right and Left bars sit.
	  - Bars 6-8 are off. When turned on they continue the columns leftwards, so
	    they stay out of the space above the bottom stack (pet, stance and the extra
	    buttons go there).
	  - The pet and stance bars are rows of 30px buttons 3px apart, 3px above bar
	    3: the pet bar at its left end, the stance bar at its right end, each
	    growing towards the middle as it gets more buttons. They're anchored by a
	    corner, so neither is centred on an axis. All 10 pet buttons are 327px,
	    more than half of bar 3, so the extra action and zone ability buttons go
	    above this row.
]]

local pixel = st.defaults.fonts.pixel

-- The gap between buttons, and between the bars the default layout stacks.
local SPACING = 3

local function Text(point, x_off, y_off)
	return {
		show = true,
		font = pixel.font_name,
		size = pixel.font_size,
		outline = pixel.font_outline,
		point = point,
		rel_point = point,
		x_off = x_off,
		y_off = y_off,
	}
end

-- A new table each call: AceDB defaults mustn't share tables between bars.
local function Bar(enable, perrow, point, frame, rel_point, x_off, y_off)
	return {
		enable = enable,
		buttons = 12,
		perrow = perrow,
		size = 45,
		spacing = SPACING,
		position = { point = point, frame = frame, rel_point = rel_point, x_off = x_off, y_off = y_off },
		visibility = 'always',
		fade_alpha = 0.3,
		text = {
			hotkey = Text('TOPRIGHT', -3, -3),
			count = Text('BOTTOMRIGHT', -3, 3),
			macro = Text('BOTTOM', 0, 3),
		},
	}
end

-- The pet and stance bars: a row of 10 buttons of 30px, on bar 3 by the
-- corner point.
local function SmallBar(point, rel_point)
	local bar = Bar(true, 10, point, 'SaftUI_ActionBar3', rel_point, 0, SPACING)
	bar.buttons = 10
	bar.size = 30
	return bar
end

-- Replaces the legacy table from SaftUI-Misc/config.lua, whose positions named
-- SaftUIActionBar1.. frames that no longer existed.
st.defaults.actionbars = {
	template = 'thicktransparent',

	bar1 = Bar(true, 12, 'BOTTOM', 'UIParent', 'BOTTOM', 0, st.CLAMP_INSET),
	bar2 = Bar(true, 12, 'BOTTOM', 'SaftUI_ActionBar1', 'TOP', 0, SPACING),
	bar3 = Bar(true, 12, 'BOTTOM', 'SaftUI_ActionBar2', 'TOP', 0, SPACING),
	bar4 = Bar(true, 1, 'RIGHT', 'UIParent', 'RIGHT', -st.CLAMP_INSET, 0),
	bar5 = Bar(true, 1, 'RIGHT', 'SaftUI_ActionBar4', 'LEFT', -SPACING, 0),
	bar6 = Bar(false, 1, 'RIGHT', 'SaftUI_ActionBar5', 'LEFT', -SPACING, 0),
	bar7 = Bar(false, 1, 'RIGHT', 'SaftUI_ActionBar6', 'LEFT', -SPACING, 0),
	bar8 = Bar(false, 1, 'RIGHT', 'SaftUI_ActionBar7', 'LEFT', -SPACING, 0),
	pet = SmallBar('BOTTOMLEFT', 'TOPLEFT'),
	stance = SmallBar('BOTTOMRIGHT', 'TOPRIGHT'),
}
