-- SaftUI-Chat's docked chat tabs (CHT:FCFDock_UpdateTabs, a post-hook on Blizzard's
-- FCFDock_UpdateTabs): on a forced update the first tab sits above its window, and each
-- later tab anchors to the tab before it.
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

-- A dock of `count` windows. The tabs start where Blizzard's own layout leaves them.
local function dock_of(count)
	local dock = { isDirty = false, DOCKED_CHAT_FRAMES = {} }
	for i = 1, count do
		local frame = CreateFrame('Frame', 'ChatFrame' .. (i + 10), UIParent)
		frame:SetSize(400, 200)
		frame:SetPoint('CENTER')
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

-- Blizzard's FCFDock_UpdateTabs, then SaftUI's post-hook with the same arguments.
local function update(dock, forceUpdate)
	if dock.isDirty or forceUpdate then
		-- Blizzard's layout: every tab cleared, then each docked one after the one before it
		-- with one anchor (the first on the dock's scroll child).
		local last
		for index in ipairs(dock.DOCKED_CHAT_FRAMES) do
			local tab = tab_of(dock, index)
			if tab then
				tab:ClearAllPoints()
				if last then
					tab:SetPoint('LEFT', last, 'RIGHT', 1, 0)
				else
					tab:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT', 5, 5)
				end
				last = tab
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

test('a forced update anchors each later tab to the tab before it', function()
	local dock = dock_of(4)
	update(dock, true)
	for i = 1, 4 do
		eq(tab_of(dock, i):GetNumPoints(), 1, 'tab ' .. i .. ' has the one anchor, not Blizzard\'s and SaftUI\'s')
	end
	for i = 2, 4 do
		local point, relative, relPoint = tab_of(dock, i):GetPoint(1)
		eq(relative, tab_of(dock, i - 1), 'tab ' .. i .. ' is anchored to tab ' .. (i - 1))
		eq(point, 'BOTTOMLEFT', 'tab ' .. i .. ' point')
		eq(relPoint, 'BOTTOMRIGHT', 'tab ' .. i .. ' relative point')
	end
end)

test('a window with no tab is skipped, and the next tab follows the one before it', function()
	local dock = dock_of(3)
	_G['ChatFrame12Tab'] = nil
	update(dock, true)
	local _, relative = tab_of(dock, 3):GetPoint(1)
	eq(relative, tab_of(dock, 1), 'tab 3 is anchored to tab 1')
end)
