extends "res://scripts/inventory_menu_system_v25.gd"

const V41_GEAR: Array[String] = ["raincoat", "radiation_suit"]
const V41_MATERIALS: Array[String] = ["plastic_sheet", "rubber", "electronics", "lead_plate", "copper_wire", "filter"]

func _add_item_row(item_id: String, display_name: String, count: int) -> void:
    if item_id not in V41_GEAR and item_id not in V41_MATERIALS:
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
    if item_id in V41_GEAR:
        action.text = "EQUIPPED"
    else:
        action.text = "MATERIAL"
    action.disabled = true
    row.add_child(action)
