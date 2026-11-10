-- SaftUI-Bags/slot.lua's quality border: INV:SetSlotQualityBorder takes the
-- profile's item quality colors (st:QualityColor), and INV:OnColorsChanged
-- redraws the filled slots when those colors change. INV:QualityBorderColor is
-- the one rule the item slots and the currency slots share, and the currency
-- slots' borders follow a change too (currencies.lua).
load_core_helpers()
local st = SaftUI
local INV = st:NewModule('Inventory')
st:NewModule('Utilities')
-- slot.lua post-hooks Blizzard's stack split button at load.
_G.StackSplitFrameOkay_Click = function() end
load_saftui('SaftUI-Bags/slot.lua')
-- currencies.lua keys a table by this enum at load.
Enum = Enum or {}
Enum.AccountCurrencyTransferResult = Enum.AccountCurrencyTransferResult
	or { MaxQuantity = 1, NoValidSourceCharacter = 2, CannotUseCurrency = 3 }
load_saftui('SaftUI-Bags/currencies.lua')

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

test('QualityBorderColor: the profile color, black for -1 and for a quality with no color', function()
	_G.ITEM_QUALITY_COLORS = {}
	local r, g, b = st.config.profile.colors.item_quality[4]:GetRGB()
	local gr, gg, gb = INV:QualityBorderColor(4)
	eq(gr .. ',' .. gg .. ',' .. gb, r .. ',' .. g .. ',' .. b, 'epic is the profile epic')
	eq(table.concat({ INV:QualityBorderColor(-1) }, ','), '0,0,0', 'quality -1')
	eq(table.concat({ INV:QualityBorderColor(20) }, ','), '0,0,0', 'no color')
end)

-- A Currencies category whose active slots are the given ones, each with the
-- currency id its border reads the quality of.
local function currency_world(qualities)
	local slots = {}
	for id, quality in pairs(qualities) do
		local slot = make_slot({})
		slot.elementData = { id = id }
		slots[#slots + 1] = slot
	end
	_G.C_CurrencyInfo = { GetBasicCurrencyInfo = function(id) return { quality = qualities[id] } end }
	local pool = {}
	function pool:EnumerateActive()
		local i = 0
		return function() i = i + 1; return slots[i] end
	end
	INV.containers = { bag = { categories = { Currencies = { slotPool = pool, slots = {} } } } }
	return slots
end

test("a currency's border is its quality's color, and follows a quality color change", function()
	_G.ITEM_QUALITY_COLORS = {}
	local slots = currency_world({ [1] = 4 })
	INV:SetCurrencyBorder(slots[1])
	local r, g, b = st.config.profile.colors.item_quality[4]:GetRGB()
	eq(last(slots[1]), r .. ',' .. g .. ',' .. b, 'the profile epic')

	st.config.profile.colors.item_quality[4] = CreateColor(0.3, 0.6, 0.9)
	INV:OnColorsChanged('class')
	eq(#slots[1].calls, 1, 'another group redraws nothing')
	INV:OnColorsChanged('item_quality')
	eq(#slots[1].calls, 2, 'a quality change redraws the currency')
	eq(last(slots[1]), '0.3,0.6,0.9', 'in the new color')
end)

test('a currency with quality -1 gets a black border', function()
	local slots = currency_world({ [7] = -1 })
	INV:SetCurrencyBorder(slots[1])
	eq(last(slots[1]), '0,0,0', 'black')
end)
