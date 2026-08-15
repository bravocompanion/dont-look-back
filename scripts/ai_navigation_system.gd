extends Node

@export var graph_link_distance: float = 13.5
@export var waypoint_reach_distance: float = 0.75
@export var path_clearance: float = 0.34
@export var search_duration: float = 6.0
@export var investigate_duration: float = 4.5
@export var hearing_radius: float = 17.0
@export var walk_noise_speed: float = 1.2
@export var sprint_noise_speed: float = 4.8
@export var noise_emit_interval: float = 0.42

var nav_graph: AStar3D = AStar3D.new()
var graph_scene_id: int = 0
var graph_ready: bool = false
var graph_retry_timer: float = 0.0
var graph_point_count: int = 0

var survivor_previous_positions: Dictionary = {}
var survivor_speeds: Dictionary = {}
var survivor_noise_cooldowns: Dictionary = {}
var noise_events: Array[Dictionary] = []

var tenant_memory: Dictionary = {}
var dark_memory: Dictionary = {}
var tenant_walk_hint: float = 1.65
var tenant_panic_hint: float = 2.35
var dark_speed_hint: float = 2.15
var solo_tenant_walk_hint: float = 1.65
var solo_tenant_panic_hint: float = 2.35
var solo_dark_speed_hints: Dictionary = {}
var last_dark_instance_id: int = 0

const CORRIDOR_PATROL: Array[Vector3] = [
    Vector3(0.0, 0.0, 8.0),
    Vector3(0.0, 0.0, 2.0),
    Vector3(0.0, 0.0, -5.0),
    Vector3(0.0, 0.0, -12.5)
]

const LABYRINTH_PATROL: Array[Vector3] = [
    Vector3(0.0, 0.0, -16.5),
    Vector3(6.8, 0.0, -19.0),
    Vector3(7.0, 0.0, -26.8),
    Vector3(-6.8, 0.0, -28.6),
    Vector3(-7.0, 0.0, -36.8),
    Vector3(6.8, 0.0, -37.5),
    Vector3(7.0, 0.0, -44.8),
    Vector3(-7.0, 0.0, -49.0)
]

const EXTERIOR_PATROL: Array[Vector3] = [
    Vector3(0.0, 0.0, -62.0),
    Vector3(14.0, 0.0, -76.0),
    Vector3(0.0, 0.0, -103.0),
    Vector3(-18.0, 0.0, -125.0),
    Vector3(-25.0, 0.0, -145.0),
    Vector3(22.0, 0.0, -156.0),
    Vector3(-8.0, 0.0, -180.0),
    Vector3(31.0, 0.0, -188.0),
    Vector3(-34.0, 0.0, -196.0),
    Vector3(38.0, 0.0, -195.0)
]

func _ready() -> void:
    tenant_memory = _new_memory()
    dark_memory = _new_memory()

func _process(delta: float) -> void:
    _check_scene_change()
    _age_noise_events(delta)
    _sample_survivor_motion(delta)
    _ensure_navigation_graph(delta)

    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online:
        var hosting: bool = network.has_method("is_server") and bool(network.call("is_server"))
        if not hosting:
            return
        _drive_online_host_ai(delta)
    else:
        _drive_solo_ai(delta)

func report_noise(position: Vector3, strength: float = 0.65, label: String = "noise", peer_id: int = 0) -> void:
    var clamped_strength: float = clampf(strength, 0.05, 1.5)
    noise_events.append({
        "position": position,
        "strength": clamped_strength,
        "label": label,
        "peer_id": peer_id,
        "ttl": 2.4
    })
    if noise_events.size() > 18:
        noise_events.pop_front()

func get_navigation_debug_state() -> Dictionary:
    return {
        "graph_ready": graph_ready,
        "graph_points": graph_point_count,
        "tenant_mode": str(tenant_memory.get("mode", "PATROL")),
        "dark_mode": str(dark_memory.get("mode", "PATROL")),
        "noise_events": noise_events.size()
    }

func _check_scene_change() -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var scene_id: int = int(scene.get_instance_id())
    if scene_id == graph_scene_id:
        return

    graph_scene_id = scene_id
    graph_ready = false
    graph_retry_timer = 0.75
    graph_point_count = 0
    nav_graph.clear()
    survivor_previous_positions.clear()
    survivor_speeds.clear()
    survivor_noise_cooldowns.clear()
    noise_events.clear()
    tenant_memory = _new_memory()
    dark_memory = _new_memory()
    solo_dark_speed_hints.clear()
    last_dark_instance_id = 0

