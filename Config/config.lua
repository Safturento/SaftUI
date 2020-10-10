local ADDON_NAME, st = ...
local AceSerializer = LibStub('AceSerializer-3.0')
local LibCompress = LibStub('LibCompress')
local LibBase64 = LibStub('LibBase64-1.0')

local MODULE_PANE_MIN_WIDTH = 150
local MODULE_PANE_DEFAULT_WIDTH = MODULE_PANE_MIN_WIDTH
local MODULE_PANE_ITEM_HEIGHT = 26
local MODULE_PANE_ITEM_SPACING = 0
local ACTIVE_PANE_MIN_WIDTH = 200
local ACTIVE_PANE_DEFAULT_WIDTH = 500
local WIDGET_MIN_UNIT_WIDTH = 150
local WIDGET_UNIT_HEIGHT = 30
local WIDGET_SPACING_VERTICAL = 4
local WIDGET_SPACING_HORIZONTAL = 4
local WIDGET_PADDING_HORIZONTAL = 10
local WIDGET_PADDING_VERTICAL = 10
local WINDOW_MIN_HEIGHT = 300
local WINDOW_DEFAULT_HEIGHT = 500

SLASH_SAFTUI1 = '/saftui'
SLASH_SAFTUI2 = '/sui'
SLASH_SAFTUI3 = '/stui'

SlashCmdList.SAFTUI = function(msg)
	if not st.config_initialized then
		st.CF:InitializeConfigGUI()
		st.config_initialized = true
	end

	if InCombatLockdown() then
		st:Print('Config will open after combat')
		config_queued = true
	else
		--ACD:Open(ADDON_NAME)
	end
end

local Config = st:NewModule('Config')
Config.Modules = {
	name = 'Config',
	subModules = {}
}

local function wrapWidget(widget)
	local wrapper = st:CreateFrame('frame', widget:GetName().."_Wrapper", Config.activePane)
	wrapper:SetHeight(WIDGET_UNIT_HEIGHT)
	st:SetBackdrop(wrapper, 'thin')
	widget:SetPoint('LEFT', wrapper, WIDGET_PADDING_HORIZONTAL, 0)
	widget:SetParent(wrapper)
	wrapper.widget = widget
	return wrapper


end

Config.WidgetTypes = {
	SECTION = 'Section',
	CHECKBOX = 'CheckBox',
	EDITBOX = 'EditBox'
}

Config.WidgetPools = {
	[Config.WidgetTypes.CHECKBOX] = CreateWidgetPool(function(self)
		local checkBox = st.Widgets:CheckBox('SaftUI_Config_CheckBox' .. self.numActiveObjects + 1, Config.activePane)
		return wrapWidget(checkBox)
	end),
	[Config.WidgetTypes.EDITBOX] = CreateWidgetPool(
		function(self)
			local editBox = st.Widgets:EditBox('SaftUI_Config_EditBox' .. self.numActiveObjects+1, Config.activePane)
			editBox:SetHeight(20)
			return wrapWidget(editBox)
		end,
		function(self, wrapper, width)
			wrapper:SetHeight(54)
			wrapper.widget:ClearAllPoints()
			wrapper.widget:SetPoint('BOTTOMLEFT', WIDGET_PADDING_HORIZONTAL, WIDGET_PADDING_VERTICAL)
			wrapper.widget:SetPoint('BOTTOMRIGHT', -WIDGET_PADDING_HORIZONTAL, WIDGET_PADDING_VERTICAL)
			--if width then
			--	wrapper.widget:SetWidth(width - 2 * WIDGET_PADDING_HORIZONTAL)
			--end
		end
	),
	[Config.WidgetTypes.SECTION] = CreateWidgetPool(
		function(self)
			local section = st:CreateFrame('frame', 'SaftUI_Config_Section'..self.numActiveObjects + 1, Config.activePane)
			section.Label = section:CreateFontString(nil, 'OVERLAY')
			section.Label:SetPoint('BOTTOMLEFT', section, 'TOPLEFT', 3, 5)
			section.Label:SetFontObject(st:GetFont('normal'))
			section.SetLabel = function(self, text) self.Label:SetText(text) end
			wrapper = wrapWidget(section)
			section:SetAllPoints(wrapper)
			return wrapper
		end
	)
}
st.CF = Config


function Config:Export(data)
	return LibBase64.Encode(
		LibCompress:Compress(
	AceSerializer:Serialize(data)))
end

