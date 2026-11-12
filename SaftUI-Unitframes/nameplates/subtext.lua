local st = SaftUI
local UF = st:GetModule('Unitframes')

--[[
	The subtext line under a plate's name, the Subtext element: an NPC's title
	("General Goods Vendor") or a player's guild, in angle brackets, on the
	plates only (UF.IsPlateUnit). Like the name it reads the settings of the
	config unit the plate draws from (frame.base_unit): Enemy nameplates' or
	Friendly nameplates' subtext table (config/units/nameplate.lua,
	friendlynameplate.lua). Its text is the st:subtext tag below.

	Either kind of unit's line has its own box (npc, player) in that table. With
	a kind's box off nothing is read for that kind: no tooltip for an NPC.
]]

-- Secret values (.agents/clients.md): a unit's tooltip text and type, its guild
-- name and whether it's a player can all be secret on a plate. A secret is
-- never compared, matched or joined here: it's tested with issecretvalue
-- first, and a secret guild name is wrapped by the game
-- (C_StringUtil.WrapString), the only thing done to one.

-- The pattern the tooltip's level line ("Level 80 Humanoid") matches, from the
-- game's TOOLTIP_UNIT_LEVEL ("Level %s"): Lua's magic characters escaped, each
-- %s or %d any text, anchored at the start. Built on first use, and again if
-- the global string ever differs.
local levelFormat, levelPattern
local function LevelPattern()
	local format = TOOLTIP_UNIT_LEVEL
	if type(format) ~= 'string' then return nil end
	if format ~= levelFormat then
		levelFormat = format
		levelPattern = '^' .. format:gsub('[%^%$%(%)%%%.%[%]%*%+%-%?]', '%%%0'):gsub('%%%%[sd]', '.+')
	end
	return levelPattern
end

-- A unit's title as a plain string, or nil. The title is the second line of its
-- tooltip, between the name and the level line, and has no line type of its own
-- (an untyped, None, line): so that line is taken only when it is untyped, its
-- text is plain and not empty, and it isn't the level line (a client may leave
-- that one untyped, so its text is checked too). A pet's "So-and-so's Pet" is
-- a typed (UnitOwner) line, so it's never a title.
function UF.NpcTitle(unit)
	local data = C_TooltipInfo and C_TooltipInfo.GetUnit(unit)
	if type(data) ~= 'table' or issecretvalue(data) then return nil end
	local lines = data.lines
	if type(lines) ~= 'table' or issecretvalue(lines) then return nil end
	local line = lines[2]
	if type(line) ~= 'table' or issecretvalue(line) then return nil end

	local lineType = line.type
	if lineType ~= nil then
		if issecretvalue(lineType) or lineType ~= Enum.TooltipDataLineType.None then return nil end
	end

	local text = st.PlainString(line.leftText)
	if not text or text == '' then return nil end
	local level = LevelPattern()
	if level and text:find(level) then return nil end
	return text
end

-- What a unit's subtext line says by config (a plate config's subtext table):
-- a plain string, a secret one the game wrapped, or nil for no line. The kind
-- is asked first, and a kind whose box is off is read no further.
function UF.PlateSubtext(unit, config)
	local isPlayer = UnitIsPlayer(unit)
	if issecretvalue(isPlayer) then return nil end

	if isPlayer then
		if not config.player then return nil end
		local guild = GetGuildInfo(unit)
		if issecretvalue(guild) then
			return C_StringUtil.WrapString(guild, '<', '>')
		end
		if type(guild) ~= 'string' or guild == '' then return nil end
		return '<' .. guild .. '>'
	end

	if not config.npc then return nil end
	local title = UF.NpcTitle(unit)
	if not title then return nil end
	return '<' .. title .. '>'
end

UF.oUF.Tags.Events['st:subtext'] = 'UNIT_NAME_UPDATE'
-- The unit's line, read with the settings of the config unit the tag is given
-- (as st:name's): '' for none. A secret result goes back as it is, never
-- tested for truth.
UF.oUF.Tags.Methods['st:subtext'] = function(unit, realUnit, baseUnit)
	local unitConfig = UF:GetProfileConfig()[baseUnit]
	local config = unitConfig and unitConfig.subtext
	if not config then return '' end
	local text = UF.PlateSubtext(unit, config)
	if issecretvalue(text) then return text end
	return text or ''
end

local function Constructor(frame)
	return UF:AddTextElement(frame, 'Subtext')
end

local function UpdateConfig(frame)
	local text = frame.Subtext
	UF:UpdateElement(text)
	local config = text.config

	local color = config.color
	text:SetTextColor(color.r, color.g, color.b)
	UF.SetMaxWidth(text, config)
end

-- The tag names the config unit it reads (st:subtext above), so it's bound
-- again when the frame's changes (a plate draws from Enemy or Friendly
-- nameplates by its unit's kind, nameplates.lua), as the name's is
-- (elements/name.lua). Done when the plate's update is over (the 'updated'
-- callback), not in UpdateConfig, so the name's own rebinding comes first and
-- the other parts' updates don't depend on the order the elements are
-- visited in. UpdateTags writes the text from the new binding at once; oUF's
-- UpdateAllElements writes it again on an add.
UF:RegisterPlateCallback('updated', function(frame)
	local text = frame.Subtext
	if not text or text.taggedUnit == frame.base_unit then return end
	if text.taggedUnit then frame:Untag(text) end
	frame:Tag(text, '[st:subtext(' .. frame.base_unit .. ')]')
	text.taggedUnit = frame.base_unit
	frame:UpdateTags()
end)

local function GetConfigTable(unit)
	local G = st.Config.generators
	-- Looked up on every get/set: a profile change replaces these tables.
	local function Config() return UF:GetProfileConfig()[unit].subtext end
	local function Update() UF:UpdateConfig(unit, 'Subtext') end

	return {
		type = 'group',
		name = 'Subtext',
		-- Right after Name's tab (5), before Castbar's (6).
		order = 5.5,
		get = function(info) return Config()[info[#info]] end,
		set = function(info, value)
			Config()[info[#info]] = value
			Update()
		end,
		args = {
			npc = G.toggle(0, 'NPC titles', "Shows an NPC's title, such as General Goods Vendor, under its name.", 'small'),
			player = G.toggle(1, 'Player guilds', "Shows a player's guild under their name.", 'small'),
			font = G.font(2, "The subtext's font."),
			color = {
				order = 3,
				name = 'Color',
				desc = "The subtext's color.",
				type = 'color',
				size = 'small',
				get = function()
					local color = Config().color
					return color.r, color.g, color.b
				end,
				set = function(_, r, g, b)
					local color = Config().color
					color.r, color.g, color.b = r, g, b
					Update()
				end,
			},
			alpha = G.alpha(4, 'How solid the subtext is, from see-through to opaque.'),
			max_width = G.range(5, 'Max width', 0, 600, 1, "Cuts the subtext at this many pixels. 0: no limit."),
			-- Last in the tab.
			position = G.uf_element_position(1000,
				function(index) return Config().position[index] end,
				function(index, value)
					Config().position[index] = value
					Update()
				end,
				UF:ConfigTarget(unit, 'Subtext'),
				"Where the subtext sits: which of its points goes to which point of what it's attached to, then moved by X and Y."
			),
		},
	}
end

UF:RegisterElement('Subtext', Constructor, UpdateConfig, GetConfigTable, UF.IsPlateUnit)
