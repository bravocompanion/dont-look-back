extends "res://scripts/field_status_menu_system_v41.gd"

func _refresh_status(player: CharacterBody3D) -> void:
    super._refresh_status(player)
    if player == null or condition_label == null:
        return

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry == null or not carry.has_method("get_current_weight"):
        return

    var current: float = float(carry.call("get_current_weight", player))
    var maximum: float = float(carry.call("get_max_weight", player))
    var status: String = str(carry.call("get_encumbrance_status", player))
    var base_condition: String = condition_label.text
    _set_label_text(
        condition_label,
        "%s\nCarry %.1f / %.1f kg  •  %s" % [base_condition, current, maximum, status]
    )

func get_field_status_weight_contract_v67() -> Dictionary:
    return {
        "shows_current_weight": true,
        "shows_max_weight": true,
        "shows_encumbrance_status": true
    }