func _ensure_navigation_graph(delta: float) -> void:
    if graph_ready:
        return
    graph_retry_timer = maxf(0.0, graph_retry_timer - delta)
    if graph_retry_timer > 0.0:
        return

    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var labyrinth: Node = scene.get_node_or_null("LabyrinthExpansion")
    var exterior: Node = scene.get_node_or_null("OutsideWorld/ExteriorExpansion")
    if labyrinth == null or exterior == null:
        graph_retry_timer = 0.35
        return

    _build_navigation_graph()
    if not graph_ready:
        graph_retry_timer = 0.55

func _build_navigation_graph() -> void:
    nav_graph.clear()
    var points: Array[Vector3] = _navigation_points()
    if points.is_empty():
        graph_ready = false
        return

    var point_id: int = 1
    for point: Vector3 in points:
        nav_graph.add_point(point_id, point)
        point_id += 1

    var ids: PackedInt64Array = nav_graph.get_point_ids()
    for first_index: int in range(ids.size()):
        var first_id: int = int(ids[first_index])
        var first_position: Vector3 = nav_graph.get_point_position(first_id)
        for second_index: int in range(first_index + 1, ids.size()):
            var second_id: int = int(ids[second_index])
            var second_position: Vector3 = nav_graph.get_point_position(second_id)
            var horizontal_distance: float = _horizontal_distance(first_position, second_position)
            if horizontal_distance > graph_link_distance:
                continue
            if _segment_clear(first_position, second_position, path_clearance):
                nav_graph.connect_points(first_id, second_id, true)

    graph_point_count = nav_graph.get_point_count()
    graph_ready = graph_point_count >= 4

func _navigation_points() -> Array[Vector3]:
    var points: Array[Vector3] = []

    for point: Vector3 in CORRIDOR_PATROL:
        points.append(point)

    var labyrinth_points: Array[Vector3] = [
        Vector3(0.0, 0.0, -15.8), Vector3(5.8, 0.0, -18.5), Vector3(7.2, 0.0, -22.2),
        Vector3(7.2, 0.0, -27.8), Vector3(1.0, 0.0, -28.5), Vector3(-6.8, 0.0, -28.5),
        Vector3(-7.2, 0.0, -32.0), Vector3(-7.2, 0.0, -37.2), Vector3(-0.5, 0.0, -37.5),
        Vector3(7.2, 0.0, -37.5), Vector3(7.2, 0.0, -41.8), Vector3(7.2, 0.0, -45.2),
        Vector3(0.5, 0.0, -45.5), Vector3(-7.2, 0.0, -45.5), Vector3(-7.2, 0.0, -49.2),
        Vector3(7.4, 0.0, -25.4), Vector3(-7.4, 0.0, -34.4), Vector3(7.4, 0.0, -43.4)
    ]
    for point: Vector3 in labyrinth_points:
        points.append(point)

    var outside_points: Array[Vector3] = [
        Vector3(0.0, 0.0, -56.5), Vector3(0.0, 0.0, -66.0), Vector3(6.0, 0.0, -75.0),
        Vector3(14.0, 0.0, -75.0), Vector3(14.0, 0.0, -83.0), Vector3(0.0, 0.0, -84.0),
        Vector3(-14.0, 0.0, -92.0), Vector3(14.0, 0.0, -100.0), Vector3(0.0, 0.0, -110.0),
        Vector3(-18.0, 0.0, -120.0), Vector3(18.0, 0.0, -122.0), Vector3(0.0, 0.0, -132.0),
        Vector3(0.0, 0.0, -143.0), Vector3(-12.0, 0.0, -150.0), Vector3(-19.0, 0.0, -145.5),
        Vector3(-25.0, 0.0, -145.2), Vector3(-25.0, 0.0, -148.3), Vector3(-28.0, 0.0, -151.0),
        Vector3(-22.0, 0.0, -151.0), Vector3(11.0, 0.0, -158.0), Vector3(17.0, 0.0, -158.0),
        Vector3(22.0, 0.0, -156.2), Vector3(25.5, 0.0, -160.4), Vector3(25.5, 0.0, -164.0),
        Vector3(0.0, 0.0, -165.0), Vector3(-14.0, 0.0, -170.0), Vector3(14.0, 0.0, -174.0),
        Vector3(0.0, 0.0, -180.0), Vector3(-8.0, 0.0, -180.7), Vector3(-8.0, 0.0, -184.0),
        Vector3(-14.2, 0.0, -185.0), Vector3(-8.0, 0.0, -187.0), Vector3(-1.8, 0.0, -185.0),
        Vector3(-14.2, 0.0, -191.0), Vector3(-8.0, 0.0, -191.5), Vector3(-1.8, 0.0, -191.0),
        Vector3(12.0, 0.0, -187.0), Vector3(22.0, 0.0, -188.0), Vector3(31.0, 0.0, -188.0),
        Vector3(-30.0, 0.0, -180.0), Vector3(-42.0, 0.0, -188.0), Vector3(-34.0, 0.0, -198.0),
        Vector3(18.0, 0.0, -197.0), Vector3(38.0, 0.0, -195.0), Vector3(0.0, 0.0, -199.0)
    ]
    for point: Vector3 in outside_points:
        points.append(point)
    return points

