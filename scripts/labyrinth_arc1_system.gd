extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const FUSE_IDS: Array[String] = ["fuse_a", "fuse_b", "fuse_c"]
const VALVE_IDS: Array[String] = ["valve_a", "valve_b"]
const BREAKER_SEQUENCE: Array[String] = ["breaker_b", "breaker_a", "breaker_c"]
const HOLDOUT_DURATION: float = 120.0
const MID_CHECKPOINT: Vector3 = Vector3(-10.5, 0.92, -103.0)
const LOCKDOWN_CHECKPOINT: Vector3 = Vector3(9.5, 0.92, -125.0)

var configured_scene_id: int = 0
var arc_root: Node3D
var objective_script: Script
var enemy_script: Script
var pickup_script: Script
var journal_note_script: Script
var transition_script: Script

var completed: Dictionary = {}
var breaker_progress: int = 0
var current_stage: int = 0
var holdout_active: bool = false
var holdout_remaining: float = 0.0
var fault_timer: float = 0.0
var arc_elapsed_seconds: float = 0.0
var arc_started: bool = false
var pending_restore_state: Dictionary = {}
var final_exit_created: bool = false

var gates: Dictionary = {}
var dim_lights: Array[OmniLight3D] = []
var dim_light_base_energy: Dictionary = {}
var checkpoint_stage: int = 0
var state_sync_timer: float = 0.0
var stage_poll_timer: float = 0.0
var hud_timer: float = 0.0
var state_dirty: bool = true

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    objective_script = load("res://scripts/arc1_objective_node.gd") as Script
    enemy_script = load("res://scripts/arc1_enemy.gd") as Script
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    journal_note_script = load("res://scripts/journal_note.gd") as Script
    transition_script = load("res://scripts/outside_exit_trigger.gd") as Script
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        arc_root = null
        configured_scene_id = 0
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        arc_root = null
        gates.clear()
        dim_lights.clear()
        dim_light_base_energy.clear()
        final_exit_created = false
        call_deferred("_configure_scene", scene)
        return

    if arc_root == null or not is_instance_valid(arc_root):
        return

    var authoritative: bool = _is_authoritative()
    if authoritative:
        if _any_survivor_in_arc():
            arc_started = true
        if arc_started:
            arc_elapsed_seconds += delta

        if fault_timer > 0.0:
            fault_timer = maxf(0.0, fault_timer - delta)

        if holdout_active:
            holdout_remaining = maxf(0.0, holdout_remaining - delta)
            if holdout_remaining <= 0.0:
                holdout_active = false
                completed["lockdown"] = true
                state_dirty = true
                _report_noise(Vector3(0.0, 0.0, -135.0), 1.25, "lockdown release")
                _request_autosave("Arc 1 lockdown complete")

        stage_poll_timer -= delta
        if stage_poll_timer <= 0.0:
            stage_poll_timer = 0.25
            _refresh_stage()

        state_sync_timer -= delta
        if state_sync_timer <= 0.0 or state_dirty:
            state_sync_timer = 0.35
            _broadcast_state()
            state_dirty = false

    _update_runtime_visuals()
    _update_gate_state()

    hud_timer -= delta
    if hud_timer <= 0.0:
        hud_timer = 0.5 if holdout_active else 1.5
        _update_objective_hud()

func request_objective_interaction(objective_id: String) -> void:
    if objective_id.is_empty():
        return
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online and not _is_authoritative():
        _request_objective_remote.rpc_id(1, objective_id)
        return
    _handle_objective(objective_id)

func is_objective_completed(objective_id: String) -> bool:
    return bool(completed.get(objective_id, false))

func is_objective_available(objective_id: String) -> bool:
    if is_objective_completed(objective_id):
        return false
    if objective_id in FUSE_IDS:
        return current_stage == 1
    if objective_id in VALVE_IDS:
        return current_stage == 2
    if objective_id.begins_with("breaker_"):
        return current_stage == 3
    if objective_id == "lockdown_console":
        return current_stage == 4 and not holdout_active
    return false

func get_objective_prompt(objective_id: String, display_name: String) -> String:
    if is_objective_completed(objective_id):
        return "%s — complete" % display_name
    if objective_id == "lockdown_console" and holdout_active:
        return "Lockdown console — stabilization running"
    if not is_objective_available(objective_id):
        return "%s — no power" % display_name
    if objective_id in FUSE_IDS:
        return "Restore %s" % display_name
    if objective_id in VALVE_IDS:
        return "Turn %s" % display_name
    if objective_id.begins_with("breaker_"):
        return "Toggle %s" % display_name
    return "Use %s" % display_name

