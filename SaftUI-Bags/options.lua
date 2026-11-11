local st = SaftUI
local INV = st:GetModule('Inventory')

local generators = st.Config.generators

-- One window's section in the /sui tree: General (its layout, then its
-- Position). Clicking the window's outline in edit mode selects its General
-- group (the mover's configPath).
local function BuildWindow(id, order)
	-- Getters and setters go through INV.config, which a profile change
	-- re-points at the new profile's table.
	local general = {
		perrow = generators.range(1, 'Items per row', 1, 12, 1,
			'How many item slots sit side by side inside a category.'),
		maxRows = generators.range(2, 'Max rows', 1, 40, 1,
			'How many rows of item slots the window shows before it scrolls.'),
		maxColumns = generators.range(3, 'Max columns', 1, 8, 1,
			'How many columns of categories the window is split into.'),
		-- Last in General.
		position = generators.position(1000, true,
			function(key) return INV.config[id].position[key] end,
			function(key, value)
				INV.config[id].position[key] = value
				INV:ApplyPosition(id)
			end,
			INV:GetAnchor(id)
		),
	}
	-- There is no select generator; sorting keeps the dropdown in this order.
	-- The view, the same choice as the title bar's buttons; INV:SetView saves
	-- it and lays the window out, and does nothing for the view it has.
	general.view = {
		name = 'View',
		desc = "How this window lays its items out: One bag (every bag's items in one grid, special bags and Currencies under it), Multi bag (a section per bag), Compact (categories in columns) or Rows (a row per category). The same as the buttons in the window's title bar.",
		type = 'select',
		order = 4,
		values = INV.viewLabels,
		sorting = INV.viewIds,
		set = function(_, value) INV:SetView(id, value) end,
	}
	-- Free bag slots as a category. Changing it goes through the group's set,
	-- which packs every window afresh, as any layout setting does (HoldLayout).
	general.emptySlots = {
		name = 'Empty slots',
		desc = 'Show free bag slots as an Empty Slots category. Grouped shows one slot for each kind of bag (your bags, the reagent bag, the bank, the warband bank) and for each bag with its own section in One bag and Multi bag, each with its free count; Every slot shows each free slot.',
		type = 'select',
		order = 5,
		values = { off = 'Off', grouped = 'Grouped', all = 'Every slot' },
		sorting = { 'off', 'grouped', 'all' },
	}

	return {
		name = INV.windowLabels[id],
		type = 'group',
		order = order,
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return INV.config[id][info[#info]] end,
				set = function(info, value)
					INV.config[id][info[#info]] = value
					-- Lays every window out again; a window that isn't made yet
					-- (the bank before its first visit) only has its outline resized.
					INV:UpdateConfig()
					INV:SyncAnchorSize(id)
				end,
				args = general,
			},
		},
	}
end

-- A setting of the bag fonts table (fonts.titles, fonts.icons): the key of one
-- of the profile's font objects, like the Font option of the other pages.
local function FontOption(order, name, key, desc)
	local option = generators.font(order, desc)
	option.name = name
	option.get = function() return INV.config.fonts[key] end
	option.set = function(_, value)
		INV.config.fonts[key] = value
		INV:UpdateConfig()
	end
	return option
end

-- A Theme or Background option for the item and currency slots: the same
-- choices as the windows' own, named apart from them.
local function SlotOption(option, name)
	option.name = name
	return option
end

-- Bags' section in the /sui tree: General (the settings for every window), the
-- windows' Look and Icons, then one subsection per window that can be placed
-- with a mover (this client's windows, for the bank layout in use), then
-- Categories. With the bags turned off, only General, with the Enable toggle
-- that turns them back on.
function INV:GetConfigTable()
	if not self.config then return end

	local enable = generators.toggle(1, 'Enable',
		'Turn SaftUI\'s bags and bank off or on. Takes effect after /reload.', 'small')
	-- A reload builds or skips the windows; nothing here can do either live.
	enable.set = function(_, value)
		INV.config.enable = value
		st:Print('Reload your UI to apply.')
	end

	if self.config.enable == false then
		return {
			name = 'Bags',
			type = 'group',
			category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
			args = {
				general = {
					name = 'General',
					type = 'group',
					order = 0,
					get = function(info) return INV.config[info[#info]] end,
					args = { enable = enable },
				},
			},
		}
	end
	if not self.containers.bag then return end

	local args = {
		-- Settings for every window. Merge Stacks used to be in the bag window's
		-- Settings menu.
		general = {
			name = 'General',
			type = 'group',
			order = 0,
			get = function(info) return INV.config[info[#info]] end,
			set = function(info, value)
				INV.config[info[#info]] = value
				INV:QueueUpdate(true)
			end,
			args = {
				enable = enable,
				stackItems = generators.toggle(2, 'Merge stacks',
					'Show stacks of the same item as one slot with their total count. Items in the reagent bag are merged separately from the same item in your other bags.',
					'small'),
				inverted = generators.toggle(3, 'Inverted',
					'Order the categories in each column shortest first. Off puts the tallest first.',
					'small'),
				combinedBank = {
					order = 4,
					name = 'Combined bank',
					desc = 'Show the bank and the warband bank as one window instead of separate ones. Takes effect the next time you open the bank.',
					type = 'toggle',
					size = 'small',
					set = function(info, value)
						INV.config[info[#info]] = value
						-- Registers the movers of the layout now in use.
						INV:UpdateConfig()
					end,
				},
				autorepair = generators.toggle(5, 'Auto repair',
					'Repair all your gear when you open a vendor that can repair, if you have the gold.',
					'small'),
				autovendor = generators.toggle(6, 'Auto sell junk',
					'Sell your junk to a vendor when you open one. Not in combat.',
					'small'),
				scrollSpeed = generators.range(7, 'Scroll speed', 1, 10, 1,
					'How many rows of item slots one notch of the mouse wheel scrolls.'),
			},
		},
		-- How the windows look: the windows' and the slots' Theme and Background,
		-- text, padding and category titles.
		look = {
			name = 'Look',
			type = 'group',
			order = 1,
			get = function(info) return INV.config[info[#info]] end,
			set = function(info, value)
				INV.config[info[#info]] = value
				INV:ApplyButtonSize() -- re-styles every window and slot and resizes their movers' outlines
			end,
			args = {
				theme = generators.theme(1, 'The border of the bag and bank windows and their search box.'),
				background = generators.background(1.5),
				buttontheme = SlotOption(generators.theme(2, 'The border of the item and currency slots.'), 'Slot theme'),
				buttonbackground = SlotOption(generators.background(2.5), 'Slot background'),
				padding = generators.range(3, 'Padding', 0, 30, 1,
					"The gap between a window's edge and its contents."),
				categoryTitleHeight = generators.range(4, 'Category title height', 20, 80, 1,
					'How tall each category title is.'),
				titles = FontOption(5, 'Title font', 'titles',
					'The font of the category titles and the search box.'),
				icons = FontOption(6, 'Icon font', 'icons',
					'The font of the numbers on the item and currency slots: item level and stack count.'),
			},
		},
		-- Icon size and spacing are shared by every window and both bag slot bars.
		icons = {
			name = 'Icons',
			type = 'group',
			order = 2,
			get = function(info) return INV.config[info[#info]] end,
			set = function(info, value)
				INV.config[info[#info]] = value
				INV:ApplyButtonSize()
			end,
			args = {
				iconsize = generators.range(1, 'Icon size', 20, 80, 1,
					'The height of an item slot; its width follows. Applies to every window and bag slot bar.'),
				buttonspacing = generators.range(2, 'Spacing', 0, 10, 1,
					'The gap between item slots, in every window and bag slot bar.'),
			},
		},
	}
	for order, id in ipairs(self.windowIds) do
		if self.moverIds[id] then
			args[id] = BuildWindow(id, order + 2) -- after General, Look and Icons
		end
	end
	-- The category list and the selected category's editor, after the windows:
	-- one row, the bagcategories widget (categoriestab.lua).
	args.categories = {
		name = 'Categories',
		type = 'group',
		order = #self.windowIds + 3,
		args = {
			categories = {
				type = 'bagcategories',
				size = 'wide',
				name = 'Categories',
				desc = 'Every bag category in the order they claim items: an item goes to the first one that catches it. Drag a category by its handle to move it, and select one to edit it.',
			},
		},
	}
	return {
		name = 'Bags',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
		args = args,
	}
end
