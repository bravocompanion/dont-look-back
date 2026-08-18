extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const YARD_CENTER: Vector3 = Vector3(14.0, 0.0, -82.0)
const YARD_HALF_SIZE: Vector2 = Vector2(15.0, 15.0)
const YARD_MIN_X: float = -1.0
const YARD_MAX_X: float = 29.0
const YARD_MIN_Z: float = -97.0
const YARD_MAX_Z: float = -67.0
const EVICT_MARGIN: float = 2.0
const RESOURCE_FRONT_Z: float = -63.5
const SCAN_INTERVAL: float = 0.20

var scan_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        _restore_solo_directors()
        return

    scan_timer -= delta
    if scan_timer > 0.0:
        return
    scan_timer = SCAN_INTERVAL

    var local_player: CharacterBody3D = _local_player()
    var local_safe: bool = local_player != null and is_position_safe(local_player.global_position)

    if local_safe:
        _protect_player(local_player)

    _enforce_solo_threat_state(scene, local_safe)
    _enforce_coop_threat_state()
    _evict_group("darkness_creature", true)
    _evict_group("coop_darkness_creature", true)
    _evict_group("wildlife", false)
    _evict_group("enemy", false)
    _evict_group("hostile", false)
    _evict_group("monster", false)
    _evict_group("tenant", false)
    _evict_group("warden", false)
    _evict_named_tenant(scene, local_safe)
    _relocate_dynamic_resources(scene)

func is_position_safe(world_position: Vector3) -> bool:
    return (
        world_position.x >= YARD_MIN_X
        and world_position.x <= YARD_MAX_X
        and world_position.z >= YARD_MIN_Z
        and world_position.z <= YARD_MAX_Z
    )

func is_player_safe(player: Node3D) -> bool:
    return player != null and is_position_safe(player.global_position)

func push_position_outside(world_position: Vector3, margin: float = EVICT_MARGIN) -> Vector3:
    if not is_position_safe(world_position):
        return world_position

    var left_distance: float = world_position.x - YARD_MIN_X
    var right_distance: float = YARD_MAX_X - world_position.x
    var front_distance: float = world_position.z - YARD_MIN_Z
    var back_distance: float = YARD_MAX_Z - world_position.z
    var nearest: float = minf(minf(left_distance, right_distance), minf(front_distance, back_distance))
    var result: Vector3 = world_position

    if is_equal_approx(nearest, left_distance):
        result.x = YARD_MIN_X - margin
    elif is_equal_approx(nearest, right_distance):
        result.x = YARD_MAX_X + margin
    elif is_equal_approx(nearest, front_distance):
        result.z = YARD_MIN_Z - margin
    else:
        result.z = YARD_MAX_Z + margin
    return result

func _local_player() -> CharacterBody3D:
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return get_tree().get_first_node_in_group("player") as CharacterBody3D

func _protect_player(player: CharacterBody3D) -> void:
    if player == null:
        return
    if _has_property(player, "darkness_exposure"):
        player.set("darkness_exposure", 0.0)
    if _has_property(player, "flashlight_panic"):
        player.set("flashlight_panic", 0.0)

func _enforce_solo_threat_state(scene: Node, local_safe: bool) -> void:
    if _network_online():
        _restore_solo_directors()
        return

    var darkness: Node = get_node_or_null("/root/DarknessDirector")
    if darkness != null:
        darkness.set_process(not local_safe)
        if local_safe and _has_property(darkness, "spawn_cooldown"):
            darkness.set("spawn_cooldown", maxf(2.0, float(darkness.get("spawn_cooldown"))))

    var night_threat: Node = get_node_or_null("/root/NightThreatSystem")
    if night_threat != null:
        night_threat.set_process(not local_safe)

    if not local_safe:
        return

    var tenant: Node = scene.get_node_or_null("Monster")
    if tenant != null and tenant.has_method("stop_stalking"):
        tenant.call("stop_stalking")

    for creature: Node in get_tree().get_nodes_in_group("darkness_creature"):
        if is_instance_valid(creature):
            creature.queue_free()

func _restore_solo_directors() -> void:
    if _network_online():
        return
    var darkness: Node = get_node_or_null("/root/DarknessDirector")
    if darkness != null and not darkness.is_processing():
        darkness.set_process(true)
    var night_threat: Node = get_node_or_null("/root/NightThreatSystem")
    if night_threat != null and not night_threat.is_processing():
        night_threat.set_process(true)