func should_enemy_be_active(_enemy_id: String, activation_stage: int) -> bool:
    return current_stage >= activation_stage and arc_root != null and is_instance_valid(arc_root)

func get_enemy_aggression_multiplier() -> float:
    var multiplier: float = 1.0 + maxf(0.0, float(current_stage - 1)) * 0.045
    if fault_timer > 0.0:
        multiplier += 0.18
    if holdout_active:
        multiplier += 0.38
    return multiplier

func get_save_state() -> Dictionary:
    return {
        "completed": completed.duplicate(true),
        "breaker_progress": breaker_progress,
        "stage": current_stage,
        "holdout_active": holdout_active,
        "holdout_remaining": holdout_remaining,
        "fault_timer": fault_timer,
        "arc_elapsed_seconds": arc_elapsed_seconds,
        "arc_started": arc_started,
        "checkpoint_stage": checkpoint_stage
    }

func restore_save_state(state: Dictionary) -> void:
    pending_restore_state = state.duplicate(true)
    _apply_restored_state(state)
    if arc_root != null and is_instance_valid(arc_root):
        _update_gate_state()
        _refresh_objective_visuals()
        _update_runtime_visuals()

func reset_progress() -> void:
    completed.clear()
    breaker_progress = 0
    current_stage = 0
    holdout_active = false
    holdout_remaining = 0.0
    fault_timer = 0.0
    arc_elapsed_seconds = 0.0
    arc_started = false
    checkpoint_stage = 0
    pending_restore_state.clear()
    state_dirty = true

@rpc("any_peer", "call_remote", "reliable", 8)
func _request_objective_remote(objective_id: String) -> void:
    if not _is_authoritative():
        return
    _handle_objective(objective_id)

@rpc("authority", "call_remote", "reliable", 8)
func _receive_arc_state(state: Dictionary) -> void:
    _apply_restored_state(state)
    if arc_root != null and is_instance_valid(arc_root):
        _update_gate_state()
        _refresh_objective_visuals()

func _handle_objective(objective_id: String) -> void:
    if not is_objective_available(objective_id):
        _set_local_objective("That control is not powered yet. Follow the current Arc 1 objective.")
        return

    if objective_id in FUSE_IDS:
        completed[objective_id] = true
        _report_noise(_objective_position(objective_id), 0.82, "fuse box restored")
        _request_autosave("Arc 1 maintenance fuse")
    elif objective_id in VALVE_IDS:
        completed[objective_id] = true
        _report_noise(_objective_position(objective_id), 0.92, "pressure valve")
        _request_autosave("Arc 1 pressure valve")
    elif objective_id.begins_with("breaker_"):
        var expected: String = BREAKER_SEQUENCE[clampi(breaker_progress, 0, BREAKER_SEQUENCE.size() - 1)]
        if objective_id == expected:
            breaker_progress += 1
            _report_noise(_objective_position(objective_id), 0.76, "archive breaker")
            if breaker_progress >= BREAKER_SEQUENCE.size():
                for breaker_id: String in BREAKER_SEQUENCE:
                    completed[breaker_id] = true
                _request_autosave("Arc 1 archive breakers")
            else:
                _set_local_objective("Breaker accepted. Sequence progress %d / %d." % [breaker_progress, BREAKER_SEQUENCE.size()])
        else:
            breaker_progress = 0
            fault_timer = 12.0
            _report_noise(_objective_position(objective_id), 1.30, "breaker fault alarm")
            _set_local_objective("POWER FAULT — sequence reset. Maintenance tag says B → A → C.")
    elif objective_id == "lockdown_console":
        holdout_active = true
        holdout_remaining = HOLDOUT_DURATION
        fault_timer = maxf(fault_timer, 5.0)
        _report_noise(_objective_position(objective_id), 1.45, "lockdown alarm")
        _set_local_objective("LOCKDOWN STARTED — survive while power stabilizes.")

    state_dirty = true
    _refresh_stage()
    _refresh_objective_visuals()

