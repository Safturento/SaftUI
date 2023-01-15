--[=[

	Name: LibStringFormat-1.0
	Revision: $Revision: 1 $
	Author: Safturento
	Website: www.safturento.com
	Description: Adds a variety of functions used to easily format strings and numbers 
	Dependencies: LibStub
	License: LGPL v2.1


	SanitizeNumber(stringOrNumber [,min [,max]]): removes any character that would render the number invalid.
	  optionally, you can pass a min and max to give the number a size limitation
		<stringOrNumber> (string or number) - the value that you want to sanitize
		<min> [optional] (number) - the minimum that the number can be
		<max> [optional] (number) - the maximum that the number can be
 
	Trim(string): removes extra whitespace from a string
		<string> (string) - the string you wish to trim

	ToClock(sec): converts seconds into a clock format
		<sec> (number) - number of seconds to format

	ToTime(sec): converts seconds into a readable time format
		<sec> (number) - number of seconds to format

	ToHex(r, g, b): converts RGB values intoa hexadecimal string
		<r>,<g>,<b> - (number) RGB color values, can be passed in values of 0-1 or 0-255

	ToRGB(hexString [,divide]): converts hexadecimal strings into RGB values
		<hexString> (string) - the hexadecimal string you wish to convert to RGB values
		<divide> [optional] (boolean) - set to true if you want the values returned in 0-1 values instead of 0-255

	ColorString(string, [r,g,b] or [hexString]): pass a string and color (either using a hex string or RGB values) to
	  get that string in your color of choice
		<string> (string) - the string that you wish to colorize
		<hexString> (string) - you can pass a hex string you wish to use to colorize the text
		<r>,<g>,<b> - (number) - you can pass a set of 3 RGB values which will be converted to colorize the text

	ShortFormat(value [,decimals]): returns the abbreviated form of a number
		<value> (number) - the number you wish to format
		<decimals> [optional] (number) -- the amount of decimals you wish to show. Default is 0

	FileSizeFormat(value [,decimals]): formats bytes into a readable file size format
		<value> (number) - the number you wish to format
		<decimals> [optional] (number) -- the amount of decimals you wish to show. Default is 0

	CommaFormat(value): comma separates a number
		<value> (number) - the number you wish to format

	GoldFormat(money [,round]): returns a number in the form of gold, silver and copper
		<money> (number) - the amount of money you wish to format
		<round> [optional] (boolean) - if set to true, only show the highest currency
]=]

local MAJOR, MINOR = "LibStringFormat-1.0", 1
local lib, oldminor = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then return end -- No Upgrade needed.

local min, max = math.min, math.max
local tonumber, type = tonumber, type
local gsub, strmatch, strfind = string.gsub, string.match, string.find
local GOLD_COLOR = {gold='|cFFFFD700', silver='|cFFC7C7C7', copper='|cFFEDA55F'}


-------------------------------
-- NUMBER FUNCTIONS -----------
-------------------------------

function lib:SanitizeNumber(stringOrNumber, minimum, maximum)
	local num
	if type(stringOrNumber) == 'string' then
		num = gsub(stringOrNumber, '%D','')
		num = tonumber(num, 10)
	else
		num = stringOrNumber
	end


	if minimum then num = math.max(minimum, num) end
	if maximum then num = math.min(maximum, num) end

	return num
end

function lib:Round(val, decimals)
  local mult = 10^(decimals or 0)
  return math.floor(val * mult + 0.5) / mult
end

function lib:ToClock(sec)
	local hour, minute = 3600, 60
	if sec > hour then 
		return format('%02.f:%02.f', floor(sec/hour), ceil(sec%hour)/minute)
	else
		return format('%02.f:%02.f', floor(sec/minute), floor(sec%minute))
	end
end

function lib:ToTime(sec)
	local day, hour, minute = 86400, 3600, 60
	if sec >= day then
		return format("%dd", ceil(sec / day))
	elseif sec >= hour then
		return format("%dh", ceil(sec / hour))
	elseif sec >= minute then
		return format("%dm", ceil(sec / minute))
	elseif sec >= minute / 12 then
		return floor(sec)
	end
	return format("%.1f", sec)
end

function lib:ShortFormat(value, decimals, decimal_threshold)
	if type(value) == 'string' then value = tonumber(value) end
	
	local suffix = 'KMBTQ' --I doubt you'd need more than quadrillions..
	local factor = floor((strlen(value)-1) / 3)
	local converted = value/math.pow(1000,factor)
	if decimals and (not decimal_threshold or value > decimal_threshold) then
		return format('%.0'..(decimals)..'f%s', converted, strsub(suffix, factor, factor))
	else
		return converted..strsub(suffix, factor, factor)
	end
