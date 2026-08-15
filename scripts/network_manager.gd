extends Node

@export var port: int = 24877
@export var max_clients: int = 4
@export var player_send_interval: float = 0.08
@export var world_send_interval: float = 0.45

var enet_peer: ENetMultiplayerPeer
var online: bool = false
var hosting: bool = false
var connecting: bool = false
var player_send_timer: float = 0.0
var world_send_timer: float = 0.0
var ui_layout_timer: float = 0.0
var avatar_scene_id: int = 0

var remote_avatars: Dictionary = {}
var remote_targets: Dictionary = {}
var claimed_pickups: Dictionary = {}
var pending_pickups: Dictionary = {}

var ui_layer: CanvasLayer
var status_label: Label
var coop_button: Button
var lobby_panel: PanelContainer
var address_edit: LineEdit
var lobby_status: Label

func _ready() -> void:
    multiplayer.peer_connected.connect(_on_peer_connected)
    multiplayer.peer_disconnected.connect(_on_peer_disconnected)
    multiplayer.connected_to_server.connect(_on_connected_to_server)
    multiplayer.connection_failed.connect(_on_connection_failed)
    multiplayer.server_disconnected.connect(_on_server_disconnected)
    call_deferred("_build_network_ui")

func _process(delta: float) -> void:
    _check_scene_change()
    _interpolate_remote_avatars(delta)

    if online:
        player_send_timer -= delta
        if player_send_timer <= 0.0:
            player_send_timer = player_send_interval
            _send_local_player_state()

        if hosting:
            world_send_timer -= delta
            if world_send_timer <= 0.0:
                world_send_timer = world_send_interval
                _broadcast_world_state()

    ui_layout_timer -= delta
    if ui_layout_timer <= 0.0:
        ui_layout_timer = 0.4
        _update_network_ui()
        _apply_responsive_ui()

func _unhandled_input(event: InputEvent) -> void:
    if event is InputEventKey:
        var key_event: InputEventKey = event as InputEventKey
        if key_event.pressed and not key_event.echo and key_event.physical_keycode == KEY_M:
            toggle_lobby()

func is_online() -> bool:
    return online

func is_server() -> bool:
    return online and hosting

func is_client() -> bool:
    return online and not hosting

func get_peer_id() -> int:
    if not online:
        return 1
    return multiplayer.get_unique_id()

func host_game() -> void:
    disconnect_game(false)
    enet_peer = ENetMultiplayerPeer.new()
    var error_code: Error = enet_peer.create_server(port, max_clients)
    if error_code != OK:
        _set_lobby_status("Host failed: %s" % error_string(error_code))
        return

    multiplayer.multiplayer_peer = enet_peer
    online = true
    hosting = true
    connecting = false
    player_send_timer = 0.0
    world_send_timer = 0.0
    _set_lobby_status("Hosting LAN game on port %d. %s" % [port, _get_lan_hint()])

func join_game(address: String) -> void:
    var clean_address: String = address.strip_edges()
    if clean_address.is_empty():
        clean_address = "127.0.0.1"

    disconnect_game(false)
    enet_peer = ENetMultiplayerPeer.new()
    var error_code: Error = enet_peer.create_client(clean_address, port)
    if error_code != OK:
        _set_lobby_status("Join failed: %s" % error_string(error_code))
        return

    multiplayer.multiplayer_peer = enet_peer
    online = false
    hosting = false
    connecting = true
    _set_lobby_status("Connecting to %s:%d..." % [clean_address, port])

func disconnect_game(show_message: bool = true) -> void:
    if enet_peer != null:
        enet_peer.close()
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    enet_peer = null
    online = false
    hosting = false
    connecting = false
    pending_pickups.clear()
    _clear_remote_avatars()
    if show_message:
        _set_lobby_status("Disconnected. Solo survival remains active.")

