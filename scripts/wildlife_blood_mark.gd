extends Node3D

@export var lifetime_seconds: float = 28.0
var remaining: float = 28.0

func _ready() -> void:
    remaining = lifetime_seconds
    _build_visual()

func _process(delta: float) -> void:
    remaining = maxf(0.0, remaining - delta)
    var mesh: MeshInstance3D = get_node_or_null("BloodMark") as MeshInstance3D
    if mesh != null and mesh.material_override is StandardMaterial3D:
        var material: StandardMaterial3D = mesh.material_override as StandardMaterial3D
        var fade_start: float = minf(8.0, lifetime_seconds * 0.35)
        if remaining < fade_start:
            var alpha: float = clampf(remaining / maxf(0.01, fade_start), 0.0, 1.0)
            var color: Color = material.albedo_color
            color.a = 0.72 * alpha
            material.albedo_color = color
    if remaining <= 0.0:
        queue_free()

func _build_visual() -> void:
    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    mesh_instance.name = "BloodMark"
    var mesh: CylinderMesh = CylinderMesh.new()
    mesh.top_radius = 0.24
    mesh.bottom_radius = 0.30
    mesh.height = 0.018
    mesh.radial_segments = 12
    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.22, 0.012, 0.015, 0.72)
    material.roughness = 0.96
    material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    mesh_instance.scale = Vector3(1.0, 1.0, 0.72)
    add_child(mesh_instance)
