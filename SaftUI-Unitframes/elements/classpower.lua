local st = SaftUI
local UF = st:GetModule('Unitframes')

local function PostUpdateClassPower(classPower, cur, max, hasCurChanged, hasMaxChanged, powerType)
	-- oUF passes no max only when the element itself is disabled. When class
	-- power turns off with the power type (e.g. a druid leaving cat form), oUF
	-- hides the points itself without calling this; the container has no
	-- backdrop, so nothing is left on screen. Otherwise class power is on, and
	-- the container follows Enable.
	if not max then classPower:Hide() return end
	classPower:SetShown(classPower.config.enable and true or false)
	local width = (classPower:GetWidth() - (classPower.config.spacing * (max - 1))) / max
	for i = 1, max do
		st:SetWidth(classPower[i], width)
		if classPower.config.show_empty then
			classPower[i]:Show()
		end
	end
end

local function Constructor(unitframe)
	if not (unitframe.base_unit == 'player') then return end

	local classPower = UF:AddElement('Frame', unitframe, 'ClassPower')
	for i = 1, 10 do
		classPower[i] =  CreateFrame('StatusBar', nil, classPower)
	end

	classPower.PostUpdate = PostUpdateClassPower
	return classPower
end

local function UpdateConfig(unitframe)
    local classPower = unitframe.ClassPower
    UF:UpdateElement(classPower)

	st:SetBackdrop(classPower, 'none')
	
	local prev
	for i=1, 10 do
		local point = classPower[i]
		st:SetBackdrop(point, classPower.config.template)
		
		point:SetStatusBarTexture(st.BLANK_TEX)
		point:ClearAllPoints()
		if prev then
			point:SetPoint('LEFT', prev, 'RIGHT', classPower.config.spacing, 0)
		else
			point:SetPoint('LEFT')
		end
		point:SetHeight(classPower.config.height)
		prev = point
	end
end

local function GetConfigTable(unit)
	local generators = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function Config() return UF:GetProfileConfig()[unit].classpower end
	local function Update() UF:UpdateConfig(unit, 'ClassPower') end

	local template = generators.template(2)
	template.desc = 'The backdrop of each point.'

	return {
		order = 4,
		type = 'group',
		name = 'Class power',
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			Update()
		end,
		args = {
			enable = generators.enable(0),
			framelevel = generators.framelevel(1),
			template = template,
			-- Each point is height tall (UpdateConfig), never relative to the
			-- unit frame, so height has no Relative toggle.
			size = {
				order = 3,
				name = '',
				type = 'group',
				inline = true,
				args = {
					width = generators.width(1),
					relative_width = generators.toggle(2, 'Relative', 1),
					height = generators.height(3),
				},
			},
			spacing = generators.range(4, 'Spacing', 0, 20, 1),
			position = generators.uf_element_position(50,
				function(index) return Config().position[index] end,
				function(index, value)
					Config().position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'ClassPower')
			),
		},
	}
end

local function ValidUnit(unit)
	return unit == 'player'
end

UF:RegisterElement('ClassPower', Constructor, UpdateConfig, GetConfigTable, ValidUnit)
