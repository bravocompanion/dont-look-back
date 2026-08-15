extends Node

@export var survivor_send_interval: float = 0.10
@export var monster_send_interval: float = 0.08
@export var revive_duration: float = 3.0
@export var revive_distance: float = 2.8
@export var revive_health: float = 45.0
@export var team_wipe_delay: float = 2.0
@export var tenant_walk_speed: float = 1.65
@export var tenant_panic_speed: float = 2.35
@export var tenant_attack_damage: float = 28.0
@export var tenant_attack_distance: float = 1.15
@export var tenant_watch_dot: float = 0.72
@export var dark_move_speed: float = 2.15
@export var dark_retreat_speed: float = 4.2
@export var dark_attack_damage: float = 18.0
@export var dark_attack_distance: float = 1.15
@export var dark_spawn_threshold: float = 72.0

var survivor_send_timer: float = 0.0
var monster_send_timer: float = 0.0
var tenant_attack_timer: float = 0.0
var dark_attack_timer: float = 0.0
var dark_spawn_cooldown: float = 5.0
var dark_light_escape_timer: float = -1.0
var team_wipe_timer: float = 2.0
var current_scene_id: int = 0
var local_player_instance_id: int = 0
var online_mode_active: bool = false

var local_downed: bool = false
var local_downed_source: String = ""
var survivor_states: Dictionary = {}
var revive_channels: Dictionary = {}

var tenant_active: bool = false
var tenant_panic: float = 0.0
var tenant_target_peer: int = 0
var dark_active: bool = false
var dark_target_peer: int = 0
var dark_node: Node3D

var revive_script: Script
var downed_layer: CanvasLayer
var downed_overlay: ColorRect
var downed_title: Label
var downed_help: Label

func _ready() -> void:
    revive_script = load("res://scripts/revive_interactable.gd") as Script
    team_wipe_timer = team_wipe_delay
    _build_downed_ui()

func _process(delta: float) -> void:
    _check_scene_change()

    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))

    if online and not online_mode_active:
        _enter_online_mode()
    elif not online and online_mode_active:
        _leave_online_mode()

    if not online:
        return

    _ensure_online_scene_control()
    _detect_local_death()
    _attach_revive_interactables()

    survivor_send_timer -= delta
    if survivor_send_timer <= 0.0:
        survivor_send_timer = survivor_send_interval
        _send_local_survivor_state()

    var hosting: bool = network.has_method("is_server") and bool(network.call("is_server"))
    if hosting:
        tenant_attack_timer = maxf(0.0, tenant_attack_timer - delta)
        dark_attack_timer = maxf(0.0, dark_attack_timer - delta)
        dark_spawn_cooldown = maxf(0.0, dark_spawn_cooldown - delta)
        _update_revive_channels(delta)
        _update_tenant(delta)
        _update_darkness_creature(delta)
        _update_team_wipe(delta)

        monster_send_timer -= delta
        if monster_send_timer <= 0.0:
            monster_send_timer = monster_send_interval
            _broadcast_monster_state()

func request_tenant_encounter() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return
    if network.has_method("is_server") and bool(network.call("is_server")):
        _server_start_tenant(1)
    else:
        _request_tenant_start.rpc_id(1)

func request_tenant_stop() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return
    if network.has_method("is_server") and bool(network.call("is_server")):
        _server_stop_tenant()
    else:
        _request_tenant_stop.rpc_id(1)

func request_revive(target_peer_id: int) -> void:
    if target_peer_id <= 0 or not is_survivor_downed(target_peer_id):
        return

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return

    if network.has_method("is_server") and bool(network.call("is_server")):
        _server_start_revive(1, target_peer_id)
    else:
        _request_revive.rpc_id(1, target_peer_id)

func is_survivor_downed(peer_id: int) -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("is_online") and bool(network.call("is_online")):
        if peer_id == multiplayer.get_unique_id():
            return local_downed
    var state: Dictionary = Dictionary(survivor_states.get(peer_id, {}))
    return bool(state.get("downed", false))

func damage_survivor(peer_id: int, amount: float, source_name: String) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_server") or not bool(network.call("is_server")):
        return
    _server_damage_survivor(peer_id, amount, source_name)

@rpc("any_peer", "call_remote", "reliable", 2)
func _request_tenant_start() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_server") or not bool(network.call("is_server")):
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    _server_start_tenant(sender_id)

@rpc("any_peer", "call_remote", "reliable", 2)
func _request_tenant_stop() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null and network.has_method("is_server") and bool(network.call("is_server")):
        _server_stop_tenant()

