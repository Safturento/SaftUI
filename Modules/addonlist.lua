local ADDON_NAME, st = ...

local AM = st:NewModule('AddonManager', 'AceHook-3.0', 'AceEvent-3.0')

function AM:OnInitialize()
	self.addon_cache = {}
	self.rows = {}
	self.sort_priority = {}

	local manager = CreateFrame('frame', ADDON_NAME..'AddonManager', UIParent)
	manager.close_button = CreateFrame('Button', nil, manager)
	manager.close_button:SetScript('OnClick', function() manager:Hide() end)
	st:CreateHeader(manager, 'Addons', manager.close_button)
	manager:SetFrameStrata('HIGH')
	manager:EnableMouse(true)
	manager:SetScript('OnMouseWheel', function(_, delta)
		local jump = IsShiftKeyDown() and self.config.num_rows or 10
		local num_addons = GetNumAddOns()
		if delta < 0 and self.config.num_rows + self.offset < num_addons then
			self.offset = self.offset + jump
		elseif delta > 0 and self.offset > 0 then
			self.offset = self.offset - jump
		end
		self.offset = max(0, self.offset)
		self.offset = min(self.offset, num_addons - self.config.num_rows)
		self.row_frame.scroll:SetValue(self.offset)
		self:UpdateAddonDisplay()
	end)

	tinsert(UISpecialFrames, manager:GetName())
	manager:SetUserPlaced(false)

	self.window = manager
	self.window:Hide()

	self.row_headers = CreateFrame('frame', nil, self.window)
	self.row_headers:SetPoint('TOPLEFT', self.window.header, 'BOTTOMLEFT', 20, -20)
	self.row_headers:SetPoint('TOPRIGHT', self.window.header, 'BOTTOMRIGHT', -20, -20)
	self.row_headers:SetHeight(20)
	
	self.row_headers.status = CreateFrame('Button', nil, self.row_headers)
	self.row_headers.status:SetHeight(20)
	self.row_headers.status.text = self.row_headers.status:CreateFontString(nil, 'OVERLAY')
	self.row_headers.status.text:SetFontObject('GameFontNormal')
	self.row_headers.status.text:SetPoint('LEFT', 0, 0)
	self.row_headers.status.text:SetText('Status')
	self.row_headers.status:SetWidth(70)
	self.row_headers.status:SetPoint('RIGHT')
	self.row_headers.status:SetScript('OnClick', function()
		self:UpdateSortPriority('status', 'down')
		self:UpdateAddonDisplay()
	end)
	
	self.row_headers.memory = CreateFrame('Button', nil, self.row_headers)
	self.row_headers.memory:SetHeight(20)
	self.row_headers.memory.text = self.row_headers.memory:CreateFontString(nil, 'OVERLAY')
	self.row_headers.memory.text:SetFontObject('GameFontNormal')
	self.row_headers.memory.text:SetPoint('RIGHT', 0, 0)
	self.row_headers.memory.text:SetText('Memory')
	self.row_headers.memory:SetWidth(60)
	self.row_headers.memory:SetPoint('RIGHT', self.row_headers.status, 'LEFT')
	self.row_headers.memory:SetScript('OnClick', function()
		self:UpdateSortPriority('memory', 'down')
		self:UpdateAddonDisplay()
	end)
	self.row_headers.memory:SetScript('OnEnter', function(self)
		local total = 0
		for i=1, GetNumAddOns() do
			total = total + GetAddOnMemoryUsage(i)
		end

		GameTooltip:SetOwner(self, 'ANCHOR_NONE')
		GameTooltip:ClearAllPoints()
		GameTooltip:SetPoint('TOPLEFT', AM.window, 'TOPRIGHT', 10, 0)
		GameTooltip:AddLine('Total Usage: ' .. st.StringFormat:FileSizeFormat(total*1000, 1))
		GameTooltip:Show()
	end)
	self.row_headers.memory:SetScript('OnLeave', function() GameTooltip:Hide() end)

	self.row_headers.name = CreateFrame('Button', nil, self.row_headers)
	self.row_headers.name:SetHeight(20)
	self.row_headers.name.text = self.row_headers.name:CreateFontString(nil, 'OVERLAY')
	self.row_headers.name.text:SetFontObject('GameFontNormal')
	self.row_headers.name.text:SetPoint('LEFT', 30, 0)
	self.row_headers.name.text:SetText('Title')
	self.row_headers.name:SetPoint('RIGHT', self.row_headers.memory, 'LEFT')
	self.row_headers.name:SetPoint('LEFT')
	self.row_headers.name:SetScript('OnClick', function()
		self:UpdateSortPriority('index', 'up')
		self:UpdateAddonDisplay()
	end)

	self:UpdateSortPriority('index', 'up')

	self.row_frame = CreateFrame('frame', nil, self.window)
	self.row_frame:SetPoint('TOPLEFT', self.row_headers, 'BOTTOMLEFT')
	self.row_frame:SetPoint('TOPRIGHT', self.row_headers, 'BOTTOMRIGHT')

	self.row_frame.scroll = CreateFrame('Slider', nil, self.row_frame, 'UIPanelScrollBarTemplate')
	self.row_frame.scroll:SetPoint('TOPLEFT', self.row_frame, 'TOPRIGHT')
	self.row_frame.scroll:SetScript('OnValueChanged', function(_, value) 
		self.offset = floor(value)
		self:UpdateAddonDisplay()
	end)
	st:SkinScrollBar(self.row_frame.scroll)
	self.row_frame.scroll.ThumbTexture:SetWidth(10)
	
	self.buttons = CreateFrame('frame', nil, self.window)
	self.buttons:SetPoint('TOPLEFT', self.row_frame, 'BOTTOMLEFT', 0, -20)
	self.buttons:SetPoint('TOPRIGHT', self.row_frame, 'BOTTOMRIGHT', 0, -20)
	self.buttons.buttons = {
		enable_all = AddonList.EnableAllButton,
		disable_all = AddonList.DisableAllButton,
		cancel = AddonList.CancelButton,
		okay = AddonList.OkayButton,
	}
	for key, button in pairs(self.buttons.buttons) do
		button:SetParent(self.buttons)
		st:StripTextures(button)
		st.SkinActionButton(button)
		button:ClearAllPoints()
		button:SetWidth(button:GetTextWidth()+20)
		button:SetPoint('TOP')
		button:SetPoint('BOTTOM')
	end
	self.buttons.buttons.enable_all:SetPoint('LEFT', self.buttons)
	self.buttons.buttons.disable_all:SetPoint('LEFT', self.buttons.buttons.enable_all, 'RIGHT', 7, 0)
	self.buttons.buttons.cancel:SetPoint('RIGHT')
	self.buttons.buttons.okay:SetPoint('RIGHT', self.buttons.buttons.cancel, 'LEFT', -7, 0)
	self.buttons.buttons.okay:SetScript('OnClick', function()
		if self.changed then
			SaveAddOns()
			ReloadUI()
		end
	end)
	self.buttons.buttons.cancel:SetScript('OnClick', function()
		ResetAddOns()
		self.window:Hide()
	end)

	self.config = st.config.profile.addon_manager
	self.offset = 0
	
	self:UpdateConfig()
	self.row_frame.scroll:SetValue(0)

	GameMenuButtonAddons:SetScript('OnClick', nil)
	self:HookScript(GameMenuButtonAddons, 'OnClick', 'OnShow')
