-- The character frame's item level text (SaftUI-Misc/Skinning/blizzard/characterframe/
-- characterframe.lua):
--   - each equipment slot gets a text of SaftUI's own in the Skinning font, white,
--     and a black 0.8 alpha backing behind it, as a bag slot's item level has;
--   - the backing shows only while the slot has an item level;
--   - a change of the Skinning font reaches the text at once, no reload.
-- Both clients: the slot buttons and C_Item are the same on each.
--
-- Real: SaftUI-Misc's config.lua, Skinning/skinning.lua and the character frame
-- skin, Core's helpers. The slot buttons are stand-ins for Blizzard's.
load_core_helpers()
load_saftui('SaftUI-Misc/config.lua')
apply_defaults()
load_saftui('SaftUI-Misc/Skinning/skinning.lua')

local st = SaftUI
local profile = st.config.profile
local SK = st:GetModule('Skinning')
st:BindModuleConfig(SK, 'skinning')

local SLOTS = {
	'Head', 'Neck', 'Shoulder', 'Shirt', 'Chest', 'Waist', 'Legs', 'Feet', 'Wrist', 'Hands',
	'Finger0', 'Finger1', 'Trinket0', 'Trinket1', 'Back', 'MainHand', 'SecondaryHand', 'Tabard', 'Ranged',
}
INVSLOT_HEAD, INVSLOT_NECK, INVSLOT_SHOULDER, INVSLOT_BODY, INVSLOT_CHEST = 1, 2, 3, 4, 5
INVSLOT_WAIST, INVSLOT_LEGS, INVSLOT_FEET, INVSLOT_WRIST, INVSLOT_HAND = 6, 7, 8, 9, 10
INVSLOT_FINGER1, INVSLOT_FINGER2, INVSLOT_TRINKET1, INVSLOT_TRINKET2 = 11, 12, 13, 14
INVSLOT_BACK, INVSLOT_MAINHAND, INVSLOT_OFFHAND, INVSLOT_TABARD, INVSLOT_RANGED = 15, 16, 17, 19, 18

local locked = load_test_file('lib/locked_widget.lua')
local buttons = {}
for _, name in ipairs(SLOTS) do
	local button = CreateFrame('Button', 'Character' .. name .. 'Slot', UIParent)
	button:SetSize(40, 40)
	button:SetPoint('CENTER')
	locked(button, 'Blizzard equipment slot')
	buttons[name] = button
end
buttons.Chest:SetID(INVSLOT_CHEST)

