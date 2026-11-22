--[[
	Blizzard's talent window (Blizzard_PlayerSpells), as far as the talent plan
	reads it. Load it with `local PSF = load_test_file('misc/fixtures/player_spells_frame.lua')`,
	then PSF.build(opts) makes what the addon makes when it loads, from the
	trees stub.traits holds (tests/wow/traits.lua, filled by the shaman
	fixture's SH.install, which comes first):

	  - PlayerSpellsFrame (Blizzard_PlayerSpells/Blizzard_PlayerSpellsFrame.xml,
	    forever and live): 1218 by 708, TOP of UIParent at 0, -41, hidden, with
	    IsInspecting, SetInspecting(unit) and ClearInspectUnit
	    (Blizzard_PlayerSpellsFrame.lua; the state is _inspecting).
	  - .TalentsFrame (Camelot/ClassTalents/Blizzard_ClassTalentsFrame.lua,
	    ClassTalentsFrameMixin): 1212 by 681, BOTTOM 0, 4, hidden, with GetTab
	    (TabSystemOwnerMixin: the spec group, _tab, 1) and SetTab, which does
	    nothing while inspecting, as the game's; GetConfigID and GetTalentTreeID
	    (Blizzard_SharedTalentUI/Blizzard_SharedTalentFrame.lua,
	    TalentFrameBaseMixin); GetTalentButtonByNodeID and
	    EnumerateAllTalentButtons (the same file; the game's iterator is a pool's
	    EnumerateActive, which gives each button as its first value), and
	    .ButtonsParent.
	  - One 40 by 40 Button per node of the tree (the trees PSF.build reads), under
	    ButtonsParent, laid in a grid, at frame level 5110, with GetNodeID (_node)
	    and an OnClick that counts PSF.clicks[nodeID] (the game's buttons buy a
	    rank there; the fixture only counts, so a test shows a plan never clicked
	    one).

	Every frame here is locked (lib/locked_widget.lua, owner 'Blizzard'), so a
	talent plan that writes a field onto one, or SetScripts one, fails. The
	fixture's own writes use rawset or a key starting with '_'.

	  PSF.load()    sets stub.loaded_addons.Blizzard_PlayerSpells and fires
	                ADDON_LOADED, as the game does once the addon's files ran.
	  PSF.open()    shows both frames, the way ShowUIPanel and SetTab do.
	  PSF.redraw()  EventRegistry's 'TalentFrameBase.ButtonsUpdated' (the tree id),
	                which TalentFrameBaseMixin:UpdateTreeInfo triggers (line 277).
	  PSF.rebind(button, nodeID)  gives a pooled button another node, as
	                TalentButtonUtil's pool does when it hands one out again.

	Not built: the tab system, the loadout and spec buttons, the other tabs of
	PlayerSpellsFrame, the lines between buttons, the search box, the hero
	talent container, the config's staged changes.
]]
local lock_widget = load_test_file('lib/locked_widget.lua')
local OWNER = 'Blizzard'

local PSF = { clicks = {} }

local COLUMNS = 8
local BUTTON = 40

function PSF.build(opts)
	opts = opts or {}
	PSF.clicks = {}
	local buttons, byNode = {}, {}
	PSF.buttons = buttons

	local window = CreateFrame('Frame', 'PlayerSpellsFrame', UIParent)
	window:SetSize(1218, 708)
	window:SetPoint('TOP', UIParent, 'TOP', 0, -41)
	window:Hide()

	local talents = CreateFrame('Frame', nil, window)
	talents:SetSize(1212, 681)
	talents:SetPoint('BOTTOM', window, 'BOTTOM', 0, 4)
	talents:Hide()

	local parent = CreateFrame('Frame', nil, talents)
	parent:SetAllPoints(talents)

	local function configOf(tab)
		return stub.traits.group_configs[tab]
	end

	rawset(window, 'TalentsFrame', talents)
	rawset(window, '_inspecting', nil)
	rawset(window, 'IsInspecting', function(self) return self._inspecting ~= nil end)
	rawset(window, 'SetInspecting', function(self, unit) rawset(self, '_inspecting', unit) end)
	rawset(window, 'ClearInspectUnit', function(self) rawset(self, '_inspecting', nil) end)

	rawset(talents, '_tab', 1)
	rawset(talents, 'GetTab', function(self) return self._tab end)
	rawset(talents, 'SetTab', function(self, tab)
		if window:IsInspecting() then return end
		rawset(self, '_tab', tab)
	end)
	rawset(talents, 'GetConfigID', function(self) return configOf(self._tab) end)
	rawset(talents, 'GetTalentTreeID', function(self)
		local config = configOf(self._tab) or C_ClassTalents.GetActiveConfigID()
		local info = config and C_Traits.GetConfigInfo(config)
		return info and info.treeIDs and info.treeIDs[1]
	end)
	rawset(talents, 'GetTalentButtonByNodeID', function(self, nodeID) return byNode[nodeID] end)
	rawset(talents, 'EnumerateAllTalentButtons', function()
		local i = 0
		return function()
			i = i + 1
			return buttons[i]
		end
	end)
	rawset(talents, 'ButtonsParent', parent)

	-- one button a node, as the tree reads (the first config's tree)
	local config = configOf(1)
	local info = config and C_Traits.GetConfigInfo(config)
	local tree = info and info.treeIDs and info.treeIDs[1]
	for i, nodeID in ipairs(tree and C_Traits.GetTreeNodes(tree) or {}) do
		local button = CreateFrame('Button', nil, parent)
		button:SetSize(BUTTON, BUTTON)
		local row, col = math.floor((i - 1) / COLUMNS), (i - 1) % COLUMNS
		button:SetPoint('TOPLEFT', parent, 'TOPLEFT', 20 + col * (BUTTON + 20), -(20 + row * (BUTTON + 20)))
		button:SetFrameLevel(5110)
		rawset(button, '_node', nodeID)
		rawset(button, 'GetNodeID', function(self) return self._node end)
		button:SetScript('OnClick', function(self)
			PSF.clicks[self._node] = (PSF.clicks[self._node] or 0) + 1
		end)
		buttons[#buttons + 1] = button
		byNode[nodeID] = button
		lock_widget(button, OWNER)
	end

	PSF.window, PSF.talents, PSF.parent = window, talents, parent
	lock_widget(parent, OWNER)
	lock_widget(talents, OWNER)
	lock_widget(window, OWNER)
	PSF.byNode = byNode
	return window
end

function PSF.load()
	stub.loaded_addons.Blizzard_PlayerSpells = true
	stub.fire_event('ADDON_LOADED', 'Blizzard_PlayerSpells')
end

function PSF.open()
	PSF.window:Show()
	PSF.talents:Show()
end

function PSF.redraw()
	EventRegistry:TriggerEvent('TalentFrameBase.ButtonsUpdated', PSF.talents:GetTalentTreeID())
end

function PSF.rebind(button, nodeID)
	local old = button._node
	if PSF.byNode[old] == button then PSF.byNode[old] = nil end
	rawset(button, '_node', nodeID)
	PSF.byNode[nodeID] = button
end

return PSF