end

function AM:RemoveSortPriority(column)
	for i=1, #self.sort_priority do
		if self.sort_priority[i].column == column then
			tremove(self.sort_priority, i)
			break
		end
	end

end

function AM:UpdateSortPriority(column, direction)
	for i=1, #self.sort_priority do
		if self.sort_priority[i].column == column then
			if self.sort_priority[i].direction == 'up' then
				direction = 'down'
			else
				direction = 'up'
			end
			tremove(self.sort_priority, i)
			break
		end
	end

	tinsert(self.sort_priority, 1, {column = column, direction = direction})
	return direction
end

function AM:OnShow()
	HideUIPanel(GameMenuFrame)
	self.window:Show()
	self:UpdateAddonCache()
	self:UpdateAddonDisplay()
end

function AM:AddRow()
	local id = #self.rows + 1
	local row = CreateFrame('frame', nil, self.window)
	row.id = id

	local enable = CreateFrame('CheckButton', nil, row, 'UICheckButtonTemplate')
	enable:SetPoint('LEFT')
	enable:SetSize(self.config.row_height, self.config.row_height)
	st:SkinCheckButton(enable)
	row.enable_button = enable
	row.enable_button:HookScript('OnClick', function(self)
		AM.changed = true
		local index = self:GetParent().index
		local checked = self:GetChecked()
		AM.addon_cache[index].checked = checked
		if checked then
			EnableAddOn(index)
		else
			DisableAddOn(index)
		end
	end)
	

	local status = row:CreateFontString(nil, 'OVERLAY')
	status:SetFontObject('GameFontNormal')
	status:SetText('-')
	status:SetPoint('RIGHT')
	status:SetJustifyH('LEFT')
	status:SetWidth(self.row_headers.status:GetWidth())
	row.status = status

	local memory = row:CreateFontString(nil, 'OVERLAY')
	memory:SetFontObject('GameFontNormal')
	memory:SetText('-')
	memory:SetPoint('RIGHT', status, 'LEFT', -5, 0)
	memory:SetWidth(self.row_headers.memory:GetWidth())
	memory:SetJustifyH('RIGHT')
	row.memory = memory

	local name = row:CreateFontString(nil, 'OVERLAY')
	name:SetWordWrap(false)
	name:SetFontObject('GameFontNormal')
	name:SetJustifyH('LEFT')
	name:SetText('Addon '..id)
	name:SetPoint('LEFT', enable, 'RIGHT', 10, 0)
	name:SetPoint('RIGHT', memory, 'LEFT', -10, 0)
	row.name = name
	
	self.rows[id] = row
	return row
end


