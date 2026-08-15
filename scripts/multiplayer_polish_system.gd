extends Node

const PROFILE_PATH: String = "user://dont_look_back_coop_profile.cfg"

@export var crawl_speed: float = 0.82
@export var crawl_acceleration: float = 8.0
@export var ping_interval: float = 2.0
@export var reconnect_delay: float = 2.5
@export var revive_ui_grace_distance: float = 0.35

var local_name: String = "Survivor"
var local_ready: bool = false
var session_started: bool = false
var profiles: Dictionary = {}
var previous_online: bool = false
var last_host_address: String = ""
var reconnect_timer: float = -1.0
var reconnect_attempted: bool = false
var ping_timer: float = 0.0
var ping_ms: int = -1
var profile_sync_timer: float = 0.0
var applying_shared_checkpoint: bool = false
var checkpoint_signature: String = ""
var shared_checkpoint_position: Vector3 = Vector3.ZERO
var shared_checkpoint_label: String = ""
var was_local_downed: bool = false
var normal_camera_y: float = 0.58
var revive_target_peer: int = 0
var revive_progress: float = 0.0
var revive_active: bool = false
var revive_complete_timer: float = 0.0
var ui_timer: float = 0.0

var layer: CanvasLayer
var teammate_panel: PanelContainer
var teammate_label: Label
var mission_label: Label
var session_panel: PanelContainer
var name_edit: LineEdit
var ready_button: Button
var start_button: Button
var reconnect_button: Button
var roster_label: Label
var connection_label: Label
var revive_box: VBoxContainer
var revive_label: Label
var revive_bar: ProgressBar

func _ready() -> void:
    _load_profile()
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    _build_ui()

func _process(delta: float) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = _network_online(network)

    if online != previous_online:
        previous_online = online
        if online:
            _enter_online_session(network)
        else:
            _leave_online_session()

    if reconnect_timer >= 0.0:
        reconnect_timer = maxf(-1.0, reconnect_timer - delta)
        if reconnect_timer <= 0.0 and not reconnect_attempted:
            reconnect_attempted = true
            reconnect_timer = -1.0
            _attempt_reconnect(network)

    if online:
        profile_sync_timer -= delta
        if profile_sync_timer <= 0.0:
            profile_sync_timer = 1.25
            _sync_local_profile(network)

        ping_timer -= delta
        if ping_timer <= 0.0:
            ping_timer = ping_interval
            _send_ping(network)

        _poll_shared_checkpoint(network)
        _update_remote_avatar_labels(network)
        _set_pre_game_lock(not session_started)
    else:
        _set_pre_game_lock(false)

    _update_revive_progress(delta)
    _update_downed_state()

    ui_timer -= delta
    if ui_timer <= 0.0:
        ui_timer = 0.20
        _update_ui(network)
        _layout_ui()

func _physics_process(delta: float) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if not _network_online(network) or not session_started or not _is_local_downed():
        return

    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return

    if not player.is_on_floor():
        var gravity_value: float = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
        player.velocity.y -= gravity_value * delta
    else:
        player.velocity.y = -0.1

    var x_input: float = float(Input.is_physical_key_pressed(KEY_D)) - float(Input.is_physical_key_pressed(KEY_A))
    var z_input: float = float(Input.is_physical_key_pressed(KEY_S)) - float(Input.is_physical_key_pressed(KEY_W))
    var input_vector: Vector2 = Vector2(x_input, z_input)

    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
    if mobile_active and mobile.has_method("get_move_vector"):
        var mobile_move: Vector2 = mobile.call("get_move_vector") as Vector2
        input_vector += mobile_move
        if mobile.has_method("consume_look_delta"):
            var look_delta: Vector2 = mobile.call("consume_look_delta") as Vector2
            _apply_crawl_look(player, look_delta, true)

    if input_vector.length() > 1.0:
        input_vector = input_vector.normalized()

    var direction: Vector3 = player.transform.basis * Vector3(input_vector.x, 0.0, input_vector.y)
    direction.y = 0.0
    if direction.length() > 0.01:
        direction = direction.normalized()

    var target_x: float = direction.x * crawl_speed
    var target_z: float = direction.z * crawl_speed
    player.velocity.x = move_toward(player.velocity.x, target_x, crawl_acceleration * delta)
    player.velocity.z = move_toward(player.velocity.z, target_z, crawl_acceleration * delta)
    player.move_and_slide()

