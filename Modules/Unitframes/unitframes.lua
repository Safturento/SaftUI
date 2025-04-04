local st = SaftUI
local UF = st:NewModule('Unitframes')

local TEST_PARTY_SOLO = false

UF.oUF = st.oUF
assert(UF.oUF, 'st was unable to locate oUF.')

UF.elements = {}

UF.unit_strings = {
	['player'] = 'Player',
	['target'] = 'Target',
	['targettarget'] = 'TargetTarget',
	['focus'] = 'Focus',
	['focustarget'] = 'FocusTarget',
	['pet'] = 'Pet',
	['pettarget'] = 'PetTarget',
	['boss'] = 'Boss',
	--['arena'] = 'Arena'
}

UF.group_strings = {
	['party'] = 'Party',
	['raid10'] = 'Raid 10',
	['raid40'] = 'Raid 40',
}

function UF:GetFrame(unitframe, configPosition)
    return unitframe[configPosition.element] or _G[configPosition.frame] or unitframe
end

function UF.ConstructUnit(self, unit)
	-- Ensure that we have access to a numberless unit type for config tables
	local base_unit = self:GetParent():GetAttribute('base_unit')
	if base_unit then
		self.is_group_unit = true
		self.base_unit = base_unit
	else
		self.base_unit = strmatch(unit, '(%D+)')
	end

	self.ID = tonumber(strmatch(self:GetName(), '(%d+)'))
	
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	
	-- Used as a parent to text objects to ensure they're always above status bars
	local textoverlay = CreateFrame('frame', nil, self)
	textoverlay:SetFrameLevel(99)
	textoverlay:SetAllPoints(self)
	self.TextOverlay = textoverlay
	
	-- self.config = st.config.profile.unitframes.units[self.base_unit]
	self.config = st.config.profile.unitframes.profiles[UF:GetProfile()][self.base_unit]
	
	-- Since oUF doesn't give us access to a table of active elements
	-- we can keep track of them here to easily loop and update through them later
	self.elements = {}
	for element_name, funcs in pairs(UF.elements) do
		if (not funcs.ValidUnit) or funcs.ValidUnit(base_unit) then
			self.elements[element_name] = funcs.Constructor(self, element_name)
		end
	end
	
	if self.base_unit == 'nameplate' then
		UF.nameplates[self.ID] = self
		UF:UpdateUnitFrame(self)
		self:EnableMouse(false)
		self.Health:EnableMouse(false)
		self.Power:EnableMouse(false)
		self:SetPoint('CENTER')
		self:SetScale(UIParent:GetEffectiveScale())
	end

	if self.is_group_unit then
		UF:UpdateUnitFrame(self)
	end
end

--[[
name (string): the name of the element to use as the key
Constructor (function): for actually creating the element and binding it to oUF
GetConfigTable (function): returns and AceConfig table for the element's configuration options.
UpdateConfig (function): the function used to update the display of the element based on the configuration table

All three functions take one argument - the unitframe object created from oUF:Spawn

]]--
function UF:RegisterElement(name, Constructor, UpdateConfig, ValidUnit)
	self.elements[name] = {
	    name = name,
		Constructor = Constructor,
		UpdateConfig = UpdateConfig,
		ValidUnit = ValidUnit
	}
end

function UF:UpdateColors()
	st.tablemerge(UF.oUF.colors.disconnected, st.config.profile.colors.status.disconnected, true)
	st.tablemerge(UF.oUF.colors.tapped, st.config.profile.colors.status.tapped, true)
	st.tablemerge(UF.oUF.colors.reaction, st.config.profile.colors.reaction, true)
	st.tablemerge(UF.oUF.colors.power, st.config.profile.colors.power, true)
	st.tablemerge(UF.oUF.colors.class, st.config.profile.colors.class, true)
	UF.oUF.colors.roles 		= st.config.profile.colors.roles
	UF.oUF.colors.runes 		= st.config.profile.colors.runes
