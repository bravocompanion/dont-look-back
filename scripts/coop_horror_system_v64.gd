extends "res://scripts/coop_horror_system_v63.gd"

func _update_revive_channels(delta: float) -> void:
    var candidates: Dictionary = {}
    for reviver_variant: Variant in revive_channels.keys():
        var reviver_peer_id: int = int(reviver_variant)
        var channel: Dictionary = Dictionary(revive_channels.get(reviver_peer_id, {}))
        var target_peer_id: int = int(channel.get("target", 0))
        if target_peer_id > 0 and is_survivor_downed(target_peer_id):
            candidates[reviver_peer_id] = target_peer_id

    super._update_revive_channels(delta)

    if candidates.is_empty():
        return
    var progression: Node = get_node_or_null("/root/ProgressionSystem")
    if progression == null or not progression.has_method("award_event_for_peer_v68"):
        return
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var day_index: int = int(outside.get("day_index")) if outside != null else 1
    for reviver_variant: Variant in candidates.keys():
        var reviver_peer_id: int = int(reviver_variant)
        var target_peer_id: int = int(candidates.get(reviver_peer_id, 0))
        if revive_channels.has(reviver_peer_id):
            continue
        if target_peer_id <= 0 or is_survivor_downed(target_peer_id):
            continue
        progression.call(
            "award_event_for_peer_v68",
            reviver_peer_id,
            "revive:day:%d:target:%d" % [day_index, target_peer_id],
            45,
            "Teammate revived",
            "teamwork"
        )

func get_coop_progression_contract_v68() -> Dictionary:
    return {
        "revive_xp": 45,
        "revive_repeat_policy": "once per target per game-day",
        "award_goes_to_reviver_peer": true,
        "progression_shared_between_party": false
    }
