extends "res://scripts/journal_system_ranger_v5_english.gd"

func _unhandled_input(event: InputEvent) -> void:
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
        return
    var status_menu: Node = get_node_or_null("/root/FieldStatusMenuSystem")
    if status_menu != null and status_menu.has_method("is_open") and bool(status_menu.call("is_open")):
        return
    var stash: Node = get_node_or_null("/root/StashMenuSystem")
    if stash != null and stash.has_method("is_open") and bool(stash.call("is_open")):
        return
    super._unhandled_input(event)

func open_journal() -> void:
    var crafting: Node = get_node_or_null("/root/CraftingSystem")
    if crafting != null and crafting.has_method("is_open") and bool(crafting.call("is_open")):
        return
    var status_menu: Node = get_node_or_null("/root/FieldStatusMenuSystem")
    if status_menu != null and status_menu.has_method("is_open") and bool(status_menu.call("is_open")):
        return
    var stash: Node = get_node_or_null("/root/StashMenuSystem")
    if stash != null and stash.has_method("is_open") and bool(stash.call("is_open")):
        return
    super.open_journal()
