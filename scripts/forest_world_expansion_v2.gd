extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"

# 4x area versus the previous ~112m x 152m playable forest:
# width 224m x depth 304m = ~68,096 m2.
const MAP_MIN_X: float = -112.0
const MAP_MAX_X: float = 112.0
const MAP_NEAR_Z: float = -52.0
const MAP_FAR_Z: float = -356.0
const MAP_CENTER: Vector3 = Vector3(0.0, 0.0, -204.0)
const MAP_SIZE: Vector3 = Vector3(224.0, 0.24, 304.0)

const CABIN_CENTER: Vector3 = Vector3(14.0, 0.0, -82.0)
const HOUSE_CENTER: Vector3 = Vector3(-70.0, 0.0, -155.0)
const GAS_CENTER: Vector3 = Vector3(76.0, 0.0, -225.0)
const WAREHOUSE_CENTER: Vector3 = Vector3(-72.0, 0.0, -286.0)
const PUMP_CENTER: Vector3 = Vector3(62.0, 0.0, -332.0)

const HOUSE_OFFSET: Vector3 = Vector3(-45.0, 0.0, -5.0)
const GAS_OFFSET: Vector3 = Vector3(54.0, 0.0, -65.0)
const WAREHOUSE_OFFSET: Vector3 = Vector3(-64.0, 0.0, -99.0)
const PUMP_OFFSET: Vector3 = Vector3(31.0, 0.0, -144.0)

const NATURAL_FILL_ENERGY: float = 0.10
const AMBIENT_FLOOR: float = 0.15