local links = {}
function GetInventoryItemLink(unit, id) return links[id] end
C_Item = C_Item or {}
C_Item.GetDetailedItemLevelInfo = function(link) return link == 'item:1' and 33 or nil end
local Util = st:NewModule('Utilities')
-- The real helpers write fields onto the frame they are handed (itemupgrades.lua), so the
-- stand-ins do too: they record the frame, and write one field on it as the real ones do.
local quality_calls = {}
Util.SetItemQuality = function(_, frame, link)
	quality_calls[#quality_calls + 1] = { frame = frame, link = link }
	frame.alwaysShowProfessionsQuality = true
end
Util.ClearItemQuality = function(_, frame)
	quality_calls[#quality_calls + 1] = { frame = frame, clear = true }
	frame.professionQualityOverlayOverride = nil
end

load_saftui('SaftUI-Misc/Skinning/blizzard/characterframe/characterframe.lua')
local CF = SK:GetModule('CharacterFrame')
-- The gems have their own tests; the events and hooks need no game.
CF.CreateSlotGems = function() return CreateFrame('Frame') end
CF.UpdateSlotGems = function() end
CF.RegisterEvent = function() end
CF.SecureHook = function() end
CF:OnEnable()

-- The slot's font strings and textures that are SaftUI's: the text, then the backing.
local function parts(button)
	local text, back
	for _, region in ipairs({ button:GetRegions() }) do
		if region:GetObjectType() == 'FontString' then text = region end
		if region:GetObjectType() == 'Texture' then back = region end
	end
	return text, back
end

test("an equipment slot's item level is in the Skinning font, Text > Strong, on a dark backing", function()
	profile.colors.text.strong:SetRGB(0.4, 0.8, 0.2) -- not the default, so a hardcoded white fails
	SK:UpdateConfig()
	local text, back = parts(buttons.Head)
	check(text ~= nil and back ~= nil, 'a text and a backing were added')
	eq(text:GetFontObject(), st:GetFont(profile.skinning.font), 'the Skinning font, not Blizzard\'s')
	local r, g, b = text:GetTextColor()
	local wr, wg, wb = profile.colors.text.strong:GetRGB()
	eq(r .. ',' .. g .. ',' .. b, wr .. ',' .. wg .. ',' .. wb, 'white')
	eq(back:GetAlpha(), 0.8, 'the backing is 0.8 alpha')
	eq(table.concat({ back:GetVertexColor() }, ','), '0,0,0,1', 'and black')
	local _, textSub = text:GetDrawLayer()
	local _, backSub = back:GetDrawLayer()
	check(backSub < textSub, 'the backing draws under the text')
	local found
	for i = 1, back:GetNumPoints() do
		local point, relativeTo = back:GetPoint(i)
		if point == 'TOPLEFT' and relativeTo == text then found = true end
	end
	check(found, "the backing's top left is on the text, so it fits any number of digits")
end)

test('the backing shows only while the slot has an item level', function()
	local text, back = parts(buttons.Chest)
	check(not back:IsShown(), 'hidden on an empty slot')
	links[INVSLOT_CHEST] = 'item:1'
	CF:UpdateEquipSlot(buttons.Chest)
	eq(text:GetText(), '33', 'the level')
	check(back:IsShown(), 'shown with it')
	links[INVSLOT_CHEST] = nil
	CF:UpdateEquipSlot(buttons.Chest)
	eq(text:GetText(), '', 'cleared')
	check(not back:IsShown(), 'hidden again')
end)

test('an item with no item level leaves the text empty and the backing hidden', function()
	local text, back = parts(buttons.Chest)
	links[INVSLOT_CHEST] = 'item:2'
	CF:UpdateEquipSlot(buttons.Chest)
	eq(text:GetText(), '', 'no text')
	check(not back:IsShown(), 'no backing')
	links[INVSLOT_CHEST] = nil
end)

test('a change of the Skinning font reaches the text without a reload', function()
	local ok, err = pcall(function()
		profile.skinning.font = 'pixel_med'
		SK:UpdateConfig()
		for _, name in ipairs(SLOTS) do
			local text = parts(buttons[name])
			eq(text:GetFontObject(), st:GetFont('pixel_med'), name .. ' follows the font')
			local r, g, b = text:GetTextColor()
			local wr, wg, wb = profile.colors.text.strong:GetRGB()
			eq(r .. ',' .. g .. ',' .. b, wr .. ',' .. wg .. ',' .. wb, name .. ' stays Text > Strong')
		end
	end)
	profile.skinning.font = 'pixel'
	SK:UpdateConfig()
	if not ok then error(err, 0) end
end)

test('a Skinning font that names nothing draws Text; a typeface reaches the text through the Skinning update', function()
	local face = { font_name = 'Colus', font_size = 12, font_outline = 'OUTLINE', shadow_offset = { 0, 0 }, spacing = 4 }
	local ok, err = pcall(function()
		for _, value in ipairs({ 'gone', 17, false }) do
			profile.skinning.font = value
			SK:UpdateConfig()
			for _, name in ipairs(SLOTS) do
				eq(parts(buttons[name]):GetFontObject(), st:GetFont('normal'), name .. ': Text for ' .. tostring(value))
			end
		end
		profile.skinning.font = face
		SK:UpdateConfig()
		for _, name in ipairs(SLOTS) do
			eq(parts(buttons[name]):GetFontObject(), st:FontObject(face), name .. ': the typeface')
		end
		eq(#take_errors(), 0, 'no errors')
	end)
	profile.skinning.font = 'pixel'
	SK:UpdateConfig()
	if not ok then error(err, 0) end
end)

-- What the game can see of one of Blizzard's buttons from the outside, apart from its
-- Lua fields (the locked button refuses those): where it is, how big, whose child, shown.
local function outside(button)
	return table.concat({ button:GetWidth(), button:GetHeight(), tostring(button:GetParent()), tostring(button:IsShown()),
		button:GetNumPoints(), button:GetFrameLevel() }, '|')
end

test("Blizzard's slot buttons get no field and no script from the item update, only SaftUI's overlay does", function()
	local button = buttons.Chest
	local before = outside(button)
	links[INVSLOT_CHEST] = 'item:1'
	quality_calls = {}
	CF:UpdateEquipSlot(button) -- the locked button errors on a field written onto it
	links[INVSLOT_CHEST] = nil
	CF:UpdateEquipSlot(button)
	check(#quality_calls == 2, 'the quality helpers ran for the set and the clear')
	for _, call in ipairs(quality_calls) do
		check(call.frame ~= button, 'the helper was handed SaftUI\'s overlay, not Blizzard\'s button')
		eq(call.frame:GetParent(), button, "the overlay is the slot's child")
		check(not call.frame:IsMouseEnabled(), 'the overlay takes no mouse, so clicks and drags reach the slot')
	end
	eq(quality_calls[1].frame, quality_calls[2].frame, 'one overlay per slot')
	eq(outside(button), before, "the button's size, points, parent, shown state and level are as Blizzard left them")
	check(button:GetScript('OnClick') == nil and button:GetScript('OnEnter') == nil, 'no script of the slot was set')
end)

test('every slot has its own overlay, over the whole slot, and the helpers use it', function()
	local seen = {}
	for _, name in ipairs(SLOTS) do
		local button = buttons[name]
		quality_calls = {}
		links[button:GetID()] = nil
		CF:UpdateEquipSlot(button)
		local overlay = quality_calls[1].frame
		check(overlay ~= nil and overlay ~= button, name .. ': an overlay of SaftUI\'s')
		check(not seen[overlay], name .. ': not shared with another slot')
		seen[overlay] = true
		local point, relativeTo = overlay:GetPoint(1)
		eq(relativeTo, button, name .. ': anchored to its slot')
	end
end)
