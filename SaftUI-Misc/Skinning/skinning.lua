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
-- Nothing is made per pass: xpcall's arguments would make a closure in a test world
-- (the game's makes none), so the call goes through a function made once.
local colorModule, colorGroup, colorKey
local function CallColors() return colorModule:OnColorsChanged(colorGroup, colorKey) end
function SK:OnColorsChanged(group, key)
	for _, module in self:IterateModules() do
		if module.OnColorsChanged then
			colorModule, colorGroup, colorKey = module, group, key
			xpcall(CallColors, geterrorhandler())
		end
	end
end

-- A shared font or a font setting changed (st:FontsChanged). It reaches the skins the
-- same way: each one with an OnFontsChanged applies what it builds from font values
-- again (the Cooldown Manager's bar heights, RestedXP's faces, the color picker's
-- title). Texts on a shared font follow its object with no call, and a change of the
-- Skinning font setting itself runs each skin's UpdateConfig.
function SK:OnFontsChanged()
	for _, module in self:IterateModules() do
		if module.OnFontsChanged then
			xpcall(module.OnFontsChanged, geterrorhandler(), module)
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
				saved = st.Config.SavedIn('skinning'),
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					self.config[info[#info]] = value
					self:UpdateConfig()
				end,
				args = {
					theme = generators.theme(1,
						"The border and background of the frames SaftUI skins: the buff icons, the swing timer bars, the Cooldown Manager, the objective tracker's bars and buttons, the color picker, Hekili, WeakAuras and Spy. Under Blizzard the objective tracker and the color picker keep Blizzard's own look."),
					background = generators.background(1.5),
					font = generators.font(2,
						"The font of the text on the frames SaftUI skins: the buff icons, the swing timer bars, the Cooldown Manager, the color picker, Spy and the item levels on the character frame."),
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
					objective_tracker = {
						order = 4,
						name = 'Objective tracker',
						type = 'toggle',
						desc = "Draw Blizzard's objective tracker in SaftUI's look: its headers' banners gone, a line under each title, its texts in the fonts of /sui's Blizzard's tracker page, flat bars and buttons in this page's Theme and Background. Off, or while this page's Theme is Blizzard, it keeps Blizzard's look. Applies at once.",
					},
					color_picker = {
						order = 5,
						name = 'Color picker',
						type = 'toggle',
						desc = "Draw Blizzard's color picker in SaftUI's look: a panel in this page's Theme and Background, SaftUI's buttons and hex box, and this page's font. Off, or while this page's Theme is Blizzard, it keeps Blizzard's look. Applies at once.",
					},
					spy = {
						order = 6,
						name = 'Spy',
						type = 'toggle',
						desc = "Draw the Spy addon's Nearby window, alert, Statistics window and Kill on Sight button in SaftUI's look, in this page's Theme, Background and font. While on, Spy's Border and window colors are not used. Off, or while this page's Theme is Blizzard, Spy keeps its own look. Requires a reload.",
						set = function(info, value)
							self.config[info[#info]] = value
							st:Print('Reload your UI to apply.')
						end,
					},
					-- WoW Forever's talent window; retail has no such skin, so no row.
					talent_window = st.forever and {
						order = 7,
						name = 'Talent window',
						type = 'toggle',
						desc = "Draw the talent window's frame in SaftUI's look: its border, title bar and close button, the search box, Unspent talents, the Apply and Copy buttons, the tabs and the dividers, in this page's Theme, Background and font. Each spec's background art, and the talents, stay Blizzard's. Off, or while this page's Theme is Blizzard, it keeps Blizzard's look. Requires a reload.",
						set = function(info, value)
							self.config[info[#info]] = value
							st:Print('Reload your UI to apply.')
						end,
					} or nil,
				},
			},
		},
	}
end
