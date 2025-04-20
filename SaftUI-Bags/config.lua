local st = SaftUI

st.defaults.inventory = {
	enable = true,
	compact = true, -- re-order categories to take up the least amount of space
	buttontemplate = 'thicktransparent',
	template = 'thicktransparent',
	padding = 10,
	buttonheight = 35,
	buttonwidth = 40,
	buttonspacing = 9,
	categoryspacing = 30,
	categoryTitleHeight = 17,
	autorepair = true,
	autovendor = true,
	fonts = {
		titles = 'normal',
		icons = 'pixel',
	},
	bag = {
		position = {'BOTTOMRIGHT', -20, 20},
		perrow = 4,
		maxRows = 15,
	},
	bank = {
		position = {'TOPLEFT', 200, -200},
		perrow = 5,
		maxRows = 20,
	},
	reagent = {
		position = {'TOPLEFT', 'SaftUIBank', 'TOPRIGHT', 20, 0},
		perrow = 5,
		maxRows = 20,
	},
	warband = {
		position = {'TOPLEFT', 'SaftUIBank', 'TOPRIGHT', 20, 0 },
		perrow = 5,
		maxRows = 20
	}
}