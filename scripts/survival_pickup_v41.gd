extends "res://scripts/survival_pickup.gd"

func _build_visual() -> void:
    if item_id not in ["plastic_sheet", "rubber", "electronics", "lead_plate", "copper_wire", "filter"]:
        super._build_visual()
        return

    var size: Vector3 = Vector3(0.38, 0.18, 0.34)
    var color: Color = Color(0.38, 0.40, 0.38, 1.0)
    var metallic: float = 0.15
    var roughness: float = 0.65

    match item_id:
        "plastic_sheet":
            size = Vector3(0.52, 0.06, 0.42)
            color = Color(0.18, 0.34, 0.42, 1.0)
            metallic = 0.0
            roughness = 0.48
        "rubber":
            size = Vector3(0.40, 0.16, 0.32)
            color = Color(0.07, 0.075, 0.07, 1.0)
            metallic = 0.0
            roughness = 0.90
        "electronics":
            size = Vector3(0.34, 0.13, 0.30)
            color = Color(0.08, 0.32, 0.18, 1.0)
            metallic = 0.28
            roughness = 0.45
        "lead_plate":
            size = Vector3(0.48, 0.09, 0.38)
            color = Color(0.30, 0.32, 0.34, 1.0)
            metallic = 0.82
            roughness = 0.55
        "copper_wire":
            size = Vector3(0.30, 0.18, 0.30)
            color = Color(0.55, 0.24, 0.08, 1.0)
            metallic = 0.68
            roughness = 0.38
        "filter":
            size = Vector3(0.30, 0.34, 0.30)
            color = Color(0.30, 0.33, 0.25, 1.0)
            metallic = 0.12
            roughness = 0.78

    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = color
    material.metallic = metallic
    material.roughness = roughness
    mesh_instance.material_override = material
    mesh_instance.position.y = size.y * 0.5
    add_child(mesh_instance)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    collision.position.y = size.y * 0.5
    add_child(collision)
