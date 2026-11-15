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

local function byte(v) return math.floor(v * 255 + 0.5) end
st.StringFormat = {
	ToClock = function(_, sec) return ('%d:%02d'):format(sec / 60, sec % 60) end,
	ColorString = function(_, text, r, g, b) return ('|cff%02x%02x%02x%s|r'):format(byte(r), byte(g), byte(b), text) end,
}
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

local function skinned(shown)
	local frame = roll_frame()
	LT:SkinRollFrame(frame)
	frame:Show()
	if shown ~= false then LT:GroupLootFrame_OnShow(frame) end
	return frame
end

------------------------------------------------------------------ the rolls

test("Loot > Need: each roll frame's Need letter and the shown Need counts; Greed's untouched", function()
	local a, b = skinned(), skinned()
	local keep = { colors.loot.need:GetRGB() }
	set(colors.loot.need, 0.1, 0.2, 0.3)
	st:ColorChanged('loot', 'need')
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
	LT.rollPreview = LT.rollPreview or { bars = {}, IsShown = function() return false end }
	tinsert(LT.rollPreview.bars, bar)
	local keep = { colors.loot.transmog:GetRGB() }
	set(colors.loot.transmog, 0.9, 0.8, 0.1)
	st:ColorChanged('loot', 'transmog')
	eq(rgb(shown_paired:GetTextColor()), rgb(0.9, 0.8, 0.1), "the shown count of Transmog's picks")
	eq(rgb(other_paired:GetTextColor()), rgb(colors.loot.greed:GetRGB()), "Greed's count is as it was")
	set(colors.loot.transmog, unpack(keep))
	st:ColorChanged('loot', 'transmog')
	LT.rollPreview.bars = {}
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

-- 16 lines: 6 epic items, 4 rare, 2 mounts (epic), 3 reputation lines at Friendly, 1 renown.
local function fill_feed()
	wipe(LT:GetAllItems())
	stub.time = 100
	LT.config.feed.fade_time = 600
	for i = 1, 6 do LT:LootFeedAddItem(loot_match('Epic ' .. i, 4)) end
	for i = 1, 4 do LT:LootFeedAddItem(loot_match('Rare ' .. i, 3)) end
	for i = 1, 2 do LT:LootFeedAddItem(loot_match('Mount ' .. i, 4, 'Mount')) end
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
local function hex(r, g, b) return ('%02x%02x%02x'):format(byte(r), byte(g), byte(b)) end

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
	eq(#lines, 16, 'sixteen lines are shown')
	local before = {}
	for i, line in ipairs(lines) do before[i] = line.text:GetText() end
	local keep = { colors.item_quality[4]:GetRGB() }
	set(colors.item_quality[4], 0.25, 0.5, 0.75)
	st:ColorChanged('item_quality', 4)
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
	eq(same, 8, 'the rest, reputation lines included')
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
	for _, line in ipairs(rep) do eq(rgb(line.progressBar:GetStatusBarColor()), rgb(0.1, 0.9, 0.2), 'a Friendly bar') end
	eq(rgb(renown.progressBar:GetStatusBarColor()), renown_before, "the renown bar is as it was")
	set(colors.reaction[5], unpack(keep))
	st:ColorChanged('reaction', 5)

	local rkeep = { colors.renown.r, colors.renown.g, colors.renown.b }
	set(colors.renown, 0.3, 0.2, 0.9)
	st:ColorChanged('renown')
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

------------------------------------------------------------------ the cost

test('a pass makes nothing and allocates under 4 KB over 100', function()
	local frames = {}
	for i = 1, 4 do frames[i] = skinned() end
	fill_feed()
	local roll = { rollID = frames[1].rollID, choice = 'Need', ends = GetTime() + 30, length = 60,
		link = GetLootRollItemLink(), item = 'item:19019' }
	local bar = LT:HoldRoll(frames[1], roll)
	local passes = {
		{ 'loot', 'need' }, { 'loot', 'mount' }, { 'item_quality', 4 }, { 'item_quality', 3 },
		{ 'reaction', 5 }, { 'renown' }, { 'accent' },
	}
	-- Each color once first: a stub widget's first color call makes its table.
	for _, p in ipairs(passes) do st:ColorChanged(p[1], p[2]) end
	for _, p in ipairs(passes) do
		local m = C.measure(function() st:ColorChanged(p[1], p[2]) end, 100)
		C.print(p[1] .. ' ' .. tostring(p[2]), m)
		check(m.kb < 4, ('%s %s: %.1f KB over 100 passes'):format(p[1], tostring(p[2]), m.kb))
		eq(m.forbidden.total, 0, p[1] .. ' ' .. tostring(p[2]) .. ': nothing forbidden')
		eq(m.made, 0, p[1] .. ' ' .. tostring(p[2]) .. ': nothing made')
	end
	LT:ReleaseHeldRoll(bar)
end)
