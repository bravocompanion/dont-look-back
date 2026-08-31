extends "res://scripts/forest_world_expansion_v10.gd"

# v0.74.6 — natural pathless terrain color variation.
# Terrain remains a single opaque ArrayMesh/trimesh. Natural ground color is
# authored per vertex from elevation, slope, and deterministic broad/detail
# variation only. Route data is deliberately never sampled by the color pass,
# so traversal smoothing cannot become a visible painted road.

const V746_MOSS_COLOR: Color = Color(0.155, 0.205, 0.105, 1.0)
const V746_LEAF_COLOR: Color = Color(0.205, 0.160, 0.080, 1.0)
const V746_WET_COLOR: Color = Color(0.095, 0.145, 0.085, 1.0)
const V746_SOIL_COLOR: Color = Color(0.180, 0.125, 0.065, 1.0)
const V746_ROCK_COLOR: Color = Color(0.220, 0.215, 0.170, 1.0)

func _build_mega_ground() -> void:
    super._build_mega_ground()
    _configure_natural_vertex_color_material_v746()

func _create_terrain_mesh_v74() -> ArrayMesh:
    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    var colors: PackedColorArray = PackedColorArray()
    var uvs: PackedVector2Array = PackedVector2Array()
    var indices: PackedInt32Array = PackedInt32Array()

    for row: int in range(V743_TERRAIN_ROWS + 1):
        var tz: float = float(row) / float(V743_TERRAIN_ROWS)
        var z: float = lerpf(V74_MAP_NEAR_Z, V74_MAP_FAR_Z, tz)
        for column: int in range(V743_TERRAIN_COLUMNS + 1):
            var tx: float = float(column) / float(V743_TERRAIN_COLUMNS)
            var x: float = lerpf(V74_MAP_MIN_X, V74_MAP_MAX_X, tx)
            var y: float = sample_terrain_height_v74(x, z)
            var normal: Vector3 = _terrain_normal_v74(x, z)
            vertices.append(Vector3(x, y, z))
            normals.append(normal)
            colors.append(_sample_natural_ground_color_v746(x, z, y, normal))
            uvs.append(Vector2(tx * 18.0, tz * 24.0))

    var stride: int = V743_TERRAIN_COLUMNS + 1
    for row: int in range(V743_TERRAIN_ROWS):
        for column: int in range(V743_TERRAIN_COLUMNS):
            var a: int = row * stride + column
            var b: int = a + 1
            var c: int = (row + 1) * stride + column
            var d: int = c + 1
            indices.append(a)
            indices.append(b)
            indices.append(c)
            indices.append(b)
            indices.append(d)
            indices.append(c)

    var arrays: Array = []
    arrays.resize(Mesh.ARRAY_MAX)
    arrays[Mesh.ARRAY_VERTEX] = vertices
    arrays[Mesh.ARRAY_NORMAL] = normals
    arrays[Mesh.ARRAY_COLOR] = colors
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh: ArrayMesh = ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func _sample_natural_ground_color_v746(x: float, z: float, height: float, normal: Vector3) -> Color:
    # Broad/detail deterministic variation. This intentionally contains no
    # V74_ROUTE_POINTS/V74_PUMP_BRANCH access: color must never reveal a path.
    var broad: float = (
        sin(x * 0.0125 + z * 0.0085)
        + cos(x * 0.0068 - z * 0.0105)
    ) * 0.25 + 0.5
    var detail: float = (
        sin(x * 0.031 + z * 0.027)
        + cos(x * 0.043 - z * 0.019)
    ) * 0.25 + 0.5
    var variation: float = clampf(broad * 0.68 + detail * 0.32, 0.0, 1.0)

    var slope_raw: float = clampf(1.0 - absf(normal.y), 0.0, 1.0)
    var slope: float = smoothstep(0.045, 0.34, slope_raw)
    var wetness: float = 1.0 - smoothstep(-1.35, 0.20, height)
    var high_ground: float = smoothstep(1.10, 3.10, height)

    var color: Color = V746_MOSS_COLOR.lerp(V746_LEAF_COLOR, 0.18 + variation * 0.34)
    color = color.lerp(V746_WET_COLOR, wetness * (0.42 + variation * 0.16))
    color = color.lerp(V746_SOIL_COLOR, slope * 0.62)
    color = color.lerp(V746_ROCK_COLOR, clampf(slope * 0.30 + high_ground * slope * 0.34, 0.0, 0.58))

    # Small lighting-independent variation breaks up large flat-color fields
    # without creating high-frequency visual noise on mobile screens.
    var shade: float = lerpf(0.90, 1.08, variation)
    return Color(
        clampf(color.r * shade, 0.0, 1.0),
        clampf(color.g * shade, 0.0, 1.0),
        clampf(color.b * shade, 0.0, 1.0),
        1.0
    )

func _configure_natural_vertex_color_material_v746() -> void:
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

    var surface_material: StandardMaterial3D = terrain_mesh.surface_get_material(0) as StandardMaterial3D
    if surface_material != null:
        _enable_vertex_ground_color_v746(surface_material)

    var override_material: StandardMaterial3D = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
    if override_material != null:
        _enable_vertex_ground_color_v746(override_material)

    mesh_instance.visible = true
    mesh_instance.transparency = 0.0
    terrain.set_meta("terrain_color_revision", "0.74.6")
    terrain.set_meta("terrain_vertex_color", true)
    terrain.set_meta("terrain_route_color", false)
    terrain.set_meta("terrain_color_source", "elevation+slope+deterministic_noise")

func _enable_vertex_ground_color_v746(material: StandardMaterial3D) -> void:
    material.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.albedo_color = Color.WHITE
    material.vertex_color_use_as_albedo = true
    material.metallic = 0.0
    material.roughness = 0.96

func get_terrain_color_contract_v746() -> Dictionary:
    var color_count: int = 0
    var vertex_count: int = 0
    var material_vertex_color: bool = false

    if world_root != null:
        var terrain: StaticBody3D = world_root.get_node_or_null("ForestTerrainV74") as StaticBody3D
        if terrain != null:
            var mesh_instance: MeshInstance3D = terrain.get_node_or_null("TerrainMesh") as MeshInstance3D
            if mesh_instance != null and mesh_instance.mesh != null and mesh_instance.mesh.get_surface_count() > 0:
                var arrays: Array = mesh_instance.mesh.surface_get_arrays(0)
                var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
                var colors: PackedColorArray = arrays[Mesh.ARRAY_COLOR]
                vertex_count = vertices.size()
                color_count = colors.size()
                var material: StandardMaterial3D = mesh_instance.get_surface_override_material(0) as StandardMaterial3D
                if material != null:
                    material_vertex_color = material.vertex_color_use_as_albedo

    return {
        "revision": "0.74.6",
        "vertex_count": vertex_count,
        "color_count": color_count,
        "vertex_color_use_as_albedo": material_vertex_color,
        "opaque": true,
        "route_coloring": false,
        "path_geometry": false,
        "path_tree_corridor": false,
        "color_source": "elevation+slope+deterministic_noise",
        "mobile_extra_texture_samples": 0,
        "traversal_smoothing_preserved": true,
        "falloff_hardening_preserved": true
    }

func get_forest_map_contract_v74() -> Dictionary:
    var contract: Dictionary = super.get_forest_map_contract_v74()
    contract["revision"] = "0.74.6"
    contract["terrain_color_mode"] = "natural vertex color"
    contract["terrain_color_route_based"] = false
    contract["path_visual_mode"] = "none"
    contract["path_geometry"] = false
    return contract
