-- Held rolls (SaftUI-Loot/roll.lua and rollinfo.lua): after you choose on a
-- roll, Blizzard takes its bar away, and SaftUI shows a bar of its own in its
-- place, locked on your choice, until the roll ends. Checks that:
--   - choosing on a roll matched to a loot history drop holds it in the same
--     place, with its item, timer, counts and tooltip;
--   - your choice's button is lit (Buttons > Blue) and the others dimmed, a
--     label names it, and the bar is drawn as the previews are (body as a bar,
--     icon and buttons as small frames), its lit border kept through a recolor;
--   - nothing on a held bar takes a click;
--   - its counts follow loot history updates, and a main spec Need held after
--     its dice animation keeps its drop and its time;
--   - it goes when its drop resolves (a winner, or all passed) and when its time
--     runs out;
--   - a roll with no drop is held with no counts;
--   - held and live bars stack together, and a new roll stacks after them;
--   - Test mode shows one of its preview bars locked;
--   - nothing is written onto Blizzard's roll frames or its container.
--
-- Real: SaftUI-Loot's config.lua, init.lua, roll.lua, rollinfo.lua and
-- Feed/rolls.lua, Core's helpers and edit mode (the rolls' mover), the theme
-- helpers' draw watch, and LibStringFormat-1.0.
-- Stand-ins:
--   - Blizzard's group loot container and its four roll frames
--     (Blizzard_UIPanels_Game/Mainline/GroupLootFrame.lua and .xml, forever),
--     trimmed to what they do with a roll: open it on the first free frame or
--     queue it, show its item and Greed or Transmog, count its time down, call
--     RollOnLoot from a roll button, and take the frame away on
--     CANCEL_LOOT_ROLL or when a main spec Need's dice animation ends (Blizzard
--     ends it from a 5 second C_Timer; the tests call GroupLootFrame_Remove);
--   - the game's roll and loot history API (GetLootRollItemInfo,
--     GetLootRollItemLink, GetLootRollTimeLeft, RollOnLoot, C_LootHistory) over
--     the rolls and drops each test sets up. A roll's time is in milliseconds,
--     as the game counts it.
-- Feed/rolls.lua calls LT:UpdateRollBars after every loot history update; the
-- tests call it themselves after changing a drop.

local locked = load_test_file('misc/fixtures/locked_widget.lua')

local LT, st, T, drawn, S
local game -- { rolls = { [rollID] = roll }, drops = { drop, ... }, rolled = { [rollID] = rollType } }

local ITEMS = {
	sword = { name = 'The Green Tower', quality = 2, texture = 135321,
		link = '|cff1eff00|Hitem:1204::::::::60:::::|h[The Green Tower]|h|r' },
	amulet = { name = 'Drakefire Amulet', quality = 4, texture = 133294,
		link = '|cffa335ee|Hitem:16309::::::::60:::::|h[Drakefire Amulet]|h|r' },
	cloth = { name = 'Linen Cloth', quality = 1, texture = 132889,
		link = '|cffffffff|Hitem:2589::::::::60:::::|h[Linen Cloth]|h|r' },
	ring = { name = 'Band of Thorns', quality = 3, texture = 133345, transmog = true,
		link = '|cff0070dd|Hitem:12345::::::::60:::::|h[Band of Thorns]|h|r' },
}
local ROLL_LENGTH = 120000 -- two minutes, in milliseconds

------------------------------------------------------------------ the game

