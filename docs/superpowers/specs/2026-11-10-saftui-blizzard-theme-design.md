# SaftUI options, project 3b-2: the Blizzard theme

Date: 2026-11-10. Status: a draft for the user's review. The calls marked "My call" are mine, not the user's. The user's own decisions, from the Themes brainstorm, are quoted under Intent and are binding.

Project 3b-1, Themes (`docs/superpowers/specs/2026-11-10-saftui-themes-design.md`, shipped), made SaftUI's look a choice: Thick or Thin, editable colors, a Transparent background toggle and Opacity, a Theme and Background override on every module, and a kind of frame named in every draw call. This spec adds the theme Themes promised next: Blizzard.

## Intent

The Themes spec: "The Blizzard theme (its own spec, after this one): panels in the character frame's metal border with Blizzard's close button, Blizzard's own art on action buttons, bag slots and buffs, and the tooltip border on bars. It builds on this spec's kinds of frames."

The user, in the Themes brainstorm (2026-11-10):
- Asked whether the gold dialog frame is the border Blizzard's panels use: "For things like action buttons, bag slots, and buffs we'd use the blizzard template for those items. for actual panels we'd use the same borders are the character frame border."
- On bars, after the mockups (`.superpowers/brainstorm/58584-1794330231/content/border-styles.html`) and a throwaway in-game spike (`/suistyles`, which drew bars in the character frame's metal, Simple metal, Generic metal, the dialogs' Diamond metal, the tooltip border and the Inset art): "okay lets go with tooltip, the rest look really bad."
- "if we're using blizzard themes the panels should also use blizzard's close button styling (CharacterFrame is a good example)".
- "I think we should have all of those options default to inherit from the base theme and that dropdown becomes an override option only." Blizzard joins the same Theme choice and the same per-module overrides as Thick and Thin.

So Blizzard is a third theme. Picking it draws each kind of frame in Blizzard's own art for that kind. Nothing changes for anyone who doesn't pick it.

## Today

- **The engine** (`SaftUI-Core/theme.lua`) draws a look as a backdrop: a 1px edge and a fill (`BackdropTemplate`), plus Thick's two dark lines. Its border reaches 2px in (Thick) or 1px (Thin). `st:ThemeInset(theme, background)` gives that width, with no kind. About 13 call sites read it, and `st:CalculateSpacing` reads `frame.thick`.
- **Every drawn frame is recorded.** `st:RecolorThemed` and `st:RedrawThemed` re-apply looks, and `st:KeepOwnColors` and `OnColorsChanged('theme')` put a frame's own colors back afterwards.
- **`'blizzard'` is already reserved.** A theme name the engine doesn't know reads as Thick (`FALLBACK`), and the saved name stays.
- **Modules color borders themselves** with `SetBackdropBorderColor` on the drawn frame, about 20 calls: an item's quality, an equipped action, a debuff's type, a tooltip's unit, a totem's element, a lit loot roll, a selected bank window, a focused edit box, a picked radio button, a selected mover. They take the color off again two ways (`docs/followups.md`, "Two ways to reset a border to the theme's").
- **SaftUI's close button** (`st:CreateCloseButton`) has a look of its own, which the theme never draws. The `close` kind only reaches a Blizzard close button handed to `st:CreateHeader`.
- **The tooltip skin** keeps Blizzard's tooltip `NineSlice` at alpha 0, and draws SaftUI's backdrop through `st:SetBackdropIn`. **The buff skin** keeps Blizzard's `DebuffBorder` and `TempEnchantBorder` at alpha 0, and colors SaftUI's border from the atlas Blizzard gives the debuff.
- **The `panel` kind covers two different things.** One is windows with SaftUI's title bar (`st:CreateHeader`): the bags, the bank, `st:CreatePanel`. The other is plain backgrounds: chat, the minimap, loot feed entries, the `/sui` window, the bag slot bars.

## Blizzard's art

The sources:
- Blizzard's UI code: `Gethe/wow-ui-source`, branches `forever` and `live`.
- Atlas sizes: the clients' atlas tables (`UiTextureAtlasElement` and `UiTextureAtlasMember`, from wago.tools), for Forever build 1.60.1.70888 and retail build 12.1.5.70783.
- File IDs: `wowdev/wow-listfile`.

