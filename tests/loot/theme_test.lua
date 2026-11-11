-- SaftUI-Loot with SaftUI's themes (SaftUI-Core/theme.lua):
--   - the roll bars', the feed's and the loot window's defaults look as their old
--     template names did;
--   - the Rolls and Feed pages offer Theme and Background, not Template;
--   - a roll bar draws its body as a bar and its icon as a slot, and the feed
--     its entries as panels, their icons as slots and its buttons as controls,
--     in the page's Theme and Background;
--   - under Blizzard the ring over each icon lies over the icon and under what
--     the icon carries (the feed's count; Blizzard's roll count is killed);
--   - the disabled loot window's buttons are marked as Blizzard's before they're
--     drawn;
--   - a shown mount entry keeps its yellow border and fill through a theme recolor.
--
-- Real: SaftUI-Loot's config.lua, init.lua, options.lua, roll.lua, rollinfo.lua,
-- Feed/history.lua, feed.lua, filter.lua and progress.lua, Core's helpers, the
-- theme engine and Core's Utilities (the feed's item quality overlay).
load_core_helpers()
local T = load_test_file('lib/theme_helpers.lua')
local drawn = T.watch()
load_saftui('SaftUI-Core/Utilities/utilities.lua')
load_saftui('SaftUI-Core/Utilities/itemupgrades.lua')
load_saftui('SaftUI-Loot/config.lua')
apply_defaults()
load_saftui('SaftUI-Loot/init.lua')
load_saftui('SaftUI-Loot/options.lua')
load_saftui('SaftUI-Loot/roll.lua')
load_saftui('SaftUI-Loot/popup.lua')
load_saftui('SaftUI-Loot/rollinfo.lua')
load_saftui('SaftUI-Loot/Feed/history.lua')
load_saftui('SaftUI-Loot/Feed/feed.lua')
load_saftui('SaftUI-Loot/Feed/filter.lua')
load_saftui('SaftUI-Loot/Feed/progress.lua')

local st = SaftUI
local LT = st.Loot
st:BindModuleConfig(LT, 'loot')
st.config.char = {} -- AceDB's per-character table; the shell has none
local profile = st.config.profile

-- Stands in for LibStringFormat-1.0 (SaftUI-Core/init.lua takes it from LibStub):
-- only ToClock, as m:ss. The real one does more.
st.StringFormat = { ToClock = function(_, sec) return ('%d:%02d'):format(sec / 60, sec % 60) end }

-- Blizzard's (Blizzard_ItemButton): clears a button's ProfessionQualityOverlay.
-- The feed's lines have none, so in game it does nothing to them either.
function ClearItemCraftingQualityOverlay(button) end

-- The old template names these defaults replaced (base commit 7ec1df8).
local OLD = { roll = 'thick', feed = 'thick', popup = 'thick' }

test('loot defaults look as they did', function()
	for key, old in pairs(OLD) do
		T.check_default(profile.loot[key], old, 'loot.' .. key)
	end
end)

