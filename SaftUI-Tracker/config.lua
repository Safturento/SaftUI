local st = SaftUI

-- The tracker's profile settings. `position` (the window's holder) has no
-- default: the first one is written when the tracker first builds
-- (TR:GetPosition, window.lua), as a copy of Misc's objective tracker mover's
-- saved one when that module is loaded and the profile has one, else
-- Blizzard's default spot.
st.defaults.tracker = {
	enable = true, theme = 'theme', background = 'theme',
	width = 260, height = 560, grow = 'down', header = true, count = true, hide_empty = true,
	font = 'normal', header_font = 'heading',
	quests = {
		show = 'tracked', zones = true, current_first = true, order = 'game', finished_first = false,
		level = st.forever, tags = true, difficulty = true, icons = true, hide_finished = false,
		finished_objectives = false, bars = true, timers = true, waypoint = true, tooltips = true,
		left_click = 'map', spacing = 8,
	},
	items = {
		placement = 'row', size = 24, cooldown = true, count = true, range = true, nearest = false, nearest_size = 40,
		nearest_position = { point = 'TOPRIGHT', frame = 'UIParent', rel_point = 'TOPRIGHT', x_off = -320, y_off = st.forever and -275 or -260 },
	},
	visibility = {
		combat = 'show', nocombat = 'show', mouseoff = 'show', instance = 'show', boss = 'show', mythic = 'show',
		fade_alpha = 0.3, hover = true, background_hover = false, scrollbar_hover = true, items = false,
	},
	blizzard = { mode = 'place' },
}

-- The key bindings screen: a SaftUI header (SaftUI-Tracker/Bindings.xml) and
-- the nearest quest item button's key.
BINDING_HEADER_SAFTUI = 'SaftUI'
_G['BINDING_NAME_CLICK SaftUITrackerNearestItem:LeftButton'] = 'Use the nearest quest item'
