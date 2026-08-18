extends "res://scripts/arc1_navigation_bridge.gd"

const RANGER_LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != RANGER_LABYRINTH_SCENE_PATH:
        last_stage = -1
        pending_rebuild_frames = 0
        return
    super._process(delta)
