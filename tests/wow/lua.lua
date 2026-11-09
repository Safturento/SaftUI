--[[
	WoW's additions to Lua 5.1: the short global names for math, string and
	table functions, wipe, strtrim and the bit library. Add more here when
	SaftUI code needs them, with the game's behavior.
]]

-- Global aliases WoW defines (the same functions as the library ones).
abs, ceil, floor, max, min, sqrt = math.abs, math.ceil, math.floor, math.max, math.min, math.sqrt
mod = math.fmod
format, gsub, strbyte, strchar, strfind, strlen, strlower, strmatch, strrep, strsub, strupper, gmatch =
	string.format, string.gsub, string.byte, string.char, string.find, string.len, string.lower,
	string.match, string.rep, string.sub, string.upper, string.gmatch
tinsert, tremove, sort = table.insert, table.remove, table.sort

-- Empties a table in place and returns it.
function wipe(t)
	for k in pairs(t) do
		t[k] = nil
	end
	return t
end
table.wipe = wipe

-- Trims whitespace (or any of the characters in chars) from both ends.
function strtrim(str, chars)
	local set = chars and ('[' .. chars:gsub('[%]%%%^%-]', '%%%0') .. ']') or '%s'
	return (str:gsub('^' .. set .. '+', ''):gsub(set .. '+$', ''))
end

-- WoW's bit library is LuaBitOp: 32-bit operations with signed results. Only
-- band so far (LibSharedMedia uses it).
local function tobit(x)
	x = x % 4294967296
	return x >= 2147483648 and x - 4294967296 or x
end

bit = {}

function bit.band(a, b)
	a, b = a % 4294967296, b % 4294967296
	local result, place = 0, 1
	for _ = 1, 32 do
		local x, y = a % 2, b % 2
		if x == 1 and y == 1 then result = result + place end
		a, b, place = (a - x) / 2, (b - y) / 2, place * 2
	end
	return tobit(result)
end