end

function UF:UpdateUnitFrame(frame, element_name)
	frame.config = st.config.profile.unitframes.profiles[self:GetProfile()][frame.base_unit]

	if element_name and self.elements[element_name] then
        if self.elements[element_name].UpdateConfig then
            self.elements[element_name].UpdateConfig(frame, element_name)
        else
            self:UpdateElement(frame[element_name])
        end
	else
		if not (InCombatLockdown() or frame.base_unit == 'nameplate') then
			if frame.is_group_unit then
				local header = frame:GetParent()
				header:ClearAllPoints()
				header:SetPoint(st:UnpackPoint(frame.config.position))
			else
				frame:ClearAllPoints()
				if not frame.config.enable then
					frame:SetPoint('BOTTOMLEFT', UIParent, 'TOPRIGHT', 10000, 10000)
					return
				elseif frame.ID and frame.ID > 1 then
					frame:SetPoint('TOPLEFT', self.units[frame.base_unit][frame.ID-1], 'BOTTOMLEFT', 0, -frame.config.spacing)
				else
					frame:SetPoint(st:UnpackPoint(frame.config.position))
				end
			end
			st:SetSize(frame, frame.config.width, frame.config.height)
		end
		
		if frame.base_unit == 'nameplate' then
			st:SetSize(frame, frame.config.width, frame.config.height)
		end

		st:SetBackdrop(frame, frame.config.template)
		
		frame.Range = {
			insideAlpha = frame.config.range_alpha.inside,
			outsideAlpha = frame.config.range_alpha.outside
		}
		
		for element_name, element in pairs(frame.elements) do
            if self.elements[element_name].UpdateConfig then
                self.elements[element_name].UpdateConfig(frame, element_name)
            else
                self:UpdateElement(frame[element_name])
            end
		end
	end

	frame:UpdateAllElements('OnShow')
end

--[[
	Wrapper function for UpdateUnitFrame that allows you to update
		using unit string instead of the frame object. Also used 
		to update all group frames at once
]]
function UF:UpdateConfig(unit, element_name)
	if not unit then 
		for unit, frame in pairs(self.units) do
			UF:UpdateConfig(unit, element_name)
		end
		
		for unit,_ in pairs(self.groups) do
			UF:UpdateConfig(unit)
		end
		
		UF:UpdateConfig('nameplate')
	else
		if self.units[unit] then
			if unit == 'boss' or unit == 'arena' then
				for i,frame in pairs(self.units[unit]) do
					self:UpdateUnitFrame(frame, element_name)
				end
			else
				self:UpdateUnitFrame(self.units[unit], element_name)
			end
		elseif self.groups[unit] then
			self.groups[unit].config = st.config.profile.unitframes.profiles[self:GetProfile()][unit]

			for i=1,self.groups[unit]:GetNumChildren() do
				local frame = select(i, self.groups[unit]:GetChildren())
				if frame and frame.Health then
					self:UpdateUnitFrame(frame, element_name)
				end
			end
		elseif unit == 'nameplate' then
			for id, nameplate in pairs(self.nameplates) do
				self:UpdateUnitFrame(nameplate, element_name)
			end
		end
	end
end

