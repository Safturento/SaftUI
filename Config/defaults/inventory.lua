local st = SaftUI

st.defaults.inventory = {
	enable = true,
	buttontemplate = 'thicktransparent',
	template = 'thicktransparent',
	padding = 10,
	buttonheight = 20,
	buttonwidth = 30,
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
		perrow = 8,
		maxRows = 30,
	},
	bank = {
		position = {'TOPLEFT', 200, -200},
		perrow = 10,
		maxRows = 20,
	}
}