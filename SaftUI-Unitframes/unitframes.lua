local _, ns = ...
local st = SaftUI
local UF = st:NewModule('Unitframes')
UF.oUF = ns.oUF
assert(UF.oUF, 'st was unable to locate oUF.')

local TEST_PARTY_SOLO = false

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
	--print(configPosition.element)
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
	if UF.unit_strings[self.base_unit] then
		self.unitLabel = UF.unit_strings[self.base_unit] .. (self.ID or '')
	end
	self:RegisterForClicks('AnyUp')
	self:SetScript('OnEnter', UnitFrame_OnEnter)
	self:SetScript('OnLeave', UnitFrame_OnLeave)
	
	-- Used as a parent to text objects to ensure they're always above status bars
	local textoverlay = CreateFrame('frame', nil, self)
	textoverlay:SetFrameLevel(99)
	textoverlay:SetAllPoints(self)
	self.TextOverlay = textoverlay

	self.config = UF:GetProfileConfig()[self.base_unit]
	self.GetConfig = function() return UF:GetProfileConfig()[self.base_unit]  end
	
	-- Since oUF doesn't give us access to a table of active elements
	-- we can keep track of them here to easily loop and update through them later
	self.elements = {}
	for element_name, funcs in pairs(UF.elements) do
		if (not funcs.ValidUnit) or funcs.ValidUnit(base_unit) then
			self.elements[element_name] = funcs.Constructor(self, element_name)
		end
	end

	if self.is_group_unit then
		UF:UpdateUnitFrame(self)
	else
		UF.allUnits[unit] = self
	end
end

--[[
name (string): the name of the element to use as the key
Constructor (function): for actually creating the element and binding it to oUF
GetConfigTable (function): returns and AceConfig table for the element's configuration options.
UpdateConfig (function): the function used to update the display of the element based on the configuration table

All three functions take one argument - the unitframe object created from oUF:Spawn

]]--
function UF:RegisterElement(name, Constructor, UpdateConfig, GetConfigTable, ValidUnit)
	self.elements[name] = {
	    name = name,
		Constructor = Constructor,
		UpdateConfig = UpdateConfig,
		GetConfigTable = GetConfigTable,
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
	frame.config = frame:GetConfig()

	if element_name and self.elements[element_name] then
        if self.elements[element_name].UpdateConfig then
            self.elements[element_name].UpdateConfig(frame, element_name)
        else
            self:UpdateElement(frame[element_name])
        end
	else
		if not (InCombatLockdown()) then
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

		st:SetBackdrop(frame, frame.config.template)
		
		frame.Range = {
			insideAlpha = frame.config.range_alpha.inside,
			outsideAlpha = frame.config.range_alpha.outside
		}
		
		for _element_name, element in pairs(frame.elements) do
            if self.elements[_element_name].UpdateConfig then
                self.elements[_element_name].UpdateConfig(frame, _element_name)
            else
                self:UpdateElement(frame[_element_name])
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
		'showPlayer', false,
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

function UF:OnEnable()
	self.oUF:RegisterStyle('SaftUI', UF.ConstructUnit)
	self.oUF:SetActiveStyle('SaftUI')

	self.units = {}
	self.allUnits = {}
	for unit, labelName in pairs(self.unit_strings) do
		if unit == 'boss' or unit == 'arena' then
			self.units[unit] = {}
			for i=1, 5 do
				self.units[unit][i] = self.oUF:Spawn(unit..i, 'SaftUI_'..labelName..i)
			end
		else
			self.units[unit] = self.oUF:Spawn(unit, 'SaftUI_'..labelName)
		end
	end

	self.RMH = RealMobHealth

	UF:CreateGroupHeaders()
	UF:UpdateConfig()
	UF:UpdateColors()

	for _, unitframe in pairs(self.units) do
		-- We're going to register boss and arena frames as a group instead, this filters then out
		if unitframe.unit then
			st:RegisterEditMode(unitframe, ("%s Unitframe"):format(unitframe.unitLabel), unitframe.config.position)
		end
	end
end