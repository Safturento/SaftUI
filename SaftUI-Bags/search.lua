local st = SaftUI
local INV = st:GetModule('Inventory')

-- The bag window's search box (INV:CreateContainer gives it to the bag window
-- only): what a query matches in an item, and fading every open window's
-- slots that don't match it.

function INV:InitializeSearch(container)
	-- st:CreateEditBox skins the box; its third argument would make it
	-- multi-line. The skin is restyled, not applied a second time.
	local search = st:CreateEditBox(container:GetName()..'Search', container.footer)
	st:StyleEditBox(search, 'theme', 'theme')
	search:SetHeight(20)
	self:HookScript(search, 'OnTextChanged', 'UpdateSearchFilter')
	container.search = search
end

function INV:ParseSearchQuery(queryString)
	local entries = { (";"):split(queryString) }
	local info = {}

	for _, entry in pairs(entries) do
		entry = entry:lower()
		if entry == "soulbound" then
			info.showSoulbound = true
		elseif entry == "warbound" then
			info.showWarbound = true
		elseif entry == "boe" then
			info.showBoE = true
		elseif entry == "useable" then
			info.showUsable = true
		end
	end

	return info
end

function INV:SearchMatches(queryString, info)
	-- A free slot has nothing to match: it only stays lit with no search.
	if info.empty then return queryString == '' end

	local queryTags = INV:ParseSearchQuery(queryString)
	queryString = queryString:lower()

	for _, check in pairs({
		queryTags.showBoE and info.isBoE,
		queryTags.showSoulbound and info.isSoulbound and not info.isWarbound,
		queryTags.showWarbound and info.isWarbound,
		info.name:lower():find(queryString),
		(info.equipSlot and info.equipSlot:lower() == queryString),
		(info.class == 'Armor') and queryString:lower():find(info.subclass),
		info.tooltipText:lower():find(queryString)
	}) do if check then return true end end
end

function INV:UpdateSearchFilter(editbox, is_user_input)
	local query = editbox:GetText()
	for _,container in pairs(self.containers) do
		if container:IsShown() then
			for _,category in pairs(container.categories) do
				for _,slot in pairs(category.slots) do
					if slot:IsShown() then
						-- The reagent wedge isn't faded with the item button.
						local alpha = self:SearchMatches(query, slot.info) and 1 or 0.1
						slot:SetAlpha(alpha)
						slot.reagentMarker:SetAlpha(alpha)
					end
				end
			end
		end
	end
end
