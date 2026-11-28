-- The world and the helpers the /sui window's tests share
-- (options_body_test.lua, options_open_test.lua, options_rerender_test.lua,
-- options_frame_test.lua, options_small_dialog_test.lua,
-- options_window_look_test.lua and options_resize_test.lua). A test file loads
-- it with load_test_file and takes the helpers it uses from what it returns.
--
-- It loads, in the file that loads it: config_helpers.lua, the model, the
-- widget files, the body and the window's files, and registers the synthetic
-- modules the window's pages come from: one shaped like Unitframes (a unit
-- picker, element tabs), Inventory's shape (tabs, and a window's own groups as
-- a second tab row, with rows that follow a Columns slider for a drag) and
-- small ones for the sidebar's categories. The helpers: frames, keys, drawn,
-- cell, click, tick (one frame on the window's clock), close_all, the readers
-- of what is drawn (size_of, rgba), theme, and the pieces of the fill row
-- page (FillRowsTable, FillRowsModule).
--
-- hideTarget, ufProfile, ufProfiles, ufManaged, ufPickerLabel, ufPickerControl, ufPickerBand
-- and columns are the modules' state, read when a page's table is built. They are globals,
-- not locals, so a case in any file that sets one (hideTarget = true) reaches
-- the modules here.

load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_options_widgets()
load_saftui('SaftUI-Core/Config/optionsbody.lua')
load_options_window()
local OM, W, OW = st.OptionsModel, st.OptionsWidgets, st.OptionsWindow

-- Unitframes' shape: childGroups = 'select' on the module (its units are the
-- picker), a footer control (SaftUI's footer field: the profile's dropdown and
-- Manage), and units whose element groups are tabs. Values live in uf, read
-- and written at call time.
local uf = {
	player = { enable = true, width = 200, power = { enable = true, height = 10 } },
	target = { enable = true, width = 180, power = { enable = true, height = 8 } },
}
hideTarget = false
ufProfile = 'Main'
ufProfiles = { Main = 'Main', Alt = 'Alt' } -- the dropdown's values, read each time it's drawn
ufManaged = 0 -- Manage's clicks
ufPickerLabel = nil -- the page's pickerLabel, when a test sets one
ufPickerControl = nil -- the player's pickerControl (SaftUI's field), when a test sets one
ufPickerBand = nil -- the player's pickerBand (SaftUI's field), when a test sets one

