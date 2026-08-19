extends "res://scripts/inventory_menu_system_v42_icons.gd"

# v0.43 stable item-icon inventory.
# The parent already injects one TextureRect per row; the registry now loads
# its atlas only once and returns cached AtlasTexture resources.

func _apply_inventory_button_icon() -> void:
    if bag_button == null:
        return
    var registry: Node = get_node_or_null("/root/ItemIconRegistry")
    if registry == null or not registry.has_method("is_ready") or not bool(registry.call("is_ready")):
        bag_button.text = "BAG" if _mobile_active() else "I"
        bag_button.tooltip_text = "Open Inventory"
        return
    super._apply_inventory_button_icon()
