extends "res://scripts/movement_system_v44.gd"

# v0.74.3 — stronger floor adhesion only in Forest. This keeps descent across
# gentle terrain continuous without changing movement rules in Mine/Labyrinth.

const V743_FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const V743_FLOOR_SNAP_LENGTH: float = 0.55
const V743_FLOOR_MAX_ANGLE_DEG: float = 50.0

func _physics_process(delta: float) -> void:
    var player_before: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player_before != null and is_instance_valid(player_before) and _is_forest_v743():
        player_before.floor_snap_length = V743_FLOOR_SNAP_LENGTH
        player_before.floor_max_angle = deg_to_rad(V743_FLOOR_MAX_ANGLE_DEG)
        player_before.floor_stop_on_slope = true
        player_before.floor_constant_speed = false

    super._physics_process(delta)

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not is_instance_valid(player) or not _is_forest_v743():
        return

    # Never snap during an intentional jump. On descending micro-relief this
    # closes tiny contact gaps that otherwise make the path feel like a ledge.
    if player.velocity.y <= 0.0 and not player.is_on_floor():
        player.apply_floor_snap()

func _is_forest_v743() -> bool:
    var scene: Node = get_tree().current_scene
    return scene != null and scene.scene_file_path == V743_FOREST_SCENE_PATH

func get_forest_traversal_movement_contract_v743() -> Dictionary:
    return {
        "revision": "0.74.3",
        "forest_only": true,
        "floor_snap_length_m": V743_FLOOR_SNAP_LENGTH,
        "floor_max_angle_deg": V743_FLOOR_MAX_ANGLE_DEG,
        "apply_snap_while_jumping": false,
        "post_move_falloff_safety_preserved": true,
        "mobile_and_desktop_shared_path": true
    }
