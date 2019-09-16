local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local AURAS = {'Buffs', 'Debuffs'}

function UF.PostCreateAura(auras, button)

	-- st:SetBackdrop(button, auras.config.template)
	-- st:SkinIcon(button.icon, auras.config)
	-- button.icon:TrimIcon()
	-- -- button.icon:SetPoints(button)
	-- button.count:SetFontObject(st:GetFont(auras.config.font)) 

	-- button.cooldown = _G[button:GetName()..'Cooldown']
	-- button.cooldown:Skin()
end

function UF.PostUpdateAura(auras, unit, button, index, position, duration, expiration, debuffType, isStealable)
	-- if isStealable then
	-- 	button:SetBackdropBorderColor(1, 1, 1)
	-- else
	-- 	button:SetBackdropBorderColor(unpack(st.config.template.actionbutton.bordercolor))
	-- end
end

local function UpdateConfig(self)
	for i,aura_type in ipairs(AURAS) do
		local auras = self[aura_type]
		if auras.config.enable then
			auras:Show()
		else
			auras:Hide()
		end

		local num_rows = ceil(auras.config.max/auras.config.per_row)

		auras:SetHeight(num_rows*auras.config.size + (num_rows-1)*auras.config.spacing)
		auras:SetWidth(auras.config.per_row*auras.config.size + (auras.config.per_row-1)*auras.config.spacing)
		local point, relativePoint, xoffset, yoffset = unpack(auras.config.position)
		auras:SetPoint(point, self, relativePoint, xoffset, yoffset)	
	
		auras.size = auras.config.size
		auras.num = auras.config.max
		auras.numRow = auras.config.per_row
		auras.spacing = auras.config.spacing
		auras.initialAnchor = auras.config.initial_anchor
		auras['growth-y'] = auras.config.vertical_growth
		auras['growth-x'] = auras.config.horizontal_growth
		auras.onlyShowPlayer = auras.config.self_only
	end

end

local function Constructor(self)
	for i,aura_type in ipairs(AURAS) do
		local auras = CreateFrame('Frame', self:GetName()..aura_type, self)
		auras.config = self.config.auras[string.lower(aura_type)]
		auras.PostCreateIcon = UF.PostCreateAura
		auras.PostUpdateIcon = UF.PostUpdateAura

		auras.disableCooldown = true
		self[aura_type] = auras
	end
end

local function GetConfigTable(self)
	return {
		type = 'group',
		name = 'Auras',
		get = function(info)
			return self.config.auras[info[#info]]
		end,
		set = function(info, value)
			self.config.auras[info[#info]] = value
			UF:UpdateConfig(self.unit, 'Auras')
		end,
		args = {
		}
	}
end

UF:RegisterElement('Auras', Constructor, UpdateConfig, GetConfigTable)
