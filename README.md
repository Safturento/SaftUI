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
- `/sui` → Action Bars sets each bar's buttons, size, spacing, text and visibility (always, in combat only, or faded until moused over). Every bar is an edit mode frame.
- `/sui kb` (or "Keybind mode" in `/sui`) binds keys to SaftUI's action bars by hovering. Hover a button and press a key or mouse button, with any modifiers; right-click a button to clear its keys; Escape leaves. Bars set to show only in combat or faded show while it's on. SaftUI's bars use Blizzard's own action bar bindings, so binds show in Blizzard's Key Bindings menu, and the binds you already have keep working.
- Profiles live under `/sui` → Profiles, and switching applies live.
- `/rl` reloads the UI.

## Development

- Plain Lua and XML, with no build step. Edit, then `/reload` in game.
- There's no test runner. Changes are checked in game; BugSack is recommended for reading errors.
- Blizzard's UI source for reference: [Gethe/wow-ui-source](https://github.com/Gethe/wow-ui-source), on the `forever` and `live` branches.
- Agent and contributor conventions are in [`AGENTS.md`](AGENTS.md) and `.agents/`. Design specs, plans and the followups queue are in `docs/`.

## License

Not specified yet.
