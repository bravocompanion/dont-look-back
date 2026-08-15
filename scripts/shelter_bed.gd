extends StaticBody3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    return "Sleep until morning"

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var director: Node = get_node_or_null("/root/ShelterSystem")
    if director == null or not director.has_method("sleep_until_morning"):
        return

    director.call("sleep_until_morning", player)

func _build_visual() -> void:
    var frame_material: StandardMaterial3D = StandardMaterial3D.new()
    frame_material.albedo_color = Color(0.16, 0.10, 0.06, 1.0)
    frame_material.roughness = 0.9

    var mattress_material: StandardMaterial3D = StandardMaterial3D.new()
    mattress_material.albedo_color = Color(0.24, 0.25, 0.22, 1.0)
    mattress_material.roughness = 0.96

    var frame_mesh: BoxMesh = BoxMesh.new()
    frame_mesh.size = Vector3(1.05, 0.28, 2.05)
    var frame: MeshInstance3D = MeshInstance3D.new()
    frame.mesh = frame_mesh
    frame.material_override = frame_material
    frame.position = Vector3(0.0, 0.24, 0.0)
    add_child(frame)

    var mattress_mesh: BoxMesh = BoxMesh.new()
    mattress_mesh.size = Vector3(0.94, 0.20, 1.90)
    var mattress: MeshInstance3D = MeshInstance3D.new()
    mattress.mesh = mattress_mesh
    mattress.material_override = mattress_material
    mattress.position = Vector3(0.0, 0.46, 0.0)
    add_child(mattress)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(1.05, 0.56, 2.05)
    collision.shape = shape
    collision.position = Vector3(0.0, 0.28, 0.0)
    add_child(collision)
