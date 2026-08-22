extends "res://scripts/forest_survival_system_v53.gd"

# v0.54 keeps all v0.53 hunting/sway/speed behavior and makes renewable food,
# carcass harvest, crafted/recovered arrows, and fishing obey expedition limits.

func _grant_loot_local(loot: Dictionary, message: String) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("add_item"):
        return

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    var lost: int = 0
    var granted_total: int = 0
    for id_value: Variant in loot.keys():
        var item_id: String = str(id_value)
        var count: int = int(loot.get(id_value, 0))
        for _index: int in range(count):
            var accepted: bool = false
            if carry != null and carry.has_method("grant_item"):
                accepted = bool(carry.call("grant_item", player, item_id, _display_name(item_id), 1))
            else:
                accepted = bool(player.call("add_item", item_id, _display_name(item_id)))
            if accepted:
                granted_total += 1
            else:
                lost += 1

    if lost > 0:
        _objective(player, "%s Carry limits left %d item(s) behind." % [message, lost])
    elif granted_total > 0:
        _objective(player, message)

func _can_harvest_loot_v52(player: CharacterBody3D, loot: Dictionary) -> bool:
    if player == null or not player.has_method("has_item") or not player.has_method("add_item"):
        return false
    if not bool(player.call("has_item", "hunting_knife")):
        _objective(player, "You need a Hunting Knife to harvest the carcass.")
        return false

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry != null and carry.has_method("can_accept_bundle"):
        if not bool(carry.call("can_accept_bundle", player, loot)):
            _objective(player, "Not enough carry capacity for this carcass. Store supplies, then return to harvest it.")
            return false
        return true

    return super._can_harvest_loot_v52(player, loot)

func _grant_harvest_loot_local_v52(player: CharacterBody3D, loot: Dictionary, animal_kind: String) -> void:
    if player == null:
        return
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    for item_value: Variant in loot.keys():
        var item_id: String = str(item_value)
        var count: int = int(loot.get(item_value, 0))
        if carry != null and carry.has_method("grant_item"):
            carry.call("grant_item", player, item_id, _display_name(item_id), count)
        else:
            for _index: int in range(count):
                player.call("add_item", item_id, _display_name(item_id))
    _objective(
        player,
        "HARVEST: %s — collected %s." % [animal_kind.capitalize(), _loot_summary(loot)]
    )

func _handle_arrow_recovery_request(peer_id: int, projectile_id: int) -> void:
    if not _is_authoritative() or peer_id <= 0:
        return
    var projectile: Node3D = arrow_projectiles.get(projectile_id, null) as Node3D
    if projectile == null or not is_instance_valid(projectile):
        arrow_projectiles.erase(projectile_id)
        return
    if not projectile.has_method("is_recoverable_arrow") or not bool(projectile.call("is_recoverable_arrow")):
        return
    if int(arrow_claims.get(projectile_id, 0)) != 0:
        return

    var peer_player: CharacterBody3D = _player_for_peer(peer_id)
    if peer_player != null and peer_player.global_position.distance_to(projectile.global_position) > 3.4:
        _message_peer(peer_id, "Move closer to the arrow before recovering it.")
        return

    if not _network_online() or peer_id == _local_peer_id():
        var local_player: CharacterBody3D = _local_player()
        if local_player == null:
            return
        if not _grant_recovered_arrow_v54(local_player):
            _objective(local_player, "Arrow carry limit reached. The arrow remains on the ground.")
            return
        _broadcast_remove_arrow(projectile_id)
        _objective(local_player, "Recovered Arrow. The shaft survived the impact.")
        return

    arrow_claims[projectile_id] = peer_id
    _attempt_arrow_recovery_remote.rpc_id(peer_id, projectile_id)

@rpc("authority", "call_remote", "reliable", 33)
func _attempt_arrow_recovery_remote(projectile_id: int) -> void:
    var player: CharacterBody3D = _local_player()
    var success: bool = false
    if player != null:
        success = _grant_recovered_arrow_v54(player)
        if success:
            _objective(player, "Recovered Arrow. The shaft survived the impact.")
        else:
            _objective(player, "Arrow carry limit reached. The arrow remains on the ground.")
    _complete_arrow_recovery_remote.rpc_id(1, projectile_id, success)

func _grant_recovered_arrow_v54(player: CharacterBody3D) -> bool:
    if player == null or not player.has_method("add_item"):
        return false
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry != null and carry.has_method("grant_item"):
        return bool(carry.call("grant_item", player, "arrow", "Arrow", 1))
    return bool(player.call("add_item", "arrow", "Arrow"))
