-- SaftUI-Loot/roll.lua's skin of Blizzard's GroupLootFrames: it must write no
-- field onto them (.agents/taint.md rule 1), keep its pieces in its own tables,
-- and still drive the skin from those, and it does no math on the icon frame's
-- level, which can be secret. Loads the real roll.lua and rollinfo.lua.
-- The stub roll frame mirrors Blizzard's GroupLootFrameTemplate on Forever: the
-- buttons sit in a LootButtonContainer child.
--
-- Not covered: st:Kill and st:SkinIcon, which the skin still calls on Blizzard's
-- art and its icon texture and which write onto those (see docs/followups.md).
-- The art pieces (Border, Background, NameFrame, Corner, Count) are left
-- unlocked in the stub for that reason.

local locked = load_test_file('misc/fixtures/locked_widget.lua')

local function world()
	reset_world()
	load_core_helpers()
	-- The roll's item as the game gives it (name, quality 4, no count over one,
	-- bind on pickup): only what GroupLootFrame_OnShow reads. A stand-in for the
	-- game's API; the skin's real code runs over it.
	ITEM_QUALITY_COLORS = { [1] = { r = 1, g = 1, b = 1 }, [4] = { r = 0.64, g = 0.21, b = 0.93 } }
	GetLootRollItemInfo = function(rollID)
		return 134400, 'Drakefire Amulet', 1, 4, true, true, true, false
	end
	load_saftui('SaftUI-Core/skinning.lua')
	load_saftui('SaftUI-Loot/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Loot/init.lua')
	-- Stands in for LibStringFormat-1.0 (SaftUI-Core/init.lua takes it from
	-- LibStub): only ToClock, as m:ss. The real one does more.
	SaftUI.StringFormat = { ToClock = function(_, sec) return ('%d:%02d'):format(sec / 60, sec % 60) end }
	local LT = SaftUI:GetModule('Loot')
	LT.config = SaftUI.config.profile.loot
	load_saftui('SaftUI-Loot/roll.lua')
	load_saftui('SaftUI-Loot/rollinfo.lua')
	return LT
end

local counter = 0

-- A GroupLootFrame as Blizzard builds it. The frame, its Timer, IconFrame and
-- buttons are locked, so a write of a new field onto them errors.
local function blizzard_roll_frame()
	counter = counter + 1
	local name = 'GroupLootFrame' .. counter
	local frame = CreateFrame('Frame', name, UIParent)
	frame:SetSize(280, 84)
	frame.rollID = 7

	frame.IconFrame = CreateFrame('Frame', nil, frame)
	frame.IconFrame.Icon = frame.IconFrame:CreateTexture(nil, 'ARTWORK')
	frame.IconFrame.Border = frame.IconFrame:CreateTexture(nil, 'OVERLAY')
	frame.IconFrame.Count = frame.IconFrame:CreateFontString(nil, 'OVERLAY')
	frame.IconFrame.Count:SetFontObject(GameFontNormal)

	frame.Timer = CreateFrame('StatusBar', nil, frame)
	frame.Timer:SetMinMaxValues(0, 300)
	frame.Timer:SetValue(120)
	frame.Timer.Background = frame.Timer:CreateTexture(nil, 'BACKGROUND')

	frame.Name = frame:CreateFontString(nil, 'OVERLAY')
	frame.Name:SetFontObject(GameFontNormal)

	_G[name .. 'NameFrame'] = frame:CreateTexture(nil, 'ARTWORK')
	_G[name .. 'Corner'] = frame:CreateTexture(nil, 'ARTWORK')

	local container = CreateFrame('Frame', nil, frame)
	frame.LootButtonContainer = container
	for _, button in ipairs({ 'Pass', 'Greed', 'Need' }) do
		container[button .. 'Button'] = CreateFrame('Button', nil, container)
	end

	local pieces = { frame, frame.IconFrame, frame.Timer, container }
	for _, button in ipairs({ 'Pass', 'Greed', 'Need' }) do
		tinsert(pieces, container[button .. 'Button'])
	end
	return frame, pieces
end

local function keys_of(widget)
	local keys = {}
	for k in pairs(widget) do keys[k] = true end
	return keys
end

