extends "res://scripts/forest_world_expansion_v8.gd"

# v0.74.4 — explicit opaque terrain/trail materials.
# Materials are stored as .tres resources and force-applied to both the ArrayMesh
# surface and MeshInstance3D override so legacy/runtime material state cannot make
# the ground transparent or invisible. v0.74.3 traversal smoothing and all
# v0.74.2 falloff hardening remain unchanged.

const V744_TERRAIN_MATERIAL_PATH: String = "res://assets/materials/terrain/forest_ground_opaque_v744.tres"
const V744_TRAIL_MATERIAL_PATH: String = "res://assets/materials/terrain/forest_trail_opaque_v744.tres"

func _build_mega_ground() -> void:
    super._build_mega_ground()
    _configure_opaque_terrain_material_v744()

func _configure_opaque_terrain_material_v744() -> void:
    if world_root == null:
        return

    var terrain: StaticBody3D = world_root.get_node_or_null("ForestTerrainV74") as StaticBody3D
    if terrain == null:
        return

    var mesh_instance: MeshInstance3D = terrain.get_node_or_null("TerrainMesh") as MeshInstance3D
    if mesh_instance == null or mesh_instance.mesh == null:
        return

    var terrain_mesh: ArrayMesh = mesh_instance.mesh as ArrayMesh
    if terrain_mesh == null or terrain_mesh.get_surface_count() <= 0:
        return

    var material: StandardMaterial3D = _load_opaque_material_v744(
        V744_TERRAIN_MATERIAL_PATH,
        Color(0.18, 0.225, 0.145, 1.0),
        0.96,
        0.12
    )

    # Force opaque render state even if the .tres is edited incorrectly later.
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    var terrain_color: Color = material.albedo_color
    terrain_color.a = 1.0
    material.albedo_color = terrain_color

    terrain_mesh.surface_set_material(0, material)
    mesh_instance.set_surface_override_material(0, material)
    mesh_instance.material_overlay = null
    mesh_instance.transparency = 0.0
    mesh_instance.visible = true
    mesh_instance.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON

    terrain.set_meta("terrain_material_revision", "0.74.4")
    terrain.set_meta("terrain_material_opaque", true)
    terrain.set_meta("terrain_material_path", V744_TERRAIN_MATERIAL_PATH)

func _build_long_distance_trails() -> void:
    var trail_material: StandardMaterial3D = _load_opaque_material_v744(
        V744_TRAIL_MATERIAL_PATH,
        Color(0.30, 0.235, 0.145, 1.0),
        0.98,
        0.10
    )

    _add_conforming_trail_v743("TrailCabinToHouse", Vector2(14.0, -67.0), Vector2(HOUSE_CENTER.x, HOUSE_CENTER.z), 3.2, trail_material)
    _add_conforming_trail_v743("TrailHouseToGas", Vector2(HOUSE_CENTER.x, HOUSE_CENTER.z), Vector2(GAS_CENTER.x, GAS_CENTER.z), 2.8, trail_material)
    _add_conforming_trail_v743("TrailGasToWarehouse", Vector2(GAS_CENTER.x, GAS_CENTER.z), Vector2(WAREHOUSE_CENTER.x, WAREHOUSE_CENTER.z), 2.7, trail_material)
    _add_conforming_trail_v743("TrailWarehouseToMine", Vector2(WAREHOUSE_CENTER.x, WAREHOUSE_CENTER.z), Vector2(V74_MINE_CENTER.x, V74_MINE_CENTER.z), 2.6, trail_material)
    _add_conforming_trail_v743("TrailMineToPumpOptional", Vector2(V74_MINE_CENTER.x, V74_MINE_CENTER.z), Vector2(PUMP_CENTER.x, PUMP_CENTER.z), 2.4, trail_material)

func _load_opaque_material_v744(
    path: String,
    fallback_color: Color,
    fallback_roughness: float,
    fallback_specular: float
) -> StandardMaterial3D:
    var material: StandardMaterial3D = null
    var loaded: Resource = load(path)
    if loaded is StandardMaterial3D:
        material = (loaded as StandardMaterial3D).duplicate(true) as StandardMaterial3D

    if material == null:
        material = StandardMaterial3D.new()
        material.albedo_color = fallback_color
        material.roughness = fallback_roughness
        material.metallic = 0.0
        material.metallic_specular = fallback_specular

    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.metallic = 0.0
    var color_value: Color = material.albedo_color
    color_value.a = 1.0
    material.albedo_color = color_value
    return material

func get_terrain_material_contract_v744() -> Dictionary:
    var terrain_ready: bool = false
    var terrain_material_ok: bool = false
    var terrain_override_ok: bool = false

    if world_root != null:
        var terrain: StaticBody3D = world_root.get_node_or_null("ForestTerrainV74") as StaticBody3D
        if terrain != null:
            var mesh_instance: MeshInstance3D = terrain.get_node_or_null("TerrainMesh") as MeshInstance3D
            if mesh_instance != null and mesh_instance.mesh != null:
                terrain_ready = mesh_instance.visible and is_zero_approx(mesh_instance.transparency)
                var surface_material: Material = mesh_instance.mesh.surface_get_material(0)
                var override_material: Material = mesh_instance.get_surface_override_material(0)
                terrain_material_ok = _material_is_opaque_v744(surface_material)
                terrain_override_ok = _material_is_opaque_v744(override_material)

    return {
        "revision": "0.74.4",
        "terrain_material_path": V744_TERRAIN_MATERIAL_PATH,
        "trail_material_path": V744_TRAIL_MATERIAL_PATH,
        "terrain_visible": terrain_ready,
        "surface_material_opaque": terrain_material_ok,
        "override_material_opaque": terrain_override_ok,
        "double_sided": true,
        "alpha": 1.0,
        "traversal_v743_preserved": true,
        "falloff_v742_preserved": true
    }

func _material_is_opaque_v744(material: Material) -> bool:
    if not (material is StandardMaterial3D):
        return false
    var standard: StandardMaterial3D = material as StandardMaterial3D
    return (
        standard.transparency == BaseMaterial3D.TRANSPARENCY_DISABLED
        and standard.cull_mode == BaseMaterial3D.CULL_DISABLED
        and standard.albedo_color.a >= 0.999
    )

func get_forest_map_contract_v74() -> Dictionary:
    var contract: Dictionary = super.get_forest_map_contract_v74()
    contract["revision"] = "0.74.4"
    contract["terrain_material"] = V744_TERRAIN_MATERIAL_PATH
    contract["trail_material"] = V744_TRAIL_MATERIAL_PATH
    contract["terrain_opaque"] = true
    return contract
