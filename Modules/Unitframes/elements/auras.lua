local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local AURAS = {'Buffs', 'Debuffs'}

local friendly_dispels = {
	SHAMAN = {
		Disease = true,
		Poison = true,
	},
	DRUID = {
		Poison = true,
		Curse = true,
	},
	PALADIN = {
		Disease = true,
		Poison = true,
		Magic = true,
	},
	PRIEST = {
		Disease = true,
		Magic = true,
	},
	MAGE = {
		Curse = true,

	}
}

function UF.FilterAura(element, unit, button, name, texture,
count, debuffType, duration, expiration, caster, isStealable, nameplateShowSelf, spellID,
canApply, isBossDebuff, casterIsPlayer, nameplateShowAll,timeMod, effect1, effect2, effect3)

	local is_friend = UnitIsFriend('player', unit) 
	local config = element.config.filter[is_friend and 'friend' or 'enemy']
	local is_dispellable = IsDispellable(unit, debuffType)
	
	if not (
		 config.show_all or 
		(config.show_self and button.isPlayer) or
		(config.show_dispel and is_dispellable)
	) then return end

	if is_dispellable and config.border == 'dispel' or config.border == 'all' then
		local c = DebuffTypeColor[debuffType]
		button.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
	end

	if config.desaturate and not (button.isPlayer or is_dispellable) then
		button.icon:SetDesaturated(1)
	else
		button.icon:SetDesaturated()
	end

	return true
end

function IsDispellable(unit, debuffType)
	return UnitIsFriend('player', unit) and friendly_dispels[st.my_class][debuffType]
end

function UF.PostCreateAura(auras, button)
	st:SetBackdrop(button, auras.config.template)
	st:SkinIcon(button.icon)
	button.count:SetFontObject(st:GetFont(auras.config.font)) 

	button.cd.noOCC = not auras.config.cooldown.timer
	button.cd.noCooldownCount = not auras.config.cooldown.timer
	button.cd:SetReverse(not auras.config.cooldown.reverse)
	button.cd:SetAlpha(auras.config.cooldown.alpha)
	-- button.cd:SetFrameLevel(button:GetFrameLevel() + 5)
	button.cd:SetHideCountdownNumbers(true)
end

function UF.PostUpdateAura(auras, unit, button, index, position, duration, expiration, debuffType, isStealable)
end

local function UpdateConfig(self, aura_type)
	local auras = self[aura_type]
	auras.config = self.config.auras[string.lower(aura_type)]

	if auras.config.enable then
		auras:Show()
	else
		auras:Hide()
		return
	end

	local num_rows = ceil(auras.config.max/auras.config.per_row)

	auras:SetHeight(num_rows*auras.config.size + (num_rows-1)*auras.config.spacing)
	auras:SetWidth(auras.config.per_row*auras.config.size + (auras.config.per_row-1)*auras.config.spacing)
	auras:ClearAllPoints()
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
	auras.disableCooldown = not auras.config.cooldown.enable
	auras.showDispellable = auras.config.show_dispellable
	auras.CustomFilter = UF.FilterAura
end

local function Constructor(self, aura_type)
	local auras = CreateFrame('Frame', self:GetName()..aura_type, self)
	auras.config = self.config.auras[string.lower(aura_type)]
	auras.PostCreateIcon = UF.PostCreateAura
	auras.PostUpdateIcon = UF.PostUpdateAura

	auras.disableCooldown = true
	self[aura_type] = auras
	return auras
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
