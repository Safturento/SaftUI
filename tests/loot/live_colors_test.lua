-- SaftUI-Loot's readers follow a color as it is picked (st:ColorChanged, through
-- LT:OnColorsChanged): the roll letters (Loot > Need, Pass...), the paired counts,
-- the held bars' timers and names, the feed's item names (Item quality), its mount
-- entries (Loot > Mount) and its reputation and renown bars. The feed keeps an
-- item's plain name and quality and colors the name as it draws (LT.FeedItemName).
-- A pass colors only: nothing made, nothing moved, almost no garbage.
--
-- Real: SaftUI-Loot's config.lua, init.lua, rollbar.lua, roll.lua, rolltest.lua,
-- rollinfo.lua, Feed/*.lua, Core's helpers and Utilities, and the color pass.
-- Made by hand: Blizzard's roll frames, as roll_skin_test.lua makes them.
load_core_helpers()
local T = load_test_file('lib/theme_helpers.lua')
local C = load_test_file('lib/color_cost.lua')
load_saftui('SaftUI-Core/Utilities/utilities.lua')
load_saftui('SaftUI-Core/Utilities/itemupgrades.lua')
load_saftui('SaftUI-Loot/config.lua')
apply_defaults()
load_saftui('SaftUI-Loot/init.lua')
load_saftui('SaftUI-Loot/rollbar.lua')
load_saftui('SaftUI-Loot/roll.lua')
load_saftui('SaftUI-Loot/rolltest.lua')
load_saftui('SaftUI-Loot/rollinfo.lua')
load_saftui('SaftUI-Loot/Feed/history.lua')
load_saftui('SaftUI-Loot/Feed/parse.lua')
load_saftui('SaftUI-Loot/Feed/feed.lua')
load_saftui('SaftUI-Loot/Feed/loothistory.lua')
load_saftui('SaftUI-Loot/Feed/rolls.lua')
load_saftui('SaftUI-Loot/Feed/filter.lua')
load_saftui('SaftUI-Loot/Feed/progress.lua')

local st = SaftUI
local LT = st.Loot
st:BindModuleConfig(LT, 'loot')
st.config.char = {}
local colors = st.config.profile.colors

load_string_format() -- the real LibStringFormat, as the game has it
function ClearItemCraftingQualityOverlay(button) end
function SetItemCraftingQualityOverlay() end
st:GetModule('Utilities').ScanItemLink = function() return '' end -- the tooltip scan
GameTooltip = GameTooltip or CreateFrame('GameTooltip', 'GameTooltip', UIParent)
st.OptionsWidgets = st.OptionsWidgets or { ListOwner = function() end }

local function set(color, r, g, b) color.r, color.g, color.b = r, g, b end
local function rgb(r, g, b) return T.rgb(r, g, b) end

-- Blizzard's roll frame as roll_skin_test.lua makes it, with a Transmog button.
local counter = 0
local function roll_frame()
	counter = counter + 1
	local name = 'GroupLootFrame' .. counter
	local frame = CreateFrame('Frame', name, UIParent)
	frame.rollID = counter
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
	for _, button in ipairs({ 'Pass', 'Greed', 'Transmog', 'Need' }) do
		container[button .. 'Button'] = CreateFrame('Button', nil, container)
	end
	return frame
end

local function letters(frame)
	local out = {}
	for _, name in ipairs({ 'Pass', 'Greed', 'Transmog', 'Need' }) do
		for _, region in ipairs({ frame.LootButtonContainer[name .. 'Button']:GetRegions() }) do
			if region:GetObjectType() == 'FontString' and region:GetNumPoints() == 1 and region:GetPoint(1) == 'CENTER' then
				out[name] = rgb(region:GetVertexColor())
			end
		end
	end
	return out
end

-- The rolls' item as the game gives it, by roll ID: quality 4 for odd rolls, 3 for even.
ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS or {}
GetLootRollItemInfo = function(rollID)
	return 134400, 'Drakefire Amulet', 1, rollID % 2 == 1 and 4 or 3, true, true, true, false
end
GetLootRollItemLink = function() return '|cffa335ee|Hitem:19019::::::::60:::::|h[Drakefire Amulet]|h|r' end

local all_frames = {}
local function skinned(shown)
	local frame = roll_frame()
	all_frames[#all_frames + 1] = frame
	LT:SkinRollFrame(frame)
	frame:Show()
	if shown ~= false then LT:GroupLootFrame_OnShow(frame) end
	return frame
end

-- One pass's setter calls: { total, by } (C.measure, once, after a first pass).
local function pass(group, key)
	st:ColorChanged(group, key)
	local m = C.measure(function() st:ColorChanged(group, key) end, 1)
	eq(m.forbidden.total, 0, group .. ' ' .. tostring(key) .. ': nothing forbidden')
	eq(m.made, 0, group .. ' ' .. tostring(key) .. ': nothing made')
	return m.calls
end

------------------------------------------------------------------ the rolls

test("Loot > Need: each roll frame's Need letter and the shown Need counts; Greed's untouched", function()
	local a, b = skinned(), skinned()
	local keep = { colors.loot.need:GetRGB() }
	set(colors.loot.need, 0.1, 0.2, 0.3)
	st:ColorChanged('loot', 'need')
	local calls = pass('loot', 'need')
	eq(calls.total, #LT.skinnedRollFrames, 'one Need letter per skinned frame, and nothing else')
	eq(calls.by.SetVertexColor, #LT.skinnedRollFrames, 'a letter is a vertex color')
	for _, frame in ipairs({ a, b }) do
		local l = letters(frame)
		eq(l.Need, rgb(0.1, 0.2, 0.3), 'the Need letter')
		eq(l.Greed, rgb(colors.loot.greed:GetRGB()), "Greed's letter is as it was")
		eq(l.Pass, rgb(colors.loot.pass:GetRGB()), "Pass's letter is as it was")
	end
	set(colors.loot.need, unpack(keep))
	st:ColorChanged('loot', 'need')
	eq(letters(a).Need, rgb(unpack(keep)), 'and back')
end)

test("Loot > Transmog: the paired counts that show Transmog's picks, on a held bar and the preview's", function()
	local S = LT.ROLL_STATE
	local rolls = { list = { { name = 'Aa', state = S.Transmog }, { name = 'Bb', state = S.Greed } } }
	local frame = skinned()
	-- A held bar (roll.lua) with its counts set.
	local bar = LT.rollbar.CreateBar(UIParent)
	LT.rollbar.ApplyBarConfig(bar, LT.config.roll)
	LT:SetRollCounts(bar.counts, rolls)
	local shown_paired, other_paired
	for text, count in pairs(bar.counts) do
		if count.color == 'transmog' and text:IsShown() then shown_paired = text end
		if count.color == 'greed' and text:IsShown() then other_paired = text end
	end
	check(shown_paired and other_paired, 'a Greed pick and a Transmog pick show, each as a paired count')
	-- Register the bar where the pass finds it: the preview's bars.
	LT.rollPreview = { bars = { bar }, IsShown = function() return false end }
	local keep = { colors.loot.transmog:GetRGB() }
	set(colors.loot.transmog, 0.9, 0.8, 0.1)
	st:ColorChanged('loot', 'transmog')
	eq(pass('loot', 'transmog').by.SetTextColor, 1, "one count: the one that shows Transmog's picks")
	eq(pass('loot', 'greed').by.SetTextColor, 1, "Loot > Greed: only Greed's count")
	eq(pass('loot', 'need').by.SetTextColor, nil, 'Loot > Need: no count')
	eq(rgb(shown_paired:GetTextColor()), rgb(0.9, 0.8, 0.1), "the shown count of Transmog's picks")
	eq(rgb(other_paired:GetTextColor()), rgb(colors.loot.greed:GetRGB()), "Greed's count is as it was")
	set(colors.loot.transmog, unpack(keep))
	st:ColorChanged('loot', 'transmog')
	LT.rollPreview = nil -- no preview is up in the normal state
	check(frame, 'kept')
end)

test('Item quality on a shown roll: its name, and only a roll of that quality', function()
	local epic, rare = skinned(), skinned()
	-- Roll IDs alternate: the first made is odd (epic), the second even (rare); find by quality.
	if epic.rollID % 2 == 0 then epic, rare = rare, epic end
	local rare_before = rgb(rare.Name:GetVertexColor())
	local keep = { colors.item_quality[4]:GetRGB() }
	set(colors.item_quality[4], 0.5, 0.6, 0.7)
	st:ColorChanged('item_quality', 4)
	local epics = 0
	for _, f in ipairs(all_frames) do if f.rollID % 2 == 1 then epics = epics + 1 end end
	eq(pass('item_quality', 4).total, epics, 'only the epic rolls\' names')
	eq(pass('item_quality', 3).total, #all_frames - epics, 'and Item quality > Rare only the rare ones')
	eq(rgb(epic.Name:GetVertexColor()), rgb(0.5, 0.6, 0.7), 'the epic roll\'s name')
	eq(rgb(rare.Name:GetVertexColor()), rare_before, "the rare roll's name is as it was")
	set(colors.item_quality[4], unpack(keep))
	st:ColorChanged('item_quality', 4)
end)

test("the Accent: held bars' timers; Item quality on a held bar: its name", function()
	local frame = skinned()
	local roll = { rollID = frame.rollID, choice = 'Need', ends = GetTime() + 30, length = 60,
		link = GetLootRollItemLink(), item = 'item:19019' }
	local bar = LT:HoldRoll(frame, roll)
	check(bar, 'a bar is held')
	local quality = frame.rollID % 2 == 1 and 4 or 3
	local keep = { st.config.profile.theme.accent:GetRGB() }
	set(st.config.profile.theme.accent, 0.2, 0.4, 0.6)
	st:ColorChanged('accent')
	eq(rgb(bar.Timer:GetStatusBarColor()), rgb(0.2, 0.4, 0.6), "the held bar's timer")
	set(st.config.profile.theme.accent, unpack(keep))
	st:ColorChanged('accent')

	local qkeep = { colors.item_quality[quality]:GetRGB() }
	set(colors.item_quality[quality], 0.7, 0.6, 0.5)
	st:ColorChanged('item_quality', quality)
	eq(rgb(bar.Name:GetVertexColor()), rgb(0.7, 0.6, 0.5), "the held bar's name")
	set(colors.item_quality[quality], unpack(qkeep))
	st:ColorChanged('item_quality', quality)
	LT:ReleaseHeldRoll(bar)
end)

------------------------------------------------------------------ the feed

local feed
local function make_feed()
	feed = CreateFrame('Frame', 'SaftUILootFeed', UIParent)
	feed:SetSize(400, 20)
	feed.items, feed.offset = {}, 0
	feed.overlay = CreateFrame('Frame', nil, feed)
	LT.feed = feed
	LT:CreateFeedButtons()
	LT.debugText = st:CreateFontString(feed, 'normal', '0/0')
	LT.config.feed.max_items = 20
	LT:UpdateLootFeedConfig()
end
make_feed()

local function tint(text) return rgb(text) end

-- An item entry as LootFeedAddItem makes it (GetItemInfo stood in for).
local item_info = {}
C_Item = C_Item or {}
C_Item.GetItemInfo = function(link)
	local i = item_info[link]
	if not i then return end
	return i.name, link, i.quality, 1, 1, 'Armor', i.sub, 1, '', 1
end

local function loot_match(name, quality, sub)
	local link = '|cffa335ee|Hitem:' .. (#name * 100 + quality) .. '|h[' .. name .. ']|h|r'
	item_info[link] = { name = name, quality = quality, sub = sub or 'Plate' }
	return { link = link, count = 1 }
end

-- 20 lines: 6 epic items, 4 rare, 2 mounts (epic), 4 uncommon, 3 reputation lines at Friendly, 1 renown.
local function fill_feed()
	wipe(LT:GetAllItems())
	stub.time = 100
	LT.config.feed.fade_time = 600
	for i = 1, 6 do LT:LootFeedAddItem(loot_match('Epic ' .. i, 4)) end
	for i = 1, 4 do LT:LootFeedAddItem(loot_match('Rare ' .. i, 3)) end
	for i = 1, 2 do LT:LootFeedAddItem(loot_match('Mount ' .. i, 4, 'Mount')) end
	for i = 1, 4 do LT:LootFeedAddItem(loot_match('Uncommon ' .. i, 2)) end
	local stack = LT:GetAllItems()
	for i = 1, 3 do
		tinsert(stack, 1, { name = i .. ' Reputation (Faction)', type = 'Reputation', icon = 1, time = 100,
			progress = { value = 1, max = 10, colorGroup = 'reaction', colorKey = 5,
				r = colors.reaction[5].r, g = colors.reaction[5].g, b = colors.reaction[5].b } })
	end
	tinsert(stack, 1, { name = 'Renown', type = 'Reputation', icon = 1, time = 100,
		progress = { value = 1, max = 10, colorGroup = 'renown',
			r = colors.renown.r, g = colors.renown.g, b = colors.renown.b } })
	LT:GetFilteredItems()
	LT:UpdateFeed()
end

local function name_color(text) return text:match('^|cff(%x%x%x%x%x%x)') end
local function hex(r, g, b) return ('%02x%02x%02x'):format(r * 255, g * 255, b * 255) end

local function shown_lines()
	local out = {}
	for i = 1, 20 do
		local line = feed.items[i]
		if line and line:IsShown() and line.info then out[#out + 1] = line end
	end
	return out
end

test('the feed keeps the plain name and quality, and a line drawn later takes the current color (LT.FeedItemName)', function()
	fill_feed()
	local info
	for _, entry in ipairs(LT:GetAllItems()) do if entry.plain == 'Epic 1' then info = entry end end
	check(info, 'the entry keeps its plain name')
	eq(info.quality, 4, 'and its quality')
	local keep = { colors.item_quality[4]:GetRGB() }
	eq(LT.FeedItemName(info), '|cff' .. hex(unpack(keep)) .. 'Epic 1|r', 'the name in the current color')
	set(colors.item_quality[4], 0.25, 0.5, 0.75)
	eq(LT.FeedItemName(info), '|cff' .. hex(0.25, 0.5, 0.75) .. 'Epic 1|r', 'a color changed after the push')
	LT:UpdateFeed()
	local drawn
	for _, line in ipairs(shown_lines()) do if line.info == info then drawn = line end end
	eq(name_color(drawn.text:GetText()), hex(0.25, 0.5, 0.75), 'a line drawn later takes the current color')
	set(colors.item_quality[4], unpack(keep))
	eq(LT.FeedItemName({ name = 'Plain' }), 'Plain', 'an entry with no plain name shows its name')
end)

test('Item quality > Epic: the 6 epic lines set their name again in the new color; the others untouched', function()
	fill_feed()
	local set_texts = {}
	local lines = shown_lines()
	eq(#lines, 20, 'twenty lines are shown')
	local before = {}
	for i, line in ipairs(lines) do before[i] = line.text:GetText() end
	local keep = { colors.item_quality[4]:GetRGB() }
	set(colors.item_quality[4], 0.25, 0.5, 0.75)
	st:ColorChanged('item_quality', 4)
	eq(pass('item_quality', 4).by.SetText, 8, 'only the 6 epic items and 2 mounts set their name again')
	eq(pass('item_quality', 3).by.SetText, 4, 'Item quality > Rare: only the 4 rare lines')
	local changed, same = 0, 0
	for i, line in ipairs(lines) do
		local now = line.text:GetText()
		if line.info.quality == 4 and line.info.itemSubType ~= 'Mount' then
			eq(name_color(now), hex(0.25, 0.5, 0.75), 'an epic line: ' .. line.info.plain)
			changed = changed + 1
		elseif line.info.quality == 4 then
			eq(name_color(now), hex(0.25, 0.5, 0.75), 'a mount (epic) line too')
		else
			eq(now, before[i], 'not an epic line: unchanged')
			same = same + 1
		end
	end
	eq(changed, 6, 'the 6 epic items')
	eq(same, 12, 'the rest, reputation lines included')
	set(colors.item_quality[4], unpack(keep))
	st:ColorChanged('item_quality', 4)
end)

test("Loot > Mount: the 2 shown mount entries' border and 60% fill", function()
	fill_feed()
	local mounts = {}
	for _, line in ipairs(shown_lines()) do if line.info.itemSubType == 'Mount' then mounts[#mounts + 1] = line end end
	eq(#mounts, 2, 'two mount lines')
	local keep = { colors.loot.mount:GetRGB() }
	set(colors.loot.mount, 0.2, 0.3, 0.4)
	st:ColorChanged('loot', 'mount')
	local calls = pass('loot', 'mount')
	eq(calls.by.SetBackdropColor, 2, 'a fill for each of the 2 mount lines')
	eq(calls.by.SetText, nil, 'no name set again')
	eq(pass('loot', 'need').by.SetBackdropColor, nil, 'Loot > Need repaints no mount')
	local want = T.text(0.2, 0.3, 0.4)
	for _, line in ipairs(mounts) do
		eq(T.edge(line.backdrop), want .. ',1.00', 'the border')
		eq(T.fill(line.backdrop), want .. ',0.60', 'the 60% fill')
		eq(T.edge(line.icon.backdrop), want .. ',1.00', "the icon's border")
	end
	set(colors.loot.mount, unpack(keep))
	st:ColorChanged('loot', 'mount')
end)

test("Reputation > Friendly: the 3 reputation lines' bars; Renown: the renown line's", function()
	fill_feed()
	local rep, renown = {}, nil
	for _, line in ipairs(shown_lines()) do
		local p = line.info.progress
		if p and p.colorGroup == 'reaction' then rep[#rep + 1] = line end
		if p and p.colorGroup == 'renown' then renown = line end
	end
	eq(#rep, 3, 'three reputation lines'); check(renown, 'a renown line')
	local keep = { colors.reaction[5]:GetRGB() }
	local renown_before = rgb(renown.progressBar:GetStatusBarColor())
	set(colors.reaction[5], 0.1, 0.9, 0.2)
	st:ColorChanged('reaction', 5)
	eq(pass('reaction', 5).by.SetStatusBarColor, 3, 'the 3 Friendly bars')
	eq(pass('reaction', 4).by.SetStatusBarColor, nil, 'Reputation > Neutral: no bar')
	for _, line in ipairs(rep) do eq(rgb(line.progressBar:GetStatusBarColor()), rgb(0.1, 0.9, 0.2), 'a Friendly bar') end
	eq(rgb(renown.progressBar:GetStatusBarColor()), renown_before, "the renown bar is as it was")
	set(colors.reaction[5], unpack(keep))
	st:ColorChanged('reaction', 5)

	local rkeep = { colors.renown.r, colors.renown.g, colors.renown.b }
	set(colors.renown, 0.3, 0.2, 0.9)
	st:ColorChanged('renown')
	eq(pass('renown').by.SetStatusBarColor, 1, "Renown: the renown line's bar only")
	eq(rgb(renown.progressBar:GetStatusBarColor()), rgb(0.3, 0.2, 0.9), "Renown's bar")
	eq(rgb(rep[1].progressBar:GetStatusBarColor()), rgb(colors.reaction[5]:GetRGB()), "a Friendly bar is as it was")
	set(colors.renown, unpack(rkeep))
	st:ColorChanged('renown')
end)

test('a progress line reads its color as it draws, so a profile switch reaches it', function()
	fill_feed()
	local line
	for _, l in ipairs(shown_lines()) do if l.info.progress and l.info.progress.colorGroup == 'reaction' then line = l end end
	local keep = { colors.reaction[5]:GetRGB() }
	-- The profile's object is replaced, as a switch does: no pass, only the next draw.
	colors.reaction[5] = CreateColor(0.6, 0.1, 0.1, 1)
	LT:UpdateFeed()
	eq(rgb(line.progressBar:GetStatusBarColor()), rgb(0.6, 0.1, 0.1), 'the next draw reads the new profile color')
	colors.reaction[5] = CreateColor(unpack(keep))
end)

test('LootFeedAddCurrency keeps the plain name, quality and counts as a suffix', function()
	C_CurrencyInfo = C_CurrencyInfo or {}
	C_CurrencyInfo.GetCurrencyInfoFromLink = function()
		return { name = 'Valor', quality = 3, quantity = 5, maxQuantity = 10, iconFileID = 1 }
	end
	wipe(LT:GetAllItems())
	LT:LootFeedAddCurrency({ currency = 'currency:1', link = 'currency:1', count = 1 })
	local info = LT:GetAllItems()[1]
	eq(info.plain, 'Valor'); eq(info.quality, 3); eq(info.suffix, ' (5/10)')
	eq(LT.FeedItemName(info), '|cff' .. hex(colors.item_quality[3]:GetRGB()) .. 'Valor|r (5/10)', 'colored name, then its counts')
end)

-- The line of an entry on screen, after the entries are made fresh and drawn.
local function line_of(info)
	for _, entry in ipairs(LT:GetAllItems()) do entry.time = GetTime() end
	LT:GetFilteredItems()
	LT:UpdateFeed()
	for _, line in ipairs(shown_lines()) do if line.info == info then return line end end
end

local function reputation_world(major)
	C_Reputation = {
		GetFactionDataByID = function(id)
			return { factionID = id, name = 'Stormwind', reaction = 5, currentStanding = 50,
				currentReactionThreshold = 0, nextReactionThreshold = 100 }
		end,
		GetNumFactions = function() return 1 end,
		GetFactionDataByIndex = function() return { factionID = 72, name = 'Stormwind' } end,
		IsMajorFaction = function() return major end,
	}
	C_MajorFactions = { GetMajorFactionData = function() return { renownReputationEarned = 5, renownLevelThreshold = 10 } end }
	LT.FEED_ICONS = LT.FEED_ICONS or { ReputationUp = 1, ReputationDown = 1 }
end

test('a real reputation gain names its color, and its line follows Reputation (and a renown gain, Renown)', function()
	wipe(LT:GetAllItems())
	reputation_world(false)
	LT:LootFeedAddReputation({ faction = 'Stormwind', count = 10 })
	local info = LT:GetAllItems()[1]
	eq(info.progress.colorGroup, 'reaction', 'the snapshot names the reaction group')
	eq(info.progress.colorKey, 5, 'and Friendly')
	local line = line_of(info)
	local keep = { colors.reaction[5]:GetRGB() }
	set(colors.reaction[5], 0.1, 0.9, 0.2)
	st:ColorChanged('reaction', 5)
	eq(rgb(line.progressBar:GetStatusBarColor()), rgb(0.1, 0.9, 0.2), 'the line follows')
	set(colors.reaction[5], unpack(keep))
	st:ColorChanged('reaction', 5)

	wipe(LT:GetAllItems())
	reputation_world(true)
	LT:LootFeedAddReputation({ faction = 'Stormwind', count = 10 })
	info = LT:GetAllItems()[1]
	eq(info.progress.colorGroup, 'renown', 'a major faction names Renown')
	line = line_of(info)
	local rkeep = { colors.renown.r, colors.renown.g, colors.renown.b }
	set(colors.renown, 0.3, 0.2, 0.9)
	st:ColorChanged('renown')
	eq(rgb(line.progressBar:GetStatusBarColor()), rgb(0.3, 0.2, 0.9), 'a renown line follows Renown')
	set(colors.renown, unpack(rkeep))
	C_Reputation, C_MajorFactions = nil, nil
end)

test("a roll result's entry keeps its plain name and quality, and its line follows Item quality", function()
	wipe(LT:GetAllItems())
	local match = loot_match('Rolled Blade', 4)
	local entry = LT:BuildRollEntry(match.link, { list = {} }, false)
	eq(entry.plain, 'Rolled Blade'); eq(entry.quality, 4)
	LT:LootFeedPush(entry)
	local line = line_of(entry)
	local keep = { colors.item_quality[4]:GetRGB() }
	set(colors.item_quality[4], 0.25, 0.5, 0.75)
	st:ColorChanged('item_quality', 4)
	eq(name_color(line.text:GetText()), hex(0.25, 0.5, 0.75), 'the roll result line follows')
	set(colors.item_quality[4], unpack(keep))
	st:ColorChanged('item_quality', 4)
	C_Item.GetItemInfoInstant = function() return 1, 'Armor', 'Plate', '', 1 end
	local uncached = LT:BuildRollEntry('|cffffffff|Hitem:1|h[Unknown]|h|r', { list = {} }, true)
	eq(uncached.plain, nil, 'an item with no data keeps no plain name')
end)

-- A roll result: a winner, or all passed.
local function winner_rolls() return { list = { { name = 'Winner', class = 'WARRIOR', state = LT.ROLL_STATE.Greed, roll = 50 } }, winner = 1 } end

test("a roll result's right text is built as the line draws: the winner follows their Class color and All passed follows Loot > Pass", function()
	wipe(LT:GetAllItems())
	local a = LT:BuildRollEntry(loot_match('Won Blade', 4).link, winner_rolls(), false)
	local b = LT:BuildRollEntry(loot_match('Passed Blade', 4).link, { allPassed = true, list = {} }, false)
	LT:LootFeedPush(a); LT:LootFeedPush(b)
	local la, lb = line_of(a), line_of(b)
	eq(la.rightText:GetText(), LT.RollResultText(a.rolls), 'the line shows the text built from the rolls')
	local keep = { colors.class.WARRIOR:GetRGB() }
	set(colors.class.WARRIOR, 0.1, 0.2, 0.3)
	st:ColorChanged('class', 'WARRIOR')
	eq(la.rightText:GetText():match('^|cff(%x%x%x%x%x%x)'), hex(0.1, 0.2, 0.3), "a shown line's winner follows Class")
	check(la.rightText:GetText():find('Winner', 1, true), 'and still names the winner')
	local pkeep = { colors.loot.pass:GetRGB() }
	set(colors.loot.pass, 0.4, 0.5, 0.6)
	st:ColorChanged('loot', 'pass')
	eq(lb.rightText:GetText():match('^|cff(%x%x%x%x%x%x)'), hex(0.4, 0.5, 0.6), 'All passed follows Loot > Pass')
	-- A line drawn later takes the current colors, and a restored one (saved with
	-- its rolls, and an older save's baked text) does too.
	wipe(LT:GetHistoryStore().feed)
	a.saved = nil
	LT:SaveFeedEntry(a)
	set(colors.class.WARRIOR, 0.7, 0.8, 0.9)
	wipe(LT:GetAllItems())
	LT.feedRestored = false
	LT:RestoreFeed()
	local restored = LT:GetAllItems()[1]
	restored.time = GetTime()
	LT:GetFilteredItems(); LT:UpdateFeed()
	local line
	for _, l in ipairs(shown_lines()) do if l.info == restored then line = l end end
	eq(line.rightText:GetText():match('^|cff(%x%x%x%x%x%x)'), hex(0.7, 0.8, 0.9), 'a restored line is colored as it draws, not as it was saved')
	set(colors.class.WARRIOR, unpack(keep)); st:ColorChanged('class', 'WARRIOR')
	set(colors.loot.pass, unpack(pkeep)); st:ColorChanged('loot', 'pass')
	wipe(LT:GetHistoryStore().feed)
end)

test("a roll result's right text follows a new roll summary (a late result) and a Class change of another class leaves it", function()
	wipe(LT:GetAllItems())
	local a = LT:BuildRollEntry(loot_match('Late Blade', 4).link, winner_rolls(), false)
	LT:LootFeedPush(a)
	local line = line_of(a)
	local before = line.rightText:GetText()
	a.rolls.list[1].class = 'MAGE'
	LT:ColorFeed('class', 'WARRIOR')
	eq(line.rightText:GetText(), before, 'a Warrior change does not recolor a Mage winner as a Warrior')
	LT:ColorFeed('class', 'MAGE')
	check(line.rightText:GetText() ~= before, 'a Mage change reaches a Mage winner')
end)

test('a roll result with no, an unknown or a non-string class shows the plain name; with no winner it shows nothing', function()
	local function w(class) return { list = { { name = 'Nobody', class = class, state = LT.ROLL_STATE.Greed, roll = 3 } }, winner = 1 } end
	eq(LT.RollResultText(w(nil)), 'Nobody', 'no class')
	eq(LT.RollResultText(w('NOTACLASS')), 'Nobody', 'an unknown class')
	eq(LT.RollResultText(w(7)), 'Nobody', 'a number for a class (a hand-edited save)')
	eq(LT.RollResultText({}), '', 'no winner')
	eq(LT.RollResultText({ list = {}, winner = 4 }), '', 'a winner index past the list')
	eq(LT.RollResultUses(w('WARRIOR'), 'class', 'MAGE'), false, 'a Mage pass does not reach a Warrior winner')
	eq(LT.RollResultUses({ allPassed = true }, 'class', nil), false, 'All passed is not Class')
	eq(LT.RollResultUses({ allPassed = true }, 'loot', 'greed'), false, 'and not Greed')
end)

test('an older save with both a baked rightText and rolls draws from the rolls; a Loot entry draws its rightText', function()
	wipe(LT:GetAllItems())
	wipe(LT:GetHistoryStore().feed)
	local link = loot_match('Old Blade', 4).link
	tinsert(LT:GetHistoryStore().feed, { name = 'Old Blade', plain = 'Old Blade', quality = 4, type = 'Rolls', link = link, when = 5,
		rightText = '|cff000000Baked|r', rolls = winner_rolls() })
	tinsert(LT:GetHistoryStore().feed, { name = 'Looted Blade', plain = 'Looted Blade', quality = 4, type = 'Loot', link = link, when = 4,
		rightText = 'Someone' })
	LT.feedRestored = false
	LT:RestoreFeed()
	for _, e in ipairs(LT:GetAllItems()) do e.time = GetTime() end
	LT:GetFilteredItems(true); LT:UpdateFeed()
	local got = {}
	for _, l in ipairs(shown_lines()) do got[l.info.plain or l.info.name or '?'] = l.rightText:GetText() end
	eq(got['Old Blade'], LT.RollResultText(winner_rolls()), 'the old baked text is not what draws')
	eq(got['Looted Blade'], 'Someone', "a Loot entry's looter name")
	wipe(LT:GetHistoryStore().feed)
end)

test('two roll results of the same item never merge, with the same winner or another', function()
	wipe(LT:GetAllItems())
	local link = loot_match('Twin Blade', 4).link
	local other = winner_rolls(); other.list[1].name = 'Other'
	for _, rolls in ipairs({ winner_rolls(), winner_rolls(), other }) do
		LT:LootFeedPush(LT:BuildRollEntry(link, rolls, false))
	end
	eq(#LT:GetAllItems(), 3, 'three entries')
end)

test("a drop that changes after its result was recorded draws its new winner on the line (RefreshResult)", function()
	wipe(LT:GetAllItems()); wipe(LT:GetHistoryStore().feed)
	local S = LT.ROLL_STATE
	local match = loot_match('Late Blade', 4)
	local drop = { lootListKey = 3, itemHyperlink = match.link, startTime = 0, duration = 600000, winner = { playerName = 'Aa' },
		rollInfos = { { playerName = 'Aa', playerClass = 'WARRIOR', state = S.Greed, roll = 50 },
			{ playerName = 'Bb', playerClass = 'MAGE', state = S.Greed, roll = 40 } } }
	local real = C_LootHistory
	C_LootHistory = { GetSortedInfoForDrop = function() return drop end, GetAllEncounterInfos = function() return {} end,
		GetLootHistoryTime = function() return 0 end }
	local ok, err = pcall(function()
		LT:OnLootHistoryUpdateDrop('LOOT_HISTORY_UPDATE_DROP', 9, 3)
		local entry = LT:GetAllItems()[1]
		check(entry, 'the result is in the feed')
		local line = line_of(entry)
		check(line.rightText:GetText():find('Aa', 1, true), 'Aa wins')
		drop.winner = { playerName = 'Bb' }
		LT:OnLootHistoryUpdateDrop('LOOT_HISTORY_UPDATE_DROP', 9, 3)
		check(line.rightText:GetText():find('Bb', 1, true), 'the line now names Bb')
		eq(#LT:GetAllItems(), 1, 'still one entry')
	end)
	C_LootHistory = real
	if not ok then error(err, 0) end
end)

test('a save and restore round trip: the restored lines follow Item quality and Reputation; an older save shows its name', function()
	wipe(LT:GetAllItems())
	wipe(LT:GetHistoryStore().feed)
	reputation_world(false)
	local match = loot_match('Saved Epic', 4)
	LT:LootFeedAddItem(match)
	LT:LootFeedAddReputation({ faction = 'Stormwind', count = 10 })
	-- An older save: no plain name, no quality.
	tinsert(LT:GetHistoryStore().feed, { name = '|cffff0000Old Item|r', type = 'Loot', icon = 1, when = 1 })
	wipe(LT:GetAllItems())
	LT.feedRestored = false
	LT:RestoreFeed()
	eq(#LT:GetAllItems(), 3, 'all three come back')
	local item, rep, old
	for _, info in ipairs(LT:GetAllItems()) do
		if info.plain == 'Saved Epic' then item = info
		elseif info.progress then rep = info
		else old = info end
	end
	check(item and item.quality == 4, 'the item keeps its plain name and quality')
	check(rep and rep.progress.colorGroup == 'reaction' and rep.progress.colorKey == 5, 'the bar keeps the color it names')
	check(old and old.plain == nil, 'the older save has no plain name')
	local item_line, rep_line, old_line = line_of(item), line_of(rep), line_of(old)
	eq(old_line.text:GetText(), '|cffff0000Old Item|r', 'the older line shows its saved name')

	local keep, rkeep = { colors.item_quality[4]:GetRGB() }, { colors.reaction[5]:GetRGB() }
	set(colors.item_quality[4], 0.25, 0.5, 0.75)
	set(colors.reaction[5], 0.1, 0.9, 0.2)
	st:ColorChanged('item_quality', 4)
	st:ColorChanged('reaction', 5)
	eq(name_color(item_line.text:GetText()), hex(0.25, 0.5, 0.75), 'the restored item follows Item quality')
	eq(rgb(rep_line.progressBar:GetStatusBarColor()), rgb(0.1, 0.9, 0.2), 'the restored bar follows Reputation')
	eq(old_line.text:GetText(), '|cffff0000Old Item|r', 'the older line does not follow, and nothing errored')
	set(colors.item_quality[4], unpack(keep))
	set(colors.reaction[5], unpack(rkeep))
	C_Reputation, C_MajorFactions = nil, nil
	wipe(LT:GetHistoryStore().feed)
end)

test('the same item looted twice merges after a pick changed its color', function()
	wipe(LT:GetAllItems())
	local match = loot_match('Twice Looted', 4)
	LT:LootFeedAddItem(match)
	local keep = { colors.item_quality[4]:GetRGB() }
	set(colors.item_quality[4], 0.25, 0.5, 0.75)
	LT:LootFeedAddItem(match)
	set(colors.item_quality[4], unpack(keep))
	eq(#LT:GetAllItems(), 1, 'one entry')
	eq(LT:GetAllItems()[1].count, 2, 'with a count of two')
end)

------------------------------------------------------------------ the cost

test('a pass makes nothing and allocates under 4 KB over 100', function()
	local frames = {}
	for i = 1, 4 do frames[i] = skinned() end
	fill_feed()
	local roll = { rollID = frames[1].rollID, choice = 'Need', ends = GetTime() + 30, length = 60,
		link = GetLootRollItemLink(), item = 'item:19019' }
	local bar = LT:HoldRoll(frames[1], roll)
	-- Two roll results in the feed: a winner and All passed.
	local won = LT:BuildRollEntry(loot_match('Cost Won', 4).link, winner_rolls(), false)
	local passed = LT:BuildRollEntry(loot_match('Cost Passed', 4).link, { allPassed = true, list = {} }, false)
	LT:LootFeedPush(won); LT:LootFeedPush(passed)
	line_of(won)
	local passes = {
		{ 'loot', 'need' }, { 'loot', 'mount' }, { 'item_quality', 4 }, { 'item_quality', 3 },
		{ 'reaction', 5 }, { 'renown' }, { 'accent' }, { 'loot', 'pass' }, { 'class', 'WARRIOR' }, { 'class' },
	}
	-- Each color once first: a stub widget's first color call makes its table.
	for _, p in ipairs(passes) do st:ColorChanged(p[1], p[2]) end
	eq(pass('class', 'WARRIOR').by.SetText, 1, 'a Class pass sets only the winner line\'s text')
	eq(pass('loot', 'pass').by.SetText, 1, 'and Loot > Pass only the All passed line')
	for _, p in ipairs(passes) do
		local m = C.measure(function() st:ColorChanged(p[1], p[2]) end, 100)
		C.print(p[1] .. ' ' .. tostring(p[2]), m)
		check(m.kb < 4, ('%s %s: %.1f KB over 100 passes'):format(p[1], tostring(p[2]), m.kb))
		eq(m.forbidden.total, 0, p[1] .. ' ' .. tostring(p[2]) .. ': nothing forbidden')
		eq(m.made, 0, p[1] .. ' ' .. tostring(p[2]) .. ': nothing made')
	end
	-- A drag (a new color each pass) sets each line's new text: the strings are
	-- made, which a line's SetText may; nothing else is.
	local n, epic_keep = 0, { colors.item_quality[4]:GetRGB() }
	local m = C.measure(function()
		n = n + 1
		set(colors.item_quality[4], (n % 100) / 100, 0.5, 0.5)
		st:ColorChanged('item_quality', 4)
	end, 100)
	print(('  a drag of Item quality > Epic: %.1f KB over 100 passes'):format(m.kb))
	eq(m.forbidden.total, 0, 'a drag: nothing forbidden'); eq(m.made, 0, 'a drag: nothing made')
	set(colors.item_quality[4], unpack(epic_keep))
	LT:ReleaseHeldRoll(bar)
end)
