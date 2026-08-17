extends "res://scripts/forest_survival_system.gd"

const CARCASS_SCRIPT_PATH: String = "res://scripts/wildlife_carcass.gd"
const BLOOD_MARK_SCRIPT_PATH: String = "res://scripts/wildlife_blood_mark.gd"
const CARCASS_DECAY_SECONDS: float = 210.0

var carcass_script: Script
var blood_mark_script: Script
var carcass_nodes: Dictionary = {}
var carcass_records: Dictionary = {}
var carcass_decay: Dictionary = {}

var rain_particles: CPUParticles3D
var rain_owner_id: int = 0
var lightning_flash: ColorRect
var lightning_strength: float = 0.0
var lightning_timer: float = 6.0
var vfx_rng: RandomNumberGenerator = RandomNumberGenerator.new()

func _ready() -> void:
    super._ready()
    carcass_script = load(CARCASS_SCRIPT_PATH) as Script
    blood_mark_script = load(BLOOD_MARK_SCRIPT_PATH) as Script
    vfx_rng.randomize()
    _build_v26_weather_ui()

func _process(delta: float) -> void:
    super._process(delta)
    if not forest_active:
        if rain_particles != null and is_instance_valid(rain_particles):
            rain_particles.emitting = false
        if lightning_flash != null:
            lightning_flash.visible = false
        return

    if _is_authoritative():
        _tick_carcass_decay(delta)
    _update_v26_weather_vfx(delta)

func on_animal_wounded(_animal_id: String, animal_kind: String, position: Vector3) -> void:
    if not _is_authoritative():
        return
    _emit_blood_mark(position, animal_kind)

func on_animal_blood_trail(position: Vector3, animal_kind: String) -> void:
    if not _is_authoritative():
        return
    _emit_blood_mark(position, animal_kind)

func on_animal_killed(animal_id: String, animal_kind: String, hunter_peer_id: int, death_position: Vector3) -> void:
    if not _is_authoritative():
        return
    respawn_timers[animal_id] = animal_respawn_seconds
    _emit_blood_mark(death_position, animal_kind)
    _spawn_or_replace_carcass(animal_id, animal_kind, death_position)
    _message_peer(
        hunter_peer_id,
        "HUNT: %s tumbang. Ikuti jejak darah dan panen carcass dengan Hunting Knife sebelum meninggalkannya." % animal_kind.capitalize()
    )
    _broadcast_wildlife_state()

func request_harvest(carcass_id: String) -> void:
    if not forest_active or _ui_blocked():
        return
    var player: CharacterBody3D = _local_player()
    if player == null or not player.has_method("has_item"):
        return
    if not bool(player.call("has_item", "hunting_knife")):
        _objective(player, "Kamu membutuhkan Hunting Knife untuk memanen carcass tanpa merusak daging dan hide.")
        return

    var peer_id: int = _local_peer_id()
    if _network_online() and not _is_authoritative():
        _request_harvest_remote.rpc_id(1, carcass_id)
    else:
        _resolve_harvest(peer_id, carcass_id)

@rpc("any_peer", "call_remote", "reliable", 29)
func _request_harvest_remote(carcass_id: String) -> void:
    if not _is_authoritative():
        return
    _resolve_harvest(multiplayer.get_remote_sender_id(), carcass_id)

func _resolve_harvest(peer_id: int, carcass_id: String) -> void:
    if not carcass_records.has(carcass_id):
        _message_peer(peer_id, "Carcass itu sudah tidak dapat dipanen.")
        return
    var record: Dictionary = Dictionary(carcass_records.get(carcass_id, {}))
    if bool(record.get("harvested", false)):
        _message_peer(peer_id, "Carcass itu sudah dipanen anggota tim lain.")
        return

    record["harvested"] = true
    carcass_records[carcass_id] = record
    carcass_decay[carcass_id] = 4.0
    _set_carcass_harvested_local(carcass_id, true)
    if _network_online():
        _receive_carcass_harvested.rpc(carcass_id)

    var animal_kind: String = str(record.get("kind", "deer"))
    var loot: Dictionary = _loot_for_kind(animal_kind)
    _grant_loot_to_peer(
        peer_id,
        loot,
        "HARVEST: %s dipanen — %s. Raw food harus dimasak di campfire." % [animal_kind.capitalize(), _loot_summary(loot)]
    )

