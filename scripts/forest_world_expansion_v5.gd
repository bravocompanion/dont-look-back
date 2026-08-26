extends "res://scripts/forest_world_expansion_v4.gd"

# v0.74 — 2x map dimensions versus v0.73.
# Old footprint: 224 x 304 m. New footprint: 448 x 608 m.
# The legacy mission footprint remains nearly level so existing POIs, loot,
# evidence, multiplayer positions, and interactables keep their authored Y.
const V74_MAP_MIN_X: float = -224.0
const V74_MAP_MAX_X: float = 224.0
const V74_MAP_NEAR_Z: float = -52.0
const V74_MAP_FAR_Z: float = -660.0
const V74_MAP_CENTER_Z: float = -356.0
const V74_MAP_WIDTH: float = 448.0
const V74_MAP_DEPTH: float = 608.0

const V74_TERRAIN_COLUMNS: int = 56
const V74_TERRAIN_ROWS: int = 76
const V74_DESKTOP_TREE_COUNT: int = 620
const V74_MOBILE_TREE_COUNT: int = 380

const V74_MINE_CENTER: Vector3 = Vector3(-98.0, 0.0, -338.0)

# Route is deliberately flattened with a soft shoulder so walking, AI pursuit,
# evidence interaction, and multiplayer regrouping are never slope-gated.
const V74_ROUTE_POINTS = [
    Vector2(14.0, -67.0),
    Vector2(-70.0, -155.0),
    Vector2(76.0, -225.0),
    Vector2(-72.0, -286.0),
    Vector2(-98.0, -338.0)
]
const V74_PUMP_BRANCH = [Vector2(-98.0, -338.0), Vector2(62.0, -332.0)]

const V74_SAFE_PLATEAUS = [
    {"center": Vector2(14.0, -82.0), "inner": 34.0, "outer": 46.0},
    {"center": Vector2(-70.0, -155.0), "inner": 16.0, "outer": 27.0},
    {"center": Vector2(76.0, -225.0), "inner": 17.0, "outer": 29.0},
    {"center": Vector2(-72.0, -286.0), "inner": 19.0, "outer": 31.0},
    {"center": Vector2(62.0, -332.0), "inner": 13.0, "outer": 23.0},
    {"center": Vector2(-98.0, -338.0), "inner": 16.0, "outer": 27.0}
]

func _build_mega_ground() -> void:
    _disable_legacy_flat_ground_v74()

    var terrain_material: StandardMaterial3D = StandardMaterial3D.new()
    terrain_material.albedo_color = Color(0.040, 0.055, 0.040, 1.0)
    terrain_material.roughness = 0.98

    var terrain_mesh: ArrayMesh = _create_terrain_mesh_v74()
    terrain_mesh.surface_set_material(0, terrain_material)

    var body: StaticBody3D = StaticBody3D.new()
    body.name = "ForestTerrainV74"
    world_root.add_child(body)

    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    mesh_instance.name = "TerrainMesh"
    mesh_instance.mesh = terrain_mesh
    body.add_child(mesh_instance)

    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.name = "TerrainCollision"
    collision.shape = terrain_mesh.create_trimesh_shape()
    body.add_child(collision)

    world_root.set_meta("forest_map_version", "0.74")
    world_root.set_meta("forest_map_dimensions_m", Vector2(V74_MAP_WIDTH, V74_MAP_DEPTH))

func _disable_legacy_flat_ground_v74() -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var outside_root: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if outside_root == null:
        return

    var legacy_ground: CSGBox3D = outside_root.get_node_or_null("ForestGround") as CSGBox3D
    if legacy_ground != null:
        legacy_ground.visible = false
        legacy_ground.use_collision = false

    var expansion: Node3D = outside_root.get_node_or_null("ExteriorExpansion") as Node3D
    if expansion != null:
        _disable_static_boundary(expansion.get_node_or_null("ExpansionGround"))

