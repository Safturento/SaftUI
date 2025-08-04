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
	fonts = {
		titles = 'normal',
		icons = 'pixel',
	},
	bag = {
		position = {'BOTTOMRIGHT', -20, 20},
		perrow = 4,
		maxRows = 15,
		maxColumns = 2
	},
	bank = {
		position = {'TOPLEFT', 200, -200},
		perrow = 4,
		maxRows = 20,
		maxColumns = 3
	},
	reagent = {
		position = {'TOPLEFT', 'SaftUIBank', 'TOPRIGHT', 20, 0},
		perrow = 4,
		maxRows = 20,
		maxColumns = 3
	},
	warband = {
		position = {'TOPLEFT', 'SaftUIBank', 'TOPRIGHT', 20, 0 },
		perrow = 4,
		maxRows = 20,
		maxColumns = 3
	},
	combinedbank = {
		position = {'TOPLEFT', 200, -200},
		perrow = 4,
		maxRows = 20,
		maxColumns = 5
	}
}