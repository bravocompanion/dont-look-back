extends "res://scripts/forest_world_expansion_v5.gd"

# v0.74.1 — terrain refinement + fall-off protection.
# Only authored yards / building pads are fully flat. Trails and open forest
# keep a gentle natural undulation, while the larger hills/valleys from v0.74
# remain concentrated in the expanded sectors.

const V741_FALL_RECOVER_Y: float = -5.20
const V741_BOUNDARY_INSET: float = 2.0
const V741_RECOVERY_LIFT: float = 1.05

const V741_FLAT_YARDS = [
    # Ranger fenced yard: exact gameplay-safe courtyard.
    {"center": Vector2(14.0, -82.0), "half": Vector2(15.1, 15.1), "feather": 2.8},
    # Small authored pads around mission structures only.
    {"center": Vector2(-70.0, -155.0), "half": Vector2(8.0, 6.5), "feather": 3.2},
    {"center": Vector2(76.0, -225.0), "half": Vector2(10.0, 8.0), "feather": 3.5},
    {"center": Vector2(-72.0, -286.0), "half": Vector2(11.0, 9.0), "feather": 3.5},
    {"center": Vector2(62.0, -332.0), "half": Vector2(5.0, 5.0), "feather": 2.8},
    {"center": Vector2(-98.0, -338.0), "half": Vector2(6.0, 5.0), "feather": 3.0}
]

var _v741_safe_position: Vector3 = Vector3(14.0, 0.92, -90.0)
var _v741_has_safe_position: bool = false
var _v741_scene_id: int = 0

func sample_terrain_height_v74(x: float, z: float) -> float:
    # Gentle low-frequency ground motion exists across the playable forest,
    # including the original v0.73 footprint. This removes the broad flat look.
    var local_relief: float = 0.0
    local_relief += sin(x * 0.018 + z * 0.010) * 0.22
    local_relief += cos(x * 0.011 - z * 0.014) * 0.16
    local_relief += sin(x * 0.0065 + z * 0.0085) * 0.10

    # Preserve the successful broad v0.74 hills and valleys, but grow their
    # amplitude mainly in the newly expanded side/deep sectors.
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

    # Only yards/pads flatten. Trails are intentionally NOT flattened anymore.
    var yard_factor: float = _yard_relief_factor_v741(Vector2(x, z))
    var height: float = (local_relief + macro_relief) * yard_factor
    return clampf(height, -2.80, 3.60)

func _gameplay_safe_factor_v74(point: Vector2) -> float:
    # Compatibility for parent helpers: safety flattening now means yards only.
    return _yard_relief_factor_v741(point)

func _yard_relief_factor_v741(point: Vector2) -> float:
    var factor: float = 1.0
    for data: Dictionary in V741_FLAT_YARDS:
        var center: Vector2 = Vector2(data.get("center", Vector2.ZERO))
        var half_size: Vector2 = Vector2(data.get("half", Vector2(6.0, 6.0)))
        var feather: float = maxf(0.5, float(data.get("feather", 3.0)))

        var dx: float = maxf(absf(point.x - center.x) - half_size.x, 0.0)
        var dz: float = maxf(absf(point.y - center.y) - half_size.y, 0.0)
        var outside_distance: float = Vector2(dx, dz).length()
        factor = minf(factor, smoothstep(0.0, feather, outside_distance))
    return factor

func _build_long_distance_trails() -> void:
    # Visual ribbons conform to the actual terrain instead of hovering as
    # horizontal box strips. They have no collision; movement uses terrain.
    var trail_material: StandardMaterial3D = StandardMaterial3D.new()
    trail_material.albedo_color = Color(0.075, 0.067, 0.050, 1.0)
    trail_material.roughness = 1.0

    _add_conforming_trail_v741("TrailCabinToHouse", Vector2(14.0, -67.0), Vector2(HOUSE_CENTER.x, HOUSE_CENTER.z), 3.2, trail_material)
    _add_conforming_trail_v741("TrailHouseToGas", Vector2(HOUSE_CENTER.x, HOUSE_CENTER.z), Vector2(GAS_CENTER.x, GAS_CENTER.z), 2.8, trail_material)
    _add_conforming_trail_v741("TrailGasToWarehouse", Vector2(GAS_CENTER.x, GAS_CENTER.z), Vector2(WAREHOUSE_CENTER.x, WAREHOUSE_CENTER.z), 2.7, trail_material)
    _add_conforming_trail_v741("TrailWarehouseToMine", Vector2(WAREHOUSE_CENTER.x, WAREHOUSE_CENTER.z), Vector2(V74_MINE_CENTER.x, V74_MINE_CENTER.z), 2.6, trail_material)
    _add_conforming_trail_v741("TrailMineToPumpOptional", Vector2(V74_MINE_CENTER.x, V74_MINE_CENTER.z), Vector2(PUMP_CENTER.x, PUMP_CENTER.z), 2.4, trail_material)

