local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')


local function Constructor(self)
	local portrait = CreateFrame('PlayerModel', nil, self)
	portrait.config = self.config.portrait
	
	self.Portrait = portrait
	return portrait
end

local function UpdateConfig(self)
	self.Portrait.config = self.config.portrait
	
	if self.config.portrait.enable == false then
		self.Portrait:Hide()
		return
	else
		self.Portrait:Show()
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
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			template = st.CF.generators.template(2),
			alpha = st.CF.generators.alpha(3),
			size = UF.GenerateRelativeSizeConfigGroup(4),
			position = st.CF.generators.position(5,
				self.config.portrait.position, false, 
				function() UF:UpdateConfig(self.unit, 'Portrait') end
			),
		}
	}
end

UF:RegisterElement('Portrait', Constructor, UpdateConfig, GetConfigTable)