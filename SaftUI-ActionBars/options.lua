local st = SaftUI
local AB = st:GetModule('ActionBars')

--[[
	The action bars' edit mode movers and their /sui page.

	Movers. ab_bar1..ab_bar8, ab_pet and ab_stance move the bars themselves (the
	SaftUI_ActionBar1..8, SaftUI_PetBar and SaftUI_StanceBar headers), as the
	single unit frames' movers do. AB:LayoutBar sizes and places every bar, a
	disabled one too, one its Visibility setting hides, the pet bar without a
	pet and the stance bar without forms (laid out as one button), and the edit
	mode outline is anchored to the bar's edges, so the outline always covers
	the bar's whole layout. Its label says when a bar is off, has nothing to
	show (the stance bar's 'no forms'), is shown only in combat, or is faded.
	Drags and nudges write the bar's position, and AB:LayoutBar places it
	through st:SafeReposition: the bars are secure, so they can't be moved in
	combat. Clicking a bar opens its page.

	ab_extra, ab_zone and ab_vehicleleave move the extra buttons' holders
	(extras.lua), which always have a size. Their outlines say when the
	buttons show, as they mostly don't. Clicking one opens its General tab.

	/sui -> Action Bars is a picker ('Bar'), with nothing above it: All bars,
	then each bar, then each extra button. All bars and each bar are one page
	with no tabs, in sections:
	  All bars
	    - Look: Theme and Background (actionbars.theme and .background, which
	      every button is drawn with, the leave vehicle button too).
	    - Layout: Buttons, Buttons per row, Button size, Spacing, First button.
	    - Visibility: Show (always, in combat only, or faded until moused
	      over) and Faded opacity, shown while All bars or any bar fades.
	    - Text: the hotkey, stack count, macro name and cooldown numbers, four
	      menu items on one line (textoptions.lua). The cooldown numbers' box
	      is Blizzard's own "Show Numbers for Cooldowns" (skin.lua: the game's
	      setting, read and set as it is, never in the profile).
	  A bar
	    - This bar: Enable.
	    - Layout, Visibility and Text as on All bars, showing what the bar has
	      (its own value, or All bars'). Buttons and Buttons per row go up to
	      the bar's own 12 or 10; Faded opacity shows while the bar fades; the
	      pet and stance bars have only the hotkey and the cooldown numbers
	      (AB.barTypes texts), and the cooldown numbers have no box on a bar.
	    - Position, last. The relative frame typed there goes through
	      st:ValidateAnchor with the bar, so a bar can't be anchored to
	      itself, its own buttons, or a bar anchored to it.
	Layout, Visibility and the texts are shared settings (shared.lua): each
	reads the effective config (AB:GetSetting), a change on a bar makes the
	setting the bar's own (unless it is given what the bar already shows:
	AB:SetFromPage), and each carries AB:ShareFor's share (Core's share
	field): on a bar its own mark and hover line (Own, Reset, Apply to: All |
	Multiple); on All bars the diff icon naming the bars that own it, with
	their values (AB:SettingText), and Apply to. Every reset is per setting:
	on All bars each setting, Theme and Background carry their own (Core's
	default field) against the shipped value; on a bar a shared setting's is
	its share's Reset (follow All bars again), and Enable and Position carry
	their own against the bar's shipped value (a Position's goes through
	st:ValidateAnchor, and says why when it would make a loop). There's no Reset button.

	Then one section per extra button, with General: Scale for Blizzard's extra
	action button and zone ability, Size for SaftUI's leave vehicle button, and
	the Position option.
	Every option applies at once through AB:UpdateBar or AB:UpdateBars
	(bars.lua; a bar's Position through AB:LayoutBar), AB:LayoutExtra
	(extras.lua) or, for the Theme and Background, AB:UpdateConfig (which
	re-skins every bar and the leave vehicle button, skin.lua's StyleBar
	reading actionbars.theme and .background). /sui can't be open in combat,
	and each of those waits for the end of combat anyway; a profile switch in
	combat waits too (AB:UpdateConfig).
]]

local generators = st.Config.generators
local floor = math.floor

local ALL_LABEL = 'All bars'

local VISIBILITY_VALUES = {
	always = 'Always',
	combat = 'In combat only',
	mouseover = 'Faded until moused over',
}
local VISIBILITY_ORDER = { 'always', 'combat', 'mouseover' }