@rpc("authority", "call_remote", "reliable", 30)
func _receive_carcass_harvested(carcass_id: String) -> void:
    _set_carcass_harvested_local(carcass_id, true)
    if carcass_records.has(carcass_id):
        var record: Dictionary = Dictionary(carcass_records.get(carcass_id, {}))
        record["harvested"] = true
        carcass_records[carcass_id] = record

func _spawn_or_replace_carcass(carcass_id: String, animal_kind: String, position: Vector3) -> void:
    carcass_records[carcass_id] = {
        "kind": animal_kind,
        "position": position,
        "harvested": false
    }
    carcass_decay[carcass_id] = CARCASS_DECAY_SECONDS
    _spawn_carcass_local(carcass_id, animal_kind, position, false)
    if _network_online():
        _receive_carcass_spawn.rpc(carcass_id, animal_kind, position, false)

@rpc("authority", "call_remote", "reliable", 31)
func _receive_carcass_spawn(carcass_id: String, animal_kind: String, position: Vector3, harvested: bool) -> void:
    carcass_records[carcass_id] = {
        "kind": animal_kind,
        "position": position,
        "harvested": harvested
    }
    _spawn_carcass_local(carcass_id, animal_kind, position, harvested)

func _spawn_carcass_local(carcass_id: String, animal_kind: String, position: Vector3, harvested: bool) -> void:
    if outside_root == null or carcass_script == null:
        return
    var old: Node = carcass_nodes.get(carcass_id, null) as Node
    if old != null and is_instance_valid(old):
        var old_parent: Node = old.get_parent()
        if old_parent != null:
            old_parent.remove_child(old)
        old.queue_free()

    var carcass: StaticBody3D = StaticBody3D.new()
    carcass.name = "Carcass_%s" % carcass_id
    carcass.set_script(carcass_script)
    outside_root.add_child(carcass)
    if carcass.has_method("configure"):
        carcass.call("configure", carcass_id, animal_kind)
    carcass.global_position = Vector3(position.x, maxf(0.0, position.y), position.z)
    if carcass.has_method("set_harvested"):
        carcass.call("set_harvested", harvested)
    carcass_nodes[carcass_id] = carcass

func _set_carcass_harvested_local(carcass_id: String, harvested: bool) -> void:
    var carcass: Node = carcass_nodes.get(carcass_id, null) as Node
    if carcass != null and is_instance_valid(carcass) and carcass.has_method("set_harvested"):
        carcass.call("set_harvested", harvested)

func _tick_carcass_decay(delta: float) -> void:
    var remove_ids: PackedStringArray = PackedStringArray()
    for id_value: Variant in carcass_decay.keys():
        var carcass_id: String = str(id_value)
        var remaining: float = maxf(0.0, float(carcass_decay.get(carcass_id, 0.0)) - delta)
        carcass_decay[carcass_id] = remaining
        if remaining <= 0.0:
            remove_ids.append(carcass_id)
    for carcass_id: String in remove_ids:
        _remove_carcass(carcass_id)

func _remove_carcass(carcass_id: String) -> void:
    _remove_carcass_local(carcass_id)
    carcass_records.erase(carcass_id)
    carcass_decay.erase(carcass_id)
    if _network_online() and _is_authoritative():
        _receive_carcass_removed.rpc(carcass_id)

@rpc("authority", "call_remote", "reliable", 32)
func _receive_carcass_removed(carcass_id: String) -> void:
    _remove_carcass_local(carcass_id)
    carcass_records.erase(carcass_id)

func _remove_carcass_local(carcass_id: String) -> void:
    var carcass: Node = carcass_nodes.get(carcass_id, null) as Node
    carcass_nodes.erase(carcass_id)
    if carcass != null and is_instance_valid(carcass):
        carcass.queue_free()

func _emit_blood_mark(position: Vector3, animal_kind: String) -> void:
    _spawn_blood_mark_local(position, animal_kind)
    if _network_online() and _is_authoritative():
        _receive_blood_mark.rpc(position, animal_kind)

@rpc("authority", "call_remote", "unreliable", 33)
func _receive_blood_mark(position: Vector3, animal_kind: String) -> void:
    _spawn_blood_mark_local(position, animal_kind)

