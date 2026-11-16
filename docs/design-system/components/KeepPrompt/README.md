# KeepPrompt

"Keep this UI size?": the question SaftUI asks after it tries a new UI size, with a countdown, Keep and Go back. It is the way back from any size, so it never depends on the size it is asking about.

## When to use

Only for a change of the UI size (`st.UIScalePrompt:Ask(choice)`, `uiscaleprompt.lua`): the Scale and UI size rows in Global settings > General and `/sui scale`. Not for any other setting (those have a reset icon on the setting) and not for a question about something that can't be undone (that is the confirm in Dialog).

## What the consumer provides

A choice, `{ mode, size }`. The prompt tries it at once (`UIScale:Preview`), counts 15 seconds, and keeps it (Keep: saved) or goes back to the choice saved before the first one tried (Go back, Esc, the end of the time).

## Sizes and tokens

| Part | Value | Tokens |
| --- | --- | --- |
| Frame | 320 wide, drawn as a `panel` in the theme on the options Background, centred on the screen; its size and corner whole pixels of its own scale | `confirm-width` |
| Scale | its own: the automatic size of this screen at 100%, whatever is tried (it ignores its parent's scale) | |
| Text | the question, then the line under it in `text-muted`: "Going back in 15 s." counting down, or "Goes back when combat ends." | `field` |
| Buttons | Keep and Go back, the kit's Button, 12 apart, 14 from the bottom | `button-gap` |
| Padding | 16 above the question, 6 between it and the line, and 16 between the line and the buttons | `confirm-top` |
| Layer | `FULLSCREEN_DIALOG`, level 9900: over the window, edit mode and its History list | `level-keep-prompt` |

## States

- Keep looks disabled and takes no click for the first half second after the prompt shows, so the second click of a double-click on what asked cannot keep. Go back and Esc work at once.
- Not modal: no catcher. A click beside it reaches what is under it, and it stays when `/sui` closes.
- Out of combat it takes Esc (go back) and lets every other key on to the game. Enter does nothing: only Keep keeps.
- In combat it takes no key. If combat starts while it shows, it stays and its buttons work. If the time ends in combat, the line reads "Goes back when combat ends.", the buttons hide, and it hides once the size has gone back.
- A second change while it shows starts the 15 seconds again for the new choice.
- Under the mouse and pressed: as the kit's Button.

## Known gaps

- Its frame and its border are whole pixels at any screen; the kit's buttons and texts are not (their sizes are in units), so away from 1440p they sit a fraction of a pixel off. The prompt is drawn at the automatic size of every screen but 1440p, not only while previewing: on 1080p its buttons are 19.5 pixels tall. Phase 2 of the scaling work (the options kit) fixes it.
- A line is `line-width` pixels of UIParent's scale: a 150% preview on a 1440p screen makes the prompt's lines 2 pixels (Thick 6), whole but heavier. The owner's call keeps one-pixel lines on frames the game scales, so the prompt follows.
- The kit's confirm dialog and an open select list are in `TOOLTIP` strata with a click catcher, so one open at the time covers the prompt. Its time still runs out.
- The countdown keeps running through a loading screen; the first tick after it can go back, the safe direction.

## Blizzard theme

Drawn as the theme's `panel` art with Blizzard's panel buttons, as the confirm is.

## Do and don't

- Do keep the question and both buttons readable at every size: the prompt takes none of the tried size.
- Don't add a key that keeps, or a click catcher: the prompt must not be answered by accident, and must not block the game.
- Don't draw the buttons' states here: the kit's Button owns them.