-- The second line of a bar's outline label, for each way a bar can be hidden.
local HIDDEN_LABELS = {
	combat = 'in combat',
	mouseover = 'mouseover',
}

-- The second line of each extra button's outline label: when it's on screen.
local EXTRA_NOTES = {
	extra = 'when active',
	zone = 'when active',
	vehicleleave = 'vehicles, flights, possess',
}

-- The extra buttons that are Blizzard's, sized by a Scale setting. The others
-- (SaftUI's leave vehicle button) have a Size setting.
local SCALED_EXTRAS = {
	extra = true,
	zone = true,
}

-- A frame as the page words it: a SaftUI bar by its label, the screen for
-- UIParent, any other frame by its name.
local function FrameText(self, name)
	if name == 'UIParent' then return 'the screen' end
	for _, id in ipairs(self.BAR_IDS) do
		if self:GetBarFrameName(id) == name then return self:GetBarLabel(id) end
	end
	return tostring(name)
end

-- A bar's own position, as the profile stores it.
local PLACE_PARTS = { 'point', 'frame', 'rel_point', 'x_off', 'y_off' }

function AB:GetBarLabel(id)
	if id == 'all' then return ALL_LABEL end
	return self.BAR_LABELS[id] or id
end

------------------------------------
--- Movers --------------------------
------------------------------------

-- The bar's name on its outline, and on a second line why it may not be seen:
-- off, nothing to show, only in combat, or faded.
function AB:UpdateMoverLabel(id)
	local mover = self.movers[id]
	local config = self.config[id] and self:GetBarConfig(id)
	if not (mover and mover.label and config) then return end
	local state
	if not config.enable then
		state = 'off'
	elseif not self:IsBarAvailable(id) then
		state = self.barTypes[id].unavailableLabel
	else
		state = HIDDEN_LABELS[config.visibility]
	end
	mover.label:SetText(self:GetBarLabel(id) .. (state and ('\n' .. state) or ''))
end

-- Once per bar, when the bars are built (AB:Build). A click opens the bar's
-- page (its pick: the page has no tabs).
function AB:RegisterBarMover(id)
	local bar = self.bars[id]
	if not bar or self.movers[id] then return end
	self.movers[id] = st:RegisterConfigMover(bar, {
		key = 'ab_' .. id,
		label = self:GetBarLabel(id),
		-- Read through self.config on every call: a profile change replaces it.
		config = function() return self.config[id] end,
		apply = function() self:LayoutBar(id) end,
		configPath = { 'ActionBars', id },
	})
	self:UpdateMoverLabel(id)
end

-- Once per extra button, when they're set up (AB:SetupExtras). The holder
-- always has the button's size, so the outline shows where it will be.
function AB:RegisterExtraMover(id)
	local holder = self.extras[id]
	if not holder or self.movers[id] then return end
	self.movers[id] = st:RegisterConfigMover(holder, {
		key = 'ab_' .. id,
		label = self.EXTRA_LABELS[id] .. '\n' .. EXTRA_NOTES[id],
		-- Read through self.config on every call: a profile change replaces it.
		config = function() return self.config[id] end,
		apply = function() self:LayoutExtra(id) end,
		configPath = { 'ActionBars', id, 'general' },
	})
end

------------------------------------
--- Values as text ------------------
------------------------------------

local function AnchorLabel(point)
	return st.FRAME_ANCHORS[point] or tostring(point)
end

local function Offset(value)
	return tostring(tonumber(value) or 0)
end

--[[
	A shared setting's value as the page's tooltips show it (the diff icon's
	lines, Own's and a reset's): key a shared key (shared.lua), value as the
	effective config holds it, a text's position as a table of its four parts
	({ point, rel_point, x_off, y_off }):
	  a number as it is; fade_alpha as a percent ('30%'); visibility and
	  growth by their labels; '<kind>.show' 'Shown' or 'Hidden'; a font by its
	  name; an outline by the Fonts module's label; an unset cooldown numbers'
	  font, size or outline 'By button size'; a position '<point> to <rel_point>,
	  <x>, <y>' with st.FRAME_ANCHORS' labels ('Top Right to Top Right, -3, -3').
]]
function AB:ValueText(key, value)
	local field = key:match('^%a+%.(%a+)$')
	if field == 'position' then
		value = value or {}
		return ('%s to %s, %s, %s'):format(AnchorLabel(value.point), AnchorLabel(value.rel_point),
			Offset(value.x_off), Offset(value.y_off))
	elseif field == 'show' then
		return value and 'Shown' or 'Hidden'
	elseif field then
		if value == nil then return 'By button size' end
		if field == 'outline' then return st:GetModule('Fonts').outlines[value] or tostring(value) end
		return tostring(value)
	elseif key == 'fade_alpha' then
		return floor((tonumber(value) or 0) * 100 + 0.5) .. '%'
	elseif key == 'visibility' then
		return VISIBILITY_VALUES[value] or tostring(value)
	elseif key == 'growth' then
		return self.GROWTH_VALUES[value] or tostring(value)
	end
	return tostring(value)
end

-- Buttons and Buttons per row as bar shows them: no more than its buttons.
-- (nil: the value as it is.)
local function Clamped(self, bar, key, value)
	if (key == 'buttons' or key == 'perrow') and bar and self.bars[bar] and tonumber(value) then
		return math.min(value, #self.bars[bar].buttons)
	end
	return value
end

--[[
	id's value of the shared key (a bar or 'all'), as ValueText words it.
	clampFor: the bar whose button count Buttons and Buttons per row are held
	to, as that bar shows them (by default id's own: All bars' have no count),
	so a bar's Own tooltip names what following All bars would show there.
]]
function AB:SettingText(id, key, clampFor)
	if key:match('%.position$') then
		local parts = {}
		for _, part in ipairs(self.POSITION_PARTS) do parts[part] = self:GetSetting(id, key, part) end
		return self:ValueText(key, parts)
	end
	return self:ValueText(key, Clamped(self, clampFor or id, key, self:GetSetting(id, key)))
end

--[[
	A change a bar's page makes to the shared key (part: a position's part).
	A bar that follows All bars for the key and is given what it already shows
	changes nothing: no write, no mark, no update, so choosing the highlighted
	entry of a list, or typing the number a slider shows, doesn't make the
	setting the bar's own. What it shows is the clamped Buttons and Buttons per
	row, and the cooldown numbers' drawn font, size and outline (which stay
	unset). All bars and a bar that owns the key write what they're given.
	Returns whether it wrote.
]]
function AB:SetFromPage(id, key, value, part)
	if id ~= 'all' and not self:IsOwn(id, key) then
		local shown
		local field = key:match('^countdown%.(%a+)$')
		if field == 'font' or field == 'size' or field == 'outline' then
			local font, size, outline = self:GetCountdownFont(self:GetBarConfig(id))
			shown = ({ font = font, size = size, outline = outline })[field]
		else
			shown = Clamped(self, id, key, self:GetSetting(id, key, part))
		end
		if value == shown then return false end
	end
	self:SetSetting(id, key, value, part)
	return true