Sizes are UI units. Art that exists only at double resolution (a `-2x` member) counts at half its texture size.

**The names are the same on both clients.** Every atlas and file below exists on both, under the same name. Forever's client also has a Camelot version (a `-c60` member) of most of them, and draws it for the same name. Blizzard says so in `Blizzard_SharedXML/Camelot/NineSliceLayoutOverrides.lua`: "In some places the art made for Camelot doesn't match the exact size of the Mainline Standard art and needs to be offset differently."

### The character frame's metal

From `NineSliceLayouts.ButtonFrameTemplateNoPortrait` (`Blizzard_SharedXML/Mainline/NineSliceLayouts.lua`, the same on both branches).
- The CharacterFrame itself uses `PortraitFrameTemplate`, which is these pieces with a portrait socket in the top-left corner (`UI-Frame-PortraitMetal-CornerTopLeft`). Forever's CharacterFrame inherits `PortraitFrameBaseTemplate`, retail's `ButtonFrameTemplate`; both get that layout.
- Every piece is in the OVERLAY layer, with sharpening off (`disableSharpening`).
- Offsets are from the window's corners. Forever's are Blizzard's after its Camelot overrides.

| Piece | Atlas | Offset, retail | Offset, Forever | Size, retail | Size, Forever |
| ----- | ----- | -------------- | --------------- | ------------ | ------------- |
| Top left corner | `UI-Frame-Metal-CornerTopLeft` | −8, 16 | −8, 16 | 75×75 | 95×95 |
| Top right corner | `UI-Frame-Metal-CornerTopRight` | 4, 16 | 2, 16 | 75×75 | 95×95 |
| Bottom left corner | `UI-Frame-Metal-CornerBottomLeft` | −8, −3 | −8, −8 | 32×32 | 95×100 |
| Bottom right corner | `UI-Frame-Metal-CornerBottomRight` | 4, −3 | 2, −8 | 32×32 | 95×100 |
| Top edge, tiled across | `_UI-Frame-Metal-EdgeTop` | between the corners | between the corners | 32×75 | 128×95 |
| Bottom edge, tiled across | `_UI-Frame-Metal-EdgeBottom` | between the corners | between the corners | 16×32 | 128×100 |
| Left edge, tiled down | `!UI-Frame-Metal-EdgeLeft` | between the corners | between the corners | 75×16 | 95×128 |
| Right edge, tiled down | `!UI-Frame-Metal-EdgeRight` | between the corners | between the corners | 75×16 | 95×128 |

- **Files.** Retail's are `Interface/FrameGeneral/UIFrameMetal2x`, `UIFrameMetalHorizontal2x` and `UIFrameMetalVertical2x` (2406979, 2406987, 2406984). Forever's are `UIFrameMetal2xc60`, `UIFrameMetalHorizontal2xc60` and `UIFrameMetalVertical2xc60` (8069116, 8069118, 8069114).
- **The top edge is the window's title bar.** Blizzard's window background starts 21px below the window's top on retail (`ButtonFrameBaseTemplate`'s `Bg`, at 2, −21, −2, 2). On Forever the CharacterFrame's panes start 20px down (`LeftPaneHost` at y −20). On the sides and the bottom it starts 2px in.

### The tooltip border

From `NineSliceLayouts.TooltipDefaultLayout`. Blizzard's tooltips draw it (`SharedTooltip_SetBackdropStyle`, `Blizzard_SharedXML/SharedTooltipTemplates.lua`).

- **Corners** `Tooltip-NineSlice-CornerTopLeft`, `-CornerTopRight`, `-CornerBottomLeft` and `-CornerBottomRight`: 7×7.
- **Edges** `_Tooltip-NineSlice-EdgeTop` and `_Tooltip-NineSlice-EdgeBottom` (16×7, tiled across), `!Tooltip-NineSlice-EdgeLeft` and `!Tooltip-NineSlice-EdgeRight` (7×16, tiled down).
- **Sizes and files.** The sizes are the same on both clients. The files are `Interface/Tooltips/UIFrameTooltip` and `UIFrameTooltipVertical` (4185447, 4185474), and on Forever the Camelot `UIFrameTooltipc60` and `UIFrameTooltipVerticalc60` (8070606, 8070610).
- **The fill.** Blizzard fills the middle with `Tooltip-NineSlice-Center` (64×64), drawn from 4px inside the corners and tinted `TOOLTIP_DEFAULT_BACKGROUND_COLOR`. The border art is white, and `SetBorderColor` tints it (a unit's or an item's color).

