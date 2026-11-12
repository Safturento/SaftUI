local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	Whole-pixel nameplates. The game moves each plate every frame, to wherever
	its unit stands on screen, and that's seldom on a whole pixel. Each texture
	snaps to the pixel grid on its own, so a 1px border can come out as no
	pixel, one or two, and shimmer as the plate moves. Two things keep the
	borders whole:

	  * Each plate's frame is pinned to UIParent's scale (UF:PinPlateScale): it
	    ignores its plate's scale and takes UIParent's, on which SaftUI makes
	    one unit a pixel (Core's init.lua). The plate's own scale, which the
	    game sets by distance and for the target, is kept at 1 by the game's
	    scale settings SaftUI sets (cvars.lua), since the frame still covers
	    its plate.
	  * Every frame and region of SaftUI's on a plate rounds its layout to the
	    nearest pixel (the game's SetRoundLayoutToNearestPixel), as Blizzard's
	    own plates do, so the plate moves by whole pixels and its parts keep
	    their places on it. Textures don't snap on their own as well (snapping
	    off, texel snapping bias 0), as ElvUI's and Inomena's plates do: the
	    rounding has placed them.

	The rounding is SaftUI's own walk (UF.RoundLayout), never PixelUtil's
	recursive helper, and never on Blizzard's frames: the plate (NamePlateN),
	its UnitFrame and widgets are left alone. The walk stops at Blizzard's aura
	containers (.agents/taint.md, rule 11) and at forbidden frames, so each aura
	button's backdrop, SaftUI's frame on the container's button, is rounded
	where it's drawn (elements/auras.lua).

	The borders themselves stay the theme engine's (the backdrop's edges, Thick's
	lines, Blizzard's art), rounded with everything else.
]]

-- Whether the walk leaves region, and everything under it, alone: a forbidden
-- object, which addon code can only ask whether it is, or Blizzard's aura
-- container, whose buttons refuse an addon's access while auras are secret.
local function Skipped(region)
	return region:IsForbidden() or region:IsObjectType('AuraContainer')
end

local function RoundEach(...)
	for i = 1, select('#', ...) do
		UF.RoundLayout((select(i, ...)), true)
	end
end

-- Rounds region's layout to whole pixels, and for a texture turns its own
-- snapping off (with the texel snapping bias at 0). With recursive, every
-- region and child frame under it too, but nothing under a forbidden frame or
-- an aura container (Skipped). It only turns the rounding on: no size or
-- position is read or set. Not protected on SaftUI's plate frames, which
-- aren't secure, so it works in combat too.
function UF.RoundLayout(region, recursive)
	if Skipped(region) then return end
	region:SetRoundLayoutToNearestPixel(true)
	if region:IsObjectType('Texture') then
		region:SetSnapToPixelGrid(false)
		region:SetTexelSnappingBias(0)
	elseif recursive and region:IsObjectType('Frame') then
		RoundEach(region:GetRegions())
		RoundEach(region:GetChildren())
	end
end

-- Pins a plate's frame to UIParent's effective scale: the frame ignores its
-- plate's scale and takes UIParent's as its own. A secret scale leaves the
-- frame as it is. A plate's frame isn't secure, so this works in combat too.
function UF:PinPlateScale(frame)
	local scale = UIParent:GetEffectiveScale()
	if issecretvalue(scale) then return end
	frame:SetIgnoreParentScale(true)
	frame:SetScale(scale)
end

-- Pinned on every add, so a plate reused after a scale change is pinned anew.
UF:RegisterPlateCallback('added', function(frame) UF:PinPlateScale(frame) end)

-- Rounded after every update of a plate (its first included), which can draw
-- new art (a theme switch). pixels.lua is the last file nameplates.xml lists,
-- so this runs after the other 'updated' callbacks and rounds what they made
-- too (the target's art, target.lua).
UF:RegisterPlateCallback('updated', function(frame) UF.RoundLayout(frame, true) end)

-- The UI's scale changed (Blizzard's UI scale setting) or the display did:
-- every plate's frame is pinned to UIParent's scale again, at once, and the
-- plates' size, which is in UIParent's pixels (UF.PlateDriverSize), is set
-- again, which waits for the end of combat. Nothing before the driver is made.
local events = CreateFrame('Frame')
events:RegisterEvent('UI_SCALE_CHANGED')
events:RegisterEvent('DISPLAY_SIZE_CHANGED')
events:SetScript('OnEvent', function()
	UF:ForEachPlate(function(frame) UF:PinPlateScale(frame) end)
	UF:ApplyPlateSize()
end)
