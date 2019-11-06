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

	local show = not config.whitelist.enable

	if config.whitelist.enable then
		local whitelist = config.whitelist.filters
		show = (whitelist.yours and button.isPlayer) or
				 (whitelist.others and not button.isPlayer) or
				 (whitelist.dispellable and is_dispellable) or
				 (whitelist.auras and duration == 0)
	end

	if config.blacklist.enable then
		local blacklist = config.blacklist.filters
		show = not (
			(blacklist.yours and button.isPlayer) or
			(blacklist.others and not button.isPlayer) or
			(blacklist.dispellable and is_dispellable) or
			(blacklist.auras and duration == 0)
		)
	end

	if not show then return end

	if debuffType and (is_dispellable and config.border == 'dispel' or config.border == 'all') then
		local c = DebuffTypeColor[debuffType]
		button.backdrop:SetBackdropBorderColor(c.r, c.g, c.b)
	else
		st:SetBackdrop(button, element.config.template)
	end

	if config.desaturate and not (button.isPlayer or is_dispellable) then
		button.icon:SetDesaturated(1)
	else
		button.icon:SetDesaturated()
	end

	return true
end

function IsDispellable(unit, debuffType)
	return friendly_dispels[st.my_class] and UnitIsFriend('player', unit) and friendly_dispels[st.my_class][debuffType]
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
	auras.aura_type = aura_type

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
	local point, _, relativePoint, xoffset, yoffset = st:UnpackPoint(auras.config.position)
	local frame = st.CF.get_frame(self, auras.config.position)
	auras:SetPoint(point, frame, relativePoint, xoffset, yoffset)	
	auras:SetFrameLevel(auras.config.framelevel)

	auras.size = auras.config.size
	auras.num = auras.config.max
	auras.numRow = auras.config.per_row
	auras.spacing = auras.config.spacing
	auras.initialAnchor = auras.config.initial_anchor
	auras['growth-y'] = auras.config.grow_up and 'UP' or 'DOWN'
	auras['growth-x'] = auras.config.grow_right and 'RIGHT' or 'LEFT'
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

local function GetConfigTable(unit, aura_type)
	local config = st.config.profile.unitframes
	local filter_values = {
		yours = 'Yours',
		others = 'Others',
		dispellable = 'Dispellable',
		auras = 'Auras'
	}
	
	local function FiltersTable(order, name, target_type, list_type)
		return {
			order = order, 
			name = name,
			type = 'group',
			desc = 'If the aura matches any of these criteria it will be ' .. (list_type == 'blacklist' and 'hidden' or 'shown'),
			-- inline = true,
			width = 0.5,
			get = function(info)
				local config = config.profiles[config.config_profile][unit].auras[aura_type:lower()]
				return config.filter[target_type][list_type][info[#info]]
			end,
			set = function(info, value)
				local config = config.profiles[config.config_profile][unit].auras[aura_type:lower()]
				local filters = config.filter[target_type][list_type]
				filters[info[#info]] = value
			end,
			args = {
				enable = st.CF.generators.enable(0),
				filters = {
					-- width = 2,
					name = '',
					type = 'multiselect',
					dialogControl = 'Dropdown',
					get = function(info, filter)
						local config = config.profiles[config.config_profile][unit].auras[aura_type:lower()]
						return config.filter[target_type][list_type].filters[filter]
					end,
					set = function(info, filter)
						local config = config.profiles[config.config_profile][unit].auras[aura_type:lower()]
						local filters = config.filter[target_type][list_type].filters
						filters[filter] = not filters[filter]
					end,
					values = filter_values,
				}
			}
		}
	end

	return {
		type = 'group',
		name = aura_type,
		get = function(info)
			return config.profiles[config.config_profile][unit].auras[aura_type:lower()][info[#info]]
		end,
		set = function(info, value)
			config.profiles[config.config_profile][unit].auras[aura_type:lower()][info[#info]] = value
			UF:UpdateConfig(unit, aura_type)
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			template = st.CF.generators.template(2),
			position = st.CF.generators.uf_element_position(3,
				function(index) return
					config.profiles[config.config_profile][unit].auras[aura_type:lower()].position[index]
				end,
				function(index, value)
					config.profiles[config.config_profile][unit].auras[aura_type:lower()].position[index] = value
					UF:UpdateConfig(unit, aura_type)
				end
			),
			size = st.CF.generators.range(4, 'Size', 1, 50, 1),
			spacing = st.CF.generators.range(5, 'Spacing', 1, 30, 1),
			max = st.CF.generators.range(6, 'Max', 1, aura_type == 'Debuff' and 16 or 32, 1),
			per_row = st.CF.generators.range(7, 'Per row', 1, aura_type == 'Debuff' and 16 or 32, 1),
			grow_up = st.CF.generators.toggle(8, 'Grow up'),
			grow_right = st.CF.generators.toggle(9, 'Grow right'),
			initial_anchor = {
				order = 10,
				type = 'select',
				name = 'initial_anchor',
				values = st.FRAME_ANCHORS
			},
			filter = {
				order = 11,
				name = 'Filters',
				type = 'group',
				inline = true,
				args = {
					friendly_whitelist = FiltersTable(1, 'Friendly Whitelist', 'friend', 'whitelist'),
					friendly_blacklist = FiltersTable(2, 'Friendly Blacklist', 'friend', 'blacklist'),
					enemy_whitelist = FiltersTable(3, 'Enemy Whitelist', 'enemy', 'whitelist'),
					enemy_blacklist = FiltersTable(4, 'Enemy Blacklist', 'enemy', 'blacklist'),
				}
			}
		}
	}
end

UF:RegisterElement('Buffs', Constructor, UpdateConfig, 
	function(self) return GetConfigTable(self, 'Buffs') end)
UF:RegisterElement('Debuffs', Constructor, UpdateConfig,
	function(self) return GetConfigTable(self, 'Debuffs') end)

-- UF:RegisterElement('Auras', Constructor, UpdateConfig, GetConfigTable)
