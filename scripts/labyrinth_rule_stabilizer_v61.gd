extends StaticBody3D

@export var stabilizer_id: int = 0
@export var display_name: String = "Archive Stabilizer"

var indicator_material: StandardMaterial3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    var rules: Node = get_node_or_null("/root/LabyrinthGameplayRules")
    if rules != null and rules.has_method("get_stabilizer_prompt_v61"):
        return str(rules.call("get_stabilizer_prompt_v61", stabilizer_id, display_name))
    return display_name

func interact() -> void:
    var rules: Node = get_node_or_null("/root/LabyrinthGameplayRules")
    if rules != null and rules.has_method("request_stabilizer_v61"):
        rules.call("request_stabilizer_v61", stabilizer_id)

func set_active_visual_v61(active: bool, owner_peer: int = 0) -> void:
    if indicator_material == null:
        return
    if active:
        indicator_material.albedo_color = Color(0.12, 0.64, 0.76, 1.0)
        indicator_material.emission = Color(0.08, 0.56, 0.82, 1.0)
        indicator_material.emission_energy_multiplier = 3.0
    else:
        indicator_material.albedo_color = Color(0.46, 0.12, 0.08, 1.0)
        indicator_material.emission = Color(0.32, 0.025, 0.015, 1.0)
        indicator_material.emission_energy_multiplier = 1.35
    var label: Label3D = get_node_or_null("Status") as Label3D
    if label != null:
        label.text = "STABLE • P%d" % owner_peer if active and owner_peer > 0 else "STABILIZE"

func _build_visual() -> void:
    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.075, 0.085, 0.095, 1.0)
    body_material.metallic = 0.58
    body_material.roughness = 0.44

    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(0.82, 1.18, 0.48)
    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 0.59, 0.0)
    add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = body_mesh.size
    collision.shape = shape
    collision.position = body.position
    add_child(collision)

    indicator_material = StandardMaterial3D.new()
    indicator_material.emission_enabled = true
    var panel_mesh: BoxMesh = BoxMesh.new()
    panel_mesh.size = Vector3(0.46, 0.22, 0.035)
    var panel: MeshInstance3D = MeshInstance3D.new()
    panel.mesh = panel_mesh
    panel.material_override = indicator_material
    panel.position = Vector3(0.0, 0.76, -0.255)
    add_child(panel)

    var label: Label3D = Label3D.new()
    label.name = "Status"
    label.text = "STABILIZE"
    label.position = Vector3(0.0, 1.36, 0.0)
    label.font_size = 22
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)
    set_active_visual_v61(false)
