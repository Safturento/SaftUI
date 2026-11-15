local st = SaftUI
local INV = st:GetModule('Inventory')

local CloseBankFrame = C_Bank and C_Bank.CloseBankFrame or CloseBankFrame

function INV:ToggleBags()
	if IsOptionFrameOpen() then return end

	if self.containers.bag:IsShown() then
		self:HideBags()
	else
		self:ShowBags()
	end
end

function INV:ShowBags()
	if C_CurrencyInfo.IsAccountCharacterCurrencyDataReady and not (C_CurrencyInfo.IsAccountCharacterCurrencyDataReady()) then
		C_CurrencyInfo.RequestCurrencyDataForAccountCharacters()
	end
	self.containers.bag:Show()
	self:QueueUpdate(true)
	self:UpdateCooldowns()
	self:MovePlayerBagSlots()
end

-- Closes a bank window (the bank or the combined bank) that's open, and
-- Blizzard's bank with it.
local function CloseBankWindow(container)
	if container and container:IsShown() then
		container:Hide()
		HideUIPanel(BankFrame);
		CloseBankFrame();
	end
end

function INV:HideBags()
	self.containers.bag:Hide()
	for _, category in pairs(self.containers.bag.categories) do
		for _, slot in pairs(category.slots) do
			if slot.info and not slot.info.empty then
				C_NewItems.RemoveNewItem(slot.info.bagID, slot.info.slotID)
			end
		end
	end

	CloseBankWindow(self.containers.bank)
	CloseBankWindow(self.containers.combinedbank)
	if CurrencyTransferMenu and CurrencyTransferMenu:IsShown() then CurrencyTransferMenu:Hide() end
end

function INV:MovePlayerBagSlots()
	local bagSlotContainer = self.containers.bag.bagSlotContainer
	local BagSlots = bagSlotContainer.slots

	local prev
	for _, slot in pairs(BagSlots) do
		slot:ClearAllPoints()
		if prev then
			slot:SetPoint('BOTTOMLEFT', prev, 'BOTTOMRIGHT', self.config.buttonspacing, 0)
		else
			slot:SetPoint('BOTTOMLEFT', bagSlotContainer, 'BOTTOMLEFT', self.config.padding, self.config.padding)
		end
		prev = slot
	end
end

-- SaftUI's pieces of each bag slot, which is Blizzard's button (a plain ItemButton,
-- not secure, on both clients): nothing is written onto it (.agents/taint.md,
-- rule 1). Weak tables keyed by the slot.
local slotBackdrops = {} -- the backdrop of SaftUI's behind it (st:SetBackdropIn)
local slotIcons = {} -- its icon, where Blizzard gave the slot none of its own
local slotTextures = {} -- its hover, pushed and disabled textures
for _, weak in ipairs({ slotBackdrops, slotIcons, slotTextures }) do
	setmetatable(weak, { __mode = 'k' })
end

-- Core's Button text setting, read when a text follows it.
local function ButtonsFont() return st.config.profile.buttons.font end

