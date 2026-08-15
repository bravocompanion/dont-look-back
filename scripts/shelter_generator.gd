extends StaticBody3D

@export var display_name: String = "Shelter Generator"

var powered: bool = false
var indicator_material: StandardMaterial3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    if powered:
        return display_name + " online"
    return "Start " + display_name + " (Fuel Can)"

func interact() -> void:
    if powered:
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var director: Node = get_node_or_null("/root/OutsideDirector")
    if director == null or not director.has_method("activate_shelter"):
        return

    var accepted: bool = bool(director.call("activate_shelter", player))
    if not accepted:
        return

    powered = true
    _set_indicator(true)

func set_powered_from_restore(value: bool) -> void:
    powered = value
    _set_indicator(value)

func _set_indicator(value: bool) -> void:
    if indicator_material == null:
        return
    if value:
        indicator_material.albedo_color = Color(0.18, 0.65, 0.34, 1.0)
        indicator_material.emission = Color(0.10, 0.55, 0.24, 1.0)
        indicator_material.emission_energy_multiplier = 2.4
    else:
        indicator_material.albedo_color = Color(0.55, 0.10, 0.07, 1.0)
        indicator_material.emission = Color(0.42, 0.03, 0.02, 1.0)
        indicator_material.emission_energy_multiplier = 1.5

func _build_visual() -> void:
    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(1.15, 0.82, 0.70)

    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.12, 0.13, 0.12, 1.0)
    body_material.metallic = 0.42
    body_material.roughness = 0.58

    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 0.48, 0.0)
    add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = body_mesh.size
    collision.shape = shape
    collision.position = body.position
    add_child(collision)

    var indicator_mesh: BoxMesh = BoxMesh.new()
    indicator_mesh.size = Vector3(0.36, 0.14, 0.05)

    indicator_material = StandardMaterial3D.new()
    indicator_material.emission_enabled = true
    _set_indicator(false)

    var indicator: MeshInstance3D = MeshInstance3D.new()
    indicator.mesh = indicator_mesh
    indicator.material_override = indicator_material
    indicator.position = Vector3(0.0, 0.62, -0.38)
    add_child(indicator)