func _sample_survivor_motion(delta: float) -> void:
    if delta <= 0.0001:
        return
    var snapshots: Dictionary = _survivor_snapshots()
    var active_ids: Array[int] = []

    for peer_variant: Variant in snapshots.keys():
        var peer_id: int = int(peer_variant)
        active_ids.append(peer_id)
        var state: Dictionary = Dictionary(snapshots.get(peer_id, {}))
        var position_value: Variant = state.get("position", null)
        if not (position_value is Vector3):
            continue
        var position: Vector3 = position_value
        var previous_value: Variant = survivor_previous_positions.get(peer_id, position)
        var previous: Vector3 = position
        if previous_value is Vector3:
            previous = previous_value
        var speed: float = _horizontal_distance(previous, position) / delta
        survivor_previous_positions[peer_id] = position
        survivor_speeds[peer_id] = speed

        var cooldown: float = maxf(0.0, float(survivor_noise_cooldowns.get(peer_id, 0.0)) - delta)
        survivor_noise_cooldowns[peer_id] = cooldown
        if cooldown > 0.0 or bool(state.get("downed", false)):
            continue

        if speed >= sprint_noise_speed:
            report_noise(position, 1.0, "sprinting", peer_id)
            survivor_noise_cooldowns[peer_id] = noise_emit_interval
        elif speed >= walk_noise_speed:
            report_noise(position, 0.48, "footsteps", peer_id)
            survivor_noise_cooldowns[peer_id] = noise_emit_interval * 1.35

    for stored_variant: Variant in survivor_previous_positions.keys():
        var stored_id: int = int(stored_variant)
        if not active_ids.has(stored_id):
            survivor_previous_positions.erase(stored_id)
            survivor_speeds.erase(stored_id)
            survivor_noise_cooldowns.erase(stored_id)

func _survivor_snapshots() -> Dictionary:
    var result: Dictionary = {}
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))

    if online:
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop == null:
            return result
        var ids_value: Variant = coop.call("_get_active_peer_ids") if coop.has_method("_get_active_peer_ids") else []
        if ids_value is Array:
            var ids: Array = Array(ids_value)
            for peer_variant: Variant in ids:
                var peer_id: int = int(peer_variant)
                var state_value: Variant = coop.call("_get_survivor_state", peer_id) if coop.has_method("_get_survivor_state") else {}
                if not (state_value is Dictionary):
                    continue
                var state: Dictionary = Dictionary(state_value)
                var transform_value: Variant = state.get("transform", null)
                if not (transform_value is Transform3D):
                    continue
                var survivor_transform: Transform3D = transform_value
                result[peer_id] = {
                    "position": survivor_transform.origin,
                    "transform": survivor_transform,
                    "downed": bool(state.get("downed", false)),
                    "in_light": bool(state.get("in_light", false))
                }
        return result

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        var in_light: bool = player.has_method("is_in_light") and bool(player.call("is_in_light"))
        result[1] = {
            "position": player.global_position,
            "transform": player.global_transform,
            "downed": bool(player.get("is_dead")),
            "in_light": in_light
        }
    return result

func _age_noise_events(delta: float) -> void:
    var survivors: Array[Dictionary] = []
    for event: Dictionary in noise_events:
        var updated: Dictionary = event.duplicate(true)
        updated["ttl"] = float(updated.get("ttl", 0.0)) - delta
        if float(updated["ttl"]) > 0.0:
            survivors.append(updated)
    noise_events = survivors

