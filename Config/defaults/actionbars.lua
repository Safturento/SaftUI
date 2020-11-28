local st = SaftUI

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
		total = 9,
		position = {point = 'BOTTOM', frame = 'UIParent', rel_point = 'BOTTOM', x_off = 0, y_off = st.CLAMP_INSET },
		backdrop = {
			-- enable = true,
			height = 3,
			conform = false,
		}
	},
	bar2 = {
		total = 9,
		position = { point = 'BOTTOM', frame = st.name ..'ActionBar1', rel_point = 'TOP', x_off = 0, y_off = 7},
	},
	bar3 = {
		total = 9,
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