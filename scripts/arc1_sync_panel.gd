extends StaticBody3D

@export var station_id: String = "maintenance_sync"
@export var panel_id: String = "a"
@export var display_name: String = "Maintenance SYNC A"

var visual_material: StandardMaterial3D
var indicator: OmniLight3D
var collision_shape: CollisionShape3D
var cached_state: int = -1

func _ready() -> void:
    _build_visual()
    _refresh_visual()

func _process(_delta: float) -> void:
    _refresh_visual()

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/LabyrinthCoopSystem")
    if system != null and system.has_method("get_panel_prompt"):
        return str(system.call("get_panel_prompt", station_id, panel_id, display_name))
    return "Use %s" % display_name

func interact() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthCoopSystem")
    if system == null or not system.has_method("request_panel_activation"):
        return
    system.call("request_panel_activation", station_id, panel_id)

func _refresh_visual() -> void:
    var system: Node = get_node_or_null("/root/LabyrinthCoopSystem")
    if system == null or not system.has_method("get_panel_visual_state"):
        return
    var state: int = int(system.call("get_panel_visual_state", station_id, panel_id))
    if state == cached_state:
        return
    cached_state = state

    if visual_material == null or indicator == null:
        return

    if state >= 2:
        visual_material.albedo_color = Color(0.10, 0.28, 0.14, 1.0)
        visual_material.emission = Color(0.18, 0.78, 0.32, 1.0)
        visual_material.emission_energy_multiplier = 1.4
        indicator.light_color = Color(0.28, 0.92, 0.42, 1.0)
        indicator.light_energy = 0.09
    elif state == 1:
        visual_material.albedo_color = Color(0.28, 0.20, 0.06, 1.0)
        visual_material.emission = Color(0.92, 0.58, 0.10, 1.0)
        visual_material.emission_energy_multiplier = 1.6
        indicator.light_color = Color(0.96, 0.62, 0.12, 1.0)
        indicator.light_energy = 0.09
    else:
        visual_material.albedo_color = Color(0.12, 0.13, 0.13, 1.0)
        visual_material.emission = Color(0.05, 0.09, 0.09, 1.0)
        visual_material.emission_energy_multiplier = 0.35
        indicator.light_color = Color(0.20, 0.28, 0.28, 1.0)
        indicator.light_energy = 0.045

func _build_visual() -> void:
    visual_material = StandardMaterial3D.new()
    visual_material.roughness = 0.62
    visual_material.metallic = 0.42
    visual_material.emission_enabled = true

    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(0.78, 1.02, 0.24)
    var body: MeshInstance3D = MeshInstance3D.new()
    body.name = "PanelVisual"
    body.mesh = body_mesh
    body.material_override = visual_material
    body.position.y = 0.58
    add_child(body)

    var label: Label3D = Label3D.new()
    label.name = "PanelLabel"
    label.text = "SYNC %s" % panel_id.to_upper()
    label.font_size = 26
    label.modulate = Color(0.78, 0.82, 0.80, 1.0)
    label.position = Vector3(0.0, 0.66, -0.14)
    add_child(label)

    indicator = OmniLight3D.new()
    indicator.name = "Indicator"
    indicator.position = Vector3(0.0, 0.90, -0.20)
    indicator.omni_range = 1.25
    indicator.shadow_enabled = false
    add_child(indicator)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(0.86, 1.10, 0.32)
    collision_shape = CollisionShape3D.new()
    collision_shape.shape = shape
    collision_shape.position.y = 0.58
    add_child(collision_shape)
