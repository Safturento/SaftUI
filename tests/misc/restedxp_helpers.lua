-- What the RestedXP skin tests share: building the world, and reading the
-- widgets back through the game's API. Not a test (no _test suffix), so the
-- runner doesn't run it; each restedxp_*_test.lua loads it with
-- load_test_file('misc/restedxp_helpers.lua').

local H = {}

H.RXP = load_test_file('misc/fixtures/restedxp_world.lua')

-- A fresh world with the skin loaded, as in game: the core's frame helpers
-- (real: panels, fonts, templates), SaftUI-Chat's defaults (the skin follows
-- chat's template and font), the Skinning module the skin is a submodule of,
-- then SaftUI-Misc's restedxp.lua. RestedXP itself comes from RXP.make().
--
-- The profile keeps Core's real defaults, except thick's border color: in the
-- defaults thick and thicktransparent (the chat's template) share one, so a
-- switch from one to the other wouldn't show in a divider's color.
function H.fresh()
	reset_world()
	load_core_helpers()
	load_saftui('SaftUI-Chat/config.lua')
	apply_defaults()
	local profile = SaftUI.config.profile
	profile.templates.thick.bordercolor = { 0.5, 0.2, 0.2, 1 }
	load_saftui('SaftUI-Misc/Skinning/skinning.lua')
	load_saftui('SaftUI-Misc/Skinning/restedxp.lua')
end

function H.get_rx()
	return SaftUI:GetModule('Skinning'):GetModule('RestedXP')
end

-- The profile's text grey, which the skin's grey text should be.
function H.is_grey(r, g, b)
	local gr, gg, gb = SaftUI.config.profile.colors.text.grey:GetRGB()
	return H.near(r, gr) and H.near(g, gg) and H.near(b, gb)
end

function H.near(a, b)
	return math.abs(a - b) < 1e-6
end

-- A font string's font: the face and outline of SaftUI's font object named
-- face ('normal', 'title', 'pixel'), or face itself if it names no such font
-- (RestedXP's own 'GameFontFace').
function H.font(fs, face, size, outline)
	local object = SaftUI:GetFont(face)
	if object then face = (object:GetFont()) end
	local f, s, o = fs:GetFont()
	return f == face and s == size and o == outline
end

-- The anchor of frame at point, as { rel =, relPoint =, x =, y = }, or nil.
function H.pt(frame, point)
	for i = 1, frame:GetNumPoints() do
		local p, rel, relPoint, x, y = frame:GetPoint(i)
		if p == point then return { rel = rel, relPoint = relPoint, x = x, y = y } end
	end
end

-- The textures of frame painted a color with SetColorTexture: { r, g, b, a }.
function H.color_of(texture)
	return stub.state(texture).color_texture
end

function H.colored(frame, r, g, b, a)
	local out = {}
	for _, t in ipairs({ frame:GetRegions() }) do
		local c = t:GetObjectType() == 'Texture' and H.color_of(t)
		if c and H.near(c[1], r) and H.near(c[2], g) and H.near(c[3], b) and H.near(c[4], a) then
			table.insert(out, t)
		end
	end
	return out
end

-- The SaftUI panel parented to frame: a child RestedXP didn't make that has a
-- backdrop (st:SetBackdrop puts one on it). Returns the first, or all of them
-- if all is set.
function H.panels_of(frame, all)
	local out = {}
	for _, c in ipairs({ frame:GetChildren() }) do
		if not H.RXP.is_rxp(c) and c.backdrop and c.backdrop.template then table.insert(out, c) end
	end
	if all then return out end
	return out[1]
end

-- Puts the cursor in the middle of frame (cursor positions are in screen
-- units, the frame's units times its effective scale), or off the window.
function H.cursor_on(frame)
	local x, y = frame:GetCenter()
	local scale = frame:GetEffectiveScale()
	stub.cursor_x, stub.cursor_y = x * scale, y * scale
end

function H.cursor_off()
	stub.cursor_x, stub.cursor_y = 0, 0
end

-- The stubs have no text layout, so a font string is one line tall. This makes
-- fs measure h, as the game's layout does once the text wraps; nil measures as
-- nothing, as for a font string that isn't laid out.
function H.text_height(fs, h)
	rawset(fs, 'GetStringHeight', function() return h end)
end

-- Runs fn and returns how many times hooksecurefunc hooked each method of each
-- table: counts[tbl][name].
function H.count_hooks(fn)
	local counts = {}
	local original = hooksecurefunc
	hooksecurefunc = function(tbl, name, hook)
		counts[tbl] = counts[tbl] or {}
		counts[tbl][name] = (counts[tbl][name] or 0) + 1
		return original(tbl, name, hook)
	end
	local ok, err = pcall(fn)
	hooksecurefunc = original
	if not ok then error(err, 0) end
	return counts
end

-- SaftUI-Chat as the skin sees it: a stand-in, the one exception to rule 1 in
-- .agents/testing.md (never fake a SaftUI function), because the real chat
-- code needs Blizzard's ChatFrame1..N, tabs and edit boxes. It models only the
-- contract the skin consumes (restedxp.lua OnEnable): ApplyAppearance exists
-- and can be hooked, and UpdateConfig and the options setter end in it.
--
-- What the real ones also do, which this omits:
--   - CHT:UpdateConfig (SaftUI-Chat/chatframe.lua:326-335) runs MigratePosition,
--     CaptureSize and ApplyHolder before ApplyAppearance;
--   - the options General setter (SaftUI-Chat/options.lua:63-72) takes the
--     width/height branch (CaptureSize, ApplyHolder) instead of ApplyAppearance
--     for those two keys. SetOption is this stand-in's name for that closure,
--     and covers only the other keys.
function H.make_chat()
	local Chat = SaftUI:NewModule('Chat')
	Chat.config = SaftUI.config.profile.chat
	function Chat:ApplyAppearance() end
	function Chat:UpdateConfig()
		if not self.config then return end
		self:ApplyAppearance()
	end
	-- the General setter's path for any key but width/height
	function Chat:SetOption(key, value)
		self.config[key] = value
		self:ApplyAppearance()
	end
	return Chat
end

return H