@rpc("any_peer", "call_remote", "unreliable", 2)
func _submit_survivor_state(state: Dictionary) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_server") or not bool(network.call("is_server")):
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    survivor_states[sender_id] = state.duplicate(true)
    _receive_survivor_state.rpc(sender_id, state)

@rpc("authority", "call_remote", "unreliable", 2)
func _receive_survivor_state(peer_id: int, state: Dictionary) -> void:
    if peer_id == multiplayer.get_unique_id():
        return
    survivor_states[peer_id] = state.duplicate(true)
    _update_remote_downed_visual(peer_id)

@rpc("any_peer", "call_remote", "reliable", 2)
func _request_revive(target_peer_id: int) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_server") or not bool(network.call("is_server")):
        return
    var reviver_peer_id: int = multiplayer.get_remote_sender_id()
    _server_start_revive(reviver_peer_id, target_peer_id)

@rpc("authority", "call_remote", "reliable", 2)
func _apply_network_damage(amount: float, source_name: String) -> void:
    _apply_local_authoritative_damage(amount, source_name)

@rpc("authority", "call_remote", "reliable", 2)
func _apply_network_revive(health_amount: float) -> void:
    _apply_local_revive(health_amount)

@rpc("authority", "call_remote", "reliable", 2)
func _revive_feedback(message: String) -> void:
    _set_local_objective(message)

@rpc("authority", "call_remote", "reliable", 2)
func _team_wipe_remote() -> void:
    _execute_team_wipe()

@rpc("authority", "call_remote", "unreliable", 3)
func _receive_monster_state(state: Dictionary) -> void:
    _apply_monster_state(state)

func _send_local_survivor_state() -> void:
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return

    var state: Dictionary = _collect_local_state(player)
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        return

    if network.has_method("is_server") and bool(network.call("is_server")):
        survivor_states[1] = state.duplicate(true)
        _receive_survivor_state.rpc(1, state)
    else:
        _submit_survivor_state.rpc_id(1, state)

func _collect_local_state(player: CharacterBody3D) -> Dictionary:
    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    var pitch: float = camera.rotation.x if camera != null else 0.0
    var in_light: bool = false
    if player.has_method("is_in_light"):
        in_light = bool(player.call("is_in_light"))

    return {
        "transform": player.global_transform,
        "pitch": pitch,
        "health": float(player.get("health")),
        "downed": local_downed,
        "darkness": float(player.get("darkness_exposure")),
        "in_light": in_light,
        "flashlight": flashlight != null and flashlight.visible and flashlight.light_energy > 0.35
    }

func _server_start_tenant(trigger_peer_id: int) -> void:
    if tenant_active:
        return

    var trigger_state: Dictionary = _get_survivor_state(trigger_peer_id)
    if trigger_state.is_empty():
        trigger_state = _get_survivor_state(1)
    if trigger_state.is_empty():
        return

    var survivor_transform: Transform3D = trigger_state.get("transform", Transform3D.IDENTITY)
    var behind: Vector3 = survivor_transform.basis.z.normalized() * 5.0
    var spawn_position: Vector3 = survivor_transform.origin + behind
    spawn_position.y = 0.0
    spawn_position.x = clampf(spawn_position.x, -1.35, 1.35)
    spawn_position.z = minf(spawn_position.z, 10.4)

    var tenant: Node3D = _get_tenant()
    if tenant == null:
        return

    tenant.global_position = spawn_position
    tenant.visible = true
    tenant.set("active", true)
    tenant.set("can_move", true)
    tenant_active = true
    tenant_panic = 12.0
    tenant_target_peer = trigger_peer_id
    tenant_attack_timer = 0.65
    _broadcast_monster_state()

func _server_stop_tenant() -> void:
    tenant_active = false
    tenant_target_peer = 0
    tenant_panic = 0.0
    tenant_attack_timer = 0.0
    var tenant: Node3D = _get_tenant()
    if tenant != null:
        tenant.visible = false
        tenant.set("active", false)
        tenant.set("can_move", false)
        tenant.set("panic", 0.0)
        if tenant.has_method("_update_hud"):
            tenant.call("_update_hud")
    _broadcast_monster_state()

