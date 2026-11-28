local st = SaftUI

st.defaults.loot = {
	-- Blizzard's loot window (popup.lua). Where it opens is Blizzard's; its
	-- width and its rows' scale are popup.lua's fixed compact layout, with no
	-- settings.
	popup = {
		enable = true,
		theme = 'theme',
		background = 'solid',
		font = 'normal',
	},
	feed = {
		width = 400,
		item_height = 32,
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
		theme = 'theme',
		background = 'solid',
		font = 'normal',
		filters = {
			Loot = true,
			Gold = true,
			Self = true,
			Honor = true,
			Currency = true,
			Reputation = true,
			Experience = true,
			Skill = true,
			Rolls = true,
		}
	},
	roll = {
		height = 30,
		width = 400,
		spacing = 7,
		theme = 'theme',
		background = 'solid',
		position = { point = 'BOTTOMRIGHT', frame = 'UIParent', rel_point = 'BOTTOMRIGHT', x_off = -500, y_off = 100 },
		font = 'normal',
		grow_down = false,
	}
}