func _configure_scene(scene: Node) -> void:
    for _frame_index: int in range(90):
        await get_tree().process_frame
        if not is_instance_valid(scene) or get_tree().current_scene != scene:
            return
        if scene.get_node_or_null("LabyrinthExpansion") != null:
            break

    if not is_instance_valid(scene) or get_tree().current_scene != scene:
        return
    if scene.get_node_or_null("LabyrinthExpansion") == null:
        return

    var old_arc: Node = scene.get_node_or_null("Arc1Expansion")
    if old_arc != null:
        old_arc.free()

    var old_transition: Node = scene.get_node_or_null("LabyrinthExpansion/OutsideTransition")
    if old_transition != null:
        old_transition.free()

    arc_root = Node3D.new()
    arc_root.name = "Arc1Expansion"
    scene.add_child(arc_root)

    _build_geometry()
    _build_objectives()
    _build_supplies()
    _build_notes()
    _build_enemies()

    if not pending_restore_state.is_empty():
        _apply_restored_state(pending_restore_state)
    _refresh_stage()
    _update_gate_state()
    _refresh_objective_visuals()
    _update_runtime_visuals()
    state_dirty = true

func _build_geometry() -> void:
    if arc_root == null:
        return

    var wall_material: StandardMaterial3D = StandardMaterial3D.new()
    wall_material.albedo_color = Color(0.085, 0.09, 0.095, 1.0)
    wall_material.roughness = 0.97

    var floor_material: StandardMaterial3D = StandardMaterial3D.new()
    floor_material.albedo_color = Color(0.027, 0.031, 0.034, 1.0)
    floor_material.roughness = 0.90

    var wet_material: StandardMaterial3D = StandardMaterial3D.new()
    wet_material.albedo_color = Color(0.035, 0.055, 0.065, 1.0)
    wet_material.roughness = 0.34

    var metal_material: StandardMaterial3D = StandardMaterial3D.new()
    metal_material.albedo_color = Color(0.13, 0.12, 0.105, 1.0)
    metal_material.metallic = 0.48
    metal_material.roughness = 0.56

    _add_box(arc_root, "ArcFloor", Vector3(0.0, -0.1, -96.0), Vector3(28.0, 0.2, 90.0), floor_material)
    _add_box(arc_root, "ArcCeiling", Vector3(0.0, 3.1, -96.0), Vector3(28.0, 0.2, 90.0), wall_material)
    _add_box(arc_root, "ArcLeftPerimeter", Vector3(-14.0, 1.5, -96.0), Vector3(0.22, 3.2, 90.0), wall_material)
    _add_box(arc_root, "ArcRightPerimeter", Vector3(14.0, 1.5, -96.0), Vector3(0.22, 3.2, 90.0), wall_material)
    _add_box(arc_root, "ArcBackPerimeter", Vector3(0.0, 1.5, -141.0), Vector3(28.0, 3.2, 0.22), wall_material)
    _add_box(arc_root, "ArcFrontLeft", Vector3(-11.85, 1.5, -51.0), Vector3(4.3, 3.2, 0.22), wall_material)
    _add_box(arc_root, "ArcFrontRight", Vector3(4.85, 1.5, -51.0), Vector3(18.3, 3.2, 0.22), wall_material)

    _add_box(arc_root, "EntryLeft", Vector3(-9.7, 1.5, -55.0), Vector3(0.22, 3.2, 8.0), wall_material)
    _add_box(arc_root, "EntryRight", Vector3(-4.3, 1.5, -55.0), Vector3(0.22, 3.2, 8.0), wall_material)

    _add_box(arc_root, "MaintenanceWallA", Vector3(-4.0, 1.5, -64.0), Vector3(19.5, 3.2, 0.24), wall_material)
    _add_box(arc_root, "MaintenanceWallB", Vector3(4.0, 1.5, -71.5), Vector3(19.5, 3.2, 0.24), wall_material)
    _add_box(arc_root, "MaintenanceWallC", Vector3(-4.0, 1.5, -77.0), Vector3(19.5, 3.2, 0.24), wall_material)

    _add_box(arc_root, "FloodWallA", Vector3(4.2, 1.5, -87.0), Vector3(19.0, 3.2, 0.24), wall_material)
    _add_box(arc_root, "FloodWallB", Vector3(-4.2, 1.5, -94.0), Vector3(19.0, 3.2, 0.24), wall_material)
    _add_box(arc_root, "FloodWallC", Vector3(4.2, 1.5, -101.0), Vector3(19.0, 3.2, 0.24), wall_material)
    _add_box(arc_root, "FloodedStripA", Vector3(-7.0, 0.015, -89.8), Vector3(12.0, 0.03, 5.0), wet_material, false)
    _add_box(arc_root, "FloodedStripB", Vector3(6.5, 0.015, -98.2), Vector3(13.0, 0.03, 4.5), wet_material, false)

    _add_box(arc_root, "ArchiveSpineA", Vector3(0.0, 1.5, -112.5), Vector3(0.24, 3.2, 9.0), wall_material)
    _add_box(arc_root, "ArchiveSpineB", Vector3(0.0, 1.5, -121.5), Vector3(0.24, 3.2, 7.0), wall_material)
    _add_box(arc_root, "ArchiveShelfA", Vector3(-7.2, 0.85, -116.0), Vector3(8.5, 1.7, 0.65), metal_material)
    _add_box(arc_root, "ArchiveShelfB", Vector3(7.2, 0.85, -116.0), Vector3(8.5, 1.7, 0.65), metal_material)
    _add_box(arc_root, "ArchiveShelfC", Vector3(-7.2, 0.85, -122.5), Vector3(8.5, 1.7, 0.65), metal_material)
    _add_box(arc_root, "ArchiveShelfD", Vector3(7.2, 0.85, -122.5), Vector3(8.5, 1.7, 0.65), metal_material)

    _add_box(arc_root, "LockdownPillarA", Vector3(-7.0, 1.5, -133.0), Vector3(1.2, 3.0, 1.2), metal_material)
    _add_box(arc_root, "LockdownPillarB", Vector3(7.0, 1.5, -133.0), Vector3(1.2, 3.0, 1.2), metal_material)
    _add_box(arc_root, "LockdownPillarC", Vector3(-7.0, 1.5, -137.0), Vector3(1.2, 3.0, 1.2), metal_material)
    _add_box(arc_root, "LockdownPillarD", Vector3(7.0, 1.5, -137.0), Vector3(1.2, 3.0, 1.2), metal_material)

    gates["maintenance"] = _create_gate("MaintenanceGate", Vector3(0.0, 1.5, -80.5), metal_material)
    gates["flood"] = _create_gate("FloodGate", Vector3(0.0, 1.5, -106.0), metal_material)
    gates["archive"] = _create_gate("ArchiveGate", Vector3(0.0, 1.5, -127.0), metal_material)

    var lamp_positions: Array[Vector3] = [
        Vector3(-7.0, 2.65, -54.0), Vector3(-10.5, 2.65, -61.0), Vector3(4.5, 2.65, -62.0),
        Vector3(10.5, 2.65, -67.0), Vector3(-8.5, 2.65, -70.0), Vector3(7.5, 2.65, -75.0),
        Vector3(-10.0, 2.65, -84.0), Vector3(5.0, 2.65, -88.0), Vector3(10.0, 2.65, -92.0),
        Vector3(-4.0, 2.65, -96.0), Vector3(-10.5, 2.65, -101.5), Vector3(8.5, 2.65, -109.0),
        Vector3(-8.5, 2.65, -112.0), Vector3(6.5, 2.65, -117.0), Vector3(-10.0, 2.65, -121.0),
        Vector3(9.0, 2.65, -124.0), Vector3(0.0, 2.65, -130.0), Vector3(-8.0, 2.65, -135.0),
        Vector3(8.0, 2.65, -137.0)
    ]
    for lamp_index: int in range(lamp_positions.size()):
        var energy: float = 0.068 + float(lamp_index % 4) * 0.007
        _add_dim_lamp("ArcDimLamp%02d" % lamp_index, lamp_positions[lamp_index], energy, 6.2)

    _add_safe_lamp("MidSafeLamp", MID_CHECKPOINT + Vector3(0.0, 1.75, 0.0), 0.72, 4.6)
    _add_safe_lamp("LockdownSafeLamp", LOCKDOWN_CHECKPOINT + Vector3(0.0, 1.75, 0.0), 0.62, 4.2)

