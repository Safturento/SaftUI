-- The micro menu's settings (SaftUI-Minimap/micromenu.lua, microbuttons.lua,
-- micromenuoptions.lua):
--   - the bar's height and its gap between items, each item laid out at them,
--     Blizzard's micro buttons at the template's shape for the height;
--   - the text items' widths, by key;
--   - an item turned off leaves the row and is concealed (alpha 0, the mouse
--     off on it and its children), never hidden or reparented, and comes back
--     as it was; a micro button stays concealed after Blizzard's OnEnable and
--     OnDisable set its alpha, and its panel hides;
--   - the text font on the items' texts;
--   - the mouseover fade: the bar and the micro buttons' panels at the faded
--     opacity, full under the mouse, alpha 1 once it's off;
--   - every row of the page has a reset, the Items tab's per-item rows too.
--
-- Real: SaftUI-Minimap's config.lua and the micro menu's files, Core's helpers
-- and the theme engine.
load_core_helpers()
load_editmode()
load_options_widgets()
local T = load_test_file('lib/theme_helpers.lua')
local locked = load_test_file('lib/locked_widget.lua')
CreateFrame('Frame', 'Minimap', UIParent)
load_saftui('SaftUI-Minimap/minimap.lua')
load_saftui('SaftUI-Minimap/config.lua')
apply_defaults()
for _, file in ipairs({ 'micromenu', 'micromenuart', 'micromenuitems', 'micromenuoptions', 'microbuttons' }) do
	load_saftui('SaftUI-Minimap/' .. file .. '.lua')
end

local st = SaftUI
local MicroMenu = st:GetModule('MicroMenu')
st:BindModuleConfig(MicroMenu, 'micromenu')
local profile = st.config.profile
MicroMenu.Container = CreateFrame('Frame', nil, UIParent)
MicroMenu.Container:SetPoint('TOPLEFT')

-- Two text items, one of them a Blizzard-like frame with a child that takes
-- the mouse, a square item, and two micro buttons.
local zone = locked(CreateFrame('Button', nil, UIParent), 'Blizzard zone button')
zone:EnableMouse(true)
local zoneChild = CreateFrame('Button', nil, zone)
zoneChild:EnableMouse(true)
local zoneText = zone:CreateFontString(nil, 'OVERLAY')
local clock = CreateFrame('Button', nil, UIParent)
local clockText = clock:CreateFontString(nil, 'OVERLAY')
local mail = locked(CreateFrame('Frame', nil, UIParent), 'Blizzard mail')

local menu = CreateFrame('Frame', 'MicroMenu', UIParent)
function menu:Layout() end
local function micro_button(index, name)
	local button = CreateFrame('Button', name, menu)
	button.layoutIndex, button.textureName = index, name
	button.Background = button:CreateTexture(nil, 'BACKGROUND')
	button.PushedBackground = button:CreateTexture(nil, 'BACKGROUND')
	button.FlashBorder = button:CreateTexture(nil, 'OVERLAY')
	button.Shadow = button:CreateTexture(nil, 'BORDER')
	button.PushedShadow = button:CreateTexture(nil, 'OVERLAY')
	button.MainMenuBarPerformanceBar = button:CreateTexture(nil, 'ARTWORK')
	button.Emblem = button:CreateTexture(nil, 'ARTWORK')
	button.HighlightEmblem = button:CreateTexture(nil, 'ARTWORK')
	button:SetNormalTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetPushedTexture(button:CreateTexture(nil, 'ARTWORK'))
	button:SetHighlightTexture(button:CreateTexture(nil, 'HIGHLIGHT'))
	button.SetHighlightAtlas = function(self, atlas, blend)
		self:GetHighlightTexture():SetAtlas(atlas)
	end
	-- Blizzard's MainMenuBarMicroButtonMixin:OnEnable and OnDisable
	button:SetScript('OnEnable', function(self) self:SetAlpha(1) end)
	button:SetScript('OnDisable', function(self) self:SetAlpha(0.5) end)
	return locked(button, 'Blizzard micro button')
end
local character = micro_button(1, 'CharacterMicroButton')
local lfd = micro_button(2, 'LFDMicroButton')