test('each page offers Theme and Background, not Template', function()
	-- SaftUI's frames the pages need (made by OnEnable in game); the updates they
	-- run build Blizzard's roll frames and the feed's lines, so they're counted.
	LT.rollAnchor = CreateFrame('Frame', nil, UIParent)
	LT.feed = CreateFrame('Frame', nil, UIParent)
	local applied = {}
	local updateRolls, updateFeed = LT.UpdateGroupLootConfig, LT.UpdateLootFeedConfig
	function LT:UpdateGroupLootConfig() applied[#applied + 1] = 'roll' end
	function LT:UpdateLootFeedConfig() applied[#applied + 1] = 'feed' end

	local tree = LT:GetConfigTable()
	for _, key in ipairs({ 'roll', 'feed' }) do
		local general = tree.args[key].args.general
		T.check_options(general, key)
		eq(general.get({ 'theme' }), 'theme', key .. ': Theme reads loot.' .. key .. '.theme')
		eq(general.get({ 'background' }), 'solid', key .. ': Background reads loot.' .. key .. '.background')
		applied = {}
		general.set({ 'theme' }, 'thin')
		general.set({ 'background' }, 'transparent')
		eq(profile.loot[key].theme, 'thin', key .. ': Theme writes loot.' .. key .. '.theme')
		eq(profile.loot[key].background, 'transparent', key .. ': Background writes loot.' .. key .. '.background')
		eq(table.concat(applied, ','), key .. ',' .. key, key .. ': each applies at once')
		profile.loot[key].theme, profile.loot[key].background = 'theme', 'solid'
	end

	LT.UpdateGroupLootConfig, LT.UpdateLootFeedConfig = updateRolls, updateFeed
	LT.rollAnchor, LT.feed = nil, nil
end)

-- A GroupLootFrame as Blizzard builds it on Forever (tests/loot/roll_skin_test.lua
-- has the full one), hidden, so skinning it doesn't style a roll.
local function roll_frame()
	local frame = CreateFrame('Frame', 'GroupLootFrame1', UIParent)
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
	_G.GroupLootFrame1NameFrame = frame:CreateTexture(nil, 'ARTWORK')
	_G.GroupLootFrame1Corner = frame:CreateTexture(nil, 'ARTWORK')
	local container = CreateFrame('Frame', nil, frame)
	frame.LootButtonContainer = container
	for _, button in ipairs({ 'Pass', 'Greed', 'Need' }) do
		container[button .. 'Button'] = CreateFrame('Button', nil, container)
	end
	return frame
end

test('a roll bar draws its body as a bar and its icon as a slot, in the Rolls theme', function()
	local frame = roll_frame()
	LT:SkinRollFrame(frame)
	local info = LT:GetRollInfoFrame(frame)
	local iconBox
	for _, child in ipairs({ frame.IconFrame:GetChildren() }) do
		if child.backdrop then iconBox = child end
	end
	eq(drawn(info), 'theme,solid,bar', 'the body: the Rolls Theme and Background, as a bar')
	eq(drawn(iconBox), 'theme,solid,slot', 'the icon: the same, as a slot')
	eq(T.inset(info.backdrop), 2, "Thick's border by default")

	profile.loot.roll.theme, profile.loot.roll.background = 'thin', 'transparent'
	LT:UpdateRollFrame(frame)
	eq(drawn(info), 'thin,transparent,bar', 'a new Theme and Background reach the body')
	eq(drawn(iconBox), 'thin,transparent,slot', 'and the icon')
	eq(T.inset(info.backdrop), 1, "Thin's border")
	eq(T.offset(info.backdrop, 'TOPLEFT'), '-1.00,1.00', '1px outside the body')
	profile.loot.roll.theme, profile.loot.roll.background = 'theme', 'solid'
end)

-- The feed as InitializeLootFeed makes it before its lines: the feed, its scroll
-- overlay, the Filter and scroll reset buttons, and the debug text. Made here as
-- InitializeLootFeed and InitializeFilterDropdown make them; the dropdown itself
-- needs Blizzard's menu, and the rest registers events and a mover.
local function make_feed()
	local feed = CreateFrame('Frame', 'SaftUILootFeed', UIParent)
	feed:SetSize(400, 20)
	feed.items, feed.offset = {}, 0
	feed.overlay = CreateFrame('Frame', nil, feed)
	feed.filterButton = st:CreateButton('LootFeedFilterButton', feed, 'F', 'theme', 'solid')
	feed.reset_button = st:CreateButton('LootFeedScrollReset', feed, 'V', 'theme', 'solid')
	LT.feed = feed
	LT.debugText = st:CreateFontString(feed, 'normal', '0/0')
	LT:UpdateLootFeedConfig()
	return feed
end

test("the feed draws its entries as panels, their icons as slots and its buttons as controls, in the Feed theme", function()
	local feed = make_feed()
	local item = feed.items[1]
	eq(drawn(item), 'theme,solid,panel', 'an entry: the Feed Theme and Background, as a panel')
	eq(drawn(item.icon), 'theme,solid,slot', 'its icon, as a slot')
	eq(drawn(feed.filterButton), 'theme,solid,control', 'the Filter button, as a control')
	eq(drawn(feed.reset_button), 'theme,solid,control', 'the scroll reset button')
	eq(T.offset(item.progressBar, 'BOTTOMLEFT'), '2.00,0.00', "the progress bar starts past the icon's Thick border")

	profile.loot.feed.theme = 'thin'
	LT:UpdateLootFeedConfig()
	eq(drawn(item), 'thin,solid,panel', 'a new Theme reaches the entries')
	eq(T.offset(item.progressBar, 'BOTTOMLEFT'), '1.00,0.00', "and the progress bar starts past Thin's")
	profile.loot.feed.theme = 'none'
	LT:UpdateLootFeedConfig()
	eq(T.offset(item.progressBar, 'BOTTOMLEFT'), '0.00,0.00', 'and right at the icon with no border')
	profile.loot.feed.theme = 'theme'
	LT:UpdateLootFeedConfig()
end)

test("a shown mount entry keeps its yellow border, fill and icon border through a recolor, and a hidden one doesn't", function()
	local feed = LT.feed
	wipe(LT:GetAllItems())
	stub.time = 100
	local stack = LT:GetAllItems()
	-- Newest first: a mount, then an ordinary item.
	tinsert(stack, { name = 'Swift Razzashi Raptor', type = 'Loot', icon = 1, itemSubType = 'Mount', time = 100 })
	tinsert(stack, { name = 'Linen Cloth', type = 'Loot', icon = 1, time = 100 })
	LT:GetFilteredItems()
	LT:UpdateFeed()

	local mount, other = feed.items[1], feed.items[2]
	check(mount:IsShown() and other:IsShown(), 'both entries show')
	local yellow = T.text(profile.colors.button.yellow:GetRGB())
	local saved = profile.templates.thick.bordercolor
	local THICK_EDGE = T.text(unpack(saved))
	eq(T.edge(mount.backdrop), yellow .. ',1.00', "the mount's border is yellow")
	eq(T.fill(mount.backdrop), yellow .. ',0.60', 'and its fill')
	eq(T.edge(mount.icon.backdrop), yellow .. ',1.00', "and its icon's border")

	for _ = 1, 3 do
		profile.templates.thick.bordercolor = { 0.7, 0.1, 0.1, 1 }
		st:RecolorThemed()
	end
	eq(T.edge(mount.backdrop), yellow .. ',1.00', "after a recolor the mount's border is still yellow")
	eq(T.fill(mount.backdrop), yellow .. ',0.60', 'and its fill')
	eq(T.edge(mount.icon.backdrop), yellow .. ',1.00', "and its icon's border")
	eq(T.edge(other.backdrop), '0.70,0.10,0.10,1.00', 'the other entry takes the new border color')
	profile.templates.thick.bordercolor = saved
	st:RecolorThemed()
	eq(T.edge(other.backdrop), THICK_EDGE, 'and back')

	-- A hidden line that last showed a mount isn't colored again.
	mount:Hide()
	st:RecolorThemed()
	eq(T.edge(mount.backdrop), THICK_EDGE, "a hidden entry keeps the theme's border")
end)

------------------------------------------------------------------ Blizzard's art on the icons and buttons

-- Where a region draws among its frame's, as one number: the layer, then the
-- sublevel.
local LAYERS = { BACKGROUND = 1, BORDER = 2, ARTWORK = 3, OVERLAY = 4, HIGHLIGHT = 5 }
local function depth(region)
	local layer, sublevel = region:GetDrawLayer()
	return LAYERS[layer] * 100 + (sublevel or 0)
end

test("under Blizzard a roll bar's icon ring lies over the icon frame's own icon, and its backdrop under it as before", function()
	local frame = roll_frame()
	LT:SkinRollFrame(frame)
	local iconBox
	for _, child in ipairs({ frame.IconFrame:GetChildren() }) do
		if child.backdrop then iconBox = child end
	end
	local level = frame.IconFrame:GetFrameLevel()
	check(iconBox:GetFrameLevel() > level, "the icon box is over Blizzard's icon frame, which holds the icon")
	check(iconBox.backdrop:GetFrameLevel() < level, 'its backdrop is under it, as before')
	eq(T.over(iconBox.backdrop), '', 'Thick: no ring')
	check(not frame.IconFrame.Count:IsShown(), "Blizzard's own count is killed by the skin, so nothing of it lies under the ring")

	profile.loot.roll.theme = 'blizzard'
	LT:UpdateRollFrame(frame)
	local art = st.ThemeArt.Get(iconBox.backdrop)
	check(art ~= nil and art.over.Ring ~= nil and art.over.Ring:IsShown(), 'Blizzard: the ring shows')
	eq(art.over.Ring:GetParent(), iconBox, "it's a texture of SaftUI's icon box")
	check(art.over.Ring:GetParent():GetFrameLevel() > frame.IconFrame.Icon:GetParent():GetFrameLevel(), "on a frame over the icon's")
	check(T.art(iconBox.backdrop) ~= '', 'and the slot art behind')
	eq(drawn(iconBox), 'blizzard,solid,slot', 'drawn as a slot')
	check(iconBox.backdrop:GetFrameLevel() < level, 'the backdrop stays under the icon frame')

	profile.loot.roll.theme = 'none'
	LT:UpdateRollFrame(frame)
	profile.loot.roll.theme = 'thin'
	LT:UpdateRollFrame(frame)
	check(iconBox.backdrop:GetFrameLevel() < level, 'a backdrop made after a None is under it too')
	profile.loot.roll.theme = 'theme'
	LT:UpdateRollFrame(frame)
end)

test("a preview roll bar's icon is a slot, its icon under the ring", function()
	LT.rollAnchor = CreateFrame('Frame', nil, UIParent)
	LT.rollPreview = nil
	C_Item = C_Item or { GetItemInfo = function() end, GetItemIconByID = function() return 134400 end }
	-- Feed/rolls.lua's states, which the preview's sample choices name.
	LT.ROLL_STATE = LT.ROLL_STATE or setmetatable({}, { __index = function() return 4 end })
	local container = LT:CreateRollPreviews()
	LT.testRolls = true
	LT:UpdateRollPreviews()
	local bar = container.bars[1]
	eq(drawn(bar.IconFrame), 'theme,solid,slot', "the icon is drawn as a slot, in the Rolls theme")
	eq(T.over(bar.IconFrame.backdrop), '', 'Thick: no ring')

	profile.loot.roll.theme = 'blizzard'
	LT:UpdateRollPreviews()
	local ring = st.ThemeArt.Get(bar.IconFrame.backdrop).over.Ring
	check(ring:IsShown(), 'Blizzard: the ring shows')
	eq(ring:GetParent(), bar.IconFrame, "a texture of the icon's frame")
	check(depth(ring) > depth(bar.Icon), 'over the icon')
	profile.loot.roll.theme = 'theme'
	LT.testRolls, LT.rollAnchor = nil, nil
end)

test("the feed's icon ring lies over the icon and under its count", function()
	profile.loot.feed.theme = 'theme'
	local feed = make_feed()
	local item = feed.items[1]
	eq(T.over(item.icon.backdrop), '', 'Thick: no ring')

	-- SaftUI's theme switched, as the Theme tab does it.
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	eq(drawn(item.icon), 'theme,solid,slot', "the icon is drawn as a slot")
	local art = st.ThemeArt.Get(item.icon.backdrop)
	local ring = art.over.Ring
	check(ring ~= nil and ring:IsShown(), 'Blizzard: the ring shows')
	-- The icon is a texture, so its ring is on a frame of SaftUI's over the entry,
	-- over the icon; the count is on a frame over that one.
	local holder, counter = ring:GetParent(), item.count:GetParent()
	check(holder ~= item and holder:GetFrameLevel() > item:GetFrameLevel(), 'the ring is on a frame over the entry, and its icon')
	check(counter ~= item and counter:GetParent() == item, "the count is on a frame of the entry's own")
	check(counter:GetFrameLevel() > holder:GetFrameLevel(), 'which is over the ring')
	eq(item.count:GetDrawLayer(), 'OVERLAY', 'the count is still OVERLAY')
	eq(T.offset(item.count, 'BOTTOMRIGHT'), '0.00,2.00', 'and still at the icon\'s corner')
	profile.theme.name = 'thick'
	st:RedrawThemed()
	eq(T.over(item.icon.backdrop), '', 'Thick again: no ring')
end)

-- The panel button's pieces shown on a button of SaftUI's, by file: whether
-- any.
local function panel_art(button)
	for _, region in ipairs({ button:GetRegions() }) do
		local file = region:GetObjectType() == 'Texture' and region:GetTexture()
		if type(file) == 'string' and file:find('UI%-Panel%-Button%-Up') and region:IsShown() then return true end
	end
	return false
end

test("the feed's filter and reset buttons are drawn again in the Feed theme, and are Blizzard's panel buttons under Blizzard", function()
	profile.loot.feed.theme = 'theme'
	local feed = make_feed()
	for name, button in pairs({ filter = feed.filterButton, reset = feed.reset_button }) do
		check(not panel_art(button), name .. ': Thick: no panel button')
	end

	profile.loot.feed.theme = 'blizzard'
	LT:UpdateLootFeedConfig()
	for name, button in pairs({ filter = feed.filterButton, reset = feed.reset_button }) do
		eq(drawn(button), 'blizzard,solid,control', name .. ': a control, in the Feed theme')
		check(panel_art(button), name .. ": Blizzard's panel button, though SaftUI's theme is Thick")
	end

	profile.loot.feed.theme = 'thin'
	LT:UpdateLootFeedConfig()
	for name, button in pairs({ filter = feed.filterButton, reset = feed.reset_button }) do
		eq(drawn(button), 'thin,solid,control', name .. ': Thin')
		check(not panel_art(button), name .. ': no panel button again')
	end
	profile.loot.feed.theme = 'theme'
	LT:UpdateLootFeedConfig()
end)

test("the loot window's buttons are marked as Blizzard's before they're drawn as slots", function()
	local order = {}
	local mark, skin = st.MarkForeign, st.SkinActionButton
	local marked, skinned
	st.MarkForeign = function(self, frame)
		order[#order + 1] = 'mark'
		marked = frame
		return mark(self, frame)
	end
	st.SkinActionButton = function(self, button, config, kind)
		order[#order + 1] = 'skin:' .. tostring(kind)
		skinned = button
	end
	local button = CreateFrame('Button', 'LootButton1', UIParent)
	button:SetID(1)
	button.icon = button:CreateTexture(nil, 'BACKGROUND')
	button.Count = button:CreateFontString(nil, 'OVERLAY')
	_G.LootButton1Text = button:CreateFontString(nil, 'OVERLAY')
	-- Locked, so any field the skin writes fails. popup.lua:38 writes button.nametext
	-- (a known write; the popup is disabled, init.lua:17), so that one key is
	-- given a placeholder first, which a lock lets be assigned.
	button.nametext = false
	local locked = load_test_file('misc/fixtures/locked_widget.lua')
	locked(button, 'Blizzard loot button')
	LT:SkinLootButton(button)
	st.MarkForeign, st.SkinActionButton = mark, skin
	eq(table.concat(order, ','), 'mark,skin:slot', 'marked, then drawn as a slot')
	eq(marked, button, 'the button is the one marked')
	eq(skinned, button, 'and drawn')
end)
