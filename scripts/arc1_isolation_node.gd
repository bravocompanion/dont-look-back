extends StaticBody3D

@export var node_id: String = "isolation_maintenance"
@export var display_name: String = "Maintenance Isolation Node"

var visual_material: StandardMaterial3D
var indicator: OmniLight3D
var cached_state: int = -1

func _ready() -> void:
    _build_visual()
    _refresh_visual()

func _process(_delta: float) -> void:
    _refresh_visual()

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    if system != null and system.has_method("get_isolation_prompt"):
        return str(system.call("get_isolation_prompt", node_id, display_name))
    return "Use %s" % display_name

func interact() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    if system == null or not system.has_method("request_isolation_node"):
        return
    system.call("request_isolation_node", node_id)

func _refresh_visual() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    if system == null or not system.has_method("get_isolation_visual_state"):
        return
    var state: int = int(system.call("get_isolation_visual_state", node_id))
    if state == cached_state:
        return
    cached_state = state

    if visual_material == null or indicator == null:
        return

    if state >= 2:
        visual_material.albedo_color = Color(0.055, 0.085, 0.065, 1.0)
        visual_material.emission = Color(0.08, 0.32, 0.12, 1.0)
        visual_material.emission_energy_multiplier = 0.75
        indicator.light_color = Color(0.20, 0.62, 0.28, 1.0)
        indicator.light_energy = 0.055
    elif state == 1:
        visual_material.albedo_color = Color(0.22, 0.075, 0.055, 1.0)
        visual_material.emission = Color(0.92, 0.12, 0.06, 1.0)
        visual_material.emission_energy_multiplier = 1.45
        indicator.light_color = Color(0.95, 0.16, 0.08, 1.0)
        indicator.light_energy = 0.09
    else:
        visual_material.albedo_color = Color(0.075, 0.08, 0.085, 1.0)
        visual_material.emission = Color(0.025, 0.035, 0.04, 1.0)
        visual_material.emission_energy_multiplier = 0.22
        indicator.light_color = Color(0.16, 0.20, 0.22, 1.0)
        indicator.light_energy = 0.035

func _build_visual() -> void:
    visual_material = StandardMaterial3D.new()
    visual_material.roughness = 0.58
    visual_material.metallic = 0.46
    visual_material.emission_enabled = true

    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(0.92, 1.32, 0.34)
    var body: MeshInstance3D = MeshInstance3D.new()
    body.name = "IsolationNodeVisual"
    body.mesh = body_mesh
    body.material_override = visual_material
    body.position.y = 0.72
    add_child(body)

    var ring_mesh: CylinderMesh = CylinderMesh.new()
    ring_mesh.top_radius = 0.20
    ring_mesh.bottom_radius = 0.20
    ring_mesh.height = 0.10
    ring_mesh.radial_segments = 12
    var ring: MeshInstance3D = MeshInstance3D.new()
    ring.name = "IsolationCore"
    ring.mesh = ring_mesh
    ring.material_override = visual_material
    ring.rotation.x = deg_to_rad(90.0)
    ring.position = Vector3(0.0, 0.83, -0.21)
    add_child(ring)

    var label: Label3D = Label3D.new()
    label.name = "IsolationLabel"
    label.text = "ISOLATION"
    label.font_size = 24
    label.modulate = Color(0.72, 0.74, 0.72, 1.0)
    label.position = Vector3(0.0, 1.18, -0.20)
    add_child(label)

    indicator = OmniLight3D.new()
    indicator.name = "Indicator"
    indicator.position = Vector3(0.0, 0.84, -0.28)
    indicator.omni_range = 1.35
    indicator.shadow_enabled = false
    add_child(indicator)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(1.0, 1.42, 0.46)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    collision.shape = shape
    collision.position.y = 0.72
    add_child(collision)
