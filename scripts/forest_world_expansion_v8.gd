extends "res://scripts/forest_world_expansion_v7.gd"

# v0.74.3 — terrain visibility + traversal smoothing.
# Keep the expanded natural terrain, but treat authored quest roads as a smooth
# traversal corridor rather than platforming. Yards stay perfectly flat while
# their transitions now span multiple terrain cells.

const V743_TERRAIN_COLUMNS: int = 84
const V743_TERRAIN_ROWS: int = 114
const V743_ROUTE_CORE_M: float = 3.5
const V743_ROUTE_SHOULDER_M: float = 15.0
const V743_ROUTE_RELIEF_SCALE: float = 0.18
const V743_TRAIL_SAMPLE_M: float = 3.0

const V743_FLAT_YARDS = [
    {"center": Vector2(14.0, -82.0), "half": Vector2(15.1, 15.1), "feather": 12.0},
    {"center": Vector2(-70.0, -155.0), "half": Vector2(8.0, 6.5), "feather": 10.0},
    {"center": Vector2(76.0, -225.0), "half": Vector2(10.0, 8.0), "feather": 11.0},
    {"center": Vector2(-72.0, -286.0), "half": Vector2(11.0, 9.0), "feather": 12.0},
    {"center": Vector2(62.0, -332.0), "half": Vector2(5.0, 5.0), "feather": 9.0},
    {"center": Vector2(-98.0, -338.0), "half": Vector2(6.0, 5.0), "feather": 10.0}
]

func _build_mega_ground() -> void:
    super._build_mega_ground()
    _configure_terrain_visual_v743()

func _configure_terrain_visual_v743() -> void:
    if world_root == null:
        return
    var terrain: StaticBody3D = world_root.get_node_or_null("ForestTerrainV74") as StaticBody3D
    if terrain == null:
        return
    var mesh_instance: MeshInstance3D = terrain.get_node_or_null("TerrainMesh") as MeshInstance3D
    if mesh_instance == null or mesh_instance.mesh == null:
        return

    mesh_instance.visible = true
    var terrain_mesh: ArrayMesh = mesh_instance.mesh as ArrayMesh
    if terrain_mesh == null or terrain_mesh.get_surface_count() <= 0:
        return
    var material: StandardMaterial3D = terrain_mesh.surface_get_material(0) as StandardMaterial3D
    if material == null:
        material = StandardMaterial3D.new()
        terrain_mesh.surface_set_material(0, material)

    # The procedural surface must stay visible even if renderer/front-face
    # conventions differ between GL Compatibility, mobile, and desktop.
    material.cull_mode = BaseMaterial3D.CULL_DISABLED
    material.albedo_color = Color(0.070, 0.088, 0.064, 1.0)
    material.roughness = 1.0

func _create_terrain_mesh_v74() -> ArrayMesh:
    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    var uvs: PackedVector2Array = PackedVector2Array()
    var indices: PackedInt32Array = PackedInt32Array()

    for row: int in range(V743_TERRAIN_ROWS + 1):
        var tz: float = float(row) / float(V743_TERRAIN_ROWS)
        var z: float = lerpf(V74_MAP_NEAR_Z, V74_MAP_FAR_Z, tz)
        for column: int in range(V743_TERRAIN_COLUMNS + 1):
            var tx: float = float(column) / float(V743_TERRAIN_COLUMNS)
            var x: float = lerpf(V74_MAP_MIN_X, V74_MAP_MAX_X, tx)
            var y: float = sample_terrain_height_v74(x, z)
            vertices.append(Vector3(x, y, z))
            normals.append(_terrain_normal_v74(x, z))
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
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh: ArrayMesh = ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    return mesh