func _unhandled_input(event: InputEvent) -> void:
    if not _is_local_downed() or not session_started:
        return

    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
    if mobile_active:
        return

    if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
        var motion: InputEventMouseMotion = event as InputEventMouseMotion
        _apply_crawl_look(_get_local_player(), motion.relative, false)
    elif event is InputEventMouseButton:
        var mouse_button: InputEventMouseButton = event as InputEventMouseButton
        if mouse_button.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    elif event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_ESCAPE:
            Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED else Input.MOUSE_MODE_CAPTURED)

func begin_local_revive(target_peer_id: int) -> void:
    if target_peer_id <= 0 or _is_local_downed():
        return
    revive_target_peer = target_peer_id
    revive_progress = 0.0
    revive_active = true
    revive_complete_timer = 0.0
    if revive_box != null:
        revive_box.visible = true

func get_player_name(peer_id: int) -> String:
    var profile: Dictionary = Dictionary(profiles.get(peer_id, {}))
    var fallback: String = "Survivor %d" % peer_id
    return str(profile.get("name", fallback))

func get_local_ping_ms() -> int:
    return ping_ms

func is_session_started() -> bool:
    return session_started

func _enter_online_session(network: Node) -> void:
    reconnect_timer = -1.0
    reconnect_attempted = false
    ping_timer = 0.0
    profile_sync_timer = 0.0
    ping_ms = 0 if _network_server(network) else -1
    local_ready = false

    if _network_server(network):
        profiles.clear()
        profiles[1] = _profile_data(local_name, local_ready, 0)
        session_started = false
        _capture_host_checkpoint()
        _broadcast_profiles()
    else:
        session_started = false
        _capture_last_host_address(network)
        _submit_profile.rpc_id(1, local_name, local_ready, ping_ms)

    checkpoint_signature = _current_checkpoint_signature()

func _leave_online_session() -> void:
    profiles.clear()
    session_started = false
    local_ready = false
    ping_ms = -1
    revive_active = false
    revive_target_peer = 0
    revive_progress = 0.0
    checkpoint_signature = ""
    _set_pre_game_lock(false)
    if revive_box != null:
        revive_box.visible = false

func _sync_local_profile(network: Node) -> void:
    if not _network_online(network):
        return
    if _network_server(network):
        profiles[1] = _profile_data(local_name, local_ready, 0)
        _broadcast_profiles()
    else:
        _submit_profile.rpc_id(1, local_name, local_ready, ping_ms)

func _profile_data(player_name: String, ready: bool, reported_ping: int) -> Dictionary:
    return {
        "name": _sanitize_name(player_name),
        "ready": ready,
        "ping": maxi(-1, reported_ping)
    }

func _sanitize_name(value: String) -> String:
    var result: String = value.strip_edges()
    if result.is_empty():
        result = "Survivor"
    if result.length() > 18:
        result = result.left(18)
    return result

func _toggle_ready() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if not _network_online(network) or session_started:
        return

    _commit_name_from_ui()
    local_ready = not local_ready
    if _network_server(network):
        profiles[1] = _profile_data(local_name, local_ready, 0)
        _broadcast_profiles()
    else:
        _submit_profile.rpc_id(1, local_name, local_ready, ping_ms)

