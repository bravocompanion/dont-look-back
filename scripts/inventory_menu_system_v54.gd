extends "res://scripts/inventory_menu_system_v43.gd"

func _add_item_row(item_id: String, display_name: String, count: int) -> void:
    super._add_item_row(item_id, display_name, count)
    if item_list == null or item_list.get_child_count() <= 0:
        return

    var carry: Node = get_node_or_null("/root/CarryLimitSystem")
    if carry == null or not carry.has_method("get_stack_limit"):
        return
    var limit: int = int(carry.call("get_stack_limit", item_id))
    if limit >= 99:
        return

    var row_panel: PanelContainer = item_list.get_child(item_list.get_child_count() - 1) as PanelContainer
    if row_panel == null or row_panel.get_child_count() <= 0:
        return
    var row: HBoxContainer = row_panel.get_child(0) as HBoxContainer
    if row == null:
        return
    for child: Node in row.get_children():
        var label: Label = child as Label
        if label != null:
            label.text = "%s   x%d / %d" % [display_name, count, limit]
            label.tooltip_text = "Expedition stack limit: %d. Store excess supplies at the ranger cabin." % limit
            return
