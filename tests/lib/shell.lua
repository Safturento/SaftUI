--[[
	The core shell: SaftUI's core as it is in game before any module code
	runs, without loading Ace3. It stands in for init.lua and the module
	plumbing Ace3 gives SaftUI (AceAddon modules, AceEvent, AceHook, AceDB's
	profile), mimicking those libraries' behavior, then loads Core's real
	constants.lua, api.lua and utilities.lua in their TOC order.

	It never fakes what a test checks. SaftUI's own helpers come from its real
	files: tests that need Core's frame helpers (st:CreateFrame, st:SetBackdrop,
	st:CreateButton, st:GetFont, st.Config.generators) call
	load_core_helpers().

	What it gives tests, besides the real files' contents:
	  SaftUI                  SaftUI-Core's namespace, as in game
	  st:NewModule(name), st:GetModule(name, silent), st:IterateModules(), st.modules
	  on every module (and SaftUI): NewModule, GetModule, IterateModules, SetDefaultModuleLibraries, Enable,
	    IsEnabled, RegisterEvent, UnregisterEvent, SecureHook, HookScript
	  st.config.profile       empty until apply_defaults()
	  st:BindModuleConfig     as SaftUI-Core/Config/config.lua has it
	  st.Config               the Config module, with Refresh and GetWindow (no /sui window)
	  apply_defaults()        fills st.config.profile from st.defaults, with AceDB's wildcard keys
	  load_core_helpers()     loads Core's frame helpers and what they need
]]

local function pack(...)
	return { n = select('#', ...), ... }
end

-- In game init.lua makes the addon object from SaftUI-Core's namespace, so
-- SaftUI and the namespace Core's files get are the same table.
local st = addon_namespace('SaftUI-Core')
SaftUI = st

-- AceAddon's safecall: optional handlers (OnInitialize, OnEnable) run
-- through the error handler, so one failing doesn't stop the rest.
local function safecall(fn, ...)
	if type(fn) == 'function' then
		local args = pack(...)
		return xpcall(function() return fn(unpack(args, 1, args.n)) end, geterrorhandler())
	end
end

------------------------------------------------------------------ AceEvent

-- AceEvent registers its events on one frame and dispatches them to every
-- object registered for them, through CallbackHandler.
local eventFrame = CreateFrame('Frame')
-- event -> list of { owner, fn }. The shell calls them in registration order.
-- Real CallbackHandler iterates its registry with pairs, so the game
-- guarantees no order between objects: tests must not rely on handler order.
local handlers = {}

eventFrame:SetScript('OnEvent', function(_, event, ...)
	local args = pack(...)
	local list = {}
	for i, handler in ipairs(handlers[event] or {}) do list[i] = handler end
	for _, handler in ipairs(list) do
		if handler.active then
			safecall(handler.fn, event, unpack(args, 1, args.n))
		end
	end
end)

local function unregister(owner, event)
	for i, handler in ipairs(handlers[event] or {}) do
		if handler.owner == owner then
			handler.active = false
			table.remove(handlers[event], i)
			break
		end
	end
	if handlers[event] and #handlers[event] == 0 then
		handlers[event] = nil
		eventFrame:UnregisterEvent(event)
	end
end

------------------------------------------------------------------ objects

-- The methods SaftUI's addon object and each module get. In game they're
-- AceAddon's plus the AceEvent and AceHook mixins init.lua sets as every
-- module's default libraries. Like AceAddon's embeds, they're copied onto
-- each object.
local Object = {}

local function new_object(object, name)
	for key, fn in pairs(Object) do object[key] = fn end
	object.name = name
	object.modules, object.orderedModules = {}, {}
	object.hooks = {} -- AceHook keeps a hooked script's original handler here
	object.enabledState = true -- AceAddon's default module state
	return object
end

-- AceAddon names a module after its parent: SaftUI_EditMode.
function Object:NewModule(name, ...)
	if type(name) ~= 'string' then
		error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]): 'name' - string expected got '%s'."):format(type(name)), 2)
	end
	if select('#', ...) > 0 then
		error("the core shell's NewModule takes only a name (SaftUI's modules get AceEvent and AceHook by default)", 2)
	end
	if self.modules[name] then
		error(("Usage: NewModule(name, [prototype, [lib, lib, lib, ...]): 'name' - Module '%s' already exists."):format(name), 2)
	end
	local module = new_object({}, ('%s_%s'):format(self.name or tostring(self), name))
	module.moduleName = name
	self.modules[name] = module
	table.insert(self.orderedModules, module)
	return module
end