function UF:CreateGroupHeaders()
	self.groups = {}

	local config = st.config.profile.unitframes.profiles[self:GetProfile()].party
	local party = self.oUF:SpawnHeader(
		'SaftUI_Party',
		nil,
		'custom [@raid1,exists] hide;show',
		"oUF-initialConfigFunction", [[
			local header = self:GetParent()
			self:SetWidth(header:GetAttribute("initial-width"))
			self:SetHeight(header:GetAttribute("initial-height"))
		]],
		"initial-width", config.width,
		"initial-height", config.height,
		"showParty", true,
		"showRaid", false,
		'showSolo', TEST_PARTY_SOLO,
		'showPlayer', TEST_PARTY_SOLO,
		"xOffset", config.spacing,
		"yOffset", config.spacing,
		"point", config.growthDirection,
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"maxColumns", config.maxColumns,
		"unitsPerColumn", config.unitsPerColumn,
		"columnSpacing", config.columnSpacing,
		"columnAnchorPoint", config.initialAnchor,
		"base_unit", "party"
	)

	party.config = config
	party:SetPoint(st:UnpackPoint(config.position))
	self.groups.party = party

	local config = st.config.profile.unitframes.profiles[self:GetProfile()].raid10
	local raid10 = self.oUF:SpawnHeader(
		'SaftUI_Raid10',
		nil,
		'custom [@raid11,exists] hide;[@raid1,exists] show;hide',
		"oUF-initialConfigFunction", [[
			local header = self:GetParent()
			self:SetWidth(header:GetAttribute("initial-width"))
			self:SetHeight(header:GetAttribute("initial-height"))
		]],
		"initial-width", config.width,
		"initial-height", config.height,
		"showParty", true,
		"showRaid", true,
		"showPlayer", true,
		"showSolo", TEST_PARTY_SOLO,
		"xOffset", config.spacing,
		"yOffset", config.spacing,
		"point", config.growthDirection,
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"maxColumns", config.maxColumns,
		"unitsPerColumn", config.unitsPerColumn,
		"columnSpacing", config.columnSpacing,
		"columnAnchorPoint", config.initialAnchor,
		"base_unit", "raid10"
	)

	raid10.config = config
	raid10:SetPoint(st:UnpackPoint(config.position))
	self.groups.raid10 = raid10

	local config = st.config.profile.unitframes.profiles[self:GetProfile()].raid40
	local raid40 = self.oUF:SpawnHeader(
		'SaftUI_Raid40',
		nil,
		'custom [@raid11,exists] show;hide',
		"oUF-initialConfigFunction", [[
			local header = self:GetParent()
			self:SetWidth(header:GetAttribute("initial-width"))
			self:SetHeight(header:GetAttribute("initial-height"))
		]],
		"initial-width", config.width,
		"initial-height", config.height,
		"showParty", true,
		"showRaid", true,
		"showPlayer", true,
		"showSolo", TEST_PARTY_SOLO,
		"xOffset", config.spacing,
		"yOffset", config.spacing,
		"point", config.growthDirection,
		"groupFilter", "1,2,3,4,5,6,7,8",
		"groupingOrder", "1,2,3,4,5,6,7,8",
		"groupBy", "GROUP",
		"maxColumns", config.maxColumns,
		"unitsPerColumn", config.unitsPerColumn,
		"columnSpacing", config.columnSpacing,
		"columnAnchorPoint", config.initialAnchor,
		"base_unit", "raid40"
	)

	raid40.config = config
	raid40:SetPoint(st:UnpackPoint(config.position))
	self.groups.raid40 = raid40
end

local function get_profiles()
	local profiles = {}
	num_profiles = 0
	for key,_ in pairs(st.config.profile.unitframes.profiles) do
		profiles[key] = key
		num_profiles = num_profiles + 1
	end
	return profiles, num_profiles
end

local function get_profile_exists(profile_name)
	for key,_ in pairs(st.config.profile.unitframes.profiles) do
		if key == profile_name then return true end
	end

	return false
end

local function get_num_profiles()
	return select(2, get_profiles())
