extends StaticBody3D

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    return "Boil Dirty Water"

func interact() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var depth: Node = get_node_or_null("/root/SurvivalDepthSystem")
    if depth == null or not depth.has_method("boil_water"):
        return
    depth.call("boil_water", player)

func _build_visual() -> void:
    var dark_metal: StandardMaterial3D = StandardMaterial3D.new()
    dark_metal.albedo_color = Color(0.10, 0.11, 0.11, 1.0)
    dark_metal.metallic = 0.72
    dark_metal.roughness = 0.42

    var rim_metal: StandardMaterial3D = StandardMaterial3D.new()
    rim_metal.albedo_color = Color(0.28, 0.29, 0.27, 1.0)
    rim_metal.metallic = 0.82
    rim_metal.roughness = 0.30

    var pot_mesh: CylinderMesh = CylinderMesh.new()
    pot_mesh.top_radius = 0.44
    pot_mesh.bottom_radius = 0.38
    pot_mesh.height = 0.42
    pot_mesh.radial_segments = 14
    var pot: MeshInstance3D = MeshInstance3D.new()
    pot.mesh = pot_mesh
    pot.material_override = dark_metal
    pot.position = Vector3(0.0, 0.34, 0.0)
    add_child(pot)

    var lid_mesh: CylinderMesh = CylinderMesh.new()
    lid_mesh.top_radius = 0.46
    lid_mesh.bottom_radius = 0.46
    lid_mesh.height = 0.07
    lid_mesh.radial_segments = 14
    var lid: MeshInstance3D = MeshInstance3D.new()
    lid.mesh = lid_mesh
    lid.material_override = rim_metal
    lid.position = Vector3(0.0, 0.57, 0.0)
    add_child(lid)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: CylinderShape3D = CylinderShape3D.new()
    shape.radius = 0.50
    shape.height = 0.64
    collision.shape = shape
    collision.position = Vector3(0.0, 0.32, 0.0)
    add_child(collision)
