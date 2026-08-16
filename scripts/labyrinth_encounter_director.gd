extends Node

const LABYRINTH_SCENE_PATH: String = "res://scenes/main.tscn"
const ENEMY_STAGE: Dictionary = {
    "mourner_a": 1,
    "mourner_b": 2,
    "crawler_a": 3,
    "crawler_b": 4
}
const HORROR_EVENT_TYPES: Array[String] = ["slam", "footsteps", "flicker", "shadow", "blackout"]
const HORROR_EVENT_POSITIONS: Array[Vector3] = [
    Vector3(-9.0, 0.0, -62.0), Vector3(9.0, 0.0, -69.0), Vector3(-8.5, 0.0, -76.0),
    Vector3(-9.5, 0.0, -88.0), Vector3(9.0, 0.0, -97.0), Vector3(-8.0, 0.0, -104.0),
    Vector3(-9.0, 0.0, -113.0), Vector3(9.0, 0.0, -121.0), Vector3(0.0, 0.0, -132.0)
]

var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var active_enemy_ids: Array[String] = []
var threat_state: String = "CALM"
var threat_budget: int = 0
var encounter_timer: float = 0.0
var horror_event_timer: float = 0.0
var sync_timer: float = 0.0
var shared_time: float = 0.0
var configured_scene_id: int = 0
var hazard_scene_id: int = 0
var last_stage: int = -1
var local_flicker_timer: float = 0.0
var local_blackout: bool = false
var hazard_script: Script

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    rng.randomize()
    hazard_script = load("res://scripts/arc1_hazard.gd") as Script
    encounter_timer = 3.0
    horror_event_timer = 65.0
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != LABYRINTH_SCENE_PATH:
        _reset_outside_labyrinth()
        return

    var arc_root: Node3D = scene.get_node_or_null("Arc1Expansion") as Node3D
    if arc_root == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        hazard_scene_id = 0
        active_enemy_ids.clear()
        threat_state = "CALM"
        threat_budget = 0
        last_stage = -1
        encounter_timer = 2.0
        horror_event_timer = 55.0

    _ensure_hazards(arc_root, scene_id)

    var authoritative: bool = _is_authoritative()
    if authoritative:
        shared_time += delta
        var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
        if arc != null:
            var stage: int = int(arc.get("current_stage"))
            var holdout: bool = bool(arc.get("holdout_active"))
            var elapsed: float = float(arc.get("arc_elapsed_seconds"))
            threat_budget = _compute_threat_budget(stage, holdout, elapsed)
            threat_state = _threat_name(threat_budget, holdout)

            encounter_timer -= delta
            if stage != last_stage or encounter_timer <= 0.0:
                last_stage = stage
                _select_enemy_set(stage, threat_budget)
                encounter_timer = _next_encounter_interval(stage, holdout)

            horror_event_timer -= delta
            if stage > 0 and horror_event_timer <= 0.0:
                _trigger_horror_event(stage, holdout)
                horror_event_timer = _next_horror_interval(stage, holdout)

        sync_timer -= delta
        if sync_timer <= 0.0:
            sync_timer = 0.45
            _receive_director_state.rpc(active_enemy_ids.duplicate(), threat_state, threat_budget, shared_time)

    local_flicker_timer = maxf(0.0, local_flicker_timer - delta)
    _apply_local_light_event()

func is_enemy_enabled(enemy_id: String, activation_stage: int) -> bool:
    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null or int(arc.get("current_stage")) < activation_stage:
        return false
    return active_enemy_ids.has(enemy_id)

func get_shared_time() -> float:
    return shared_time

func get_threat_state() -> String:
    return threat_state

func get_threat_budget() -> int:
    return threat_budget

func _compute_threat_budget(stage: int, holdout: bool, elapsed: float) -> int:
    if stage <= 0 or stage >= 6:
        return 0

    var budget: int = 1
    if stage == 2:
        budget = 2
    elif stage == 3:
        budget = 2
    elif stage == 4:
        budget = 3
    elif stage == 5 or holdout:
        budget = 4

    if elapsed >= 1200.0 and stage <= 3:
        budget += 1
    if _survivors_in_distress():
        budget -= 1

    budget -= _external_monster_pressure_cost()
    return clampi(budget, 0, 4)

func _threat_name(budget: int, holdout: bool) -> String:
    if holdout:
        return "LOCKDOWN"
    if budget <= 0:
        return "CALM"
    if budget == 1:
        return "UNEASY"
    if budget == 2:
        return "DANGER"
    return "SEVERE"

