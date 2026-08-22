# Don't Look Back v0.62 — Gameplay Update

## Design goal

v0.62 does not add another map or inflate monster HP. It makes the existing horror loop more readable and gives the Research Facility decision a persistent tactical consequence.

Canonical loop remains:

**Prepare → Investigate → Expose yourself to danger → Recover evidence/resources → Survive encounter → Unlock deeper anomaly.**

## Horror pacing states

The high-level encounter budget now exposes five conceptual states:

1. **CALM** — no meaningful pressure budget active.
2. **UNEASE** — warning pressure is rising, but no major threat is committed.
3. **STALK** — conditions strongly indicate a threat is forming; player should secure a light/escape route.
4. **HUNT** — a major threat owns the encounter budget.
5. **RECOVERY** — post-encounter decompression; another different major threat cannot immediately replace the last one.

The pacing system does not own monster pathfinding, movement, attacks, health, or damage.

## Solo Darkness integration

Offline Darkness Creature spawning now participates in the same pacing budget used by co-op major threats.

- Darkness exposure at roughly 55% of spawn threshold begins feeding UNEASE.
- Exposure at roughly 80% of threshold feeds STALK.
- At the actual spawn threshold, Darkness must acquire the major-threat budget before spawning.
- When the creature despawns, the Darkness encounter ends and enters its existing recovery window.
- Creature speed, retreat speed, attack damage, attack distance, and light-recoil identity are unchanged.

This prevents the solo Darkness path from bypassing the horror pacing layer while preserving the existing survival tuning.

## Multiplayer ownership

Tenant remains an online host-authoritative co-op encounter. v0.62 does not invent a separate offline Tenant implementation.

Co-op Tenant/Darkness continue to use the existing major-threat budget. Research consequence effects are layered on that authority rather than replacing it.

## Research Facility persistent tradeoff

The mutually exclusive v0.61 decision now changes future play after its response sequence is complete.

### RESCUE PRIORITY / Distress Signal

Theme: regroup, protect the team, return to base.

- A powered/protected Ranger shelter accelerates post-encounter recovery by **45%**.
- Solo: the player must actually be inside the protected Ranger safe zone.
- Online host: at least half of the connected party must be inside the protected Ranger safe zone.
- The bonus does not increase health, stamina, damage, inventory, or monster weakness.
- An unpowered Ranger yard gives no recovery bonus.

### ANOMALY PRIORITY / Containment Data

Theme: stay in the field with better information.

- No recovery-speed bonus.
- No damage or defense bonus.
- Decoded topology exposes readable threat-analysis transitions: UNEASE, STALK, HUNT, and RECOVERY.
- Host broadcasts this analysis to the party during online play.

The choice is therefore **regroup efficiency vs threat intelligence**, not two versions of the same numerical buff.

## Platform rules

The new rules do not add a new input action and therefore inherit existing desktop/mobile controls. Threat intelligence uses the existing objective/HUD fallback and should later receive compact mobile-friendly icon/audio production treatment.

## Validation targets

Manual Godot playtest after CI:

1. Offline Darkness exposure moves CALM → UNEASE → STALK before spawn.
2. Darkness spawn enters HUNT only when pacing budget is available.
3. Darkness light-retreat/despawn enters RECOVERY and prevents immediate re-spawn pressure.
4. Rescue Priority does nothing at an unpowered Ranger shelter.
5. Rescue Priority accelerates recovery at a protected shelter.
6. In 3–4 player co-op, Rescue requires at least half the party regrouped at shelter.
7. Anomaly Priority shows threat-state intelligence but does not shorten recovery.
8. Online Anomaly HUNT/RECOVERY feedback reaches remote peers.
9. v0.61 Labyrinth split/regroup and Research response encounter do not regress.
10. Android touch layout and desktop HUD remain readable.
