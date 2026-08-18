extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const DEPLOYMENT_SPAWN: Vector3 = Vector3(14.0, 0.92, -90.0)

var configured_scene_id: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        configured_scene_id = 0
        return
    var scene_id: int = int(scene.get_instance_id())
    if scene_id == configured_scene_id:
        return
    configured_scene_id = scene_id
    call_deferred("_apply_layout", scene)

func _apply_layout(scene: Node) -> void:
    await get_tree().process_frame
    if scene == null or not is_instance_valid(scene) or get_tree().current_scene != scene:
        return

    # The solid rear/edge wall is now on +Z. The gate is on -Z, toward the
    # center/deep forest, matching the mirrored cabin entrance.
    var edge_wall: CSGBox3D = scene.get_node_or_null("RangerFenceBack") as CSGBox3D
    if edge_wall != null:
        edge_wall.position = Vector3(14.0, 1.0, -67.0)
        edge_wall.size = Vector3(30.0, 2.0, 0.12)

    var forest_left: CSGBox3D = scene.get_node_or_null("RangerFenceFrontLeft") as CSGBox3D
    if forest_left != null:
        forest_left.position = Vector3(5.75, 1.0, -97.0)
        forest_left.size = Vector3(13.5, 2.0, 0.12)

    var forest_right: CSGBox3D = scene.get_node_or_null("RangerFenceFrontRight") as CSGBox3D
    if forest_right != null:
        forest_right.position = Vector3(22.25, 1.0, -97.0)
        forest_right.size = Vector3(13.5, 2.0, 0.12)

    var left_post: CSGBox3D = scene.get_node_or_null("RangerGateLeftPost") as CSGBox3D
    if left_post != null:
        left_post.position = Vector3(12.5, 1.3, -97.0)
    var right_post: CSGBox3D = scene.get_node_or_null("RangerGateRightPost") as CSGBox3D
    if right_post != null:
        right_post.position = Vector3(15.5, 1.3, -97.0)

    var left_leaf: CSGBox3D = scene.get_node_or_null("RangerGateLeftLeaf") as CSGBox3D
    if left_leaf != null:
        left_leaf.position = Vector3(11.7, 1.0, -97.45)
        left_leaf.rotation_degrees = Vector3(0.0, -55.0, 0.0)
    var right_leaf: CSGBox3D = scene.get_node_or_null("RangerGateRightLeaf") as CSGBox3D
    if right_leaf != null:
        right_leaf.position = Vector3(16.3, 1.0, -97.45)
        right_leaf.rotation_degrees = Vector3(0.0, 55.0, 0.0)

    var player: CharacterBody3D = scene.get_node_or_null("Player") as CharacterBody3D
    if player != null:
        player.global_position = DEPLOYMENT_SPAWN
        player.rotation.y = 0.0
        player.velocity = Vector3.ZERO