func _build_objectives() -> void:
    _spawn_objective("fuse_a", "Fuse Box A", "fuse", Vector3(-11.5, 0.0, -61.5))
    _spawn_objective("fuse_b", "Fuse Box B", "fuse", Vector3(11.2, 0.0, -68.0))
    _spawn_objective("fuse_c", "Fuse Box C", "fuse", Vector3(-11.2, 0.0, -76.0))

    _spawn_objective("valve_a", "Pressure Valve A", "valve", Vector3(-11.5, 0.0, -90.5))
    _spawn_objective("valve_b", "Pressure Valve B", "valve", Vector3(11.4, 0.0, -99.0))

    _spawn_objective("breaker_a", "Archive Breaker A", "breaker", Vector3(-10.5, 0.0, -111.0))
    _spawn_objective("breaker_b", "Archive Breaker B", "breaker", Vector3(10.5, 0.0, -118.5))
    _spawn_objective("breaker_c", "Archive Breaker C", "breaker", Vector3(-10.5, 0.0, -124.0))

    _spawn_objective("lockdown_console", "Lockdown Console", "console", Vector3(0.0, 0.0, -135.5))

func _build_supplies() -> void:
    _spawn_supply("flashlight_battery", "Flashlight Battery", Vector3(10.8, 0.05, -62.0))
    _spawn_supply("canned_food", "Canned Food", Vector3(-10.8, 0.05, -69.0))
    _spawn_supply("bottled_water", "Bottled Water", Vector3(9.8, 0.05, -76.5))
    _spawn_supply("bandage", "Bandage", Vector3(-11.0, 0.05, -86.0))
    _spawn_supply("flashlight_battery", "Flashlight Battery", Vector3(10.8, 0.05, -96.0))
    _spawn_supply("medkit", "Medkit", Vector3(-10.7, 0.05, -109.0))
    _spawn_supply("cloth", "Cloth", Vector3(10.8, 0.05, -121.0))
    _spawn_supply("bottled_water", "Bottled Water", Vector3(9.5, 0.05, -131.0))

