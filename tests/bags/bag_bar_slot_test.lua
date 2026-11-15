-- The bags bar's Blizzard bag slots (SaftUI-Bags/containers/bag.lua,
-- INV:InitializePlayerBagSlots), which are Blizzard's secure buttons:
--   - no field is written onto a slot: each is locked
--     (lib/locked_widget.lua), so .backdrop, .thick, .hover, .pushed, .disabled
--     or any other new key fails; SaftUI keeps its pieces in weak tables;
--   - a slot is still drawn: a backdrop of SaftUI's behind it (a child frame
--     of it) in the Buttons profile's Theme and Background, the hover and
--     pushed textures made on it and handed to SetHighlightTexture and
--     SetPushedTexture, the hover in the HIGHLIGHT layer, and the icon cropped
--     inside it;
--   - Blizzard's UpdateTextures, running again, gives the same look back.
-- Real: container_helpers.lua's world and containers/bag.lua. The slots are
-- stand-ins for BagSlotButtonTemplate (an ItemButton), locked.
local H = load_test_file('bags/container_helpers.lua')
local lock = load_test_file('lib/locked_widget.lua')
local INV = H.views_world('forever')
local st = SaftUI
load_saftui('SaftUI-Bags/containers/bag.lua')

-- Blizzard's bag slot: the regions BagSlotButtonTemplate names, with their
-- global names, and its UpdateTextures, which gives the normal texture an atlas
-- and the state textures Blizzard's art. Locked once built.
local function make_slot(name)
	local slot = CreateFrame('Button', name, UIParent)
	slot:SetSize(37, 37)
	slot.icon = slot:CreateTexture(name .. 'IconTexture', 'BORDER')
	_G[name .. 'IconTexture'] = slot.icon
	slot.IconBorder = slot:CreateTexture(nil, 'OVERLAY')
	slot.SlotHighlightTexture = slot:CreateTexture(nil, 'OVERLAY')
	slot.Count = slot:CreateFontString(nil, 'OVERLAY')
	slot:SetNormalTexture(st.BLANK_TEX)
	slot.UpdateTextures = function(self)
		self:GetNormalTexture():SetAlpha(1)
		self:GetHighlightTexture():SetTexture('Interface\\Blizzard')
		self:GetHighlightTexture():SetVertexColor(1, 1, 1)
	end
	return slot
end

local SLOTS = { 'CharacterBag0Slot', 'CharacterBag1Slot', 'CharacterBag2Slot', 'CharacterBag3Slot', 'CharacterReagentBag0Slot' }

-- A fresh bag window and slots, locked, then the bar made as the module makes it.
local function world()
	local container = H.window('bag')
	local slots, before = {}, {}
	for _, name in ipairs(SLOTS) do
		local slot = make_slot(name)
		-- Blizzard's parentKey icon, served through the lock's __index (not a raw
		-- key), so a skin that writes slot.icon again, even the same texture,
		-- reaches __newindex and fails like a new field.
		local icon = rawget(slot, 'icon')
		rawset(slot, 'icon', nil)
		lock(slot, 'Blizzard')
		local mt = getmetatable(slot)
		local methods = mt.__index
		mt.__index = function(_, key)
			if key == 'icon' then return icon end
			return methods[key]
		end
		slots[#slots + 1] = slot
		local keys = {}
		for key in pairs(slot) do keys[key] = true end
		before[slot] = keys
	end
	MainMenuBarBackpackButton = CreateFrame('Button', nil, UIParent)
	BagBarExpandToggle = CreateFrame('Button', nil, UIParent)
	INV:InitializePlayerBagSlots()
	return container, slots, before
end

local function backdrop_of(slot)
	for _, child in ipairs({ slot:GetChildren() }) do
		if child.SetBackdrop then return child end
	end
end

test('no field is written onto a Blizzard bag slot', function()
	local _, slots, before = world()
	for _, slot in ipairs(slots) do
		for key in pairs(slot) do
			check(before[slot][key], 'field written onto ' .. slot:GetName() .. ': ' .. tostring(key))
		end
	end
end)

test('a bag slot is still drawn: a backdrop of its own behind it, hover and pushed textures set on it', function()
	local _, slots = world()
	for _, slot in ipairs(slots) do
		check(backdrop_of(slot), slot:GetName() .. ' has a backdrop of SaftUI\'s')
		local hover, pushed = slot:GetHighlightTexture(), slot:GetPushedTexture()
		check(hover and pushed, 'the hover and pushed textures are set')
		eq(hover:GetDrawLayer(), 'HIGHLIGHT', 'the hover stays in the layer the client shows only under the mouse')
		eq(slot:GetNormalTexture():GetAlpha(), 0, 'the normal texture is faded')
	end
end)

test("Blizzard's UpdateTextures running again gives the same look back", function()
	local _, slots = world()
	local slot = slots[1]
	slot:UpdateTextures()
	local r, g, b = slot:GetHighlightTexture():GetVertexColor()
	local ar, ag, ab = st:Color('accent'):GetRGB()
	check(math.abs(r - ar) < 0.01 and math.abs(g - ag) < 0.01 and math.abs(b - ab) < 0.01, 'the hover is the accent again')
	eq(slot:GetNormalTexture():GetAlpha(), 0, 'the normal texture is faded again')
end)

test('under Thin, Blizzard and None the slots are still skinned with no field written', function()
	for _, theme in ipairs({ 'thin', 'blizzard', 'none' }) do
		st.config.profile.buttons.theme = theme
		local _, slots = world()
		for _, slot in ipairs(slots) do
			eq((backdrop_of(slot) ~= nil), theme ~= 'none', theme .. ': a backdrop behind the slot unless None')
			check(slot:GetHighlightTexture(), theme .. ': hover texture set')
		end
	end
	st.config.profile.buttons.theme = 'theme'
end)

test("a slot's count text follows Button text, at once", function()
	st.config.profile.buttons.theme = 'theme'
	st.config.profile.buttons.font = 'pixel'
	local _, slots = world()
	local count = slots[1].Count
	check(count:GetFontObject() == st:GetFont('pixel'), 'it starts in Button text')
	st.config.profile.buttons.font = 'pixel_med'
	st:RefollowFonts()
	check(count:GetFontObject() == st:GetFont('pixel_med'), 'Button text reaches it')
end)
