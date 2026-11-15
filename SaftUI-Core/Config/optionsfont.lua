local st = SaftUI
local W = st.OptionsWidgets
local Kit = W.Kit

--[[
	The options window's font row, type 'font' (st.OptionsWidgets,
	optionswidgets.lua): a font setting's one control. The setting holds a
	shared font's key (Text, Heading, ...) or a typeface, a table of a shared
	font's own fields (Media/fonts.lua, st:FontFields), and the row shows
	either in the face it names. Generators: generators.font(order, desc,
	opts), opts.faceOnly and opts.fields (SaftUI's faceOnly and fontFields
	option fields, read raw).

	  w.frame   a container, w.width by 24: 190, or 194 under Blizzard, whose
	            dropdown art reaches 7 past its face (the slot's gap is
	            Kit.FONT_SLOT_GAP, 4 and 8)
	  w.face    the select face (W.SelectFace, W.WIDTH.select wide) at the
	            container's left: it shows the font's name in its own face at
	            15 and opens the list. A click does nothing on a disabled row
	  w.dots    the slot (Kit.NewSlot, optionsitem.lua), 16 by 24 at the
	            container's right edge, one button whose icon is the link to
	            the shared font's section of Global settings > Fonts (OW:Reveal)
	            or, from the dots' task on, the typeface's own menu. Empty (hidden,
	            its room kept) for a typeface until then
	  w.value   the saved value; w.kind, 'shared' (a key of a shared font, or
	            nothing known: Text) or 'typeface' (a table, a dropped font's
	            key, or on a faceOnly row a face name)
	  w:Open()  opens the list; w:Pick(key) saves a pick (below)

	The list (W.FontEntries) is SaftUI's fonts, a caption then the six shared
	fonts each in its own face, then Typefaces, a caption, then every face
	LibSharedMedia lists, in its order and each in its own face. A shared font
	is picked by its key and saves it. A typeface is picked as 'face:' .. its
	name and saves a table: the fields the row showed (st:FontFields of the
	value, so Text's look under the new face from a shared font or nothing)
	with the new face's name, never the saved table written to. A faceOnly
	row, a menu's, saves the face's name alone and has no table to keep
	options in.
]]

local Base, builders, define = Kit.Base, Kit.builders, Kit.define
local FIELD_FONT_SIZE, SetFieldFont, PaintFace = Kit.FIELD_FONT_SIZE, Kit.SetFieldFont, Kit.PaintFace
local NewSlot, PaintSlot = Kit.NewSlot, Kit.PaintSlot
local BlizzardLook = W.BlizzardLook

W.WIDTH.font = 190
local FONT_SLOT_GAP = { theme = 4, blizzard = 8 }
Kit.FONT_SLOT_GAP = FONT_SLOT_GAP
local SLOT_WIDTH = 16 -- Kit.NewSlot's
local FACE_PREFIX = 'face:' -- a typeface's key in the list; a shared font's has none

local function Fonts() return st:GetModule('Fonts') end

-- What a font setting is, for the row: 'shared' and a shared font's key (nil
-- when the value names none: Text), or 'typeface' and its face. On a faceOnly
-- row a string that isn't a shared font's key is a face name.
local function Describe(value, faceOnly)
	if st:IsSharedFont(value) then return 'shared', value end
	if faceOnly then
		if type(value) == 'string' and value ~= '' then return 'typeface', nil, value end
		return 'shared'
	end
	if type(value) == 'table' or (type(value) == 'string' and Fonts().DROPPED[value]) then
		return 'typeface', nil, st:FontFields(value).font_name
	end
	return 'shared'
end

