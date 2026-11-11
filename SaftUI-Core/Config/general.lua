local st = SaftUI

-- The General tab of Global Settings: Core's settings that aren't fonts or
-- colors. Config:GetOptionsTable makes this module's table the page's first
-- tab. Each row is bound to its profile key and reads st.config.profile at
-- call time, so a profile switch reaches the new profile.
local GN = st:NewModule('General')

local ICONS_NOTE = 'The preview changes at once. The icons across SaftUI change when you reload (Reload UI, bottom left).'
-- Icon zoom's preview: any spell's icon would do.
local PREVIEW_ICON, PREVIEW_SIZE = 'Interface\\Icons\\Spell_Nature_Lightning', 36
local WINDOWS_NOTE = "The margin keeps all of SaftUI's frames that far from the screen's edges, not just the bags and bank; the minimap, which is Blizzard's, only when you drag it. Title bars and the margin change at once."

-- A range bound to st.config.profile[group][key]. apply, if given, runs after
-- a set, for a setting that can be re-applied to what's already built.
local function Setting(order, name, min, max, step, desc, group, key, apply)
	local option = st.Config.generators.range(order, name, min, max, step, desc)
	option.get = function() return st.config.profile[group][key] end
	option.set = function(_, value)
		st.config.profile[group][key] = value
		if apply then apply() end
	end
	return option
end

-- Title bar height reaches every window with a header at once, and the margin
-- every frame it keeps in (st:KeepInScreenMargin).
local function UpdateHeaders() st:UpdateHeader() end
local function UpdateScreenMargin() st:UpdateScreenMargin() end

function GN:GetConfigTable()
	-- The profile keeps the fraction of each edge that's cut (0.065); the
	-- window shows it as a percent.
	local zoom = Setting(1, 'Icon zoom', 0, 0.2, 0.005,
		"How much of each edge SaftUI cuts off the icons it skins, zooming them in so the border drawn into Blizzard's icon art doesn't show: action buttons, bag and currency slots, buffs, unit frame auras and icons, loot rolls and the loot feed, the totem bar, the character frame's gems, and WeakAuras and Hekili icons.",
		'misc', 'icon_trim')
	zoom.isPercent = true

	-- An icon cut as SaftUI cuts the ones it skins at the zoom set now. SaftUI
	-- cuts its icons when it builds its frames, so they take a new zoom on a
	-- reload; the preview reads it whenever the window draws or refreshes the
	-- row, which it does while the slider is dragged.
	local preview = {
		type = 'description',
		order = 2,
		name = 'Preview',
		image = PREVIEW_ICON,
		imageWidth = PREVIEW_SIZE,
		imageHeight = PREVIEW_SIZE,
		imageCoords = function()
			return { st:IconTexCoords(st.config.profile.misc.icon_trim, PREVIEW_SIZE, PREVIEW_SIZE) }
		end,
	}

	return {
		type = 'group',
		name = 'General',
		args = {
			icons = {
				type = 'group',
				inline = true,
				order = 1,
				name = 'Icons',
				desc = ICONS_NOTE,
				args = { icon_trim = zoom, icon_preview = preview },
			},
			windows = {
				type = 'group',
				inline = true,
				order = 2,
				name = 'Layout',
				desc = WINDOWS_NOTE,
				args = {
					header_height = Setting(1, 'Title bar height', 20, 60, 1,
						"The height of the strip along the top of SaftUI's windows (the bags and bank) that holds the title and the close button, and of the strip along their bottom. Under the Blizzard theme a window in Blizzard's metal holds its title in the metal's own title bar, which keeps Blizzard's height.",
						'headers', 'height', UpdateHeaders),
					clamp_inset = Setting(2, 'Screen edge margin', -50, 50, 1,
						"How close to the screen's edges frames can go.",
						'misc', 'clamp_inset', UpdateScreenMargin),
				},
			},
		},
	}
end
