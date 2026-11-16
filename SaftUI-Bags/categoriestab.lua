local st = SaftUI
local INV = st:GetModule('Inventory')

--[[
	The Categories tab in /sui > Bags (options.lua's categories row), as the
	approved mockup lays it out: the category list on the left, the selected
	category's editor on the right. Two widget types (W.Define):

	  { type = 'bagcategories', size = 'wide', name, desc }
	      the whole tab: bare and fill (W.Define), the body's width (774 at full; 388, or 368
	      under Blizzard, at half) and the height its view leaves, so the body has nothing to scroll
	  { type = 'bagitems', size = 'wide', name, desc,
	    items = function(info) -> { { itemID, info } } end,
	    onRemove = function(itemID) end,     an X on each icon unpins it, or
	    onHover = function(entry | nil) end } the mouse on an icon, then off it
	      a strip of item icons (Pinned items, Caught now): bare and titled

	The list, 210 wide: a 22 high row per category in order, each with a
	handle (6 dots; Miscellaneous has none), its name, an 'edited' or 'yours'
	marker in Text > Muted, and its count in Text > Muted at the right when above 0 (what
	the bag window's Compact header shows: INV:CountCategories). A category
	that is off is Muted, with a 1px line through its name. The selected row is
	tinted in the accent, with a 3px accent bar at its left. Under the list, + New
	category in the accent, and the order's reset icon after it while the shipped
	categories are out of their order (INV:ResetCategoryOrder). A click on a row selects it. Dragging a
	handle moves the category (INV:MoveCategory) above the row under the
	cursor, or below it from its lower half, but never below Miscellaneous;
	the drag holds the window's render as the rule editor's does, and the drop
	is worked out on the mouse up (OnUpdate only draws the ghost and the line,
	and scrolls the list while the cursor is held near its top or bottom
	edge). The handle, the ghost and the row under the cursor are the ones
	the rule editor drags with (INV.DragParts, dragparts.lua), with their text
	helpers.

	The editor, from x 234 and 540 wide, is an options body of its own drawing
	INV:CategoryEditorOptions(selected), less Caught now and Pinned items
	(SplitFooter, FOOTER_KEYS): those two are its footer's, a body of its own
	at the bottom of the editor's column, Caught now above Pinned items, under
	an edge across its top (the body's 1px line; under Blizzard the Settings
	panel's divider). So a rule taller than the editor's view scrolls above
	the items it catches, which stay in view with the block a hovered one
	lights up. The footer is as tall as its strips and its edge, but at most
	half the tab; the editor's view is the rest. The bodies' widgets'
	onChanged goes on to the tab's own, with the tab as the dragged widget
	while one drags (the rule editor's handles), so the window refreshes
	nothing in the tab until the mouse is let go; and the tab lays nothing out
	again while either drags.

	The list, the editor and its footer each scroll on their own, the mouse
	wheel over one scrolling that one, each with the window's 3px bar
	(OB.ScrollTo) shown only when it has something to scroll: the list's 4 to
	its right, short of the divider, the editor's and the footer's 10 to their
	right, where the body's own would be (a fill page's body reaches over
	it). Under Blizzard each is Blizzard's minimal scroll bar instead, whose
	arrows, track and thumb scroll it too: the list's narrow, 4 to its right,
	the editor's and the footer's 12 to their right, inside the body's clip.
	The list's view stops short of its footer, so + New category and the order's
	reset stay under it, right under the last row when every row fits. Each
	keeps its scroll while the tab is drawn again, and when the tab grows or
	shrinks (SetHeight); the editor and its footer start at their top for
	another category, and the list brings the selected row into view when
	another is selected (a click, + New category, Restore a default), the
	selected one is dragged, or after the order's reset; never when another row
	dragged past it moves it.

	  INV.categoryEditor.selected       the selected id, for the session. One
	                                    that is gone (a delete, a profile
	                                    switch) gives way to the first category.
	  INV.categoryEditor.listOffset, editorOffset, footerOffset
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
	  widget.addButton (with .text), widget.resetOrder (the order's reset icon, with .icon; shown while
	  INV:CategoryOrderDiffers(); both in the menu at half), widget.list
	  (the rows, the scroll child of widget.listScroll), widget.listBar,
	  widget.pane (the editor's rows, the scroll child of widget.editorScroll),
	  widget.editorBar, widget.body (the editor's body), widget.footer (its
	  footer: widget.footerLine, its edge; widget.footerPane, the scroll child
	  of widget.footerScroll; widget.footerBody; widget.footerBar;
	  widget.footerContent, the footer body's drawn height),
	  widget:EditorCell(key) (a row of the editor's, or of its footer's)
	  bagitems: widget.icons[i] = a button { texture, remove (.icon), entry }

	At half width, narrower than 774 (EDITOR_X + EDITOR_WIDTH: w.compact, set by
	SetWidth), the tab has no list beside the editor. A button row is on top:
	w.menuButton, a 260 wide W.SelectFace with the list icon, the edited
	category's name and its place in Muted ('3 of 31', counting every row), then
	w.prevButton and w.nextButton, 24 square and 6 apart (the previous and the
	next category, each disabled at its end, with a red line saying so, and not
	wrapping round). Under it the editor and its footer take the whole width
	(their bodies' SetWidth(width, true): one column, as every page at half) from
	BUTTON_LINE down. The button opens w.menu, the list as a menu: a panel 234
	wide on UIParent at FULLSCREEN_DIALOG level 410 (its catcher at 400 closes
	it on a click outside, and Esc through W.Kit.CatchKeys), 4 under the
	button, captioned 'Categories: drag to reorder', holding w.listPane (the
	same rows, counts, handles, ghost, drop line and bar, and + New category and
	the order's reset under them), its view at most 14 rows. The code of the list is the
	same in the menu as beside the editor; only the pane's parent and its view's
	height change (ApplyMode, Fit). A drag in the menu scrolls it at its edges as
	the list does. The menu closes on a pick, + New category, a click outside,
	Esc, the window closing or leaving half, and INV:EditCategory; it stays open
	through a drop, the order's reset and a bag update, which draw the tab again:
	INV.categoryEditor.menuOpen is kept across that, and Layout closes it when
	the tab is drawn in a later render than it was released in (another page or
	tab). A close with a drag on ends the drag with no move (D.StopDrag), and the
	window, which waited for it, draws again.

	  INV.categoryEditor.menuOpen       the menu is open while this is true and
	                                    the tab is compact. It stays true,
	                                    the menu hidden, from the tab's release
	                                    until it is drawn again (state.menuAt,
	                                    the OW.GetRenderCount() of the release),
	                                    where Layout clears it unless that draw
	                                    is in the same render. This depends on
	                                    the count going up once per render.
	  widget.compact, widget.menuButton, widget.prevButton, widget.nextButton,
	  widget.menu (widget.menu.catcher, widget.menu.caption)

	An icon's item tooltip opens beside the window it's in (/sui), out of it,
	its top level with the icon's: on the window's right, or on its left when
	the screen has no room for it on the right. So it never covers the rule
	whose path a Caught now icon lights up.

	Every change goes through the store's setters (categories.lua), which copy
	what they keep. Every frame here is SaftUI's; item tooltips are
	GameTooltip's, through its public API (SetOwner, ClearAllPoints, SetPoint).
]]

local W, OB, OM, OW = st.OptionsWidgets, st.OptionsBody, st.OptionsModel, st.OptionsWindow
-- What the rule editor drags with too (dragparts.lua): text helpers and the drag.
local D = INV.DragParts
local R = INV.Rules
local Muted, Text, TextWidth, Inside = D.Muted, D.Text, D.TextWidth, D.Inside

local floor, ceil, max, min = math.floor, math.ceil, math.max, math.min
local format = string.format

INV.categoryEditor = { selected = nil, listOffset = 0, editorOffset = 0, footerOffset = 0, menuOpen = false }
INV.categoriesTabShown = false

------------------------------------------------------------------ the look

local LIST_WIDTH = 210
local EDITOR_X, EDITOR_WIDTH = 234, 540
local DIVIDER_X = 222 -- in the middle of the gap between the panes
local ROW_HEIGHT = 22
local RESET_SIZE = 14 -- the order's reset icon (the kit's size)
local PAD = 8 -- a row's contents from its edges
local GAP = 6
local BAR_WIDTH = 3
local FOOTER_GAP = 8
local FOOTER_HEIGHT = FOOTER_GAP + ROW_HEIGHT -- + New category and the order's reset, under the list
local LIST_BAR_GAP = 4 -- the list's scroll bar, between it and the divider
local LIST_STEP = 3 * ROW_HEIGHT -- a turn of the wheel over the list
local MIN_HEIGHT = 10 * ROW_HEIGHT + FOOTER_HEIGHT -- the tab's least: ten rows and the footer
-- A drag held near the list's top or bottom edge scrolls it: this far inside
-- the edge (so resting on the first or last row in view doesn't), or up to a
-- row outside it, this far a second.
local EDGE_INSIDE, EDGE_OUTSIDE = 6, ROW_HEIGHT
local EDGE_SPEED = 12 * ROW_HEIGHT
-- At half the list is a menu on a button (see the header): the tab is compact
-- while it is narrower than the list and the editor side by side.
local COMPACT_BELOW = EDITOR_X + EDITOR_WIDTH
local MENU_BUTTON_WIDTH = 260
local BUTTON_LINE = W.FIELD_HEIGHT + 10 -- the button row, and the editor's top under it
local STEP_SIZE, STEP_ICON = 24, 16 -- previous and next
local MENU_PAD = 8
local MENU_WIDTH = LIST_WIDTH + 24 -- the list, its bar's room and the padding each side
local MENU_ROWS = 14 -- the menu's list view, most
local MENU_GAP = 4 -- the menu under the button
local MENU_CAPTION_HEIGHT = 14
local MENU_LIST_TOP = MENU_PAD + MENU_CAPTION_HEIGHT + GAP
local MENU_LEVEL, MENU_CATCHER_LEVEL = 410, 400 -- as an item's menu (optionsmenu.lua)
local FACE_ICON, FACE_PLACE_RIGHT = 16, 26 -- the button's icon; its place's right edge from the face's (6 before the caret)
local TIP_GAP = 4 -- an item tooltip from the window's edge
local ICON_SIZE, ICON_GAP = 30, 6
local REMOVE_SIZE = 14
local QUESTION_MARK = 134400 -- Interface\Icons\INV_Misc_QuestionMark
-- The editor's rows its footer draws, in this order, top down.
local FOOTER_KEYS = { 'caught', 'pins' }
local FOOTER_EDGE = 1 -- the line across the footer's top

local function Normal() return st:Color('text', 'normal'):GetRGB() end

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
	Show in, its rule or a note, Pinned items, Caught now and Delete
	rows), each reading the store at call time and writing through its setters;
	a shipped category's Name, On, Show in and rule each carry a reset to what
	SaftUI ships, a category of your own a noReset.
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

	-- The combined bank is the default bank on both clients, so it is always
	-- listed; the warband bank only where there is one.
	local windows = { bag = WINDOW_NAMES.bag, bank = WINDOW_NAMES.bank, combinedbank = WINDOW_NAMES.combinedbank }
	local sorting = { 'bag', 'bank', 'combinedbank' }
	if self:HasWarbandBank() then
		windows.warband = WINDOW_NAMES.warband
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

	-- Each field resets alone, to what SaftUI ships (INV:GetDefaultCategory),
	-- through the setter the row already uses. A category of your own has no
	-- shipped version. Pinned items are not a field: they stay.
	local NO_SHIPPED = 'Your own category has no shipped version.'
	local shipped = entry.default and INV:GetDefaultCategory(id)
	if shipped then
		local function Edit() return INV:CategoryStore().edits[id] end
		args.name.default = {
			differs = function()
				local edit = Edit()
				return type(edit) == 'table' and type(edit.name) == 'string' and edit.name ~= ''
			end,
			-- A name another category has now is refused, with the reason.
			reset = function()
				local valid = ValidName(id, shipped.name)
				if valid ~= true then return false, valid end
				INV:RenameCategory(id, shipped.name)
			end,
			value = function() return shipped.name end,
		}
		args.show.default = {
			-- Any window it is hidden in, even one Show in doesn't list on this
			-- client (Forever's combined bank): nothing else clears that flag.
			differs = function()
				local e = Entry()
				return e ~= nil and next(e.hide) ~= nil
			end,
			reset = function() INV:ShowCategoryEverywhere(id) end,
			text = 'shown in every window',
		}
		if args.enabled then
			args.enabled.default = {
				differs = function() local e = Entry(); return e and e.enabled ~= shipped.enabled or false end,
				reset = function() INV:SetCategoryEnabled(id, shipped.enabled) end,
				value = function() return shipped.enabled end,
			}
		end
		if entry.kind == 'rule' then
			args.rule.default = {
				differs = function() local e = Entry(); return e and not R.Equal(e.rule, shipped.rule) or false end,
				reset = function() INV:SetCategoryRule(id, R.Copy(shipped.rule)) end,
				tipName = 'The rule', -- the row's name, "Catches an item when", is no subject
				text = 'the rule SaftUI ships',
			}
		end
	else
		args.name.noReset = NO_SHIPPED
		args.show.noReset = NO_SHIPPED
		if args.enabled then args.enabled.noReset = NO_SHIPPED end
		if args.rule then args.rule.noReset = NO_SHIPPED end
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
					return format('Delete %s? You can bring it back with + New category > Restore a default...', name)
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
	self.categoryEditor.menuOpen = false -- at half the button names the category
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
	if isDragging then
		if w.startEditorScroll then w.startEditorScroll() end
		return w.onChanged(ok, err, true, w)
	end
	return w.onChanged(ok, err)
end

-- The editor's group (INV:CategoryEditorOptions', built for this draw) and
-- its footer's: the rows FOOTER_KEYS names move to a group of their own, each
-- ordered by its place in that list; the rest stay in the editor's.
local function SplitFooter(group)
	local args, footer = group.args, {}
	for order, key in ipairs(FOOTER_KEYS) do
		local option = args[key]
		if option then
			args[key] = nil
			option.order = order
			footer[key] = option
		end
	end
	return group, { type = 'group', name = '', args = footer }
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

-- + New category: accent text that runs run(button).
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

local StartDrag, EndDrag, Fit

-- The place of the category id in list, or nil.
local function PlaceOf(list, id)
	for i, entry in ipairs(list) do
		if entry.id == id then return i end
	end
end

------------------------------------------------------------------ the tab: the menu (at half)

-- The menu over the editor holds the list. It is shown while the tab is
-- compact and INV.categoryEditor.menuOpen is true, which only the button, a
-- pick and the other things that close it change; a draw (a drop, the order's reset, a
-- bag update) leaves it as it was.

local function HideMenu(w)
	w.menu.catcher:Hide()
	w.menu:Hide()
	W.SetOn(w.menuButton, false)
end

-- Under the button, 4 below its bottom left, drawn at the button's scale.
local function ShowMenu(w)
	local menu, face = w.menu, w.menuButton
	menu:SetScale(face:GetEffectiveScale() / UIParent:GetEffectiveScale())
	menu:ClearAllPoints()
	menu:SetPoint('TOPLEFT', face, 'BOTTOMLEFT', 0, -MENU_GAP)
	menu.catcher:Show()
	menu:Show()
	W.SetOn(face, true)
end

-- Closes it. A drag in it ends with no move, and the window, which waited
-- for the drag, draws again.
local function CloseMenu(w)
	INV.categoryEditor.menuOpen = false
	if not w.menu:IsShown() then return end
	local dragging = w.drag ~= nil
	D.StopDrag(w)
	HideMenu(w)
	if dragging then Changed(w) end
end

-- The list's selected row comes into view as the menu opens.
local function OpenMenu(w)
	if not (w.row and w.compact) or w.drag then return end
	local state = INV.categoryEditor
	state.menuOpen = true
	local list = INV:GetCategoryList()
	w.reveal, w.listBase = PlaceOf(list, Selected(list)), state.listOffset
	Fit(w)
	ShowMenu(w)
end

local function ToggleMenu(w)
	if INV.categoryEditor.menuOpen then CloseMenu(w) else OpenMenu(w) end
end

-- Previous and next: the category dir (-1, 1) places from the edited one.
local function Step(w, dir)
	if not w.row or w.drag then return end
	local list = INV:GetCategoryList()
	local target = list[(PlaceOf(list, Selected(list)) or 1) + dir]
	if not target then return end
	INV.categoryEditor.selected = target.id
	Changed(w)
end

local function StepTip(dir)
	return function(button)
		local title = dir < 0 and 'Previous category' or 'Next category'
		if not button.disabled then return title end
		return title, { { text = dir < 0 and 'This is the first category.' or 'This is the last category.', danger = true } }
	end
end

local function Select(w, i)
	local record = w.rows[i]
	if not (w.row and record) or w.drag then return end
	CloseMenu(w) -- a pick, of the edited category too
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
	-- Under Blizzard the Settings category list: the hover and the picked
	-- row on its art, no accent bar, the name gold (white when picked). Else the
	-- accent tint and bar. Read on each layout, so a theme switch shows at once.
	local look = W.BlizzardLook() and st.ThemeArt.Control('optionslist')
	if look then
		f.hover:SetAtlas(look.hover)
		f.hover:SetAlpha(1)
		f.tint:SetAtlas(look.picked)
		f.tint:SetAlpha(1)
		f.bar:Hide()
	else
		local r, g, b = st:Color('accent'):GetRGB()
		f.hover:SetColorTexture(r, g, b, st.TINT_ROW)
		f.tint:SetColorTexture(r, g, b, st.TINT_ROW)
		f.bar:SetColorTexture(r, g, b)
		f.bar:SetShown(selected)
	end
	f.tint:SetShown(selected)
	f.handle:SetShown(entry.kind ~= 'misc')

	local x, right = PAD + D.HANDLE_WIDTH + GAP, LIST_WIDTH - PAD
	f.count:SetText(count > 0 and tostring(count) or '')
	f.count:SetTextColor(Muted())
	f.count:SetShown(count > 0)
	if count > 0 then right = right - TextWidth(f.count) - GAP end
	local marker = (not entry.default and 'yours') or (entry.edited and 'edited') or nil
	f.marker:SetText(marker or '')
	f.marker:SetTextColor(Muted())
	f.marker:SetShown(marker ~= nil)
	if marker then right = right - TextWidth(f.marker) - GAP end

	f.name:SetText(entry.name)
	if not entry.enabled then
		f.name:SetTextColor(Muted())
	elseif look then
		f.name:SetTextColor(unpack(look.text[selected and 'picked' or 'normal']))
	else
		f.name:SetTextColor(Normal())
	end
	local nameWidth = max(1, min(TextWidth(f.name), right - x))
	f.name:SetWidth(nameWidth)
	f.name:ClearAllPoints()
	f.name:SetPoint('LEFT', f, 'LEFT', x, 0)
	f.marker:ClearAllPoints()
	f.marker:SetPoint('LEFT', f, 'LEFT', x + nameWidth + GAP, 0)
	-- Off: a line through the name, on a whole pixel.
	f.strike:SetColorTexture(Muted())
	f.strike:ClearAllPoints()
	f.strike:SetPoint('TOPLEFT', f, 'TOPLEFT', x, -floor(ROW_HEIGHT / 2))
	f.strike:SetWidth(nameWidth)
	f.strike:SetShown(not entry.enabled)

	w.rows[i] = {
		frame = f, id = entry.id, entry = entry, handle = f.handle, name = f.name, marker = f.marker,
		count = f.count, strike = f.strike, tint = f.tint, bar = f.bar,
	}
end

------------------------------------------------------------------ the tab: + New category

local function Added(w, id)
	if id then INV.categoryEditor.selected = id end
	CloseMenu(w)
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

-- The order's reset: the shipped categories back in SaftUI's order, yours
-- right after the one they follow.
local function ResetOrder(w)
	if not w.row or w.drag then return end
	if INV:ResetCategoryOrder() then
		INV.categoryEditor.reveal = true -- the selected row may be in another place now
		Changed(w)
	end
end

-- The reset icon of the list's footer: the kit's own (OB.ResetIcon), with the
-- order's tooltip.
local function OrderResetIcon(parent, run)
	return OB.ResetIcon(parent, function(self)
		GameTooltip:SetOwner(self, 'ANCHOR_TOPLEFT')
		GameTooltip:AddLine('Reset', 1, 1, 1)
		GameTooltip:AddLine("Order goes back to its default: SaftUI's order, with your own categories where they are.", nil, nil, nil, true)
		GameTooltip:Show()
	end, run)
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

local function ScrollFooter(w, offset)
	local state = INV.categoryEditor
	state.footerOffset = OB.ScrollTo(w.footerScroll, w.footerBar, offset, w.footerContent or 0)
	w.footerBase = state.footerOffset
end

--[[
	The panes in the tab's height: the list's view down to its footer, and no
	taller than its rows, so the footer sits right under the last row when
	they all fit. The editor's column: its footer at the bottom, as tall as
	its strips and its edge but at most half the tab, and the editor's view
	the rest above it. Each is scrolled from where Layout found it
	(w.listBase, w.editorBase, w.footerBase), the list to the selected row
	when Layout says so (w.reveal), so running this again (the body gives the
	tab its height after Layout, and again when /sui grows) lands on the same
	spot for the new height.
]]
function Fit(w)
	local height = max(1, w.frame:GetHeight())
	local state = INV.categoryEditor
	local compact = w.compact
	-- The editor's column: from under the button row (compact) down.
	local top, x = compact and BUTTON_LINE or 0, compact and 0 or EDITOR_X
	local column = max(1, height - top)
	local rows = ListHeight(w)
	-- The list's view: down to its footer, or in the menu at most MENU_ROWS rows.
	local view = max(1, min(rows, compact and MENU_ROWS * ROW_HEIGHT or height - FOOTER_HEIGHT))
	w.listScroll:SetHeight(view)
	w.listScroll:UpdateScrollChildRect()
	if compact then
		w.listPane:SetHeight(view + FOOTER_HEIGHT)
		w.menu:SetSize(MENU_WIDTH, MENU_LIST_TOP + view + FOOTER_HEIGHT + MENU_PAD)
	end
	local offset = w.listBase or state.listOffset
	if w.reveal then offset = Reveal(offset, (w.reveal - 1) * ROW_HEIGHT, w.listScroll:GetHeight()) end
	state.listOffset = OB.ScrollTo(w.listScroll, w.listBar, offset, rows, LIST_BAR_GAP)

	-- Nothing in the footer (an editor with no rows): no footer.
	local content = w.footerContent or 0
	local footer = content > 0 and min(content + FOOTER_EDGE, floor(column / 2)) or 0
	w.footer:ClearAllPoints()
	w.footer:SetPoint('TOPLEFT', w.frame, 'TOPLEFT', x, -(height - footer))
	w.footer:SetHeight(max(1, footer))
	w.footer:SetShown(footer > 0)
	w.footerScroll:SetHeight(max(1, footer - FOOTER_EDGE))
	w.footerScroll:UpdateScrollChildRect()
	state.footerOffset = OB.ScrollTo(w.footerScroll, w.footerBar, w.footerBase or state.footerOffset, footer > 0 and content or 0)

	w.editorScroll:SetHeight(max(1, column - footer))
	w.editorScroll:UpdateScrollChildRect()
	state.editorOffset = OB.ScrollTo(w.editorScroll, w.editorBar, w.editorBase or state.editorOffset, w.editorHeight or 0)
	w.divider:SetHeight(height)
end

------------------------------------------------------------------ the tab: dragging a row

-- While a drag is held near the list's top or bottom edge (EDGE_INSIDE
-- inside it, EDGE_OUTSIDE outside it, over the list's width), the list
-- scrolls that way, EDGE_SPEED a second, in whole units: carry keeps the part
-- of a unit a short frame left.
local function EdgeStep(w, key, scroll, content, elapsed)
	local left, right, bottom, top = scroll:GetLeft(), scroll:GetRight(), scroll:GetBottom(), scroll:GetTop()
	local direction
	if elapsed and left and content > scroll:GetHeight() then
		local x, y = GetCursorPosition()
		local scale = scroll:GetEffectiveScale()
		x, y = x / scale, y / scale
		if x >= left and x <= right then
			if y > top - EDGE_INSIDE and y < top + EDGE_OUTSIDE then
				direction = -1
			elseif y < bottom + EDGE_INSIDE and y > bottom - EDGE_OUTSIDE then
				direction = 1
			end
		end
	end
	if not direction then
		w[key] = 0
		return
	end
	w[key] = (w[key] or 0) + elapsed * EDGE_SPEED
	local step = floor(w[key])
	if step < 1 then return end
	w[key] = w[key] - step
	return direction * step
end

local function EdgeScroll(w, elapsed)
	local step = EdgeStep(w, 'carry', w.listScroll, ListHeight(w), elapsed)
	if step then ScrollList(w, INV.categoryEditor.listOffset + step) end
end

-- The same for a block held in the rule editor, from the tab's own driver
-- frame (the rule editor's OnUpdate only draws its line, and has no elapsed
-- to give): it runs only while a block is held, and takes itself off when
-- the drag is over or the tab is hidden. The editor then draws its line and
-- ghost again, from the rows where the scroll has put them.
local function EditorEdgeScroll(w, elapsed)
	local dragging
	for _, cell in ipairs(w.body.cells) do
		if cell.widget and cell.widget.drag then dragging = cell.widget break end
	end
	if not (dragging and w.row) then
		w.editorCarry = 0
		w.editorDriver:SetScript('OnUpdate', nil)
		return
	end
	local step = EdgeStep(w, 'editorCarry', w.editorScroll, w.editorHeight or 0, elapsed)
	if not step then return end
	ScrollEditor(w, INV.categoryEditor.editorOffset + step)
	if dragging.drawDrag then dragging.drawDrag() end
end

local function StartEditorEdgeScroll(w)
	w.editorCarry = 0
	w.editorDriver:SetScript('OnUpdate', function(_, elapsed) EditorEdgeScroll(w, elapsed) end)
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

-- The drop. A move of the selected category brings its row into view; a
-- move of another, which may push the selected row out of view, leaves the
-- list where the drop was.
function EndDrag(w)
	if not w.drag then return end
	local id = w.drag.id
	local place = DropSpot(w)
	StopDrag(w)
	if place and INV:MoveCategory(id, place) then
		if id == INV.categoryEditor.selected then INV.categoryEditor.reveal = true end
		Changed(w)
	end
end

------------------------------------------------------------------ the tab: laying it out

-- The panes for the width the tab has: full, the list beside the editor (234,
-- 540 wide), or compact, the list in the menu and the editor under the button
-- row with the whole width and one column (the half body's).
local function ApplyMode(w)
	local frame, compact = w.frame, w.compact
	local width = compact and w.tabWidth or EDITOR_WIDTH
	local x, top = compact and 0 or EDITOR_X, compact and BUTTON_LINE or 0

	local target = compact and w.menu or frame
	if w.listPane:GetParent() ~= target then w.listPane:SetParent(target) end
	w.listPane:ClearAllPoints()
	w.listPane:SetWidth(LIST_WIDTH)
	if compact then
		w.listPane:SetPoint('TOPLEFT', w.menu, 'TOPLEFT', MENU_PAD, -MENU_LIST_TOP)
	else
		w.listPane:SetPoint('TOPLEFT', frame, 'TOPLEFT', 0, 0)
		w.listPane:SetPoint('BOTTOMLEFT', frame, 'BOTTOMLEFT', 0, 0)
	end
	w.divider:SetShown(not compact)

	w.editorScroll:ClearAllPoints()
	w.editorScroll:SetPoint('TOPLEFT', frame, 'TOPLEFT', x, -top)
	for _, pane in ipairs({ w.editorScroll, w.pane, w.footer, w.footerScroll, w.footerPane }) do pane:SetWidth(width) end
	w.body:SetWidth(width, compact)
	w.footerBody:SetWidth(width, compact)

	-- The button row, at the editor's content (under Blizzard the body has no padding).
	for _, control in ipairs({ w.menuButton, w.prevButton, w.nextButton }) do control:SetShown(compact) end
	if compact then
		local pad = (W.BlizzardLook() and OB.FLAT or OB.PANELED).pad
		w.menuButton:ClearAllPoints()
		w.menuButton:SetPoint('TOPLEFT', frame, 'TOPLEFT', pad, 0)
		w.prevButton:ClearAllPoints()
		w.prevButton:SetPoint('TOPLEFT', w.menuButton, 'TOPRIGHT', GAP, 0)
		w.nextButton:ClearAllPoints()
		w.nextButton:SetPoint('TOPLEFT', w.prevButton, 'TOPRIGHT', GAP, 0)
	end
end

-- The face's contents: the list icon, the name (cut short, not over the place)
-- and its place at the right, before the caret. Under Blizzard the face's own
-- code (W.LookSelectFace) puts the name across it, centred, each time it is
-- painted: so these go on again after it (hooks on its scripts, and each
-- layout). Never call W.SetEnabled or Kit.PaintFace on this face: they put the
-- name back across it.
local function PlaceFaceContents(face)
	face.text:SetJustifyH('LEFT')
	face.text:ClearAllPoints()
	face.text:SetPoint('LEFT', face.icon, 'RIGHT', GAP, 0)
	face.text:SetPoint('RIGHT', face.place, 'LEFT', -GAP, 0)
end

-- The button row for the edited category (place of list): the button's name
-- and place, previous and next disabled at the ends, each in the look now.
local function LayButtonRow(w, list, place)
	local face, blizzard = w.menuButton, W.BlizzardLook() or false
	face.text:SetText(list[place].name)
	face.place:SetText(format('%d of %d', place, #list))
	face.place:SetTextColor(Muted())
	W.LookSelectFace(face, blizzard)
	PlaceFaceContents(face)
	W.SetOn(face, w.menu:IsShown())
	for _, step in ipairs({ { w.prevButton, place > 1 }, { w.nextButton, place < #list } }) do
		W.LookControl(step[1], blizzard)
		W.SetEnabled(step[1], step[2])
	end
end

local function Layout(w, relayout)
	-- Nothing moves under the mouse: the drop is worked out on its up.
	if w.drag or EditorDragging(w) then return end
	INV.categoriesTabShown = true
	local owner = W.ListOwner()
	if owner and Inside(owner, w.listPane) then W.CloseList() end

	local state = INV.categoryEditor
	-- A menu open as the tab was released stays open only when this draw is
	-- the one that replaced it (a drop, a bag update): the tab shown again
	-- later (another page, another tab) opens with it closed.
	if state.menuAt ~= nil and state.menuAt ~= OW.GetRenderCount() then state.menuOpen = false end
	state.menuAt = nil
	ApplyMode(w)

	local list = INV:GetCategoryList()
	local selected = Selected(list)
	-- The bags, read once for the counts and the editor's item strips.
	local counts, items = INV:CountCategories('bag')
	local level = w.frame:GetFrameLevel()
	-- The list's levels: over the menu's when it is in the menu.
	local listLevel = w.compact and w.menu:GetFrameLevel() or level
	w.listPane:SetFrameLevel(listLevel + 1)
	w.listScroll:SetFrameLevel(listLevel + 2)
	w.list:SetFrameLevel(listLevel + 3)
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
	local x = PAD
	local add = w.addButton
	add.text:SetTextColor(st:Color('accent'):GetRGB())
	add.text:SetAlpha(1)
	add:SetSize(TextWidth(add.text), ROW_HEIGHT)
	add:ClearAllPoints()
	add:SetPoint('TOPLEFT', w.listScroll, 'BOTTOMLEFT', x, -FOOTER_GAP)
	x = x + add:GetWidth() + 12
	-- The order's reset, after it: while the shipped categories are out of
	-- their order.
	local reset = w.resetOrder
	reset.icon:SetVertexColor(Muted())
	reset:ClearAllPoints()
	reset:SetPoint('TOPLEFT', w.listScroll, 'BOTTOMLEFT', x, -(FOOTER_GAP + floor((ROW_HEIGHT - RESET_SIZE) / 2)))
	reset:SetShown(INV:CategoryOrderDiffers())

	-- The list brings the selected row into view when another is selected,
	-- or when asked (state.reveal): the selected one dragged, the order's reset,
	-- EditCategory. A draw that did neither leaves the list where it is: a
	-- bag update, or another row dragged past the selected one.
	-- (A draw again for another width keeps what the first one found.)
	if not relayout then
		w.reveal = nil
		if state.reveal or state.shownId ~= selected then w.reveal = place end
		state.reveal, state.shownId = false, selected
		w.listBase = state.listOffset
	end
	LayButtonRow(w, list, place or 1)

	-- The editor's options, less Caught now and Pinned items, which its
	-- footer draws, under it.
	local editor, footer = SplitFooter(INV:CategoryEditorOptions(selected, w, items))
	w.body:Release()
	local root = { category = editor }
	w.body:SetRoot(root)
	local view = OM.BuildView(root, 'category')
	w.editorScroll:SetFrameLevel(level + 1)
	w.pane:SetFrameLevel(level + 2)
	w.editorHeight = view and w.body:Draw(view.sections) or 0
	w.pane:SetHeight(max(1, w.editorHeight))

	w.footerBody:Release()
	local footerRoot = { footer = footer }
	w.footerBody:SetRoot(footerRoot)
	local footerView = OM.BuildView(footerRoot, 'footer')
	w.footer:SetFrameLevel(level + 1)
	w.footerScroll:SetFrameLevel(level + 1)
	w.footerPane:SetFrameLevel(level + 2)
	w.footerContent = footerView and w.footerBody:Draw(footerView.sections) or 0
	w.footerPane:SetHeight(max(1, w.footerContent))
	-- Its edge: under Blizzard the Settings panel's divider, else the body's line.
	if W.BlizzardLook() then
		w.footerLine:SetAtlas(st.ThemeArt.Control('optionswindow').rule)
		w.footerLine:SetVertexColor(1, 1, 1)
	else
		w.footerLine:SetColorTexture(unpack(OB.LINE))
	end

	-- Another category's editor, and its footer, start at their top.
	if state.editorFor ~= selected then
		state.editorFor, state.editorOffset, state.footerOffset = selected, 0, 0
	end
	w.editorBase, w.footerBase = state.editorOffset, state.footerOffset

	Fit(w)
	if w.compact and state.menuOpen then ShowMenu(w) else HideMenu(w) end
end

-- The button row (compact only) and the menu, built hidden: the face, previous
-- and next in the tab's frame; the menu and its catcher on UIParent, where the
-- list goes while the tab is compact (ApplyMode).
local function BuildMenu(w)
	local face = W.SelectFace(w.frame, MENU_BUTTON_WIDTH, function() ToggleMenu(w) end)
	face.tip = function() return 'Categories', { 'Opens the list: pick one to edit, or drag one to reorder.' } end
	face.icon = face:CreateTexture(nil, 'OVERLAY')
	face.icon:SetTexture(st.icons.list)
	face.icon:SetSize(FACE_ICON, FACE_ICON)
	face.icon:SetPoint('LEFT', face, 'LEFT', PAD, 0)
	face.icon:SetVertexColor(Muted())
	face.place = Text(face, OB.Font('small'), 'RIGHT')
	face.place:SetPoint('RIGHT', face, 'RIGHT', -FACE_PLACE_RIGHT, 0)
	PlaceFaceContents(face)
	-- The kit's face code puts the name across it again as it paints it (the mouse, a press).
	for _, script in ipairs({ 'OnEnter', 'OnLeave', 'OnMouseDown', 'OnMouseUp', 'OnHide' }) do
		face:HookScript(script, function(self) PlaceFaceContents(self) end)
	end
	w.menuButton = face
	w.prevButton = W.IconButton(w.frame, st.icons.chevronLeft, StepTip(-1), STEP_SIZE, STEP_ICON)
	w.prevButton.onClick = function() Step(w, -1) end
	w.nextButton = W.IconButton(w.frame, st.icons.chevronRight, StepTip(1), STEP_SIZE, STEP_ICON)
	w.nextButton.onClick = function() Step(w, 1) end

	local catcher = CreateFrame('Frame', nil, UIParent)
	catcher:SetAllPoints(UIParent)
	catcher:SetFrameStrata('FULLSCREEN_DIALOG')
	catcher:SetFrameLevel(MENU_CATCHER_LEVEL)
	catcher:EnableMouse(true)
	catcher:Hide()
	catcher:SetScript('OnMouseDown', function() if w.row then CloseMenu(w) end end)
	-- Esc closes it; every other key goes on to the game.
	W.Kit.CatchKeys(catcher, { ESCAPE = true }, function(key)
		if key == 'ESCAPE' and w.row then CloseMenu(w) end
	end)

	local menu = st:CreateFrame('Frame', nil, UIParent)
	menu:SetFrameStrata('FULLSCREEN_DIALOG')
	menu:SetFrameLevel(MENU_LEVEL)
	menu:SetSize(MENU_WIDTH, MENU_LIST_TOP + FOOTER_HEIGHT + MENU_PAD)
	st:KeepInScreenMargin(menu)
	menu:EnableMouse(true)
	menu:Hide()
	st:SetTemplate(menu, 'theme', 'solid', 'panel')
	-- The wheel stops at the menu and its catcher: the page under them stays.
	for _, frame in ipairs({ catcher, menu }) do
		frame:EnableMouseWheel(true)
		frame:SetScript('OnMouseWheel', function() end)
	end
	menu.caption = Text(menu, OB.Font('caption'))
	menu.caption:SetPoint('TOPLEFT', menu, 'TOPLEFT', MENU_PAD + PAD, -MENU_PAD)
	menu.caption:SetText('Categories: drag to reorder')
	menu.caption:SetTextColor(Muted())
	menu.catcher = catcher
	w.menu = menu
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
		w.listBar = OB.ScrollBar(w.listPane, function(offset)
			if w.row then ScrollList(w, offset) end
		end, { narrow = true, step = LIST_STEP })
		w.addButton = Action(w.listPane, '+ New category', function(button) NewCategory(w, button) end)
		w.resetOrder = OrderResetIcon(w.listPane, function() ResetOrder(w) end)

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
		w.editorDriver = CreateFrame('Frame', nil, frame)
		w.startEditorScroll = function() StartEditorEdgeScroll(w) end
		w.editorDriver:SetScript('OnHide', function(self) self:SetScript('OnUpdate', nil) end)
		w.editorScroll:EnableMouseWheel(true)
		w.editorScroll:SetScript('OnMouseWheel', function(_, delta)
			if w.row then ScrollEditor(w, INV.categoryEditor.editorOffset - delta * OB.SCROLL_STEP) end
		end)
		w.editorBar = OB.ScrollBar(frame, function(offset)
			if w.row then ScrollEditor(w, offset) end
		end, { step = OB.SCROLL_STEP })
		w.body = OB.New(w.pane, nil, function(...) Forward(w, ...) end, EDITOR_WIDTH)

		-- The editor's footer, under it (Fit places and sizes it): an edge
		-- across its top, then its own body, in w.footerPane, which scrolls
		-- in w.footerScroll.
		w.footer = CreateFrame('Frame', nil, frame)
		w.footer:SetSize(EDITOR_WIDTH, ROW_HEIGHT)
		w.footer:SetPoint('TOPLEFT', frame, 'TOPLEFT', EDITOR_X, 0)
		w.footerLine = w.footer:CreateTexture(nil, 'ARTWORK')
		w.footerLine:SetPoint('TOPLEFT', w.footer, 'TOPLEFT', 0, 0)
		w.footerLine:SetPoint('TOPRIGHT', w.footer, 'TOPRIGHT', 0, 0)
		w.footerLine:SetHeight(FOOTER_EDGE)
		w.footerScroll = CreateFrame('ScrollFrame', nil, w.footer)
		w.footerScroll:SetPoint('TOPLEFT', w.footer, 'TOPLEFT', 0, -FOOTER_EDGE)
		w.footerScroll:SetSize(EDITOR_WIDTH, ROW_HEIGHT)
		w.footerPane = CreateFrame('Frame', nil, w.footerScroll)
		w.footerPane:SetSize(EDITOR_WIDTH, ROW_HEIGHT)
		w.footerScroll:SetScrollChild(w.footerPane)
		w.footerScroll:EnableMouseWheel(true)
		w.footerScroll:SetScript('OnMouseWheel', function(_, delta)
			if w.row then ScrollFooter(w, INV.categoryEditor.footerOffset - delta * OB.SCROLL_STEP) end
		end)
		w.footerBar = OB.ScrollBar(frame, function(offset)
			if w.row then ScrollFooter(w, offset) end
		end, { step = OB.SCROLL_STEP })
		w.footerBody = OB.New(w.footerPane, nil, function(...) Forward(w, ...) end, EDITOR_WIDTH)

		w.compact, w.tabWidth = false, OB.WIDTH
		BuildMenu(w)

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

		-- The body's width (a bare row): under COMPACT_BELOW the list is a menu
		-- and the editor takes the width. The body gives it after the tab is
		-- bound, so a change of layout draws the tab again, keeping what the
		-- first draw found (the list's reveal).
		SetWidth = function(w, width)
			local compact = width < COMPACT_BELOW
			local changed = compact ~= w.compact or width ~= w.tabWidth
			w.compact, w.tabWidth = compact, width
			w.frame:SetWidth(width)
			if not compact then INV.categoryEditor.menuOpen = false end
			if changed and w.row then Layout(w, true) end
		end,

		-- The height the body's view leaves it (a fill row): the panes follow.
		SetHeight = function(w, height)
			w.frame:SetHeight(max(1, height))
			if w.row then Fit(w) end
		end,

		-- The editor's drawn row of an option key, in the editor or its
		-- footer, or nil.
		EditorCell = function(w, key)
			for _, body in ipairs({ w.body, w.footerBody }) do
				for _, cell in ipairs(body.cells) do
					if cell.row.key == key then return cell end
				end
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
			if owner and (Inside(owner, w.frame) or Inside(owner, w.menu)) then W.CloseList() end
			-- The menu goes with the tab, and the list back into it. It stays
			-- open for the draw that replaces the tab at once (a drop, a bag
			-- update: Layout), not when the window is closed or not at half.
			HideMenu(w)
			if w.listPane:GetParent() ~= w.frame then w.listPane:SetParent(w.frame) end
			local state = INV.categoryEditor
			if state.menuOpen then
				if OW:IsShown() and OW:GetWindowSize() == 'half' then
					state.menuAt = OW.GetRenderCount()
				else
					state.menuOpen = false
				end
			end
			w.body:Release()
			w.footerBody:Release()
			for _, f in ipairs(w.rowFrames) do f:Hide() end
			wipe(w.rows)
			w.reveal, w.listBase, w.editorBase, w.footerBase = nil, nil, nil, nil
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

-- The window frame is in: its farthest ancestor under UIParent (/sui's).
local function WindowOf(frame)
	local parent = frame:GetParent()
	while parent and parent ~= UIParent do
		frame, parent = parent, parent:GetParent()
	end
	return frame
end

-- How far an item tooltip sits out from the window's left and right edges:
-- TIP_GAP, and under Blizzard past the metal too, which reaches out past
-- the window's edges (ThemeArt.MetalReach).
local function TipGaps()
	if not W.BlizzardLook() then return TIP_GAP, TIP_GAP end
	local left, right = st.ThemeArt.MetalReach()
	return TIP_GAP + left, TIP_GAP + right
end

-- The tooltip beside icon's window, out of it (TipGaps), its top level with
-- the icon's: on the window's right, or on its left when the screen has no
-- room for it on the right (and the left has more). Placed in screen pixels from
-- UIParent's corner, as the drag's ghost is, so the tooltip's own scale
-- doesn't matter. Read once it's shown, when its size is its content's.
-- When an edge or the width can't be read (a secret width), it goes at the
-- icon's top right instead: an ANCHOR_NONE tooltip left unplaced would show
-- at the last tooltip's anchors, anywhere.
local function PlaceTip(icon)
	local window = WindowOf(icon)
	local left, right, top = window:GetLeft(), window:GetRight(), icon:GetTop()
	local width, screen = GameTooltip:GetWidth(), UIParent:GetRight()
	GameTooltip:ClearAllPoints()
	if not (left and right and top and screen) or issecretvalue(width) then
		GameTooltip:SetPoint('TOPLEFT', icon, 'TOPRIGHT', TIP_GAP, 0)
		return
	end
	local ws, ts = window:GetEffectiveScale(), GameTooltip:GetEffectiveScale()
	left, right, top, screen = left * ws, right * ws, top * icon:GetEffectiveScale(), screen * UIParent:GetEffectiveScale()
	width = (width or 0) * ts
	local leftGap, rightGap = TipGaps()
	leftGap, rightGap = leftGap * ws, rightGap * ws
	if right + rightGap + width <= screen or screen - right >= left then
		GameTooltip:SetPoint('TOPLEFT', UIParent, 'BOTTOMLEFT', floor((right + rightGap) / ts + 0.5), floor(top / ts + 0.5))
	else
		GameTooltip:SetPoint('TOPRIGHT', UIParent, 'BOTTOMLEFT', floor((left - leftGap) / ts + 0.5), floor(top / ts + 0.5))
	end
end

-- The item's tooltip: its bag slot's when it is in the bags, else its ID's,
-- beside the window so it covers nothing in it.
local function ShowItem(w, icon)
	local entry = icon.entry
	if not (w.row and entry) then return end
	GameTooltip:SetOwner(icon, 'ANCHOR_NONE')
	local info = entry.info
	if info and info.bagID and info.slotID then
		GameTooltip:SetBagItem(info.bagID, info.slotID)
	else
		GameTooltip:SetItemByID(entry.itemID)
	end
	GameTooltip:Show()
	PlaceTip(icon)
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
	remove.icon:SetTexture(st.icons.x)
	remove.icon:SetSize(16, 16) -- an 8 px cross in the middle
	remove.icon:SetPoint('CENTER', remove, 'CENTER', 0, 0)
	remove:SetScript('OnEnter', function(self) self.icon:SetVertexColor(st:Color('text', 'danger'):GetRGB()) end)
	remove:SetScript('OnLeave', function(self) self.icon:SetVertexColor(Muted()) end)
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
		icon.remove.icon:SetVertexColor(Muted())
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
