-- SaftUI-Loot's colors, read from Colors > Loot and no longer from Colors >
-- Text or Buttons:
--   - each roll button's letter, the paired counts and the feed's roll tooltip
--     (rollbar.lua, roll.lua, rollinfo.lua, Feed/rolls.lua);
--   - a mount's entry in the feed (Feed/feed.lua).
-- A changed Text > Danger, Caution or Strong reaches none of them.
--
-- Real: SaftUI-Loot's config.lua, init.lua, rollbar.lua, roll.lua, rolltest.lua,
-- rollinfo.lua and Feed/history.lua, parse.lua, feed.lua, loothistory.lua and
-- rolls.lua, filter.lua and progress.lua, Core's helpers and Core's Utilities.
load_core_helpers()
local T = load_test_file('lib/theme_helpers.lua')
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
st.config.char = {} -- AceDB's per-character table; the shell has none
local colors = st.config.profile.colors

-- Stands in for LibStringFormat-1.0 (SaftUI-Core/init.lua takes it from LibStub):
-- ToClock as m:ss and ColorString as a |cff color code. The real one does more.
local function byte(v) return math.floor(v * 255 + 0.5) end
st.StringFormat = {
	ToClock = function(_, sec) return ('%d:%02d'):format(sec / 60, sec % 60) end,
	ColorString = function(_, text, r, g, b) return ('|cff%02x%02x%02x%s|r'):format(byte(r), byte(g), byte(b), text) end,
}
function ClearItemCraftingQualityOverlay(button) end

local RED, YELLOW, PURPLE, WHITE = T.rgb(220/255, 100/255, 100/255), T.rgb(200/255, 200/255, 100/255),
	T.rgb(197/255, 128/255, 1), T.rgb(1, 1, 1)

local counter = 0
-- A GroupLootFrame as Blizzard builds it on Forever (tests/loot/roll_skin_test.lua
-- has the full one), hidden, with a Transmog button too.
local function roll_frame()
	counter = counter + 1
	local name = 'GroupLootFrame' .. counter
	local frame = CreateFrame('Frame', name, UIParent)
	frame:Hide()
	frame.IconFrame = CreateFrame('Frame', nil, frame)
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
	local container = CreateFrame('Frame', nil, frame)
	frame.LootButtonContainer = container
	for _, button in ipairs({ 'Pass', 'Greed', 'Transmog', 'Need' }) do
		container[button .. 'Button'] = CreateFrame('Button', nil, container)
	end
	return frame
end

-- Each button's letter, as its vertex color: the one font string centered on it.
local function letters(frame)
	local out = {}
	for _, name in ipairs({ 'Pass', 'Greed', 'Transmog', 'Need' }) do
		for _, region in ipairs({ frame.LootButtonContainer[name .. 'Button']:GetRegions() }) do
			if region:GetObjectType() == 'FontString' and region:GetNumPoints() == 1 and region:GetPoint(1) == 'CENTER' then
				out[name] = T.rgb(region:GetVertexColor())
			end
		end
	end
	return out
end

-- Sets a color's channels in place, so the profile's own object stays.
local function set(color, r, g, b) color.r, color.g, color.b = r, g, b end

test('each roll letter takes its Loot color, and a changed Text color reaches none of them', function()
	local l = letters((function() local f = roll_frame(); LT:SkinRollFrame(f); return f end)())
	eq(l.Pass, RED, 'Pass'); eq(l.Greed, YELLOW, 'Greed'); eq(l.Transmog, PURPLE, 'Transmog'); eq(l.Need, WHITE, 'Need')

	local text = { danger = { colors.text.danger:GetRGB() }, caution = { colors.text.caution:GetRGB() }, strong = { colors.text.strong:GetRGB() } }
	for key in pairs(text) do set(colors.text[key], 0, 0, 0) end
	local frame = roll_frame(); LT:SkinRollFrame(frame)
	l = letters(frame)
	eq(l.Pass, RED, 'Pass, with Text > Danger changed'); eq(l.Greed, YELLOW, 'Greed, with Text > Caution changed')
	eq(l.Need, WHITE, 'Need, with Text > Strong changed')
	for key, rgb in pairs(text) do set(colors.text[key], unpack(rgb)) end

	local pass = { colors.loot.pass:GetRGB() }
	set(colors.loot.pass, 0, 1, 0)
	frame = roll_frame(); LT:SkinRollFrame(frame)
	eq(letters(frame).Pass, T.rgb(0, 1, 0), 'the next skinned Pass letter takes the changed Loot > Pass')
	set(colors.loot.pass, unpack(pass))
end)