### Blizzard's close button

From `UIPanelCloseButton` (`Blizzard_SharedXML/Mainline/SharedUIPanelTemplates.xml`).

- **Its four textures:** normal `RedButton-Exit`, pushed `RedButton-exit-pressed`, highlight `RedButton-Highlight` (ADD) and disabled `RedButton-Exit-Disabled`.
- **Retail:** the art is 18×19 (`Interface/buttons/redbuttons`, 5262907). The button is 24×24, at TOPRIGHT (1, 0) of its window (`UIPanelCloseButtonDefaultAnchors`).
- **Forever:** the Camelot art is 32×32 (`redbuttonsc60`, 8107307). The button is 28×28, at TOPRIGHT (0, 3) (`UIPanelCloseButtonDefaultAnchorsMixin:OnLoad`, `Blizzard_SharedXML/Camelot/SharedUIPanelTemplates.lua`).
- **The socket.** The metal's top right corner has a socket where the button sits.

### The action button

From `ActionButtonTemplate` (`Blizzard_ActionBar/Mainline/ActionButtonTemplate.xml`). The button is 45×45.

- **Ring:** `UI-HUD-ActionBar-IconFrame` (46×45), the normal texture, over the icon.
- **Behind the icon:** `UI-HUD-ActionBar-IconFrame-Background` (46×45) and `UI-HUD-ActionBar-IconFrame-Slot` (64×62, drawn 45×45).
- **Hover:** `UI-HUD-ActionBar-IconFrame-Mouseover`. **Pushed:** `UI-HUD-ActionBar-IconFrame-Down`. **Checked:** `UI-HUD-ActionBar-IconFrame-Mouseover`, additive on Forever and plain on retail (the one line the two templates differ by). **Flash:** `UI-HUD-ActionBar-IconFrame-Flash`.
- **Equipped:** `UI-HUD-ActionBar-IconFrame-Border` (46×45), which Blizzard tints.
- **Files.** All of these are in `Interface/HUD/UIActionBar` (4613342). On Forever the ring and the slot art are the Camelot `UIActionBarc60` (7948328).
- **The icon** fills the button and is rounded by `UI-HUD-ActionBar-IconFrame-Mask`.

### The item button (bag slots)

From `ItemButton` (`Blizzard_ItemButton/Shared/ItemButtonTemplate.xml`). `ContainerFrameItemButtonTemplate`, which SaftUI's bag slots are made from, inherits it. The button is 37×37.

- **Ring:** `Interface\Buttons\UI-Quickslot2` (130841), the normal texture: 64×64, centred 1px low.
- **Pushed:** `Interface\Buttons\UI-Quickslot-Depress` (130839). **Highlight:** `Interface\Buttons\ButtonHilight-Square` (130718, additive).
- **Quality:** `Interface\Common\WhiteIconFrame` (651080), the `IconBorder`, tinted by the item's quality.
- **Empty slot:** `bags-item-slot64` (32×32). Forever's bags show it in an empty slot (`ContainerFrameItemButtonMixin:GetItemButtonBackgroundTexture`, Forever's `Mainline/ContainerFrame.lua`). Retail has the atlas, but its bag buttons have no empty-slot art.

### The aura button

From `AuraButtonArtTemplate` (`Blizzard_BuffFrame/BuffFrameTemplates.xml`). The icon is 30×30.

- **A buff has no border.**
- **A debuff** has `DebuffBorder`: 40×40, centred on the icon. Its atlas is by dispel type, from `AuraUtil.SetAuraBorderAtlas`: `ui-debuff-border-magic-noicon`, `-curse-`, `-disease-`, `-poison-`, `-bleed-` and `ui-debuff-border-default-noicon`, all 40×40.
- **A temporary enchant** has `TempEnchantBorder`, `Interface\Buttons\UI-TempEnchant-Border` (130870): 32×32.