func toggle_lobby() -> void:
    if lobby_panel == null:
        return
    lobby_panel.visible = not lobby_panel.visible
    if lobby_panel.visible:
        Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
    else:
        Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func request_relay_activation(relay_id: int) -> void:
    if not online:
        var director: Node = get_node_or_null("/root/LabyrinthDirector")
        if director != null and director.has_method("activate_relay"):
            director.call("activate_relay", relay_id)
        return

    if hosting:
        _server_activate_relay(relay_id)
    else:
        _request_relay_activation.rpc_id(1, relay_id)

func request_pickup(pickup: Node) -> bool:
    if pickup == null or not is_instance_valid(pickup):
        return false
    if not online:
        return true

    var pickup_path: String = str(pickup.get_path())
    if hosting:
        if bool(claimed_pickups.get(pickup_path, false)):
            return false
        claimed_pickups[pickup_path] = true
        _despawn_pickup.rpc(pickup_path, 1)
        return true

    if bool(pending_pickups.get(pickup_path, false)):
        return false
    pending_pickups[pickup_path] = true
    _request_pickup_claim.rpc_id(1, pickup_path)
    return false

func request_shared_shelter_action(action: String) -> void:
    if not online:
        return
    if hosting:
        _server_apply_shelter_action(action)
    else:
        _request_shelter_action.rpc_id(1, action)

@rpc("any_peer", "call_remote", "unreliable", 0)
func _submit_player_state(player_transform: Transform3D, camera_pitch: float, flashlight_on: bool, stats: Dictionary) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    _apply_remote_player_state(sender_id, player_transform, camera_pitch, flashlight_on, stats)
    _receive_player_state.rpc(sender_id, player_transform, camera_pitch, flashlight_on, stats)

@rpc("authority", "call_remote", "unreliable", 0)
func _receive_player_state(peer_id: int, player_transform: Transform3D, camera_pitch: float, flashlight_on: bool, stats: Dictionary) -> void:
    if not online or peer_id == multiplayer.get_unique_id():
        return
    _apply_remote_player_state(peer_id, player_transform, camera_pitch, flashlight_on, stats)

@rpc("any_peer", "call_remote", "reliable", 1)
func _request_relay_activation(relay_id: int) -> void:
    if not hosting:
        return
    _server_activate_relay(relay_id)

@rpc("any_peer", "call_remote", "reliable", 1)
func _request_pickup_claim(pickup_path: String) -> void:
    if not hosting:
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    var accepted: bool = not bool(claimed_pickups.get(pickup_path, false))
    if accepted:
        claimed_pickups[pickup_path] = true
        _despawn_pickup.rpc(pickup_path, sender_id)
    _pickup_claim_result.rpc_id(sender_id, pickup_path, accepted)

@rpc("authority", "call_remote", "reliable", 1)
func _pickup_claim_result(pickup_path: String, accepted: bool) -> void:
    pending_pickups.erase(pickup_path)
    if not accepted:
        var denied_player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        if denied_player != null:
            var denied_label: Label = denied_player.get_node_or_null("HUD/Objective") as Label
            if denied_label != null:
                denied_label.text = "Another survivor took that supply first."
        return

    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var pickup: Node = scene.get_node_or_null(NodePath(pickup_path))
    if pickup != null and pickup.has_method("complete_network_pickup"):
        pickup.call("complete_network_pickup")

@rpc("authority", "call_remote", "reliable", 1)
func _despawn_pickup(pickup_path: String, claimant_id: int) -> void:
    if online and multiplayer.get_unique_id() == claimant_id:
        return
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var pickup: Node = scene.get_node_or_null(NodePath(pickup_path))
    if pickup != null:
        pickup.queue_free()

@rpc("authority", "call_remote", "reliable", 1)
func _sync_claimed_pickups(paths: Array) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    for path_variant: Variant in paths:
        var pickup_path: String = str(path_variant)
        claimed_pickups[pickup_path] = true
        var pickup: Node = scene.get_node_or_null(NodePath(pickup_path))
        if pickup != null:
            pickup.queue_free()

@rpc("any_peer", "call_remote", "reliable", 1)
func _request_shelter_action(action: String) -> void:
    if not hosting:
        return
    _server_apply_shelter_action(action)