func _start_session() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if not _network_server(network) or session_started:
        return

    _commit_name_from_ui()
    profiles[1] = _profile_data(local_name, local_ready, 0)

    if profiles.size() < 2:
        _set_connection_text("Need at least 2 survivors before START.")
        return
    if not _all_profiles_ready():
        _set_connection_text("Every connected survivor must be READY.")
        return

    var player: CharacterBody3D = _get_local_player()
    if player == null:
        _set_connection_text("Player not ready yet.")
        return

    session_started = true
    var host_transform: Transform3D = player.global_transform
    _session_started_remote.rpc(host_transform)
    _apply_session_started(host_transform, true)
    _broadcast_profiles()

func _all_profiles_ready() -> bool:
    if profiles.is_empty():
        return false
    for profile_variant: Variant in profiles.values():
        var profile: Dictionary = Dictionary(profile_variant)
        if not bool(profile.get("ready", false)):
            return false
    return true

func _apply_session_started(host_transform: Transform3D, host_local: bool) -> void:
    session_started = true
    local_ready = true
    _set_pre_game_lock(false)

    var player: CharacterBody3D = _get_local_player()
    if player != null and not host_local:
        var peer_id: int = multiplayer.get_unique_id()
        var side: float = -0.7 if peer_id % 2 == 0 else 0.7
        var back: float = 0.65 + float(peer_id % 3) * 0.22
        var offset: Vector3 = host_transform.basis.x.normalized() * side + host_transform.basis.z.normalized() * back
        player.global_position = host_transform.origin + offset
        player.rotation.y = host_transform.basis.get_euler().y
        player.velocity = Vector3.ZERO

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network != null:
        var lobby: PanelContainer = network.get("lobby_panel") as PanelContainer
        if lobby != null:
            lobby.visible = false
    if session_panel != null:
        session_panel.visible = false

    var mobile: Node = get_node_or_null("/root/MobileControls")
    var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
    if not mobile_active:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    _objective("Team ready. Stay together and keep the light moving.")

@rpc("any_peer", "call_remote", "reliable", 4)
func _submit_profile(player_name: String, ready: bool, reported_ping: int) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if not _network_server(network):
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    profiles[sender_id] = _profile_data(player_name, ready, reported_ping)
    _broadcast_profiles()
    if session_started:
        var player: CharacterBody3D = _get_local_player()
        if player != null:
            _session_started_remote.rpc_id(sender_id, player.global_transform)
        _send_shared_checkpoint_to_peer(sender_id)

@rpc("authority", "call_remote", "reliable", 4)
func _receive_profiles(snapshot: Dictionary, started: bool) -> void:
    profiles = snapshot.duplicate(true)
    session_started = started
    var local_profile: Dictionary = Dictionary(profiles.get(multiplayer.get_unique_id(), {}))
    if not local_profile.is_empty():
        local_ready = bool(local_profile.get("ready", local_ready))

@rpc("authority", "call_remote", "reliable", 4)
func _session_started_remote(host_transform: Transform3D) -> void:
    _apply_session_started(host_transform, false)

func _broadcast_profiles() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if not _network_server(network):
        return
    _receive_profiles.rpc(profiles.duplicate(true), session_started)

func _send_ping(network: Node) -> void:
    if not _network_online(network):
        return
    if _network_server(network):
        ping_ms = 0
        return
    var sent_ticks: int = int(Time.get_ticks_msec())
    _ping_request.rpc_id(1, sent_ticks)

@rpc("any_peer", "call_remote", "unreliable", 4)
func _ping_request(sent_ticks: int) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if not _network_server(network):
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id > 1:
        _ping_reply.rpc_id(sender_id, sent_ticks)

@rpc("authority", "call_remote", "unreliable", 4)
func _ping_reply(sent_ticks: int) -> void:
    ping_ms = maxi(0, int(Time.get_ticks_msec()) - sent_ticks)

func _poll_shared_checkpoint(network: Node) -> void:
    if applying_shared_checkpoint or not session_started:
        return

    var signature: String = _current_checkpoint_signature()
    if signature == checkpoint_signature:
        return
    checkpoint_signature = signature

    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint == null or not bool(checkpoint.get("checkpoint_active")):
        return

    var position: Vector3 = checkpoint.get("checkpoint_position") as Vector3
    var label: String = str(checkpoint.get("checkpoint_name"))
    if _network_server(network):
        _server_share_checkpoint(position, label, false)
    else:
        _request_shared_checkpoint.rpc_id(1, position, label)