### Colors

From the clients' `GlobalColor` tables. They're the same on both.
- `TOOLTIP_DEFAULT_BACKGROUND_COLOR`: 0.09, 0.09, 0.19.
- `PANEL_BACKGROUND_COLOR`: 0.12, 0.12, 0.13 at 0.8, the fill of Blizzard's flat windows (`FlatPanelBackgroundTemplate`).

## Goals

### Blizzard is a theme like Thick and Thin

- **Global Settings → Theme offers Thick, Thin and Blizzard.**
- **Every module's Theme override offers Blizzard:** Use SaftUI's theme, Thick, Thin, Blizzard, None. Background stays Use SaftUI's theme, Solid or Transparent.
- **Blizzard keeps its own colors,** as Thick and Thin do. Switching to Thick and back brings them back.
- **A switch to or from Blizzard is live,** like a switch between Thick and Thin. It waits for the end of combat, and needs no reload.

### Each kind under Blizzard

The Themes spec's kinds, plus one: **`window`, a window with SaftUI's title bar** (`st:CreateHeader`): the bags, the bank, `st:CreatePanel` and skinned Blizzard panels. `panel` keeps every other background. Under Thick and Thin a window draws exactly as a panel. My call. The metal has the title bar built in (above), which only fits a frame that has one, and only the call site knows whether it does. A test of whether the frame has a header would depend on which ran first, the draw or `st:CreateHeader`.

- **window: the character frame's metal.** The user: "for actual panels we'd use the same borders are the character frame border."
  - These are the eight pieces above, without the portrait socket: SaftUI's windows have no portrait. My call.
  - The fill is the theme's Background.
  - The metal's title bar sits on top of the window, above SaftUI's header, so the art reaches up from the window and nothing inside it moves. The close button sits in its socket on the title bar. The title and the header's buttons stay in the header row, which keeps its height (General → Header height).
  - My call, and question 1 below. SaftUI's headers are 31px by default and the bag windows' view buttons are sized from them. The title bar is about 20px. Shrinking the header into it would shrink those buttons to about 10px, and the title bar can't stretch.
- **panel: the tooltip border.** The tooltip border, with the theme's Background as the fill.
  - My call. Chat, the minimap, loot feed entries, the `/sui` window and the bag slot bars are backgrounds, not windows with SaftUI's title bar. The metal would put an empty title bar on each, and around a feed entry it would be bigger than the entry.
  - The user liked the tooltip border on bars, and rejected the other metals: "the rest look really bad".
  - The `/sui` window's own layout stays as it is.
- **bar: the tooltip border.** The user's decision. The fill is the theme's Background.
- **tooltip: the tooltip border.** The fill is the theme's Background. My call: it is Blizzard's own tooltip border.
- **action: the action button's art.** The user: "the blizzard template".
  - The ring sits over the icon's edge, and the slot art (`-Background` and `-Slot`) behind the icon.
  - Hover, pushed, checked and flash are Blizzard's atlases, where SaftUI makes those textures: the action bars, the pet and stance bars, the totem bar.
- **slot: the item button's art.** Each kind takes the template of what it is, as the user asked for "action buttons, bag slots, and buffs". My call: a bag slot takes the item button's art, not the action button's.
  - The `UI-Quickslot2` ring sits over the icon's edge, and `bags-item-slot64` behind the icon.
  - Pushed and highlight are Blizzard's (`UI-Quickslot-Depress`, `ButtonHilight-Square`).
- **aura: the bare icon,** as Blizzard draws a buff: no ring and no fill.
  - On Blizzard's own buff buttons (the buff skin), Blizzard's own `DebuffBorder` and `TempEnchantBorder` show, sized to SaftUI's icon (40 to 30, 32 to 30). SaftUI draws none of its own there. My call: that is Blizzard's art for each dispel type.
  - SaftUI's own aura buttons (the unit frames, WeakAuras) take a colored border as below.
