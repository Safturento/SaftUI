local st = SaftUI

--[[
	The Position option for a unit frame's parts (generators.uf_element_position,
	in st.Config.generators with Core's other option generators in
	SaftUI-Core/Config/generators.lua). Unit frames' elements and the nameplates'
	parts call it from their config tables, when the options are built.
]]
local generators = st.Config.generators

-- target is the frame being placed, or a function returning it (or nil while
-- it doesn't exist). A copy of ResolveTarget in Core's generators.lua: keep it
-- in step with that one.
local function ResolveTarget(target)
	if type(target) == 'function' then
		return target()
	end
	return target
end

-- Runs check() (a call of st:ValidateAnchor) with the page being edited set
-- as UF.anchorPage, so a plate's parts are checked against that page's config
-- and not the config of the plate that happens to be on screen
-- (UF.PlatePartAnchors). Cleared whether check errors or not; an error goes on
-- with the traceback of where it happened.
local function WithAnchorPage(page, check)
	local UF = st:GetModule('Unitframes', true)
	if UF then UF.anchorPage = page end
	local ok, a, b = xpcall(check, function(err) return debug.traceback(tostring(err), 2) end)
	if UF then UF.anchorPage = nil end
	if not ok then error(a, 0) end
	return a, b
end

-- The relative_to choices that aren't an element name.
local UNIT_FRAME, GLOBAL_FRAME = '__unitframe', '__global'

--[[
	The Position option for a unit frame element, or for an element's text or
	icon. UF:GetFrame places it relative to another element of the same unit
	frame (position.element) if that unit frame has it, else to a global frame
	(position.frame), else to its own unit frame. The block's TO part is a
	dropdown (target = 'select') of those choices, its part 'relative_to': it
	shows and sets that choice from those two keys. Global frame starts at
	UIParent, and while it's picked the name box under the dropdown types the
	frame's name (nameKey). A key is cleared by writing false, not nil: AceDB
	would fill a nil key with its default again at the next login.

	get and set are get(key) and set(key, value) functions. saved is the
	option's own saved, where the position is kept in the profile (UF.SavedAt);
	the reset icon's default and reset go by it. target is the frame
	being placed, or a function returning it (nil while it doesn't exist). The
	elements offered come from its unit frame, and every picked or typed anchor
	is checked with st:ValidateAnchor against it.
]]
function generators.uf_element_position(order, get, set, target, desc, name, saved)
	local option = generators.position(order, true, get, set, target, desc, name, saved)
	local GetPart, SetPart, ValidatePart = option.get, option.set, option.validate

	local function UnitFrame()
		local frame = ResolveTarget(target)
		return frame and frame.unitframe
	end

	-- What UF:GetFrame anchors to: an element name, UNIT_FRAME or GLOBAL_FRAME.
	local function GetRelativeTo()
		local element, frame = get('element'), get('frame')
		local unitframe = UnitFrame()
		if element and (not unitframe or unitframe[element]) then
			return element
		elseif frame then
			return GLOBAL_FRAME
		end
		return UNIT_FRAME
	end

	-- On All units (no frame of its own): the members that have the part this Position places, and which
	-- of them lack an element. The element's own ValidUnit decides, as the pages do (ruling L7).
	local UF = st:GetModule('Unitframes', true)
	local function AllSpec()
		local spec = UF and type(target) == 'function' and UF.targetSpecs and UF.targetSpecs[target]
		return spec and spec.unit == 'all' and UF.MembersWith and spec or nil
	end
	local function HasElement(unit, name)
		local element = UF.elements and UF.elements[name]
		return element ~= nil and (not element.ValidUnit or element.ValidUnit(unit) and true or false)
	end
	local function LackingUnits(spec, name)
		local lacking = {}
		for _, unit in ipairs(UF.MembersWith(spec.element)) do
			if not HasElement(unit, name) then lacking[#lacking + 1] = unit end
		end
		return lacking
	end

	-- An element as the dropdown shows it: the name the pages use (UF.ELEMENT_NAMES, parts.lua), else its key.
	local function ElementLabel(name)
		return UF and UF.ELEMENT_NAMES and UF.ELEMENT_NAMES[name] or name
	end
	local function ByLabel(a, b)
		local la, lb = ElementLabel(a), ElementLabel(b)
		if la ~= lb then return la < lb end
		return a < b
	end

	-- The elements of the target's unit frame, apart from the target itself,
	-- sorted by the name shown. On All units the elements every member having the part has. Every
	-- registered element while the unit frame isn't known.
	local function GetElementNames()
		local unitframe, frame = UnitFrame(), ResolveTarget(target)
		local names = {}
		local all = AllSpec()
		if all then
			for name in pairs(UF.elements) do
				if not (name == all.element and not all.key) and #LackingUnits(all, name) == 0 then
					tinsert(names, name)
				end
			end
			sort(names, ByLabel)
			return names
		end
		for name in pairs(unitframe and unitframe.elements or st:GetModule('Unitframes').elements) do
			if not (unitframe and unitframe[name] == frame) then
				tinsert(names, name)
			end
		end
		sort(names, ByLabel)
		return names
	end

	-- On All units, the element the saved position already names when some members lack it: kept in the list,
	-- marked, so the box is not blank, but never offered to a new pick (validate refuses it).
	local function KeptElement(listed)
		if not AllSpec() then return nil end
		local element = get('element')
		if not element then return nil end
		for _, name in ipairs(listed) do
			if name == element then return nil end
		end
		if not (UF.elements and UF.elements[element]) then return nil end
		return element
	end

	-- Which element (and its text or icon) the position places, for an All units row's check against
	-- each follower's own frame (sharedoptions.lua): a weak side table, so the option gains no field.
	if UF and UF.targetSpecs and type(target) == 'function' and UF.targetSpecs[target] then
		UF.positionSpecs = UF.positionSpecs or setmetatable({}, { __mode = 'k' })
		UF.positionSpecs[option] = UF.targetSpecs[target]
	end

	option.target = 'select'
	-- 4 narrower than the kit's TO dropdown, so the whole block (351 less 4) fits a part menu's cell (347).
	option.selectWidth = 136
	option.nameKey = GLOBAL_FRAME
	-- The dropdown's choice for the unit frame itself: the options kit's reset puts
	-- an anchor back through the row's own set of 'relative_to' with it, an element's
	-- name or nameKey (optionsdefault.lua).
	option.unitKey = UNIT_FRAME

	-- The dropdown: Unit frame, the elements, Global frame.
	option.values = function()
		local values = { [UNIT_FRAME] = 'Unit frame', [GLOBAL_FRAME] = 'Global frame' }
		for _, name in ipairs(GetElementNames()) do
			values[name] = ElementLabel(name)
		end
		local kept = KeptElement(GetElementNames())
		if kept then values[kept] = ElementLabel(kept) .. ' (not every unit)' end
		return values
	end
	option.sorting = function()
		local sorting = { UNIT_FRAME }
		local names = GetElementNames()
		for _, name in ipairs(names) do
			tinsert(sorting, name)
		end
		local kept = KeptElement(names)
		if kept then tinsert(sorting, kept) end
		tinsert(sorting, GLOBAL_FRAME)
		return sorting
	end

	option.get = function(info, part)
		if part == 'relative_to' then
			return GetRelativeTo()
		end
		return GetPart(info, part)
	end

	option.validate = function(info, part, value)
		-- The target's second return, when it gives one (UF:ConfigTarget), is the
		-- page being edited.
		local frame, page = ResolveTarget(target)
		if part ~= 'relative_to' then
			-- A typed global frame name is checked against the page too.
			return WithAnchorPage(page, function() return ValidatePart(info, part, value) end)
		end
		local unitframe = UnitFrame()
		local all = AllSpec()
		if all and value ~= UNIT_FRAME and value ~= GLOBAL_FRAME then
			local lacking = LackingUnits(all, value)
			if #lacking > 0 then
				local names = {}
				for i, unit in ipairs(lacking) do names[i] = UF.UnitPageName(unit) end
				local who = #names == 1 and names[1] or table.concat(names, ', ', 1, #names - 1) .. ' and ' .. names[#names]
				return who .. (#names == 1 and ' has no ' or ' have no ') .. (UF.ELEMENT_NAMES and UF.ELEMENT_NAMES[value] or value) .. '.'
			end
		end
		if not (frame and unitframe) then return true end
		local relative
		if value == UNIT_FRAME then
			relative = unitframe
		elseif value == GLOBAL_FRAME then
			relative = UIParent
		else
			relative = unitframe[value]
		end
		if not relative then return true end
		local ok, err = WithAnchorPage(page, function() return st:ValidateAnchor(frame, relative) end)
		return ok or err
	end

	option.set = function(info, part, value)
		if part ~= 'relative_to' then
			return SetPart(info, part, value)
		end
		if value == GetRelativeTo() then return end
		if value == UNIT_FRAME then
			set('element', false)
			set('frame', false)
		elseif value == GLOBAL_FRAME then
			set('element', false)
			set('frame', 'UIParent')
		else
			set('frame', false)
			set('element', value)
		end
	end

	return option
end
