-- Every unit frame text's Max width and Align (its config's max_width and
-- justify; UF.SetMaxWidth, UF.TextJustify and UF.ApplyJustify in updaters.lua).
-- Max width gives the text that width on one line. Align is taken only while
-- the text has one (its row is disabled at 0): Left, Center and Right set the
-- font string's horizontal justification; Auto, the default, and any text with
-- no width follow the text's point, as before. On every text's options (Name,
-- Health and Power text, Additional power's text, the castbar's spell name and
-- time, the plates' Subtext and Threat), applied by each text's update.
--
-- The world is nameplate_world.lua's (see its top): real unit frame files over
-- oUF's stand-in (fixtures/ouf.lua), the plates spawned with the defaults.
local NP = load_test_file('unitframes/nameplate_world.lua')

local function world(client)
	local st, UF = NP.world(client or 'forever')
	UF:SpawnNameplates()
	return st, UF, UF:GetProfileConfig()
end

local function enemy(unit)
	stub.units[unit] = { name = 'Kobold', level = 22, reaction = 2, classification = 'elite', friend = false, attackable = true }
	return NP.add(unit)
end

test('Auto follows the point; Left, Center and Right are taken only with a Max width', function()
	local _, UF = world()
	local function at(point, justify, width)
		return UF.TextJustify({ justify = justify, position = { point = point }, max_width = width or 100 })
	end
	eq(at('LEFT', 'AUTO'), 'LEFT', 'a left point')
	eq(at('TOPLEFT', 'AUTO'), 'LEFT', 'a top left point')
	eq(at('BOTTOMRIGHT', 'AUTO'), 'RIGHT', 'a bottom right point')
	eq(at('TOP', 'AUTO'), 'CENTER', 'a top point')
	eq(at('CENTER', 'AUTO'), 'CENTER', 'the center')
	eq(at('LEFT', nil), 'LEFT', 'no value (a config from before the setting) is Auto')
	eq(at('RIGHT', 'bogus'), 'RIGHT', 'an unknown value is Auto')
	eq(UF.TextJustify({ justify = 'AUTO' }), 'CENTER', 'Auto with no position: centered')
	for _, justify in ipairs({ 'LEFT', 'CENTER', 'RIGHT' }) do
		eq(at('TOPRIGHT', justify), justify, justify .. ' over a right point')
		eq(at('LEFT', justify), justify, justify .. ' over a left point')
		eq(at('TOPRIGHT', justify, 0), 'RIGHT', justify .. ' with no Max width: by the point')
		eq(UF.TextJustify({ justify = justify, position = { point = 'LEFT' } }), 'LEFT', justify .. ' with no max_width at all: by the point')
	end
end)

-- Each text's options group, by the config unit and the path to the group in
-- its element's config table.
local TEXTS = {
	{ 'Name', 'target', {} },
	{ 'Health', 'target', { 'text' } },
	{ 'Power', 'target', { 'text' } },
	{ 'AdditionalPower', 'player', { 'text' } },
	{ 'Castbar', 'target', { 'text' } },
	{ 'Castbar', 'target', { 'time' } },
	{ 'Name', 'nameplate', {} },
	{ 'Subtext', 'nameplate', {} },
	{ 'Subtext', 'friendlynameplate', {} },
	{ 'Threat', 'nameplate', {} },
}

local function group_of(UF, element, unit, path)
	local group = UF.elements[element].GetConfigTable(unit)
	for _, key in ipairs(path) do
		group = group.args[key]
		-- Power's and Additional power's text sits in an inline group under the tab's args.
		if not group then return nil end
	end
	return group
end

local function find_text_group(UF, element, unit, path)
	local tab = UF.elements[element].GetConfigTable(unit)
	if #path == 0 then return tab end
	-- The text's group may sit deeper (a bar's own inline group): search for it by key.
	local function search(node)
		if type(node) ~= 'table' or not node.args then return nil end
		if node.args[path[1]] and node.args[path[1]].type == 'group' then return node.args[path[1]] end
		for _, child in pairs(node.args) do
			local found = search(child)
			if found then return found end
		end
	end
	return group_of(UF, element, unit, path) or search(tab)
end