func sample_terrain_height_v74(x: float, z: float) -> float:
    # Small natural ground motion remains across the forest, but its amplitude
    # is intentionally lower than v0.74.1 so normal walking never needs jump.
    var local_relief: float = 0.0
    local_relief += sin(x * 0.018 + z * 0.010) * 0.15
    local_relief += cos(x * 0.011 - z * 0.014) * 0.11
    local_relief += sin(x * 0.0065 + z * 0.0085) * 0.07

    var deep_factor: float = smoothstep(330.0, 430.0, -z)
    var side_factor: float = smoothstep(100.0, 150.0, absf(x))
    var expansion_factor: float = maxf(deep_factor, side_factor)

    var macro_relief: float = 0.0
    macro_relief += _terrain_gaussian_v74(x, z, 148.0, -458.0, 3.35, 92.0, 118.0)
    macro_relief += _terrain_gaussian_v74(x, z, -162.0, -520.0, 2.85, 86.0, 102.0)
    macro_relief += _terrain_gaussian_v74(x, z, 58.0, -610.0, 1.75, 125.0, 58.0)
    macro_relief += _terrain_gaussian_v74(x, z, 8.0, -492.0, -2.45, 132.0, 78.0)
    macro_relief += _terrain_gaussian_v74(x, z, -118.0, -420.0, -1.65, 82.0, 92.0)
    macro_relief *= expansion_factor

    var point: Vector2 = Vector2(x, z)
    var route_scale: float = _route_relief_scale_v743(point)
    var yard_factor: float = _yard_relief_factor_v743(point)
    var height: float = (local_relief + macro_relief) * route_scale * yard_factor
    return clampf(height, -2.80, 3.60)

func _gameplay_safe_factor_v74(point: Vector2) -> float:
    # Compatibility for inherited helpers. Exact zero is reserved for yards;
    # route smoothing is handled independently by route relief scaling.
    return _yard_relief_factor_v743(point)

func _yard_relief_factor_v743(point: Vector2) -> float:
    var factor: float = 1.0
    for data: Dictionary in V743_FLAT_YARDS:
        var center: Vector2 = Vector2(data.get("center", Vector2.ZERO))
        var half_size: Vector2 = Vector2(data.get("half", Vector2(6.0, 6.0)))
        var feather: float = maxf(4.0, float(data.get("feather", 10.0)))
        var dx: float = maxf(absf(point.x - center.x) - half_size.x, 0.0)
        var dz: float = maxf(absf(point.y - center.y) - half_size.y, 0.0)
        var outside_distance: float = Vector2(dx, dz).length()
        factor = minf(factor, smoothstep(0.0, feather, outside_distance))
    return factor

func _route_relief_scale_v743(point: Vector2) -> float:
    var closest: float = INF
    closest = minf(closest, _closest_route_distance_v743(point, V74_ROUTE_POINTS))
    closest = minf(closest, _closest_route_distance_v743(point, V74_PUMP_BRANCH))
    if closest == INF:
        return 1.0
    var blend: float = smoothstep(V743_ROUTE_CORE_M, V743_ROUTE_SHOULDER_M, closest)
    return lerpf(V743_ROUTE_RELIEF_SCALE, 1.0, blend)

func _closest_route_distance_v743(point: Vector2, route_points: Array) -> float:
    if route_points.size() < 2:
        return INF
    var closest: float = INF
    for index: int in range(route_points.size() - 1):
        closest = minf(
            closest,
            _distance_to_segment_v74(point, Vector2(route_points[index]), Vector2(route_points[index + 1]))
        )
    return closest

