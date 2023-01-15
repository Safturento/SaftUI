local st = SaftUI

st.defaults.inventory = {
	enable = true,
	buttontemplate = 'thicktransparent',
	template = 'thicktransparent',
	padding = 10,
	buttonheight = 40,
	buttonwidth = 40,
	buttonspacing = 7,
	categoryspacing = 10,
	autorepair = true,
	autovendor = true,
	fonts = {
		titles = 'normal',
		icons = 'pixel',
	},
	bag = {
		position = {'BOTTOMRIGHT', -20, 20},
		perrow = 5,
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
	}
}