-- SaftUI-Core/constants.lua's st.TINT_ROW and st.TINT_OBJECT, and its st.icons:
-- Lucide's icons by name, as TGA files in
-- SaftUI-Core/Media/Textures (made by tools/lucide-to-tga.cjs).
--
-- Real: constants.lua through the core shell. The files are read off the disk with
-- read_saftui_source (which turns any CRLF pair into LF; a white TGA has no 13
-- followed by 10, so its bytes come back as they are).
local st = SaftUI

local NAMES = { 'x', 'chevronDown', 'chevronUp', 'rotateCcw', 'diff', 'ellipsis', 'ellipsisVertical', 'settings', 'funnel', 'arrowDownToLine',
	'logOut', 'grid3x3', 'magnet', 'alignStartVertical', 'layers', 'mapPin', 'eye', 'powerOff', 'search', 'undo2', 'redo2', 'history', 'pictureInPicture2', 'panelTop',
	'chevronLeft', 'chevronRight', 'panelLeftOpen', 'panelLeftClose', 'move', 'keyboard', 'list', 'minimize2', 'maximize2',
	'squareMousePointer', 'squareDashedMousePointer', 'link' }

local function read(path)
	return (read_saftui_source(path))
end

-- The path the game is given -> the file in the repo.
local function repo_path(texture)
	local name = texture:match('Textures\\([^\\]+)$')
	return name and ('SaftUI-Core/Media/Textures/' .. name)
end

-- Decision 29: a hovered or selected row in a list is tinted at 25%, a selected
-- object's fill at 15%.
test('st.TINT_ROW and st.TINT_OBJECT: the two tint strengths', function()
	eq(st.TINT_ROW, 0.25, 'a row, hovered or selected')
	eq(st.TINT_OBJECT, 0.15, "a selected object's fill")
end)

test('st.icons: every registered icon is a file on disk', function()
	for _, name in ipairs(NAMES) do
		local texture = st.icons[name]
		check(type(texture) == 'string', name .. ' is registered')
		local path = repo_path(texture)
		check(path ~= nil and path:find('lucide-', 1, true) ~= nil, name .. ': a lucide-*.tga under Media/Textures')
		check(read(path) ~= nil, name .. ': ' .. tostring(path) .. ' exists')
	end
	local count = 0
	for _ in pairs(st.icons) do count = count + 1 end
	eq(count, #NAMES, 'and nothing else is registered without a test line')
end)

test('st.icons: each file is a 32x32 uncompressed 32-bit TGA, white, with some alpha', function()
	for _, name in ipairs(NAMES) do
		local data = read(repo_path(st.icons[name]))
		eq(#data, 18 + 32 * 32 * 4, name .. ': the size of 32x32 at 4 bytes')
		eq(data:byte(3), 2, name .. ': uncompressed true colour')
		eq(data:byte(13) + 256 * data:byte(14), 32, name .. ': 32 wide')
		eq(data:byte(15) + 256 * data:byte(16), 32, name .. ': 32 tall')
		eq(data:byte(17), 32, name .. ': 32 bits a pixel')
		eq(data:byte(18), 8, name .. ': 8 alpha bits, origin bottom left')
		local drawn, clear, white = 0, 0, true
		for i = 19, #data, 4 do
			if data:byte(i + 3) > 0 then drawn = drawn + 1 else clear = clear + 1 end
			if data:byte(i) ~= 255 or data:byte(i + 1) ~= 255 or data:byte(i + 2) ~= 255 then white = false end
		end
		check(white, name .. ': white in every pixel, so a tint is the whole colour')
		check(drawn > 40 and clear > 400, name .. ': a glyph on transparent')
	end
end)

test('st.icons: the old close texture is gone, and its license is kept', function()
	eq(st.textures.close, nil, 'no st.textures.close')
	eq(read('SaftUI-Core/Media/Textures/close.tga'), nil, 'no close.tga')
	check(read('SaftUI-Core/Media/Textures/LUCIDE-LICENSE.txt') ~= nil, "Lucide's license sits with its icons")
end)