func _create_terrain_mesh_v74() -> ArrayMesh:
    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    var uvs: PackedVector2Array = PackedVector2Array()
    var indices: PackedInt32Array = PackedInt32Array()

    for row: int in range(V74_TERRAIN_ROWS + 1):
        var tz: float = float(row) / float(V74_TERRAIN_ROWS)
        var z: float = lerpf(V74_MAP_NEAR_Z, V74_MAP_FAR_Z, tz)
        for column: int in range(V74_TERRAIN_COLUMNS + 1):
            var tx: float = float(column) / float(V74_TERRAIN_COLUMNS)
            var x: float = lerpf(V74_MAP_MIN_X, V74_MAP_MAX_X, tx)
            var y: float = sample_terrain_height_v74(x, z)
            vertices.append(Vector3(x, y, z))
            normals.append(_terrain_normal_v74(x, z))
            uvs.append(Vector2(tx * 18.0, tz * 24.0))

    var stride: int = V74_TERRAIN_COLUMNS + 1
    for row: int in range(V74_TERRAIN_ROWS):
        for column: int in range(V74_TERRAIN_COLUMNS):
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
    # Terrain motion is introduced mainly outside the old v0.73 footprint.
    # This is what preserves every legacy authored pickup/quest Y coordinate.
    var deep_factor: float = smoothstep(348.0, 430.0, -z)
    var side_factor: float = smoothstep(108.0, 150.0, absf(x))
    var expansion_factor: float = maxf(deep_factor, side_factor)

    var height: float = 0.0
    height += _terrain_gaussian_v74(x, z, 148.0, -458.0, 3.35, 92.0, 118.0)
    height += _terrain_gaussian_v74(x, z, -162.0, -520.0, 2.85, 86.0, 102.0)
    height += _terrain_gaussian_v74(x, z, 58.0, -610.0, 1.75, 125.0, 58.0)
    height += _terrain_gaussian_v74(x, z, 8.0, -492.0, -2.45, 132.0, 78.0)
    height += _terrain_gaussian_v74(x, z, -118.0, -420.0, -1.65, 82.0, 92.0)

    # Very low-frequency undulation avoids a mathematically perfect surface
    # while keeping local grades comfortable for sprinting and co-op movement.
    height += sin(x * 0.018 + z * 0.010) * 0.28
    height += cos(x * 0.011 - z * 0.014) * 0.20
    height *= expansion_factor

    var safe_factor: float = _gameplay_safe_factor_v74(Vector2(x, z))
    height *= safe_factor
    return clampf(height, -2.80, 3.60)

func _terrain_gaussian_v74(x: float, z: float, center_x: float, center_z: float, amplitude: float, sigma_x: float, sigma_z: float) -> float:
    var dx: float = (x - center_x) / maxf(1.0, sigma_x)
    var dz: float = (z - center_z) / maxf(1.0, sigma_z)
    return amplitude * exp(-0.5 * (dx * dx + dz * dz))

func _terrain_normal_v74(x: float, z: float) -> Vector3:
    var epsilon: float = 1.25
    var dx: float = (sample_terrain_height_v74(x + epsilon, z) - sample_terrain_height_v74(x - epsilon, z)) / (epsilon * 2.0)
    var dz: float = (sample_terrain_height_v74(x, z + epsilon) - sample_terrain_height_v74(x, z - epsilon)) / (epsilon * 2.0)
    return Vector3(-dx, 1.0, -dz).normalized()

func _gameplay_safe_factor_v74(point: Vector2) -> float:
    var factor: float = 1.0

    for data: Dictionary in V74_SAFE_PLATEAUS:
        var center: Vector2 = Vector2(data.get("center", Vector2.ZERO))
        var inner: float = float(data.get("inner", 12.0))
        var outer: float = float(data.get("outer", inner + 10.0))
        var distance_value: float = point.distance_to(center)
        factor = minf(factor, smoothstep(inner, outer, distance_value))

    factor = minf(factor, _route_safe_factor_v74(point, V74_ROUTE_POINTS))
    factor = minf(factor, _route_safe_factor_v74(point, V74_PUMP_BRANCH))
    return factor

