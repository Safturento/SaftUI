local st = SaftUI
local OM = st.OptionsModel

--[[
	The widgets SaftUI's options window draws its rows with. Each is a control
	only: the window draws the label and the row around it.

	  local widget = W.Create(parent, row.type)       -- from a pool, one per type
	  widget:Bind(root, row, onChanged)               -- reads the value, shows it
	  widget:SetPoint(...)                            -- widget.frame is the frame
	  widget:GetWidth()                               -- the control's fixed width
	  widget:SetDisabled(true)
	  widget:Release()                                -- back to the pool

	Bind reads the row's value with OM.Get. A change the user makes goes the
	way AceConfigDialog's does: OM.Validate (a failure calls
	onChanged(false, message) and sets nothing), then OM.Confirm (a text asks
	with W.Confirm first), then OM.Set. After that onChanged(ok, err) runs, ok
	false when the set errored. The window re-renders from it. While a slider
	is being dragged, onChanged gets a third argument, true, and a fourth,
	the widget, so the window can refresh the other rows and leave the
	slider be; one more onChanged(true) comes when the mouse is let go, so
	the window doesn't rebuild the slider under the user's mouse.

	Types: toggle, range, select, multiselect, input, color, execute,
	keybinding, item, font, description, position. Widths: toggle 18, range 168 (a 116 track, a gap
	of 6 and a 46 value box), select, multiselect, input, keybinding and color 170.
	An item (its Show box, its name and its menu's dots) spans its cell: the
	body gives it the cell's width (W.WIDTH.item is 0) and draws its name.
	An execute button is as wide as its name needs (80 at least), or as its
	slot when the body gives it one (widget:SetWidth: a floating line of
	buttons that share it), and a description is as wide as the window sets it (400 until it does). A
	font row (optionsfont.lua) is 190 wide, 194 under Blizzard (a select's face and
	a 16 wide slot). A
	position block is as wide as its parts (200, 332 with a name target, 352
	with a select target) and 65 high; its get/set/validate take the part first (point,
	rel_point, x_off, y_off, frame, relative_to), so a change is
	Commit(part, value). The window sets widget.onTip, which the block calls
	as the mouse enters and leaves any of its parts. A multiselect's and a description's height follow what they hold
	(widget.frame:GetHeight()); the others are 18, 24 or 26 high.

	Left out: input's multiline (one line), select's radio style (a dropdown,
	as the spec says). A description's fontSize is small (the default), medium
	or large. Its image is read as AceConfigDialog reads it: image a texture
	path or fileID, or a function giving that with a width and height;
	imageWidth and imageHeight otherwise (32 each by default); imageCoords 4
	or 8 numbers, or a function giving them, else the whole texture. The image
	sits at the description's left with the text to its right, and the height
	covers both. It has a border in SaftUI's theme, as an icon SaftUI skins
	does. Refresh reads them all again (the window refreshes the other
	rows while a slider is dragged, so a preview can follow it). SaftUI's
	own justifyH sets a description's text LEFT (the default), CENTER or
	RIGHT across it, and SaftUI's fill makes its row a fill row
	(optionsbody.lua), which tells it its height with SetHeight: it is then
	that tall, with what it shows in the middle. A disabled toggle takes no
	mouse, as every other disabled control but a multiselect (whose rows
	keep it), so its row shows its tooltip.

	Other files add types of their own with W.Define (custom types, at the
	end), each with its own pool. W.CUSTOM marks them, and the body draws a
	bare one's row with no label, across the line. W.OpenCheckList (in
	optionslist.lua) opens the select list's frames as a list of check boxes,
	and W.OpenApplyList as one whose picks wait for its Apply button.

	The widgets are split by job, each file loading after this one in
	Config/load.xml's order. This file has the registry: the base widget,
	the pools, W.Create and W.Define. The others: optionslook.lua (the look
	the controls share: the field font, Box, Blizzard's art, the check box),
	optionsdialog.lua (W.Confirm, W.Prompt), optionsbar.lua (W.BlizzardBar),
	optionslist.lua (the select list and the check list), optionstypes.lua
	(toggle, input, color, execute, description), optionsrange.lua,
	optionsselect.lua (select, multiselect), optionskeybinding.lua,
	optionsitem.lua (the item), optionscontrols.lua (the standalone controls), optionscolorpicker.lua, optionsfont.lua (the font row) and optionsposition.lua. W.Kit (below) holds
	what they share.

	widget.rowBody is the body (optionsbody.lua) that drew the widget, set
	as its row is drawn and cleared when it's released: an item opens its
	menu from it (optionsmenu.lua). (A custom type may keep a body of its
	own: the bags' Categories tab's is widget.body.)
]]