@rpc("authority", "call_remote", "reliable", 1)
func _receive_world_state(state: Dictionary) -> void:
    if hosting:
        return
    _apply_world_state(state)

func _send_local_player_state() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
    var flashlight: SpotLight3D = player.get_node_or_null("Camera3D/Flashlight") as SpotLight3D
    var camera_pitch: float = camera.rotation.x if camera != null else 0.0
    var flashlight_on: bool = flashlight != null and flashlight.visible and flashlight.light_energy > 0.05
    var stats: Dictionary = {
        "health": float(player.get("health")),
        "hunger": float(player.get("hunger")),
        "thirst": float(player.get("thirst")),
        "stamina": float(player.get("stamina")),
        "battery": float(player.get("flashlight_battery")),
        "darkness": float(player.get("darkness_exposure"))
    }

    if hosting:
        _receive_player_state.rpc(1, player.global_transform, camera_pitch, flashlight_on, stats)
    else:
        _submit_player_state.rpc_id(1, player.global_transform, camera_pitch, flashlight_on, stats)

func _apply_remote_player_state(peer_id: int, player_transform: Transform3D, camera_pitch: float, flashlight_on: bool, stats: Dictionary) -> void:
    remote_targets[peer_id] = {
        "transform": player_transform,
        "pitch": camera_pitch,
        "flashlight": flashlight_on,
        "stats": stats.duplicate(true)
    }
    _ensure_remote_avatar(peer_id, player_transform)

func _ensure_remote_avatar(peer_id: int, initial_transform: Transform3D) -> void:
    var existing_variant: Variant = remote_avatars.get(peer_id)
    if existing_variant != null:
        var existing: Node3D = existing_variant as Node3D
        if existing != null and is_instance_valid(existing):
            return

    var parent: Node3D = _get_network_player_parent()
    if parent == null:
        return

    var avatar: Node3D = Node3D.new()
    avatar.name = "RemotePlayer%d" % peer_id
    avatar.global_transform = initial_transform
    parent.add_child(avatar)

    var body_mesh: CapsuleMesh = CapsuleMesh.new()
    body_mesh.radius = 0.34
    body_mesh.height = 1.65
    body_mesh.radial_segments = 10
    body_mesh.rings = 5
    var body_material: StandardMaterial3D = StandardMaterial3D.new()
    var hue: float = fmod(float(peer_id) * 0.173, 1.0)
    body_material.albedo_color = Color.from_hsv(hue, 0.45, 0.72, 1.0)
    body_material.roughness = 0.82
    var body: MeshInstance3D = MeshInstance3D.new()
    body.name = "Body"
    body.mesh = body_mesh
    body.material_override = body_material
    body.position = Vector3(0.0, 0.36, 0.0)
    avatar.add_child(body)

    var head: Node3D = Node3D.new()
    head.name = "Head"
    head.position = Vector3(0.0, 0.58, 0.0)
    avatar.add_child(head)

    var light: SpotLight3D = SpotLight3D.new()
    light.name = "Flashlight"
    light.light_color = Color(0.92, 0.90, 0.78, 1.0)
    light.light_energy = 2.6
    light.spot_range = 10.0
    light.spot_angle = 30.0
    light.shadow_enabled = false
    head.add_child(light)

    var label: Label3D = Label3D.new()
    label.name = "StatusLabel"
    label.position = Vector3(0.0, 1.55, 0.0)
    label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    label.font_size = 28
    label.text = "SURVIVOR %d" % peer_id
    avatar.add_child(label)

    remote_avatars[peer_id] = avatar