func _route_safe_factor_v74(point: Vector2, route_points: Array) -> float:
    var closest: float = INF
    for index: int in range(route_points.size() - 1):
        closest = minf(closest, _distance_to_segment_v74(point, Vector2(route_points[index]), Vector2(route_points[index + 1])))
    return smoothstep(5.0, 14.0, closest)

func _distance_to_segment_v74(point: Vector2, start: Vector2, finish: Vector2) -> float:
    var segment: Vector2 = finish - start
    var length_squared: float = segment.length_squared()
    if length_squared <= 0.0001:
        return point.distance_to(start)
    var t: float = clampf((point - start).dot(segment) / length_squared, 0.0, 1.0)
    return point.distance_to(start + segment * t)

func _build_invisible_boundaries() -> void:
    var wall_height: float = 12.0
    var wall_thickness: float = 0.70
    var center_z: float = (V74_MAP_NEAR_Z + V74_MAP_FAR_Z) * 0.5

    _add_invisible_wall("MapBoundaryLeftV74", Vector3(V74_MAP_MIN_X, wall_height * 0.5, center_z), Vector3(wall_thickness, wall_height, V74_MAP_DEPTH))
    _add_invisible_wall("MapBoundaryRightV74", Vector3(V74_MAP_MAX_X, wall_height * 0.5, center_z), Vector3(wall_thickness, wall_height, V74_MAP_DEPTH))
    _add_invisible_wall("MapBoundaryNearV74", Vector3(0.0, wall_height * 0.5, V74_MAP_NEAR_Z), Vector3(V74_MAP_WIDTH, wall_height, wall_thickness))
    _add_invisible_wall("MapBoundaryFarV74", Vector3(0.0, wall_height * 0.5, V74_MAP_FAR_Z), Vector3(V74_MAP_WIDTH, wall_height, wall_thickness))

func _build_long_distance_trails() -> void:
    var trail_material: StandardMaterial3D = StandardMaterial3D.new()
    trail_material.albedo_color = Color(0.075, 0.067, 0.050, 1.0)
    trail_material.roughness = 1.0

    _add_trail_segment("TrailCabinToHouse", Vector3(14.0, 0.015, -67.0), HOUSE_CENTER, 3.2, trail_material)
    _add_trail_segment("TrailHouseToGas", HOUSE_CENTER, GAS_CENTER, 2.8, trail_material)
    _add_trail_segment("TrailGasToWarehouse", GAS_CENTER, WAREHOUSE_CENTER, 2.7, trail_material)
    _add_trail_segment("TrailWarehouseToMine", WAREHOUSE_CENTER, V74_MINE_CENTER, 2.6, trail_material)
    _add_trail_segment("TrailMineToPumpOptional", V74_MINE_CENTER, PUMP_CENTER, 2.4, trail_material)

