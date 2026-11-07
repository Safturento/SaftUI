local st = SaftUI
local UF = st:GetModule('Unitframes')

local function GetColorFromBoolean(bool, trueColor, falseColor)
	local trueR, trueG, trueB, falseR, falseG, falseB;

	if trueColor.r then
		trueR = trueColor.r
		trueG = trueColor.g
		trueB = trueColor.b
	else
		trueR, trueG, trueB = unpack(trueColor)
	end

	if falseColor.r then
		falseR = falseColor.r
		falseG = falseColor.g
		falseB = falseColor.b
	else
		falseR, falseG, falseB = unpack(falseColor)
	end

	return
		C_CurveUtil.EvaluateColorValueFromBoolean(bool, trueR, falseR),
		C_CurveUtil.EvaluateColorValueFromBoolean(bool, trueG, falseG),
		C_CurveUtil.EvaluateColorValueFromBoolean(bool, trueB, falseB)
end

local function PostCastStart(castbar, unit)
	castbar:SetColorFill(castbar.config.colors.normal:GetRGB())
	if issecretvalue(castbar.notInterruptible) then
		castbar:SetStatusBarColor(GetColorFromBoolean(castbar.notInterruptible, castbar.colors.notInterruptible, castbar.colors.normal))
		--castbar:SetColorFill(C_CurveUtil.EvaluateColorFromBoolean(
		--	castbar.notInterruptible, castbar.colors.notInterruptible, castbar.colors.normal):GetRGBA()
		--)
	else
		if castbar.notInterruptible then
			castbar:SetColorFill(castbar.config.colors.nointerrupt:GetRGB())
		else
			castbar:SetColorFill(castbar.config.colors.normal:GetRGB())
		end
	end

	if castbar.Icon.texture:GetTexture() == [[Interface\ICONS\INV_Misc_QuestionMark]] then
		local name, _, texture, startTime, endTime, isTradeSkill, castID, notInterruptible, spellID = CastingInfo(unit)
		local icon = select(10, C_Item.GetItemInfo(name))

		if icon then
			castbar.Icon.texture:SetTexture(icon)
		end
	end
end

-- oUF shows the castbar on every cast of the unit, whatever UF:SetElementEnabled
-- did. It skips a cast event while this returns false, so a disabled castbar
-- stays hidden. oUF's own check is just the unit.
local function ShouldShow(castbar, unit)
	return castbar.config.enable and castbar.__owner.__unit == unit
end

local function Constructor(unitframe)
    local castbar = UF:AddStatusBarElement(unitframe, 'Castbar')
    UF:AddText(unitframe, castbar, 'Text', castbar)
    UF:AddText(unitframe, castbar, 'Time', castbar)
    UF:AddIcon(unitframe, castbar, 'Icon')


	castbar.colors = {
		normal = CreateColor(castbar.config.colors.normal:GetRGB()),
		notInterruptible = CreateColor(castbar.config.colors.nointerrupt:GetRGB())
	}
	castbar.ShouldShow = ShouldShow
	castbar.PostCastStart = PostCastStart
	castbar.PostChannelStart = PostCastStart

	return castbar
end

local function UpdateConfig(unitframe)
	local castbar = unitframe.Castbar
	UF:UpdateElement(castbar)

	-- castbar.colors are copies (made once above), so carry the profile's
	-- colors over into them.
	local colors = castbar.config.colors
	castbar.colors.normal:SetRGB(colors.normal:GetRGB())
	castbar.colors.notInterruptible:SetRGB(colors.nointerrupt:GetRGB())
end

local function GetConfigTable(unit)
	local generators = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function Config() return UF:GetProfileConfig()[unit].castbar end
	local function Update() UF:UpdateConfig(unit, 'Castbar') end

	-- The settings of the castbar (key nil), or of its text, time or icon
	-- (castbar[key]), placed on the castbar's frame at frameKey.
	local function Position(order, key, frameKey)
		local function Get() return key and Config()[key].position or Config().position end
		return generators.uf_element_position(order,
			function(index) return Get()[index] end,
			function(index, value)
				Get()[index] = value
				Update()
			end,
			UF:ConfigTarget(unit, 'Castbar', frameKey)
		)
	end

	-- A text's or the icon's settings, in castbar[key].
	local function Section(order, name, key, args)
		return {
			order = order,
			name = name,
			type = 'group',
			inline = true,
			get = function(info) return Config()[key][info[#info]] end,
			set = function(info, value)
				Config()[key][info[#info]] = value
				Update()
			end,
			args = args,
		}
	end

	-- castbar.colors[key]. Shown from the next cast.
	local function Color(order, name, key)
		return {
			order = order,
			name = name,
			type = 'color',
			get = function()
				local color = Config().colors[key]
				return color.r, color.g, color.b
			end,
			set = function(_, r, g, b)
				local color = Config().colors[key]
				color.r, color.g, color.b = r, g, b
				Update()
			end,
		}
	end

	local function TextArgs(frameKey, key)
		return {
			enable = generators.enable(0),
			font = generators.font(1),
			position = Position(2, key, frameKey),
		}
	end

	return {
		order = 6,
		type = 'group',
		name = 'Castbar',
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			Update()
		end,
		args = {
			enable = generators.enable(0),
			bar = {
				order = 1,
				name = 'Bar',
				type = 'group',
				inline = true,
				args = {
					framelevel = generators.framelevel(1),
					template = generators.template(2),
					size = UF.GenerateRelativeSizeConfigGroup(3),
					normal = Color(4, 'Color', 'normal'),
					nointerrupt = Color(5, "Can't interrupt", 'nointerrupt'),
					position = Position(6),
				},
			},
			text = Section(2, 'Spell name', 'text', TextArgs('Text', 'text')),
			time = Section(3, 'Time', 'time', TextArgs('Time', 'time')),
			icon = Section(4, 'Icon', 'icon', {
				enable = generators.enable(0),
				framelevel = generators.framelevel(1),
				template = generators.template(2),
				size = UF.GenerateRelativeSizeConfigGroup(3),
				position = Position(4, 'icon', 'Icon'),
			}),
		},
	}
end

-- oUF never enables a castbar on a unit's target (targettarget, focustarget).
local function ValidUnit(unit)
	return not unit:match('%wtarget$')
end

UF:RegisterElement('Castbar', Constructor, UpdateConfig, GetConfigTable, ValidUnit)