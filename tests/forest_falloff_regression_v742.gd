extends SceneTree

const FOREST_SCENE: String = "res://scenes/forest.tscn"
const MIN_X: float = -224.0
const MAX_X: float = 224.0
const NEAR_Z: float = -52.0
const FAR_Z: float = -660.0
const SAFE_MARGIN: float = 1.25

var failures: Array[String] = []

func _initialize() -> void:
    call_deferred("_run")

func _run() -> void:
    print("[FALLOFF v0.74.2] starting")
    var change_error: Error = change_scene_to_file(FOREST_SCENE)
    if change_error != OK:
        _fail("forest scene load failed: %s" % error_string(change_error))
        _finish()
        return

    var player: CharacterBody3D = null
    var safety: Node = null
    var ready: bool = false
    for _frame: int in range(420):
        await process_frame
        player = get_first_node_in_group("player") as CharacterBody3D
        safety = root.get_node_or_null("ForestWorldExpansion")
        if player == null or safety == null:
            continue
        if safety.has_method("is_forest_terrain_ready_v742") and bool(safety.call("is_forest_terrain_ready_v742")):
            ready = true
            break

    if not ready or player == null or safety == null:
        _fail("expanded terrain collision/underlay did not become ready")
        _finish()
        return

    _check_runtime_contracts(safety)
    _check_collision_hardening()
    await _prime_safe_position(player, safety)
    _check_horizontal_containment(player, safety)
    _check_vertical_recovery(player, safety)
    _check_deep_return_position(player, safety)
    _finish()

func _check_runtime_contracts(safety: Node) -> void:
    for method_name: String in [
        "enforce_player_safety_v742",
        "is_forest_terrain_ready_v742",
        "get_fall_safety_contract_v742"
    ]:
        if not safety.has_method(method_name):
            _fail("ForestWorldExpansion missing %s" % method_name)

    var movement: Node = root.get_node_or_null("MovementSystem")
    if movement == null or not movement.has_method("get_forest_movement_safety_contract_v742"):
        _fail("MovementSystem v0.74.2 post-move safety is not active")

    var transition: Node = root.get_node_or_null("MapTransitionSystem")
    if transition == null or not transition.has_method("get_forest_transition_readiness_contract_v742"):
        _fail("MapTransitionSystem v0.74.2 terrain readiness is not active")

    var network: Node = root.get_node_or_null("NetworkManager")
    if network == null or not network.has_method("get_forest_remote_transform_contract_v742"):
        _fail("NetworkManager v0.74.2 remote-bound validation is not active")

func _check_collision_hardening() -> void:
    var scene: Node = current_scene
    if scene == null:
        _fail("forest current_scene missing")
        return

    var terrain: StaticBody3D = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2/ForestTerrainV74") as StaticBody3D
    if terrain == null:
        _fail("ForestTerrainV74 body missing")
        return
    var collision: CollisionShape3D = terrain.get_node_or_null("TerrainCollision") as CollisionShape3D
    if collision == null or collision.shape == null or collision.disabled:
        _fail("TerrainCollision missing/disabled")
    elif collision.shape is ConcavePolygonShape3D:
        var concave: ConcavePolygonShape3D = collision.shape as ConcavePolygonShape3D
        if not concave.backface_collision:
            _fail("terrain backface collision not enabled")
    else:
        _fail("TerrainCollision is not ConcavePolygonShape3D")

    var underlay: StaticBody3D = scene.get_node_or_null("OutsideWorld/ForestMegaExpansionV2/TerrainSafetyUnderlayV742") as StaticBody3D
    if underlay == null:
        _fail("TerrainSafetyUnderlayV742 missing")
        return
    var underlay_collision: CollisionShape3D = underlay.get_node_or_null("UnderlayCollision") as CollisionShape3D
    if underlay_collision == null or underlay_collision.shape == null or underlay_collision.disabled:
        _fail("underlay collision missing/disabled")

func _prime_safe_position(player: CharacterBody3D, safety: Node) -> void:
    player.global_position = Vector3(14.0, 0.92, -90.0)
    player.velocity = Vector3.ZERO
    for _frame: int in range(12):
        await physics_frame
    safety.call("enforce_player_safety_v742", player)

func _check_horizontal_containment(player: CharacterBody3D, safety: Node) -> void:
    player.global_position = Vector3(MAX_X + 9.0, 2.0, -200.0)
    player.velocity = Vector3(12.0, -3.0, 0.0)
    safety.call("enforce_player_safety_v742", player)
    if player.global_position.x > MAX_X - SAFE_MARGIN + 0.01:
        _fail("right-edge containment failed: x=%.3f" % player.global_position.x)
    if absf(player.velocity.x) > 0.001:
        _fail("right-edge outward velocity was not cancelled")

    player.global_position = Vector3(MIN_X - 9.0, 2.0, -200.0)
    player.velocity = Vector3(-12.0, -3.0, 0.0)
    safety.call("enforce_player_safety_v742", player)
    if player.global_position.x < MIN_X + SAFE_MARGIN - 0.01:
        _fail("left-edge containment failed: x=%.3f" % player.global_position.x)

    player.global_position = Vector3(0.0, 2.0, FAR_Z - 9.0)
    player.velocity = Vector3(0.0, -3.0, -12.0)
    safety.call("enforce_player_safety_v742", player)
    if player.global_position.z < FAR_Z + SAFE_MARGIN - 0.01:
        _fail("far-edge containment failed: z=%.3f" % player.global_position.z)

    player.global_position = Vector3(0.0, 2.0, NEAR_Z + 9.0)
    player.velocity = Vector3(0.0, -3.0, 12.0)
    safety.call("enforce_player_safety_v742", player)
    if player.global_position.z > NEAR_Z - SAFE_MARGIN + 0.01:
        _fail("near-edge containment failed: z=%.3f" % player.global_position.z)

func _check_vertical_recovery(player: CharacterBody3D, safety: Node) -> void:
    player.global_position = Vector3(14.0, -12.0, -90.0)
    player.velocity = Vector3(0.0, -30.0, 0.0)
    safety.call("enforce_player_safety_v742", player)
    if player.global_position.y < 0.70:
        _fail("vertical recovery failed: y=%.3f" % player.global_position.y)
    if player.velocity.length() > 0.001:
        _fail("vertical recovery did not clear velocity")

func _check_deep_return_position(player: CharacterBody3D, safety: Node) -> void:
    var deep_return: Vector3 = Vector3(-94.0, 0.92, -334.0)
    player.global_position = deep_return
    player.velocity = Vector3.ZERO
    safety.call("enforce_player_safety_v742", player)
    if player.global_position.z < FAR_Z + SAFE_MARGIN or player.global_position.z > NEAR_Z - SAFE_MARGIN:
        _fail("deep return spawn is outside hardened forest bounds")

func _fail(message: String) -> void:
    failures.append(message)
    push_error("[FALLOFF v0.74.2] %s" % message)

func _finish() -> void:
    if failures.is_empty():
        print("[FALLOFF v0.74.2] PASS — terrain collision, underlay, edge clamp, deep return, and recovery active")
        quit(0)
        return
    push_error("[FALLOFF v0.74.2] FAIL — %d issue(s)" % failures.size())
    quit(1)