func _update_tenant(delta: float) -> void:
    if not tenant_active:
        return

    var tenant: Node3D = _get_tenant()
    if tenant == null:
        tenant_active = false
        return

    var target_peer_id: int = _select_nearest_survivor(tenant.global_position)
    if target_peer_id <= 0:
        return
    tenant_target_peer = target_peer_id

    var target_state: Dictionary = _get_survivor_state(target_peer_id)
    var target_transform: Transform3D = target_state.get("transform", Transform3D.IDENTITY)
    var target_position: Vector3 = target_transform.origin
    target_position.y = tenant.global_position.y
    var distance: float = tenant.global_position.distance_to(target_position)
    var watched: bool = _tenant_is_watched(tenant.global_position + Vector3(0.0, 1.35, 0.0))

    if not watched:
        var direction: Vector3 = target_position - tenant.global_position
        direction.y = 0.0
        if direction.length() > 0.01:
            direction = direction.normalized()
            var speed: float = tenant_panic_speed if tenant_panic >= 60.0 else tenant_walk_speed
            tenant.global_position += direction * speed * delta
            tenant.look_at(Vector3(target_position.x, 1.25, target_position.z), Vector3.UP)

    distance = tenant.global_position.distance_to(target_position)
    if watched:
        if distance < 4.5:
            tenant_panic += (4.5 - distance) * 1.8 * delta
        else:
            tenant_panic -= 7.5 * delta
    else:
        var proximity: float = clampf(11.0 - distance, 0.0, 11.0)
        tenant_panic += (4.0 + proximity * 1.55) * delta
    tenant_panic = clampf(tenant_panic, 0.0, 100.0)

    tenant.set("panic", tenant_panic)
    if tenant.has_method("_update_hud"):
        tenant.call("_update_hud")

    if distance <= tenant_attack_distance and tenant_attack_timer <= 0.0:
        tenant_attack_timer = 2.4
        _server_damage_survivor(target_peer_id, tenant_attack_damage, "The Tenant")
        var retreat: Vector3 = tenant.global_position - target_position
        retreat.y = 0.0
        if retreat.length() <= 0.01:
            retreat = Vector3(0.0, 0.0, 1.0)
        else:
            retreat = retreat.normalized()
        tenant.global_position += retreat * 3.8
        tenant.global_position.x = clampf(tenant.global_position.x, -1.45, 1.45)
        tenant.global_position.z = clampf(tenant.global_position.z, -10.0, 10.4)

func _tenant_is_watched(monster_focus: Vector3) -> bool:
    var peer_ids: Array[int] = _get_active_peer_ids()
    for peer_id: int in peer_ids:
        var state: Dictionary = _get_survivor_state(peer_id)
        if state.is_empty() or bool(state.get("downed", false)):
            continue

        var survivor_transform: Transform3D = state.get("transform", Transform3D.IDENTITY)
        var pitch: float = float(state.get("pitch", 0.0))
        var camera_origin: Vector3 = survivor_transform.origin + Vector3(0.0, 0.58, 0.0)
        var view_basis: Basis = survivor_transform.basis.orthonormalized() * Basis(Vector3.RIGHT, pitch)
        var forward: Vector3 = -view_basis.z.normalized()
        var to_monster: Vector3 = monster_focus - camera_origin
        if to_monster.length() <= 0.01:
            return true
        to_monster = to_monster.normalized()
        if forward.dot(to_monster) < tenant_watch_dot:
            continue
        if _has_clear_line(camera_origin, monster_focus):
            return true
    return false

func _update_darkness_creature(delta: float) -> void:
    if not dark_active:
        if dark_spawn_cooldown > 0.0:
            return
        var candidate: int = _select_darkness_candidate()
        if candidate > 0:
            _spawn_shared_darkness(candidate)
        return

    _ensure_dark_visual()
    if dark_node == null or not is_instance_valid(dark_node):
        dark_active = false
        return

    var target_peer_id: int = _select_nearest_survivor(dark_node.global_position)
    if target_peer_id <= 0:
        _despawn_shared_darkness(4.0)
        return
    dark_target_peer = target_peer_id

    var lit_peer_id: int = _nearest_lit_survivor(dark_node.global_position, 6.5)
    if lit_peer_id > 0:
        var lit_state: Dictionary = _get_survivor_state(lit_peer_id)
        var lit_transform: Transform3D = lit_state.get("transform", Transform3D.IDENTITY)
        var away: Vector3 = dark_node.global_position - lit_transform.origin
        away.y = 0.0
        if away.length() <= 0.01:
            away = Vector3(0.0, 0.0, 1.0)
        else:
            away = away.normalized()
        dark_node.global_position += away * dark_retreat_speed * delta
        if dark_light_escape_timer < 0.0:
            dark_light_escape_timer = 0.78
        dark_light_escape_timer -= delta
        if dark_light_escape_timer <= 0.0:
            _despawn_shared_darkness(7.0)
        return

    dark_light_escape_timer = -1.0
    var target_state: Dictionary = _get_survivor_state(target_peer_id)
    var target_transform: Transform3D = target_state.get("transform", Transform3D.IDENTITY)
    var target_position: Vector3 = target_transform.origin
    target_position.y = dark_node.global_position.y
    var distance: float = dark_node.global_position.distance_to(target_position)

    if distance > 0.05:
        var direction: Vector3 = (target_position - dark_node.global_position).normalized()
        dark_node.global_position += direction * dark_move_speed * delta
        dark_node.look_at(Vector3(target_position.x, dark_node.global_position.y + 1.15, target_position.z), Vector3.UP)

    distance = dark_node.global_position.distance_to(target_position)
    if distance <= dark_attack_distance and dark_attack_timer <= 0.0:
        dark_attack_timer = 2.0
        _server_damage_survivor(target_peer_id, dark_attack_damage, "the darkness")
        var retreat: Vector3 = dark_node.global_position - target_position
        retreat.y = 0.0
        if retreat.length() <= 0.01:
            retreat = Vector3(0.0, 0.0, 1.0)
        else:
            retreat = retreat.normalized()
        dark_node.global_position += retreat * 2.8

