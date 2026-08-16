extends StaticBody3D

@export var objective_id: String = "arc_objective"
@export var display_name: String = "Maintenance control"
@export var objective_kind: String = "fuse"

var body_material: StandardMaterial3D
var indicator_material: StandardMaterial3D
var last_completed: bool = false
var last_available: bool = true

func _ready() -> void:
    _build_visual()
    call_deferred("_refresh_visual")

func _process(_delta: float) -> void:
    var system: Node = get_node_or_null("/root/LabyrinthArc1System")
    if system == null:
        return
    var completed: bool = system.has_method("is_objective_completed") and bool(system.call("is_objective_completed", objective_id))
    var available: bool = system.has_method("is_objective_available") and bool(system.call("is_objective_available", objective_id))
    if completed != last_completed or available != last_available:
        last_completed = completed
        last_available = available
        _apply_visual_state(completed, available)

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/LabyrinthArc1System")
    if system != null:
        if system.has_method("is_objective_completed") and bool(system.call("is_objective_completed", objective_id)):
            return "%s — complete" % display_name
        if system.has_method("get_objective_prompt"):
            return str(system.call("get_objective_prompt", objective_id, display_name))
    return display_name

func interact() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthArc1System")
    if system == null or not system.has_method("request_objective_interaction"):
        return
    system.call("request_objective_interaction", objective_id)

func _refresh_visual() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthArc1System")
    if system == null:
        _apply_visual_state(false, true)
        return
    last_completed = system.has_method("is_objective_completed") and bool(system.call("is_objective_completed", objective_id))
    last_available = system.has_method("is_objective_available") and bool(system.call("is_objective_available", objective_id))
    _apply_visual_state(last_completed, last_available)

func _build_visual() -> void:
    body_material = StandardMaterial3D.new()
    body_material.roughness = 0.72
    body_material.metallic = 0.34

    indicator_material = StandardMaterial3D.new()
    indicator_material.roughness = 0.28
    indicator_material.emission_enabled = true

    var body_mesh: BoxMesh = BoxMesh.new()
    var body_shape: BoxShape3D = BoxShape3D.new()
    var body_size: Vector3 = Vector3(0.56, 0.92, 0.34)

    match objective_kind:
        "valve":
            body_size = Vector3(0.62, 0.78, 0.46)
        "breaker":
            body_size = Vector3(0.52, 0.86, 0.30)
        "console":
            body_size = Vector3(0.92, 1.08, 0.52)
        _:
            body_size = Vector3(0.56, 0.92, 0.34)

    body_mesh.size = body_size
    body_shape.size = body_size

    var body_visual: MeshInstance3D = MeshInstance3D.new()
    body_visual.mesh = body_mesh
    body_visual.material_override = body_material
    body_visual.position.y = body_size.y * 0.5
    add_child(body_visual)

    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = body_shape
    collision.position.y = body_size.y * 0.5
    add_child(collision)

    var indicator_mesh: BoxMesh = BoxMesh.new()
    indicator_mesh.size = Vector3(body_size.x * 0.46, 0.12, 0.05)
    var indicator: MeshInstance3D = MeshInstance3D.new()
    indicator.mesh = indicator_mesh
    indicator.material_override = indicator_material
    indicator.position = Vector3(0.0, body_size.y * 0.67, -(body_size.z * 0.5 + 0.03))
    add_child(indicator)

    if objective_kind == "valve":
        var wheel_mesh: CylinderMesh = CylinderMesh.new()
        wheel_mesh.top_radius = 0.24
        wheel_mesh.bottom_radius = 0.24
        wheel_mesh.height = 0.06
        wheel_mesh.radial_segments = 12
        var wheel: MeshInstance3D = MeshInstance3D.new()
        wheel.mesh = wheel_mesh
        wheel.material_override = indicator_material
        wheel.rotation.x = deg_to_rad(90.0)
        wheel.position = Vector3(0.0, body_size.y * 0.56, -(body_size.z * 0.5 + 0.08))
        add_child(wheel)

    _apply_visual_state(false, true)

func _apply_visual_state(completed: bool, available: bool) -> void:
    if body_material == null or indicator_material == null:
        return

    if completed:
        body_material.albedo_color = Color(0.13, 0.24, 0.17, 1.0)
        indicator_material.albedo_color = Color(0.32, 0.90, 0.48, 1.0)
        indicator_material.emission = Color(0.18, 0.72, 0.34, 1.0)
        indicator_material.emission_energy_multiplier = 1.6
    elif available:
        body_material.albedo_color = Color(0.20, 0.20, 0.18, 1.0)
        indicator_material.albedo_color = Color(0.82, 0.62, 0.18, 1.0)
        indicator_material.emission = Color(0.58, 0.33, 0.05, 1.0)
        indicator_material.emission_energy_multiplier = 1.2
    else:
        body_material.albedo_color = Color(0.12, 0.12, 0.13, 1.0)
        indicator_material.albedo_color = Color(0.20, 0.20, 0.22, 1.0)
        indicator_material.emission = Color(0.03, 0.03, 0.035, 1.0)
        indicator_material.emission_energy_multiplier = 0.25