func _interpolate_remote_avatars(delta: float) -> void:
    var weight: float = clampf(delta * 12.0, 0.0, 1.0)
    for peer_variant: Variant in remote_targets.keys():
        var peer_id: int = int(peer_variant)
        var avatar_variant: Variant = remote_avatars.get(peer_id)
        var target_variant: Variant = remote_targets.get(peer_id)
        if avatar_variant == null or target_variant == null:
            continue
        var avatar: Node3D = avatar_variant as Node3D
        var target: Dictionary = target_variant as Dictionary
        if avatar == null or not is_instance_valid(avatar):
            continue

        var target_transform: Transform3D = target.get("transform", avatar.global_transform)
        var current_transform: Transform3D = avatar.global_transform
        var current_quaternion: Quaternion = current_transform.basis.get_rotation_quaternion()
        var target_quaternion: Quaternion = target_transform.basis.get_rotation_quaternion()
        var blended_quaternion: Quaternion = current_quaternion.slerp(target_quaternion, weight)
        var blended_origin: Vector3 = current_transform.origin.lerp(target_transform.origin, weight)
        avatar.global_transform = Transform3D(Basis(blended_quaternion), blended_origin)

        var head: Node3D = avatar.get_node_or_null("Head") as Node3D
        if head != null:
            head.rotation.x = float(target.get("pitch", 0.0))
            var light: SpotLight3D = head.get_node_or_null("Flashlight") as SpotLight3D
            if light != null:
                light.visible = bool(target.get("flashlight", false))

        var label: Label3D = avatar.get_node_or_null("StatusLabel") as Label3D
        if label != null:
            var stats: Dictionary = target.get("stats", {}) as Dictionary
            var health: int = int(round(float(stats.get("health", 100.0))))
            label.text = "SURVIVOR %d  HP %d" % [peer_id, health]

func _get_network_player_parent() -> Node3D:
    var scene: Node = get_tree().current_scene
    if scene == null or not (scene is Node3D):
        return null
    var scene_3d: Node3D = scene as Node3D
    var existing: Node3D = scene_3d.get_node_or_null("NetworkPlayers") as Node3D
    if existing != null:
        return existing
    var parent: Node3D = Node3D.new()
    parent.name = "NetworkPlayers"
    scene_3d.add_child(parent)
    return parent

func _server_activate_relay(relay_id: int) -> void:
    if not hosting:
        return
    var director: Node = get_node_or_null("/root/LabyrinthDirector")
    if director != null and director.has_method("activate_relay"):
        director.call("activate_relay", relay_id)
    _broadcast_world_state()

func _server_apply_shelter_action(action: String) -> void:
    if not hosting:
        return
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null or not shelter.has_method("apply_network_shared_action"):
        return
    shelter.call("apply_network_shared_action", action)
    _broadcast_world_state()

func _broadcast_world_state() -> void:
    if not hosting:
        return

    var state: Dictionary = {}
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        state["game_minutes"] = float(outside.get("game_minutes"))
        state["day_index"] = int(outside.get("day_index"))

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter != null:
        state["generator_running"] = bool(shelter.get("generator_running"))
        state["generator_fuel_seconds"] = float(shelter.get("generator_fuel_seconds"))
        state["campfire_burn_seconds"] = float(shelter.get("campfire_burn_seconds"))
        state["storage_names"] = Dictionary(shelter.get("storage_names")).duplicate(true)
        state["storage_counts"] = Dictionary(shelter.get("storage_counts")).duplicate(true)

    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth != null:
        state["active_relays"] = Dictionary(labyrinth.get("active_relays")).duplicate(true)

    _receive_world_state.rpc(state)

func _apply_world_state(state: Dictionary) -> void:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside != null:
        if state.has("game_minutes"):
            outside.set("game_minutes", float(state["game_minutes"]))
        if state.has("day_index"):
            outside.set("day_index", int(state["day_index"]))

    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter != null:
        if state.has("generator_running"):
            shelter.set("generator_running", bool(state["generator_running"]))
        if state.has("generator_fuel_seconds"):
            shelter.set("generator_fuel_seconds", float(state["generator_fuel_seconds"]))
        if state.has("campfire_burn_seconds"):
            shelter.set("campfire_burn_seconds", float(state["campfire_burn_seconds"]))
        if state.has("storage_names"):
            shelter.set("storage_names", Dictionary(state["storage_names"]).duplicate(true))
        if state.has("storage_counts"):
            shelter.set("storage_counts", Dictionary(state["storage_counts"]).duplicate(true))
        if shelter.has_method("refresh_shared_state"):
            shelter.call("refresh_shared_state")

    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth != null and state.has("active_relays"):
        labyrinth.set("active_relays", Dictionary(state["active_relays"]).duplicate(true))
        if labyrinth.has_method("_restore_relay_visuals"):
            labyrinth.call("_restore_relay_visuals")
        if labyrinth.has_method("_update_gate_state"):
            labyrinth.call("_update_gate_state")

