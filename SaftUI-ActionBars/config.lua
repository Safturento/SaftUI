local st = SaftUI

--[[
	SaftUI's action bars (SaftUI-ActionBars). One table per bar, keyed 'bar1'..'bar8'
	(see AB.BAR_IDS in init.lua). Every key of a bar:
	  - enable: a disabled bar is hidden, and its keys do nothing (bindings.lua).
	  - buttons: how many of its 12 buttons are shown. The keys of the others do
	    nothing.
	  - perrow: buttons per row. 1 makes a column.
	  - size: the edge of a button, its border included. The icon sits inside the
	    border, so bars fit together on a size + spacing grid.
	  - spacing: the gap between buttons, and in the default layout between bars.
	  - position: { point, frame, rel_point, x_off, y_off }, as everywhere in SaftUI.
	  - visibility: 'always' for now. The Visibility settings come with the options.
	  - text: hotkey, stack count and macro name. Each has show, font (a
	    LibSharedMedia font name), size, outline, point and rel_point (the text's
	    point and the button's), and x_off / y_off from there.
	template is the backdrop template every button uses.

	The default layout, at 45px buttons 2px apart (a 47px pitch):
	  - Bars 1-3 are rows of 12 at the bottom centre. Bar 1 is 20px up from the
	    bottom edge (st.CLAMP_INSET, the minimap's gap), and bars 2 and 3 stack above
	    it, 2px apart. Each row is 562px wide and 45px high.
	  - Bars 4 and 5 are columns of 12, side by side, centred vertically. Bar 4 is
	    20px in from the right edge and bar 5 is 2px to its left, the way Blizzard's
	    Right and Left bars sit.
	  - Bars 6-8 are off. When turned on they continue the columns leftwards, so
	    they stay out of the space above the bottom stack (pet, stance and the extra
	    buttons go there).
]]

local pixel = st.defaults.fonts.pixel

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
		spacing = 2,
		position = { point = point, frame = frame, rel_point = rel_point, x_off = x_off, y_off = y_off },
		visibility = 'always',
		text = {
			hotkey = Text('TOPRIGHT', -3, -3),
			count = Text('BOTTOMRIGHT', -3, 3),
			macro = Text('BOTTOM', 0, 3),
		},
	}
end

-- Replaces the legacy table from SaftUI-Misc/config.lua, whose positions named
-- SaftUIActionBar1.. frames that no longer existed.
st.defaults.actionbars = {
	template = 'thicktransparent',

	bar1 = Bar(true, 12, 'BOTTOM', 'UIParent', 'BOTTOM', 0, st.CLAMP_INSET),
	bar2 = Bar(true, 12, 'BOTTOM', 'SaftUI_ActionBar1', 'TOP', 0, 2),
	bar3 = Bar(true, 12, 'BOTTOM', 'SaftUI_ActionBar2', 'TOP', 0, 2),
	bar4 = Bar(true, 1, 'RIGHT', 'UIParent', 'RIGHT', -st.CLAMP_INSET, 0),
	bar5 = Bar(true, 1, 'RIGHT', 'SaftUI_ActionBar4', 'LEFT', -2, 0),
	bar6 = Bar(false, 1, 'RIGHT', 'SaftUI_ActionBar5', 'LEFT', -2, 0),
	bar7 = Bar(false, 1, 'RIGHT', 'SaftUI_ActionBar6', 'LEFT', -2, 0),
	bar8 = Bar(false, 1, 'RIGHT', 'SaftUI_ActionBar7', 'LEFT', -2, 0),
}
