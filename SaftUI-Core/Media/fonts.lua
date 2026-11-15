local st = SaftUI

local FN = st:NewModule('Fonts')

FN.font_objects = {}

FN.outlines = {
	NONE = 'None',
	OUTLINE = 'Outline',
	THICKOUTLINE = 'Thick outline',
	MONOCHROME = 'Monochrome',
	MONOCHROMEOUTLINE = 'Monochrome outline',
	MONOCHROMETHICKOUTLINE = 'Monochrome thick outline',
}

-- The outlines in the order every list of them shows (a select's sorting).
FN.OUTLINE_ORDER = { 'NONE', 'OUTLINE', 'THICKOUTLINE', 'MONOCHROME', 'MONOCHROMEOUTLINE', 'MONOCHROMETHICKOUTLINE' }

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

-- Resolve's six answers, for a caller that wants no table (the options kit's
-- compare of a typeface with its default, asked of every row on every render):
-- font_name, font_size, font_outline, shadow X, shadow Y, spacing. Not
-- st:FontValues, which gives the face's file path and flags for a reader that
-- draws.
function st:FontParts(value)
	return Resolve(value)
end

-- Sets a font object to a look (st:FontFields' shape): the face from
-- LibSharedMedia (its default face when it doesn't list the name), size,
-- outline, an opaque black shadow, the shadow's offset, line spacing. The one
-- routine for a shared font's object and a typeface's. fresh is true for an
-- object nothing uses yet (a typeface's first set): it skips the bounce below,
-- which only makes texts already on the object measure again, and so builds the
-- face once at its size, not at two (a Size drag makes a new object per step).
function FN:SetObject(object, fields, fresh)
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
	if fresh then return end
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
-- Which font files the game is known to take, path -> true, kept for the session
-- (SaftUI's preloaded faces are known from here), and those it refused, path ->
-- true, kept only until the next st:FontsChanged (st:FontLoads, below).
local loads, refused = {}, {}
for i, name in ipairs(st.SAFTUI_FACES or {}) do
	local object = CreateFont('SaftUI_Preload' .. i .. 'Font')
	local path = st.LSM:Fetch('font', name)
	object:SetFont(path, 12, '')
	FN.preloaded[name] = object
	loads[path] = true
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
	-- A face the game refuses (st:FontLoads), or a SetObject that raises, puts the
	-- object in the fallback face with the rest of the look kept, as a typeface's
	-- object is (a shared font can be put on any face LibSharedMedia lists).
	local fields = st:FontFields(key)
	if not st:FontLoads(st.LSM:Fetch('font', fields.font_name)) or not pcall(self.SetObject, self, font, fields) then
		fields.font_name = self:FallbackName()
		self:SetObject(font, fields)
	end
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
local fellBack = {} -- key -> true: the object is in Text's face for a refused file
local function Typeface(value)
	local name, size, outline, x, y, spacing = Resolve(value)
	local path = st.LSM:Fetch('font', name)
	local key = path .. '\31' .. size .. '\31' .. outline .. '\31' .. x .. '\31' .. y .. '\31' .. spacing
	local object = typefaces[key]
	-- An object made in Text's face for a refused file is made again once the file loads.
	if object and fellBack[key] and st:FontLoads(path) then object = nil end
	if not object then
		typefaceCount = typefaceCount + 1
		object = CreateFont('SaftUI_Typeface' .. typefaceCount .. 'Font')
		object:SetTextColor(1, 1, 1)
		local fields = { font_name = name, font_size = size, font_outline = outline, shadow_offset = { x, y }, spacing = spacing }
		-- A face LibSharedMedia lists whose file the game refuses (st:FontLoads): the
		-- object takes Text's face with the size, outline, shadow and spacing asked
		-- for, so the text still draws (in Text's face). A SetObject that raises
		-- for another reason falls back the same way.
		fellBack[key] = nil
		if not st:FontLoads(path) or not pcall(FN.SetObject, FN, object, fields, true) then
			fields.font_name = FN:FallbackName()
			FN:SetObject(object, fields, true)
			fellBack[key] = true
		end
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

-- Whether the game takes a font file. SaftUI's preloaded faces do, with no probe.
-- Any other file is tried on a font object of SaftUI's own (`CreateFont`: a font
-- file draws reliably only once a font object has been set to it, the font demo
-- found, so this is the mechanism known to work and not a font string's own
-- SetFont). It counts as refused when the call raises, returns false, or leaves
-- the object still on the face it was put on before (`Font:GetFont` returns a file, a height and flags in
-- the API documentation, on both clients; `Font:SetFont` has no return value
-- there, `FontString:SetFont` returns `success`, and neither says whether a missing
-- file raises or returns false). A positive answer is kept for the session. A
-- refusal is kept only until the next st:RetryFonts (which st:FontsChanged runs,
-- and so does a font row picking a face and a font list opening, so a changed
-- font setting or a reopened list tries the file again), and a path is probed at
-- most once between two of those, so a reader on a hot path (the tooltip's
-- Show) costs one table lookup.
local probe
function st:FontLoads(path)
	if loads[path] then return true end
	if refused[path] then return false end
	probe = probe or CreateFont('SaftUI_FontProbeFont')
	-- Put on a face known to load first, so a refusal that says nothing shows as the
	-- object still having it, whatever form the game reports a path in. It is a
	-- file already known to load, which is never the one probed (that is not in
	-- `loads` here): one of SaftUI's preloaded faces, never Text's own, which a
	-- player may have put on a face SaftUI does not preload, or that raises. The
	-- call is guarded as the probed one is.
	local sentinel = next(loads)
	if not sentinel or sentinel == path then
		sentinel = st.LSM:Fetch('font', st.defaults.fonts.normal.font_name)
	end
	pcall(probe.SetFont, probe, sentinel, 12, '')
	local before = probe:GetFont()
	local ok, result = pcall(probe.SetFont, probe, path, 12, '')
	local file = ok and result ~= false and probe:GetFont()
	if type(file) == 'string' and file ~= '' and file ~= before then
		loads[path] = true
		return true
	end
	refused[path] = true
	return false
end

-- Forgets the refusals, so a face the game refused is tried again the next time
-- it is asked for. Run by st:FontsChanged, by a font row's pick and by a font
-- list opening (a face another addon registers late, or a file that appears).
function st:RetryFonts()
	for path in pairs(refused) do refused[path] = nil end
end

-- The face a refused face draws in, for the value readers and every font
-- object alike: the profile's Text when it loads, else SaftUI's default Text
-- face (which is preloaded).
function FN:FallbackName()
	local name = Resolve('normal')
	if st:FontLoads(st.LSM:Fetch('font', name)) then return name end
	return st.defaults.fonts.normal.font_name
end

-- For a reader that takes values, not an object: path, size, flags, shadow X,
-- shadow Y and spacing of a font setting. A face the game refuses to load
-- (st:FontLoads) gives Text's face in its place, with the size and flags asked,
-- so every reader, whether it sets a font string, a chat window or another
-- addon's timer, draws something. Builds nothing once a face is known.
function st:FontValues(value)
	local name, size, outline, x, y, spacing = Resolve(value)
	local path = st.LSM:Fetch('font', name)
	if not st:FontLoads(path) then
		path = st.LSM:Fetch('font', FN:FallbackName())
	end
	return path, size, st.OutlineFlag(outline), x, y, spacing
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

-- Followers that are not a text: region -> apply(region, fontObject), for a key
-- that has no SetFontObject of its own (a Button, whose normal, highlight and
-- disabled font objects are what draw its label). Weak keys, like followers.
local appliers = setmetatable({}, { __mode = 'k' })

-- Puts getValue()'s font on the region now, and again on every
-- st:RefollowFonts. A region kept twice keeps the last getter; a nil getValue
-- forgets the region. A getter that errors on this first apply is not kept.
-- apply, if given, puts the font object on the key in place of
-- key:SetFontObject; it must not close over the key either.
function st:FollowFont(region, getValue, apply)
	if getValue then
		local object = st:FontObject(getValue())
		if apply then apply(region, object) else region:SetFontObject(object) end
		followers[region] = getValue
		appliers[region] = apply
	else
		followers[region] = nil
		appliers[region] = nil
	end
end

-- Forgets a region (a pool releasing it).
function st:UnfollowFont(region)
	followers[region] = nil
	appliers[region] = nil
end

-- Every kept region again, reading its getter now. One that errors is reported
-- (xpcall) and the rest still follow.
function st:RefollowFonts()
	local regions = {}
	for region, getValue in pairs(followers) do regions[#regions + 1] = { region, getValue, appliers[region] } end
	for _, kept in ipairs(regions) do
		xpcall(function()
			local object = st:FontObject(kept[2]())
			if kept[3] then kept[3](kept[1], object) else kept[1]:SetFontObject(object) end
		end, geterrorhandler())
	end
end

-- A font setting or a shared font changed (the Fonts tab, a profile update):
-- the kept texts again, then every module's OnFontsChanged() for what only
-- takes values or lays out around a font (in xpcall, as st:ColorsChanged runs
-- OnColorsChanged, so one that errors doesn't stop the rest). A module whose
-- OnFontsChanged reads a profile it converts runs its conversion first: the
-- profile update calls this before the modules' UpdateConfig.
function st:FontsChanged()
	-- A face the game refused is tried again: a wrong refusal lasts no longer.
	st:RetryFonts()
	st:RefollowFonts()
	for _, module in pairs(st.modules) do
		if module.OnFontsChanged then
			xpcall(module.OnFontsChanged, geterrorhandler(), module)
		end
	end
end

-- The rows of one font's look, as the Fonts tab shows them and as the dots menu
-- of a font row does: Size, Outline, Shadow offset X and Y, Line spacing.
FN.FIELDS = { 'font_size', 'font_outline', 'shadow_x', 'shadow_y', 'spacing' }

-- One field of a look (st:FontFields' shape, or a profile's or default's
-- table): shadow_x and shadow_y are the two numbers of its shadow_offset.
function FN.FieldValue(fields, field)
	if field == 'shadow_x' then return fields.shadow_offset[1] end
	if field == 'shadow_y' then return fields.shadow_offset[2] end
	return fields[field]
end

-- A copy of a look (st:FontFields' shape) with that one field set: the dots
-- menu writes this, never the saved table edited in place.
function FN.WithField(fields, field, value)
	local copy = {}
	for key, v in pairs(fields) do copy[key] = v end
	copy.shadow_offset = { fields.shadow_offset[1], fields.shadow_offset[2] }
	if field == 'shadow_x' then
		copy.shadow_offset[1] = value
	elseif field == 'shadow_y' then
		copy.shadow_offset[2] = value
	else
		copy[field] = value
	end
	return copy
end

-- The dots' tooltip title for a typeface: "Size, outline, shadow and line
-- spacing for Colus", listing only what the row's menu shows (fields: the
-- row's fontFields, nil for all five).
local DOTS_WORDS = { font_size = 'size', font_outline = 'outline', shadow_x = 'shadow', shadow_y = 'shadow', spacing = 'line spacing' }
function FN.DotsTitle(fields, face)
	local wanted
	if fields then
		wanted = {}
		for _, field in ipairs(fields) do wanted[field] = true end
	end
	local words, seen = {}, {}
	for _, field in ipairs(FN.FIELDS) do
		local word = DOTS_WORDS[field]
		if (not wanted or wanted[field]) and not seen[word] then
			seen[word] = true
			words[#words + 1] = word
		end
	end
	local list = words[1]
	if #words > 1 then
		list = table.concat(words, ', ', 1, #words - 1) .. ' and ' .. words[#words]
	end
	return (list or 'Options'):gsub('^%l', string.upper) .. ' for ' .. face
end

-- Per field: its name and its desc for each subject. A 'shared' desc is the
-- Fonts tab's (it says every text that uses the font); a 'text' desc is the
-- dots menu's, for one text.
local FIELD_TEXT = {
	font_size = { name = 'Size',
		shared = 'How big every text that uses this font is.',
		text = 'How big this text is.' },
	font_outline = { name = 'Outline',
		shared = 'The outline around the letters of every text that uses this font.',
		text = 'The outline around its letters.' },
	shadow_x = { name = 'Shadow offset X',
		shared = 'How far right of the letters the shadow of every text that uses this font falls, in pixels; below 0, to the left. With X and Y both 0 the shadow sits behind the letters.',
		text = 'How far right of the letters its shadow falls, in pixels; below 0, to the left.' },
	shadow_y = { name = 'Shadow offset Y',
		shared = 'How far above the letters the shadow of every text that uses this font falls, in pixels; below 0, below them.',
		text = 'How far above the letters its shadow falls, in pixels; below 0, below them.' },
	spacing = { name = 'Line spacing',
		shared = 'The gap, in pixels, between the lines of every text that uses this font, when it runs to more than one line.',
		text = 'The gap between its lines, in pixels, when it runs to more than one line.' },
}

-- The options for a font's size, outline, shadow and spacing, built once for
-- the Fonts tab and the dots menu: { [field] = option }, at orders 2 to 6 (the
-- Typeface row, which the menu has no use for, is order 1 on the tab).
--   read(field) -> value, write(field, value): the caller's, by the field's
--     name; shadow_x and shadow_y are the two numbers of shadow_offset.
--   subject: 'shared' (the tab: every text that uses this font) or 'text'
--     (the menu: one text).
--   fields: which of FN.FIELDS to make (nil: all five).
-- The options have no default (a reset): the tab adds its own, and the menu's
-- rows have none.
function FN.FieldOptions(read, write, subject, fields)
	local wanted
	if fields then
		wanted = {}
		for _, field in ipairs(fields) do wanted[field] = true end
	end
	local generators = st.Config.generators
	local options = {}
	for i, field in ipairs(FN.FIELDS) do
		if not wanted or wanted[field] then
			local text = FIELD_TEXT[field]
			local option
			if field == 'font_size' then
				option = generators.range(i + 1, text.name, 1, 100, 1, text[subject])
			elseif field == 'font_outline' then
				option = {
					order = i + 1,
					type = 'select',
					name = text.name,
					desc = text[subject],
					values = FN.outlines,
					sorting = { unpack(FN.OUTLINE_ORDER) },
				}
			elseif field == 'spacing' then
				option = generators.range(i + 1, text.name, 0, 20, 1, text[subject])
			else
				option = generators.range(i + 1, text.name, -5, 5, 1, text[subject])
			end
			option.get = function() return read(field) end
			option.set = function(_, value) write(field, value) end
			options[field] = option
		end
	end
	return options
end

-- The default of a row that holds a font setting (a shared font's key or a
-- typeface): it differs while the value is anything but the default (a
-- typeface table always does), a reset writes the default and runs
-- st:FontsChanged(), and the tooltip names it through st:FontLabel. read(info)
-- and write(info, value) are the row's, as an option's get and set are; the
-- caller's write does what a set does short of st:FontsChanged.
function FN.FontSettingDefault(read, write, default)
	return {
		differs = function(info) return read(info) ~= default end,
		reset = function(info)
			write(info, default)
			st:FontsChanged()
		end,
		text = st:FontLabel(default),
	}
end

-- The Kinds of text section: which font each kind of text uses, as
-- { row key, profile key, name, desc }. A row reads and writes
-- st.config.profile[profile key].font. Each kind's texts follow their setting
-- (st:FollowFont), so a change reaches them at once.
local TEXT_FONTS = {
	{ 'button_text', 'buttons', 'Button text',
		"The labels of SaftUI's buttons (such as the bags' Bag Slots and Warband Bank and keybind mode's Done), the totem bar's key bindings, counts and names, and the bag slot bars' and the bank's bag slots' texts. The totem timers have a font of their own on the Totem bar's page." },
}

local TEXT_FONTS_NOTE = 'Which font each kind of text uses. A change shows at once.'

local function TextFontsGroup()
	local args = {}
	for i, entry in ipairs(TEXT_FONTS) do
		local key, profile_key, name, desc = unpack(entry)
		local option = st.Config.generators.font(i, desc)
		option.name = name
		option.get = function() return st.config.profile[profile_key].font end
		option.set = function(_, value)
			st.config.profile[profile_key].font = value
			st:FontsChanged()
		end
		option.saved = st.Config.SavedAt(profile_key, 'font')
		args[key] = option
	end
	return {
		type = 'group',
		inline = true,
		order = #FN.FONTS + 1,
		name = 'Kinds of text',
		desc = TEXT_FONTS_NOTE,
		args = args,
	}
end

-- The first sentence is Task 2's wording, kept: a Font row lists these first.
-- The second is the spec's, about the dots.
local INTRO = "SaftUI's shared fonts. Font rows throughout SaftUI choose from these, and a change here changes every text that uses the font, at once. A Font row can take a typeface of its own instead, with its size and outline in its dots, or in the Size and Outline beside the row."

-- The look of a shared font at its default, for the row's reset: one field of
-- st.defaults.fonts[key].
local function DefaultField(key, field)
	return FN.FieldValue(st.defaults.fonts[key], field)
end

-- One shared font's section: its Typeface row and FN.FieldOptions' five, each
-- reading and writing the profile at call time. Every set and every reset
-- applies to the font's object, then runs st:FontsChanged().
local function FontSection(entry, order)
	local key = entry.key
	local function read(field)
		return FN.FieldValue(st:FontFields(key), field)
	end
	local function write(field, value)
		local saved = st.config.profile.fonts[key]
		if field == 'shadow_x' or field == 'shadow_y' then
			-- Rebuilt from what is drawn, so a malformed saved shadow is healed.
			saved.shadow_offset = FN.WithField(st:FontFields(key), field, value).shadow_offset
		else
			saved[field] = value
		end
		FN:UpdateFontConfig(key)
		st:FontsChanged()
	end

	local args = FN.FieldOptions(read, write, 'shared')
	args.font_name = {
		order = 1,
		type = 'select',
		dialogControl = 'LSM30_Font',
		name = 'Typeface',
		desc = 'The typeface of every text that uses this font.',
		values = st.LSM:HashTable('font'),
		get = function() return read('font_name') end,
		set = function(_, value) write('font_name', value) end,
	}
	for field, option in pairs(args) do
		option.default = {
			differs = function() return read(field) ~= DefaultField(key, field) end,
			reset = function() write(field, DefaultField(key, field)) end,
			value = function() return DefaultField(key, field) end,
		}
	end
	return {
		name = entry.name,
		desc = entry.job .. '.',
		order = order,
		type = 'group',
		inline = true,
		args = args,
	}
end

function FN:GetConfigTable()
	local config = {
		order = 1,
		type = 'group',
		name = 'Fonts',
		-- childGroups = 'select',
		args = {
			intro = { order = 0, type = 'description', name = INTRO },
			kinds = TextFontsGroup(),
		}
	}

	-- One section per shared font, in FN.FONTS order, named from code, with its
	-- job as the section's note.
	for i, entry in ipairs(self.FONTS) do
		config.args[entry.key] = FontSection(entry, i)
	end

	return config
end