MicroMenu:AddButton(zone, { key = 'zone', width = 200, text = zoneText })
MicroMenu:AddButton(clock, { key = 'clock', width = 60, text = clockText })
MicroMenu:SkinBlizzardMicroMenu()
MicroMenu:AddButton(mail, { key = 'mail' })

local function fresh()
	profile.micromenu = nil
	apply_defaults()
	st:BindModuleConfig(MicroMenu, 'micromenu')
	MicroMenu:UpdateConfig()
	stub.cursor_x, stub.cursor_y = -1000, -1000
end

-- The gap from a's right edge to b's left edge
local function gap(a, b) return b:GetLeft() - a:GetRight() end

test('by default every item is 25 tall, 8 apart, the micro buttons 20 wide', function()
	fresh()
	eq(zone:GetHeight(), 25, 'the zone is 25 tall')
	eq(zone:GetWidth(), 200, 'the zone is 200 wide')
	eq(clock:GetWidth(), 60, 'the clock is 60 wide')
	eq(gap(zone, clock), 8, '8 between the zone and the clock')
	eq(character:GetWidth(), 20, 'a micro button is 20 wide')
	eq(character:GetHeight(), 25, 'and 25 tall')
	eq(mail:GetWidth(), 25, 'the mail is square')
	eq(MicroMenu.Container:GetHeight(), 25, 'the bar is 25 tall')
	eq(table.concat(take_errors(), '\n'), '', 'no errors')
end)

test('Height and Spacing lay every item out again', function()
	fresh()
	profile.micromenu.height = 30
	profile.micromenu.spacing = 2
	MicroMenu:UpdateConfig()
	eq(zone:GetHeight(), 30, 'the zone is 30 tall')
	eq(gap(zone, clock), 2, '2 between the zone and the clock')
	eq(character:GetWidth(), 24, 'a micro button keeps its shape: 24 wide')
	eq(character:GetHeight(), 30, 'and 30 tall')
	eq(mail:GetWidth(), 30, 'the mail is square at 30')
	eq(MicroMenu.Container:GetHeight(), 30, 'the bar is 30 tall')
	local w = 200 + 60 + 24 + 24 + 30 + 2 * 4
	eq(MicroMenu.Container:GetWidth(), w, 'the bar is as wide as its items and gaps')
	-- out of range values are held to the page's
	profile.micromenu.height, profile.micromenu.spacing = 400, -5
	MicroMenu:UpdateConfig()
	eq(zone:GetHeight(), MicroMenu.HEIGHT_MAX, 'the height is held to its most')
	eq(gap(zone, clock), 0, 'the gap to its least')
end)

test('a text item takes its width from the profile', function()
	fresh()
	profile.micromenu.widths.zone = 120
	profile.micromenu.widths.clock = 44
	MicroMenu:UpdateConfig()
	eq(zone:GetWidth(), 120, 'the zone is 120 wide')
	eq(clock:GetWidth(), 44, 'the clock is 44 wide')
end)

test('an item turned off leaves the row, concealed, and comes back as it was', function()
	fresh()
	profile.micromenu.show.clock = false
	profile.micromenu.show.zone = false
	MicroMenu:UpdateConfig()
	check(zone:IsShown(), 'the zone keeps its shown state')
	eq(zone:GetParent(), MicroMenu.Container, 'and its parent')
	eq(zone:GetAlpha(), 0, 'it draws nothing')
	check(not zone:IsMouseEnabled(), 'it takes no mouse')
	check(not zoneChild:IsMouseEnabled(), 'nor does its child')
	check(MicroMenu:IsConcealed(zone), 'it reads as concealed')
	local first = select(2, character:GetPoint(1))
	eq(select(2, first:GetPoint(1)), MicroMenu.Container, 'the micro buttons lead the row')

	profile.micromenu.show.zone = nil
	profile.micromenu.show.clock = nil
	MicroMenu:UpdateConfig()
	eq(zone:GetAlpha(), 1, 'the zone draws again')
	check(zone:IsMouseEnabled(), 'it takes the mouse again')
	check(zoneChild:IsMouseEnabled(), 'and its child')
	eq(gap(zone, clock), 8, 'and is back in the row')
	eq(table.concat(take_errors(), '\n'), '', 'no errors')
end)