func _capture_host_checkpoint() -> void:
    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint == null or not bool(checkpoint.get("checkpoint_active")):
        shared_checkpoint_position = Vector3.ZERO
        shared_checkpoint_label = ""
        return
    shared_checkpoint_position = checkpoint.get("checkpoint_position") as Vector3
    shared_checkpoint_label = str(checkpoint.get("checkpoint_name"))

func _server_share_checkpoint(position: Vector3, label: String, apply_host: bool) -> void:
    shared_checkpoint_position = position
    shared_checkpoint_label = label
    if apply_host:
        _apply_shared_checkpoint_local(position, label)
    _apply_shared_checkpoint_remote.rpc(position, label)

@rpc("any_peer", "call_remote", "reliable", 5)
func _request_shared_checkpoint(position: Vector3, label: String) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if not _network_server(network) or not session_started:
        return
    _server_share_checkpoint(position, label, true)

@rpc("authority", "call_remote", "reliable", 5)
func _apply_shared_checkpoint_remote(position: Vector3, label: String) -> void:
    _apply_shared_checkpoint_local(position, label)

func _apply_shared_checkpoint_local(position: Vector3, label: String) -> void:
    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    var player: CharacterBody3D = _get_local_player()
    if checkpoint == null or player == null or not checkpoint.has_method("save_checkpoint"):
        return

    applying_shared_checkpoint = true
    checkpoint.call("save_checkpoint", player, position, label)
    checkpoint_signature = _current_checkpoint_signature()
    applying_shared_checkpoint = false
    _objective("TEAM CHECKPOINT: %s" % label)

func _send_shared_checkpoint_to_peer(peer_id: int) -> void:
    if shared_checkpoint_label.is_empty():
        return
    _apply_shared_checkpoint_remote.rpc_id(peer_id, shared_checkpoint_position, shared_checkpoint_label)

func _current_checkpoint_signature() -> String:
    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint == null or not bool(checkpoint.get("checkpoint_active")):
        return "none"
    var position: Vector3 = checkpoint.get("checkpoint_position") as Vector3
    var label: String = str(checkpoint.get("checkpoint_name"))
    return "%s|%.2f|%.2f|%.2f" % [label, position.x, position.y, position.z]

func _update_revive_progress(delta: float) -> void:
    if revive_complete_timer > 0.0:
        revive_complete_timer = maxf(0.0, revive_complete_timer - delta)
        if revive_complete_timer <= 0.0 and revive_box != null:
            revive_box.visible = false

    if not revive_active:
        return

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null or _is_local_downed():
        _cancel_revive_ui("Revive interrupted")
        return

    if not coop.has_method("is_survivor_downed") or not bool(coop.call("is_survivor_downed", revive_target_peer)):
        revive_active = false
        revive_progress = 1.0
        if revive_bar != null:
            revive_bar.value = 100.0
        if revive_label != null:
            revive_label.text = "%s revived" % get_player_name(revive_target_peer)
        revive_complete_timer = 1.2
        return

    var distance: float = _distance_to_peer(revive_target_peer)
    var revive_distance: float = float(coop.get("revive_distance")) + revive_ui_grace_distance
    if distance > revive_distance:
        _cancel_revive_ui("Move closer to continue revive")
        return

    var duration: float = maxf(0.1, float(coop.get("revive_duration")))
    revive_progress = minf(duration * 0.99, revive_progress + delta)
    if revive_bar != null:
        revive_bar.value = revive_progress / duration * 100.0
    if revive_label != null:
        revive_label.text = "REVIVING %s  %.1fs" % [get_player_name(revive_target_peer), maxf(0.0, duration - revive_progress)]