func _build_notes() -> void:
    _spawn_note(
        "arc1_maintenance_map",
        "Maintenance Route Sheet",
        "MISSION NOTE",
        "The old relay gate is only the entrance. Three fuse boxes feed the lower service wing. The route loops deliberately: if you think you are going backward, you probably are.",
        Vector3(-6.2, 0.06, -57.5)
    )
    _spawn_note(
        "arc1_breaker_sequence",
        "Archive Breaker Tag",
        "TIP",
        "Archive isolation sequence: B, then A, then C. A wrong switch drops the maintenance lights and wakes everything that listens for alarms.",
        Vector3(8.7, 0.06, -109.5)
    )
    _spawn_note(
        "arc1_lockdown_warning",
        "Lockdown Procedure",
        "WARNING",
        "When the final console starts, stabilization takes two minutes. The emergency lights will pulse. Do not stand in one place. The things below learned where the safe lamps are.",
        Vector3(-8.5, 0.06, -129.5)
    )

func _build_enemies() -> void:
    _spawn_enemy("mourner_a", "mourner", 1, Vector3(9.5, 0.0, -73.5), 1.72, 12.0, 18.0)
    _spawn_enemy("mourner_b", "mourner", 2, Vector3(-9.5, 0.0, -98.0), 1.88, 13.0, 19.0)
    _spawn_enemy("crawler_a", "crawler", 3, Vector3(10.0, 0.0, -119.5), 2.48, 15.0, 22.0)
    _spawn_enemy("crawler_b", "crawler", 4, Vector3(-9.0, 0.0, -134.0), 2.62, 16.0, 23.0)

func _refresh_stage() -> void:
    var previous_stage: int = current_stage
    var next_stage: int = 0

    if _all_relays_active():
        next_stage = 1
        if _all_completed(FUSE_IDS):
            next_stage = 2
        if next_stage >= 2 and _all_completed(VALVE_IDS):
            next_stage = 3
        if next_stage >= 3 and breaker_progress >= BREAKER_SEQUENCE.size():
            next_stage = 4
        if next_stage >= 4 and holdout_active:
            next_stage = 5
        if bool(completed.get("lockdown", false)):
            next_stage = 6

    current_stage = next_stage
    if current_stage != previous_stage:
        state_dirty = true
        _on_stage_changed(previous_stage, current_stage)

