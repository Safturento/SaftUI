local st = SaftUI

local FN = st:NewModule('Fonts')

FN.font_objects = {}

FN.outlines = {
	NONE = st.retail and '' or 'NONE',
	OUTLINE = 'Outline',
	THICKOUTLINE = 'Thick Outline',
	MONOCHROME = 'Monochrome',
	MONOCHROMEOUTLINE = 'Monochrome Outline',
	MONOCHROMETHICKOUTLINE = 'Monochrome Thick Outine',
}

function FN:OnEnable()
	self:UpdateFontConfig()
end

-- A profile change. Font objects are shared, so re-applying them updates every
-- font string set to one; nothing else has to be touched.
function FN:UpdateConfig()
	self:UpdateFontConfig()
end

-- Applies a font's profile settings to its font object, creating the object
-- the first time. With no font_name, does every font in the profile.
function FN:UpdateFontConfig(font_name)
	if not font_name then
		for key, config in pairs(st.config.profile.fonts) do
			self:UpdateFontConfig(key)
		end
		return 
	end

	local config = st.config.profile.fonts[font_name]
	local font = self.font_objects[font_name]
	if not font then
		font = CreateFont('SaftUI_'..config.name..'Font')
		font:SetTextColor(1, 1, 1)
		self.font_objects[font_name] = font
	end

	font:SetFont(
		st.LSM:Fetch('font', config.font_name),
		config.font_size,
		config.font_outline
	)
	-- Opaque black, so a shadow offset shows: a font object's own shadow color
	-- may be clear. At offset 0, 0 the shadow sits behind the letters, unseen.
	font:SetShadowColor(0, 0, 0, 1)
	font:SetShadowOffset(unpack(config.shadow_offset))
	font:SetSpacing(config.spacing)
	-- The game measures a text when it's laid out, and a font's shadow or line
	-- spacing changing doesn't measure the texts using it again: a shadow pushed
	-- right cut their last letters off until a reload. A size change does, so
	-- the size goes up by one and straight back (checked in game: no flicker).
	local path = st.LSM:Fetch('font', config.font_name)
	font:SetFont(path, config.font_size + 1, config.font_outline)
	font:SetFont(path, config.font_size, config.font_outline)
end

function st:GetFont(font_name)
	return FN.font_objects[font_name]
end

-- Shadow offset X (index 1) or Y (index 2) of the font whose section the row
-- is in: one of the two numbers in its shadow_offset. The font object takes it
-- at once, and so does every text set to it that doesn't set its own.
local function ShadowOffset(order, index, name, desc)
	local option = st.Config.generators.range(order, name, -5, 5, 1, desc)
	option.get = function(info)
		return st.config.profile.fonts[info[#info-1]].shadow_offset[index]
	end
	option.set = function(info, value)
		local font_key = info[#info-1]
		st.config.profile.fonts[font_key].shadow_offset[index] = value
		FN:UpdateFontConfig(font_key)
	end
	return option
end

-- The Kinds of text section: which font each kind of text uses, as
-- { row key, profile key, name, desc, apply }. A row reads and writes
-- st.config.profile[profile key].font. Only window titles can be re-applied
-- (st:UpdateHeader); the others are set when their frames are built.
local TEXT_FONTS = {
	{ 'window_titles', 'headers', 'Window titles',
		"The titles of SaftUI's windows (the bags and bank), which change at once, and the bags' gold and free-slot text along their bottom, which changes on a reload.",
		function() st:UpdateHeader() end },
	{ 'button_text', 'buttons', 'Button text',
		"The text on the totem bar's buttons (key bindings, counts and names) and its totem timers." },
	{ 'checkbox_labels', 'panels', 'Check box labels',
		"The labels of SaftUI's check boxes, such as the bags' filters." },
}

local TEXT_FONTS_NOTE = 'Window titles change at once. The rest is read when SaftUI builds its frames: reload (Reload UI, bottom left) to see a change everywhere.'

local function TextFontsGroup()
	local args = {}
	for i, entry in ipairs(TEXT_FONTS) do
		local key, profile_key, name, desc, apply = unpack(entry)
		local option = st.Config.generators.font(i, desc)
		option.name = name
		option.get = function() return st.config.profile[profile_key].font end
		option.set = function(_, value)
			st.config.profile[profile_key].font = value
			if apply then apply() end
		end
		args[key] = option
	end
	return {
		type = 'group',
		inline = true,
		order = 1,
		name = 'Kinds of text',
		desc = TEXT_FONTS_NOTE,
		args = args,
	}
end

function FN:GetConfigTable()
	local config = {
		order = 1,
		type = 'group',
		name = 'Fonts',
		-- childGroups = 'select',
		set = function(info, value)
			st.config.profile.fonts[info[#info-1]][info[#info]] = value
			self:UpdateFontConfig(info[#info-1])
		end,
		get = function(info)
			return st.config.profile.fonts[info[#info-1]][info[#info]]
		end,
		args = {
			kinds = TextFontsGroup(),
		}
	}


	for font_key, font_object in pairs(self.font_objects) do
		config.args[font_key] = {
			name = st.config.profile.fonts[font_key].name,
			type = 'group',
			inline = true,
			args = {
				name = {
					order = 1,
					name = 'Name',
					desc = "What this font is called in the Font lists of SaftUI's settings.",
					type = 'input',
				},
				font_name = {
					order = 2,
					type = 'select',
					dialogControl = 'LSM30_Font',
					name = 'Font Name',
					desc = 'The typeface of every text that uses this font.',
					values = st.LSM:HashTable("font"),
				},
				font_size = st.Config.generators.range(3, 'Font Size', 1, 100, 1,
					'How big every text that uses this font is.'),
				font_outline = {
					order = 4,
					type = 'select',
					name = 'Font Outline',
					desc = 'The outline around the letters of every text that uses this font.',
					values = FN.outlines,
				},
				shadow_x = ShadowOffset(5, 1, 'Shadow offset X',
					'How far right of the letters the shadow of every text that uses this font falls, in pixels; below 0, to the left. With X and Y both 0 the shadow sits behind the letters.'),
				shadow_y = ShadowOffset(6, 2, 'Shadow offset Y',
					'How far above the letters the shadow of every text that uses this font falls, in pixels; below 0, below them.'),
				spacing = st.Config.generators.range(7, 'Line spacing', 0, 20, 1,
					'The gap, in pixels, between the lines of every text that uses this font, when it runs to more than one line.'),
			},
		}
	end

	return config
end