end
--
--StaticPopupDialogs["SAFTUI_UF_PROFILE_NEW"] = {
--	text = "Enter a name for your new profile",
--	button1 = "Create",
--	button2 = "Cancel",
--	OnAccept = function(self)
--		local profile_name = self.editBox:GetText()
--		if not get_profile_exists(profile_name) then
--			if self.is_copy then
--				st.config.profile.unitframes.profiles[profile_name] = st.tablecopy(
--					st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile],
--					true
--				)
--			end
--			st.config.profile.unitframes.config_profile = profile_name
--			UF:UpdateConfig()
--			st.CF:Refresh()
--		end
--	end,
--	OnCancel = function (_,reason)
--	end,
--	whileDead = true,
--	hideOnEscape = true,
--	hasEditBox = true,
--}
--
--StaticPopupDialogs["SAFTUI_UF_PROFILE_DELETE"] = {
--	text = "Are you sure you wish to delete this profile?",
--	button1 = "Delete",
--	button2 = "Cancel",
--	OnAccept = function(self)
--		if get_num_profiles() > 1 then
--			st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile] = nil
--		end
--		st.config.profile.unitframes.config_profile = next(st.config.profile.unitframes.profiles)
--		UF:UpdateConfig()
--		st.CF:Refresh()
--	end,
--	OnCancel = function (_,reason)
--	end,
--	whileDead = true,
--	hideOnEscape = true,
--}
--
--
--StaticPopupDialogs["SAFTUI_UF_PROFILE_RENAME"] = {
--	text = "Enter a new profile name",
--	button1 = "Rename",
--	button2 = "Cancel",
--	OnAccept = function(self)
--
--	end,
--	OnCancel = function() end,
--	whileDead = true,
--	hideOnEscape = true,
--}
--
--StaticPopupDialogs["SAFTUI_UF_PROFILE_EXPORT"] = {
--	text = "",
--	button1 = "Close",
--	OnShow = function(self)
--		local data = st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile]
--		self.editBox:SetText(st.CF:Export(data))
--
--	end,
--	OnAccept = function(self)
--
--	end,
--	hasEditBox = true,
--	whileDead = true,
--	hideOnEscape = true,
--}
--
--StaticPopupDialogs["SAFTUI_UF_PROFILE_IMPORT"] = {
--	text = "",
--	button1 = "Close",
--	OnShow = function(self)
--		local data = st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile]
--		self.wideEditBox:Show()
--	end,
--	OnAccept = function(self)
--
--	end,
--	hasEditBox = true,
--	whileDead = true,
--	hideOnEscape = true,
--}
--
--StaticPopupDialogs["SAFTUI_UF_CONFIRM_UNIT_COPY"] = {
--	text = "",
--	button1 = "Copy",
--	button2 = "Cancel",
--	OnAccept = function(self)
--		local profile = st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile]
--		if not self.options.from then return end
--
--		for element,copy in pairs(self.options.elements) do
--			if copy then
--				if type(profile[self.options.from][element]) == 'table' then
--					profile[self.options.to][element] = st.tablecopy(profile[self.options.from][element], true)
--				else
--					profile[self.options.to][element] = profile[self.options.from][element]
--				end
--			end
--		end
--
--		UF:UpdateConfig()
--		st.CF:Refresh()
--
--		dialog:Close(st.addon_name..'_Copy_Unitframe')
--	end,
--	OnCancel = function() end,
--	whileDead = true,
--	hideOnEscape = true,
--}

function UF.GenerateRelativeSizeConfigGroup(order)
	return {
		order = order,
		name = '',
		type = 'group',
		inline = true,
		args = {
			width = st.CF.generators.width(1),
			relative_width = st.CF.generators.toggle(2, 'Relative', 1),
			height = st.CF.generators.height(3),
			relative_height = st.CF.generators.toggle(4, 'Relative', 1),
		},
	}
end


function UF:RegisterCopyTable()
	local config_table = {
		name = 'Copy from',
		type = 'group',
		args = {
			copy_from = {
				order = 0,
				name = 'Copy from',
				type = 'select',
				values = function() return {} end,
			},
			toggle_all = {
				order = 1,
				name = 'All',
				type = 'execute',
				func = function(self, info) end,
				width = 0.5,
			},
			toggle_none = {
				order = 1,
				name = 'None',
				type = 'execute',
				func = function(self, info) end,
				width = 0.5,
			},
			elements = {
				order = -99,
				name = '',
				type = 'group',
				inline = true,
				childGroups = 'inline',
				args = {}
			},
			accept = {
				order = -95,
				name = 'Confirm copy',
				type = 'execute',
				
			},
		},
	}

	UF.CopyTable = config_table
	LibStub('AceConfig-3.0'):RegisterOptionsTable(st.name ..'_Copy_Unitframe', config_table)