func _on_stage_changed(_previous_stage: int, new_stage: int) -> void:
    _update_gate_state()
    _refresh_objective_visuals()
    _update_objective_hud()

    if new_stage == 2:
        _request_autosave("Arc 1 Maintenance Wing complete")
    elif new_stage == 3:
        _activate_checkpoint(MID_CHECKPOINT, "Arc 1 flooded service safe lamp", 1)
        _request_autosave("Arc 1 Flooded Service complete")
    elif new_stage == 4:
        _activate_checkpoint(LOCKDOWN_CHECKPOINT, "Arc 1 lockdown approach", 2)
        _request_autosave("Arc 1 Archive complete")
    elif new_stage == 6:
        _create_final_exit()
        _request_autosave("Arc 1 complete")

func _update_gate_state() -> void:
    if arc_root == null:
        return
    if current_stage >= 2:
        _remove_gate("maintenance")
    if current_stage >= 3:
        _remove_gate("flood")
    if current_stage >= 4:
        _remove_gate("archive")
    if current_stage >= 6:
        _create_final_exit()

func _update_runtime_visuals() -> void:
    var multiplier: float = 1.0
    if fault_timer > 0.0:
        multiplier = 0.16 + 0.12 * absf(sin(float(Time.get_ticks_msec()) / 95.0))
    elif holdout_active:
        multiplier = 0.58 + 0.38 * absf(sin(float(Time.get_ticks_msec()) / 180.0))

    for light: OmniLight3D in dim_lights:
        if light == null or not is_instance_valid(light):
            continue
        var base_energy: float = float(dim_light_base_energy.get(int(light.get_instance_id()), 0.075))
        light.light_energy = minf(0.098, base_energy * multiplier)

func _update_objective_hud() -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    if player.global_position.z > -47.5 and current_stage <= 1:
        return

    match current_stage:
        0:
            _set_local_objective("ARC 1: Restore all 3 emergency relays to open the lower labyrinth.")
        1:
            _set_local_objective("ARC 1 — MAINTENANCE WING: Restore fuse boxes %d / 3." % _completed_count(FUSE_IDS))
        2:
            _set_local_objective("ARC 1 — FLOODED SERVICE: Turn pressure valves %d / 2. Search side passages for supplies." % _completed_count(VALVE_IDS))
        3:
            _set_local_objective("ARC 1 — ARCHIVE: Breaker sequence B → A → C. Progress %d / 3." % breaker_progress)
        4:
            _set_local_objective("ARC 1 — LOCKDOWN: Reach the final console. Prepare light, healing and stamina first.")
        5:
            var remaining: int = maxi(0, int(ceil(holdout_remaining)))
            _set_local_objective("LOCKDOWN: stabilize power %d:%02d — survive and keep moving." % [remaining / 60, remaining % 60])
        6:
            _set_local_objective("ARC 1 COMPLETE: Final exit unlocked. Follow the beacon to THE OUTSIDE.")

func _refresh_objective_visuals() -> void:
    if arc_root == null:
        return
    for child: Node in arc_root.get_children():
        if child.has_method("_refresh_visual"):
            child.call("_refresh_visual")

func _create_final_exit() -> void:
    if final_exit_created or arc_root == null or transition_script == null:
        return
    final_exit_created = true

    var beacon: OmniLight3D = OmniLight3D.new()
    beacon.name = "Arc1FinalBeacon"
    beacon.position = Vector3(0.0, 2.45, -139.0)
    beacon.light_color = Color(0.66, 0.84, 0.70, 1.0)
    beacon.light_energy = 1.65
    beacon.omni_range = 7.0
    beacon.shadow_enabled = true
    arc_root.add_child(beacon)

    var transition: Area3D = Area3D.new()
    transition.name = "OutsideTransitionArc1"
    transition.position = Vector3(0.0, 1.2, -139.3)
    transition.set_script(transition_script)
    arc_root.add_child(transition)

    var collision: CollisionShape3D = CollisionShape3D.new()
    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(5.0, 2.5, 1.2)
    collision.shape = shape
    transition.add_child(collision)

func _spawn_objective(objective_id: String, display_name: String, kind: String, position: Vector3) -> void:
    if arc_root == null or objective_script == null:
        return
    var node: StaticBody3D = StaticBody3D.new()
    node.name = "ArcObjective_%s" % objective_id
    node.position = position
    node.set_script(objective_script)
    node.set("objective_id", objective_id)
    node.set("display_name", display_name)
    node.set("objective_kind", kind)
    arc_root.add_child(node)

