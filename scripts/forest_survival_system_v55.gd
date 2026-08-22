extends "res://scripts/forest_survival_system_v54.gd"

# v0.55 P1 food economy: wildlife regeneration follows in-game hours instead
# of rapidly shrinking real-time cooldowns, while fishing is slower and less
# deterministic. Existing hunting, corpse harvesting, arrows and carry limits
# remain inherited from v0.54.
@export var fishing_cooldown_v55: float = 75.0
@export var fishing_clear_chance_v55: float = 0.55
@export var fishing_rain_chance_v55: float = 0.70
@export var fishing_storm_chance_v55: float = 0.35
@export var fishing_double_catch_chance_v55: float = 0.10

func _process(delta: float) -> void:
    super._process(delta)
    if not forest_active:
        return
    animal_respawn_seconds = _wildlife_respawn_seconds_v55()
    fishing_cooldown_seconds = fishing_cooldown_v55

func _wildlife_respawn_seconds_v55() -> float:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var day_index: int = int(outside.get("day_index")) if outside != null else 1
    var full_day_seconds: float = maxf(60.0, float(outside.get("full_day_seconds"))) if outside != null else 720.0
    var respawn_game_hours: float = 8.0
    if day_index >= 4:
        respawn_game_hours = 12.0
    elif day_index >= 2:
        respawn_game_hours = 10.0
    return full_day_seconds * respawn_game_hours / 24.0

func _resolve_fishing(peer_id: int, _spot_id: String) -> void:
    var remaining: float = float(fishing_cooldowns.get(peer_id, 0.0))
    if remaining > 0.0:
        _message_peer(peer_id, "The water needs time to settle. Try fishing again in %d seconds." % int(ceil(remaining)))
        return

    fishing_cooldowns[peer_id] = fishing_cooldown_v55

    var chance: float = fishing_clear_chance_v55
    if current_weather == "rain":
        chance = fishing_rain_chance_v55
    elif current_weather == "storm":
        chance = fishing_storm_chance_v55

    if weather_rng.randf() > chance:
        _message_peer(peer_id, "The line stays quiet. The fish will need time before another attempt.")
        return

    var count: int = 2 if weather_rng.randf() < fishing_double_catch_chance_v55 else 1
    var loot: Dictionary = {"raw_fish": count}
    _grant_loot_to_peer(
        peer_id,
        loot,
        "FISHING: caught %d freshwater fish. The spot now needs time to recover." % count
    )
