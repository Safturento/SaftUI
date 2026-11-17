-- SaftUI-Chat's docked chat tabs (CHT:FCFDock_UpdateTabs, a post-hook on Blizzard's
-- FCFDock_UpdateTabs): on a forced update the first tab sits above its window, and each
-- later tab anchors to the tab before it, except the first one on the dock's scroll child
-- (ChatFrame3 and up), which keeps Blizzard's anchor so an overflowing row still scrolls.
--
-- Blizzard's FCFDock_UpdateTabs (FloatingChatFrame.lua, both clients) returns at once
-- when `not dock.isDirty and not forceUpdate`, and otherwise ends with
-- `dock.isDirty = false`. The game runs a post-hook after it, so by then isDirty is
-- already false, so the hook can't tell a plain dirty update (a resize of ChatFrame1, a
-- pick from the overflow list, an undock) from an idle call: it lays the row out on every
-- call, forced or not. These cases call the hook as the game does and pin each path.
--
-- Real: SaftUI-Chat's config.lua and chatframe.lua, Core's helpers and edit mode.
-- Stand-ins: the dock is a plain table with Blizzard's DOCKED_CHAT_FRAMES list, each a
-- chat window with its tab, a global named ChatFrameNTab as Blizzard's XML names it
-- (Blizzard's FCFDock_UpdateTabs walks that list the same way); `update` is Blizzard's
-- function and its post-hook, in the order the game runs them.
load_core_helpers()
load_editmode()
load_saftui('SaftUI-Chat/config.lua')
apply_defaults()
load_saftui('SaftUI-Chat/chatframe.lua')

local CHT = SaftUI:GetModule('Chat')

-- A dock of `count` windows, the first `static` of them static docked (Blizzard's
-- isStaticDocked: its first two, ChatFrame1 and ChatFrame2, in the game), the rest dynamic
-- (they sit on the dock's scroll child and scroll when the row overflows). The tabs start
-- where Blizzard's own layout leaves them.
local function dock_of(count, static)
	static = static or 2
	local scrollFrame = CreateFrame('ScrollFrame', nil, UIParent)
	local scrollChild = CreateFrame('Frame', nil, scrollFrame)
	scrollFrame:SetScrollChild(scrollChild)
	local dock = { isDirty = false, DOCKED_CHAT_FRAMES = {}, scrollFrame = scrollFrame }
	for i = 1, count do
		local frame = CreateFrame('Frame', 'ChatFrame' .. (i + 10), UIParent)
		frame:SetSize(400, 200)
		frame:SetPoint('CENTER')
		frame.isStaticDocked = i <= static
		local tab = CreateFrame('Button', 'ChatFrame' .. (i + 10) .. 'Tab', UIParent)
		tab:SetSize(60, 20)
		tab:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5 * i, 5 * i)
		dock.DOCKED_CHAT_FRAMES[i] = frame
	end
	return dock
end

local function tab_of(dock, i)
	return _G[dock.DOCKED_CHAT_FRAMES[i]:GetName() .. 'Tab']
end

-- Blizzard's FCFDock_UpdateTabs (Forever 2322-2370, retail 2023-2069), then SaftUI's
-- post-hook with the same arguments. Blizzard clears each tab and gives it one anchor: the
-- first static tab sits on the dock (UIParent here), a later static one LEFT of the static
-- tab before it (+1), the first dynamic tab on the scroll child (LEFT, 0, -1) and a later
-- dynamic one LEFT of the dynamic tab before it (+1).
local function update(dock, forceUpdate)
	if dock.isDirty or forceUpdate then
		local scrollChild = dock.scrollFrame:GetScrollChild()
		local lastStatic, lastDynamic
		for index, frame in ipairs(dock.DOCKED_CHAT_FRAMES) do
			local tab = tab_of(dock, index)
			if tab then
				tab:ClearAllPoints()
				if frame.isStaticDocked then
					if lastStatic then
						tab:SetPoint('LEFT', lastStatic, 'RIGHT', 1, 0)
					else
						tab:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5, 5)
					end
					lastStatic = tab
				else
					if lastDynamic then
						tab:SetPoint('LEFT', lastDynamic, 'RIGHT', 1, 0)
					else
						tab:SetPoint('LEFT', scrollChild, 'LEFT', 0, -1)
					end
					lastDynamic = tab
				end
			end
		end
		dock.isDirty = false -- the end of Blizzard's function
	end
	CHT:FCFDock_UpdateTabs(dock, forceUpdate)
end

-- Where a docked tab ends up after SaftUI's layout: the first above its window, a static
-- one after it on the tab before it, with the one anchor.
local function assert_laid_out(dock, label)
	local first = tab_of(dock, 1)
	local point, relative, relPoint, x, y = first:GetPoint(1)
	eq(relative, dock.DOCKED_CHAT_FRAMES[1], label .. ': the first tab is above its window, not on the dock')
	eq(point .. ',' .. relPoint .. ',' .. x .. ',' .. y, 'BOTTOMLEFT,TOPLEFT,0,10', label .. ': at SaftUI\'s offset')
	eq(first:GetNumPoints(), 1, label .. ': one anchor')
end

-- Blizzard clears dock.isDirty before the post-hook runs (the end of FCFDock_UpdateTabs), so
-- the hook can't tell a plain dirty update from an idle call; it lays the row out every time.
-- Each of these is a path that is not forced.
test('a plain dirty update (a resize of ChatFrame1) lays the tabs out, not Blizzard', function()
	local dock = dock_of(3)
	dock.isDirty = true -- FCFDock_OnPrimarySizeChanged
	update(dock)
	assert_laid_out(dock, 'after a resize')
	eq(select(2, tab_of(dock, 2):GetPoint(1)), tab_of(dock, 1), 'tab 2 follows tab 1')
end)

