local st = SaftUI
local INV = st:GetModule('Inventory')

-- A bag or bank window (INV:CreateContainer): its frame, scroll frame, footer
-- (the count of used slots and the bag window's gold) and loading bar, and
-- its update (INV:UpdateContainer). Its title bar is header.lua's, its layout
-- layout.lua's and the bag window's search box search.lua's; each window's
-- own code is in containers/.

function INV:GetContainer(containerName)
	return self.containers[containerName]
end

function INV:CreateContainer(id, name, isBankContainer)
	local container = CreateFrame('frame', st.name ..name, UIParent)
	container.id = id
	container:SetFrameStrata('HIGH')
	self.containers[id] = container

	container.scrollFrame = st:CreateScrollFrame(container)
	container.scrollFrame:SetScript('OnMouseWheel', function(self, delta)
        local current = self:GetVerticalScroll()
        local maxScroll = self:GetVerticalScrollRange()
        local newScroll = current - (delta * INV.config.scrollSpeed * (INV:GetButtonHeight() + INV.config.buttonspacing))

        newScroll = max(0, min(newScroll, maxScroll))
        self:SetVerticalScroll(newScroll)
    end)

	st:CreateCloseButton(container)
	st:CreateHeader(container, name)
	self:InitializeFooter(container)
	if id == 'bag' then
		self:InitializeSearch(container)
	end

    if container.search then
        container.scrollFrame:SetPoint('TOPLEFT', container.search, 'BOTTOMLEFT', 0, -self.config.padding)
    else
        container.scrollFrame:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
    end

	container.categories = {}
	container.columns = {}
	container.bag_ids = self.bagIds[id]

	if not INV.config.filters.categories[id] then
		INV.config.filters.categories[id] = {}
	end

	self:CreateViewButtons(container)
	self:CreateEditToggle(container)

	container.bags = {}
	for _, bag_id in pairs(container.bag_ids) do
		local bag = CreateFrame('frame', 'SaftUI_Bag'..bag_id, container.scrollFrame.ScrollChild)
		bag:SetID(bag_id)
		container.bags[bag_id] = bag
	end

	self:InitializeLoadingOverlay(container)

	-- The next time it opens, the window is packed afresh.
	container:HookScript('OnHide', function() INV:ReleaseLayout(container) end)

	if isBankContainer and id ~= 'combinedbank' then
		 self:HookScript(container.header, 'OnClick', 'SelectBankCategory')
	end

	self:UpdateConfig(id)
	return container
end

function INV:InitializeLoadingOverlay(container)
	local loadingOverlay = st:CreateFrame('frame', container:GetName().."LoadingOverlay", container)
	loadingOverlay:SetBackdrop(st.BACKDROP)
	loadingOverlay:SetBackdropColor(0, 0, 0, .7)
	loadingOverlay:SetAllPoints()
	loadingOverlay:SetFrameStrata('HIGH')
	loadingOverlay:SetFrameLevel(50)

	local loadingBar = st:CreateStatusBar(container:GetName().."LoadingBar", loadingOverlay, '-/-', 'theme', 'solid')
	loadingBar:SetPoint('CENTER')
	loadingBar:SetSize(300, 30)
	loadingBar:SetStatusBarColor(st.config.profile.colors.button.blue:GetRGB())
	loadingOverlay.loadingBar = loadingBar

	container.loadingOverlay = loadingOverlay
	container.SetLoading = function(self, current, max)
		if current == max then
			loadingOverlay:Hide()
			return
		end
		loadingOverlay:Show()
		loadingBar:SetMinMaxValues(0, max)
		loadingBar:SetValue(current)
		loadingBar.text:SetFormattedText('%d / %d', current, max)
	end
end

function INV:InitializeFooter(container)
	st:CreateFooter(container)

	local slottext = container.footer:CreateFontString(nil, 'OVERLAY')
	st:ApplyFont(slottext, 'normal')
	slottext:SetPoint('LEFT', 10, 0)
	slottext:SetText('#/# Slots Used')
	slottext:SetJustifyH('LEFT')
	container.footer.slots = slottext

	if container.id == 'bag' then
		self:CreateGoldString(container)
		self:UpdateGold()
	elseif container.id == 'bank' and self:HasWarbandBank() then
		-- Neither client has a reagent bank anymore, so the separate bank only
		-- needs the way into the warband window.
		local warbandButton = st:CreateButton('WarbandBankButton', container, 'Warband Bank', 'theme', 'solid')
		warbandButton:SetPoint('BOTTOMRIGHT', container.footer, -6, 6)
		warbandButton:SetScript('OnClick', function()
			if not self.containers.warband then
				self:InitializeWarbandBank()
			else
				ToggleFrame(self.containers.warband)
			end
		end)
		warbandButton:SetSize(100, 16)
		warbandButton:SetFrameLevel(90)
	end
end

-- A window's gold (container.footer.gold), at its footer's right end, with
-- the gold on the realm in a tooltip (INV:DisplayServerGold). The bag window
-- shows the character's gold in it (INV:UpdateGold), the warband bank and the
-- combined bank the warband bank's (containers/).
function INV:CreateGoldString(container)
    local goldString = CreateFrame('frame', nil, container.footer)
    goldString:EnableMouse(true)
    goldString:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
    goldString:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
    goldString:SetWidth(120)

    goldString.text = goldString:CreateFontString(nil, 'OVERLAY')
    st:ApplyFont(goldString.text, 'normal')
    goldString.text:SetPoint('RIGHT', goldString, 'RIGHT', -10, 0)
    goldString.text:SetJustifyH('RIGHT')

    goldString:SetScript('OnEnter', function() INV:DisplayServerGold() end)
    goldString:SetScript('OnLeave', st.HideGameTooltip)

	container.footer.gold = goldString

    return goldString
end

function INV:UpdateGold()
	local money = GetMoney()
	self:GetContainer('bag').footer.gold.text:SetText(st.StringFormat:GoldFormat(money))
	self:UpdateWarbandMoney()
	self:UpdateCombinedBankWarbandMoney()
	st.config.realm.summary[st.my_name].gold = money
end

function INV:DisplayServerGold()
	GameTooltip:SetOwner(self.containers.bag, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('TOPRIGHT', self.containers.bag, 'TOPLEFT', -10, 0)

	GameTooltip:ClearLines()
	-- List server wide gold
	GameTooltip:AddLine('Gold on ' .. st.my_realm)
	local totalGold = 0
	for toonName, summary in pairs(st.config.realm.summary) do
		local color = summary.class
			and (st.config.profile.colors.class[summary.class] or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[summary.class]))
			or { r = 1, g = 1, b = 1 }
		GameTooltip:AddDoubleLine(toonName, summary.gold and st.StringFormat:GoldFormat(summary.gold) or "??", color.r, color.g, color.b)
		totalGold = totalGold + (summary.gold or 0)
	end


	if self:HasWarbandBank() then
		local warbandGold = C_Bank.FetchDepositedMoney(Enum.BankType.Account)
		totalGold = totalGold + warbandGold
		GameTooltip:AddLine(' ')
		GameTooltip:AddDoubleLine("Warband bank", st.StringFormat:GoldFormat(warbandGold))
	end

	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Total', st.StringFormat:GoldFormat(totalGold))

	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Vendor profit', st.StringFormat:GoldFormat(select(2, self:GetVendorItems())))

	GameTooltip:Show()
end

function INV:GetNumContainerSlots(bagIds)
	local empty, total = 0, 0
	for _,bagID in pairs(bagIds) do
		empty = empty + C_Container.GetContainerNumFreeSlots(bagID)
		total = total + C_Container.GetContainerNumSlots(bagID)
	end

	return empty, total
end

-- The loading bar and the footer's count of used slots.
local function ShowSlotCounts(self, container, numItems, numLoading)
	container:SetLoading(numItems - numLoading, numItems)

	if container.UpdateContainerSlots then
		container:UpdateContainerSlots()
	else
		local empty, total = self:GetNumContainerSlots(container.bag_ids)
			container.footer.slots:SetFormattedText('%d/%d', total-empty, total)
	end
end

-- A window that isn't open waits for its next update, unless whileHidden asks
-- for this one (the first update makes every slot before the window opens).
function INV:UpdateContainer(id, updateLayout, whileHidden)
	local container = self.containers[id]
	if not container or not (whileHidden or container:IsShown()) then return end
	self:EnsureSlotPools(id)

	-- One bag, Multi bag and Rows lay their sections out on every update.
	local view = self:GetLaidOutView(container)
	if view ~= 'compact' then
		local sections, numItems, numLoading = self:GetViewSections(id, view)
		self:LayoutSections(container, sections)
		ShowSlotCounts(self, container, numItems, numLoading)
		return
	end

	local sortedInventory, numItems, numLoading = self:GetSortedInventory(id)

	for name, items in pairs(sortedInventory) do
		self:UpdateCategory(id, name, items)
	end

	self:UpdateCurrencyCategory(container.filterButton:GetChecked())

	self:FlushCategories(container, sortedInventory)

	-- A layout is only held once every item is in it (see HoldLayout).
	container.loadingItems = numLoading > 0

	-- Items whose data is still loading (cold item cache after a reload) are left
	-- out until GET_ITEM_INFO_RECEIVED fires, and those updates don't request a
	-- layout. Keep relaying out until loading finishes so they actually appear.
	if updateLayout or container.layoutPending then
		self:UpdateContainerLayout(id)
	end
	container.layoutPending = numLoading > 0

	ShowSlotCounts(self, container, numItems, numLoading)
end
