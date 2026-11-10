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
	local r, g, b
	r, g, b = castbar.config.colors.normal:GetRGB()
	if issecretvalue(castbar.notInterruptible) then
		r, g, b = GetColorFromBoolean(castbar.notInterruptible, castbar.colors.notInterruptible, castbar.colors.normal)
		castbar:SetStatusBarColor(r, g, b)
		--castbar:SetColorFill(C_CurveUtil.EvaluateColorFromBoolean(
		--	castbar.notInterruptible, castbar.colors.notInterruptible, castbar.colors.normal):GetRGBA()
		--)
	else
		if castbar.notInterruptible then
			r, g, b = castbar.config.colors.nointerrupt:GetRGB()
		end
		castbar:SetColorFill(r, g, b)
	end

	-- The background is a darker shade of the bar color, as for the power bar.
	if castbar.config.bg.enable then
		UF.SetPowerBackgroundColor(castbar, r, g, b)
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
-- stays hidden. oUF's own check is just the unit. It skips the stop and fail
-- events too, so a bar mid-cast when it's disabled (a profile switch in combat
-- re-points the config before SetElementEnabled can run) is hidden here.
local function ShouldShow(castbar, unit)
	if not castbar.config.enable then
		castbar:Hide()
		return false
	end
	return castbar.__owner.__unit == unit
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
	-- (castbar[key]), placed on the castbar's frame at frameKey. what names it
	-- in the desc.
	local function Position(order, key, frameKey, what, name)
		local function Get() return key and Config()[key].position or Config().position end
		return generators.uf_element_position(order,
			function(index) return Get()[index] end,
			function(index, value)
				Get()[index] = value
				Update()
			end,
			UF:ConfigTarget(unit, 'Castbar', frameKey),
			("Where the %s sits: which of its points goes to which point of what it's attached to, then moved by X and Y."):format(what),
			name
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
	local function Color(order, name, key, desc)
		return {
			order = order,
			name = name,
			desc = desc,
			type = 'color',
			size = 'small',
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

	-- The spell name's or the time's settings, in castbar[key].
	local function TextArgs(frameKey, key, what, name)
		return {
			enable = generators.toggle(0, 'Enable', ('Shows the %s on the castbar.'):format(what), 'small'),
			font = generators.font(1, ("The %s's font."):format(what)),
			-- Last in its section.
			position = Position(1000, key, frameKey, what, name),
		}
	end

	local FRAME_LEVEL = 'Draws it over the parts of the unit frame with a lower frame level, and under those with a higher one.'
	-- oUF hides them when it enables the player castbar, and Enable doesn't undo that.
	local enableDesc = unit == 'player'
		and "Shows your castbar while you cast. Blizzard's player and pet castbars stay hidden either way."
		or 'Shows the castbar while the unit casts.'

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
			enable = generators.toggle(0, 'Enable', enableDesc, 'small'),
			bar = {
				order = 1,
				name = 'Bar',
				type = 'group',
				inline = true,
				args = {
					theme = generators.theme(1, "The castbar's border and background."),
					background = generators.background(1.5),
					alpha = generators.alpha(2, 'How solid the castbar, its texts and its icon are, from see-through to opaque.'),
					framelevel = generators.framelevel(3, FRAME_LEVEL),
					normal = Color(4, 'Color', 'normal', "The bar's color while the cast can be interrupted. Shown from the next cast."),
					nointerrupt = Color(5, "Can't interrupt", 'nointerrupt', "The bar's color while the cast can't be interrupted. Shown from the next cast."),
					size = UF.GenerateRelativeSizeConfigGroup(6),
					-- Last in Bar.
					position = Position(1000, nil, nil, 'castbar'),
				},
			},
			text = Section(2, 'Spell name', 'text', TextArgs('Text', 'text', 'spell name', 'Spell name position')),
			time = Section(3, 'Time', 'time', TextArgs('Time', 'time', 'cast time', 'Time position')),
			icon = Section(4, 'Icon', 'icon', {
				enable = generators.toggle(0, 'Enable', "Shows the spell's icon.", 'small'),
				theme = generators.theme(1, "The icon's border and background."),
				background = generators.background(1.5),
				framelevel = generators.framelevel(2, FRAME_LEVEL),
				size = UF.GenerateRelativeSizeConfigGroup(3),
				-- Last in Icon.
				position = Position(1000, 'icon', 'Icon', 'icon', 'Icon position'),
			}),
		},
	}
end

-- oUF never enables a castbar on a unit's target (targettarget, focustarget).
local function ValidUnit(unit)
	return not unit:match('%wtarget$')
end

UF:RegisterElement('Castbar', Constructor, UpdateConfig, GetConfigTable, ValidUnit)