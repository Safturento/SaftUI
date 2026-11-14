local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	The four texts of the Action Bars page's Text line (options.lua), on All
	bars and on each bar: the hotkey, stack count, macro name and cooldown
	numbers, each a menu item (Core's type 'item': a Show box, its name and the
	dots that open its menu). The pet and stance bars only have the hotkey and
	the cooldown numbers (AB.barTypes texts), so their pages show only those.

	AB:GetTextItem(id, kind, order): id is a bar or 'all'. Its Show box is the
	text's show; its menu holds Font, Size, Outline, then the text's Position
	block with no TO part (the text's point, THIS, the button's, AT ITS, and the
	offsets), named Position, as the menu's title names the text. Each one, the
	Show too, is a shared setting (shared.lua): it reads the effective config
	(AB:GetSetting), a change on a bar makes it the bar's own, and it carries
	AB:ShareFor's share for the marks, the hover line and the diff icon
	(options.lua). On All bars each also carries its own reset (default)
	against All bars' shipped value; on a bar the share's Reset is its one
	reset. A set on All bars runs AB:UpdateBars, on a bar AB:UpdateBar(id),
	which wait for the end of combat.

	The cooldown numbers (named Cooldown, its menu Cooldown numbers) differ:
	  - their Show is Blizzard's own "Show Numbers for Cooldowns" (skin.lua:
	    AB:ShowsCooldownNumbers, AB:SetShowCooldownNumbers), read and set as
	    the game's setting, never saved in the profile, so the item's box on
	    All bars is that setting, with no share or default (it is the game's,
	    for every bar). An open /sui draws again when it changes in Blizzard's
	    options (skin.lua), so the box follows. On a bar there's no box.
	  - their Font, Size and Outline show what's drawn until they're set
	    (AB:GetCountdownFont: Pixel Med on buttons of 36px and up, Pixel
	    below); on All bars their default is unset, and their reset unsets
	    them again.
	There is no Reset button: every setting has its own (Core's default and
	share fields, .agents/edit-mode.md).
]]

local generators = st.Config.generators

-- Each text's name on the page; the cooldown numbers' menu is titled in full.
local NAMES = {
	hotkey = 'Hotkey',
	count = 'Stack count',
	macro = 'Macro name',
	countdown = 'Cooldown',
}
local COUNTDOWN_TITLE = 'Cooldown numbers'

-- What each text is, for its tooltips.
local WHAT = {
	hotkey = 'the key bound to the button',
	count = "the button's stack or charge count",
	macro = "a macro button's name",
	countdown = 'the cooldown numbers',
}

-- The item's own tooltip: what its box shows.
local SHOW_DESCS = {
	hotkey = 'Show the key bound to each button.',
	count = "Show each button's stack or charge count.",
	macro = "Show a macro button's name.",
}
local MENU_NOTE = ' The dots hold its font, size, outline and place.'

local COUNTDOWN_ALL_DESC = "Show the time left on a button's cooldown, on every bar. This is Blizzard's own Show Numbers for Cooldowns (Options > Gameplay > Action Bars), so it changes there too, and SaftUI's profiles don't keep it. The dots hold the numbers' font, size, outline and place."
local COUNTDOWN_BAR_DESC = "The time left on a button's cooldown. All bars shows or hides the numbers on every bar (Blizzard's own Show Numbers for Cooldowns). The dots hold their font, size, outline and place on this bar."

-- What the cooldown numbers' Font, Size and Outline add: what's drawn until
-- they're set (AB:GetCountdownFont), which is also their default. field: font,
-- size or outline.
local function CountdownDefault(field)
	return ("Pixel Med's %s on buttons of 36px and up, Pixel's below (Global Settings > Fonts)"):format(field)
end
local function CountdownUnset(field)
	return " Until set, it goes by the button's size: " .. CountdownDefault(field) .. '.'
end

-- All bars' shipped text settings (config.lua).
local function Shipped(kind)
	return st.defaults.actionbars.all.text[kind]
end

