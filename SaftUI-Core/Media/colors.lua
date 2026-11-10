local st = SaftUI

local CO = st:NewModule('Colors')

-- Tells every module that shows profile colors that a group of them changed
-- (the Colors tab calls this after an edit). group is 'text', 'button',
-- 'class', 'reaction', 'renown', 'power', 'item_quality' or 'status'. Each
-- module's OnColorsChanged(group) runs in xpcall, so one that errors doesn't
-- stop the rest.
function st:ColorsChanged(group)
	for _, module in pairs(st.modules) do
		if module.OnColorsChanged then
			xpcall(module.OnColorsChanged, geterrorhandler(), module, group)
		end
	end
end

-- The color for an item quality: the profile's, else Blizzard's, else nil.
-- Either object has r, g and b.
function st:QualityColor(quality)
	if quality == nil then return nil end
	return st.config.profile.colors.item_quality[quality] or (ITEM_QUALITY_COLORS and ITEM_QUALITY_COLORS[quality])
end
