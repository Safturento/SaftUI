-- SaftUI-Bags/slot.lua's quality border: INV:SetSlotQualityBorder takes the
-- profile's item quality colors (st:QualityColor), and INV:OnColorsChanged
-- redraws the filled slots when those colors change.
load_core_helpers()
local st = SaftUI
local INV = st:NewModule('Inventory')
st:NewModule('Utilities')
-- slot.lua post-hooks Blizzard's stack split button at load.
_G.StackSplitFrameOkay_Click = function() end
load_saftui('SaftUI-Bags/slot.lua')

-- A slot with a backdrop that records the border colors it's given.
local function make_slot(info)
	local slot = { info = info, calls = {} }
	slot.backdrop = {
		SetBackdropBorderColor = function(_, r, g, b) slot.calls[#slot.calls + 1] = { r, g, b } end,
	}
	return slot
end

local function last(slot)
	local c = slot.calls[#slot.calls]
	return c and (c[1] .. ',' .. c[2] .. ',' .. c[3])
end

test('a slot border is the profile color for its quality', function()
	_G.ITEM_QUALITY_COLORS = { [3] = { r = 0.9, g = 0.9, b = 0.9 } }
	local slot = make_slot({ quality = 3 })
	INV:SetSlotQualityBorder(slot)
	local r, g, b = st.config.profile.colors.item_quality[3]:GetRGB()
	eq(last(slot), r .. ',' .. g .. ',' .. b, "the profile's color")
end)

test('quality -1, and a quality with no color, give black', function()
	_G.ITEM_QUALITY_COLORS = {}
	for _, quality in ipairs({ -1, 20 }) do
		local slot = make_slot({ quality = quality })
		INV:SetSlotQualityBorder(slot)
		eq(last(slot), '0,0,0', 'quality ' .. quality)
	end
end)

test('a locked slot, and a slot with no quality, are left alone', function()
	local locked = make_slot({ quality = 3, locked = true })
	local bare = make_slot({})
	INV:SetSlotQualityBorder(locked)
	INV:SetSlotQualityBorder(bare)
	eq(#locked.calls, 0, 'locked')
	eq(#bare.calls, 0, 'no quality')
end)

test('OnColorsChanged item_quality redraws filled slots only', function()
	local filled = make_slot({ quality = 4 })
	local empty = make_slot({ empty = true })
	local bare = make_slot(nil)
	INV.containers = { bag = { categories = { A = { slots = { filled, empty, bare } } } } }

	INV:OnColorsChanged('class')
	eq(#filled.calls, 0, 'another group recolors nothing')

	INV:OnColorsChanged('item_quality')
	eq(#filled.calls, 1, 'the filled slot')
	eq(#empty.calls, 0, 'the empty-slot stub')
	eq(#bare.calls, 0, 'the slot with no info')
end)