function AM:UpdateAddonCache()
	UpdateAddOnMemoryUsage()
	UpdateAddOnCPUUsage()
	local addons = {}
	local name, title, notes, enabled, loadable, reason, security, mem, cpu
	for i=1, GetNumAddOns() do
		name, title, notes, loadable, reason, security = GetAddOnInfo(i)
		enabled = IsAddOnLoaded(i)
		tinsert(addons, {
			index = i,
			name = name,
			author = GetAddOnMetadata(i, 'Author'),
			version = GetAddOnMetadata(i, 'Version'),
			title = title,
			notes = notes,
			enabled = enabled,
			checked = enabled,
			loadable = loadable,
			status = (enabled and 1) or (loadable and 0) or -1,
			reason = reason,
			security = security,
			memory = GetAddOnMemoryUsage(i),
			cpu = GetAddOnCPUUsage(i),
			dependencies = GetAddOnDependencies(i)
		})
	end

	self.addon_cache = addons
	return addons
end

function AM.sort(a, b)
	for i,v in ipairs(AM.sort_priority) do
		if not (a[v.column] == b[v.column]) then
			if v.direction == 'up' then
				return a[v.column] < b[v.column]
			end
			return a[v.column] > b[v.column]
		end
	end
end

function AM:UpdateAddonDisplay()
	local addon, index
	if #self.addon_cache == 0 then
		print(self)
		self:UpdateAddonCache()
	end
	
	table.sort(self.addon_cache, self.sort)

	for i,row in ipairs(self.rows) do
		index = i + self.offset
		addon = self.addon_cache[index]
		row.index = index
		row.enable_button:SetChecked(addon.checked)
		row.name:SetText(addon.title)
		row.memory:SetText(addon.memory > 0 and st.StringFormat:FileSizeFormat(addon.memory*1000, 1) or '')

		row:EnableMouse(true)
		row:SetScript('OnEnter', function()
			GameTooltip:SetOwner(self.window, 'ANCHOR_NONE')
			GameTooltip:ClearAllPoints()
			GameTooltip:SetPoint('TOPLEFT', self.window, 'TOPRIGHT', 10, 0)
			GameTooltip:ClearLines()
			addon = self.addon_cache[row.index]
			GameTooltip:AddDoubleLine(addon.title, addon.version or '')
			
			if addon.author then
				GameTooltip:AddLine('By '.. addon.author)
			end
			
			GameTooltip:AddLine(addon.notes, 1, 1, 1, 1)
			
			if addon.dependencies then
				GameTooltip:AddDoubleLine('Dependencies:', addon.dependencies)
			end
			
			GameTooltip:Show()
		end)
		row:SetScript('OnLeave', function()
			GameTooltip:Hide()
		end)

		if addon.enabled then
			row.status:SetText('Enabled')
			row.status:SetVertexColor(unpack(st.config.profile.colors.text.green))
		elseif addon.loadable then
			row.status:SetText('Loadable')
			row.status:SetVertexColor(unpack(st.config.profile.colors.text.yellow))
		else
			row.status:SetText('Disabled')
			row.status:SetVertexColor(unpack(st.config.profile.colors.text.grey))
		end
	end
end

function AM:UpdateConfig()
	self.window:SetWidth(400)
	st:SetBackdrop(self.window, st.config.profile.panels.template)

	self.row_frame:SetHeight(self.config.num_rows * self.config.row_height)
	self.row_frame.scroll:SetHeight(self.row_frame:GetHeight())
	st:SetBackdrop(self.row_frame.scroll.ThumbTexture, st.config.profile.panels.template)
	self.row_frame.scroll:SetMinMaxValues(0, GetNumAddOns() - self.config.num_rows)
	self.row_headers:SetHeight(self.config.row_height)

	local font = st:GetFont(self.config.font)
	self.row_headers.name.text:SetFontObject(font)
	self.row_headers.memory.text:SetFontObject(font)
	self.row_headers.status.text:SetFontObject(font)

	
	local prev, row = self.row_headers
	for i=1, self.config.num_rows do
		row = self.rows[i] or self:AddRow()
		row:SetHeight(self.config.row_height)
		row:ClearAllPoints()
		row.name:SetFontObject(font)
		row.memory:SetFontObject(font)
		row.status:SetFontObject(font)
		row:SetPoint('RIGHT', self.window, -20, 0)
		row:SetPoint('TOPLEFT', prev, 'BOTTOMLEFT', 0, 0)
		
		prev = row
	end

	self.buttons:SetHeight(self.config.row_height)
	
	local height = st.config.profile.headers.height + self.row_frame:GetHeight() + self.row_headers:GetHeight() + self.buttons:GetHeight() + 60
	self.window:SetHeight(height)
	
	-- We use this weird offset instead of anchoring to center to ensure that
	-- we retail pixel perfect borders with frames that have an even height
	self.window:ClearAllPoints()
	local w, h = self.window:GetSize()
	self.window:SetPoint('TOPLEFT', UIParent, 'CENTER', -floor(w/2), floor(h/2))
end