local ADDON_NAME, st = ...

st.HideGameTooltip = function() GameTooltip:Hide() end
st.dummy = function() end

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