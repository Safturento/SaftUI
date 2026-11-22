local st = SaftUI
local TP = st:GetModule('TalentPlan')
local M = TP.Model

--[[
	The saved plans. The plans are account wide, per class:
	st.config.global.talentplan = { nextID, plans = { [classFile] = { [id] = plan } } }.
	Which plan each spec tab shows is per character:
	st.config.char.talentplan = { active = { [specGroup] = id }, collapsed }.
	Both are read at call time, and made on first use.
]]
local S = {}
TP.Store = S

function S.ClassFile()
	return select(2, UnitClass('player'))
end

local function root()
	local g = st.config.global
	g.talentplan = g.talentplan or {}
	local r = g.talentplan
	r.nextID = r.nextID or 1
	r.plans = r.plans or {}
	return r
end

function S.Plans()
	local r, class = root(), S.ClassFile()
	r.plans[class] = r.plans[class] or {}
	return r.plans[class]
end

function S.Char()
	local c = st.config.char
	c.talentplan = c.talentplan or {}
	c.talentplan.active = c.talentplan.active or {}
	return c.talentplan
end

function S.List()
	local list = {}
	for _, plan in pairs(S.Plans()) do list[#list + 1] = plan end
	table.sort(list, function(a, b)
		local x, y = a.name:lower(), b.name:lower()
		if x ~= y then return x < y end
		return a.id < b.id
	end)
	return list
end

function S.Active(specGroup)
	local id = S.Char().active[specGroup]
	return id and S.Plans()[id] or nil
end

function S.SetActive(specGroup, id)
	S.Char().active[specGroup] = id
end

local function names()
	local set = {}
	for _, plan in pairs(S.Plans()) do set[plan.name] = true end
	return set
end

local function nextID()
	local r = root()
	local id = r.nextID
	r.nextID = id + 1
	return id
end

function S.New(name, specGroup)
	local plan = M.NewPlan(nextID(), M.UniqueName(names(), name))
	S.Plans()[plan.id] = plan
	S.SetActive(specGroup, plan.id)
	return plan
end

-- true, or false and 'empty' | 'taken'. Keeping the same name is fine.
function S.Rename(plan, name)
	name = (name or ''):match('^%s*(.-)%s*$')
	if name == '' then return false, 'empty' end
	for _, other in pairs(S.Plans()) do
		if other ~= plan and other.name == name then return false, 'taken' end
	end
	plan.name = name
	return true
end

local function copy(value)
	if type(value) ~= 'table' then return value end
	local out = {}
	for k, v in pairs(value) do out[k] = copy(v) end
	return out
end

function S.Duplicate(plan, specGroup)
	local dup = copy(plan)
	dup.id = nextID()
	dup.name = M.UniqueName(names(), plan.name .. ' copy')
	S.Plans()[dup.id] = dup
	S.SetActive(specGroup, dup.id)
	return dup
end

function S.Delete(plan)
	S.Plans()[plan.id] = nil
	local active = S.Char().active
	for specGroup, id in pairs(active) do
		if id == plan.id then active[specGroup] = nil end
	end
end