- **header: nothing.** Header and footer strips draw no fill and no lines, so they're rows on the window's Background. My call: Blizzard's windows have no strips, and the metal's title bar already marks the top.
  - Strips still follow SaftUI's theme, not their window's override, as the Themes spec decided. So a window overridden to Blizzard while SaftUI's theme is Thick keeps Thick's strips inside its metal. My call: that keeps one rule for strips, for a rare case.
- **close: Blizzard's red close button.** The user: "the panels should also use blizzard's close button styling (CharacterFrame is a good example)".
  - SaftUI's close buttons (`st:CreateCloseButton`) take Blizzard's four textures, at Blizzard's size for the client: 24×24 on retail, 28×28 on Forever.
  - On a window it sits where Blizzard puts it on its own windows, in the metal's socket. Elsewhere (the `/sui` window and its dialog, item tooltips) it stays where SaftUI puts it today.
  - While a bag window's close button is in the socket, the header's buttons, which line up from the close button today, line up from the header's right edge.
  - Close buttons follow SaftUI's theme, as the `close` kind always has. Under Thick and Thin they keep today's look. My call.
- **small: one 1px line,** in the Blizzard theme's Border, around its Background. That is Thin's drawing in Blizzard's colors. My call.
  - The smallest of Blizzard's art, the tooltip's corners, is 7px. Class power points, indicators, check boxes, edit mode's outlines and scroll bar thumbs are about that size or smaller.
  - Blizzard has a different art for each kind of widget, which the kinds don't tell apart.

### How the Blizzard look fits the engine

**Art, not a backdrop.**
- Blizzard's borders are pieces: textures on frames of SaftUI's, in Blizzard's layers.
- The fill stays the drawn frame's own backdrop fill. That way a module's own fill colors keep working (a loot feed entry's quality fill), and Transparent background and Opacity apply as today.
- Under Blizzard the backdrop draws no edge line, and Thick's dark lines are hidden.

**SaftUI places the pieces itself,** from tables of its own in Core's theme engine. It doesn't call `NineSliceUtil`. My call:
- Blizzard's layouts place art around Blizzard's windows, and SaftUI's frames are shaped differently.
- `NineSliceUtil` writes fields onto its container and reads Blizzard's layout tables.
- The tests can't load it.

The tables hold:
- each piece's atlas or file;
- its anchors and offsets, for each client where they differ (the metal);
- its layer and tiling;
- each kind's inset for each client.

**Where the art sits.**
- **The drawn frame** holds it for window, panel, bar, tooltip and small. That is the backdrop behind the owner (`st:SetBackdrop`, `st:SetBackdropIn`), or the frame itself (`st:SetTemplate`).
- **Over the icon's edge** for action, slot and aura: the ring, and a colored border. They sit under the button's texts, cooldown and glows, as Blizzard's ring does.
- **Behind the icon** for action and slot: the slot art, on the drawn frame.

**What `st:ThemeInset` gives.**
- It names the kind: `st:ThemeInset(theme, background, kind)`. Under Thick and Thin the kind changes nothing (2 or 1). Under Blizzard it's how far the kind's art reaches in from the drawn frame's edge on its sides, for the client: where content starts to stay uncovered.
- My call: a kind that's missing is an error, as it is for draw calls, and the kinds scan checks every call.
- Starting values, which the builder measures in game on both clients:

| Kind | Inset | Where the value comes from |
| ---- | ----- | -------------------------- |
| tooltip, bar, panel | 3 | 7px corners, with Blizzard's center starting 4px inside them |
| window | 2 | Blizzard's window background starts 2px in |
| action, slot | 3 | measured; no layout in Blizzard's source gives the rings' width |
| aura | 0 | Blizzard's buffs have no border |
| small | 1 | one line |
| header, close | 0 | |

- **The window's title bar** is 21px on retail and 20px on Forever, from the metal's frame. A window's backdrop reaches that far above the window (and its inset on the other sides), so the title bar covers nothing of the window.

**How layouts cope.**
- **Unchanged:** a backdrop still sits its inset outside its owner, and a frame drawn on itself keeps its content inside the inset. Layouts that read `st:ThemeInset` follow it. Frames keep their sizes and their spacing settings.
- **Where the art goes:** a backdrop's art reaches outward, and the content of a frame drawn on itself moves inward. On a 45px action button inside a 3px ring, the icon is 39px.
- **Spacing:** where a module's spacing lets two frames' art touch, the user widens the spacing. Nothing re-spaces itself. My call: spacing is the user's setting.
- **`st:CalculateSpacing`** reads the inset each frame was last drawn at, in place of `frame.thick`.
- **A window keeps its header and its size.** The metal reaches above it by the title bar's height. The screen edge margin holds the window, not the art above it.

**What the Theme tab's settings mean under Blizzard.**
- **Background** is the fill of every Blizzard look that has one: window, panel, bar, tooltip and small. Its default is Blizzard's tooltip fill, 0.09, 0.09, 0.19.
  - My call: one Background covers the theme, as with Thick and Thin.
  - The tooltip border is on tooltips, bars and every panel, and Blizzard fills it with that color.
  - Question 2 below.
- **Border** is the small frames' line, default 0.5, 0.5, 0.5. Blizzard's art keeps its own colors: no setting tints it. My call.
- **Outer border** is hidden, as it is under Thin.
- **Transparent background and Opacity** work as today, on fills. The action and slot art behind the icon takes the same alpha. Borders stay opaque.
- **Reset** puts Blizzard's defaults back.

**A frame's own border color.**
- **The new call.** Modules stop calling `SetBackdropBorderColor` on drawn frames. They call `st:SetBorderColor(frame, r, g, b, a)`, and `st:SetBorderColor(frame)` with no color for the theme's own border. Under Thick, Thin and small it is the backdrop's border color, exactly as today.
- **Under Blizzard art:**
  - the tooltip border and the metal tint their pieces, as Blizzard's `NineSlice:SetBorderColor` does (a unit tooltip's class color);
  - an action button shows Blizzard's equipped border (`UI-HUD-ActionBar-IconFrame-Border`) in the color;
  - a slot or an aura shows Blizzard's `WhiteIconFrame` in the color, as Blizzard shows an item's quality.

  No color takes it off.