-- On All bars, a text setting's own reset (Core's default field): it differs
-- from the shipped value, and its reset writes that back. The cooldown
-- numbers' font, size and outline ship unset: set is differing, and the
-- reset unsets.
local function TextDefault(self, kind, field, update)
	local key = kind .. '.' .. field
	local shipped = Shipped(kind)
	if field == 'position' then
		return {
			differs = function()
				for _, part in ipairs(self.POSITION_PARTS) do
					if self:GetSetting('all', key, part) ~= shipped[part] then return true end
				end
				return false
			end,
			reset = function()
				for _, part in ipairs(self.POSITION_PARTS) do
					self:SetSetting('all', key, shipped[part], part)
				end
				update()
			end,
			text = function() return self:ValueText(key, shipped) end,
		}
	end
	return {
		differs = function() return self:GetSetting('all', key) ~= shipped[field] end,
		reset = function()
			self:SetSetting('all', key, shipped[field])
			update()
		end,
		text = function()
			if shipped[field] == nil then return CountdownDefault(field) end
			return self:ValueText(key, shipped[field])
		end,
	}
end

-- A text's menu: Font, Size, Outline, then its Position block. Every closure
-- captures the bar and the text: a menu option reads from its own tree
-- (Core's OM.MenuRoot) and inherits only from the menu group.
local function TextMenu(self, id, kind, update)
	local what = WHAT[kind]
	local countdown = kind == 'countdown'
	local args = {
		font = {
			order = 1,
			name = 'Font',
			desc = 'The font of ' .. what .. '.',
			type = 'select',
			dialogControl = 'LSM30_Font',
			values = st.LSM:HashTable('font'),
		},
		size = generators.range(2, 'Size', 6, 32, 1, 'The size of ' .. what .. ', in points.'),
		outline = {
			order = 3,
			name = 'Outline',
			desc = 'The outline drawn around ' .. what .. '.',
			type = 'select',
			values = st:GetModule('Fonts').outlines,
		},
		position = generators.position(4, false,
			function(part) return self:GetSetting(id, kind .. '.position', part) end,
			function(part, value)
				if self:SetFromPage(id, kind .. '.position', value, part) then update() end
			end,
			nil,
			countdown
				and 'Where the cooldown numbers sit on the button: the point of the numbers that is anchored (THIS), the point of the button it is anchored to (AT ITS), and how far they are moved from there.'
				or 'Where ' .. what .. ' sits on the button: the point of the text that is anchored (THIS), the point of the button it is anchored to (AT ITS), and how far it is moved from there.',
			'Position'
		),
	}
	for field, option in pairs(args) do
		option.share = self:ShareFor(id, kind .. '.' .. field)
		if id == 'all' then option.default = TextDefault(self, kind, field, update) end
		if countdown and field ~= 'position' then option.desc = option.desc .. CountdownUnset(field) end
	end

	local get = function(info) return self:GetSetting(id, kind .. '.' .. info[#info]) end
	if countdown then
		-- What's drawn until set.
		get = function(info)
			local font, size, outline = self:GetCountdownFont(self:GetBarConfig(id))
			return ({ font = font, size = size, outline = outline })[info[#info]]
		end
	end
	return {
		type = 'group',
		name = countdown and COUNTDOWN_TITLE or NAMES[kind],
		get = get,
		set = function(info, value)
			if self:SetFromPage(id, kind .. '.' .. info[#info], value) then update() end
		end,
		args = args,
	}
end

-- One text's item on id's page (a bar or 'all'), a quarter of the Text line.
function AB:GetTextItem(id, kind, order)
	local update = function() self:UpdateFor(id) end
	local item = {
		type = 'item',
		size = 'small',
		order = order,
		name = NAMES[kind],
		menu = TextMenu(self, id, kind, update),
	}
	if kind == 'countdown' then
		item.menuTitle = COUNTDOWN_TITLE
		if id == 'all' then
			-- Blizzard's own setting, read and set at call time (see the top).
			item.desc = COUNTDOWN_ALL_DESC
			item.get = function() return self:ShowsCooldownNumbers() end
			item.set = function(_, value) self:SetShowCooldownNumbers(value) end
		else
			item.desc = COUNTDOWN_BAR_DESC
			item.get = false
		end
		return item
	end

	local key = kind .. '.show'
	item.desc = SHOW_DESCS[kind] .. MENU_NOTE
	item.get = function() return self:GetSetting(id, key) end
	item.set = function(_, value)
		if self:SetFromPage(id, key, value) then update() end
	end
	item.share = self:ShareFor(id, key)
	if id == 'all' then
		local shipped = Shipped(kind).show
		item.default = {
			differs = function() return self:GetSetting('all', key) ~= shipped end,
			reset = function()
				self:SetSetting('all', key, shipped)
				update()
			end,
			value = function() return shipped end,
		}
	end
	return item
end