test('a pick from the overflow list (FCFDock_SelectWindow) lays the tabs out', function()
	local dock = dock_of(5)
	update(dock, true)
	dock.isDirty = true -- FCFDock_SelectWindow: dirty, then an unforced update
	update(dock)
	assert_laid_out(dock, 'after a pick')
	eq(select(2, tab_of(dock, 3):GetPoint(1)), dock.scrollFrame:GetScrollChild(), 'the first dynamic tab stays on the scroll child')
end)

test('an undock (FCFDock_RemoveChatFrame) lays out the tabs that stay, and skips the one that left', function()
	local dock = dock_of(4, 4)
	update(dock, true)
	local gone = table.remove(dock.DOCKED_CHAT_FRAMES, 2) -- tDeleteItem, then dirty and an unforced update
	dock.isDirty = true
	update(dock)
	assert_laid_out(dock, 'after an undock')
	eq(select(2, tab_of(dock, 2):GetPoint(1)), tab_of(dock, 1), 'the window that was third is now on the first')
	eq(tab_of(dock, 2):GetNumPoints(), 1, 'one anchor')
	check(gone ~= dock.DOCKED_CHAT_FRAMES[2], 'the undocked window is no longer in the list')
end)

test('an idle call (nothing dirty, nothing forced) leaves the row as it is', function()
	local dock = dock_of(5)
	update(dock, true)
	local before = {}
	for i = 1, 5 do
		local point, relative, relPoint, x, y = tab_of(dock, i):GetPoint(1)
		before[i] = { point, relative, relPoint, x, y, tab_of(dock, i):GetNumPoints() }
	end
	update(dock)
	update(dock)
	for i = 1, 5 do
		local point, relative, relPoint, x, y = tab_of(dock, i):GetPoint(1)
		local was = before[i]
		eq(point .. relPoint .. x .. y .. tab_of(dock, i):GetNumPoints(), was[1] .. was[3] .. was[4] .. was[5] .. was[6], 'tab ' .. i .. ' unchanged')
		eq(relative, was[2], 'tab ' .. i .. ' on the same frame')
	end
end)

test('a forced update puts the first tab above its window', function()
	local dock = dock_of(3)
	update(dock, true)
	local frame = dock.DOCKED_CHAT_FRAMES[1]
	local point, relative, relPoint, x, y = tab_of(dock, 1):GetPoint(1)
	eq(point, 'BOTTOMLEFT', 'tab 1 point')
	eq(relative, frame, 'tab 1 is anchored to its window')
	eq(relPoint, 'TOPLEFT', 'tab 1 relative point')
	eq(x, 0, 'tab 1 x')
	eq(y, 10, 'tab 1 y')
end)

test('a forced update anchors each later static tab to the tab before it, with no gap', function()
	local dock = dock_of(4, 4)
	update(dock, true)
	for i = 1, 4 do
		eq(tab_of(dock, i):GetNumPoints(), 1, 'tab ' .. i .. " has the one anchor, not Blizzard's and SaftUI's")
	end
	for i = 2, 4 do
		local point, relative, relPoint, x, y = tab_of(dock, i):GetPoint(1)
		eq(relative, tab_of(dock, i - 1), 'tab ' .. i .. ' is anchored to tab ' .. (i - 1))
		eq(point, 'BOTTOMLEFT', 'tab ' .. i .. ' point')
		eq(relPoint, 'BOTTOMRIGHT', 'tab ' .. i .. ' relative point')
		eq(x .. ',' .. y, '0,0', 'tab ' .. i .. ' offset: the tabs touch')
	end
end)

-- The dock scrolls an overflowing row by moving the scroll child, so only a tab whose x
-- hangs off it scrolls. Blizzard anchors the first dynamic tab (ChatFrame3 and up) to the
-- scroll child and each later one to the tab before it; the hook leaves the first one's
-- anchor as Blizzard set it.
test("the first dynamic tab stays on the dock's scroll child, and the ones after it follow it", function()
	local dock = dock_of(5) -- two static, three dynamic
	update(dock, true)
	local scrollChild = dock.scrollFrame:GetScrollChild()
	local tab3 = tab_of(dock, 3)
	eq(tab3:GetNumPoints(), 1, 'one anchor')
	local point, relative, relPoint, x, y = tab3:GetPoint(1)
	eq(relative, scrollChild, "the first tab past the static ones is on the scroll child, as Blizzard's layout leaves it")
	eq(point .. ',' .. relPoint .. ',' .. x .. ',' .. y, 'LEFT,LEFT,0,-1', "Blizzard's own anchor, untouched")
	for i = 4, 5 do
		local _, rel = tab_of(dock, i):GetPoint(1)
		eq(rel, tab_of(dock, i - 1), 'tab ' .. i .. ' hangs off the tab before it, so it scrolls with the row')
		eq(tab_of(dock, i):GetNumPoints(), 1, 'tab ' .. i .. ' has the one anchor')
	end
	-- Chat 2 stays after chat 1, as the hook lays the static ones out.
	eq(select(2, tab_of(dock, 2):GetPoint(1)), tab_of(dock, 1), 'the second static tab follows the first')
end)

test('a window with no tab is skipped, and the next tab follows the one before it', function()
	local dock = dock_of(3, 3)
	_G['ChatFrame12Tab'] = nil
	update(dock, true)
	local _, relative = tab_of(dock, 3):GetPoint(1)
	eq(relative, tab_of(dock, 1), 'tab 3 is anchored to tab 1')
end)
