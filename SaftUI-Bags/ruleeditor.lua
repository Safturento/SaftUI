local st = SaftUI
local INV = st:GetModule('Inventory')

--[[
	The outline rule editor: the options window's widget type 'bagrule', a
	category's rule drawn as an outline with connector lines (the approved
	mockup's option C).

	  { type = 'bagrule', size = 'wide', name, desc,
	    get = function(info) -> rule end, set = function(info, rule) end }

	It's a bare, titled type (W.Define): its name over it, the body's width.
	Each row is 26 high and each level of nesting indents 34. A row whose
	fields don't fit before the X goes on in lines of 26 under it, each
	starting under its label (its handle, NOT, label and X stay on the
	first line), so a narrow editor (the Categories tab's 540) never runs a
	field under the X. A group's rows hang off its
	line (2 wide, at its indent plus 12; AND blue, OR orange), with its AND or
	OR badge on the line's middle (a click flips it) and an 18 connector from
	the line to each row. Rows:
	  - a block: its handle (6 dots), NOT, its grey label, its fields, the X;
	  - a group's title: handle, NOT, 'group' in grey, the X;
	  - an add row, last in every group: + Block (a list of the block types)
	    and + Group (an empty group of the other operator);
	  - a node this version can't read: 'Unknown block' and the X.
	The root has no title row and no NOT.

	Every change sets the whole new rule, made on a copy of get's rule: the
	stored rule can be the shipped default's own table (or the store's), so
	nothing here changes a rule in place. A change commits through the
	widget's Commit, and the window draws again; a check list's toggle sets
	through the model and calls st.Config:Refresh(), so the list stays open
	and the window draws once it closes. Text boxes set on Enter; Esc or
	leaving one puts the stored value back.

	A drag starts on a handle's OnMouseDown (onChanged(true, nil, true,
	widget) holds the window's render off) and ends on its OnMouseUp: the row
	under the cursor (IsMouseOver, and the cursor against its middle for the
	half) gives R.DropAt's spot, R.Move moves the node there, and the rule is
	set. The OnUpdate that runs during a drag only draws the insertion line
	and the ghost.

	  widget:SetHighlight(path | nil)  tints the row at path orange (Caught now)
	  widget.rows[i] = { frame, path, kind, depth, node, op, top, height,
	    handle, notBox, remove, label, tint, connector, badge (on a group's
	    add row: every group has one, the root too; badge.line is its line),
	    captions, fields = { [name] = control } }
	top is the row's from the editor's top, and height its lines times 26.
	fields are named for the params they set: text and word; class and
	subclasses; qualities, slots, states and expansions; mode, min and max;
	value; ids and id; levels, expansion and share; note; and an add row's
	addBlock and addGroup.

	Every frame here is SaftUI's. The cursor is read with GetCursorInfo and
	cleared with ClearCursor, out of combat (/sui closes in combat).
]]

local R = INV.Rules
local IC = INV.ItemClasses
local W, OB, OM = st.OptionsWidgets, st.OptionsBody, st.OptionsModel

local floor, ceil, max = math.floor, math.ceil, math.max
local format, tconcat = string.format, table.concat

------------------------------------------------------------------ the look

local ROW_HEIGHT = 26
local INDENT = 34 -- per level of nesting
local LINE_X = 12 -- a group's line, from its indent
local LINE_WIDTH = 2
local CONNECTOR = 18
local CONTENT_X = 22 -- a row's content, from the line it hangs off
local FIELD_HEIGHT = 22
local BADGE_WIDTH, BADGE_HEIGHT = 26, 16
local NOT_WIDTH, NOT_HEIGHT = 30, 16
local HANDLE_WIDTH = 10
local REMOVE_SIZE = 16
local CHECK_SIZE = 14
local GAP = 6
local TEXT_BOX, NUMBER_BOX, SMALL_BOX = 150, 50, 40
local FIELD_WIDTH, MODE_WIDTH, YES_NO_WIDTH, COUNT_WIDTH = 150, 80, 60, 90
local TINT_ALPHA = 0.15

------------------------------------------------------------------ shared with the Categories tab

