local st = SaftUI

st.HideGameTooltip = function() GameTooltip:Hide() end
st.dummy = function() end

if not issecretvalue then
	function issecretvalue() return false end
end

-- Values the game may hand an addon as secrets (.agents/clients.md): a secret
-- can't be compared, looked up or typed, so these give nil for one.
-- A value that isn't secret, else nil.
function st.Plain(value)
	if not issecretvalue(value) then return value end
end

-- A value that is a plain number, else nil.
function st.PlainNumber(value)
	if not issecretvalue(value) and type(value) == 'number' then return value end
end

-- A value that is a plain string, else nil.
function st.PlainString(value)
	if not issecretvalue(value) and type(value) == 'string' then return value end
end

-- A tooltip's lines (C_TooltipInfo's data.lines) as one string: each line's
-- leftText then rightText, with a space before each.
function st.TooltipLinesText(lines)
	local text = ""
	for _, line in pairs(lines) do
		if line.leftText then
			text = text .. " " .. line.leftText
		end
		if line.rightText then
			text = text .. " " .. line.rightText
		end
	end
	return text
end

-- A whole number from `value` (nil or false counts as `low`) held between low and high; with
-- low above high, high. Errors on a string or a secret value, as math.floor does.
function st.Clamp(value, low, high)
	return math.min(math.max(math.floor(value or low), low), high)
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

string.unmagic = removeMagicChars

function string.matchnocase(str, pattern) return strlower(removeMagicChars(str)):match(strlower(pattern)) end

function st:barrier(self, elapsed, threshold)
	self.barrierTime = (self.barrierTime or 0) + elapsed
	if self.barrierTime <= threshold then return true end
	self.barrierTime = 0
	return false
end

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
function st.tablemerge(t1, t2, inPlace)
	local rootTable = inPlace and t1 or st.tablecopy(t1)

	if not t2 then t2 = {} end
	for k, v in pairs(t2) do
		if (type(v) == 'table') and (type(rootTable[k] or false) == 'table') then
		   st.tablemerge(rootTable[k], t2[k], true)
		else
			rootTable[k] = v
		end
	end
	return rootTable
end

local colors = {
	'E65050',--red
	'50E650',--green
	'50AAE6',--blue
	'C14FE3',--purple
}

function st.tableprint(table, indent, maxDepth)
	if not indent then indent = 2 end

	for key, val in pairs(table) do
		local prefix = ''
		for i=1, indent do
			prefix = prefix .. '    '
		end
		if type(val) == 'table' then
			if maxDepth == 0 then
				print(prefix .. val)
			else
				local colorIndex = (indent)%(#colors)+1
				print(prefix .. st.StringFormat:ColorString(key .. ' = {', colors[colorIndex]))
				st.tableprint(val, indent + 1, maxDepth and maxDepth - 1 or nil)
				print(prefix .. st.StringFormat:ColorString('}', colors[colorIndex]))
			end
		else
			print(prefix .. key .. ' = ' .. tostring(val))
		end
	end
end


function st.map(table, func)
	for key, value in pairs(table) do
		func(key, value)
	end
end

function st.normalizeRGB(r, g, b)
	return r/255, g/255, b/255
end


-- The dialog's edit box is Blizzard's StaticPopupN edit box, so nothing here
-- SetScripts on it or writes onto it: Blizzard calls the dialog's own
-- EditBoxOnTextChanged / EditBoxOnEscapePressed (editBox, data), where data is
-- the link passed to StaticPopup_Show. Blizzard passes no userInput flag.
local function EscapedLink(link)
	return gsub(link, "\124", "\\124")
end

-- GetEditBox on current clients, the named child before.
local function EditBoxOf(dialog)
	if dialog.GetEditBox then return dialog:GetEditBox() end
	return _G[dialog:GetName() .. 'EditBox']
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
		local editBox = EditBoxOf(self)
		editBox:SetText(EscapedLink(link))
		editBox:HighlightText()
	end,
	-- Typing can't change the text: put the link back.
	EditBoxOnTextChanged = function(editBox, link)
		local escapedLink = EscapedLink(link)
		if editBox:GetText() ~= escapedLink then
			editBox:SetText(escapedLink)
		end
	end,
	EditBoxOnEscapePressed = function(editBox, link)
		StaticPopup_Hide("EXTRACT_LINK_DIALOG")
	end,
}

 --extract chat link to dialog box for easy copying
SLASH_EXTRACT_LINK1 = '/link'
SlashCmdList['EXTRACT_LINK'] = function(link, editbox)
	StaticPopup_Show("EXTRACT_LINK_DIALOG", nil, nil, link)
end

SLASH_PRINT_ITEM1 = '/item'
SlashCmdList['PRINT_ITEM'] = function(link)
	local itemName, itemLink, itemQuality, itemLevel, itemMinLevel, itemType, itemSubType,
	itemStackCount, itemEquipLoc, itemTexture, sellPrice, classID, subclassID, bindType,
	expacID, setID, isCraftingReagent = C_Item.GetItemInfo(link)
	st.tableprint({
		itemName = itemName,
		itemLink = itemLink,
		itemQuality = itemQuality,
		itemLevel = itemLevel,
		itemMinLevel = itemMinLevel,
		itemType = itemType,
		itemSubType = itemSubType,
		itemStackCount = itemStackCount,
		itemEquipLoc = _G[itemEquipLoc],
		itemTexture = itemTexture,
		sellPrice = sellPrice,
		classID = classID,
		subclassID = subclassID,
		bindType = bindType,
		expacID = expacID,
		setID = setID,
		isCraftingReagent = isCraftingReagent,
	})
end