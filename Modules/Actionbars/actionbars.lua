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

		local width = min(bar.config.total, bar.config.perrow) * (bar.config.width + bar.config.spacing) - bar.config.spacing
		local height = ceil(bar.config.total/bar.config.perrow) * (bar.config.height + bar.config.spacing) - bar.config.spacing
		
		bar:SetSize(width, height)
		bar:SetPoint(st:UnpackPoint(bar.config.position))

		if bar.config.backdrop.enable then
			st:SetBackdrop(bar, bar.config.backdrop.template)

			local height, width
			bar.backdrop:ClearAllPoints()
			if bar.config.backdrop.conform then
				width = bar:GetWidth() + bar.config.backdrop.padding * 2
				height = bar:GetHeight() + bar.config.backdrop.padding * 2
				
				bar.backdrop:SetPoint('TOPLEFT', bar, 'TOPLEFT', -bar.config.backdrop.padding, bar.config.backdrop.padding)
			else
				width = bar.config.backdrop.width * (bar.config.width + bar.config.spacing) - bar.config.spacing + bar.config.backdrop.padding * 2

				height = bar.config.backdrop.height * (bar.config.height + bar.config.spacing) - bar.config.spacing + bar.config.backdrop.padding * 2
			
				bar.backdrop:SetPoint(bar.config.backdrop.anchor, bar, -bar.config.backdrop.padding, -bar.config.backdrop.padding)
			end
			
			bar.backdrop:SetSize(width, height)
		else
			st:SetBackdrop(bar, 'none')
		end
		
		

		local prev
		for j, slot in ipairs(bar.slots) do
			slot:SetSize(bar.config.width, bar.config.height)
			st.SkinActionButton(slot, { font = self.config.font, template = bar.config.template })
			if slot.Border then
				slot.Border:ClearAllPoints()
			end

			self:UpdateHotkey(slot)
			slot:ClearAllPoints()

			if j > bar.config.total then
				slot:SetPoint('BOTTOMLEFT', UIParent, 'TOPRIGHT', 500, 500)
			elseif j == 1 then
				slot:SetPoint('TOPLEFT', bar)
			elseif j % bar.config.perrow == 1 or bar.config.perrow == 1 then
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

function AB:UpdateActionButton(self)
	if not self.backdrop then return end
	
	if IsEquippedAction(self.action) then
		self.backdrop:SetBackdropBorderColor(unpack(st.config.profile.colors.button.green))
	else
		st:SetTemplate(self.backdrop, self.backdrop.template)
	end
end

function AB:GetConfigTable()
	local config = st.config.profile.actionbars

	local config_table = {
		name = 'Action Bars',
		type = 'group',
		args = {
			general = {
				name = '',
				type = 'group',
				inline = true,
				args = {
					font = st.CF.generators.font(0),
					template = st.CF.generators.template(1),
				}
			}
		}
	}

	for i=1, 5 do
		config_table.args['bar'..i] = {
			name = 'Bar '..i,
			type = 'group',
			get = function(info) 
				return config[i][info[#info]]
			end,
			set = function(info, value)
				config[i][info[#info]] = value
				self:UpdateConfig()
			end,
			args = {
				enable = st.CF.generators.enable(0),
				width = st.CF.generators.range(1, 'Button width'),
				height = st.CF.generators.range(2, 'Button height'),
				spacing = st.CF.generators.range(3, 'Button spacing', 1, 20, 1),
				total = st.CF.generators.range(4, 'Total buttons', 1, 12, 1),
				perrow = st.CF.generators.range(5, 'Buttons per row', 1, 12, 1),
				position = st.CF.generators.position(6, true, 
					function(key) return config[i].position[key] end,
					function(key, value) 
						config[i].position[key] = value
						self:UpdateConfig()
					end
				),
				backdrop = {
					name = 'Backdrop',
					type = 'group',
					inline = true,
					get = function(info) 
						return config[i].backdrop[info[#info]]
					end,
					set = function(info, value)
						config[i].backdrop[info[#info]] = value
						self:UpdateConfig()
					end,
					args = {
						enable = st.CF.generators.enable(0),
						template = st.CF.generators.template(1),
						conform = st.CF.generators.toggle(2, 'Conform'),
						manual = {
							name = 'Manual',
							type = 'group',
							set = function(info, value)
								config[i].backdrop[info[#info]] = value		
								self:UpdateConfig()
							end,
							get = function(info) return config[i].backdrop[info[#info]] end,
							hidden = function(info) return config[i].backdrop.conform end,
							args = {
								width = st.CF.generators.range(1, 'Width', 1, 36, 1),
								height = st.CF.generators.range(2, 'Height', 1, 36, 1),
								padding = st.CF.generators.range(3, 'Padding', 0, 30, 1),
								anchor = {
									order = 1,
									name = 'Anchor', 
									type = 'select',
									values = st.FRAME_ANCHORS,
									width = 0.65,
								},
							}
						}

					}
				}
			},
		}
	end

	return config_table
end

function AB:OnInitialize()
	self.config = st.config.profile.actionbars
	self:KillBlizzard()
	self:CreateBars()
	self:UpdateConfig()

	self:SecureHook('ActionButton_Update', 'UpdateActionButton')
	self:SecureHook('ActionButton_UpdateHotkeys', 'UpdateHotkey')
	self:SecureHook('PetActionButton_SetHotkeys', 'UpdateHotkey')
end