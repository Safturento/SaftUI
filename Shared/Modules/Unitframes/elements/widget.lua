local st = SaftUI
local UF = st:GetModule('Unitframes')

function Constructor(self)
    local widget = CreateFrame('StatusBar', nil, self)
    widget.config = self.config.widget

    widget.text = self.TextOverlay:CreateFontString(nil, 'OVERLAY')
	widget.text:SetFontObject(st:GetFont(self.config.widget.text.font))

    self.Widget = widget
    return widget
end

function UpdateConfig(self)
    local config = self.config.widget

    if config.enable == false then
		self.Widget:Hide()
		return
	else
		self.Widget:Show()
	end

    if config.relative_height then
		st:SetHeight(self.Widget, self.config.height + config.height)
	else
		st:SetHeight(self.Widget, config.height)
	end

	if config.relative_width then
		st:SetWidth(self.Widget, self.config.width + config.width)
	else
		st:SetWidth(self.Widget, config.width)
	end

    st:SetBackdrop(self.Widget, config.template)

    self.Widget:ClearAllPoints()
	local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(config.position)
	local frame = st.CF.get_frame(self, config.position)
	self.Widget:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
	self.Widget:SetFrameLevel(config.framelevel)
	self.Widget:SetStatusBarTexture(st.BLANK_TEX)
    self.Widget:SetStatusBarColor(0.3, 0.3, 0.3)

    if config.text.enable then
        self.Widget.text:Show()
        self.Widget.text:SetFontObject(st:GetFont(config.text.font))
		self.Widget.text:ClearAllPoints()
		local anchor, _, rel_anchor, x_off, y_off = st:UnpackPoint(config.text.position)
		local frame = st.CF.get_frame(self, config.text.position)
		self.Widget.text:SetPoint(anchor, frame, rel_anchor, x_off, y_off)
    else
        self.Widget.text:Hide()
    end

end

function GetConfigTable()  end

UF:RegisterElement('Widget', Constructor, UpdateConfig, GetConfigTable)