func _drive_online_host_ai(delta: float) -> void:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return

    var current_tenant_walk: float = float(coop.get("tenant_walk_speed"))
    if current_tenant_walk > 0.05:
        tenant_walk_hint = current_tenant_walk
    var current_tenant_panic: float = float(coop.get("tenant_panic_speed"))
    if current_tenant_panic > 0.05:
        tenant_panic_hint = current_tenant_panic
    var current_dark_speed: float = float(coop.get("dark_move_speed"))
    if current_dark_speed > 0.05:
        dark_speed_hint = current_dark_speed

    coop.set("tenant_walk_speed", 0.0)
    coop.set("tenant_panic_speed", 0.0)
    coop.set("dark_move_speed", 0.0)

    if bool(coop.get("tenant_active")):
        var tenant: Node3D = _get_tenant()
        if tenant != null:
            var watched: bool = false
            if coop.has_method("_tenant_is_watched"):
                watched = bool(coop.call("_tenant_is_watched", tenant.global_position + Vector3(0.0, 1.35, 0.0)))
            if not watched:
                tenant_memory = _drive_monster_memory(tenant, tenant_memory, delta, false)
                var panic: float = float(coop.get("tenant_panic"))
                var speed: float = tenant_panic_hint if panic >= 60.0 else tenant_walk_hint
                _move_monster_to_memory_goal(tenant, tenant_memory, speed, delta, 1.25)

    if bool(coop.get("dark_active")):
        var dark_value: Variant = coop.get("dark_node")
        var dark_node: Node3D = dark_value as Node3D
        if dark_node != null and is_instance_valid(dark_node):
            _repair_dark_spawn_if_needed(dark_node)
            var lit_peer: int = 0
            if coop.has_method("_nearest_lit_survivor"):
                lit_peer = int(coop.call("_nearest_lit_survivor", dark_node.global_position, 6.5))
            if lit_peer <= 0:
                dark_memory = _drive_monster_memory(dark_node, dark_memory, delta, true)
                _move_monster_to_memory_goal(dark_node, dark_memory, dark_speed_hint, delta, 1.15)

func _drive_solo_ai(delta: float) -> void:
    var tenant: Node3D = _get_tenant()
    if tenant != null and bool(tenant.get("active")) and tenant.visible:
        var walk_speed: float = float(tenant.get("walk_speed"))
        if walk_speed > 0.05:
            solo_tenant_walk_hint = walk_speed
        var panic_speed: float = float(tenant.get("panic_speed"))
        if panic_speed > 0.05:
            solo_tenant_panic_hint = panic_speed
        tenant.set("walk_speed", 0.0)
        tenant.set("panic_speed", 0.0)

        var watched: bool = _survivor_watches_position(tenant.global_position + Vector3(0.0, 1.35, 0.0))
        if not watched and bool(tenant.get("can_move")):
            tenant_memory = _drive_monster_memory(tenant, tenant_memory, delta, false)
            var panic: float = float(tenant.get("panic"))
            var speed: float = solo_tenant_panic_hint if panic >= 60.0 else solo_tenant_walk_hint
            _move_monster_to_memory_goal(tenant, tenant_memory, speed, delta, 1.25)

    var dark: Node3D = get_tree().get_first_node_in_group("darkness_creature") as Node3D
    if dark == null or not is_instance_valid(dark):
        return

    _repair_dark_spawn_if_needed(dark)
    var dark_id: int = int(dark.get_instance_id())
    var move_speed: float = float(dark.get("move_speed"))
    if move_speed > 0.05:
        solo_dark_speed_hints[dark_id] = move_speed
    var speed_hint: float = float(solo_dark_speed_hints.get(dark_id, dark_speed_hint))
    dark.set("move_speed", 0.0)

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    var player_in_light: bool = player != null and player.has_method("is_in_light") and bool(player.call("is_in_light"))
    if not player_in_light:
        dark_memory = _drive_monster_memory(dark, dark_memory, delta, true)
        _move_monster_to_memory_goal(dark, dark_memory, speed_hint, delta, 1.15)