func _enforce_coop_threat_state() -> void:
    if not _network_online():
        return
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null:
        return

    var tenant_target: int = int(coop.get("tenant_target_peer"))
    if bool(coop.get("tenant_active")) and tenant_target > 0 and _peer_is_safe(coop, tenant_target):
        if coop.has_method("request_tenant_stop"):
            coop.call("request_tenant_stop")

    var dark_target: int = int(coop.get("dark_target_peer"))
    if not bool(coop.get("dark_active")) or dark_target <= 0 or not _peer_is_safe(coop, dark_target):
        return

    var network: Node = get_node_or_null("/root/NetworkManager")
    var hosting: bool = network != null and network.has_method("is_server") and bool(network.call("is_server"))
    if not hosting:
        return

    coop.set("dark_active", false)
    coop.set("dark_target_peer", 0)
    coop.set("dark_spawn_cooldown", maxf(4.0, float(coop.get("dark_spawn_cooldown"))))
    var dark_variant: Variant = coop.get("dark_node")
    if dark_variant is Node and is_instance_valid(dark_variant):
        (dark_variant as Node).queue_free()
    coop.set("dark_node", null)

func _peer_is_safe(coop: Node, peer_id: int) -> bool:
    if peer_id <= 0:
        return false
    if peer_id == multiplayer.get_unique_id():
        var player: CharacterBody3D = _local_player()
        return player != null and is_position_safe(player.global_position)

    var states: Dictionary = Dictionary(coop.get("survivor_states"))
    var state: Dictionary = Dictionary(states.get(peer_id, {}))
    if state.is_empty():
        return false
    var transform: Transform3D = state.get("transform", Transform3D.IDENTITY)
    return is_position_safe(transform.origin)

func _evict_group(group_name: StringName, despawn: bool) -> void:
    for node: Node in get_tree().get_nodes_in_group(group_name):
        var spatial: Node3D = node as Node3D
        if spatial == null or not is_instance_valid(spatial) or not is_position_safe(spatial.global_position):
            continue
        if despawn:
            spatial.queue_free()
            continue
        spatial.global_position = push_position_outside(spatial.global_position)
        if spatial is CharacterBody3D:
            (spatial as CharacterBody3D).velocity = Vector3.ZERO

func _evict_named_tenant(scene: Node, local_safe: bool) -> void:
    var tenant: Node3D = scene.get_node_or_null("Monster") as Node3D
    if tenant == null:
        return
    if local_safe and tenant.has_method("stop_stalking"):
        tenant.call("stop_stalking")
        return
    if is_position_safe(tenant.global_position):
        tenant.global_position = push_position_outside(tenant.global_position)

func _relocate_dynamic_resources(scene: Node) -> void:
    var stack: Array[Node] = [scene]
    while not stack.is_empty():
        var current: Node = stack.pop_back()
        for child: Node in current.get_children():
            stack.append(child)

        var spatial: Node3D = current as Node3D
        if spatial == null or not is_instance_valid(spatial) or not is_position_safe(spatial.global_position):
            continue
        if not _is_dynamic_resource(current):
            continue
        spatial.global_position = _resource_relocation_position(current, spatial.global_position.y)

func _is_dynamic_resource(node: Node) -> bool:
    var script: Script = node.get_script() as Script
    var script_path: String = script.resource_path.to_lower() if script != null else ""
    if script_path.contains("survival_pickup.gd"):
        return true
    if script_path.contains("forest_supply_cache.gd"):
        return true
    if script_path.contains("wildlife_carcass.gd"):
        return true
    if script_path.contains("wildlife_blood_mark.gd"):
        return true

    var lower_name: String = str(node.name).to_lower()
    return lower_name.contains("randomloot") or lower_name.contains("randomresource")

func _resource_relocation_position(node: Node, y_value: float) -> Vector3:
    var slot: int = absi(hash(str(node.name))) % 7
    var x_value: float = 5.0 + float(slot) * 3.0
    return Vector3(x_value, y_value, RESOURCE_FRONT_Z)

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _has_property(object: Object, property_name: String) -> bool:
    for property: Dictionary in object.get_property_list():
        if str(property.get("name", "")) == property_name:
            return true
    return false
