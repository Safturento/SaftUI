local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local function Constructor(self)
	local name = self.TextOverlay:CreateFontString(nil, 'OVERLAY')

	self.Name = name
	return name
end

local function UpdateConfig(self)
	self.Name.config = self.config.name
	if self.config.name.enable == false then
		self.Name:Hide()
		return
	else
		self.Name:Show()
	end

	self.Name:SetFontObject(st:GetFont(self.config.name.font))
	self.Name:ClearAllPoints()
	local anchor, rel_anchor, x_off, y_off = unpack(self.config.name.position)
	self.Name:SetPoint(anchor, self, rel_anchor, x_off, y_off)

	self:Tag(self.Name, '[st:name]')
end

local function GetConfigTable(self)
	return {
		type = 'group',
		name = 'Name',
		get = function(info)
			return self.config.name[info[#info]]
		end,
		set = function(info, value)
			self.config.name[info[#info]] = value
			UF:UpdateConfig(self.unit, 'Name')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			template = st.CF.generators.template(2),
			alpha = st.CF.generators.alpha(3),
			position = st.CF.generators.position(4,
				self.config.name.position, false, 
				function() UF:UpdateConfig(self.unit, 'Name') end
			),
			show_level = st.CF.generators.toggle(5, 'Show level', 1),
			max_length = st.CF.generators.range(6, 'Max length', 1, 100, 1),
		}
	}
end

UF:RegisterElement('Name', Constructor, UpdateConfig, GetConfigTable)