function Config:Import(string)
	return AceSerializer:Deserialize(
				 LibCompress:Decompress(
						 LibBase64:Decode(data)))
end

function Config:InitializeConfigGUI()
	local defaultWidth = MODULE_PANE_DEFAULT_WIDTH + ACTIVE_PANE_DEFAULT_WIDTH
	local configWindow = st:CreatePanel("SaftUI Config", defaultWidth, WINDOW_DEFAULT_HEIGHT)
	configWindow:SetPoint("CENTER")
	st:EnableResizing(configWindow)
	configWindow:SetMinResize(MODULE_PANE_MIN_WIDTH + ACTIVE_PANE_MIN_WIDTH, WINDOW_MIN_HEIGHT)
	self.window = configWindow

	local modulePane = st:CreateFrame('frame', configWindow:GetName() .. '_ModulePane', configWindow)
	modulePane:SetPoint('TOPLEFT', configWindow.header, 'BOTTOMLEFT', 0, 0)
	modulePane:SetPoint('BOTTOMLEFT', configWindow, 'BOTTOMLEFT', 0, 0)
	modulePane:SetWidth(MODULE_PANE_MIN_WIDTH)
	st:EnableResizing(modulePane)
	modulePane:SetMinResize(MODULE_PANE_MIN_WIDTH, WINDOW_MIN_HEIGHT)
	st:SetTemplate(modulePane, 'thin')
	modulePane:SetBackdropBorderColor(modulePane:GetBackdropColor())
	modulePane.rows = {}
	self.modulePane = modulePane

	local activePane = st:CreateFrame('frame', configWindow:GetName() .. '_ActivePane', configWindow)
	activePane:SetPoint('TOPLEFT', modulePane, 'TOPRIGHT', 0, 0)
	activePane:SetPoint('BOTTOMLEFT', modulePane, 'BOTTOMRIGHT', 0, 0)
	activePane.UpdateSize = function(self)
		self:SetWidth((configWindow:GetWidth() - modulePane:GetWidth()))
		self:SetHeight(configWindow:GetHeight() - configWindow.header:GetHeight())
	end
	activePane:UpdateSize()
	self.activePane = activePane

	modulePane.UpdateSize = function(self)
		self:ClearAllPoints()
		self:SetPoint('TOPLEFT', configWindow.header, 'BOTTOMLEFT', 0, 0)
		self:SetPoint('BOTTOMLEFT', configWindow, 'BOTTOMLEFT', 0, 0)
		self:SetHeight(configWindow:GetHeight() - configWindow.header:GetHeight())
	end

	modulePane:SetScript('OnSizeChanged', function()
		activePane:UpdateSize()
		modulePane:UpdateSize()
		Config:UpdateActiveWidgets()
	end)

	configWindow:HookScript('OnSizeChanged', function()
		modulePane:UpdateSize()
	end)

	self:Test()

	self:UpdateModulePane()

	self:SetActiveModule(self.defaultModule)
end

function Config:UpdateModulePane()
	local numItems = floor(self.modulePane:GetHeight()/(MODULE_PANE_ITEM_HEIGHT  + MODULE_PANE_ITEM_SPACING))

	local scrollOffset = 0
	local modules = self:GetModuleTree()

	for i = 1, numItems do
		local row = self.modulePane.rows[i]
		if not row then
			row = st:CreateFrame('Button', self.modulePane:GetName() .. 'Row'..i, self.modulePane)
			row:SetFrameLevel(self.modulePane:GetFrameLevel() + 2)
			if i == 1 then
				st:SnapTopAcross(row, self.modulePane)
			else
				st:SnapBelowAcross(row, self.modulePane.rows[i-1], MODULE_PANE_ITEM_SPACING)
			end
			row:SetHeight(MODULE_PANE_ITEM_HEIGHT)
			row.Text = row:CreateFontString(nil, 'OVERLAY')
			row.Text:SetFontObject(st:GetFont('normal'))
			row.Text:SetPoint('LEFT', 5, 0)
			self.modulePane.rows[i] = row
		end

		local module = modules[i+scrollOffset]
		if not module then
			row:Hide()
		else
			row:Show()
			local indent = ''
			for _=0, module.indent do indent = indent .. '  ' end
			row.Text:SetText(indent .. module.name)
		end
	end
end

function Config:OpenConfigGui()
	self.window:Show()
	st:EnableMovers()
end

function Config:CloseConfigGui()
	self.window:Hide()
	st:DisableMovers()
end