var configured_scene_id: int = 0
var world_root: Node3D
var natural_fill: DirectionalLight3D
var daylight_safety: OmniLight3D

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(_delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        configured_scene_id = 0
        world_root = null
        natural_fill = null
        daylight_safety = null
        return

    var scene_id: int = int(scene.get_instance_id())
    if configured_scene_id != scene_id:
        configured_scene_id = scene_id
        world_root = null
        natural_fill = null
        daylight_safety = null

    if world_root == null or not is_instance_valid(world_root):
        _try_configure_world(scene)

    _apply_readability_lighting(scene)
    _update_daylight_safety()

func _try_configure_world(scene: Node) -> void:
    var outside_root: Node3D = scene.get_node_or_null("OutsideWorld") as Node3D
    if outside_root == null:
        return
    var expansion: Node3D = outside_root.get_node_or_null("ExteriorExpansion") as Node3D
    if expansion == null:
        return

    var existing: Node3D = outside_root.get_node_or_null("ForestMegaExpansionV2") as Node3D
    if existing != null:
        world_root = existing
        natural_fill = world_root.get_node_or_null("NaturalObjectFill") as DirectionalLight3D
        daylight_safety = world_root.get_node_or_null("MegaDaylightSafety") as OmniLight3D
        return

    _disable_legacy_boundaries(outside_root, expansion)
    _spread_mission_clusters(expansion)

    world_root = Node3D.new()
    world_root.name = "ForestMegaExpansionV2"
    outside_root.add_child(world_root)

    _build_mega_ground()
    _build_invisible_boundaries()
    _build_long_distance_trails()
    _build_far_forest_multimesh()
    _build_readability_lights()

func _disable_legacy_boundaries(outside_root: Node3D, expansion: Node3D) -> void:
    var entry: CSGBox3D = outside_root.get_node_or_null("ForestEntryBoundary") as CSGBox3D
    if entry != null:
        entry.visible = false
        entry.use_collision = false

    for path: String in ["LeftBoundary", "RightBoundary", "FarBoundary"]:
        _disable_static_boundary(outside_root.get_node_or_null(NodePath(path)))

    for path: String in ["ExpansionLeftBoundary", "ExpansionRightBoundary", "ExpansionFarBoundary"]:
        _disable_static_boundary(expansion.get_node_or_null(NodePath(path)))

func _disable_static_boundary(node: Node) -> void:
    var body: Node3D = node as Node3D
    if body == null:
        return
    body.visible = false
    var collision: CollisionShape3D = body.get_node_or_null("CollisionShape3D") as CollisionShape3D
    if collision == null:
        for child: Node in body.get_children():
            if child is CollisionShape3D:
                collision = child as CollisionShape3D
                break
    if collision != null:
        collision.disabled = true

func _spread_mission_clusters(expansion: Node3D) -> void:
    if bool(expansion.get_meta("mega_mission_layout_v2", false)):
        return

    for child: Node in expansion.get_children():
        var spatial: Node3D = child as Node3D
        if spatial == null:
            continue
        var node_name: String = str(child.name)
        if node_name.begins_with("House"):
            spatial.position += HOUSE_OFFSET
        elif node_name.begins_with("Gas"):
            spatial.position += GAS_OFFSET
        elif node_name.begins_with("Warehouse"):
            spatial.position += WAREHOUSE_OFFSET
        elif node_name == "OldWaterPump" or node_name.begins_with("Pump"):
            spatial.position += PUMP_OFFSET
        elif node_name == "FarMedkit":
            spatial.position = Vector3(80.0, spatial.position.y, -340.0)

    expansion.set_meta("mega_mission_layout_v2", true)

func _build_mega_ground() -> void:
    var ground_material: StandardMaterial3D = StandardMaterial3D.new()
    ground_material.albedo_color = Color(0.040, 0.055, 0.040, 1.0)
    ground_material.roughness = 0.98
    _add_box_body("MegaForestGround", Vector3(MAP_CENTER.x, -0.13, MAP_CENTER.z), MAP_SIZE, ground_material, true)

func _build_invisible_boundaries() -> void:
    var wall_height: float = 5.0
    var wall_thickness: float = 0.50
    var depth: float = MAP_NEAR_Z - MAP_FAR_Z
    var center_z: float = (MAP_NEAR_Z + MAP_FAR_Z) * 0.5
    var width: float = MAP_MAX_X - MAP_MIN_X

    _add_invisible_wall("MapBoundaryLeft", Vector3(MAP_MIN_X, wall_height * 0.5, center_z), Vector3(wall_thickness, wall_height, depth))
    _add_invisible_wall("MapBoundaryRight", Vector3(MAP_MAX_X, wall_height * 0.5, center_z), Vector3(wall_thickness, wall_height, depth))
    _add_invisible_wall("MapBoundaryNear", Vector3(0.0, wall_height * 0.5, MAP_NEAR_Z), Vector3(width, wall_height, wall_thickness))
    _add_invisible_wall("MapBoundaryFar", Vector3(0.0, wall_height * 0.5, MAP_FAR_Z), Vector3(width, wall_height, wall_thickness))

func _build_long_distance_trails() -> void:
    var trail_material: StandardMaterial3D = StandardMaterial3D.new()
    trail_material.albedo_color = Color(0.075, 0.067, 0.050, 1.0)
    trail_material.roughness = 1.0

    _add_trail_segment("TrailCabinToHouse", Vector3(14.0, 0.015, -67.0), HOUSE_CENTER, 3.2, trail_material)
    _add_trail_segment("TrailHouseToGas", HOUSE_CENTER, GAS_CENTER, 2.8, trail_material)
    _add_trail_segment("TrailGasToWarehouse", GAS_CENTER, WAREHOUSE_CENTER, 2.7, trail_material)
    _add_trail_segment("TrailWarehouseToPump", WAREHOUSE_CENTER, PUMP_CENTER, 2.5, trail_material)

func _add_trail_segment(node_name: String, from_position: Vector3, to_position: Vector3, width: float, material: Material) -> void:
    var delta: Vector3 = to_position - from_position
    delta.y = 0.0
    var length: float = delta.length()
    if length <= 0.1:
        return

    var trail: MeshInstance3D = MeshInstance3D.new()
    trail.name = StringName(node_name)
    trail.position = (from_position + to_position) * 0.5
    trail.position.y = 0.012
    trail.rotation.y = atan2(delta.x, delta.z)

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(width, 0.025, length)
    trail.mesh = mesh
    trail.material_override = material
    world_root.add_child(trail)

func _build_far_forest_multimesh() -> void:
    var rng: RandomNumberGenerator = RandomNumberGenerator.new()
    rng.seed = 240824

    var positions: Array[Vector3] = []
    var attempts: int = 0
    while positions.size() < 180 and attempts < 900:
        attempts += 1
        var p: Vector3 = Vector3(
            rng.randf_range(MAP_MIN_X + 5.0, MAP_MAX_X - 5.0),
            0.0,
            rng.randf_range(-345.0, -105.0)
        )
        if _inside_clearance(p, CABIN_CENTER, 31.0):
            continue
        if _inside_clearance(p, HOUSE_CENTER, 17.0):
            continue
        if _inside_clearance(p, GAS_CENTER, 20.0):
            continue
        if _inside_clearance(p, WAREHOUSE_CENTER, 21.0):
            continue
        if _inside_clearance(p, PUMP_CENTER, 15.0):
            continue
        positions.append(p)

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
    trunks.name = "MegaForestTrunks"
    trunks.multimesh = trunk_multi
    world_root.add_child(trunks)

    var crowns: MultiMeshInstance3D = MultiMeshInstance3D.new()
    crowns.name = "MegaForestCrowns"
    crowns.multimesh = crown_multi
    world_root.add_child(crowns)

func _inside_clearance(position_value: Vector3, center: Vector3, radius: float) -> bool:
    return Vector2(position_value.x - center.x, position_value.z - center.z).length() <= radius

func _build_readability_lights() -> void:
    natural_fill = DirectionalLight3D.new()
    natural_fill.name = "NaturalObjectFill"
    natural_fill.light_color = Color(0.48, 0.55, 0.63, 1.0)
    natural_fill.light_energy = NATURAL_FILL_ENERGY
    natural_fill.shadow_enabled = false
    natural_fill.rotation_degrees = Vector3(-55.0, 135.0, 0.0)
    world_root.add_child(natural_fill)

    # This OmniLight is gameplay daylight protection only. It turns off at
    # dusk/night, so the Darkness Creature rules remain intact after sunset.
    daylight_safety = OmniLight3D.new()
    daylight_safety.name = "MegaDaylightSafety"
    daylight_safety.position = Vector3(0.0, 8.0, -204.0)
    daylight_safety.light_color = Color(0.58, 0.62, 0.56, 1.0)
    daylight_safety.light_energy = 0.0
    daylight_safety.omni_range = 270.0
    daylight_safety.shadow_enabled = false
    world_root.add_child(daylight_safety)

func _apply_readability_lighting(scene: Node) -> void:
    if natural_fill != null and is_instance_valid(natural_fill):
        natural_fill.light_energy = NATURAL_FILL_ENERGY

    var world_environment: WorldEnvironment = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
    if world_environment == null or world_environment.environment == null:
        return
    var environment: Environment = world_environment.environment
    environment.ambient_light_energy = maxf(AMBIENT_FLOOR, environment.ambient_light_energy)

func _update_daylight_safety() -> void:
    if daylight_safety == null or not is_instance_valid(daylight_safety):
        return
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        daylight_safety.light_energy = 0.0
        return

    var minute: float = float(outside.get("game_minutes"))
    var daylight: float = 0.0
    if minute >= 420.0 and minute < 1020.0:
        daylight = 1.0
    elif minute >= 1020.0 and minute < 1140.0:
        daylight = 1.0 - clampf((minute - 1020.0) / 120.0, 0.0, 1.0)
    elif minute >= 300.0 and minute < 420.0:
        daylight = clampf((minute - 300.0) / 120.0, 0.0, 1.0)

    daylight_safety.light_energy = 0.12 if daylight >= 0.38 else 0.0

func _add_box_body(node_name: String, position_value: Vector3, size: Vector3, material: Material, collision_enabled: bool) -> StaticBody3D:
    var body: StaticBody3D = StaticBody3D.new()
    body.name = StringName(node_name)
    body.position = position_value
    world_root.add_child(body)

    var mesh_instance: MeshInstance3D = MeshInstance3D.new()
    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = size
    mesh_instance.mesh = mesh
    mesh_instance.material_override = material
    body.add_child(mesh_instance)

    if collision_enabled:
        var collision: CollisionShape3D = CollisionShape3D.new()
        var shape: BoxShape3D = BoxShape3D.new()
        shape.size = size
        collision.shape = shape
        body.add_child(collision)
    return body

func _add_invisible_wall(node_name: String, position_value: Vector3, size: Vector3) -> void:
    var body: StaticBody3D = StaticBody3D.new()
    body.name = StringName(node_name)
    body.position = position_value
    world_root.add_child(body)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = size
    collision.shape = shape
    body.add_child(collision)
