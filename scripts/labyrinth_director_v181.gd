extends "res://scripts/labyrinth_director.gd"

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
var lighting_scene_id: int = 0
var lighting_time: float = 0.0
var dim_light_base_energy: Dictionary = {}
var dim_light_phase: Dictionary = {}

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        return
    super._process(delta)
    _open_arc1_threshold(scene)
    _ensure_v181_labyrinth_lighting(scene)
    _update_v22_dim_light_feel(delta)

func activate_relay(relay_id: int) -> bool:
    var activated: bool = super.activate_relay(relay_id)
    if not activated:
        return false

    if _active_relay_count() >= 3:
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if player != null:
            var objective: Label = player.get_node_or_null("HUD/Objective") as Label
            if objective != null:
                objective.text = "All 3 relays are online. The lower Labyrinth is open — follow the beacon deeper."
    return true

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

    lighting_scene_id = scene_id
    lighting_time = 0.0
    dim_light_base_energy.clear()
    dim_light_phase.clear()

    # Ambience stays below the player's protective-light threshold (> 0.1).
    # More lamps make navigation readable without making the maze safe.
    var light_index: int = 0
    for child: Node in expansion_root.get_children():
        if child is OmniLight3D:
            var light: OmniLight3D = child as OmniLight3D
            if light.light_energy <= 0.10 and light.omni_range <= 6.5:
                if light.light_energy <= 0.08 and light.omni_range <= 4.6:
                    light.light_energy = 0.095
                    light.omni_range = 6.2
                    light.light_color = Color(0.46, 0.50, 0.54, 1.0)
                    light.shadow_enabled = false
                _register_dim_light(light, float(light_index) * 0.83)
                light_index += 1

    _add_v181_dim_light("MazeAmbientA", Vector3(-6.5, 2.55, -22.8), 0.085, 5.8)
    _add_v181_dim_light("MazeAmbientB", Vector3(6.5, 2.55, -31.6), 0.080, 5.7)
    _add_v181_dim_light("MazeAmbientC", Vector3(-6.5, 2.55, -40.2), 0.085, 5.8)
    _add_v181_dim_light("MazeAmbientD", Vector3(-5.5, 2.55, -48.0), 0.075, 5.4)
    _add_v181_dim_light("MazeAmbientE", Vector3(6.7, 2.55, -19.2), 0.070, 5.4)
    _add_v181_dim_light("MazeAmbientF", Vector3(-6.8, 2.55, -27.2), 0.078, 5.6)
    _add_v181_dim_light("MazeAmbientG", Vector3(6.6, 2.55, -36.2), 0.073, 5.5)
    _add_v181_dim_light("MazeAmbientH", Vector3(-6.6, 2.55, -44.8), 0.082, 5.7)
    _add_v181_dim_light("MazeAmbientI", Vector3(0.0, 2.55, -49.5), 0.068, 5.2)

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
    _register_dim_light(light, float(dim_light_base_energy.size()) * 0.91)

func _register_dim_light(light: OmniLight3D, phase: float) -> void:
    if light == null:
        return
    var light_id: int = int(light.get_instance_id())
    dim_light_base_energy[light_id] = minf(0.098, light.light_energy)
    dim_light_phase[light_id] = phase

func _update_v22_dim_light_feel(delta: float) -> void:
    if expansion_root == null or not is_instance_valid(expansion_root):
        return
    lighting_time += delta

    var fault_active: bool = false
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc != null:
        fault_active = float(arc.get("fault_timer")) > 0.0

    var evacuation_active: bool = false
    var evacuation_critical: bool = false
    var evacuation: Node = get_node_or_null("/root/LabyrinthEvacuationSystem")
    if evacuation != null:
        if evacuation.has_method("is_escape_active"):
            evacuation_active = bool(evacuation.call("is_escape_active"))
        if evacuation.has_method("is_escape_critical"):
            evacuation_critical = bool(evacuation.call("is_escape_critical"))

    for child: Node in expansion_root.get_children():
        if not (child is OmniLight3D):
            continue
        var light: OmniLight3D = child as OmniLight3D
        var light_id: int = int(light.get_instance_id())
        if not dim_light_base_energy.has(light_id):
            continue

        var base_energy: float = float(dim_light_base_energy.get(light_id, 0.075))
        var phase: float = float(dim_light_phase.get(light_id, 0.0))
        var multiplier: float = 0.945
        multiplier += sin(lighting_time * 1.35 + phase) * 0.028
        multiplier += sin(lighting_time * 4.10 + phase * 1.73) * 0.018

        if fault_active:
            multiplier = 0.18 + 0.22 * absf(sin(lighting_time * 11.5 + phase))
        elif evacuation_active:
            var frequency: float = 8.4 if evacuation_critical else 4.2
            var floor_value: float = 0.50 if evacuation_critical else 0.68
            multiplier = floor_value + 0.26 * absf(sin(lighting_time * frequency + phase))

        light.light_energy = clampf(base_energy * multiplier, 0.012, 0.098)