func _drive_monster_memory(monster: Node3D, memory: Dictionary, delta: float, darkness: bool) -> Dictionary:
    var updated: Dictionary = memory.duplicate(true)
    var visible_peer: int = _select_visible_survivor(monster.global_position, darkness)
    if visible_peer > 0:
        var visible_position: Variant = _survivor_position(visible_peer)
        if visible_position is Vector3:
            updated["mode"] = "CHASE"
            updated["target_peer"] = visible_peer
            updated["last_known"] = visible_position
            updated["search_timer"] = search_duration
            updated["investigate_timer"] = 0.0
            return updated

    var noise: Dictionary = _best_audible_noise(monster.global_position)
    if not noise.is_empty():
        var noise_position: Variant = noise.get("position", null)
        if noise_position is Vector3:
            updated["mode"] = "INVESTIGATE"
            updated["target_peer"] = int(noise.get("peer_id", 0))
            updated["last_known"] = noise_position
            updated["investigate_timer"] = investigate_duration
            updated["search_timer"] = search_duration
            return updated

    var investigate_timer: float = maxf(0.0, float(updated.get("investigate_timer", 0.0)) - delta)
    updated["investigate_timer"] = investigate_timer
    if investigate_timer > 0.0:
        updated["mode"] = "INVESTIGATE"
        return updated

    var search_timer: float = maxf(0.0, float(updated.get("search_timer", 0.0)) - delta)
    updated["search_timer"] = search_timer
    if search_timer > 0.0:
        updated["mode"] = "SEARCH"
        return updated

    updated["mode"] = "PATROL"
    updated["target_peer"] = 0
    var patrol: Array[Vector3] = _patrol_for_position(monster.global_position)
    if not patrol.is_empty():
        var patrol_index: int = int(updated.get("patrol_index", 0)) % patrol.size()
        var patrol_point: Vector3 = patrol[patrol_index]
        if _horizontal_distance(monster.global_position, patrol_point) <= 1.2:
            patrol_index = (patrol_index + 1) % patrol.size()
            updated["patrol_index"] = patrol_index
            patrol_point = patrol[patrol_index]
        updated["last_known"] = patrol_point
    return updated

func _move_monster_to_memory_goal(monster: Node3D, memory: Dictionary, speed: float, delta: float, look_height: float) -> void:
    if speed <= 0.01:
        return
    var goal_value: Variant = memory.get("last_known", null)
    if not (goal_value is Vector3):
        return
    var goal: Vector3 = goal_value
    var next_point: Vector3 = _next_navigation_point(monster.global_position, goal)
    next_point.y = monster.global_position.y

    var direction: Vector3 = next_point - monster.global_position
    direction.y = 0.0
    if direction.length() <= 0.03:
        return
    direction = direction.normalized()
    monster.global_position += direction * speed * delta
    monster.global_position = _clamp_monster_position(monster.global_position)
    var look_target: Vector3 = monster.global_position + direction
    look_target.y = monster.global_position.y + look_height
    monster.look_at(look_target, Vector3.UP)

func _next_navigation_point(origin: Vector3, target: Vector3) -> Vector3:
    if _segment_clear(origin, target, path_clearance * 0.85):
        return target
    if not graph_ready or nav_graph.get_point_count() <= 0:
        return target

    var start_id: int = nav_graph.get_closest_point(origin)
    var end_id: int = nav_graph.get_closest_point(target)
    if start_id < 0 or end_id < 0:
        return target

    var path: PackedVector3Array = nav_graph.get_point_path(start_id, end_id, true)
    if path.is_empty():
        return target

    for point: Vector3 in path:
        if _horizontal_distance(origin, point) > waypoint_reach_distance:
            return Vector3(point.x, origin.y, point.z)
    return target

func _select_visible_survivor(monster_position: Vector3, darkness: bool) -> int:
    var snapshots: Dictionary = _survivor_snapshots()
    var best_peer: int = 0
    var best_score: float = INF
    for peer_variant: Variant in snapshots.keys():
        var peer_id: int = int(peer_variant)
        var state: Dictionary = Dictionary(snapshots.get(peer_id, {}))
        if bool(state.get("downed", false)):
            continue
        if darkness and bool(state.get("in_light", false)):
            continue
        var position_value: Variant = state.get("position", null)
        if not (position_value is Vector3):
            continue
        var position: Vector3 = position_value
        var distance: float = _horizontal_distance(monster_position, position)
        if distance > 25.0:
            continue
        if not _segment_clear(monster_position, position, 0.0):
            continue
        var speed: float = float(survivor_speeds.get(peer_id, 0.0))
        var score: float = distance - minf(5.0, speed * 0.65)
        if score < best_score:
            best_score = score
            best_peer = peer_id
    return best_peer

func _best_audible_noise(monster_position: Vector3) -> Dictionary:
    var best: Dictionary = {}
    var best_score: float = 0.0
    for event: Dictionary in noise_events:
        var position_value: Variant = event.get("position", null)
        if not (position_value is Vector3):
            continue
        var position: Vector3 = position_value
        var strength: float = float(event.get("strength", 0.0))
        var radius: float = hearing_radius * strength
        var distance: float = _horizontal_distance(monster_position, position)
        if distance > radius:
            continue
        var score: float = strength * (1.0 - distance / maxf(radius, 0.1))
        if score > best_score:
            best_score = score
            best = event.duplicate(true)
    return best

