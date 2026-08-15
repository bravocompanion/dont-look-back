extends StaticBody3D

@export var item_id: String = "canned_food"
@export var display_name: String = "Canned Food"
@export var objective_label_path: NodePath

var collected: bool = false

func _ready() -> void:
    _build_visual()

func get_interaction_text() -> String:
    return "Pick up " + display_name

func interact() -> void:
    if collected:
        return

    var player: Node = get_tree().get_first_node_in_group("player")
    if player == null or not player.has_method("add_item"):
        return

    var accepted: bool = bool(player.call("add_item", item_id, display_name))
    var objective: Label = get_node_or_null(objective_label_path) as Label

    if not accepted:
        if objective != null:
            objective.text = "Inventory full."
        return

    collected = true
    if objective != null:
        objective.text = "%s added to inventory." % display_name
    queue_free()

func _build_visual() -> void:
    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    var collision: CollisionShape3D = CollisionShape3D.new()
    var material: StandardMaterial3D = StandardMaterial3D.new()
    var mesh: BoxMesh = BoxMesh.new()
    var shape: BoxShape3D = BoxShape3D.new()
    var size: Vector3 = Vector3(0.36, 0.26, 0.30)

    match item_id:
        "bottled_water":
            size = Vector3(0.22, 0.48, 0.22)
            material.albedo_color = Color(0.15, 0.32, 0.46, 1.0)
            material.roughness = 0.35
        "medkit":
            size = Vector3(0.46, 0.22, 0.34)
            material.albedo_color = Color(0.60, 0.12, 0.10, 1.0)
            material.roughness = 0.65
        "flashlight_battery":
            size = Vector3(0.16, 0.42, 0.16)
            material.albedo_color = Color(0.72, 0.58, 0.12, 1.0)
            material.metallic = 0.45
            material.roughness = 0.32
        "generator_fuel":
            size = Vector3(0.42, 0.52, 0.24)
            material.albedo_color = Color(0.48, 0.13, 0.08, 1.0)
            material.metallic = 0.30
            material.roughness = 0.46
        "wood":
            size = Vector3(0.72, 0.16, 0.20)
            material.albedo_color = Color(0.28, 0.15, 0.065, 1.0)
            material.roughness = 0.96
        "scrap":
            size = Vector3(0.38, 0.12, 0.34)
            material.albedo_color = Color(0.27, 0.29, 0.28, 1.0)
            material.metallic = 0.72
            material.roughness = 0.42
        _:
            material.albedo_color = Color(0.42, 0.35, 0.16, 1.0)
            material.metallic = 0.2
            material.roughness = 0.58

    mesh.size = size
    shape.size = size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    collision.shape = shape

    mesh_instance.position.y = size.y * 0.5
    collision.position.y = size.y * 0.5
    add_child(mesh_instance)
    add_child(collision)
