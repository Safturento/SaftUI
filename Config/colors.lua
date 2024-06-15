local st = SaftUI

local CL = st:NewModule('Colors')


function CL:OnInitialize()
	self:UpdateConfig()
end

function CL:UpdateConfig()
	--if not CUSTOM_CLASS_COLORS then CUSTOM_CLASS_COLORS = {} end
	--for class, color in pairs(st.config.profile.colors.class) do
	--	local r, g, b = unpack(color)
	--	print(class, r, g, b)
	--	--CUSTOM_CLASS_COLORS[class].r = r
	--	--CUSTOM_CLASS_COLORS[class].g = g
	--	--CUSTOM_CLASS_COLORS[class].b = b
	--end

	for q,item_quality in pairs(st.config.profile.colors.item_quality) do
		local r, g, b = unpack(item_quality)
		ITEM_QUALITY_COLORS[q].r = r 
		ITEM_QUALITY_COLORS[q].g = g
		ITEM_QUALITY_COLORS[q].b = b
	end

	for reaction, color in pairs(st.config.profile.colors.reaction) do
		local r, g, b = unpack(color)
		FACTION_BAR_COLORS[reaction].r = r
		FACTION_BAR_COLORS[reaction].g = g
		FACTION_BAR_COLORS[reaction].b = b
	end
end

local color_keys = {
	reaction = {
		[1] = 'hated',
		[2] = 'hostile',
		[3] = 'unfriendly',
		[4] = 'neutral',
		[5] = 'friendly',
		[6] = 'honored',
		[7] = 'revered',
		[8] = 'exalted',
	},
	item_quality = {
		[0] = 'trash',
		[1] = 'common',
		[2] = 'uncommon',
		[3] = 'rare',
		[4] = 'epic',
		[5] = 'legendary',
	},
	power = {
		MANA = 'mana',
		RAGE = 'rage',
		FOCUS = 'focus',
		ENERGY = 'energy',
	},
	class = {
		DRUID = 'druid',
		HUNTER = 'hunter',
		MAGE = 'mage',
		PALADIN = 'paladin',
		PRIEST = 'priest',
		ROGUE = 'rogue',
		SHAMAN = 'shaman',
		WARLOCK = 'warlock',
		WARRIOR = 'warrior',
	}
}

function CL:GetConfigTable()
	local colors = {
		order = 2,
		type = 'group',
		name = 'Colors',
		args = {},
		get = function(info)
			return unpack(st.config.profile.colors[info[#info-1]][info[#info]])
		end,
	}

	for group_key, group in pairs(st.config.profile.colors) do
		colors.args[group_key] = {
			type = 'group',
			name = group_key,
			inline = true,
			args = {}
		}
		for config_key, color in pairs(group) do
			translated_key = color_keys[group_key] and color_keys[group_key][config_key] or config_key
			colors.args[group_key].args[translated_key] = {
				name = translated_key,
				type = 'color',
				get = function(info)
					return unpack(st.config.profile.colors[group_key][config_key])
				end,
				set = function(info, r, g, b, a)
					st.config.profile.colors[group_key][config_key] = { r, g, b, a }
				end
			}
		end
	end


	return colors
end
