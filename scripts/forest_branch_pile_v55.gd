extends StaticBody3D

@export var resource_id: String = "branch_a"

var available_v55: bool = true
var collision_shape_v55: CollisionShape3D

func _ready() -> void:
    add_to_group("renewable_branch")
    _build_visual_v55()

func get_interaction_text() -> String:
    return "Gather Fallen Branches"

func interact() -> void:
    if not available_v55:
        return
    var system: Node = get_node_or_null("/root/RenewableResourceSystem")
    if system != null and system.has_method("request_branch_gather"):
        system.call("request_branch_gather", resource_id, global_position)

func set_available_v55(value: bool) -> void:
    available_v55 = value
    visible = value
    if collision_shape_v55 != null:
        collision_shape_v55.set_deferred("disabled", not value)

func _build_visual_v55() -> void:
    var wood_material: StandardMaterial3D = StandardMaterial3D.new()
    wood_material.albedo_color = Color(0.20, 0.115, 0.052, 1.0)
    wood_material.roughness = 0.98

    for index: int in range(3):
        var branch: MeshInstance3D = MeshInstance3D.new()
        branch.name = "Branch%d" % index
        var mesh: CylinderMesh = CylinderMesh.new()
        mesh.top_radius = 0.055 + float(index) * 0.008
        mesh.bottom_radius = 0.075 + float(index) * 0.008
        mesh.height = 1.10 + float(index) * 0.14
        mesh.radial_segments = 6
        branch.mesh = mesh
        branch.material_override = wood_material
        branch.rotation_degrees = Vector3(0.0, 18.0 + float(index) * 46.0, 82.0 + float(index) * 4.0)
        branch.position = Vector3(-0.18 + float(index) * 0.18, 0.12 + float(index) * 0.035, -0.08 + float(index) * 0.09)
        add_child(branch)

    collision_shape_v55 = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(1.35, 0.42, 0.95)
    collision_shape_v55.shape = shape
    collision_shape_v55.position = Vector3(0.0, 0.20, 0.0)
    add_child(collision_shape_v55)
