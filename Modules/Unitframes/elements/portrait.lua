local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')


local function Constructor(self)
	local portrait = CreateFrame('PlayerModel', nil, self)
	portrait.config = self.config.portrait
	
	self.Portrait = portrait
	return portrait
end

local function UpdateConfig(self)
	if self.config.portrait.enable == false then
		self:DisableElement('Portrait')
		return
	else
		self:EnableElement('Portrait')
	end

	if self.config.portrait.relative_height then
		self.Portrait:SetHeight(self.config.height + self.config.portrait.height)
	else
		self.Portrait:SetHeight(self.config.portrait.height)
	end

	if self.config.portrait.relative_width then
		self.Portrait:SetWidth(self.config.width + self.config.portrait.width)
	else
		self.Portrait:SetWidth(self.config.portrait.width)
	end

	st:SetBackdrop(self.Portrait, self.config.portrait.template)

	self.Portrait:ClearAllPoints()
	local anchor, rel_anchor, x_off, y_off = unpack(self.config.portrait.position)
	self.Portrait:SetPoint(anchor, self, rel_anchor, x_off, y_off)
	self.Portrait:SetFrameLevel(self.config.portrait.framelevel)
	self.Portrait:SetAlpha(self.config.portrait.alpha)
end

local function GetConfigTable(self)
	return {
		type = 'group',
		name = 'Portrait',
		get = function(info)
			return self.config.portrait[info[#info]]
		end,
		set = function(info, value)
			self.config.portrait[info[#info]] = value
			UF:UpdateConfig(self.unit, 'Portrait')
		end,
		args = {
			enable = {
				order = 0,
				name = 'Enable',
				type = 'toggle',
				width = 0.5,
			},
			framelevel = {
				order = 1,
				name = 'Frame Level',
				type = 'range',
				min = 0,
				max = 99,
				step = 1,
				width = 1,
			},
			alpha = {
				order = 1,
				name = 'Alpha',
				type = 'range',
				min = 0,
				max = 1,
				step = 0.05,
				width = 0.5,
			},
			height = {
				order = 2,
				name = 'Height',
				type = 'input',
				pattern = '%d+',
				width = 0.5,
			},
			width = {
				order = 3,
				name = 'Width',
				type = 'input',
				pattern = '%d+',
				width = 0.5,
			},
			template = {
				order = 4,
				name = 'Template',
				type = 'select',
				values = st.CF:GetFrameTemplates(),
			},
			position = st.CF.generators.position(
				self.config.portrait.position, false, 5, nil, 
				function() UF:UpdateConfig(self.unit, 'Portrait') end
			),
		}
	}
end

UF:RegisterElement('Portrait', Constructor, UpdateConfig, GetConfigTable)