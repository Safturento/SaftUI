-- The totem bar's timers have a font of their own (totembar.timer_font, a Font
-- row on the Totem bar's page), not Button text's:
--   - an untouched profile draws what the timers drew while they followed Button
--     text: the shared font Small text (the default of both), so nothing changes;
--   - Button text no longer reaches them (it still reaches the bar's key
--     bindings, counts and names), and the row's pick (a shared font or a
--     typeface) reaches them at once and sets how tall the timers are laid out;
--   - the row has a reset, which names Small text.
--
-- Real: SaftUI-Misc's config.lua, totembar.lua, totemlayout.lua,
-- totemposition.lua, totemoptions.lua, totemskin.lua and totemtimers.lua, Core's
-- helpers and options model. Stand-ins: Blizzard's totem slot buttons and the
-- summon button (as font_readers_test.lua builds them).
local T = load_test_file('lib/theme_helpers.lua')

local function world()
	local st = T.client('forever')
	load_editmode()
	load_saftui('SaftUI-Misc/config.lua')
	apply_defaults()
	load_saftui('SaftUI-Core/Config/optionsmodel.lua')
	for _, file in ipairs({ 'totembar', 'totemlayout', 'totemposition', 'totemoptions', 'totemskin', 'totemtimers' }) do
		load_saftui('SaftUI-Misc/' .. file .. '.lua')
	end
	GetTotemDuration = function() end
	FIRE_TOTEM_SLOT, EARTH_TOTEM_SLOT, WATER_TOTEM_SLOT, AIR_TOTEM_SLOT = 1, 2, 3, 4
	local slots = {}
	for i = 1, 4 do
		local button = CreateFrame('Button', 'MultiCastSlotButton' .. i, UIParent)
		button:SetID(i)
		button:SetSize(30, 30)
		button:SetPoint('CENTER')
		button.background = button:CreateTexture(nil, 'BACKGROUND')
		button.overlayTex = button:CreateTexture(nil, 'OVERLAY')
		slots[i] = button
	end
	local summon = CreateFrame('CheckButton', 'MultiCastSummonSpellButton', UIParent)
	summon:SetSize(30, 30)
	summon:SetPoint('CENTER')
	summon.icon = summon:CreateTexture(nil, 'BACKGROUND')
	summon.Flash = summon:CreateTexture(nil, 'ARTWORK', nil, 1)
	summon.Count = summon:CreateFontString(nil, 'ARTWORK')
	summon.HotKey = summon:CreateFontString(nil, 'OVERLAY')
	summon.Name = summon:CreateFontString(nil, 'OVERLAY')
	local TB = st:GetModule('TotemBar')
	st:BindModuleConfig(TB, 'totembar')
	TB:SetupSkin()
	TB:SetupTimers()
	return st, TB, summon, slots
end

-- The timer text on a slot button: the first font string under it.
local function timer_text(frame, depth)
	for _, region in ipairs({ frame:GetRegions() }) do
		if region:GetObjectType() == 'FontString' then return region end
	end
	if depth > 0 then
		for _, child in ipairs({ frame:GetChildren() }) do
			local found = timer_text(child, depth - 1)
			if found then return found end
		end
	end
end

local FACE = { font_name = 'Colus', font_size = 13, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }

