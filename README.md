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

- `/sui` (or `/saftui`) opens the options window. The sidebar on the left has Edit mode and Keybind mode buttons at the top, then Global Settings, Profiles and every module's page, grouped under Frames, Combat and Info. A page's settings sit in titled sections, two columns of a label and its control, with small ones (checkboxes, colours) two to a column and thin lines between the columns. A position is one block: click a dot on each square for which point of the frame goes to which point of what it's attached to, then type X and Y or nudge them with the arrows (Shift for 10). Tabs along the top switch between a page's parts, and on pages with many of one thing (unit frames, action bars) a dropdown picks which one. Hover a setting's name for what it does. The search box at the top right finds settings by name across every page; click a result to go to it. Drag the window by its title to move it (it remembers where), and close it with the X at the top right, Close at the bottom, or Escape. Reload UI is at the bottom left. On a unit frame's page, Copy from opens a small window that copies the settings you tick from another unit.
- `/sui` → Global Settings → Colors edits SaftUI's colors, in sections Text, Buttons, Class, Reputation, Power, Item quality and Status. Hover a color for where SaftUI shows it, and Reset puts a section back to its defaults. Unit frames, bags and the experience bar's reputation bar show a change at once; text and button colors show after a reload (Reload UI, bottom left).
- `/sui edit` toggles SaftUI's edit mode. Drag frames, nudge them with the arrow keys (Shift for 10px), and click a frame to open its settings. Where frames overlap, a list by the cursor shows which one you'd grab, and Alt switches to the next. It also turns on when Blizzard's Edit Mode opens. The footer of the options window turns on an alignment grid, drawn out from the screen's center lines, with its Grid size (− and + on the footer), and Snap to grid and Snap to frames, which pull a dragged frame onto grid lines or other frames' edges. The same settings are under `/sui` → Global Settings → Edit mode. Hold Ctrl while dragging to move freely. Edit mode and the options window close when combat starts.
- `/sui` → Unitframes → Party, Raid 10, Raid 40 or Boss → General → Test mode fills that spot with made-up group members, or for Boss made-up bosses, styled and laid out like the real frames, so the Layout settings can be checked without a group or out of an encounter. The made-up frames make way while real ones show, and Test mode is off after a reload.
- `/sui` → Action Bars sets each bar's buttons, size, spacing, text and visibility (always, in combat only, or faded until moused over), for bars 1–8, the pet bar and the stance bar. Every bar is an edit mode frame. The pet bar shows while you have a pet out (right-click a pet ability to toggle its autocast), and the stance bar shows one button per stance or form your class has. The extra action button, the zone ability and a leave vehicle button are edit mode frames too, with their own size. The leave vehicle button shows in a vehicle you can leave; on a flight path, where it asks for an early landing; and while you control a creature (mind control or a quest), where it ends the possess.
- `/sui kb` (or "Keybind mode" in `/sui`) binds keys to SaftUI's action bars by hovering. Hover a button and press a key or mouse button, with any modifiers; right-click a button to clear its keys; Escape leaves. Bars set to show only in combat or faded show while it's on; to bind pet bar keys this way, have a pet out. SaftUI's bars use Blizzard's own action bar bindings, so binds show in Blizzard's Key Bindings menu, and the binds you already have keep working.
- `/sui` → Bags → Bag → General → Empty slots (Off, Grouped, Every slot) shows free bag slots as an Empty Slots category. Grouped is one slot for the bags and one for the reagent bag, each with its free count; drop an item on it to put the item in the first free slot. Items in the reagent bag carry a green wedge in the top right of the icon. `/sui` → Bags → General → Merge stacks shows stacks of one item as a single slot, kept apart for the reagent bag and your other bags.
- While a bag or bank window is open, its categories stay in their columns and the window doesn't shrink, so selling or moving items doesn't shuffle them. Items inside a category still close up. Each time you open it, the window is arranged afresh, as short as its columns allow.
- `/sui` → Totem Bar is for Blizzard's shaman totem bar on WoW Forever, which SaftUI skins to match its action bars, each element's button bordered in that element's colour. Button size and Spacing set the size of its buttons and the gap between them, and the totem choices that open above a button follow. Above each element button, while that element has a totem down, a bar drains and a countdown shows how long the totem has left; both turn red in the last 10 seconds. Show timer bar and Show timer text turn each off, Text position puts the time above the bar or on it, Text X and Y offset nudge it from there, and Timer bar height sets how tall the bar is. Hide totem bar hides the whole bar. On a shaman the bar is an edit mode frame: drag it in `/sui edit`, or set its Position at the end of the section. It starts where Blizzard had it.
- While a roll is open, each button on SaftUI's roll bars shows how many players have picked that choice so far (main and off spec needs both count as Need). A bar has Greed or Transmog, never both, so the one it has also shows the other choice's count at its top right, in that choice's colour. Hover the bar's icon or body for the item tooltip with everyone's choice, their roll once the game has it, who hasn't chosen yet, and who leads. It updates as people choose. The sample roll bars (`/sui` → Loot → Rolls → General → Test mode) show sample counts and choices.
- `/sui` → Experience → General sets the experience bar's size and colours: Experience color for the bar, and Rested color for the bar while you have rested experience. The rested part past the bar shows in that colour at Rested bar alpha.
- The loot feed is kept per character across reloads and logouts: scroll the feed back to see earlier entries, hover one to see how long ago it happened. `/sui` → Loot → Feed → General → Clear history empties it.
- Every item your group rolls on gets one loot feed entry when its roll ends, naming the winner (or "All passed"); hover it to see everyone's choice and roll. When the winner loots the item, that goes into the same entry rather than a second one. Roll results show even with Self Only on. Untick Rolls in the feed's F menu to hide them; items you looted still show while Loot is ticked.
- If you use RestedXP Guides, SaftUI restyles its guide window in SaftUI's chat look: the chat panel and font, with fine divider lines. Its flight timer becomes a flat bar like SaftUI's cast bar. It follows SaftUI-Chat's panel and font and RestedXP's "Guide font size", and leaves RestedXP's newer (beta) guide window alone.
- Profiles live under `/sui` → Profiles, and switching applies live.
- `/rl` reloads the UI.

## Development

- Plain Lua and XML, with no build step. Edit, then `/reload` in game.
- `tests/run` runs the Lua tests in `tests/`. They check SaftUI's logic on Lua 5.1 against stubbed WoW API, and the first run sets up `tests/.venv` with Python's lupa. They're for agents and development: changes are still checked in game, where BugSack is recommended for reading errors.
- Blizzard's UI source for reference: [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), on the `forever` and `live` branches.
- Agent and contributor conventions are in [`AGENTS.md`](AGENTS.md) and `.agents/`. Design specs, plans and the followups queue are in `docs/`.

## License

Not specified yet.