local function game_api()
	game = { rolls = {}, drops = {}, rolled = {} }

	-- A roll's item: texture, name, count, quality, bindOnPickUp, canNeed,
	-- canGreed, canDisenchant, the three reasons, deSkillRequired, canTransmog.
	function GetLootRollItemInfo(rollID)
		local roll = game.rolls[rollID]
		if not roll then return end
		return roll.texture, roll.name, 1, roll.quality, true, true, true, false, 0, 0, 0, 0, roll.transmog == true
	end
	function GetLootRollItemLink(rollID)
		local roll = game.rolls[rollID]
		return roll and roll.link
	end
	function GetLootRollTimeLeft(rollID)
		local roll = game.rolls[rollID]
		if not roll then return 0 end
		return math.max(0, roll.length - (stub.time - roll.start) * 1000)
	end
	-- The roll buttons call this. The server's answer is the test's to send.
	function RollOnLoot(rollID, rollType)
		game.rolled[rollID] = rollType
	end
	-- One encounter, its drops all started at 0 and rolled for five minutes, on
	-- the history's millisecond clock.
	C_LootHistory = {
		GetLootHistoryTime = function() return stub.time * 1000 end,
		GetAllEncounterInfos = function() return { { encounterID = 7, startTime = 0, duration = 600000 } } end,
		GetSortedDropsForEncounter = function(encounterID)
			return encounterID == 7 and game.drops or {}
		end,
		GetSortedInfoForDrop = function(encounterID, index)
			if encounterID ~= 7 then return end
			for _, drop in ipairs(game.drops) do
				if drop.lootListKey == index then return drop end
			end
		end,
	}
	-- Item data for Test mode's previews: none cached, so they show their own names.
	C_Item = {
		GetItemInfo = function() return nil end,
		GetItemIconByID = function() return 134400 end,
		RequestLoadItemDataByID = function() end,
	}
end

------------------------------------------------------------------ Blizzard's roll frames

local BUTTONS = { { 'Need', 1 }, { 'Pass', 0 }, { 'Greed', 2 }, { 'Transmog', 4 } }

