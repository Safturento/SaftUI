local st = SaftUI

st.defaults.chat = {
	position = {
		point = 'BOTTOMLEFT',
		frame = 'UIParent',
		rel_point = 'BOTTOMLEFT',
		x_off = 30,
		y_off = 30,
	},
	-- width and height (ChatFrame1's size) have no defaults: a profile without them (a
	-- new or reset one too) takes the chat frame's current size once (CHT:CaptureSize).
	theme = 'theme',
	background = 'theme',
	-- fontsVersion has no default: it marks a profile CHT:ConvertFonts has converted (it
	-- took the old Font size row's value, fontsize, which has no default now either).
	font = 'normal',
	padding = 10,
	tabs = {
		fade = false,
	},
	editbox = {
		height = 25,
	}
}