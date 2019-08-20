local ADDON_NAME, st = ...

st.defaults = {
	unitframes = {
		config_unit = 'player',
		config_element = 'general',
		units = {
			['**'] = {
				enable = true,
				width = 200,
				height = 20,
				position = {'CENTER', 'UIParent', 'CENTER',  0, 0},
				range_alpha = {
					inside = 1,
					outside = 0.3,
				},
				['**'] = {
					enable = true,
					relative_width = true,
					width = 0,
					relative_height = true,
					height = 0,
					position = {'CENTER'},
					framelevel = 0,
				},
				health = {
					Smooth = true,
					colorTapping = true,
					colorDisconnected = true,
					colorHealth = false,
					colorClass = true,
					colorClassNPC = false,
					colorClassPet = false,
					colorReaction = true,
					colorSmooth = false,
					colorCustom = false,
					customColor = { 0.25, 0.25, 0.25},
				},
				power = {
					Smooth = true,
					colorTapping = true,
					colorDisconnected = true,
					colorHealth = false,
					colorClass = true,
					colorClassNPC = false,
					colorClassPet = false,
					colorReaction = true,
					colorSmooth = false,
					colorCustom = false,
					customColor = { 0.25, 0.25, 0.25},
				},
			},
			player = {
				position = {'RIGHT', 'UIParent', 'CENTER', -100, -200},
			},
			target = {
				position = {'LEFT', 'UIParent', 'CENTER', 100, -200},
			},
			targettarget = {
				width = 100,
				position = {'LEFT', 'SaftUI_Target', 'RIGHT', 6, 0},
			}
		}
	}
}