func _spawn_blood_mark_local(position: Vector3, animal_kind: String) -> void:
    if outside_root == null or blood_mark_script == null:
        return
    var mark: Node3D = Node3D.new()
    mark.name = "BloodTrail_%s_%d" % [animal_kind, Time.get_ticks_msec()]
    mark.set_script(blood_mark_script)
    outside_root.add_child(mark)
    mark.global_position = Vector3(position.x, 0.025, position.z)
    mark.rotation.y = vfx_rng.randf_range(0.0, TAU)
    var scale_factor: float = 0.72 if animal_kind == "rabbit" else vfx_rng.randf_range(0.90, 1.18)
    mark.scale = Vector3(scale_factor, 1.0, scale_factor)

func _on_peer_connected(peer_id: int) -> void:
    super._on_peer_connected(peer_id)
    if not forest_active or not _is_authoritative():
        return
    call_deferred("_send_carcasses_to_peer", peer_id)

func _send_carcasses_to_peer(peer_id: int) -> void:
    await get_tree().process_frame
    if not _is_authoritative():
        return
    for id_value: Variant in carcass_records.keys():
        var carcass_id: String = str(id_value)
        var record: Dictionary = Dictionary(carcass_records.get(carcass_id, {}))
        _receive_carcass_spawn.rpc_id(
            peer_id,
            carcass_id,
            str(record.get("kind", "deer")),
            Vector3(record.get("position", Vector3.ZERO)),
            bool(record.get("harvested", false))
        )

func _build_v26_weather_ui() -> void:
    if ui_layer == null:
        return
    lightning_flash = ColorRect.new()
    lightning_flash.name = "LightningFlash"
    lightning_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
    lightning_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
    lightning_flash.color = Color(0.78, 0.86, 1.0, 0.0)
    lightning_flash.visible = false
    ui_layer.add_child(lightning_flash)

func _update_v26_weather_vfx(delta: float) -> void:
    var player: CharacterBody3D = _local_player()
    if player == null:
        return
    _ensure_rain_particles(player)

    var sheltered: bool = player.global_position.distance_to(SHELTER_CENTER) <= 6.0
    var raining: bool = current_weather == "rain" or current_weather == "storm"
    if rain_particles != null:
        rain_particles.emitting = raining and not sheltered
        rain_particles.amount = 360 if current_weather == "storm" else 230
        rain_particles.gravity = Vector3(2.4, -27.0, 0.8) if current_weather == "storm" else Vector3(0.8, -23.0, 0.3)

    if current_weather == "storm":
        lightning_timer -= delta
        if lightning_timer <= 0.0:
            lightning_strength = vfx_rng.randf_range(0.42, 0.72)
            lightning_timer = vfx_rng.randf_range(4.0, 10.5)
    else:
        lightning_timer = minf(lightning_timer, 4.0)

    lightning_strength = move_toward(lightning_strength, 0.0, delta * 2.8)
    if lightning_flash != null:
        lightning_flash.visible = lightning_strength > 0.002
        lightning_flash.color = Color(0.78, 0.86, 1.0, lightning_strength)

func _ensure_rain_particles(player: CharacterBody3D) -> void:
    var player_id: int = int(player.get_instance_id())
    if rain_particles != null and is_instance_valid(rain_particles) and rain_owner_id == player_id:
        return
    if rain_particles != null and is_instance_valid(rain_particles):
        rain_particles.queue_free()

    rain_owner_id = player_id
    rain_particles = CPUParticles3D.new()
    rain_particles.name = "LocalRainV26"
    rain_particles.amount = 230
    rain_particles.lifetime = 0.95
    rain_particles.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
    rain_particles.emission_box_extents = Vector3(12.0, 0.25, 12.0)
    rain_particles.direction = Vector3(0.0, -1.0, 0.0)
    rain_particles.spread = 5.0
    rain_particles.initial_velocity_min = 13.0
    rain_particles.initial_velocity_max = 18.0
    rain_particles.gravity = Vector3(0.8, -23.0, 0.3)
    rain_particles.position = Vector3(0.0, 8.5, 0.0)
    rain_particles.emitting = false

    var drop_mesh: BoxMesh = BoxMesh.new()
    drop_mesh.size = Vector3(0.018, 0.58, 0.018)
    var drop_material: StandardMaterial3D = StandardMaterial3D.new()
    drop_material.albedo_color = Color(0.62, 0.73, 0.86, 0.48)
    drop_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    drop_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    drop_mesh.material = drop_material
    rain_particles.mesh = drop_mesh
    player.add_child(rain_particles)
