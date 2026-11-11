local st = SaftUI
local INV = st:GetModule('Inventory')

--[[
	The client's item classes and subclasses, read from the game once, on first
	use, so the category blocks name them in English and resolve the names to
	this client's ids (Forever's Trade Goods is class 7 and retail's Tradeskill
	is too; Forever has no Gem class and retail has no Devices subclass).

	  IC.ClassIDs(name)          -> { [classID] = true }
	  IC.SubclassIDs(name)       -> { [classID] = { subclassID, ... } }, ascending
	  IC.ClassName(id)           -> name | nil
	  IC.SubclassName(classID, subclassID) -> name | nil
	  IC.Classes()               -> { { id, name }, ... }, by id
	  IC.Subclasses(classID)     -> { { id, name }, ... }, by id
	  IC.IsGear(info)            -> bool: Armor or Weapon
	  IC.Reset()                 for tests
]]
local IC = {}
INV.ItemClasses = IC

local MAX_ID = 39

local classes, subclasses, gear -- [id] = name; [classID] = { [id] = name }; [classID] = true

local function name_of(fn, ...)
	if not fn then return nil end
	local ok, name = pcall(fn, ...)
	if ok and type(name) == 'string' and name ~= '' then return name end
end

local function load()
	if classes then return end
	classes, subclasses, gear = {}, {}, nil
	local classInfo = (C_Item and C_Item.GetItemClassInfo) or GetItemClassInfo
	local subclassInfo = (C_Item and C_Item.GetItemSubClassInfo) or GetItemSubClassInfo
	for classID = 0, MAX_ID do
		classes[classID] = name_of(classInfo, classID)
		for subclassID = 0, MAX_ID do
			local name = name_of(subclassInfo, classID, subclassID)
			if name then
				subclasses[classID] = subclasses[classID] or {}
				subclasses[classID][subclassID] = name
			end
		end
	end
end

local function sorted_keys(t)
	local keys = {}
	for k in pairs(t) do keys[#keys + 1] = k end
	table.sort(keys)
	return keys
end

function IC.ClassIDs(name)
	load()
	local ids = {}
	for id, n in pairs(classes) do
		if n == name then ids[id] = true end
	end
	return ids
end

function IC.SubclassIDs(name)
	load()
	local out = {}
	for _, classID in ipairs(sorted_keys(subclasses)) do
		for _, subclassID in ipairs(sorted_keys(subclasses[classID])) do
			if subclasses[classID][subclassID] == name then
				out[classID] = out[classID] or {}
				tinsert(out[classID], subclassID)
			end
		end
	end
	return out
end

function IC.ClassName(id)
	load()
	return classes[id]
end

function IC.SubclassName(classID, subclassID)
	load()
	return subclasses[classID] and subclasses[classID][subclassID]
end

function IC.Classes()
	load()
	local out = {}
	for _, id in ipairs(sorted_keys(classes)) do tinsert(out, { id = id, name = classes[id] }) end
	return out
end

function IC.Subclasses(classID)
	load()
	local out = {}
	local names = subclasses[classID] or {}
	for _, id in ipairs(sorted_keys(names)) do tinsert(out, { id = id, name = names[id] }) end
	return out
end

-- Armor or Weapon: the item's classID is one of those classes on this client.
function IC.IsGear(info)
	load()
	if not gear then
		gear = {}
		for _, name in ipairs({ 'Armor', 'Weapon' }) do
			for id in pairs(IC.ClassIDs(name)) do gear[id] = true end
		end
	end
	return info ~= nil and info.classID ~= nil and gear[info.classID] == true
end

function IC.Reset()
	classes, subclasses, gear = nil, nil, nil
end
