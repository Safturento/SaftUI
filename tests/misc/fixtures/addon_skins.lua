-- Hekili's buttons and WeakAuras' icon regions, as the SaftUI skins
-- (SaftUI-Misc/Skinning/addons/hekili.lua and weakauras.lua) see them. Stand-ins
-- for third-party addons: the widgets come from the shared stubs in tests/wow/.
-- Every frame is locked (lib/locked_widget.lua), so a skin that stamps a field
-- onto one (.backdrop, .skinned) or replaces a script fails loudly.
--
--   A.make_hekili()            makes the global Hekili with one display and one
--                              button (A.button), and a CreateButton the skin
--                              hooks, as Hekili's is.
--   A.make_weakauras()         makes the global WeakAurasPrivate with an icon
--                              region type whose modify the skin hooks, and
--                              A.region(), which makes and locks one icon region.
--
-- Call them after reset_world(), before the skin's module is enabled.

local lock = load_test_file('lib/locked_widget.lua')

local A = {}

-- The keys a frame holds, as a set copy, to compare before and after a skin.
function A.keys(frame)
	local set = {}
	for key in pairs(frame) do set[key] = true end
	return set
end

local function make_frame(owner, parent)
	local frame = CreateFrame('Frame', nil, parent or UIParent)
	frame:SetSize(40, 40)
	frame:SetFrameLevel(10) -- not the lowest, so a level taken off it shows
	frame.Icon = frame:CreateTexture(nil, 'ARTWORK')
	frame.icon = frame.Icon
	return lock(frame, owner)
end

function A.make_hekili()
	local button = make_frame('Hekili')
	A.button = button
	Hekili = {
		DisplayPool = { [1] = { Buttons = { [1] = button } } },
		CreateButton = function() end,
	}
	return Hekili
end

function A.make_weakauras()
	local modify = function() end
	WeakAurasPrivate = { regionTypes = { icon = { modify = modify } } }
	return WeakAurasPrivate
end

function A.region()
	return make_frame('WeakAuras')
end

return A
