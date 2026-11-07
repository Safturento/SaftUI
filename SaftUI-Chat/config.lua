local st = SaftUI

st.defaults.chat = {
	position = {
		point = 'BOTTOMLEFT',
		frame = 'UIParent',
		rel_point = 'BOTTOMLEFT',
		x_off = 30,
		y_off = 30,
	},
	-- width and height (ChatFrame1's size) have no defaults: a profile without them takes
	-- the size Blizzard's Edit Mode layout gave the chat frame (CHT:CaptureSize).
	template = 'thicktransparent',
	font = 'normal',
	padding = 10,
	fontsize = 16,
	linespacing = 5,
	fadetabs = true,
	tabs = {
		height = 25,
		fade = false,
	},
	editbox = {
		height = 25,
	}
}