--[[
	INV.DragParts: what the rule editor and the Categories tab
	(categoriestab.lua, which loads after this file) both draw and drag with.
	  Colors(), Grey()                the profile's colors; grey text's r, g, b
	  Text(parent, font, justify)     a font string that doesn't wrap (the
	                                  options window's field font by default)
	  TextWidth(fs)                   its whole text's width, rounded up
	  Inside(frame, ancestor)         frame is ancestor or inside it
	  HANDLE_WIDTH, Handle(parent, height)
	                                  a drag handle: 6 grey dots, two across
	                                  and three down, 2 apart
	  UnderCursor(rows) -> i, lower   the row (a record with .frame) under the
	                                  cursor, and whether it's in its lower half
	  ShowGhost(w, label, height)     shows w.ghost (made once, drawn in
	                                  SaftUI's theme) with label, colors
	                                  w.insert blue and runs w.drawDrag on
	                                  w.frame's OnUpdate
	  PlaceGhost(ghost)               the ghost by the cursor
	  StopDrag(w)                     no w.drag, no OnUpdate, the ghost and
	                                  w.insert hidden
	A widget that drags has w.frame, w.insert (its insertion line), w.drawDrag
	and w.drag while it drags.
]]
local D = {}
INV.DragParts = D

function D.Colors() return st.config.profile.colors end
function D.Grey() return D.Colors().text.grey:GetRGB() end

function D.Text(parent, font, justify)
	local fs = parent:CreateFontString(nil, 'OVERLAY')
	fs:SetFontObject(font or W.GetFont())
	fs:SetJustifyH(justify or 'LEFT')
	fs:SetWordWrap(false)
	return fs
end

function D.TextWidth(fs) return ceil(fs:GetUnboundedStringWidth()) end

function D.Inside(frame, ancestor)
	while frame do
		if frame == ancestor then return true end
		frame = frame:GetParent()
	end
	return false
end

D.HANDLE_WIDTH = HANDLE_WIDTH

function D.Handle(parent, height)
	local handle = CreateFrame('Button', nil, parent)
	handle:SetSize(D.HANDLE_WIDTH, height)
	for row = 0, 2 do
		for col = 0, 1 do
			local dot = handle:CreateTexture(nil, 'OVERLAY')
			dot:SetColorTexture(D.Grey())
			dot:SetSize(2, 2)
			dot:SetPoint('TOPLEFT', handle, 'TOPLEFT', 2 + col * 4, -(6 + row * 4))
		end
	end
	return handle
end

function D.UnderCursor(rows)
	for i, record in ipairs(rows) do
		local f = record.frame
		if f:IsMouseOver() then
			local _, y = GetCursorPosition()
			local _, middle = f:GetCenter()
			return i, y / f:GetEffectiveScale() < middle
		end
	end
end

function D.ShowGhost(w, label, height)
	local ghost = w.ghost
	if not ghost then
		ghost = st:CreateFrame('Frame', nil, w.frame)
		ghost:SetFrameStrata('TOOLTIP')
		ghost:SetHeight(height)
		ghost:EnableMouse(false)
		ghost.text = D.Text(ghost)
		ghost.text:SetPoint('LEFT', ghost, 'LEFT', 8, 0)
		w.ghost = ghost
	end
	st:SetBackdrop(ghost, 'theme', 'solid', 'small')
	ghost.text:SetText(label)
	ghost:SetWidth(D.TextWidth(ghost.text) + 16)
	ghost:Show()
	w.insert:SetColorTexture(D.Colors().button.blue:GetRGB())
	w.frame:SetScript('OnUpdate', w.drawDrag)
	return ghost
end

function D.PlaceGhost(ghost)
	local x, y = GetCursorPosition()
	local scale = ghost:GetEffectiveScale()
	ghost:ClearAllPoints()
	ghost:SetPoint('LEFT', UIParent, 'BOTTOMLEFT', floor(x / scale) + 12, floor(y / scale))
end

function D.StopDrag(w)
	w.drag = nil
	w.frame:SetScript('OnUpdate', nil)
	if w.ghost then w.ghost:Hide() end
	w.insert:Hide()
end

local Colors, Grey, Text, TextWidth, Inside = D.Colors, D.Grey, D.Text, D.TextWidth, D.Inside

-- A group's color: AND blue, OR orange.
local function OpColor(op)
	if op == 'or' then return Colors().text.orange:GetRGB() end
	return Colors().button.blue:GetRGB()
end

-- A select's caret: rows of 7, 5, 3 and 1 pixels, each placed by its left edge.
local function Caret(parent)
	for i, width in ipairs({ 7, 5, 3, 1 }) do
		local t = parent:CreateTexture(nil, 'OVERLAY')
		t:SetColorTexture(Grey())
		t:SetSize(width, 1)
		t:SetPoint('TOPLEFT', parent, 'RIGHT', -12 - floor(width / 2), 3 - i)
	end
end

------------------------------------------------------------------ values

local function is_num(v) return type(v) == 'number' and v == v end

-- A number as a box shows it: 0.85, 12, 90.
local function Shown(v)
	if not is_num(v) then return '' end
	return tostring(tonumber(format('%.6g', v)))
end

local function Tidy(v) return tonumber(format('%.10g', v)) end

local function Typed(text)
	text = tostring(text or ''):gsub('%%', ''):gsub('^%s+', ''):gsub('%s+$', '')
	return tonumber(text)
end

local function Has(list, key)
	if type(list) ~= 'table' then return false end
	for _, v in ipairs(list) do
		if v == key then return true end
	end
	return false
end

-- list with key toggled, in the entries' order; values the entries don't
-- know keep their order, after them.
local function Toggled(list, key, entries)
	local known, set, unknown, had = {}, {}, {}, false
	for _, entry in ipairs(entries) do known[entry.key] = true end
	if type(list) == 'table' then
		for _, v in ipairs(list) do
			if v == key then
				had = true
			elseif known[v] then
				set[v] = true
			else
				unknown[#unknown + 1] = v
			end
		end
	end
	if not had then set[key] = true end
	local out = {}
	for _, entry in ipairs(entries) do
		if set[entry.key] then out[#out + 1] = entry.key end
	end
	for _, v in ipairs(unknown) do out[#out + 1] = v end
	return out
end

-- The labels of list's values joined, or placeholder when there are none.
local function ListText(list, entries, placeholder, fallback)
	if type(list) ~= 'table' or #list == 0 then return placeholder end
	local labels = {}
	for _, entry in ipairs(entries) do labels[entry.key] = entry.label end
	local out = {}
	for _, v in ipairs(list) do
		out[#out + 1] = labels[v] or (fallback and fallback(v)) or tostring(v)
	end
	return tconcat(out, ', ')
end

local function Ids(list)
	local out = {}
	if type(list) == 'table' then
		for _, v in ipairs(list) do
			if is_num(v) then out[#out + 1] = v end
		end
	end
	return out
end

local function Count(n) return n == 1 and '1 item' or (n .. ' items') end

local function ItemLabel(id)
	local name = C_Item and C_Item.GetItemNameByID and C_Item.GetItemNameByID(id)
	if type(name) == 'string' and name ~= '' then return name .. ' (' .. id .. ')' end
	return 'Item ' .. id
end

------------------------------------------------------------------ list entries

local BLOCK_ENTRIES = {}
for i, type_ in ipairs(R.BLOCKS) do BLOCK_ENTRIES[i] = { key = type_.id, label = type_.label } end

local function ClassEntries()
	local out = {}
	for _, class in ipairs(IC.Classes()) do
		if not class.name:find('OBSOLETE', 1, true) then out[#out + 1] = { key = class.id, label = class.name } end
	end
	return out
end

local function SubclassEntries(class)
	local out = {}
	if not is_num(class) then return out end
	for _, sub in ipairs(IC.Subclasses(class)) do out[#out + 1] = { key = sub.id, label = sub.name } end
	return out
end

local function QualityEntries()
	local out = {}
	for q = 0, 7 do out[#out + 1] = { key = q, label = R.QUALITY_LABELS[q] } end
	return out
end

local function SlotEntries()
	local out = {}
	for i, slot in ipairs(R.SLOTS) do out[i] = { key = slot[1], label = slot[2] } end
	return out
end

local function BindingEntries()
	local out = {}
	for i, state in ipairs(R.BINDING_STATES) do out[i] = { key = state[1], label = state[2] } end
	return out
end

-- 0 to GetNumExpansions() - 1, or 0 to 11 without it.
local function ExpansionEntries()
	local n = type(GetNumExpansions) == 'function' and GetNumExpansions()
	if not is_num(n) or n < 1 then n = 12 end
	local out = {}
	for e = 0, n - 1 do out[#out + 1] = { key = e, label = R.ExpansionLabel(e) } end
	return out
end

local MODES = {
	{ key = 'atleast', label = 'at least' },
	{ key = 'atmost', label = 'at most' },
	{ key = 'between', label = 'between' },
}
local MODE_LABEL = { atleast = 'at least', atmost = 'at most', between = 'between' }

local YES_NO = { { key = 'yes', label = 'Yes' }, { key = 'no', label = 'No' } }

------------------------------------------------------------------ the rule

-- get's rule, or an empty AND when it isn't a group this version can read
-- (an edit then starts it afresh).
local function Current(w)
	local rule = w:Value()
	if R.IsGroup(rule) then return rule end
	return { op = 'and', items = {} }
end

local function NodeNow(w, path)
	local node = R.NodeAt(Current(w), path)
	return type(node) == 'table' and node or nil
end

-- Changes a copy of the rule with fn(rule), true when it changed something,
-- and commits it (the window draws again).
local function Edit(w, fn)
	if w.disabled or not w.row then return end
	local rule = R.Copy(Current(w))
	if fn(rule) then w:Commit(rule) end
end

-- The same for a check list's toggle: set through the model and refresh,
-- with no render while the list is open.
local function Write(w, fn)
	if w.disabled or not w.row then return end
	local rule = R.Copy(Current(w))
	if not fn(rule) then return end
	OM.Set(w.root, w.row, rule)
	st.Config:Refresh()
end

-- fn(node) on the block at path in a copy; it returns false for no change.
local function EditNode(w, path, fn, quiet)
	local apply = quiet and Write or Edit
	apply(w, function(rule)
		local node = R.NodeAt(rule, path)
		if type(node) ~= 'table' or node.block == nil then return false end
		return fn(node) ~= false
	end)
end

local function AddItem(w, path, id)
	if not is_num(id) or id < 1 or id ~= floor(id) then return end
	EditNode(w, path, function(node)
		if Has(node.ids, id) then return false end
		local ids = Ids(node.ids)
		ids[#ids + 1] = id
		node.ids = ids
	end)
end

-- A check list over entries for the array param of the block at path. A
-- toggle writes it, and the field shows text(node) at once.
local function OpenChecks(w, field, path, param, entries, text)
	W.OpenCheckList(field, entries, function(key)
		local node = w.row and NodeNow(w, path)
		return node ~= nil and Has(node[param], key)
	end, function(key)
		if w.disabled or not w.row then return end
		EditNode(w, path, function(node) node[param] = Toggled(node[param], key, entries) end, true)
		if w.row then field.text:SetText(text(NodeNow(w, path))) end
	end)
end

------------------------------------------------------------------ the controls

-- A box (EditBox): Enter commits what was typed (box.commit), Esc and
-- leaving it put the stored value (box.shown) back.
local function MakeBox(f)
	local box = W.Box(st:CreateFrame('EditBox', nil, f))
	box:SetHeight(FIELD_HEIGHT)
	box:SetFontObject(W.GetFont())
	box:SetTextInsets(6, 6, 0, 0)
	box:SetAutoFocus(false)
	box:SetScript('OnEnterPressed', function(self)
		local text = self:GetText()
		self:ClearFocus()
		self:SetText(self.shown or '')
		if self.commit then self.commit(text) end
	end)
	box:SetScript('OnEscapePressed', function(self)
		self:SetText(self.shown or '')
		self:ClearFocus()
	end)
	box:SetScript('OnEditFocusGained', function(self)
		if self.w and self.w.disabled then return self:ClearFocus() end
		W.Edge(self, true)
		self:HighlightText(0, -1)
	end)
	box:SetScript('OnEditFocusLost', function(self)
		W.Edge(self, false)
		self:SetText(self.shown or '')
	end)
	return box
end

-- A field that opens a list (field.open), showing its value (field.text).
local function MakeField(f)
	local field = W.Box(st:CreateFrame('Button', nil, f))
	field.text = Text(field)
	field.text:SetPoint('LEFT', field, 'LEFT', 6, 0)
	field.text:SetPoint('RIGHT', field, 'RIGHT', -20, 0)
	Caret(field)
	W.HoverEdge(field, function() return field.w == nil or field.w.disabled end)
	field:SetScript('OnClick', function(self)
		if self.w and not self.w.disabled and self.w.row and self.open then self.open(self) end
	end)
	field:SetScript('OnHide', function(self)
		if W.ListOwner() == self then W.CloseList() end
	end)
	return field
end

-- A check box with its caption after it (check.toggle on a click).
local function MakeCheck(f)
	local check = W.Box(st:CreateFrame('CheckButton', nil, f))
	check:SetSize(CHECK_SIZE, CHECK_SIZE)
	check.mark = check:CreateTexture(nil, 'OVERLAY')
	check.mark:SetPoint('TOPLEFT', check, 'TOPLEFT', 3, -3)
	check.mark:SetPoint('BOTTOMRIGHT', check, 'BOTTOMRIGHT', -3, 3)
	check.caption = Text(check)
	check.caption:SetPoint('LEFT', check, 'RIGHT', 6, 0)
	W.HoverEdge(check, function() return check.w == nil or check.w.disabled end)
	check:SetScript('OnClick', function(self)
		if self.w and not self.w.disabled and self.toggle then self.toggle() end
	end)
	return check
end

-- + Block and + Group: blue text that runs add.run.
local function MakeAdd(f)
	local add = st:CreateFrame('Button', nil, f)
	add.text = Text(add)
	add.text:SetPoint('LEFT', add, 'LEFT', 0, 0)
	add:SetScript('OnEnter', function(self) self.text:SetAlpha(0.7) end)
	add:SetScript('OnLeave', function(self) self.text:SetAlpha(1) end)
	add:SetScript('OnClick', function(self)
		if self.w and not self.w.disabled and self.run then self.run(self) end
	end)
	return add
end

local function MakeCaption(f) return Text(f) end

-- The next control of kind in the row frame, made when it has none spare.
local function Take(f, kind, make)
	local list = f.controls[kind]
	if not list then
		list = {}
		f.controls[kind] = list
	end
	local n = (f.used[kind] or 0) + 1
	f.used[kind] = n
	local control = list[n]
	if not control then
		control = make(f)
		list[n] = control
	end
	control:ClearAllPoints()
	control:Show()
	return control
end

-- Hides the controls this layout didn't take.
local function HideUnused(f)
	for kind, list in pairs(f.controls) do
		for k = (f.used[kind] or 0) + 1, #list do
			local control = list[k]
			if control.ClearFocus then control:ClearFocus() end
			control:Hide()
		end
	end
end

------------------------------------------------------------------ laying a row out

-- Places a row's controls left to right from x, on lines of ROW_HEIGHT: a
-- control that would pass limit (the X, or the row's end) starts the next
-- line at wrapX, unless it is already the first on its line.
local Lay = {}
Lay.__index = Lay

-- Where a control width wide goes: its x is self.x after this, and the
-- line's top (0 for the first) is returned.
function Lay:Fit(width)
	if self.x > self.wrapX and self.x + width > self.limit then
		self.line = self.line + 1
		self.x = self.wrapX
	end
	return self.line * ROW_HEIGHT
end

function Lay:Box(name, width, shown, commit)
	local box = Take(self.f, 'box', MakeBox)
	box:SetWidth(width)
	local top = self:Fit(width)
	box:SetPoint('TOPLEFT', self.f, 'TOPLEFT', self.x, -(top + 2))
	box:SetJustifyH(width > NUMBER_BOX and 'LEFT' or 'CENTER')
	box.w, box.shown, box.commit = self.w, shown, commit
	box:SetText(shown)
	self.record.fields[name] = box
	self.x = self.x + width + GAP
	return box
end

-- A box for a number param of the block; percent shows and takes a share as a percent.
function Lay:NumberBox(name, width, percent)
	local w, path = self.w, self.path
	local value = self.node[name]
	if percent and is_num(value) then value = value * 100 end
	return self:Box(name, width, Shown(value), function(text)
		local number = Typed(text)
		if not number then return end
		if percent then number = Tidy(number / 100) end
		EditNode(w, path, function(node)
			if node[name] == number then return false end
			node[name] = number
		end)
	end)
end

function Lay:Field(name, width, text, open)
	local field = Take(self.f, 'field', MakeField)
	field:SetSize(width, FIELD_HEIGHT)
	local top = self:Fit(width)
	field:SetPoint('TOPLEFT', self.f, 'TOPLEFT', self.x, -(top + 2))
	field.w, field.open = self.w, open
	field.text:SetText(text)
	self.record.fields[name] = field
	self.x = self.x + width + GAP
	return field
end

function Lay:Check(name, caption, checked, toggle)
	local check = Take(self.f, 'check', MakeCheck)
	check.w, check.toggle = self.w, toggle
	check:SetChecked(checked)
	check.mark:SetColorTexture(Colors().button.blue:GetRGB())
	check.mark:SetShown(checked)
	check.caption:SetText(caption)
	check.caption:SetTextColor(Grey())
	-- The box and its caption go together.
	local width = CHECK_SIZE + 6 + TextWidth(check.caption)
	local top = self:Fit(width)
	check:SetPoint('TOPLEFT', self.f, 'TOPLEFT', self.x, -(top + (ROW_HEIGHT - CHECK_SIZE) / 2))
	self.record.fields[name] = check
	self.x = self.x + width + GAP
	return check
end

-- Grey words between the controls (a field of the row's when named).
function Lay:Caption(text, name)
	local caption = Take(self.f, 'caption', MakeCaption)
	caption:SetText(text)
	caption:SetTextColor(Grey())
	local width = TextWidth(caption)
	local top = self:Fit(width)
	caption:SetPoint('LEFT', self.f, 'TOPLEFT', self.x, -(top + ROW_HEIGHT / 2))
	local captions = self.record.captions
	captions[#captions + 1] = caption
	if name then self.record.fields[name] = caption end
	self.x = self.x + width + GAP
	return caption
end

function Lay:Add(name, text, run)
	local add = Take(self.f, 'add', MakeAdd)
	add.w, add.run = self.w, run
	add.text:SetText(text)
	add.text:SetTextColor(Colors().text.blue:GetRGB())
	add.text:SetAlpha(1)
	local width = TextWidth(add.text)
	add:SetSize(width, FIELD_HEIGHT)
	local top = self:Fit(width)
	add:SetPoint('TOPLEFT', self.f, 'TOPLEFT', self.x, -(top + 2))
	self.record.fields[name] = add
	self.x = self.x + width + 12
	return add
end

------------------------------------------------------------------ each block's fields

local FIELDS = {}

local function TextBox(lay, node)
	local w, path = lay.w, lay.path
	lay:Box('text', TEXT_BOX, type(node.text) == 'string' and node.text or '', function(text)
		EditNode(w, path, function(n)
			if n.text == text then return false end
			n.text = text
		end)
	end)
end

FIELDS.tooltip = function(lay, node)
	local w, path = lay.w, lay.path
	TextBox(lay, node)
	lay:Check('word', 'whole word', node.word == true, function()
		EditNode(w, path, function(n) n.word = n.word ~= true or nil end)
	end)
end
FIELDS.name = FIELDS.tooltip
FIELDS.nameis = TextBox

local function ClassText(class)
	if not is_num(class) then return 'Pick a class' end
	return IC.ClassName(class) or ('Class ' .. class)
end

-- The class, picked from a list. A subclass block's subclasses go with a
-- change of class: they're the old class's.
local function ClassField(lay, node)
	local w, path = lay.w, lay.path
	lay:Field('class', FIELD_WIDTH, ClassText(node.class), function(field)
		local now = NodeNow(w, path)
		W.OpenList(field, ClassEntries(), now and now.class, function(class)
			EditNode(w, path, function(n)
				if n.class == class then return false end
				n.class = class
				if n.block == 'subclass' then n.subclasses = {} end
			end)
		end)
	end)
end

FIELDS.class = ClassField

FIELDS.subclass = function(lay, node)
	local w, path = lay.w, lay.path
	ClassField(lay, node)
	local function text(n)
		local class = n and n.class
		return ListText(n and n.subclasses, SubclassEntries(class), 'Pick subclasses', function(id)
			return 'Subclass ' .. tostring(id)
		end)
	end
	lay:Field('subclasses', FIELD_WIDTH, text(node), function(field)
		local now = NodeNow(w, path)
		local entries = SubclassEntries(now and now.class)
		OpenChecks(w, field, path, 'subclasses', entries, text)
	end)
end

-- A field and a check list over entries() for an array param.
local function ListField(param, entries, placeholder)
	return function(lay, node)
		local w, path = lay.w, lay.path
		local function text(n) return ListText(n and n[param], entries(), placeholder) end
		lay:Field(param, FIELD_WIDTH, text(node), function(field)
			OpenChecks(w, field, path, param, entries(), text)
		end)
	end
end

FIELDS.quality = ListField('qualities', QualityEntries, 'Pick qualities')
FIELDS.slot = ListField('slots', SlotEntries, 'Pick slots')
FIELDS.binding = ListField('states', BindingEntries, 'Pick bindings')
FIELDS.expansion = ListField('expansions', ExpansionEntries, 'Pick expansions')

-- The mode (at least, at most or between) and one or two number boxes.
local function LevelMode(node)
	local min, max_ = is_num(node.min), is_num(node.max)
	if min and max_ then return 'between' end
	if max_ then return 'atmost' end
	return 'atleast'
end

local function LevelFields(lay, node)
	local w, path = lay.w, lay.path
	local mode = LevelMode(node)
	lay:Field('mode', MODE_WIDTH, MODE_LABEL[mode], function(field)
		W.OpenList(field, MODES, mode, function(key)
			EditNode(w, path, function(n)
				if LevelMode(n) == key then return false end
				local min = is_num(n.min) and n.min or nil
				local max_ = is_num(n.max) and n.max or nil
				if key == 'atleast' then
					n.min, n.max = min or max_ or 0, nil
				elseif key == 'atmost' then
					n.min, n.max = nil, max_ or min or 0
				else
					local low = min or max_ or 0
					n.min, n.max = low, max_ or low
				end
			end)
		end)
	end)
	if mode ~= 'atmost' then lay:NumberBox('min', NUMBER_BOX) end
	if mode == 'between' then lay:Caption('and') end
	if mode ~= 'atleast' then lay:NumberBox('max', NUMBER_BOX) end
end

FIELDS.ilvl = LevelFields
FIELDS.reqlevel = LevelFields

local function YesNo(lay, node)
	local w, path = lay.w, lay.path
	local key = node.value == true and 'yes' or node.value == false and 'no' or nil
	lay:Field('value', YES_NO_WIDTH, key == 'yes' and 'Yes' or key == 'no' and 'No' or '', function(field)
		W.OpenList(field, YES_NO, key, function(picked)
			EditNode(w, path, function(n)
				local value = picked == 'yes'
				if n.value == value then return false end
				n.value = value
			end)
		end)
	end)
end

FIELDS.reagent = YesNo
FIELDS.vendorprice = YesNo

-- The count (a check list of the items, where unchecking one removes it),
-- and an ID box. The row takes an item from the cursor too (TakeCursorItem).
FIELDS.items = function(lay, node)
	local w, path = lay.w, lay.path
	local function text(n) return Count(#Ids(n and n.ids)) end
	lay:Field('ids', COUNT_WIDTH, text(node), function(field)
		local entries = {}
		local now = NodeNow(w, path)
		for _, id in ipairs(Ids(now and now.ids)) do entries[#entries + 1] = { key = id, label = ItemLabel(id) } end
		OpenChecks(w, field, path, 'ids', entries, text)
	end)
	lay:Caption('ID')
	lay:Box('id', NUMBER_BOX, '', function(typed) AddItem(w, path, Typed(typed)) end)
end

FIELDS.oldgear = function(lay)
	lay:NumberBox('levels', SMALL_BOX)
	lay:Caption('levels below me')
	lay:Caption('expansion up to')
	lay:NumberBox('expansion', SMALL_BOX)
	lay:NumberBox('share', SMALL_BOX, true)
	lay:Caption('% of my item level')
end

FIELDS.protected = function(lay) lay:Caption('items marked Protected', 'note') end

------------------------------------------------------------------ the rows

-- A block of a type this version knows (any params): its fields are drawn.
local function KnownBlock(node)
	return type(node) == 'table' and node.op == nil and type(node.block) == 'string' and R.BlockType(node.block) ~= nil
end

local function NotLook(box, on)
	box.on = on
	if on then
		box.text:SetTextColor(Colors().text.blue:GetRGB())
	else
		box.text:SetTextColor(Grey())
	end
	W.Edge(box, on)
end

-- An item on the cursor joins the Item is one of block of row i.
local function TakeCursorItem(w, i)
	local record = w.rows[i]
	if w.disabled or not w.row or not record or record.kind ~= 'block' then return end
	if not (KnownBlock(record.node) and record.node.block == 'items') then return end
	local kind, id = GetCursorInfo()
	if kind ~= 'item' or not is_num(id) then return end
	ClearCursor()
	AddItem(w, record.path, id)
end

local StartDrag, EndDrag

-- Row frame i: made once, used for the outline's row i on every layout,
-- which places it (rows above it may take more than one line).
local function RowFrame(w, i)
	local f = w.rowFrames[i]
	if f then return f end
	f = CreateFrame('Button', nil, w.frame)
	f:SetHeight(ROW_HEIGHT)
	f:RegisterForClicks('LeftButtonUp')
	f:SetScript('OnClick', function() TakeCursorItem(w, i) end)
	f:SetScript('OnReceiveDrag', function() TakeCursorItem(w, i) end)
	f.controls, f.used = {}, {}

	f.tint = f:CreateTexture(nil, 'BACKGROUND')
	f.tint:SetPoint('BOTTOMRIGHT', f, 'BOTTOMRIGHT', 0, 0)
	f.tint:Hide()

	f.connector = f:CreateTexture(nil, 'ARTWORK')
	f.connector:SetSize(CONNECTOR, LINE_WIDTH)

	local handle = D.Handle(f, FIELD_HEIGHT)
	handle:SetScript('OnMouseDown', function(_, button)
		if button == nil or button == 'LeftButton' then StartDrag(w, i) end
	end)
	handle:SetScript('OnMouseUp', function(_, button)
		if button == nil or button == 'LeftButton' then EndDrag(w) end
	end)
	f.handle = handle

	local notBox = W.Box(st:CreateFrame('Button', nil, f))
	notBox:SetSize(NOT_WIDTH, NOT_HEIGHT)
	notBox.text = Text(notBox, OB.Font('caption'))
	notBox.text:SetPoint('CENTER', notBox, 'CENTER', 0, 0)
	notBox.text:SetText('NOT')
	notBox:SetScript('OnEnter', function(self) W.Edge(self, true) end)
	notBox:SetScript('OnLeave', function(self) W.Edge(self, self.on) end)
	notBox:SetScript('OnClick', function()
		local record = w.rows[i]
		if record then Edit(w, function(rule) return R.ToggleNot(rule, record.path) end) end
	end)
	f.notBox = notBox

	f.label = Text(f)

	local remove = CreateFrame('Button', nil, f)
	remove:SetSize(REMOVE_SIZE, REMOVE_SIZE)
	remove:SetPoint('RIGHT', f, 'TOPRIGHT', 0, -ROW_HEIGHT / 2) -- on the first line
	remove.icon = remove:CreateTexture(nil, 'OVERLAY')
	remove.icon:SetTexture(st.textures.close)
	remove.icon:SetTexCoord(unpack(st.CLOSE_X_COORDS))
	remove.icon:SetSize(10, 10)
	remove.icon:SetPoint('CENTER', remove, 'CENTER', 0, 0)
	remove:SetScript('OnEnter', function(self) self.icon:SetVertexColor(Colors().text.red:GetRGB()) end)
	remove:SetScript('OnLeave', function(self) self.icon:SetVertexColor(Grey()) end)
	remove:SetScript('OnClick', function()
		local record = w.rows[i]
		if record then Edit(w, function(rule) return R.Remove(rule, record.path) ~= nil end) end
	end)
	f.remove = remove

	w.rowFrames[i] = f
	return f
end

local function HideRow(f)
	wipe(f.used)
	HideUnused(f)
	f:Hide()
end

-- Lays outline row i out top down from the editor's top, and returns its
-- height (its lines of ROW_HEIGHT).
local function LayRow(w, i, row, top)
	local f = RowFrame(w, i)
	local level = w.frame:GetFrameLevel()
	f:SetFrameLevel(level + 1)
	f:ClearAllPoints()
	f:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', 0, -top)
	f:SetPoint('TOPRIGHT', w.frame, 'TOPRIGHT', 0, -top)
	f:Show()
	wipe(f.used)
	local record = {
		frame = f, path = row.path, kind = row.kind, depth = row.depth, node = row.node, op = row.op, top = top,
		handle = f.handle, notBox = f.notBox, remove = f.remove, label = f.label, tint = f.tint,
		connector = f.connector, captions = {}, fields = {},
	}
	w.rows[i] = record

	local lineX = row.depth * INDENT + LINE_X
	local x = lineX + CONTENT_X
	f.connector:SetColorTexture(OpColor(row.op))
	f.connector:ClearAllPoints()
	f.connector:SetPoint('TOPLEFT', f, 'TOPLEFT', lineX, -(ROW_HEIGHT - LINE_WIDTH) / 2)
	f.tint:SetPoint('TOPLEFT', f, 'TOPLEFT', x - 4, 0)
	local r, g, b = Colors().text.orange:GetRGB()
	f.tint:SetColorTexture(r, g, b, TINT_ALPHA)

	local known = row.kind == 'group' or (row.kind == 'block' and KnownBlock(row.node))
	f:EnableMouse(row.kind == 'block' and known and row.node.block == 'items')
	f.handle:SetShown(known)
	f.notBox:SetShown(known)
	f.remove:SetShown(row.kind ~= 'add')
	f.label:SetShown(row.kind ~= 'add')
	f.remove.icon:SetVertexColor(Grey())
	for _, part in ipairs({ f.handle, f.notBox, f.remove }) do part:SetFrameLevel(level + 2) end

	if known then
		f.handle:ClearAllPoints()
		f.handle:SetPoint('TOPLEFT', f, 'TOPLEFT', x, -2)
		x = x + HANDLE_WIDTH + GAP
		f.notBox:ClearAllPoints()
		f.notBox:SetPoint('TOPLEFT', f, 'TOPLEFT', x, -(ROW_HEIGHT - NOT_HEIGHT) / 2)
		NotLook(f.notBox, type(row.node) == 'table' and row.node.negate == true)
		x = x + NOT_WIDTH + GAP
	end
	-- A field that doesn't fit before the X (or, on an add row, the end) goes
	-- on a line under the first, starting under the label.
	local wrapX = x
	local limit = w.frame:GetWidth() - (row.kind ~= 'add' and REMOVE_SIZE + GAP or 0)
	if row.kind ~= 'add' then
		local label = 'Unknown block'
		if row.kind == 'group' then
			label = 'group'
		elseif known then
			label = R.BlockType(row.node.block).label
		end
		f.label:SetText(label)
		f.label:SetTextColor(Grey())
		f.label:ClearAllPoints()
		f.label:SetPoint('LEFT', f, 'TOPLEFT', x, -ROW_HEIGHT / 2)
		x = x + TextWidth(f.label) + 8
	end

	local lay = setmetatable({
		w = w, f = f, record = record, x = x, path = row.path, node = row.node,
		line = 0, wrapX = wrapX, limit = limit,
	}, Lay)
	if row.kind == 'add' then
		local path = row.path
		lay:Add('addBlock', '+ Block', function(button)
			W.OpenList(button, BLOCK_ENTRIES, nil, function(id)
				Edit(w, function(rule) return R.Insert(rule, path, nil, R.NewBlock(id)) end)
			end)
		end)
		lay:Add('addGroup', '+ Group', function()
			Edit(w, function(rule)
				local group = R.NodeAt(rule, path)
				return R.Insert(rule, path, nil, R.NewGroup(group and group.op))
			end)
		end)
	elseif row.kind == 'block' and known and FIELDS[row.node.block] then
		FIELDS[row.node.block](lay, row.node)
	end
	for _, list in pairs(f.controls) do
		for _, control in ipairs(list) do
			if control.SetFrameLevel then control:SetFrameLevel(level + 2) end
		end
	end
	HideUnused(f)
	record.height = (lay.line + 1) * ROW_HEIGHT
	f:SetHeight(record.height)
	return record.height
end

-- Each group's line and badge, on its add row: the line from its first
-- row's top to its add row's middle, the badge centered on it.
local function GroupParts(w, g)
	local parts = w.groupParts[g]
	if parts then return parts end
	parts = {}
	parts.line = w.frame:CreateTexture(nil, 'ARTWORK')
	local badge = W.Box(st:CreateFrame('Button', nil, w.frame))
	badge:SetSize(BADGE_WIDTH, BADGE_HEIGHT)
	badge.text = Text(badge, OB.Font('caption'))
	badge.text:SetPoint('CENTER', badge, 'CENTER', 0, 0)
	badge:SetScript('OnEnter', function(self) self.text:SetAlpha(0.7) end)
	badge:SetScript('OnLeave', function(self) self.text:SetAlpha(1) end)
	badge:SetScript('OnClick', function(self)
		local path = self.path
		if path then Edit(w, function(rule) return R.Flip(rule, path) end) end
	end)
	parts.badge = badge
	w.groupParts[g] = parts
	return parts
end

local function PathKey(path) return tconcat(path, ',') end

local function LayGroups(w)
	local titles, g = {}, 0
	local level = w.frame:GetFrameLevel()
	for i, record in ipairs(w.rows) do
		if record.kind == 'group' then titles[PathKey(record.path)] = i end
		if record.kind == 'add' then
			g = g + 1
			local parts = GroupParts(w, g)
			local first = #record.path == 0 and 1 or (titles[PathKey(record.path)] + 1)
			local top = w.rows[first].top
			local bottom = record.top + ROW_HEIGHT / 2
			local lineX = record.depth * INDENT + LINE_X
			local r, gr, b = OpColor(record.op)

			local line = parts.line
			line:SetColorTexture(r, gr, b)
			line:ClearAllPoints()
			line:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', lineX, -top)
			line:SetSize(LINE_WIDTH, bottom - top)
			line:Show()

			local badge = parts.badge
			badge.path, badge.line = record.path, line
			badge.text:SetText(record.op == 'or' and 'OR' or 'AND')
			badge.text:SetTextColor(r, gr, b)
			badge.text:SetAlpha(1)
			badge:SetBackdropBorderColor(r, gr, b)
			badge:ClearAllPoints()
			local middle = floor((top + bottom) / 2)
			badge:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', lineX + LINE_WIDTH / 2 - BADGE_WIDTH / 2, -(middle - BADGE_HEIGHT / 2))
			badge:SetFrameLevel(level + 4)
			badge:Show()
			record.badge = badge
		end
	end
	for k = g + 1, #w.groupParts do
		w.groupParts[k].line:Hide()
		w.groupParts[k].badge:Hide()
		w.groupParts[k].badge.path = nil
	end
end

local function ApplyHighlight(w)
	local key = w.highlight and #w.highlight > 0 and PathKey(w.highlight)
	for _, record in ipairs(w.rows) do
		record.tint:SetShown(key ~= nil and key ~= false and record.kind ~= 'add' and PathKey(record.path) == key)
	end
end

local function Layout(w)
	local owner = W.ListOwner()
	if owner and Inside(owner, w.frame) then W.CloseList() end
	local rows = R.Outline(Current(w))
	w.outline = rows
	wipe(w.rows)
	local top = 0
	for i, row in ipairs(rows) do top = top + LayRow(w, i, row, top) end
	for i = #rows + 1, #w.rowFrames do HideRow(w.rowFrames[i]) end
	LayGroups(w)
	w.over:SetFrameLevel(w.frame:GetFrameLevel() + 6)
	w.frame:SetHeight(max(ROW_HEIGHT, top))
	ApplyHighlight(w)
end

------------------------------------------------------------------ dragging

-- The drop spot under the cursor, when the drag would move something there.
local function DropSpot(w)
	local drag = w.drag
	local i, lower = D.UnderCursor(w.rows)
	if not (drag and i) then return nil end
	local parentPath, index = R.DropAt(w.outline, i, lower)
	if not parentPath or not R.Move(R.Copy(Current(w)), drag.path, parentPath, index) then return nil end
	return i, lower, parentPath, index
end

-- Draws the drag: the ghost by the cursor, the insertion line where the
-- node would go. Only drawing: the drop is worked out again on the mouse up.
local function DrawDrag(w)
	if not w.drag or not w.row then return end
	D.PlaceGhost(w.ghost)
	local i, lower, parentPath = DropSpot(w)
	if not i then return w.insert:Hide() end
	local top = w.rows[i].top
	if lower and w.rows[i].kind ~= 'add' then top = top + w.rows[i].height end
	local left = #parentPath * INDENT + LINE_X + CONTENT_X - 4
	w.insert:ClearAllPoints()
	w.insert:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', left, -(top - 1))
	w.insert:SetPoint('TOPRIGHT', w.frame, 'TOPRIGHT', 0, -(top - 1))
	w.insert:Show()
end

local StopDrag = D.StopDrag

function StartDrag(w, i)
	local record = w.rows[i]
	if w.disabled or not w.row or not record or (record.kind ~= 'block' and record.kind ~= 'group') then return end
	w.drag = { path = record.path }
	D.ShowGhost(w, record.label:GetText() or '', FIELD_HEIGHT)
	DrawDrag(w)
	-- The window waits to draw again until the mouse is let go.
	if w.onChanged then w.onChanged(true, nil, true, w) end
end

function EndDrag(w)
	if not w.drag then return end
	local from = w.drag.path
	local i, _, parentPath, index = DropSpot(w)
	StopDrag(w)
	if not i then return end
	Edit(w, function(rule) return R.Move(rule, from, parentPath, index) end)
end

------------------------------------------------------------------ the type

W.Define('bagrule', {
	bare = true,
	titled = true,
	build = function(w)
		local frame = CreateFrame('Frame', nil, UIParent)
		frame:SetSize(1, ROW_HEIGHT)
		w.frame = frame
		w.rows, w.rowFrames, w.groupParts = {}, {}, {}
		-- Over the rows: the insertion line a drag draws.
		local over = CreateFrame('Frame', nil, frame)
		over:SetAllPoints(frame)
		w.over = over
		w.insert = over:CreateTexture(nil, 'OVERLAY')
		w.insert:SetHeight(2)
		w.insert:Hide()
		w.drawDrag = function() DrawDrag(w) end
	end,
	methods = {
		Refresh = function(w) Layout(w) end,

		-- The body's width (a bare row). Rows wrap at the width, so a new one
		-- lays them out again.
		SetWidth = function(w, width)
			if width == w.frame:GetWidth() then return end
			w.frame:SetWidth(width)
			if w.row then Layout(w) end
		end,

		-- Tints the row at path (a block or a group's title), or none for nil.
		SetHighlight = function(w, path)
			w.highlight = type(path) == 'table' and R.Copy(path) or nil
			ApplyHighlight(w)
		end,

		OnRelease = function(w)
			StopDrag(w)
			local owner = W.ListOwner()
			if owner and Inside(owner, w.frame) then W.CloseList() end
			for _, f in ipairs(w.rowFrames) do HideRow(f) end
			for _, parts in ipairs(w.groupParts) do
				parts.line:Hide()
				parts.badge:Hide()
				parts.badge.path = nil
			end
			wipe(w.rows)
			w.outline, w.highlight = nil, nil
		end,
	},
})
