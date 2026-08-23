extends "res://scripts/inventory_menu_system_v56.gd"

func _blocked_elsewhere() -> bool:
    if super._blocked_elsewhere():
        return true
    var progression_menu: Node = get_node_or_null("/root/ProgressionMenuSystem")
    return progression_menu != null and progression_menu.has_method("is_open") and bool(progression_menu.call("is_open"))

func get_inventory_progression_contract_v68() -> Dictionary:
    return {
        "progression_menu_exclusive": true,
        "weight_ui_retained": true,
        "mobile_inventory_retained": true
    }