func _spawn_supply(item_id: String, display_name: String, position: Vector3) -> void:
    if arc_root == null or pickup_script == null:
        return
    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = "ArcSupply_%s_%d" % [item_id, arc_root.get_child_count()]
    pickup.position = position
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", NodePath("../../Player/HUD/Objective"))
    arc_root.add_child(pickup)

func _spawn_note(entry_id: String, title: String, category: String, body: String, position: Vector3) -> void:
    if arc_root == null or journal_note_script == null:
        return
    var note: StaticBody3D = StaticBody3D.new()
    note.name = "ArcJournal_%s" % entry_id
    note.position = position
    note.set_script(journal_note_script)
    note.set("entry_id", entry_id)
    note.set("entry_title", title)
    note.set("entry_category", category)
    note.set("entry_body", body)
    arc_root.add_child(note)

func _spawn_enemy(enemy_id: String, kind: String, activation_stage: int, position: Vector3, speed: float, damage: float, radius: float) -> void:
    if arc_root == null or enemy_script == null:
        return
    var enemy: Node3D = Node3D.new()
    enemy.name = "ArcEnemy_%s" % enemy_id
    enemy.position = position
    enemy.set_script(enemy_script)
    enemy.set("enemy_id", enemy_id)
    enemy.set("enemy_kind", kind)
    enemy.set("activation_stage", activation_stage)
    enemy.set("move_speed", speed)
    enemy.set("attack_damage", damage)
    enemy.set("detection_radius", radius)
    arc_root.add_child(enemy)

func _create_gate(node_name: String, position: Vector3, material: Material) -> StaticBody3D:
    if arc_root == null:
        return null
    var gate: StaticBody3D = StaticBody3D.new()
    gate.name = node_name
    gate.position = position
    arc_root.add_child(gate)

    var mesh: BoxMesh = BoxMesh.new()
    mesh.size = Vector3(27.5, 3.0, 0.34)
    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = material
    gate.add_child(visual)

    var shape: BoxShape3D = BoxShape3D.new()
    shape.size = Vector3(27.5, 3.0, 0.34)
    var collision: CollisionShape3D = CollisionShape3D.new()
    collision.shape = shape
    gate.add_child(collision)
    return gate

func _remove_gate(gate_id: String) -> void:
    var value: Variant = gates.get(gate_id, null)
    var gate: StaticBody3D = value as StaticBody3D
    if gate != null and is_instance_valid(gate):
        gate.queue_free()
    gates.erase(gate_id)

func _add_dim_lamp(node_name: String, position: Vector3, energy: float, light_range: float) -> void:
    if arc_root == null:
        return
    var fixture_material: StandardMaterial3D = StandardMaterial3D.new()
    fixture_material.albedo_color = Color(0.20, 0.21, 0.20, 1.0)
    fixture_material.emission_enabled = true
    fixture_material.emission = Color(0.24, 0.27, 0.25, 1.0)
    fixture_material.emission_energy_multiplier = 0.55

    var fixture_mesh: BoxMesh = BoxMesh.new()
    fixture_mesh.size = Vector3(0.58, 0.07, 0.24)
    var fixture: MeshInstance3D = MeshInstance3D.new()
    fixture.name = "%sFixture" % node_name
    fixture.mesh = fixture_mesh
    fixture.material_override = fixture_material
    fixture.position = position
    arc_root.add_child(fixture)

    var light: OmniLight3D = OmniLight3D.new()
    light.name = node_name
    light.position = position - Vector3(0.0, 0.12, 0.0)
    light.light_color = Color(0.42, 0.47, 0.49, 1.0)
    light.light_energy = minf(0.098, energy)
    light.omni_range = light_range
    light.shadow_enabled = false
    arc_root.add_child(light)
    dim_lights.append(light)
    dim_light_base_energy[int(light.get_instance_id())] = light.light_energy

func _add_safe_lamp(node_name: String, position: Vector3, energy: float, light_range: float) -> void:
    if arc_root == null:
        return
    var light: OmniLight3D = OmniLight3D.new()
    light.name = node_name
    light.position = position
    light.light_color = Color(0.58, 0.72, 0.62, 1.0)
    light.light_energy = energy
    light.omni_range = light_range
    light.shadow_enabled = true
    arc_root.add_child(light)