local function UnitTable(unit, name)
	local cfg = uf[unit]
	return {
		name = name,
		type = 'group',
		childGroups = 'tab',
		hidden = unit == 'target' and function() return hideTarget end or nil,
		pickerControl = unit == 'player' and ufPickerControl or nil,
		pickerBand = unit == 'player' and ufPickerBand or nil,
		args = {
			copy = { name = 'Copy from', type = 'execute', order = -99, func = function() end },
			general = {
				order = 0, name = 'General', type = 'group',
				get = function(info) return cfg[info[#info]] end,
				set = function(info, value) cfg[info[#info]] = value end,
				args = {
					enable = { order = 1, type = 'toggle', name = 'Enable' },
					width = { order = 2, type = 'range', name = 'Frame width', min = 10, max = 600, step = 1 },
				},
			},
			power = {
				order = 1, name = 'Power', type = 'group',
				get = function(info) return cfg.power[info[#info]] end,
				set = function(info, value) cfg.power[info[#info]] = value end,
				args = {
					enable = { order = 1, type = 'toggle', name = 'Enable' },
					height = {
						order = 2, type = 'range', name = 'Bar height', min = 1, max = 50, step = 1,
						hidden = function() return not cfg.power.enable end,
					},
					size = {
						order = 3, type = 'input', name = 'Size',
						validate = function(_, value) return tonumber(value) ~= nil or 'Size: a number, please' end,
						get = function() return '1' end,
						set = function() end,
					},
				},
			},
		},
	}
end

local UFM = st:NewModule('Unitframes')
function UFM:GetConfigTable()
	return {
		name = 'Unitframes',
		type = 'group',
		childGroups = 'select',
		pickerLabel = ufPickerLabel,
		category = 'Frames',
		footer = {
			type = 'group', name = 'Unit frame profile',
			args = {
				current = {
					order = 1, type = 'select', name = 'Profile', desc = 'The profile.',
					values = function() return ufProfiles end,
					-- As UF's real profile select does: its get notifies the registry.
					get = function() st.Config:Refresh(); return ufProfile end,
					set = function(_, value) ufProfile = value end,
				},
				manage = {
					order = 2, type = 'execute', name = 'Manage', desc = 'Manages the profiles.',
					func = function() ufManaged = ufManaged + 1 end,
				},
			},
		},
		args = {
			player = UnitTable('player', 'Player'),
			target = UnitTable('target', 'Target'),
		},
	}
end

-- One small page per category, to see the sidebar group them.
local function SmallModule(key, name, category, order)
	local module = st:NewModule(key)
	function module:GetConfigTable()
		return {
			name = name, type = 'group', category = category, order = order,
			args = { general = { name = 'General', type = 'group', args = {
				on = { type = 'toggle', name = name .. ' on', get = function() return true end, set = function() end },
			} } },
		}
	end
	return module
end
SmallModule('Chat', 'Chat', 'Frames')

-- Inventory's shape: tabs (settings for every window, then each window), and a
-- window's own groups as a second tab row. Its General tab also has rows that
-- follow its Columns slider, for a drag: a box showing the value, a toggle
-- disabled at 8 columns or more, and one hidden at 9 or more.
local bagValue = 5
columns = 5
local INVM = st:NewModule('Inventory')
function INVM:GetConfigTable()
	local function toggle(name) return { type = 'toggle', name = name, get = function() return true end, set = function() end } end
	local wide, extra = toggle('Wide slots'), toggle('Extra row')
	wide.order, wide.disabled = 3, function() return columns >= 8 end
	extra.order, extra.hidden = 4, function() return columns >= 9 end
	return {
		name = 'Bags', type = 'group', category = 'Frames',
		args = {
			general = { order = 0, name = 'General', type = 'group', args = {
				merge = toggle('Merge stacks'),
				columns = { order = 1, type = 'range', name = 'Columns', min = 1, max = 12, step = 1,
					get = function() return columns end, set = function(_, v) columns = v end },
				columns_shown = { order = 2, type = 'input', name = 'Columns shown',
					get = function() return tostring(columns) end, set = function() end },
				wide = wide,
				extra = extra,
			} },
			bag = {
				order = 1, name = 'Bag', type = 'group',
				args = {
					general = { order = 1, name = 'General', type = 'group', args = {
						size = { type = 'range', name = 'Slot size', min = 1, max = 10, step = 1,
							get = function() return bagValue end, set = function(_, v) bagValue = v end },
					} },
					text = { order = 2, name = 'Text', type = 'group', args = { count = toggle('Show count') } },
				},
			},
		},
	}
end
SmallModule('Auras', 'Auras', 'Combat')
SmallModule('Loot', 'Loot', 'Info')
SmallModule('Zeta', 'Zeta', nil) -- no category: Other

local function frames() return OW.GetFrames() end

local function keys(list, field)
	local out = {}
	for i, entry in ipairs(list) do out[i] = tostring(entry[field or 'key']) end
	return table.concat(out, ',')
end

-- The drawn body rows, as 'key' (or 'key=name') in order.
local function drawn()
	local out = {}
	for i, cell in ipairs(OW.GetDrawnRows()) do out[i] = cell.row.key end
	return table.concat(out, ',')
end

local function cell(key)
	for _, c in ipairs(OW.GetDrawnRows()) do
		if c.row.key == key then return c end
	end
end

local click = stub.click

-- One frame passes on the window's clock.
local tick = tick_options_window

local function close_all()
	st.Config:Close()
	-- No test's size or sidebar leaks into the next.
	local saved = st.config.global.optionsWindow
	if type(saved) == 'table' then saved.size, saved.sidebar = nil, nil end
	stub.in_combat = false
	hideTarget = false
end

-- The FillRows module's page: a fill row (the windowfill type, defined in the
-- test below) between two toggles.
local function FillRowsTable()
	local function toggle(name, order)
		return { type = 'toggle', name = name, desc = name, order = order, get = function() return true end, set = function() end }
	end
	return {
		name = 'Fill rows', type = 'group', category = 'Frames',
		args = {
			before = toggle('Before', 1),
			fill = { type = 'windowfill', name = 'Fill', desc = 'A fill row.', size = 'wide', order = 2 },
			after = toggle('After', 3),
		},
	}
end

-- The windowfill type, a bare fill row at least 100 tall, each height it's
-- told noted in heights when given; and the FillRows module, whose page has
-- one (its GetConfigTable left to the test). Each made once.
local function FillRowsModule(heights)
	if not W.CUSTOM.windowfill then
		W.Define('windowfill', {
			bare = true,
			fill = true,
			minHeight = 100,
			build = function(w)
				w.frame = CreateFrame('Frame', nil, UIParent)
				w.frame:SetSize(10, 10)
			end,
			methods = {
				SetWidth = function(self, width) self.frame:SetWidth(width) end,
				SetHeight = function(self, height)
					self.frame:SetHeight(height)
					if heights then heights[#heights + 1] = height end
				end,
				Refresh = function() end,
			},
		})
	end
	return st:GetModule('FillRows', true) or st:NewModule('FillRows')
end

local function theme(name)
	st.config.profile.theme.name = name
	OW:Render() -- the window renders again after a theme change
end

local function rgba(...) return string.format('%.2f,%.2f,%.2f,%.2f', ...) end

local function size_of(frame) return frame:GetWidth() .. 'x' .. frame:GetHeight() end

return {
	cell = cell,
	close_all = close_all,
	drawn = drawn,
	FillRowsTable = FillRowsTable,
	frames = frames,
	FillRowsModule = FillRowsModule,
	tick = tick,
	click = click,
	keys = keys,
	theme = theme,
	size_of = size_of,
	rgba = rgba,
	uf = uf,
}
