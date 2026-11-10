-- The /sui pages of SaftUI-Misc whose tables the suite can't get through
-- Config:GetOptionsTable, because they build only after OnEnable has made
-- frames: Tooltip, Totem bar, Buffs and debuffs (Auras), Swing timer. Each is
-- built here with stand-ins for those frames (SaftUI's own: holders, bars,
-- Blizzard's bar and bar frames left out because the tables never touch them),
-- and the Skinning page, which needs none. Checked for each page: every option
-- has a desc and no Ace width, Position is the last option of its group, and
-- the new options read and write their profile keys and apply the change.
--
-- Real: the files of the pages (tooltipposition.lua, totembar.lua,
-- Blizzard_BuffFramePosition.lua, Blizzard_SwingTimerPosition.lua,
-- skinning.lua), Misc's defaults, Core's generators and the options model.
load_core_helpers()
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
load_test_file('core/options_walk.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')
local st = SaftUI
local OM, OB = st.OptionsModel, st.OptionsBody
local profile = st.config.profile

local NO_DESC = { group = true, header = true, description = true }

-- An info table for option `key` of the group `group`, as the options window passes one.
local function info_for(key) return { key } end

-- Every option has a desc (a string or a function) and no width; every group's
-- Position is after all of its other options, and the page has the childGroups
-- it wants. Returns the number of Position options.
local function check_page(name, tree)
	check(tree ~= nil, name .. ' builds')
	local positions = 0
	local function siblings(group, where)
		for key, option in pairs(group.args) do
			if option.type == 'position' then
				positions = positions + 1
				for other, sibling in pairs(group.args) do
					if other ~= key then
						check((sibling.order or 100) < option.order, where .. ': Position is after ' .. other)
					end
				end
			end
		end
	end
	siblings(tree, name)
	each_option(tree, function(option, path)
		local where = name .. '.' .. table.concat(path, '.')
		check(option.width == nil, where .. ' has an Ace width')
		if not NO_DESC[option.type] then
			local desc = option.desc
			check((type(desc) == 'string' and desc ~= '') or type(desc) == 'function', where .. ' has no desc')
		end
		if option.type == 'group' then siblings(option, where) end
	end)
	return positions
end

-- The rows of the first section of the page's first tab, as LayoutRows places them: 'key:size col[/quarter]'.
local function layout(root, page, tab)
	local view = OM.BuildView(root, page, { tab = tab })
	local placed = OB.LayoutRows(view.sections[1].rows)
	local got = {}
	for _, p in ipairs(placed) do
		got[#got + 1] = string.format('%s:%s %s%s', p.row.key, p.row.size or 'normal', tostring(p.col),
			p.quarter and ('/' .. p.quarter) or '')
	end
	return table.concat(got, ', '), view
end

local function position(x_off) return { point = 'TOP', rel_point = 'TOP', x_off = x_off or 0, y_off = 0, frame = 'UIParent' } end

test('Tooltip: Template and Font are new, read and write the profile, and a template change re-skins', function()
	local TT = st:NewModule('Tooltip')
	TT.tooltipHolder = CreateFrame('Frame', nil, UIParent)
	TT.config = profile.tooltip
	local reskins, anchors = 0, 0
	load_saftui('SaftUI-Misc/tooltipposition.lua')
	-- tooltip.lua's UpdateConfig (it needs Blizzard's tooltips), and the anchor update, counted.
	function TT:UpdateConfig() reskins = reskins + 1 end
	function TT:UpdateTooltipAnchor() anchors = anchors + 1 end
	local tree = TT:GetConfigTable()
	eq(check_page('Tooltip', tree), 1, 'one Position')
	local general = tree.args.general
	eq(general.args.template.type, 'select', 'Template is a select')
	eq(general.args.font.type, 'select', 'Font is a select')
	eq(general.get(info_for('template')), profile.tooltip.template, 'Template reads tooltip.template')
	eq(general.get(info_for('font')), profile.tooltip.font, 'Font reads tooltip.font')
	check(general.args.template.values.thicktransparent ~= nil, 'Template lists the templates')
	general.set(info_for('template'), 'thick')
	eq(profile.tooltip.template, 'thick', 'Template writes tooltip.template')
	eq(reskins, 1, 'and re-skins the tooltips')
	general.set(info_for('font'), 'pixel')
	eq(profile.tooltip.font, 'pixel', 'Font writes tooltip.font')
	eq(reskins, 1, 'the font needs no re-skin (each tooltip takes it as it shows)')
	eq(anchors, 0, 'neither moves the tooltip')
	general.set(info_for('attach_to_bags'), false)
	eq(anchors, 1, 'the snap toggles re-anchor it')
	local root = { Tooltip = tree }
	eq(layout(root, 'Tooltip'), 'template:normal 1, font:normal 2', 'Template | Font, then the toggles are hidden (no bag window or feed here)')
	local view = OM.BuildView(root, 'Tooltip')
	eq(view.sections[#view.sections].title, 'Position', 'Position is the last section')
end)

test('Totem bar: one small color per element, read and written as the bar reads them, applied at once', function()
	load_saftui('SaftUI-Misc/totembar.lua')
	local TB = st:GetModule('TotemBar')
	TB.bar = CreateFrame('Frame', 'ScratchTotemBar', UIParent)
	TB.holder = CreateFrame('Frame', nil, UIParent)
	TB.config = profile.totembar
	profile.totembar.position = position()
	function TB:GetPosition() return self.config.position end
	local applied = {}
	-- totemskin.lua and totemtimers.lua's, which need Blizzard's bar and its buttons.
	for _, name in ipairs({ 'ApplySkin', 'ApplyTimerLayout', 'ApplyButtonLayout', 'Apply' }) do
		TB[name] = function() applied[#applied + 1] = name end
	end
	local tree = TB:GetConfigTable()
	eq(check_page('TotemBar', tree), 1, 'one Position')
	local args = tree.args.general.args

	local elements = { 'earth', 'fire', 'water', 'air' }
	for _, element in ipairs(elements) do
		local option = args['color_' .. element]
		check(option and option.type == 'color' and option.size == 'small', element .. ' is a small color')
		eq(option.name, element:sub(1, 1):upper() .. element:sub(2), element .. "'s label is its name")
		local r, g, b = option.get()
		local default = profile.totembar.colors[element]
		check(r == default[1] and g == default[2] and b == default[3], element .. ' reads totembar.colors.' .. element)
	end
	for key in pairs(st.defaults.totembar.colors) do
		check(args['color_' .. key], 'the default color ' .. key .. ' has an option')
	end

	applied = {}
	args.color_fire.set(nil, 1, 0.5, 0.25)
	local fire = profile.totembar.colors.fire
	check(fire[1] == 1 and fire[2] == 0.5 and fire[3] == 0.25, 'setting Fire writes totembar.colors.fire')
	eq(table.concat(applied, ','), 'ApplySkin,ApplyTimerLayout', 'and re-skins the buttons and redraws the timers')

	local got, view = layout({ TotemBar = tree }, 'TotemBar')
	eq(got, 'button_size:normal 1, button_spacing:normal 2, timer_bar:small 1/1, timer_text:small 1/2, '
		.. 'timer_text_position:normal 2, timer_text_x:normal 1, timer_text_y:normal 2, '
		.. 'timer_bar_height:normal 1, hide:normal 2', 'the settings in pairs')
	local colors = view.sections[2]
	eq(colors.title, 'Element colors', 'the colors have a section')
	local placed = OB.LayoutRows(colors.rows)
	eq(#placed, 4, 'four colors')
	eq(placed[1].y == placed[4].y, true, 'on one line')
	eq(view.sections[#view.sections].title, 'Position', 'Position is the last section')

	profile.totembar.position = nil
	TB.holder = nil
	local plain = TB:GetConfigTable()
	check_page('TotemBarOffClass', plain)
end)

test('Buffs: the text positions are Position options over the same keys', function()
	load_saftui('SaftUI-Misc/Skinning/Blizzard_BuffFramePosition.lua')
	local AP = st:GetModule('Auras')
	AP.holders = { buffs = CreateFrame('Frame', nil, UIParent), debuffs = CreateFrame('Frame', nil, UIParent) }
	AP.maxAuras = { buffs = 32, debuffs = 16 }
	AP.config = profile.auras
	function AP:GetGeometry() return { horizontal = true, grow = 'LEFT', wrap = 'DOWN' } end
	local updates = 0
	function AP:UpdateText() updates = updates + 1 end
	function AP:UpdateFont() end
	local tree = AP:GetConfigTable()
	eq(check_page('Auras', tree), 6, 'a Position in General, Duration and Stack count of each of the two frames')

	local duration = tree.args.buffs.args.text.args.duration
	local p = duration.args.position
	eq(p.type, 'position', 'Duration has a Position option')
	eq(p.target, nil, 'with no TO part (it is the icon)')
	for _, key in ipairs({ 'point_', 'rel_point_', 'x_off_', 'y_off_' }) do
		eq(duration.args[key:sub(1, -2)], nil, 'the hand-built ' .. key:sub(1, -2) .. ' option is gone')
	end
	local d = profile.auras.buffs.duration
	eq(p.get(nil, 'point'), d.point, 'reads point')
	eq(p.get(nil, 'rel_point'), d.rel_point, 'reads rel_point')
	eq(p.get(nil, 'y_off'), d.y_off, 'reads y_off')
	p.set(nil, 'x_off', 7)
	p.set(nil, 'point', 'LEFT')
	eq(profile.auras.buffs.duration.x_off, 7, 'writes x_off')
	eq(profile.auras.buffs.duration.point, 'LEFT', 'writes point')
	eq(updates, 2, 'and re-applies the text')
	local c = tree.args.debuffs.args.text.args.count.args.position
	c.set(nil, 'rel_point', 'TOPLEFT')
	eq(profile.auras.debuffs.count.rel_point, 'TOPLEFT', "Stack count's Position writes debuffs.count.rel_point")

	local got = layout({ Auras = tree }, 'Auras', 'buffs')
	eq(got, 'size:normal 1, max:normal 2, spacing_x:normal 1, spacing_y:normal 2, grow:normal 1, wrap:normal 2, perrow:normal 1',
		'General in pairs')
end)

test('Swing timer: sizes and descs, Position last', function()
	load_saftui('SaftUI-Misc/Skinning/Blizzard_SwingTimerPosition.lua')
	local STP = st:GetModule('SwingTimer')
	STP.holders = {
		mainhand = CreateFrame('Frame', nil, UIParent),
		offhand = CreateFrame('Frame', nil, UIParent),
		ranged = CreateFrame('Frame', nil, UIParent),
	}
	STP.config = profile.swingtimer
	function STP:ApplyAppearance() end
	function STP:ApplyHolder() end
	local tree = STP:GetConfigTable()
	eq(check_page('SwingTimer', tree), 3, 'three Positions')
	local got = layout({ SwingTimer = tree }, 'SwingTimer', 'mainhand')
	eq(got, 'width:normal 1, height:normal 2, showtitle:small 1/1, showtime:small 1/2, opacity:normal 2', 'Width | Height, the toggles | Opacity')
end)

test('Skinning: a page with the shared font and template, which re-applies the skins', function()
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	local SK = st:GetModule('Skinning')
	SK.config = profile.skinning
	local skin = SK:NewModule('Scratch')
	local reapplied = 0
	function skin:UpdateConfig() reapplied = reapplied + 1 end
	local tree = SK:GetConfigTable()
	eq(check_page('Skinning', tree), 0, 'no Position')
	eq(tree.category, 'Info', 'in the Info group')
	local general = tree.args.general
	eq(general.args.template.type, 'select', 'Template is a select')
	eq(general.args.font.type, 'select', 'Font is a select')
	eq(general.get(info_for('template')), profile.skinning.template, 'Template reads skinning.template')
	eq(general.get(info_for('font')), profile.skinning.font, 'Font reads skinning.font')
	general.set(info_for('template'), 'thick')
	eq(profile.skinning.template, 'thick', 'Template writes skinning.template')
	general.set(info_for('font'), 'normal')
	eq(profile.skinning.font, 'normal', 'Font writes skinning.font')
	eq(reapplied, 2, 'each change re-applies the skins')
	eq(layout({ Skinning = tree }, 'Skinning'), 'template:normal 1, font:normal 2', 'Template | Font')
end)
