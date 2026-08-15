extends "res://scripts/outside_director.gd"

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        outside_active = false
        return
    super._process(delta)

func enter_outside(player: CharacterBody3D) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        var transition: Node = get_node_or_null("/root/MapTransitionSystem")
        if transition != null and transition.has_method("request_forest_transition"):
            transition.call("request_forest_transition")
        return
    super.enter_outside(player)
