-- SaftUI-Chat's docked chat tabs (CHT:FCFDock_UpdateTabs, a post-hook on Blizzard's
-- FCFDock_UpdateTabs): the first tab sits above its window, and each later tab
-- anchors to the tab before it.
--
-- Real: SaftUI-Chat's config.lua and chatframe.lua, Core's helpers and edit mode.
-- Stand-ins: the dock is a plain table with Blizzard's DOCKED_CHAT_FRAMES list, each a
-- chat window with its Tab (Blizzard's FCFDock_UpdateTabs walks that list the same way).
load_core_helpers()
load_editmode()
load_saftui('SaftUI-Chat/config.lua')
apply_defaults()
load_saftui('SaftUI-Chat/chatframe.lua')

local CHT = SaftUI:GetModule('Chat')

local function dock_of(count)
	local dock = { isDirty = true, DOCKED_CHAT_FRAMES = {} }
	for i = 1, count do
		local frame = CreateFrame('Frame', 'ChatFrame' .. (i + 10), UIParent)
		frame:SetSize(400, 200)
		frame:SetPoint('CENTER')
		frame.Tab = CreateFrame('Button', 'ChatFrame' .. (i + 10) .. 'Tab', frame)
		frame.Tab:SetSize(60, 20)
		dock.DOCKED_CHAT_FRAMES[i] = frame
	end
	return dock
end

test('the first tab sits above its window', function()
	local dock = dock_of(3)
	CHT:FCFDock_UpdateTabs(dock)
	local frame = dock.DOCKED_CHAT_FRAMES[1]
	local point, relative, relPoint, x, y = frame.Tab:GetPoint(1)
	eq(point, 'BOTTOMLEFT', 'tab 1 point')
	eq(relative, frame, 'tab 1 is anchored to its window')
	eq(relPoint, 'TOPLEFT', 'tab 1 relative point')
	eq(x, 0, 'tab 1 x')
	eq(y, 10, 'tab 1 y')
end)

test('each later tab anchors to the tab before it', function()
	local dock = dock_of(4)
	CHT:FCFDock_UpdateTabs(dock)
	local frames = dock.DOCKED_CHAT_FRAMES
	for i = 2, 4 do
		local point, relative, relPoint = frames[i].Tab:GetPoint(1)
		eq(relative, frames[i - 1].Tab, 'tab ' .. i .. ' is anchored to tab ' .. (i - 1))
		eq(point, 'BOTTOMLEFT', 'tab ' .. i .. ' point')
		eq(relPoint, 'BOTTOMRIGHT', 'tab ' .. i .. ' relative point')
	end
end)
