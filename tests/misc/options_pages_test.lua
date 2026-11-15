-- The /sui pages of SaftUI-Misc whose tables the suite can't get through
-- Config:GetOptionsTable, because they build only after OnEnable has made
-- frames: Tooltip, Totem bar, Buffs and debuffs (Auras), Swing timer. Each is
-- built here with stand-ins for those frames (SaftUI's own: holders, bars,
-- Blizzard's bar and bar frames left out because the tables never touch them),
-- and the Skinning page, which needs none. (The Blizzard's tracker page is
-- checked in objective_tracker_position_test.lua, over the tracker's fixture.) Checked for each page: every option
-- has a desc and no Ace width, Position is the last option of its group, and
-- the new options read and write their profile keys and apply the change.
--
-- Real: the files of the pages (tooltipposition.lua; totembar.lua,
-- totemlayout.lua, totemposition.lua and totemoptions.lua;
-- Blizzard_BuffFramePosition.lua; Blizzard_SwingTimerPosition.lua;
-- skinning.lua), Misc's defaults, Core's generators and the options model.
load_core_helpers()
load_editmode() -- the pages' Position rows reset through their movers
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
load_test_file('lib/options_walk.lua')
local T = load_test_file('lib/theme_helpers.lua')
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
load_saftui('SaftUI-Core/Config/optionsbody.lua')
local R = load_test_file('lib/reset_walk.lua')
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
	-- Nothing on it is a Template, Highlight or Close Button, or an old template name.
	T.check_no_old_names(tree, name)
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

-- The model's row for a path under the root (as tests/core/options_saved_test.lua makes one).
local function row_of(root, ...)
	local path = { ... }
	local option = { args = root }
	for _, key in ipairs(path) do option = OM.SubOption(option, key) end
	return { option = option, path = path, type = option.type, key = path[#path] }
end

-- Moves a row's value through its own set, checks the icon shows, resets it, checks the icon goes
-- and the saved value is the default again.
local function reset_roundtrip(root, name, get_saved, default, change, ...)
	local row = row_of(root, ...)
	check(not OM.DefaultDiffers(root, row), name .. ': fresh, no icon')
	change()
	check(OM.DefaultDiffers(root, row), name .. ': changed, the icon shows')
	local ok = OM.DefaultReset(root, row)
	check(ok, name .. ': the reset runs')
	eq(get_saved(), default, name .. ': back to the default')
	check(not OM.DefaultDiffers(root, row), name .. ': and the icon is gone')
end

local function position(x_off) return { point = 'TOP', rel_point = 'TOP', x_off = x_off or 0, y_off = 0, frame = 'UIParent' } end

test('Tooltip: Theme, Background and Font read and write the profile, and a Theme or Background change re-skins', function()
	local TT = st:NewModule('Tooltip')
	TT.tooltipHolder = CreateFrame('Frame', nil, UIParent)
	TT.config = profile.tooltip
	local reskins, anchors = 0, 0
	load_saftui('SaftUI-Misc/tooltipposition.lua')
	-- tooltip.lua's UpdateConfig (it needs Blizzard's tooltips), and the anchor update, counted.
	function TT:UpdateConfig() reskins = reskins + 1 end
	function TT:UpdateTooltipAnchor() anchors = anchors + 1 end
	-- tooltipposition.lua's mover (SetupTooltipPosition needs Blizzard's tooltip), with its fields.
	st:RegisterConfigMover(TT.tooltipHolder, {
		key = 'tooltip', label = 'Tooltip', config = function() return TT.config end, apply = function() end,
		configPath = { 'Tooltip', 'general' }, module = 'Misc', defaults = function() return st.defaults.tooltip end,
	})
	-- The stand-in's configPath is the real one: the Position row's reset is the mover's only while they match.
	local source = read_saftui_source('SaftUI-Misc/tooltipposition.lua')
	check(source:find("configPath = { 'Tooltip', 'general' }", 1, true) ~= nil, "tooltipposition.lua's mover has the configPath the stand-in has")
	local tree = TT:GetConfigTable()
	eq(check_page('Tooltip', tree), 1, 'one Position')
	-- With a bag window and a loot feed the two snap toggles show, so the walk probes them too.
	local INV, LT = st:GetModule('Inventory', true) or st:NewModule('Inventory'), st:GetModule('Loot', true) or st:NewModule('Loot')
	local had = { containers = INV.containers, feed = LT.feed }
	INV.containers = { bag = CreateFrame('Frame', nil, UIParent) }
	LT.feed = CreateFrame('Frame', nil, UIParent)
	local walked = R.check_page({ Tooltip = tree }, 'Tooltip')
	INV.containers, LT.feed = had.containers, had.feed
	check(walked >= 6, 'the walk reached the two snap toggles as well as Theme, Background, Font and Position (' .. walked .. ')')
	reskins, anchors = 0, 0 -- the walk's sets counted
	local tt_root = { Tooltip = tree }
	reset_roundtrip(tt_root, "Tooltip's Font", function() return profile.tooltip.font end, st.defaults.tooltip.font,
		function() tree.args.general.set(info_for('font'), 'pixel') end, 'Tooltip', 'general', 'font')
	reskins = 0
	local general = tree.args.general
	eq(general.args.theme.type, 'select', 'Theme is a select')
	eq(general.args.background.type, 'select', 'Background is a select')
	eq(general.args.font.type, 'font', 'Font is a font row')
	eq(general.get(info_for('theme')), profile.tooltip.theme, 'Theme reads tooltip.theme')
	eq(general.get(info_for('background')), profile.tooltip.background, 'Background reads tooltip.background')
	eq(general.get(info_for('font')), profile.tooltip.font, 'Font reads tooltip.font')
	check(general.args.theme.values.thick ~= nil, 'Theme lists the themes')
	general.set(info_for('theme'), 'thick')
	eq(profile.tooltip.theme, 'thick', 'Theme writes tooltip.theme')
	eq(reskins, 1, 'and re-skins the tooltips')
	general.set(info_for('background'), 'solid')
	eq(profile.tooltip.background, 'solid', 'Background writes tooltip.background')
	eq(reskins, 2, 'and re-skins the tooltips')
	general.set(info_for('font'), 'pixel')
	eq(profile.tooltip.font, 'pixel', 'Font writes tooltip.font')
	eq(reskins, 2, 'the font needs no re-skin (each tooltip takes it as it shows)')
	eq(anchors, 0, 'neither moves the tooltip')
	general.set(info_for('attach_to_bags'), false)
	eq(anchors, 1, 'the snap toggles re-anchor it')
	local root = { Tooltip = tree }
	eq(layout(root, 'Tooltip'), 'theme:normal 1, background:normal 2, font:normal 1',
		'Theme | Background, Font, then the toggles are hidden (no bag window or feed here)')
	local view = OM.BuildView(root, 'Tooltip')
	eq(view.sections[#view.sections].title, 'Position', 'Position is the last section')
end)

test('Totem bar: one small color per element, read and written as the bar reads them, applied at once', function()
	for _, file in ipairs({ 'totembar', 'totemlayout', 'totemposition', 'totemoptions' }) do
		load_saftui('SaftUI-Misc/' .. file .. '.lua') -- the TOC's order
	end
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
	-- totemposition.lua's mover: no default place (it took Blizzard's).
	st:RegisterMover('totembar', {
		frame = TB.holder, label = 'Totem Bar', getPosition = function() return TB:GetPosition() end,
		setPosition = function(position) TB.config.position = position end, apply = function() end,
		configPath = { 'TotemBar', 'general' }, module = 'Misc', noDefaultReason = 'no default place',
	})
	local tree = TB:GetConfigTable()
	eq(tree.name, 'Totem bar', 'sentence case, as the sidebar shows it')
	eq(check_page('TotemBar', tree), 1, 'one Position')
	R.check_page({ TotemBar = tree }, 'TotemBar')
	do
		local fire = st.defaults.totembar.colors.fire
		local row = row_of({ TotemBar = tree }, 'TotemBar', 'general', 'color_fire')
		check(not OM.DefaultDiffers({ TotemBar = tree }, row), "the fire color: fresh, no icon")
		tree.args.general.args.color_fire.set(nil, 0.1, 0.2, 0.3)
		check(OM.DefaultDiffers({ TotemBar = tree }, row), 'the fire color: changed, the icon shows')
		check(OM.DefaultReset({ TotemBar = tree }, row), 'the reset runs')
		eq(profile.totembar.colors.fire[1] .. profile.totembar.colors.fire[2] .. profile.totembar.colors.fire[3], fire[1] .. fire[2] .. fire[3],
			'the fire color is the default again')
	end
	applied = {}
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
		.. 'timer_text_position:normal 2, timer_font:normal 1, timer_bar_height:normal 2, '
		.. 'timer_text_x:normal 1, timer_text_y:normal 2, hide:normal 1', 'the settings in pairs: Text X and Y stay a pair')
	local colors = view.sections[2]
	eq(colors.title, 'Element colors', 'the colors have a section')
	local placed = OB.LayoutRows(colors.rows)
	eq(#placed, 4, 'four colors')
	eq(placed[1].y == placed[2].y and placed[3].y == placed[4].y and placed[1].y ~= placed[3].y, true,
		'two to a line (each a bar as wide as a dropdown)')
	eq(view.sections[#view.sections].title, 'Position', 'Position is the last section')

	profile.totembar.position = nil
	TB.holder = nil
	local plain = TB:GetConfigTable()
	eq(plain.name, 'Totem bar', 'off a totem class too')
	check_page('TotemBarOffClass', plain)
end)

-- The Auras module, its file loaded once (a module's file can't load twice).
local function auras()
	if not st:GetModule('Auras', true) then load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_BuffFramePosition.lua') end
	return st:GetModule('Auras')
end

test('Buffs: the text positions are Position options over the same keys', function()
	local AP = auras()
	local real = { UpdateFont = AP.UpdateFont, UpdateText = AP.UpdateText,
		ApplyHolder = AP.ApplyHolder, RestoreUnderMax = AP.RestoreUnderMax, LayoutButtons = AP.LayoutButtons }
	AP.holders = { buffs = CreateFrame('Frame', nil, UIParent), debuffs = CreateFrame('Frame', nil, UIParent) }
	AP.maxAuras = { buffs = 32, debuffs = 16 }
	AP.config = profile.auras
	-- Refresh (every General set) re-lays the holder and Blizzard's buttons, which the stand-in has none of.
	AP.geometry = AP.geometry or {}
	function AP:ApplyHolder() end
	function AP:RestoreUnderMax() end
	function AP:LayoutButtons() end
	-- GetGeometry is the real one (its cache is dropped by every General set, as Refresh does).
	for _, key in ipairs({ 'buffs', 'debuffs' }) do AP:RegisterAuraMover({ key = key, label = key }) end
	local updates = 0
	function AP:UpdateText() updates = updates + 1 end
	function AP:UpdateFont() end
	local tree = AP:GetConfigTable()
	eq(check_page('Auras', tree), 6, 'a Position in General, Duration and Stack count of each of the two frames')
	-- Grow also writes Wrap (allowed); their get shows the values in use.
	R.check_page({ Auras = tree }, 'Auras', { allow = { ['Auras.buffs.general.grow'] = { 'auras.buffs.wrap' },
		['Auras.debuffs.general.grow'] = { 'auras.debuffs.wrap' } } })
	updates = 0 -- the walk's sets counted
	local aroot = { Auras = tree }
	reset_roundtrip(aroot, "a buff's Icon size", function() return profile.auras.buffs.size end, st.defaults.auras.buffs.size,
		function() tree.args.buffs.args.general.set(info_for('size'), 44) end, 'Auras', 'buffs', 'general', 'size')
	-- Wrap's reset while Grow runs up: its default is the wrap the layout keeps, Left, so the icon goes.
	tree.args.buffs.args.general.set(info_for('grow'), 'UP')
	local wraprow = row_of(aroot, 'Auras', 'buffs', 'general', 'wrap')
	profile.auras.buffs.wrap = 'RIGHT'
	check(OM.DefaultDiffers(aroot, wraprow), 'Wrap Right differs (Grow up: the default is Left)')
	check(OM.DefaultReset(aroot, wraprow), 'its reset runs')
	eq(profile.auras.buffs.wrap, 'LEFT', 'and writes the wrap the layout keeps')
	check(not OM.DefaultDiffers(aroot, wraprow), 'so the icon goes')
	tree.args.buffs.args.general.set(info_for('grow'), st.defaults.auras.buffs.grow)
	profile.auras.buffs.wrap = st.defaults.auras.buffs.wrap

	-- Grow's reset from Up: Grow is back to its default but its set moved Wrap to the side the layout keeps,
	-- so Wrap shows its icon, and one click on it gives a fresh profile.
	local growrow = row_of(aroot, 'Auras', 'buffs', 'general', 'grow')
	tree.args.buffs.args.general.set(info_for('grow'), 'UP')
	check(OM.DefaultDiffers(aroot, growrow), 'Grow Up differs')
	check(OM.DefaultReset(aroot, growrow), "Grow's reset runs")
	eq(profile.auras.buffs.grow, st.defaults.auras.buffs.grow, 'Grow is back to its default')
	check(not OM.DefaultDiffers(aroot, growrow), 'its icon goes')
	check(OM.DefaultDiffers(aroot, wraprow), 'Wrap still differs: Grow Up left it on the side Up keeps (two clicks to fresh)')
	check(OM.DefaultReset(aroot, wraprow), "Wrap's reset runs")
	check(not OM.DefaultDiffers(aroot, wraprow), 'and one Wrap reset gives a fresh profile')
	eq(profile.auras.buffs.wrap, st.defaults.auras.buffs.wrap, 'Wrap is its default')

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
	for name, fn in pairs(real) do AP[name] = fn end -- the real ones back for the next case
end)

test("Buffs > Duration's Font lists the shared fonts; Small text picked hides Size and Outline, and the timers follow Small text", function()
	local AP = auras()
	local real = { UpdateText = AP.UpdateText, GetGeometry = AP.GetGeometry }
	st:BindModuleConfig(AP, 'auras')
	AP.holders = { buffs = CreateFrame('Frame', nil, UIParent), debuffs = CreateFrame('Frame', nil, UIParent) }
	AP.maxAuras = { buffs = 32, debuffs = 16 }
	function AP:GetGeometry() return { horizontal = true, grow = 'LEFT', wrap = 'DOWN' } end
	function AP:UpdateText() end
	local tree = AP:GetConfigTable()
	-- The shipped texts are Small text, with no Size or Outline; a face shows them.
	for _, frame in ipairs({ 'buffs', 'debuffs' }) do
		for _, kind in ipairs({ 'duration', 'count' }) do
			local group = tree.args[frame].args.text.args[kind]
			eq(profile.auras[frame][kind].font, 'pixel', frame .. ' ' .. kind .. ' ships Small text')
			eq(group.args.size.hidden() and group.args.outline.hidden(), true, 'with Size and Outline hidden')
			profile.auras[frame][kind].font = 'Homespun'
		end
	end
	for _, frame in ipairs({ 'buffs', 'debuffs' }) do
		for _, kind in ipairs({ 'duration', 'count' }) do
			local group = tree.args[frame].args.text.args[kind]
			eq(group.args.font.type, 'font', frame .. ' ' .. kind .. ": Font is Core's font row")
			eq(group.args.font.faceOnly, true, 'in its face-only mode')
			eq(table.concat(group.args.outline.sorting or {}, ','), table.concat(st:GetModule('Fonts').OUTLINE_ORDER, ','), 'Outline lists None first')
			eq(group.args.size.hidden(), false, 'a face: Size shows')
			eq(group.args.outline.hidden(), false, 'and Outline')
		end
	end

	-- The window's walk of the page: a face lists Size and Outline, a shared font does not.
	local function keys()
		local list = {}
		local group = tree.args.buffs.args.text.args.duration
		for key, option in pairs(group.args) do
			if not (option.hidden and option.hidden()) then list[#list + 1] = { key = key, order = option.order } end
		end
		table.sort(list, function(a, b) return a.order < b.order end)
		local out = {}
		for _, each in ipairs(list) do out[#out + 1] = each.key end
		return table.concat(out, ',')
	end
	eq(keys(), 'font,size,outline,position', 'Font, Size, Outline, Position on a face')

	local duration = tree.args.buffs.args.text.args.duration
	local timer = AP:GetFont('buffs', 'duration')
	local face = profile.auras.buffs.duration
	eq(duration.get(info_for('font')), face.font, "the face the profile names, as it was saved")
	duration.set(info_for('font'), 'pixel')
	eq(profile.auras.buffs.duration.font, 'pixel', 'Small text saves its key')
	eq(keys(), 'font,position', 'Size and Outline are hidden')
	local path, size, flags = st:FontValues('pixel')
	local got, gotSize, gotFlags = timer:GetFont()
	eq(got .. ',' .. gotSize .. ',' .. gotFlags, path .. ',' .. size .. ',' .. flags, "the timers take Small text's face, size and outline")

	-- And follow a change of Small text on the Fonts tab.
	st.config.profile.fonts.pixel.font_size = 13
	st:GetModule('Fonts'):UpdateFontConfig('pixel')
	st:FontsChanged()
	eq(select(2, timer:GetFont()), 13, 'at once, with no reload')

	-- A face again: Size and Outline come back and apply.
	duration.set(info_for('font'), 'Colus')
	eq(keys(), 'font,size,outline,position', 'Size and Outline are back')
	duration.set(info_for('size'), 12)
	eq(select(2, timer:GetFont()), 12, "the setting's own size")
	local stack = tree.args.buffs.args.text.args.count
	stack.set(info_for('font'), 'heading')
	eq(stack.args.size.hidden() and stack.args.outline.hidden(), true, "Stack count's too")
	eq(duration.args.size.hidden(), false, "and its own: Duration's Size shows on a face")
	eq(#take_errors(), 0, 'no errors')
	for name, fn in pairs(real) do AP[name] = fn end
end)

test('Swing timer: sizes and descs, Position last', function()
	load_saftui('SaftUI-Misc/Skinning/blizzard/Blizzard_SwingTimerPosition.lua')
	local STP = st:GetModule('SwingTimer')
	STP.holders = {
		mainhand = CreateFrame('Frame', nil, UIParent),
		offhand = CreateFrame('Frame', nil, UIParent),
		ranged = CreateFrame('Frame', nil, UIParent),
	}
	STP.config = profile.swingtimer
	function STP:ApplyAppearance() end
	function STP:ApplyHolder() end
	STP.movers = {}
	function STP:IsHiddenByBlizzard() return false end
	for _, info in ipairs({ { key = 'mainhand', label = 'Main Hand' }, { key = 'offhand', label = 'Off Hand' }, { key = 'ranged', label = 'Ranged' } }) do
		STP:RegisterBarMover(info)
	end
	local tree = STP:GetConfigTable()
	eq(tree.name, 'Swing timer', 'sentence case, as the sidebar shows it')
	eq(check_page('SwingTimer', tree), 3, 'three Positions')
	R.check_page({ SwingTimer = tree }, 'SwingTimer')
	reset_roundtrip({ SwingTimer = tree }, "the main hand's Width", function() return profile.swingtimer.mainhand.width end,
		st.defaults.swingtimer.mainhand.width, function() tree.args.mainhand.args.general.set(info_for('width'), 321) end,
		'SwingTimer', 'mainhand', 'general', 'width')
	local got = layout({ SwingTimer = tree }, 'SwingTimer', 'mainhand')
	eq(got, 'width:normal 1, height:normal 2, showtitle:small 1/1, showtime:small 1/2, opacity:normal 2', 'Width | Height, the toggles | Opacity')
end)

test('Skinning: a page with the shared Theme, Background and font, which re-applies the skins', function()
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	local SK = st:GetModule('Skinning')
	SK.config = profile.skinning
	local skin = SK:NewModule('Scratch')
	local reapplied = 0
	function skin:UpdateConfig() reapplied = reapplied + 1 end
	local tree = SK:GetConfigTable()
	eq(check_page('Skinning', tree), 0, 'no Position')
	R.check_page({ Skinning = tree }, 'Skinning')
	reapplied = 0 -- the walk's sets counted
	eq(tree.category, 'Info', 'in the Info group')
	local general = tree.args.general
	eq(general.args.theme.type, 'select', 'Theme is a select')
	eq(general.args.background.type, 'select', 'Background is a select')
	eq(general.args.font.type, 'font', 'Font is a font row')
	eq(general.get(info_for('theme')), profile.skinning.theme, 'Theme reads skinning.theme')
	eq(general.get(info_for('background')), profile.skinning.background, 'Background reads skinning.background')
	eq(general.get(info_for('font')), profile.skinning.font, 'Font reads skinning.font')
	general.set(info_for('theme'), 'thick')
	eq(profile.skinning.theme, 'thick', 'Theme writes skinning.theme')
	general.set(info_for('background'), 'solid')
	eq(profile.skinning.background, 'solid', 'Background writes skinning.background')
	general.set(info_for('font'), 'normal')
	eq(profile.skinning.font, 'normal', 'Font writes skinning.font')
	eq(reapplied, 3, 'each change re-applies the skins')

	-- Cooldown Manager turns the Cooldown Manager's skin on or off, after a reload.
	local toggle = general.args.cooldown_manager
	eq(toggle.type, 'toggle', 'Cooldown Manager is a toggle')
	check(toggle.desc:find('Requires a reload', 1, true) ~= nil, 'its tooltip says it needs a reload')
	eq(general.get(info_for('cooldown_manager')), true, 'on by default')
	local printed = {}
	local print_ = st.Print
	function st:Print(...) printed[#printed + 1] = table.concat({ ... }, ' ') end
	toggle.set(info_for('cooldown_manager'), false)
	st.Print = print_
	eq(profile.skinning.cooldown_manager, false, 'Cooldown Manager writes skinning.cooldown_manager')
	eq(reapplied, 3, 'and re-applies no skin')
	eq(printed[1], 'Reload your UI to apply.', 'it says to reload')
	profile.skinning.cooldown_manager = true

	-- Objective tracker turns the objective tracker's skin on or off at once.
	local tracker = general.args.objective_tracker
	eq(tracker.type, 'toggle', 'Objective tracker is a toggle')
	check(tracker.desc:find('reload', 1, true) == nil, 'its tooltip asks for no reload')
	eq(general.get(info_for('objective_tracker')), true, 'on by default')
	general.set(info_for('objective_tracker'), false)
	eq(profile.skinning.objective_tracker, false, 'Objective tracker writes skinning.objective_tracker')
	eq(reapplied, 4, 'and re-applies the skins')
	profile.skinning.objective_tracker = true

	-- Color picker turns the color picker's skin on or off at once.
	local picker = general.args.color_picker
	eq(picker.type, 'toggle', 'Color picker is a toggle')
	check(picker.desc:find('reload', 1, true) == nil, 'its tooltip asks for no reload')
	eq(general.get(info_for('color_picker')), true, 'on by default')
	general.set(info_for('color_picker'), false)
	eq(profile.skinning.color_picker, false, 'Color picker writes skinning.color_picker')
	eq(reapplied, 5, 'and re-applies the skins')
	profile.skinning.color_picker = true

	eq(layout({ Skinning = tree }, 'Skinning'),
		'theme:normal 1, background:normal 2, font:normal 1, cooldown_manager:normal 2, objective_tracker:normal 1, color_picker:normal 2',
		'Theme | Background, Font | Cooldown Manager, Objective tracker, Color picker')
end)
