extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const SYNC_WINDOW_ONLINE: float = 9.0
const SYNC_WINDOW_SOLO: float = 18.0
const SUPPORT_LIGHT_DURATION: float = 36.0
const PANEL_USE_DISTANCE: float = 3.4
const TEAM_SPLIT_DISTANCE: float = 18.0

const STATION_STAGE: Dictionary = {
    "maintenance_sync": 1,
    "flood_sync": 2,
    "archive_sync": 3
}
const PANEL_POSITIONS: Dictionary = {
    "maintenance_sync:a": Vector3(-10.8, 0.0, -67.0),
    "maintenance_sync:b": Vector3(10.8, 0.0, -75.0),
    "flood_sync:a": Vector3(-10.8, 0.0, -88.5),
    "flood_sync:b": Vector3(10.8, 0.0, -99.0),
    "archive_sync:a": Vector3(-10.6, 0.0, -112.0),
    "archive_sync:b": Vector3(10.6, 0.0, -122.0)
}
const SUPPORT_POSITIONS: Dictionary = {
    "maintenance_sync": Vector3(0.0, 2.25, -72.0),
    "flood_sync": Vector3(0.0, 2.25, -94.0),
    "archive_sync": Vector3(0.0, 2.25, -117.0)
}

var configured_scene_id: int = 0
var coop_root: Node3D
var panel_script: Script
var pickup_script: Script
var completed_stations: Dictionary = {}
var station_progress: Dictionary = {}
var support_remaining: Dictionary = {}
var support_lights: Dictionary = {}
var state_dirty: bool = true
var sync_timer: float = 0.0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    panel_script = load("res://scripts/arc1_sync_panel.gd") as Script
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        coop_root = null
        configured_scene_id = 0
        station_progress.clear()
        support_remaining.clear()
        support_lights.clear()
        return

    var arc_root: Node3D = scene.get_node_or_null("Arc1Expansion") as Node3D
    if arc_root == null:
        return

    _sync_completed_from_arc()

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        coop_root = null
        support_lights.clear()
        station_progress.clear()
        call_deferred("_configure_scene", scene, arc_root)
        return

    if coop_root == null or not is_instance_valid(coop_root):
        return

    if _is_authoritative():
        _update_windows(delta)
        _update_support_timers(delta)
        _apply_team_tension_to_encounter()
        sync_timer -= delta
        if state_dirty or sync_timer <= 0.0:
            sync_timer = 0.45
            if _network_online():
                _receive_coop_state.rpc(get_network_state())
            state_dirty = false

    _update_support_lights()

func request_panel_activation(station_id: String, panel_id: String) -> void:
    if not _valid_panel(station_id, panel_id):
        return

    if _network_online() and not _is_authoritative():
        _request_panel_remote.rpc_id(1, station_id, panel_id)
        return

    var requester_id: int = multiplayer.get_unique_id() if _network_online() else 1
    _server_activate_panel(station_id, panel_id, requester_id)

func get_panel_prompt(station_id: String, panel_id: String, display_name: String) -> String:
    if bool(completed_stations.get(station_id, false)):
        return "%s — synchronized" % display_name

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    var required_stage: int = int(STATION_STAGE.get(station_id, 99))
    if arc == null or int(arc.get("current_stage")) < required_stage:
        return "%s — no power" % display_name

    var progress: Dictionary = Dictionary(station_progress.get(station_id, {}))
    if progress.is_empty():
        return "Activate %s" % display_name

    var armed_panel: String = str(progress.get("panel", ""))
    var remaining: int = maxi(0, int(ceil(float(progress.get("remaining", 0.0)))))
    if armed_panel == panel_id:
        return "SYNC %s armed — %ds" % [panel_id.to_upper(), remaining]
    if _network_online():
        return "Activate SYNC %s — teammate window %ds" % [panel_id.to_upper(), remaining]
    return "Activate SYNC %s — solo window %ds" % [panel_id.to_upper(), remaining]

func get_panel_visual_state(station_id: String, panel_id: String) -> int:
    if bool(completed_stations.get(station_id, false)):
        return 2
    var progress: Dictionary = Dictionary(station_progress.get(station_id, {}))
    if not progress.is_empty() and str(progress.get("panel", "")) == panel_id:
        return 1
    return 0

func get_network_state() -> Dictionary:
    return {
        "completed_stations": completed_stations.duplicate(true),
        "station_progress": station_progress.duplicate(true),
        "support_remaining": support_remaining.duplicate(true)
    }

func reset_progress() -> void:
    completed_stations.clear()
    station_progress.clear()
    support_remaining.clear()
    state_dirty = true
    _update_support_lights()

