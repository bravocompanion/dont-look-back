extends StaticBody3D

@export var choice_id: String = "distress_signal"
@export var display_name: String = "Distress Routing Terminal"

var indicator_material: StandardMaterial3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    var payoff: Node = get_node_or_null("/root/ResearchFacilityPayoffSystem")
    if payoff != null and payoff.has_method("get_choice_prompt_v61"):
        return str(payoff.call("get_choice_prompt_v61", choice_id, display_name))
    return display_name

func interact() -> void:
    var payoff: Node = get_node_or_null("/root/ResearchFacilityPayoffSystem")
    if payoff != null and payoff.has_method("request_choice_v61"):
        payoff.call("request_choice_v61", choice_id)

func set_selected_v61(selected: bool, locked: bool) -> void:
    if indicator_material == null:
        return
    if selected:
        indicator_material.albedo_color = Color(0.12, 0.62, 0.45, 1.0)
        indicator_material.emission = Color(0.08, 0.58, 0.36, 1.0)
        indicator_material.emission_energy_multiplier = 3.0
    elif locked:
        indicator_material.albedo_color = Color(0.18, 0.18, 0.18, 1.0)
        indicator_material.emission = Color(0.04, 0.04, 0.04, 1.0)
        indicator_material.emission_energy_multiplier = 0.5
    else:
        indicator_material.albedo_color = Color(0.18, 0.34, 0.48, 1.0)
        indicator_material.emission = Color(0.06, 0.26, 0.48, 1.0)
        indicator_material.emission_energy_multiplier = 1.8

func _build_visual() -> void:
    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.075, 0.08, 0.085, 1.0)
    body_material.metallic = 0.55
    body_material.roughness = 0.42

    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(1.15, 1.25, 0.52)
    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 0.63, 0.0)
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
    panel_mesh.size = Vector3(0.70, 0.34, 0.035)
    var panel: MeshInstance3D = MeshInstance3D.new()
    panel.mesh = panel_mesh
    panel.material_override = indicator_material
    panel.position = Vector3(0.0, 0.77, -0.28)
    add_child(panel)

    var label: Label3D = Label3D.new()
    label.position = Vector3(0.0, 1.55, 0.0)
    label.text = "RESCUE PRIORITY" if choice_id == "distress_signal" else "ANOMALY PRIORITY"
    label.font_size = 24
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    add_child(label)
    set_selected_v61(false, false)
