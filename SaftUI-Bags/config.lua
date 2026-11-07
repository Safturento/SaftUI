local st = SaftUI

st.defaults.inventory = {
	enable = true,
	compact = true, -- re-order categories to take up the least amount of space
	buttontemplate = 'thicktransparent',
	template = 'thicktransparent',
	padding = 10,
	buttonheight = 50,
	buttonwidth = 60,
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
		maxColumns = 3
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