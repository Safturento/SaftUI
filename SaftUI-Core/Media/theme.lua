local st = SaftUI

-- The Theme tab of Global settings: Thick, Thin or Blizzard and the chosen theme's
-- colors, the Background's opacity among them (the engine is SaftUI-Core/theme.lua).
-- Each color has its own reset by its swatch while it differs from the chosen
-- theme's default (the options kit's default field; no Reset for the tab).
-- Each row reads st.config.profile at call time, so a profile switch reaches
-- the new profile's tables.
local TH = st:NewModule('Theme')

local NAMES = { thick = 'Thick', thin = 'Thin', blizzard = 'Blizzard' }
local SORTING = { 'thick', 'thin', 'blizzard' }

-- After the theme or whether the background is see-through changed: the profile
-- update a profile switch runs (Config:UpdateConfig), which draws every themed
-- frame again, has every module lay itself out again (the border's width moves
-- what sits inside it), and tells them the theme's colors changed. Redrawing
-- touches frames that may be protected, so in combat it waits for the end of
-- it, once however many changes were made.
function st:ThemeChanged()
	if st:QueueAfterCombat('ThemeChanged', function() st:ThemeChanged() end) then return end
	st.Config:UpdateConfig()
end

-- After a theme color or the background's opacity changed: the same wait for combat.
local function Recolor()
	if st:QueueAfterCombat('ThemeRecolor', function() st:RecolorThemed() end) then return end
	st:RecolorThemed()
end

local function Theme() return st.config.profile.theme end
-- The theme frames are drawn in: the saved one, or Thick for a name this
-- version doesn't know (a later version's), which st:ResolveTheme draws as
-- Thick. The saved name stays until the user picks a theme.
local function Name() return st:ResolveTheme().name end
local function Colors() return st.config.profile.templates[Name()] end
-- The chosen theme's defaults (Thick's and Thin's have no windowcolor).
local function Defaults() return st.defaults.templates[Name()] end

-- Whether two colors' r, g and b look the same on the tab: each a whole 0-255.
local function SameRgb(a, b)
	for i = 1, 3 do
		if math.floor((a[i] or 0) * 255 + 0.5) ~= math.floor((b[i] or 0) * 255 + 0.5) then return false end
	end
	return true
end

-- A color row for one of the chosen theme's colors. It's written into
-- the theme's array in place, with the array's own alpha left alone. Its
-- reset puts the theme's default back into the array, alpha too, as the
-- tab's Reset did, and recolors as a set does.
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
		default = {
			differs = function()
				local d = Defaults()[key]
				return d ~= nil and not SameRgb(Colors()[key], d)
			end,
			reset = function()
				local c, d = Colors()[key], Defaults()[key]
				if not d then return end
				for i, v in ipairs(d) do c[i] = v end
				Recolor()
			end,
			value = function()
				local d = Defaults()[key]
				if d then return d[1], d[2], d[3] end
			end,
		},
	}
end

-- The Background color, with the opacity every theme shares. The profile saves
-- that opacity as theme.transparent (see-through or solid) and theme.opacity,
-- as it did when they were a toggle and a slider, so a saved profile reads and
-- draws as before: an alpha of 100% is a solid background, under it a
-- see-through one at that opacity (the opacity kept while it's solid, so
-- going back to see-through returns to it).
local function BackgroundAlpha()
	local theme = Theme()
	return theme.transparent and theme.opacity or 1
end

-- After the background's transparency changed from wasTransparent: solid
-- or see-through moves borders (a redraw); an opacity only recolors.
local function BackgroundChanged(wasTransparent)
	if (Theme().transparent and true or false) ~= (wasTransparent and true or false) then
		st:ThemeChanged()
	else
		Recolor()
	end
end

local function SetBackgroundAlpha(alpha)
	local theme = Theme()
	local wasTransparent = theme.transparent
	if alpha >= 1 then
		theme.transparent = false
	else
		theme.transparent = true
		theme.opacity = alpha
	end
	BackgroundChanged(wasTransparent)
end

-- The Background's default alpha: the shipped transparency and opacity.
local function DefaultAlpha()
	local theme = st.defaults.theme
	return theme.transparent and theme.opacity or 1
end

local function NotThick() return Name() ~= 'thick' end
local function NotBlizzard() return Name() ~= 'blizzard' end

-- A desc that says what the row colors in the chosen theme: Blizzard's rows
-- color different things than Thick's and Thin's.
local function ByTheme(blizzard, other)
	return function() return Name() == 'blizzard' and blizzard or other end
end

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
				desc = "How SaftUI's frames are drawn: Thick has a dark line on each side of its border, Thin just the border. Blizzard draws them in Blizzard's own art. A module can use another theme or none in its own settings. Each theme keeps its own colors.",
				values = NAMES,
				sorting = SORTING,
				get = function() return Name() end,
				set = function(_, value)
					Theme().name = value
					st:ThemeChanged()
				end,
			},
			border = ColorRow(2, 'Border', 'bordercolor',
				ByTheme("The line around the few small frames that have no Blizzard art. The art keeps Blizzard's own colors.",
					"The line around SaftUI's frames, and the fill of the title and bottom bars of windows, in the chosen theme.")),
			outer = ColorRow(3, 'Outer border', 'altbordercolor',
				"The dark lines on either side of a Thick frame's border.", NotThick),
			windowcolor = ColorRow(4, 'Window background', 'windowcolor',
				"The fill of SaftUI's windows in Blizzard's theme. How see-through it is is set by Background's opacity.",
				NotBlizzard),
			background = {
				type = 'color',
				size = 'small',
				order = 5,
				name = 'Background',
				desc = ByTheme("The fill of everything that isn't a window in Blizzard's theme, and how see-through the fills are: 100% is solid, less shows what is behind. A module can set its own background.",
					"The fill of SaftUI's frames in the chosen theme, and how see-through the fills are: 100% is solid, less shows what is behind. A module can set its own background."),
				hasAlpha = true,
				get = function()
					local c = Colors().backdropcolor
					return c[1], c[2], c[3], BackgroundAlpha()
				end,
				set = function(_, r, g, b, a)
					local c = Colors().backdropcolor
					c[1], c[2], c[3] = r, g, b
					if a == nil then
						Recolor()
					else
						SetBackgroundAlpha(a)
					end
				end,
				-- Its color and its opacity: either differing shows the reset,
				-- which puts back both, the shipped transparency with the opacity.
				default = {
					differs = function()
						return not SameRgb(Colors().backdropcolor, Defaults().backdropcolor)
							or math.floor(BackgroundAlpha() * 100 + 0.5) ~= math.floor(DefaultAlpha() * 100 + 0.5)
					end,
					reset = function()
						local c = Colors().backdropcolor
						for i, v in ipairs(Defaults().backdropcolor) do c[i] = v end
						local theme = Theme()
						local wasTransparent = theme.transparent
						theme.transparent, theme.opacity = st.defaults.theme.transparent, st.defaults.theme.opacity
						BackgroundChanged(wasTransparent)
					end,
					value = function()
						local d = Defaults().backdropcolor
						return d[1], d[2], d[3], DefaultAlpha()
					end,
				},
			},
		},
	}
end
