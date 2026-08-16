extends "res://scripts/labyrinth_director.gd"

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
var lighting_scene_id: int = 0

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        return
    super._process(delta)
    _open_arc1_threshold(scene)
    _ensure_v181_labyrinth_lighting(scene)

func _open_arc1_threshold(scene: Node) -> void:
    if scene.get_node_or_null("Arc1Expansion") == null:
        return
    var old_back_wall: Node = scene.get_node_or_null("LabyrinthExpansion/PerimeterBack")
    if old_back_wall != null:
        old_back_wall.queue_free()
    var old_transition: Node = scene.get_node_or_null("LabyrinthExpansion/OutsideTransition")
    if old_transition != null:
        old_transition.queue_free()

func _ensure_v181_labyrinth_lighting(scene: Node) -> void:
    if expansion_root == null or not is_instance_valid(expansion_root):
        return
    var scene_id: int = int(scene.get_instance_id())
    if lighting_scene_id == scene_id:
        return

    # Ambience stays below the player's protective-light threshold (> 0.1).
    # More lamps make navigation readable without making the maze safe.
    for child: Node in expansion_root.get_children():
        if child is OmniLight3D:
            var light: OmniLight3D = child as OmniLight3D
            if light.light_energy <= 0.08 and light.omni_range <= 4.6:
                light.light_energy = 0.095
                light.omni_range = 6.2
                light.light_color = Color(0.46, 0.50, 0.54, 1.0)
                light.shadow_enabled = false

    _add_v181_dim_light("MazeAmbientA", Vector3(-6.5, 2.55, -22.8), 0.085, 5.8)
    _add_v181_dim_light("MazeAmbientB", Vector3(6.5, 2.55, -31.6), 0.080, 5.7)
    _add_v181_dim_light("MazeAmbientC", Vector3(-6.5, 2.55, -40.2), 0.085, 5.8)
    _add_v181_dim_light("MazeAmbientD", Vector3(-5.5, 2.55, -48.0), 0.075, 5.4)
    _add_v181_dim_light("MazeAmbientE", Vector3(6.7, 2.55, -19.2), 0.070, 5.4)
    _add_v181_dim_light("MazeAmbientF", Vector3(-6.8, 2.55, -27.2), 0.078, 5.6)
    _add_v181_dim_light("MazeAmbientG", Vector3(6.6, 2.55, -36.2), 0.073, 5.5)
    _add_v181_dim_light("MazeAmbientH", Vector3(-6.6, 2.55, -44.8), 0.082, 5.7)
    _add_v181_dim_light("MazeAmbientI", Vector3(0.0, 2.55, -49.5), 0.068, 5.2)
    lighting_scene_id = scene_id

func _add_v181_dim_light(node_name: String, position: Vector3, energy: float, light_range: float) -> void:
    if expansion_root == null or expansion_root.has_node(NodePath(node_name)):
        return

    var fixture_material: StandardMaterial3D = StandardMaterial3D.new()
    fixture_material.albedo_color = Color(0.18, 0.19, 0.19, 1.0)
    fixture_material.emission_enabled = true
    fixture_material.emission = Color(0.20, 0.23, 0.22, 1.0)
    fixture_material.emission_energy_multiplier = 0.45

    var fixture_mesh: BoxMesh = BoxMesh.new()
    fixture_mesh.size = Vector3(0.54, 0.06, 0.22)
    var fixture: MeshInstance3D = MeshInstance3D.new()
    fixture.name = "%sFixture" % node_name
    fixture.mesh = fixture_mesh
    fixture.material_override = fixture_material
    fixture.position = position + Vector3(0.0, 0.10, 0.0)
    expansion_root.add_child(fixture)

    var light: OmniLight3D = OmniLight3D.new()
    light.name = node_name
    light.position = position
    light.light_color = Color(0.43, 0.47, 0.52, 1.0)
    light.light_energy = minf(0.098, energy)
    light.omni_range = light_range
    light.shadow_enabled = false
    expansion_root.add_child(light)
