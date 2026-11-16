-- The General tab of Global settings (SaftUI-Core/Config/general.lua): Icon
-- zoom with its preview, Title bar height and Screen edge margin. Each row
-- reads and writes its profile key at call time, so a profile switch reaches
-- the new profile; the preview is cut as st:IconTexCoords (skinning.lua) cuts
-- SaftUI's icons at the zoom set now. Title bar height reaches every window
-- with a header at once (st:UpdateHeader, SaftUI-Core/panels.lua), and the
-- margin every frame kept inside it (st:UpdateScreenMargin, SaftUI-Core/api.lua;
-- the window with a header here), in combat too where the frame isn't
-- protected. tests/core/screen_margin_test.lua checks the margin on the other
-- frames it keeps in.
--
-- The UI scale section above them (Scale, UI size and the line under them)
-- reads and writes st.UIScale, not the profile, and asks through the Keep
-- prompt: a pick or a release previews, Keep saves, Go back puts the row back.
--
-- Real: Core's Config/config.lua on a real AceDB-3.0 (config_helpers.lua,
-- with Core's helpers, skinning.lua among them), the options model the window
-- reads rows with (optionsmodel.lua), the kit's widgets and body (the section
-- is drawn for the whole-pixel check), st.UIScale's runtime, the Keep prompt,
-- and panels.lua's headers and footers on a panel from st:CreatePanel.

local H = load_test_file('core/options_window_helpers.lua')
local P = load_test_file('lib/pixels.lua')
local st = SaftUI
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
load_saftui('SaftUI-Core/Config/uiscaleprompt.lua')
local OM, OB, UIScale, KP = st.OptionsModel, st.OptionsBody, st.UIScale, st.UIScalePrompt

local ICONS_NOTE = 'The preview changes at once. The icons across SaftUI change when you reload (Reload UI, bottom right).'
local PREVIEW_ICON = 'Interface\\Icons\\Spell_Nature_Lightning'
-- The bags' Bag Slots button follows the title bar's height (INV:SizeHeaderButtons),
-- so the note no longer says it waits for a reload.
local WINDOWS_NOTE = "The margin keeps all of SaftUI's frames that far from the screen's edges, not just the bags and bank; the minimap, which is Blizzard's, only when you drag it. Title bars and the margin change at once."
-- Under the Blizzard theme a window drawn in Blizzard's metal has the metal's
-- title bar, so the row says what it doesn't set there. A window whose own
-- Theme isn't Blizzard keeps its title bar at this height.
local TITLE_BAR_DESC = "The height of the strip along the top of SaftUI's windows (the bags and bank) that holds the title and the close button, and of the strip along their bottom. Under the Blizzard theme a window in Blizzard's metal holds its title in the metal's own title bar, which keeps Blizzard's height."

local function Tab() return st.Config:GetOptionsTable().Fonts.args.general end

