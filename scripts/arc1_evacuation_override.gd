extends StaticBody3D

@export var override_id: String = "archive_override"
@export var display_name: String = "Emergency Override"

var body_material: StandardMaterial3D
var indicator: OmniLight3D
var cached_state: int = -1

func _ready() -> void:
    _build_visual()
    _refresh_visual()

func _process(_delta: float) -> void:
    _refresh_visual()

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/LabyrinthEvacuationSystem")
    if system != null and system.has_method("get_override_prompt"):
        return str(system.call("get_override_prompt", override_id, display_name))
    return display_name

func interact() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthEvacuationSystem")
    if system == null or not system.has_method("request_override_activation"):
        return
    system.call("request_override_activation", override_id)

func _refresh_visual() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthEvacuationSystem")
    if system == null or not system.has_method("get_override_visual_state"):
        return
    var state: int = int(system.call("get_override_visual_state", override_id))
    if state == cached_state:
        return
    cached_state = state

    if body_material == null or indicator == null:
        return
    if state >= 2:
        body_material.albedo_color = Color(0.08, 0.24, 0.13, 1.0)
        body_material.emission = Color(0.12, 0.82, 0.30, 1.0)
        body_material.emission_energy_multiplier = 1.45
        indicator.light_color = Color(0.22, 0.92, 0.38, 1.0)
        indicator.light_energy = 0.09
    elif state == 1:
        body_material.albedo_color = Color(0.28, 0.10, 0.045, 1.0)
        body_material.emission = Color(0.92, 0.18, 0.045, 1.0)
        body_material.emission_energy_multiplier = 1.60
        indicator.light_color = Color(1.0, 0.24, 0.06, 1.0)
        indicator.light_energy = 0.09
    else:
        body_material.albedo_color = Color(0.11, 0.11, 0.12, 1.0)
        body_material.emission = Color(0.05, 0.025, 0.02, 1.0)
        body_material.emission_energy_multiplier = 0.25
        indicator.light_color = Color(0.22, 0.10, 0.06, 1.0)
        indicator.light_energy = 0.035

func _build_visual() -> void:
    body_material = StandardMaterial3D.new()
    body_material.roughness = 0.62
    body_material.metallic = 0.52
    body_material.emission_enabled = true

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(0.86, 1.12, 0.30)
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.name = "OverrideVisual"
    visual.mesh = mesh
    visual.material_override = body_material
    visual.position.y = 0.60
    add_child(visual)

    var label: Label3D = Label3D.new()
    label.name = "OverrideLabel"
    label.text = "EVAC OVERRIDE"
    label.font_size = 24
    label.modulate = Color(0.88, 0.75, 0.66, 1.0)
    label.position = Vector3(0.0, 0.74, -0.17)
    add_child(label)

    indicator = OmniLight3D.new()
    indicator.name = "Indicator"
    indicator.position = Vector3(0.0, 0.98, -0.22)
    indicator.omni_range = 1.35
    indicator.shadow_enabled = false
    add_child(indicator)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(0.94, 1.18, 0.38)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 0.60
    add_child(collision)

    _refresh_visual()
