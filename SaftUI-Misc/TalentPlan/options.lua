local st = SaftUI
local TP = st:GetModule('TalentPlan')

-- The talent plan's page in /sui, under Info (the other Misc frame additions,
-- such as Durability, sit there; optionslayout.lua's CATEGORIES has no Misc).
-- Forever only, as the plan is: nil on retail. The compact talent window's
-- switch is on this page too, but it is saved in talentwindow (the skin in
-- Skinning/blizzard/Blizzard_PlayerSpellsLayout.lua reads it on each layout
-- pass; switching it in a session leaves a mixed layout until a /reload), so it
-- has its own get, set and saved path.
function TP:GetConfigTable()
	if not st.forever then return end
	local generators = st.Config.generators

	local compact = generators.toggle(3, 'Compact talent window',
		"Closes up the empty space in Blizzard's talent window, so the gaps at the edges and between the specs match the gaps between talents. Takes effect after a /reload.")
	compact.saved = st.Config.SavedIn('talentwindow')
	compact.get = function() return st.config.profile.talentwindow.compact end
	compact.set = function(_, value) st.config.profile.talentwindow.compact = value end

	return {
		name = 'Talent plan',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionslayout.lua)
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				saved = st.Config.SavedIn('talentplan'),
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					self.config[info[#info]] = value
					self:UpdateConfig()
				end,
				args = {
					enable = generators.toggle(1, 'Enable',
						"Shows your leveling plan beside Blizzard's talent window: the order to take talents in, which ones you have, and the next one. Off, the talent window is Blizzard's alone."),
					dim = generators.toggle(2, 'Dim talents not in the plan',
						'Darkens the talents in the tree that your plan never takes, while the plan shows.'),
					compact = compact,
				},
			},
		},
	}
end
