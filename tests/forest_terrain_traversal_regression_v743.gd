extends SceneTree

const FOREST_SCENE: String = "res://scenes/forest.tscn"
const ROUTE_POINTS = [
    Vector2(14.0, -67.0),
    Vector2(-70.0, -155.0),
    Vector2(76.0, -225.0),
    Vector2(-72.0, -286.0),
    Vector2(-98.0, -338.0)
]
const PUMP_BRANCH = [Vector2(-98.0, -338.0), Vector2(62.0, -332.0)]
const YARD_CENTERS = [
    Vector2(14.0, -82.0),
    Vector2(-70.0, -155.0),
    Vector2(76.0, -225.0),
    Vector2(-72.0, -286.0),
    Vector2(62.0, -332.0),
    Vector2(-98.0, -338.0)
]

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[TERRAIN v0.74.3] starting")
    var change_error: Error = change_scene_to_file(FOREST_SCENE)
    if change_error != OK:
        _fail("forest scene load failed: %s" % error_string(change_error))
        _finish()
        return

    var expansion: Node = null
    var player: CharacterBody3D = null
    var ready: bool = false
    for _frame: int in range(480):
        await process_frame
        expansion = root.get_node_or_null("ForestWorldExpansion")
        player = get_first_node_in_group("player") as CharacterBody3D
        if expansion == null or player == null:
            continue
        if expansion.has_method("is_forest_terrain_ready_v742") and bool(expansion.call("is_forest_terrain_ready_v742")):
            ready = true
            break

    if not ready or expansion == null or player == null:
        _fail("forest expanded terrain did not become ready")
        _finish()
        return

    _check_contracts(expansion)
    _check_visual_surface()
    _check_flat_yards(expansion)
    _check_route_smoothness(expansion, ROUTE_POINTS, "main route")
    _check_route_smoothness(expansion, PUMP_BRANCH, "pump branch")
    _check_open_forest_relief(expansion)
    await _check_floor_snap(player)
    _finish()

func _check_contracts(expansion: Node) -> void:
    if not expansion.has_method("get_terrain_traversal_contract_v743"):
        _fail("ForestWorldExpansion v0.74.3 traversal contract missing")
        return
    var contract: Dictionary = Dictionary(expansion.call("get_terrain_traversal_contract_v743"))
    var grid: Vector2i = Vector2i(contract.get("terrain_grid", Vector2i.ZERO))
    if grid.x < 84 or grid.y < 114:
        _fail("terrain grid resolution regressed: %s" % str(grid))
    if float(contract.get("route_relief_scale", 1.0)) > 0.20:
        _fail("quest route relief scale is too high")
    if float(contract.get("route_shoulder_m", 0.0)) < 12.0:
        _fail("quest route shoulder is too narrow")
    if not bool(contract.get("terrain_double_sided", false)):
        _fail("terrain double-sided visual contract is disabled")

    var movement: Node = root.get_node_or_null("MovementSystem")
    if movement == null or not movement.has_method("get_forest_traversal_movement_contract_v743"):
        _fail("MovementSystem v0.74.3 floor-snap contract missing")

func _check_visual_surface() -> void:
    var scene: Node = current_scene
    if scene == null:
        _fail("forest current_scene missing")
        return
    var mesh_instance: MeshInstance3D = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2/ForestTerrainV74/TerrainMesh") as MeshInstance3D
    if mesh_instance == null or mesh_instance.mesh == null:
        _fail("TerrainMesh missing")
        return
    if not mesh_instance.visible:
        _fail("TerrainMesh is hidden")

    var mesh: ArrayMesh = mesh_instance.mesh as ArrayMesh
    if mesh == null or mesh.get_surface_count() <= 0:
        _fail("TerrainMesh has no ArrayMesh surface")
        return
    var material: StandardMaterial3D = mesh.surface_get_material(0) as StandardMaterial3D
    if material == null:
        _fail("TerrainMesh material missing")
    elif material.cull_mode != BaseMaterial3D.CULL_DISABLED:
        _fail("TerrainMesh is still back-face culled")

    var arrays: Array = mesh.surface_get_arrays(0)
    var vertices: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
    var indices: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
    if vertices.size() < 9000:
        _fail("TerrainMesh vertex density too low: %d" % vertices.size())
    if indices.size() / 3 < 18000:
        _fail("TerrainMesh triangle density too low: %d" % (indices.size() / 3))

func _check_flat_yards(expansion: Node) -> void:
    for center: Vector2 in YARD_CENTERS:
        var h: float = float(expansion.call("sample_terrain_height_v74", center.x, center.y))
        if absf(h) > 0.01:
            _fail("yard center not flat at %s: %.4f m" % [str(center), h])

func _check_route_smoothness(expansion: Node, points: Array, label: String) -> void:
    var maximum_grade: float = 0.0
    var maximum_step: float = 0.0
    for segment_index: int in range(points.size() - 1):
        var start: Vector2 = Vector2(points[segment_index])
        var finish: Vector2 = Vector2(points[segment_index + 1])
        var length: float = start.distance_to(finish)
        var steps: int = maxi(2, int(ceil(length / 4.0)))
        var previous: Vector2 = start
        var previous_h: float = float(expansion.call("sample_terrain_height_v74", previous.x, previous.y))
        for index: int in range(1, steps + 1):
            var t: float = float(index) / float(steps)
            var current: Vector2 = start.lerp(finish, t)
            var current_h: float = float(expansion.call("sample_terrain_height_v74", current.x, current.y))
            var horizontal: float = maxf(0.001, previous.distance_to(current))
            var vertical: float = absf(current_h - previous_h)
            maximum_step = maxf(maximum_step, vertical)
            maximum_grade = maxf(maximum_grade, vertical / horizontal)
            previous = current
            previous_h = current_h

    if maximum_step > 0.28:
        _fail("%s has a vertical micro-step %.3f m" % [label, maximum_step])
    if maximum_grade > 0.075:
        _fail("%s grade too abrupt: %.2f%%" % [label, maximum_grade * 100.0])

func _check_open_forest_relief(expansion: Node) -> void:
    var samples: Array[float] = []
    for point: Vector2 in [Vector2(148.0, -458.0), Vector2(-162.0, -520.0), Vector2(8.0, -492.0), Vector2(58.0, -610.0)]:
        samples.append(float(expansion.call("sample_terrain_height_v74", point.x, point.y)))
    var min_h: float = samples[0]
    var max_h: float = samples[0]
    for h: float in samples:
        min_h = minf(min_h, h)
        max_h = maxf(max_h, h)
    if max_h - min_h < 1.5:
        _fail("open forest relief became too flat: range %.3f m" % (max_h - min_h))

func _check_floor_snap(player: CharacterBody3D) -> void:
    for _frame: int in range(6):
        await physics_frame
    if player.floor_snap_length < 0.50:
        _fail("forest floor snap too short: %.3f m" % player.floor_snap_length)
    if rad_to_deg(player.floor_max_angle) < 48.0:
        _fail("forest floor max angle too restrictive: %.2f deg" % rad_to_deg(player.floor_max_angle))

func _fail(message: String) -> void:
    failures.append(message)
    push_error("[TERRAIN v0.74.3] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[TERRAIN v0.74.3] PASS — visible terrain, smooth roads, flat yards, natural relief, and floor snap active")
        quit(0)
        return
    push_error("[TERRAIN v0.74.3] FAIL — %d issue(s)" % failures.size())
    quit(1)