local function snapshot(pieces)
	local all = {}
	for i, widget in ipairs(pieces) do all[i] = keys_of(widget) end
	return all
end

-- Keys that a piece has now and didn't before the skin.
local function new_keys(pieces, before)
	local added = {}
	for i, widget in ipairs(pieces) do
		for k in pairs(widget) do
			if not before[i][k] then tinsert(added, i .. ':' .. tostring(k)) end
		end
	end
	table.sort(added)
	return added
end

test('skinning a roll frame leaves no new field on it or its pieces', function()
	local LT = world()
	local frame, pieces = blizzard_roll_frame()
	local before = snapshot(pieces)
	for _, widget in ipairs(pieces) do locked(widget, 'Blizzard roll') end

	LT:SkinRollFrame(frame)
	LT:UpdateRollFrame(frame)
	eq(table.concat(new_keys(pieces, before), ', '), '', 'fields added to Blizzard frames')
end)

test('the pieces come from the side table', function()
	local LT = world()
	local frame = blizzard_roll_frame()
	LT:SkinRollFrame(frame)

	local info = LT:GetRollInfoFrame(frame)
	check(info, 'the info frame is found by the roll frame')
	eq(info:GetParent(), frame, 'the info frame is a child of the roll frame')
	check(info.backdrop, 'the info frame has its backdrop (a SaftUI frame, so a field is fine)')
	eq(LT:GetRollInfoFrame(blizzard_roll_frame()), nil, 'an unskinned frame has none')

	-- The icon's backdrop is on a SaftUI frame over the icon frame, not on it.
	eq(frame.IconFrame.backdrop, nil, 'no backdrop field on the icon frame')
	local found
	for _, child in ipairs({ frame.IconFrame:GetChildren() }) do
		if child.backdrop then found = child end
	end
	check(found, 'a SaftUI child of the icon frame holds the backdrop')
	eq(found:GetFrameLevel(), frame.IconFrame:GetFrameLevel() + 1, "one level over the icon frame, so the Blizzard theme's ring lies over the icon")
	eq(found.backdrop:GetFrameLevel(), frame.IconFrame:GetFrameLevel() - 1, 'backdrop one below the icon frame')

	local config = LT.config.roll
	eq(frame:GetWidth(), config.width, 'UpdateRollFrame sized the frame')
	eq(frame.IconFrame:GetWidth(), config.height, 'and the icon frame')
end)

