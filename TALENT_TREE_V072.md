# v0.72 Talent Tree

v0.72 changes the Talent tab from a flat list into a branching specialization tree without changing existing talent IDs, ranks, save format, or gameplay authority.

## Specialization trees

- SURVIVAL
- SCOUT
- TECHNICIAN
- INVESTIGATOR

Each tree keeps the five talents already present in v0.68-v0.71.

## Tier structure

- Tier I / Level 1: foundation nodes
- Tier II / Level 5: specialization nodes
- Tier III / Level 10: advanced nodes
- Tier IV / Level 20: signature node

Existing `requires` and `requires_rank` data are the branch edges. Independent talents remain side branches rather than being forced into artificial prerequisites.

## UX

Desktop uses a left-to-right tree: Tier I -> Tier II -> Tier III -> Tier IV.

Mobile/compact uses a top-to-bottom tree so touch targets and text remain readable without horizontal scrolling.

Each node displays:
- talent name
- current/max rank
- prerequisite or ROOT NODE
- level gate
- description
- current state: MAXED, LOCKED, NEED TALENT POINT, UNLOCK, or + RANK

The Talent tab shows one specialization tree at a time through a four-tree selector. This avoids the old long vertical list and keeps the branch structure readable.

## Compatibility

- Progression save state remains version 68.
- `talent_ranks` keys are unchanged.
- Existing saves retain all unlocked ranks.
- Existing `unlock_talent_v68()` remains the authoritative spending path.
- Level cap remains 30.
- Talent Point economy is unchanged.
- Stats and Knowledge are unchanged.
- Multiplayer/network authority is unchanged.
- v0.71 GameplayInputLock and safe HUD layout remain active.
