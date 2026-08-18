extends StaticBody3D

@export var interaction_kind: String = "evidence"
@export var interaction_id: String = ""
@export var display_name: String = "Evidence"
@export var visual_size: Vector3 = Vector3(0.52, 0.10, 0.38)
@export var visual_offset: Vector3 = Vector3(0.0, 0.12, 0.0)

func _ready() -> void:
    add_to_group("investigation_interactable")
    _build_visual()
    _build_collision()

func get_interaction_text() -> String:
    var system: Node = get_node_or_null("/root/InvestigationSystem")
    if system != null and system.has_method("get_interaction_text"):
        return str(system.call("get_interaction_text", interaction_kind, interaction_id, display_name))
    return display_name

func interact() -> void:
    var system: Node = get_node_or_null("/root/InvestigationSystem")
    if system != null and system.has_method("interact_with"):
        system.call("interact_with", interaction_kind, interaction_id, self)

func _build_visual() -> void:
    if get_node_or_null("Visual") != null:
        return
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.roughness = 0.82
    match interaction_kind:
        "evidence":
            material.albedo_color = Color(0.42, 0.39, 0.28, 1.0)
        "case_board":
            material.albedo_color = Color(0.18, 0.12, 0.075, 1.0)
        "mine_entrance", "labyrinth_entrance", "forest_return", "facility_route":
            material.albedo_color = Color(0.10, 0.105, 0.105, 1.0)
        _:
            material.albedo_color = Color(0.24, 0.24, 0.22, 1.0)

    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    mesh_instance.name = "Visual"
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = visual_size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    mesh_instance.position = visual_offset
    add_child(mesh_instance)

func _build_collision() -> void:
    if get_node_or_null("CollisionShape3D") != null:
        return
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(
        maxf(0.35, visual_size.x),
        maxf(0.45, visual_size.y + 0.35),
        maxf(0.30, visual_size.z)
    )
    collision.shape = shape
    collision.position = visual_offset
    add_child(collision)
