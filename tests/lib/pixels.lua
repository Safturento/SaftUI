-- Whole pixels, for tests of what SaftUI draws. SaftUI's scale makes a unit
-- of UIParent a pixel, and a 1px border or line whose edge sits between two
-- pixels blurs (or the game snaps it away, or doubles it), so a frame and
-- every part of it must start and end on whole units. Loaded with
-- local P = load_test_file('lib/pixels.lua') (no globals).
--
-- P.off(root) -> a list of '<where>: <edge> <value>', one for each edge of a
-- shown frame or texture under root (root too) that isn't on a whole pixel
-- of the screen (UIParent's units; within a hair, below), in the order
-- they're walked; empty when
-- every edge is. Font strings are left out: the game draws text on whole
-- pixels itself. So are a slider's own textures (the slider is checked):
-- its knob and fill follow its value, and Blizzard's art is drawn as
-- Blizzard's own slider draws it. <where> is the region's path from root (its place among its
-- parent's children, then regions) and type, with the key of the options
-- row it belongs to (a body's row frame has .row).
-- P.report(list) -> the list's first few entries as one line, for a message.
local P = {}

local EDGES = { 'left', 'right', 'top', 'bottom' }

-- Within a hair of a whole unit: a size read back from the game (with
-- stub.size_noise, a hair off what it was given) and placed from leaves an
-- edge that far off, which the game draws on its pixel. Half a unit isn't.
local HAIR = 1e-3

local function whole(v)
	return math.abs(v - math.floor(v + 0.5)) < HAIR
end

local function walk(region, where, out)
	if not region:IsVisible() then return end
	local kind = region:GetObjectType()
	if region.row and region.row.key then where = where .. '[' .. tostring(region.row.key) .. ']' end
	if kind ~= 'FontString' then
		local edges = { left = region:GetLeft(), right = region:GetRight(), top = region:GetTop(), bottom = region:GetBottom() }
		if edges.left then
			local k = region:GetEffectiveScale() / UIParent:GetEffectiveScale()
			for _, edge in ipairs(EDGES) do
				local v = edges[edge] * k
				if not whole(v) then out[#out + 1] = ('%s %s: %s %s'):format(where, kind, edge, tostring(v)) end
			end
		end
	end
	if region.GetChildren then
		for i, child in ipairs({ region:GetChildren() }) do walk(child, where .. '.' .. i, out) end
		if kind ~= 'Slider' then
			for i, part in ipairs({ region:GetRegions() }) do walk(part, where .. '.r' .. i, out) end
		end
	end
end

function P.off(root)
	local out = {}
	walk(root, 'root', out)
	return out
end

function P.report(list)
	local shown = {}
	for i = 1, math.min(#list, 4) do shown[i] = list[i] end
	if #list > 4 then shown[#shown + 1] = ('and %d more'):format(#list - 4) end
	return table.concat(shown, '; ')
end

return P
