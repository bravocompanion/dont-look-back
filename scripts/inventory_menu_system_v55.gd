extends "res://scripts/inventory_menu_system_v54.gd"

func _add_item_row(item_id: String, display_name: String, count: int) -> void:
    super._add_item_row(item_id, display_name, count)
    if item_list == null or item_list.get_child_count() <= 0:
        return
    if item_id != "filter" and item_id != "radiation_suit":
        return

    var row_panel: PanelContainer = item_list.get_child(item_list.get_child_count() - 1) as PanelContainer
    if row_panel == null or row_panel.get_child_count() <= 0:
        return
    var row: HBoxContainer = row_panel.get_child(0) as HBoxContainer
    if row == null:
        return

    var action: Button = null
    for child: Node in row.get_children():
        if child is Button:
            action = child as Button
            break
    if action == null:
        return

    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    var filter_percent: int = int(radiation.call("get_suit_filter_percent_v55")) if radiation != null and radiation.has_method("get_suit_filter_percent_v55") else 100

    if item_id == "radiation_suit":
        action.text = "FILTER %d%%" % filter_percent
        action.tooltip_text = "Radiation shielding weakens as the cartridge depletes."
        action.disabled = true
        return

    var has_suit: bool = active_player != null and active_player.has_method("has_item") and bool(active_player.call("has_item", "radiation_suit"))
    action.text = "REPLACE"
    action.tooltip_text = "Consume 1 Industrial Filter to restore the Radiation Suit cartridge to 100%."
    action.disabled = not has_suit or filter_percent >= 99 or count <= 0
    if not action.disabled:
        action.pressed.connect(_replace_filter_v55)

func _replace_filter_v55() -> void:
    if active_player == null:
        return
    var radiation: Node = get_node_or_null("/root/RadiationSystem")
    if radiation == null or not radiation.has_method("replace_suit_filter_v55"):
        return
    radiation.call("replace_suit_filter_v55", active_player)
    last_signature = ""
    call_deferred("_refresh_inventory", true)
