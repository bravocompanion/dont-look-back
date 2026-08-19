extends Node

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
const TOWER_POSITION: Vector3 = Vector3(24.0, 0.0, -91.0)
const TOWER_PROTECTION_RADIUS: float = 42.0
const TOWER_EXTRA_GENERATOR_DRAW: float = 0.35
const RADIATION_START_DAY: int = 3

var radiation: float = 0.0
var radiation_rate: float = 0.0
var tower_built: bool = false
var tower_root: Node3D = null
var tower_aura: MeshInstance3D = null
var tower_light: OmniLight3D = null
var tower_scene_id: int = 0
var damage_timer: float = 3.0
var last_day_announced: int = 0

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    process_priority = 260
    if not multiplayer.peer_connected.is_connected(_on_peer_connected):
        multiplayer.peer_connected.connect(_on_peer_connected)

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    if scene.scene_file_path == FOREST_SCENE_PATH:
        _ensure_tower_visual(scene)
        _update_tower_visual(delta)
        if _is_authoritative():
            _apply_tower_power_draw(delta)
    else:
        tower_root = null
        tower_aura = null
        tower_light = null
        tower_scene_id = 0

    var player: CharacterBody3D = _local_player()
    if player == null or bool(player.get("is_dead")):
        radiation_rate = 0.0
        return

    _update_radiation(player, scene, delta)
    _apply_radiation_condition(player, delta)
    _announce_day_transition(player)

func get_radiation() -> float:
    return radiation

func get_radiation_rate() -> float:
    return radiation_rate

func is_tower_built() -> bool:
    return tower_built

func is_tower_powered() -> bool:
    if not tower_built:
        return false
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    return shelter != null and shelter.has_method("is_generator_running") and bool(shelter.call("is_generator_running"))

func get_tower_radius() -> float:
    return TOWER_PROTECTION_RADIUS

func can_build_tower() -> bool:
    if tower_built:
        return false
    if _network_online() and not _is_authoritative():
        return false
    return true

func build_tower(_player: CharacterBody3D = null) -> bool:
    if not can_build_tower():
        return false
    tower_built = true
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == FOREST_SCENE_PATH:
        _ensure_tower_visual(scene)
    if _network_online() and _is_authoritative():
        _receive_tower_state.rpc(tower_built)
    _request_autosave("Anti-radiation tower constructed")
    return true

func reset_progress() -> void:
    radiation = 0.0
    radiation_rate = 0.0
    tower_built = false
    damage_timer = 3.0
    last_day_announced = 0
    if tower_root != null and is_instance_valid(tower_root):
        tower_root.queue_free()
    tower_root = null
    tower_aura = null
    tower_light = null
    tower_scene_id = 0

func get_save_state() -> Dictionary:
    return {
        "radiation": radiation,
        "tower_built": tower_built
    }

func restore_save_state(state: Dictionary) -> void:
    radiation = clampf(float(state.get("radiation", 0.0)), 0.0, 100.0)
    tower_built = bool(state.get("tower_built", false))
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == FOREST_SCENE_PATH:
        call_deferred("_ensure_tower_visual", scene)

func is_position_protected(world_position: Vector3) -> bool:
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    var generator_on: bool = shelter != null and shelter.has_method("is_generator_running") and bool(shelter.call("is_generator_running"))
    if not generator_on:
        return false

    var safe_zone: Node = get_node_or_null("/root/RangerSafeZone")
    if safe_zone != null and safe_zone.has_method("is_position_safe") and bool(safe_zone.call("is_position_safe", world_position)):
        return true

    return tower_built and world_position.distance_to(TOWER_POSITION) <= TOWER_PROTECTION_RADIUS

func _update_radiation(player: CharacterBody3D, scene: Node, delta: float) -> void:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    var day_index: int = int(outside.get("day_index")) if outside != null else 1

    if scene.scene_file_path != FOREST_SCENE_PATH or day_index < RADIATION_START_DAY:
        radiation_rate = -0.45
        radiation = maxf(0.0, radiation + radiation_rate * delta)
        return

    if is_position_protected(player.global_position):
        radiation_rate = -1.20
        radiation = maxf(0.0, radiation + radiation_rate * delta)
        return

    var base_rate: float = 0.10
    if day_index == 4:
        base_rate = 0.14
    elif day_index >= 5:
        base_rate = minf(0.32, 0.18 + float(day_index - 5) * 0.018)

    var weather_multiplier: float = 1.0
    var forest_runtime: Node = get_node_or_null("/root/SurvivalSystem/ForestSurvivalRuntime")
    if forest_runtime != null:
        var weather: String = str(forest_runtime.get("current_weather"))
        if weather == "rain":
            weather_multiplier = 1.12
        elif weather == "storm":
            weather_multiplier = 1.35

    var gear_multiplier: float = 1.0
    if player.has_method("has_item") and bool(player.call("has_item", "radiation_suit")):
        gear_multiplier = 0.22

    radiation_rate = base_rate * weather_multiplier * gear_multiplier
    radiation = minf(100.0, radiation + radiation_rate * delta)

