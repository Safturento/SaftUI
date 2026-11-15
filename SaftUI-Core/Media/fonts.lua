local st = SaftUI

local FN = st:NewModule('Fonts')

FN.font_objects = {}

FN.outlines = {
	NONE = 'None',
	OUTLINE = 'Outline',
	THICKOUTLINE = 'Thick Outline',
	MONOCHROME = 'Monochrome',
	MONOCHROMEOUTLINE = 'Monochrome Outline',
	MONOCHROMETHICKOUTLINE = 'Monochrome Thick Outline',
}

-- The font flag for a saved outline key (an FN.outlines key): 'NONE' and nil
-- are no flags, so SetFont takes the result; any other key is its own flag.
function st.OutlineFlag(outline)
	if not outline or outline == 'NONE' then return '' end
	return outline
end

-- The shared fonts: the order of the Fonts tab and of every list of fonts, and
-- the one place their names and jobs are written (a profile's saved name is
-- ignored, so two can never ask CreateFont for one name). Each has a font
-- object, SaftUI_<key>Font, and a profile entry, st.config.profile.fonts[key],
-- over st.defaults.fonts[key]. A job is the note on the font's section of the
-- Fonts tab.
FN.FONTS = {
	{ key = 'normal', name = 'Text',
		job = "Most readable text: unit frame names and values, tooltips, chat, the loot feed and rolls, the trackers' quests, window titles, check box labels; and the face of /sui's labels and fields" },
	{ key = 'pixel', name = 'Small text',
		job = "Small numbers and labels on buttons, icons and bars: counts, item levels, cast bar text, chat tabs, the micro menu, edit mode's labels" },
	{ key = 'pixel_med', name = 'Large numbers',
		job = "Cooldown numbers on buttons 36 pixels and larger, and the player's mana text" },
	{ key = 'heading', name = 'Heading',
		job = "Headings: the bags' category titles, SaftUI's tracker's header and zone headers; and the face of /sui's titles" },
	{ key = 'title', name = 'Huge title',
		job = 'The zone name, as you enter a zone' },
	{ key = 'subtitle', name = 'Subtitle',
		job = 'The lines under the zone name' },
}

local BY_KEY = {}
for _, entry in ipairs(FN.FONTS) do BY_KEY[entry.key] = entry end

