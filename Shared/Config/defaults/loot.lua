local st = SaftUI

st.defaults.loot = {
	popup = {
		template = 'thick',
		font = 'pixel',
		name_wrap = true,
		width = 200,
		button_height = 30,
		spacing = 7,
	},
	feed = {
		width = 400,
		-- anchor_height = 20,
		item_height = 30,
		position = {
			point = 'BOTTOMRIGHT',
			frame = 'UIParent',
			rel_point = 'BOTTOMRIGHT',
			x_off = -st.CLAMP_INSET,
			y_off = st.CLAMP_INSET,
		},
		spacing = 8,
		max_items = 10,
		fade_time = 10,
		template = 'thick',
		font = 'pixel',
		filters = {
			Loot = true,
			Gold = true,
			Self = true,
			Honor = true,
			Currency = true,
			Reputation = true,
		}
	},
	roll = {
		height = 30,
		width = 400,
		spacing = 7,
		template = 'thick',
		position = {'BOTTOMLEFT', 'UIParent', 'LEFT', 20, -300},
		font = 'pixel',
		grow_down = false,
	}
}
