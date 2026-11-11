local st = SaftUI
local INV = st:GetModule('Inventory')

--[[
	The Categories tab in /sui > Bags (options.lua's categories row), as the
	approved mockup lays it out: the category list on the left, the selected
	category's editor on the right. Two widget types (W.Define):

	  { type = 'bagcategories', size = 'wide', name, desc }
	      the whole tab: bare and fill (W.Define), the body's width (774) and
	      the height its view leaves, so the body has nothing to scroll
	  { type = 'bagitems', size = 'wide', name, desc,
	    items = function(info) -> { { itemID, info } } end,
	    onRemove = function(itemID) end,     an X on each icon unpins it, or
	    onHover = function(entry | nil) end } the mouse on an icon, then off it
	      a strip of item icons (Pinned items, Caught now): bare and titled

	The list, 210 wide: a 22 high row per category in order, each with a
	handle (6 dots; Miscellaneous has none), its name, an 'edited' or 'yours'
	marker in orange, and its count in grey at the right when above 0 (what
	the bag window's Compact header shows: INV:CountCategories). A category
	that is off is grey, with a 1px line through its name. The selected row is
	tinted blue, with a 3px blue bar at its left. Under the list, + New
	category and Reset all, in blue. A click on a row selects it. Dragging a
	handle moves the category (INV:MoveCategory) above the row under the
	cursor, or below it from its lower half, but never below Miscellaneous;
	the drag holds the window's render as the rule editor's does, and the drop
	is worked out on the mouse up (OnUpdate only draws the ghost and the line,
	and scrolls the list while the cursor is held near its top or bottom
	edge). The handle, the ghost and the row under the cursor are the rule
	editor's (INV.DragParts, ruleeditor.lua), with its text helpers.

	The editor, from x 234 and 540 wide, is an options body of its own drawing
	INV:CategoryEditorOptions(selected). Its widgets' onChanged goes on to the
	tab's own, with the tab as the dragged widget while one drags (the rule
	editor's handles), so the window refreshes nothing in the tab until the
	mouse is let go; and the tab lays nothing out again while either drags.

	The list and the editor each scroll on their own, the mouse wheel over one
	scrolling that one, each with the window's 3px bar (OB.ScrollTo) shown
	only when it has something to scroll: the list's 4 to its right, short of
	the divider, the editor's 10 to its right, where the body's own would be
	(a fill page's body reaches over it). The list's view stops short of its
	footer, so + New category and Reset all stay under it, right under the
	last row when every row fits. Each keeps its scroll while the tab is drawn
	again; the editor starts at its top for another category, and the list
	brings the selected row into view when it changes (another selected, or
	the one selected moved: + New category, Restore a default, a drag).

	  INV.categoryEditor.selected       the selected id, for the session. One
	                                    that is gone (a delete, a profile
	                                    switch) gives way to the first category.
	  INV.categoryEditor.listOffset, editorOffset
	                                    each pane's scroll, for the session
	  INV.categoriesTabShown            true while a bagcategories widget is
	                                    bound: a bag update then refreshes /sui
	                                    (inventory.lua's UpdateHandler).
	  INV:CountCategories(windowId) -> counts, items   by key, read as Compact
	                                    reads the window, counting no tooltip tries
	  INV:CategoryEditorOptions(id, tab, items) -> the editor's group (tab,
	                                    the widget, gets Caught now's hover;
	                                    items, the bags as the tab read them)
	  INV:EditCategory(key)             /sui at this tab, key's category
	                                    selected ('Set: ...' selects the sets entry)

	  widget.rows[i] = { frame, id, entry, handle, name, marker, count, strike, tint, bar }
	  widget.addButton, widget.resetButton (each with .text), widget.list
	  (the rows, the scroll child of widget.listScroll), widget.listBar,
	  widget.pane (the editor's rows, the scroll child of widget.editorScroll),
	  widget.editorBar, widget.body (the editor's body), widget:EditorCell(key)
	  bagitems: widget.icons[i] = a button { texture, remove (.icon), entry }

	Every change goes through the store's setters (categories.lua), which copy
	what they keep. Every frame here is SaftUI's; item tooltips are
	GameTooltip's, through its public API.
]]

local W, OB, OM = st.OptionsWidgets, st.OptionsBody, st.OptionsModel
-- The rule editor's (ruleeditor.lua): its text helpers and how it drags.
local D = INV.DragParts
local Colors, Grey, Text, TextWidth, Inside = D.Colors, D.Grey, D.Text, D.TextWidth, D.Inside

local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min
local format = string.format

INV.categoryEditor = { selected = nil, listOffset = 0, editorOffset = 0 }
INV.categoriesTabShown = false

------------------------------------------------------------------ the look

local LIST_WIDTH = 210
local EDITOR_X, EDITOR_WIDTH = 234, 540
local DIVIDER_X = 222 -- in the middle of the gap between the panes
local ROW_HEIGHT = 22
local PAD = 8 -- a row's contents from its edges
local GAP = 6
local BAR_WIDTH = 3
local FOOTER_GAP = 8
local FOOTER_HEIGHT = FOOTER_GAP + ROW_HEIGHT -- + New category and Reset all, under the list
local LIST_BAR_GAP = 4 -- the list's scroll bar, between it and the divider
local LIST_STEP = 3 * ROW_HEIGHT -- a turn of the wheel over the list
local MIN_HEIGHT = 10 * ROW_HEIGHT + FOOTER_HEIGHT -- the tab's least: ten rows and the footer
local EDGE = ROW_HEIGHT -- a drag held this near the list's top or bottom edge scrolls it,
local EDGE_SPEED = 12 * ROW_HEIGHT -- this far a second
local TINT_ALPHA, HOVER_ALPHA = 0.25, 0.1
local ICON_SIZE, ICON_GAP = 30, 6
local REMOVE_SIZE = 14
local QUESTION_MARK = 134400 -- Interface\Icons\INV_Misc_QuestionMark

local function Normal() return Colors().text.normal:GetRGB() end

local function IsSetKey(key)
	return type(key) == 'string' and key:sub(1, 5) == 'Set: '
end

------------------------------------------------------------------ counting

-- What a window's bags hold by category key, read as Compact reads them
-- (stacks merged as INV:GetSortedInventory merges them), so a count is what
-- the window's header shows: counts[key] and items[key], the item infos in
-- bag order (each with its category and categoryWhy). Empty for a window
-- that isn't made. A read only to show them (ReadBags' peek): an item
-- waiting for its tooltip uses up none of its tries, however often the tab
-- is drawn.
function INV:CountCategories(windowId)
	local counts, items = {}, {}
	if not self.containers[windowId] then return counts, items end
	local bags, _, _, categoryOf = self:ReadBags(windowId, function(bagID) return self:StackGroup(bagID) end, nil, true)
	for _, bag in ipairs(bags) do
		for _, info in ipairs(bag.items) do
			local key = categoryOf[info]
			if key ~= nil then
				counts[key] = (counts[key] or 0) + 1
				items[key] = items[key] or {}
				items[key][#items[key] + 1] = info
			end
		end
	end
	return counts, items
end

-- An entry's count, and its items: the sets entry's are every set's.
local function EntryCount(counts, entry)
	if entry.kind ~= 'sets' then return counts[entry.id] or 0 end
	local n = 0
	for key, count in pairs(counts) do
		if IsSetKey(key) then n = n + count end
	end
	return n
end

local function EntryItems(items, entry)
	if entry.kind ~= 'sets' then return items[entry.id] or {} end
	local keys, out = {}, {}
	for key in pairs(items) do
		if IsSetKey(key) then keys[#keys + 1] = key end
	end
	table.sort(keys)
	for _, key in ipairs(keys) do
		for _, info in ipairs(items[key]) do out[#out + 1] = info end
	end
	return out
end

------------------------------------------------------------------ the editor's options

local WINDOW_NAMES = { bag = 'Bags', bank = 'Bank', warband = 'Warband bank', combinedbank = 'Combined bank' }

local NOTES = {
	sets = 'Makes a category for each equipment set, "Set: <name>", for the armor and weapons in it. It has no rule.',
	misc = 'Catches every item no category above it catches. It is always last.',
}

-- A name another category doesn't have (in any case), and not empty.
local function ValidName(id, value)
	local name = type(value) == 'string' and value:match('^%s*(.-)%s*$') or ''
	if name == '' then return 'Enter a name.' end
	local lower = name:lower()
	for _, other in ipairs(INV:GetCategoryList()) do
		if other.id ~= id and other.name:lower() == lower then
			return format('Another category is already called %s.', other.name)
		end
	end
	return true
end

-- The item infos by item ID (of CountCategories' items), for the pins in the bags.
local function BagInfos(items)
	local byItem = {}
	for _, list in pairs(items) do
		for _, info in ipairs(list) do
			if info.itemID ~= nil and not byItem[info.itemID] then byItem[info.itemID] = info end
		end
	end
	return byItem
end

--[[
	The editor of the list category id: a group of its options (the Name, On,
	Show in, its rule or a note, Pinned items, Caught now, Reset and Delete
	rows), each reading the store at call time and writing through its setters.
	Which rows there are follows the category as it is now: the tab builds it
	again on every draw. tab, when given, is the bagcategories widget whose
	rule editor a Caught now hover highlights in, and items the bag window's
	items by key (INV:CountCategories) that the tab read for this draw; without
	them, Pinned items and Caught now read the bags once, when first drawn.
]]
function INV:CategoryEditorOptions(id, tab, items)
	local function Entry() return INV:GetCategoryList().byId[id] end
	local entry = Entry()
	if not entry then return { type = 'group', name = '', args = {} } end
	local function Items()
		if not items then items = select(2, INV:CountCategories('bag')) end
		return items
	end

	local windows, sorting = { bag = WINDOW_NAMES.bag, bank = WINDOW_NAMES.bank }, { 'bag', 'bank' }
	if self:HasWarbandBank() then
		windows.warband, windows.combinedbank = WINDOW_NAMES.warband, WINDOW_NAMES.combinedbank
		sorting = { 'bag', 'bank', 'warband', 'combinedbank' }
	end

	local args = {
		name = {
			order = 1,
			type = 'input',
			name = 'Name',
			desc = 'What the category is called in the bag windows. Renaming it keeps its place, its Show in choices and its pinned items.',
			get = function() local e = Entry(); return e and e.name end,
			set = function(_, value) INV:RenameCategory(id, value) end,
			validate = function(_, value) return ValidName(id, value) end,
		},
		show = {
			order = 3,
			type = 'multiselect',
			name = 'Show in',
			desc = 'The windows that show this category. A hidden category still catches its items; One bag and Multi bag show every item.',
			values = windows,
			sorting = sorting,
			get = function(_, window) local e = Entry(); return not (e and e.hide[window]) end,
			set = function(_, window, on) INV:SetCategoryHidden(window, id, not on) end,
		},
		pins = {
			order = 20,
			type = 'bagitems',
			size = 'wide',
			name = 'Pinned items',
			desc = 'Items you added to this category from the slot menu (Ctrl + right click an item). They go here whatever the rules say. Click the X on one to unpin it.',
			hidden = function() return #INV:GetPinnedItems(id) == 0 end,
			items = function()
				local byItem, out = BagInfos(Items()), {}
				for i, itemID in ipairs(INV:GetPinnedItems(id)) do out[i] = { itemID = itemID, info = byItem[itemID] } end
				return out
			end,
			onRemove = function(itemID) INV:UnpinItem(itemID) end,
		},
		caught = {
			order = 30,
			type = 'bagitems',
			size = 'wide',
			name = 'Caught now',
			desc = 'The items in your bags this category catches now. Hover one to see which block caught it.',
			items = function()
				local e, out = Entry(), {}
				if not e then return out end
				for i, info in ipairs(EntryItems(Items(), e)) do out[i] = { itemID = info.itemID, info = info } end
				return out
			end,
			onHover = function(item)
				if tab and tab.row then tab:HighlightWhy(item) end
			end,
		},
	}

	-- Miscellaneous catches whatever is left: always on.
	if entry.kind ~= 'misc' then
		local desc = 'Turned off, the items it would catch go to the next category that catches them.'
		if entry.sells then desc = desc .. ' Turned off, auto vendor sells nothing.' end
		args.enabled = {
			order = 2,
			type = 'toggle',
			size = 'small',
			name = 'On',
			desc = desc,
			get = function() local e = Entry(); return e and e.enabled end,
			set = function(_, on) INV:SetCategoryEnabled(id, on) end,
		}
	end

	if entry.kind == 'rule' then
		args.rule = {
			order = 10,
			type = 'bagrule',
			size = 'wide',
			name = 'Catches an item when',
			desc = 'An item goes to the first category, from the top of the list, whose rule it matches. AND needs every block, OR any one. Click AND or OR to flip it, and drag a block by its handle to move it.',
			get = function() local e = Entry(); return e and e.rule end,
			set = function(_, rule) INV:SetCategoryRule(id, rule) end,
		}
	else
		args.note = { order = 10, type = 'description', name = NOTES[entry.kind] }
	end

	if entry.default then
		args.reset = {
			order = 40,
			type = 'execute',
			name = format('Reset %s to default', entry.name),
			desc = 'Put this category back as SaftUI ships it: its name, on or off, Show in and rule. Its pinned items stay.',
			disabled = function() local e = Entry(); return not (e and e.edited) end,
			func = function() INV:ResetCategory(id) end,
		}
	end

	-- Not Miscellaneous, the sets entry or Grays/Auto Vendor, which the bags need.
	if entry.kind == 'rule' and not entry.sells then
		args.delete = {
			order = 41,
			type = 'execute',
			name = 'Delete',
			desc = 'Delete this category. Its items go to the next category that catches them.',
			confirm = function()
				local e = Entry()
				local name = e and e.name or id
				if e and e.default then
					return format('Delete %s? You can bring it back with + New category > Restore a default..., or Reset all.', name)
				end
				return format('Delete %s? Items pinned to it go back to the rules.', name)
			end,
			-- The selection moves to the category that takes its place.
			func = function()
				local gone = Entry()
				if not (gone and INV:RemoveCategory(id)) then return end
				local list = INV:GetCategoryList()
				local now = list[min(gone.place, #list)]
				INV.categoryEditor.selected = now and now.id
			end,
		}
	end

	return { type = 'group', name = entry.name, args = args }
end

-- /sui at the Categories tab, with key's category selected: a list id, or
-- the sets entry for an equipment set's 'Set: ...' key. The list shows its
-- row, even when it was already the selected one.
function INV:EditCategory(key)
	local byId = self:GetCategoryList().byId
	local entry = byId[key]
	if not entry and IsSetKey(key) then entry = byId[self.SETS_ENTRY] end
	if entry then
		self.categoryEditor.selected = entry.id
		self.categoryEditor.reveal = true
	end
	st.Config:Open('Inventory', 'categories')
end

------------------------------------------------------------------ the tab: its pieces

-- The window draws the tab again (a selection, an add, a move).
local function Changed(w)
	if w.onChanged then w.onChanged(true) end
end

-- The editor's widgets tell the window through the tab, which is the dragged
-- widget while one of them drags.
local function Forward(w, ok, err, isDragging)
	if not w.onChanged then return end
	if isDragging then return w.onChanged(ok, err, true, w) end
	return w.onChanged(ok, err)
end

-- Whether a widget in the editor is being dragged (the rule editor's handle).
local function EditorDragging(w)
	for _, cell in ipairs(w.body.cells) do
		if cell.widget and cell.widget.drag then return true end
	end
	return false
end

-- The selected id, the first category's when it isn't in the list.
local function Selected(list)
	local id = INV.categoryEditor.selected
	if not (id and list.byId[id]) then
		id = list[1] and list[1].id
		INV.categoryEditor.selected = id
	end
	return id
end

-- + New category and Reset all: blue text that runs run(button).
local function Action(parent, text, run)
	local button = CreateFrame('Button', nil, parent)
	button.text = Text(button, W.GetFont())
	button.text:SetPoint('LEFT', button, 'LEFT', 0, 0)
	button.text:SetText(text)
	button:SetScript('OnEnter', function(self) self.text:SetAlpha(0.7) end)
	button:SetScript('OnLeave', function(self) self.text:SetAlpha(1) end)
	button:SetScript('OnClick', function(self) run(self) end)
	return button
end

local StartDrag, EndDrag

local function Select(w, i)
	local record = w.rows[i]
	if not (w.row and record) or w.drag then return end
	if INV.categoryEditor.selected == record.id then return end
	INV.categoryEditor.selected = record.id
	Changed(w)
end

-- Row frame i of the list: made once, used for the list's row i every time.
local function ListRow(w, i)
	local f = w.rowFrames[i]
	if f then return f end
	f = CreateFrame('Button', nil, w.list)
	f:SetHeight(ROW_HEIGHT)
	f:SetPoint('TOPLEFT', w.list, 'TOPLEFT', 0, -(i - 1) * ROW_HEIGHT)
	f:SetPoint('TOPRIGHT', w.list, 'TOPRIGHT', 0, -(i - 1) * ROW_HEIGHT)
	f:RegisterForClicks('LeftButtonUp')
	f:SetScript('OnClick', function() Select(w, i) end)
	f.hover = f:CreateTexture(nil, 'BACKGROUND')
	f.hover:SetAllPoints(f)
	f.hover:Hide()
	f:SetScript('OnEnter', function(self) self.hover:Show() end)
	f:SetScript('OnLeave', function(self) self.hover:Hide() end)
	f.tint = f:CreateTexture(nil, 'BACKGROUND')
	f.tint:SetAllPoints(f)
	f.bar = f:CreateTexture(nil, 'ARTWORK')
	f.bar:SetPoint('TOPLEFT', f, 'TOPLEFT', 0, 0)
	f.bar:SetPoint('BOTTOMLEFT', f, 'BOTTOMLEFT', 0, 0)
	f.bar:SetWidth(BAR_WIDTH)
	f.handle = D.Handle(f, ROW_HEIGHT)
	f.handle:SetPoint('TOPLEFT', f, 'TOPLEFT', PAD, 0)
	f.handle:SetScript('OnMouseDown', function(_, button)
		if button == nil or button == 'LeftButton' then StartDrag(w, i) end
	end)
	f.handle:SetScript('OnMouseUp', function(_, button)
		if button == nil or button == 'LeftButton' then EndDrag(w) end
	end)
	f.name = Text(f, W.GetFont())
	f.strike = f:CreateTexture(nil, 'OVERLAY')
	f.strike:SetHeight(1)
	f.marker = Text(f, OB.Font('small'))
	f.count = Text(f, OB.Font('small'), 'RIGHT')
	f.count:SetPoint('RIGHT', f, 'RIGHT', -PAD, 0)
	w.rowFrames[i] = f
	return f
end

-- The count at the right, the marker after the name, the name in what's left.
local function LayListRow(w, i, entry, count, selected)
	local f = ListRow(w, i)
	f:SetFrameLevel(w.list:GetFrameLevel() + 1)
	f.handle:SetFrameLevel(f:GetFrameLevel() + 1)
	f:Show()
	local r, g, b = Colors().button.blue:GetRGB()
	f.hover:SetColorTexture(r, g, b, HOVER_ALPHA)
	f.tint:SetColorTexture(r, g, b, TINT_ALPHA)
	f.bar:SetColorTexture(r, g, b)
	f.tint:SetShown(selected)
	f.bar:SetShown(selected)
	f.handle:SetShown(entry.kind ~= 'misc')

	local x, right = PAD + D.HANDLE_WIDTH + GAP, LIST_WIDTH - PAD
	f.count:SetText(count > 0 and tostring(count) or '')
	f.count:SetTextColor(Grey())
	f.count:SetShown(count > 0)
	if count > 0 then right = right - TextWidth(f.count) - GAP end
	local marker = (not entry.default and 'yours') or (entry.edited and 'edited') or nil
	f.marker:SetText(marker or '')
	f.marker:SetTextColor(Colors().text.orange:GetRGB())
	f.marker:SetShown(marker ~= nil)
	if marker then right = right - TextWidth(f.marker) - GAP end

	f.name:SetText(entry.name)
	if entry.enabled then f.name:SetTextColor(Normal()) else f.name:SetTextColor(Grey()) end
	local nameWidth = max(1, min(TextWidth(f.name), right - x))
	f.name:SetWidth(nameWidth)
	f.name:ClearAllPoints()
	f.name:SetPoint('LEFT', f, 'LEFT', x, 0)
	f.marker:ClearAllPoints()
	f.marker:SetPoint('LEFT', f, 'LEFT', x + nameWidth + GAP, 0)
	-- Off: a line through the name, on a whole pixel.
	f.strike:SetColorTexture(Grey())
	f.strike:ClearAllPoints()
	f.strike:SetPoint('TOPLEFT', f, 'TOPLEFT', x, -floor(ROW_HEIGHT / 2))
	f.strike:SetWidth(nameWidth)
	f.strike:SetShown(not entry.enabled)

	w.rows[i] = {
		frame = f, id = entry.id, entry = entry, handle = f.handle, name = f.name, marker = f.marker,
		count = f.count, strike = f.strike, tint = f.tint, bar = f.bar,
	}
end

------------------------------------------------------------------ the tab: + New category, Reset all

local function Added(w, id)
	if id then INV.categoryEditor.selected = id end
	Changed(w)
end

-- One at once with no deleted default; else a list of New category and
-- Restore a default..., which lists the deleted defaults by name.
local function NewCategory(w, button)
	if not w.row or w.drag then return end
	if #INV:GetDeletedDefaults() == 0 then return Added(w, INV:AddUserCategory()) end
	W.OpenList(button, {
		{ key = 'new', label = 'New category' },
		{ key = 'restore', label = 'Restore a default...' },
	}, nil, function(key)
		if not w.row then return end
		if key == 'new' then return Added(w, INV:AddUserCategory()) end
		local entries = {}
		for i, def in ipairs(INV:GetDeletedDefaults()) do entries[i] = { key = def.id, label = def.name } end
		W.OpenList(button, entries, nil, function(id)
			if w.row and INV:RestoreCategory(id) then Added(w, id) end
		end)
	end)
end

local function ResetAll(w)
	if not w.row or w.drag then return end
	W.Confirm("Reset all categories to SaftUI's defaults? Your own categories are deleted. Pinned and Protected items are kept.", function()
		INV:ResetAllCategories()
		Changed(w)
	end)
end

------------------------------------------------------------------ the tab: scrolling

-- The list's rows' height: what it scrolls.
local function ListHeight(w) return #w.rows * ROW_HEIGHT end

-- offset moved the least that shows the row from top down (ROW_HEIGHT) in a
-- view view high.
local function Reveal(offset, top, view)
	if top < offset then return top end
	if top + ROW_HEIGHT > offset + view then return top + ROW_HEIGHT - view end
	return offset
end

-- The list to offset (the wheel, a drag held near an edge): it stays there,
-- the selected row no longer brought into view.
local function ScrollList(w, offset)
	local state = INV.categoryEditor
	state.listOffset = OB.ScrollTo(w.listScroll, w.listBar, offset, ListHeight(w), LIST_BAR_GAP)
	w.listBase, w.reveal = state.listOffset, nil
end

local function ScrollEditor(w, offset)
	local state = INV.categoryEditor
	state.editorOffset = OB.ScrollTo(w.editorScroll, w.editorBar, offset, w.editorHeight or 0)
	w.editorBase = state.editorOffset
end

--[[
	The panes in the tab's height: the list's view down to its footer, and no
	taller than its rows, so the footer sits right under the last row when
	they all fit; the editor's the whole height. Each is scrolled from where
	Layout found it (w.listBase, w.editorBase), the list to the selected row
	when Layout says so (w.reveal), so running this again (the body gives the
	tab its height after Layout) lands on the same spot for the new height.
]]
local function Fit(w)
	local height = max(1, w.frame:GetHeight())
	local state = INV.categoryEditor
	local rows = ListHeight(w)
	w.listScroll:SetHeight(max(1, min(rows, height - FOOTER_HEIGHT)))
	w.listScroll:UpdateScrollChildRect()
	local offset = w.listBase or state.listOffset
	if w.reveal then offset = Reveal(offset, (w.reveal - 1) * ROW_HEIGHT, w.listScroll:GetHeight()) end
	state.listOffset = OB.ScrollTo(w.listScroll, w.listBar, offset, rows, LIST_BAR_GAP)
	w.editorScroll:SetHeight(height)
	w.editorScroll:UpdateScrollChildRect()
	state.editorOffset = OB.ScrollTo(w.editorScroll, w.editorBar, w.editorBase or state.editorOffset, w.editorHeight or 0)
	w.divider:SetHeight(height)
end

------------------------------------------------------------------ the tab: dragging a row

-- While a drag is held near the list's top or bottom edge (EDGE inside or
-- outside it, over the list's width), the list scrolls that way, EDGE_SPEED
-- a second, in whole units: carry keeps the part of a unit a short frame left.
local function EdgeScroll(w, elapsed)
	local scroll = w.listScroll
	local left, right, bottom, top = scroll:GetLeft(), scroll:GetRight(), scroll:GetBottom(), scroll:GetTop()
	local direction
	if elapsed and left and ListHeight(w) > scroll:GetHeight() then
		local x, y = GetCursorPosition()
		local scale = scroll:GetEffectiveScale()
		x, y = x / scale, y / scale
		if x >= left and x <= right then
			if y > top - EDGE and y < top + EDGE then
				direction = -1
			elseif y < bottom + EDGE and y > bottom - EDGE then
				direction = 1
			end
		end
	end
	if not direction then
		w.carry = 0
		return
	end
	w.carry = (w.carry or 0) + elapsed * EDGE_SPEED
	local step = floor(w.carry)
	if step < 1 then return end
	w.carry = w.carry - step
	ScrollList(w, INV.categoryEditor.listOffset + direction * step)
end

-- The place the dragged category would take on the mouse up, and the row it
-- would go before, or nil when it wouldn't move: above the row under the
-- cursor, below it from its lower half, never below Miscellaneous (last).
-- Only a row in the list's view is under the cursor (D.UnderCursor).
local function DropSpot(w)
	local drag = w.drag
	local i, lower = D.UnderCursor(w.rows)
	if not (drag and i) then return end
	local before = min(lower and i + 1 or i, #w.rows)
	local place = before > drag.from and before - 1 or before
	if place == drag.from then return end
	return place, before
end

-- Draws the drag: the ghost by the cursor, the line where it would go (on
-- the rows, so it moves with the list's scroll). Each frame (elapsed, from
-- OnUpdate) first scrolls the list when the cursor is held near an edge.
local function DrawDrag(w, elapsed)
	if not w.drag or not w.row then return end
	EdgeScroll(w, elapsed)
	D.PlaceGhost(w.ghost)
	local place, before = DropSpot(w)
	if not place then return w.insert:Hide() end
	local top = (before - 1) * ROW_HEIGHT
	w.insert:ClearAllPoints()
	w.insert:SetPoint('TOPLEFT', w.list, 'TOPLEFT', 0, -(top - 1))
	w.insert:SetPoint('TOPRIGHT', w.list, 'TOPRIGHT', 0, -(top - 1))
	w.insert:Show()
end

local StopDrag = D.StopDrag

function StartDrag(w, i)
	local record = w.rows[i]
	if not (w.row and record) or w.drag or record.entry.kind == 'misc' then return end
	w.drag, w.carry = { id = record.id, from = i }, 0
	D.ShowGhost(w, record.entry.name, ROW_HEIGHT)
	DrawDrag(w)
	-- The window waits to draw again until the mouse is let go.
	if w.onChanged then w.onChanged(true, nil, true, w) end
end

function EndDrag(w)
	if not w.drag then return end
	local id = w.drag.id
	local place = DropSpot(w)
	StopDrag(w)
	if place and INV:MoveCategory(id, place) then Changed(w) end
end

------------------------------------------------------------------ the tab: laying it out

local function Layout(w)
	-- Nothing moves under the mouse: the drop is worked out on its up.
	if w.drag or EditorDragging(w) then return end
	INV.categoriesTabShown = true
	local owner = W.ListOwner()
	if owner and Inside(owner, w.listPane) then W.CloseList() end

	local list = INV:GetCategoryList()
	local selected = Selected(list)
	-- The bags, read once for the counts and the editor's item strips.
	local counts, items = INV:CountCategories('bag')
	local level = w.frame:GetFrameLevel()
	w.listPane:SetFrameLevel(level + 1)
	w.listScroll:SetFrameLevel(level + 2)
	w.list:SetFrameLevel(level + 3)
	wipe(w.rows)
	local place
	for i, entry in ipairs(list) do
		LayListRow(w, i, entry, EntryCount(counts, entry), entry.id == selected)
		if entry.id == selected then place = i end
	end
	for i = #list + 1, #w.rowFrames do w.rowFrames[i]:Hide() end
	w.list:SetHeight(max(1, ListHeight(w)))
	w.over:SetFrameLevel(w.list:GetFrameLevel() + 4) -- the drag's line, over the rows

	-- Under the list's view (Fit sizes it).
	local blue = Colors().text.blue
	local x = PAD
	for _, button in ipairs({ w.addButton, w.resetButton }) do
		button.text:SetTextColor(blue:GetRGB())
		button.text:SetAlpha(1)
		button:SetSize(TextWidth(button.text), ROW_HEIGHT)
		button:ClearAllPoints()
		button:SetPoint('TOPLEFT', w.listScroll, 'BOTTOMLEFT', x, -FOOTER_GAP)
		x = x + button:GetWidth() + 12
	end

	-- The list brings the selected row into view when it changed: another
	-- selected, or the selected one moved (or EditCategory asked for it).
	-- A draw that changed neither (a bag update) leaves the list where it is.
	local state = INV.categoryEditor
	w.reveal = nil
	if state.reveal or state.shownId ~= selected or state.shownPlace ~= place then w.reveal = place end
	state.reveal, state.shownId, state.shownPlace = false, selected, place
	w.listBase = state.listOffset

	w.body:Release()
	local root = { category = INV:CategoryEditorOptions(selected, w, items) }
	w.body:SetRoot(root)
	local view = OM.BuildView(root, 'category')
	w.editorScroll:SetFrameLevel(level + 1)
	w.pane:SetFrameLevel(level + 2)
	w.editorHeight = view and w.body:Draw(view.sections) or 0
	w.pane:SetHeight(max(1, w.editorHeight))
	-- Another category's editor starts at its top.
	if state.editorFor ~= selected then state.editorFor, state.editorOffset = selected, 0 end
	w.editorBase = state.editorOffset

	Fit(w)
end

W.Define('bagcategories', {
	bare = true,
	fill = true,
	minHeight = MIN_HEIGHT,
	build = function(w)
		local frame = CreateFrame('Frame', nil, UIParent)
		frame:SetSize(OB.WIDTH, MIN_HEIGHT)
		w.frame = frame

		-- The list: its rows (w.list) scroll in w.listScroll, its footer and
		-- bar under and beside it.
		w.listPane = CreateFrame('Frame', nil, frame)
		w.listPane:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
		w.listPane:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, 0)
		w.listPane:SetWidth(LIST_WIDTH)
		w.listScroll = CreateFrame('ScrollFrame', nil, w.listPane)
		w.listScroll:SetPoint('TOPLEFT', w.listPane, 'TOPLEFT', 0, 0)
		w.listScroll:SetSize(LIST_WIDTH, ROW_HEIGHT)
		w.list = CreateFrame('Frame', nil, w.listScroll)
		w.list:SetSize(LIST_WIDTH, ROW_HEIGHT)
		w.listScroll:SetScrollChild(w.list)
		w.listScroll:EnableMouseWheel(true)
		w.listScroll:SetScript('OnMouseWheel', function(_, delta)
			if w.row then ScrollList(w, INV.categoryEditor.listOffset - delta * LIST_STEP) end
		end)
		w.listBar = OB.ScrollBar(w.listPane)
		w.addButton = Action(w.listPane, '+ New category', function(button) NewCategory(w, button) end)
		w.resetButton = Action(w.listPane, 'Reset all', function() ResetAll(w) end)

		w.divider = frame:CreateTexture(nil, 'ARTWORK')
		w.divider:SetColorTexture(unpack(OB.LINE))
		w.divider:SetPoint('TOPLEFT', frame, 'TOPLEFT', DIVIDER_X, 0)
		w.divider:SetSize(1, ROW_HEIGHT)

		-- The editor: its body draws in w.pane, which scrolls in w.editorScroll.
		w.editorScroll = CreateFrame('ScrollFrame', nil, frame)
		w.editorScroll:SetPoint('TOPLEFT', frame, 'TOPLEFT', EDITOR_X, 0)
		w.editorScroll:SetSize(EDITOR_WIDTH, ROW_HEIGHT)
		w.pane = CreateFrame('Frame', nil, w.editorScroll)
		w.pane:SetSize(EDITOR_WIDTH, ROW_HEIGHT)
		w.editorScroll:SetScrollChild(w.pane)
		w.editorScroll:EnableMouseWheel(true)
		w.editorScroll:SetScript('OnMouseWheel', function(_, delta)
			if w.row then ScrollEditor(w, INV.categoryEditor.editorOffset - delta * OB.SCROLL_STEP) end
		end)
		w.editorBar = OB.ScrollBar(frame)
		w.body = OB.New(w.pane, nil, function(...) Forward(w, ...) end, EDITOR_WIDTH)

		w.rows, w.rowFrames = {}, {}
		-- Over the rows: the line a drag draws where the category would go.
		w.over = CreateFrame('Frame', nil, w.list)
		w.over:SetAllPoints(w.list)
		w.insert = w.over:CreateTexture(nil, 'OVERLAY')
		w.insert:SetHeight(2)
		w.insert:Hide()
		w.drawDrag = function(_, elapsed) DrawDrag(w, elapsed) end
	end,
	methods = {
		Refresh = function(w) Layout(w) end,

		-- The body's width (a bare row); the panes' are fixed.
		SetWidth = function(w, width) w.frame:SetWidth(width) end,

		-- The height the body's view leaves it (a fill row): the panes follow.
		SetHeight = function(w, height)
			w.frame:SetHeight(max(1, height))
			if w.row then Fit(w) end
		end,

		-- The editor's drawn row of an option key, or nil.
		EditorCell = function(w, key)
			for _, cell in ipairs(w.body.cells) do
				if cell.row.key == key then return cell end
			end
		end,

		-- A Caught now item under the mouse ({ itemID, info }), or nil: the
		-- rule editor tints the block that caught it.
		HighlightWhy = function(w, item)
			local cell = w:EditorCell('rule')
			if not (cell and cell.widget.SetHighlight) then return end
			local why = item and item.info and item.info.categoryWhy
			cell.widget:SetHighlight(why and why.kind == 'rule' and why.path or nil)
		end,

		OnRelease = function(w)
			StopDrag(w)
			local owner = W.ListOwner()
			if owner and Inside(owner, w.frame) then W.CloseList() end
			w.body:Release()
			for _, f in ipairs(w.rowFrames) do f:Hide() end
			wipe(w.rows)
			w.reveal, w.listBase, w.editorBase = nil, nil, nil
			INV.categoriesTabShown = false
		end,
	},
})

------------------------------------------------------------------ bagitems

local function ItemTexture(entry)
	local info = entry.info
	if info and info.texture then return info.texture end
	local icon = C_Item and C_Item.GetItemIconByID and C_Item.GetItemIconByID(entry.itemID)
	return icon or QUESTION_MARK
end

-- The item's tooltip: its bag slot's when it is in the bags, else its ID's.
local function ShowItem(w, icon)
	local entry = icon.entry
	if not (w.row and entry) then return end
	GameTooltip:SetOwner(icon, 'ANCHOR_RIGHT')
	local info = entry.info
	if info and info.bagID and info.slotID then
		GameTooltip:SetBagItem(info.bagID, info.slotID)
	else
		GameTooltip:SetItemByID(entry.itemID)
	end
	GameTooltip:Show()
	local onHover = w.row.option.onHover
	if type(onHover) == 'function' then onHover(entry) end
end

local function HideItem(w, icon)
	if GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
	local onHover = w.row and w.row.option.onHover
	if type(onHover) == 'function' then onHover(nil) end
end

local function RemoveItem(w, icon)
	local onRemove = w.row and w.row.option.onRemove
	if w.disabled or not icon.entry or type(onRemove) ~= 'function' then return end
	if GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
	onRemove(icon.entry.itemID)
	if w.onChanged then w.onChanged(true) end
end

-- Icon i: a button with the item's icon, drawn as the description's image
-- (an action button's, its border in SaftUI's theme outside it), and an X at
-- its top right.
local function ItemButton(w, i)
	local icon = w.icons[i]
	if icon then return icon end
	icon = CreateFrame('Button', nil, w.frame)
	icon:SetSize(ICON_SIZE, ICON_SIZE)
	icon.texture = icon:CreateTexture(nil, 'ARTWORK')
	icon.texture:SetAllPoints(icon)
	st:SetBackdrop(icon.texture, 'theme', 'theme', 'action')
	icon:SetScript('OnEnter', function(self) ShowItem(w, self) end)
	icon:SetScript('OnLeave', function(self) HideItem(w, self) end)
	local remove = CreateFrame('Button', nil, icon)
	remove:SetSize(REMOVE_SIZE, REMOVE_SIZE)
	remove:SetPoint('TOPRIGHT', icon, 'TOPRIGHT', 0, 0)
	remove.back = remove:CreateTexture(nil, 'BACKGROUND')
	remove.back:SetAllPoints(remove)
	remove.back:SetColorTexture(0, 0, 0, 0.7)
	remove.icon = remove:CreateTexture(nil, 'OVERLAY')
	remove.icon:SetTexture(st.textures.close)
	remove.icon:SetTexCoord(unpack(st.CLOSE_X_COORDS))
	remove.icon:SetSize(8, 8)
	remove.icon:SetPoint('CENTER', remove, 'CENTER', 0, 0)
	remove:SetScript('OnEnter', function(self) self.icon:SetVertexColor(Colors().text.red:GetRGB()) end)
	remove:SetScript('OnLeave', function(self) self.icon:SetVertexColor(Grey()) end)
	remove:SetScript('OnClick', function() RemoveItem(w, icon) end)
	icon.remove = remove
	w.icons[i] = icon
	return icon
end

local function HideIcon(icon)
	if GameTooltip and GameTooltip:IsOwned(icon) then GameTooltip:Hide() end
	icon.entry = nil
	icon:Hide()
end

-- The icons in lines as wide as the widget, each its border's width in.
local function LayItems(w)
	local list = OM.Member(w.root, w.row, 'items')
	if type(list) ~= 'table' then list = {} end
	local removable = type(w.row.option.onRemove) == 'function'
	local border = st:ThemeInset('theme', 'theme', 'action')
	local step = ICON_SIZE + 2 * border + ICON_GAP
	local perLine = max(1, floor((w.frame:GetWidth() + ICON_GAP) / step))
	local trim = st.config.profile.misc.icon_trim or 0
	local level = w.frame:GetFrameLevel()
	for i, entry in ipairs(list) do
		local icon = ItemButton(w, i)
		icon:SetFrameLevel(level + 2)
		-- Its border's frame under the icon again: a level change (or the
		-- widget moving to another row) puts a frame's children above it.
		if icon.texture.backdrop then icon.texture.backdrop:SetFrameLevel(level + 1) end
		icon.remove:SetFrameLevel(level + 3)
		icon.entry = entry
		icon.texture:SetTexture(ItemTexture(entry))
		icon.texture:SetTexCoord(st:IconTexCoords(trim))
		icon.remove:SetShown(removable)
		icon.remove.icon:SetVertexColor(Grey())
		local col, line = (i - 1) % perLine, floor((i - 1) / perLine)
		icon:ClearAllPoints()
		icon:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', border + col * step, -(border + line * step))
		icon:Show()
	end
	for i = #list + 1, #w.icons do HideIcon(w.icons[i]) end
	w.frame:SetHeight(max(1, ceil(#list / perLine) * step - ICON_GAP))
end

W.Define('bagitems', {
	bare = true,
	titled = true,
	build = function(w)
		local frame = CreateFrame('Frame', nil, UIParent)
		frame:SetSize(1, ICON_SIZE)
		w.frame = frame
		w.icons = {}
	end,
	methods = {
		Refresh = function(w) LayItems(w) end,

		-- The body's width (a bare row): the icons fill lines of it.
		SetWidth = function(w, width)
			if width == w.frame:GetWidth() then return end
			w.frame:SetWidth(width)
			if w.row then LayItems(w) end
		end,

		OnRelease = function(w)
			for _, icon in ipairs(w.icons) do HideIcon(icon) end
		end,
	},
})
