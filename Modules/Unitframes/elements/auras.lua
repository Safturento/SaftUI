local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local AURAS = {'Buffs', 'Debuffs'}

function UF.PostCreateAura(auras, button)

	st:SetBackdrop(button, auras.config.template)
	st:SkinIcon(button.icon)
	button.count:SetFontObject(st:GetFont(auras.config.font)) 

	-- button.cooldown = _G[button:GetName()..'Cooldown']
	-- button.cooldown:Skin()
end

function UF.PostUpdateAura(auras, unit, button, index, position, duration, expiration, debuffType, isStealable)
	if auras.config.desaturate_others and (not button.isPlayer) then
		button.icon:SetDesaturated(1)
	end
	-- if isStealable then
	-- 	button:SetBackdropBorderColor(1, 1, 1)
	-- else
	-- 	button:SetBackdropBorderColor(unpack(st.config.template.actionbutton.bordercolor))
	-- end
end

local function UpdateConfig(self, aura_type)
	local auras = self[aura_type]
	auras.config = self.config.auras[string.lower(aura_type)]
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

local function Constructor(self, aura_type)
	local auras = CreateFrame('Frame', self:GetName()..aura_type, self)
	auras.config = self.config.auras[string.lower(aura_type)]
	auras.PostCreateIcon = UF.PostCreateAura
	auras.PostUpdateIcon = UF.PostUpdateAura

	auras.disableCooldown = true
	self[aura_type] = auras
	return self[aura_type]
end





local function GetConfigTable(self, aura_type)
	return {
		type = 'group',
		name = aura_type,
		get = function(info)
			return self.config.auras[string.lower(aura_type)][info[#info]]
		end,
		set = function(info, value)
			self.config.auras[string.lower(aura_type)][info[#info]] = value
			UF:UpdateConfig(self.unit, aura_type)
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			template = st.CF.generators.template(2),
			position = st.CF.generators.position(3,
				self.config[string.lower(aura_type)].position, false,
				function() UF:UpdateConfig(self.unit, aura_type) end
			),
		}
	}
end

UF:RegisterElement('Buffs', Constructor, UpdateConfig, 
	function(self) return GetConfigTable(self, 'Buffs') end)
UF:RegisterElement('Debuffs', Constructor, UpdateConfig,
	function(self) return GetConfigTable(self, 'Debuffs') end)

-- UF:RegisterElement('Auras', Constructor, UpdateConfig, GetConfigTable)
