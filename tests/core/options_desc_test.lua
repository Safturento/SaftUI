-- Every setting in /sui has a tooltip: on a finished page, each option that
-- isn't a group, header or description has a desc, and no option carries
-- Ace's width, which SaftUI's window doesn't read (it packs rows by size).
--
-- The tree is built as tests/core/options_validate_test.lua builds it, with
-- the same files: Core's real Config/config.lua on a real AceDB-3.0
-- (config_helpers.lua: Global Settings' General, Fonts, Colors and Edit mode
-- tabs, and AceDBOptions' profiles), and Experience, the minimap and the
-- micro menu, whose tables build with no frames of their own made.

load_test_file('core/config_helpers.lua')
load_test_file('core/options_walk.lua')
local st = SaftUI

CreateFrame('Frame', 'Minimap', UIParent) -- Blizzard's, which experience.lua and the minimap's files find
for _, file in ipairs({
	'SaftUI-Misc/experience.lua',
	'SaftUI-Minimap/minimap.lua', 'SaftUI-Minimap/config.lua', 'SaftUI-Minimap/micromenu.lua',
}) do
	load_saftui(file)
end

-- AceDBOptions' table, which is Ace's own.
local NOT_SAFTUI = { profile = true }

local NO_DESC = { group = true, header = true, description = true }

local function HasDesc(option)
	local desc = option.desc
	return (type(desc) == 'string' and desc ~= '') or type(desc) == 'function'
end

-- What's wrong on a page: an option with no tooltip (unless widthOnly), and
-- an option with an Ace width. Each names the page and the option's path.
local function Problems(pageKey, page, widthOnly)
	local found = {}
	each_option(page, function(option, path)
		local where = pageKey .. '.' .. table.concat(path, '.')
		if not widthOnly and not NO_DESC[option.type] and not HasDesc(option) then
			found[#found + 1] = where .. ' has no desc'
		end
		if option.width ~= nil then
			found[#found + 1] = where .. ' has an Ace width (' .. tostring(option.width) .. ')'
		end
	end)
	return found
end

local function SortedPages(root)
	local keys = {}
	for key in pairs(root) do keys[#keys + 1] = key end
	table.sort(keys)
	return keys
end

test('every option on a finished page has a tooltip and no Ace width', function()
	local root = st.Config:GetOptionsTable()
	local checked = {}
	for _, key in ipairs(SortedPages(root)) do
		if not NOT_SAFTUI[key] then
			checked[#checked + 1] = key
			for _, problem in ipairs(Problems(key, root[key])) do
				check(false, problem)
			end
		end
	end
	eq(table.concat(checked, ','), 'Experience,Fonts,MicroMenu,Minimap', 'the finished pages built here')
end)

test("no SaftUI page carries an Ace width", function()
	local root = st.Config:GetOptionsTable()
	local checked = 0
	for _, key in ipairs(SortedPages(root)) do
		if not NOT_SAFTUI[key] then
			checked = checked + 1
			for _, problem in ipairs(Problems(key, root[key], true)) do
				check(false, problem)
			end
		end
	end
	eq(checked, 4, "every page but AceDBOptions' Profiles")
end)

test('the check is real: an option without desc fails it, and so does an Ace width', function()
	local page = {
		type = 'group', name = 'Page',
		args = {
			good = { type = 'toggle', name = 'Good', desc = 'Fine.' },
			fn = { type = 'toggle', name = 'Fn', desc = function() return 'Fine too.' end },
			bare = { type = 'toggle', name = 'Bare' },
			blank = { type = 'range', name = 'Blank', desc = '' },
			box = {
				type = 'group', name = 'Box', inline = true,
				args = {
					note = { type = 'description', name = 'A note needs no desc.' },
					title = { type = 'header', name = 'Nor a header' },
					wide = { type = 'input', name = 'Wide', desc = 'Has one.', width = 'full' },
				},
			},
		},
	}
	local problems = Problems('Page', page)
	eq(table.concat(problems, '; '),
		'Page.bare has no desc; Page.blank has no desc; Page.box.wide has an Ace width (full)',
		'a missing or empty desc and an Ace width, each named by page and path')
	eq(table.concat(Problems('Page', page, true), '; '), 'Page.box.wide has an Ace width (full)',
		'the width check alone')
end)
