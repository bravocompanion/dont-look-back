extends "res://scripts/field_status_menu_system_v43.gd"

func _other_menu_open() -> bool:
    if super._other_menu_open():
        return true
    var progression_menu: Node = get_node_or_null("/root/ProgressionMenuSystem")
    return progression_menu != null and progression_menu.has_method("is_open") and bool(progression_menu.call("is_open"))
