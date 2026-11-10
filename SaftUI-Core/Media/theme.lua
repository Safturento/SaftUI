local st = SaftUI

-- The Theme tab of Global Settings: Thick or Thin, the chosen theme's colors,
-- Transparent background and Opacity (the engine is SaftUI-Core/theme.lua).
-- Each row reads st.config.profile at call time, so a profile switch reaches
-- the new profile's tables.
local TH = st:NewModule('Theme')

local NAMES = { thick = 'Thick', thin = 'Thin' }
local COLORS = { 'bordercolor', 'altbordercolor', 'backdropcolor' }

-- After the theme or the Transparent background toggle changed: the profile
-- update a profile switch runs (Config:UpdateConfig), which draws every themed
-- frame again, has every module lay itself out again (the border's width moves
-- what sits inside it), and tells them the theme's colors changed. Redrawing
-- touches frames that may be protected, so in combat it waits for the end of
-- it, once however many changes were made.
function st:ThemeChanged()
	if st:QueueAfterCombat('ThemeChanged', function() st:ThemeChanged() end) then return end
	st.Config:UpdateConfig()
end

-- After a theme color or the opacity changed: the same wait for combat.
local function Recolor()
	if st:QueueAfterCombat('ThemeRecolor', function() st:RecolorThemed() end) then return end
	st:RecolorThemed()
end

local function Theme() return st.config.profile.theme end
local function Colors() return st.config.profile.templates[Theme().name] end

-- A color row for one of the chosen theme's three colors. It's written into
-- the theme's array in place, with the array's own alpha left alone.
local function ColorRow(order, name, key, desc, hidden)
	return {
		type = 'color',
		size = 'small',
		order = order,
		name = name,
		desc = desc,
		hidden = hidden,
		get = function()
			local c = Colors()[key]
			return c[1], c[2], c[3]
		end,
		set = function(_, r, g, b)
			local c = Colors()[key]
			c[1], c[2], c[3] = r, g, b
			Recolor()
		end,
	}
end

local function NotThick() return Theme().name ~= 'thick' end

function TH:GetConfigTable()
	return {
		type = 'group',
		name = 'Theme',
		order = 4,
		args = {
			theme = {
				type = 'select',
				order = 1,
				name = 'Theme',
				desc = "How SaftUI's frames are drawn: Thick has a dark line on each side of its border, Thin just the border. A module can use another theme or none in its own settings. Each theme keeps its own colors.",
				values = NAMES,
				get = function() return Theme().name end,
				set = function(_, value)
					Theme().name = value
					st:ThemeChanged()
				end,
			},
			border = ColorRow(2, 'Border', 'bordercolor',
				"The line around SaftUI's frames, and the fill of the title and bottom bars of windows, in the chosen theme."),
			outer = ColorRow(3, 'Outer border', 'altbordercolor',
				"The dark lines on either side of a Thick frame's border.", NotThick),
			background = ColorRow(4, 'Background', 'backdropcolor',
				"The fill of SaftUI's frames in the chosen theme. How see-through it is is set by Transparent background and Opacity."),
			transparent = {
				type = 'toggle',
				size = 'small',
				order = 5,
				name = 'Transparent background',
				desc = "Makes the background of SaftUI's frames see-through, at the Opacity below. A module can set its own background.",
				get = function() return Theme().transparent end,
				set = function(_, value)
					Theme().transparent = value
					st:ThemeChanged()
				end,
			},
			opacity = {
				type = 'range',
				order = 6,
				name = 'Opacity',
				desc = 'How solid the background is while Transparent background is on: 0% shows everything behind it, 100% none of it.',
				min = 0, max = 1, step = 0.05,
				isPercent = true,
				disabled = function() return not Theme().transparent end,
				get = function() return Theme().opacity end,
				set = function(_, value)
					Theme().opacity = value
					Recolor()
				end,
			},
			reset = {
				type = 'execute',
				size = 'small',
				order = 7,
				name = 'Reset',
				desc = "Puts the chosen theme's colors, Transparent background and Opacity back to SaftUI's default.",
				confirm = function()
					return ("Reset the %s theme to SaftUI's defaults?"):format(NAMES[Theme().name])
				end,
				func = function()
					local name = Theme().name
					local from, to = st.defaults.templates[name], Colors()
					for _, key in ipairs(COLORS) do
						for i, v in ipairs(from[key]) do to[key][i] = v end
					end
					Theme().transparent = st.defaults.theme.transparent
					Theme().opacity = st.defaults.theme.opacity
					st:ThemeChanged()
				end,
			},
		},
	}
end
