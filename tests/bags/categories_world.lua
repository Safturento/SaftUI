-- The world and the helpers the Categories tab's tests share
-- (categories_list_test.lua, categories_drag_test.lua,
-- categories_editor_test.lua and categories_scroll_test.lua). A test file
-- loads it with load_test_file and takes what it returns: H (bags/
-- container_helpers.lua's), the helpers it uses, and world(client), which
-- rebuilds the world and returns the bag window's container, st, INV, B, OW,
-- OM, W and R (INV.Rules), for the file to keep in its own locals (each file
-- wraps it, since a case reads those names as upvalues).
--
-- world(client) is the views world on 'forever' or the given client: the
-- backpack (a tonic, a gray cloth, a plank and a board, a common bit and a mace
-- in the Heal equipment set, laid out in Compact), then Core's config, the
-- options window's files and SaftUI-Bags' options.lua, dragparts.lua,
-- ruleeditor.lua and categoriestab.lua. The helpers: open (the tab), cell, tab
-- (its widget as the window drew it last), tick, click, yes, pick, rgb, row_of,
-- ids, cursor_on, wheel, in_view, drag_frame, half (the window at half width) and
-- the rest the cases share.

local H = load_test_file('bags/container_helpers.lua')

local st, INV, B, OW, OM, W, R

local SELL, SETS, MISC = 'Grays/Auto Vendor', 'Equipment sets', 'Miscellaneous'

-- The backpack: a tonic (Consumables), a gray cloth (Grays/Auto Vendor, by its
-- quality), a plank and a board (Trade Goods), a common bit (Miscellaneous)
-- and a mace in the Heal equipment set. The bag window is laid out in Compact.
local function world(client)
	INV, B = H.views_world(client or 'forever', function() load_test_file('core/config_helpers.lua') end)
	st = SaftUI
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	load_options_widgets()
	load_saftui('SaftUI-Core/Config/optionsbody.lua')
	load_options_window()
	load_saftui('SaftUI-Bags/options.lua')
	load_saftui('SaftUI-Bags/dragparts.lua')
	load_saftui('SaftUI-Bags/ruleeditor.lua')
	load_saftui('SaftUI-Bags/categoriestab.lua')
	OW, OM, W, R = st.OptionsWindow, st.OptionsModel, st.OptionsWidgets, INV.Rules
	-- The money in the bag window's footer (GetMoney, LibStringFormat-1.0).
	INV.UpdateGold = function() end
	if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
	B.bag(0, 20, 'Backpack')
	B.put(0, 1, B.item(101, 'Tonic', 'Consumable', 30))
	B.put(0, 2, B.item(502, 'Gray Cloth', 'Miscellaneous', 1, { quality = 0 }))
	B.put(0, 3, B.item(301, 'Plank', 'Trade Goods', 15))
	B.put(0, 4, B.item(302, 'Board', 'Trade Goods', 15))
	B.put(0, 5, B.item(503, 'Common Bit', 'Miscellaneous', 1))
	B.put(0, 6, B.item(601, 'Healing Mace', 'Weapon', 50, { set = 'Heal' }))
	INV.config.stackItems = false
	INV.config.bag.view = 'compact'
	INV.config.bag.emptySlots = 'off'
	local container = H.window('bag')
	H.search(container)
	INV:RegisterMovers()
	INV:UpdateContainer('bag', true)
	take_errors()
	return container, st, INV, B, OW, OM, W, R
end

local function open()
	st.Config:Open('Inventory', 'categories')
end

local function cell(key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key then return c end
	end
end

-- The window at half width (388 under Thick and Thin, 368 under Blizzard): the
-- size changed and the time moved past the size buttons' guard, so a test can
-- change it again at once.
local function half()
	if not OW:SetWindowSize('half') then error('the window did not go to half') end
	stub.time = stub.time + 1
end

-- The tab's widget, as the window drew it last.
local function tab() return cell('categories').widget end

local tick = tick_options_window
local click = stub.click

local function rgb(group, name) return { st.config.profile.colors[group][name]:GetRGB() } end
local function same_rgb(c, want)
	return math.abs(c[1] - want[1]) < 1e-6 and math.abs(c[2] - want[2]) < 1e-6 and math.abs(c[3] - want[3]) < 1e-6
end

-- The list's row of a category.
local function row_of(w, id)
	for _, row in ipairs(w.rows) do
		if row.id == id then return row end
	end
end

local function ids()
	local out = {}
	for i, entry in ipairs(INV:GetCategoryList()) do out[i] = entry.id end
	return table.concat(out, ',')
end

-- Puts the cursor on a frame's upper or lower half.
local function cursor_on(frame, lower)
	local l, b, width, h = frame:GetRect()
	local scale = frame:GetEffectiveScale()
	stub.cursor_x = (l + width / 2) * scale
	stub.cursor_y = (b + (lower and 0.25 or 0.75) * h) * scale
end

-- Turns of the mouse wheel over frame: 1 scrolls up, -1 down.
local function wheel(frame, delta, times)
	for _ = 1, times or 1 do stub.fire_script(frame, 'OnMouseWheel', delta) end
end

-- Whether a list row's whole frame shows in the list's view.
local function in_view(w, row)
	return row.frame:GetTop() <= w.listScroll:GetTop() and row.frame:GetBottom() >= w.listScroll:GetBottom()
end

-- A frame of a drag: its frame's OnUpdate, as the game runs it each frame.
local function drag_frame(w, elapsed) stub.fire_script(w.frame, 'OnUpdate', elapsed or 0.01) end

local function pick(label)
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() and row.text:GetText() == label then return click(row) end
	end
	error('no list row ' .. label)
end

local function yes() click(W.GetDialogFrames().yes) end
local function no() click(W.GetDialogFrames().no) end

-- The shown icons of a bagitems widget.
local function icons(items)
	local out = {}
	for _, icon in ipairs(items.icons) do
		if icon:IsShown() then out[#out + 1] = icon end
	end
	return out
end

-- The keys of the rows the tab's editor drew, in order (its footer's not).
local function editor_keys(w)
	local out = {}
	for i, c in ipairs(w.body.cells) do out[i] = c.row.key end
	return table.concat(out, ',')
end

-- Whether frame is ancestor or one of its descendants.
local function inside(frame, ancestor)
	while frame do
		if frame == ancestor then return true end
		frame = frame:GetParent()
	end
	return false
end

-- A rule of id's with n more Name blocks: an editor taller than the tab.
local function tall_rule(id, n)
	local rule = R.Copy(INV:GetCategoryList().byId[id].rule)
	for i = 1, n do rule.items[#rule.items + 1] = { block = 'name', text = 'Item ' .. i } end
	INV:SetCategoryRule(id, rule)
end

return {
	cell = cell,
	open = open,
	half = half,
	rgb = rgb,
	SETS = SETS,
	same_rgb = same_rgb,
	MISC = MISC,
	click = click,
	tab = tab,
	SELL = SELL,
	row_of = row_of,
	pick = pick,
	yes = yes,
	no = no,
	ids = ids,
	cursor_on = cursor_on,
	drag_frame = drag_frame,
	tick = tick,
	wheel = wheel,
	in_view = in_view,
	inside = inside,
	tall_rule = tall_rule,
	editor_keys = editor_keys,
	icons = icons,
	world = world,
}
