extends StaticBody3D

var visual_material: StandardMaterial3D

func _ready() -> void:
    _build_visual()

func _process(_delta: float) -> void:
    if visual_material == null:
        return
    var pulse: float = 0.52 + 0.48 * absf(sin(float(Time.get_ticks_msec()) / 260.0))
    visual_material.emission_energy_multiplier = 0.55 + pulse * 0.45

func get_interaction_text() -> String:
    var major: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    if major == null:
        return "Lockdown interlock — offline"
    var count: int = int(major.call("get_isolation_completed_count")) if major.has_method("get_isolation_completed_count") else 0
    return "Lockdown interlock — Isolation %d / 3" % count

func interact() -> void:
    var major: Node = get_node_or_null("/root/LabyrinthMajorSystem")
    var count: int = int(major.call("get_isolation_completed_count")) if major != null and major.has_method("get_isolation_completed_count") else 0
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "ISOLATION SWEEP: shut down all 3 nodes before Lockdown. %d / 3 complete." % count

func _build_visual() -> void:
    visual_material = StandardMaterial3D.new()
    visual_material.albedo_color = Color(0.16, 0.055, 0.045, 1.0)
    visual_material.metallic = 0.60
    visual_material.roughness = 0.48
    visual_material.emission_enabled = true
    visual_material.emission = Color(0.72, 0.08, 0.035, 1.0)
    visual_material.emission_energy_multiplier = 0.80

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(1.65, 1.65, 0.28)
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = visual_material
    visual.position.y = 0.90
    add_child(visual)

    var label: Label3D = Label3D.new()
    label.text = "ISOLATION\nINTERLOCK"
    label.font_size = 24
    label.modulate = Color(0.92, 0.34, 0.22, 1.0)
    label.position = Vector3(0.0, 1.02, -0.17)
    add_child(label)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(1.75, 1.72, 0.38)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    collision.position.y = 0.90
    add_child(collision)
