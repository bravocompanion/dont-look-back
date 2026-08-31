extends SceneTree

const FOREST_SCENE: String = "res://scenes/forest.tscn"
const TRAIL_NAMES: Array[String] = [
    "TrailCabinToHouse",
    "TrailHouseToGas",
    "TrailGasToWarehouse",
    "TrailWarehouseToMine",
    "TrailMineToPumpOptional"
]

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[PATHLESS FOREST v0.74.5] starting")
    var change_error: Error = change_scene_to_file(FOREST_SCENE)
    if change_error != OK:
        _fail("forest scene load failed: %s" % error_string(change_error))
        _finish()
        return

    var expansion: Node = null
    var ready: bool = false
    for _frame: int in range(420):
        await process_frame
        expansion = root.get_node_or_null("ForestWorldExpansion")
        if expansion == null:
            continue
        if expansion.has_method("is_forest_terrain_ready_v742") and bool(expansion.call("is_forest_terrain_ready_v742")):
            ready = true
            break

    if not ready or expansion == null:
        _fail("forest terrain did not become ready")
        _finish()
        return

    _check_contract(expansion)
    _check_no_path_geometry()
    _check_no_route_tree_reservation(expansion)
    _check_traversal_smoothing(expansion)
    _finish()

func _check_contract(expansion: Node) -> void:
    if not expansion.has_method("get_forest_path_contract_v745"):
        _fail("v0.74.5 path contract missing")
        return
    var contract: Dictionary = Dictionary(expansion.call("get_forest_path_contract_v745"))
    if str(contract.get("revision", "")) != "0.74.5":
        _fail("unexpected path revision: %s" % str(contract.get("revision", "missing")))
    if str(contract.get("visual_path_mode", "")) != "none":
        _fail("visual path mode is not none")
    if bool(contract.get("separate_path_geometry", true)):
        _fail("separate path geometry still enabled")
    if bool(contract.get("separate_path_collision", true)):
        _fail("separate path collision still enabled")
    if int(contract.get("legacy_path_mesh_count", -1)) != 0:
        _fail("legacy path mesh count is not zero")
    if not bool(contract.get("route_tree_clearance_removed", false)):
        _fail("route tree-clearance removal is not active")
    if str(contract.get("future_path_policy", "")) != "terrain color/material only":
        _fail("future path policy is not color/material only")

func _check_no_path_geometry() -> void:
    var scene: Node = current_scene
    if scene == null:
        _fail("current forest scene missing")
        return
    var world: Node = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2")
    if world == null:
        _fail("ForestMegaExpansionV2 root missing")
        return

    for trail_name: String in TRAIL_NAMES:
        if world.get_node_or_null(trail_name) != null:
            _fail("legacy path mesh still exists: %s" % trail_name)

    if str(world.get_meta("forest_path_visual_mode", "missing")) != "none":
        _fail("world metadata does not report pathless visual mode")
    if bool(world.get_meta("forest_path_geometry", true)):
        _fail("world metadata still reports path geometry")

func _check_no_route_tree_reservation(expansion: Node) -> void:
    if not expansion.has_method("_tree_position_clear_v74"):
        _fail("tree clearance helper missing")
        return
    # Midpoint between Gas and Warehouse, far from either mission plateau. In
    # older versions this was rejected solely because it sat on the route.
    var former_route_point: Vector2 = Vector2(2.0, -255.5)
    if not bool(expansion.call("_tree_position_clear_v74", former_route_point)):
        _fail("former route is still reserved as a tree-free corridor")

func _check_traversal_smoothing(expansion: Node) -> void:
    if not expansion.has_method("get_terrain_traversal_contract_v743"):
        _fail("v0.74.3 traversal smoothing contract missing")
        return
    var traversal: Dictionary = Dictionary(expansion.call("get_terrain_traversal_contract_v743"))
    if float(traversal.get("route_relief_scale", 1.0)) > 0.25:
        _fail("route traversal smoothing no longer preserved")
    if not bool(traversal.get("falloff_hardening_preserved", false)):
        _fail("falloff hardening preservation flag missing")

func _fail(message: String) -> void:
    failures.append(message)
    push_error("[PATHLESS FOREST v0.74.5] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[PATHLESS FOREST v0.74.5] PASS — no path mesh/collision/corridor; terrain smoothing preserved")
        quit(0)
        return
    push_error("[PATHLESS FOREST v0.74.5] FAIL — %d issue(s)" % failures.size())
    quit(1)
