extends "res://scripts/front_end_system_v199.gd"

const VERSION_BADGE_TEXT_V71: String = "v0.71  •  UI / CODE COLLISION AUDIT  •  CENTRAL MODAL + SAFE HUD LANES"

func _process(delta: float) -> void:
    super._process(delta)
    var scene: Node = get_tree().current_scene
    if scene == null or not _is_main_menu_scene(scene):
        return
    var version_label: Label = scene.get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/Version") as Label
    if version_label != null and version_label.text != VERSION_BADGE_TEXT_V71:
        version_label.text = VERSION_BADGE_TEXT_V71

func _layout_ui() -> void:
    super._layout_ui()
    if menu_button == null:
        return
    var coordinator: Node = get_node_or_null("/root/UIRuntimeCoordinator")
    if coordinator == null or not coordinator.has_method("get_layout_v71"):
        return
    var viewport: Vector2 = get_viewport().get_visible_rect().size
    var layout: Dictionary = Dictionary(coordinator.call("get_layout_v71", viewport))
    if not bool(layout.get("compact", false)):
        return
    var rect_value: Variant = layout.get("menu_button", null)
    if rect_value is Rect2:
        var rect: Rect2 = rect_value
        menu_button.position = rect.position
        menu_button.size = rect.size

func get_front_end_collision_contract_v71() -> Dictionary:
    return {
        "mobile_menu_uses_coordinator": true,
        "mobile_status_overlap": false,
        "session_prestart_mobile_block_retained": true,
        "front_end_registered_in_gameplay_lock": true
    }
