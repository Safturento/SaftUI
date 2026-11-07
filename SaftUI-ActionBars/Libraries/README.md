# Bundled libraries

Copied unchanged from upstream. Only the `.lua` files are kept, and `SaftUI-ActionBars.toc` loads them, LibButtonGlow first. LibStub and CallbackHandler-1.0 come from `SaftUI-Core/Libraries`, which loads first. Both libraries are BSD-licensed; the licence is at the top of each file.

| Library | Version | Source |
| ------- | ------- | ------ |
| LibActionButton-1.0 | minor 168, `master` at `bc1da7a581d21dad5d7da114263c6a513f448f32` (2026-10-02, "Fix range indicator updating") | <https://github.com/Nevcairiel/LibActionButton-1.0> |
| LibButtonGlow-1.0 | minor 10, tag `1.3.6` (`302ff4812d95c27a491283376fc8fa0f90f12fe7`, 2026-06-26) | <https://repos.wowace.com/wow/libbuttonglow-1-0> |

## Notes for updating

- LibActionButton detects WoW Forever itself (`buildInfo >= 16001 and < 20000`) and treats it as a mainline client, as it does Midnight. Check that this still holds after an update.
- LibActionButton's action buttons call Blizzard's global action APIs (`HasAction`, `GetActionTexture`, `IsUsableAction` and others). In 12.0 those moved to `Blizzard_DeprecatedActionBar`, which only defines them while the `loadDeprecationFallbacks` CVar is on. An update that moves LibActionButton to `C_ActionBar` removes that dependency.
- LibButtonGlow is optional to LibActionButton (`LibStub("LibButtonGlow-1.0", true)`). Without it, procs don't glow.
