-- The reset walk works in a world without the options widget files: the pages'
-- own tests (Global settings', Chat's, the bags') run in worlds that don't load
-- them, and one stubs st.OptionsWidgets with no CUSTOM table.
load_test_file('core/config_helpers.lua')
local st = SaftUI
load_saftui('SaftUI-Core/Config/optionsmodel.lua')
local R = load_test_file('lib/reset_walk.lua')

local function root()
	st.defaults.bw_ = { a = true }
	st.config.profile.bw_ = { a = true }
	return { Page = { type = 'group', name = 'Page', args = { box = {
		type = 'group', name = 'Box',
		get = function(info) return st.config.profile.bw_[info[#info]] end,
		set = function(info, value) st.config.profile.bw_[info[#info]] = value end,
		saved = st.Config.SavedIn('bw_'),
		args = { a = { type = 'toggle', name = 'A', order = 1 }, bare = { type = 'toggle', name = 'Bare', order = 2, get = function() return true end } },
	} } } }
end

test('with no widget files loaded', function()
	check(st.OptionsWidgets == nil, 'the world has none')
	local problems, walked = R.problems(root(), 'Page')
	eq(walked, 2, 'both value rows walked')
	eq(#problems, 1, 'the bare row fails and the saved one passes: ' .. table.concat(problems, '; '))
end)

test('with st.OptionsWidgets stubbed and no CUSTOM table', function()
	st.OptionsWidgets = {}
	local problems, walked = R.problems(root(), 'Page')
	eq(walked, 2, 'walked')
	eq(#problems, 1, 'the same one problem')
	st.OptionsWidgets = nil
end)
