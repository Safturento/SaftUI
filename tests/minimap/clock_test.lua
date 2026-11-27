-- The micro menu's clock (SaftUI-Minimap/clockbutton.lua):
--   - it shows realm or local time by Blizzard's own setting,
--     timeMgrUseLocalTime, which a right click switches;
--   - with Blizzard's time manager loaded, the switch goes through its own
--     toggle, so its cached copy and its Use Local Time box agree;
--   - in combat the switch waits for the end of the fight, the clock showing
--     the new choice at once;
--   - a left click opens the calendar through GameTimeFrame's OnClick (the old
--     global GameTimeFrame_OnClick is gone on Forever), Shift the time manager;
--   - the tooltip names both times and the clicks.
--
-- Real: Core's helpers and the clock's file. Blizzard's time functions and
-- frames are stand-ins.
load_core_helpers()
CreateFrame('Frame', 'Minimap', UIParent)
load_saftui('SaftUI-Minimap/minimap.lua')
load_saftui('SaftUI-Minimap/config.lua')
apply_defaults()
load_saftui('SaftUI-Minimap/micromenu.lua')
load_saftui('SaftUI-Minimap/clockbutton.lua')

local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')
GameTooltip = GameTooltip or CreateFrame('GameTooltip', 'GameTooltip', UIParent)

stub.cvars.timeMgrUseLocalTime = '0'
function GameTime_GetGameTime(ampm) return ampm and '9:00 PM' or '21:00' end
function GameTime_GetLocalTime(ampm) return ampm and '1:00 PM' or '13:00' end

local calls
GameTimeFrame = CreateFrame('Button', 'GameTimeFrame', UIParent)
function GameTimeFrame:OnClick() calls[#calls + 1] = 'calendar' end

local button = MicroMenu:SkinTimeManagerClockButton()

local function fresh()
	calls = {}
	stub.in_combat = false
	stub.shift_down = false
	stub.cvars.timeMgrUseLocalTime = '0'
	TimeManager_ToggleLocalTime, TimeManager_StartCheckingAlarm, TimeManagerLocalTimeCheck = nil, nil, nil
	TimeManager_Toggle, TimeManager_LoadUI, TimeManagerFrame = nil, nil, nil
end

local function shown()
	stub.fire_script(button, 'OnUpdate', 0)
	return button.text:GetText()
end

local function click(mouseButton)
	stub.fire_script(button, 'OnClick', mouseButton)
end

test('the clock takes right clicks as well as left', function()
	local registered = stub.state(button).click_buttons
	check(registered and #registered == 2, 'two buttons registered')
	eq(registered[1], 'LeftButtonUp', 'left')
	eq(registered[2], 'RightButtonUp', 'right')
end)

test('a right click switches between realm and local time, in the game setting', function()
	fresh()
	eq(shown(), '21:00', 'realm time at first')
	click('RightButton')
	eq(stub.cvars.timeMgrUseLocalTime, '1', 'the setting says local')
	eq(shown(), '13:00', 'local time')
	click('RightButton')
	eq(stub.cvars.timeMgrUseLocalTime, '0', 'and back to realm')
	eq(shown(), '21:00', 'realm time again')
	eq(#calls, 0, 'no calendar')
end)

test('with the time manager loaded, its own toggle switches it', function()
	fresh()
	local checked
	TimeManagerLocalTimeCheck = { SetChecked = function(_, v) checked = v end }
	function TimeManager_ToggleLocalTime()
		calls[#calls + 1] = 'toggle'
		C_CVar.SetCVar('timeMgrUseLocalTime', stub.cvars.timeMgrUseLocalTime == '1' and '0' or '1')
	end
	function TimeManager_StartCheckingAlarm() calls[#calls + 1] = 'alarm' end
	click('RightButton')
	eq(calls[1], 'toggle', "Blizzard's toggle")
	eq(calls[2], 'alarm', 'the alarm checked against the new time')
	eq(checked, true, 'its box checked')
	eq(stub.cvars.timeMgrUseLocalTime, '1', 'the setting says local')
end)

test('in combat the switch waits for the end of the fight', function()
	fresh()
	stub.in_combat = true
	click('RightButton')
	eq(stub.cvars.timeMgrUseLocalTime, '0', 'the setting unchanged in combat')
	eq(#stub.blocked, 0, 'nothing blocked')
	eq(shown(), '13:00', 'the clock shows the choice at once')
	click('RightButton')
	click('RightButton')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(stub.cvars.timeMgrUseLocalTime, '1', 'the last choice set after the fight')
	eq(shown(), '13:00', 'still local')
end)

test('two switches in combat that cancel out change nothing', function()
	fresh()
	stub.in_combat = true
	click('RightButton')
	click('RightButton')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(stub.cvars.timeMgrUseLocalTime, '0', 'realm as before')
	eq(shown(), '21:00', 'realm time')
end)

test("a left click opens the calendar through GameTimeFrame's OnClick", function()
	fresh()
	click('LeftButton')
	eq(calls[1], 'calendar', 'the calendar')
	eq(stub.cvars.timeMgrUseLocalTime, '0', 'the time unchanged')
end)

test('Shift and a left click open the time manager, loading it first', function()
	fresh()
	stub.shift_down = true
	function TimeManager_LoadUI()
		TimeManagerFrame = CreateFrame('Frame', nil, UIParent)
		function TimeManager_Toggle() calls[#calls + 1] = 'timemanager' end
		return true
	end
	click('LeftButton')
	eq(calls[1], 'timemanager', 'the time manager')
	eq(#calls, 1, 'no calendar')
end)

test('the tooltip names both times and the clicks', function()
	fresh()
	stub.fire_script(button, 'OnEnter')
	check(GameTooltip:IsOwned(button), 'the clock owns the tooltip')
	local s = stub.state(GameTooltip)
	eq(s.texts[1], 'Realm time', 'the title is the time shown')
	local all = table.concat(s.texts, '|')
	check(all:find('Right-click: show local time', 1, true), 'the right click hint')
	click('RightButton')
	eq(stub.state(GameTooltip).texts[1], 'Local time', 'redrawn after a switch')
	stub.fire_script(button, 'OnLeave')
	check(not GameTooltip:IsShown(), 'hidden on leave')
end)
