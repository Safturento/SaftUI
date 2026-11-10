-- The default layout sits inside the screen edge margin (misc.clamp_inset,
-- st.CLAMP_INSET by default), so the clamp that keeps SaftUI's frames inside it
-- doesn't push any of them on first load. The buffs were 10 from the top of the
-- screen; they now sit the margin in. The debuffs below them stay where they were.
--
-- Real: Core's defaults (load_core_helpers) and SaftUI-Misc/config.lua.

load_core_helpers()
load_saftui('SaftUI-Misc/config.lua')
local st = SaftUI

test('the buffs sit the margin in from the top right of the screen; the debuffs stay put', function()
	local buffs = st.defaults.auras.buffs.position
	eq(buffs.point .. ' ' .. buffs.frame .. ' ' .. buffs.rel_point, 'TOPRIGHT UIParent TOPRIGHT', "the buffs' anchor")
	eq(buffs.y_off, -st.CLAMP_INSET, 'the margin down from the top')
	eq(buffs.x_off, -270, 'left of the minimap, as before')
	local debuffs = st.defaults.auras.debuffs.position
	eq(debuffs.x_off .. ',' .. debuffs.y_off, '-270,-155', 'the debuffs, as before')
end)