test('a micro button turned off stays concealed through Blizzard\'s alpha', function()
	fresh()
	profile.micromenu.show.micro_LFD = false
	MicroMenu:UpdateConfig()
	eq(lfd:GetAlpha(), 0, 'the group finder draws nothing')
	check(not lfd:IsMouseEnabled(), 'it takes no mouse')
	lfd:Disable()
	eq(lfd:GetAlpha(), 0, 'still nothing after Blizzard\'s OnDisable')
	lfd:Enable()
	eq(lfd:GetAlpha(), 0, 'and after its OnEnable')
	eq(MicroMenu.Container:GetWidth(), 200 + 60 + 20 + 25 + 8 * 3, 'its slot is gone from the bar')

	profile.micromenu.show.micro_LFD = nil
	MicroMenu:UpdateConfig()
	eq(lfd:GetAlpha(), 1, 'it draws again')
	check(lfd:IsMouseEnabled(), 'and takes the mouse')
	lfd:Disable()
	eq(lfd:GetAlpha(), 0.5, 'Blizzard dims it while disabled again')
	lfd:Enable()
end)

test('the text font goes on the items\' texts', function()
	fresh()
	eq(zoneText:GetFontObject(), st:FontObject('pixel'), 'the pixel font by default')
	profile.micromenu.font = 'heading'
	MicroMenu:OnFontsChanged()
	eq(zoneText:GetFontObject(), st:FontObject('heading'), 'the zone text takes Heading')
	eq(clockText:GetFontObject(), st:FontObject('heading'), 'so does the clock')
end)

test('the mouseover fade: faded, full under the mouse, whole once off', function()
	fresh()
	profile.micromenu.visibility = 'mouseover'
	profile.micromenu.fade_alpha = 0.3
	MicroMenu:UpdateFade()
	eq(MicroMenu.Container:GetAlpha(), 0.3, 'the bar is faded')
	eq(menu:GetAlpha(), 0.3, "Blizzard's micro menu with it")
	check(MicroMenu.Fader:IsShown(), 'the fader runs')

	local scale = MicroMenu.Container:GetEffectiveScale()
	stub.cursor_x = (MicroMenu.Container:GetLeft() + 5) * scale
	stub.cursor_y = (MicroMenu.Container:GetTop() - 5) * scale
	stub.fire_script(MicroMenu.Fader, 'OnUpdate', 10)
	eq(MicroMenu.Container:GetAlpha(), 1, 'full under the mouse')
	eq(menu:GetAlpha(), 1, 'the micro menu too')
	stub.cursor_x, stub.cursor_y = -1000, -1000
	stub.fire_script(MicroMenu.Fader, 'OnUpdate', 10)
	eq(MicroMenu.Container:GetAlpha(), 0.3, 'faded again once the mouse leaves')

	profile.micromenu.visibility = 'always'
	MicroMenu:UpdateFade()
	eq(MicroMenu.Container:GetAlpha(), 1, 'whole once the fade is off')
	eq(menu:GetAlpha(), 1, 'the micro menu too')
	check(not MicroMenu.Fader:IsShown(), 'the fader stops')
end)

test('every row of the page has a reset, each item\'s too', function()
	fresh()
	local update = MicroMenu.UpdateConfig
	function MicroMenu:UpdateConfig() end
	MicroMenu:RegisterMicroMenuMover() -- the Position's reset is the mover's
	local page = MicroMenu:GetConfigTable()
	local show = page.args.items.args.show.args
	check(show.zone and show.clock and show.mail, 'the bar\'s items are listed')
	check(show.micro_Character and show.micro_LFD, 'and its micro buttons')
	eq(show.micro_LFD.name, 'Group finder', 'named for people')
	local R = load_test_file('lib/reset_walk.lua')
	local ok, err = pcall(function() R.check_page({ MicroMenu = page }, 'MicroMenu') end)
	MicroMenu.UpdateConfig = update
	if not ok then error(err, 0) end
end)
