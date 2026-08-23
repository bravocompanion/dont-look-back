# v0.69 — Progression Gameplay Pass

## Purpose

v0.68 established Level / Stats / Talents / Knowledge. v0.69 makes that progression easier to read and ties more of it to successful survival play without changing the saved level curve.

## Compatibility

- Level cap remains **30**.
- XP curve remains `120 + (level - 1) * 55 + (level - 1)^2 * 4`.
- Existing `user://dont_look_back_progression_v68.json` profile remains valid and unchanged.
- Existing v0.68 Talent Point / Stat Point economy is unchanged.
- Existing weight, multiplayer authority, checkpoint, threat and protection contracts remain unchanged.

## New first-time survival milestones

These milestones are personal and use the existing persistent anti-grind claim dictionary.

| Milestone | XP | Knowledge | Repeat XP |
| --- | ---: | --- | ---: |
| First successful safe-water boil | 30 | Water Safety | 0 |
| First successful wildlife carcass harvest | 40 | Wildlife Anatomy | 0 |
| First successful fishing catch | 30 | Wildlife Anatomy | 0 |
| First completed medkit treatment | 20 | Field Medicine | 0 |

The four early survival milestones total **120 XP**, exactly the unchanged Level 1 → Level 2 requirement. They only award after their real gameplay transaction succeeds. Failed fishing, full carry, failed boiling, interrupted treatment or repeated actions do not provide repeat XP.

Normal resource farming and threat kills still grant **0 XP**.

## Multiplayer behavior

Harvest and fishing progression is awarded on the peer where the physical loot is actually granted. This keeps progression personal in co-op instead of redirecting client experience to the host. Milestone keys are persisted in each survivor's local progression profile.

## Progression feedback HUD

A compact responsive HUD strip now exposes:

- current survivor level;
- progress toward the next level;
- unspent Talent Points / Stat Points when present;
- temporary progression feedback/toast messages.

The full build editor remains the existing `P` / `PROG` Survivor Progression menu. The compact strip does not add another gameplay input mode.

Desktop and mobile use the same lightweight Control nodes and no textures are required.

## Horror balance guardrails

v0.69 does not add:

- combat-kill XP loops;
- threat damage scaling;
- HP scaling;
- immunity;
- permanent threat radar;
- unlimited sprint;
- free generator power;
- extra carry-stack/type caps.

The progression fantasy remains knowledge, preparation, efficiency and survival experience.

## Validation

`tests/progression_gameplay_regression_v69.gd` validates:

- Level 1 threshold is still 120 XP;
- the four first-time milestones reach exactly Level 2;
- Level 2 still grants +1 Talent Point and +1 Stat Point;
- repeat milestones grant no XP;
- Water Safety / Wildlife Anatomy / Field Medicine unlock correctly;
- Level 2 threshold remains the v0.68 value of 179 XP;
- profile path/format stays compatible;
- normal resource farming and threat kills remain zero-XP contracts;
- progression feedback HUD is active and desktop/mobile responsive;
- water and medkit runtime milestone contracts are active.