- My call: one call takes a module's color on and off in every theme. A plain border color can't reach art, and this also ends the followup's "two ways to reset a border". A source scan keeps modules off `SetBackdropBorderColor` on a drawn backdrop.
- A recolor or redraw takes own colors off. Modules put them back as today (`OnColorsChanged('theme')`, `st:KeepOwnColors`).

**Recolor and redraw.** These work for Blizzard as for the others.
- A recolor puts the Background, the alpha and the small lines back, and moves nothing.
- A redraw draws each recorded frame's look again: it shows or hides the art, and moves each backdrop to its kind's inset.
- A frame that resolves to None is cleared, art included.

**Close buttons follow the theme.** `st:CreateCloseButton` switches its button between today's look and Blizzard's on every recolor and redraw (`st:KeepOwnColors`, which already runs after both). On a window it also moves into the socket, or back. My call: the button has no module to hang `OnColorsChanged` on.

### What the user sees

- **On Global Settings → Theme:** a third choice, Blizzard. Picking it redraws SaftUI at once (out of combat):
  - the bags and bank in the character frame's metal, with the red close button in its socket;
  - tooltips, unit frames and every bar in Blizzard's tooltip border;
  - action buttons in Blizzard's ring;
  - bag slots in the item button's frame;
  - buffs bare, with Blizzard's debuff borders;
  - chat, the minimap and the `/sui` window in the tooltip border;
  - small things in a thin grey line.
- **On every module page:** the Theme override has Blizzard, so one module can use Blizzard while the rest stay Thick, or the reverse.
- **On the Theme tab, under Blizzard:** Border and Background, which say what they color, then Transparent background, Opacity and Reset. Outer border is hidden.
- **No reload,** and nothing left in the old look.

### SaftUI looks exactly as today until the user picks Blizzard

