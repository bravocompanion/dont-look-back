extends "res://scripts/progression_menu_system_v72.gd"

const TALENT_TREE_HORIZONTAL_BREAKPOINT_V72: float = 900.0

func _talent_tree_compact_v72() -> bool:
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    return get_talent_tree_layout_mode_v72(viewport.x, _mobile_v68()) == "VERTICAL"

func get_talent_tree_layout_mode_v72(viewport_width: float, mobile_active: bool = false) -> String:
    if mobile_active or viewport_width < TALENT_TREE_HORIZONTAL_BREAKPOINT_V72:
        return "VERTICAL"
    return "HORIZONTAL"

func get_progression_menu_tree_contract_v72() -> Dictionary:
    var contract: Dictionary = super.get_progression_menu_tree_contract_v72()
    contract["horizontal_breakpoint"] = TALENT_TREE_HORIZONTAL_BREAKPOINT_V72
    contract["width_360_mode"] = get_talent_tree_layout_mode_v72(360.0, false)
    contract["width_430_mode"] = get_talent_tree_layout_mode_v72(430.0, false)
    contract["width_800_mode"] = get_talent_tree_layout_mode_v72(800.0, false)
    contract["width_1280_mode"] = get_talent_tree_layout_mode_v72(1280.0, false)
    return contract
