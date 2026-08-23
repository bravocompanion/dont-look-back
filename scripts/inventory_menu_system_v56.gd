extends "res://scripts/inventory_menu_system_v55.gd"

func _refresh_inventory(force: bool) -> void:
    super._refresh_inventory(force)
    _refresh_weight_summary_v67()

func _add_item_row(item_id: String, display_name: String, count: int) -> void:
    super._add_item_row(item_id, display_name, count)
    if item_list == null or item_list.get_child_count() <= 0:
        return

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry == null or not carry.has_method("get_item_weight"):
        return

    var row_panel: PanelContainer = item_list.get_child(item_list.get_child_count() - 1) as PanelContainer
    if row_panel == null or row_panel.get_child_count() <= 0:
        return
    var row: HBoxContainer = row_panel.get_child(0) as HBoxContainer
    if row == null:
        return

    var unit_weight: float = float(carry.call("get_item_weight", item_id))
    var total_weight: float = unit_weight * float(maxi(0, count))
    for child: Node in row.get_children():
        var label: Label = child as Label
        if label == null:
            continue
        label.text = "%s   x%d   %.2f kg" % [display_name, count, total_weight]
        label.tooltip_text = "%.2f kg per unit • %.2f kg carried" % [unit_weight, total_weight]
        break

func _refresh_weight_summary_v67() -> void:
    if summary_label == null or active_player == null:
        return
    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry == null or not carry.has_method("get_current_weight"):
        return

    var current: float = float(carry.call("get_current_weight", active_player))
    var maximum: float = float(carry.call("get_max_weight", active_player))
    var status: String = str(carry.call("get_encumbrance_status", active_player))
    if _mobile_active():
        summary_label.text = "CARRY %.1f / %.0f kg  •  %s" % [current, maximum, status]
    else:
        summary_label.text = "CARRY %.1f / %.1f kg  •  %s" % [current, maximum, status]

    if help_label != null:
        if status == "OVERWEIGHT":
            help_label.text = "Store, consume, or drop weight before collecting more items."
        elif status == "HEAVY":
            help_label.text = "Heavy load slows movement and makes sprinting more exhausting."
        else:
            help_label.text = "Tap USE to consume an item" if _mobile_active() else "I: close inventory"
