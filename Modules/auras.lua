local ADDON_NAME, st = ...

local AU = st:NewModule('Auras', 'AceHook-3.0', 'AceEvent-3.0')

function AU:SkinAuraButton(button, button_base)
	local button_name = button:GetName()
	button.icon = _G[button_name..'Icon']
	button.border = _G[button_name..'Border']
	button.duration = _G[button_name..'Duration']
	-- button.bar = CreateFrame('StatusBar')

	if button.border then
		st:Kill(button.border)
	end

	if not button.bar then
		button.bar = CreateFrame('StatusBar', nil, button)
		button.bar:SetStatusBarTexture(st.BLANK_TEX)
	end
	if self.config.timer_bar.enable then
		local anchor, relAnchor, xoff, yoff = unpack(self.config.timer_bar.position)
		button.bar:ClearAllPoints()
		button.bar:SetPoint(anchor, button, relAnchor, xoff, yoff)
		if not self.config.color_time then
			button.bar:SetStatusBarColor(unpack(self.config.timer_bar.custom_color))
		end
		button.bar:SetSize(self.config.timer_bar.width, self.config.timer_bar.height)
		st:SetBackdrop(button.bar, self.config.timer_bar.template)
		button.bar:Show()
	elseif button.bar then
		button.bar:Hide()
	end

	st.SkinActionButton(button, self.config)

	button.count:SetDrawLayer('OVERLAY', 99)

	if self.config.timer_text.enable then
		local anchor, relAnchor, xoff, yoff = unpack(self.config.timer_text.position)
		button.duration:ClearAllPoints()
		button.duration:SetPoint(anchor, button, relAnchor, xoff, yoff)
		button.duration:Show()
	else
		button.duration:Hide()
	end

	button.skinned = true
end


function AU:AuraButton_Update(button_base, index, filter)
	local name, texture, count, debuffType, duration, expirationTime, _, _, _, spellId, _, _, _, _, timeMod = UnitAura('player', index, filter)

	local button = _G[button_base..index]
	if not button then return end
	
	local helpful = (filter == "HELPFUL")
	
	button.total_time = duration
	
	if not button.skinned then
		self:SkinAuraButton(button, button_base, filter)
	end
	
	if duration and duration > 0 then
		button.bar:Show()
	else
		button.bar:Hide()
	end

	if name and not helpful then
		local color = DebuffTypeColor[debuffType or 'none'];
		button.backdrop:SetBackdropBorderColor(color.r, color.g, color.b);
	end

	self[helpful and 'Buffs' or 'Debuffs'][index] = button
end

function AU:UpdateConfig()
	for i,aura in pairs(self.Buffs) do
		self:SkinAuraButton(aura, 'BuffButton')
	end
	
	for i,aura in pairs(self.Buffs) do
		self:SkinAuraButton(aura, 'DebuffButton')
	end

	for i=1, NUM_TEMP_ENCHANT_FRAMES do
		self:SkinAuraButton(_G['TempEnchant'..i], 'TempEnchant')
	end
end

function AU:UpdateDebuffAnchor()
	if not DebuffButton1 then return end
	DebuffButton1:ClearAllPoints()
	DebuffButton1:SetPoint(unpack(self.config.debuffs.position))
end

local function PositionNextBuff(prev, spacing, direction)
	local rel = st.INVERSE_ANCHORS[direction]

	local xoff, yoff = -spacing, 0
	if direction == 'RIGHT' then
		xoff, yoff = spacing, 0
	elseif direction == 'BOTTOM' then
		xoff, yoff = 0, -spacing
	elseif direction == 'TOP' then
		xoff, yoff = 0, spacing
	end		
	return rel, prev, direction, xoff, yoff
end

function AU:BuffFrame_UpdateAllBuffAnchors()
	local prev
	
	if BuffFrame.numEnchants > 0 then
		TemporaryEnchantFrame:SetSize(self.config.size, self.config.size)
		TemporaryEnchantFrame:ClearAllPoints()
		TemporaryEnchantFrame:SetPoint(unpack(self.config.buffs.position))

		for i=1, BuffFrame.numEnchants do
			local enchant = _G['TempEnchant'..i]
			enchant:ClearAllPoints()
			if i == 1 then
				enchant:SetPoint('TOPRIGHT', TemporaryEnchantFrame)
			else
				enchant:SetPoint(PositionNextBuff(prev, self.config.spacing, self.config.buffs.growth_direction))
			end
			
			prev = enchant
		end
	end

	for i = 1, BUFF_ACTUAL_DISPLAY do
		buff = _G["BuffButton"..i]
		
		buff:ClearAllPoints()
		if BuffFrame.numEnchants == 0 and i == 1 then
			buff:SetPoint(unpack(self.config.buffs.position))
		else
			buff:SetPoint(PositionNextBuff(prev, self.config.spacing, self.config.buffs.growth_direction))
		end

		prev = buff
	end
end

function AU:TemporaryEnchantFrame_Update()
	-- for i=1, BuffFrame.numEnchants do
	-- 	self:AuraButton_Update('TempEnchant', i)
	-- end
end

function AU:AuraButton_UpdateDuration(button, remaining)
	if button.bar and button.total_time and button.total_time > 0 then
		button.bar:SetMinMaxValues(0, button.total_time)
		button.bar:SetValue(remaining)
	end
end

function AU:OnEnable()
	self.config = st.config.profile.auras

	self.Buffs = {}
	self.Debuffs = {}

	self:UpdateConfig()

	self:SecureHook('DebuffButton_UpdateAnchors', 'UpdateDebuffAnchor')
	self:SecureHook('AuraButton_Update')	
	self:SecureHook('BuffFrame_UpdateAllBuffAnchors')
	self:SecureHook('TemporaryEnchantFrame_Update')
	self:SecureHook('AuraButton_UpdateDuration')
end