func _spawn_shared_darkness(target_peer_id: int) -> void:
    var state: Dictionary = _get_survivor_state(target_peer_id)
    if state.is_empty():
        return
    var survivor_transform: Transform3D = state.get("transform", Transform3D.IDENTITY)
    var spawn_position: Vector3 = survivor_transform.origin + survivor_transform.basis.z.normalized() * 4.2
    spawn_position.y = survivor_transform.origin.y - 0.92
    dark_active = true
    dark_target_peer = target_peer_id
    dark_attack_timer = 0.6
    dark_light_escape_timer = -1.0
    _ensure_dark_visual()
    if dark_node != null:
        dark_node.global_position = spawn_position
    _set_objective_for_peer(target_peer_id, "Something is forming in the dark. GET TO THE LIGHT.")
    _broadcast_monster_state()

func _despawn_shared_darkness(cooldown: float) -> void:
    dark_active = false
    dark_target_peer = 0
    dark_spawn_cooldown = maxf(dark_spawn_cooldown, cooldown)
    dark_light_escape_timer = -1.0
    if dark_node != null and is_instance_valid(dark_node):
        dark_node.queue_free()
    dark_node = null

func _server_damage_survivor(peer_id: int, amount: float, source_name: String) -> void:
    if peer_id <= 0 or is_survivor_downed(peer_id):
        return
    if peer_id == 1:
        _apply_local_authoritative_damage(amount, source_name)
    else:
        _apply_network_damage.rpc_id(peer_id, amount, source_name)

    var state: Dictionary = _get_survivor_state(peer_id)
    if not state.is_empty():
        var predicted_health: float = maxf(0.0, float(state.get("health", 100.0)) - amount)
        state["health"] = predicted_health
        if predicted_health <= 0.0:
            state["downed"] = true
        survivor_states[peer_id] = state

func _apply_local_authoritative_damage(amount: float, source_name: String) -> void:
    if local_downed:
        return
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    var health: float = float(player.get("health"))
    if health - amount <= 0.0:
        player.set("health", 0.0)
        if player.has_method("_update_survival_hud"):
            player.call("_update_survival_hud")
        _enter_local_downed(source_name)
        return
    if player.has_method("apply_damage"):
        player.call("apply_damage", amount, source_name)

func _enter_local_downed(source_name: String) -> void:
    if local_downed:
        return
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return

    local_downed = true
    local_downed_source = source_name
    player.set("health", 0.0)
    player.set("is_dead", false)
    player.velocity = Vector3.ZERO
    player.set_process(false)
    player.set_physics_process(false)
    player.set_process_unhandled_input(false)

    var death_panel: Control = player.get_node_or_null("HUD/CaughtPanel") as Control
    if death_panel != null:
        death_panel.visible = false
    if player.has_method("_update_survival_hud"):
        player.call("_update_survival_hud")

    _show_downed_ui(true)
    downed_title.text = "YOU ARE DOWNED"
    downed_help.text = "A survivor must reach you and revive you.\nStay together. Light protects the team."
    Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _apply_local_revive(health_amount: float) -> void:
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return

    local_downed = false
    local_downed_source = ""
    player.set("is_dead", false)
    player.set("health", minf(float(player.get("max_health")), maxf(1.0, health_amount)))
    player.set("stamina", maxf(float(player.get("stamina")), 35.0))
    player.set_process(true)
    player.set_physics_process(true)
    player.set_process_unhandled_input(true)
    if player.has_method("_update_survival_hud"):
        player.call("_update_survival_hud")

    _show_downed_ui(false)
    _set_local_objective("You were revived. Find light and regroup.")

    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
    if not mobile_active:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _detect_local_death() -> void:
    if local_downed:
        return
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    if bool(player.get("is_dead")):
        _enter_local_downed("critical condition")

