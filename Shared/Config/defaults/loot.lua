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
		width = 300,
		-- anchor_height = 20,
		item_height = 20,
		position = {
			point = 'BOTTOMRIGHT',
			frame = 'UIParent',
			rel_point = 'BOTTOMRIGHT',
			x_off = -st.CLAMP_INSET,
			y_off = st.CLAMP_INSET,
		},
		min_quality = 0,
		spacing = 7,
		max_items = 10,
		fade_time = 10,
		template = 'thick',
		font = 'pixel',
		filters = {
			self_item = true,
			other_item = true,
			gold = true,
			currency = true,
			reputation = true,
			experience = false
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
