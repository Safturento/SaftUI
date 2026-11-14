local st = SaftUI
local EM = st.EditModeFrames

--[[
	Which movers show in edit mode, and which of them show their name.

	One rule (EM:IsMoverShown): a mover outside the bar's module choice
	(hidden_modules) or its filter never shows; else a mover whose frame is
	turned off (EM:IsMoverDisabled) shows under Show disabled, one whose frame
	is on but not on screen now (EM:IsMoverHidden) under Show hidden, and every
	other shows. The two toggles and the module choice are in the profile
	(st.defaults.editmode); the filter is only for this session (EM.filterText,
	lowercase, '' for none) and goes when edit mode closes.

	  EM:GetModules()                 the modules with a mover, A to Z, Other last
	  EM:IsModuleShown(name), EM:SetModuleShown(name, shown),
	  EM:SetAllModulesShown(shown)    write hidden_modules through EM:SetSetting;
	                                  a ticked module's key is cleared, never false
	  EM.ShowFaceText(modules, isShown)   what the Show list's face says
	  EM:SetFilter(text), EM:MatchesFilter(mover), EM:SelectFirstMatch()
	  EM:IsMoverShown(mover)          the rule
	  EM:UpdateShown()                every overlay shown or not by the rule; a
	                                  selected mover that no longer shows is
	                                  deselected; then the overlaps and the labels;
	                                  then 'ShownChanged', only if an overlay, the
	                                  selection or an overlap changed
	  EM.RectsOverlap(a, b, tol)      rects { left, right, bottom, top } sharing
	                                  more than an edge (more than tol on both axes)
	  mover.overlaps                  the mover's frame rect overlaps another shown
	                                  mover's by more than EM.OVERLAP_TOLERANCE (1),
	                                  not the outlines, which reach outside the frame
	  EM:UpdateLabels(hovered)        a mover's label shows when it doesn't overlap,
	                                  or when it is hovered (the picker's top mover)
	                                  or being dragged

	What shows can change while edit mode is open (a target appears, a bag
	opens, a pet is summoned), since the hidden check reads live frame state. So
	EM.shownFrame, a frame of this file's, runs EM:UpdateShown() every
	EM.SHOWN_INTERVAL seconds while edit mode is on, besides on Enabled, on
	SettingsChanged and when the filter changes. Showing or hiding an overlay
	never touches the mover's own frame (it may be protected): the overlay is
	SaftUI's.
]]

EM.SHOWN_INTERVAL = 0.5

------------------------------------------------------------------ modules

local function HiddenModules()
	return EM:GetSettings().hidden_modules or {}
end

-- The modules with at least one registered mover, A to Z ignoring case, with
-- EM.OTHER_MODULE last.
function EM:GetModules()
	local seen, list = {}, {}
	for _, mover in pairs(self.movers) do
		local name = self:MoverModule(mover)
		if not seen[name] then
			seen[name] = true
			list[#list + 1] = name
		end
	end
	local other = EM.OTHER_MODULE
	table.sort(list, function(a, b)
		if (a == other) ~= (b == other) then return b == other end
		local la, lb = a:lower(), b:lower()
		if la ~= lb then return la < lb end
		return a < b
	end)
	return list
end

function EM:IsModuleShown(name)
	return not HiddenModules()[name]
end

-- Ticks or unticks one module. The profile's table is replaced, not changed
-- in place, so SetSetting sees a new value; an unticked module's key is true,
-- a ticked one's is gone.
function EM:SetModuleShown(name, shown)
	local hidden = {}
	for key, value in pairs(HiddenModules()) do hidden[key] = value end
	hidden[name] = (not shown) or nil
	self:SetSetting('hidden_modules', hidden)
end

-- Ticks every module, or unticks every one that has a mover now.
function EM:SetAllModulesShown(shown)
	local hidden = {}
	if not shown then
		for _, name in ipairs(self:GetModules()) do hidden[name] = true end
	end
	self:SetSetting('hidden_modules', hidden)
end

-- What the Show list's face says: 'All modules', the one module's name,
-- '<n> modules' or 'Nothing'. isShown(name) says whether a module is ticked.
function EM.ShowFaceText(modules, isShown)
	local shown, only = 0, nil
	for _, name in ipairs(modules) do
		if isShown(name) then shown, only = shown + 1, name end
	end
	if shown == #modules then return 'All modules' end
	if shown == 0 then return 'Nothing' end
	if shown == 1 then return only end
	return shown .. ' modules'
end

------------------------------------------------------------------ the filter

EM.filterText = ''

-- The filter, lowercase ('' for none). Not saved; every other part sees it
-- through EM:UpdateShown.
function EM:SetFilter(text)
	text = (type(text) == 'string' and text or ''):lower()
	if text == self.filterText then return end
	self.filterText = text
	if self.active then self:UpdateShown() end
end

-- A plain, case-ignored find of the filter in the mover's name.
function EM:MatchesFilter(mover)
	local text = self.filterText
	if text == '' then return true end
	return EM.MoverName(mover):lower():find(text, 1, true) ~= nil
end

------------------------------------------------------------------ the rule

-- (a mover outside the module choice or the filter never shows)
function EM:IsMoverShown(mover)
	if not self:IsModuleShown(self:MoverModule(mover)) or not self:MatchesFilter(mover) then return false end
	local settings = self:GetSettings()
	if self:IsMoverDisabled(mover) then return settings.show_disabled == true end
	if self:IsMoverHidden(mover) then return settings.show_hidden == true end
	return true
end

-- The first shown mover by name, ignoring case (the key when names match),
-- selected. Returns it, or nil when nothing shows.
function EM:SelectFirstMatch()
	local first, firstName
	for key, mover in pairs(self.movers) do
		if mover.overlay:IsShown() then
			local name = EM.MoverName(mover):lower()
			if not first or name < firstName or (name == firstName and key < first.key) then
				first, firstName = mover, name
			end
		end
	end
	if first then self:Select(first) end
	return first
end

------------------------------------------------------------------ overlaps and labels

-- Whether two rects { left, right, bottom, top } share more than an edge, or
-- more than tolerance (UIParent units, default 0) on both axes.
function EM.RectsOverlap(a, b, tolerance)
	tolerance = tolerance or 0
	return a.left < b.right - tolerance and b.left < a.right - tolerance
		and a.bottom < b.top - tolerance and b.bottom < a.top - tolerance
end

-- Two movers overlap when their frames' own rects share more than a pixel on
-- both axes. Not the outlines, which reach outside the frame (2 px under
-- Thick): frames that touch or sit a few pixels apart don't have labels on top
-- of each other, and a read-back error of a hair is no overlap.
EM.OVERLAP_TOLERANCE = 1

local function FrameRect(mover)
	local l, r, b, t = EM.GetRectInUI(mover.def.frame)
	if l then return { left = l, right = r, bottom = b, top = t } end
end

-- Sets mover.overlaps for every shown mover: its frame overlaps another shown
-- mover's (EM.OVERLAP_TOLERANCE). A mover whose rect can't be read (a secret
-- edge) overlaps nothing. Returns whether any mover's state changed.
function EM:UpdateOverlaps()
	local rects, before = {}, {}
	for _, mover in pairs(self.movers) do
		before[mover] = mover.overlaps or false
		mover.overlaps = false
		if mover.overlay:IsShown() then rects[mover] = FrameRect(mover) end
	end
	for a, ra in pairs(rects) do
		for b, rb in pairs(rects) do
			if a ~= b and EM.RectsOverlap(ra, rb, EM.OVERLAP_TOLERANCE) then
				a.overlaps = true
				break
			end
		end
	end
	for mover, was in pairs(before) do
		if mover.overlaps ~= was then return true end
	end
	return false
end

-- Each shown mover's label shows unless it overlaps another shown mover, and
-- then only while it is hovered: the top mover under the cursor (picker.lua),
-- or being dragged (the mouse is on it for the whole drag).
function EM:UpdateLabels(hovered)
	self.hovered = hovered
	for _, mover in pairs(self.movers) do
		if mover.overlay:IsShown() then
			mover.label:SetShown(not mover.overlaps or mover == hovered or mover.drag ~= nil)
		end
	end
end

------------------------------------------------------------------ showing

-- Every overlay shown or not by the rule while edit mode is on. A selected
-- mover that doesn't show is deselected, so its label and selection go with
-- it (/sui stays where it is). A mover being dragged stays shown, with its
-- label, until its drop; then the rule applies.
-- 'ShownChanged' fires only when an overlay was shown or hidden, a selection
-- was dropped, or a mover's overlap state changed: the ticker runs this twice
-- a second, and a listener rebuilds on it.
function EM:UpdateShown()
	local active = self.active
	local changed = false
	for _, mover in pairs(self.movers) do
		local shown = active and (mover.drag ~= nil or self:IsMoverShown(mover)) or false
		if mover.overlay:IsShown() ~= shown then
			mover.overlay:SetShown(shown)
			changed = true
		end
	end
	if self.selected and not self.selected.overlay:IsShown() then
		self:Select(nil)
		changed = true
	end
	if self:UpdateOverlaps() then changed = true end
	self:UpdateLabels(self.hovered)
	if changed then self:Fire('ShownChanged') end
end

-- A mover moved: its overlaps and everyone's labels follow.
EM:On('PositionChanged', function()
	if not EM.active then return end
	EM:UpdateOverlaps()
	EM:UpdateLabels(EM.hovered)
end)

-- A drag keeps its label (UpdateLabels); its drop applies the rule to a mover
-- whose frame stopped showing meanwhile.
EM:On('DragStarted', function()
	if EM.active then EM:UpdateLabels(EM.hovered) end
end)

EM:On('DragStopped', function()
	if EM.active then EM:UpdateShown() end
end)

EM:On('SettingsChanged', function()
	if EM.active then EM:UpdateShown() end
end)

-- The ticker: a bag opens or a pet comes, and its mover follows.
local ticker = CreateFrame('Frame')
EM.shownFrame = ticker
ticker:Hide()
local elapsed = 0
ticker:SetScript('OnUpdate', function(_, delta)
	elapsed = elapsed + delta
	if elapsed < EM.SHOWN_INTERVAL then return end
	elapsed = 0
	EM:UpdateShown()
end)

EM:On('Enabled', function()
	elapsed = 0
	ticker:Show()
end)

EM:On('Disabled', function()
	ticker:Hide()
	EM.hovered = nil
	EM:SetFilter('')
end)
