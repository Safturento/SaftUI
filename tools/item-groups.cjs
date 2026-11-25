// Makes the bag item groups' data: SaftUI-Bags/itemgroups_data.lua.
//
// An item group is a named set of item IDs (today: fish) that the Inventory
// categories can match with a { block = 'group' } rule. The sets are derived
// from the game's own tables for the "forever" (wowf) build: Item and
// ItemSparse for class and name, ManifestInterfaceData for the icon path, and
// SpellReagents + SkillLineAbility + SkillLine for "is a reagent of a Cooking,
// Alchemy or Fishing recipe". Hand corrections live in
// tools/item-groups/<group>.overrides.txt (`+13757 Lightning Eel` adds an item,
// `-5468 Soft Frenzy Flesh` removes one; a `-` line always wins).
//
// The generated Lua file is committed; nothing runs this at load or build time.
// Rerun it after a content patch. From the repo root:
//
//   node tools/item-groups.cjs [--build <version>] [--from <dir>] [--out <path>]
//
// With no --build it asks https://wago.tools/api/builds for the newest wowf
// build and downloads each table as CSV from wago.tools. On a machine that
// can't reach wago.tools, put <Table>.csv files in a directory and pass
// --from <dir> (then --build is required, because it goes in the file header).
// Default --out is SaftUI-Bags/itemgroups_data.lua. No dependencies.

const fs = require('fs')
const path = require('path')

const TABLES = ['Item', 'ItemSparse', 'ManifestInterfaceData', 'SpellReagents', 'SkillLineAbility', 'SkillLine']

// Quoted fields may hold commas, newlines and "" for a quote. Rows shorter than
// the header (wago omits trailing columns) get '' for the missing ones.
function parseCSV(text) {
	const rows = []
	let row = []
	let field = ''
	let quoted = false
	for (let i = 0; i < text.length; i++) {
		const c = text[i]
		if (quoted) {
			if (c === '"') {
				if (text[i + 1] === '"') { field += '"'; i++ } else quoted = false
			} else field += c
		} else if (c === '"') quoted = true
		else if (c === ',') { row.push(field); field = '' }
		else if (c === '\n' || c === '\r') {
			if (c === '\r' && text[i + 1] === '\n') i++
			row.push(field); field = ''
			rows.push(row); row = []
		} else field += c
	}
	if (field !== '' || row.length) { row.push(field); rows.push(row) }
	const nonEmpty = rows.filter(r => !(r.length === 1 && r[0] === ''))
	if (!nonEmpty.length) return []
	const header = nonEmpty[0]
	return nonEmpty.slice(1).map(r => {
		const o = {}
		header.forEach((h, i) => { o[h] = r[i] === undefined ? '' : r[i] })
		return o
	})
}

const FISH_CLASSES = new Set([0, 7, 12, 15])
const FISH_WORDS = /\b(eel|snapper|salmon|squid|blackmouth|lobster|trout|mackerel|yellowtail|loach|grouper|bass|cod|halibut|albacore)\b/i
const EXCLUDED = /Deprecated|Monster|Test|Recipe|Writ|Pound|Bloated|Waylaid|Potion|Rune/
const RECIPE_LINES = new Set(['Cooking', 'Alchemy', 'Fishing'])

function selectFish(tables) {
	const icons = new Map()
	for (const r of tables.ManifestInterfaceData) icons.set(r.ID, ((r.FilePath || '') + (r.FileName || '')).toLowerCase())
	const sparse = new Map()
	for (const r of tables.ItemSparse) sparse.set(r.ID, r.Display_lang || '')

	// Skill lines named Cooking/Alchemy/Fishing plus any line parented to one.
	const roots = new Set(tables.SkillLine.filter(r => RECIPE_LINES.has(r.DisplayName_lang)).map(r => r.ID))
	const lines = new Set(roots)
	for (const r of tables.SkillLine) if (roots.has(r.ParentSkillLineID)) lines.add(r.ID)
	const spells = new Set(tables.SkillLineAbility.filter(r => lines.has(r.SkillLine)).map(r => r.Spell))
	const reagents = new Set()
	for (const r of tables.SpellReagents) {
		if (!spells.has(r.SpellID)) continue
		for (let i = 0; i < 8; i++) {
			const v = r['Reagent_' + i]
			if (v && v !== '0') reagents.add(v)
		}
	}

	const out = []
	for (const it of tables.Item) {
		if (!FISH_CLASSES.has(Number(it.ClassID))) continue
		const name = (sparse.get(it.ID) || '').replace(/[\r\n]+/g, ' ').trim()
		if (!name || EXCLUDED.test(name)) continue
		const icon = icons.get(it.IconFileDataID) || ''
		const fishy = icon.includes('fish') || /fish/i.test(name) || FISH_WORDS.test(name)
		if (!fishy) continue
		if (!(reagents.has(it.ID) || name.startsWith('Raw '))) continue
		out.push({ id: Number(it.ID), name })
	}
	return out.sort((a, b) => a.id - b.id)
}