-- Skins a bag slot as st:SkinActionButton skins a button with the profile's
-- Buttons settings, as a 'slot', without its fields: .backdrop, .thick, .hover,
-- .pushed and .disabled are kept in the tables above. The state textures are
-- made here and handed to the setters; RestyleBagSlot gives them their look.
-- This is a local copy of st:SkinActionButton, kept because that writes fields
-- onto the button (SaftUI-Core is not this file's to change). Its font part
-- should switch to st:ApplyButtonFonts(slot, config.font, true) once that Core
-- helper is in.
local function SkinBagSlot(slot)
	local config = st.config.profile.buttons
	local backdrop = st:SetBackdropIn(slotBackdrops, slot, config.theme, config.background, 'slot')

	local inset = config.trueSize and st:CalculateSpacing(slot) or 0
	if config.trueSize and backdrop then
		backdrop:ClearAllPoints()
		backdrop:SetAllPoints()
	end

	local name = slot:GetName() or ''
	local icon = _G[name .. 'Icon'] or _G[name .. 'IconTexture'] or slot.icon or slot.Icon
	local count = _G[name .. 'Count'] or slot.count or slot.Count
	local flash = _G[name .. 'Flash'] or slot.flash or slot.Flash
	local hotkey = _G[name .. 'HotKey'] or slot.hotkey or slot.HotKey
	local normal = _G[name .. 'NormalTexture'] or slot.NormalTexture
	local item_level = slot.item_level
	local bg = _G[name .. 'FloatingBG']
	local cooldown = _G[name .. 'Cooldown'] or slot.cooldown or slot.Cooldown

	for _, region in pairs({
		'Left', 'Middle', 'Right',
		'TopLeft', 'TopMiddle', 'TopRight',
		'MiddleLeft', 'MiddleMiddle', 'MiddleRight',
		'BottomLeft', 'BottomMiddle', 'BottomRight',
		'LeftSeparator', 'RightSeparator',
	}) do if slot[region] then slot[region]:SetAlpha(0) end end

	if bg then bg:SetTexture(nil) end

	if flash then
		flash:SetTexture('')
		st:SetInside(flash, inset)
	end

	if icon then
		st:SkinIcon(icon)
		st:SetInside(icon, inset)
	end

	st:Kill(slot.CircleMask)

	if config.font then
		local font_object = st:FontObject(config.font)

		for _, region in pairs({ slot:GetRegions() }) do
			if region:GetObjectType() == 'FontString' then
				st:FollowFont(region, ButtonsFont)
			end
		end

		if cooldown then st:SkinCooldown(slot, cooldown) end

		if count and type(count) == 'table' then
			count:ClearAllPoints()
			count:SetPoint('BOTTOMRIGHT', 2 - inset, 1 + inset)
			count:SetJustifyH('RIGHT')
			count:SetJustifyV('BOTTOM')
		end

		if item_level then
			item_level:ClearAllPoints()
			item_level:SetPoint('BOTTOMRIGHT', 2 - inset, 1 + inset)
			item_level:SetJustifyH('RIGHT')
			item_level:SetJustifyV('BOTTOM')
		end

		if hotkey then
			hotkey:ClearAllPoints()
			hotkey:SetPoint('TOPRIGHT', 2, 2)
			hotkey:SetPoint('TOPLEFT', 4, 0)
			hotkey:SetJustifyH('RIGHT')
			hotkey:SetJustifyV('TOP')
		end

		if slot.SetNormalFontObject then
			slot:SetNormalFontObject(font_object)
			slot:SetHighlightFontObject(font_object)
			slot:SetDisabledFontObject(font_object)
			slot:SetPushedTextOffset(0, 0)
		end
	end

	if normal and slot.SetNormalTexture then
		slot:SetNormalTexture('')
		st:SetInside(normal, inset)
	end

	-- The state textures are SaftUI's own, made on the slot and given to the
	-- setters. The hover stays in the layer the client shows only under the
	-- mouse (st.ThemeArt.HOVER_LAYER), in every look.
	local textures = slotTextures[slot]
	if not textures then
		textures = {}
		slotTextures[slot] = textures
		if slot.SetHighlightTexture then
			local hover = slot:CreateTexture(nil, 'OVERLAY')
			hover:SetTexture(st.BLANK_TEX)
			slot:SetHighlightTexture(hover)
			hover:SetDrawLayer(st.ThemeArt.HOVER_LAYER, 0)
			textures.hover = hover
		end
		if slot.SetPushedTexture then
			local pushed = slot:CreateTexture(nil, 'OVERLAY')
			pushed:SetTexture(st.BLANK_TEX)
			pushed:SetVertexColor(0, 0, 0, .1)
			slot:SetPushedTexture(pushed)
			pushed:SetDrawLayer('OVERLAY', 0)
			textures.pushed = pushed
		end
		if slot.SetDisabledTexture then
			local disabled = slot:CreateTexture(nil, 'OVERLAY')
			disabled:SetTexture(st.BLANK_TEX)
			disabled:SetVertexColor(0, 0, 0, .4)
			slot:SetDisabledTexture(disabled)
			textures.disabled = disabled
		end
	end
	if textures.disabled then st:SetInside(textures.disabled, inset) end
end

-- The hover is the accent (a follower of Theme > Accent, on the slot).
local function PaintBagSlotHover(slot)
	local hover = slot:GetHighlightTexture()
	if hover then hover:SetVertexColor(st:Color('accent'):GetRGB()) end
end

-- Re-apply SaftUI styling on top of Blizzard's BaseBagSlotButtonMixin:UpdateTextures.
local function RestyleBagSlot(slot)
	slot:GetNormalTexture():SetAlpha(0)
	if slot.SlotHighlightTexture then slot.SlotHighlightTexture:SetAlpha(0) end

	-- GetHighlightTexture/GetPushedTexture are SaftUI's hover/pushed textures from
	-- SkinActionButton; Blizzard overwrites their atlas, size, anchors and blending.
	local hover = slot:GetHighlightTexture()
	hover:SetTexture(st.BLANK_TEX)
	hover:SetVertexColor(st:Color('accent'):GetRGB())
	hover:SetBlendMode('ADD')
	hover:SetAlpha(1)
	hover:ClearAllPoints()
	hover:SetAllPoints(slot.icon or slotIcons[slot])

	local pushed = slot:GetPushedTexture()
	pushed:SetTexture(st.BLANK_TEX)
	pushed:SetVertexColor(0, 0, 0, .1)
	pushed:ClearAllPoints()
	pushed:SetAllPoints(slot.icon or slotIcons[slot])
end

function INV:InitializePlayerBagSlots()

	st:Kill(MainMenuBarBackpackButton)
	st:Kill(BagBarExpandToggle)

	local BagSlots = {}
	for i=0,3 do
		local slot = _G['CharacterBag'..i..'Slot']
		if not slot.icon then slotIcons[slot] = _G['CharacterBag'..i..'SlotIconTexture'] end
		tinsert(BagSlots, slot)
	end

	if not CharacterReagentBag0Slot.icon then slotIcons[CharacterReagentBag0Slot] = CharacterReagentBag0SlotIconTexture end
	tinsert(BagSlots, CharacterReagentBag0Slot)

	-- Forever has a keyring bag button on the bags bar
	if KeyRingButton and C_ActionBar.ShouldShowKeyring and C_ActionBar.ShouldShowKeyring() then
		tinsert(BagSlots, KeyRingButton)
	end

	-- The slots get reparented into our container below; hide what's left of
	-- Blizzard's bags bar (border art and the dividers it draws between slots).
	-- Alpha rather than Kill, since BagsBar is an Edit Mode system frame.
	if BagsBar then
		BagsBar:SetAlpha(0)
	end

	local bagSlotContainer = st:CreateFrame('frame', 'BagSlotFrame', self.containers.bag)
	bagSlotContainer:Hide()
	bagSlotContainer:SetSize(
		self:GetButtonWidth() * #BagSlots + self.config.buttonspacing * (#BagSlots - 1) + self.config.padding * 2,
		self:GetButtonHeight() + self.config.padding * 2)
	st:SetBackdrop(bagSlotContainer, 'theme', 'solid', 'panel')
	self:PlaceBagSlotBar(self.containers.bag, bagSlotContainer)

	bagSlotContainer.slots = BagSlots
	self:CreateSlotToggle(self.containers.bag, bagSlotContainer, 'BagSlotToggle')


	for _,slot in pairs(BagSlots) do
		slot.IconBorder:SetAlpha(0)
		slot:SetParent(bagSlotContainer)
		slot:SetSize(self:GetButtonWidth(), self:GetButtonHeight())
		-- Blizzard's button: the Blizzard theme makes none of its art on it.
		st:MarkForeign(slot)
		SkinBagSlot(slot)

		st:Kill(slot.AnimIcon)

		-- Blizzard's UpdateTextures runs on load and on every bag change, re-applying
		-- its frame atlas to the normal texture and its atlases to our hover/pushed
		-- textures. Undo that after every call, and once now for the initial state.
		if slot.UpdateTextures then
			self:SecureHook(slot, 'UpdateTextures', RestyleBagSlot)
		end
		RestyleBagSlot(slot)
		-- Once, not on every UpdateTextures: the hover follows the accent.
		st:FollowColor(slot, 'accent', nil, PaintBagSlotHover)

		-- With the bar collapsed Blizzard hides the slots; ours should always show.
		if slot.SetBarExpanded then
			self:SecureHook(slot, 'SetBarExpanded', function(slot, isExpanded)
				if not isExpanded then slot:Show() end
			end)
		end
	end

	self.containers.bag.bagSlotContainer = bagSlotContainer

	self:MovePlayerBagSlots()
	self:RegisterEvent('BAG_SLOT_FLAGS_UPDATED', 'MovePlayerBagSlots')

	-- BagsBar:Layout re-anchors every bag slot back onto Blizzard's bar (on load,
	-- Edit Mode changes and bar expand/collapse), so move them back after it.
	if BagsBar and BagsBar.Layout then
		self:SecureHook(BagsBar, 'Layout', 'MovePlayerBagSlots')
	end

	-- The expand/collapse layout doesn't go through that hook. BagsBar registered
	-- its original Layout as an EventRegistry callback at load, before the hook
	-- existed, and MainMenuBarBagManager fires it whenever an item goes on or off
	-- the cursor (the bar expands while you hold one). Put the slots back on that
	-- event too: now, and again next frame, since the registry runs callbacks in
	-- no set order and Blizzard's may come after ours.
	if EventRegistry then
		EventRegistry:RegisterCallback('MainMenuBarManager.OnExpandChanged', function()
			INV:MovePlayerBagSlots()
			C_Timer.After(0, function() INV:MovePlayerBagSlots() end)
		end, self)
	end
