extends "res://scripts/outside_director.gd"

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
var entry_boundary_scene_id: int = 0

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        outside_active = false
        return
    super._process(delta)
    _ensure_forest_entry_boundary(scene)

func enter_outside(player: CharacterBody3D) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        var transition: Node = get_node_or_null("/root/MapTransitionSystem")
        if transition != null and transition.has_method("request_forest_transition"):
            transition.call("request_forest_transition")
        return
    super.enter_outside(player)

func _ensure_forest_entry_boundary(scene: Node) -> void:
    if outside_root == null or not is_instance_valid(outside_root):
        return
    var scene_id: int = int(scene.get_instance_id())
    if entry_boundary_scene_id == scene_id:
        return
    if outside_root.has_node("ForestEntryBoundary"):
        entry_boundary_scene_id = scene_id
        return

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.035, 0.042, 0.035, 1.0)
    material.roughness = 1.0

    var boundary: CSGBox3D = CSGBox3D.new()
    boundary.name = "ForestEntryBoundary"
    boundary.position = Vector3(0.0, 1.25, -52.2)
    boundary.size = Vector3(72.0, 2.5, 0.35)
    boundary.use_collision = true
    boundary.material = material
    outside_root.add_child(boundary)
    entry_boundary_scene_id = scene_id
