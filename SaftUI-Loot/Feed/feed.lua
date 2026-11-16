local st = SaftUI
local LT = st.Loot

local Util = st:GetModule('Utilities')

-- The chat lines' parsing is Feed/parse.lua's.
local get_match, decreasePatterns = LT.parse.get_match, LT.parse.decreasePatterns

local MAX_HISTORY = LT.MAX_HISTORY -- Feed/history.lua
local feed_stack = {}


------------------------------------
---- Feed updates ------------------
------------------------------------

function LT:GetAllItems()
	return feed_stack
end

-- Whether an entry is still within its fade time. Test entries stay put while
-- test mode is on so the feed doesn't fade out while it's being tuned.
function LT:IsFeedEntryFresh(info, now)
	if self.testFeed and info.test then return true end
	return now - info.time <= self.config.feed.fade_time
end

-- The feed's two small buttons (the filter and the jump to the newest entry) are
-- a Lucide icon on a button drawn in the feed's theme: Colors -> Text -> Normal
-- at rest, the lighter tone of the states under the mouse (the interaction states:
-- the button's Layer is the hover, the icon its glyph). The icon is 16 px on the
-- 20 px button: Lucide's funnel fills 20 of its 24 grid, the arrow 14, so 16
-- leaves the funnel 13 px wide and each a few px of the button round it.
local ICON_SIZE = 16

-- The icon's rest color, Text -> Normal (the states put it back after a hover).
local function IconRest()
	return st:Color('text', 'normal'):GetRGB()
end

-- The icon's rest color put on: the states' paint (a glyph's rest color needs an
-- explicit one), and under the Blizzard look, where the helper leaves a glyph alone,
-- Text > Normal directly (a rest color is not a state).
function LT.RestIcon(button)
	if not button then return end
	if st:GetState(button, 'hover') ~= nil then st:PaintStates(button) end
	if st:DrawnTheme(button) == 'blizzard' and not st:GetState(button, 'hover') then
		button.icon:SetVertexColor(IconRest())
	end
end

-- A feed button with its icon and its tooltip: a title and, for the filter, a line
-- under it. Hovering lights the button and its icon (the states'); a button that
-- hides under the cursor (UpdateFeedButtons) gets no OnLeave, so hiding puts the
-- tooltip away too (the states clear the hover on hide).
function LT:CreateFeedIconButton(name, icon, title, line)
	local button = st:CreateButton(name, self.feed, nil, 'theme', 'solid')
	button:SetSize(20, 20)
	button.icon = button:CreateTexture(nil, 'OVERLAY', nil, 7)
	button.icon:SetTexture(icon)
	button.icon:SetSize(ICON_SIZE, ICON_SIZE)
	button.icon:SetPoint('CENTER')
	-- Merged into the skinner's states: no `text`, the label stays the skinner's.
	st:AddStates(button, 'box', { edge = 'theme', glyph = button.icon, glyphRest = IconRest })
	LT.RestIcon(button) -- the icon's rest color: only an explicit paint puts it on

	button:SetScript('OnEnter', function(self)
		if GameTooltip:IsForbidden() then return end
		GameTooltip:SetOwner(self, 'ANCHOR_TOP')
		GameTooltip:SetText(title)
		if line then GameTooltip:AddLine(line, 1, 1, 1, true) end
		GameTooltip:Show()
	end)
	local function Away(self)
		if not GameTooltip:IsForbidden() and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
	end
	button:SetScript('OnLeave', Away)
	button:SetScript('OnHide', Away)
	return button
end

-- Whether the mouse is where the buttons belong: over the feed, the strip beside
-- it the buttons sit in (feed.hover, which also covers the gap between the feed
-- and them), or a button; or the filter menu is open, so the button isn't
-- gone from under its own menu.
function LT:IsFeedHovered()
	local feed = self.feed
	if feed.hover:IsMouseOver() then return true end
	for _, button in ipairs({ feed.filterButton, feed.reset_button }) do
		if button:IsShown() and button:IsMouseOver() then return true end
	end
	local W = st.OptionsWidgets
	return W.ListOwner() == feed.filterMenuAnchor
end

-- The highest alpha among the entries on screen, or 0 with none shown. An entry
-- being faded out (UpdateFeedVisibility) is still shown at its alpha.
function LT:GetFeedEntryAlpha()
	local top = 0
	for i = 1, self.config.feed.max_items do
		local item = self.feed.items[i]
		if item and item:IsShown() then
			top = max(top, item:GetAlpha())
		end
	end
	return top
end

-- Shows the filter button while at least one entry is on the feed, or the mouse is
-- over the feed's area (or the filter menu is open), and the jump button too while
-- the feed is scrolled back. The buttons are at full alpha under the mouse, and
-- otherwise at the alpha of the most visible entry, so they fade out with the last
-- one and come back at once with a new one. A button at alpha 0 is hidden, so it
-- takes no mouse and shows no tooltip. Runs every frame, and where the scroll
-- offset or the entries change.
function LT:UpdateFeedButtons()
	local feed = self.feed
	if not (feed and feed.hover and feed.filterButton) then return end
	local alpha = self:IsFeedHovered() and 1 or self:GetFeedEntryAlpha()
	local visible = alpha > 0
	feed.filterButton:SetShown(visible)
	feed.filterButton:SetAlpha(alpha)
	feed.reset_button:SetShown(visible and feed.offset > 0)
	feed.reset_button:SetAlpha(alpha)
end

-- The feed's buttons and the area the mouse brings them up in (feed.hover: the
-- feed and the strip the buttons sit in, placed with them by
-- UpdateLootFeedConfig; it takes no mouse). The first UpdateFeedButtons hides
-- them unless an entry is on the feed or the mouse is there.
function LT:CreateFeedButtons()
	local feed = self.feed
	feed.hover = CreateFrame('frame', feed:GetName()..'Hover', feed)

	self:InitializeFilterDropdown()
	feed.reset_button = self:CreateFeedIconButton(feed:GetName()..'ScrollReset', st.icons.arrowDownToLine,
		'Jump to the newest entry')
	feed.reset_button:Hide()
	feed.reset_button:SetScript('OnClick', function()
		feed.offset = 0
		self:UpdateFeedButtons()
		self:UpdateFeed()
	end)
end

-- An item or currency entry's name in its quality's color, as it is now: the
-- entry keeps its plain name (`plain`), its `quality` and what follows the name
-- (`suffix`, a currency's counts), so a changed Item quality color reaches a line
-- already drawn (LT:ColorFeed) and one drawn later. An entry with no plain name
-- (gold, skills, a roll result with no item data yet) shows its `name` as it is.
function LT.FeedItemName(info)
	local plain = info.plain
	if not plain then return info.name end
	local color = info.quality and st.config.profile.colors.item_quality[info.quality]
	if color then
		-- The color code LibStringFormat's ColorString makes (the same text), without
		-- its table per call: a pass runs this for every line of that quality.
		local r, g, b = color:GetRGB()
		if r < 0 or r > 1 then r = r / 255 end
		if g < 0 or g > 1 then g = g / 255 end
		if b < 0 or b > 1 then b = b / 255 end
		plain = ('|cff%02x%02x%02x%s|r'):format(r * 255, g * 255, b * 255, plain)
	end
	if info.suffix then return plain .. info.suffix end
	return plain
end

-- A progress snapshot's bar color: the profile's color it names (colorGroup and
-- colorKey) as it is now, else the color it was taken in.
function LT.ProgressRGB(progress)
	local color = st.config.profile.colors[progress.colorGroup]
	if progress.colorKey ~= nil and type(color) == 'table' then color = color[progress.colorKey] end
	if type(color) == 'table' and color.GetRGB then return color:GetRGB() end
	return progress.r, progress.g, progress.b
end

-- A mount's entry in the Loot > Mount color: its border and fill, and its
-- icon's border. Every other entry has the feed's Theme and Background (drawn by DrawEntry).
local function ColorMount(item)
	local r, g, b = st:Color('loot', 'mount'):GetRGB()
	if item.backdrop then
		st:SetBorderColor(item.backdrop, r, g, b, 1)
		item.backdrop:SetBackdropColor(r, g, b, .6)
	end
	if item.icon.backdrop then
		st:SetBorderColor(item.icon.backdrop, r, g, b, 1)
	end
end

-- Draws a feed line for the entry it shows: an entry as a panel, its icon as a
-- small frame, or a mount in its own color.
local function DrawEntry(item, info, config)
	if info.itemSubType == "Mount" then
		ColorMount(item)
	else
		st:SetBackdrop(item, config.theme, config.background, 'panel')
		st:SetBackdrop(item.icon, config.theme, config.background, 'slot')
	end
end

-- A color change (st:ColorChanged, through LT:OnColorsChanged, init.lua); `key`
-- is nil on a whole group. Only colors are set, on the lines shown:
--   'text' and 'theme': the buttons' icons at rest (the accent is the states' own pass);
--   'theme' (st:RecolorThemed gave every line the theme's colors) and Loot >
--     Mount: the mount entries take their Loot > Mount color back;
--   'item_quality': the lines of that quality set their name again (SetText on
--     SaftUI's own font string);
--   'reaction' and 'renown': the progress lines' bars that name that color;
--   'class' and Loot > Pass: a roll result's right text (the winner's name,
--     "All passed"), built again from its rolls (LT.RollResultText).
function LT:ColorFeed(group, key)
	if not self.feed then return end
	-- The buttons' icons rest in Colors -> Text -> Normal; the accent group is the
	-- states' own pass (the hover tone follows it).
	if group == 'text' or group == 'theme' then
		LT.RestIcon(self.feed.filterButton)
		LT.RestIcon(self.feed.reset_button)
		if group == 'text' then return end
	end
	if group == 'accent' then return end
	local mounts = group == 'theme' or (group == 'loot' and (key == nil or key == 'mount'))
	local names = group == 'item_quality'
	local bars = group == 'reaction' or group == 'renown'
	local results = group == 'class' or group == 'loot'
	if not (mounts or names or bars or results) then return end
	for _, item in ipairs(self.feed.items) do
		local info = item:IsShown() and item.info
		if info then
			if mounts and info.itemSubType == "Mount" then
				ColorMount(item)
			end
			if names and info.plain and info.quality and (key == nil or key == info.quality) then
				item.text:SetText(self.FeedItemName(info))
			end
			if results and info.rolls and self.RollResultUses(info.rolls, group, key) then
				item.rightText:SetText(self.RollResultText(info.rolls))
			end
			local progress = info.progress
			if bars and progress and progress.colorGroup == group and (key == nil or key == progress.colorKey) then
				item.progressBar:SetStatusBarColor(self.ProgressRGB(progress))
			end
		end
	end
end

function LT:UpdateFeed(recentlyScrolled, useCache)
	local now = GetTime()
	local item, info

	local filteredItems =  self:GetFilteredItems(useCache)

	self.debugText:SetFormattedText('%d/%d/%d', self.feed.offset, #filteredItems, #feed_stack)

	local feedConfig = self.config.feed

	for i=1, feedConfig.max_items do
		item = self.feed.items[i]
		info = filteredItems[i + self.feed.offset]
		if not info then break end

		if recentlyScrolled then
			info.time = now
		end

		if self:IsFeedEntryFresh(info, now) then
			Util:ClearItemQuality(item)
			DrawEntry(item, info, feedConfig)

			if info.gold then
				item.text:SetText(st.StringFormat:GoldFormat(info.gold))
			else
				if info.link then
					Util:SetItemQuality(item, info.link, item.icon)
				end

				item.text:SetText(self.FeedItemName(info))
			end

			item.rightText:SetText(info.rolls and LT.RollResultText(info.rolls) or info.rightText or '')

			item.count:SetText(info.count or '')
			item.icon:SetTexture(info.icon)

			-- Items are reused across entry types, so the bar hides on entries
			-- without a progress snapshot.
			local progress = info.progress
			if progress then
				item.progressBar:SetMinMaxValues(0, progress.max)
				item.progressBar:SetValue(progress.value)
				item.progressBar:SetStatusBarColor(self.ProgressRGB(progress))
			end
			item.progressBar:SetShown(progress ~= nil)

			item.link = info.link
			item.info = info

			item:SetAlpha(1)
			item:Show()
		end
	end
	self:UpdateFeedButtons()
end

-- Drops every entry test mode pushed, leaves real ones alone, and hides the
-- feed lines that no longer have an entry behind them.
function LT:RemoveTestFeedEntries()
	for i = #feed_stack, 1, -1 do
		if feed_stack[i].test then tremove(feed_stack, i) end
	end

	if not self.feed then return end
	self.feed.offset = 0
	self:UpdateFeedButtons()

	local filteredItems = self:GetFilteredItems()
	for i, item in ipairs(self.feed.items) do
		if not filteredItems[i] then
			item:Hide()
		end
	end
	self:UpdateFeed()
end

function LT:UpdateAllFeedTimers(index)
	local now = GetTime()
	-- The lines show the filtered list, so `index` and the offset count in it.
	local filteredItems = self:GetFilteredItems(true)
	for i=1, index or self.config.feed.max_items do
		local info = filteredItems[i + self.feed.offset]
		if not info then break end

		info.time = now
	end
end

-- Two entries are the same item: the plain name and quality when both have them
-- (`name` keeps the color it was pushed in, which a pick may since have changed),
-- else the name.
local function SameName(a, b)
	if a.plain and b.plain then return a.plain == b.plain and a.quality == b.quality and a.suffix == b.suffix end
	return a.name == b.name
end

function LT:LootFeedPush(info)
	info.time = GetTime()
	info.when = time()
	-- Entries pushed by test mode are tagged so they can be told apart (and
	-- removed) later; they never merge with real entries.
	info.test = self.pushingTest or nil

	local inserted = false
	local top = feed_stack[1]
	if top and (top.test or false) ~= (info.test or false) then top = nil end
	-- Restored entries are history; new gains start their own entry.
	if top and top.restored then top = nil end

	-- Each rolled item is its own entry, with its own rolls.
	if top and (top.rolls or info.rolls) then top = nil end

	-- If you loot gold multiple times together, group it up into one item
	if info.gold and top and top.gold then
		top.gold = top.gold + info.gold
		top.time = info.time
		top.when = info.when
		self:SaveFeedEntry(top)
	elseif top and SameName(info, top) and info.craftQuality == top.craftQuality and info.rightText == top.rightText then
		top.count = (top.count or 1) + (info.count or 1)
		top.time = info.time
		-- The merged entry now stands for the latest gain, so it shows that snapshot.
		top.progress = info.progress
		top.when = info.when
		self:SaveFeedEntry(top)
	else
		-- Only an inserted entry grows the feed; a merge leaves it as it was.
		while #feed_stack >= MAX_HISTORY do
			tremove(feed_stack)
		end
		tinsert(feed_stack, 1, info)
		self:SaveFeedEntry(info)
		inserted = true
	end

	-- If scrolling through history, don't push the feed upwards. A merge adds
	-- no entry, so it moves nothing.
	if inserted and self.feed.offset > 0 then
		self.feed.offset = self.feed.offset + 1
	end

	self:UpdateFeed()
end

function LT:LootFeedAddCurrency(match)
	if not match['currency'] then return end

	local info = C_CurrencyInfo.GetCurrencyInfoFromLink(match['currency'])

	if not info then
		st:Error("No current info found for", match['currency'])
		return
	end

	local suffix
	if info.maxQuantity > 0 then
		suffix = (" (%d/%d)"):format(info.quantity, info.maxQuantity)
	else
		suffix = (" (%d)"):format(info.quantity)
	end

	local entry = { plain = info.name, quality = info.quality, suffix = suffix }
	-- The entry's text, as it was drawn (saved with it, and what a merge compares).
	entry.name = self.FeedItemName(entry)
	if not st.config.profile.colors.item_quality[info.quality] then
		st:Debug('Loot', ('Invalid quality (%d) for item %s'):format(info.quality, info.name))
	end

	self:LootFeedPush({
		name = entry.name,
		plain = entry.plain,
		quality = entry.quality,
		suffix = entry.suffix,
		icon = info.iconFileID,
		link = match['link'],
		count = match['count'],
		type = 'Currency',
	})
end

function LT:LootFeedAddItem(match)
	if not match['link'] then return end

	-- The winner's loot for a roll result already in the feed goes into that
	-- entry instead (Feed/rolls.lua).
	if self:AbsorbLootMessage(match) then return end

	local name, _, quality, _, _, type, subType, _, _, texture = C_Item.GetItemInfo(match['link'])

	if not name or not quality then
		st:Error("Item has weird link:", match['link'], match['link']:gsub("|", "||"))
		return
	end

	local item_color = st.config.profile.colors.item_quality[quality]
	if not item_color then return st:Debug('Loot', ('Invalid quality (%d) for item %s'):format(quality, name)) end

	-- The plain name and quality are kept: the line colors the name as it draws.
	local plain = name
	name = self.FeedItemName({ plain = plain, quality = quality })

	self:LootFeedPush({
		name = name,
		plain = plain,
		quality = quality,
		rightText = match['player'],
		icon = texture,
		link = match['link'],
		count = match['count'],
		notSelf = match['player'],
		type = 'Loot',
		itemType = type,
		itemSubType = subType,
	})
end

local function extract_gold(gold_string)
	local c = gold_string:match(COPPER_AMOUNT:gsub('%%d', '%%s'):format('(%d+)')) or 0
	local s = gold_string:match(SILVER_AMOUNT:gsub('%%d', '%%s'):format('(%d+)')) or 0
	local g = gold_string:match(GOLD_AMOUNT:gsub('%%d', '%%s'):format('(%d+)')) or 0

	return c + s*1E2 + g*1E4
end

function LT:LootFeedAddGold(match)
	local gold, icon = extract_gold(match['gold']), [[Interface\ICONS\INV_Misc_Coin_06]]

	if gold >= 1E4 then
		icon = [[Interface\ICONS\INV_Misc_Coin_02]]
	elseif gold >= 1E2 then
		icon = [[Interface\ICONS\INV_Misc_Coin_04]]
	end

	self:LootFeedPush({
		name = 'Gold',
		gold = gold,
		icon = icon,
		type = 'Gold',
	})
end

function LT:LootFeedAddSkillUp(match)
	self:LootFeedPush({
		name = ('%s %d'):format(match['skill'], match['count']),
		icon = self:GetSkillIcon(match['skill']),
		type = 'Skill'
	})
end

function LT:LootFeedAddExperience(match)
	self:LootFeedPush({
		name = ('%d Experience'):format(match['experience']),
		icon = self.FEED_ICONS.Experience,
		type = 'Experience',
		progress = self:SnapshotExperienceProgress(),
	})
end

function LT:LootFeedAddHonor(match)
	if not match.honor then return end

	local player = ''
	if match.player then
		player = match.player or ''
		if match.rank then
			player = match.rank .. ' ' .. player
		end
		player = format(' (%s)', player)
	end

	self:LootFeedPush({
		name = ('%s Honor%s'):format(match.honor, player),
		icon = "Interface\\PvPRankBadges\\PvPRank12",
		type = 'Honor',
	})
end

function LT:LootFeedAddReputation(match)
	if not match.faction then return end

	local icon = match.count >= 0 and self.FEED_ICONS.ReputationUp or self.FEED_ICONS.ReputationDown
	--TODO: Add font color based on current status with the faction? Add current faction rank?
	self:LootFeedPush({
		name = ('%d Reputation (%s)'):format(match.count, match.faction),
		icon = icon,
		type = 'Reputation',
		progress = self:SnapshotReputationProgress(match.faction),
	})
end
------------------------------------
-- General
------------------------------------

function LT:LootFeedHandler(event, text)
	local match = get_match(text)
	if not match then return end

	if match['link'] then
		self:LootFeedAddItem(match)
	elseif match['currency'] then
		self:LootFeedAddCurrency(match)
	elseif match['gold'] then
		self:LootFeedAddGold(match)
	elseif match['skill'] then
		self:LootFeedAddSkillUp(match)
	elseif match['honor'] then
		self:LootFeedAddHonor(match)
	elseif match['experience'] then
		self:LootFeedAddExperience(match)
	elseif match['faction'] then
		match.count = tonumber(match.count)
		if decreasePatterns[match.pattern] then
			match.count = -match.count
		end
		self:LootFeedAddReputation(match)
	end
end

-- The line's tooltip. It's also the line's UpdateTooltip: when the item's data
-- arrives, GameTooltip redoes the item part and drops the lines added after it,
-- unless the owner has an UpdateTooltip, which it calls instead (then, and on
-- its update timer). The fade timers aren't touched here, so hovering doesn't
-- keep resetting them.
local function BuildTooltip(self)
	local info = self.info
	if not self.link and not info then return end
	-- UpdateTooltip runs this every 0.2s while hovered; a forbidden tooltip errors on SetOwner.
	if GameTooltip:IsForbidden() then return end

	GameTooltip:SetOwner(self, 'ANCHOR_NONE')
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('BOTTOMRIGHT', self, 'BOTTOMLEFT', -10, 0)
	if self.link then
		GameTooltip:SetHyperlink(self.link)
	else
		-- Gold, XP, reputation and the like have no link: a small tooltip with
		-- the line's own text.
		GameTooltip:SetText(info.gold and st.StringFormat:GoldFormat(info.gold) or info.name or '')
	end
	if info and info.rolls then
		LT:AddRollLines(GameTooltip, info.rolls, false)
	end
	local ago = LT:FormatAgo(info and info.when)
	if ago ~= '' then
		GameTooltip:AddLine(ago, .6, .6, .6)
	end
	GameTooltip:Show()
end

-- Hovering a line restarts the fade of it and the lines above it, once.
local function ShowTooltip(self)
	if not self.link and not self.info then return end
	LT:UpdateAllFeedTimers(self:GetID())
	BuildTooltip(self)
end

local function HideTooltip()
	GameTooltip:Hide()
end

local function HandleClick(self, button, upInside)
	-- Only act if mouse is still inside on mouse up
	if not upInside then return end

	-- We don't care about non-items
	if not self.link then return end

	if button == 'LeftButton' then
		if IsShiftKeyDown() then
			-- chat link
		elseif IsControlKeyDown() and C_Item.IsDressableItemByID(self.link) then
			DressUpLink(self.link)
		end
	end
end

-- Places the feed from loot.feed.position. Also used by the edit mode mover.
function LT:ApplyFeedPosition()
	st:PlaceAtPosition(self.feed, self.config.feed.position)
end

-- Safe in combat lockdown: the feed and its items are not protected.
function LT:UpdateLootFeedConfig()
	local config = self.config.feed

	self.feed:SetWidth(config.width)
	self.feed:SetHeight(config.max_items * config.item_height + (config.max_items - 1) * config.spacing)
	self:ApplyFeedPosition()

	for i=#self.feed.items+1, config.max_items do
		local item = CreateFrame('button', st.name ..'LootFeed'..i, self.feed)

		item:Hide()
		item:SetID(i)
		item.timer = item:CreateFontString(nil, 'OVERLAY')
		item.text = item:CreateFontString(nil, 'OVERLAY')
		item.rightText = item:CreateFontString(nil, 'OVERLAY')
		item.icon = item:CreateTexture(nil, 'OVERLAY', nil, 1)
		-- The icon is a texture, so the Blizzard theme draws its ring on a frame
		-- one level over the entry, over the icon. The count goes on a frame
		-- over that one, so the ring lies under it.
		local over = CreateFrame('Frame', nil, item)
		over:SetAllPoints(item)
		over:SetFrameLevel(item:GetFrameLevel() + 2)
		item.count = over:CreateFontString(nil, 'OVERLAY')

		-- XP and reputation progress, styled like the roll frame's timer bar.
		item.progressBar = CreateFrame('StatusBar', nil, item)
		item.progressBar:SetStatusBarTexture(st.BLANK_TEX)
		item.progressBar:Hide()

		st:SetBackdrop(item.icon, config.theme, config.background, 'slot')

		item.UpdateTooltip = BuildTooltip
		item:SetScript("OnEnter", ShowTooltip)
		item:SetScript("OnLeave", HideTooltip)
		item:SetScript('OnMouseUp', HandleClick)
		item:EnableMouse(true)

		self.feed.items[i] = item
	end

	local font_obj = st:FontObject(config.font)

	for i,item in pairs(self.feed.items) do
		item:ClearAllPoints()
		if i == 1 then
			item:SetPoint('BOTTOMRIGHT', self.feed , 'BOTTOMRIGHT', 0, 0)
		else
			item:SetPoint('BOTTOMRIGHT', self.feed.items[i-1], 'TOPRIGHT', 0, config.spacing)
		end

		-- Lowering max_items leaves the extra items behind; keep them out of sight.
		if i > config.max_items then item:Hide() end

		item:SetSize(config.width, config.item_height)
		item.text:SetFontObject(font_obj)
		item.text:SetPoint('LEFT', item.icon, 'RIGHT', 10, 0)
		item.text:SetPoint('RIGHT', item.rightText, 'LEFT', -10, 0)
		item.text:SetJustifyH('LEFT')
		item.text:SetWordWrap(false)

		item.timer:SetPoint('RIGHT', item, 'LEFT', -20, 0)
		item.timer:SetFontObject(font_obj)
		item.timer:SetJustifyH('LEFT')

		item.rightText:SetFontObject(font_obj)
		item.rightText:SetPoint('RIGHT', item, 'RIGHT', -10, 0)
		item.rightText:SetJustifyH('RIGHT')

		-- Placeholder text for new items only; re-applying must not clobber live entries.
		if not item.placeholderSet then
			item.placeholderSet = true
			item.text:SetText('Item '..i)
			item.rightText:SetText('Player '..i)
		end

		item.count:SetFontObject(font_obj)
		item.count:SetPoint('BOTTOMRIGHT', item.icon, 0, 2)

		item.icon:SetSize(config.item_height, config.item_height)
		item.icon:SetPoint('LEFT', item)
		st:SkinIcon(item.icon)
		st:SetBackdrop(item, config.theme, config.background, 'panel')

		-- Along the bottom edge of the text panel. The panel's visible left edge is
		-- the icon's border, which st:SetBackdrop draws outside the icon (2px for
		-- Thick, 1px for Thin, none for None), so start right after it and run to
		-- the entry's right edge.
		local iconBorder = st:ThemeInset(config.theme, config.background, 'slot')
		item.progressBar:ClearAllPoints()
		item.progressBar:SetPoint('BOTTOMLEFT', item.icon, 'BOTTOMRIGHT', iconBorder, 0)
		item.progressBar:SetPoint('BOTTOMRIGHT', item, 'BOTTOMRIGHT', 0, 0)
		item.progressBar:SetHeight(1)
	end

	self.feed.overlay:SetPoint('BOTTOMLEFT', self.feed)
	self.feed.overlay:SetPoint('TOPRIGHT', self.feed.items[config.max_items], 'TOPRIGHT')

	-- The buttons sit on the feed's inner side, the one facing the screen's middle.
	local x = self.feed:GetCenter()
	local onLeft = x and x > GetScreenWidth()/2
	local strip = 20 + config.spacing -- a button and its gap
	self.feed.filterButton:ClearAllPoints()
	self.feed.hover:ClearAllPoints()
	self.feed.hover:SetPoint('TOPLEFT', self.feed, 'TOPLEFT', onLeft and -strip or 0, 0)
	self.feed.hover:SetPoint('BOTTOMRIGHT', self.feed, 'BOTTOMRIGHT', onLeft and 0 or strip, 0)
	if onLeft then
		self.feed.filterButton:SetPoint('BOTTOMRIGHT', self.feed, 'BOTTOMLEFT', -config.spacing, 0)
	else
		self.feed.filterButton:SetPoint('BOTTOMLEFT', self.feed, 'BOTTOMRIGHT', config.spacing, 0)
	end
	self.feed.buttonsOnLeft = onLeft

	st:SkinButton(self.feed.filterButton, config.theme, config.background)

	st:SkinButton(self.feed.reset_button, config.theme, config.background)
	self.feed.reset_button:ClearAllPoints()
	self.feed.reset_button:SetPoint('BOTTOM', self.feed.filterButton, 'TOP', 0, config.spacing)
	self:UpdateFeedButtons()
end


-- Runs every frame, so it reads the filtered list cached by the last
-- GetFilteredItems() rather than filtering the whole feed (up to 500 entries)
-- again. Everything that changes the feed or a filter refreshes that cache.
function LT:UpdateFeedVisibility(feed, elapsed)
	if self.config.feed.fade_time == 0  then
		self:UpdateFeedButtons()
		return
	end
	local filteredItems = self:GetFilteredItems(true)

	if self.testFeed then
		local now = GetTime()
		for i=1, self.config.feed.max_items do
			local item = self.feed.items[i]
			local info = filteredItems[i + self.feed.offset]
			if info then
				item.timer:SetText(st.StringFormat:ToTime(now - info.time))
			else
				item.timer:SetText('-')
			end
		end
	end

	local now = GetTime()
	for i=1, self.config.feed.max_items do
		local item = self.feed.items[i]
		local info = filteredItems[i + self.feed.offset]

		if info and self:IsFeedEntryFresh(info, now) then
			item:SetAlpha(1)
			item:Show()
		elseif item:IsShown() and item:GetAlpha() == 1 and self.feed.offset == 0 then
			UIFrameFadeOut(item, 1, 1, 0)
			item.fadeInfo.finishedFunc = function()
				item:Hide()
				item.fadeInfo = nil
			end
		end

		--item:SetShown(info and now - info.time <= self.config.feed.fade_time)
	end
	-- After the entries' alpha is set, so the buttons follow this frame's.
	self:UpdateFeedButtons()
end

-- The feed's edit mode mover. A method of its own so the tests' reset walk
-- registers the real one.
function LT:RegisterFeedMover()
	st:RegisterConfigMover(self.feed, {
		key = 'lootfeed',
		label = 'Loot Feed',
		config = function() return self.config.feed end,
		apply = function() self:UpdateLootFeedConfig(); self:UpdateFeed() end,
		configPath = { 'Loot', 'feed', 'general' },
		module = 'Loot',
		defaults = function() return st.defaults.loot.feed end,
	})
end

function LT:InitializeLootFeed()
	local config = self.config.feed
	local feed = CreateFrame('frame', st.name ..'LootFeed', UIParent)
	feed:SetSize(config.width, 20)
	st:PlaceAtPosition(feed, config.position)
	feed.items = {}
	feed.offset = 0
	feed.overlay = CreateFrame('frame', feed:GetName()..'ScrollOverlay', feed)
	feed.overlay:SetScript('OnMouseWheel', function(_, offset)
		if IsControlKeyDown() then -- Scroll to top/bottom
			offset = offset * #feed_stack
		elseif IsShiftKeyDown() then -- Page scroll
			offset = offset * self.config.feed.max_items
		elseif not IsAltKeyDown() then
			offset = offset * 3
		end

		feed.offset = min(
			max(0, feed.offset + offset),
			max(0, #self:GetFilteredItems(true) - self.config.feed.max_items)
		)

		self:UpdateFeedButtons()
		self:UpdateFeed(true, true)
	end)

	self:HookScript(feed, 'OnUpdate', 'UpdateFeedVisibility')

	self.feed = feed
	self:CreateFeedButtons()

	self.debugText = st:CreateFontString(self.feed, 'normal', '0/0')
	self.debugText:SetPoint('RIGHT', self.feed, 'LEFT', -40, 0)
	self.debugText:Hide()

	-- Before the first draw: the saved feed fills feed_stack as non-fresh entries.
	-- Then the filtered list is cached once, for the fade and for scrolling,
	-- which both read the cache (with Fade time 0 nothing else fills it until
	-- the first new entry).
	self:RestoreFeed()
	self:GetFilteredItems()

	self:UpdateLootFeedConfig()

	self:RegisterFeedMover()

	self:RegisterEvent('CHAT_MSG_LOOT', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_MONEY', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_CURRENCY', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_SKILL', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_COMBAT_HONOR_GAIN', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE', 'LootFeedHandler')
	self:RegisterEvent('CHAT_MSG_COMBAT_XP_GAIN', 'LootFeedHandler')
	-- Lets reputation entries find factions hidden under collapsed headers.
	self:RegisterEvent('FACTION_STANDING_CHANGED', 'RememberChangedFaction')

	-- Roll results (Feed/rolls.lua), now the restored feed is in place.
	self:InitializeRollResults()
end