func _server_start_revive(reviver_peer_id: int, target_peer_id: int) -> void:
    if reviver_peer_id <= 0 or target_peer_id <= 0 or reviver_peer_id == target_peer_id:
        return
    if not is_survivor_downed(target_peer_id) or is_survivor_downed(reviver_peer_id):
        _feedback_to_peer(reviver_peer_id, "That survivor cannot be revived right now.")
        return
    if _survivor_distance(reviver_peer_id, target_peer_id) > revive_distance:
        _feedback_to_peer(reviver_peer_id, "Move closer to the downed survivor.")
        return

    revive_channels[reviver_peer_id] = {
        "target": target_peer_id,
        "progress": 0.0
    }
    _feedback_to_peer(reviver_peer_id, "Reviving... stay close for %.1f seconds." % revive_duration)

func _update_revive_channels(delta: float) -> void:
    var finished: Array[int] = []
    var cancelled: Array[int] = []

    for reviver_variant: Variant in revive_channels.keys():
        var reviver_peer_id: int = int(reviver_variant)
        var channel: Dictionary = Dictionary(revive_channels.get(reviver_peer_id, {}))
        var target_peer_id: int = int(channel.get("target", 0))

        if target_peer_id <= 0 or not is_survivor_downed(target_peer_id) or is_survivor_downed(reviver_peer_id):
            cancelled.append(reviver_peer_id)
            continue
        if _survivor_distance(reviver_peer_id, target_peer_id) > revive_distance:
            cancelled.append(reviver_peer_id)
            continue

        var progress: float = float(channel.get("progress", 0.0)) + delta
        channel["progress"] = progress
        revive_channels[reviver_peer_id] = channel
        if progress >= revive_duration:
            finished.append(reviver_peer_id)

    for reviver_peer_id: int in cancelled:
        revive_channels.erase(reviver_peer_id)
        _feedback_to_peer(reviver_peer_id, "Revive interrupted. Stay close and try again.")

    for reviver_peer_id: int in finished:
        var channel: Dictionary = Dictionary(revive_channels.get(reviver_peer_id, {}))
        var target_peer_id: int = int(channel.get("target", 0))
        revive_channels.erase(reviver_peer_id)
        if target_peer_id > 0:
            _server_revive_target(target_peer_id)
            _feedback_to_peer(reviver_peer_id, "Survivor %d revived." % target_peer_id)

func _server_revive_target(target_peer_id: int) -> void:
    var state: Dictionary = _get_survivor_state(target_peer_id)
    if not state.is_empty():
        state["downed"] = false
        state["health"] = revive_health
        survivor_states[target_peer_id] = state

    if target_peer_id == 1:
        _apply_local_revive(revive_health)
    else:
        _apply_network_revive.rpc_id(target_peer_id, revive_health)

func _update_team_wipe(delta: float) -> void:
    var peer_ids: Array[int] = _get_active_peer_ids()
    if peer_ids.is_empty():
        team_wipe_timer = team_wipe_delay
        return

    var all_downed: bool = true
    for peer_id: int in peer_ids:
        if not is_survivor_downed(peer_id):
            all_downed = false
            break

    if not all_downed:
        team_wipe_timer = team_wipe_delay
        return

    team_wipe_timer -= delta
    if team_wipe_timer > 0.0:
        return

    team_wipe_timer = team_wipe_delay
    _team_wipe_remote.rpc()
    _execute_team_wipe()

func _execute_team_wipe() -> void:
    local_downed = false
    _show_downed_ui(false)
    var tree: SceneTree = get_tree()
    tree.reload_current_scene()

func _broadcast_monster_state() -> void:
    var tenant: Node3D = _get_tenant()
    var tenant_transform: Transform3D = tenant.global_transform if tenant != null else Transform3D.IDENTITY
    var dark_transform: Transform3D = dark_node.global_transform if dark_node != null and is_instance_valid(dark_node) else Transform3D.IDENTITY
    var state: Dictionary = {
        "tenant_active": tenant_active,
        "tenant_transform": tenant_transform,
        "tenant_panic": tenant_panic,
        "tenant_target": tenant_target_peer,
        "dark_active": dark_active,
        "dark_transform": dark_transform,
        "dark_target": dark_target_peer
    }
    _receive_monster_state.rpc(state)

