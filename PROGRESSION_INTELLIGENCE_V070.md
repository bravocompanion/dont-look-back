# v0.70 — Progression Intelligence Pass

v0.70 converts the remaining information-oriented survivor talents into concrete, read-only gameplay intelligence while preserving v0.68/v0.69 progression balance, multiplayer authority, horror rules, save compatibility, and the v0.67 weight inventory.

## Active talent intelligence

### Scout
- **Escape Instinct**: when The Tenant or Darkness is nearby, contextual intel shows the authored escape/light rule.
- **Ghost Trail**: extends escape intel with the survivor's exact player-noise multiplier and current carry warning. It never grants invisibility.

### Technician
- **Salvager**: shows carried technical salvage. Rank 2 adds Copper Wire and Lead Plate detail. This is inventory planning, not free material generation.
- **Circuit Memory**: shows the current Mine UPPER/DEEP support-light circuit, stabilized-junction status, and warns that switching circuits emits AI noise.
- **Emergency Power**: exposes generator condition/fuel telemetry and creates contextual low-reserve warnings. It never creates free fuel or permanent power.

### Investigator
- **Cold Reader**: reveals advanced analysis for anomaly knowledge already discovered. It cannot reveal undiscovered evidence-gated entries.
- **Threat Familiarity** continues to expose advanced learned threat analysis without damage resistance.

## UI

The existing progression menu gains:
- **ACTIVE SPECIALIZATION INTEL** cards in Overview.
- **TALENT ANALYSIS** cards in Knowledge.

A new contextual `ProgressionIntelHUD` appears only when a currently relevant high-tier talent has actionable information:
- nearby threat + Escape Instinct;
- low/broken generator + Emergency Power;
- Mine scene + Circuit Memory.

The HUD is responsive on desktop and mobile and hides while gameplay UI is locked.

## Compatibility

Unchanged:
- Level 1–30 curve and point economy.
- v0.69 survival milestones and anti-grind claims.
- `user://dont_look_back_progression_v68.json` profile path and profile version.
- progression save-state version 68.
- personal survivor progression in multiplayer.
- checkpoint progression behavior.
- Tenant/Darkness authority and damage.
- LightRegistry protection rules.
- generator fuel/resource transactions.
- Mine circuit authority and switching noise.
- 32 kg base weight system plus progression carry bonuses.

## Explicit safety/balance contracts

v0.70 grants **none** of the following:
- threat immunity;
- threat damage resistance;
- invisibility;
- free generator fuel;
- permanent emergency power;
- evidence-gate bypass;
- world-authority changes.
