# DON'T LOOK BACK — v0.23 LANGUAGE SETTINGS

## Languages

v0.23 adds two runtime language choices:

- English (`en`)
- Bahasa Indonesia (`id`)

The first launch uses the device language when it is Indonesian; other locales default to English. After the player changes language, the explicit choice is saved and wins over device locale.

## Where to change language

Open **Settings / Pengaturan** from the main menu or the in-game pause menu.

A new runtime button appears:

- `LANGUAGE: ENGLISH`
- `BAHASA: INDONESIA`

Press/click/tap the button to switch immediately. While the Settings panel is visible, keyboard `L` also toggles the language.

No restart is required.

## Persistence

Language is stored in:

`user://dont_look_back_language.cfg`

It is intentionally separate from:

- `user://dont_look_back_settings.cfg`
- `user://dont_look_back_save_v1.json`

This prevents existing Settings save code from accidentally removing the language field and keeps language preference independent from NEW GAME / Continue world progress.

## Localized v0.23 scope

The runtime language pass covers the high-frequency player-facing interface:

- main menu buttons
- Join Co-op panel
- Settings labels and FPS presets
- new-game confirmation UI
- main-menu status/help text
- pause/front-end buttons
- survival HUD stats
- inventory header and core item names
- controls hint
- interaction prompt
- death/restart text
- Journal navigation labels and current-mission text
- core Arc 1 objective text
- Maintenance / Flooded / Archive / Lockdown objective wording
- evacuation / extraction objective wording
- evacuation extraction world label

Technical co-op and map callouts such as `M-01`, `F-02`, `A-03`, `L-04`, `SYNC`, `LOCKDOWN`, `Warden`, `E`, and `USE` remain recognizable between languages so mixed-language co-op teams can use the same callouts.

Long-form Journal lore entries are not rewritten destructively. The system currently localizes Journal UI, categories, counters, mission text, and gameplay-facing notifications while preserving original narrative source text for future curated translation passes.

## Mobile / desktop

The language control is generated at runtime inside the existing Settings container.

The Settings panel minimum height is expanded to fit the extra control. The same language system is shared by desktop and mobile; no separate touch-only language menu is required.

A direct input fallback handles the runtime language button so the setting remains usable with the project's hardened main-menu input path.

## Architecture

`LanguageSystem` is created by the existing `FrontEndSystem` wrapper.

No new `project.godot` autoload entry is required.

This is deliberate because `project.godot` is kept stable to avoid another local Pull/Discard conflict.

## Test checklist

1. Launch with no language config and confirm Indonesian device locale defaults to Bahasa Indonesia; otherwise English.
2. Main Menu → Settings → toggle language.
3. Confirm menu buttons change without restarting.
4. Close Settings, reopen it, and confirm selected language remains.
5. Restart the game and confirm the explicit language choice persists.
6. Start New Game and confirm survival HUD stats translate.
7. Pick up Battery/Food/Water and confirm inventory-facing item names translate.
8. Aim at an interactable objective and confirm interaction text follows the selected language.
9. Reach Maintenance, Flooded, Archive and Lockdown and confirm core objective wording changes.
10. Reach evacuation and confirm EVACUATION / EXTRACTION objective text changes.
11. Open Journal and confirm navigation/current-mission UI changes.
12. Switch language from in-game Settings and confirm active HUD changes without a scene reload.
13. Test the same flow on mobile with touch input.
14. In co-op, confirm language selection is local per device and does not change another player's UI.

## Runtime validation status

Static code audit completed. Godot executable is not available in the assistant environment, so F5/runtime validation still needs to be performed on the development machine.
