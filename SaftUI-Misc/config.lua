local st = SaftUI

st.defaults.actionbars = {
	font = 'pixel',
	hide_empty = true,

	['**'] = {
		enable = true,
		template = 'thicktransparent',
		spacing = 7,
		height = 20,
		width = 30,
		alpha = 1,
		ooc_alpha = 1,
		total = 12,
		perrow = 12,
		backdrop = {
			enable = false,
			conform = true,
			template = 'thick',
			width = 12,
			height = 1,
			padding = 6,
			anchor = 'BOTTOMLEFT',
		}
	},
	bar1 = {
		total = 10,
		position = {point = 'BOTTOM', frame = 'UIParent', rel_point = 'BOTTOM', x_off = 0, y_off = st.CLAMP_INSET },
		backdrop = {
			-- enable = true,
			height = 3,
			conform = false,
		}
	},
	bar2 = {
		total = 10,
		position = { point = 'BOTTOM', frame = st.name ..'ActionBar1', rel_point = 'TOP', x_off = 0, y_off = 7},
	},
	bar3 = {
		total = 10,
		position = { point = 'BOTTOM', frame = st.name ..'ActionBar2', rel_point = 'TOP', x_off = 0, y_off = 7},
	},
	bar4 = {
		position = {point = 'RIGHT', frame = 'UIParent', rel_point = 'RIGHT', x_off = -st.CLAMP_INSET, y_off = 0},
		perrow = 1,
	},
	bar5 = {
		position = { point = 'RIGHT', frame = st.name ..'ActionBar4', rel_point = 'LEFT', x_off = -7, y_off = 0},
		perrow = 1,
	},
	pet = {
		total = 10,
		perrow = 10,
		position = { point = 'BOTTOM', frame = st.name ..'ActionBar3', rel_point = 'TOP', x_off = 0, y_off = 8}
	}
}

st.defaults.tooltip = {
	template = 'thicktransparent',
	font = 'normal',
	attach_to_bags = true,
}

st.defaults.skinning = {
	font = 'pixel',
	template = 'thicktransparent',
}

-- Forever's swing timer bars (SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua).
-- Width and height are the visible bar: Blizzard's default 426x30 frame less the
-- 5/4px art inset around its StatusBar. Blizzard stacks the bars in its bottom managed
-- container, main hand on top with a 12px gap between visible bars; the chain below
-- keeps that stack. The container's spot depends on Blizzard's action bars, so the main
-- hand uses Blizzard's own out-of-container anchor (BOTTOM, UIParent, BOTTOM, 0, 450)
-- plus the 4px inset. showtitle / showtime show the bar's title and time text, and
-- opacity is the whole bar's alpha (Blizzard's range dimming multiplies with it).
st.defaults.swingtimer = {
	mainhand = {
		width = 416,
		height = 22,
		showtitle = true,
		showtime = true,
		opacity = 1,
		position = { point = 'BOTTOM', frame = 'UIParent', rel_point = 'BOTTOM', x_off = 0, y_off = 454 },
	},
	offhand = {
		width = 416,
		height = 22,
		showtitle = true,
		showtime = true,
		opacity = 1,
		position = { point = 'TOP', frame = st.name .. 'SwingTimerMainHand', rel_point = 'BOTTOM', x_off = 0, y_off = -12 },
	},
	ranged = {
		width = 416,
		height = 22,
		showtitle = true,
		showtime = true,
		opacity = 1,
		position = { point = 'TOP', frame = st.name .. 'SwingTimerOffHand', rel_point = 'BOTTOM', x_off = 0, y_off = -12 },
	},
}