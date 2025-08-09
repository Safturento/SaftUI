local st = SaftUI
local INV = st:NewModule('Inventory')

local BAG_IDS
if st.retail then
	BAG_IDS = {
		['bag'] = {
            Enum.BagIndex.Backpack,
            Enum.BagIndex.Bag_1,
            Enum.BagIndex.Bag_2,
            Enum.BagIndex.Bag_3,
            Enum.BagIndex.Bag_4,
            Enum.BagIndex.ReagentBag,
         },
		['bank'] = {
            Enum.BagIndex.CharacterBankTab_1,
            Enum.BagIndex.CharacterBankTab_2,
            Enum.BagIndex.CharacterBankTab_3,
            Enum.BagIndex.CharacterBankTab_4,
            Enum.BagIndex.CharacterBankTab_5,
            Enum.BagIndex.CharacterBankTab_6,
        },
		['warband'] = {
            Enum.BagIndex.AccountBankTab_1,
            Enum.BagIndex.AccountBankTab_2,
            Enum.BagIndex.AccountBankTab_3,
            Enum.BagIndex.AccountBankTab_4,
            Enum.BagIndex.AccountBankTab_5,
            Enum.BagIndex.AccountBankTab_6,
        },
		['combinedbank'] = {
            Enum.BagIndex.CharacterBankTab_1,
            Enum.BagIndex.CharacterBankTab_2,
            Enum.BagIndex.CharacterBankTab_3,
            Enum.BagIndex.CharacterBankTab_4,
            Enum.BagIndex.CharacterBankTab_5,
            Enum.BagIndex.CharacterBankTab_6,
            Enum.BagIndex.AccountBankTab_1,
            Enum.BagIndex.AccountBankTab_2,
            Enum.BagIndex.AccountBankTab_3,
            Enum.BagIndex.AccountBankTab_4,
            Enum.BagIndex.AccountBankTab_5,
            Enum.BagIndex.AccountBankTab_6,
        }
	}
else
	BAG_IDS = {
		['bag'] = { 0, 1, 2, 3, 4 },
		['bank'] = { -1, 5, 6, 7, 8, 9, 10, 11 }
	}
end

INV.bagIds = BAG_IDS

INV.containers = {}
INV.OnUseItems = {}

function INV:SelectBankCategory(clickedHeader)
	local selectedContainer = clickedHeader:GetParent()
    if selectedContainer.id == 'warband' then
		BankFrame.BankPanel:SetBankType(Enum.BankType.Character)
	elseif selectedContainer.id == 'bank' then
        BankFrame.BankPanel:SetBankType(Enum.BankType.Account)
	end

    for containerName, container in pairs(self.containers) do
        if containerName == selectedContainer.id then
            container.backdrop:SetBackdropBorderColor(unpack(st.config.profile.colors.button.blue))
        else
            st:SetBackdrop(container, self.config.template)
        end
    end
end

function INV:UpdateConfig(id)
	if not id then
		for containerId, _ in pairs(self.containers) do
			self:UpdateConfig(containerId)
		end
	end

	local container = self.containers[id]

	container:ClearAllPoints()
	container:SetPoint(unpack(self.config[id].position))

    for i=1, self.config[id].maxColumns do
        local column = container.columns[i]
        if not column then
            column = st:CreateFrame('Frame', container:GetName() .. 'Column'..i, container.scrollFrame)
            container.columns[i] = column
        end

        column:SetWidth((self.config.buttonwidth + self.config.buttonspacing) * self.config[id].perrow - self.config.buttonspacing)
        column:ClearAllPoints()
        if i == 1 then
            column:SetPoint('TOPLEFT', container.scrollFrame.ScrollChild, 'TOPLEFT')
        else
            column:SetPoint('TOPLEFT', container.columns[i-1], 'TOPRIGHT', self.config.buttonspacing, 0)
        end
    end

	local inner_width = (self.config.buttonwidth + self.config.buttonspacing) * self.config[id].perrow - self.config.buttonspacing

	container:SetWidth(self.config.padding * 2 + inner_width)
	container:SetHeight(200)

	for _, category in pairs(container.categories) do
		category:SetWidth(inner_width)
	end
	if container.search then
		container.search:SetWidth(inner_width)
		st:SkinEditBox(container.search, self.config.template, self.config.fonts.titles)
	end

	st:SetBackdrop(container, self.config.template)
