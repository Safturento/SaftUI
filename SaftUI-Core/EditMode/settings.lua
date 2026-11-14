local st = SaftUI
local EM = st.EditModeFrames

-- Edit mode's grid, snapping, Dim world, Coordinates, Show disabled, Show hidden, module-choice and History length settings: where they live, how they are set
-- (EM:SetSetting, which the bar's controls and the "Edit mode" tab in /sui both
-- use), and the screen events that redraw the grid. The values live in the
-- profile (st.defaults.editmode); the bar (Bar/) shows them.

EM.MIN_GRID_SIZE, EM.MAX_GRID_SIZE, EM.GRID_STEP = 8, 128, 4
EM.MIN_HISTORY, EM.MAX_HISTORY = 1, 1000 -- History length; history.lua's LIMIT_MIN and LIMIT_MAX are these

function EM:GetSettings()
	return st.config.profile.editmode
end

-- Sets one of the settings. Grid size is made a whole number from MIN_GRID_SIZE
-- to MAX_GRID_SIZE first (a value that is not a number changes nothing), and
-- History length the same from MIN_HISTORY to MAX_HISTORY, which the history
-- then keeps (History:SetLimit: lowering it trims lazily, at the next recorded
-- step).
-- Then 'SettingsChanged' (key) tells the grid and the bar, and an open /sui
-- shows the new value on its row.
function EM:SetSetting(key, value)
	if key == 'grid_size' then
		if type(value) ~= 'number' or value ~= value then return end
		value = math.max(self.MIN_GRID_SIZE, math.min(self.MAX_GRID_SIZE, math.floor(value + 0.5)))
	elseif key == 'history_limit' then
		if type(value) ~= 'number' or value ~= value then return end
		value = math.max(self.MIN_HISTORY, math.min(self.MAX_HISTORY, math.floor(value + 0.5)))
		self.History:SetLimit(value)
	end
	self:GetSettings()[key] = value
	self:Fire('SettingsChanged', key)
	st.Config:Refresh()
end

function EM:SetGridSize(size)
	self:SetSetting('grid_size', size)
end

-- The saved History length goes to the history: at load, and when the profile
-- changes (its own saved length). A profile with no length has the default.
function EM:ApplyHistoryLimit()
	local profile = st.config and st.config.profile
	local settings = profile and profile.editmode
	if settings and self.History then self.History:SetLimit(settings.history_limit) end
end

EM:On('SettingsChanged', function(key)
	if key == nil then EM:ApplyHistoryLimit() end
end)

function EM:OnEnable()
	self:ApplyHistoryLimit()
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
					show_disabled = generators.toggle(7, 'Show disabled',
						"Shows the movers of frames you've turned off."),
					show_hidden = generators.toggle(8, 'Show hidden',
						"Shows the movers of frames that aren't on screen right now: closed bags, no pet, no boss."),
					history_limit = generators.range(9, 'History length', self.MIN_HISTORY, self.MAX_HISTORY, 1,
						"How many of your changes the bar's Undo and History keep, from 1 to 1000. Past that, the oldest are forgotten."),
				},
			},
		},
	}
end
