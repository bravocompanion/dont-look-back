extends "res://scripts/movement_system.gd"

func _movement_allowed(player: CharacterBody3D) -> bool:
    if not super._movement_allowed(player):
        return false
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
        return false
    var status_menu: Node = get_node_or_null("/root/FieldStatusMenuSystem")
    if status_menu != null and status_menu.has_method("is_open") and bool(status_menu.call("is_open")):
        return false
    return true
