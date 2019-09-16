local ADDON_NAME, st = ...
local INV = st:NewModule('Inventory', 'AceHook-3.0', 'AceEvent-3.0')

local BACKPACK_IDS = {0, 1, 2, 3, 4}
local BANK_IDS = {-1, 5, 6, 7, 8, 9, 10, 11}

INV.containers = {}

function INV:CreateContainer(id, name)
	local container = CreateFrame('frame', ADDON_NAME..name, UIParent)
	container.id = id
	container:SetFrameStrata('HIGH')
	self.containers[id] = container

	st:CreateCloseButton(container)
	st:CreateHeader(container, name)
	self:InitializeFooter(container)

	container.slots = {}
	container.categories = {}
	container.bag_ids = id == 'bag' and BACKPACK_IDS or BANK_IDS

	container.bags = {}
	for _, bag_id in pairs(container.bag_ids) do
		local bag = CreateFrame('frame', 'SaftUI_Bag'..bag_id, container)
		bag:SetID(bag_id)
		container.bags[bag_id] = bag
	end

	self:UpdateConfig(id)
end

function INV:InitializeFooter(container)
	st:CreateFooter(container)

	local slottext = container.footer:CreateFontString(nil, 'OVERLAY')
	slottext:SetFontObject(st:GetFont(st.config.profile.headers.font))
	slottext:SetPoint('LEFT', 10, 0)
	slottext:SetText('#/# Slots Used')
	container.footer.slots = slottext

	if container.id == 'bag' then
		local goldstring = CreateFrame('frame', nil, container.footer)
		goldstring:EnableMouse(true)
		goldstring:SetPoint('TOPRIGHT', container.footer, 'TOPRIGHT', 0, 0)
		goldstring:SetPoint('BOTTOMRIGHT', container.footer, 'BOTTOMRIGHT', 0, 0)
		goldstring:SetWidth(110)

		goldstring.text = goldstring:CreateFontString(nil, 'OVERLAY')
		goldstring.text:SetFontObject(st:GetFont(st.config.profile.headers.font))
		goldstring.text:SetPoint('RIGHT', goldstring, 'RIGHT', -10, 0)

		goldstring:SetScript('OnEnter', function() INV:DisplayServerGold() end)
		goldstring:SetScript('OnLeave', st.HideGameTooltip)

		container.footer.gold = goldstring
		self:UpdateGold()
	end
end

function INV:UpdateGold()
	local money = GetMoney()
	self.containers.bag.footer.gold.text:SetText(st.StringFormat:GoldFormat(money))
	st.config.realm.gold[st.my_name] = money
end

function INV:DisplayServerGold()
	GameTooltip:SetOwner(self.containers.bag, "ANCHOR_NONE")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint('TOPRIGHT', self.containers.bag, 'TOPLEFT', -10, 0)
	
	GameTooltip:ClearLines()	
	-- List server wide gold
	GameTooltip:AddLine('Gold on ' .. st.my_realm)
	local totalGold = 0
	for toonName, gold in pairs(st.config.realm.gold) do 
		GameTooltip:AddDoubleLine(toonName, st.StringFormat:GoldFormat(gold), 1,1,1)
		totalGold = totalGold + gold
	end
	GameTooltip:AddLine(' ')
	GameTooltip:AddDoubleLine('Total', st.StringFormat:GoldFormat(totalGold))

	GameTooltip:Show()
end

function INV:GetNumContainerSlots(container)
	local empty, total = 0, 0
	for _,bagID in pairs(container.bag_ids) do
		empty = empty + GetContainerNumFreeSlots(bagID)
		total = total + GetContainerNumSlots(bagID)
	end

	return empty, total
end

function INV:UpdateContainerItems(id)
	local container = self.containers[id]

	local sorted_inv = self:GetSortedInventory(id)

	for cat_name, cat_items in pairs(sorted_inv) do
		self:UpdateCategory(id, cat_name, cat_items)
	end

	self:FlushCategories(container, sorted_inv)

	self:UpdateContainerHeight(container)

	local empty, total = self:GetNumContainerSlots(container)
	container.footer.slots:SetFormattedText('%d/%d',total-empty, total)