function Config:ToggleConfigGui()
	if self.window:IsShown() then
		self:CloseConfigGui()
	else
		self:OpenConfigGui()
	end
end

--[[
	pass config key values as separate meters to get nested module
	e.g. to get unitframes player health config you'd  pass
	Config:GetModule('Unitframes', 'Player', 'Health')
]]
function Config:GetModule(...)
	local parent = self.Modules
	for i = 1, select('#', ...) do
		module = select(i, ...)
		if parent.subModules[module] then
			parent = parent.subModules[module]
		else
			st:Error(('No module named %s in %s module'):format(module, parent.name))
			return
		end
	end
	return parent
end

--[[
	Registers a new module into the config table
	moduleName : the display name and table key of the module
	configTable : contains all information about that  module's config options
	... : chain of parent modules
	example - create empty config table for Health config for player unitframes:

	Config:RegisterModule('Health', { }, 'Unitframes', 'Player')
]]
function Config:RegisterModule(moduleName, configTable, ...)
	local parent = self:GetModule(...)
	if not parent then return end
	if self:ValidateModuleConfig(moduleName, configTable) then
		parent.subModules[moduleName] = {
			name = moduleName,
			subModules = {},
			configTable = configTable or {}
		}
	end
end

-- Same parameters as RegisterModule, will left join your new table into the existing table
function Config:UpdateModuleConfig(moduleName, configTable, ...)
	if self:ValidateModuleConfig(moduleName, configTable) then
		st.tablemerge(self:GetModule(...).subModules[moduleName].configTable, configTable)
	end
end

-- Same parameters as RegisterModule, will replace the existing configTable with your new one
function Config:SetModuleConfig(moduleName, configTable, ...)
	if self:ValidateModuleConfig(moduleName, configTable) then
		self:GetModule(...).subModules[moduleName].configTable = configTable
	end
end

function Config:ValidateModuleConfig(moduleName, configTable)
	for _, widgetConfig in ipairs(configTable) do
		if not self.WidgetPools[widgetConfig.type] then
			st:Error(('Invalid widget %s in %s module'):format(widgetConfig.type, moduleName))
			return false
		end
	end

	return true
end

function Config:SetDefaultModule(moduleName)
	if self:GetModule(moduleName) then
		self.defaultModule = moduleName
	else
		st:Error(("Failed to set default module: module %s does not exist"):format(moduleName))
	end
end

function Config:GetDefaultModule()
	return self.defaultModule
end


function Config:PositionActiveWidgets(section)
	local width = self.activePane:GetWidth()
	local unitsPerRow = floor((width - 2*WIDGET_SPACING_HORIZONTAL) / (WIDGET_MIN_UNIT_WIDTH + 2*WIDGET_SPACING_HORIZONTAL))
	local unitsLeft = unitsPerRow
	local prevRow
	local prevWidget
	for _,widget in pairs(section and section.widgets or self.activeWidgets) do
		if widget.type == Config.WidgetTypes.SECTION then
			Config:PositionActiveWidgets(widget)
		end
		if not (prevRow or prevWidget) then
		--First widget
			st:SnapTopLeft(widget, self.activePane, WIDGET_SPACING_HORIZONTAL)
			prevRow = widget
			prevWidget = widget
		elseif unitsLeft < widget.config.width then
		-- New row
			st:SnapBelowLeft(widget, prevRow, WIDGET_SPACING_VERTICAL)
			prevRow = widget
			prevWidget = widget
			unitsLeft = unitsPerRow
		else
		--	Keep going on same row
			st:SnapTopRightOf(widget, prevWidget, WIDGET_SPACING_HORIZONTAL)
			prevWidget = widget
		end
		unitsLeft = unitsLeft - widget.config.width
	end
end

