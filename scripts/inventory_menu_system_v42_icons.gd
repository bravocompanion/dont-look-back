extends "res://scripts/inventory_menu_system_v41.gd"

const ITEM_ICON_SIZE: Vector2 = Vector2(50.0, 44.0)

func _build_ui(hud: CanvasLayer) -> void:
    super._build_ui(hud)
    _apply_inventory_button_icon()

func _add_item_row(item_id: String, display_name: String, count: int) -> void:
    super._add_item_row(item_id, display_name, count)
    _inject_icon_into_last_row(item_id)

func _blocked_elsewhere() -> bool:
    if super._blocked_elsewhere():
        return true
    var stash: Node = get_node_or_null("/root/StashMenuSystem")
    return stash != null and stash.has_method("is_open") and bool(stash.call("is_open"))

func _inject_icon_into_last_row(item_id: String) -> void:
    if item_list == null or item_list.get_child_count() <= 0:
        return

    var registry: Node = get_node_or_null("/root/ItemIconRegistry")
    if registry == null or not registry.has_method("get_icon"):
        return
    var texture: Texture2D = registry.call("get_icon", item_id) as Texture2D
    if texture == null:
        return

    var row_panel: PanelContainer = item_list.get_child(item_list.get_child_count() - 1) as PanelContainer
    if row_panel == null or row_panel.get_child_count() <= 0:
        return
    var row: HBoxContainer = row_panel.get_child(0) as HBoxContainer
    if row == null:
        return

    var icon: TextureRect = TextureRect.new()
    icon.name = "ItemIcon"
    icon.texture = texture
    icon.custom_minimum_size = ITEM_ICON_SIZE
    icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
    icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
    icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
    row.add_child(icon)
    row.move_child(icon, 0)

func _apply_inventory_button_icon() -> void:
    if bag_button == null:
        return
    var registry: Node = get_node_or_null("/root/ItemIconRegistry")
    if registry == null or not registry.has_method("get_icon"):
        return
    var texture: Texture2D = registry.call("get_icon", "backpack") as Texture2D
    if texture == null:
        return
    bag_button.icon = texture
    bag_button.expand_icon = true
    bag_button.text = "" if _mobile_active() else "I"
    bag_button.tooltip_text = "Open Inventory"
