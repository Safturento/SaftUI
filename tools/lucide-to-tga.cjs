// Makes SaftUI's Lucide icon textures (SaftUI-Core/Media/Textures/lucide-<name>.tga).
//
// Each icon is Lucide's own SVG (lucide-static, pinned below, stroke width 2,
// round caps and joins), drawn white on transparent so code tints it with
// SetVertexColor, at SIZE x SIZE and written as an uncompressed 32-bit TGA the
// way close.tga was (origin bottom left, 8 alpha bits). The TGAs are committed;
// nothing runs this at load or build time.
//
// To add or redo an icon:
//   1. Install the rasteriser anywhere outside the repo:
//        mkdir /tmp/lucide-tool && cd /tmp/lucide-tool && npm init -y && npm install @resvg/resvg-js
//   2. From the repo root:
//        NODE_PATH=/tmp/lucide-tool/node_modules node tools/lucide-to-tga.cjs chevron-down x ...
//   3. Register the new name in st.icons (SaftUI-Core/constants.lua), which
//      tests/core/icons_test.lua checks against the files.
//
// SIZE is 32: Lucide draws on a 24 grid with the glyph in the middle 12 or so,
// and SaftUI draws icons at 10 to 16 px, so 32 is a whole-number 2x or more over
// the size drawn, enough for the 2 px stroke to stay smooth at 16 px, and the
// game needs power-of-two sides.

const fs = require('fs')
const path = require('path')
const { Resvg } = require('@resvg/resvg-js')

const VERSION = '0.460.0'
const SIZE = 32
const OUT = path.join(__dirname, '..', 'SaftUI-Core', 'Media', 'Textures')

function tga(width, height, rgba) {
	const header = Buffer.alloc(18)
	header[2] = 2 // uncompressed true colour
	header.writeUInt16LE(width, 12)
	header.writeUInt16LE(height, 14)
	header[16] = 32
	header[17] = 8 // 8 alpha bits, origin bottom left
	const body = Buffer.alloc(width * height * 4)
	for (let y = 0; y < height; y++) {
		const from = (height - 1 - y) * width * 4 // rows run bottom to top
		for (let x = 0; x < width; x++) {
			const s = from + x * 4, d = (y * width + x) * 4
			// White whatever the alpha: the PNG's colour at the soft edge is not wanted.
			body[d] = 255; body[d + 1] = 255; body[d + 2] = 255; body[d + 3] = rgba[s + 3]
		}
	}
	return Buffer.concat([header, body])
}

async function main() {
	const names = process.argv.slice(2)
	if (names.length === 0) {
		console.error('usage: node tools/lucide-to-tga.cjs <lucide icon name>...')
		process.exit(2)
	}
	for (const name of names) {
		const url = `https://unpkg.com/lucide-static@${VERSION}/icons/${name}.svg`
		const response = await fetch(url)
		if (!response.ok) throw new Error(`${url}: ${response.status}`)
		const svg = (await response.text()).replace(/currentColor/g, '#ffffff')
		const image = new Resvg(svg, { fitTo: { mode: 'width', value: SIZE } }).render()
		if (image.width !== SIZE || image.height !== SIZE) throw new Error(`${name}: drew ${image.width}x${image.height}`)
		const file = path.join(OUT, `lucide-${name}.tga`)
		fs.writeFileSync(file, tga(SIZE, SIZE, image.pixels))
		console.log('wrote', file)
	}
}

main().catch(error => { console.error(error); process.exit(1) })
