extends "res://scripts/front_end_system_v187.gd"

const VERSION_BADGE_TEXT_V59: String = "v0.59  •  CHECKPOINT SNAPSHOT  •  FINITE LOOT  •  WIPE CONSISTENCY"

func _process(delta: float) -> void:
    super._process(delta)
    var scene: Node = get_tree().current_scene
    if scene == null or not _is_main_menu_scene(scene):
        return
    var version_label: Label = scene.get_node_or_null("MenuLayer/Root/Center/MainPanel/VBox/Version") as Label
    if version_label != null and version_label.text != VERSION_BADGE_TEXT_V59:
        version_label.text = VERSION_BADGE_TEXT_V59
