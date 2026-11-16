// Makes the selected Fill's ramp: SaftUI-Core/Media/Textures/state-fade.tga.
//
// 256 x 8, every pixel white (255, 255, 255) with the alpha of its column x:
// floor(255 * (1 - x / 255) + 0.5), which is 255 at the left falling evenly to 0
// in the last column. Written as an uncompressed 32-bit TGA the way the Lucide
// icons are (type 2, origin bottom left, 8 alpha bits). The widget helpers
// (SaftUI-Core/Widgets/states.lua) set it with wrap mode CLAMP and the texture
// coordinates (0, 1 / f, 0, 1), so the fade ends f of the way across the widget.
// The TGA is committed; nothing runs this at load or build time. No
// dependencies. From the repo root:
//
//   node tools/fade-to-tga.cjs

const fs = require('fs')
const path = require('path')

const WIDTH = 256
const HEIGHT = 8
const OUT = path.join(__dirname, '..', 'SaftUI-Core', 'Media', 'Textures', 'state-fade.tga')

const header = Buffer.alloc(18)
header[2] = 2 // uncompressed true colour
header.writeUInt16LE(WIDTH, 12)
header.writeUInt16LE(HEIGHT, 14)
header[16] = 32
header[17] = 8 // 8 alpha bits, origin bottom left

const body = Buffer.alloc(WIDTH * HEIGHT * 4)
for (let y = 0; y < HEIGHT; y++) {
	for (let x = 0; x < WIDTH; x++) {
		const at = (y * WIDTH + x) * 4 // BGRA
		body[at] = 255
		body[at + 1] = 255
		body[at + 2] = 255
		body[at + 3] = Math.floor(255 * (1 - x / 255) + 0.5)
	}
}

fs.writeFileSync(OUT, Buffer.concat([header, body]))
console.log('wrote ' + path.relative(process.cwd(), OUT))