func _apply_monster_state(state: Dictionary) -> void:
    tenant_active = bool(state.get("tenant_active", false))
    tenant_panic = float(state.get("tenant_panic", 0.0))
    tenant_target_peer = int(state.get("tenant_target", 0))

    var tenant: Node3D = _get_tenant()
    if tenant != null:
        tenant.set_process(false)
        tenant.visible = tenant_active
        tenant.set("active", tenant_active)
        tenant.set("panic", tenant_panic)
        if tenant_active:
            tenant.global_transform = state.get("tenant_transform", tenant.global_transform)
        if tenant.has_method("_update_hud"):
            tenant.call("_update_hud")

    dark_active = bool(state.get("dark_active", false))
    dark_target_peer = int(state.get("dark_target", 0))
    if dark_active:
        _ensure_dark_visual()
        if dark_node != null:
            dark_node.global_transform = state.get("dark_transform", dark_node.global_transform)
    else:
        if dark_node != null and is_instance_valid(dark_node):
            dark_node.queue_free()
        dark_node = null

func _select_nearest_survivor(origin: Vector3) -> int:
    var best_peer_id: int = 0
    var best_distance: float = INF
    for peer_id: int in _get_active_peer_ids():
        var state: Dictionary = _get_survivor_state(peer_id)
        if state.is_empty() or bool(state.get("downed", false)):
            continue
        var survivor_transform: Transform3D = state.get("transform", Transform3D.IDENTITY)
        var distance: float = origin.distance_to(survivor_transform.origin)
        if distance < best_distance:
            best_distance = distance
            best_peer_id = peer_id
    return best_peer_id

func _select_darkness_candidate() -> int:
    var best_peer_id: int = 0
    var best_exposure: float = dark_spawn_threshold
    for peer_id: int in _get_active_peer_ids():
        var state: Dictionary = _get_survivor_state(peer_id)
        if state.is_empty() or bool(state.get("downed", false)) or bool(state.get("in_light", false)):
            continue
        var exposure: float = float(state.get("darkness", 0.0))
        if exposure >= best_exposure:
            best_exposure = exposure
            best_peer_id = peer_id
    return best_peer_id

func _nearest_lit_survivor(origin: Vector3, max_distance: float) -> int:
    var best_peer_id: int = 0
    var best_distance: float = max_distance
    for peer_id: int in _get_active_peer_ids():
        var state: Dictionary = _get_survivor_state(peer_id)
        if state.is_empty() or bool(state.get("downed", false)) or not bool(state.get("in_light", false)):
            continue
        var survivor_transform: Transform3D = state.get("transform", Transform3D.IDENTITY)
        var distance: float = origin.distance_to(survivor_transform.origin)
        if distance <= best_distance:
            best_distance = distance
            best_peer_id = peer_id
    return best_peer_id

func _survivor_distance(first_peer_id: int, second_peer_id: int) -> float:
    var first_state: Dictionary = _get_survivor_state(first_peer_id)
    var second_state: Dictionary = _get_survivor_state(second_peer_id)
    if first_state.is_empty() or second_state.is_empty():
        return INF
    var first_transform: Transform3D = first_state.get("transform", Transform3D.IDENTITY)
    var second_transform: Transform3D = second_state.get("transform", Transform3D.IDENTITY)
    return first_transform.origin.distance_to(second_transform.origin)

func _get_survivor_state(peer_id: int) -> Dictionary:
    if peer_id == multiplayer.get_unique_id():
        var player: CharacterBody3D = _get_local_player()
        if player != null:
            return _collect_local_state(player)
    return Dictionary(survivor_states.get(peer_id, {}))

func _get_active_peer_ids() -> Array[int]:
    var result: Array[int] = []
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return result

    if network.has_method("is_server") and bool(network.call("is_server")):
        result.append(1)
        var connected: PackedInt32Array = multiplayer.get_peers()
        for peer_id: int in connected:
            result.append(peer_id)
    else:
        result.append(multiplayer.get_unique_id())
        for peer_variant: Variant in survivor_states.keys():
            var peer_id: int = int(peer_variant)
            if not result.has(peer_id):
                result.append(peer_id)
    return result

func _has_clear_line(from_position: Vector3, to_position: Vector3) -> bool:
    var player: CharacterBody3D = _get_local_player()
    if player == null or player.get_world_3d() == null:
        return true

    var query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(from_position, to_position)
    var excludes: Array[RID] = []
    excludes.append(player.get_rid())

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        var avatar_values: Dictionary = Dictionary(network.get("remote_avatars"))
        for avatar_variant: Variant in avatar_values.values():
            var avatar: Node3D = avatar_variant as Node3D
            if avatar == null:
                continue
            var revive_body: StaticBody3D = avatar.get_node_or_null("ReviveCollider") as StaticBody3D
            if revive_body != null:
                excludes.append(revive_body.get_rid())

    query.exclude = excludes
    var hit: Dictionary = player.get_world_3d().direct_space_state.intersect_ray(query)
    return hit.is_empty()

