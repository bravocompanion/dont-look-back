extends "res://scripts/inventory_menu_system.gd"

const FOREST_FOOD: Dictionary = {
    "cooked_meat": {"hunger": 56.0, "health": 4.0},
    "cooked_fish": {"hunger": 44.0, "health": 2.0}
}
const FOREST_EQUIPMENT: Array[String] = ["hunting_bow", "fishing_rod"]
const FOREST_MATERIALS: Array[String] = ["arrow", "raw_meat", "raw_fish", "hide", "bone", "animal_fat"]

func _add_item_row(item_id: String, display_name: String, count: int) -> void:
    if not FOREST_FOOD.has(item_id) and item_id not in FOREST_EQUIPMENT and item_id not in FOREST_MATERIALS:
        super._add_item_row(item_id, display_name, count)
        return

    var row_panel: PanelContainer = PanelContainer.new()
    row_panel.add_theme_stylebox_override("panel", _item_style())
    item_list.add_child(row_panel)

    var row: HBoxContainer = HBoxContainer.new()
    row.add_theme_constant_override("separation", 10)
    row_panel.add_child(row)

    var name_label: Label = Label.new()
    name_label.text = "%s   x%d" % [display_name, count]
    name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
    name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    name_label.add_theme_font_size_override("font_size", 16)
    row.add_child(name_label)

    var action: Button = Button.new()
    action.custom_minimum_size = Vector2(104, 40)
    action.focus_mode = Control.FOCUS_NONE
    if FOREST_FOOD.has(item_id):
        action.text = "EAT"
        action.pressed.connect(_use_forest_food.bind(item_id))
    elif item_id in FOREST_EQUIPMENT:
        action.text = "EQUIPPED"
        action.disabled = true
    else:
        action.text = "MATERIAL"
        action.disabled = true
    row.add_child(action)

func _use_forest_food(item_id: String) -> void:
    if active_player == null or not FOREST_FOOD.has(item_id):
        return
    if not active_player.has_method("remove_item") or not bool(active_player.call("remove_item", item_id)):
        return

    var data: Dictionary = Dictionary(FOREST_FOOD.get(item_id, {}))
    var max_hunger: float = float(active_player.get("max_hunger"))
    var hunger: float = minf(max_hunger, float(active_player.get("hunger")) + float(data.get("hunger", 0.0)))
    active_player.set("hunger", hunger)
    if float(data.get("health", 0.0)) > 0.0 and active_player.has_method("heal"):
        active_player.call("heal", float(data.get("health", 0.0)))

    var objective: Label = active_player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "You eat %s. A hot meal makes the next expedition feel possible." % ("Cooked Meat" if item_id == "cooked_meat" else "Cooked Fish")
    last_signature = ""
    call_deferred("_refresh_inventory", true)