@rpc("any_peer", "call_remote", "reliable", 13)
func _request_panel_remote(station_id: String, panel_id: String) -> void:
    if not _is_authoritative():
        return
    var sender_id: int = multiplayer.get_remote_sender_id()
    if sender_id <= 1:
        return
    _server_activate_panel(station_id, panel_id, sender_id)

@rpc("authority", "call_remote", "reliable", 13)
func _receive_coop_state(state: Dictionary) -> void:
    _apply_network_state(state)

@rpc("authority", "call_remote", "reliable", 13)
func _receive_feedback(text: String) -> void:
    _set_local_status(text)

func _server_activate_panel(station_id: String, panel_id: String, requester_id: int) -> void:
    if not _valid_panel(station_id, panel_id):
        return
    if bool(completed_stations.get(station_id, false)):
        _feedback_to_peer(requester_id, "That emergency sync station is already complete.")
        return

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var required_stage: int = int(STATION_STAGE.get(station_id, 99))
    if int(arc.get("current_stage")) < required_stage:
        _feedback_to_peer(requester_id, "That sync station has no power yet.")
        return

    var requester_position: Vector3 = _requester_position(requester_id)
    var panel_position: Vector3 = _dictionary_vector(PANEL_POSITIONS, "%s:%s" % [station_id, panel_id])
    if requester_position == Vector3.INF or requester_position.distance_to(panel_position) > PANEL_USE_DISTANCE:
        _feedback_to_peer(requester_id, "Move closer to the sync panel.")
        return

    var progress: Dictionary = Dictionary(station_progress.get(station_id, {}))
    if progress.is_empty():
        var window: float = SYNC_WINDOW_ONLINE if _network_online() else SYNC_WINDOW_SOLO
        station_progress[station_id] = {
            "panel": panel_id,
            "peer_id": requester_id,
            "remaining": window
        }
        state_dirty = true
        if _network_online():
            _feedback_to_peer(requester_id, "SYNC %s armed. Another survivor must reach the paired panel within %.0f seconds." % [panel_id.to_upper(), window])
        else:
            _feedback_to_peer(requester_id, "SYNC %s armed. Reach the paired panel within %.0f seconds." % [panel_id.to_upper(), window])
        _report_noise(panel_position, 0.46, "sync panel armed")
        return

    var first_panel: String = str(progress.get("panel", ""))
    var first_peer: int = int(progress.get("peer_id", 0))
    if first_panel == panel_id:
        _feedback_to_peer(requester_id, "This panel is already armed. Use the paired panel.")
        return
    if _network_online() and first_peer == requester_id:
        _feedback_to_peer(requester_id, "Online sync requires another survivor on the paired panel.")
        return

    _complete_station(station_id, requester_id)

func _complete_station(station_id: String, requester_id: int) -> void:
    completed_stations[station_id] = true
    station_progress.erase(station_id)
    support_remaining[station_id] = SUPPORT_LIGHT_DURATION
    _persist_station_to_arc(station_id)
    state_dirty = true
    _spawn_station_reward(station_id)
    _update_support_lights()

    var support_position: Vector3 = _dictionary_vector(SUPPORT_POSITIONS, station_id)
    _report_noise(support_position, 0.74, "emergency team light online")
    _feedback_to_peer(requester_id, "TEAM SYNC COMPLETE — emergency safe light online for %.0f seconds." % SUPPORT_LIGHT_DURATION)
    _set_local_status("TEAM SYNC COMPLETE — emergency safe light online.")
    _request_autosave("Arc 1 team sync complete")

func _update_windows(delta: float) -> void:
    var expired: Array[String] = []
    for station_variant: Variant in station_progress.keys():
        var station_id: String = str(station_variant)
        var progress: Dictionary = Dictionary(station_progress.get(station_id, {}))
        var remaining: float = maxf(0.0, float(progress.get("remaining", 0.0)) - delta)
        progress["remaining"] = remaining
        station_progress[station_id] = progress
        if remaining <= 0.0:
            expired.append(station_id)

    for station_id: String in expired:
        station_progress.erase(station_id)
        state_dirty = true

func _update_support_timers(delta: float) -> void:
    var expired: Array[String] = []
    for station_variant: Variant in support_remaining.keys():
        var station_id: String = str(station_variant)
        var remaining: float = maxf(0.0, float(support_remaining.get(station_id, 0.0)) - delta)
        support_remaining[station_id] = remaining
        if remaining <= 0.0:
            expired.append(station_id)
    for station_id: String in expired:
        support_remaining.erase(station_id)
        state_dirty = true

