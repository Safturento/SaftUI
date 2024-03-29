local st = SaftUI
local SK = st:NewModule('Skinning')
SK:SetDefaultModuleLibraries('AceEvent-3.0', 'AceHook-3.0')

function SK:OnInitialize()
	self.config = st.config.profile.skinning
end

function SK:SkinBlizzardPanel(panel, options) --fix_padding, title, close, portrait)
	if not options then options = {} end
	-- if not panel then return end
	local name = panel:GetName()
	local title = options.title or _G[name..'TitleText']
	local close = options.close or _G[name..'CloseButton']
	local portrait = options.portrait or _G[name..'Portrait']
	local inset = _G[name..'Inset']

	if inset then
		st:StripTextures(inset)
	end

	if portrait then
		st:Kill(portrait)
	end

	st:StripTextures(panel)

	st:CreateHeader(panel, title, close)
	st:SetBackdrop(panel, st.config.profile.panels.template)

	if options.fix_padding then
		panel.backdrop:ClearAllPoints()

		panel.backdrop:SetPoint('TOPLEFT', 10, -10)
		panel.backdrop:SetPoint('BOTTOMRIGHT', -30, 74)

		panel.header:SetPoint('TOPLEFT', 12, -12)
		panel.header:SetPoint('TOPRIGHT', -32, -12)
		
		if panel.footer then
			panel.footer:ClearAllPoints()
			panel.footer:SetPoint('BOTTOMLEFT', 12, 74)
			panel.footer:SetPoint('BOTTOMRIGHT', -32, 74)
		end
	end

	local i = 1
	local tab = _G[name..'Tab'..i]
	local prev

	while tab do
		self:SkinTab(tab)

		tab:ClearAllPoints()
		if i == 1 then
			tab:SetPoint('TOPLEFT', panel.backdrop, 'BOTTOMLEFT', 2, -5)
		else
			tab:SetPoint('LEFT', prev, 'RIGHT', 7, 0)
		end
		prev = tab
		i = i + 1
		tab = _G[name..'Tab'..i]
	end
end

function SK:SkinTab(tab)
	st:StripTextures(tab)
	st:SkinActionButton(tab, st.config.profile.panels)
	if not tab.Text then tab.Text = _G[tab:GetName()..'Text'] end
	tab.skinned = true

	self:UpdateTab(tab)
end

function SK:UpdateTab(tab)
	if not tab.skinned then
		self:SkinTab(tab)
	end
	
	tab:SetDisabledFontObject(st:GetFont(st.config.profile.panels.font))
	if tab.Text then
		tab.Text:ClearAllPoints()
		tab.Text:SetPoint('CENTER')
	end
	tab:SetHeight(st.config.profile.panels.tab_height)
	local bd = tab:GetParent().backdrop
	tab:SetWidth(tab:GetTextWidth()+20)
end

function SK:SkinTabHeader(header)
	local name = header:GetName()

	local i = 1
	local tab = _G[name..'Tab'..i]
	local prev

	
	header:SetHeight(st.config.profile.panels.tab_height)
	while tab do
		self:SkinTab(tab)

		tab:ClearAllPoints()
		if i == 1 then
			tab:SetPoint('TOPLEFT', header, 'TOPLEFT', 0, 0)
		else
			tab:SetPoint('TOPLEFT', prev, 'TOPRIGHT', 7, 0)
		end
		prev = tab
		i = i + 1
		tab = _G[name..'Tab'..i]
	end
end