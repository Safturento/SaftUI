-- What the bag layout tests share: the world with SaftUI-Bags' container.lua
-- loaded, and the containers and categories the layout works on. Not a test
-- (no _test suffix), so the runner doesn't run it; container_hold_test.lua and
-- container_pack_test.lua load it with load_test_file('bags/container_helpers.lua').
--
-- The layout (INV:UpdateContainerLayout) is the real one. So are the rest of
-- the module's files it calls into: inventory.lua (GetButtonHeight), movers.lua
-- (SyncAnchorSize, which sizes the window's edit mode anchor) and category.lua
-- (FlushCategory), and the module's defaults (config.lua). What the tests make
-- by hand is what the real code builds around the layout: the container's
-- frames, the column frames and the category frames.

local H = {}

-- The height of one row of items, button and spacing.
function H.row() return H.INV:GetButtonHeight() + H.INV.config.buttonspacing end

-- A fresh world with container.lua loaded. The module's config is the real
-- defaults (padding 10, spacing 3, icon height 50, inverted, the bag window
-- 15 rows by 3 columns).
function H.fresh()
	reset_world()
	load_core_helpers()
	load_saftui('SaftUI-Bags/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Bags/inventory.lua')
	load_saftui('SaftUI-Bags/category.lua')
	load_saftui('SaftUI-Bags/movers.lua')
	load_saftui('SaftUI-Bags/container.lua')
	local INV = SaftUI:GetModule('Inventory')
	H.INV = INV
	-- As INV:OnEnable binds it.
	SaftUI:BindModuleConfig(INV, 'inventory')
	INV.containers.bag = {} -- so EnsureConfigTables makes the bag's filter table
	INV:EnsureConfigTables()
	INV.containers.bag = nil
end

-- A frame of the given height (and width), parented to UIParent.
local function frame(height, width, parent)
	local f = CreateFrame('Frame', nil, parent or UIParent)
	f:SetSize(width or 0, height)
	return f
end

-- A category the way INV:UpdateCategory leaves one: a name, the rows of items
-- it holds, and the height of the title plus the rows.
function H.cat(name, rows)
	local category = frame(0)
	category.name = name
	category.slots = {} -- what INV:FlushCategory walks
	H.set_rows(category, rows)
	return category
end

function H.set_rows(category, rows)
	category:SetHeight(rows * H.row() + H.INV.config.categoryTitleHeight)
	category.numRows = rows
end

-- A bag window with the given categories and k columns, 200 wide each.
--
-- The scroll frame stands in for st:CreateScrollFrame (SaftUI-Core/Widgets/
-- scrollframe.lua), which needs Blizzard's ScrollFrameTemplate and the
-- scroll bar skin. The layout only reaches it through SetContentSize, which
-- there sizes the scroll child; so does this one (the real one also calls
-- UpdateScrollChildRect, which the stubs don't have).
function H.container(categories, k)
	local container = frame(0)
	container.id = 'bag'
	container.categories, container.columns = {}, {}
	container.header, container.footer = frame(30), frame(20)
	container.filterButton = CreateFrame('CheckButton', nil, container)

	local scrollFrame = CreateFrame('ScrollFrame', nil, container)
	local content = frame(0, 0, scrollFrame)
	scrollFrame:SetScrollChild(content)
	scrollFrame.ScrollChild = content
	scrollFrame.SetContentSize = function(self, width, height) content:SetSize(width, height) end
	container.scrollFrame = scrollFrame

	for i = 1, k or 3 do
		container.columns[i] = frame(0, 200, scrollFrame)
		container.columns[i].categories = {}
	end
	for _, category in ipairs(categories) do
		category:SetParent(container)
		container.categories[category.name] = category
	end
	return container
end

-- Lays the container out, as INV:UpdateContainer does when its items change.
function H.layout(container)
	H.INV.containers = { bag = container }
	H.INV:UpdateContainerLayout('bag')
end

-- Which column (index) and position each shown category is in: name -> '2:1'.
function H.where(container)
	local out = {}
	for i, column in ipairs(container.columns) do
		for pos, category in ipairs(column.categories) do out[category.name] = i .. ':' .. pos end
	end
	return out
end

function H.same(a, b)
	for k, v in pairs(a) do if b[k] ~= v then return false end end
	for k, v in pairs(b) do if a[k] ~= v then return false end end
	return true
end

return H