function Config:UpdateActiveWidgets(section)
	if not section then section = self.activePane end

	local sectionWidth = section:GetWidth()
	local unitsPerRow = floor((sectionWidth - 2*WIDGET_SPACING_HORIZONTAL) / (WIDGET_MIN_UNIT_WIDTH + 2*WIDGET_SPACING_HORIZONTAL))
	local unitWidth = floor((sectionWidth - 2*WIDGET_SPACING_HORIZONTAL) / (unitsPerRow) - WIDGET_SPACING_HORIZONTAL)
	print(sectionWidth, unitsPerRow, unitWidth)
	local unitsLeft = unitsPerRow
	local prevRow, prevWidget
	for _, widgetWrapper in pairs(section.widgets) do
		local widgetUnits = widgetWrapper.config.width == 0 and unitsPerRow or widgetWrapper.config.width
		local widgetWidth = unitWidth * widgetUnits
		widgetWrapper:SetWidth(widgetWidth + (widgetUnits - 1) * (WIDGET_SPACING_HORIZONTAL + 1))

		if not (prevRow or prevWidget) then
		--First widget
			st:SnapTopLeft(widgetWrapper, section, WIDGET_SPACING_HORIZONTAL)
			prevRow = widgetWrapper
			prevWidget = widgetWrapper
		elseif unitsLeft < widgetUnits then
		-- New row
			st:SnapBelowLeft(widgetWrapper, prevRow, WIDGET_SPACING_VERTICAL)
			prevRow = widgetWrapper
			prevWidget = widgetWrapper
			unitsLeft = unitsPerRow
		else
		--	Keep going on same row
			st:SnapTopRightOf(widgetWrapper, prevWidget, WIDGET_SPACING_HORIZONTAL)
			prevWidget = widgetWrapper
		end
		unitsLeft = unitsLeft - widgetUnits

		if widgetWrapper.config.type == Config.WidgetTypes.SECTION then
			Config:UpdateActiveWidgets(widgetWrapper)
		end
	end

end

function Config:PopulateWidgets(configTable, section)
	if not (configTable and section) then
		configTable = self.activeModule.configTable
		section = self.activePane

		for _,pool in pairs(self.WidgetPools) do
			pool:ReleaseAll()
		end
	end

	section.widgets = {}
	for _, widgetConfig in ipairs(configTable) do
		local widgetWrapper = self.WidgetPools[widgetConfig.type]:Acquire(widgetWidth)
		widgetWrapper.config = widgetConfig
		if widgetConfig.label and widgetWrapper.widget.SetLabel then
			widgetWrapper.widget:SetLabel(widgetConfig.label)
		end
		if widgetConfig.type == Config.WidgetTypes.SECTION then
			self:PopulateWidgets(widgetConfig.configTable, widgetWrapper)
			self:UpdateActiveWidgets()
		end
		tinsert(section.widgets, widgetWrapper)
	end
end

function Config:SetActiveModule(moduleName)
	local activeModule = self:GetModule(moduleName)
	if activeModule then
		self.activeModule = activeModule
		self:PopulateWidgets()
	else
		st:Error(("Failed to set active module: module %s does not exist"):format(moduleName))
	end
end

function Config:GetActiveModule()
	return self.activeModule
end

function Config:GetModuleTree(tree, parent, indent)
	if not parent then
		tree, parent, indent =
			{}, self.Modules, 0
	end

	tinsert(tree, { name = parent.name, indent = indent })
	for subModuleName, subModule in pairs(parent.subModules) do
		Config:GetModuleTree(tree, subModule, indent + 1)
	end

	return tree
end

function Config:CheckBox(label, onClick, width)
	return {
		type = Config.WidgetTypes.CHECKBOX,
		label = label,
		onClick = onClick,
		width = width or 1
	}
end

function Config:EditBox(label, onChange, width)
	return {
		type = Config.WidgetTypes.EDITBOX,
		label = label,
		onChange = onChange,
		width = width or 1
	}
end

function Config:Section(label, configTable, width)
	return {
		type = Config.WidgetTypes.SECTION,
		label = label,
		configTable = configTable,
		width = width or 0
	}
end

function Config:Test()
	self:RegisterModule('general', {
		self:CheckBox('CheckBox 1'),
		self:CheckBox('CheckBox 1'),
		self:CheckBox('CheckBox 2'),
		self:CheckBox('CheckBox 3'),
		self:CheckBox('CheckBox 4'),
		self:CheckBox('CheckBox 5'),
		self:CheckBox('CheckBox 6'),
		self:EditBox('EditBox 1', nil, 2),
		self:Section('Misc', {
			self:CheckBox('CheckBox 7'),
			self:CheckBox('CheckBox 8'),
			self:EditBox('EditBox 2', nil, 1),
			self:EditBox('EditBox 3', nil, 2),
			self:CheckBox('CheckBox 9'),
			self:CheckBox('CheckBox 10'),
			self:Section('Nested Section', {
				self:CheckBox('CheckBox 11'),
				self:CheckBox('CheckBox 12'),
			})
		})
	})

	self:RegisterModule('unitframes', {})
	self:RegisterModule('player', {}, 'unitframes')
	self:RegisterModule('actionbars', {})

	self:SetDefaultModule('general')
end