func _apply_radiation_condition(player: CharacterBody3D, delta: float) -> void:
    if radiation >= 35.0:
        player.set("stamina", maxf(0.0, float(player.get("stamina")) - 0.08 * delta))
    if radiation >= 55.0:
        player.set("thirst", maxf(0.0, float(player.get("thirst")) - 0.035 * delta))

    damage_timer -= delta
    if damage_timer > 0.0:
        return
    damage_timer = 3.0

    var damage: float = 0.0
    if radiation >= 90.0:
        damage = 5.0
    elif radiation >= 72.0:
        damage = 2.5
    if damage > 0.0 and player.has_method("apply_damage"):
        player.call("apply_damage", damage, "radiation exposure")

func _announce_day_transition(player: CharacterBody3D) -> void:
    var outside: Node = get_node_or_null("/root/OutsideDirector")
    if outside == null:
        return
    var day_index: int = int(outside.get("day_index"))
    if day_index == last_day_announced:
        return
    last_day_announced = day_index

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective == null:
        return
    if day_index == 2:
        objective.text = "DAY 2 WARNING: Radiation is forecast for Day 3. Scavenge shielding parts and prepare powered protection."
    elif day_index == 3:
        objective.text = "DAY 3: Radiation has reached the forest. A running generator protects the ranger yard; a powered tower extends the safe field."
    elif day_index >= 4:
        objective.text = "DAY %d: Radiation intensity and hostile pressure are increasing. Keep power, protection gear, and an escape route ready." % day_index

func _apply_tower_power_draw(delta: float) -> void:
    if not is_tower_powered():
        return
    var shelter: Node = get_node_or_null("/root/ShelterSystem")
    if shelter == null:
        return
    var fuel: float = maxf(0.0, float(shelter.get("generator_fuel_seconds")) - TOWER_EXTRA_GENERATOR_DRAW * delta)
    shelter.set("generator_fuel_seconds", fuel)
    if fuel <= 0.0:
        shelter.set("generator_running", false)
        if shelter.has_method("_sync_generator_state"):
            shelter.call("_sync_generator_state")

func _ensure_tower_visual(scene: Node) -> void:
    if not tower_built or scene == null or not is_instance_valid(scene):
        return
    var scene_id: int = int(scene.get_instance_id())
    if tower_scene_id == scene_id and tower_root != null and is_instance_valid(tower_root):
        return

    tower_root = scene.get_node_or_null("AntiRadiationTowerV41") as Node3D
    if tower_root == null:
        tower_root = Node3D.new()
        tower_root.name = "AntiRadiationTowerV41"
        tower_root.position = TOWER_POSITION
        scene.add_child(tower_root)
        _build_tower_geometry(tower_root)

    tower_aura = tower_root.get_node_or_null("Aura") as MeshInstance3D
    tower_light = tower_root.get_node_or_null("PowerGlow") as OmniLight3D
    tower_scene_id = scene_id