func _cancel_revive_ui(message: String) -> void:
    revive_active = false
    revive_target_peer = 0
    revive_progress = 0.0
    if revive_bar != null:
        revive_bar.value = 0.0
    if revive_label != null:
        revive_label.text = message
    revive_complete_timer = 1.0

func _distance_to_peer(peer_id: int) -> float:
    var local_player: CharacterBody3D = _get_local_player()
    if local_player == null:
        return INF
    var target_position: Variant = _peer_position(peer_id)
    if not (target_position is Vector3):
        return INF
    return local_player.global_position.distance_to(target_position as Vector3)

func _peer_position(peer_id: int) -> Variant:
    if peer_id == multiplayer.get_unique_id():
        var player: CharacterBody3D = _get_local_player()
        return player.global_position if player != null else null

    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null:
        return null
    var targets: Dictionary = Dictionary(network.get("remote_targets"))
    var target: Dictionary = Dictionary(targets.get(peer_id, {}))
    if target.is_empty():
        return null
    var transform_value: Variant = target.get("transform", null)
    if transform_value is Transform3D:
        return (transform_value as Transform3D).origin
    return null

func _update_downed_state() -> void:
    var downed: bool = _is_local_downed()
    if downed == was_local_downed:
        return
    was_local_downed = downed

    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D

    if downed:
        if camera != null:
            normal_camera_y = camera.position.y
            camera.position.y = minf(camera.position.y, 0.27)
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null:
            var help: Label = coop.get("downed_help") as Label
            if help != null:
                help.text = "You can crawl slowly. Reach light or crawl toward a teammate.\nAnother survivor must stay close for the revive."
        var mobile: Node = get_node_or_null("/root/MobileControls")
        var mobile_active: bool = mobile != null and mobile.has_method("is_mobile_active") and bool(mobile.call("is_mobile_active"))
        if not mobile_active:
            Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
    else:
        if camera != null:
            camera.position.y = normal_camera_y

func _apply_crawl_look(player: CharacterBody3D, delta_value: Vector2, touch: bool) -> void:
    if player == null or delta_value.length_squared() <= 0.0:
        return
    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    if camera == null:
        return
    var sensitivity: float = float(player.get("touch_look_sensitivity")) if touch else float(player.get("mouse_sensitivity"))
    player.rotate_y(-delta_value.x * sensitivity)
    camera.rotate_x(-delta_value.y * sensitivity)
    camera.rotation.x = clampf(camera.rotation.x, deg_to_rad(-65.0), deg_to_rad(65.0))

func _set_pre_game_lock(locked: bool) -> void:
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    if _is_local_downed():
        return

    var journal: Node = get_node_or_null("/root/JournalSystem")
    var journal_open: bool = journal != null and journal.has_method("is_open") and bool(journal.call("is_open"))
    if not locked and journal_open:
        return

    if locked:
        player.velocity = Vector3.ZERO
        player.set_process(false)
        player.set_physics_process(false)
        player.set_process_unhandled_input(false)
    else:
        player.set_process(true)
        player.set_physics_process(true)
        player.set_process_unhandled_input(true)

func _update_remote_avatar_labels(network: Node) -> void:
    if network == null:
        return
    var avatars: Dictionary = Dictionary(network.get("remote_avatars"))
    var targets: Dictionary = Dictionary(network.get("remote_targets"))
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")

    for peer_variant: Variant in avatars.keys():
        var peer_id: int = int(peer_variant)
        var avatar: Node3D = avatars.get(peer_id) as Node3D
        if avatar == null or not is_instance_valid(avatar):
            continue
        var label: Label3D = avatar.get_node_or_null("StatusLabel") as Label3D
        if label == null:
            continue
        var target: Dictionary = Dictionary(targets.get(peer_id, {}))
        var stats: Dictionary = Dictionary(target.get("stats", {}))
        var health: int = int(round(float(stats.get("health", 100.0))))
        var downed: bool = coop != null and coop.has_method("is_survivor_downed") and bool(coop.call("is_survivor_downed", peer_id))
        label.text = "%s  %s" % [get_player_name(peer_id), "DOWNED" if downed else "HP %d" % health]

