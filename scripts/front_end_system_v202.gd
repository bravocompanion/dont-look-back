extends "res://scripts/front_end_system_v201.gd"

const VERSION_BADGE_TEXT_V73: String = "v0.73  •  VISUAL TALENT TREE  •  GRAPH LINKS / ICON NODES"

func _process(delta: float) -> void:
    super._process(delta)
    var scene: Node = get_tree().current_scene
    if scene == null or not _is_main_menu_scene(scene):
        return
    var version_label: Label = scene.get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/Version") as Label
    if version_label != null and version_label.text != VERSION_BADGE_TEXT_V73:
        version_label.text = VERSION_BADGE_TEXT_V73

func get_front_end_visual_talent_tree_contract_v73() -> Dictionary:
    return {
        "version_badge_v73": true,
        "v072_tree_retained": true,
        "v071_ui_coordinator_retained": true,
        "mobile_menu_safe_lane_retained": true
    }