end

function lib:FileSizeFormat(bytes, decimals)
    local suffix = 'kMGTPEZY'
	 local factor = floor((strlen(floor(bytes))-1) / 3)
	 local converted = bytes/math.pow(1024,factor)
    return format('%.0'..(decimals or 0)..'f%sB', converted, strsub(suffix, factor, factor))
end

function lib:GoldFormat(money, round)
	if not money then return "" end
	local negative = money < 0 and true or false --if money is negative, add a negative sign when returning the string
	money = (abs(money)) --remove the negative sign from the actual value\

	local gold   = floor(money / 10000)
	local silver = floor(mod(money/100, 100))
	local copper = floor(mod(money, 100))

	-- just incase you have no money :p
	if gold + silver + copper == 0 then return '-' end

	if round then
		if gold > 0 then
			return GOLD_COLOR.gold..self:CommaFormat(gold)..'|r'
		elseif silver > 0 then
			return GOLD_COLOR.silver..silver..'|r'
		elseif copper > 0 then
			return GOLD_COLOR.copper..copper..'|r'
		end
	else
		gold   = gold   > 0 and GOLD_COLOR.gold..self:CommaFormat(gold)..'|r ' or ''
		silver = silver > 0 and GOLD_COLOR.silver..silver..'|r ' or ''
		copper = copper > 0 and GOLD_COLOR.copper..copper..'|r' or ''

		return string.trim(gold..silver..copper)
	end
end

-------------------------------
-- STRING FUNCTIONS -----------
-------------------------------

function lib:Trim(string)
	return string:find('^%s*$') and '' or string:match('^%s*(.*%S)')
end

function lib:CommaFormat(value)
	local k
	while true do  
		value, k = string.gsub(value, "^(-?%d+)(%d%d%d)", '%1,%2')
		if (k==0) then break end
	end
	return value
end

-------------------------------
-- COLOUR FUNCTIONS -----------
-------------------------------

function lib:ToHex(r, g, b)
	r = r <= 1 and r >= 0 and r or r/255
	g = g <= 1 and g >= 0 and g or g/255
	b = b <= 1 and b >= 0 and b or b/255
	return string.format("%02x%02x%02x", r*255, g*255, b*255)
end

function lib:ToRGB(hexString, divide)
	local rHex, gHex, bHex
	if strlen(hexString) == 6 then
		rHex, gHex, bHex = strmatch(hexString, '([a-fA-F0-9][a-fA-F0-9])([a-fA-F0-9][a-fA-F0-9])([a-fA-F0-9][a-fA-F0-9])')
	elseif strlen(hexString) == 3 then
		rHex, gHex, bHex = strmatch(hexString, '([a-fA-F0-9])([a-fA-F0-9])([a-fA-F0-9])')
		if rHex and gHex and bHex then
			rHex = rHex .. rHex
			gHex = gHex .. gHex
			bHex = bHex .. bHex
		end
	end
	
	assert(rHex and gHex and bHex, MAJOR..'Invalid hexString parameter passed for ToRGB function.')

	local r, g, b = tonumber(rHex, 16), tonumber(gHex, 16), tonumber(bHex, 16)
	if divide then r=r/255; g=g/255; b=b/255 end
	return r, g, b
end

function lib:ColorString(string, ...)
	-- if only one parameter is passed to the varargs, assume a hex
	--	value was passed. Otherwise, assume RGB values were passed.
	local hex = #{...} == 1 and ... or self:ToHex(...)

	return format('|cff%s%s|r', hex, string)
end

----------------------------
-- UTF-8 AWARE FUNCTIONS ---
----------------------------

function lib:UTF8gsub(s, i, j)
	i = strfind(s, i, 1, true)

	if not i then return '' end

	if j then
		local tmp = strfind(s, j, 1, true)
		if not tmp then return '' end
		j = (tmp - 1) + #j
	end

	return gsub(s, i, j)
end

function lib:UTF8strsub(string, numChars, dots)
	local bytes = string:len()
	if (bytes <= numChars) then
		return string
	else
		local len, pos = 0, 1
		while(pos <= bytes) do
			len = len + 1
			local c = string:byte(pos)
			if (c > 0 and c <= 127) then
				pos = pos + 1
			elseif (c >= 192 and c <= 223) then
				pos = pos + 2
			elseif (c >= 224 and c <= 239) then
				pos = pos + 3
			elseif (c >= 240 and c <= 247) then
				pos = pos + 4
			end
			if (len == numChars) then break end
		end

		if (len == numChars and pos <= bytes) then
			return string:sub(1, pos - 1)..(dots and '...' or '')
		else
			return string
		end
	end
end