func _on_peer_connected(peer_id: int) -> void:
    if hosting:
        _sync_claimed_pickups.rpc_id(peer_id, claimed_pickups.keys())
        call_deferred("_broadcast_world_state")
    _set_lobby_status("Survivor %d connected." % peer_id)

func _on_peer_disconnected(peer_id: int) -> void:
    _remove_remote_avatar(peer_id)
    _set_lobby_status("Survivor %d disconnected." % peer_id)

func _on_connected_to_server() -> void:
    online = true
    hosting = false
    connecting = false
    player_send_timer = 0.0
    _set_lobby_status("Connected as Survivor %d." % multiplayer.get_unique_id())

func _on_connection_failed() -> void:
    online = false
    hosting = false
    connecting = false
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    _set_lobby_status("Connection failed. Check the host LAN IP and port %d." % port)

func _on_server_disconnected() -> void:
    online = false
    hosting = false
    connecting = false
    multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
    _clear_remote_avatars()
    _set_lobby_status("Host disconnected. Returned to solo mode.")

func _remove_remote_avatar(peer_id: int) -> void:
    var avatar_variant: Variant = remote_avatars.get(peer_id)
    if avatar_variant != null:
        var avatar: Node3D = avatar_variant as Node3D
        if avatar != null and is_instance_valid(avatar):
            avatar.queue_free()
    remote_avatars.erase(peer_id)
    remote_targets.erase(peer_id)

func _clear_remote_avatars() -> void:
    for avatar_variant: Variant in remote_avatars.values():
        var avatar: Node3D = avatar_variant as Node3D
        if avatar != null and is_instance_valid(avatar):
            avatar.queue_free()
    remote_avatars.clear()
    remote_targets.clear()

func _check_scene_change() -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return
    var scene_id: int = int(scene.get_instance_id())
    if scene_id == avatar_scene_id:
        return
    avatar_scene_id = scene_id
    _clear_remote_avatars()

