local st = SaftUI
local SK = st:NewModule('Skinning')
SK:SetDefaultModuleLibraries('AceEvent-3.0', 'AceHook-3.0')

function SK:OnEnable()
	st:BindModuleConfig(self, 'skinning')
end

-- A profile change. The skins are this module's submodules, which aren't in
-- st.modules, so Config:UpdateConfig only reaches them through here. Each one
-- with an UpdateConfig re-applies the profile's skinning font, Theme and
-- Background.
function SK:UpdateConfig()
	for _, module in self:IterateModules() do
		if module.UpdateConfig then
			xpcall(function() module:UpdateConfig() end, geterrorhandler())
		end
	end
end

-- A color changed (st:ColorsChanged). It reaches the skins the same way: each one
-- with an OnColorsChanged colors again what it colors itself, such as a debuff's
-- border after a theme recolor.
function SK:OnColorsChanged(group)
	for _, module in self:IterateModules() do
		if module.OnColorsChanged then
			xpcall(module.OnColorsChanged, geterrorhandler(), module, group)
		end
	end
end

-- The Skinning page in /sui: the font, Theme and Background the skins share. The
-- skins re-apply them at once (SK:UpdateConfig above).
function SK:GetConfigTable()
	local generators = st.Config.generators
	return {
		name = 'Skinning',
		type = 'group',
		category = 'Info', -- the /sui sidebar's group (optionswindow.lua)
		childGroups = 'tab',
		args = {
			general = {
				name = 'General',
				type = 'group',
				order = 1,
				get = function(info) return self.config[info[#info]] end,
				set = function(info, value)
					self.config[info[#info]] = value
					self:UpdateConfig()
				end,
				args = {
					theme = generators.theme(1,
						"The border and background of the frames SaftUI skins: the buff icons, the swing timer bars, Hekili and WeakAuras."),
					background = generators.background(1.5),
					font = generators.font(2,
						"The font of the text on the frames SaftUI skins: the buff icons and the swing timer bars."),
				},
			},
		},
	}
end

-- panel -> the frame of SaftUI's over a fix_padding panel's padded area, which
-- its window is drawn behind (SK:SkinBlizzardPanel). Nothing is written onto
-- the panel for it.
local paddedAreas = setmetatable({}, { __mode = 'k' })

-- Skins one of Blizzard's panels as a window with SaftUI's title bar: in the
-- metal under Blizzard, as every window. The engine places the window's
-- backdrop around the frame it's drawn behind, with the metal's title bar
-- above it and the fill under that. With fix_padding (Blizzard's panel art
-- left padding round the content) that frame is a frame of SaftUI's over the
-- padded area, so the title bar sits above the header there, not over it.
-- Nothing calls it today.
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
	local panels = st.config.profile.panels
	local window = panel

	if options.fix_padding then
		-- The padded area, where Thick's backdrop was put by hand before:
		-- 10, 10, 30 and 74 in, plus Thick's 2.
		window = paddedAreas[panel]
		if not window then
			window = st:CreateFrame('Frame', nil, panel)
			window:SetFrameLevel(panel:GetFrameLevel()) -- its backdrop goes one level under the panel
			paddedAreas[panel] = window
		end
		window:SetPoint('TOPLEFT', 12, -12)
		window:SetPoint('BOTTOMRIGHT', -32, 76)

		panel.header:SetPoint('TOPLEFT', 12, -12)
		panel.header:SetPoint('TOPRIGHT', -32, -12)
		
		if panel.footer then
			panel.footer:ClearAllPoints()
			panel.footer:SetPoint('BOTTOMLEFT', 12, 74)
			panel.footer:SetPoint('BOTTOMRIGHT', -32, 74)
		end
	end
	st:SetBackdrop(window, panels.theme, panels.background, 'window')

	local i = 1
	local tab = _G[name..'Tab'..i]
	local prev

	while tab do
		self:SkinTab(tab)

		tab:ClearAllPoints()
		if i == 1 then
			tab:SetPoint('TOPLEFT', window.backdrop, 'BOTTOMLEFT', 2, -5)
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
	st:SkinActionButton(tab, st.config.profile.panels, 'small')
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