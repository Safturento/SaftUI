-- Three small things of /sui's window sizes, from the final review:
--   - the title's page list (collapsed sidebar) takes no click that ends a
--     drag, as the bar's names and a mover don't;
--   - a size change takes the keyboard from a box of the window's, whatever
--     the size (the render rebinds its pooled boxes to other rows);
--   - the size arrows wear Blizzard's art only where every one of its atlases
--     exists (the pressed and disabled ones and the highlight too).
-- Real: Core's Config on a real AceDB, the model, the widgets, the body and the
-- window (options_window_helpers.lua). The mouse is played by firing scripts.
local H = load_test_file('core/options_window_helpers.lua')
local st = SaftUI
local OW, W = st.OptionsWindow, st.OptionsWidgets
local theme, close_all, frames, click = H.theme, H.close_all, H.frames, H.click
if not _G.GameTooltip then CreateFrame('GameTooltip', 'GameTooltip', UIParent) end

local function wait() stub.time = stub.time + 0.31 end

test("a drag by the page's title is no click: it opens no list; a plain click does", function()
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
	st.Config:Open('Loot')
	wait(); OW:SetSidebarShown(false)
	local F = frames()
	local button = F.titleButton
	check(button:IsShown(), 'the title is a button while the sidebar is collapsed')
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	stub.fire_script(button, 'OnDragStart')
	stub.fire_script(button, 'OnDragStop')
	click(button)
	eq(W.ListOwner(), nil, 'the click that ends a drag opens nothing')
	stub.fire_script(button, 'OnMouseDown', 'LeftButton')
	click(button)
	eq(W.ListOwner(), button, 'a click opens the list')
	W.CloseList()
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test('a size change takes the keyboard from a box of the window, at full and at half too', function()
	st.config.global.optionsWindow = nil
	close_all()
	theme('thick')
	st.Config:Open('Loot')
	local F = frames()
	F.search:SetFocus()
	eq(GetCurrentKeyBoardFocus(), F.search, 'the search box has it')
	wait(); check(OW:SetWindowSize('half'), 'shrink')
	eq(GetCurrentKeyBoardFocus(), nil, 'shrinking to half took it')
	F.search:SetFocus()
	wait(); check(OW:SetWindowSize('full'), 'grow')
	eq(GetCurrentKeyBoardFocus(), nil, 'growing took it')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)

test("the arrows keep the chevron when the client lacks any one of Blizzard's atlases, not only the normal ones", function()
	local info = C_Texture.GetAtlasInfo
	local art = st.ThemeArt.Control('sizebutton')
	local members = { art.grow.pushed, art.grow.disabled, art.shrink.pushed, art.shrink.disabled, art.highlight }
	for _, missing in ipairs(members) do
		C_Texture.GetAtlasInfo = function(name)
			if name == missing then return nil end
			return info(name)
		end
		st.config.global.optionsWindow = nil
		close_all()
		theme('blizzard')
		st.Config:Open('Loot')
		wait(); OW:SetWindowSize('half')
		local F = frames()
		check(F.shrink.icon:IsShown() and F.grow.icon:IsShown(), 'without ' .. missing .. ': the chevrons')
		C_Texture.GetAtlasInfo = info
	end
	C_Texture.GetAtlasInfo = info
	theme('thick')
	st.config.global.optionsWindow = nil
	close_all()
	eq(#take_errors(), 0, 'no errors')
end)
