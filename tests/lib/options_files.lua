-- Which Lua files the game's TOCs load define /sui options, for the reset coverage scan
-- (tests/core/reset_coverage_test.lua) and for worlds that load a folder of them
-- (tests/unitframes/config_test.lua). Not a test (no _test suffix), so the runner doesn't
-- run it. Load it with `local OF = load_test_file('lib/options_files.lua')`; it makes no globals.
--
-- The rule (OF.Defines): a file defines options when its code, with comments and strings
-- blanked by lib/source_lex.lua, uses one of OF.MARKS: GetConfigTable (a page), the
-- options kit's generators, a saved field (SavedIn, SavedAt), a unit frame element's
-- registration or Position (RegisterElement, uf_element_position), or the Categories editor's
-- options (CategoryEditorOptions). Those are the words every option-building file in the
-- repo uses; a file that builds a row without any of them would have none of the kit's
-- fields either, and the walk would fail it.
-- OF.EXCEPTIONS names the files the rule catches that define no page rows themselves, with
-- the reason.
local T = load_test_file('lib/theme_helpers.lua')
local L = load_test_file('lib/source_lex.lua')

local OF = {}

OF.MARKS = { 'GetConfigTable', 'Config%s*%.%s*generators', 'SavedIn', 'SavedAt', 'RegisterElement', 'uf_element_position', 'CategoryEditorOptions' }

OF.EXCEPTIONS = {
	['SaftUI-Core/Config/generators.lua'] = 'the generators themselves: they build rows for the pages, none of their own',
	['SaftUI-Core/Config/optionsdefault.lua'] = 'the reset kit: it defines SavedIn and SavedAt, no rows',
	['SaftUI-Core/Config/config.lua'] = "the options window's host: it assembles every module's GetConfigTable, with no page of its own",
	['SaftUI-Unitframes/unitframes.lua'] = 'the module and the element registry: the elements register their own rows',
}

-- Whether a Lua file's source defines options, by the rule above.
function OF.Defines(source)
	local _, mask = L.Lex(source)
	for _, mark in ipairs(OF.MARKS) do
		if mask:find('%f[%w_]' .. mark .. '%f[^%w_]') then return true end
	end
	return false
end

-- Every file the TOCs load that defines options, in load order, with the exceptions left out.
-- Under prefix (a path start such as 'SaftUI-Unitframes/elements/') when one is given.
function OF.Files(prefix)
	local out = {}
	for _, path in ipairs((T.saftui_files())) do
		if (not prefix or path:sub(1, #prefix) == prefix) and not OF.EXCEPTIONS[path] then
			local source = read_saftui_source(path)
			if source and OF.Defines(source) then out[#out + 1] = path end
		end
	end
	return out
end

return OF
