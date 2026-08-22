extends "res://scripts/movement_system.gd"

func _movement_allowed(player: CharacterBody3D) -> bool:
    if not super._movement_allowed(player):
        return false

    var input_lock: Node = get_node_or_null("/root/GameplayInputLock")
    if input_lock != null and input_lock.has_method("is_locked"):
        if bool(input_lock.call("is_locked")):
            return false
        return true

    # Fallback protection for scenes/project settings that do not yet include
    # GameplayInputLock. Keep all current blocking menus covered.
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
        return false
    var status_menu: Node = get_node_or_null("/root/FieldStatusMenuSystem")
    if status_menu != null and status_menu.has_method("is_open") and bool(status_menu.call("is_open")):
        return false
    var journal: Node = get_node_or_null("/root/JournalSystem")
    if journal != null and journal.has_method("is_open") and bool(journal.call("is_open")):
        return false
    var stash: Node = get_node_or_null("/root/StashMenuSystem")
    if stash != null and stash.has_method("is_open") and bool(stash.call("is_open")):
        return false
    return true