func _build_far_forest_multimesh() -> void:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 740826

    var target_count: int = V74_MOBILE_TREE_COUNT if _is_mobile_runtime_v74() else V74_DESKTOP_TREE_COUNT
    var positions: Array[Vector3] = []
    var attempts: int = 0
    var max_attempts: int = target_count * 14

    while positions.size() < target_count and attempts < max_attempts:
        attempts += 1
        var x: float = rng.randf_range(V74_MAP_MIN_X + 6.0, V74_MAP_MAX_X - 6.0)
        var z: float = rng.randf_range(V74_MAP_FAR_Z + 8.0, -108.0)
        var point: Vector2 = Vector2(x, z)
        if not _tree_position_clear_v74(point):
            continue
        positions.append(Vector3(x, sample_terrain_height_v74(x, z), z))

    var trunk_material: StandardMaterial3D = StandardMaterial3D.new()
    trunk_material.albedo_color = Color(0.095, 0.065, 0.038, 1.0)
    trunk_material.roughness = 1.0
    var trunk_mesh: CylinderMesh = CylinderMesh.new()
    trunk_mesh.top_radius = 0.18
    trunk_mesh.bottom_radius = 0.27
    trunk_mesh.height = 4.2
    trunk_mesh.radial_segments = 6
    trunk_mesh.material = trunk_material

    var crown_material: StandardMaterial3D = StandardMaterial3D.new()
    crown_material.albedo_color = Color(0.030, 0.050, 0.030, 1.0)
    crown_material.roughness = 1.0
    var crown_mesh: SphereMesh = SphereMesh.new()
    crown_mesh.radius = 1.25
    crown_mesh.height = 2.5
    crown_mesh.radial_segments = 8
    crown_mesh.rings = 4
    crown_mesh.material = crown_material

    var trunk_multi: MultiMesh = MultiMesh.new()
    trunk_multi.transform_format = MultiMesh.TRANSFORM_3D
    trunk_multi.mesh = trunk_mesh
    trunk_multi.instance_count = positions.size()

    var crown_multi: MultiMesh = MultiMesh.new()
    crown_multi.transform_format = MultiMesh.TRANSFORM_3D
    crown_multi.mesh = crown_mesh
    crown_multi.instance_count = positions.size()

    for index: int in range(positions.size()):
        var p: Vector3 = positions[index]
        var scale_value: float = rng.randf_range(0.82, 1.35)
        var yaw: float = rng.randf_range(0.0, TAU)
        var basis: Basis = Basis(Vector3.UP, yaw).scaled(Vector3(scale_value, scale_value, scale_value))
        trunk_multi.set_instance_transform(index, Transform3D(basis, p + Vector3(0.0, 2.1 * scale_value, 0.0)))
        crown_multi.set_instance_transform(index, Transform3D(basis, p + Vector3(0.0, 5.0 * scale_value, 0.0)))

    var trunks: MultiMeshInstance3D = MultiMeshInstance3D.new()
    trunks.name = "ForestTerrainTrunksV74"
    trunks.multimesh = trunk_multi
    world_root.add_child(trunks)

    var crowns: MultiMeshInstance3D = MultiMeshInstance3D.new()
    crowns.name = "ForestTerrainCrownsV74"
    crowns.multimesh = crown_multi
    world_root.add_child(crowns)

func _tree_position_clear_v74(point: Vector2) -> bool:
    for data: Dictionary in V74_SAFE_PLATEAUS:
        var center: Vector2 = Vector2(data.get("center", Vector2.ZERO))
        var clearance: float = float(data.get("outer", 20.0)) + 2.0
        if point.distance_to(center) <= clearance:
            return false
    if _route_safe_factor_v74(point, V74_ROUTE_POINTS) < 0.98:
        return false
    if _route_safe_factor_v74(point, V74_PUMP_BRANCH) < 0.98:
        return false
    return true

func _is_mobile_runtime_v74() -> bool:
    return OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")

func _build_readability_lights() -> void:
    super._build_readability_lights()
    if daylight_safety != null and is_instance_valid(daylight_safety):
        daylight_safety.position = Vector3(0.0, 8.0, V74_MAP_CENTER_Z)
        daylight_safety.omni_range = 505.0

func get_forest_map_contract_v74() -> Dictionary:
    return {
        "version": "0.74",
        "bounds": {
            "min_x": V74_MAP_MIN_X,
            "max_x": V74_MAP_MAX_X,
            "near_z": V74_MAP_NEAR_Z,
            "far_z": V74_MAP_FAR_Z,
            "width_m": V74_MAP_WIDTH,
            "depth_m": V74_MAP_DEPTH
        },
        "player_spawn": Vector3(14.0, 0.92, -90.0),
        "case_board": Vector3(12.15, 1.35, -83.45),
        "quest_points": {
            "survey_manifest": Vector3(-72.0, 0.92, -157.2),
            "radio_trace": Vector3(78.0, 0.92, -228.0),
            "maintenance_map": Vector3(-70.0, 0.92, -288.0),
            "water_sample_optional": Vector3(62.0, 0.78, -332.0),
            "old_mine_gate": Vector3(-98.0, 1.25, -337.35)
        },
        "terrain_height_min_m": -2.80,
        "terrain_height_max_m": 3.60,
        "desktop_tree_budget": V74_DESKTOP_TREE_COUNT,
        "mobile_tree_budget": V74_MOBILE_TREE_COUNT
    }