func _select_enemy_set(stage: int, budget: int) -> void:
    var eligible: Array[String] = []
    for enemy_variant: Variant in ENEMY_STAGE.keys():
        var enemy_id: String = str(enemy_variant)
        if stage >= int(ENEMY_STAGE.get(enemy_id, 99)):
            eligible.append(enemy_id)

    var selected: Array[String] = []
    var remaining: int = budget
    while remaining > 0 and not eligible.is_empty():
        var pick_index: int = rng.randi_range(0, eligible.size() - 1)
        var picked: String = eligible[pick_index]
        eligible.remove_at(pick_index)
        selected.append(picked)
        remaining -= 1

    selected.sort()
    if selected != active_enemy_ids:
        active_enemy_ids = selected
        _receive_director_snapshot.rpc(active_enemy_ids.duplicate(), threat_state, threat_budget, shared_time)

func _next_encounter_interval(stage: int, holdout: bool) -> float:
    if holdout:
        return rng.randf_range(12.0, 20.0)
    if stage <= 1:
        return rng.randf_range(28.0, 42.0)
    if stage <= 3:
        return rng.randf_range(22.0, 34.0)
    return rng.randf_range(17.0, 27.0)

func _next_horror_interval(stage: int, holdout: bool) -> float:
    if holdout:
        return rng.randf_range(18.0, 30.0)
    if stage <= 1:
        return rng.randf_range(70.0, 125.0)
    if stage <= 3:
        return rng.randf_range(48.0, 92.0)
    return rng.randf_range(36.0, 68.0)

func _trigger_horror_event(stage: int, holdout: bool) -> void:
    var type_pool: Array[String] = HORROR_EVENT_TYPES.duplicate()
    if stage <= 1:
        type_pool.erase("blackout")
    if holdout:
        type_pool.append("blackout")
        type_pool.append("slam")

    var event_type: String = type_pool[rng.randi_range(0, type_pool.size() - 1)]
    var event_position: Vector3 = HORROR_EVENT_POSITIONS[rng.randi_range(0, HORROR_EVENT_POSITIONS.size() - 1)]
    _apply_horror_event(event_type, event_position)
    _receive_horror_event.rpc(event_type, event_position)

func _apply_horror_event(event_type: String, event_position: Vector3) -> void:
    match event_type:
        "flicker":
            local_flicker_timer = maxf(local_flicker_timer, 2.4)
            local_blackout = false
            _report_noise(event_position, 0.55, "light relay flicker")
        "blackout":
            local_flicker_timer = maxf(local_flicker_timer, 3.6)
            local_blackout = true
            _report_noise(event_position, 0.92, "maintenance blackout")
        "shadow":
            _spawn_fake_shadow(event_position)
            _report_noise(event_position, 0.34, "movement in the dark")
        "footsteps":
            _report_noise(event_position, 0.72, "false footsteps")
        _:
            _report_noise(event_position, 0.88, "distant metal slam")

func _apply_local_light_event() -> void:
    if local_flicker_timer <= 0.0:
        local_blackout = false
        return

    var arc: Node = get_node_or_null("/root/LabyrinthArc1System")
    if arc == null:
        return
    var light_value: Variant = arc.get("dim_lights")
    if not (light_value is Array):
        return

    var pulse: float = 0.26 + 0.28 * absf(sin(float(Time.get_ticks_msec()) / 82.0))
    if local_blackout:
        pulse *= 0.22
    for light_variant: Variant in Array(light_value):
        var light: OmniLight3D = light_variant as OmniLight3D
        if light != null and is_instance_valid(light):
            light.light_energy *= pulse

func _spawn_fake_shadow(event_position: Vector3) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var shadow: Node3D = Node3D.new()
    shadow.name = "ArcFakeShadow"
    shadow.position = event_position + Vector3(-3.2, 0.0, 0.0)
    scene.add_child(shadow)

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.005, 0.005, 0.006, 1.0)
    material.roughness = 1.0

    var mesh: CapsuleMesh = CapsuleMesh.new()
    mesh.radius = 0.28
    mesh.height = 1.9
    mesh.radial_segments = 8
    mesh.rings = 4

    var visual: MeshInstance3D = MeshInstance3D.new()
    visual.mesh = mesh
    visual.material_override = material
    visual.position.y = 1.0
    shadow.add_child(visual)

    var tween: Tween = shadow.create_tween()
    tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
    tween.tween_property(shadow, "position:x", event_position.x + 3.2, 1.15)
    tween.tween_interval(0.15)
    tween.tween_callback(shadow.queue_free)