func _update_ui(network: Node) -> void:
    if session_panel == null:
        return

    var online: bool = _network_online(network)
    var connecting: bool = network != null and bool(network.get("connecting"))
    var network_lobby_visible: bool = false
    if network != null:
        var lobby: PanelContainer = network.get("lobby_panel") as PanelContainer
        network_lobby_visible = lobby != null and lobby.visible

    var reconnect_available: bool = not online and not connecting and not last_host_address.is_empty() and reconnect_attempted
    session_panel.visible = network_lobby_visible or (online and not session_started) or reconnect_available

    if name_edit != null:
        if not name_edit.has_focus():
            name_edit.text = local_name
        name_edit.editable = not session_started
    if ready_button != null:
        ready_button.visible = online and not session_started
        ready_button.text = "NOT READY" if not local_ready else "READY ✓"
    if start_button != null:
        start_button.visible = _network_server(network) and not session_started
        start_button.disabled = profiles.size() < 2 or not _all_profiles_ready()
    if reconnect_button != null:
        reconnect_button.visible = reconnect_available
        reconnect_button.text = "RECONNECT %s" % last_host_address

    _update_roster(network)
    _update_teammate_hud(network)

func _update_roster(network: Node) -> void:
    if roster_label == null or connection_label == null:
        return

    var ids: Array[int] = []
    for key_variant: Variant in profiles.keys():
        ids.append(int(key_variant))
    ids.sort()

    var lines: Array[String] = []
    for peer_id: int in ids:
        var profile: Dictionary = Dictionary(profiles.get(peer_id, {}))
        var ready_text: String = "READY" if bool(profile.get("ready", false)) else "WAITING"
        var host_text: String = " HOST" if peer_id == 1 else ""
        lines.append("%s%s — %s" % [str(profile.get("name", "Survivor")), host_text, ready_text])
    roster_label.text = "\n".join(lines) if not lines.is_empty() else "No survivors connected."

    if network == null:
        connection_label.text = "OFFLINE"
    elif bool(network.get("connecting")):
        connection_label.text = "CONNECTING..."
    elif _network_server(network):
        connection_label.text = "HOST  •  %d/%d" % [profiles.size(), int(network.get("max_clients"))]
    elif _network_online(network):
        connection_label.text = "CONNECTED  •  %d ms" % maxi(0, ping_ms)
    else:
        connection_label.text = "OFFLINE"

func _update_teammate_hud(network: Node) -> void:
    if teammate_panel == null or teammate_label == null or mission_label == null:
        return

    var online: bool = _network_online(network)
    teammate_panel.visible = online and session_started
    if not teammate_panel.visible:
        return

    var ids: Array[int] = []
    for key_variant: Variant in profiles.keys():
        ids.append(int(key_variant))
    ids.sort()

    var target_data: Dictionary = Dictionary(network.get("remote_targets")) if network != null else {}
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    var local_player: CharacterBody3D = _get_local_player()
    var lines: Array[String] = []

    for peer_id: int in ids:
        var health: float = 100.0
        if peer_id == multiplayer.get_unique_id():
            if local_player != null:
                health = float(local_player.get("health"))
        else:
            var target: Dictionary = Dictionary(target_data.get(peer_id, {}))
            var stats: Dictionary = Dictionary(target.get("stats", {}))
            health = float(stats.get("health", 100.0))
        var downed: bool = coop != null and coop.has_method("is_survivor_downed") and bool(coop.call("is_survivor_downed", peer_id))
        var you: String = " (YOU)" if peer_id == multiplayer.get_unique_id() else ""
        var condition: String = "DOWNED" if downed else "HP %d" % int(round(health))
        lines.append("%s%s  •  %s" % [get_player_name(peer_id), you, condition])

    teammate_label.text = "TEAM\n%s" % "\n".join(lines)
    var journal: Node = get_node_or_null("/root/JournalSystem")
    var mission: String = "Stay together and survive."
    if journal != null and journal.has_method("_get_current_mission"):
        mission = str(journal.call("_get_current_mission"))
    mission_label.text = "TEAM OBJECTIVE\n%s" % mission