local W = {}
st.OptionsWidgets = W

-- W.Kit: the names the widget files share with each other and nothing else.
-- They load in Config/load.xml's order, this file first. Each ends by setting
-- here what a later file takes from it, and starts by taking what it needs as
-- locals of its own. A name W exports (W.Box, W.LookDropdown, ...) is taken
-- from W instead.
local Kit = {}
W.Kit = Kit

local format, tinsert, tremove = string.format, table.insert, table.remove

W.WIDTH = {
	toggle = 18, range = 168, select = 170, multiselect = 170, input = 170,
	execute = 80, keybinding = 170, description = 400,
	position = 0, -- the block's width follows its parts (widget:GetWidth())
	item = 0, -- it spans its cell: the body gives it the cell's width
}
W.WIDTH.color = W.WIDTH.select -- a color's field is as wide as a dropdown
local FIELD_HEIGHT = 24
-- Above the options window (FULLSCREEN_DIALOG, like edit mode's outlines), so
-- the list and the confirm dialog show over it and catch the clicks around them.
local LIST_STRATA = 'TOOLTIP'

------------------------------------------------------------------ the base widget

local Base = {}
Base.__index = Base

local pools = {} -- rowType -> { widget }
local builders = {} -- rowType -> function(widget): makes widget.frame

function Base:GetWidth() return self.width end
function Base:GetHeight() return self.frame:GetHeight() end
function Base:SetPoint(...) self.frame:SetPoint(...) end

function Base:IsDisabled() return self.disabled end

function Base:SetDisabled(disabled)
	self.disabled = disabled and true or false
	self.frame:SetAlpha(self.disabled and 0.4 or 1)
	if self.OnDisabled then self:OnDisabled(self.disabled) end
end

-- Reads the row's value and shows it. Each type's Refresh does the showing.
function Base:Bind(root, row, onChanged)
	self.root, self.row, self.onChanged = root, row, onChanged
	self:SetDisabled(row.disabled)
	self:Refresh()
	return self
end

function Base:Value(...)
	return OM.Get(self.root, self.row, ...)
end

-- A change from the user: validate, then confirm, then set, then tell the
-- window. A failed validation puts the shown value back (an input keeps its text).
function Base:Commit(...)
	local root, row = self.root, self.row
	if not row or self.disabled then return end
	local args, n = { ... }, select('#', ...)
	local function Apply()
		if self.root ~= root or self.row ~= row then return end -- released meanwhile
		local ok = OM.Set(root, row, unpack(args, 1, n))
		self:Refresh()
		if self.onChanged then self.onChanged(ok ~= false, nil, self.dragging, self) end
	end
	local valid, err = OM.Validate(root, row, ...)
	if not valid then
		if self.type == 'input' then
			-- AceConfigDialog keeps what was typed beside the error. The box may
			-- have been reset when Enter dropped its focus, so put the text back.
			self.frame:SetText(tostring((...)))
		else
			self:Refresh()
		end
		if self.onChanged then self.onChanged(false, err) end
		return
	end
	local text = OM.Confirm(root, row, ...)
	if text then
		W.Confirm(text, Apply, function()
			if self.root == root and self.row == row then self:Refresh() end
		end)
	else
		Apply()
	end
end

function Base:Release()
	if self.released then return end
	self.released = true
	if self.OnRelease then self:OnRelease() end
	self.root, self.row, self.onChanged, self.rowBody = nil, nil, nil, nil
	self.dragging = nil
	self.frame:Hide()
	self.frame:ClearAllPoints()
	self.frame:SetParent(nil)
	self.frame:SetAlpha(1)
	self.disabled = false
	tinsert(self.pool, self)
end

-- The widget for rowType, from the pool when one was released.
function W.Create(parent, rowType)
	local build = builders[rowType]
	if not build then error(format('SaftUI options: no widget for type %q', tostring(rowType)), 2) end
	pools[rowType] = pools[rowType] or {}
	local widget = tremove(pools[rowType])
	if not widget then
		-- Its pool is the one it was built for: a custom type defined again
		-- starts a new one (W.Define).
		widget = setmetatable({ type = rowType, width = W.WIDTH[rowType], pool = pools[rowType] }, Base)
		build(widget)
	end
	widget.released = false
	widget.frame:SetParent(parent)
	widget.frame:SetFrameLevel(parent:GetFrameLevel() + 1)
	widget.frame:Show()
	return widget
end

-- How many widgets of a type sit in the pool.
function W.Pooled(rowType)
	return pools[rowType] and #pools[rowType] or 0
end

-- Each type's methods are copied onto its widgets as they're built. A
-- Refresh that comes after a release (a hidden edit box losing focus) does
-- nothing.
local function define(rowType, methods)
	local build = builders[rowType]
	builders[rowType] = function(w)
		for name, fn in pairs(methods) do w[name] = fn end
		if methods.Refresh then
			local refresh = methods.Refresh
			w.Refresh = function(self, ...)
				if self.row then return refresh(self, ...) end
			end
		end
		build(w)
	end
end

------------------------------------------------------------------ whole units

-- SaftUI's scale makes a unit a pixel, and a 1px border or line on a frame
-- whose edge sits between two pixels blurs (or the game snaps it away, or
-- doubles it). So the window, its dialogs and its menus keep every edge on a
-- whole unit, whatever they hold (the body's heights: OB.WholeHeight).

-- Places frame, width x height (the size just given it), over relative's
-- middle as near as whole units allow: its top left corner half its size,
-- rounded down, left of and above relative's centre. Anchored by its own
-- centre, a frame of odd height (or width) would have every edge half a unit
-- off, and all it holds with it. relative's centre is whole itself (the
-- options window's is: an even size on whole units; and so is the screen's).
-- Placed again whenever its size changes.
function W.PlaceCentred(frame, relative, width, height)
	frame:ClearAllPoints()
	frame:SetPoint('TOPLEFT', relative, 'CENTER', -math.floor(width / 2), math.floor(height / 2))
end

------------------------------------------------------------------ custom types

-- The types other files define (the bags' Categories tab): W.CUSTOM[rowType]
-- is { bare = true | false, titled = true | false, fill = true | false,
-- minHeight = n | nil } for each. The body draws a bare type's row with no
-- label, the widget across the whole line, and a titled bare type's with its
-- name above the widget; a fill type's row takes the height the body's view
-- has left, minHeight at least (optionsbody.lua).
W.CUSTOM = {}

-- The built-in types, which W.Define can't replace. The last type file,
-- optionsposition.lua, fills it once every built-in type has its builder.
local BUILT_IN = {}

-- W.Define(rowType, { width = n, bare = bool, titled = bool, fill = bool,
-- minHeight = n, build = function(w) end, methods = { Refresh = ...,
-- OnRelease = ..., ... } }) makes a widget type.
-- titled is for a bare type only: its row shows its name over the widget.
-- fill is for a bare type only too: its row stretches down to the bottom of
-- the body's view, so a page of it has nothing to scroll (the Categories tab,
-- whose list and editor scroll on their own); the body gives the widget its
-- height with w:SetHeight(h), never less than minHeight (34 when nil).
-- build makes w.frame, and whatever else the type keeps, once per widget.
-- The methods are copied onto each widget as define copies a built-in
-- type's, so Bind, Refresh (nothing after a release), Commit, SetDisabled
-- (OnDisabled) and Release (OnRelease) work as for the built-in types.
-- width is W.WIDTH[rowType] and the widget's GetWidth (0 when nil). A custom
-- type may be defined again (its file loaded again): widgets are then built
-- from the new definition, in a new pool, so the old ones never come back.
-- Redefining a built-in type is an error.
function W.Define(rowType, spec)
	if BUILT_IN[rowType] then
		error(format('SaftUI options: %q is a built-in widget type', tostring(rowType)), 2)
	end
	if type(rowType) ~= 'string' or type(spec) ~= 'table' or type(spec.build) ~= 'function' then
		error(format('SaftUI options: W.Define(%q) needs a type name and a build function', tostring(rowType)), 2)
	end
	builders[rowType] = spec.build
	define(rowType, spec.methods or {})
	pools[rowType] = {}
	W.WIDTH[rowType] = spec.width or 0
	local fill = (spec.bare and spec.fill) and true or false
	W.CUSTOM[rowType] = {
		bare = spec.bare and true or false,
		titled = (spec.bare and spec.titled) and true or false,
		fill = fill,
		minHeight = fill and (spec.minHeight or 34) or nil,
	}
end

------------------------------------------------------------------ for the later widget files

Kit.FIELD_HEIGHT, Kit.LIST_STRATA, Kit.Base, Kit.builders = FIELD_HEIGHT, LIST_STRATA, Base, builders
W.FIELD_HEIGHT = FIELD_HEIGHT -- the window's files take it from here too
Kit.define, Kit.BUILT_IN = define, BUILT_IN
