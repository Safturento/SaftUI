local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

local ADDON_NAME, st = ...
local UF = st:GetModule('Unitframes')

function UF.PostCastStart(castbar, unit, spellName)
	if castbar.notInterruptible then
		castbar:SetStatusBarTexture(unpack(castbar.config.colors.nointerrupt))
	else
		castbar:SetStatusBarTexture(unpack(castbar.config.colors.normal))
	end
end

local function Constructor(self)
	local castbar = CreateFrame('StatusBar', nil, self)
	castbar.config = self.config.castbar

	castbar.Text = castbar:CreateFontString(nil, 'OVERLAY')
	castbar.Text:SetFontObject(st:GetFont(self.config.castbar.text.font))
	castbar.Time = castbar:CreateFontString(nil, 'OVERLAY')
	castbar.Time:SetFontObject(st:GetFont(self.config.castbar.time.font))
	
	castbar.PostCastStart = UF.PostCastStart
	castbar.PostChannelStart = UF.PostCastStart

	self.Castbar = castbar
	return castbar
end

local function UpdateConfig(self)
	self.Castbar.config = self.config.castbar
	
	if self.config.castbar.enable == false then
		self.Castbar:Hide()
		return
	else
		self.Castbar:Show()
	end

	if self.config.castbar.relative_height then
		self.Castbar:SetHeight(self.config.height + self.config.castbar.height)
	else
		self.Castbar:SetHeight(self.config.castbar.height)
	end

	if self.config.castbar.relative_width then
		self.Castbar:SetWidth(self.config.width + self.config.castbar.width)
	else
		self.Castbar:SetWidth(self.config.castbar.width)
	end

	st:SetBackdrop(self.Castbar, self.config.castbar.template)

	if self.config.castbar.text.enable then
		self.Castbar.Text:Show()
		self.Castbar.Text:SetFontObject(st:GetFont(self.config.castbar.text.font))
		self.Castbar.Text:ClearAllPoints()
		local anchor, rel_anchor, x_off, y_off = unpack(self.config.castbar.text.position)
		self.Castbar.Text:SetPoint(anchor, self, rel_anchor, x_off, y_off)
	else
		self.Castbar.Text:Hide()
	end

	if self.config.castbar.time.enable then
		self.Castbar.Time:Show()
		self.Castbar.Time:SetFontObject(st:GetFont(self.config.castbar.time.font))
		self.Castbar.Time:ClearAllPoints()
		local anchor, rel_anchor, x_off, y_off = unpack(self.config.castbar.time.position)
		self.Castbar.Time:SetPoint(anchor, self, rel_anchor, x_off, y_off)
	else
		self.Castbar.Time:Hide()
	end

	self.Castbar:ClearAllPoints()
	local anchor, rel_anchor, x_off, y_off = unpack(self.config.castbar.position)
	self.Castbar:SetPoint(anchor, self, rel_anchor, x_off, y_off)
	self.Castbar:SetFrameLevel(self.config.castbar.framelevel)
end

local function GetConfigTable(self)
	return {
		type = 'group',
		name = 'Castbar',
		get = function(info)
			return self.config.castbar[info[#info]]
		end,
		set = function(info, value)
			self.config.castbar[info[#info]] = value
			UF:UpdateConfig(self.unit, 'Castbar')
		end,
		args = {
			enable = st.CF.generators.enable(0),
			framelevel = st.CF.generators.framelevel(1),
			size = {
				order = 3,
				name = 'Size',
				type = 'group',
				inline = true,
				args = {
					width = st.CF.generators.width(1),
					relative_width = st.CF.generators.toggle(2, 'Relative', 1),
					height = st.CF.generators.height(3),
					relative_height = st.CF.generators.toggle(4, 'Relative', 1),
				},
			},
			template = st.CF.generators.template(4),
			position = st.CF.generators.position(
				self.config.castbar.position, false, 5, nil, 
				function() UF:UpdateConfig(self.unit, 'Castbar') end
			),
		}
	}
end

UF:RegisterElement('Castbar', Constructor, UpdateConfig, GetConfigTable)