end

function INV:UpdateContainerHeight(container)
	local height = container.header:GetHeight() + container.footer:GetHeight() + self.config.padding * 2

	local prev
	for i, category in ipairs(self.CATEGORY_FILTERS) do
		local category_frame = container.categories[category.name]
		if category_frame and category_frame:IsShown() then
			height = height + category_frame:GetHeight() + self.config.categoryspacing
			category_frame:ClearAllPoints()
			if prev then
				category_frame:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, -self.config.categoryspacing)
			else
				category_frame:SetPoint('TOPLEFT', container.header, 'BOTTOMLEFT', self.config.padding, -self.config.padding)
			end
			prev = category_frame
		end
	end

	-- Remove the last spacing
	height = height - self.config.categoryspacing
	
	container:SetHeight(height)
end

function INV:UpdateConfig(id)
	local container = self.containers[id]
	
	container:ClearAllPoints()
	container:SetPoint(unpack(self.config[id].position))

	container:SetWidth(self.config.padding * 2 + (self.config.buttonsize + self.config.buttonspacing) * self.config[id].perrow - self.config.buttonspacing)
	container:SetHeight(200)
	
	st:SetBackdrop(container, self.config.template)
end

local lastUpdate = 0
local interval = .01
function INV:UpdateHandler(event)
	-- Don't let the bags spam update, just wait
	local time = GetTime()
	-- if time - lastUpdate < interval then return end
	lastUpdate = time
	
	self:UpdateGold()
	self:UpdateContainerItems('bag')
	if self.containers.bank then
		self:UpdateContainerItems('bank')
	end
end

function INV:ToggleBags()
	if INV.containers.bag:IsShown() then
		INV:HideBags()
	else
		INV:ShowBags()
	end
end

function INV:ShowBags()
	INV.containers.bag:Show()
	INV:UpdateHandler()
	INV:UpdateCooldowns()
end

function INV:HideBags() 
	INV.containers.bag:Hide() 
	if INV.containers.bank and INV.containers.bank:IsShown() then
		INV.containers.bank:Hide()
		BankFrame:Hide()
	end
end

function INV:DisableBlizzardBank()
	BankFrame:ClearAllPoints()
	BankFrame:SetPoint('BOTTOMRIGHT', UIParent, 'TOPLEFT', -100, 100)
	BankFrame.SetPoint = function() end
end

function INV:OpenBank()
	if not self.containers.bank then
		self:CreateContainer('bank', 'Bank')
		self:DisableBlizzardBank()
		-- self:SecureHook('ContainerFrameItemButton_OnEnter', 'SetBankItemTooltip')
	end
	self:UpdateContainerItems('bank')
	self.containers.bank:Show()
end

function INV:CloseBank()
	self.containers.bank:Hide()
end

function INV:OnInitialize()
	self.config = st.config.profile.inventory
	if self.config.enable == false then return end

	if not st.config.realm.gold then st.config.realm.gold = {} end

	self:CreateContainer('bag', 'Bag')
	self.containers.bag:Hide()
end

function INV:OnEnable()
	ToggleBackpack		= INV.ToggleBags
	ToggleBag 			= INV.ToggleBags
	ToggleAllBags 		= INV.ToggleBags
	OpenAllBags 		= INV.ShowBags
	OpenBackpack 		= INV.ShowBags
	CloseAllBags 		= INV.HideBags
	CloseBackpack 		= INV.HideBags
	
	self:RegisterEvent('PLAYER_MONEY', 'UpdateGold')
	self:RegisterEvent('MERCHANT_SHOW', 'HandleMerchant')

	self:RegisterEvent('BAG_UPDATE', 'UpdateHandler')
	self:RegisterEvent('ITEM_LOCK_CHANGED', 'UpdateHandler')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', 'UpdateHandler')

	self:RegisterEvent('BANKFRAME_OPENED', 'OpenBank')
	self:RegisterEvent('BANKFRAME_CLOSED', 'CloseBank')
end