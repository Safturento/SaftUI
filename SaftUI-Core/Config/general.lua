local st = SaftUI

-- The General tab of Global settings: Core's settings that aren't fonts or
-- colors. Config:GetOptionsTable makes this module's table the page's first
-- tab. Each row is bound to its profile key and reads st.config.profile at
-- call time, so a profile switch reaches the new profile. The UI scale
-- section above them is the exception: it reads and writes st.UIScale (the
-- choice is saved for this account, not in a profile) and asks through the
-- Keep prompt (st.UIScalePrompt, loaded after this file and read when a row
-- is used).
local GN = st:NewModule('General')

local ICONS_NOTE = 'The preview changes at once. The icons across SaftUI change when you reload (Reload UI, bottom right).'
-- Icon zoom's preview: any spell's icon would do.
local PREVIEW_ICON, PREVIEW_SIZE = 'Interface\\Icons\\Spell_Nature_Lightning', 36
local WINDOWS_NOTE = "The margin keeps all of SaftUI's frames that far from the screen's edges, not just the bags and bank; the minimap, which is Blizzard's, only when you drag it. Title bars and the margin change at once."

-- A range bound to st.config.profile[group][key]. apply, if given, runs after
-- a set, for a setting that can be re-applied to what's already built.
local function Setting(order, name, min, max, step, desc, group, key, apply)
	local option = st.Config.generators.range(order, name, min, max, step, desc)
	option.saved = st.Config.SavedAt(group, key)
	option.get = function() return st.config.profile[group][key] end
	option.set = function(_, value)
		st.config.profile[group][key] = value
		if apply then apply() end
	end
	return option
end

------------------------------------------------------------------ UI scale

local UI_SCALE_DESC = "Saved for this computer and account, not in the profile, so a profile you share keeps the other person's screen size. A change shows at once: keep it within 15 seconds or it goes back. If SaftUI ever ends up too large or too small to use, type /sui scale reset."
local SCALE_DESC = "Automatic: SaftUI is laid out for a screen 1440 pixels high and scales to yours, so it takes the same share of any screen. Pixel for pixel: every size is that many pixels on your screen, as before this version, so SaftUI looks larger on a small screen and smaller on a large one. The game's UI scale: the game's own UI Scale (Options > Graphics) sets the size, and SaftUI keeps its lines whole at whatever size that is."
local SIZE_DESC = "Makes all of SaftUI larger or smaller than the automatic size. 100% is the size SaftUI works out for this screen. Every size and position in SaftUI's settings is in pixels of a 1440p screen, so they grow and shrink with this."
local SIZE_OFF = "Only Automatic has a size. Pixel for pixel draws every size as that many pixels, and in the game's UI scale the game's UI Scale sets it."
local NO_PROMPT = "The Keep prompt didn't load, so a size can't be tried. Type /sui scale reset to go back to Automatic at 100%."
local NO_SIZE = "That UI size doesn't fit this screen."
local NO_SCREEN = "SaftUI can't read this screen's size here."
local GAVE_UP = "The game keeps setting its own UI scale, so SaftUI stopped setting it back. Untick Use UI Scale in the game's graphics options, or change a setting here to try again."

-- Tries a choice through the Keep prompt: true, or false and the line that says
-- why not (the same two /sui scale prints for combat and for no screen).
local function Ask(choice)
	local KP = st.UIScalePrompt
	if not KP then return false, NO_PROMPT end
	local ok, why = KP:Ask(choice)
	if ok then return true end
	return false, KP.REFUSED[why] or NO_SIZE
end

-- A set that cannot ask says so in chat (a reset hands the line to the status line).
local function Say(ok, line)
	if not ok then st:Print(line) end
end

-- The size row shows the size SaftUI is drawing: the choice's, on the 5% steps
-- and held to what this screen takes.
local function ShownSize()
	local UIScale = st.UIScale
	local size = UIScale:Current().size
	local screen = UIScale.ReadScreen()
	local resolved = screen and UIScale.Resolve({ mode = 'auto', size = size }, screen)
	return resolved and resolved.size or size
end

local function UIScaleSection()
	local UIScale = st.UIScale
	local DEFAULT = UIScale.DEFAULT
	local default = UIScale:Default()
	return {
		type = 'group',
		inline = true,
		order = 0,
		name = 'UI scale',
		desc = UI_SCALE_DESC,
		args = {
			scale = {
				type = 'select',
				order = 1,
				name = 'Scale',
				desc = SCALE_DESC,
				values = UIScale.MODE_NAMES,
				sorting = UIScale.MODES,
				get = function() return UIScale:Current().mode end,
				set = function(_, value)
					Say(Ask({ mode = value, size = UIScale:Current().size }))
				end,
				default = {
					differs = function() return UIScale:Current().mode ~= DEFAULT.mode end,
					reset = function() return Ask({ mode = DEFAULT.mode, size = UIScale:Current().size }) end,
					text = UIScale.MODE_NAMES[DEFAULT.mode],
				},
			},
			size = {
				type = 'range',
				order = 2,
				name = 'UI size',
				desc = SIZE_DESC,
				min = UIScale.SIZE.min,
				max = default and default.sizeMax or UIScale.SIZE.max,
				step = UIScale.SIZE.step,
				isPercent = true,
				applyOnRelease = true,
				disabled = function() return UIScale:Current().mode ~= 'auto' end,
				disabledDesc = SIZE_OFF,
				get = ShownSize,
				set = function(_, value)
					Say(Ask({ mode = 'auto', size = value }))
				end,
				default = {
					differs = function() return math.abs(ShownSize() - DEFAULT.size) > 1e-4 end,
					reset = function() return Ask({ mode = UIScale:Current().mode, size = DEFAULT.size }) end,
					text = ('%d%%'):format(DEFAULT.size * 100 + 0.5),
				},
			},
			describe = {
				type = 'description',
				order = 3,
				name = function()
					if UIScale:GaveUp() then return GAVE_UP end
					local line = UIScale:Describe(UIScale:Applied())
					return line ~= '' and line or NO_SCREEN
				end,
			},
		},
	}
end

-- Title bar height reaches every window with a header at once, and the margin
-- every frame it keeps in (st:KeepInScreenMargin).
local function UpdateHeaders() st:UpdateHeader() end
local function UpdateScreenMargin() st:UpdateScreenMargin() end

function GN:GetConfigTable()
	-- The profile keeps the fraction of each edge that's cut (0.065); the
	-- window shows it as a percent.
	local zoom = Setting(1, 'Icon zoom', 0, 0.2, 0.005,
		"How much of each edge SaftUI cuts off the icons it skins, zooming them in so the border drawn into Blizzard's icon art doesn't show: action buttons, bag and currency slots, buffs, unit frame auras and icons, loot rolls, the loot feed and the loot window, the totem bar, the character frame's gems, and WeakAuras and Hekili icons.",
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
			uiscale = UIScaleSection(),
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
