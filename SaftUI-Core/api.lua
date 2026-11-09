local st = SaftUI

function st:GetConfig(configUnit)
	return st.config.profile[configUnit]
end

function st:UnpackPoint(config)
	return config.point, config.frame, config.rel_point or config.point, config.x_off or 0, config.y_off or 0
end

-- Size of one physical pixel in frame's (or UIParent's) coordinate space, or nil if unknown.
function st:GetPixelSize(frame)
	local physicalHeight = select(2, GetPhysicalScreenSize())
	local scale = (frame or UIParent):GetEffectiveScale()
	if not physicalHeight or physicalHeight == 0 or not scale or scale == 0 then
		return nil
	end
	return (768 / physicalHeight) / scale
end

-- Rounds a value (in frame's coordinate space) to the nearest physical pixel.
function st:RoundToPixel(value, frame)
	local pixel = st:GetPixelSize(frame)
	if not pixel then
		return value
	end
	local pixels = math.floor(math.abs(value) / pixel + 0.5)
	if pixels == 0 then return 0 end -- avoid -0

	-- Pixel sizes like 0.99999995 leave float noise (25px -> 24.999998); trim it
	-- so stored offsets stay clean. 1e-4 is far below a pixel at any UI scale.
	local result = math.floor(pixels * pixel * 10000 + 0.5) / 10000
	return value < 0 and -result or result
end

-- Resolves a global frame name or frame object to a frame, or nil.
function st:ResolveFrame(ref)
	if type(ref) == 'string' then
		return _G[ref]
	elseif type(ref) == 'table' and ref.GetObjectType then
		return ref
	end
	return nil
end

local function AnchorReaches(from, target, visited)
	if from == target then
		return true
	end
	if visited[from] then
		return false
	end
	visited[from] = true
	if not from.GetNumPoints then
		return false
	end
	for i = 1, from:GetNumPoints() do
		local _, relativeTo = from:GetPoint(i)
		if relativeTo and not issecretvalue(relativeTo) and type(relativeTo) == 'table'
				and AnchorReaches(relativeTo, target, visited) then
			return true
		end
	end
	return false
end

-- True if frame moves when target moves: it is target, one of its anchors
-- reaches target (directly or through other frames), or target is one of its
-- parents. Anchoring target to frame would therefore make a loop, and edit
-- mode skips such frames as snap targets because they ride along with a drag.
function st:MovesWith(frame, target)
	if AnchorReaches(frame, target, {}) then
		return true
	end
	local parent = frame.GetParent and frame:GetParent()
	while parent do
		if parent == target then
			return true
		end
		parent = parent.GetParent and parent:GetParent()
	end
	return false
end

-- Returns true if anchoring frame to relative is valid, else false and an error message.
function st:ValidateAnchor(frame, relative)
	local relativeFrame = st:ResolveFrame(relative)
	if not relativeFrame then
		return false, "Frame doesn't exist"
	end
	if relativeFrame == frame then
		return false, "Can't anchor a frame to itself"
	end
	if st:MovesWith(relativeFrame, frame) then
		return false, "Anchor would create a loop"
	end
	return true
end

-- st:SetBackdrop for a frame that isn't SaftUI's (a Blizzard tooltip, a dropdown
-- list): the backdrop frame is kept in `backdrops`, the caller's weak table keyed
-- by the frame, and nothing is written onto the frame (.agents/taint.md, rule 1;
-- st:SetBackdrop would set .backdrop and .thick). Returns the backdrop frame, or
-- nil when the template is none. Frames only, not textures.
function st:SetBackdropIn(backdrops, frame, template)
	local backdrop = backdrops[frame]
	if template == nil or template == 'none' or template == '' then
		if backdrop then st:SetTemplate(backdrop, 'none') end
		return
	end

	local config = st.config.profile.templates[template]
	assert(config, template .. ' template not found')

	if not backdrop then
		backdrop = st:CreateFrame('frame', nil, frame)
		backdrop:SetFrameLevel(max(0, frame:GetFrameLevel() - 1))
		backdrops[frame] = backdrop
	end

	local offset = config.thick and 2 or 1
	backdrop:ClearAllPoints()
	backdrop:SetPoint('TOPLEFT', frame, 'TOPLEFT', -offset, offset)
	backdrop:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', offset, -offset)
	backdrop.template = template

	st:SetTemplate(backdrop, template)
	return backdrop
end

function st:SetHeight(frame, height)
	frame:SetHeight(height)
end

function st:SetWidth(frame, width)
	frame:SetWidth(width)
end

function st:SetSize(frame, width, height)
	frame:SetSize(width, height or width)
end

function st:CalculateSpacing(frame, anchorFrame, spacing)
	return (spacing or 0) + (frame.thick and 2 or frame.thick == false and 1 or 0) + (anchorFrame and anchorFrame.thick and 2 or 0)
end

function st:SetInside(frame, inset)
	inset = inset or 0

	frame:SetPoint('TOPLEFT', inset, -inset)
	frame:SetPoint('BOTTOMRIGHT', -inset, inset)
end

function st:InsetTexture(texture, inset)
	inset = inset or 0
	texture:SetTexCoord(inset, 1-inset, inset, 1-inset)
end

function st:SnapTop(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOP', anchorFrame, 'TOP', 0, -yOffset)
end


function st:SnapTopLeft(frame, anchorFrame, xOffset, yOffset)
	xOffset = st:CalculateSpacing(frame, anchorFrame, xOffset)
	if yOffset then
		yOffset = st:CalculateSpacing(frame, anchorFrame,yOffset)
	end
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPLEFT', xOffset, -(yOffset or xOffset))
end

function st:SnapBottomLeft(frame, anchorFrame, xOffset, yOffset)
	xOffset = st:CalculateSpacing(frame, anchorFrame, xOffset)
	if yOffset then
		yOffset = st:CalculateSpacing(frame, anchorFrame,yOffset)
	end
	frame:ClearAllPoints()
	frame:SetPoint('BOTTOMLEFT', anchorFrame, 'BOTTOMLEFT', xOffset, -(yOffset or xOffset))
end

function st:SnapTopRight(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'TOPRIGHT', 0, -yOffset)
end

function st:SnapTopAcross(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPLEFT', 0, -yOffset)
	frame:SetPoint('TOPRIGHT', anchorFrame, 'TOPRIGHT', 0, -yOffset)
end

function st:SnapBelow(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOP', anchorFrame, 'BOTTOM', 0, -yOffset)
end

function st:SnapBelowLeft(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'BOTTOMLEFT', 0, -yOffset)
end

function st:SnapBelowRight(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'BOTTOMRIGHT', 0, -yOffset)
end

function st:SnapBelowAcross(frame, anchorFrame, spacing)
	local yOffset = st:CalculateSpacing(frame, anchorFrame, spacing)

	frame:ClearAllPoints()
	frame:SetPoint('TOPRIGHT', anchorFrame, 'BOTTOMRIGHT', 0, -yOffset)
	frame:SetPoint('TOPLEFT', anchorFrame, 'BOTTOMLEFT', 0, -yOffset)
end

function st:SnapTopRightOf(frame, anchorFrame, spacing)
	local xOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', anchorFrame, 'TOPRIGHT', xOffset, 0)
end

function st:SnapBottomRightOf(frame, anchorFrame, spacing)
	local xOffset = st:CalculateSpacing(frame, anchorFrame, spacing)
	frame:ClearAllPoints()
	frame:SetPoint('BOTTOMLEFT', anchorFrame, 'BOTTOMRIGHT', xOffset, 0)
end

local title = "|cff00adefSaftUI|r"

function st:Print(...)
	print(('[%s]: '):format(title), ...)
end

function st:Error(...)
	print(('[%s |cFFFF0000Error|r]: '):format(title), ...)
end

function st:Debug(module, ...)
	if not self.DEBUG then return end

	debug = st.StringFormat:ColorString(
			'DEBUG', st.config.profile.colors.text.red:GetRGB())
	st:Print(('<%s:%s>'):format(debug, module), ...)
end

function st:Kill(frame)
	if not frame then return end
	if frame.UnregisterAllEvents then
		frame:UnregisterAllEvents()
		frame:SetParent(st.HiddenFrame)
	end
	st:StripTextures(frame)

	if frame.SetAlpha then frame:SetAlpha(0) end

	frame._Show = frame.Show
	frame.Show = frame.Hide

	frame._SetAtlas = frame.SetAtlas
	frame.SetAtlas = frame.Hide

	frame:Hide()
end

function st:Hide(frame, reparent)
   frame:ClearAllPoints()
   frame:SetPoint('BOTTOM', HiddenFrame)

   if reparent then frame:SetParent(st.HiddenFrame) end
end

-- Work that touches protected (secure) frames can't run in combat. In combat,
-- st:QueueAfterCombat queues fn under key and returns true; fn then runs once
-- on PLAYER_REGEN_ENABLED. Queuing the same key again replaces the earlier fn,
-- so repeated profile changes in one fight refresh once. Out of combat it
-- queues nothing and returns false, and the caller goes ahead now.
local combatQueue = {}
local combatQueueFrame = CreateFrame('Frame')
combatQueueFrame:SetScript('OnEvent', function(self)
	self:UnregisterEvent('PLAYER_REGEN_ENABLED')
	local queued = combatQueue
	combatQueue = {}
	for _, fn in pairs(queued) do
		xpcall(fn, geterrorhandler())
	end
end)

function st:QueueAfterCombat(key, fn)
	if not InCombatLockdown() then return false end
	combatQueue[key] = fn
	combatQueueFrame:RegisterEvent('PLAYER_REGEN_ENABLED')
	return true
end

-- The widget API's own ClearAllPoints and SetPoint, called directly so any Lua
-- replacement on the frame itself is skipped. Blizzard's Edit Mode systems (e.g.
-- ChatFrame1) get Lua overrides of both (EditModeSystemMixin:OnSystemLoad) that
-- write Edit Mode state, and calling those from addon code taints it.
function st:ClearAllPointsDirect(frame)
	getmetatable(frame).__index.ClearAllPoints(frame)
end

function st:SetPointDirect(frame, ...)
	getmetatable(frame).__index.SetPoint(frame, ...)
end

-- The widget API's own SetSize, called the same way. Edit Mode systems keep the
-- plain SetSize today (OnSystemLoad doesn't replace it), but a frame placed with
-- the helpers above is sized without going through its fields either, so
-- neither a later Lua override nor a hook on the frame's SetSize runs.
function st:SetSizeDirect(frame, width, height)
	getmetatable(frame).__index.SetSize(frame, width, height)
end

-- Every anchor of frame, for st:RestorePoints. The values are only kept and
-- handed back to SetPoint, never compared, so secret values are fine.
function st:GetPoints(frame)
	local points = {}
	for i = 1, frame:GetNumPoints() do
		points[i] = { frame:GetPoint(i) }
	end
	return points
end

-- Gives a frame left with no anchors (e.g. by a placement that failed after
-- its anchors were cleared) somewhere to be again: the points st:GetPoints
-- saved, or the middle of the screen if there are none or they fail (e.g. the
-- frame they name is now anchored to this one). A frame with anchors is left alone.
function st:RestorePoints(frame, points)
	if frame:GetNumPoints() > 0 then return end
	local restored = points and #points > 0 and pcall(function()
		for _, p in ipairs(points) do
			st:SetPointDirect(frame, p[1], p[2], p[3], p[4], p[5])
		end
	end)
	if not restored then
		st:ClearAllPointsDirect(frame)
		st:SetPointDirect(frame, 'CENTER', UIParent, 'CENTER')
	end
end

-- Moving a protected frame (ClearAllPoints, SetPoint, SetSize and the like) is
-- blocked in combat. A frame that isn't protected by itself counts as protected
-- while a protected frame is anchored to it, directly or through a chain of
-- anchors. Users can set that up, e.g. by anchoring a unit frame to the minimap
-- or a swing timer. True if frame can be moved right now.
function st:CanMoveNow(frame)
	return not (InCombatLockdown() and frame:IsProtected())
end

-- Repositions waiting for the end of combat: key -> { frame = frame, fn = fn }.
local pendingMoves = {}

-- Runs every waiting reposition together. All their frames' anchors are
-- cleared before any fn runs, so the frames can be placed in any order without
-- passing through an anchor loop (a new profile may chain them the other way
-- round). A frame still without anchors afterwards (its fn failed, or only
-- arranged what hangs off it) gets its old ones back.
local function FlushPendingMoves()
	-- PLAYER_REGEN_ENABLED can fire while combat is still on; wait again then.
	if st:QueueAfterCombat('SafeReposition', FlushPendingMoves) then return end

	local moves = pendingMoves
	pendingMoves = {}

	local saved = {}
	for _, move in pairs(moves) do
		local frame = move.frame
		if not saved[frame] then
			saved[frame] = st:GetPoints(frame)
			st:ClearAllPointsDirect(frame)
		end
	end
	for _, move in pairs(moves) do
		xpcall(move.fn, geterrorhandler())
	end
	for frame, points in pairs(saved) do
		st:RestorePoints(frame, points)
	end
end

-- Runs fn, which sizes or places frame, now if frame can be moved now
-- (st:CanMoveNow). Otherwise frame is left exactly as it is, anchors included,
-- and fn waits for the end of combat under key (one key per frame or module;
-- queuing a key again replaces its fn). fn should read the profile when it
-- runs, so a deferred one places the frame for the profile active by then.
-- Returns true if fn ran now.
function st:SafeReposition(frame, key, fn)
	if st:CanMoveNow(frame) then
		fn()
		return true
	end
	pendingMoves[key] = { frame = frame, fn = fn }
	st:QueueAfterCombat('SafeReposition', FlushPendingMoves)
	return false
end

function st:EnableMoving(frame)
	frame:EnableMouse(true)
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	frame:HookScript('OnMouseDown', function(self) self:StartMoving() end)
	frame:HookScript('OnMouseUp', function(self)
		self:StopMovingOrSizing()
		local point, relativeTo, relativePoint, offsetX, offsetY = self:GetPoint()
		self:ClearAllPoints()
		self:SetPoint(point, relativeTo, relativePoint, math.floor(offsetX), math.floor(offsetY))
	end)
end