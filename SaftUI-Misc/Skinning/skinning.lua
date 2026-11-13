local st = SaftUI
local SK = st:NewModule('Skinning')
SK:SetDefaultModuleLibraries('AceEvent-3.0', 'AceHook-3.0')

function SK:OnEnable()
	st:BindModuleConfig(self, 'skinning')
end

-- A profile change. The skins are this module's submodules, which aren't in
-- st.modules, so Config:UpdateConfig only reaches them through here. Each one
-- with an UpdateConfig re-applies the profile's skinning font, Theme and
-- Background.
function SK:UpdateConfig()
	for _, module in self:IterateModules() do
		if module.UpdateConfig then
			xpcall(function() module:UpdateConfig() end, geterrorhandler())
		end
	end
end

-- A color changed (st:ColorsChanged). It reaches the skins the same way: each one
-- with an OnColorsChanged colors again what it colors itself, such as a debuff's
-- border after a theme recolor.
function SK:OnColorsChanged(group)
	for _, module in self:IterateModules() do
		if module.OnColorsChanged then
			xpcall(module.OnColorsChanged, geterrorhandler(), module, group)
		end
	end
end

-- The Skinning page in /sui: the font, Theme and Background the skins share. The
-- skins re-apply them at once (SK:UpdateConfig above).
function SK:GetConfigTable()
	local generators = st.Config.generators
	return {
		name = 'Skinning',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionslayout.lua)
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					self.config[info[#info]] = value
					self:UpdateConfig()
				end,
				args = {
					theme = generators.theme(1,
						"The border and background of the frames SaftUI skins: the buff icons, the swing timer bars, the Cooldown Manager, Hekili and WeakAuras."),
					background = generators.background(1.5),
					font = generators.font(2,
						"The font of the text on the frames SaftUI skins: the buff icons, the swing timer bars, the Cooldown Manager and the item levels on the character frame."),
					cooldown_manager = {
						order = 3,
						name = 'Cooldown Manager',
						type = 'toggle',
						desc = "Draw Blizzard's Cooldown Manager as SaftUI's action buttons, in this page's Theme, Background and font, and its tracked buff bars as SaftUI's bars. Off, it keeps Blizzard's look. Requires a reload.",
						set = function(info, value)
							self.config[info[#info]] = value
							st:Print('Reload your UI to apply.')
						end,
					},
				},
			},
		},
	}
end