test('an untouched profile draws the timers as they were drawn: in Small text', function()
	local st, TB, _, slots = world()
	eq(st.defaults.totembar.timer_font, 'pixel', 'the default is the shared font Small text')
	eq(TB.config.timer_font, 'pixel', 'a profile that never saved it reads Small text')
	eq(st.config.profile.buttons.font, 'pixel', 'and Button text defaults to the same font')
	local text = timer_text(slots[1], 3)
	check(text ~= nil, 'a timer text was made')
	check(text:GetFontObject() == st:GetFont('pixel'), 'drawn in Small text')
	local _, size, flags = text:GetFontObject():GetFont()
	local _, wantSize, wantFlags = st:FontValues('pixel')
	eq(size .. flags, wantSize .. wantFlags, 'at the size and outline Button text gave it')
	local x, y = text:GetFontObject():GetShadowOffset()
	eq(x .. ',' .. y, '0,0', 'with no shadow')
	eq(#take_errors(), 0, 'no errors')
end)

test('Button text no longer reaches the timers, and still reaches the bar\'s other texts', function()
	local st, TB, summon, slots = world()
	local text = timer_text(slots[1], 3)
	st.config.profile.buttons.font = 'heading'
	st:FontsChanged()
	check(text:GetFontObject() == st:GetFont('pixel'), 'the timer text stays in its own font')
	for _, key in ipairs({ 'HotKey', 'Count', 'Name' }) do
		check(summon[key]:GetFontObject() == st:GetFont('heading'), 'the ' .. key .. ' follows Button text')
	end
	st.config.profile.buttons.font = FACE
	st:FontsChanged()
	check(text:GetFontObject() == st:GetFont('pixel'), 'a typeface in Button text leaves it too')
	st.config.profile.buttons.font = 'pixel'
	st:FontsChanged()
	eq(#take_errors(), 0, 'no errors')
end)

test('the timers follow their own font: a shared font or a typeface, at once, and lay out by its size', function()
	local st, TB, _, slots = world()
	local text = timer_text(slots[1], 3)
	TB.config.timer_bar, TB.config.timer_text, TB.config.timer_text_position = true, true, 'on'
	local function tallest()
		local tall = 0
		for _, child in ipairs({ slots[1]:GetChildren() }) do
			for _, grandchild in ipairs({ child:GetChildren() }) do tall = math.max(tall, grandchild:GetHeight()) end
		end
		return tall
	end
	TB.config.timer_font = 'pixel'
	st:FontsChanged()
	local small = tallest()

	TB.config.timer_font = 'pixel_med'
	st:FontsChanged()
	check(text:GetFontObject() == st:GetFont('pixel_med'), 'Large numbers reach the timer text at once')
	check(tallest() > small, 'and lay the timers out taller: ' .. tallest() .. ' against ' .. small)

	TB.config.timer_font = FACE
	st:FontsChanged()
	check(text:GetFontObject() == st:FontObject(FACE), 'a typeface reaches it')

	-- Small text's own change reaches a timer on it.
	TB.config.timer_font = 'pixel'
	st.config.profile.fonts.pixel.font_size = 14
	st:GetModule('Fonts'):UpdateFontConfig('pixel')
	st:FontsChanged()
	eq(select(2, text:GetFontObject():GetFont()), 14, 'a Small text change reaches a timer that follows Small text')
	st.config.profile.fonts.pixel.font_size = nil
	st:GetModule('Fonts'):UpdateFontConfig('pixel')

	-- A value that names nothing draws Text.
	TB.config.timer_font = 'gone'
	st:FontsChanged()
	check(text:GetFontObject() == st:GetFont('normal'), 'a value that names nothing draws Text')
	TB.config.timer_font = 'pixel'
	st:FontsChanged()
	eq(#take_errors(), 0, 'no errors')
end)

test('the Totem bar page has a Timer font row: a font row with a reset that names Small text', function()
	local st, TB = world()
	local OM = st.OptionsModel
	TB.bar = CreateFrame('Frame', 'ScratchTotemBar', UIParent)
	local tree = TB:GetConfigTable()
	local row = tree.args.timer_font
	check(row ~= nil, 'the page has a timer_font row')
	eq(row.type, 'font', 'it is the font row (a shared font with the link, or a typeface with dots)')
	check(not row.faceOnly, 'the full row: the typeface menu has every field')
	check(row.name:find('Timer', 1, true), 'named for the timers: ' .. tostring(row.name))
	check(type(row.desc) == 'string' and row.desc:find('timer', 1, true), 'it says what it changes: ' .. tostring(row.desc))
	check(row.default ~= nil, 'it has a reset')

	local root = { TotemBar = tree }
	local view = OM.BuildView(root, 'TotemBar')
	local found
	for _, section in ipairs(view.sections) do
		for _, r in ipairs(section.rows) do
			if r.key == 'timer_font' then found = r end
		end
	end
	check(found ~= nil, 'the row is on the page')
	eq(OM.Get(root, found), 'pixel', 'it reads totembar.timer_font')
	eq(OM.DefaultState(root, found).differs, false, 'at the default it shows no reset')

	-- A pick writes the profile and reaches the timers at once (the page's set runs st:FontsChanged).
	local text = timer_text(_G.MultiCastSlotButton1, 3)
	OM.Set(root, found, 'heading')
	eq(TB.config.timer_font, 'heading', 'a pick writes totembar.timer_font')
	check(text:GetFontObject() == st:GetFont('heading'), 'and reaches the timers at once')
	local state = OM.DefaultState(root, found)
	eq(state.differs, true, 'it differs now')
	eq(state.text, 'Small text', 'the reset names Small text')
	OM.Set(root, found, FACE)
	eq(OM.DefaultState(root, found).differs, true, 'a typeface differs too')
	check(text:GetFontObject() == st:FontObject(FACE), 'and reaches the timers')
	OM.DefaultReset(root, found)
	eq(TB.config.timer_font, 'pixel', 'the reset puts Small text back')
	check(text:GetFontObject() == st:GetFont('pixel'), 'and the timers with it')
	eq(#take_errors(), 0, 'no errors')
end)

test('the timers read no Button text: no ButtonsFont left in totemtimers.lua', function()
	local code = select(1, load_test_file('lib/source_lex.lua').Lex(read_saftui_source('SaftUI-Misc/totemtimers.lua')))
	check(not code:find('buttons.font', 1, true), 'totemtimers.lua does not read profile.buttons.font')
end)