test('skinning twice is a no-op, and option updates reach every skinned frame', function()
	local LT = world()
	local frame = blizzard_roll_frame()
	LT:SkinRollFrame(frame)
	local info = LT:GetRollInfoFrame(frame)
	LT:SkinRollFrame(frame)
	eq(#LT.skinnedRollFrames, 1, 'tracked once')
	eq(LT:GetRollInfoFrame(frame), info, 'same info frame')

	LT.config.roll.width = 333
	LT:UpdateRollFrame(frame)
	eq(frame:GetWidth(), 333, 'new width applied')
	eq(LT:GetRollInfoFrame(frame), info, 'the info frame is kept, not remade')
end)

test('the timer hook drives the timer text through the side table', function()
	local LT = world()
	local frame = blizzard_roll_frame()
	LT:SkinRollFrame(frame)
	local timer_text
	for _, region in ipairs({ frame.Timer:GetRegions() }) do
		if region:GetObjectType() == 'FontString' then timer_text = region end
	end
	check(timer_text, 'the timer has a font string')

	frame.Timer:SetValue(120)
	stub.fire_script(frame.Timer, 'OnUpdate', 0.1)
	eq(timer_text:GetText(), SaftUI.StringFormat:ToClock(120), 'two minutes shown')
	local r, g, b = timer_text:GetVertexColor()
	check(r == 1 and g == 1 and b == 1, 'white at 60 seconds or more')

	frame.Timer:SetValue(30)
	stub.fire_script(frame.Timer, 'OnUpdate', 0.1)
	eq(timer_text:GetText(), SaftUI.StringFormat:ToClock(30), 'thirty seconds shown')
	local red = SaftUI.config.profile.colors.text.red
	local rr, rg, rb = red:GetRGB()
	r, g, b = timer_text:GetVertexColor()
	check(math.abs(r - rr) < 1e-6 and math.abs(g - rg) < 1e-6 and math.abs(b - rb) < 1e-6, 'red under 60 seconds')

	-- The game times a roll in milliseconds (START_LOOT_ROLL's rollTime,
	-- GetLootRollTimeLeft): Blizzard's timer runs from the roll's length in
	-- them, and the text still reads seconds.
	frame.Timer:SetMinMaxValues(0, 120000)
	frame.Timer:SetValue(30000)
	stub.fire_script(frame.Timer, 'OnUpdate', 0.1)
	eq(timer_text:GetText(), SaftUI.StringFormat:ToClock(30), 'a roll timed in milliseconds: thirty seconds shown')

	-- A timer SaftUI never skinned is left alone.
	local other = CreateFrame('StatusBar', nil, UIParent)
	other:SetMinMaxValues(0, 10)
	LT:GroupLootFrame_OnUpdateTimer(other, 0.1)
end)

test('each roll button gets its letter, and rollinfo hooks the info frame', function()
	local LT = world()
	local frame = blizzard_roll_frame()
	LT:SkinRollFrame(frame)

	local container = frame.LootButtonContainer
	for _, name in ipairs({ 'Pass', 'Greed', 'Need' }) do
		local letters = 0
		for _, region in ipairs({ container[name .. 'Button']:GetRegions() }) do
			if region:GetObjectType() == 'FontString' and region:GetNumPoints() == 1 then
				local point = region:GetPoint(1)
				if point == 'CENTER' then letters = letters + 1 end
			end
		end
		eq(letters, 1, name .. ' has one centered letter')
	end

	-- AttachRollInfo found the info frame through the accessor and put the
	-- tooltip scripts on it.
	local info = LT:GetRollInfoFrame(frame)
	check(info:GetScript('OnEnter'), 'the info frame has the tooltip scripts')
end)

test('a roll takes the profile quality color for its name and timer', function()
	local LT = world()
	local frame = blizzard_roll_frame()
	LT:SkinRollFrame(frame)
	LT:GroupLootFrame_OnShow(frame)
	local er, eg, eb = SaftUI.config.profile.colors.item_quality[4]:GetRGB()
	local r, g, b = frame.Name:GetVertexColor()
	check(r == er and g == eg and b == eb, "the name is the profile's quality color, not Blizzard's")
	r, g, b = frame.Timer:GetStatusBarColor()
	check(r == er and g == eg and b == eb, "the timer is the profile's quality color, not Blizzard's")
end)

test('a roll of an item whose quality has no color does not error', function()
	local LT = world()
	-- Quality 99: not in the profile's colors or Blizzard's.
	GetLootRollItemInfo = function() return 134400, 'Strange Thing', 1, 99, true, true, true, false end
	local frame = blizzard_roll_frame()
	LT:SkinRollFrame(frame)
	LT:GroupLootFrame_OnShow(frame)
	check(true, 'OnShow returned')
end)

-- The icon frame is Blizzard's, and a frame level can be secret
-- (.agents/clients.md), so the skin does no math on it: its box and the box's
-- backdrop stay at the levels they were made at. A secret value is a newproxy
-- here, which issecretvalue is told to recognise.
test("an icon frame whose level is secret is skinned without math on it", function()
	local LT = world()
	local frame = blizzard_roll_frame()
	local level = frame.IconFrame:GetFrameLevel()
	local secret = newproxy(false)
	local real = issecretvalue
	issecretvalue = function(v) return v == secret or real(v) end
	frame.IconFrame.GetFrameLevel = function() return secret end
	local ok, err = pcall(LT.SkinRollFrame, LT, frame)
	check(ok, 'skinned: ' .. tostring(err))
	ok, err = pcall(LT.UpdateRollFrame, LT, frame)
	check(ok, 'and updated again: ' .. tostring(err))
	issecretvalue = real

	local box
	for _, child in ipairs({ frame.IconFrame:GetChildren() }) do
		if child.backdrop then box = child end
	end
	if check(box ~= nil, 'the icon box is made') then
		eq(box:GetFrameLevel(), level + 1, "the box where it was made, one over the icon frame")
	end
	eq(#take_errors(), 0, 'no errors')
end)
