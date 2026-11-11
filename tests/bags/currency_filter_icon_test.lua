-- SaftUI-Bags/currencies.lua: the Currencies category's Filter button shows
-- SaftUI's funnel icon (st.textures.filter, SaftUI-Core/Media/Textures/funnel.tga)
-- instead of the word, keeps toggling the currency filter, and names itself in
-- a tooltip.
load_core_helpers()
local st = SaftUI
-- st:CreateCheckButton's contract (SaftUI-Core/Widgets/checkbutton.lua): a check
-- button with a .text label and SetFont/SetText, in the style asked for (nil
-- a check box, 'button' Blizzard's panel button under the Blizzard theme,
-- 'bare' no box), which is noted here. The widget's own skinning isn't what's
-- under test (tests/core/theme_blizzard_controls_test.lua tests it).
local styles = {}
function st:CreateCheckButton(name, parent, style)
	local button = CreateFrame('CheckButton', name, parent)
	button.text = button:CreateFontString(nil, 'OVERLAY')
	button.text:SetFontObject(GameFontNormal)
	button.SetFont = function() end
	button.SetText = function(_, value) button.text:SetText(value) end
	styles[button] = style or 'check box'
	return button
end
local INV = st:NewModule('Inventory')
st:NewModule('Utilities')
_G.StackSplitFrameOkay_Click = function() end
load_saftui('SaftUI-Bags/slot.lua')
Enum = Enum or {}
Enum.AccountCurrencyTransferResult = Enum.AccountCurrencyTransferResult
	or { MaxQuantity = 1, NoValidSourceCharacter = 2, CannotUseCurrency = 3 }
load_saftui('SaftUI-Bags/currencies.lua')

-- The world InitializeCurrencyCategory needs: the currency API, a bag window and
-- a Currencies category with a 50-high header.
_G.C_CurrencyInfo = { RequestCurrencyDataForAccountCharacters = function() end }
_G.CurrencyTransferMenu = CreateFrame('Frame')
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end
INV.config = { filters = {} }
function INV:GetButtonWidth() return 60 end
function INV:GetButtonHeight() return 50 end
local updated = 0
function INV:UpdateContainer() updated = updated + 1 end
local container = CreateFrame('Frame', nil, UIParent)
local category
function INV:CreateCategory()
	category = CreateFrame('Frame', nil, container)
	category.container = container
	category.header = CreateFrame('Button', nil, category)
	category.header:SetHeight(50)
	local pool = {}
	function pool:EnumerateActive() return function() end end
	category.slotPool = pool
	return category
end
INV:InitializeCurrencyCategory()
local button = category.filterButton

-- The icon texture on the button: the one showing SaftUI's funnel.
local function icon()
	for _, region in ipairs({ button:GetRegions() }) do
		if region.GetTexture and region:GetTexture() == st.textures.filter then return region end
	end
end

test('the Filter button shows the funnel icon, not the word', function()
	check(st.textures.filter ~= nil, 'st.textures.filter is defined')
	check(icon() ~= nil, 'a texture with the funnel')
	eq(button.text:GetText() or '', '', 'no "Filter" text')
end)

test("the Filter button is a check button styled as a button", function()
	eq(styles[button], 'button', "st:CreateCheckButton's style 'button': Blizzard's panel button under the Blizzard theme")
end)

test('the Filter button is a square the header can hold', function()
	eq(button:GetWidth(), 20, 'width')
	eq(button:GetHeight(), 20, 'height')
	INV.containers = { bag = { categories = { Currencies = category } } }
	INV:StyleCurrencySlots()
	eq(button:GetWidth(), 20, 'still square after a restyle')
end)

test('the icon is tinted the text color', function()
	local r, g, b = icon():GetVertexColor()
	local tr, tg, tb = st.config.profile.colors.text.normal:GetRGB()
	check(r == tr and g == tg and b == tb, 'the profile text color')
end)

test('a click still toggles the filter and updates the bag', function()
	local before = updated
	button:SetChecked(true) -- a click checks the button before its OnClick runs
	stub.fire_script(button, 'OnClick')
	eq(updated, before + 1, 'the bag updated')
	check(button:GetChecked(), 'still checked')
end)

test('hovering names it', function()
	stub.fire_script(button, 'OnEnter')
	check(GameTooltip:IsShown(), 'a tooltip')
	eq(GameTooltip:NumLines(), 2, 'its name and what it does')
	stub.fire_script(button, 'OnLeave')
end)