function parseOverrides(text) {
	const add = new Map()
	const remove = new Set()
	text.split(/\r?\n/).forEach((raw, i) => {
		const line = raw.trim()
		if (line === '' || line.startsWith('#')) return
		const m = /^([+-])(\d+)(?:\s+(.*))?$/.exec(line)
		if (!m) throw new Error(`overrides: malformed line ${i + 1}: ${raw}`)
		const id = Number(m[2])
		if (m[1] === '+') add.set(id, (m[3] || '').trim())
		else remove.add(id)
	})
	return { add, remove }
}

function applyOverrides(candidates, overrides) {
	const byId = new Map()
	for (const c of candidates) byId.set(c.id, c)
	for (const [id, name] of overrides.add) byId.set(id, { id, name })
	for (const id of overrides.remove) byId.delete(id)
	return [...byId.values()].sort((a, b) => a.id - b.id)
}

function renderLua({ build, groups }) {
	const lines = [
		`-- Generated by tools/item-groups.cjs from wowf ${build}. Don't edit by hand:`,
		`-- change tools/item-groups/<group>.overrides.txt and run it again.`,
		`local INV = SaftUI:GetModule('Inventory')`,
		``,
		`INV.ItemGroupsData = {`,
		`\tforever = {`,
	]
	for (const [group, items] of Object.entries(groups)) {
		lines.push(`\t\t${group} = {`)
		for (const it of items) lines.push(`\t\t\t[${it.id}] = true, -- ${String(it.name).replace(/[\r\n]+/g, ' ')}`)
		lines.push(`\t\t},`)
	}
	lines.push(`\t},`, `}`, ``)
	return lines.join('\n')
}

function parseArgs(argv) {
	const args = {}
	for (let i = 0; i < argv.length; i++) {
		const a = argv[i]
		if (a === '--build' || a === '--from' || a === '--out') {
			if (i + 1 >= argv.length) throw new Error(`${a} needs a value`)
			args[a.slice(2)] = argv[++i]
		} else throw new Error(`unknown argument: ${a}`)
	}
	return args
}

async function fetchText(url) {
	const res = await fetch(url)
	if (!res.ok) throw new Error(`${url}: HTTP ${res.status}`)
	return res.text()
}

async function main() {
	const args = parseArgs(process.argv.slice(2))
	const root = path.join(__dirname, '..')
	let build = args.build
	if (!build) {
		if (args.from) throw new Error('--from needs --build (the build goes in the file header)')
		const builds = JSON.parse(await fetchText('https://wago.tools/api/builds'))
		const list = Array.isArray(builds) ? builds : Object.values(builds).flat()
		const wowf = list.find(b => /^wowf/.test(b.product || '') || b.branch === 'wowf')
			|| (builds.wowf && builds.wowf[0])
		if (!wowf || !wowf.version) throw new Error('no wowf build found at wago.tools/api/builds')
		build = wowf.version
	}
	const tables = {}
	for (const t of TABLES) {
		const text = args.from
			? fs.readFileSync(path.join(args.from, `${t}.csv`), 'utf8')
			: await fetchText(`https://wago.tools/db2/${t}/csv?build=${encodeURIComponent(build)}`)
		tables[t] = parseCSV(text)
	}
	const overridesPath = path.join(__dirname, 'item-groups', 'fish.overrides.txt')
	const overrides = parseOverrides(fs.existsSync(overridesPath) ? fs.readFileSync(overridesPath, 'utf8') : '')
	const fish = applyOverrides(selectFish(tables), overrides)
	const out = args.out || path.join(root, 'SaftUI-Bags', 'itemgroups_data.lua')
	fs.writeFileSync(out, renderLua({ build, groups: { fish } }))
	console.log(`build ${build}`)
	console.log(`fish: ${fish.length}`)
	console.log(`wrote ${out}`)
}

module.exports = { parseCSV, selectFish, parseOverrides, applyOverrides, renderLua }

if (require.main === module) {
	main().catch(e => { console.error(e.message); process.exit(1) })
}
