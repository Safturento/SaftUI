local st = SaftUI

st.config.profile.chat = st.tablemerge({
	position = {'BOTTOMLEFT', 'UIParent', 'BOTTOMLEFT', 30, 30},
	template = 'thicktransparent',
	font = 'normal',
	padding = 10,
	fontsize = 16,
	linespacing = 5,
	fadetabs = true,
	tabs = {
		height = 25,
		fade = false,
	},
	editbox = {
		height = 25,
	}
}, st.config.profile.chat)