func _apply_team_tension_to_encounter() -> void:
    var director: Node = get_node_or_null("/root/LabyrinthEncounterDirector")
    if director == null:
        return

    var encounter_timer: float = float(director.get("encounter_timer"))
    var horror_timer: float = float(director.get("horror_event_timer"))

    if _has_active_support_light():
        director.set("encounter_timer", maxf(encounter_timer, 8.0))
        director.set("horror_event_timer", maxf(horror_timer, 12.0))
        return

    if _network_online() and _team_spread_distance() >= TEAM_SPLIT_DISTANCE:
        director.set("encounter_timer", minf(encounter_timer, 5.0))
        director.set("horror_event_timer", minf(horror_timer, 12.0))

func _configure_scene(scene: Node, arc_root: Node3D) -> void:
    for _frame_index: int in range(45):
        await get_tree().process_frame
        if not is_instance_valid(scene) or get_tree().current_scene != scene:
            return
        if is_instance_valid(arc_root):
            break

    if not is_instance_valid(scene) or get_tree().current_scene != scene or not is_instance_valid(arc_root):
        return

    var old_root: Node = arc_root.get_node_or_null("CoopExpansion")
    if old_root != null:
        old_root.free()

    coop_root = Node3D.new()
    coop_root.name = "CoopExpansion"
    arc_root.add_child(coop_root)

    _spawn_panel("maintenance_sync", "a", "M-01 SYNC A", _dictionary_vector(PANEL_POSITIONS, "maintenance_sync:a"))
    _spawn_panel("maintenance_sync", "b", "M-01 SYNC B", _dictionary_vector(PANEL_POSITIONS, "maintenance_sync:b"))
    _spawn_panel("flood_sync", "a", "F-02 SYNC A", _dictionary_vector(PANEL_POSITIONS, "flood_sync:a"))
    _spawn_panel("flood_sync", "b", "F-02 SYNC B", _dictionary_vector(PANEL_POSITIONS, "flood_sync:b"))
    _spawn_panel("archive_sync", "a", "A-03 SYNC A", _dictionary_vector(PANEL_POSITIONS, "archive_sync:a"))
    _spawn_panel("archive_sync", "b", "A-03 SYNC B", _dictionary_vector(PANEL_POSITIONS, "archive_sync:b"))

    _spawn_support_light("maintenance_sync")
    _spawn_support_light("flood_sync")
    _spawn_support_light("archive_sync")

    _sync_completed_from_arc()
    for station_variant: Variant in completed_stations.keys():
        var station_id: String = str(station_variant)
        if bool(completed_stations.get(station_id, false)):
            _spawn_station_reward(station_id)
    _update_support_lights()
    state_dirty = true

func _spawn_panel(station_id: String, panel_id: String, display_name: String, position: Vector3) -> void:
    if coop_root == null or panel_script == null:
        return
    var panel: StaticBody3D = StaticBody3D.new()
    panel.name = "SyncPanel_%s_%s" % [station_id, panel_id]
    panel.position = position
    panel.set_script(panel_script)
    panel.set("station_id", station_id)
    panel.set("panel_id", panel_id)
    panel.set("display_name", display_name)
    coop_root.add_child(panel)

func _spawn_support_light(station_id: String) -> void:
    if coop_root == null:
        return
    var light: OmniLight3D = OmniLight3D.new()
    light.name = "SupportLight_%s" % station_id
    light.position = _dictionary_vector(SUPPORT_POSITIONS, station_id)
    light.light_color = Color(0.54, 0.78, 0.64, 1.0)
    light.light_energy = 1.10
    light.omni_range = 5.6
    light.shadow_enabled = false
    light.visible = false
    coop_root.add_child(light)
    support_lights[station_id] = light

func _spawn_station_reward(station_id: String) -> void:
    if coop_root == null or pickup_script == null:
        return

    var reward_position: Vector3 = _dictionary_vector(SUPPORT_POSITIONS, station_id)
    reward_position.y = 0.05
    var item_id: String = "flashlight_battery"
    var display_name: String = "Flashlight Battery"
    if station_id == "flood_sync":
        item_id = "bottled_water"
        display_name = "Bottled Water"
    elif station_id == "archive_sync":
        item_id = "medkit"
        display_name = "Medkit"

    var node_name: String = "TeamReward_%s" % station_id
    if coop_root.has_node(NodePath(node_name)):
        return

    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = node_name
    pickup.position = reward_position
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", NodePath("../../../Player/HUD/Objective"))
    coop_root.add_child(pickup)

func _update_support_lights() -> void:
    for station_variant: Variant in support_lights.keys():
        var station_id: String = str(station_variant)
        var light: OmniLight3D = support_lights.get(station_id, null) as OmniLight3D
        if light == null or not is_instance_valid(light):
            continue
        var remaining: float = float(support_remaining.get(station_id, 0.0))
        light.visible = remaining > 0.0
        if light.visible:
            var pulse: float = 0.92 + 0.08 * absf(sin(float(Time.get_ticks_msec()) / 220.0))
            light.light_energy = 1.10 * pulse