- **Defaults:** SaftUI's theme stays Thick, and every module's override stays Use SaftUI's theme. No default names Blizzard.
- **Unchanged by this project:**
  - Thick and Thin draw as before;
  - every theme test keeps its assertions, apart from the API changes (`st:ThemeInset`'s kind, `st:SetBorderColor`);
  - SaftUI's close buttons look as before.
- **Saved profiles need nothing.** `templates.blizzard` is new, and AceDB fills it in from the defaults. A profile saved with Blizzard and opened by an older build reads as Thick there (already true).

## Combat and taint

- **Nothing is drawn on Blizzard's frames.**
  - Every piece of art is a texture on a frame of SaftUI's (a backdrop, or the frame that holds a ring), kept in SaftUI's tables.
  - A frame that isn't SaftUI's gets nothing written onto it, as `st:SetBackdropIn` promises (`.agents/taint.md` rule 1).
  - The tooltip skin keeps Blizzard's `NineSlice` hidden, and SaftUI's backdrop draws the tooltip border.
  - No Blizzard code runs for the theme: no `NineSliceUtil`, and no Blizzard setter (rule 3).
- **Blizzard's own regions** are touched only where a skin already touches them:
  - the buff skin shows `DebuffBorder` and `TempEnchantBorder` under Blizzard, with `SetAlpha` and points. It sets them today, and Blizzard never sets their alpha;
  - the totem bar's state textures stay out of combat, as today (rule 1).
- **A redraw never runs in combat.** A theme switch, and a profile switch, copy or reset, wait for the end of combat (`st:ThemeChanged`, `Config:UpdateConfig`).
- **Drawing in combat is safe.** Frames drawn for the first time in combat keep working under Blizzard, as today: a bag opened mid-fight, a tooltip, an aura. Art is textures (`SetAtlas`, `SetTexture`, points, vertex color, show and hide) on frames of SaftUI's. A frame of SaftUI's that's a child of a secure button, or anchored to one, isn't protected (rule 6). None of it is a protected call.
- **No art is sized from a frame's size read back from the game.** Aura buttons' sizes can be secret (rule 11). Pieces are placed by anchors and offsets, or by sizes from SaftUI's config.

## Both clients

- **Every name SaftUI uses exists on both clients**, so there's no feature check. Forever draws its Camelot art for the same names.
- **Per client, in the theme's tables:**
  - the metal's offsets and sizes;
  - the window's title bar (21 retail, 20 Forever);
  - the close button's size and spot;
  - the checked texture's blend;
  - each kind's measured inset.
- **Picking the client:** the tables are read through `st.forever` at draw time. Tests switch with `stub.interface`.
- **Names that exist on one client only aren't used,** such as retail's `tooltip-nineslice-bottomarrow` and Forever's `common-framedivider` or `bags-item-slot-blank`.

## Constraints

- **`.agents/taint.md`**, above.
- **Saved profiles keep working,** with no step the user has to take.
- **The finished-page rules:** every option has a desc and SaftUI's `size`, and no Ace `width`.
- **Words the user sees:** Blizzard, joining the Themes spec's words. No atlas or file name, and no "Template", "Highlight" or "Close Button", is ever shown.

## Non-goals

- **Blizzard's art for each kind of widget** (buttons, check boxes, sliders, dropdowns, scroll bars, edit boxes). Small frames take a line.
- **Pieces of Blizzard's windows SaftUI's don't have:** the portrait socket, the minimize button, the rock background, the title streaks.
- **Per-dispel-type debuff art on SaftUI's own aura buttons** (unit frames, WeakAuras). They take the white icon border in SaftUI's colors.
- **Re-tagging icons drawn as small as slots,** such as the castbar icon, loot icons and feed icons.
- **Round icon masks.**
- **Showing Blizzard's own tooltip `NineSlice`** in place of SaftUI's copy.
- **Unifying `st:KeepOwnColors` and `OnColorsChanged('theme')`** (`docs/followups.md`).
- **Themes beyond these three.**

## Anti-goals

- SaftUI looking any different under Thick or Thin, or for a profile that never picks Blizzard.
- Art drawn on Blizzard's frames, or Blizzard's `NineSlice` code run by SaftUI.
- A frame left in another theme's look after a switch, until a reload.
- Art over content (text, icons, bar fills) past its inset.
- A protected call made to draw art, or a theme switch in combat.

## Tests

- **Resolution:**
  - Blizzard resolves its name, colors and alpha by the same rules as Thick and Thin.
  - Each kind's inset is right on each client.
  - Thick's and Thin's insets ignore the kind.
  - A window draws as a panel under Thick and Thin.
- **Each kind under Blizzard, on each client:**
  - the right atlases and files, anchors and offsets, layers and tiling;
  - no SaftUI edge line and no Thick lines;
  - the fill in the Background at the right alpha;
  - small is one line in Border;
  - header is clear;
  - aura has no art.
- **Switches.** A frame of every kind goes Thick → Blizzard → Thin → Blizzard:
  - art only under Blizzard, and Thick's lines only under Thick;
  - each backdrop at its kind's inset;
  - None stays bare;
  - `st:CalculateSpacing` follows.
- **Recolor under Blizzard:** the fill and the small lines follow, the art stays untinted, and nothing moves.
- **Own colors:**
  - `st:SetBorderColor` by kind and theme;
  - under Blizzard, after a recolor and a redraw, the modules' own colors come back: a slot's quality, an equipped action, a unit tooltip's class color.
- **Close buttons:** Blizzard's four atlases and the client's size under Blizzard, today's look under Thick, and a window's button in the socket.
- **Windows:** under Blizzard the metal reaches the title bar's height above the window, the header keeps its height with no strip, and the bag header's buttons line up from its right edge. Under Thick everything is as before.
- **Buttons:** Blizzard's hover, pushed and checked art on action buttons and slots, and the buff skin showing Blizzard's debuff and enchant borders.
- **Options:**
  - the Theme tab offers Blizzard, hides Outer border under it, and resets it to Blizzard's defaults;
  - every Theme override offers Blizzard, in order, with descs.
- **Defaults:** no default names Blizzard, and every existing theme test passes.
- **Taint:**
  - drawing under Blizzard writes nothing onto a frame that isn't SaftUI's (the locked frame fixture);
  - `theme.lua` never names `NineSliceUtil`.
- **Scans:** every `st:ThemeInset` call names a kind, and no module sets a drawn backdrop's border color itself.
- **Atlases:** every atlas the theme names exists on both clients. The test stub's atlas list is taken from the clients' atlas tables (above).

## Left to the builder

- **Exact offsets, insets and the title bar's height on each client,** measured in game from the starting values above.
- **How pieces are made and kept:** SaftUI's tables, keyed by the drawn frame.
- **How the ring gets over the icon:** a texture of the button's own in its ARTWORK layer, or a frame of SaftUI's just above it. The button's texts, cooldown and glows stay above it either way.
- **How the item ring fits a slot of any size:** cropped to the 37-in-64 Blizzard draws, or sized from the config.
- **Texel snapping** on the metal (Blizzard's `disableSharpening`).
- **Whether the title bar above a window needs keeping on screen,** given that the screen edge margin holds only the window.
- **Where the tables live and their shapes, and the descs.**

## Questions for the user

1. **Window title bars.** Blizzard's metal has a title bar about 20px tall, and SaftUI's window headers are 31px (General → Header height). My call: the title bar sits on top of each window, above its header, holding only the close button in its socket. The title and the bag windows' view buttons stay in the header, so nothing inside a window moves. Or should the title move up onto the title bar? Or should the header shrink into the title bar, which would make the view buttons about 10px?
2. **One background color.** My call: one Background for the whole theme, by default Blizzard's tooltip navy (0.09, 0.09, 0.19), windows included. Or should windows take Blizzard's dark grey panel color (0.12, 0.12, 0.13), with tooltips and bars staying navy?
3. **Backgrounds that aren't windows** have no title bar for the metal: chat, the minimap, loot feed entries, the `/sui` window and the bag slot bars. My call: the tooltip border, like bars. Or the metal anyway, or something else?
4. **The tooltip border's size on bars.** Your `/suistyles` spike showed it at Blizzard's size and at half size. My call: Blizzard's size (7px corners), the size of its tooltips. Or half?
5. **Small frames** are too small for Blizzard's art: buttons and check boxes in `/sui`, indicators, class power points, micro menu buttons, edit mode's outlines. My call: a 1px line in the Blizzard theme's colors, like Thin. Or something else?
