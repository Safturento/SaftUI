local st = SaftUI
local EM = st.EditModeFrames

-- Edit mode's grid and snapping settings: the footer buttons on the /sui
-- window, the "Edit mode" section in /sui, and the events that redraw the grid.
-- The values live in the profile (st.defaults.editmode).

local MIN_GRID_SIZE, MAX_GRID_SIZE, GRID_STEP = 8, 128, 4

function EM:GetSettings()
	return st.config.profile.editmode
end

local toggleButtons = {} -- setting key -> footer button
local sizeLabel

-- Gives each footer toggle an on/off look (green text when on, grey when off)
-- and the size label the current Grid size. The buttons don't exist until
-- OnEnable, and a profile change can run this before that.
function EM:UpdateFooterToggles()
	local settings = self:GetSettings()
	local colors = st.config.profile.colors.text
	for key, button in pairs(toggleButtons) do
		local color = settings[key] and colors.green or colors.grey
		button.text:SetTextColor(color:GetRGB())
	end
	if sizeLabel then
		sizeLabel.text:SetText(tostring(settings.grid_size))
	end
end

-- Steps Grid size by delta within the slider's range, and redraws the grid.
function EM:StepGridSize(delta)
	local settings = self:GetSettings()
	settings.grid_size = math.max(MIN_GRID_SIZE, math.min(MAX_GRID_SIZE, settings.grid_size + delta))
	self:UpdateGrid()
	self:UpdateFooterToggles()
	st.Config:Refresh() -- an open /sui shows the new value on its slider
end

local function AddToggle(text, key)
	toggleButtons[key] = EM:AddFooterButton(text, function()
		local settings = EM:GetSettings()
		settings[key] = not settings[key]
		EM:UpdateGrid()
		EM:UpdateFooterToggles()
		st.Config:Refresh()
	end)
end

function EM:OnEnable()
	AddToggle('Grid', 'grid')
	AddToggle('Snap to grid', 'snap_grid')
	AddToggle('Snap to frames', 'snap_frames')

	-- Grid size: - label +. AddFooterButton sizes a button from its first
	-- text, so the label starts as "128", the widest it gets. It is a button only
	-- for its look, so it takes no mouse. (Set its text through .text:
	-- st:CreateButton's SetText alias passes the button, not the FontString.)
	self:AddFooterButton('-', function() self:StepGridSize(-GRID_STEP) end)
	sizeLabel = self:AddFooterButton('128', function() end)
	sizeLabel:EnableMouse(false)
	self:AddFooterButton('+', function() self:StepGridSize(GRID_STEP) end)
	self:UpdateFooterToggles()

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
				order = 1,
				get = function(info) return self:GetSettings()[info[#info]] end,
				set = function(info, value)
					self:GetSettings()[info[#info]] = value
					self:UpdateGrid()
					self:UpdateFooterToggles()
				end,
				args = {
					grid = generators.toggle(1, 'Show grid',
						"Draws a grid over the screen while edit mode is on, centered on the screen's middle."),
					grid_size = generators.range(2, 'Grid size', MIN_GRID_SIZE, MAX_GRID_SIZE, 1,
						"The gap between the grid's lines. Edit mode's - and + buttons change it too."),
					snap_grid = generators.toggle(3, 'Snap to grid',
						"A frame you drag in edit mode snaps to the grid's lines, shown or not."),
					snap_frames = generators.toggle(4, 'Snap to frames',
						"A frame you drag in edit mode snaps to the edges and middles of the other frames on screen, and to the screen's middle."),
				},
			},
		},
	}
end