func _capture_last_host_address(network: Node) -> void:
    if network == null:
        return
    var address_field: LineEdit = network.get("address_edit") as LineEdit
    if address_field != null:
        var candidate: String = address_field.text.strip_edges()
        if not candidate.is_empty() and candidate != "127.0.0.1":
            last_host_address = candidate
            _save_profile()

func _attempt_reconnect(network: Node) -> void:
    if network == null or last_host_address.is_empty() or _network_online(network) or bool(network.get("connecting")):
        return
    if network.has_method("join_game"):
        _set_connection_text("Reconnecting to %s..." % last_host_address)
        network.call("join_game", last_host_address)

func _manual_reconnect() -> void:
    reconnect_attempted = true
    reconnect_timer = -1.0
    _attempt_reconnect(get_node_or_null("/root/NetworkManager"))

func _commit_name_from_ui() -> void:
    if name_edit != null:
        local_name = _sanitize_name(name_edit.text)
        name_edit.text = local_name
        _save_profile()

func _on_peer_connected(peer_id: int) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if not _network_server(network):
        return
    profiles[peer_id] = _profile_data("Survivor %d" % peer_id, false, -1)
    _broadcast_profiles()
    call_deferred("_sync_peer_after_connect", peer_id)

func _sync_peer_after_connect(peer_id: int) -> void:
    await get_tree().process_frame
    if not profiles.has(peer_id):
        return
    _receive_profiles.rpc_id(peer_id, profiles.duplicate(true), session_started)
    if session_started:
        var player: CharacterBody3D = _get_local_player()
        if player != null:
            _session_started_remote.rpc_id(peer_id, player.global_transform)
        _send_shared_checkpoint_to_peer(peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if _network_server(network):
        profiles.erase(peer_id)
        _broadcast_profiles()

func _on_connected_to_server() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    _capture_last_host_address(network)
    reconnect_attempted = false
    reconnect_timer = -1.0

func _on_connection_failed() -> void:
    reconnect_timer = -1.0
    reconnect_attempted = true
    _set_connection_text("Reconnect failed. Check LAN connection and host address.")

func _on_server_disconnected() -> void:
    session_started = false
    profiles.clear()
    reconnect_attempted = false
    if not last_host_address.is_empty():
        reconnect_timer = reconnect_delay
        _set_connection_text("Host lost. Automatic reconnect in %.1fs..." % reconnect_delay)

func _network_online(network: Node) -> bool:
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _network_server(network: Node) -> bool:
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _is_local_downed() -> bool:
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    return coop != null and bool(coop.get("local_downed"))

func _get_local_player() -> CharacterBody3D:
    return get_tree().get_first_node_in_group("player") as CharacterBody3D

func _objective(text: String) -> void:
    var player: CharacterBody3D = _get_local_player()
    if player == null:
        return
    var objective_label: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective_label != null:
        objective_label.text = text

func _set_connection_text(text: String) -> void:
    if connection_label != null:
        connection_label.text = text

func _load_profile() -> void:
    var config: ConfigFile = ConfigFile.new()
    var load_error: Error = config.load(PROFILE_PATH)
    if load_error != OK:
        return
    local_name = _sanitize_name(str(config.get_value("player", "name", local_name)))
    last_host_address = str(config.get_value("network", "last_host", ""))

func _save_profile() -> void:
    var config: ConfigFile = ConfigFile.new()
    config.set_value("player", "name", local_name)
    config.set_value("network", "last_host", last_host_address)
    config.save(PROFILE_PATH)

func _build_ui() -> void:
    layer = CanvasLayer.new()
    layer.name = "MultiplayerPolishUI"
    layer.layer = 24
    add_child(layer)

    teammate_panel = PanelContainer.new()
    teammate_panel.visible = false
    layer.add_child(teammate_panel)
    var teammate_box: VBoxContainer = VBoxContainer.new()
    teammate_box.add_theme_constant_override("separation", 5)
    teammate_panel.add_child(teammate_box)
    teammate_label = Label.new()
    teammate_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    teammate_box.add_child(teammate_label)
    mission_label = Label.new()
    mission_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    mission_label.add_theme_font_size_override("font_size", 12)
    teammate_box.add_child(mission_label)

    session_panel = PanelContainer.new()
    session_panel.visible = false
    layer.add_child(session_panel)
    var session_box: VBoxContainer = VBoxContainer.new()
    session_box.add_theme_constant_override("separation", 7)
    session_panel.add_child(session_box)

    var title: Label = Label.new()
    title.text = "CO-OP SESSION"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 18)
    session_box.add_child(title)

    connection_label = Label.new()
    connection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    connection_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    session_box.add_child(connection_label)

    name_edit = LineEdit.new()
    name_edit.text = local_name
    name_edit.placeholder_text = "Survivor name"
    name_edit.max_length = 18
    name_edit.text_submitted.connect(_on_name_submitted)
    session_box.add_child(name_edit)

    roster_label = Label.new()
    roster_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    roster_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    session_box.add_child(roster_label)

    var buttons: HBoxContainer = HBoxContainer.new()
    buttons.alignment = BoxContainer.ALIGNMENT_CENTER
    buttons.add_theme_constant_override("separation", 7)
    session_box.add_child(buttons)

    ready_button = Button.new()
    ready_button.text = "NOT READY"
    ready_button.pressed.connect(_toggle_ready)
    buttons.add_child(ready_button)

    start_button = Button.new()
    start_button.text = "START"
    start_button.pressed.connect(_start_session)
    buttons.add_child(start_button)

    reconnect_button = Button.new()
    reconnect_button.text = "RECONNECT"
    reconnect_button.pressed.connect(_manual_reconnect)
    session_box.add_child(reconnect_button)

    revive_box = VBoxContainer.new()
    revive_box.visible = false
    revive_box.alignment = BoxContainer.ALIGNMENT_CENTER
    layer.add_child(revive_box)
    revive_label = Label.new()
    revive_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    revive_box.add_child(revive_label)
    revive_bar = ProgressBar.new()
    revive_bar.min_value = 0.0
    revive_bar.max_value = 100.0
    revive_bar.value = 0.0
    revive_bar.show_percentage = false
    revive_box.add_child(revive_bar)

    _layout_ui()