func _add_conforming_trail_v741(node_name: String, start: Vector2, finish: Vector2, width: float, material: Material) -> void:
    var delta: Vector2 = finish - start
    var length: float = delta.length()
    if length <= 0.1:
        return

    var direction: Vector2 = delta / length
    var side: Vector2 = Vector2(-direction.y, direction.x) * (width * 0.5)
    var steps: int = maxi(2, int(ceil(length / 6.0)))

    var vertices: PackedVector3Array = PackedVector3Array()
    var normals: PackedVector3Array = PackedVector3Array()
    var uvs: PackedVector2Array = PackedVector2Array()
    var indices: PackedInt32Array = PackedInt32Array()

    for index: int in range(steps + 1):
        var t: float = float(index) / float(steps)
        var center: Vector2 = start.lerp(finish, t)
        var left: Vector2 = center + side
        var right: Vector2 = center - side
        var left_y: float = sample_terrain_height_v74(left.x, left.y) + 0.035
        var right_y: float = sample_terrain_height_v74(right.x, right.y) + 0.035

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

func _build_invisible_boundaries() -> void:
    # Walls extend below the terrain as well as high above it, preventing the
    # player from slipping under an edge after a collision miss.
    var wall_height: float = 24.0
    var wall_bottom: float = -8.0
    var wall_center_y: float = wall_bottom + wall_height * 0.5
    var wall_thickness: float = 1.20
    var center_z: float = (V74_MAP_NEAR_Z + V74_MAP_FAR_Z) * 0.5

    _add_invisible_wall("MapBoundaryLeftV741", Vector3(V74_MAP_MIN_X, wall_center_y, center_z), Vector3(wall_thickness, wall_height, V74_MAP_DEPTH + wall_thickness * 2.0))
    _add_invisible_wall("MapBoundaryRightV741", Vector3(V74_MAP_MAX_X, wall_center_y, center_z), Vector3(wall_thickness, wall_height, V74_MAP_DEPTH + wall_thickness * 2.0))
    _add_invisible_wall("MapBoundaryNearV741", Vector3(0.0, wall_center_y, V74_MAP_NEAR_Z), Vector3(V74_MAP_WIDTH + wall_thickness * 2.0, wall_height, wall_thickness))
    _add_invisible_wall("MapBoundaryFarV741", Vector3(0.0, wall_center_y, V74_MAP_FAR_Z), Vector3(V74_MAP_WIDTH + wall_thickness * 2.0, wall_height, wall_thickness))

func _physics_process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        _v741_scene_id = 0
        _v741_has_safe_position = false
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != _v741_scene_id:
        _v741_scene_id = scene_id
        _v741_safe_position = Vector3(14.0, 0.92, -90.0)
        _v741_has_safe_position = false

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or not is_instance_valid(player):
        return
    if bool(player.get("is_dead")):
        return

    var position_value: Vector3 = player.global_position
    var fell_below_terrain: bool = position_value.y < V741_FALL_RECOVER_Y
    var escaped_boundary: bool = not _inside_playable_bounds_v741(position_value, -1.5)

    if fell_below_terrain or escaped_boundary:
        _recover_player_v741(player)
        return

    # Save only grounded positions with a small boundary inset. Updating this
    # continuously means recovery normally moves <8 m, compatible with the
    # existing multiplayer remote-step validation.
    if player.is_on_floor() and _inside_playable_bounds_v741(position_value, V741_BOUNDARY_INSET):
        _v741_safe_position = position_value
        _v741_has_safe_position = true

func _inside_playable_bounds_v741(position_value: Vector3, inset: float) -> bool:
    return (
        position_value.x >= V74_MAP_MIN_X + inset
        and position_value.x <= V74_MAP_MAX_X - inset
        and position_value.z >= V74_MAP_FAR_Z + inset
        and position_value.z <= V74_MAP_NEAR_Z - inset
    )

func _recover_player_v741(player: CharacterBody3D) -> void:
    var target: Vector3 = _v741_safe_position if _v741_has_safe_position else Vector3(14.0, 0.92, -90.0)
    target.x = clampf(target.x, V74_MAP_MIN_X + 3.0, V74_MAP_MAX_X - 3.0)
    target.z = clampf(target.z, V74_MAP_FAR_Z + 3.0, V74_MAP_NEAR_Z - 3.0)
    var ground_y: float = sample_terrain_height_v74(target.x, target.z)
    target.y = maxf(target.y + 0.20, ground_y + V741_RECOVERY_LIFT)

    player.global_position = target
    player.velocity = Vector3.ZERO
    _v741_safe_position = target
    _v741_has_safe_position = true

func get_forest_map_contract_v74() -> Dictionary:
    var contract: Dictionary = super.get_forest_map_contract_v74()
    contract["revision"] = "0.74.1"
    contract["terrain_policy"] = "flat yards only; trails and open forest follow natural relief"
    contract["fall_recovery_y"] = V741_FALL_RECOVER_Y
    contract["boundary_wall_height_m"] = 24.0
    return contract
