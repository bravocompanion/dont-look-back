extends "res://scripts/save_system_v181.gd"

const RANGER_MENU_SCENE_PATH: String = "res://scenes/main_menu_ranger.tscn"
const RANGER_FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const RANGER_STORY_VERSION: int = 1
const RANGER_START_POSITION: Array = [14.0, 0.92, -76.0]

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == RANGER_MENU_SCENE_PATH:
        if layer != null:
            layer.visible = false
        return
    super._process(delta)

func _collect_state(player: CharacterBody3D) -> Dictionary:
    var state: Dictionary = super._collect_state(player)
    state["ranger_story_version"] = RANGER_STORY_VERSION
    return state

func _target_scene_for_state(state: Dictionary) -> String:
    if int(state.get("ranger_story_version", 0)) < RANGER_STORY_VERSION:
        return RANGER_FOREST_SCENE_PATH
    return super._target_scene_for_state(state)

func _restore_state(state: Dictionary) -> void:
    var migrated: Dictionary = state.duplicate(true)
    if int(migrated.get("ranger_story_version", 0)) < RANGER_STORY_VERSION:
        migrated["ranger_story_version"] = RANGER_STORY_VERSION
        migrated["map_scene"] = RANGER_FOREST_SCENE_PATH
        var player_state: Dictionary = Dictionary(migrated.get("player", {})).duplicate(true)
        player_state["position"] = RANGER_START_POSITION.duplicate()
        player_state["rotation_y"] = 0.0
        migrated["player"] = player_state
        migrated["checkpoint"] = {}
        migrated["claimed_pickups"] = []
        migrated["arc1"] = {}
        migrated["arc1_exploration"] = {}
    super._restore_state(migrated)
