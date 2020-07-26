local ADDON_NAME, st = ...

st.defaults.auras = {
	enable = true,
	size = 30,
	font = 'pixel',
	template = 'thick',
	spacing = 8,
	timer_text = {
		enable = true,
		position = {'TOP', 'BOTTOM', 0, -6},
	},
	timer_bar = {
		enable = false,
		template = 'thick',
		position = {'TOP', 'BOTTOM', 0, -7},
		width = 30,
		height = 3,
		color_time = true,
		custom_color = { 0.16, 0.51, 0.91 },
	},
	buffs = {
		growth_direction = 'LEFT',
		position = {'TOPRIGHT', 'Minimap', 'TOPLEFT', -20, 0},
	},
	debuffs = {
		growth_direction = 'LEFT',
		position = {'BOTTOMRIGHT', 'Minimap', 'BOTTOMLEFT', -20, 0},
	}
}
