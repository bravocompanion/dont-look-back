extends "res://scripts/journal_system_ranger_v6.gd"

func _unhandled_input(event: InputEvent) -> void:
    var progression_menu: Node = get_node_or_null("/root/ProgressionMenuSystem")
    if progression_menu != null and progression_menu.has_method("is_open") and bool(progression_menu.call("is_open")):
        return
    super._unhandled_input(event)

func open_journal() -> void:
    var progression_menu: Node = get_node_or_null("/root/ProgressionMenuSystem")
    if progression_menu != null and progression_menu.has_method("is_open") and bool(progression_menu.call("is_open")):
        return
    super.open_journal()