end

function INV:UpdateVisibleContainers()
	for containerName, container in pairs(self.containers) do
		if container:IsShown() then
			self:UpdateContainer(containerName)
		end
	end
	self:UpdateSearchFilter(self.containers.bag.search, false)
end

function INV:UpdateHandler(_, elapsed)
	if self.IS_UPDATING or not self.NEED_UPDATE then return end

	self.IS_UPDATING = true
	self.NEED_UPDATE = false
	self:UpdateGold()
	self:UpdateVisibleContainers()
	self.IS_UPDATING = false
end

function INV:QueueUpdate()
	self.NEED_UPDATE = true
end

function INV:ADDON_LOADED(event, addon)
	if addon == 'ItemRackOptions' then
		self:SecureHook(ItemRackOpt, 'SaveSet', 'UpdateItemRackCategories')
		self:SecureHook(ItemRackOpt, 'DeleteSet', 'UpdateItemRackCategories')
	end
end


function INV:OnEnable()
	self.config = st.config.profile.inventory
	if self.config.enable == false then return end

	if not self.config.filters then
		self.config.filters = {}
	end

	if not self.config.filters.categories then
        self.config.filters.categories = {}
    end

	self:InitializeTooltipScanner()
	self:InitializePlayerBags()

	--ToggleBackpack		= INV.ToggleBags
	--ToggleBag 			= INV.ToggleBags
	--ToggleAllBags 		= INV.ToggleBags
	--OpenAllBags 		= INV.ShowBags
	--OpenBackpack 		= INV.ShowBags
	--OpenBag 			= INV.ShowBags
	--CloseAllBags 		= INV.HideBags
	--CloseBackpack 		= INV.HideBags
	--CloseBag			= INV.HideBags

	for _,frame in pairs({ BankFrame, ContainerFrameCombinedBags }) do
		if frame then
			frame:UnregisterAllEvents()
			frame:SetScript('OnShow', nil)
			frame:SetScript('OnHide', nil)
			frame:SetParent(st.HiddenFrame)
			frame:ClearAllPoints()
			frame:SetPoint("BOTTOM")
		end
	end

	if ContainerFrameCombinedBags then
		ContainerFrameCombinedBags:RegisterEvent('BAG_CONTAINER_UPDATE')
	end


	if ItemRack then
		self:UpdateItemRackCategories()
	end

	-- Make sure the slots are all created immediately intead of on first open
	-- We do this to avoid tainting all of the slots when the bag is first opened
	-- while in combat
	self:UpdateContainer('bag')

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent('PLAYER_MONEY', 'UpdateGold')
	self:RegisterEvent('MERCHANT_SHOW', 'HandleMerchant')

	self:RegisterEvent('BAG_UPDATE', 'QueueUpdate')
	self:RegisterEvent('BAG_UPDATE_DELAYED', 'QueueUpdate')
	self:RegisterEvent('BAG_CONTAINER_UPDATE', 'QueueUpdate')
	self:RegisterEvent('BAG_NEW_ITEMS_UPDATED', 'QueueUpdate')
	self:RegisterEvent('ITEM_LOCK_CHANGED', 'QueueUpdate')
	self:RegisterEvent('PLAYERBANKSLOTS_CHANGED', 'QueueUpdate')
	self:RegisterEvent('GET_ITEM_INFO_RECEIVED', 'QueueUpdate')

	if st.retail and self.config.combinedBank then
		self:RegisterEvent('BANKFRAME_OPENED', 'OpenCombinedBank')
		self:RegisterEvent('BANKFRAME_CLOSED', 'CloseCombinedBank')
	else
		self:RegisterEvent('BANKFRAME_OPENED', 'OpenBank')
		self:RegisterEvent('BANKFRAME_CLOSED', 'CloseBank')
	end

	self.updater = CreateFrame('frame')
	self:HookScript(self.updater, 'OnUpdate', 'UpdateHandler')
end