end

-- Applies a change on id's page: every bar for All bars, else the bar.
function AB:UpdateFor(id)
	if id == 'all' then self:UpdateBars() else self:UpdateBar(id) end
end

------------------------------------
--- Sharing -------------------------
------------------------------------

-- { {key, label} } for bar ids.
local function Targets(self, ids)
	local list = {}
	for _, id in ipairs(ids) do list[#list + 1] = { key = id, label = self:GetBarLabel(id) } end
	return list
end

--[[
	The share (Core's share field, optionsmodel.lua) of the shared key on id's
	page, a bar or 'all'. Everything the kit says comes from here: All bars is
	the source, each bar a member page named by its label, a member a bar
	(noun), and a bar's name in a sentence its pageText.
	  On All bars: shared (All bars' value), differs (each bar that owns the
	  setting, with its value: owning is differing, even at All bars' value),
	  targets (those bars), applyAll (every bar follows) and apply (the picked
	  bars follow).
	  On a bar: own, reset (follow All bars again), shared, targets (every
	  other bar that has the setting: no pet or stance bar for a stack count
	  or macro name), applyAll (All bars takes the bar's value, every bar
	  follows) and apply (the picked bars take it as their own, or follow
	  when it's All bars').
	Each action applies at once: AB:UpdateBar for the bars it changed (and,
	on a bar, the bar itself), AB:UpdateBars for every bar.
]]
function AB:ShareFor(id, key)
	local function shared() return self:SettingText('all', key, id ~= 'all' and id or nil) end
	-- What a member is, for the kit's texts ('every bar', 'which bars'); and a
	-- bar's name in a sentence: the pet and stance bars read as common nouns
	-- ('from the Pet bar'), Bar 1 to 8 as names.
	local noun = { 'bar', 'bars' }
	local label = self:GetBarLabel(id)
	if id == 'all' then
		return {
			source = ALL_LABEL,
			noun = noun,
			shared = shared,
			differs = function()
				local list = {}
				for _, owner in ipairs(self:OwnersOf(key)) do
					list[#list + 1] = { name = self:GetBarLabel(owner), value = self:SettingText(owner, key) }
				end
				return list
			end,
			targets = function() return Targets(self, self:OwnersOf(key)) end,
			applyAll = function()
				self:ApplyToAll('all', key)
				self:UpdateBars()
			end,
			apply = function(_, keys)
				self:ApplyTo('all', key, keys)
				for _, target in ipairs(keys) do self:UpdateBar(target) end
			end,
		}
	end
	return {
		source = ALL_LABEL,
		page = label,
		pageText = (id == 'pet' or id == 'stance') and ('the ' .. label) or label,
		noun = noun,
		own = function() return self:IsOwn(id, key) end,
		reset = function()
			self:ResetSetting(id, key)
			self:UpdateBar(id)
		end,
		shared = shared,
		targets = function()
			local others = {}
			for _, other in ipairs(self.BAR_IDS) do
				if other ~= id and self:HasSetting(other, key) then others[#others + 1] = other end
			end
			return Targets(self, others)
		end,
		applyAll = function()
			self:ApplyToAll(id, key)
			self:UpdateBars()
		end,
		apply = function(_, keys)
			self:ApplyTo(id, key, keys)
			self:UpdateBar(id)
			for _, target in ipairs(keys) do self:UpdateBar(target) end
		end,
	}
end

-- On All bars, a Layout or Visibility setting's own reset (Core's default
-- field): it differs from All bars' shipped value, and its reset puts that
-- back on All bars (bars owning the setting keep theirs).
local function SharedDefault(self, key)
	local shipped = st.defaults.actionbars.all[key]
	return {
		differs = function() return self:GetSetting('all', key) ~= shipped end,
		reset = function()
			self:SetSetting('all', key, shipped)
			self:UpdateBars()
		end,
		text = function() return self:ValueText(key, shipped) end,
	}
end

------------------------------------
--- The page ------------------------
------------------------------------

-- Gives every option of args its share on id's page and, on All bars, its
-- own reset.
local function Shared(self, id, args)
	for key, option in pairs(args) do
		option.share = self:ShareFor(id, key)
		if id == 'all' then option.default = SharedDefault(self, key) end
	end
	return args
end

-- The Layout section on id's page (a bar or 'all'). numButtons: what
-- Buttons and Buttons per row go up to, and the most they show.
local function LayoutGroup(self, id, numButtons)
	local barType = self.barTypes[id]
	local buttonsDesc
	if id == 'all' then
		buttonsDesc = "How many of each bar's buttons it shows, up to its own 12 or 10. The keys of the others do nothing."
	else
		buttonsDesc = ('How many of the bar\'s %d buttons it shows. The keys of the others do nothing.'):format(numButtons)
		if barType and barType.buttonsNote then
			buttonsDesc = buttonsDesc .. ' ' .. barType.buttonsNote
		end
	end
	local args = Shared(self, id, {
		buttons = generators.range(1, 'Buttons', 1, numButtons, 1, buttonsDesc),
		perrow = generators.range(2, 'Buttons per row', 1, numButtons, 1,
			'How many buttons sit in a row before the next row starts. 1 makes a column.'),
		size = generators.range(3, 'Button size', 16, 80, 1, 'The whole button, its border included.'),
		spacing = generators.range(4, 'Spacing', 0, 20, 1, 'The gap between buttons.'),
		growth = {
			order = 5,
			name = 'First button',
			desc = 'The corner of the bar its first button sits in. Rows fill across from it and the next row starts away from it.',
			type = 'select',
			values = self.GROWTH_VALUES,
			sorting = self.GROWTH_ORDER,
		},
	})
	return {
		name = 'Layout',
		type = 'group',
		inline = true,
		order = 2,
		-- Buttons and Buttons per row show no more than the bar has, as a bar
		-- following All bars' 12 does on the pet bar's 10.
		get = function(info)
			local key = info[#info]
			local value = self:GetSetting(id, key)
			if key == 'buttons' or key == 'perrow' then return math.min(value, numButtons) end
			return value
		end,
		set = function(info, value)
			if self:SetFromPage(id, info[#info], value) then self:UpdateFor(id) end
		end,
		args = args,
	}
end

-- Whether a bar shows Faded opacity: on All bars while All bars or any bar
-- fades until moused over, on a bar while it does.
local function FadeHidden(self, id)
	if id ~= 'all' then
		return function() return self:GetSetting(id, 'visibility') ~= 'mouseover' end
	end
	return function()
		if self:GetSetting('all', 'visibility') == 'mouseover' then return false end
		for _, bar in ipairs(self.BAR_IDS) do
			if self.config[bar] and self:GetSetting(bar, 'visibility') == 'mouseover' then return false end
		end
		return true
	end
end

-- The Visibility section on id's page.
local function VisibilityGroup(self, id)
	local fade = generators.range(2, 'Faded opacity', 0, 1, 0.05, id == 'all'
		and "How visible a bar faded until moused over is while the mouse isn't over it."
		or "How visible the bar is while the mouse isn't over it.")
	fade.isPercent = true
	fade.hidden = FadeHidden(self, id)
	return {
		name = 'Visibility',
		type = 'group',
		inline = true,
		order = 3,
		get = function(info) return self:GetSetting(id, info[#info]) end,
		set = function(info, value)
			if self:SetFromPage(id, info[#info], value) then self:UpdateFor(id) end
		end,
		args = Shared(self, id, {
			visibility = {
				order = 1,
				name = 'Show',
				desc = "Always, only in combat, or faded until the mouse is over it. Keybind mode (/sui kb) shows every enabled bar while it's on.",
				type = 'select',
				values = VISIBILITY_VALUES,
				sorting = VISIBILITY_ORDER,
			},
			fade_alpha = fade,
		}),
	}
end

-- The Text section on id's page: the texts its buttons have, one line of
-- menu items (textoptions.lua).
local function TextGroup(self, id)
	local barType = id ~= 'all' and self.barTypes[id]
	local used = barType and barType.texts
	local args = {}
	for i, kind in ipairs(self.TEXT_KINDS) do
		if not used or used[kind] then
			args[kind] = self:GetTextItem(id, kind, i)
		end
	end
	return {
		name = 'Text',
		type = 'group',
		inline = true,
		order = 4,
		args = args,
	}
end

-- All bars' page: Look, Layout, Visibility and Text (see the top).
function AB:GetAllBarsOptions(order)
	-- The Theme and Background of every bar button and of the leave vehicle
	-- button. skin.lua reads them each time a bar is styled, so AB:UpdateConfig
	-- (every bar, then the extras) applies them at once; it waits for the end of
	-- combat if need be. Each resets to SaftUI's theme.
	local look = {
		theme = generators.theme(1, 'The border of every action button, the leave vehicle button too.'),
		background = generators.background(2),
	}
	for key, option in pairs(look) do
		option.get = function() return self.config[key] end
		option.set = function(_, value)
			self.config[key] = value
			self:UpdateConfig()
		end
		local shipped = st.defaults.actionbars[key]
		option.default = {
			differs = function() return self.config[key] ~= shipped end,
			reset = function()
				self.config[key] = shipped
				self:UpdateConfig()
			end,
			value = function() return shipped end,
		}
	end

	return {
		name = ALL_LABEL,
		desc = 'The settings every bar follows until it changes one of its own.',
		type = 'group',
		order = order,
		args = {
			look = {
				name = 'Look',
				type = 'group',
				inline = true,
				order = 1,
				args = look,
			},
			layout = LayoutGroup(self, 'all', self.NUM_BUTTONS),
			visibility = VisibilityGroup(self, 'all'),
			text = TextGroup(self, 'all'),
		},
	}
end

-- One bar's page: This bar, Layout, Visibility, Text, then Position (see the
-- top). The ranges go up to the bar's own number of buttons, and Text has the
-- texts its buttons use.
function AB:GetBarOptions(id, order)
	local numButtons = #self.bars[id].buttons
	local shipped = st.defaults.actionbars[id]

	local enable = generators.enable(1, 'A disabled bar is hidden and its keys do nothing.', 'small')
	enable.get = function() return self.config[id].enable end
	enable.set = function(_, value)
		self.config[id].enable = value
		self:UpdateBar(id)
	end
	enable.default = {
		differs = function() return self.config[id].enable ~= shipped.enable end,
		reset = function()
			self.config[id].enable = shipped.enable
			self:UpdateBar(id)
		end,
		value = function() return shipped.enable end,
	}

	-- Every SetPoint parameter is editable, the relative frame included. Passing
	-- the bar makes a typed frame go through st:ValidateAnchor. Last.
	local position = generators.position(1000, true,
		function(key) return self.config[id].position[key] end,
		function(key, value)
			self.config[id].position[key] = value
			self:LayoutBar(id)
		end,
		self.bars[id]
	)
	local place = shipped.position
	position.default = {
		differs = function()
			local now = self.config[id].position
			for _, part in ipairs(PLACE_PARTS) do
				local a, b = now[part], place[part]
				if part == 'x_off' or part == 'y_off' then a, b = tonumber(a) or 0, tonumber(b) or 0 end
				if a ~= b then return true end
			end
			return false
		end,
		reset = function()
			-- As a typed frame is: where it ships may be on a bar that now sits on this one.
			local ok, err = st:ValidateAnchor(self.bars[id], place.frame)
			if not ok then
				st:Print(("%s's position can't go back to its default: %s."):format(self:GetBarLabel(id), err))
				return
			end
			local now = self.config[id].position
			for _, part in ipairs(PLACE_PARTS) do now[part] = place[part] end
			self:LayoutBar(id)
		end,
		text = ('%s to %s of %s, %s, %s'):format(AnchorLabel(place.point), AnchorLabel(place.rel_point),
			FrameText(self, place.frame), Offset(place.x_off), Offset(place.y_off)),
	}

	return {
		name = self:GetBarLabel(id),
		type = 'group',
		order = order,
		args = {
			thisbar = {
				name = 'This bar',
				type = 'group',
				inline = true,
				order = 1,
				args = { enable = enable },
			},
			layout = LayoutGroup(self, id, numButtons),
			visibility = VisibilityGroup(self, id),
			text = TextGroup(self, id),
			position = position,
		},
	}
end

-- One extra button's section: General with its Scale or Size, then the
-- Position option.
function AB:GetExtraOptions(id, order)
	local size
	if SCALED_EXTRAS[id] then
		size = generators.range(1, 'Scale', 0.5, 2, 0.05,
			"The size of Blizzard's button and the art around it. 100% is Blizzard's size.")
		size.isPercent = true
	else
		size = generators.range(1, 'Button size', 16, 80, 1, 'The whole button, its border included.')
	end

	-- Every SetPoint parameter is editable, the relative frame included. Passing
	-- the holder makes a typed frame go through st:ValidateAnchor, which rejects
	-- what's anchored to the holder (the extra action button) too.
	local position = generators.position(1000, true,
		function(key) return self.config[id].position[key] end,
		function(key, value)
			self.config[id].position[key] = value
			self:LayoutExtra(id)
		end,
		self.extras[id]
	)

	return {
		name = self.EXTRA_LABELS[id],
		type = 'group',
		order = order,
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[id][info[#info]] end,
				set = function(info, value)
					self.config[id][info[#info]] = value
					self:LayoutExtra(id)
				end,
				args = {
					[SCALED_EXTRAS[id] and 'scale' or 'size'] = size,
					position = position,
				},
			},
		},
	}
end

-- The Action Bars page of /sui: the picker, All bars first, then one entry per
-- bar, then one per extra button; nothing above it. Clicking a bar in edit
-- mode picks its entry (the mover's configPath). Absent until the bars are
-- built.
function AB:GetConfigTable()
	if not self.built then return end
	local args = { all = self:GetAllBarsOptions(0) }
	for i, id in ipairs(self.BAR_IDS) do
		if self.bars[id] then
			args[id] = self:GetBarOptions(id, i)
		end
	end
	for i, id in ipairs(self.EXTRA_IDS) do
		if self.extras[id] then
			args[id] = self:GetExtraOptions(id, #self.BAR_IDS + i)
		end
	end
	return {
		name = 'Action Bars',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionslayout.lua)
		-- All bars, the bars and the extra buttons are the page's picker.
		childGroups = 'select',
		pickerLabel = 'Bar',
		args = args,
	}
end