-- The list's entries for a font setting's value, and the key it picks:
-- SaftUI's fonts (a caption, then each shared font in its own face), then
-- Typefaces (a caption, then every face LibSharedMedia lists, in its order,
-- each in its own face). A typeface is 'face:' .. its name. selected is the
-- shared font's key, 'face:' .. the typeface's face (listed or not: none is
-- picked then), or 'normal' for a value that names nothing.
function W.FontEntries(value, faceOnly)
	local kind, key, face = Describe(value, faceOnly)
	local selected = kind == 'typeface' and FACE_PREFIX .. face or key or 'normal'
	local entries = { { caption = true, label = 'SaftUI fonts' } }
	for _, entry in ipairs(Fonts().FONTS) do
		entries[#entries + 1] = { key = entry.key, label = entry.name, font = (st:FontValues(entry.key)) }
	end
	entries[#entries + 1] = { caption = true, label = 'Typefaces' }
	for _, name in ipairs(st.LSM:List('font')) do
		entries[#entries + 1] = { key = FACE_PREFIX .. name, label = name, font = st.LSM:Fetch('font', name) }
	end
	return entries, selected
end

local LINK_LINES = {
	'A shared font. Its typeface, size and outline are set on Global settings > Fonts, and change every text that uses it.',
	'Click to go there.',
}

builders.font = function(w)
	local frame = CreateFrame('Frame', nil, UIParent)
	frame:SetSize(W.WIDTH.font, Kit.FIELD_HEIGHT)
	w.frame = frame

	w.face = W.SelectFace(frame, W.WIDTH.select, function() w:Open() end)
	w.face:SetPoint('LEFT', frame, 'LEFT', 0, 0)

	local dots = NewSlot(frame, st.icons.link)
	dots:SetPoint('RIGHT', frame, 'RIGHT', 0, 0)
	dots.tip = function()
		return st:FontLabel(w.linkKey), LINK_LINES
	end
	dots.onClick = function()
		local OW = st.OptionsWindow
		if w.linkKey and OW and OW.Reveal then
			OW:Reveal({ 'Fonts', 'fonts', w.linkKey, 'font_name' })
		end
	end
	w.dots = dots
end

define('font', {
	-- The look before the row: the width (the dropdown's art under Blizzard
	-- reaches past the face, so the slot is further off), the face's and the
	-- slot's.
	Bind = function(self, ...)
		local blizzard = BlizzardLook()
		self.blizzard = blizzard
		self.width = W.WIDTH.select + (blizzard and FONT_SLOT_GAP.blizzard or FONT_SLOT_GAP.theme) + SLOT_WIDTH
		self.frame:SetWidth(self.width)
		W.LookSelectFace(self.face, blizzard)
		self.dots.blizzard = blizzard
		PaintSlot(self.dots, false)
		return Base.Bind(self, ...)
	end,

	Refresh = function(self)
		local option = self.row.option
		self.faceOnly = option and option.faceOnly == true or false
		self.value = self:Value()
		local kind, key, face = Describe(self.value, self.faceOnly)
		self.kind = kind
		local text, path
		if kind == 'shared' then
			key = key or 'normal'
			self.linkKey = key
			text, path = st:FontLabel(key), (st:FontValues(key))
		else
			self.linkKey = nil
			-- A face LibSharedMedia doesn't list reads in the field font.
			text, path = face, st.LSM:HashTable('font')[face]
		end
		SetFieldFont(self.face.text, path, FIELD_FONT_SIZE, '')
		self.face.text:SetText(text)
		-- The slot holds the link for a shared font and is empty for a typeface
		-- (its room kept) until the dots.
		self.dots:SetShown(kind == 'shared')
	end,

	Open = function(self)
		if self.disabled or not self.row then return end
		local entries, selected = W.FontEntries(self:Value(), self.faceOnly)
		W.OpenList(self.face, entries, selected, function(key) self:Pick(key) end)
	end,

	-- Saves a pick of the list: a shared font's key as it is; a typeface (its
	-- key 'face:' .. name) as the face's name on a faceOnly row, else a fresh
	-- table of what the row showed with that face.
	Pick = function(self, key)
		if self.disabled or not self.row or type(key) ~= 'string' then return end
		if key:sub(1, #FACE_PREFIX) ~= FACE_PREFIX then return self:Commit(key) end
		local face = key:sub(#FACE_PREFIX + 1)
		if self.faceOnly then return self:Commit(face) end
		local fields = st:FontFields(self:Value())
		fields.font_name = face
		self:Commit(fields)
	end,

	-- A disabled row takes no mouse (so its row shows its tooltip), neither on
	-- the face nor on the slot. The widget's own alpha dims both, so the face
	-- keeps its own.
	OnDisabled = function(self, disabled)
		local face = self.face
		face.disabled = disabled
		face:EnableMouse(not disabled)
		face:SetAlpha(1)
		PaintFace(face)
		self.dots.disabled = disabled
		self.dots:EnableMouse(not disabled)
	end,

	OnRelease = function(self)
		if W.ListOwner() == self.face then W.CloseList() end
		PaintSlot(self.dots, false)
		self.value, self.kind, self.linkKey = nil, nil, nil
	end,
})