func _on_name_submitted(_text: String) -> void:
    _commit_name_from_ui()
    _sync_local_profile(get_node_or_null("/root/NetworkManager"))

func _layout_ui() -> void:
    if layer == null or session_panel == null or teammate_panel == null or revive_box == null:
        return
    var size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = size.x < 800.0

    if compact:
        session_panel.position = Vector2(size.x * 0.5 - 155.0, 96.0)
        session_panel.size = Vector2(310.0, 205.0)
        teammate_panel.position = Vector2(12.0, 98.0)
        teammate_panel.size = Vector2(minf(280.0, size.x - 24.0), 126.0)
        teammate_label.add_theme_font_size_override("font_size", 12)
        mission_label.add_theme_font_size_override("font_size", 10)
        revive_box.position = Vector2(size.x * 0.5 - 120.0, size.y - 168.0)
        revive_box.size = Vector2(240.0, 56.0)
    else:
        session_panel.position = Vector2(size.x * 0.5 + 245.0, size.y * 0.5 - 160.0)
        session_panel.size = Vector2(260.0, 260.0)
        teammate_panel.position = Vector2(size.x - 330.0, 330.0)
        teammate_panel.size = Vector2(300.0, 170.0)
        teammate_label.add_theme_font_size_override("font_size", 14)
        mission_label.add_theme_font_size_override("font_size", 12)
        revive_box.position = Vector2(size.x * 0.5 - 150.0, size.y - 130.0)
        revive_box.size = Vector2(300.0, 62.0)