func _survivor_position(peer_id: int) -> Variant:
    var snapshots: Dictionary = _survivor_snapshots()
    var state: Dictionary = Dictionary(snapshots.get(peer_id, {}))
    if state.is_empty():
        return null
    return state.get("position", null)

func _survivor_watches_position(focus_position: Vector3) -> bool:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return false
    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return false
    if not camera.is_position_in_frustum(focus_position):
        return false
    var forward: Vector3 = -camera.global_transform.basis.z.normalized()
    var to_focus: Vector3 = focus_position - camera.global_position
    if to_focus.length() <= 0.01:
        return true
    to_focus = to_focus.normalized()
    if forward.dot(to_focus) < 0.72:
        return false
    return _segment_clear(camera.global_position, focus_position, 0.0)

func _segment_clear(from_position: Vector3, to_position: Vector3, clearance: float) -> bool:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return true
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null or player.get_world_3d() == null:
        return true

    var start: Vector3 = Vector3(from_position.x, maxf(0.75, from_position.y + 0.85), from_position.z)
    var finish: Vector3 = Vector3(to_position.x, maxf(0.75, to_position.y + 0.85), to_position.z)
    var direction: Vector3 = finish - start
    direction.y = 0.0
    var side: Vector3 = Vector3.ZERO
    if direction.length() > 0.01:
        direction = direction.normalized()
        side = Vector3(-direction.z, 0.0, direction.x) * clearance

    var offsets: Array[Vector3] = [Vector3.ZERO]
    if clearance > 0.01:
        offsets.append(side)
        offsets.append(-side)

    var excludes: Array[RID] = []
    excludes.append(player.get_rid())
    for offset: Vector3 in offsets:
        var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(start + offset, finish + offset)
        query.exclude = excludes
        var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
        if not hit.is_empty():
            var collider_value: Variant = hit.get("collider", null)
            if collider_value is CharacterBody3D:
                continue
            return false
    return true

func _repair_dark_spawn_if_needed(dark: Node3D) -> void:
    var instance_id: int = int(dark.get_instance_id())
    if instance_id == last_dark_instance_id:
        return
    last_dark_instance_id = instance_id
    dark_memory = _new_memory()

    if not graph_ready:
        return
    if _position_has_clearance(dark.global_position):
        return
    var closest_id: int = nav_graph.get_closest_point(dark.global_position)
    if closest_id < 0:
        return
    var safe_point: Vector3 = nav_graph.get_point_position(closest_id)
    dark.global_position = Vector3(safe_point.x, dark.global_position.y, safe_point.z)

func _position_has_clearance(position: Vector3) -> bool:
    var offsets: Array[Vector3] = [
        Vector3(0.42, 0.0, 0.0), Vector3(-0.42, 0.0, 0.0),
        Vector3(0.0, 0.0, 0.42), Vector3(0.0, 0.0, -0.42)
    ]
    for offset: Vector3 in offsets:
        if not _segment_clear(position, position + offset, 0.0):
            return false
    return true

func _patrol_for_position(position: Vector3) -> Array[Vector3]:
    if position.z > -14.5:
        return CORRIDOR_PATROL.duplicate()
    if position.z > -53.0:
        return LABYRINTH_PATROL.duplicate()
    return EXTERIOR_PATROL.duplicate()

func _clamp_monster_position(position: Vector3) -> Vector3:
    var result: Vector3 = position
    if result.z > -14.5:
        result.x = clampf(result.x, -1.45, 1.45)
        result.z = clampf(result.z, -13.8, 10.5)
    elif result.z > -53.0:
        result.x = clampf(result.x, -9.35, 9.35)
        result.z = clampf(result.z, -51.0, -14.8)
    else:
        result.x = clampf(result.x, -54.0, 54.0)
        result.z = clampf(result.z, -202.0, -53.0)
    return result

func _horizontal_distance(first: Vector3, second: Vector3) -> float:
    return Vector2(first.x - second.x, first.z - second.z).length()

func _new_memory() -> Dictionary:
    return {
        "mode": "PATROL",
        "target_peer": 0,
        "last_known": Vector3.ZERO,
        "search_timer": 0.0,
        "investigate_timer": 0.0,
        "patrol_index": 0
    }

func _get_tenant() -> Node3D:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return null
    return scene.get_node_or_null("Monster") as Node3D
