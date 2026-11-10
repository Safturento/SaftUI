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

-- position is the default tooltip's edit mode holder (tooltipposition.lua). The
-- tooltip grows from the holder's corner. attach_to_bags and attach_to_feed put
-- it to the left of the bag window or the loot feed while they show.
st.defaults.tooltip = {
	theme = 'theme',
	background = 'theme',
	font = 'normal',
	attach_to_bags = true,
	attach_to_feed = true,
	position = { point = 'BOTTOMRIGHT', frame = 'UIParent', rel_point = 'BOTTOMRIGHT', x_off = -20, y_off = 20 },
}

st.defaults.skinning = {
	font = 'pixel',
	theme = 'theme',
	background = 'theme',
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
-- button_size is every button on the bar, its border included (Blizzard's is 30), and
-- button_spacing the gap between neighbouring buttons (3, as on SaftUI's action bars;
-- Blizzard has 3 or 8). timer_bar and timer_text show a draining bar and a countdown above
-- each element button while that element has a totem down (SaftUI-Misc/totemtimers.lua).
-- timer_text_position is 'above' (a thin bar with the text above it) or 'on' (a taller bar
-- with the text on it); it only applies while both show. timer_text_x and timer_text_y
-- move the text from its centred spot, in pixels. timer_bar_height is the bar's
-- height with its border; with the text on it the bar is never shorter than the text
-- needs. colors are the bar's element colours, by element (SaftUI-Misc/totemskin.lua):
-- each element button's border, its flyout's "none" choice and its timer bar. Sampled from
-- Blizzard's UI-TotemBar border art, so they read as the same elements. One color per element in /sui (the totem bar's Element colors).
-- position (a shaman's holder, SaftUI's edit mode mover for the bar) has no default: a
-- profile without one (a new or reset one too) keeps the holder's spot from the last
-- profile, or takes the bar's spot on screen once Blizzard has placed it
-- (SaftUI-Misc/totembar.lua), so nothing moves on first load or on a profile change.
st.defaults.totembar = {
	hide = false,
	button_size = 30,
	button_spacing = 3,
	timer_bar = true,
	timer_text = true,
	timer_text_position = 'above',
	timer_text_x = 0,
	timer_text_y = 0,
	timer_bar_height = 8,
	colors = {
		earth = { 0.29, 0.55, 0.16 },
		fire = { 0.71, 0.28, 0.13 },
		water = { 0.22, 0.57, 0.71 },
		air = { 0.51, 0.22, 0.90 },
	},
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
		-- The screen edge margin in from the top, so its clamp doesn't push the buffs.
		position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -270, y_off = -st.CLAMP_INSET },
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