end

-- The footer's text from the counts last read (container.slotCounts: used and
-- total, then the reagent bag's used and total): the second count, the reagent
-- bag's, is left out when there is none equipped instead of showing a useless
-- 0/0, and is drawn in Text > Success.
local function SetFooter(container)
	local counts = container.slotCounts
	local text = ('%d/%d '):format(counts[1], counts[2])
	if counts[4] > 0 then
		text = text .. INV.TintText(('%d/%d '):format(counts[3], counts[4]), 'success')
	end
	container.footer.slots:SetText(text)
end

local function UpdateContainerSlots(container)
	local empty, total
	empty, total = INV:GetNumContainerSlots({
        Enum.BagIndex.Backpack,
        Enum.BagIndex.Bag_1,
        Enum.BagIndex.Bag_2,
        Enum.BagIndex.Bag_3,
        Enum.BagIndex.Bag_4,
     })
	local counts = container.slotCounts or {}
	container.slotCounts = counts
	counts[1], counts[2] = total - empty, total

	empty, total = INV:GetNumContainerSlots({
        Enum.BagIndex.ReagentBag,
    })
	counts[3], counts[4] = total - empty, total

	SetFooter(container)
end

-- Text > Success changed: the footer's reagent count set again from the counts
-- last read (no bag is asked, nothing laid out).
function INV:ColorBagFooter()
	local container = self.containers.bag
	if container and container.slotCounts and container.footer then SetFooter(container) end
end

function INV:InitializePlayerBags()
	local container = self:CreateContainer('bag', INVTYPE_BAG)
	container:Hide()

	self:InitializePlayerBagSlots()
	self:InitializeAllCategories('bag')
	container.UpdateContainerSlots = UpdateContainerSlots

	self:SecureHook('OpenAllBags', 'ShowBags')
	self:SecureHook('CloseAllBags', 'HideBags')
	self:SecureHook('ToggleBag', 'ToggleBags')
	self:SecureHook('ToggleAllBags', 'ToggleBags')

	self:SecureHook('ToggleBackpack', 'ToggleBags')
end