func _build_network_ui() -> void:
    if ui_layer != null:
        return

    ui_layer = CanvasLayer.new()
    ui_layer.name = "NetworkUI"
    ui_layer.layer = 20
    add_child(ui_layer)

    status_label = Label.new()
    status_label.name = "NetworkStatus"
    status_label.offset_left = 16.0
    status_label.offset_top = 12.0
    status_label.offset_right = 430.0
    status_label.offset_bottom = 40.0
    status_label.add_theme_font_size_override("font_size", 14)
    ui_layer.add_child(status_label)

    coop_button = Button.new()
    coop_button.name = "CoopButton"
    coop_button.text = "CO-OP"
    coop_button.offset_left = 16.0
    coop_button.offset_top = 44.0
    coop_button.offset_right = 112.0
    coop_button.offset_bottom = 82.0
    coop_button.pressed.connect(toggle_lobby)
    ui_layer.add_child(coop_button)

    lobby_panel = PanelContainer.new()
    lobby_panel.name = "LobbyPanel"
    lobby_panel.visible = false
    lobby_panel.anchor_left = 0.5
    lobby_panel.anchor_top = 0.5
    lobby_panel.anchor_right = 0.5
    lobby_panel.anchor_bottom = 0.5
    lobby_panel.offset_left = -230.0
    lobby_panel.offset_top = -160.0
    lobby_panel.offset_right = 230.0
    lobby_panel.offset_bottom = 160.0
    ui_layer.add_child(lobby_panel)

    var box: VBoxContainer = VBoxContainer.new()
    box.add_theme_constant_override("separation", 10)
    lobby_panel.add_child(box)

    var title: Label = Label.new()
    title.text = "DON'T LOOK BACK — CO-OP"
    title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    title.add_theme_font_size_override("font_size", 22)
    box.add_child(title)

    var help: Label = Label.new()
    help.text = "LAN multiplayer • 2–4 survivors\nHost on one device, then enter that device's LAN IPv4 on the others."
    help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    help.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(help)

    address_edit = LineEdit.new()
    address_edit.placeholder_text = "Host IPv4, e.g. 192.168.1.20"
    address_edit.text = "127.0.0.1"
    box.add_child(address_edit)

    var button_row: HBoxContainer = HBoxContainer.new()
    button_row.alignment = BoxContainer.ALIGNMENT_CENTER
    button_row.add_theme_constant_override("separation", 8)
    box.add_child(button_row)

    var host_button: Button = Button.new()
    host_button.text = "HOST"
    host_button.pressed.connect(host_game)
    button_row.add_child(host_button)

    var join_button: Button = Button.new()
    join_button.text = "JOIN"
    join_button.pressed.connect(_join_from_ui)
    button_row.add_child(join_button)

    var leave_button: Button = Button.new()
    leave_button.text = "LEAVE"
    leave_button.pressed.connect(_disconnect_from_ui)
    button_row.add_child(leave_button)

    var close_button: Button = Button.new()
    close_button.text = "CLOSE"
    close_button.pressed.connect(toggle_lobby)
    button_row.add_child(close_button)

    lobby_status = Label.new()
    lobby_status.text = "Offline. Press HOST or JOIN."
    lobby_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    lobby_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(lobby_status)

    var shortcut: Label = Label.new()
    shortcut.text = "Desktop shortcut: M opens/closes this panel."
    shortcut.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    box.add_child(shortcut)
    _update_network_ui()

func _join_from_ui() -> void:
    if address_edit == null:
        return
    join_game(address_edit.text)

func _disconnect_from_ui() -> void:
    disconnect_game(true)

func _update_network_ui() -> void:
    if status_label == null:
        return
    if connecting:
        status_label.text = "CO-OP  CONNECTING..."
    elif not online:
        status_label.text = "CO-OP  OFFLINE  |  M Lobby"
    elif hosting:
        status_label.text = "CO-OP  HOST  |  %d/%d survivors" % [remote_targets.size() + 1, max_clients]
    else:
        status_label.text = "CO-OP  CLIENT #%d  |  %d survivors visible" % [multiplayer.get_unique_id(), remote_targets.size() + 1]

func _apply_responsive_ui() -> void:
    if lobby_panel == null or coop_button == null:
        return
    var viewport_size: Vector2 = get_viewport().get_visible_rect().size
    var compact: bool = viewport_size.x < 800.0
    if compact:
        lobby_panel.offset_left = -170.0
        lobby_panel.offset_right = 170.0
        lobby_panel.offset_top = -190.0
        lobby_panel.offset_bottom = 190.0
        coop_button.offset_left = 12.0
        coop_button.offset_top = viewport_size.y - 66.0
        coop_button.offset_right = 108.0
        coop_button.offset_bottom = viewport_size.y - 18.0
        status_label.add_theme_font_size_override("font_size", 12)
    else:
        lobby_panel.offset_left = -230.0
        lobby_panel.offset_right = 230.0
        lobby_panel.offset_top = -160.0
        lobby_panel.offset_bottom = 160.0
        coop_button.offset_left = 16.0
        coop_button.offset_top = 44.0
        coop_button.offset_right = 112.0
        coop_button.offset_bottom = 82.0
        status_label.add_theme_font_size_override("font_size", 14)

func _set_lobby_status(message: String) -> void:
    if lobby_status != null:
        lobby_status.text = message

func _get_lan_hint() -> String:
    var addresses: PackedStringArray = IP.get_local_addresses()
    for address: String in addresses:
        if address.begins_with("127.") or address == "::1" or address.contains(":"):
            continue
        return "LAN IP: %s" % address
    return "Share this device's LAN IPv4 with clients."
