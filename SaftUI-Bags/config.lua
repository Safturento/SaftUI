local st = SaftUI

st.defaults.inventory = {
	enable = true,
	-- The Theme and Background (SaftUI-Core/theme.lua) of the item and currency
	-- slots, and of the windows. 'theme' follows SaftUI's.
	buttontheme = 'theme',
	buttonbackground = 'theme',
	theme = 'theme',
	background = 'theme',
	padding = 10,
	iconsize = 50, -- item button height; the width follows at 6:5 (60 by default), see INV:GetButtonWidth
	buttonspacing = 3,
	categoryTitleHeight = 50,
	scrollSpeed = 3,
	autorepair = true,
	autovendor = true,
	combinedBank = true,
	inverted = true,
	stackItems = true,
	fonts = {
		titles = 'normal',
		icons = 'pixel',
	},
	bag = {
		position = {
			point = 'BOTTOMRIGHT',
			frame = 'UIParent',
			rel_point = 'BOTTOMRIGHT',
			x_off = -20,
			y_off = 20,
		},
		perrow = 3,
		maxRows = 15,
		maxColumns = 3,
		-- The view: 'onebag', 'multibag', 'compact' (the original) or 'rows'.
		view = 'compact',
		-- Free bag slots shown as empty slots: 'off', 'grouped' (one slot with its
		-- free count: per kind of bag in Compact and Rows, per section in One bag
		-- and Multi bag) or 'all' (one slot per free slot). Every window has its own.
		emptySlots = 'off',
	},
	bank = {
		position = {
			point = 'TOPLEFT',
			frame = 'UIParent',
			rel_point = 'TOPLEFT',
			x_off = 200,
			y_off = -200,
		},
		perrow = 4,
		maxRows = 20,
		maxColumns = 3,
		view = 'compact',
		emptySlots = 'off',
	},
	reagent = {
		position = {
			point = 'TOPLEFT',
			frame = 'SaftUIBagsAnchor_bank',
			rel_point = 'TOPRIGHT',
			x_off = 20,
			y_off = 0,
		},
		perrow = 4,
		maxRows = 20,
		maxColumns = 3
	},
	warband = {
		position = {
			point = 'TOPLEFT',
			frame = 'SaftUIBagsAnchor_bank',
			rel_point = 'TOPRIGHT',
			x_off = 20,
			y_off = 0,
		},
		perrow = 4,
		maxRows = 20,
		maxColumns = 3,
		view = 'compact',
		emptySlots = 'off',
	},
	combinedbank = {
		position = {
			point = 'TOPLEFT',
			frame = 'UIParent',
			rel_point = 'TOPLEFT',
			x_off = 200,
			y_off = -200,
		},
		perrow = 4,
		maxRows = 20,
		maxColumns = 5,
		view = 'compact',
		emptySlots = 'off',
	}
}