extends "res://scripts/front_end_system_v200.gd"

const VERSION_BADGE_TEXT_V72: String = "v0.72  •  TALENT TREE  •  BRANCHING SURVIVOR SPECIALIZATIONS"

func _process(delta: float) -> void:
    super._process(delta)
    var scene: Node = get_tree().current_scene
    if scene == null or not _is_main_menu_scene(scene):
        return
    var version_label: Label = scene.get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/Version") as Label
    if version_label != null and version_label.text != VERSION_BADGE_TEXT_V72:
        version_label.text = VERSION_BADGE_TEXT_V72

func get_front_end_talent_tree_contract_v72() -> Dictionary:
    return {
        "version_badge_v72": true,
        "v071_ui_coordinator_retained": true,
        "mobile_menu_safe_lane_retained": true
    }
