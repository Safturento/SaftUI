local st = SaftUI
local SK = st:GetModule('Skinning')

local WA = SK:NewModule('WeakAuras')

-- WeakAuras' regions aren't SaftUI's: nothing is written onto them
-- (.agents/taint.md). The backdrop of SaftUI's behind each one is kept here
-- (st:SetBackdropIn), and the regions skinned, in order for UpdateConfig, in
-- skinnedRegions.
local backdrops = setmetatable({}, { __mode = 'k' })
local skinned = setmetatable({}, { __mode = 'k' })
local skinnedRegions = {}

-- Draws the region's backdrop in the profile's Theme and Background. Under None
-- there is none, so there is nothing to place. A backdrop first made here (by
-- UpdateConfig, once the theme is no longer None) gets its level and strata like
-- one made with the skin.
local function Draw(region)
	local backdrop = st:SetBackdropIn(backdrops, region, SK.config.theme, SK.config.background, 'aura')
	if backdrop then
		backdrop:SetFrameLevel(max(0, region:GetFrameLevel() - 4))
		-- Make sure the backdrop always stay below the icons..
		backdrop:SetFrameStrata('LOW')
	end
end

function WA:SkinIcon(parent, region, data)
	if not skinned[region] then
		-- WeakAuras' region isn't SaftUI's: the Blizzard theme's art goes on a
		-- frame of SaftUI's, not on it.
		st:MarkForeign(region)
		-- Recorded first: under None there is no backdrop yet, and UpdateConfig draws
		-- it once the theme changes.
		skinned[region] = true
		tinsert(skinnedRegions, region)
		Draw(region)
	end

	local icon = region.icon
	st:SkinIcon(icon, nil, region)
end

-- A profile change: re-applies the profile's skinning Theme and Background.
function WA:UpdateConfig()
	for _, region in ipairs(skinnedRegions) do
		Draw(region)
	end
end

function WA:OnEnable()
	if not WeakAurasPrivate then return end
	self:SecureHook(WeakAurasPrivate.regionTypes.icon, 'modify', 'SkinIcon')
end
