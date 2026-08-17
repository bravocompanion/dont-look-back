extends StaticBody3D

@export var carcass_id: String = "carcass"
@export var animal_kind: String = "deer"
var harvested: bool = false

func _ready() -> void:
    add_to_group("wildlife_carcass")
    call_deferred("_finish_setup")

func _finish_setup() -> void:
    if not is_inside_tree():
        return
    _build_visual()
    _build_collision()
    set_harvested(harvested)

func configure(id_value: String, kind_value: String) -> void:
    carcass_id = id_value
    animal_kind = kind_value

func get_interaction_text() -> String:
    if harvested:
        return "Carcass already harvested"
    return "Harvest %s carcass (Hunting Knife)" % animal_kind.capitalize()

func interact() -> void:
    if harvested:
        return
    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system != null and system.has_method("request_harvest"):
        system.call("request_harvest", carcass_id)

func set_harvested(value: bool) -> void:
    harvested = value
    visible = not harvested
    var collision: CollisionShape3D = get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision != null:
        collision.disabled = harvested

func _build_visual() -> void:
    if get_node_or_null("CarcassBody") != null:
        return
    var material: StandardMaterial3D = StandardMaterial3D.new()
    match animal_kind:
        "rabbit": material.albedo_color = Color(0.34, 0.31, 0.28, 1.0)
        "boar": material.albedo_color = Color(0.12, 0.085, 0.065, 1.0)
        "wolf": material.albedo_color = Color(0.20, 0.20, 0.21, 1.0)
        _: material.albedo_color = Color(0.25, 0.15, 0.085, 1.0)
    material.roughness = 1.0

    var body: MeshInstance3D = MeshInstance3D.new()
    body.name = "CarcassBody"
    var mesh: CapsuleMesh = CapsuleMesh.new()
    var scale_value: Vector3 = Vector3(1.2, 0.55, 1.6)
    if animal_kind == "rabbit":
        mesh.radius = 0.18
        mesh.height = 0.45
        scale_value = Vector3(0.85, 0.55, 1.15)
    elif animal_kind == "boar":
        mesh.radius = 0.34
        mesh.height = 0.95
    elif animal_kind == "wolf":
        mesh.radius = 0.28
        mesh.height = 0.92
    else:
        mesh.radius = 0.32
        mesh.height = 1.10
    body.mesh = mesh
    body.material_override = material
    body.position = Vector3(0.0, 0.24, 0.0)
    body.rotation_degrees = Vector3(0.0, 0.0, 90.0)
    body.scale = scale_value
    add_child(body)

func _build_collision() -> void:
    if get_node_or_null("CollisionShape3D") != null:
        return
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.name = "CollisionShape3D"
    var shape: BoxShape3D = BoxShape3D.new()
    if animal_kind == "rabbit":
        shape.size = Vector3(0.65, 0.40, 0.55)
        collision.position = Vector3(0.0, 0.20, 0.0)
    else:
        shape.size = Vector3(1.45, 0.62, 0.82)
        collision.position = Vector3(0.0, 0.31, 0.0)
    collision.shape = shape
    add_child(collision)
