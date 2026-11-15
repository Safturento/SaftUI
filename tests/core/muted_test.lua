-- Text > Muted (st.config.profile.colors.text.muted): what the options window,
-- the options kit and edit mode draw in it where they drew Text > Grey (and, for
-- the two readers outside this file, Buttons > Grey), the diff icon and its
-- strength (OB.DIFF_STRENGTH), and a changed Muted reaching them. The migration
-- and the Colors page rows are color_migration_test.lua's and colors_test.lua's.
--
-- Every case runs at a Muted that is not the default, so a reader that drew a
-- grey of its own (the old #b4b4b4, or Buttons > Grey's #969696) fails: the walk
-- at the end finds any text or icon in either.
--
-- Real: the /sui window's world (options_window_helpers.lua). The edit mode
-- picker's hint line is pinned in editmode_filter_test.lua beside the picker's
-- accent line, and the combined bank's eye in bags/views_switch_test.lua.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local W, OB, OW = st.OptionsWidgets, st.OptionsBody, st.OptionsWindow
local frames, theme, close_all = H.frames, H.theme, H.close_all
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent, 'GameTooltipTemplate') end

-- A page with an inline section (its title, and a note under it), a disabled
-- toggle (a disabled row's label is Muted) and a range that differs on another
-- page (the diff icon).
local MUTED_PAGE = st:NewModule('MutedPage')
function MUTED_PAGE:GetConfigTable()
	return {
		name = 'Muted page', type = 'group', category = 'Frames',
		args = { general = { name = 'General', type = 'group', args = {
			section = { name = 'A section', desc = 'Its note.', type = 'group', inline = true, order = 1, args = {
				off = { type = 'toggle', name = 'Off row', order = 1, disabled = true,
					get = function() return true end, set = function() end },
				size = { type = 'range', name = 'Size', order = 2, min = 1, max = 10, step = 1,
					get = function() return 3 end, set = function() end,
					share = { source = 'All', shared = function() return '3' end, targets = function() return {} end,
						applyAll = function() end, apply = function() end,
						differs = function() return { { name = 'Bar 2', value = '2' } } end } },
			} },
		} } },
	}
end

local function text(r, g, b) return string.format('%.2f,%.2f,%.2f', r, g, b) end
local function muted() return st.config.profile.colors.text.muted end
local MINE = '0.20,0.40,0.60'
local DEFAULT = '0.71,0.71,0.71' -- #b4b4b4, Text > Grey's default before and Muted's
local BUTTONS_GREY = '0.59,0.59,0.59' -- #969696, Buttons > Grey's, the other old grey
local function vertex(region) return text(region:GetVertexColor()) end
local function ink(fs) return text(fs:GetTextColor()) end

local function with_muted(r, g, b, fn)
	local c = muted()
	local keep = { c.r, c.g, c.b }
	c:SetRGB(r, g, b)
	local ok, err = pcall(fn)
	c:SetRGB(unpack(keep))
	if not ok then error(err, 0) end
end

test("Muted's default is the grey Text > Grey had: #b4b4b4, and OB.Muted is its r, g, b, exported as S.Muted too", function()
	eq(text(muted():GetRGB()), DEFAULT)
	eq(text(OB.Muted()), DEFAULT); eq(text(OW.S.Muted()), DEFAULT, 'S.Muted, the window files\' copy')
	check(OB.Grey == nil and OB.DIFF_COLOR == nil, 'the old names are gone')
	with_muted(0.1, 0.2, 0.3, function() eq(text(OB.Muted()), '0.10,0.20,0.30', 'read at each call') end)
	eq(OB.DIFF_STRENGTH, 1)
end)

-- Every FontString's ink and every Texture's tint under a frame, with the
-- region's name (its text, or its texture) for the failure.
local function walk(frame, out, seen)
	seen = seen or {}
	if seen[frame] then return out end
	seen[frame] = true
	for _, region in ipairs({ frame:GetRegions() }) do
		local kind = region:GetObjectType()
		if kind == 'FontString' and region:GetText() and region:GetText() ~= '' then
			out[#out + 1] = { what = 'text "' .. region:GetText() .. '"', rgb = ink(region) }
		elseif kind == 'Texture' and region.GetVertexColor and region:GetTexture() then
			out[#out + 1] = { what = 'icon ' .. tostring(region:GetTexture()), rgb = vertex(region) }
		end
	end
	for _, child in ipairs({ frame:GetChildren() }) do walk(child, out, seen) end
	return out
end

test('the window draws its hints, captions, section titles, tools and arrows in Muted, none in the old greys', function()
	theme('thick')
	with_muted(0.2, 0.4, 0.6, function()
		close_all()
		st.Config:Open('MutedPage')
		local F = frames()
		-- Drawn once at build: the sidebar's profile, the page's description, the
		-- search box's hint, the footer label and the placeholder.
		eq(ink(F.profile), MINE, 'the profile name in the sidebar')
		eq(ink(F.desc), MINE, "the page's description")
		eq(ink(F.search.hint), MINE, "the search box's hint")
		eq(ink(F.placeholder), MINE, 'the empty page line')
		eq(ink(F.footerLabel), MINE, "the footer control's label")
		eq(vertex(F.sideToggle.icon), MINE, "the sidebar toggle's icon at rest")
		for i, tool in ipairs(F.tools) do eq(vertex(tool.icon), MINE, 'tool ' .. i .. ' at rest') end
		eq(vertex(F.shrink.icon), MINE, "the window's shrink arrow at rest")
		eq(vertex(F.titleArrow), MINE, "the title's page list arrow at rest")
		stub.fire_script(F.titleButton, 'OnEnter')
		check(vertex(F.titleArrow) ~= MINE, 'lit under the mouse')
		stub.fire_script(F.titleButton, 'OnLeave')
		eq(vertex(F.titleArrow), MINE, 'Muted again when the mouse leaves')
		stub.fire_script(F.titleButton, 'OnEnter')
		stub.fire_script(F.titleButton, 'OnHide')
		eq(vertex(F.titleArrow), MINE, 'and when the button hides')
		stub.fire_script(F.titleButton, 'OnLeave')
		-- The sidebar's captions and its closed pages.
		local captions = 0
		for _, entry in ipairs(F.nav) do
			if entry.group then
				eq(ink(entry.text), MINE, 'a group caption in the sidebar')
				captions = captions + 1
			end
		end
		check(captions > 0, 'there are captions')
		-- The body: a section's title and note, and a disabled row's label.
		local seen = {}
		for _, found in ipairs(walk(F.content, {})) do seen[found.what] = found.rgb end
		eq(seen['text "A section"'], MINE, "a section's title"); eq(seen['text "Its note."'], MINE, "a section's note")
		eq(seen['text "Off row"'], MINE, "a disabled row's label")
		check(seen['text "Size"'] and seen['text "Size"'] ~= MINE, 'an enabled row keeps its normal color')

		-- Nothing in the whole window is drawn in either old grey.
		for _, found in ipairs(walk(F.window, {})) do
			check(found.rgb ~= DEFAULT and found.rgb ~= BUTTONS_GREY, found.what .. ' is not drawn in the old grey')
		end
		close_all()
	end)
end)

test('a changed Muted reaches them after the window draws again', function()
	theme('thick')
	st.Config:Open('MutedPage')
	local F = frames()
	with_muted(0.9, 0.3, 0.1, function()
		OW:Render()
		-- A section title and the page's body repaint at each draw.
		local seen = {}
		for _, item in ipairs(walk(F.content, {})) do seen[item.what] = item.rgb end
		eq(seen['text "A section"'], '0.90,0.30,0.10', "the section's title"); eq(seen['text "Its note."'], '0.90,0.30,0.10', 'its note')
		eq(seen['text "Off row"'], '0.90,0.30,0.10', "a disabled row's label")
		eq(ink(F.desc), '0.90,0.30,0.10', "the page's description"); eq(ink(F.search.hint), '0.90,0.30,0.10', "the search box's hint")
		eq(ink(F.profile), '0.90,0.30,0.10', 'the sidebar\'s profile line')
	end)
	close_all()
end)

test("the diff icon is Muted at OB.DIFF_STRENGTH (a listed change from orange); a strength changes its alpha", function()
	theme('thick')
	with_muted(0.2, 0.4, 0.6, function()
		close_all()
		st.Config:Open('MutedPage')
		local diff
		for _, cell in ipairs(OW.GetDrawnRows()) do
			if cell.row.key == 'size' and cell.frame.share then diff = cell.frame.share.diff end
		end
		check(diff and diff:IsShown(), 'the diff icon shows')
		local r, g, b, a = diff.icon:GetVertexColor()
		eq(text(r, g, b), MINE, 'in Muted, not orange'); eq(a, 1, 'at strength 1')
		local keep = OB.DIFF_STRENGTH
		OB.DIFF_STRENGTH = 0.5
		OW:Render()
		for _, cell in ipairs(OW.GetDrawnRows()) do
			if cell.row.key == 'size' and cell.frame.share then diff = cell.frame.share.diff end
		end
		r, g, b, a = diff.icon:GetVertexColor()
		eq(text(r, g, b), MINE); eq(string.format('%.2f', a), '0.50', 'its alpha follows OB.DIFF_STRENGTH')
		OB.DIFF_STRENGTH = keep
		close_all()
	end)
end)

test('a tab you are not on is Muted, lit under the mouse and Muted again when it leaves', function()
	theme('thick')
	with_muted(0.2, 0.4, 0.6, function()
		close_all()
		st.Config:Open('Inventory')
		local inactive
		for _, tab in ipairs(frames().tabs) do
			if tab:IsShown() and not tab.active then inactive = inactive or tab end
		end
		check(inactive, 'a tab that is not the open one')
		eq(ink(inactive.text), MINE, 'Muted at rest')
		stub.fire_script(inactive, 'OnEnter')
		check(ink(inactive.text) ~= MINE, 'lit under the mouse')
		stub.fire_script(inactive, 'OnLeave')
		eq(ink(inactive.text), MINE, 'Muted again')
		close_all()
	end)
end)
