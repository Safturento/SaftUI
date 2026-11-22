local st = SaftUI
local TP = st:GetModule('TalentPlan')

--[[
	The paste parser, pure (no WoW API). TP.Parse(text, names) reads a pasted
	talent order as words and finds talent names in them, longest first. A
	number that isn't a rank is a level, checked against the last level seen.
	Lines before the first match are a preamble and skipped; after it, a line
	with a word nothing explains goes in `unmatched`. names is
	{ { name, nodeID, maxRanks }, ... }.
]]

local lower, gmatch, format = string.lower, string.gmatch, string.format

-- The curly apostrophe's UTF-8 bytes are dropped as a unit, so none are left
-- behind as stray characters; Lua 5.1 has no utf8 library.
function TP.Normalize(s)
	s = lower(s):gsub('\226\128\153', ''):gsub("'", ''):gsub('[^%w]', ' ')
	return (s:gsub('%s+', ' '):gsub('^ ', ''):gsub(' $', ''))
end
local Normalize = TP.Normalize

local function words(s)
	local out = {}
	for w in gmatch(Normalize(s), '%S+') do out[#out + 1] = w end
	return out
end

local function entries(names)
	local list = {}
	for _, n in ipairs(names) do
		local w = words(n.name)
		if #w > 0 then
			list[#list + 1] = { words = w, key = Normalize(n.name), name = n.name, nodeID = n.nodeID, maxRanks = n.maxRanks }
		end
	end
	table.sort(list, function(a, b)
		if #a.words ~= #b.words then return #a.words > #b.words end
		return #a.key > #b.key
	end)
	return list
end

-- The rank a word (and maybe the next) gives: rank, words used. Nil if none.
local function rankAt(list, i, from)
	local w = list[i]
	if not w then return end
	if w.line ~= from and not w.first then return end
	if w.line > from + 1 then return end
	local n = w.w:match('^rank(%d+)$') or w.w:match('^r(%d+)$')
	if n then return tonumber(n), 1 end
	if w.w == 'rank' or w.w == 'r' then
		local nx = list[i + 1]
		if nx and nx.line == w.line and nx.w:match('^%d+$') then return tonumber(nx.w), 2 end
	end
end

function TP.Parse(text, names)
	local result = { steps = {}, warnings = {}, unmatched = {} }
	local ents = entries(names)

	local flat, rawLines = {}, {}
	local lineNo = 0
	for raw in (text:gsub('\r', '') .. '\n'):gmatch('(.-)\n') do
		lineNo = lineNo + 1
		rawLines[lineNo] = raw
		local prepared = raw:gsub('(%d+)/(%d+)', ' rank %1 ')
		local first = true
		for w in gmatch(Normalize(prepared), '%S+') do
			flat[#flat + 1] = { w = w, line = lineNo, first = first }
			first = false
		end
	end

	local planned, lastLevel, matched = {}, nil, false
	local reported = {}
	local function warn(line, msg) result.warnings[#result.warnings + 1] = { line = line, text = msg } end

	local i = 1
	while i <= #flat do
		local cur = flat[i]
		local hit
		for _, e in ipairs(ents) do
			local ok = true
			for k = 1, #e.words do
				local f = flat[i + k - 1]
				if not f or f.line ~= cur.line or f.w ~= e.words[k] then ok = false break end
			end
			if ok then hit = e break end
		end
		if hit then
			matched = true
			local nextI = i + #hit.words
			local given, used = rankAt(flat, nextI, cur.line)
			local rank = (planned[hit.nodeID] or 0) + 1
			if given and given ~= rank then
				warn(cur.line, format('Line %d: %s says rank %d, but it is rank %d in the plan.', cur.line, hit.name, given, rank))
			end
			if rank > hit.maxRanks then
				warn(cur.line, format('Line %d: %s has only %d ranks, so this one is left out.', cur.line, hit.name, hit.maxRanks))
			else
				planned[hit.nodeID] = rank
				result.steps[#result.steps + 1] = hit.nodeID
			end
			i = nextI + (used or 0)
		else
			local w = cur.w
			if w:match('^%d+$') then
				local level = tonumber(w)
				if matched and lastLevel and level ~= lastLevel + 1 then
					warn(cur.line, format('Line %d: level %d comes after level %d.', cur.line, level, lastLevel))
				end
				lastLevel = level
			elseif w ~= 'level' and w ~= 'lvl' and w ~= 'rank' and matched and not reported[cur.line] then
				reported[cur.line] = true
				local text = rawLines[cur.line]:gsub('^%s+', ''):gsub('%s+$', '')
				result.unmatched[#result.unmatched + 1] = { line = cur.line, text = text }
			end
			i = i + 1
		end
	end
	return result
end

local function cut(out, list, maxLines, fmt)
	for i = 1, math.min(#list, maxLines) do out[#out + 1] = fmt(list[i]) end
	if #list > maxLines then out[#out + 1] = format('and %d more', #list - maxLines) end
end

function TP.ImportSummary(result, maxLines)
	local M = TP.Model
	local n = #result.steps
	local out = {}
	if n == 0 then
		out[1] = 'No talents found.'
	else
		out[1] = format('%d steps, levels %d to %d.', n, M.FIRST_LEVEL, M.Level(n))
	end
	cut(out, result.warnings, maxLines, function(w) return w.text end)
	cut(out, result.unmatched, maxLines, function(u) return format('Not matched, line %d: %s', u.line, u.text) end)
	return out
end
