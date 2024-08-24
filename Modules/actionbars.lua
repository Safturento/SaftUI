local st = SaftUI
local AB = st:NewModule('Actionbars')

AB.BUTTON_PREFIXES = {
	'Action',
	'MultiBarBottomLeft',
	'MultiBarBottomRight',
	'MultiBarRight',
	'MultiBarLeft',
}

AB.HOTKEY_SUBS = {
	["(s%-)"] = "S",
	["(a%-)"] = "A",
	["(c%-)"] = "C",
	[KEY_MOUSEWHEELDOWN] = "MDn",
	[KEY_MOUSEWHEELUP] = "MUp",
	[KEY_BUTTON3] = "M3",
	[KEY_BUTTON4] = "M4",
	[KEY_BUTTON5] = "M5",
	[KEY_MOUSEWHEELUP] = "MU",
	[KEY_MOUSEWHEELDOWN] = "MD",
	[KEY_NUMPAD0] = "N0",
	[KEY_NUMPAD1] = "N1",
	[KEY_NUMPAD2] = "N2",
	[KEY_NUMPAD3] = "N3",
	[KEY_NUMPAD4] = "N4",
	[KEY_NUMPAD5] = "N5",
	[KEY_NUMPAD6] = "N6",
	[KEY_NUMPAD7] = "N7",
	[KEY_NUMPAD8] = "N8",
	[KEY_NUMPAD9] = "N9",
	[KEY_NUMPADDECIMAL] = "N.",
	[KEY_NUMPADDIVIDE] = "N/",
	[KEY_NUMPADMINUS] = "N-",
	[KEY_NUMPADMULTIPLY] = "N*",
	[KEY_NUMPADPLUS] = "N+",
	[KEY_PAGEUP] = "PU",
	[KEY_PAGEDOWN] = "PD",
	[KEY_SPACE] = "SpB",
	[KEY_INSERT] = "Ins",
	[KEY_HOME] = "Hm",
	[KEY_DELETE] = "Del",
	[KEY_INSERT_MAC] = "Hlp",
}

function AB:SkinActionButtons()
	self.bars = {}

	for barIndex, prefix in ipairs(self.BUTTON_PREFIXES) do
		local bar = {}
		local slot, name
		for slotIndex = 1, NUM_ACTIONBAR_BUTTONS do
			name = prefix..'Button'.. slotIndex
			slot = _G[name]
			self:SecureHook(slot, 'UpdateHotkeys', 'UpdateHotkey')
			self:SecureHook(slot, 'Update', 'UpdateActionButton')
			self:SecureHook(slot, 'UpdateButtonArt', 'UpdateActionButton')

			st:Kill(slot.SlotArt)
			slot.count = _G[name..'Count']
			slot.hotkey = _G[name..'HotKey']

			bar[slotIndex] = slot
		end

		self.bars[barIndex] = bar
	end

	--self:InitializePetBar()
end

function AB:InitializePetBar()
	local slot, name
	local bar = {}
	for i=1, NUM_PET_ACTION_SLOTS do
		name = 'PetActionButton'..i
		slot = _G[name]
		slot:SetParent(bar)
		slot.count = _G[name..'Count']
		slot.hotkey = _G[name..'HotKey']
		local tex2 = _G[name..'NormalTexture2']
		st:Kill(tex2)

		bar[i] = slot
	end
	self.bars.pet = bar
end

function AB:UpdateConfig()
	for _, bar in pairs(self.bars) do
        for _, slot in ipairs(bar) do
            st:SkinActionButton(slot)
            if slot.Border then
                slot.Border:ClearAllPoints()
            end
			AB:UpdateActionButton(slot)
            self:UpdateHotkey(slot)
        end
    end
end

function AB:UpdateHotkey(slot)
	if not slot.hotkey then return end

	local text = slot.hotkey:GetText() or ''
	for long, short in pairs(self.HOTKEY_SUBS) do
		text = string.gsub(text, long, short)
	end

	slot.hotkey:ClearAllPoints()
	slot.hotkey:SetPoint('TOPRIGHT', 2, 2)
	slot.hotkey:SetJustifyH('RIGHT')
	slot.hotkey:SetJustifyV('TOP')

	slot.hotkey:SetText(text)
end

function AB:UpdateActionButton(slot)
	if InCombatLockdown() then return end

	if not slot.backdrop then return end

	if slot.NormalTexture then slot.NormalTexture:SetTexture('') end

	slot.IconMask:Hide()
	slot.cooldown:SetAllPoints()
	slot.Flash:SetAllPoints()
	slot:SetSize(39, 39)

	if IsEquippedAction(slot.action) then
		slot.backdrop:SetBackdropBorderColor(unpack(st.config.profile.colors.button.green))
	else
		if slot.backdrop then
			st:SetBackdrop(slot, slot.backdrop.template)
		end
	end
end

function AB:OnInitialize()
	self.config = st.config.profile.actionbars

	st:Kill(MainMenuBar.EndCaps)
	st:Kill(MainMenuBar.BorderArt)
	st:Kill(MainMenuBar.EndCaps.LeftEndCap)
	st:Kill(MainMenuBar.EndCaps.RightEndCap)

	self:SkinActionButtons()
	self:UpdateConfig()
end