func _attach_revive_interactables() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or revive_script == null:
        return

    var avatars: Dictionary = Dictionary(network.get("remote_avatars"))
    for peer_variant: Variant in avatars.keys():
        var peer_id: int = int(peer_variant)
        var avatar: Node3D = avatars.get(peer_id) as Node3D
        if avatar == null or not is_instance_valid(avatar):
            continue

        var revive_body: StaticBody3D = avatar.get_node_or_null("ReviveCollider") as StaticBody3D
        if revive_body == null:
            revive_body = StaticBody3D.new()
            revive_body.name = "ReviveCollider"
            revive_body.set_script(revive_script)
            revive_body.set("peer_id", peer_id)
            revive_body.collision_layer = 1
            revive_body.collision_mask = 0
            avatar.add_child(revive_body)

            var collision: CollisionShape3D = CollisionShape3D.new()
            var shape: CapsuleShape3D = CapsuleShape3D.new()
            shape.radius = 0.42
            shape.height = 1.75
            collision.shape = shape
            collision.position = Vector3(0.0, 0.10, 0.0)
            revive_body.add_child(collision)

        var state_label: Label3D = avatar.get_node_or_null("CoopDownedLabel") as Label3D
        if state_label == null:
            state_label = Label3D.new()
            state_label.name = "CoopDownedLabel"
            state_label.position = Vector3(0.0, 1.82, 0.0)
            state_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
            state_label.font_size = 26
            avatar.add_child(state_label)

        _update_remote_downed_visual(peer_id)

func _update_remote_downed_visual(peer_id: int) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        return
    var avatars: Dictionary = Dictionary(network.get("remote_avatars"))
    var avatar: Node3D = avatars.get(peer_id) as Node3D
    if avatar == null or not is_instance_valid(avatar):
        return

    var downed: bool = is_survivor_downed(peer_id)
    var state_label: Label3D = avatar.get_node_or_null("CoopDownedLabel") as Label3D
    if state_label != null:
        state_label.visible = downed
        state_label.text = "DOWNED\nUSE TO REVIVE" if downed else ""

    var body: MeshInstance3D = avatar.get_node_or_null("Body") as MeshInstance3D
    if body != null:
        body.rotation.z = 1.25 if downed else 0.0
        body.position.y = 0.08 if downed else 0.36

func _ensure_dark_visual() -> void:
    if dark_node != null and is_instance_valid(dark_node):
        return
    var scene: Node = get_tree().current_scene
    if scene == null or not (scene is Node3D):
        return

    var scene_3d: Node3D = scene as Node3D
    dark_node = Node3D.new()
    dark_node.name = "SharedDarknessCreature"
    dark_node.add_to_group("coop_darkness_creature")
    scene_3d.add_child(dark_node)

    var body_mesh: CapsuleMesh = CapsuleMesh.new()
    body_mesh.radius = 0.30
    body_mesh.height = 2.35
    body_mesh.radial_segments = 10
    body_mesh.rings = 5
    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    body_material.albedo_color = Color(0.001, 0.001, 0.002, 1.0)
    body_material.roughness = 1.0
    var body: MeshInstance3D = MeshInstance3D.new()
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 1.25, 0.0)
    dark_node.add_child(body)

    var eye_mesh: SphereMesh = SphereMesh.new()
    eye_mesh.radius = 0.04
    eye_mesh.height = 0.08
    eye_mesh.radial_segments = 8
    eye_mesh.rings = 4
    var eye_material: StandardMaterial3D = StandardMaterial3D.new()
    eye_material.albedo_color = Color(0.68, 0.72, 0.62, 1.0)
    eye_material.emission_enabled = true
    eye_material.emission = Color(0.55, 0.60, 0.48, 1.0)
    eye_material.emission_energy_multiplier = 3.0

    var left_eye: MeshInstance3D = MeshInstance3D.new()
    left_eye.mesh = eye_mesh
    left_eye.material_override = eye_material
    left_eye.position = Vector3(-0.10, 2.02, 0.27)
    dark_node.add_child(left_eye)

    var right_eye: MeshInstance3D = MeshInstance3D.new()
    right_eye.mesh = eye_mesh
    right_eye.material_override = eye_material
    right_eye.position = Vector3(0.10, 2.02, 0.27)
    dark_node.add_child(right_eye)

func _enter_online_mode() -> void:
    online_mode_active = true
    survivor_send_timer = 0.0
    monster_send_timer = 0.0
    team_wipe_timer = team_wipe_delay
    _ensure_online_scene_control()