-- The shared font with this key, or nil (for a dropped key, an unknown one and
-- anything that isn't a key).
function FN:Font(key)
	if type(key) ~= 'string' then return nil end
	return BY_KEY[key]
end

-- Fonts that were shared fonts once, and that a profile may still name from a
-- font row. Such a value reads as the typeface it looked like: this look, with
-- whatever the profile saved under fonts.<key> over it. Nothing reads them but
-- that, and nothing writes them.
FN.DROPPED = {
	pixel_huge = { font_name = 'Homespun', font_size = 32, font_outline = 'MONOCHROMEOUTLINE', shadow_offset = { 0, 0 }, spacing = 4 },
	normal_med = { font_name = 'AgencyFB Bold', font_size = 24, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 },
}

local function IsNumber(n) return type(n) == 'number' and n == n end

-- A font setting's look, whichever of its two shapes it holds: a key of a
-- shared font (a string) or a typeface (a table of a shared font's fields).
-- Returns font_name, font_size, font_outline, shadow X, shadow Y and spacing,
-- and builds no table, so a reader on a hot path (a tooltip line, a unit frame
-- update) costs no garbage. A field the setting has that isn't valid (a wrong
-- type, an unknown outline) reads as the base's, and a number is held to the
-- range of the row that sets it. The shadow is read per axis: AceDB saves only
-- the axis that differs from a default, so a dropped font's saved
-- shadow_offset may hold one number.
--   a shared font's key: its default, with the profile's fonts[key] over it;
--   a dropped key: its old look, with the profile's fonts[key] over it;
--   a table: Text's default, with the table over it;
--   anything else (nil, an unknown key, a number): Text, as the profile has it.
local function Resolve(value)
	local defaults, profile = st.defaults.fonts, st.config.profile.fonts
	local base, overlay
	if type(value) == 'string' and BY_KEY[value] then
		base, overlay = defaults[value], profile[value]
	elseif type(value) == 'string' and FN.DROPPED[value] then
		base, overlay = FN.DROPPED[value], rawget(profile, value)
	elseif type(value) == 'table' then
		base, overlay = defaults.normal, value
	else
		base, overlay = defaults.normal, profile.normal
	end
	if type(overlay) ~= 'table' then overlay = base end

	local name = overlay.font_name
	if type(name) ~= 'string' or name == '' then name = base.font_name end
	local size = overlay.font_size
	if IsNumber(size) then size = st.Clamp(size, 1, 100) else size = base.font_size end
	local outline = overlay.font_outline
	if type(outline) ~= 'string' or not FN.outlines[outline] then outline = base.font_outline end
	local shadow, x, y = overlay.shadow_offset, base.shadow_offset[1], base.shadow_offset[2]
	if type(shadow) == 'table' then
		-- + 0 turns a negative zero into 0, so -0 and 0 are one look.
		if IsNumber(shadow[1]) then x = st.Clamp(shadow[1], -5, 5) + 0 end
		if IsNumber(shadow[2]) then y = st.Clamp(shadow[2], -5, 5) + 0 end
	end
	local spacing = overlay.spacing
	if IsNumber(spacing) then spacing = st.Clamp(spacing, 0, 20) else spacing = base.spacing end
	return name, size, outline, x, y, spacing
end

-- The same as a table, for a caller that wants one (the dots menu, a font
-- object's setter): { font_name, font_size, font_outline, shadow_offset =
-- { x, y }, spacing }. A fresh table every call, never written to the profile.
function st:FontFields(value)
	local name, size, outline, x, y, spacing = Resolve(value)
	return { font_name = name, font_size = size, font_outline = outline, shadow_offset = { x, y }, spacing = spacing }
end

-- Sets a font object to a look (st:FontFields' shape): the face from
-- LibSharedMedia (its default face when it doesn't list the name), size,
-- outline, an opaque black shadow, the shadow's offset, line spacing. The one
-- routine for a shared font's object and a typeface's.
function FN:SetObject(object, fields)
	local path = st.LSM:Fetch('font', fields.font_name)
	local size = fields.font_size
	-- The saved key NONE is no flags at all; SetFont takes '' for that.
	local flags = st.OutlineFlag(fields.font_outline)

	object:SetFont(path, size, flags)
	-- Opaque black, so a shadow offset shows: a font object's own shadow color
	-- may be clear. At offset 0, 0 the shadow sits behind the letters, unseen.
	object:SetShadowColor(0, 0, 0, 1)
	object:SetShadowOffset(fields.shadow_offset[1], fields.shadow_offset[2])
	object:SetSpacing(fields.spacing)
	-- The game measures a text when it's laid out, and a font's shadow or line
	-- spacing changing doesn't measure the texts using it again: a shadow pushed
	-- right cut their last letters off until a reload. A size change does, so
	-- the size goes up by one and straight back (checked in game: no flicker).
	object:SetFont(path, size + 1, flags)
	object:SetFont(path, size, flags)
end

-- SaftUI's own faces (st.SAFTUI_FACES, Media/sharedmedia.lua), each set once
-- on a font object of its own, here, while the addon loads. The game only draws
-- a font file reliably once a font object has been set to it at load (the font
-- demo found a font string's own SetFont failing for a file not loaded yet), and
-- every text SaftUI draws takes its font from a font object: so a typeface
-- picked mid-session draws at once. Another addon's faces are not preloaded
-- (the in-game check G1 says whether they need to be).
FN.preloaded = {}
for i, name in ipairs(st.SAFTUI_FACES or {}) do
	local object = CreateFont('SaftUI_Preload' .. i .. 'Font')
	object:SetFont(st.LSM:Fetch('font', name), 12, '')
	FN.preloaded[name] = object
end

-- Heading's face, once per profile (the Settled 3 of the fonts design). Heading
-- is new; /sui's titles took Huge title's face until it, so a profile that
-- holds a changed face on Huge title gives it to Heading, as long as Heading's
-- own is still its default. Only the face moves. It runs while fonts.version is
-- nil, then marks the profile (version 1; no default, so a reset profile is
-- unmarked again and takes the step on its next load). A profile switched to,
-- copied, reset or imported runs it in FN:UpdateConfig. Returns whether it ran.
-- It writes the profile's tables only, so it is safe in combat. It is
-- independent of the colors' migration (st:MigrateColors), which Config runs
-- before the Fonts module's update.
function FN:ConvertHeadingFace()
	local profile = st.config.profile.fonts
	if profile.version ~= nil then return false end
	local defaults = st.defaults.fonts
	local title, heading = profile.title, profile.heading
	if type(title) == 'table' and type(heading) == 'table'
		and type(title.font_name) == 'string' and title.font_name ~= defaults.title.font_name
		and heading.font_name == defaults.heading.font_name then
		heading.font_name = title.font_name
	end
	profile.version = 1
	return true
end

function FN:OnEnable()
	-- In xpcall, as the colors' migration is at login: a step that fails is
	-- reported and the objects are still set.
	xpcall(self.ConvertHeadingFace, geterrorhandler(), self)
	self:UpdateFontConfig()
end

-- A profile change. Font objects are shared, so re-applying them updates every
-- font string set to one; nothing else has to be touched. The face step is
-- first, so the objects are set from the profile it has settled.
function FN:UpdateConfig()
	-- In xpcall, as in OnEnable: a step that fails is reported and the objects
	-- are still set.
	xpcall(self.ConvertHeadingFace, geterrorhandler(), self)
	self:UpdateFontConfig()
end

-- Applies a shared font's profile settings to its font object, creating the
-- object the first time. With no key, does every shared font (FN.FONTS, never
-- the profile's fonts table, which may hold a dropped font's saved edits).
function FN:UpdateFontConfig(key)
	if key == nil then
		for _, entry in ipairs(self.FONTS) do
			self:UpdateFontConfig(entry.key)
		end
		return
	end
	if not BY_KEY[key] then return end

	local font = self.font_objects[key]
	if not font then
		font = CreateFont('SaftUI_' .. key .. 'Font')
		font:SetTextColor(1, 1, 1)
		self.font_objects[key] = font
	end
	self:SetObject(font, st:FontFields(key))
end

-- One font object per typeface look (a table, or a dropped key), made the first
-- time the look is asked for: SaftUI_Typeface<n>Font, white like the shared
-- fonts (so SetFontObject keeps giving texts white), set once and never again.
-- The look is its resolved fields and the file the face fetches (so a face
-- another addon registers after the first ask is a new look, and the next
-- ask gets an object that draws it; a reader that wants it at once runs
-- st:FontsChanged from LibSharedMedia's registration callback). A look already
-- seen costs no garbage: the key is one concatenation, which Lua interns.
-- The game can't free a font object, so they last the session. A Size slider
-- dragged across its range makes at most one object per whole size (100) for
-- each face, outline, shadow and spacing it is dragged at, and the same one
-- again when it comes back.
local typefaces, typefaceCount = {}, 0
local function Typeface(value)
	local name, size, outline, x, y, spacing = Resolve(value)
	local path = st.LSM:Fetch('font', name)
	local key = path .. '\31' .. size .. '\31' .. outline .. '\31' .. x .. '\31' .. y .. '\31' .. spacing
	local object = typefaces[key]
	if not object then
		typefaceCount = typefaceCount + 1
		object = CreateFont('SaftUI_Typeface' .. typefaceCount .. 'Font')
		object:SetTextColor(1, 1, 1)
		FN:SetObject(object, { font_name = name, font_size = size, font_outline = outline, shadow_offset = { x, y }, spacing = spacing })
		typefaces[key] = object
	end
	return object
end

-- The font object for a font setting: a shared key's object; for a dropped key
-- or a typeface table, the typeface object of its look; for anything else, nil
-- (so code that falls back with `or st:GetFont('normal')` still works).
function st:GetFont(value)
	if type(value) == 'string' then
		if BY_KEY[value] then return FN.font_objects[value] end
		if FN.DROPPED[value] then return Typeface(value) end
		return nil
	end
	if type(value) == 'table' then return Typeface(value) end
	return nil
end

-- The font object for a setting, Text's when the setting names nothing.
function st:FontObject(value)
	return st:GetFont(value) or FN.font_objects.normal
end

-- How every reader puts a font setting on a text: its font object, and nothing
-- else (never SetFont, which SetFontObject doesn't undo in game). A value that
-- names nothing draws Text. No skip when the text already has the object: a
-- caller that sets a color of its own puts it back after.
function st:ApplyFont(fontString, value)
	fontString:SetFontObject(st:FontObject(value))
end

-- For a reader that takes values, not an object: path, size, flags, shadow X,
-- shadow Y and spacing of a font setting.
function st:FontValues(value)
	local name, size, outline, x, y, spacing = Resolve(value)
	return st.LSM:Fetch('font', name), size, st.OutlineFlag(outline), x, y, spacing
end

-- The words for a font setting: a shared font's name ("Heading"), a typeface as
-- "Colus 15, outline" ("Homespun 10" with no outline), anything else "Text".
function st:FontLabel(value)
	if type(value) == 'string' and BY_KEY[value] then return BY_KEY[value].name end
	if type(value) == 'table' or (type(value) == 'string' and FN.DROPPED[value]) then
		local fields = st:FontFields(value)
		local label = fields.font_name .. ' ' .. fields.font_size
		if fields.font_outline ~= 'NONE' then
			label = label .. ', ' .. FN.outlines[fields.font_outline]:lower()
		end
		return label
	end
	return BY_KEY.normal.name
end

-- Whether a setting is a shared font's key. A dropped key is a typeface.
function st:IsSharedFont(value)
	return type(value) == 'string' and BY_KEY[value] ~= nil
end

-- A font setting from a font, size and outline that are saved apart (the action
-- bars' and buffs' texts): the font's key when it is a shared font, else a
-- typeface table of the face, size and outline.
function st:FaceFont(font, size, outline)
	if st:IsSharedFont(font) then return font end
	return { font_name = font, font_size = size, font_outline = outline }
end

-- Texts with no module to apply them again when a font setting changes, kept
-- weakly: region -> the function that gives the setting's value now. Weak keys
-- do not free a frame's regions in the game, so a pool that releases a region
-- must call st:UnfollowFont(region) (or st:FollowFont(region, nil)) then, else
-- the next change puts the old setting's font on a region reused for something
-- else. A getter must not close over its own region either (Lua 5.1 has no
-- ephemerons: the entry would keep the region alive).
local followers = setmetatable({}, { __mode = 'k' })

-- Puts getValue()'s font on the region now, and again on every
-- st:RefollowFonts. A region kept twice keeps the last getter; a nil getValue
-- forgets the region. A getter that errors on this first apply is not kept.
function st:FollowFont(region, getValue)
	if getValue then
		st:ApplyFont(region, getValue())
		followers[region] = getValue
	else
		followers[region] = nil
	end
end

-- Forgets a region (a pool releasing it).
function st:UnfollowFont(region)
	followers[region] = nil
end

-- Every kept region again, reading its getter now. One that errors is reported
-- (xpcall) and the rest still follow.
function st:RefollowFonts()
	local regions = {}
	for region, getValue in pairs(followers) do regions[#regions + 1] = { region, getValue } end
	for _, kept in ipairs(regions) do
		xpcall(function() st:ApplyFont(kept[1], kept[2]()) end, geterrorhandler())
	end
end

-- A font setting or a shared font changed (the Fonts tab, a profile update):
-- the kept texts again, then every module's OnFontsChanged() for what only
-- takes values or lays out around a font (in xpcall, as st:ColorsChanged runs
-- OnColorsChanged, so one that errors doesn't stop the rest). A module whose
-- OnFontsChanged reads a profile it converts runs its conversion first: the
-- profile update calls this before the modules' UpdateConfig.
function st:FontsChanged()
	st:RefollowFonts()
	for _, module in pairs(st.modules) do
		if module.OnFontsChanged then
			xpcall(module.OnFontsChanged, geterrorhandler(), module)
		end
	end
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
		st:FontsChanged()
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

local TEXT_FONTS_NOTE = 'Window titles change at once. The rest is read when SaftUI builds its frames: reload (Reload UI, bottom right) to see a change everywhere.'

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
			st:FontsChanged()
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
			st:FontsChanged()
		end,
		get = function(info)
			return st.config.profile.fonts[info[#info-1]][info[#info]]
		end,
		args = {
			kinds = TextFontsGroup(),
		}
	}


	-- One section per shared font, in FN.FONTS order (after the Kinds of text
	-- section's order 1), named from code.
	for i, entry in ipairs(self.FONTS) do
		config.args[entry.key] = {
			name = entry.name,
			order = i + 1,
			type = 'group',
			inline = true,
			args = {
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