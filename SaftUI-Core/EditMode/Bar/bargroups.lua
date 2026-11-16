local st = SaftUI
local EM = st.EditModeFrames
local W = st.OptionsWidgets

--[[
	The groups of the edit mode bar's controls (bar.lua), each with its row on
	the docked bar and its section in the floating window:
	  exit     (left, 10, row 1, section 'title')    Exit
	  grid     (left, 20, row 1, section 'grid')     Grid, Grid size, Snap to grid,
	                                                 Snap to frames
	  view     (left, 25, row 1, section 'grid')     Dim world, Coordinates
	  options  (right, 90, row 2, section 'changes') Options, Hide until hovered,
	                                                 and Detach (section 'title')
	                                                 at its end
	Each control is { key, frame, Lay, Refresh, ... } as bar.lua says. The
	tooltips sit under the control (W.ShowTip), in the spec's wording; an icon
	says nothing, so each has one.

	It also exports EM.BarGuard (the click guard) and EM.BarToggle (an icon
	toggle of a setting) for barshow.lua's controls (show, filter).

	A control's click is set as control.onClick, never SetScript('OnClick'):
	the kit's controls guard a disabled one in their own script
	(optionscontrols.lua). Every click, and the number box's set, goes through
	Guard, which does nothing in combat (the bar is gone then anyway, since
	edit mode closes on entering combat; this is for the frames' last moment).

	Grid, Grid size, the snaps, Dim world and Coordinates read and write the profile's settings only
	through EM:GetSettings and EM:SetSetting (settings.lua), which tells the
	grid and the bar ('SettingsChanged').
]]

local ICON = 26

-- fn, or nothing in combat.
local function Guard(fn)
	return function(...)
		if InCombatLockdown() then return end
		return fn(...)
	end
end
EM.BarGuard = Guard -- barshow.lua's controls wrap their clicks the same way

------------------------------------------------------------------ Exit and Options

local function Exit(bar)
	local button = W.Button(bar, 'Exit', nil, {
		icon = st.icons.logOut, iconWithLabel = true,
		tip = function()
			local lines = { 'Turns edit mode off. Your moves are already saved.' }
			if EM:IsBlizzardEditModeOpen() then
				lines[#lines + 1] = "Blizzard's Edit Mode stays open; close it with its own button."
			end
			return 'Exit', lines
		end,
	})
	button.onClick = Guard(function() EM:Deactivate() end)
	return {
		key = 'exit', frame = button,
		-- Compact (the icon alone) in the floating window's title.
		Lay = function(_, floating) return W.SetCompact(button, floating) end,
	}
end

-- The page Options opens: the selected mover's, if it has one, else Global
-- settings > Edit mode.
local function SelectedPage()
	local mover = EM.selected
	return mover and mover.def.configPath and mover or nil
end

local function Options(bar)
	local button = W.Button(bar, 'Options', nil, {
		icon = st.icons.settings,
		tip = function()
			local mover = SelectedPage()
			return 'Options', { mover and ("Opens %s's page in /sui."):format(EM.MoverName(mover))
				or "Opens edit mode's settings in /sui." }
		end,
	})
	button.onClick = Guard(function()
		local mover = SelectedPage()
		if mover then EM:ShowSettings(mover) else st.Config:Open('Fonts', 'editmode') end
	end)
	return {
		key = 'options', frame = button, align = 'right',
		Lay = function() return W.SetCompact(button, false) end,
	}
end

-- Detach: turns the bar into the floating window (barwindow.lua), whose title
-- has Dock in its place, so it is not shown there.
local function Detach(bar)
	local button = W.IconButton(bar, st.icons.pictureInPicture2, function()
		return 'Detach', { 'Turns the bar into a small window you can move anywhere.' }
	end)
	button.onClick = Guard(function() EM:SetBarFloating(true) end)
	return {
		key = 'detach', frame = button, section = 'title',
		Lay = function(_, floating) return floating and 0 or ICON end,
	}
end

-- Hide until hovered (bardock.lua keeps the setting and does the hiding): an
-- icon toggle on the docked bar only, square-mouse-pointer while off and
-- square-dashed-mouse-pointer while on, lit in the accent as the other toggles
-- are. Not in the floating window, which has nothing to hide.
local function HideToggle(bar)
	local button = W.IconButton(bar, st.icons.squareMousePointer, function()
		return 'Hide until hovered', { 'Hides this bar until the mouse reaches the top edge of the screen where it sits.' }
	end)
	button.onClick = Guard(function() EM:SetBarHideUntilHovered(not EM:IsBarHideUntilHovered()) end)
	return {
		key = 'hide', frame = button, section = 'title',
		Lay = function(_, floating) return floating and 0 or ICON end,
		Refresh = function()
			local on = EM:IsBarHideUntilHovered()
			button.icon:SetTexture(on and st.icons.squareDashedMousePointer or st.icons.squareMousePointer)
			W.SetOn(button, on)
		end,
	}
end

------------------------------------------------------------------ the grid

-- An icon button that toggles the boolean setting key, lit while it is on.
local function Toggle(bar, controlKey, icon, key, title, line)
	local button = W.IconButton(bar, icon, function() return title, { line } end)
	button.onClick = Guard(function() EM:SetSetting(key, not EM:GetSettings()[key]) end)
	return {
		key = controlKey, frame = button,
		Lay = function() return ICON end,
		Refresh = function() W.SetOn(button, EM:GetSettings()[key] == true) end,
	}
end

-- Grid size: a number box, on while Grid or Snap to grid is, as both use the
-- grid's lines.
-- A number box's colors, for a color pass: its arrows at rest (Muted). The
-- edit box's edge (the Accent while it has the keyboard) is the states helper's
-- (W.NumberBox's box: a focus state), which a pass of the Accent colors on its
-- own. The mouse is not asked: a pass runs while the color picker has it, not a
-- bar control, and a hover paints itself again on the next enter. Nothing of
-- its look: no art, no state, no table (W.LookNumberBox makes one).
function EM.RecolorNumberBox(box)
	local r, g, b = st:Color('text', 'muted'):GetRGB()
	box.pair.up.arrow:SetVertexColor(r, g, b)
	box.pair.down.arrow:SetVertexColor(r, g, b)
end

local function GridSize(bar)
	local box
	box = W.NumberBox(bar, {
		width = 54, min = EM.MIN_GRID_SIZE, max = EM.MAX_GRID_SIZE, step = EM.GRID_STEP,
		get = function() return EM:GetSettings().grid_size end,
		set = Guard(function(size) EM:SetGridSize(size) end),
		tip = function()
			local lines = { ("The gap between the grid's lines, in pixels. The arrows step it by %d."):format(EM.GRID_STEP) }
			if box.disabled then
				lines[#lines + 1] = { text = 'Turn on Grid or Snap to grid to use it.', danger = true }
			end
			return 'Grid size', lines
		end,
	})
	return {
		key = 'gridSize', frame = box,
		Lay = function() return 54 end,
		-- Look alone: the bar looks again on every setting, a click on an arrow
		-- among them, and that must not take the hovered arrow's Normal back
		-- (the catch-up of Muted is the bar's Enabled listener, bar.lua).
		Look = function(_, blizzard) W.LookNumberBox(box, blizzard) end,
		Recolor = function() EM.RecolorNumberBox(box) end,
		Refresh = function()
			local settings = EM:GetSettings()
			-- Not while it is being typed in, unless the size itself changed since
			-- the box showed it (an arrow's value shows at once).
			if not box.edit:HasFocus() or settings.grid_size ~= box.shownSize then
				box.shownSize = settings.grid_size
				box:Refresh()
			end
			W.SetEnabled(box, settings.grid == true or settings.snap_grid == true)
		end,
	}
end

EM.BarToggle = Toggle -- Show disabled and Show hidden (barshow.lua) are toggles too

------------------------------------------------------------------ the groups

EM:AddBarGroup({
	key = 'exit', order = 10, side = 'left', row = 1, section = 'title',
	controls = function(bar) return { Exit(bar) } end,
})

EM:AddBarGroup({
	key = 'grid', order = 20, side = 'left', row = 1, section = 'grid',
	controls = function(bar)
		return {
			Toggle(bar, 'grid', st.icons.grid3x3, 'grid', 'Grid', 'Draws a grid over the screen, centred on its middle.'),
			GridSize(bar),
			Toggle(bar, 'snapGrid', st.icons.magnet, 'snap_grid', 'Snap to grid',
				"A dragged frame snaps to the grid's lines, shown or not. Hold Ctrl to drag without snapping."),
			Toggle(bar, 'snapFrames', st.icons.alignStartVertical, 'snap_frames', 'Snap to frames',
				"A dragged frame snaps to the edges and middles of the other frames shown, and to the screen's middle. Hold Ctrl to drag without snapping."),
		}
	end,
})

-- Dim world and Coordinates: a group of their own on the docked bar (the mockup
-- has a divider after the snaps), in the floating window's Grid and snap section
-- with the rest.
EM:AddBarGroup({
	key = 'view', order = 25, side = 'left', row = 1, section = 'grid',
	controls = function(bar)
		return {
			Toggle(bar, 'dim', st.icons.layers, 'dim', 'Dim world',
				'Darkens the game world behind your frames while edit mode is on.'),
			Toggle(bar, 'coordinates', st.icons.mapPin, 'coordinates', 'Coordinates',
				"Shows the selected frame's position by the corner it's anchored by."),
		}
	end,
})

EM:AddBarGroup({
	key = 'options', order = 90, side = 'right', row = 2, section = 'changes',
	controls = function(bar) return { Options(bar), HideToggle(bar), Detach(bar) } end,
})
