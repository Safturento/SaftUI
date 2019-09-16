local ADDON_NAME, st = ...
local AB = st:NewModule('Actionbars', 'AceHook-3.0', 'AceEvent-3.0')

BUTTON_PREFIXES = {
	'Action',
	'MultiBarBottomLeft',
	'MultiBarBottomRight',
	'MultiBarRight',
	'MultiBarLeft',
}

st.hotkey_subs = {
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

function AB:KillBlizzard()
	for _,frame in pairs({
		MainMenuBar,
		MainMenuBarArtFrame,
		OverrideActionBar,
		PossessBarFrame,
		ShapeshiftBarLeft,
		ShapeshiftBarMiddle,
		ShapeshiftBarRight,
		TalentMicroButtonAlert,
		CollectionsMicroButtonAlert,
		EJMicroButtonAlert,
		CharacterMicroButtonAlert
	}) do
		frame:UnregisterAllEvents()
		frame:SetParent(st.hidden_frame)
	end
end

function AB:CreateBars()
	self.bars = {}

	for i,prefix in ipairs(BUTTON_PREFIXES) do
		local bar = CreateFrame('frame', ADDON_NAME..'ActionBar'..i, UIParent, 'SecureHandlerStateTemplate')
		bar.slots = {}
		bar:SetID(i)
		bar.config = self.config[i]

		if i > 1 then
			_G[prefix]:SetParent(bar)
		end

		for j = 1, NUM_ACTIONBAR_BUTTONS do
			local name = prefix..'Button'..j
			local slot = _G[name]

			if i == 1 then
				slot:SetParent(bar)
			end

			slot.count = _G[name..'Count']
			slot.hotkey = _G[name..'HotKey']

			slot.count:ClearAllPoints()
			slot.count:SetPoint('BOTTOMRIGHT', -3, 3)

			slot.hotkey:ClearAllPoints()
			slot.hotkey:SetPoint('TOPRIGHT')
			slot.hotkey:SetPoint('TOPLEFT')
			slot.hotkey:SetJustifyH('RIGHT')


			bar.slots[j] = slot
		end
		
		self.bars[i] = bar
	end
end

function AB:UpdateConfig()
	for i, bar in ipairs(self.bars) do
		if not bar.config.enable then
			bar:Hide()
			return 
		else
			bar:Show()
		end

		st:SetBackdrop(bar, self.config.template)
		local width = bar.config.perrow * (bar.config.size + bar.config.spacing) - bar.config.spacing + bar.config.padding_x * 2
		local height = floor(bar.config.total/bar.config.perrow) * (bar.config.size + bar.config.spacing) - bar.config.spacing + bar.config.padding_y * 2
		bar:SetSize(width, height)
		bar:SetPoint(unpack(bar.config.position))
		
		local prev
		for j, slot in ipairs(bar.slots) do
			slot:SetSize(bar.config.size, bar.config.size)
			st.SkinActionButton(slot, { font = self.config.font, template = bar.config.template })
			self:UpdateHotkey(slot)
			slot:ClearAllPoints()

			if j == 1 then
				slot:SetPoint('TOPLEFT', bar, 'TOPLEFT', bar.config.padding_x, -bar.config.padding_y)
			elseif j % bar.config.perrow == 0 then
				slot:SetPoint('TOP', bar.slots[j - bar.config.perrow], 'BOTTOM', 0, -bar.config.spacing)
			else
				slot:SetPoint('LEFT', prev, 'RIGHT', bar.config.spacing, 0)
			end
			prev = slot
		end
	end
end

function AB:UpdateHotkey(slot)
	if not slot.hotkey then return end

	local text = slot.hotkey:GetText() or ''
	for long, short in pairs(st.hotkey_subs) do
		text = string.gsub(text, long, short)
	end
	slot.hotkey:SetText(text)
end

function AB:OnInitialize()
	self.config = st.config.profile.actionbars
	self:KillBlizzard()
	self:CreateBars()
	self:UpdateConfig()

	self:SecureHook('ActionButton_UpdateHotkeys', 'UpdateHotkey')
	self:SecureHook('PetActionButton_SetHotkeys', 'UpdateHotkey')
end