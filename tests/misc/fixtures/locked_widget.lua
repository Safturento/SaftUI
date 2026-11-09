-- Locks a widget that belongs to a third-party addon (RestedXP, LibCandyBar),
-- so a SaftUI skin that stamps its own field onto it, or replaces one of its
-- scripts, fails loudly instead of passing where the game would break the
-- addon. Returns lock(widget, owner), where owner names the addon in the error.
--
-- Once locked, assigning a new string key errors, except:
--   - keys starting with '_', which a fixture or test uses for its own state;
--   - 'backdropInfo', which Blizzard's backdrop code writes on any frame.
-- The addon itself writes with rawset, as it would in its own code. A
-- hooksecurefunc wrapper is stored with rawset too, so hooking is allowed.
-- SetScript errors on a locked widget: skins hook scripts (HookScript), they
-- never replace the addon's. An addon's fixture sets its own scripts before
-- locking, or through the game's SetScript.

return function(widget, owner)
	local methods = getmetatable(widget).__index
	local without_set_script = setmetatable({
		SetScript = function() error('SetScript on a ' .. owner .. ' frame', 2) end,
	}, { __index = methods })
	setmetatable(widget, {
		__index = without_set_script,
		__newindex = function(t, key, value)
			if type(key) == 'string' and key:sub(1, 1) ~= '_' and key ~= 'backdropInfo' then
				error(('skin wrote field "%s" onto a %s frame'):format(key, owner), 2)
			end
			rawset(t, key, value)
		end,
	})
	return widget
end
