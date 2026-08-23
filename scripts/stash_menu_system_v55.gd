extends "res://scripts/stash_menu_system_v54.gd"

func _take_one(item_id: String) -> void:
    if not _can_control_stash() or active_player == null or not active_player.has_method("add_item"):
        return
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        return

    var storage_names: Dictionary = Dictionary(shelter.get("storage_names"))
    var storage_counts: Dictionary = Dictionary(shelter.get("storage_counts"))
    var count: int = int(storage_counts.get(item_id, 0))
    if count <= 0:
        return

    var display_name: String = str(storage_names.get(item_id, _display_name(item_id)))
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    var accepted: bool = false
    if carry != null and carry.has_method("grant_item"):
        accepted = bool(carry.call("grant_item", active_player, item_id, display_name, 1))
    else:
        accepted = bool(active_player.call("add_item", item_id, display_name))

    if not accepted:
        if carry != null and carry.has_method("get_current_weight") and carry.has_method("get_item_weight"):
            var current: float = float(carry.call("get_current_weight", active_player))
            var maximum: float = float(carry.call("get_max_weight", active_player))
            var item_weight: float = float(carry.call("get_item_weight", item_id))
            _feedback("Too heavy: %s is %.2f kg. Carry %.1f / %.1f kg." % [display_name, item_weight, current, maximum])
        else:
            _feedback("Cannot take %s right now." % display_name)
        return

    count -= 1
    if count <= 0:
        storage_counts.erase(item_id)
        storage_names.erase(item_id)
    else:
        storage_counts[item_id] = count
    shelter.set("storage_names", storage_names)
    shelter.set("storage_counts", storage_counts)
    _after_transfer()

func get_stash_weight_contract_v67() -> Dictionary:
    return {
        "store_always_reduces_player_weight": true,
        "withdrawal_uses_weight_check": true,
        "stash_has_personal_32kg_limit": false
    }