test("every text has Align: Auto, Left, Center, Right; Auto by default", function()
	local _, UF = world()
	for _, item in ipairs(TEXTS) do
		local element, unit, path = item[1], item[2], item[3]
		local label = element .. ' ' .. table.concat(path, '.') .. ' on ' .. unit
		local group = find_text_group(UF, element, unit, path)
		if check(group ~= nil, label .. ': its options') then
			local option = group.args.justify
			if check(option ~= nil, label .. ': has Align') then
				eq(option.name, 'Align', label .. ': named')
				eq(option.type, 'select', label .. ': a select')
				eq(table.concat(option.sorting, ','), 'AUTO,LEFT,CENTER,RIGHT', label .. ': its choices in order')
				eq(option.values.AUTO, 'Auto', label .. ': Auto named')
				check(type(option.desc) == 'string' and option.desc ~= '', label .. ': with a desc')
				eq(group.get({ 'justify' }), 'AUTO', label .. ': Auto by default')
				eq(option.disabledDesc ~= nil, true, label .. ': says why it is disabled')
				local width = group.args.max_width
				if check(width ~= nil, label .. ': has Max width') then
					eq(width.name, 'Max width', label .. ': Max width named')
					eq(width.type, 'range', label .. ': a range')
					eq(width.min, 0, label .. ': from 0')
					local saved = group.get({ 'max_width' })
					group.set({ 'max_width' }, 0)
					eq(option.disabled(), true, label .. ': Align disabled with no Max width')
					group.set({ 'max_width' }, 80)
					eq(option.disabled(), false, label .. ': and enabled with one')
					group.set({ 'max_width' }, saved)
				end
			end
		end
	end
	eq(#take_errors(), 0, 'no error')
end)

test('Max width sizes each text on a plate, Align lines it up in it; Auto, and no width, by the point', function()
	local _, UF, P = world()
	local frame = enemy('nameplate1')
	local cases = {
		{ 'Name', {}, function() return frame.Name end, 'LEFT' },
		{ 'Health', { 'text' }, function() return frame.Health.text end, 'RIGHT' },
		{ 'Castbar', { 'text' }, function() return frame.Castbar.Text end, 'LEFT' },
		{ 'Subtext', {}, function() return frame.Subtext end, 'CENTER' },
		{ 'Threat', {}, function() return frame.Threat end, 'RIGHT' },
	}
	for _, case in ipairs(cases) do
		local element, path, text, auto = case[1], case[2], case[3], case[4]
		local group = find_text_group(UF, element, 'nameplate', path)
		local label = element .. ' ' .. table.concat(path, '.')
		eq(text():GetJustifyH(), auto, label .. ': Auto, by its point')
		group.set({ 'max_width' }, 120)
		eq(text():GetWidth(), 120, label .. ': Max width gives it 120')
		eq(text():CanWordWrap(), false, label .. ': on one line')
		for _, justify in ipairs({ 'RIGHT', 'CENTER', 'LEFT' }) do
			group.set({ 'justify' }, justify)
			eq(text():GetJustifyH(), justify, label .. ': ' .. justify)
		end
		group.set({ 'justify' }, 'RIGHT')
		group.set({ 'max_width' }, 0)
		eq(text():GetWidth(), 0, label .. ': no width again')
		eq(text():GetJustifyH(), auto, label .. ': Right is set aside with no width: by its point')
		group.set({ 'justify' }, 'AUTO')
		eq(text():GetJustifyH(), auto, label .. ': Auto again')
	end
	eq(P.nameplate.name.justify, 'AUTO', 'saved back to Auto')
	eq(#take_errors(), 0, 'no error')
end)

test("a name's Align waits for a Max width, and keeps it through a font change", function()
	local _, UF, P = world()
	local target = NP.ouf:Spawn('target', 'SaftUI_Target')
	UF.units.target = target
	UF:UpdateUnitFrame(target)
	local name = target.Name
	local tab = UF.elements.Name.GetConfigTable('target')
	eq(P.target.name.max_width, 0, 'no Max width')
	eq(name:GetJustifyH(), 'LEFT', 'Auto: the target name is at a left point')
	tab.set({ 'justify' }, 'RIGHT')
	eq(name:GetJustifyH(), 'LEFT', 'Right waits: no width, so by its point')
	tab.set({ 'max_width' }, 100)
	eq(name:GetJustifyH(), 'RIGHT', 'Right once it has a width')
	-- In game SetFontObject puts the font's justification back; the stub keeps it, so this name's does
	-- what the game does, and an Align set before the font would be lost here.
	local setFontObject = name.SetFontObject
	name.SetFontObject = function(self, ...)
		setFontObject(self, ...)
		self:SetJustifyH('CENTER')
	end
	tab.set({ 'font' }, 'pixel')
	eq(name:GetJustifyH(), 'RIGHT', 'kept through a font change')
	tab.set({ 'max_width' }, 0)
	eq(name:GetJustifyH(), 'LEFT', 'by its point again when it loses the width')
	eq(#take_errors(), 0, 'no error')
end)

test('Align and Max width are shared: All units has their rows, step 1 entries like the rest', function()
	world()
	local UF = SaftUI:GetModule('Unitframes')
	for _, key in ipairs({ 'name.justify', 'health.text.justify', 'power.text.justify', 'castbar.text.justify', 'castbar.time.justify',
			'health.text.max_width', 'power.text.max_width', 'castbar.text.max_width', 'castbar.time.max_width' }) do
		local entry = UF.SHARED_BY_KEY[key]
		if check(entry ~= nil, key .. ' is shared') then
			eq(entry.type, key:match('max_width$') and 'range' or 'select', key .. ': its row type')
			eq(entry.since, 1, key .. ': step 1')
		end
	end
	eq(UF.SHARED_BY_KEY['subtext.justify'], nil, "the plates' texts aren't shared")
	eq(UF.SHARED_BY_KEY['threat.justify'], nil, "the plates' texts aren't shared")
	eq(UF.SHARED_BY_KEY['additionalpower.text.justify'], nil, 'Additional power is never shared')
end)

test('a profile converted before Align existed: nothing to sync, nobody owns it', function()
	local _, UF, profile = world()
	eq(UF:PrepareShared(profile) ~= nil, true, 'prepared')
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		for _, key in ipairs({ 'name.justify', 'health.text.justify', 'power.text.justify', 'castbar.text.justify', 'castbar.time.justify' }) do
			if UF:HasShared(unit, key) then rawset(profile[unit].own, key, nil) end
		end
	end
	eq(UF:SyncShared(profile), 0, 'the sync writes nothing')
	for _, unit in ipairs(UF.SHARE_MEMBERS) do
		eq(profile[unit].name.justify, 'AUTO', unit .. ': Auto')
		check(not rawget(profile[unit].own, 'name.justify'), unit .. ': follows All units')
	end
end)
