-- The totem bar under Blizzard, over Blizzard's action art:
--  1. an element action button's ring (StyleRing: st:SetBackdropIn, then the
--     backdrop anchored on the button) fills the button, cut to its part of
--     the art, as do the state textures, whatever the flat look left on them;
--  2. a slot button's element border recolored in combat moves nothing when
--     the slot button is secure (.agents/taint.md rule 12).
load_core_helpers()
load_editmode()
local T = load_test_file('lib/theme_helpers.lua')
local locked = load_test_file('lib/locked_widget.lua')
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
for _, file in ipairs({ 'totembar', 'totemlayout', 'totemposition', 'totemoptions', 'totemskin' }) do
	load_saftui('SaftUI-Misc/' .. file .. '.lua')
end
local st = SaftUI
local profile = st.config.profile

FIRE_TOTEM_SLOT, EARTH_TOTEM_SLOT, WATER_TOTEM_SLOT, AIR_TOTEM_SLOT = 1, 2, 3, 4
-- Blizzard's update, which the skin post-hooks.
function MultiCastSlotButton_Update(self) end
local slots = {}
for i = 1, 4 do
	local button = CreateFrame('Button', 'MultiCastSlotButton' .. i, UIParent, 'SecureActionButtonTemplate')
	button:SetID(i)
	button:SetSize(30, 30)
	button:SetPoint('CENTER')
	button.background = button:CreateTexture(nil, 'BACKGROUND')
	button.overlayTex = button:CreateTexture(nil, 'OVERLAY')
	slots[i] = locked(button, 'Blizzard totem slot')
end
local flyout = CreateFrame('Frame', 'MultiCastFlyoutFrame', UIParent)
flyout.top = flyout:CreateTexture(nil, 'ARTWORK')
flyout.middle = flyout:CreateTexture(nil, 'ARTWORK')
locked(flyout, 'Blizzard totem flyout')

local function totem_button(name)
	local button = CreateFrame('CheckButton', name, UIParent)
	button:SetSize(30, 30)
	button:SetPoint('CENTER')
	button.icon = button:CreateTexture(nil, 'BACKGROUND')
	button.Flash = button:CreateTexture(nil, 'ARTWORK', nil, 1)
	button.TextOverlayContainer = CreateFrame('Frame', nil, button)
	button.TextOverlayContainer:SetFrameLevel(500)
	button.Count = button.TextOverlayContainer:CreateFontString(nil, 'OVERLAY')
	button.HotKey = button.TextOverlayContainer:CreateFontString(nil, 'OVERLAY')
	button.Name = button:CreateFontString(nil, 'OVERLAY')
	return locked(button, 'Blizzard totem button')
end
local action = totem_button('MultiCastActionButton1')
action:SetFrameLevel(slots[1]:GetFrameLevel() + 2)

local TB = st:GetModule('TotemBar')
st:BindModuleConfig(TB, 'totembar')

local function ring_of(button)
	for _, child in ipairs({ button:GetChildren() }) do
		local art = st.ThemeArt.Get(child)
		if art and art.over and art.over.Ring then return art.over.Ring, child end
	end
end

local CUT = T.text(0, 0, 0, 1, 45 / 46, 0, 45 / 46, 1)

test("under Blizzard an element action button's ring and state art fill the button, cut to 45/46", function()
	TB:SetupSkin()
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	TB:ApplySkin()
	local ring = ring_of(action)
	check(ring ~= nil, 'the action button has a ring')
	if not ring then return end
	eq(T.around(ring, action), '0,0,0,0', 'the ring fills the button')
	eq(T.text(ring:GetTexCoord()), CUT, 'cut to the button\'s part of the art')
	for name, region in pairs({ hover = action:GetHighlightTexture(), pushed = action:GetPushedTexture(), flash = action.Flash }) do
		eq(T.around(region, action), '0,0,0,0', name .. ' fills the button')
		eq(T.text(region:GetTexCoord()), CUT, name .. ' is cut')
	end
	take_errors()
end)

test("the totem bar's checked texture is the cut atlas under Blizzard after the flat look's fade was on it", function()
	profile.theme.name = 'thick'
	st:RedrawThemed()
	TB:ApplySkin()
	local checked = action:GetCheckedTexture()
	check(checked ~= nil, 'the action button has a checked texture')
	if not checked then return end
	eq(select(5, checked:GetTexCoord()) > 1, true, "the flat look's fade is on it")
	profile.theme.name = 'blizzard'
	st:RedrawThemed()
	TB:ApplySkin()
	eq(T.text(checked:GetTexCoord()), CUT, 'under Blizzard it is the cut of the atlas')
	take_errors()
end)

test("a secure slot button's element border recolored in combat moves nothing", function()
	stub.blocked = {}
	stub.in_combat = true
	MultiCastSlotButton_Update(slots[1])
	MultiCastSlotButton_Update(slots[2])
	stub.in_combat = false
	local names = {}
	for _, call in ipairs(stub.blocked) do names[#names + 1] = call[2] end
	eq(#stub.blocked, 0, 'nothing refused (' .. table.concat(names, ',') .. ')')
	take_errors()
end)