-- A counts table with a bottom right and a top right number per button, the
-- way a roll bar's buttons make them (LT:CreateRollCounts).
local function counts_for(name)
	local counts = {}
	local button = CreateFrame('Frame', nil, UIParent)
	LT:CreateRollCounts(counts, button, name)
	return counts
end

local function paired_color(counts)
	for text, count in pairs(counts) do
		if count.color then return text end
	end
end

test("the paired counts and the feed's roll tooltip read Loot: All passed and Pass: in Pass", function()
	local S = LT.ROLL_STATE
	local rolls = { list = { { name = 'Aa', state = S.Greed }, { name = 'Bb', state = S.Transmog } } }

	-- Greed's bar also counts Transmog's picks, in Transmog's color, and the other way round.
	set(colors.text.caution, 0, 0, 0)
	local greed = counts_for('Greed')
	LT:SetRollCounts(greed, rolls)
	eq(T.rgb(paired_color(greed):GetTextColor()), PURPLE, "Greed's bar: Transmog's count in Loot > Transmog")
	local transmog = counts_for('Transmog')
	LT:SetRollCounts(transmog, rolls)
	eq(T.rgb(paired_color(transmog):GetTextColor()), YELLOW, "Transmog's bar: Greed's count in Loot > Greed, not Text > Caution")
	set(colors.text.caution, 200/255, 200/255, 100/255)

	-- The tooltip: the headers in their Loot colors, All passed and Pass: in Pass.
	local lines = {}
	local tooltip = {
		AddLine = function(_, text, r, g, b) lines[#lines + 1] = { text = text, r = r, g = g, b = b } end,
		AddDoubleLine = function() end,
	}
	local text = { colors.text.danger:GetRGB() }
	set(colors.text.danger, 0, 0, 0)
	-- Need shares Strong's default (White's) and Greed Caution's (Yellow's): move both away.
	local keep_strong, keep_caution = { colors.text.strong:GetRGB() }, { colors.text.caution:GetRGB() }
	set(colors.text.strong, 0, 0, 0); set(colors.text.caution, 0, 0, 0)

	-- The feed line's right side, "All passed", in Loot > Pass too.
	C_Item = { GetItemInfo = function() end, GetItemInfoInstant = function() return 1, 'Armor', 'Cloth', nil, 134400 end }
	local entry = LT:BuildRollEntry('item:1', { allPassed = true }, true)
	check(entry and entry.rightText:find('^|cffdc6464All passed|r$'), 'the feed line: ' .. tostring(entry and entry.rightText))

	LT:AddRollLines(tooltip, { allPassed = true }, false)
	eq(lines[#lines].text, 'All passed'); eq(T.rgb(lines[#lines].r, lines[#lines].g, lines[#lines].b), RED, 'All passed in Loot > Pass')

	lines = {}
	local list = { { name = 'Aa', state = S.NeedMainSpec }, { name = 'Bb', state = S.Transmog },
		{ name = 'Cc', state = S.Greed }, { name = 'Dd', state = S.Pass } }
	LT:AddRollLines(tooltip, { list = list }, false)
	local seen = {}
	for _, line in ipairs(lines) do
		if line.r then seen[line.text] = T.rgb(line.r, line.g, line.b) end
	end
	eq(seen.Need, WHITE, 'Need'); eq(seen.Transmog, PURPLE, 'Transmog'); eq(seen.Greed, YELLOW, 'Greed')
	set(colors.text.strong, unpack(keep_strong)); set(colors.text.caution, unpack(keep_caution))
	local passed
	for _, line in ipairs(lines) do
		if line.text:find('Pass: ', 1, true) then passed = line.text end
	end
	check(passed and passed:find('^|cffdc6464Pass: |r'), 'Pass: in Loot > Pass, not the changed Text > Danger: ' .. tostring(passed))

	-- The winner's line stays Text > Success (not a Loot color).
	local doubles = {}
	tooltip.AddDoubleLine = function(_, _, _, _, _, _, r, g, b) doubles[#doubles + 1] = T.rgb(r, g, b) end
	local green = { colors.text.success:GetRGB() }
	set(colors.text.success, 0.1, 0.2, 0.3)
	local winning = { { name = 'Aa', state = S.NeedMainSpec, roll = 50 } }
	LT:AddRollLines(tooltip, { list = winning, winner = 1 }, false)
	eq(doubles[1], T.rgb(0.1, 0.2, 0.3), "the winner's roll in Text > Success")
	set(colors.text.success, unpack(green))

	set(colors.text.danger, unpack(text))
	local pass = { colors.loot.pass:GetRGB() }
	set(colors.loot.pass, 0, 1, 0)
	lines = {}
	LT:AddRollLines(tooltip, { allPassed = true }, false)
	eq(T.rgb(lines[#lines].r, lines[#lines].g, lines[#lines].b), T.rgb(0, 1, 0), 'a changed Loot > Pass reaches All passed')
	set(colors.loot.pass, unpack(pass))
end)

-- The feed as InitializeLootFeed makes it before its lines (tests/loot/theme_test.lua).
local function make_feed()
	GameTooltip = GameTooltip or CreateFrame('GameTooltip', 'GameTooltip', UIParent)
	st.OptionsWidgets = st.OptionsWidgets or { ListOwner = function() end }
	local feed = CreateFrame('Frame', 'SaftUILootFeed', UIParent)
	feed:SetSize(400, 20)
	feed.items, feed.offset = {}, 0
	feed.overlay = CreateFrame('Frame', nil, feed)
	LT.feed = feed
	LT:CreateFeedButtons()
	LT.debugText = st:CreateFontString(feed, 'normal', '0/0')
	LT:UpdateLootFeedConfig()
	return feed
end

test("a mount's feed entry: border and icon border in Loot > Mount, its fill at 60%", function()
	local feed = make_feed()
	wipe(LT:GetAllItems())
	stub.time = 100
	local stack = LT:GetAllItems()
	tinsert(stack, { name = 'Swift Razzashi Raptor', type = 'Loot', icon = 1, itemSubType = 'Mount', time = 100 })
	LT:GetFilteredItems()
	LT:UpdateFeed()
	local mount = feed.items[1]
	check(mount:IsShown(), 'the entry shows')

	local want = T.text(colors.loot.mount:GetRGB())
	eq(T.edge(mount.backdrop), want .. ',1.00', 'the border')
	eq(T.fill(mount.backdrop), want .. ',0.60', 'the fill, at 60%')
	eq(T.edge(mount.icon.backdrop), want .. ',1.00', "the icon's border")

	set(colors.loot.mount, 0.2, 0.3, 0.4)
	LT:UpdateFeed()
	local other = T.text(0.2, 0.3, 0.4)
	eq(T.edge(mount.backdrop), other .. ',1.00', 'a changed Loot > Mount reaches the next draw: border')
	eq(T.fill(mount.backdrop), other .. ',0.60', 'fill')
	eq(T.edge(mount.icon.backdrop), other .. ',1.00', "and the icon's border")
end)
