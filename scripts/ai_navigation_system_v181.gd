extends "res://scripts/ai_navigation_system.gd"

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const TENANT_FLASHLIGHT_SPEED_MULTIPLIER: float = 0.50

const ARC1_NAV_POINTS: Array[Vector3] = [
    Vector3(-7.0, 0.0, -52.0), Vector3(-7.0, 0.0, -57.5), Vector3(-11.0, 0.0, -61.0),
    Vector3(1.0, 0.0, -62.0), Vector3(11.0, 0.0, -62.0), Vector3(11.0, 0.0, -67.0),
    Vector3(-10.5, 0.0, -68.0), Vector3(-11.0, 0.0, -74.5), Vector3(1.0, 0.0, -74.5),
    Vector3(11.0, 0.0, -77.5), Vector3(0.0, 0.0, -81.5), Vector3(-10.5, 0.0, -84.5),
    Vector3(-11.0, 0.0, -90.0), Vector3(0.5, 0.0, -90.0), Vector3(11.0, 0.0, -91.0),
    Vector3(11.0, 0.0, -96.5), Vector3(-0.5, 0.0, -97.0), Vector3(-11.0, 0.0, -99.0),
    Vector3(-10.5, 0.0, -103.0), Vector3(0.0, 0.0, -104.5), Vector3(0.0, 0.0, -107.0),
    Vector3(-10.5, 0.0, -110.5), Vector3(-5.0, 0.0, -112.5), Vector3(5.0, 0.0, -112.5),
    Vector3(10.5, 0.0, -112.0), Vector3(10.5, 0.0, -118.0), Vector3(4.8, 0.0, -119.0),
    Vector3(-4.8, 0.0, -119.0), Vector3(-10.5, 0.0, -123.5), Vector3(0.0, 0.0, -125.5),
    Vector3(9.5, 0.0, -125.0), Vector3(0.0, 0.0, -128.5), Vector3(-8.0, 0.0, -131.0),
    Vector3(8.0, 0.0, -131.0), Vector3(-9.0, 0.0, -135.5), Vector3(0.0, 0.0, -135.5),
    Vector3(9.0, 0.0, -135.5), Vector3(0.0, 0.0, -139.0)
]

const ARC1_PATROL: Array[Vector3] = [
    Vector3(-7.0, 0.0, -56.0),
    Vector3(10.5, 0.0, -66.5),
    Vector3(-10.5, 0.0, -74.0),
    Vector3(-10.5, 0.0, -88.0),
    Vector3(10.5, 0.0, -98.0),
    Vector3(-9.5, 0.0, -111.0),
    Vector3(9.5, 0.0, -119.0),
    Vector3(-9.5, 0.0, -124.0),
    Vector3(0.0, 0.0, -135.0)
]

func _ensure_navigation_graph(delta: float) -> void:
    if graph_ready:
        return
    graph_retry_timer = maxf(0.0, graph_retry_timer - delta)
    if graph_retry_timer > 0.0:
        return

    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    if scene.scene_file_path == LABYRINTH_SCENE_PATH:
        if scene.get_node_or_null("LabyrinthExpansion") == null or scene.get_node_or_null("Arc1Expansion") == null:
            graph_retry_timer = 0.35
            return
    elif scene.scene_file_path == FOREST_SCENE_PATH:
        if scene.get_node_or_null("OutsideWorld/ExteriorExpansion") == null:
            graph_retry_timer = 0.35
            return
    else:
        graph_retry_timer = 0.55
        return

    _build_navigation_graph()
    if not graph_ready:
        graph_retry_timer = 0.55

func _navigation_points() -> Array[Vector3]:
    var all_points: Array[Vector3] = super._navigation_points()
    var filtered: Array[Vector3] = []
    var scene: Node = get_tree().current_scene
    if scene == null:
        return filtered

    if scene.scene_file_path == LABYRINTH_SCENE_PATH:
        for point: Vector3 in all_points:
            if point.z > -53.0:
                filtered.append(point)
        for point: Vector3 in ARC1_NAV_POINTS:
            filtered.append(point)
    elif scene.scene_file_path == FOREST_SCENE_PATH:
        for point: Vector3 in all_points:
            if point.z <= -53.0:
                filtered.append(point)
    return filtered

func _patrol_for_position(position: Vector3) -> Array[Vector3]:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == LABYRINTH_SCENE_PATH and position.z <= -53.0:
        return ARC1_PATROL.duplicate()
    return super._patrol_for_position(position)

func _clamp_monster_position(position: Vector3) -> Vector3:
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == LABYRINTH_SCENE_PATH and position.z <= -53.0:
        return Vector3(
            clampf(position.x, -13.35, 13.35),
            position.y,
            clampf(position.z, -139.5, -52.0)
        )
    return super._clamp_monster_position(position)

func _drive_online_host_ai(delta: float) -> void:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return

    var current_dark_speed: float = float(coop.get("dark_move_speed"))
    if current_dark_speed > 0.05:
        dark_speed_hint = current_dark_speed
    coop.set("dark_move_speed", 0.0)

    if bool(coop.get("tenant_active")):
        var tenant: Node3D = _get_tenant()
        if tenant != null:
            var watched: bool = false
            if coop.has_method("_tenant_is_watched"):
                watched = bool(coop.call("_tenant_is_watched", tenant.global_position + Vector3(0.0, 1.35, 0.0)))
            var flashlight_hit: bool = _tenant_flashlight_contact_active()
            if (not watched or flashlight_hit) and bool(tenant.get("can_move")):
                tenant_memory = _drive_monster_memory(tenant, tenant_memory, delta, false)
                var speed: float = 1.65
                if tenant.has_method("get_current_move_speed"):
                    speed = float(tenant.call("get_current_move_speed"))
                elif coop.has_method("get_tenant_move_speed"):
                    speed = float(coop.call("get_tenant_move_speed"))
                if flashlight_hit:
                    speed *= TENANT_FLASHLIGHT_SPEED_MULTIPLIER
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
        var watched: bool = _survivor_watches_position(tenant.global_position + Vector3(0.0, 1.35, 0.0))
        var flashlight_hit: bool = _tenant_flashlight_contact_active()
        if (not watched or flashlight_hit) and bool(tenant.get("can_move")):
            tenant_memory = _drive_monster_memory(tenant, tenant_memory, delta, false)
            var speed: float = 1.65
            if tenant.has_method("get_current_move_speed"):
                speed = float(tenant.call("get_current_move_speed"))
            if flashlight_hit:
                speed *= TENANT_FLASHLIGHT_SPEED_MULTIPLIER
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

func _tenant_flashlight_contact_active() -> bool:
    if _network_online():
        var bridge: Node = get_node_or_null("/root/TenantPanicNetworkBridge")
        if bridge != null:
            var contacts_value: Variant = bridge.get("peer_flashlight_contact")
            if contacts_value is Dictionary:
                var contacts: Dictionary = Dictionary(contacts_value)
                for contact_variant: Variant in contacts.values():
                    if bool(contact_variant):
                        return true
        return false

    var panic_system: Node = get_node_or_null("/root/PanicTenantSystem")
    return panic_system != null and panic_system.has_method("is_tenant_in_flashlight") and bool(panic_system.call("is_tenant_in_flashlight"))

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))