func _apply_network_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    var completed_value: Variant = state.get("completed_stations", {})
    if completed_value is Dictionary:
        completed_stations = Dictionary(completed_value).duplicate(true)
    var support_value: Variant = state.get("support_remaining", {})
    if support_value is Dictionary:
        support_remaining = Dictionary(support_value).duplicate(true)
    var progress_value: Variant = state.get("station_progress", {})
    if progress_value is Dictionary:
        station_progress = Dictionary(progress_value).duplicate(true)
    if coop_root != null and is_instance_valid(coop_root):
        for station_variant: Variant in completed_stations.keys():
            var station_id: String = str(station_variant)
            if bool(completed_stations.get(station_id, false)):
                _spawn_station_reward(station_id)
    _update_support_lights()

func _sync_completed_from_arc() -> void:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var arc_completed: Dictionary = Dictionary(arc.get("completed"))
    for station_variant: Variant in STATION_STAGE.keys():
        var station_id: String = str(station_variant)
        completed_stations[station_id] = bool(arc_completed.get(_station_save_key(station_id), false))

func _persist_station_to_arc(station_id: String) -> void:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var arc_completed: Dictionary = Dictionary(arc.get("completed"))
    arc_completed[_station_save_key(station_id)] = true
    arc.set("completed", arc_completed)
    arc.set("state_dirty", true)

func _station_save_key(station_id: String) -> String:
    return "coop_sync_%s" % station_id

func _has_active_support_light() -> bool:
    for remaining_variant: Variant in support_remaining.values():
        if float(remaining_variant) > 0.0:
            return true
    return false

func _team_spread_distance() -> float:
    if not _network_online():
        return 0.0
    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null or not coop.has_method("_get_active_peer_ids") or not coop.has_method("_get_survivor_state"):
        return 0.0

    var ids_value: Variant = coop.call("_get_active_peer_ids")
    if not (ids_value is Array):
        return 0.0
    var positions: Array[Vector3] = []
    for peer_variant: Variant in Array(ids_value):
        var state_value: Variant = coop.call("_get_survivor_state", int(peer_variant))
        if not (state_value is Dictionary):
            continue
        var state: Dictionary = Dictionary(state_value)
        if bool(state.get("downed", false)):
            continue
        var transform_value: Variant = state.get("transform", null)
        if transform_value is Transform3D:
            var survivor_transform: Transform3D = transform_value
            positions.append(survivor_transform.origin)

    var max_distance: float = 0.0
    for first_index: int in range(positions.size()):
        for second_index: int in range(first_index + 1, positions.size()):
            max_distance = maxf(max_distance, positions[first_index].distance_to(positions[second_index]))
    return max_distance

func _requester_position(peer_id: int) -> Vector3:
    if not _network_online() or peer_id == multiplayer.get_unique_id() or peer_id == 1 and _is_authoritative():
        var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
        return player.global_position if player != null else Vector3.INF

    var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
    if coop == null or not coop.has_method("_get_survivor_state"):
        return Vector3.INF
    var state_value: Variant = coop.call("_get_survivor_state", peer_id)
    if not (state_value is Dictionary):
        return Vector3.INF
    var state: Dictionary = Dictionary(state_value)
    var transform_value: Variant = state.get("transform", null)
    if transform_value is Transform3D:
        var survivor_transform: Transform3D = transform_value
        return survivor_transform.origin
    return Vector3.INF

func _dictionary_vector(values: Dictionary, key: String) -> Vector3:
    var value: Variant = values.get(key, Vector3.ZERO)
    return value if value is Vector3 else Vector3.ZERO

func _valid_panel(station_id: String, panel_id: String) -> bool:
    if not STATION_STAGE.has(station_id):
        return false
    return panel_id == "a" or panel_id == "b"

func _feedback_to_peer(peer_id: int, text: String) -> void:
    if not _network_online() or peer_id == multiplayer.get_unique_id() or peer_id == 1 and _is_authoritative():
        _set_local_status(text)
        return
    _receive_feedback.rpc_id(peer_id, text)

func _set_local_status(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _report_noise(position: Vector3, strength: float, label: String) -> void:
    if not _is_authoritative():
        return
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise != null and noise.has_method("report_noise"):
        noise.call("report_noise", position, strength, label)

func _request_autosave(reason: String) -> void:
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("request_autosave"):
        save_system.call("request_autosave", reason)

func _on_peer_connected(peer_id: int) -> void:
    if not _is_authoritative():
        return
    call_deferred("_send_state_to_peer", peer_id)

func _send_state_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    if _network_online():
        _receive_coop_state.rpc_id(peer_id, get_network_state())

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return true
    return network.has_method("is_server") and bool(network.call("is_server"))