func _ensure_hazards(arc_root: Node3D, scene_id: int) -> void:
    if hazard_scene_id == scene_id or hazard_script == null:
        return
    hazard_scene_id = scene_id

    _spawn_hazard(arc_root, "SteamMaintenance", "steam", 1, Vector3(2.8, 0.0, -73.5), 1.25, 9.0, 5.3, 1.15, 0.4)
    _spawn_hazard(arc_root, "ElectricFloodA", "electric", 2, Vector3(-7.0, 0.02, -89.8), 1.85, 8.0, 2.8, 1.05, 0.0)
    _spawn_hazard(arc_root, "SteamFlood", "steam", 2, Vector3(4.8, 0.0, -94.5), 1.30, 10.0, 4.8, 1.10, 1.3)
    _spawn_hazard(arc_root, "ElectricFloodB", "electric", 2, Vector3(6.5, 0.02, -98.2), 1.90, 8.0, 3.1, 1.05, 1.1)
    _spawn_hazard(arc_root, "SteamArchive", "steam", 3, Vector3(4.8, 0.0, -121.0), 1.20, 11.0, 4.5, 1.00, 2.0)

func _spawn_hazard(parent: Node3D, node_name: String, kind: String, stage: int, position: Vector3, radius: float, damage: float, cycle: float, active_duration: float, phase_offset: float) -> void:
    if parent.has_node(NodePath(node_name)):
        return
    var hazard: Node3D = Node3D.new()
    hazard.name = node_name
    hazard.position = position
    hazard.set_script(hazard_script)
    hazard.set("hazard_id", node_name.to_snake_case())
    hazard.set("hazard_kind", kind)
    hazard.set("activation_stage", stage)
    hazard.set("hazard_radius", radius)
    hazard.set("damage", damage)
    hazard.set("cycle_duration", cycle)
    hazard.set("active_duration", active_duration)
    hazard.set("phase_offset", phase_offset)
    parent.add_child(hazard)

func _survivors_in_distress() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online:
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop == null or not coop.has_method("_get_active_peer_ids") or not coop.has_method("_get_survivor_state"):
            return false
        var ids_value: Variant = coop.call("_get_active_peer_ids")
        if not (ids_value is Array):
            return false
        for peer_variant: Variant in Array(ids_value):
            var state_value: Variant = coop.call("_get_survivor_state", int(peer_variant))
            if not (state_value is Dictionary):
                continue
            var state: Dictionary = Dictionary(state_value)
            if bool(state.get("downed", false)) or float(state.get("health", 100.0)) < 35.0:
                return true
        return false

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    return player != null and float(player.get("health")) < 35.0

func _external_monster_pressure_cost() -> int:
    var cost: int = 0
    var network: Node = get_node_or_null("/root/NetworkManager")
    var online: bool = network != null and network.has_method("is_online") and bool(network.call("is_online"))
    if online:
        var coop: Node = get_node_or_null("/root/CoopHorrorSystem")
        if coop != null:
            if bool(coop.get("tenant_active")):
                cost += 2
            if bool(coop.get("dark_active")):
                cost += 2
        return cost

    var scene: Node = get_tree().current_scene
    if scene != null:
        var tenant: Node = scene.get_node_or_null("Monster")
        if tenant != null and bool(tenant.get("active")) and tenant.visible:
            cost += 2
    var dark: Node3D = get_tree().get_first_node_in_group("darkness_creature") as Node3D
    if dark != null and is_instance_valid(dark) and dark.visible:
        cost += 2
    return cost

func _report_noise(position: Vector3, strength: float, label: String) -> void:
    if not _is_authoritative():
        return
    var noise: Node = get_node_or_null("/root/AINoiseRelaySystem")
    if noise != null and noise.has_method("report_noise"):
        noise.call("report_noise", position, strength, label)

func _is_authoritative() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    if network == null or not network.has_method("is_online") or not bool(network.call("is_online")):
        return true
    return network.has_method("is_server") and bool(network.call("is_server"))

func _reset_outside_labyrinth() -> void:
    configured_scene_id = 0
    hazard_scene_id = 0
    active_enemy_ids.clear()
    threat_state = "CALM"
    threat_budget = 0
    last_stage = -1
    local_flicker_timer = 0.0
    local_blackout = false

@rpc("authority", "call_remote", "unreliable", 11)
func _receive_director_state(ids: Array, state_name: String, budget: int, host_time: float) -> void:
    var restored: Array[String] = []
    for id_variant: Variant in ids:
        restored.append(str(id_variant))
    active_enemy_ids = restored
    threat_state = state_name
    threat_budget = budget
    shared_time = host_time

@rpc("authority", "call_remote", "reliable", 11)
func _receive_director_snapshot(ids: Array, state_name: String, budget: int, host_time: float) -> void:
    _receive_director_state(ids, state_name, budget, host_time)

@rpc("authority", "call_remote", "reliable", 11)
func _receive_horror_event(event_type: String, event_position: Vector3) -> void:
    _apply_horror_event(event_type, event_position)

func _on_peer_connected(peer_id: int) -> void:
    if not _is_authoritative() or peer_id <= 1:
        return
    call_deferred("_send_snapshot_to_peer", peer_id)

func _send_snapshot_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    _receive_director_snapshot.rpc_id(peer_id, active_enemy_ids.duplicate(), threat_state, threat_budget, shared_time)
