extends "res://scripts/stash_menu_system_v43.gd"

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
        var status: String = str(carry.call("stack_status", active_player, item_id)) if carry != null and carry.has_method("stack_status") else "full"
        _feedback("Carry limit reached for %s (%s). Leave it in the stash or make room." % [display_name, status])
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