func _add_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material, collision: bool = true) -> CSGBox3D:
    var box: CSGBox3D = CSGBox3D.new()
    box.name = node_name
    box.position = position
    box.size = size
    box.use_collision = collision
    box.material = material
    parent.add_child(box)
    return box

func _all_relays_active() -> bool:
    var labyrinth: Node = get_node_or_null("/root/LabyrinthDirector")
    if labyrinth == null:
        return false
    var relays: Dictionary = Dictionary(labyrinth.get("active_relays"))
    return bool(relays.get(0, false)) and bool(relays.get(1, false)) and bool(relays.get(2, false))

func _all_completed(ids: Array[String]) -> bool:
    for objective_id: String in ids:
        if not bool(completed.get(objective_id, false)):
            return false
    return true

func _completed_count(ids: Array[String]) -> int:
    var count: int = 0
    for objective_id: String in ids:
        if bool(completed.get(objective_id, false)):
            count += 1
    return count

func _objective_position(objective_id: String) -> Vector3:
    if arc_root == null:
        return Vector3.ZERO
    var objective: Node3D = arc_root.get_node_or_null("ArcObjective_%s" % objective_id) as Node3D
    return objective.global_position if objective != null else Vector3.ZERO

func _any_survivor_in_arc() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online:
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop == null or not coop.has_method("_get_active_peer_ids") or not coop.has_method("_get_survivor_state"):
            return false
        var ids_value: Variant = coop.call("_get_active_peer_ids")
        if ids_value is Array:
            for peer_variant: Variant in Array(ids_value):
                var state_value: Variant = coop.call("_get_survivor_state", int(peer_variant))
                if not (state_value is Dictionary):
                    continue
                var state: Dictionary = Dictionary(state_value)
                var transform_value: Variant = state.get("transform", null)
                if transform_value is Transform3D:
                    var survivor_transform: Transform3D = transform_value
                    if survivor_transform.origin.z <= -50.0:
                        return true
        return false

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    return player != null and player.global_position.z <= -50.0

func _activate_checkpoint(position: Vector3, label: String, target_stage: int) -> void:
    if checkpoint_stage >= target_stage:
        return
    checkpoint_stage = target_stage
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    var checkpoint: Node = get_node_or_null("/root/CheckpointSystem")
    if player != null and checkpoint != null and checkpoint.has_method("save_checkpoint"):
        checkpoint.call("save_checkpoint", player, position, label)

func _request_autosave(reason: String) -> void:
    var save_system: Node = get_node_or_null("/root/SaveSystem")
    if save_system != null and save_system.has_method("request_autosave"):
        save_system.call("request_autosave", reason)

func _set_local_objective(text: String) -> void:
    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return
    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = text

func _report_noise(position: Vector3, strength: float, label: String) -> void:
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise != null and noise.has_method("report_noise"):
        noise.call("report_noise", position, strength, label)

func _is_authoritative() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return true
    return network.has_method("is_server") and bool(network.call("is_server"))

func _broadcast_state() -> void:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return
    if not _is_authoritative():
        return
    _receive_arc_state.rpc(get_save_state())

func _on_peer_connected(peer_id: int) -> void:
    if not _is_authoritative():
        return
    call_deferred("_send_state_to_peer", peer_id)

func _send_state_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    _receive_arc_state.rpc_id(peer_id, get_save_state())

func _apply_restored_state(state: Dictionary) -> void:
    if state.is_empty():
        return
    completed = Dictionary(state.get("completed", {})).duplicate(true)
    breaker_progress = clampi(int(state.get("breaker_progress", 0)), 0, BREAKER_SEQUENCE.size())
    current_stage = clampi(int(state.get("stage", 0)), 0, 6)
    holdout_active = bool(state.get("holdout_active", false))
    holdout_remaining = clampf(float(state.get("holdout_remaining", 0.0)), 0.0, HOLDOUT_DURATION)
    fault_timer = clampf(float(state.get("fault_timer", 0.0)), 0.0, 20.0)
    arc_elapsed_seconds = maxf(0.0, float(state.get("arc_elapsed_seconds", 0.0)))
    arc_started = bool(state.get("arc_started", false))
    checkpoint_stage = clampi(int(state.get("checkpoint_stage", 0)), 0, 2)
    state_dirty = true