func _leave_online_mode() -> void:
    online_mode_active = false
    local_downed = false
    survivor_states.clear()
    revive_channels.clear()
    tenant_active = false
    tenant_panic = 0.0
    tenant_target_peer = 0
    _despawn_shared_darkness(0.0)
    _show_downed_ui(false)

    var darkness_director: Node = get_node_or_null("/root/DarknessDirector")
    if darkness_director != null:
        darkness_director.set_process(true)

    var tenant: Node3D = _get_tenant()
    if tenant != null:
        tenant.set_process(true)
        if tenant.has_method("stop_stalking"):
            tenant.call("stop_stalking")

    var player: CharacterBody3D = _get_local_player()
    if player != null:
        player.set_process(true)
        player.set_physics_process(true)
        player.set_process_unhandled_input(true)
        if float(player.get("health")) <= 0.0:
            player.set("health", 35.0)
            if player.has_method("_update_survival_hud"):
                player.call("_update_survival_hud")

func _ensure_online_scene_control() -> void:
    var darkness_director: Node = get_node_or_null("/root/DarknessDirector")
    if darkness_director != null:
        darkness_director.set_process(false)

    var tenant: Node3D = _get_tenant()
    if tenant != null:
        tenant.set_process(false)

    var old_darkness: Node = get_tree().get_first_node_in_group("darkness_creature")
    if old_darkness != null:
        old_darkness.queue_free()

func _check_scene_change() -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var scene_id: int = int(scene.get_instance_id())
    if scene_id == current_scene_id:
        return

    current_scene_id = scene_id
    local_player_instance_id = 0
    local_downed = false
    local_downed_source = ""
    survivor_states.clear()
    revive_channels.clear()
    tenant_active = false
    tenant_panic = 0.0
    tenant_target_peer = 0
    dark_active = false
    dark_target_peer = 0
    if dark_node != null and is_instance_valid(dark_node):
        dark_node.queue_free()
    dark_node = null
    _show_downed_ui(false)

    if online_mode_active:
        call_deferred("_ensure_online_scene_control")

func _get_local_player() -> CharacterBody3D:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player != null:
        var instance_id: int = int(player.get_instance_id())
        if local_player_instance_id != instance_id:
            local_player_instance_id = instance_id
            if not local_downed:
                player.set_process(true)
                player.set_physics_process(true)
                player.set_process_unhandled_input(true)
    return player

func _get_tenant() -> Node3D:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return null
    return scene.get_node_or_null("Monster") as Node3D

func _feedback_to_peer(peer_id: int, message: String) -> void:
    if peer_id == 1:
        _set_local_objective(message)
    else:
        _revive_feedback.rpc_id(peer_id, message)

func _set_objective_for_peer(peer_id: int, message: String) -> void:
    if peer_id == 1:
        _set_local_objective(message)
    else:
        _revive_feedback.rpc_id(peer_id, message)

func _set_local_objective(message: String) -> void:
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = message

func _build_downed_ui() -> void:
    downed_layer = CanvasLayer.new()
    downed_layer.name = "CoopDownedUI"
    downed_layer.layer = 30
    add_child(downed_layer)

    downed_overlay = ColorRect.new()
    downed_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    downed_overlay.color = Color(0.16, 0.0, 0.0, 0.54)
    downed_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    downed_layer.add_child(downed_overlay)

    downed_title = Label.new()
    downed_title.anchor_left = 0.5
    downed_title.anchor_top = 0.5
    downed_title.anchor_right = 0.5
    downed_title.anchor_bottom = 0.5
    downed_title.offset_left = -280.0
    downed_title.offset_top = -88.0
    downed_title.offset_right = 280.0
    downed_title.offset_bottom = -28.0
    downed_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    downed_title.add_theme_font_size_override("font_size", 38)
    downed_layer.add_child(downed_title)

    downed_help = Label.new()
    downed_help.anchor_left = 0.5
    downed_help.anchor_top = 0.5
    downed_help.anchor_right = 0.5
    downed_help.anchor_bottom = 0.5
    downed_help.offset_left = -340.0
    downed_help.offset_top = -18.0
    downed_help.offset_right = 340.0
    downed_help.offset_bottom = 72.0
    downed_help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    downed_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    downed_help.add_theme_font_size_override("font_size", 18)
    downed_layer.add_child(downed_help)

    _show_downed_ui(false)

func _show_downed_ui(value: bool) -> void:
    if downed_overlay != null:
        downed_overlay.visible = value
    if downed_title != null:
        downed_title.visible = value
    if downed_help != null:
        downed_help.visible = value
