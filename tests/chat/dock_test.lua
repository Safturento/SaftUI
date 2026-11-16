-- SaftUI-Chat's docked chat tabs (CHT:FCFDock_UpdateTabs, a post-hook on Blizzard's
-- FCFDock_UpdateTabs): on a forced update the first tab sits above its window, and each
-- later tab anchors to the tab before it, except the first one on the dock's scroll child
-- (ChatFrame3 and up), which keeps Blizzard's anchor so an overflowing row still scrolls.
--
-- Blizzard's FCFDock_UpdateTabs (FloatingChatFrame.lua, both clients) returns at once
-- when `not dock.isDirty and not forceUpdate`, and otherwise ends with
-- `dock.isDirty = false`. The game runs a post-hook after it, so by then isDirty is
-- already false: the hook lays the tabs out only on a forced update (a call with
-- forceUpdate, as Blizzard makes after a window is added or closed and when the gamepad
-- mode changes). In game the docked tabs sit right after a drag and dock and after a
-- plain tab switch (checked 2026-11-13), so that is harmless; these cases call the hook as
-- the game does and pin the early return and the forced update.
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

test('a plain update leaves the tabs where Blizzard put them: its isDirty is already cleared', function()
	local dock = dock_of(3)
	dock.isDirty = true -- a window was docked; Blizzard lays the tabs out and clears it
	update(dock)
	local tab = tab_of(dock, 1)
	local point, relative, relPoint, x, y = tab:GetPoint(1)
	eq(relative, UIParent, "the first tab is still anchored where Blizzard's layout left it")
	eq(x .. ',' .. y, '5,5', 'at the same offset')

	update(dock) -- nothing dirty, nothing forced
	_, relative, _, x, y = tab:GetPoint(1)
	eq(relative, UIParent, 'a clean, unforced update changes nothing either')
	eq(x .. ',' .. y, '5,5', 'at the same offset')
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
