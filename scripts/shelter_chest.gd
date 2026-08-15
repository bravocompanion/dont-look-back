extends StaticBody3D

var store_mode: bool = true
var indicator_material: StandardMaterial3D

func _ready() -> void:
    _build_visual()
    _update_indicator()

func get_interaction_text() -> String:
    return "Storage: STORE one supply" if store_mode else "Storage: TAKE one supply"

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var director: Node = get_node_or_null("/root/ShelterSystem")
    if director == null:
        return

    var success: bool = false
    if store_mode and director.has_method("store_one_supply"):
        success = bool(director.call("store_one_supply", player))
    elif not store_mode and director.has_method("take_one_supply"):
        success = bool(director.call("take_one_supply", player))

    store_mode = not store_mode
    _update_indicator()

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null and not success:
        objective.text = "Storage action failed. Mode changed to %s." % ("STORE" if store_mode else "TAKE")

func _update_indicator() -> void:
    if indicator_material == null:
        return
    if store_mode:
        indicator_material.albedo_color = Color(0.18, 0.48, 0.62, 1.0)
        indicator_material.emission = Color(0.06, 0.28, 0.48, 1.0)
    else:
        indicator_material.albedo_color = Color(0.56, 0.42, 0.14, 1.0)
        indicator_material.emission = Color(0.42, 0.26, 0.04, 1.0)

func _build_visual() -> void:
    var body_mesh: BoxMesh = BoxMesh.new()
    body_mesh.size = Vector3(1.35, 0.72, 0.78)

    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.18, 0.11, 0.055, 1.0)
    body_material.roughness = 0.86

    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 0.36, 0.0)
    add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = body_mesh.size
    collision.shape = shape
    collision.position = body.position
    add_child(collision)

    indicator_material = StandardMaterial3D.new()
    indicator_material.emission_enabled = true
    indicator_material.emission_energy_multiplier = 1.6

    var indicator_mesh: BoxMesh = BoxMesh.new()
    indicator_mesh.size = Vector3(0.42, 0.08, 0.04)
    var indicator: MeshInstance3D = MeshInstance3D.new()
    indicator.mesh = indicator_mesh
    indicator.material_override = indicator_material
    indicator.position = Vector3(0.0, 0.62, -0.41)
    add_child(indicator)