func _build_tower_geometry(root: Node3D) -> void:
    var dark_material: StandardMaterial3D = StandardMaterial3D.new()
    dark_material.albedo_color = Color(0.12, 0.14, 0.15, 1.0)
    dark_material.metallic = 0.72
    dark_material.roughness = 0.48

    var base_body: StaticBody3D = StaticBody3D.new()
    base_body.name = "TowerBase"
    root.add_child(base_body)

    var base_mesh: MeshInstance3D = MeshInstance3D.new()
    var base_box: BoxMesh = BoxMesh.new()
    base_box.size = Vector3(1.7, 0.35, 1.7)
    base_mesh.mesh = base_box
    base_mesh.material_override = dark_material
    base_mesh.position = Vector3(0.0, 0.18, 0.0)
    base_body.add_child(base_mesh)

    var base_collision: CollisionShape3D = CollisionShape3D.new()
    var base_shape: BoxShape3D = BoxShape3D.new()
    base_shape.size = Vector3(1.7, 0.35, 1.7)
    base_collision.shape = base_shape
    base_collision.position = Vector3(0.0, 0.18, 0.0)
    base_body.add_child(base_collision)

    var mast: MeshInstance3D = MeshInstance3D.new()
    mast.name = "Mast"
    var cylinder: CylinderMesh = CylinderMesh.new()
    cylinder.top_radius = 0.16
    cylinder.bottom_radius = 0.22
    cylinder.height = 4.8
    mast.mesh = cylinder
    mast.material_override = dark_material
    mast.position = Vector3(0.0, 2.65, 0.0)
    root.add_child(mast)

    var emitter_material: StandardMaterial3D = StandardMaterial3D.new()
    emitter_material.albedo_color = Color(0.20, 0.82, 0.72, 1.0)
    emitter_material.emission_enabled = true
    emitter_material.emission = Color(0.08, 0.72, 0.58, 1.0)
    emitter_material.emission_energy_multiplier = 3.0

    var emitter: MeshInstance3D = MeshInstance3D.new()
    emitter.name = "Emitter"
    var emitter_mesh: SphereMesh = SphereMesh.new()
    emitter_mesh.radius = 0.42
    emitter_mesh.height = 0.84
    emitter.mesh = emitter_mesh
    emitter.material_override = emitter_material
    emitter.position = Vector3(0.0, 5.1, 0.0)
    root.add_child(emitter)

    var aura_material: StandardMaterial3D = StandardMaterial3D.new()
    aura_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
    aura_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
    aura_material.albedo_color = Color(0.10, 0.82, 0.66, 0.12)
    aura_material.emission_enabled = true
    aura_material.emission = Color(0.04, 0.52, 0.38, 1.0)
    aura_material.emission_energy_multiplier = 1.4

    tower_aura = MeshInstance3D.new()
    tower_aura.name = "Aura"
    var aura_mesh: CylinderMesh = CylinderMesh.new()
    aura_mesh.top_radius = 5.4
    aura_mesh.bottom_radius = 5.4
    aura_mesh.height = 0.035
    tower_aura.mesh = aura_mesh
    tower_aura.material_override = aura_material
    tower_aura.position = Vector3(0.0, 0.045, 0.0)
    root.add_child(tower_aura)

    tower_light = OmniLight3D.new()
    tower_light.name = "PowerGlow"
    tower_light.position = Vector3(0.0, 4.8, 0.0)
    tower_light.light_color = Color(0.18, 0.88, 0.68, 1.0)
    tower_light.light_energy = 0.0
    tower_light.omni_range = 9.0
    tower_light.shadow_enabled = false
    root.add_child(tower_light)

    var sign: Label3D = Label3D.new()
    sign.name = "TowerLabel"
    sign.text = "ANTI-RADIATION TOWER"
    sign.position = Vector3(0.0, 3.6, 0.0)
    sign.font_size = 24
    sign.billboard = BaseMaterial3D.BILLBOARD_ENABLED
    root.add_child(sign)

func _update_tower_visual(_delta: float) -> void:
    if tower_root == null or not is_instance_valid(tower_root):
        return
    var active: bool = is_tower_powered()
    if tower_aura != null and is_instance_valid(tower_aura):
        tower_aura.visible = active
        if active:
            var pulse: float = 0.96 + 0.04 * sin(float(Time.get_ticks_msec()) / 330.0)
            tower_aura.scale = Vector3(pulse, 1.0, pulse)
    if tower_light != null and is_instance_valid(tower_light):
        tower_light.light_energy = 0.52 if active else 0.0

func _local_player() -> CharacterBody3D:
    var fallback: CharacterBody3D = null
    for node: Node in get_tree().get_nodes_in_group("player"):
        var player: CharacterBody3D = node as CharacterBody3D
        if player == null:
            continue
        if fallback == null:
            fallback = player
        var camera: Camera3D = player.get_node_or_null("Camera3D") as Camera3D
        if camera != null and camera.current:
            return player
    return fallback

func _network_online() -> bool:
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_online") and bool(network.call("is_online"))

func _is_authoritative() -> bool:
    if not _network_online():
        return true
    var network: Node = get_node_or_null("/root/NetworkManager")
    return network != null and network.has_method("is_server") and bool(network.call("is_server"))

func _on_peer_connected(peer_id: int) -> void:
    if not _is_authoritative() or peer_id <= 1:
        return
    _receive_tower_state.rpc_id(peer_id, tower_built)

@rpc("authority", "call_remote", "reliable", 63)
func _receive_tower_state(built: bool) -> void:
    tower_built = built
    var scene: Node = get_tree().current_scene
    if scene != null and scene.scene_file_path == FOREST_SCENE_PATH:
        call_deferred("_ensure_tower_visual", scene)

func _request_autosave(reason: String) -> void:
    var save: Node = get_node_or_null("/root/SaveSystem")
    if save != null and save.has_method("request_autosave"):
        save.call("request_autosave", reason)
