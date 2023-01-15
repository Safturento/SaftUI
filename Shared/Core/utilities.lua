local st = SaftUI

st.HideGameTooltip = function() GameTooltip:Hide() end
st.dummy = function() end

local function escape(str)
	return string.gsub(str, "[%(%)%.%+%-%*%?%[%]%^%$%%]", "%%%1") -- escape pattern
end

local function removeMagicChars(x)
   return (x:gsub('%%', ' ')
            :gsub('^%^', '')
            :gsub('%$$', '')
            :gsub('%(', '')
            :gsub('%)', '')
            :gsub('%.', '')
            :gsub('%[', '')
            :gsub('%]', '')
            :gsub('%*', '')
            :gsub('%+', '')
            :gsub('%-', '')
            :gsub('%?', ''))
end

function string.matchnocase(x, y) return string.match(strlower(removeMagicChars(x)), strlower(removeMagicChars(y))) end
function string.findnocase(x, y) return string.find(strlower(removeMagicChars(x)), strlower(removeMagicChars(y))) end

--https://wowpedia.fandom.com/wiki/ColorGradient
function st:ColorGradient(perc, ...)
 	if perc >= 1 then
 		local r, g, b = select(select('#', ...) - 2, ...)
 		return r, g, b
 	elseif perc <= 0 then
 		local r, g, b = ...
 		return r, g, b
 	end

 	local num = select('#', ...) / 3

 	local segment, relperc = math.modf(perc*(num-1))
 	local r1, g1, b1, r2, g2, b2 = select((segment*3)+1, ...)

 	return r1 + (r2-r1)*relperc, g1 + (g2-g1)*relperc, b1 + (b2-b1)*relperc
 end

--Make a copy of a table
function st.tablecopy(t, deep, seen)
	seen = seen or {}
	if t == nil then return nil end
	if seen[t] then return seen[t] end

	local nt = {}
	for k, v in pairs(t) do
		if deep and type(v) == 'table' then
			nt[k] = st.tablecopy(v, deep, seen)
		else
			nt[k] = v
		end
	end
	setmetatable(nt, st.tablecopy(getmetatable(t), deep, seen))
	seen[t] = nt
	return nt
end

--Merge two tables, with variables from t2 overwriting t1 when a duplicate is found
function st.tablemerge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == 'table') and (type(t1[k] or false) == 'table') then
		   st.tablemerge(t1[k], t2[k])
		else
			t1[k] = v
		end
	end
	return t1
end

--Purge any variable of t1 who's value is set to the same as t2
function st.tablepurge(t1, t2)
	for k, v in pairs(t2) do
		if (type(v) == 'table') and (type(t1[k] or false) == 'table') then
			st.tablepurge(t1[k], t2[k])
		else
			if t1[k] == v then
				t1[k] = nil
			end
		end
	end
	return t1
end

local colors = {
	'E65050',--red
	'50E650',--green
	'50AAE6',--blue
	'C14FE3',--purple
}

function st.tableprint(table, indent)
	if not indent then indent = 0 end

	for key, val in pairs(table) do
		local prefix = ''
		for i=1, indent do
			prefix = prefix .. '    '
		end
		if type(val) == 'table' then
			local colorIndex = (indent)%(#colors)+1
			print(prefix .. st.StringFormat:ColorString(key .. ' = {', colors[colorIndex]))
			st.tableprint(val, indent + 1)
			print(prefix .. st.StringFormat:ColorString('}', colors[colorIndex]))
		else
			print(prefix .. key .. ' = ' .. tostring(val))
		end
	end
end

function st.tableinvert(table)
	local inverted = {}
	for k,v in pairs(table) do
		inverted[v] = k
	end
	return inverted
end

function st.map(table, func)
	for key, value in pairs(table) do
		func(key, value)
	end
end

function st.imap(table, func)
	for index, value in ipairs(table) do
		func(index, value)
	end
end


StaticPopupDialogs["EXTRACT_LINK_DIALOG"] = {
	text = "Copy link",
	button1 = "Close",
	timeout = 0,
	whileDead = true,
	hasEditBox = true,
	hasWideEditBox = true,
	hideOnEscape = true,
	preferredIndex = 3,  -- avoid some UI taint, see http://www.wowace.com/announcements/how-to-avoid-some-ui-taint/
	OnShow = function(self, link)
		local escapedLink = gsub(link, "\124", "\\124")

		self.editBox:SetText(escapedLink)
		self.editBox:HighlightText()

		self.editBox:SetScript('OnTextChanged', function(self, userInput)
			print(userInput)
			if userInput then self:SetText(escapedLink) end
		end)

		self.editBox:SetScript('OnEscapePressed', function(self)
			StaticPopup_Hide("EXTRACT_LINK_DIALOG")
		end)
	end
}

 --extract chat link to dialog box for easy copying
SLASH_EXTRACT_LINK1 = '/link'
SlashCmdList['EXTRACT_LINK'] = function(link, editbox)
	StaticPopup_Show("EXTRACT_LINK_DIALOG", nil, nil, link)
end

SLASH_PRINT_ITEM1 = '/item'
SlashCmdList['PRINT_ITEM'] = function(link)
	print(GetItemInfo(link))
end