local function ByOrder(t)
	local out = {}
	for key, v in pairs(t) do out[#out + 1] = { key = key, v = v } end
	table.sort(out, function(a, b) return a.v.order < b.v.order end)
	return out
end

-- The model's row for key on the General tab, and the tree it's in.
local function Row(key)
	local root = st.Config:GetOptionsTable()
	for _, section in ipairs(OM.BuildView(root, 'Fonts', { tab = 'general' }).sections) do
		for _, row in ipairs(section.rows) do
			if row.key == key then return root, row end
		end
	end
	error('no row ' .. key)
end

local function Get(key) local root, row = Row(key); return OM.Get(root, row) end
local function Set(key, value) local root, row = Row(key); return OM.Set(root, row, value) end

-- A frame's clamp insets as 'left,right,top,bottom' (-0 written as 0).
local function Insets(frame)
	local out = { frame:GetClampRectInsets() }
	for i, v in ipairs(out) do out[i] = tostring(v == 0 and 0 or v) end
	return table.concat(out, ',')
end

local panel = st:CreatePanel('General test', 200, 100)
st:CreateFooter(panel)

test('General: the UI scale section first, then Icons and Layout as before, each with a note; ranges with tooltips, and the preview', function()
	local tab = Tab()
	eq(tab.name, 'General')
	eq(tab.type, 'group')
	local sections = ByOrder(tab.args)
	eq(#sections, 3, 'three sections')
	eq(sections[1].key .. ',' .. sections[2].key .. ',' .. sections[3].key, 'uiscale,icons,windows')
	-- The last section's key is still windows; its name is Layout, since the
	-- margin keeps every frame in, not just the windows.
	eq(sections[1].v.name .. ',' .. sections[2].v.name .. ',' .. sections[3].v.name, 'UI scale,Icons,Layout')
	for _, s in ipairs(sections) do
		eq(s.v.type, 'group', s.key)
		eq(s.v.inline, true, s.key .. ' is a section, not a tab')
	end
	eq(tab.args.icons.desc, ICONS_NOTE, "Icons' note")
	eq(tab.args.windows.desc, WINDOWS_NOTE, "Layout's note")

	local function names(section)
		local out = {}
		for i, r in ipairs(ByOrder(section.args)) do out[i] = r.key .. '=' .. r.v.name end
		return table.concat(out, ',')
	end
	eq(names(tab.args.icons), 'icon_trim=Icon zoom,icon_preview=Preview')
	eq(names(tab.args.windows), 'header_height=Title bar height,clamp_inset=Screen edge margin')

	-- Every row is a range but the preview, a description (a line of its own,
	-- with no tooltip: it shows what the zoom does).
	eq(tab.args.icons.args.icon_preview.type, 'description', 'the preview')
	eq(tab.args.icons.args.icon_preview.width, nil, 'the preview has no Ace width')
	for sectionKey, section in pairs(tab.args) do
		for key, option in pairs(section.args) do
			if sectionKey ~= 'uiscale' and key ~= 'icon_preview' then
				eq(option.type, 'range', key)
				check(type(option.desc) == 'string' and #option.desc > 40, key .. ' has a desc')
				eq(option.width, nil, key .. ' has no Ace width')
				-- A slider can't be small in SaftUI's window; it takes a half.
				eq(option.size, nil, key .. ' takes the normal size')
			end
		end
	end
	eq(tab.args.windows.args.clamp_inset.desc, "How close to the screen's edges frames can go.", "the margin's tooltip, in the user's words")
	eq(tab.args.windows.args.header_height.desc, TITLE_BAR_DESC, "Title bar height's tooltip says what it doesn't set under Blizzard")
end)

test("Icon zoom is a percent of each edge, and its value is the profile's fraction", function()
	local zoom = Tab().args.icons.args.icon_trim
	eq(zoom.isPercent, true, 'shown as a percent')
	eq(zoom.min, 0); eq(zoom.max, 0.2, 'up to 20%'); eq(zoom.step, 0.005, 'in steps of half a percent')
	eq(Get('icon_trim'), 0.065, 'the default')
	Set('icon_trim', 0.1)
	eq(st.config.profile.misc.icon_trim, 0.1, 'a set writes the fraction')
	eq(Get('icon_trim'), 0.1, 'and reads it back')
	Set('icon_trim', 0.065)
end)

-- The preview's imageCoords as text, read through the model as the window
-- reads them.
local function PreviewCoords()
	local root, row = Row('icon_preview')
	local coords = OM.Member(root, row, 'imageCoords')
	return type(coords) == 'table' and table.concat(coords, ',') or tostring(coords)
end

test("Icon zoom's preview: a lightning icon at 36 by 36, cut as st:IconTexCoords cuts SaftUI's icons at the zoom set now", function()
	local root, row = Row('icon_preview')
	eq(row.type, 'description', 'a description row')
	eq(row.size, 'wide', 'on a line of its own')
	eq(row.name, 'Preview', 'its text')
	local zoomOrder = Tab().args.icons.args.icon_trim.order
	check(Tab().args.icons.args.icon_preview.order > zoomOrder, 'after Icon zoom')
	eq(OM.Member(root, row, 'image'), PREVIEW_ICON, 'the icon')
	eq(OM.Member(root, row, 'imageWidth'), 36, 'width')
	eq(OM.Member(root, row, 'imageHeight'), 36, 'height')

	local function Expected(trim) return table.concat({ st:IconTexCoords(trim, 36, 36) }, ',') end
	eq(PreviewCoords(), Expected(0.065), 'the default zoom')
	eq(#OM.Member(root, row, 'imageCoords'), 4, 'left, right, top, bottom')
	Set('icon_trim', 0.15)
	eq(PreviewCoords(), Expected(0.15), 'a new zoom, read when the coords are read')
	eq(PreviewCoords(), '0.15,0.85,0.15,0.85', '0.15 off each edge')
	st.config.profile.misc.icon_trim = 0
	eq(PreviewCoords(), '0,1,0,1', 'no zoom: the whole icon')
	Set('icon_trim', 0.065)
end)

test('Title bar height resizes every header and footer at once', function()
	eq(Get('header_height'), 31, 'the default')
	eq(panel.header:GetHeight(), 31)
	Set('header_height', 40)
	eq(st.config.profile.headers.height, 40, 'the profile')
	eq(panel.header:GetHeight(), 40, 'the header')
	eq(panel.footer:GetHeight(), 40, 'the footer')
	local range = Tab().args.windows.args.header_height
	eq(range.min .. '-' .. range.max .. '/' .. range.step, '20-60/1')
	Set('header_height', 31)
	eq(panel.header:GetHeight(), 31, 'and back')
end)

test("Screen edge margin keeps a window that far in from the screen's edges, and changes at once", function()
	eq(Get('clamp_inset'), 20, 'the default')
	check(panel:IsClampedToScreen(), 'a window with a header is clamped to the screen')
	-- The clamp rect is the frame's rect grown by the insets, and the game keeps
	-- it on screen: a positive margin keeps the window that far in.
	eq(Insets(panel), '-20,20,20,-20', 'the default margin')
	Set('clamp_inset', -10)
	eq(st.config.profile.misc.clamp_inset, -10, 'the profile')
	eq(Insets(panel), '10,-10,-10,10', 'below 0: the window can go that far past the edge')
	local range = Tab().args.windows.args.clamp_inset
	eq(range.min .. '-' .. range.max .. '/' .. range.step, '-50-50/1')
	Set('clamp_inset', 20)
	eq(Insets(panel), '-20,20,20,-20', 'and back')
end)

test("in combat a protected window's margin waits for the end of combat; the others change at once", function()
	-- Stub frames are never protected; this one says it is, as a bag window
	-- holding Blizzard's item buttons may be in game.
	local guarded = st:CreatePanel('General guarded', 200, 100)
	function guarded:IsProtected() return true, true end
	stub.in_combat = true
	st.config.profile.misc.clamp_inset = 5
	st:UpdateScreenMargin() -- what a profile change in combat runs
	eq(Insets(panel), '-5,5,5,-5', 'an unprotected window, at once')
	eq(Insets(guarded), '-20,20,20,-20', 'the protected one keeps its margin in combat')
	stub.in_combat = false
	stub.fire_event('PLAYER_REGEN_ENABLED')
	eq(Insets(guarded), '-5,5,5,-5', 'and takes the new one when combat ends')
	st.config.profile.misc.clamp_inset = 20
	st:UpdateScreenMargin()
	eq(#take_errors(), 0, 'no errors')
end)

test('after a profile switch, each row reads and writes the new profile, and the windows take its values', function()
	local first = st.config:GetCurrentProfile()
	Set('icon_trim', 0.1)
	Set('header_height', 44)
	Set('clamp_inset', 0)

	eq(PreviewCoords(), table.concat({ st:IconTexCoords(0.1, 36, 36) }, ','), 'the preview at the first profile\'s zoom')
	st.config:SetProfile('GeneralTestTwo')
	eq(Get('icon_trim'), 0.065, "the new profile's icon zoom")
	eq(PreviewCoords(), table.concat({ st:IconTexCoords(0.065, 36, 36) }, ','), "the preview takes the new profile's zoom")
	eq(Get('header_height'), 31, "the new profile's title bar height")
	eq(Get('clamp_inset'), 20, "the new profile's margin")
	eq(panel.header:GetHeight(), 31, 'the header takes it')
	eq(Insets(panel), '-20,20,20,-20', 'so does the margin')

	Set('header_height', 36)
	eq(st.config.profile.headers.height, 36, 'a set reaches the new profile')
	eq(panel.header:GetHeight(), 36)

	st.config:SetProfile(first)
	eq(Get('icon_trim'), 0.1, "the first profile's values are as they were")
	eq(Get('header_height'), 44)
	eq(Get('clamp_inset'), 0)
	eq(panel.header:GetHeight(), 44, 'and the windows take them again')
	eq(Insets(panel), '0,0,0,0')
	Set('icon_trim', 0.065)
	Set('header_height', 31)
	Set('clamp_inset', 20)
	eq(#take_errors(), 0, 'no errors')
end)


------------------------------------------------------------------ UI scale

local SECTION_DESC = "Saved for this computer and account, not in the profile, so a profile you share keeps the other person's screen size. A change shows at once: keep it within 15 seconds or it goes back. If SaftUI ever ends up too large or too small to use, type /sui scale reset."
local SCALE_DESC = "Automatic: SaftUI is laid out for a screen 1440 pixels high and scales to yours, so it takes the same share of any screen. Pixel for pixel: every size is that many pixels on your screen, as before this version, so SaftUI looks larger on a small screen and smaller on a large one. The game's UI scale: the game's own UI Scale (Options > Graphics) sets the size, and SaftUI keeps its lines whole at whatever size that is."
local SIZE_DESC = "Makes all of SaftUI larger or smaller than the automatic size. 100% is the size SaftUI works out for this screen. Every size and position in SaftUI's settings is in pixels of a 1440p screen, so they grow and shrink with this."

local function frames()
	for _ = 1, 20 do if stub.run_timers() == 0 then return end end
end

-- Past the half second Keep takes no click for.
local function ready()
	stub.time = stub.time + 0.6
	frames()
end

-- Chat lines printed while fn ran.
local function chat(fn)
	local lines, real = {}, print
	print = function(...)
		local parts = {}
		for i = 1, select('#', ...) do parts[i] = tostring((select(i, ...))) end
		lines[#lines + 1] = table.concat(parts, ' ')
	end
	local ok, err = pcall(fn)
	print = real
	if not ok then error(err, 0) end
	return lines
end

-- A world on a screen with the scale started: nothing saved, nothing
-- previewed, no prompt, out of combat, the first-login line already shown.
local function screen(width, height)
	KP:Dismiss()
	UIScale:Revert()
	stub.in_combat = false
	stub.screen_width, stub.screen_height = width or 1920, height or 1080
	UIParent:SetScale(0.64)
	st.config.global.uiScale = nil
	st.config.global.uiScaleNotice = 1
	start_uiscale()
	frames()
	take_errors()
end

local function keep() ready(); stub.click(KP:GetFrames().keep) end
local function goback() stub.click(KP:GetFrames().back) end

local function Section() return Tab().args.uiscale end
local function Differs(key) local root, row = Row(key); return OM.DefaultDiffers(root, row) end
local function Reset(key) local root, row = Row(key); return OM.DefaultReset(root, row) end
local function Disabled(key) local _, row = Row(key); return row.disabled, row.disabledDesc end

test('the UI scale section is first: Scale, UI size and the line; then Icons and Layout as before', function()
	local section = Section()
	eq(section.type, 'group'); eq(section.inline, true, 'a section, not a tab')
	eq(section.order, 0, 'first')
	eq(section.name, 'UI scale')
	eq(section.desc, SECTION_DESC, "the spec's description")
	local rows = ByOrder(section.args)
	eq(#rows, 3, 'three rows')
	eq(rows[1].key .. ',' .. rows[2].key .. ',' .. rows[3].key, 'scale,size,describe')
	eq(section.args.scale.name, 'Scale'); eq(section.args.scale.type, 'select')
	eq(section.args.scale.desc, SCALE_DESC)
	eq(section.args.size.name, 'UI size'); eq(section.args.size.type, 'range')
	eq(section.args.size.desc, SIZE_DESC)
	eq(section.args.describe.type, 'description')
	eq(Tab().args.icons.order, 1, 'Icons keeps its place after it')
	eq(Tab().args.windows.order, 2)
	for key, option in pairs(section.args) do
		eq(option.width, nil, key .. ' has no Ace width')
		eq(option.size, nil, key .. ' takes the normal size')
	end
end)

test("Scale lists Automatic, Pixel for pixel and The game's UI scale in that order; its reset goes back to Automatic through the prompt", function()
	screen(1920, 1080)
	local scale = Section().args.scale
	eq(scale.values.auto, 'Automatic'); eq(scale.values.pixel, 'Pixel for pixel'); eq(scale.values.game, "The game's UI scale")
	eq(table.concat(scale.sorting, ','), 'auto,pixel,game')
	check(scale.values == KP.MODE_NAMES, "the prompt's names, one list")
	eq(Get('scale'), 'auto', 'Automatic to begin with')
	eq(Differs('scale'), false, 'no reset icon at the default')

	UIScale:Apply({ mode = 'pixel', size = 1 })
	eq(Get('scale'), 'pixel')
	eq(Differs('scale'), true, 'the reset icon shows off Automatic')
	local root, row = Row('scale')
	local state = OM.DefaultState(root, row)
	eq(state.differs, true)
	eq(state.text, 'Automatic', "the default in words")
	eq(OM.DefaultSource(root, row), 'default', 'a hand default (the choice is not a profile key)')
	local ok = Reset('scale')
	eq(ok, true, 'the reset ran')
	check(KP:IsShown(), 'the reset asks through the prompt')
	check(UIScale:IsPreviewing(), 'it is a preview')
	eq(UIScale:Current().mode, 'auto'); eq(UIScale:Saved().mode, 'pixel', 'nothing saved until Keep')
	eq(Differs('scale'), false, 'the row shows the previewed choice')
	goback()
	eq(Get('scale'), 'pixel', 'Go back: the saved choice again')
	eq(Differs('scale'), true)
	Reset('scale'); keep()
	eq(UIScale:Saved(), nil, 'Keep: Automatic at 100% is the default, nothing saved')
	eq(Get('scale'), 'auto')
	eq(#take_errors(), 0)
end)

test('UI size: 70% to 150% in 5% steps, its top 130% on a 768 high screen, disabled unless Automatic, its reset to 100% through the prompt', function()
	screen(1920, 1080)
	local size = Section().args.size
	eq(size.min, 0.7); eq(size.step, 0.05); eq(size.isPercent, true); eq(size.applyOnRelease, true)
	eq(size.max, 1.5, 'the top on 1080p')
	screen(1366, 768)
	eq(Section().args.size.max, 1.3, '130% on a screen 768 high')
	screen(2560, 1440)
	eq(Section().args.size.max, 1.5)
	check(UIScale:Default().sizeMax == 1.5)

	screen(1920, 1080)
	eq(Get('size'), 1); eq(Differs('size'), false)
	local disabled = Disabled('size')
	check(not disabled, 'enabled in Automatic')
	UIScale:Apply({ mode = 'pixel', size = 1 })
	local off, why = Disabled('size')
	check(off, 'disabled in Pixel for pixel')
	check(type(why) == 'string' and #why > 20, 'with why: ' .. tostring(why))
	UIScale:Apply({ mode = 'auto', size = 0.8 })
	check(not Disabled('size'), 'enabled again')
	eq(Get('size'), 0.8)
	eq(Differs('size'), true, 'the reset shows off 100%')
	local root, row = Row('size')
	eq(OM.DefaultState(root, row).text, '100%', "the default in words")
	eq(Reset('size'), true)
	check(KP:IsShown(), 'the reset asks through the prompt')
	eq(UIScale:Saved().size, 0.8, 'nothing saved before Keep')
	eq(Get('size'), 1, 'the row shows the previewed size')
	goback()
	eq(Get('size'), 0.8, 'Go back')
	Reset('size'); keep()
	eq(UIScale:Saved(), nil, 'Keep at 100%: the default, nothing saved')
	eq(#take_errors(), 0)
end)

test('a pick previews and asks; Keep saves it; Go back puts the row back', function()
	screen(1920, 1080)
	check(Set('scale', 'pixel') ~= false, 'the set is taken')
	check(UIScale:IsPreviewing() and KP:IsShown(), 'the pick previews and the prompt asks')
	eq(Get('scale'), 'pixel', 'the row shows the previewed pick while the prompt waits')
	eq(UIScale:Saved(), nil, 'nothing saved yet')
	eq(UIParent:GetScale(), 768 / 1080, 'pixel for pixel is on screen')
	keep()
	eq(UIScale:Saved().mode, 'pixel', 'Keep saves it')
	eq(st.config.global.uiScale.mode, 'pixel')
	eq(Get('scale'), 'pixel')
	check(not KP:IsShown() and not UIScale:IsPreviewing(), 'the prompt is gone')

	Set('scale', 'auto')
	eq(Get('scale'), 'auto', 'previewing back')
	goback()
	eq(Get('scale'), 'pixel', 'Go back puts the row back')
	eq(st.config.global.uiScale.mode, 'pixel')

	-- A size release: Automatic at that size, with the prompt.
	Set('size', 1.25)
	eq(UIScale:Current().mode, 'auto'); eq(UIScale:Current().size, 1.25)
	eq(Get('size'), 1.25, 'the slider shows the previewed size')
	goback()
	eq(Get('size'), 1, 'and the saved one after Go back (Pixel for pixel keeps its size)')
	eq(#take_errors(), 0)
end)

test("a Go back or a Keep that makes the same scale draws nothing again, so the rows are told: on 1440p Automatic and Pixel for pixel are one scale", function()
	screen(2560, 1440)
	local told = 0
	local refresh = st.Config.Refresh
	st.Config.Refresh = function(...) told = told + 1; return refresh(...) end
	Set('scale', 'pixel')
	eq(Get('scale'), 'pixel')
	goback()
	eq(Get('scale'), 'auto', 'the row is back though no pass ran')
	check(told >= 1, 'the rows were told')
	local before = told
	Set('scale', 'pixel'); keep()
	check(told > before, 'Keep tells them too')
	st.Config.Refresh = refresh
	UIScale:Apply(nil)
end)

test('refusals: in combat the row says so and asks nothing; a size the screen no longer holds says so', function()
	screen(1920, 1080)
	stub.in_combat = true
	local lines = chat(function() Set('scale', 'pixel') end)
	stub.in_combat = false
	eq(#lines, 1, 'one line')
	check(lines[1]:find("The UI size can't change in combat.", 1, true), lines[1])
	check(not KP:IsShown() and not UIScale:IsPreviewing(), 'no prompt, no preview')
	eq(Get('scale'), 'auto', 'the row is as it was')

	stub.in_combat = true
	local ok, message = Reset('size')
	check(ok == false or ok == nil or Differs('size') == false, 'a reset that is not needed')
	stub.in_combat = false
	UIScale:Apply({ mode = 'auto', size = 0.8 })
	stub.in_combat = true
	ok, message = Reset('size')
	stub.in_combat = false
	eq(ok, false, "a reset in combat is refused; the status line shows why")
	check(type(message) == 'string' and message:find('combat', 1, true), tostring(message))

	local without = st.UIScalePrompt
	st.UIScalePrompt = nil
	lines = chat(function() Set('scale', 'pixel') end)
	st.UIScalePrompt = without
	eq(#lines, 1, 'no prompt loaded: one line, no error')
	eq(#take_errors(), 0)
end)

test('the line says what is applied: "This screen is 1920 x 1080: SaftUI draws at 75% of its 1440p size, with 1 pixel lines."', function()
	screen(1920, 1080)
	local _, row = Row('describe')
	eq(row.name, 'This screen is 1920 x 1080: SaftUI draws at 75% of its 1440p size, with 1 pixel lines.')
	Set('size', 1.25)
	_, row = Row('describe')
	eq(row.name, 'This screen is 1920 x 1080: SaftUI draws at 94% of its 1440p size, with 1 pixel lines.', 'it follows the preview')
	goback()
	_, row = Row('describe')
	eq(row.name, 'This screen is 1920 x 1080: SaftUI draws at 75% of its 1440p size, with 1 pixel lines.', 'and Go back')
	screen(3456, 2234)
	_, row = Row('describe')
	eq(row.name, 'This screen is 3456 x 2234: SaftUI draws at 155% of its 1440p size, with 2 pixel lines.')
	UIScale:Apply({ mode = 'pixel', size = 1 })
	_, row = Row('describe')
	eq(row.name, 'This screen is 3456 x 2234: SaftUI draws pixel for pixel, at 100% of its 1440p size, with 1 pixel lines.')
	screen(1920, 1080)
end)

test("six fast display changes in a second: the guard stops setting the scale back, and the section says so instead of a size it is not drawing; a change here starts it again", function()
	screen(2560, 1440)
	stub.timers_wait_a_frame = true
	local lines = chat(function()
		for _ = 1, 8 do
			stub.engine_set_scale(0.9)
			stub.run_timers()
		end
	end)
	stub.timers_wait_a_frame = false
	check(UIScale:GaveUp(), 'the guard gave up')
	local _, row = Row('describe')
	check(not row.name:find('draws at 100%', 1, true), 'the line does not claim a size that is not drawn: ' .. row.name)
	check(row.name:find('Use UI Scale', 1, true), 'it says what to do: ' .. row.name)
	eq(Get('scale'), 'auto', 'the rows still show the choice')
	eq(Get('size'), 1)
	Set('size', 0.9)
	check(not UIScale:GaveUp(), 'a change here sets the scale again')
	check(math.abs(UIParent:GetScale() - 768 / 1440 * 0.9) < 1e-9, 'at the previewed size')
	goback()
	eq(#take_errors(), 0)
end)

test('the rows read and write st.UIScale, never the profile: a profile switch changes nothing they show', function()
	screen(1920, 1080)
	UIScale:Apply({ mode = 'auto', size = 0.9 })
	local first = st.config:GetCurrentProfile()
	local function snapshot() return Get('scale') .. ',' .. Get('size') end
	eq(snapshot(), 'auto,0.9')
	Set('size', 1.1); keep()
	eq(st.config.profile.uiScale, nil, 'a write puts nothing in the profile')
	eq(st.config.global.uiScale.size, 1.1, 'it is in the account-wide table')
	st.config:SetProfile('GeneralTestScale')
	eq(snapshot(), 'auto,1.1', 'a new profile changes nothing')
	eq(st.config.profile.uiScale, nil)
	st.config:SetProfile(first)
	eq(snapshot(), 'auto,1.1')
	UIScale:Apply(nil)
	eq(#take_errors(), 0)
end)

-- The section drawn as the window draws it, under each look, with the
-- game's read-back noise.
test('the section on whole pixels under Thick, Thin and Blizzard, with stub.size_noise up, down and off', function()
	-- At one pixel to the unit: the kit's own boxes are whole pixels only there
	-- until its phase (.agents/edit-mode.md, the UI scale).
	screen(1920, 1080)
	UIScale:Apply({ mode = 'pixel', size = 1 })
	frames()
	local root = st.Config:GetOptionsTable()
	for _, name in ipairs({ 'thick', 'thin', 'blizzard' }) do
		st.config.profile.theme.name = name
		for _, noise in ipairs({ 2 ^ -14, -2 ^ -14, 0 }) do
			stub.size_noise = noise
			local content = CreateFrame('Frame', nil, UIParent)
			content:SetPoint('TOPLEFT', UIParent, 'TOPLEFT', 100, -100)
			content:SetSize(774, 900)
			local body = OB.New(content, root, nil, 774)
			local view = OM.BuildView(root, 'Fonts', { tab = 'general' })
			local drawn = {}
			for _, section in ipairs(view.sections) do
				if section.title == 'UI scale' then drawn[#drawn + 1] = section end
			end
			check(#drawn == 1, 'the UI scale section is in the view')
			body:Draw(drawn)
			local off = P.off(content)
			eq(#off, 0, name .. ' noise ' .. noise .. ': ' .. P.report(off))
			body:Release()
		end
	end
	st.config.profile.theme.name = 'thick'
	stub.size_noise = 0
	UIScale:Apply(nil)
end)
