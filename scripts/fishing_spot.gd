extends StaticBody3D

@export var spot_id: String = "forest_pond_a"

func _ready() -> void:
    _build_visual()
    _build_collision()

func get_interaction_text() -> String:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null and player.has_method("has_item") and not bool(player.call("has_item", "fishing_rod")):
        return "Fishing spot — but you need a Fishing Rod"
    return "Fish here"

func interact() -> void:
    var system: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if system != null and system.has_method("request_fishing"):
        system.call("request_fishing", spot_id)

func _build_visual() -> void:
    var ring: MeshInstance3D = MeshInstance3D.new()
    ring.name = "WaterMarker"
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = 1.15
    mesh.bottom_radius = 1.15
    mesh.height = 0.025
    mesh.radial_segments = 24
    ring.mesh = mesh
    ring.position = Vector3(0.0, 0.025, 0.0)

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.08, 0.18, 0.22, 0.72)
    material.metallic = 0.05
    material.roughness = 0.28
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    ring.material_override = material
    add_child(ring)

func _build_collision() -> void:
    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: CylinderShape3D = CylinderShape3D.new()
    shape.radius = 1.25
    shape.height = 0.20
    collision.shape = shape
    collision.position = Vector3(0.0, 0.10, 0.0)
    add_child(collision)