local function blizzard()
	local container = CreateFrame('Frame', 'GroupLootContainer', UIParent)
	container:SetPoint('BOTTOM', UIParent, 'BOTTOM', 0, 150)
	container:SetWidth(300)
	container.rollFrames, container.waitingRolls, container.maxIndex = {}, {}, 0
	container.reservedSize = 100

	function GroupLootContainer_CalcMaxIndex(self)
		local maxIdx = 0
		for k in pairs(self.rollFrames) do maxIdx = math.max(maxIdx, k) end
		rawset(self, 'maxIndex', maxIdx)
	end
	function GroupLootContainer_AddFrame(self, frame)
		local idx = self.maxIndex + 1
		for i = 1, self.maxIndex do
			if not self.rollFrames[i] then
				idx = i
				break
			end
		end
		self.rollFrames[idx] = frame
		if idx > self.maxIndex then rawset(self, 'maxIndex', idx) end
		GroupLootContainer_Update(self)
		frame:Show()
	end
	function GroupLootContainer_RemoveFrame(self, frame)
		local idx
		for k, v in pairs(self.rollFrames) do
			if v == frame then
				idx = k
				break
			end
		end
		frame:Hide()
		if idx then
			self.rollFrames[idx] = nil
			if idx == self.maxIndex then GroupLootContainer_CalcMaxIndex(self) end
			if #self.waitingRolls > 0 then
				local newRoll = table.remove(self.waitingRolls, 1)
				GroupLootContainer_AddRoll(newRoll.rollID, newRoll.rollTime)
			end
		end
		GroupLootContainer_Update(self)
	end
	-- Blizzard also has the container's layout parent lay it out; that isn't here.
	function GroupLootContainer_Update(self)
		local lastIdx
		for i = 1, self.maxIndex do
			local frame = self.rollFrames[i]
			if frame then
				frame:ClearAllPoints()
				frame:SetPoint('CENTER', self, 'BOTTOM', 0, self.reservedSize * (i - 1 + 0.5))
				lastIdx = i
			end
		end
		if lastIdx then
			self:SetHeight(self.reservedSize * lastIdx)
			self:Show()
		else
			self:Hide()
		end
	end
	function GroupLootContainer_AddRoll(rollID, rollTime)
		if not GroupLootContainer_OpenNewFrame(rollID, rollTime) then
			table.insert(GroupLootContainer.waitingRolls, { rollID = rollID, rollTime = rollTime })
		end
	end
	function GroupLootContainer_OpenNewFrame(rollID, rollTime)
		for i = 1, 4 do
			local frame = _G['GroupLootFrame' .. i]
			if not frame:IsShown() then
				rawset(frame, 'rollID', rollID)
				rawset(frame, 'rollTime', rollTime)
				frame.Timer:SetMinMaxValues(0, rollTime)
				GroupLootContainer_AddFrame(GroupLootContainer, frame)
				return true
			end
		end
		return false
	end

	function GroupLootFrame_OnShow(self)
		local texture, name, _, _, _, _, _, _, _, _, _, _, canTransmog = GetLootRollItemInfo(self.rollID)
		if name == nil then
			GroupLootContainer_RemoveFrame(GroupLootContainer, self)
			return
		end
		self.IconFrame.Icon:SetTexture(texture)
		self.Name:SetText(name)
		local buttons = self.LootButtonContainer
		buttons.TransmogButton:SetShown(canTransmog)
		buttons.GreedButton:SetShown(not canTransmog)
		self:RegisterEvent('CANCEL_LOOT_ROLL')
		self:RegisterEvent('CANCEL_ALL_LOOT_ROLLS')
		self:RegisterEvent('MAIN_SPEC_NEED_ROLL')
	end
	function GroupLootFrame_StopNeedAnimation(self)
		for _, button in ipairs(self.LootButtonContainer.LootButtons) do button:Show() end
		self.NeedRollAnim:Hide()
	end
	function GroupLootFrame_StartNeedAnimation(self)
		self.Timer:SetValue(0)
		for _, button in ipairs(self.LootButtonContainer.LootButtons) do button:Hide() end
		self.NeedRollAnim:Show()
	end
	function GroupLootFrame_OnHide(self)
		GroupLootFrame_StopNeedAnimation(self)
		self:UnregisterEvent('CANCEL_LOOT_ROLL')
		self:UnregisterEvent('CANCEL_ALL_LOOT_ROLLS')
		self:UnregisterEvent('MAIN_SPEC_NEED_ROLL')
	end
	function GroupLootFrame_Remove(self)
		if self:IsShown() then GroupLootContainer_RemoveFrame(GroupLootContainer, self) end
	end
	function GroupLootFrame_OnEvent(self, event, ...)
		if event == 'CANCEL_LOOT_ROLL' then
			if ... == self.rollID then GroupLootFrame_Remove(self) end
		elseif event == 'CANCEL_ALL_LOOT_ROLLS' then
			GroupLootFrame_Remove(self)
		elseif event == 'MAIN_SPEC_NEED_ROLL' then
			if ... == self.rollID then GroupLootFrame_StartNeedAnimation(self) end
		end
	end
	function GroupLootFrame_OnUpdate(self)
		if not self.rollID or self.NeedRollAnim:IsShown() then return end
		local left = GetLootRollTimeLeft(self.rollID)
		local min, max = self.Timer:GetMinMaxValues()
		if left < min or left > max then left = min end
		self.Timer:SetValue(left)
	end

	for i = 1, 4 do
		local name = 'GroupLootFrame' .. i
		local frame = CreateFrame('Frame', name, container)
		frame:Hide()
		frame:SetSize(243, 84)
		frame.IconFrame = CreateFrame('Button', nil, frame)
		frame.IconFrame.Icon = frame.IconFrame:CreateTexture(nil, 'ARTWORK')
		frame.IconFrame.Border = frame.IconFrame:CreateTexture(nil, 'OVERLAY')
		frame.IconFrame.Count = frame.IconFrame:CreateFontString(nil, 'OVERLAY')
		frame.IconFrame.Count:SetFontObject(GameFontNormal)
		frame.Timer = CreateFrame('StatusBar', nil, frame)
		frame.Timer.Background = frame.Timer:CreateTexture(nil, 'BACKGROUND')
		frame.Name = frame:CreateFontString(nil, 'OVERLAY')
		frame.Name:SetFontObject(GameFontNormal)
		_G[name .. 'NameFrame'] = frame:CreateTexture(nil, 'ARTWORK')
		_G[name .. 'Corner'] = frame:CreateTexture(nil, 'ARTWORK')
		frame.NeedRollAnim = CreateFrame('Frame', nil, frame)
		frame.NeedRollAnim:Hide()
		local buttons = CreateFrame('Frame', nil, frame)
		frame.LootButtonContainer = buttons
		buttons.LootButtons = {}
		for _, def in ipairs(BUTTONS) do
			local button = CreateFrame('Button', nil, buttons)
			button:SetID(def[2])
			button:SetScript('OnClick', function(self)
				RollOnLoot(self:GetParent():GetParent().rollID, self:GetID())
			end)
			buttons[def[1] .. 'Button'] = button
			table.insert(buttons.LootButtons, button)
		end
		frame:SetScript('OnShow', GroupLootFrame_OnShow)
		frame:SetScript('OnHide', GroupLootFrame_OnHide)
		frame:SetScript('OnEvent', GroupLootFrame_OnEvent)
		frame:SetScript('OnUpdate', GroupLootFrame_OnUpdate)
	end
