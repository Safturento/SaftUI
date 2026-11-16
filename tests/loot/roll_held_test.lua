-- Held rolls (SaftUI-Loot/roll.lua and rollinfo.lua): after you choose on a
-- roll, Blizzard takes its bar away, and SaftUI shows a bar of its own in its
-- place, locked on your choice, until the roll ends. Checks that:
--   - choosing on a roll matched to a loot history drop holds it in the same
--     place, with its item, timer, counts and tooltip;
--   - your choice's button is lit (the accent) and the others dimmed, a
--     label names it, and the bar is drawn as the previews are (body as a bar,
--     icon as a slot, the lit button as a small frame), its lit border kept
--     through a recolor;
--   - nothing on a held bar takes a click;
--   - its counts follow loot history updates, and a main spec Need held after
--     its dice animation keeps its drop and its time;
--   - it finishes when its drop resolves (a winner, or all passed) and when its
--     time runs out: it stays up locked for 3 seconds, fades over half a second
--     and then goes, and the stack closes; it takes no drop meanwhile, has its
--     drop's final counts, and CANCEL_ALL_LOOT_ROLLS takes it at once; the
--     roll that resolved before it was held (the last to choose) does the same;
--   - /sui debug's prints for a held roll's decisions, off unless turned on;
--   - a roll with no drop is held with no counts;
--   - held and live bars stack together, and a new roll stacks after them;
--   - Test mode shows one of its preview bars locked;
--   - nothing is written onto Blizzard's roll frames or its container.
--
-- Real: SaftUI-Loot's config.lua, init.lua, rollbar.lua, roll.lua, rolltest.lua,
-- rollinfo.lua and Feed/loothistory.lua and rolls.lua, Core's helpers and edit mode (the rolls' mover), the theme
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

local locked = load_test_file('lib/locked_widget.lua')

-- Where the roll buttons are: Forever keeps them in a LootButtonContainer child,
-- retail directly on the roll frame (GroupLootFrame.xml on each). The tests of a
-- click run on both (each_shape); the rest on Forever's.
local SHAPE = 'forever'
local function BC(frame) return frame.LootButtonContainer or frame end

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
	-- The roll buttons call this, and the client answers INSIDE the call, before
	-- it returns (the events are synchronous): a roll that needs no confirmation
	-- is cancelled for you (CANCEL_LOOT_ROLL, so Blizzard takes the bar away and
	-- the next waiting roll may take its frame), one that needs it (bind on
	-- pickup, `confirm`: Need, Greed, Transmog and Disenchant ask, Pass binds
	-- nothing and never does) asks (CONFIRM_LOOT_ROLL: the bar stays up, and
	-- nothing more happens until you accept). A main spec Need (`needAnim`)
	-- starts its dice animation (MAIN_SPEC_NEED_ROLL: the timer zeroed, the bar
	-- up). That event almost certainly comes later, from the server (the
	-- animation could not play if the roll were cancelled inside the call), so
	-- `needAnim = 'later'` is the realistic case (nothing inside the call, the
	-- test sends the event); `true` has it inside the call and `'instant'`
	-- inside it and cancelled at once, to show the code handles that order too.
	-- A roll the game doesn't know, or a type it doesn't have, does nothing.
	function RollOnLoot(rollID, rollType)
		game.rolled[rollID] = rollType
		local roll = game.rolls[rollID]
		if not roll or type(rollType) ~= 'number' or rollType < 0 or rollType > 4 then return end
		if roll.confirm and rollType ~= 0 then
			stub.fire_event('CONFIRM_LOOT_ROLL', rollID, rollType)
		elseif rollType == 1 and roll.needAnim == 'later' then
			return
		elseif rollType == 1 and roll.needAnim then
			stub.fire_event('MAIN_SPEC_NEED_ROLL', rollID, 77, true)
			if roll.needAnim == 'instant' then stub.fire_event('CANCEL_LOOT_ROLL', rollID) end
		else
			stub.fire_event('CANCEL_LOOT_ROLL', rollID)
		end
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
local buttonArt -- [Blizzard roll button] = the texture its art is drawn with

