# DON'T LOOK BACK — Asset Delta v0.23

Updated for **v0.23 — INDONESIAN / ENGLISH LANGUAGE SETTINGS**.

## New production assets required

No new 3D model, texture, animation, VFX, or audio asset is required for the language-setting implementation itself.

## UI / localization production requirements

The existing UI font must remain readable for both English and Bahasa Indonesia on desktop and mobile. Current Indonesian strings use the same Latin-character coverage as the existing interface, so no additional font file is required by v0.23.

Future production/localization work should include:

- final localization QA screenshots at 16:9 desktop, small mobile landscape, and narrow mobile layouts
- button-width review for longer Indonesian labels such as `SENSITIVITAS PANDANGAN`
- subtitle/localized VO text conventions if voiced dialogue is added later
- curated Bahasa Indonesia translations for long-form Journal lore entries
- terminology sheet for shared co-op callouts (`M-01`, `F-02`, `A-03`, `L-04`, `SYNC`, `LOCKDOWN`, `Warden`, `Tenant`)

## Asset rule

Do not create separate English/Indonesian texture variants for ordinary UI text when the same text can be rendered dynamically. Keep signage that is a gameplay callout language-neutral where possible, using sector codes, arrows, icons, and numbers.

If future environment signage requires baked text, prioritize either:

- language-neutral industrial symbols, or
- separate localized texture/material variants loaded according to `LanguageSystem`.

No existing v0.22 flashlight/lighting asset requirement is removed by this update.