-- AceAddon's: the libraries every module made after this call gets. The shell
-- gives every module AceEvent and AceHook (SaftUI's default), so those are the
-- only ones it takes. Like AceAddon, it can't change once a module exists.
function Object:SetDefaultModuleLibraries(...)
	if next(self.modules) then
		error('Usage: SetDefaultModuleLibraries(...): cannot change the module defaults after a module has been registered.', 2)
	end
	for i = 1, select('#', ...) do
		local library = select(i, ...)
		if library ~= 'AceEvent-3.0' and library ~= 'AceHook-3.0' then
			error(("the core shell's modules only have AceEvent-3.0 and AceHook-3.0, got '%s'"):format(tostring(library)), 2)
		end
	end
end

function Object:GetModule(name, silent)
	if not self.modules[name] and not silent then
		error(("Usage: GetModule(name, silent): 'name' - Cannot find module '%s'."):format(tostring(name)), 2)
	end
	return self.modules[name]
end

function Object:IterateModules()
	return pairs(self.modules)
end

-- AceAddon's: the module's enabled state, true by default, even before
-- Enable has run.
function Object:IsEnabled()
	return self.enabledState
end

local initialized, enabled = {}, {}

-- In game AceAddon runs every OnInitialize (the addon's, then its modules',
-- at ADDON_LOADED) before any OnEnable (at login). The shell's Enable does
-- both, each once: it initializes the object and its whole module subtree
-- first, then enables the object and then its modules in the order they were
-- made, as AceAddon:EnableAddon does.
local function initialize(object)
	if initialized[object] then return end
	initialized[object] = true
	safecall(object.OnInitialize, object)
	for _, module in ipairs(object.orderedModules) do
		initialize(module)
	end
end

local function enable(object)
	if enabled[object] or not object.enabledState then return false end
	enabled[object] = true
	safecall(object.OnEnable, object)
	for _, module in ipairs(object.orderedModules) do
		enable(module)
	end
	return true
end

function Object:Enable()
	self.enabledState = true
	initialize(self)
	return enable(self)
end

-- AceEvent (through CallbackHandler): method is a method name (default: the
-- event's name), which must exist on self now, or a function. A method name
-- is called as self[method](self, event, ...), a function as fn(event, ...).
-- With an extra arg, it comes before event. Registering again replaces it.
function Object:RegisterEvent(event, method, ...)
	if type(event) ~= 'string' then
		error("Usage: RegisterEvent(eventname, method[, arg]): 'eventname' - string expected.", 2)
	end
	method = method or event
	local hasArg, arg = select('#', ...) >= 1, ...
	local fn
	if type(method) == 'string' then
		if type(self[method]) ~= 'function' then
			error(("Usage: RegisterEvent(\"eventname\", \"methodname\"): 'methodname' - method '%s' not found on self."):format(method), 2)
		end
		fn = hasArg and function(...) self[method](self, arg, ...) end or function(...) self[method](self, ...) end
	elseif type(method) == 'function' then
		fn = hasArg and function(...) method(arg, ...) end or method
	else
		error("Usage: RegisterEvent(eventname, method[, arg]): 'methodname' - string or function expected.", 2)
	end
	unregister(self, event)
	handlers[event] = handlers[event] or {}
	table.insert(handlers[event], { owner = self, fn = fn, active = true })
	eventFrame:RegisterEvent(event)
end

function Object:UnregisterEvent(event)
	unregister(self, event)
end

-- AceHook's checks: a handler named by string must exist on self, and the
-- same target can't be hooked twice.
local hooked = {} -- object -> target -> name -> true

local function claim_hook(object, target, name)
	hooked[object] = hooked[object] or {}
	hooked[object][target] = hooked[object][target] or {}
	if hooked[object][target][name] then
		error(('Attempting to rehook already active hook %s.'):format(name), 3)
	end
	hooked[object][target][name] = true
end

local function call_handler(object, handler, ...)
	if type(handler) == 'string' then
		return object[handler](object, ...)
	end
	return handler(...)
end

local function check_handler(object, handler, usage)
	if type(handler) ~= 'string' and type(handler) ~= 'function' then
		error(("%s: 'handler' - nil, string, or function expected got %s"):format(usage, type(handler)), 3)
	end
	if type(handler) == 'string' and type(object[handler]) ~= 'function' then
		error(("%s: 'handler' - Handler specified does not exist at self[handler]"):format(usage), 3)
	end
end

-- AceHook:SecureHook([object], method, [handler]): a post-hook through
-- hooksecurefunc. The handler gets the hooked call's arguments.
function Object:SecureHook(object, method, handler)
	if type(object) == 'string' then
		object, method, handler = nil, object, method
	end
	local usage = 'Usage: SecureHook([object], method, [handler])'
	handler = handler or method
	check_handler(self, handler, usage)
	local target = object or _G
	if type(target[method]) ~= 'function' then
		error(usage .. ': Attempting to hook a non existing target', 2)
	end
	claim_hook(self, target, method)
	hooksecurefunc(target, method, function(...) call_handler(self, handler, ...) end)
end

-- AceHook:HookScript(frame, script, [handler]): a pre-hook that replaces the
-- script with one calling the handler, then the original.
function Object:HookScript(frame, script, handler)
	local usage = 'Usage: HookScript(object, method, [handler])'
	handler = handler or script
	check_handler(self, handler, usage)
	if type(frame) ~= 'table' or not frame.GetScript or not frame:HasScript(script) then
		error(usage .. ': You can only hook a script on a frame object', 2)
	end
	claim_hook(self, frame, script)
	local original = frame:GetScript(script) or function() end
	self.hooks[frame] = self.hooks[frame] or {}
	self.hooks[frame][script] = original
	frame:SetScript(script, function(...)
		call_handler(self, handler, ...)
		return original(...)
	end)
end

------------------------------------------------------------------ SaftUI

-- AceAddon names the addon after its folder; constants.lua renames it.
new_object(st, 'SaftUI-Core')

-- AceDB's profile. In game AceDB builds it from st.defaults; here it starts
-- empty and apply_defaults() fills it.
st.config = { profile = {} }

-- As SaftUI-Core/Config/config.lua has it: points module.config at the
-- profile's key and remembers the key for a profile change.
function st:BindModuleConfig(module, key)
	module.configKey = key
	module.config = st.config.profile[key]
	return module.config
end

-- Fills st.config.profile from st.defaults the way AceDB-3.0's copyDefaults
-- does (SaftUI-Core/Libraries/Ace3/AceDB-3.0/AceDB-3.0.lua): every key the
-- profile lacks gets the default (tables are deep-copied), and values the
-- profile has are kept. The wildcard keys are AceDB's too:
--   ['*'] and ['**'] are never keys of the profile. Their value is the
--   default of every key the table doesn't have: a table is copied into each
--   new subtable, a plain value is what any other key reads as. It works for
--   keys made later, through a metatable on the table, and it is filled into
--   the tables the profile already has there.
--   ['**'] beside other tables' keys also fills those keys' tables.
-- Load the defaults files (e.g. SaftUI-Core/Config/defaults.lua) first.
local function copy_defaults(dest, src)
	for key, value in pairs(src) do
		if key == '*' or key == '**' then
			if type(value) == 'table' then
				setmetatable(dest, {
					__index = function(t, key2)
						if key2 == nil then return nil end
						local subtable = {}
						copy_defaults(subtable, value)
						rawset(t, key2, subtable)
						return subtable
					end,
				})
				for existing_key, existing in pairs(dest) do
					if not rawget(src, existing_key) and type(existing) == 'table' then
						copy_defaults(existing, value)
					end
				end
			else
				setmetatable(dest, { __index = function(t, key2) return key2 ~= nil and value or nil end })
			end
		elseif type(value) == 'table' then
			if not rawget(dest, key) then rawset(dest, key, {}) end
			if type(dest[key]) == 'table' then
				copy_defaults(dest[key], value)
				if src['**'] then
					copy_defaults(dest[key], src['**'])
				end
			end
		elseif rawget(dest, key) == nil then
			rawset(dest, key, value)
		end
	end
	return dest
end

function apply_defaults()
	if type(st.defaults) ~= 'table' then
		error('apply_defaults: there is no st.defaults yet; load SaftUI-Core/Config/defaults.lua first', 2)
	end
	copy_defaults(st.config.profile, st.defaults)
end

-- Core's frame helpers and what they need, in TOC order: LibSharedMedia and
-- its libraries, Widgets/button.lua (st:CreateButton), panels.lua
-- (st:CreateFrame, st:SetBackdrop, st:CreateFontString), the media and fonts
-- (st:GetFont), the profile defaults and Config/widgets.lua
-- (st.Config.generators). Then the profile is filled from the defaults and
-- the Fonts module enabled, as at login, so st:GetFont has font objects.
function load_core_helpers()
	load_saftui('SaftUI-Core/Libraries/LibStub/LibStub.lua')
	load_saftui('SaftUI-Core/Libraries/CallbackHandler-1.0/CallbackHandler-1.0.lua')
	load_saftui('SaftUI-Core/Libraries/LibSharedMedia-3.0/LibSharedMedia-3.0.lua')
	load_saftui('SaftUI-Core/Widgets/button.lua')
	load_saftui('SaftUI-Core/panels.lua')
	load_saftui('SaftUI-Core/Media/sharedmedia.lua')
	load_saftui('SaftUI-Core/Media/fonts.lua')
	load_saftui('SaftUI-Core/Config/defaults.lua')
	load_saftui('SaftUI-Core/Config/widgets.lua')
	apply_defaults()
	st:GetModule('Fonts'):Enable()
end

-- Core's TOC loads these three in this order (with Widgets, skinning.lua and
-- panels.lua between api.lua and utilities.lua).
load_saftui('SaftUI-Core/constants.lua')
load_saftui('SaftUI-Core/api.lua')
load_saftui('SaftUI-Core/utilities.lua')

-- Config/config.lua's module, made after constants.lua as in game, so it's
-- SaftUI_Config. Its real Refresh redraws an open /sui window and GetWindow
-- returns it; the shell has no /sui window.
st.Config = st:NewModule('Config')
function st.Config:Refresh() end
function st.Config:GetWindow() return nil end

-- What init.lua's OnEnable does: SaftUI's pixel-perfect scale, one UIParent
-- unit per physical pixel.
UIParent:SetScale(st.scale)