end

function UF:OpenCopyTable(unit)
	local config = st.config.profile.unitframes.profiles[st.config.profile.unitframes.config_profile]
	-- We use a local table of configurations and reset all of the setters and getters
	-- To ensure there's no funny business with accidentally not clearing old values

	local copy_options = {
		['to'] = unit,
		['elements'] = {}
	}
	
	for element,_ in pairs(config[unit]) do
		copy_options.elements[element] = false
		self.CopyTable.name = 'Clone '..unit..' from..'
		
		self.CopyTable.args.copy_from.set = function(info, from)
			copy_options.from = from
			self.CopyTable.name = 'Clone '..unit..' from '..from
		end
		self.CopyTable.args.copy_from.get = function(info) return copy_options.from end
		self.CopyTable.args.copy_from.values = function(info)
			local units = {}
			for key,_ in pairs(config) do
				if not (key == unit) then
					units[key] = key
				end
			end
			return units
		end

		self.CopyTable.args.toggle_all.func = function()
			for k,v in pairs(copy_options.elements) do
				copy_options.elements[k] = true
			end
			LibStub("AceConfigRegistry-3.0"):NotifyChange(st.name ..'_Copy_Unitframe')
		end

		self.CopyTable.args.toggle_none.func = function()
			for k,v in pairs(copy_options.elements) do
				copy_options.elements[k] = false
			end
			LibStub("AceConfigRegistry-3.0"):NotifyChange(st.name ..'_Copy_Unitframe')
		end

		self.CopyTable.args.elements.get = function(info)
			return copy_options.elements[info[#info]]
		end
		self.CopyTable.args.elements.set = function(info, value) 
			copy_options.elements[info[#info]] = value
		end
		
		self.CopyTable.args.elements.args[element] = st.CF.generators.toggle(0, element, 0.7)

		self.CopyTable.args.accept.func = function()
			if not copy_options.from then return end
			StaticPopupDialogs["SAFTUI_UF_CONFIRM_UNIT_COPY"].text = 'Are you sure you want to clone '..unit..' from ' .. copy_options.from .. '?'
			local popup = StaticPopup_Show('SAFTUI_UF_CONFIRM_UNIT_COPY')
			popup.options = copy_options
		end
	end

	dialog:SetDefaultSize(st.name ..'_Copy_Unitframe', 400, 300)
	dialog:Open(st.name ..'_Copy_Unitframe')
end

function UF:GetProfile()
	return st.config.profile.unitframes.config_profile
end

function UF:SetProfile(profile_name)
	if st.config.profile.unitframes.profiles[profile_name] then
		st.config.profile.unitframes.config_profile = profile_name
	end
end

function UF:OnInitialize()
	self.oUF:RegisterStyle('SaftUI', UF.ConstructUnit)
	self.oUF:SetActiveStyle('SaftUI')

	self.units = {}

	for unit, global_name in pairs(self.unit_strings) do
		if unit == 'boss' or unit == 'arena' then
			self.units[unit] = {}
			for i=1, 5 do
				self.units[unit][i] = self.oUF:Spawn(unit..i, 'SaftUI_'..global_name..i)
			end
		else
			self.units[unit] = self.oUF:Spawn(unit, 'SaftUI_'..global_name)
		end
	end

	
	self.nameplates = {}
	--st.oUF:SpawnNamePlates('SaftUI')

	self.RMH = RealMobHealth

	UF:CreateGroupHeaders()
end

function UF:OnEnable()
	UF:UpdateConfig()
	UF:UpdateColors()
end