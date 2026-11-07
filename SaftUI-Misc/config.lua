local st = SaftUI

-- The experience bars' default spot, in the named position shape (Core's default
-- is an array). Same spot: under the minimap, right edges lined up.
st.defaults.experience.position = {
	point = 'TOPRIGHT',
	frame = 'Minimap',
	rel_point = 'BOTTOMRIGHT',
	x_off = 0,
	y_off = -7,
}

st.defaults.actionbars = {
	font = 'pixel',
	hide_empty = true,

	['**'] = {
		enable = true,
		template = 'thicktransparent',
		spacing = 7,
		height = 20,
		width = 30,
		alpha = 1,
		ooc_alpha = 1,
		total = 12,
		perrow = 12,
		backdrop = {
			enable = false,
			conform = true,
			template = 'thick',
			width = 12,
			height = 1,
			padding = 6,
			anchor = 'BOTTOMLEFT',
		}
	},
	bar1 = {
		total = 10,
		position = {point = 'BOTTOM', frame = 'UIParent', rel_point = 'BOTTOM', x_off = 0, y_off = st.CLAMP_INSET },
		backdrop = {
			-- enable = true,
			height = 3,
			conform = false,
		}
	},
	bar2 = {
		total = 10,
		position = { point = 'BOTTOM', frame = st.name ..'ActionBar1', rel_point = 'TOP', x_off = 0, y_off = 7},
	},
	bar3 = {
		total = 10,
		position = { point = 'BOTTOM', frame = st.name ..'ActionBar2', rel_point = 'TOP', x_off = 0, y_off = 7},
	},
	bar4 = {
		position = {point = 'RIGHT', frame = 'UIParent', rel_point = 'RIGHT', x_off = -st.CLAMP_INSET, y_off = 0},
		perrow = 1,
	},
	bar5 = {
		position = { point = 'RIGHT', frame = st.name ..'ActionBar4', rel_point = 'LEFT', x_off = -7, y_off = 0},
		perrow = 1,
	},
	pet = {
		total = 10,
		perrow = 10,
		position = { point = 'BOTTOM', frame = st.name ..'ActionBar3', rel_point = 'TOP', x_off = 0, y_off = 8}
	}
}

st.defaults.tooltip = {
	template = 'thicktransparent',
	font = 'normal',
	attach_to_bags = true,
}

st.defaults.skinning = {
	font = 'pixel',
	template = 'thicktransparent',
}

-- Forever's swing timer bars (SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua).
-- Width and height are the visible bar: Blizzard's default 426x30 frame less the
-- 5/4px art inset around its StatusBar. Blizzard stacks the bars in its bottom managed
-- container, main hand on top with a 12px gap between visible bars; the chain below
-- keeps that stack. The container's spot depends on Blizzard's action bars, so the main
-- hand uses Blizzard's own out-of-container anchor (BOTTOM, UIParent, BOTTOM, 0, 450)
-- plus the 4px inset. showtitle / showtime show the bar's title and time text, and
-- opacity is the whole bar's alpha (Blizzard's range dimming multiplies with it).
st.defaults.swingtimer = {
	mainhand = {
		width = 416,
		height = 22,
		showtitle = true,
		showtime = true,
		opacity = 1,
		position = { point = 'BOTTOM', frame = 'UIParent', rel_point = 'BOTTOM', x_off = 0, y_off = 454 },
	},
	offhand = {
		width = 416,
		height = 22,
		showtitle = true,
		showtime = true,
		opacity = 1,
		position = { point = 'TOP', frame = st.name .. 'SwingTimerMainHand', rel_point = 'BOTTOM', x_off = 0, y_off = -12 },
	},
	ranged = {
		width = 416,
		height = 22,
		showtitle = true,
		showtime = true,
		opacity = 1,
		position = { point = 'TOP', frame = st.name .. 'SwingTimerOffHand', rel_point = 'BOTTOM', x_off = 0, y_off = -12 },
	},
}

-- Forever's totem bar (SaftUI-Misc/totembar.lua). Shown by default, as Blizzard shows it.
st.defaults.totembar = {
	hide = false,
}

-- Blizzard's player buff and debuff frames (SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua).
-- The defaults reproduce Blizzard's default Edit Mode layout (Modern and Classic share it),
-- which is what SaftUI showed before it took the frames over:
--   - 30px icons, 5px apart in a row. Rows are 15px apart: Blizzard's buttons are 40px
--     tall, leaving 10px under each icon for its duration, plus 5px padding.
--   - 11 buffs or 8 debuffs per row, growing left and wrapping down, up to all of
--     Blizzard's 32 buff and 16 debuff buttons.
--   - The first buff's top-right corner is 270px in from the screen's top-right corner and
--     10px down. That's Blizzard's BuffFrame anchor (-255, -10) less its 15px-wide
--     collapse button. The first debuff is at Blizzard's DebuffFrame anchor (-270, -155).
--   - Text in the skin's font (the default 'pixel' font). The duration sits 3px under the
--     icon, clearing the thick backdrop. The stack count sits in the icon's bottom-right
--     corner, 1px up.
-- size is the icon's edge. spacing_x and spacing_y are the gaps between icons. perrow is
-- icons per row (per column when growing up or down), like Blizzard's Icon Limit, and max
-- caps the icons shown. grow is the direction icons are added in (LEFT, RIGHT, UP, DOWN),
-- and wrap the direction new rows or columns go, perpendicular to grow. duration and count
-- style the duration and stack count texts: point is the text's anchor point and rel_point
-- the icon's, with x_off/y_off from there.
local pixel = st.defaults.fonts.pixel
st.defaults.auras = {
	buffs = {
		size = 30,
		spacing_x = 5,
		spacing_y = 15,
		perrow = 11,
		max = 32,
		grow = 'LEFT',
		wrap = 'DOWN',
		position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -270, y_off = -10 },
		duration = { font = pixel.font_name, size = pixel.font_size, outline = pixel.font_outline, point = 'TOP', rel_point = 'BOTTOM', x_off = 0, y_off = -3 },
		count = { font = pixel.font_name, size = pixel.font_size, outline = pixel.font_outline, point = 'BOTTOMRIGHT', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = 1 },
	},
	debuffs = {
		size = 30,
		spacing_x = 5,
		spacing_y = 15,
		perrow = 8,
		max = 16,
		grow = 'LEFT',
		wrap = 'DOWN',
		position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -270, y_off = -155 },
		duration = { font = pixel.font_name, size = pixel.font_size, outline = pixel.font_outline, point = 'TOP', rel_point = 'BOTTOM', x_off = 0, y_off = -3 },
		count = { font = pixel.font_name, size = pixel.font_size, outline = pixel.font_outline, point = 'BOTTOMRIGHT', rel_point = 'BOTTOMRIGHT', x_off = 0, y_off = 1 },
	},
}