func _build_long_distance_trails() -> void:
    var trail_material: StandardMaterial3D = StandardMaterial3D.new()
    trail_material.albedo_color = Color(0.105, 0.090, 0.064, 1.0)
    trail_material.roughness = 1.0
    trail_material.cull_mode = BaseMaterial3D.CULL_DISABLED

    _add_conforming_trail_v743("TrailCabinToHouse", Vector2(14.0, -67.0), Vector2(HOUSE_CENTER.x, HOUSE_CENTER.z), 3.2, trail_material)
    _add_conforming_trail_v743("TrailHouseToGas", Vector2(HOUSE_CENTER.x, HOUSE_CENTER.z), Vector2(GAS_CENTER.x, GAS_CENTER.z), 2.8, trail_material)
    _add_conforming_trail_v743("TrailGasToWarehouse", Vector2(GAS_CENTER.x, GAS_CENTER.z), Vector2(WAREHOUSE_CENTER.x, WAREHOUSE_CENTER.z), 2.7, trail_material)
    _add_conforming_trail_v743("TrailWarehouseToMine", Vector2(WAREHOUSE_CENTER.x, WAREHOUSE_CENTER.z), Vector2(V74_MINE_CENTER.x, V74_MINE_CENTER.z), 2.6, trail_material)
    _add_conforming_trail_v743("TrailMineToPumpOptional", Vector2(V74_MINE_CENTER.x, V74_MINE_CENTER.z), Vector2(PUMP_CENTER.x, PUMP_CENTER.z), 2.4, trail_material)

func _add_conforming_trail_v743(node_name: String, start: Vector2, finish: Vector2, width: float, material: Material) -> void:
    var delta: Vector2 = finish - start
    var length: float = delta.length()
    if length <= 0.1:
        return

    var direction: Vector2 = delta / length
    var side: Vector2 = Vector2(-direction.y, direction.x) * (width * 0.5)
    var steps: int = maxi(2, int(ceil(length / V743_TRAIL_SAMPLE_M)))

    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    var uvs: PackedVector2Array = PackedVector2Array()
    var indices: PackedInt32Array = PackedInt32Array()

    for index: int in range(steps + 1):
        var t: float = float(index) / float(steps)
        var center: Vector2 = start.lerp(finish, t)
        var left: Vector2 = center + side
        var right: Vector2 = center - side
        var left_y: float = sample_terrain_height_v74(left.x, left.y) + 0.025
        var right_y: float = sample_terrain_height_v74(right.x, right.y) + 0.025

        vertices.append(Vector3(left.x, left_y, left.y))
        vertices.append(Vector3(right.x, right_y, right.y))
        normals.append(_terrain_normal_v74(left.x, left.y))
        normals.append(_terrain_normal_v74(right.x, right.y))
        uvs.append(Vector2(0.0, t * length / 4.0))
        uvs.append(Vector2(1.0, t * length / 4.0))

        if index < steps:
            var a: int = index * 2
            var b: int = a + 1
            var c: int = a + 2
            var d: int = a + 3
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
    arrays[Mesh.ARRAY_TEX_UV] = uvs
    arrays[Mesh.ARRAY_INDEX] = indices

    var mesh: ArrayMesh = ArrayMesh.new()
    mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
    mesh.surface_set_material(0, material)

    var trail: MeshInstance3D = MeshInstance3D.new()
    trail.name = StringName(node_name)
    trail.mesh = mesh
    world_root.add_child(trail)

func get_terrain_traversal_contract_v743() -> Dictionary:
    return {
        "revision": "0.74.3",
        "terrain_grid": Vector2i(V743_TERRAIN_COLUMNS, V743_TERRAIN_ROWS),
        "approx_cell_m": Vector2(V74_MAP_WIDTH / float(V743_TERRAIN_COLUMNS), V74_MAP_DEPTH / float(V743_TERRAIN_ROWS)),
        "route_core_m": V743_ROUTE_CORE_M,
        "route_shoulder_m": V743_ROUTE_SHOULDER_M,
        "route_relief_scale": V743_ROUTE_RELIEF_SCALE,
        "yard_feather_min_m": 9.0,
        "terrain_double_sided": true,
        "trail_sample_m": V743_TRAIL_SAMPLE_M,
        "falloff_hardening_preserved": true
    }

func get_forest_map_contract_v74() -> Dictionary:
    var contract: Dictionary = super.get_forest_map_contract_v74()
    contract["revision"] = "0.74.3"
    contract["terrain_policy"] = "flat yards, smooth semi-flat quest routes, natural open forest"
    contract["terrain_grid"] = Vector2i(V743_TERRAIN_COLUMNS, V743_TERRAIN_ROWS)
    contract["terrain_double_sided"] = true
    return contract