local function blizzard()
	buttonArt = {}
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
		local buttons = BC(self)
		buttons.TransmogButton:SetShown(canTransmog)
		buttons.GreedButton:SetShown(not canTransmog)
		self:RegisterEvent('CANCEL_LOOT_ROLL')
		self:RegisterEvent('CANCEL_ALL_LOOT_ROLLS')
		self:RegisterEvent('MAIN_SPEC_NEED_ROLL')
	end
	function GroupLootFrame_StopNeedAnimation(self)
		for _, button in ipairs(BC(self).LootButtons) do button:Show() end
		self.NeedRollAnim:Hide()
	end
	function GroupLootFrame_StartNeedAnimation(self)
		self.Timer:SetValue(0)
		for _, button in ipairs(BC(self).LootButtons) do button:Hide() end
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

	-- MKBGroupLootFrameTemplate: parent UIParent, frameStrata DIALOG.
	for i = 1, 4 do
		local name = 'GroupLootFrame' .. i
		local frame = CreateFrame('Frame', name, UIParent)
		frame:SetFrameStrata('DIALOG')
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
		local buttons = frame -- retail: the buttons are the frame's own
		if SHAPE == 'forever' then
			buttons = CreateFrame('Frame', nil, frame)
			frame.LootButtonContainer = buttons
		end
		buttons.LootButtons = {}
		for _, def in ipairs(BUTTONS) do
			local button = CreateFrame('Button', nil, buttons)
			button:SetID(def[2])
			-- Its <NormalTexture atlas="lootroll-toast-icon-<choice>-up"/>; the
			-- stubs have no normal texture slot, so it's a texture of the
			-- button's, kept in buttonArt.
			local art = button:CreateTexture(nil, 'ARTWORK')
			art:SetAllPoints()
			art:SetAtlas('lootroll-toast-icon-' .. def[1]:lower() .. '-up')
			buttonArt[button] = art
			button:SetScript('OnClick', function(self)
				local owner = SHAPE == 'forever' and self:GetParent():GetParent() or self:GetParent()
				RollOnLoot(owner.rollID, self:GetID())
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
	load_editmode()
	load_string_format()
	st = SaftUI
	CreateFrame('GameTooltip', 'GameTooltip', UIParent)
	game_api()
	blizzard()
	load_saftui('SaftUI-Loot/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Loot/init.lua')
	LT = st:GetModule('Loot')
	st:BindModuleConfig(LT, 'loot')
	load_saftui('SaftUI-Loot/rollbar.lua')
	load_saftui('SaftUI-Loot/roll.lua')
	load_saftui('SaftUI-Loot/rolltest.lua')
	load_saftui('SaftUI-Loot/rollinfo.lua')
	load_saftui('SaftUI-Loot/Feed/loothistory.lua')
	load_saftui('SaftUI-Loot/Feed/rolls.lua')
	S = LT.ROLL_STATE
	LT:InitializeRollFrame()
	stub.time = 0
	-- Strong and Danger at values that are not their defaults, so a timer drawn in a white or red of its own fails.
	st.config.profile.colors.text.strong:SetRGB(0.4, 0.8, 0.2)
	st.config.profile.colors.text.danger:SetRGB(0.9, 0.2, 0.3)
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
-- `opts`: confirm (a bind on pickup roll), needAnim (a main spec Need's dice
-- animation; 'instant' cancels at once too).
local function start_roll(key, opts)
	nextRollID = nextRollID + 1
	local item = ITEMS[key]
	game.rolls[nextRollID] = {
		name = item.name, quality = item.quality, texture = item.texture, link = item.link,
		transmog = item.transmog, length = ROLL_LENGTH, start = stub.time,
		confirm = opts and opts.confirm, needAnim = opts and opts.needAnim,
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

-- A click on a button: its PreClick, OnClick (RollOnLoot) and PostClick.
-- The game delivers no click to a hidden or disabled button (as stub.click
-- refuses), so then none of the three scripts runs. Returns whether it clicked.
local function click(button)
	if not button:IsVisible() or not button:IsEnabled() then return false end
	stub.fire_script(button, 'PreClick', 'LeftButton', false)
	stub.fire_script(button, 'OnClick', 'LeftButton', false)
	stub.fire_script(button, 'PostClick', 'LeftButton', false)
	return true
end

local function click_of(rollID, choice)
	return click(BC(frame_of(rollID))[choice .. 'Button'])
end

-- You click a roll button on Blizzard's bar: RollOnLoot, inside which the game
-- cancels the roll for you (a plain click: CANCEL_LOOT_ROLL, so Blizzard takes
-- the bar away before RollOnLoot returns), and the loot history gets your
-- choice (after which Feed/rolls.lua updates the roll bars).
local function choose(rollID, choice, drop)
	click_of(rollID, choice)
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

-- Whether a SaftUI bar's button shows a border: a backdrop drawn on its art
-- that's shown and has a backdrop (None clears it).
local function has_border(button)
	local backdrop = button.Icon.backdrop
	return backdrop ~= nil and backdrop:IsVisible() and backdrop.backdropInfo ~= nil
end

-- The atlas a Blizzard roll frame's button for a choice draws.
local function live_atlas(frame, choice)
	return buttonArt[BC(frame)[choice .. 'Button']]:GetAtlas()
end

-- Whether any of the tooltip's left texts has needle in it.
local function tooltip_has(needle)
	for _, text in pairs(stub.state(GameTooltip).texts or {}) do
		if type(text) == 'string' and text:find(needle, 1, true) then return true end
	end
	return false
end

local function blue()
	return T.text(st.config.profile.theme.accent:GetRGB())
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
	eq(T.rgb(bar.Timer.Text:GetVertexColor()), T.rgb(0.4, 0.8, 0.2), 'in Text > Strong over a minute')
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

test("your choice is lit and the others dimmed, a label names it, and its buttons are its Blizzard bar's", function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local roll = start_roll('amulet')
	local frame = frame_of(roll)
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end

	for _, choice in ipairs({ 'Need', 'Pass', 'Greed' }) do
		eq(button_of(bar, choice).Icon:GetAtlas(), live_atlas(frame, choice), choice .. ": the art its Blizzard bar showed")
	end
	local lit = button_of(bar, 'Greed')
	eq(lit:GetAlpha(), 1, 'your choice stays bright')
	check(has_border(lit), 'with a border')
	eq(T.edge_rgb(lit.Icon.backdrop), blue(), 'in the accent')
	for _, choice in ipairs({ 'Need', 'Pass' }) do
		local button = button_of(bar, choice)
		eq(T.text(button:GetAlpha()), '0.35', choice .. ' is dimmed')
		check(not has_border(button), choice .. ' has no border, as on its Blizzard bar')
	end
	check(not button_of(bar, 'Transmog'):IsShown(), 'Greed shows, not Transmog, as on its Blizzard bar')
	check(bar.Choice:IsShown(), 'a label shows')
	eq(bar.Choice:GetText(), 'Greed', 'naming your choice')

	eq(drawn(bar.InfoFrame), 'theme,solid,bar', "the body: the Rolls Theme and Background, as a bar")
	eq(drawn(bar.IconFrame), 'theme,solid,slot', 'the icon, as a slot')
	eq(drawn(lit.Icon), 'theme,solid,small', 'the lit button, as a small frame')
	eq(T.around(lit.Icon.backdrop, lit), '0,0,0,0', "its border lies on the button's edges, the art inside it")
	eq(bar:GetFrameStrata(), frame:GetFrameStrata(), "at the strata Blizzard's bar had")

	st:RecolorThemed()
	eq(T.edge_rgb(lit.Icon.backdrop), blue(), 'the lit border stays through a theme recolor')
	check(not has_border(button_of(bar, 'Need')), 'and the others stay without one')
	st:RedrawThemed()
	eq(T.edge_rgb(lit.Icon.backdrop), blue(), 'and through a redraw')
	check(not has_border(button_of(bar, 'Need')), 'the others still without one')

	-- A bar reused for another choice moves the border to it.
	local sword = add_drop('sword', {})
	tick(130)
	tick(4)
	eq(#LT:GetHeldRolls(), 0, 'the held roll ran out, lingered and went')
	local roll2 = start_roll('sword')
	choose(roll2, 'Pass', sword)
	local again = held_bar(roll2)
	check(again == bar, 'the bar is reused')
	if again ~= bar then return end
	check(has_border(button_of(bar, 'Pass')), 'Pass now has the border')
	check(not has_border(button_of(bar, 'Greed')), 'Greed no longer does')
	eq(button_of(bar, 'Greed'):GetAlpha() < 1, true, 'and is dimmed')
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

test('a main spec Need whose animation starts inside the call is held after it, with its drop and its time', function()
	world()
	local drop = add_drop('amulet', { { 'Brightblade', 'PALADIN', 'NeedMainSpec', 41 } })
	local roll = start_roll('amulet', { needAnim = true })
	LT:UpdateRollBars()
	tick(20)

	-- If the client starts the dice animation inside RollOnLoot (probably it does
	-- not: the event comes later, from the server; the code handles both), Blizzard's
	-- bar stays up for 5 seconds, its timer zeroed (before RollOnLoot returns) and
	local frame = frame_of(roll)
	click_of(roll, 'Need')
	eq(frame.Timer:GetValue(), 0, 'the timer was zeroed inside the call')
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

test('a main spec Need whose animation starts after the call (the server answers later) is held after it, with its drop and its time', function()
	world()
	local drop = add_drop('amulet', { { 'Brightblade', 'PALADIN', 'NeedMainSpec', 41 } })
	local roll = start_roll('amulet', { needAnim = 'later' })
	LT:UpdateRollBars()
	tick(20)

	-- The server answers a main spec Need a moment after the call, with the dice
	-- animation: Blizzard's bar stays up for 5 seconds, its timer zeroed and its
	-- buttons hidden.
	local frame = frame_of(roll)
	click_of(roll, 'Need')
	check(frame:IsShown() and frame.Timer:GetValue() > 0, 'nothing happened inside the call')
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

-- Time passes with the held bars' per-frame update called each `step`.
local function tick_by(seconds, step)
	for _ = 1, math.floor(seconds / step + 0.5) do tick(step) end
end

test('a held roll whose drop resolves stays up locked for 3 seconds, fades, then goes and closes the stack', function()
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
	check(bar:IsShown() and held_bar(a) == bar, 'a winner: the held bar stays')
	eq(bar:GetAlpha(), 1, 'at full alpha')
	eq(bar.Choice:GetText(), 'Greed', 'locked on your choice')
	eq(bar:GetBottom(), bottomA, 'in its place')
	eq(frame_of(b):GetBottom() > bottomA, true, 'the roll after it has not moved down yet')

	tick_by(2.9, 0.1)
	check(bar:IsShown() and bar:GetAlpha() == 1, 'still up and bright just short of 3 seconds')
	tick(0.35)
	check(bar:IsShown(), 'fading')
	eq(T.text(bar:GetAlpha()), '0.50', 'a quarter-second into the fade: half alpha')
	tick(0.1)
	eq(bar:GetAlpha() < 0.5 and bar:GetAlpha() > 0, true, 'alpha keeps falling')
	check(held_bar(a) == bar, 'held until the fade is over')
	tick(0.2)
	check(not bar:IsShown(), 'faded: it goes')
	eq(#LT:GetHeldRolls(), 0, 'no roll is held')
	eq(frame_of(b):GetBottom(), bottomA, 'and the roll after it moves into its place')

	choose(b, 'Pass', cloth)
	check(held_bar(b) ~= nil, 'the next roll is held')
	cloth.allPassed = true
	LT:UpdateRollBars()
	check(held_bar(b) ~= nil, 'everyone passed: it lingers too')
	tick(3.6)
	eq(held_bar(b), nil, 'then goes')
end)

test('a held roll whose time runs out stays up locked, empty, for 3 seconds, fades, then goes', function()
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
	eq(T.rgb(bar.Timer.Text:GetVertexColor()), T.rgb(0.9, 0.2, 0.3), 'in Text > Danger under a minute')
	tick(2)
	check(bar:IsShown() and held_bar(roll) == bar, 'its time ran out: it stays')
	eq(bar.Timer.Text:GetText(), '00:00', 'its timer empty')
	eq(bar.Timer:GetValue(), 0, 'and stopped')
	eq(bar.Choice:GetText(), 'Greed', 'still locked on your choice')
	eq(bar:GetAlpha(), 1, 'at full alpha')
	tick(2.5)
	eq(bar:GetAlpha(), 1, 'for 3 seconds in all')
	tick(0.75)
	eq(T.text(bar:GetAlpha()), '0.50', 'then fading')
	tick(0.5)
	check(not bar:IsShown(), 'then gone')
	eq(#LT:GetHeldRolls(), 0, 'no roll is held')
end)

test('a roll that resolved before the bar was held (the last to choose) shows your choice for 3 seconds, then fades', function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' }, { 'Quickshot', 'HUNTER', 'Pass' } })
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(10)
	-- Your click is the last choice: the roll resolves with it.
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	history_choice(drop, 'Greed')
	choose(roll, 'Greed')
	local bar = held_bar(roll)
	check(bar ~= nil and bar:IsShown(), 'held and showing')
	if not bar then return end
	eq(bar.Choice:GetText(), 'Greed', 'locked on your choice')
	eq(count(bar, 'Greed'), '2', "with the final counts: Mistweave's and yours")
	eq(count(bar, 'Pass'), '1', "and Quickshot's pass")
	tick(2.9)
	eq(bar:GetAlpha(), 1, 'full alpha for 3 seconds')
	tick(0.35)
	eq(T.text(bar:GetAlpha()), '0.50', 'then fading')
	tick(0.3)
	eq(held_bar(roll), nil, 'then gone')
end)

test('a finished bar takes and keeps no drop, and a new roll of the same item matches normally', function()
	world()
	local first = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local a = start_roll('amulet')
	LT:UpdateRollBars()
	choose(a, 'Greed', first)
	local old = held_bar(a)
	first.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	eq(old.dropID, nil, 'the finished bar keeps no drop')

	-- Another of the item drops, and you choose on it while the old bar lingers.
	local second = add_drop('amulet', { { 'Quickshot', 'HUNTER', 'Greed' }, { 'Stonefist', 'SHAMAN', 'Greed' } })
	local b = start_roll('amulet')
	LT:UpdateRollBars()
	choose(b, 'Greed', second)
	local new = held_bar(b)
	check(new ~= nil and new ~= old, 'the new roll is held on a bar of its own')
	if not new then return end
	eq(new.dropID, '7:2', 'it took the second drop')
	eq(count(new, 'Greed'), '3', 'with its counts')
	eq(count(old, 'Greed'), '2', 'the finished bar keeps its own')
	eq(old.dropID, nil, 'still no drop')

	-- A finished bar takes none of a drop that is still open either.
	local third = add_drop('amulet', { { 'Brightblade', 'PALADIN', 'Greed' } })
	history_choice(third, 'Greed')
	LT:UpdateRollBars()
	eq(old.dropID, nil, 'a drop you chose on is not taken by the finished bar')
	eq(count(old, 'Greed'), '2', 'its counts do not change')
	local c = start_roll('amulet')
	choose(c, 'Greed', third)
	eq(held_bar(c).dropID, '7:3', 'a third roll takes it')
end)

test("a finished bar's counts are its drop's last, and its tooltip still works", function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local roll = start_roll('amulet')
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end
	eq(count(bar, 'Pass'), nil, 'nobody has passed')

	-- The final picks arrive with the result.
	table.insert(drop.rollInfos, { playerName = 'Stonefist', playerClass = 'SHAMAN', state = S.Pass })
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	eq(count(bar, 'Pass'), '1', "the pass that came with the result is counted")
	eq(count(bar, 'Greed'), '2', 'and the Greeds')
	eq(bar.rolls ~= nil and #bar.rolls.list, 3, "its summary is the drop's last")

	stub.fire_script(bar.InfoFrame, 'OnEnter')
	check(GameTooltip:IsOwned(bar.InfoFrame), 'hovering it shows its tooltip')
	check(tooltip_has('Stonefist') and tooltip_has('Mistweave'), 'with the final picks')

	-- If the drop can no longer be read, the bar keeps what it had.
	local drop2 = add_drop('sword', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local roll2 = start_roll('sword')
	choose(roll2, 'Greed', drop2)
	local bar2 = held_bar(roll2)
	C_LootHistory.GetSortedInfoForDrop = function() return nil end
	drop2.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	check(held_bar(roll2) == bar2 and bar2.finishedAt ~= nil, 'finished all the same')
	eq(count(bar2, 'Greed'), '2', 'with the counts it had')
end)

test('CANCEL_ALL_LOOT_ROLLS takes a finished bar at once', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	check(bar:IsShown() and held_bar(roll) == bar, 'finished and lingering')
	stub.fire_event('CANCEL_ALL_LOOT_ROLLS')
	check(not bar:IsShown(), 'gone at once')
	eq(#LT:GetHeldRolls(), 0, 'no roll held')
end)

test('a bar reused from the pool has full alpha, no finished state, and counts down', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	tick(3.3)
	check(bar:GetAlpha() < 1, 'faded part way')
	tick(0.5)
	check(not bar:IsShown(), 'gone')

	local sword = add_drop('sword', {})
	local roll2 = start_roll('sword')
	choose(roll2, 'Pass', sword)
	local again = held_bar(roll2)
	check(again == bar, 'the bar is reused')
	if again ~= bar then return end
	eq(bar:GetAlpha(), 1, 'at full alpha')
	eq(bar.finishedAt, nil, 'not finished')
	tick(10)
	eq(bar.Timer.Text:GetText(), '01:50', 'its timer counts down')
	eq(bar.Choice:GetText(), 'Pass', 'locked on its new choice')
	tick(10)
	eq(bar:GetAlpha(), 1, 'and stays bright')
end)

-- The lines st:Debug prints while `fn` runs, each as one string.
local function printed_by(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		table.insert(lines, table.concat(parts, ' '))
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

local function any_line(lines, needle)
	for _, line in ipairs(lines) do
		if line:find(needle, 1, true) then return true end
	end
	return false
end

test('with debug off a held roll prints nothing, with it on its decisions print', function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(10)

	st.DEBUG = false
	local quiet = printed_by(function()
		choose(roll, 'Greed', drop)
		drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
		LT:UpdateRollBars()
		tick(5)
	end)
	eq(#quiet, 0, 'debug off: nothing printed')

	st.DEBUG = true
	local late = start_roll('sword')
	local c = start_roll('cloth')
	local asked = start_roll('amulet', { confirm = true })
	LT:UpdateRollBars()
	local lines = printed_by(function()
		-- No drop in the loot history yet: the held roll takes it when it comes.
		choose(late, 'Greed')
		local sword = add_drop('sword', {})
		history_choice(sword, 'Greed')
		LT:UpdateRollBars()
		-- A click that asks to confirm: the bar stays up, and the choice is noted.
		click_of(asked, 'Need')
		-- A roll on no shown bar, and a type with no choice.
		RollOnLoot(9999, 1)
		RollOnLoot(c, 7)
	end)
	st.DEBUG = false
	local at = {}
	for i, line in ipairs(lines) do
		for _, key in ipairs({ 'choice pending: ' .. late .. ' Greed seconds left', 'bar hid: ' .. late, 'held roll ' .. late .. ' choice Greed' }) do
			if line:find(key, 1, true) and not at[key] then at[key] = i end
		end
	end
	local pend, hid, hold = at['choice pending: ' .. late .. ' Greed seconds left'], at['bar hid: ' .. late], at['held roll ' .. late .. ' choice Greed']
	check(pend and hid and hold and pend < hid and hid < hold,
		'a plain click: pending at PreClick, then the bar hiding, then the held roll: ' .. table.concat(lines, ' | '))
	check(any_line(lines, 'bar hid: ' .. late .. ' choice noted false pending true frame hidden true'), 'the bar hiding: the choice pending, not yet noted')
	check(any_line(lines, 'choice held at the bar hiding: ' .. late .. ' Greed'), 'and the post-hook says it was held at the hide')
	check(any_line(lines, 'choice pending: ' .. asked .. ' Need seconds left'), 'a confirmation click is pending too')
	check(any_line(lines, 'choice noted: ' .. asked .. ' Need'), 'and its choice noted once the bar stays up: ' .. table.concat(lines, ' | '))
	check(any_line(lines, 'held roll ' .. late .. ' choice Greed seconds left'), 'the held roll')
	check(any_line(lines, 'took drop 7:2'), 'a held roll claiming its drop: ' .. table.concat(lines, ' | '))
	check(any_line(lines, 'choice not noted: 9999 no shown bar with that roll'), 'a choice on no shown bar says so')
	check(any_line(lines, 'choice not noted: ' .. c .. ' 7') or any_line(lines, 'no plain roll ID or roll type'), 'a roll type with no choice says so')
end)

test('the held roll debug prints each early return, finishing and release, once', function()
	world()
	st.DEBUG = true
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	tick(119.5)
	local lines = printed_by(function()
		choose(roll, 'Greed', drop)
	end)
	check(any_line(lines, 'hold ' .. roll .. ' skipped: under a second left'), 'under a second left: ' .. table.concat(lines, ' | '))

	local frame = frame_of(start_roll('sword'))
	local sword = frame.rollID
	lines = printed_by(function()
		-- A held roll the frame did not show.
		LT:HoldRoll(frame, { rollID = sword + 50, choice = 'Greed', ends = stub.time + 50, length = 60 })
	end)
	check(any_line(lines, 'skipped: the frame did not show that roll'), 'a roll the frame did not show')

	local drop2 = add_drop('cloth', {})
	local r2 = start_roll('cloth')
	tick(5)
	lines = printed_by(function()
		choose(r2, 'Pass', drop2)
		drop2.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
		LT:UpdateRollBars()
		tick(1)
		tick(1)
		tick(2)
		tick(1)
	end)
	st.DEBUG = false
	local finished, released = 0, 0
	for _, line in ipairs(lines) do
		if line:find('held roll finished: ' .. r2 .. ' drop resolved', 1, true) then finished = finished + 1 end
		if line:find('held roll released: ' .. r2, 1, true) then released = released + 1 end
	end
	eq(finished, 1, 'finishing prints once, with the reason: ' .. table.concat(lines, ' | '))
	eq(released, 1, 'and so does its release')

	st.DEBUG = true
	local late = start_roll('ring')
	choose(late, 'Transmog')
	lines = printed_by(function() tick(125) end)
	check(any_line(lines, 'held roll finished: ' .. late .. ' time'), 'a held roll that times out says why')
	eq(#lines, 1, 'the frame it finishes prints that and nothing else: ' .. table.concat(lines, ' | '))
	lines = printed_by(function() tick_by(2.9, 0.1) end)
	eq(#lines, 0, 'the frames of its linger print nothing: ' .. table.concat(lines, ' | '))
	lines = printed_by(function() tick_by(0.4, 0.1) end)
	eq(#lines, 0, 'nor do those of its fade: ' .. table.concat(lines, ' | '))
	lines = printed_by(function() tick(0.3) end)
	st.DEBUG = false
	eq(#lines, 1, 'the frame it goes prints its release: ' .. table.concat(lines, ' | '))
	check(any_line(lines, 'held roll released: ' .. late), 'naming the roll')
end)

test('debug prints only at a state change: not per frame in the countdown, the linger or the fade, nor on every update', function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(0.123)
	st.DEBUG = true
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end

	local lines = printed_by(function()
		tick_by(5, 0.1)
		for _ = 1, 3 do LT:UpdateRollBars() end
		tick_by(5, 0.1)
	end)
	eq(#lines, 0, 'the countdown and updates that change nothing print nothing: ' .. table.concat(lines, ' | '))

	-- A held roll with no drop yet claims one once, then keeps it quietly.
	local late = start_roll('sword')
	LT:UpdateRollBars()
	choose(late, 'Greed')
	lines = printed_by(function()
		history_choice(add_drop('sword', {}), 'Greed')
		for _ = 1, 4 do LT:UpdateRollBars() end
	end)
	local took = 0
	for _, line in ipairs(lines) do
		if line:find('took drop', 1, true) then took = took + 1 end
	end
	eq(took, 1, 'a claim prints once, not on every update: ' .. table.concat(lines, ' | '))

	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	lines = printed_by(function()
		LT:UpdateRollBars()
		LT:UpdateRollBars()
		tick_by(2.9, 0.1)
		LT:UpdateRollBars()
		tick_by(0.4, 0.1)
	end)
	eq(#lines, 1, 'the finish, then nothing in the linger or the fade: ' .. table.concat(lines, ' | '))
	check(any_line(lines, 'held roll finished: ' .. roll .. ' drop resolved'), 'it is the finish')
	st.DEBUG = false
end)

test('the debug lines give seconds to one decimal, and the finish says what the result was', function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' }, { 'Stonefist', 'SHAMAN', 'NoRoll' } })
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(0.123)
	st.DEBUG = true
	local lines = printed_by(function() choose(roll, 'Greed', drop) end)
	check(any_line(lines, 'choice pending: ' .. roll .. ' Greed seconds left 119.9'), 'pending: ' .. table.concat(lines, ' | '))
	check(any_line(lines, 'choice Greed seconds left 119.9'), 'held: ' .. table.concat(lines, ' | '))
	for _, line in ipairs(lines) do
		check(not line:find('%.%d%d'), 'no long decimals: ' .. line)
	end

	-- Resolved with a winner while one player has not chosen.
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	lines = printed_by(function() LT:UpdateRollBars() end)
	check(any_line(lines, 'held roll finished: ' .. roll .. ' drop resolved waiting 1 winner'), 'a winner: ' .. table.concat(lines, ' | '))

	-- Everyone passed.
	local passed = add_drop('cloth', { { 'Mistweave', 'PRIEST', 'Pass' } })
	local r2 = start_roll('cloth')
	choose(r2, 'Pass', passed)
	passed.allPassed = true
	lines = printed_by(function() LT:UpdateRollBars() end)
	check(any_line(lines, 'held roll finished: ' .. r2 .. ' drop resolved waiting 0 all passed'), 'all passed: ' .. table.concat(lines, ' | '))

	-- Its time ran out with no result yet.
	local open = add_drop('sword', { { 'Stonefist', 'SHAMAN', 'NoRoll' } })
	local r3 = start_roll('sword')
	choose(r3, 'Greed', open)
	lines = printed_by(function() tick(121) end)
	st.DEBUG = false
	check(any_line(lines, 'held roll finished: ' .. r3 .. ' time waiting 1 no winner'), 'timed out: ' .. table.concat(lines, ' | '))
end)

test('a time-out shows the result when it arrives inside the linger, for its own drop only', function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' }, { 'Stonefist', 'SHAMAN', 'NoRoll' } })
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(30)
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end
	tick(91)
	check(bar.finishedAt ~= nil, 'its time ran out')
	eq(bar.dropID, nil, 'it claims no drop')
	eq(count(bar, 'Pass'), nil, 'and shows no pass yet')
	local finishedAt = bar.finishedAt
	tick(0.5)

	-- Another drop of the item changes nothing on it.
	local other = add_drop('amulet', { { 'Quickshot', 'HUNTER', 'Greed' }, { 'Brightblade', 'PALADIN', 'Greed' } })
	LT:UpdateRollBars()
	eq(count(bar, 'Greed'), '2', "another drop's choices are not its counts")
	eq(bar.dropID, nil, 'and it still claims nothing')

	-- The server's result for its own drop: the AFK player auto-passes, a winner.
	drop.rollInfos[2].state = S.Pass
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	eq(count(bar, 'Greed'), '2', 'the Greeds')
	eq(count(bar, 'Pass'), '1', 'the auto-pass shows')
	eq(bar.rolls ~= nil and bar.rolls.winner, 1, 'its summary has the winner')
	eq(bar.dropID, nil, 'it still claims no drop')
	eq(bar.finishedAt, finishedAt, "and the linger's clock is untouched")
	eq(bar.Timer.Text:GetText(), '00:00', 'its timer stays empty')
	eq(bar:GetAlpha(), 1, 'at full alpha')

	-- A new roll of the item matches normally while the old bar lingers.
	local r2 = start_roll('amulet')
	LT:UpdateRollBars()
	choose(r2, 'Greed', other)
	local new = held_bar(r2)
	check(new ~= nil and new ~= bar, 'a bar of its own')
	if not new then return end
	eq(new.dropID, '7:2', 'it took the other drop')
	eq(count(new, 'Greed'), '3', 'with its counts')
	eq(count(bar, 'Pass'), '1', "the old bar's own")
	tick(3.6)
	eq(held_bar(roll), nil, 'the old bar goes on its own clock')
	check(held_bar(r2) ~= nil, 'the new one stays')
end)

test("a finished bar's timer stays where it was, through frames and a config change", function()
	world()
	local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } })
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(30)
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end
	eq(bar.Timer.Text:GetText(), '01:30', 'counting down')
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	tick_by(2.5, 0.1)
	eq(bar.Timer.Text:GetText(), '01:30', 'stopped once finished')
	eq(bar.Timer:GetValue(), 90, 'at the same value')
	LT:UpdateGroupLootConfig()
	eq(bar.Timer.Text:GetText(), '01:30', 'a config change does not set it going again')
	eq(bar.Timer:GetValue(), 90, 'nor move it')
end)

test('the per-frame update stops when the last held bar, finished or not, is released', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end
	local parent = bar:GetParent()
	check(parent:GetScript('OnUpdate') ~= nil, 'running while a roll is held')
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	LT:UpdateRollBars()
	check(parent:GetScript('OnUpdate') ~= nil, 'and while it lingers')
	tick(3.6)
	eq(held_bar(roll), nil, 'released')
	eq(parent:GetScript('OnUpdate'), nil, 'nothing runs every frame any more')
end)

test('the last to choose gets the final counts whichever comes first, the history update or the bar hiding', function()
	local function room()
		world()
		local drop = add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' }, { 'Quickshot', 'HUNTER', 'Pass' } })
		local roll = start_roll('amulet')
		LT:UpdateRollBars()
		tick(10)
		return drop, roll
	end

	-- The bar hides first; the history update (your pick, the result) follows.
	local drop, roll = room()
	choose(roll, 'Greed')
	local bar = held_bar(roll)
	check(bar ~= nil and bar.finishedAt == nil, 'A: held, not finished yet')
	if not bar then return end
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	history_choice(drop, 'Greed')
	LT:UpdateRollBars()
	check(bar.finishedAt ~= nil, 'A: the update finishes it')
	eq(count(bar, 'Greed'), '2', "A: Mistweave's and yours")
	eq(count(bar, 'Pass'), '1', "A: and Quickshot's pass")

	-- The history update comes first, with Blizzard's bar still up.
	drop, roll = room()
	drop.winner = { playerName = 'Mistweave', playerClass = 'PRIEST' }
	history_choice(drop, 'Greed')
	LT:UpdateRollBars()
	check(frame_of(roll) ~= nil, 'B: Blizzard bar still up')
	choose(roll, 'Greed')
	bar = held_bar(roll)
	check(bar ~= nil and bar.finishedAt ~= nil, 'B: held and finished at once')
	if not bar then return end
	eq(count(bar, 'Greed'), '2', "B: Mistweave's and yours")
	eq(count(bar, 'Pass'), '1', "B: and Quickshot's pass")
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

	-- The middle roll is held where it was. A new roll takes Blizzard's free
	-- frame and its slot, and goes last: nothing on screen moves.
	choose(b, 'Greed')
	eq(held_bar(b):GetBottom(), base + step, 'held in the middle')
	eq(frame_of(c):GetBottom(), base + 2 * step, 'the roll after it stays')
	local d = start_roll('ring')
	eq(frame_of(d):GetBottom(), base + 3 * step, 'the new roll, in the held roll\'s old slot, goes last')
	eq(frame_of(c):GetBottom(), base + 2 * step, 'and the one after the held roll stays put')

	-- Held all the way: a new roll goes after every held bar.
	choose(a, 'Pass', sword)
	choose(c, 'Greed')
	choose(d, 'Need')
	eq(held_bar(a):GetBottom(), base, 'each held bar stays where its roll was')
	eq(held_bar(b):GetBottom(), base + step, 'each held bar stays where its roll was')
	eq(held_bar(c):GetBottom(), base + 2 * step, 'each held bar stays where its roll was')
	eq(held_bar(d):GetBottom(), base + 3 * step, 'each held bar stays where its roll was')
	local e = start_roll('sword')
	eq(frame_of(e):GetBottom(), base + 4 * step, 'a new roll stacks after them')

	-- One goes: the stack closes up.
	sword.winner = { playerName = 'Brightblade', playerClass = 'PALADIN' }
	LT:UpdateRollBars()
	check(held_bar(a) ~= nil, 'the first roll ended, and lingers')
	eq(held_bar(b):GetBottom(), base + step, 'with the rest where they were')
	tick(3.6)
	eq(held_bar(a), nil, 'then it goes')
	eq(held_bar(b):GetBottom(), base, 'the rest move down into the gap')
	eq(frame_of(e):GetBottom(), base + 3 * step, 'the live roll too')
end)

test('a queued roll opens at the end of the stack, and nothing on screen moves', function()
	world()
	local config = LT.config.roll
	local step = config.height + config.spacing
	local rolls = {}
	for i, key in ipairs({ 'sword', 'amulet', 'cloth', 'ring', 'amulet' }) do rolls[i] = start_roll(key) end
	eq(frame_of(rolls[5]), nil, "the fifth roll waits: Blizzard has four frames")
	local base = frame_of(rolls[1]):GetBottom()

	-- Choosing frees a frame, and Blizzard opens the waiting roll in it, in the
	-- same slot.
	choose(rolls[2], 'Greed')
	check(frame_of(rolls[5]) ~= nil, 'the waiting roll opens')
	eq(frame_of(rolls[1]):GetBottom(), base, 'the first roll stays')
	eq(held_bar(rolls[2]):GetBottom(), base + step, 'the held roll stays')
	eq(frame_of(rolls[3]):GetBottom(), base + 2 * step, 'the third stays')
	eq(frame_of(rolls[4]):GetBottom(), base + 3 * step, 'the fourth stays')
	eq(frame_of(rolls[5]):GetBottom(), base + 4 * step, 'the queued roll goes last')

	choose(rolls[4], 'Pass')
	eq(held_bar(rolls[4]):GetBottom(), base + 3 * step, 'a second held roll stays where it was')
	eq(frame_of(rolls[5]):GetBottom(), base + 4 * step, 'and so does the roll after it')
end)

test('grow down stacks held and new rolls the same way, downwards', function()
	world()
	LT.config.roll.grow_down = true
	LT:UpdateGroupLootConfig()
	local config = LT.config.roll
	local step = config.height + config.spacing
	local a = start_roll('sword')
	local b = start_roll('amulet')
	local c = start_roll('cloth')
	local top = frame_of(a):GetTop()
	eq(frame_of(b):GetTop(), top - step, 'the rolls stack down from the anchor')
	eq(frame_of(c):GetTop(), top - 2 * step, 'one under the other')

	choose(b, 'Greed')
	eq(held_bar(b):GetTop(), top - step, 'held where it was')
	eq(frame_of(c):GetTop(), top - 2 * step, 'the roll under it stays')
	local d = start_roll('ring')
	eq(frame_of(d):GetTop(), top - 3 * step, 'a new roll goes last, at the bottom')
	choose(a, 'Pass')
	eq(held_bar(a):GetTop(), top, 'the first held roll stays at the top')
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
				check(not has_border(button), 'and no border on any, like a live bar')
			end
		end
		for _, button in ipairs(bar.buttons) do
			eq(button.Icon:GetAtlas(), live_atlas(GroupLootFrame1, button.choice), button.choice .. ": Blizzard's roll button art")
		end
		eq(bar:GetFrameStrata(), GroupLootFrame1:GetFrameStrata(), "at the strata of Blizzard's roll bars")
	end
	eq(#lockedBars, 1, 'one preview is locked')
	local bar = lockedBars[1]
	if not bar then return end
	local choice = bar.Choice:GetText()
	local lit = button_of(bar, choice)
	check(lit ~= nil and lit:IsShown(), 'its label names a button it shows')
	eq(lit:GetAlpha(), 1, 'that one bright')
	check(has_border(lit), 'and lit')
	eq(T.edge_rgb(lit.Icon.backdrop), blue(), 'in the accent')
	for _, button in ipairs(bar.buttons) do
		if button ~= lit and button:IsShown() then
			eq(T.text(button:GetAlpha()), '0.35', 'the others dimmed')
			check(not has_border(button), 'with no border')
		end
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

-- Two rolls held, and a click on a third still waiting on the server (a bind
-- on pickup confirmation still open, say).
local function held_and_pending()
	local a = start_roll('amulet')
	local b = start_roll('sword')
	local c = start_roll('cloth', { confirm = true })
	tick(10)
	choose(a, 'Greed')
	choose(b, 'Need')
	click_of(c, 'Greed')
	eq(#LT:GetHeldRolls(), 2, 'two rolls held')
	check(frame_of(c) ~= nil, 'the third still up')
	return c
end

test('CANCEL_ALL_LOOT_ROLLS ends every held roll and holds none, whichever hears it first', function()
	-- SaftUI first: it registered at login, before Blizzard's frames registered
	-- for their rolls.
	world()
	held_and_pending()
	stub.fire_event('CANCEL_ALL_LOOT_ROLLS')
	eq(#LT:GetHeldRolls(), 0, 'SaftUI first: no roll held')
	for i = 1, 4 do check(not _G['GroupLootFrame' .. i]:IsShown(), "Blizzard's bars are gone") end

	-- Blizzard's frames first: each takes itself away (holding the clicked one
	-- for a moment), then SaftUI hears it.
	world()
	held_and_pending()
	for i = 1, 4 do
		local frame = _G['GroupLootFrame' .. i]
		if frame:IsShown() then GroupLootFrame_OnEvent(frame, 'CANCEL_ALL_LOOT_ROLLS') end
	end
	stub.fire_event('CANCEL_ALL_LOOT_ROLLS')
	eq(#LT:GetHeldRolls(), 0, "Blizzard's frames first: no roll held")
end)

test('a roll with under a second left is not held', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	tick(119.5)
	choose(roll, 'Greed', drop)
	eq(held_bar(roll), nil, 'half a second left: not held')

	local other = start_roll('sword')
	tick(118)
	choose(other, 'Greed')
	check(held_bar(other) ~= nil, 'two seconds left: held')
end)

test('a click is held only when Blizzard takes the bar away, not when it hides with UIParent', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet', { confirm = true })
	tick(10)
	-- You click; the game asks you to confirm, so the bar stays up.
	click_of(roll, 'Greed')
	UIParent:Hide() -- Alt+Z
	eq(#LT:GetHeldRolls(), 0, 'hidden with UIParent: not held')
	UIParent:Show()
	check(frame_of(roll) ~= nil and frame_of(roll):IsVisible(), "Blizzard's bar is back")
	eq(#LT:GetHeldRolls(), 0, 'still nothing held')
	GroupLootContainer:Hide()
	eq(#LT:GetHeldRolls(), 0, 'the container hidden: not held')
	GroupLootContainer:Show()

	stub.fire_event('CANCEL_LOOT_ROLL', roll) -- you accept: the server takes it away
	eq(#LT:GetHeldRolls(), 1, 'the server takes it away: held once')
	check(held_bar(roll) ~= nil, 'that roll')
end)

test('a roll that ends without a choice is not held', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	tick(119)
	stub.fire_event('CANCEL_LOOT_ROLL', roll)
	check(frame_of(roll) == nil, 'its bar went')
	eq(#LT:GetHeldRolls(), 0, 'nothing held')
end)

test("an accent change recolors a held roll's lit border and label, and the locked preview's; a Buttons change does not", function()
	world()
	LT:SetTestRolls(true)
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if not bar then return end
	local preview
	for _, other in ipairs(LT.rollPreview.bars) do
		if other.Choice:IsShown() then preview = other end
	end

	local color = st.config.profile.theme.accent
	color.r, color.g, color.b = 0.9, 0.3, 0.1
	st:ColorsChanged('button')
	eq(T.edge_rgb(button_of(bar, bar.choice).Icon.backdrop), '0.00,0.68,0.94', "a 'button' change moves nothing (Review Focus 4)")
	st:ColorsChanged('accent')
	for what, b in pairs({ held = bar, preview = preview }) do
		eq(T.edge_rgb(button_of(b, b.choice).Icon.backdrop), '0.90,0.30,0.10', what .. ": the lit border takes the new accent")
		local r, g, bl = b.Choice:GetTextColor()
		eq(T.text(r, g, bl), '0.90,0.30,0.10', what .. ': and the label')
	end
end)

test('the roll timer bars fill in the accent, in the skinned frame and in a held bar (Question 3)', function()
	world()
	LT:SetTestRolls(true)
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	tick(1)
	eq(T.text(frame_of(roll).Timer:GetStatusBarColor()), '0.00,0.68,0.94,1.00', "the skinned frame's timer: the accent at the defaults")
	local accent = st.config.profile.theme.accent
	accent:SetRGB(0.9, 0.3, 0.1)
	tick(1)
	eq(T.text(frame_of(roll).Timer:GetStatusBarColor()), '0.90,0.30,0.10,1.00', 'a changed accent is the next frame')
	choose(roll, 'Greed', drop)
	local bar = held_bar(roll)
	tick(1)
	check(bar, 'held')
	eq(T.text(bar.Timer:GetStatusBarColor()), '0.90,0.30,0.10,1.00', "and the held bar's timer")
	accent:SetRGB(0, 0.68, 0.94)
end)

test('a Disenchant choice lights the Greed or Transmog button the bar shows', function()
	world()
	local greed = start_roll('amulet', { confirm = true }) -- Greed shows
	local transmog = start_roll('ring', { confirm = true }) -- Transmog shows
	tick(5)
	-- Neither client has a Disenchant button: an addon calls RollOnLoot(roll, 3).
	-- A roll with no confirmation would be cancelled inside the call (not held,
	-- see docs/followups.md); one that asks (bind on pickup) stays up, the post-hook
	-- notes the choice, and accepting the popup takes the bar away.
	for _, roll in ipairs({ greed, transmog }) do
		RollOnLoot(roll, 3)
		check(frame_of(roll) ~= nil, 'the bar stays up for the popup')
		stub.fire_event('CANCEL_LOOT_ROLL', roll) -- you accept
	end

	local a, b = held_bar(greed), held_bar(transmog)
	check(a ~= nil and b ~= nil, 'both held')
	if not (a and b) then return end
	eq(a.Choice:GetText(), 'Greed', 'on a Greed bar, Greed')
	eq(button_of(a, 'Greed'):GetAlpha(), 1, 'lit')
	check(has_border(button_of(a, 'Greed')), 'with the border')
	eq(b.Choice:GetText(), 'Transmog', 'on a Transmog bar, Transmog')
	eq(button_of(b, 'Transmog'):GetAlpha(), 1, 'lit')
end)

------------------------------------------------------------------ a click holds the roll at the bar's hide

-- A test run once on each client's roll frame shape.
local function each_shape(name, fn)
	for _, shape in ipairs({ 'forever', 'retail' }) do
		test(name .. ' [' .. shape .. ']', function()
			SHAPE = shape
			local ok, err = pcall(fn)
			SHAPE = 'forever'
			if not ok then error(err, 0) end
		end)
	end
end

-- A plain click (no confirmation): the client cancels the roll inside
-- RollOnLoot, so the bar hides before RollOnLoot returns and before any post-hook
-- on it could note the choice. The click's PreClick has noted it already.
for _, case in ipairs({
	{ 'Need', 'amulet', 'Need' }, { 'Greed', 'amulet', 'Greed' }, { 'Pass', 'amulet', 'Pass' },
	{ 'Transmog', 'ring', 'Transmog' },
}) do
	local choice, key, label = case[1], case[2], case[3]
	each_shape('a plain click on ' .. choice .. ' holds the roll with its choice, drop, time and place', function()
		world()
		local first = add_drop('sword', {})
		local drop = add_drop(key, { { 'Brightblade', 'PALADIN', 'Greed' } })
		local a = start_roll('sword')
		local b = start_roll(key)
		local c = start_roll('cloth')
		LT:UpdateRollBars()
		tick(30)
		local frame = frame_of(b)
		local bottom = frame:GetBottom()
		local bottomC = frame_of(c):GetBottom()

		choose(b, choice, drop)

		check(not frame:IsShown(), "Blizzard took the bar away inside the call")
		local bar = held_bar(b)
		check(bar ~= nil, 'the roll is held')
		if not bar then return end
		eq(bar.Choice:GetText(), label, 'locked on ' .. label)
		eq(bar:GetBottom(), bottom, 'in the bar\'s place in the stack')
		eq(frame_of(c):GetBottom(), bottomC, 'the roll after it stays')
		eq(bar.Timer.Text:GetText(), '01:30', 'with the time left when you clicked')
		eq(bar.Name:GetText(), ITEMS[key].name, 'and its item')
		check(bar.dropID ~= nil and bar.dropID == '7:' .. drop.lootListKey, 'and its drop: ' .. tostring(bar.dropID))
		local greeds = { Need = '1', Greed = '2', Pass = '1' }
		eq(count(bar, 'Greed'), greeds[choice], 'with its counts')
		check(counts_shown(bar) >= 1, 'some count shown')
		check(frame_of(a) ~= nil, 'the other roll is untouched')
	end)
end

each_shape('a roll chosen with a fifth waiting is held with its own item while its frame shows the next', function()
	world()
	local drops = { add_drop('sword', {}), add_drop('amulet', { { 'Mistweave', 'PRIEST', 'Greed' } }),
		add_drop('cloth', {}), add_drop('ring', {}), add_drop('sword', {}) }
	local rolls = {}
	for _, key in ipairs({ 'sword', 'amulet', 'cloth', 'ring', 'sword' }) do rolls[#rolls + 1] = start_roll(key) end
	LT:UpdateRollBars()
	tick(40)
	local step = LT.config.roll.height + LT.config.roll.spacing
	local base = frame_of(rolls[1]):GetBottom()
	local frame = frame_of(rolls[2])

	choose(rolls[2], 'Greed', drops[2])

	eq(frame_of(rolls[5]), frame, 'the waiting roll took the frame inside the same call')
	local bar = held_bar(rolls[2])
	check(bar ~= nil, 'the chosen roll is held')
	if not bar then return end
	eq(bar.Name:GetText(), ITEMS.amulet.name, 'the held bar shows the old item')
	eq(bar.Icon:GetTexture(), ITEMS.amulet.texture, 'and its icon')
	eq(frame.Name:GetText():gsub('^BoE ', ''), ITEMS.sword.name, 'the frame the new one')
	eq(bar:GetBottom(), base + step, 'the held bar keeps the second place')
	eq(frame_of(rolls[5]):GetBottom(), base + 4 * step, 'the new roll goes last')
	eq(bar.Timer.Text:GetText(), '01:20', 'with the time left at the click')
	eq(count(bar, 'Greed'), '2', 'and the old roll\'s counts, not the new one\'s')
end)

each_shape('a confirmation roll is held once you accept, and not when you cancel the popup', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet', { confirm = true })
	local declined = start_roll('sword', { confirm = true })
	LT:UpdateRollBars()
	tick(10)

	click_of(roll, 'Greed')
	check(frame_of(roll) ~= nil, 'the bar stays up for the popup')
	eq(#LT:GetHeldRolls(), 0, 'nothing held yet')
	-- You accept: the client cancels the roll and the bar goes.
	stub.fire_event('CANCEL_LOOT_ROLL', roll)
	local bar = held_bar(roll)
	check(bar ~= nil, 'held after accepting')
	if bar then eq(bar.Choice:GetText(), 'Greed', 'on your choice') end

	-- You click and then decline the popup: the bar stays, nothing is held, and
	-- when the roll times out later it is not shown as chosen.
	click_of(declined, 'Need')
	check(frame_of(declined) ~= nil, 'the bar is still up')
	eq(held_bar(declined), nil, 'declined: not held')
	tick(109.5)
	stub.fire_event('CANCEL_LOOT_ROLL', declined) -- the roll ends
	eq(held_bar(declined), nil, 'a later time-out is not shown as chosen')
end)

test('a main spec Need cancelled right after its animation, inside the call, is held with the time read before it', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet', { needAnim = 'instant' })
	LT:UpdateRollBars()
	tick(50)
	local frame = frame_of(roll)
	choose(roll, 'Need', drop)
	eq(frame.Timer:GetValue(), 0, 'the timer was zeroed inside the call')
	local bar = held_bar(roll)
	check(bar ~= nil, 'held, not skipped as under a second left')
	if bar then eq(bar.Timer.Text:GetText(), '01:10', 'with the 70 seconds it had at the click') end
end)

test('a click that hides nothing leaves no pending choice, and a pending choice never reaches another roll', function()
	world()
	local a = start_roll('amulet', { confirm = true })
	local b = start_roll('sword')
	LT:UpdateRollBars()
	tick(10)
	click_of(a, 'Greed') -- the popup: the bar stays, its choice is noted by the post-hook
	-- The popup is declined; the bar later hides without a choice made now: a
	-- click on another roll must not be taken for this one.
	choose(b, 'Pass')
	check(held_bar(b) ~= nil, 'the other roll is held on its own choice')
	eq(held_bar(b).Choice:GetText(), 'Pass', 'Pass')
	eq(held_bar(a), nil, 'the first is not held')

	-- A click whose PostClick has run has no pending choice left: hiding the bar
	-- now (the roll ends at 9 seconds left) holds only what the post-hook noted.
	local c = start_roll('cloth')
	tick(0)
	local frame = frame_of(c)
	stub.fire_script(BC(frame).GreedButton, 'PreClick', 'LeftButton', false)
	stub.fire_script(BC(frame).GreedButton, 'PostClick', 'LeftButton', false)
	tick(30)
	stub.fire_event('CANCEL_LOOT_ROLL', c)
	eq(held_bar(c), nil, 'a cleared pending choice holds nothing')
end)

test('a roll click holds in combat', function()
	world()
	local drop = add_drop('amulet', {})
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(10)
	stub.in_combat = true
	choose(roll, 'Greed', drop)
	stub.in_combat = false
	check(held_bar(roll) ~= nil, 'held in combat')
end)

each_shape('a bind on pickup Need, then Pass while its popup is up, is held as Pass', function()
	world()
	add_drop('amulet', {})
	local roll = start_roll('amulet', { confirm = true })
	LT:UpdateRollBars()
	tick(10)
	click_of(roll, 'Need') -- the popup: the choice is noted, the bar stays
	check(frame_of(roll) ~= nil, 'the bar is still up')
	click_of(roll, 'Pass') -- a Pass binds nothing: the client cancels the roll inside the call
	local bar = held_bar(roll)
	check(bar ~= nil, 'held')
	if bar then eq(bar.Choice:GetText(), 'Pass', 'on Pass, not the Need noted before it') end
end)

test('a roll whose hold is skipped is not reported as held at the bar hiding', function()
	world()
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(119.5)
	st.DEBUG = true
	local lines = printed_by(function() choose(roll, 'Greed') end)
	st.DEBUG = false
	check(any_line(lines, 'hold ' .. roll .. ' skipped: under a second left'), 'the hold is skipped: ' .. table.concat(lines, ' | '))
	check(not any_line(lines, 'choice held at the bar hiding'), 'and nothing says it was held')
end)

test('CANCEL_ALL_LOOT_ROLLS clears a pending click (its PostClick never ran), so no later hide holds it', function()
	world()
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(10)
	-- A PreClick with no PostClick after it (an error in OnClick, say).
	stub.fire_script(BC(frame_of(roll)).GreedButton, 'PreClick', 'LeftButton', false)
	stub.fire_event('CANCEL_ALL_LOOT_ROLLS') -- SaftUI hears it first
	eq(#LT:GetHeldRolls(), 0, 'nothing held after SaftUI and then Blizzard hear it')
	for i = 1, 4 do check(not _G['GroupLootFrame' .. i]:IsShown(), "Blizzard's bars are gone") end
end)

test('a disabled Need takes no click: nothing is pending, nothing held', function()
	world()
	local roll = start_roll('amulet')
	LT:UpdateRollBars()
	tick(10)
	local need = BC(frame_of(roll)).NeedButton
	need:Disable() -- canNeed false: Blizzard disables it with a reason
	st.DEBUG = true
	local clicked
	local lines = printed_by(function() clicked = click(need) end)
	st.DEBUG = false
	eq(clicked, false, 'the game delivers no click to a disabled button')
	eq(game.rolled[roll], nil, 'RollOnLoot was not called')
	check(not any_line(lines, 'choice pending'), 'nothing pending')
	stub.fire_event('CANCEL_LOOT_ROLL', roll) -- the roll ends
	eq(held_bar(roll), nil, 'not held')
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
	tick(4)
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

test("the roll mover is hidden with no roll up, and shown while a roll frame shows", function()
	world()
	local EM = st.EditModeFrames
	LT:RegisterRollMover()
	local mover = EM.movers.lootroll
	eq(EM:MoverModule(mover), 'Loot', 'module')
	eq(EM:IsMoverHidden(mover), true, 'no roll bar shows')
	start_roll('sword')
	eq(EM:IsMoverHidden(mover), false, "a roll's frame shows")
	eq(#take_errors(), 0, 'no errors')
end)
