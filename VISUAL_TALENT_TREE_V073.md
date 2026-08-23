# v0.73 — Visual Talent Tree Gameplay UI

v0.73 upgrades the v0.72 talent tree from text-heavy tier cards into a graphical survivor-build interface while retaining the exact progression rules underneath it.

## Runtime behavior

- Talent trees remain SURVIVAL, SCOUT, TECHNICIAN and INVESTIGATOR.
- Existing Tier I / Lv1, Tier II / Lv5, Tier III / Lv10 and Tier IV / Lv20 gates remain unchanged.
- Parent -> child connectors are generated directly from each talent's existing `requires` and `requires_rank` fields.
- Independent talents remain independent branch/root nodes; v0.73 adds no fake prerequisites.
- Connector lines are native Godot drawing and render behind the talent nodes.
- Locked branches are dim.
- Satisfied prerequisite branches become teal/readable.
- Invested branches become stronger.
- Maxed child paths receive a restrained gold completion treatment.
- Arrowheads make dependency direction explicit.

## Node interaction

Every talent node now centers its unique generated icon and keeps only compact information in the graph:

- talent name,
- current/max rank,
- LOCKED / AVAILABLE / INVESTED / MAXED state.

Long descriptions are moved to a selected-node detail panel below the graph.

Selecting a node never spends a Talent Point. Spending remains an explicit UNLOCK / + RANK action in the detail panel and still calls the existing authoritative `unlock_talent_v68()` API. This is safer for touch input and preserves the established progression/save behavior.

## Responsive layout

The v0.72 responsive breakpoint is retained:

- desktop >= 900 px: horizontal left-to-right graph,
- desktop below 900 px: vertical graph,
- mobile: vertical graph regardless of physical width.

Graph node placement supports tiers with multiple roots/side branches without horizontal scrolling on narrow mobile layouts.

## Generated talent icon atlas

The 20 talent icons created for this project are integrated into the Godot runtime as one compact 320x256 atlas with 64x64 cells. The source PNG is encoded into seven repository text parts and reconstructed in memory by `TalentIconRegistry` at startup, allowing the already-created art to ship even though the repository connector cannot directly commit binary PNG bytes.

Cell order:

### SURVIVAL
1. Efficient Metabolism
2. Field Medic
3. Pack Discipline
4. Load Bearing
5. Last Reserve

### SCOUT
1. Runner
2. Quiet Steps
3. Pathfinder
4. Escape Instinct
5. Ghost Trail

### TECHNICIAN
1. Quick Repair
2. Fuel Economy
3. Salvager
4. Circuit Memory
5. Emergency Power

### INVESTIGATOR
1. Steady Hands
2. Evidence Analyst
3. Pattern Recognition
4. Threat Familiarity
5. Cold Reader

## Compatibility

v0.73 deliberately does not change:

- level cap or XP curve,
- Talent Point economy,
- talent IDs,
- talent max ranks,
- prerequisites,
- gameplay modifiers,
- profile path/format,
- progression save-state version 68,
- checkpoint behavior,
- multiplayer/network authority,
- Tenant/Darkness/light rules.

The visual tree is a UI/readability upgrade over the same personal survivor build system.