end

------------------------------------------------------------------ the world

local function world()
	reset_world()
	load_core_helpers()
	T = load_test_file('lib/theme_helpers.lua')
	drawn = T.watch()
	for _, file in ipairs({ 'editmode', 'mover', 'picker', 'footer', 'grid', 'snap', 'settings' }) do
		load_saftui('SaftUI-Core/EditMode/' .. file .. '.lua')
	end
	load_saftui('SaftUI-Core/Libraries/LibStringFormat-1.0/LibStringFormat-1.0.lua')
	st = SaftUI
	st.StringFormat = LibStub('LibStringFormat-1.0') -- as SaftUI-Core/init.lua does
	CreateFrame('GameTooltip', 'GameTooltip', UIParent)
	game_api()
	blizzard()
	load_saftui('SaftUI-Loot/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Loot/init.lua')
	LT = st:GetModule('Loot')
	st:BindModuleConfig(LT, 'loot')
	load_saftui('SaftUI-Loot/roll.lua')
	load_saftui('SaftUI-Loot/rollinfo.lua')
	load_saftui('SaftUI-Loot/Feed/rolls.lua')
	S = LT.ROLL_STATE
	LT:InitializeRollFrame()
	stub.time = 0
	return LT
end

-- The Blizzard roll frame showing rollID.
local function frame_of(rollID)
	for i = 1, 4 do
		local frame = _G['GroupLootFrame' .. i]
		if frame:IsShown() and frame.rollID == rollID then return frame end
	end
end

-- The held bar of rollID.
local function held_bar(rollID)
	for _, bar in ipairs(LT:GetHeldRolls()) do
		if bar.rollID == rollID then return bar end
	end
end

-- Time passes: Blizzard's roll frames count down and SaftUI's skin and held
-- bars follow, as their OnUpdate scripts would every frame.
local function tick(seconds)
	stub.time = stub.time + seconds
	for i = 1, 4 do
		local frame = _G['GroupLootFrame' .. i]
		if frame:IsVisible() then
			stub.fire_script(frame, 'OnUpdate', seconds)
			stub.fire_script(frame.Timer, 'OnUpdate', seconds)
		end
	end
	local bar = LT:GetHeldRolls()[1]
	if bar then stub.fire_script(bar:GetParent(), 'OnUpdate', seconds) end
end

local nextRollID = 100

