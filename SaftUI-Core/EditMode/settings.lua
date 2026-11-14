local st = SaftUI
local EM = st.EditModeFrames

-- Edit mode's grid, snapping, Dim world and Coordinates settings: where they live, how they are set
-- (EM:SetSetting, which the bar's controls and the "Edit mode" tab in /sui both
-- use), and the screen events that redraw the grid. The values live in the
-- profile (st.defaults.editmode); the bar (Bar/) shows them.

EM.MIN_GRID_SIZE, EM.MAX_GRID_SIZE, EM.GRID_STEP = 8, 128, 4

function EM:GetSettings()
	return st.config.profile.editmode
end

-- Sets one of the settings. Grid size is made a whole number from MIN_GRID_SIZE
-- to MAX_GRID_SIZE first (a value that is not a number changes nothing). Then
-- 'SettingsChanged' (key) tells the grid and the bar, and an open /sui shows
-- the new value on its row.
function EM:SetSetting(key, value)
	if key == 'grid_size' then
		if type(value) ~= 'number' or value ~= value then return end
		value = math.max(self.MIN_GRID_SIZE, math.min(self.MAX_GRID_SIZE, math.floor(value + 0.5)))
	end
	self:GetSettings()[key] = value
	self:Fire('SettingsChanged', key)
	st.Config:Refresh()
end

function EM:SetGridSize(size)
	self:SetSetting('grid_size', size)
end

-- Steps Grid size by delta within its range.
function EM:StepGridSize(delta)
	self:SetGridSize(self:GetSettings().grid_size + delta)
end

function EM:OnEnable()
	-- The grid is sized in physical pixels, so it redraws when the screen does.
	self:RegisterEvent('UI_SCALE_CHANGED', 'UpdateGrid')
	self:RegisterEvent('DISPLAY_SIZE_CHANGED', 'UpdateGrid')
end

-- The "Edit mode" section in /sui. Getters and setters go through
-- EM:GetSettings(), which follows a profile change.
function EM:GetConfigTable()
	local generators = st.Config.generators
	return {
		name = 'Edit mode',
		type = 'group',
		args = {
			general = {
				name = 'General',
				type = 'group',
				inline = true,
				order = 1,
				get = function(info) return self:GetSettings()[info[#info]] end,
				set = function(info, value) self:SetSetting(info[#info], value) end,
				args = {
					grid = generators.toggle(1, 'Show grid',
						"Draws a grid over the screen while edit mode is on, centered on the screen's middle."),
					grid_size = generators.range(2, 'Grid size', self.MIN_GRID_SIZE, self.MAX_GRID_SIZE, 1,
						"The gap between the grid's lines. The bar's arrows change it too."),
					snap_grid = generators.toggle(3, 'Snap to grid',
						"A frame you drag in edit mode snaps to the grid's lines, shown or not."),
					snap_frames = generators.toggle(4, 'Snap to frames',
						"A frame you drag in edit mode snaps to the edges and middles of the other frames on screen, and to the screen's middle."),
					dim = generators.toggle(5, 'Dim world',
						'Darkens the game world behind your frames while edit mode is on.'),
					coordinates = generators.toggle(6, 'Coordinates',
						"Shows the selected frame's position by the corner it's anchored by."),
				},
			},
		},
	}
end
