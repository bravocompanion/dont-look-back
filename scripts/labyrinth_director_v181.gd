extends "res://scripts/labyrinth_director.gd"

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
var lighting_scene_id: int = 0

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        return
    super._process(delta)
    _ensure_v181_labyrinth_lighting(scene)

func _ensure_v181_labyrinth_lighting(scene: Node) -> void:
    if expansion_root == null or not is_instance_valid(expansion_root):
        return
    var scene_id: int = int(scene.get_instance_id())
    if lighting_scene_id == scene_id:
        return

    for child: Node in expansion_root.get_children():
        if child is OmniLight3D:
            var light: OmniLight3D = child as OmniLight3D
            if light.light_energy <= 0.08 and light.omni_range <= 4.6:
                light.light_energy = 0.16
                light.omni_range = 5.7
                light.light_color = Color(0.46, 0.50, 0.54, 1.0)
                light.shadow_enabled = false

    _add_v181_dim_light("MazeAmbientA", Vector3(-6.5, 2.55, -22.8), 0.11, 5.1)
    _add_v181_dim_light("MazeAmbientB", Vector3(6.5, 2.55, -31.6), 0.10, 5.0)
    _add_v181_dim_light("MazeAmbientC", Vector3(-6.5, 2.55, -40.2), 0.11, 5.1)
    _add_v181_dim_light("MazeAmbientD", Vector3(-5.5, 2.55, -48.0), 0.09, 4.8)
    lighting_scene_id = scene_id

func _add_v181_dim_light(node_name: String, position: Vector3, energy: float, light_range: float) -> void:
    if expansion_root == null or expansion_root.has_node(NodePath(node_name)):
        return
    var light: OmniLight3D = OmniLight3D.new()
    light.name = node_name
    light.position = position
    light.light_color = Color(0.43, 0.47, 0.52, 1.0)
    light.light_energy = energy
    light.omni_range = light_range
    light.shadow_enabled = false
    expansion_root.add_child(light)
