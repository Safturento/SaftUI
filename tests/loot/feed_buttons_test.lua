-- The loot feed's two buttons (SaftUI-Loot/Feed/feed.lua, filter.lua): the filter
-- button and the jump to the newest entry are Lucide icons with tooltips (not the
-- letters F and V); they show while an entry is on the feed, at the alpha of the
-- most visible one (so they fade out with the last), or while the mouse is over the
-- feed's area (the feed, the strip its buttons sit in, or a button) or the filter
-- menu is open, at full alpha, and the jump button only while the feed is scrolled
-- back; a faded-out button is hidden and takes no mouse; and the filter menu is
-- the options kit's check list, not Blizzard's menu. Both looks.
--
-- Real: SaftUI-Loot's config.lua, init.lua, Feed/history.lua, parse.lua, feed.lua,
-- filter.lua and progress.lua, Core's helpers, the theme engine, Core's Utilities,
-- and the options window's model, widgets and body (the check list, W.OpenCheckList,
-- and its list frames). Made by hand: the feed frame as InitializeLootFeed makes it
-- before its lines (the rest registers events and a mover), and LT:UpdateFeed, which
-- draws lines this file doesn't build: it refreshes the filtered list and counts.
-- The mouse is the stub's cursor (stub.cursor_x, stub.cursor_y), and OnUpdate is
-- fired by hand.
load_core_helpers()
local T = load_test_file('lib/theme_helpers.lua')
local drawn = T.watch()
load_saftui('SaftUI-Core/skinning.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_saftui('SaftUI-Core/Utilities/utilities.lua')
load_saftui('SaftUI-Loot/config.lua')
apply_defaults()
load_saftui('SaftUI-Loot/init.lua')
load_saftui('SaftUI-Loot/Feed/history.lua')
load_saftui('SaftUI-Loot/Feed/parse.lua')
load_saftui('SaftUI-Loot/Feed/feed.lua')
load_saftui('SaftUI-Loot/Feed/filter.lua')
load_saftui('SaftUI-Loot/Feed/progress.lua')

local st = SaftUI
local W = st.OptionsWidgets
local LT = st.Loot
st:BindModuleConfig(LT, 'loot')
st.config.char = {}
local profile = st.config.profile
local config = LT.config.feed

GameTooltip = GameTooltip or CreateFrame('GameTooltip', 'GameTooltip', UIParent)

-- The fade of an entry that ran out (UpdateFeedVisibility): Blizzard's, not under test.
function UIFrameFadeOut(frame) frame.fadeInfo = {} end

local updates = 0
function LT:UpdateFeed()
	updates = updates + 1
	self:GetFilteredItems()
end

local feed
local function make_feed()
	feed = CreateFrame('Frame', 'SaftUILootFeed', UIParent)
	feed:SetSize(400, 20)
	feed.items, feed.offset = {}, 0
	feed.overlay = CreateFrame('Frame', nil, feed)
	LT:HookScript(feed, 'OnUpdate', 'UpdateFeedVisibility') -- as InitializeLootFeed does
	LT.feed = feed
	LT.debugText = st:CreateFontString(feed, 'normal', '0/0')
	LT:CreateFeedButtons()
	LT:UpdateLootFeedConfig()
	return feed
end

local function reset()
	W.CloseList()
	wipe(LT:GetAllItems())
	feed.offset = 0
	for _, item in ipairs(feed.items) do
		item:Hide()
		item:SetAlpha(1)
		item.fadeInfo = nil
	end
	stub.time = 1000
	config.fade_time = 10
	for key in pairs(config.filters) do config.filters[key] = true end
	config.filters.Self = false
	stub.cursor_x, stub.cursor_y = 0, 0 -- the corner: nowhere near the feed
	LT:GetFilteredItems()
	LT:UpdateFeedButtons()
end

-- The cursor is in screen pixels, a frame's rect in its own units.
local function cursor_at(x, y)
	local scale = UIParent:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = x * scale, y * scale
end

-- Puts the cursor at the middle of a frame.
local function mouse_on(frame)
	cursor_at(frame:GetCenter())
end

-- One frame passes: the feed's OnUpdate.
local function frame_passes()
	stub.fire_script(feed, 'OnUpdate', 0.016)
end

local function shown(button) return button:IsShown() and true or false end
local function rgb(r, g, b) return ('%.2f,%.2f,%.2f'):format(r, g, b) end
local function tint(button) return rgb(button.icon:GetVertexColor()) end

make_feed()
local filterButton, jumpButton = feed.filterButton, feed.reset_button

------------------------------------------------------------------ the buttons

test('a feed button made by CreateFeedIconButton alone hovers (its own SetScript keeps the hover)', function()
	reset()
	local lone = LT:CreateFeedIconButton('SaftUITestLoneFeedButton', st.icons.funnel)
	stub.fire_script(lone, 'OnEnter', true)
	eq(st:GetState(lone, 'hover'), true)
	stub.fire_script(lone, 'OnLeave', true)
	eq(st:GetState(lone, 'hover'), false)
end)

test('the filter button is the funnel and the jump button the arrow, 16 px icons on 20 px buttons, no letters', function()
	reset()
	eq(filterButton.icon:GetTexture(), st.icons.funnel, "Lucide's funnel")
	eq(jumpButton.icon:GetTexture(), st.icons.arrowDownToLine, "Lucide's arrow-down-to-line")
	check(st.icons.funnel:find('lucide-', 1, true) and st.icons.arrowDownToLine:find('lucide-', 1, true), 'both are registered Lucide files')
	for name, button in pairs({ filter = filterButton, jump = jumpButton }) do
		eq(button:GetWidth() .. 'x' .. button:GetHeight(), '20x20', name .. ': 20 by 20')
		eq(button.icon:GetWidth() .. 'x' .. button.icon:GetHeight(), '16x16', name .. ': a 16 px icon')
		eq(button.text:GetText() or '', '', name .. ': no letter')
	end
end)

test('an icon is tinted as the theme text is, the lighter tone under the mouse, and follows a Colors -> Text change', function()
	reset()
	local colors = profile.colors.text
	local lighter = rgb(st:StateColor('edgeHover'))
	eq(tint(filterButton), rgb(colors.normal:GetRGB()), 'filter: the text color at rest')
	stub.fire_script(filterButton, 'OnEnter', true)
	eq(tint(filterButton), lighter, 'filter: the lighter tone under the mouse')
	stub.fire_script(filterButton, 'OnLeave', true)
	eq(tint(filterButton), rgb(colors.normal:GetRGB()), 'filter: back at rest')

	stub.fire_script(jumpButton, 'OnEnter', true)
	eq(tint(jumpButton), lighter, 'jump: the lighter tone under the mouse')
	stub.fire_script(jumpButton, 'OnLeave', true)
	eq(tint(jumpButton), rgb(colors.normal:GetRGB()), 'jump: back at rest')

	local saved = colors.normal
	colors.normal = CreateColor(0.25, 0.5, 0.75, 1)
	LT:ColorFeed('text')
	eq(tint(filterButton), '0.25,0.50,0.75', 'a new Text -> Normal reaches the filter icon')
	eq(tint(jumpButton), '0.25,0.50,0.75', 'and the jump icon')
	colors.normal = saved
	LT:ColorFeed('text')
end)

test('a hovered feed button follows an accent change at once (the states\' own pass)', function()
	reset()
	stub.fire_script(filterButton, 'OnEnter', true)
	eq(tint(filterButton), rgb(st:StateColor('edgeHover')), 'the lighter tone')
	local accent = profile.theme.accent
	accent:SetRGB(0.9, 0.1, 0.2)
	st:ColorsChanged('accent')
	eq(tint(filterButton), rgb(st:StateColor('edgeHover')), 'the new accent\'s lighter tone, at once, through ColorsChanged')
	check(tint(filterButton) ~= '0.36,0.78,1.00', 'and not the old one')
	stub.fire_script(filterButton, 'OnLeave', true)
	eq(tint(filterButton), rgb(profile.colors.text.normal:GetRGB()), 'and back to the text color at rest')
	accent:SetRGB(0, 0.68, 0.94)
	st:ColorsChanged('accent')
end)

test('each button has a tooltip, above it, put away on leaving', function()
	reset()
	stub.fire_script(filterButton, 'OnEnter', true)
	check(GameTooltip:IsShown(), 'the filter button: a tooltip')
	eq(GameTooltip:GetOwner(), filterButton, 'owned by the button')
	eq(stub.state(GameTooltip).anchor, 'ANCHOR_TOP', 'above it, as the bags buttons')
	eq(stub.state(GameTooltip).texts[1], 'Filter the loot feed', 'its name')
	eq(GameTooltip:NumLines(), 2, 'and what it does')
	stub.fire_script(filterButton, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'gone when the mouse leaves')

	stub.fire_script(jumpButton, 'OnEnter', true)
	check(GameTooltip:IsShown(), 'the jump button: a tooltip')
	eq(GameTooltip:GetOwner(), jumpButton, 'owned by the button')
	eq(stub.state(GameTooltip).texts[1], 'Jump to the newest entry', 'its name')
	stub.fire_script(jumpButton, 'OnLeave', true)
	check(not GameTooltip:IsShown(), 'gone when the mouse leaves')
end)

test('a button that hides under the mouse puts its tooltip and its lit icon away', function()
	reset()
	filterButton:Show()
	stub.fire_script(filterButton, 'OnEnter', true)
	filterButton:Hide() -- no OnLeave comes
	check(not GameTooltip:IsShown(), 'no tooltip left behind')
	eq(tint(filterButton), rgb(profile.colors.text.normal:GetRGB()), 'and the icon is at rest')
end)

------------------------------------------------------------------ where the mouse is

test('with the mouse away an empty feed shows no button, nor do entries that have gone from the screen', function()
	reset()
	frame_passes()
	check(not shown(filterButton), 'empty feed, mouse away: no filter button')
	check(not shown(jumpButton), 'and no jump button')

	tinsert(LT:GetAllItems(), { name = 'A', type = 'Loot', icon = 1, time = 0 })
	LT:GetFilteredItems()
	frame_passes()
	check(not shown(filterButton), 'an entry in the history but none on screen, mouse away: no filter button')
	check(not shown(jumpButton), 'and no jump button')
end)

test('the filter button shows while the mouse is over the feed, its entries, or the button, and goes with the mouse', function()
	reset()
	mouse_on(feed)
	frame_passes()
	check(shown(filterButton), 'over the feed')
	check(not shown(jumpButton), 'the jump button waits for a scrolled feed')

	local item = feed.items[1]
	check(item ~= nil, 'the feed has its lines')
	mouse_on(item)
	frame_passes()
	check(shown(filterButton), 'over an entry')

	mouse_on(filterButton)
	frame_passes()
	check(shown(filterButton), 'over the button itself, beside the feed')

	-- The gap between the feed and its button: crossing it must not lose the button.
	local gap = (feed:GetLeft() - filterButton:GetRight()) / 2
	check(gap > 0, 'a gap lies between them')
	cursor_at(filterButton:GetRight() + gap, select(2, filterButton:GetCenter()))
	frame_passes()
	check(shown(filterButton), 'in the gap between the feed and the button')

	stub.cursor_x, stub.cursor_y = 0, 0
	frame_passes()
	check(not shown(filterButton), 'the mouse gone: the button goes')
end)

test('the buttons sit on the far side of the feed when it is on the left of the screen, and the strip follows', function()
	reset()
	local saved = config.position
	config.position = { point = 'BOTTOMLEFT', frame = 'UIParent', rel_point = 'BOTTOMLEFT', x_off = 100, y_off = 100 }
	LT:UpdateLootFeedConfig()
	check(filterButton:GetLeft() >= feed:GetRight(), 'the button is right of the feed')
	mouse_on(filterButton)
	frame_passes()
	check(shown(filterButton), 'hovering it shows it')
	cursor_at(filterButton:GetRight() + 40, select(2, filterButton:GetCenter()))
	frame_passes()
	check(not shown(filterButton), 'a point past the button is not the feed')
	config.position = saved
	LT:UpdateLootFeedConfig()
end)

test('the jump button shows only while the feed is scrolled back and the mouse is on its area', function()
	reset()
	mouse_on(feed)
	feed.offset = 3
	frame_passes()
	check(shown(jumpButton), 'scrolled back, mouse on the feed: shown')
	check(shown(filterButton), 'with the filter button')

	mouse_on(jumpButton)
	frame_passes()
	check(shown(jumpButton), 'over the jump button itself')

	stub.cursor_x, stub.cursor_y = 0, 0
	frame_passes()
	check(not shown(jumpButton), 'the mouse gone and no entry on screen: the jump button goes, scrolled back or not')

	mouse_on(feed)
	feed.offset = 0
	frame_passes()
	check(not shown(jumpButton), 'at the newest entry: no jump button')
	check(shown(filterButton), 'the filter button stays')
end)

test('scrolling back with the mouse on the feed shows the jump button at once, and its click goes to the newest entry and puts it away', function()
	reset()
	for i = 1, 30 do tinsert(LT:GetAllItems(), { name = 'E' .. i, type = 'Loot', icon = 1, time = 100 }) end
	LT:GetFilteredItems()
	mouse_on(feed)
	feed.offset = 4 -- the wheel's handler (InitializeLootFeed's) sets it, then asks for the buttons
	LT:UpdateFeedButtons()
	check(shown(jumpButton), 'scrolled back with the mouse on the feed: shown without waiting for a frame')

	stub.click(jumpButton)
	eq(feed.offset, 0, 'the click goes back to the newest entry')
	check(not shown(jumpButton), 'and the jump button is put away')
end)

