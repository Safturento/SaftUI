# SaftUI

A modular World of Warcraft UI replacement: unit frames, action bars, bags and bank, chat, minimap and micro menu, loot rolls and loot feed, and a set of flat, pixel-perfect skins for Blizzard frames. Every part is its own addon on top of `SaftUI-Core`. It runs on WoW Forever (interface 16001) and retail (interface 120000).

## Installation

1. Clone the repo.
2. Put each `SaftUI-*` folder in your game's `Interface/AddOns` folder for the client you play (e.g. `World of Warcraft/_forever_/Interface/AddOns`). For development, link them instead of copying. On Windows, use directory symlinks so the game sees folders:

   ```bat
   mklink /D "E:\Games\World of Warcraft\_forever_\Interface\AddOns\SaftUI-Core" "C:\path\to\SaftUI-Modular\SaftUI-Core"
   ```

   Repeat for each `SaftUI-*` folder. From WSL, run it through `cmd.exe /c`. A WSL `ln -s` link shows up as a file to the game, not a folder.
3. Enable the SaftUI addons on the character select screen. `SaftUI-Core` is required by all the others.

SaftUI sets the UI scale itself, to be pixel-perfect for your screen height, and ignores Blizzard's UI Scale setting.

## Usage

- `/sui` (or `/saftui`) opens the options window.
- `/sui edit` toggles SaftUI's edit mode. Drag frames, nudge them with the arrow keys (Shift for 10px), and click a frame to open its settings. Where frames overlap, a list by the cursor shows which one you'd grab, and Alt switches to the next. It also turns on when Blizzard's Edit Mode opens. Edit mode and the options window close when combat starts.
- `/sui` → Action Bars sets each bar's buttons, size, spacing, text and visibility (always, in combat only, or faded until moused over), for bars 1–8, the pet bar and the stance bar. Every bar is an edit mode frame. The pet bar shows while you have a pet out (right-click a pet ability to toggle its autocast), and the stance bar shows one button per stance or form your class has. The extra action button, the zone ability and a leave vehicle button are edit mode frames too, with their own size. The leave vehicle button shows in a vehicle you can leave; on a flight path, where it asks for an early landing; and while you control a creature (mind control or a quest), where it ends the possess.
- `/sui kb` (or "Keybind mode" in `/sui`) binds keys to SaftUI's action bars by hovering. Hover a button and press a key or mouse button, with any modifiers; right-click a button to clear its keys; Escape leaves. Bars set to show only in combat or faded show while it's on; to bind pet bar keys this way, have a pet out. SaftUI's bars use Blizzard's own action bar bindings, so binds show in Blizzard's Key Bindings menu, and the binds you already have keep working.
- `/sui` → Bags → Bag → General → Empty slots (Off, Grouped, Every slot) shows free bag slots as an Empty Slots category. Grouped is one slot for the bags and one for the reagent bag, each with its free count; drop an item on it to put the item in the first free slot. Items in the reagent bag carry a green wedge in the top right of the icon. `/sui` → Bags → General → Merge stacks shows stacks of one item as a single slot, kept apart for the reagent bag and your other bags.
- `/sui` → Totem Bar is for Blizzard's shaman totem bar on WoW Forever, which SaftUI skins to match its action bars, each element's button bordered in that element's colour. Above each element button, while that element has a totem down, a bar drains and a countdown shows how long the totem has left; both turn red in the last 10 seconds. Show timer bar and Show timer text turn each off, and Text position puts the time above the bar or on it. Hide totem bar hides the whole bar. The bar stays where Blizzard puts it: to move it, tick Totem Bar in Blizzard's Edit Mode settings and drag it there.
- Profiles live under `/sui` → Profiles, and switching applies live.
- `/rl` reloads the UI.

## Development

- Plain Lua and XML, with no build step. Edit, then `/reload` in game.
- There's no test runner. Changes are checked in game; BugSack is recommended for reading errors.
- Blizzard's UI source for reference: [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), on the `forever` and `live` branches.
- Agent and contributor conventions are in [`AGENTS.md`](AGENTS.md) and `.agents/`. Design specs, plans and the followups queue are in `docs/`.

## License

Not specified yet.
