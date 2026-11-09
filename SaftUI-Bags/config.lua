local st = SaftUI

st.defaults.inventory = {
	enable = true,
	buttontemplate = 'thicktransparent', -- item and currency slots
	template = 'thicktransparent', -- the windows
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
		-- Free bag slots shown as an 'Empty Slots' category: 'off', 'grouped' (one
		-- slot for the bags and one for the reagent bag, each with its free count)
		-- or 'all' (one slot per free slot). Bag window only.
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
		maxColumns = 3
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
		maxColumns = 3
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
		maxColumns = 5
	}
}