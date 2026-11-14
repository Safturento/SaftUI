-- st:RegisterAnchorSource (SaftUI-Core/api.lua): a module can say what a frame
-- of its own is anchored to, where the live walk of st:ValidateAnchor and
-- st:MovesWith can't ask the frame (a nameplate's parts: the game refuses to
-- measure them). Every other frame keeps the live walk.
load_core_helpers()
local st = SaftUI

test('an anchor source answers for the frames it knows, and the live walk stays for the rest', function()
	local a, b, c = CreateFrame('Frame'), CreateFrame('Frame'), CreateFrame('Frame')
	b:SetPoint('TOP', a, 'BOTTOM')
	local ok, why = st:ValidateAnchor(a, b)
	eq(ok, false, 'live anchors, no source: a loop')
	eq(why, 'Anchor would create a loop', 'and its message')
	ok = st:ValidateAnchor(a, c)
	eq(ok, true, 'c is on nothing yet')

	-- A source for c only: c "is on" a, though no point says so.
	st:RegisterAnchorSource(function(frame)
		if frame == c then return { a } end
	end)
	ok, why = st:ValidateAnchor(a, c)
	eq(ok, false, "the source's anchors count")
	eq(why, 'Anchor would create a loop', 'with the usual message')
	eq(st:MovesWith(c, a), true, 'MovesWith asks it too')
	eq(st:ValidateAnchor(c, a), true, 'a is not on c')
	ok = st:ValidateAnchor(a, b)
	eq(ok, false, 'other frames still walk live')
end)

test('an anchor source answering with an empty list ends the walk, and a nil falls back to the live points', function()
	local a, b, c = CreateFrame('Frame'), CreateFrame('Frame'), CreateFrame('Frame')
	b:SetPoint('TOP', a, 'BOTTOM')
	c:SetPoint('TOP', b, 'BOTTOM')
	st:RegisterAnchorSource(function(frame)
		if frame == b then return {} end
	end)
	eq(st:ValidateAnchor(a, c), true, "b's source says it is on nothing: c doesn't reach a")
	eq(st:ValidateAnchor(b, c), false, 'c is on b by its live points: anchoring b to c would loop')
end)
