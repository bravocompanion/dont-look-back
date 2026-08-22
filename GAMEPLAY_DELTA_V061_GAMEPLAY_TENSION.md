# DON'T LOOK BACK — Gameplay Delta v0.61

## Goal

v0.61 deepens the existing Forest → Mine → Labyrinth → Research Facility route instead of adding another large map. The pass follows the canon rule that every system should create a readable horror decision and that co-op difficulty should scale through coordination rather than enemy HP.

## Labyrinth rule-depth

### Stage 1 — Fuse blackout

The maintenance fuse phase now runs under a severe Arc lighting cap. The route is still navigable, but flashlight ownership and battery decisions become the primary visibility choice until all three fuses are restored.

### Stage 2 — Flooded pipe noise

The valve phase periodically emits false AI noise from the flooded service section. Players can no longer assume every sound event points to another survivor or a monster. The goal is to make the flooded section change perception rules instead of acting as two more buttons.

### Stage 3 — Archive stabilizers / split pressure

The B → A → C archive breaker sequence is now locked behind simultaneous stabilizer coverage:

- solo: 1 stabilizer;
- 2 players: 2 stabilizers;
- 3–4 players: 3 stabilizers.

Each survivor may hold only one stabilizer at a time. A hold lasts 24 seconds, forcing a split → communicate → execute → regroup cadence without increasing monster health.

### Stage 5 — Moving lockdown protection

During the existing 120-second lockdown holdout, emergency protection rotates among three beacons every 23 seconds. For 3–4 player parties, at least two survivors must regroup at the active beacon; solo/duo requires one. Failure adds enemy aggression and exposed-team AI noise. Static camping is therefore less reliable than controlled relocation.

## Research Facility payoff

The Restricted Research Facility now contains a mutually exclusive campaign decision after the routing table is reviewed.

### Rescue Priority — Distress Signal

Commit the facility array to transmitting the missing survey team's distress packet. During the response, the emergency carrier moves between three safe beacons. The persisted outcome prioritizes finding the survey team in future content.

### Anomaly Priority — Containment Data

Commit the facility array to decoding the anomaly/containment topology. The response is shorter and uses a fixed central carrier, but the player still experiences containment-light interference outside the protected radius. The persisted outcome prioritizes containment/network knowledge in future content.

Both routes create a short darkness-interference sequence before the current campaign endpoint and both are saved/checkpointed.

## Multiplayer authority

Stabilizer and Research Facility choice requests are host-decided in online play. The host uses the current NetworkManager peer-position path to validate that the requesting survivor is physically near the device before accepting the action.

## Persistence

`SaveSystem v7` adds `research_payoff_v61` to normal save state and therefore to the v0.59 shared checkpoint snapshot path. Labyrinth stabilizer windows and rotating lockdown beacons are deliberately transient encounter state; the authoritative Arc objective/checkpoint state remains the durable source of truth.

## Deferred

- Hospital/Museum/Laboratory/Cave expansion remains deferred.
- No monster HP scaling was added.
- No new crafting tree was added.
- No new mandatory asset dependency was added.
