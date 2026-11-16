-- Where a /sui page's Position section sits. Not a test (no _test suffix), so
-- the runner doesn't run it. The owner's rule (2026-11-15): on every page or
-- tab about a frame, the frame's Position is the SECOND section, right after
-- the first (the one with Enable and the frame's basics), not the last.
--
--   local PS = load_test_file('lib/position_second.lua')
--   local problems, found = PS.problems(root, 'Chat')
--
-- root is the options tree as the model reads it (as lib/reset_walk.lua's);
-- every page, picker pick, tab and sub tab is built with OM.BuildView, so the
-- sections are the ones the window draws. A section is a Position section when
-- its one row is a 'position' row. found is how many frame Positions it
-- checked (a part's Position, below, is not counted), and skipped the parts'
-- Positions it left alone, as 'Page:tab[/sub tab]:title'.
--
-- Not a frame's Position, and so left where its own section has it (a redesign
-- of those pages is coming): the Position of a PART inside an element's tab
-- (a text's, an icon's, the aura area's own position within its tab), built by
-- generators.uf_element_position, or named for the part ('Duration position',
-- 'Stack count position'). On the Unitframes page a Position in any tab (or sub
-- tab) but FRAME_TABS' General is a part's; a Position whose title is in
-- PART_TITLES is a part's anywhere. Every other tab, and a page with no tabs,
-- is about the frame itself. The test names the parts' Positions it skips.
local PS = {}

-- On the Unitframes page, every tab but General is an element's: its Position is
-- the part's within the unit frame (generators.uf_element_position). The
-- nameplate pages and group pages keep the same tabs. 'general' is the frame's.
PS.FRAME_TABS = { general = true }
-- The unit frames' bar tabs (Health, Power and its Power bar and Additional power,
-- Cast bar, Auras' Buffs and Debuffs) are about a frame of their own, so their own
-- Position is the second section too: only the texts' and icons' inside them are a
-- part's (PART_TITLES). Every other element is a row of General's Parts, whose
-- menu is no page.
for _, tab in ipairs({ 'Health', 'Power', 'bar', 'AdditionalPower', 'Castbar', 'Auras', 'Buffs', 'Debuffs' }) do
	PS.FRAME_TABS[tab] = true
end
-- Titles of a part's Position (a text drawn on each icon), on a General tab or
-- not: Auras' Duration and Stack count (Blizzard_BuffFramePosition.lua), the unit
-- frames' texts and icons inside a bar's tab.
PS.PART_TITLES = { ['Duration position'] = true, ['Stack count position'] = true }
-- The unit frames' texts and icons inside a bar's tab: a part's on the Unit frames page only.
PS.UNITFRAME_PART_TITLES = {
	['Text position'] = true, ['Spell name position'] = true, ['Time position'] = true,
	['Icon position'] = true, ['Count position'] = true, ['Timer position'] = true,
}

local function OM() return SaftUI.OptionsModel end

-- Every selection of a page: { pick, tab, subtab } keys as the views name
-- them, by breadth over picks, tabs and sub tabs.
local function Views(root, pageKey)
	local views, seen, queue = {}, {}, { {} }
	local head = 1
	while queue[head] do
		local selection = queue[head]
		head = head + 1
		local view = OM().BuildView(root, pageKey, selection)
		if not view then return views end
		local picked = view.picker and view.picker.selected
		local id = tostring(picked) .. '|' .. tostring(view.tab) .. '|' .. tostring(view.subtab)
		if not seen[id] then
			seen[id] = true
			views[#views + 1] = { view = view, pick = picked, tab = view.tab, subtab = view.subtab }
			local function Add(field, list)
				for _, entry in ipairs(list or {}) do
					local next = { pick = selection.pick, tab = selection.tab, subtab = selection.subtab }
					-- The picker's pick is the only slot named 'pick' (OM.BuildView).
					next[field] = entry.key
					queue[#queue + 1] = next
				end
			end
			if view.picker then Add('pick', view.picker.values) end
			Add('tab', view.tabs)
			Add('subtab', view.subtabs)
		end
	end
	return views
end

-- The section titles of a view, for a message.
local function Titles(view)
	local out = {}
	for i, section in ipairs(view.sections) do out[i] = section.title or '(untitled)' end
	return table.concat(out, ' | ')
end

-- Whether a Position section is a part's, not the frame's: a part's title, or
-- a tab other than General on a page whose tabs are elements' (elementPage).
function PS.IsPart(entry, section, elementPage)
	if PS.PART_TITLES[section.title] or (elementPage and PS.UNITFRAME_PART_TITLES[section.title]) then return true end
	if not elementPage then return false end
	for _, key in ipairs({ entry.tab, entry.subtab }) do
		if key ~= nil and not PS.FRAME_TABS[key] then return true end
	end
	return false
end

-- Problems of one page: the frame's Position sections that are not second.
function PS.problems(root, pageKey, opts)
	opts = opts or {}
	local problems, found, skipped = {}, 0, {}
	local elementPage = pageKey == 'Unitframes' -- the only page whose tabs are elements'
	for _, entry in ipairs(Views(root, pageKey)) do
		local view = entry.view
		for i, section in ipairs(view.sections) do
			local row = section.rows[1]
			if #section.rows == 1 and row.type == 'position' and PS.IsPart(entry, section, elementPage) then
				-- 'Page:tab[/sub tab]:title', as the test's list of skipped Positions names them.
				skipped[#skipped + 1] = ('%s:%s%s:%s'):format(pageKey, tostring(entry.tab),
					entry.subtab and ('/' .. entry.subtab) or '', tostring(section.title))
			elseif #section.rows == 1 and row.type == 'position' then
				found = found + 1
				-- An untitled section after another joins the panel above it (the options body's
				-- layout draws it there): the bar's size line belongs to the bar's first section.
				local place = 0
				for j = 1, i do
					if j == 1 or view.sections[j].title ~= nil then place = place + 1 end
				end
				if place ~= 2 and not (i == #view.sections and #view.sections == 1) then
					problems[#problems + 1] = ('%s [pick %s, tab %s, sub tab %s]: Position is section %d of %d, not the second (%s)')
						:format(pageKey, tostring(entry.pick), tostring(entry.tab), tostring(entry.subtab), place, #view.sections, Titles(view))
				end
			end
		end
	end
	return problems, found, skipped
end

return PS
