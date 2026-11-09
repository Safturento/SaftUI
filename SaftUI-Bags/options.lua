local st = SaftUI
local INV = st:GetModule('Inventory')

local generators = st.Config.generators

-- One window's section in the /sui tree: General (its layout) and Position.
-- Clicking the window's outline in edit mode selects its General group (the
-- mover's configPath).
local function BuildWindow(id, order)
	-- Getters and setters go through INV.config, which a profile change
	-- re-points at the new profile's table.
	local position = generators.position(2, true,
		function(key) return INV.config[id].position[key] end,
		function(key, value)
			INV.config[id].position[key] = value
			INV:ApplyPosition(id)
		end,
		INV:GetAnchor(id)
	)
	position.inline = false -- a tree section, not an inline box

	local general = {
		perrow = generators.range(1, 'Items per row', 1, 12, 1),
		maxRows = generators.range(2, 'Max rows', 1, 40, 1),
		maxColumns = generators.range(3, 'Max columns', 1, 8, 1),
	}
	-- Free bag slots as a category: the bag window only, the banks have none.
	-- There is no select generator; sorting keeps the dropdown in this order.
	-- Changing it goes through the group's set, which re-lays the bags out.
	if id == 'bag' then
		general.emptySlots = {
			name = 'Empty slots',
			desc = 'Show free bag slots as an Empty Slots category. Grouped shows one slot for the bags and one for the reagent bag, each with its free count; Every slot shows each free slot.',
			type = 'select',
			order = 4,
			values = { off = 'Off', grouped = 'Grouped', all = 'Every slot' },
			sorting = { 'off', 'grouped', 'all' },
		}
	end

	return {
		name = INV.windowLabels[id],
		type = 'group',
		order = order,
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
			position = position,
		},
	}
end

-- Bags' section in the /sui tree: one subsection per window that can be placed
-- with a mover (this client's windows, for the bank layout in use).
function INV:GetConfigTable()
	if not self.config or self.config.enable == false or not self.containers.bag then return end

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
				stackItems = {
					name = 'Merge stacks',
					desc = 'Show stacks of the same item as one slot with their total count. Items in the reagent bag are merged separately from the same item in your other bags.',
					type = 'toggle',
					order = 1,
					width = 'full',
				},
			},
		},
		-- Icon size and spacing are shared by every window and both bag slot bars.
		icons = {
			name = 'Icons',
			type = 'group',
			order = 1,
			get = function(info) return INV.config[info[#info]] end,
			set = function(info, value)
				INV.config[info[#info]] = value
				INV:ApplyButtonSize()
			end,
			args = {
				iconsize = generators.range(1, 'Icon size', 20, 80, 1),
				buttonspacing = generators.range(2, 'Spacing', 0, 10, 1),
			},
		},
	}
	for order, id in ipairs(self.windowIds) do
		if self.moverIds[id] then
			args[id] = BuildWindow(id, order + 1) -- after General and Icons
		end
	end
	return {
		name = 'Bags',
		type = 'group',
		category = 'Frames', -- the /sui sidebar's group (optionswindow.lua)
		args = args,
	}
end