-- A roll of an item starts (START_LOOT_ROLL: Blizzard's GroupLootContainer_AddRoll).
local function start_roll(key)
	nextRollID = nextRollID + 1
	local item = ITEMS[key]
	game.rolls[nextRollID] = {
		name = item.name, quality = item.quality, texture = item.texture, link = item.link,
		transmog = item.transmog, length = ROLL_LENGTH, start = stub.time,
	}
	GroupLootContainer_AddRoll(nextRollID, ROLL_LENGTH)
	tick(0)
	return nextRollID
end

-- A loot history drop of an item, still being rolled, with the choices made on
-- it so far ({ name, class, state (a LT.ROLL_STATE name), roll }). You (Tester)
-- haven't chosen yet.
local function add_drop(key, choices)
	local infos = {}
	for _, c in ipairs(choices) do
		table.insert(infos, { playerName = c[1], playerClass = c[2], state = S[c[3]], roll = c[4] })
	end
	table.insert(infos, { playerName = 'Tester', playerClass = 'WARRIOR', state = S.NoRoll, isSelf = true })
	local drop = {
		lootListKey = #game.drops + 1, itemHyperlink = ITEMS[key].link, startTime = 0, duration = 300000,
		playerRollState = S.NoRoll, rollInfos = infos,
	}
	table.insert(game.drops, drop)
	return drop
end

-- The loot history now has your choice on a drop.
local function history_choice(drop, state, roll)
	drop.playerRollState = S[state]
	for _, info in ipairs(drop.rollInfos) do
		if info.isSelf then info.state, info.roll = S[state], roll end
	end
end

local STATE_OF = { Need = 'NeedMainSpec', Greed = 'Greed', Pass = 'Pass', Transmog = 'Transmog' }

-- You click a roll button on Blizzard's bar (RollOnLoot), and the server
-- answers: it cancels the roll for you (CANCEL_LOOT_ROLL, so Blizzard takes the
-- bar away), and the loot history gets your choice (after which Feed/rolls.lua
-- updates the roll bars).
local function choose(rollID, choice, drop)
	local frame = frame_of(rollID)
	stub.fire_script(frame.LootButtonContainer[choice .. 'Button'], 'OnClick', 'LeftButton', false)
	stub.fire_event('CANCEL_LOOT_ROLL', rollID)
	if drop then
		history_choice(drop, STATE_OF[choice])
		LT:UpdateRollBars()
	end
end

-- The number a held bar's choice button shows (its own count, bottom right),
-- or nil when it's hidden.
local function count(bar, choice)
	for text, c in pairs(bar.counts) do
		if c.choice == choice and not c.color and text:GetParent():IsShown() then
			return text:IsShown() and tostring(text:GetText()) or nil
		end
	end
end

local function counts_shown(bar)
	local n = 0
	for text in pairs(bar.counts) do
		if text:IsShown() then n = n + 1 end
	end
	return n
end

local function button_of(bar, choice)
	for _, button in ipairs(bar.buttons) do
		if button.choice == choice then return button end
	end
end

-- Whether any of the tooltip's left texts has needle in it.
local function tooltip_has(needle)
	for _, text in pairs(stub.state(GameTooltip).texts or {}) do
		if type(text) == 'string' and text:find(needle, 1, true) then return true end
	end
	return false
end

local function blue()
	return T.text(st.config.profile.colors.button.blue:GetRGB())
end

------------------------------------------------------------------ tests

test('choosing on a matched roll holds it in its place, with its item, timer, counts and tooltip', function()
	world()
	add_drop('sword', { { 'Brightblade', 'PALADIN', 'Greed' } })
	local amulet = add_drop('amulet', {
		{ 'Brightblade', 'PALADIN', 'NeedMainSpec', 92 },
		{ 'Mistweave', 'PRIEST', 'Greed' },
		{ 'Quickshot', 'HUNTER', 'Greed' },
	})
	add_drop('cloth', {})
	local a = start_roll('sword')
	local b = start_roll('amulet')
	local c = start_roll('cloth')
	LT:UpdateRollBars()
	tick(30)

	local frameB, frameC = frame_of(b), frame_of(c)
	local bottomB, leftB, bottomC = frameB:GetBottom(), frameB:GetLeft(), frameC:GetBottom()
	choose(b, 'Greed', amulet)

	check(not frameB:IsShown(), "Blizzard took the amulet's bar away")
	local bar = held_bar(b)
	check(bar ~= nil and bar:IsVisible(), 'a held bar shows in its place')
	if not bar then return end
	eq(bar:GetBottom(), bottomB, 'at the height the bar was')
	eq(bar:GetLeft(), leftB, 'and the same left edge')
	eq(frame_of(c):GetBottom(), bottomC, 'the roll after it stays where it was')
	check(frame_of(a) ~= nil and frame_of(c) ~= nil, 'the other rolls are still up')

	eq(bar.Name:GetText(), 'Drakefire Amulet', 'the item name')
	eq(bar.Icon:GetTexture(), ITEMS.amulet.texture, "the item's icon")
	eq(bar.Timer.Text:GetText(), '01:30', 'the time left: 30 of 120 seconds gone')
	local _, length = bar.Timer:GetMinMaxValues()
	eq(length, 120, 'the timer runs over the roll, in seconds')
	eq(bar.Timer:GetValue(), 90, 'with 90 left')
	eq(count(bar, 'Greed'), '3', 'Greed: two others and you')
	eq(count(bar, 'Need'), '1', 'Need: one')
	eq(count(bar, 'Pass'), nil, 'Pass: none, so no number')

	stub.fire_script(bar.InfoFrame, 'OnEnter')
	check(GameTooltip:IsOwned(bar.InfoFrame), 'hovering the bar shows its tooltip')
	eq(stub.state(GameTooltip).texts[1], ITEMS.amulet.link, 'the item first')
	check(tooltip_has('Brightblade') and tooltip_has('Mistweave') and tooltip_has('Quickshot'), "then everyone's choices")
	check(tooltip_has('Tester'), 'yours among them')
end)

test('your choice is lit and the others dimmed, a label names it, and it draws as the previews do', function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local roll = start_roll('amulet')
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end

	local lit = button_of(bar, 'Greed')
	eq(lit:GetAlpha(), 1, 'your choice stays bright')
	eq(T.edge_rgb(lit.Icon.backdrop), blue(), 'with a border in Buttons > Blue')
	for _, choice in ipairs({ 'Need', 'Pass' }) do
		local button = button_of(bar, choice)
		eq(T.text(button:GetAlpha()), '0.35', choice .. ' is dimmed')
		check(T.edge_rgb(button.Icon.backdrop) ~= blue(), choice .. "'s border is the theme's")
	end
	check(not button_of(bar, 'Transmog'):IsShown(), 'Greed shows, not Transmog, as on its Blizzard bar')
	check(bar.Choice:IsShown(), 'a label shows')
	eq(bar.Choice:GetText(), 'Greed', 'naming your choice')

	eq(drawn(bar.InfoFrame), 'theme,solid,bar', "the body: the Rolls Theme and Background, as a bar")
	eq(drawn(bar.IconFrame), 'theme,solid,small', 'the icon, as a small frame')
	eq(drawn(lit.Icon), 'theme,solid,small', 'each button, as a small frame')
	eq(T.around(lit.Icon.backdrop, lit), '0,0,0,0', "a button's border lies on its edges, the icon inside it")

	st:RecolorThemed()
	eq(T.edge_rgb(lit.Icon.backdrop), blue(), 'the lit border stays through a theme recolor')
	eq(T.edge_rgb(button_of(bar, 'Need').Icon.backdrop), T.text(unpack(st.config.profile.templates.thick.bordercolor, 1, 3)),
		"and the others keep the theme's")
end)

test("nothing on a held bar takes a click", function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	choose(roll, 'Need', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end

	for _, button in ipairs(bar.buttons) do
		check(not button:IsObjectType('Button'), button.choice .. ' is no button')
		check(not button:IsMouseEnabled(), button.choice .. ' takes no mouse')
		check(not button:GetScript('OnMouseDown') and not button:GetScript('OnMouseUp'), button.choice .. ' has no click scripts')
	end

	-- With the cursor over a button, the bar's body under it has the mouse: its
	-- tooltip shows, and there's nothing to click.
	local greed = button_of(bar, 'Greed')
	local x, y = greed:GetCenter()
	local scale = greed:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = x * scale, y * scale
	check(bar.InfoFrame:IsMouseMotionFocus(), "the body under the buttons has the mouse")
	eq(game.rolled[roll], 1, 'only your Need reached RollOnLoot')
end)

test('the counts follow loot history updates', function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local roll = start_roll('amulet')
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end
	eq(count(bar, 'Greed'), '2', 'Mistweave and you')
	eq(count(bar, 'Pass'), nil, 'nobody passed yet')

	stub.fire_script(bar.InfoFrame, 'OnEnter')
	table.insert(drop.rollInfos, { playerName = 'Stonefist', playerClass = 'SHAMAN', state = S.Pass })
	LT:UpdateRollBars()
	eq(count(bar, 'Pass'), '1', 'a pass after you chose is counted')
	check(tooltip_has('Stonefist'), 'and the open tooltip is rebuilt with it')
end)

test('a main spec Need held after its dice animation keeps its drop and its time', function()
	world()
	local drop = add_drop('amulet', { { 'Brightblade', 'PALADIN', 'NeedMainSpec', 41 } })
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(20)

	-- The server answers a main spec Need with the dice animation: Blizzard's
	-- bar stays up for 5 seconds, its timer zeroed and its buttons hidden.
	local frame = frame_of(roll)
	stub.fire_script(frame.LootButtonContainer.NeedButton, 'OnClick', 'LeftButton', false)
	stub.fire_event('MAIN_SPEC_NEED_ROLL', roll, 77, true)
	history_choice(drop, 'NeedMainSpec', 77)
	LT:UpdateRollBars()
	tick(5)
	check(frame:IsShown() and frame.Timer:GetValue() == 0, "Blizzard's bar is still up, its timer at 0")
	GroupLootFrame_Remove(frame) -- its C_Timer.After(5) callback

	local bar = held_bar(roll)
	check(bar ~= nil, 'held once the animation ends')
	if not bar then return end
	eq(count(bar, 'Need'), '2', 'with its drop: Brightblade and you')
	eq(bar.Timer.Text:GetText(), '01:35', 'and the time left when you chose, run on since')
	eq(bar.Choice:GetText(), 'Need', 'locked on Need')
end)

test('a held roll goes when its drop resolves', function()
	world()
	local amulet = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local cloth = add_drop('cloth', {})
	local a = start_roll('amulet')
	local b = start_roll('cloth')
	LT:UpdateRollBars()
	local bottomA = frame_of(a):GetBottom()
	choose(a, 'Greed', amulet)
	local bar = held_bar(a)
	check(bar ~= nil, 'held')
	if not bar then return end

	amulet.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	check(not bar:IsShown(), 'a winner: the held bar goes')
	eq(#LT:GetHeldRolls(), 0, 'no roll is held')
	eq(frame_of(b):GetBottom(), bottomA, 'and the roll after it moves into its place')

	choose(b, 'Pass', cloth)
	check(held_bar(b) ~= nil, 'the next roll is held')
	cloth.allPassed = true
	LT:UpdateRollBars()
	eq(held_bar(b), nil, 'everyone passed: it goes too')
end)

test('a held roll goes when its time runs out', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	tick(30)
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end

	tick(89)
	check(bar:IsShown(), 'still up with a second left')
	eq(bar.Timer.Text:GetText(), '00:01', 'counting down')
	tick(2)
	check(not bar:IsShown(), 'its time ran out: it goes')
	eq(#LT:GetHeldRolls(), 0, 'no roll is held')
end)

test('a roll with no loot history drop is held with no counts', function()
	world()
	local roll = start_roll('ring')
	tick(10)
	choose(roll, 'Transmog')
	LT:UpdateRollBars()
	local bar = held_bar(roll)
	check(bar ~= nil, 'held without a drop')
	if not bar then return end
	eq(counts_shown(bar), 0, 'no counts')
	eq(bar.Name:GetText(), 'Band of Thorns', 'the item')
	eq(bar.Timer.Text:GetText(), '01:50', 'the timer')
	eq(bar.Choice:GetText(), 'Transmog', 'your choice')
	check(button_of(bar, 'Transmog'):IsShown() and not button_of(bar, 'Greed'):IsShown(), 'Transmog, as its Blizzard bar had')
	eq(button_of(bar, 'Transmog'):GetAlpha(), 1, 'lit')

	stub.fire_script(bar.InfoFrame, 'OnEnter')
	eq(GameTooltip:NumLines(), 1, 'the tooltip is just the item')
	eq(stub.state(GameTooltip).texts[1], ITEMS.ring.link, 'by its link')
end)

test('held and live bars stack together, and a new roll stacks after them', function()
	world()
	local config = LT.config.roll
	local step = config.height + config.spacing
	local sword = add_drop('sword', {})
	local a = start_roll('sword')
	local b = start_roll('amulet')
	local c = start_roll('cloth')
	local base = frame_of(a):GetBottom()
	eq(frame_of(b):GetBottom(), base + step, 'the rolls stack up from the anchor')
	eq(frame_of(c):GetBottom(), base + 2 * step, 'one above the other')

	-- The middle roll is held where it was; a new roll takes Blizzard's free
	-- frame and its slot, and stacks after the held bar.
	choose(b, 'Greed')
	eq(held_bar(b):GetBottom(), base + step, 'held in the middle')
	eq(frame_of(c):GetBottom(), base + 2 * step, 'the roll after it stays')
	local d = start_roll('ring')
	eq(frame_of(d):GetBottom(), base + 2 * step, "the new roll, in the held roll's slot, comes after it")
	eq(frame_of(c):GetBottom(), base + 3 * step, 'and the one after moves up')

	-- Held all the way: a new roll goes after every held bar.
	choose(a, 'Pass', sword)
	choose(c, 'Greed')
	choose(d, 'Need')
	eq(held_bar(a):GetBottom(), base, 'each held bar stays where its roll was')
	eq(held_bar(b):GetBottom(), base + step, 'each held bar stays where its roll was')
	eq(held_bar(d):GetBottom(), base + 2 * step, 'each held bar stays where its roll was')
	eq(held_bar(c):GetBottom(), base + 3 * step, 'each held bar stays where its roll was')
	local e = start_roll('sword')
	eq(frame_of(e):GetBottom(), base + 4 * step, 'a new roll stacks after them')

	-- One goes: the stack closes up.
	sword.winner = { playerName = 'Brightblade', playerClass = 'PALADIN' }
	LT:UpdateRollBars()
	eq(held_bar(a), nil, 'the first roll ended')
	eq(held_bar(b):GetBottom(), base, 'the rest move down into the gap')
	eq(frame_of(e):GetBottom(), base + 3 * step, 'the live roll too')
end)

test('Test mode shows one of its preview bars locked', function()
	world()
	LT:SetTestRolls(true)
	local previews = LT.rollPreview
	check(previews ~= nil and previews:IsShown(), 'the previews show')
	if not previews then return end
	local lockedBars = {}
	for _, bar in ipairs(previews.bars) do
		if bar.Choice:IsShown() then
			table.insert(lockedBars, bar)
		else
			for _, button in ipairs(bar.buttons) do
				eq(button:GetAlpha(), 1, 'an unlocked bar has every button bright')
			end
		end
	end
	eq(#lockedBars, 1, 'one preview is locked')
	local bar = lockedBars[1]
	if not bar then return end
	local choice = bar.Choice:GetText()
	local lit = button_of(bar, choice)
	check(lit ~= nil and lit:IsShown(), 'its label names a button it shows')
	eq(lit:GetAlpha(), 1, 'that one bright')
	eq(T.edge_rgb(lit.Icon.backdrop), blue(), 'and lit')
	for _, button in ipairs(bar.buttons) do
		if button ~= lit and button:IsShown() then eq(T.text(button:GetAlpha()), '0.35', 'the others dimmed') end
	end
	check(count(bar, choice) ~= nil, 'your choice is counted on it')

	-- A held roll is a real roll: the previews make way for it.
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	choose(roll, 'Greed', drop)
	check(held_bar(roll) ~= nil, 'the roll is held')
	stub.fire_script(LT.rollPreviewDriver, 'OnUpdate', 0.3) -- the previews' poll
	check(not previews:IsShown(), 'the previews hide while a roll is held')
end)

------------------------------------------------------------------ no fields on Blizzard's frames

local function keys_of(widget)
	local keys = {}
	for k in pairs(widget) do keys[k] = true end
	return keys
end

test("holding rolls writes nothing onto Blizzard's roll frames or its container", function()
	world()
	-- Blizzard's pieces SaftUI touches, locked so a write of a new field errors.
	-- The art (IconFrame's Icon, Border and Count, Timer.Background, NameFrame,
	-- Corner) is left open: st:Kill and st:SkinIcon still write onto those (see
	-- docs/followups.md, and tests/loot/roll_skin_test.lua).
	local pieces = { GroupLootContainer }
	for i = 1, 4 do
		local frame = _G['GroupLootFrame' .. i]
		for _, widget in ipairs({ frame, frame.IconFrame, frame.Timer, frame.LootButtonContainer }) do
			table.insert(pieces, widget)
		end
		for _, button in ipairs(frame.LootButtonContainer.LootButtons) do table.insert(pieces, button) end
	end
	local before = {}
	for i, widget in ipairs(pieces) do
		before[i] = keys_of(widget)
		locked(widget, 'Blizzard roll')
	end

	local amulet = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local sword = add_drop('sword', {})
	local a = start_roll('amulet')
	local b = start_roll('sword')
	local c = start_roll('ring')
	LT:UpdateRollBars()
	tick(10)
	choose(a, 'Greed', amulet)
	choose(b, 'Need', sword)
	choose(c, 'Pass')
	table.insert(amulet.rollInfos, { playerName = 'Stonefist', playerClass = 'SHAMAN', state = S.Pass })
	LT:UpdateRollBars()
	amulet.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	start_roll('cloth')
	tick(200)
	eq(#LT:GetHeldRolls(), 0, 'every held roll went')

	local added = {}
	for i, widget in ipairs(pieces) do
		for k in pairs(widget) do
			if not before[i][k] and not (type(k) == 'string' and (k == 'rollID' or k == 'rollTime' or k == 'maxIndex')) then
				table.insert(added, i .. ':' .. tostring(k))
			end
		end
	end
	eq(table.concat(added, ', '), '', 'fields SaftUI added to Blizzard frames')
end)
