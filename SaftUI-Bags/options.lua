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
				args = {
					perrow = generators.range(1, 'Items per row', 1, 12, 1),
					maxRows = generators.range(2, 'Max rows', 1, 40, 1),
					maxColumns = generators.range(3, 'Max columns', 1, 8, 1),
				},
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
		-- Icon size and spacing are shared by every window and both bag slot bars.
		icons = {
			name = 'Icons',
			type = 'group',
			order = 0,
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
			args[id] = BuildWindow(id, order)
		end
	end
	return {
		name = 'Bags',
		type = 'group',
		args = args,
	}
end
