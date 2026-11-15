local st = SaftUI
local SK = st:GetModule('Skinning')

local HK = SK:NewModule('Hekili')

-- Hekili's buttons aren't SaftUI's: nothing is written onto them (.agents/taint.md).
-- The backdrop of SaftUI's behind each one is kept here (st:SetBackdropIn), and the
-- buttons skinned, in order for UpdateConfig, in skinnedButtons.
local backdrops = setmetatable({}, { __mode = 'k' })
local skinned = setmetatable({}, { __mode = 'k' })
local skinnedButtons = {}

-- Draws the button's backdrop in the profile's Theme and Background. Under None
-- there is none, so there is nothing to place. A backdrop first made here (by
-- UpdateConfig, once the theme is no longer None) gets its strata like one made
-- with the skin.
local function Draw(button)
	local backdrop = st:SetBackdropIn(backdrops, button, SK.config.theme, SK.config.background, 'action')
	-- Make sure the backdrop always stay below the icons..
	if backdrop then backdrop:SetFrameStrata('LOW') end
end

function HK:SkinIcon(_, dispID, id)
	local button = Hekili.DisplayPool[dispID] and Hekili.DisplayPool[dispID].Buttons[ id ]
	if not button then return end

	if not skinned[button] then
		-- Hekili's button: the Blizzard theme makes none of its art on it.
		st:MarkForeign(button)
		-- Recorded first: under None there is no backdrop yet, and UpdateConfig draws
		-- it once the theme changes.
		skinned[button] = true
		tinsert(skinnedButtons, button)
		Draw(button)
	end

	st:SkinIcon(button.Icon, nil, button)
end

-- A profile change: re-applies the profile's skinning Theme and Background.
function HK:UpdateConfig()
	for _, button in ipairs(skinnedButtons) do
		Draw(button)
	end
end

function HK:OnEnable()
	if not Hekili then return end
	self:SecureHook(Hekili, 'CreateButton', 'SkinIcon')
end