test('the filter menu being open keeps the filter button, and closing it lets the mouse decide again', function()
	reset()
	mouse_on(feed)
	frame_passes()
	stub.click(filterButton)
	eq(W.ListOwner(), feed.filterMenuAnchor, 'the menu is open')
	stub.cursor_x, stub.cursor_y = 0, 0 -- the mouse is on the menu, off the feed
	frame_passes()
	check(shown(filterButton), 'the filter button stays under its own menu')
	W.CloseList()
	frame_passes()
	check(not shown(filterButton), 'the menu closed and the mouse away: the button goes')
end)

------------------------------------------------------------------ with entries on the feed

-- A fresh entry on screen, as UpdateFeed draws it (the test's UpdateFeed draws no lines).
local function entry_on(i)
	tinsert(LT:GetAllItems(), i, { name = 'E' .. i, type = 'Loot', icon = 1, time = GetTime() })
	local item = feed.items[i]
	item.info = LT:GetFilteredItems()[i]
	item:SetAlpha(1)
	item:Show()
	return item
end

-- The entry on a line has run out of time: UpdateFeedVisibility leaves its alpha to
-- the fade (Blizzard's UIFrameFadeOut, which the test sets by hand), instead of
-- putting it back to full as it does a fresh one.
local function run_out(item) item.info.time = 0 end

local function alpha(button) return button:GetAlpha() end

test('an entry on screen shows the filter button with the mouse away, at full alpha, and a blank feed shows none', function()
	reset()
	frame_passes()
	check(not shown(filterButton), 'blank feed, mouse away: none')
	entry_on(1)
	frame_passes()
	check(shown(filterButton), 'one entry on screen: the filter button')
	eq(alpha(filterButton), 1, 'at full alpha')
	check(not shown(jumpButton), 'the jump button waits for a scrolled feed')
end)

test('the buttons fade with the last entry: their alpha is the highest entry alpha, and they are gone when it is', function()
	reset()
	local a, b = entry_on(1), entry_on(2)
	frame_passes()
	run_out(a)
	run_out(b)
	a:SetAlpha(.5)
	b:SetAlpha(.25)
	frame_passes()
	eq(alpha(filterButton), .5, 'the highest of the two')
	a:Hide() -- the first one is gone
	frame_passes()
	eq(alpha(filterButton), .25, 'then the last one: its alpha')
	b:SetAlpha(.1)
	frame_passes()
	eq(alpha(filterButton), .1, 'fading with it')
	b:SetAlpha(0)
	frame_passes()
	check(not shown(filterButton), 'at 0: the button is hidden')
	b:Hide()
	frame_passes()
	check(not shown(filterButton), 'and stays gone with the entry')
end)

test('an entry arriving brings the buttons back at once, at its alpha', function()
	reset()
	local a = entry_on(1)
	run_out(a)
	a:SetAlpha(.2)
	a:Hide()
	frame_passes()
	check(not shown(filterButton), 'faded out')
	entry_on(1) -- UpdateFeed draws it: full alpha, shown, then asks for the buttons
	LT:UpdateFeedButtons()
	check(shown(filterButton), 'back with no frame passing')
	eq(alpha(filterButton), 1, 'at full alpha')
end)

test('under the mouse or with the list open the buttons are at full alpha, whatever the entries are', function()
	reset()
	local a = entry_on(1)
	frame_passes()
	run_out(a)
	a:SetAlpha(.3) -- fading out
	frame_passes()
	eq(alpha(filterButton), .3, 'mouse away: the entry alpha')
	mouse_on(feed)
	frame_passes()
	eq(alpha(filterButton), 1, 'over the feed: full')
	stub.cursor_x, stub.cursor_y = 0, 0
	frame_passes()
	eq(alpha(filterButton), .3, 'the mouse gone: back to the entry alpha')
	stub.click(filterButton)
	frame_passes()
	eq(alpha(filterButton), 1, 'list open: full')
	W.CloseList()

	a:Hide()
	mouse_on(feed)
	frame_passes()
	check(shown(filterButton), 'blank feed, mouse over: shown')
	eq(alpha(filterButton), 1, 'at full alpha')
end)

test('the jump button shows while scrolled back with an entry on screen, and follows the same alpha', function()
	reset()
	local a = entry_on(1)
	feed.offset = 3
	frame_passes()
	check(shown(jumpButton) and shown(filterButton), 'scrolled back, entry on screen, mouse away: both')
	run_out(a)
	a:SetAlpha(.4)
	frame_passes()
	eq(alpha(jumpButton), .4, 'the jump button: the entry alpha')
	eq(alpha(filterButton), .4, 'the filter button too')
	feed.offset = 0
	frame_passes()
	check(not shown(jumpButton), 'at the newest entry: no jump button')
	check(shown(filterButton), 'the filter button stays')
	feed.offset = 3
	a:Hide()
	frame_passes()
	check(not shown(jumpButton) and not shown(filterButton), 'no entry on screen, mouse away: neither')
end)

test('a faded-out button takes no mouse and shows no tooltip, until it is visible again', function()
	reset()
	local a = entry_on(1)
	frame_passes()
	stub.fire_script(filterButton, 'OnEnter', true)
	check(GameTooltip:IsShown(), 'visible: its tooltip shows')
	run_out(a)
	a:SetAlpha(0)
	frame_passes()
	check(not shown(filterButton), 'faded out: hidden, which takes no mouse')
	check(not GameTooltip:IsShown(), 'and its tooltip is put away')
	a.info.time = GetTime() -- a new gain: fresh again
	frame_passes()
	check(shown(filterButton), 'visible again: back')
end)

test('Fade time 0 keeps the entries on screen, and the buttons stay as long as they do', function()
	reset()
	config.fade_time = 0
	local a = entry_on(1)
	frame_passes()
	check(shown(filterButton), 'an entry on screen: the buttons')
	stub.time = stub.time + 100000
	frame_passes()
	eq(alpha(a), 1, 'the entry never fades')
	check(shown(filterButton), 'and the buttons stay')
	eq(alpha(filterButton), 1, 'at full alpha')
	a:Hide()
	frame_passes()
	check(not shown(filterButton), 'the entry gone: so are the buttons')
	config.fade_time = 10
end)

------------------------------------------------------------------ the filter menu

local ORDER = { 'Self', 'Loot', 'Rolls', 'Gold', 'Currency', 'Skill', 'Experience', 'Reputation', 'Honor' }
local LABELS = { 'Self Only', 'Loot', 'Rolls', 'Gold', 'Currency', 'Skill ups', 'Experience', 'Reputation', 'Honor' }

local function rows()
	local lines = {}
	for _, row in ipairs(W.GetListFrames().rows) do
		if row:IsShown() then lines[#lines + 1] = row end
	end
	return lines
end

-- The filter button as the player clicks it: it shows while the mouse is over
-- the feed (a frame passes), so the click is one the game delivers.
local function click_filter()
	mouse_on(feed)
	frame_passes()
	stub.click(filterButton)
end

test("the filter button opens the options kit's check list with the nine entries, Self Only first", function()
	reset()
	click_filter()
	eq(W.ListOwner(), feed.filterMenuAnchor, "the kit's list is open, owned by the menu's anchor")
	local lines = rows()
	eq(#lines, 9, 'nine rows')
	for i, row in ipairs(lines) do
		eq(row.entry.key, ORDER[i], 'row ' .. i .. ' is ' .. ORDER[i])
		eq(row.text:GetText(), LABELS[i], 'row ' .. i .. ' reads ' .. LABELS[i])
	end
	check(MenuUtil == nil or not stub.state(feed).menu, "Blizzard's menu is not what opened")
	W.CloseList()
end)

test('the list opens beside the button, on the side away from the feed, in the button row', function()
	reset()
	eq(W.ListOwner(), nil, 'the list is closed before the click')
	click_filter()
	local anchor = feed.filterMenuAnchor
	check(anchor:GetRight() <= filterButton:GetLeft(), 'the anchor is left of the button (the feed is on the right of the screen)')
	eq(anchor:GetHeight(), filterButton:GetHeight(), "as tall as the button, so the list lies under or over the button's row")
	eq(W.ListOwner(), anchor, 'the click opened the list, owned by the anchor')
	check(W.GetListFrames().frame:IsShown(), 'the list is shown')
	W.CloseList()
end)

test('the rows show the filters as they are, and a click flips one at once, redraws the feed, and leaves the list open', function()
	reset()
	config.filters.Self, config.filters.Gold = false, false
	click_filter()
	local lines = rows()
	local function checked(i) return W.GetListFrames().isChecked(ORDER[i]) end
	eq(checked(1), false, 'Self Only off')
	eq(checked(2), true, 'Loot on')
	eq(checked(4), false, 'Gold off')

	for i, key in ipairs(ORDER) do
		local before = config.filters[key]
		local drawn_before = updates
		stub.click(lines[i])
		eq(config.filters[key], not before, key .. ' flipped')
		eq(updates, drawn_before + 1, key .. ': the feed redrew')
		eq(W.ListOwner(), feed.filterMenuAnchor, key .. ': the list stays open')
	end
	W.CloseList()
end)

test('a toggle changes what the feed shows', function()
	reset()
	local stack = LT:GetAllItems()
	tinsert(stack, { name = 'G', type = 'Gold', gold = 5, icon = 1, time = 100 })
	tinsert(stack, { name = 'L', type = 'Loot', icon = 1, time = 100 })
	eq(#LT:GetFilteredItems(), 2, 'both show')
	click_filter()
	stub.click(rows()[4]) -- Gold
	eq(#LT:GetFilteredItems(), 1, 'Gold off: one entry')
	stub.click(rows()[4])
	eq(#LT:GetFilteredItems(), 2, 'Gold on: both again')
	W.CloseList()
end)

test("Blizzard's check box menu is gone", function()
	eq(st.CreateCheckboxDropdown, nil, 'st:CreateCheckboxDropdown has no caller left and is removed')
	eq(LT.filterDropdown, nil, 'and the feed keeps no dropdown')
end)

------------------------------------------------------------------ both looks

local function panel_art(button)
	for _, region in ipairs({ button:GetRegions() }) do
		local file = region:GetObjectType() == 'Texture' and region:GetTexture()
		if type(file) == 'string' and file:find('UI%-Panel%-Button%-Up') and region:IsShown() then return true end
	end
	return false
end

test("under the Blizzard theme the buttons are Blizzard's panel buttons with the same icons, and the list is the Settings menu's", function()
	reset()
	for _, name in ipairs({ 'theme', 'blizzard' }) do
		profile.loot.feed.theme = name
		T.theme(name == 'blizzard' and 'blizzard' or 'thick', function() LT:UpdateLootFeedConfig() end)
		eq(panel_art(filterButton), name == 'blizzard', name .. ': the filter button is the panel button only under Blizzard')
		eq(panel_art(jumpButton), name == 'blizzard', name .. ': so is the jump button')
		eq(filterButton.icon:GetTexture(), st.icons.funnel, name .. ': the same funnel')
		eq(jumpButton.icon:GetTexture(), st.icons.arrowDownToLine, name .. ': the same arrow')
		eq(filterButton.icon:GetWidth(), 16, name .. ': the same size')
		eq(tint(filterButton), rgb(profile.colors.text.normal:GetRGB()), name .. ': the same tint')
		mouse_on(feed)
		frame_passes()
		check(shown(filterButton), name .. ': shown under the mouse')
		stub.click(filterButton)
		eq(W.GetListFrames().blizzard, name == 'blizzard', name .. ': the list is the Settings menu under Blizzard only')
		eq(#rows(), 9, name .. ': nine rows')
		W.CloseList()
		stub.cursor_x, stub.cursor_y = 0, 0
		frame_passes()
		check(not shown(filterButton), name .. ': away with the mouse')
	end
	profile.loot.feed.theme = 'theme'
	T.theme('thick', function() LT:UpdateLootFeedConfig() end)
end)

test("a typeface on the feed's Font reaches its texts; a value naming nothing draws Text", function()
	reset()
	local typeface = { font_name = 'Friz Quadrata TT', font_size = 13, font_outline = 'NONE', shadow_offset = { 0, 0 }, spacing = 0 }
	local keys = { 'text', 'timer', 'rightText', 'count' }
	config.font = typeface
	LT:UpdateLootFeedConfig()
	local item = feed.items[1]
	for _, key in ipairs(keys) do
		eq(item[key]:GetFontObject(), st:GetFont(typeface), key .. ": the typeface's object")
		eq(stub.state(item[key]).font, nil, key .. ': set by object, never SetFont')
	end
	eq(select(2, item.text:GetFont()), 13, 'at its size')

	config.font = 'pixel'
	LT:UpdateLootFeedConfig()
	eq(item.text:GetFontObject(), st:GetFont('pixel'), 'Small text: the shared font after the typeface')

	config.font = 'a font that does not exist'
	LT:UpdateLootFeedConfig()
	for _, key in ipairs(keys) do
		eq(item[key]:GetFontObject(), st:GetFont('normal'), key .. ': a value naming nothing draws Text')
	end
	config.font = 'normal'
	LT:UpdateLootFeedConfig()
	eq(#take_errors(), 0, 'no errors')
end)
