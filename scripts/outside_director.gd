extends Node

@export var full_day_seconds: float = 720.0

var configured_scene_id: int = 0
var outside_root: Node3D
var world_environment: WorldEnvironment
var sun: DirectionalLight3D
var daylight_protection: OmniLight3D
var shelter_generator: StaticBody3D
var shelter_lights: Array[OmniLight3D] = []
var pickup_script: Script
var generator_script: Script

var outside_active: bool = false
var shelter_powered: bool = false
var game_minutes: float = 990.0
var day_index: int = 1
var cold_exposure: float = 0.0
var cold_damage_timer: float = 4.0
var status_label: Label
var ui_timer: float = 0.0

const OUTSIDE_SPAWN := Vector3(0.0, 0.92, -57.5)
const SHELTER_CENTER := Vector3(14.0, 0.92, -82.0)
const SHELTER_CHECKPOINT := Vector3(14.0, 0.92, -82.2)

func _ready() -> void:
    pickup_script = load("res://scripts/survival_pickup.gd") as Script
    generator_script = load("res://scripts/shelter_generator.gd") as Script

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    var scene_id: int = int(scene.get_instance_id())
    if scene_id != configured_scene_id:
        configured_scene_id = scene_id
        outside_root = null
        world_environment = null
        sun = null
        daylight_protection = null
        shelter_generator = null
        shelter_lights.clear()
        status_label = null
        outside_active = false
        call_deferred("_configure_scene", scene)
        return

    var player: CharacterBody3D = get_tree().get_first_node_in_group("player") as CharacterBody3D
    if player == null:
        return

    outside_active = player.global_position.z < -52.0
    _ensure_status_label(player)

    if not outside_active:
        if status_label != null:
            status_label.visible = false
        return

    if status_label != null:
        status_label.visible = true

    var minutes_per_second: float = 1440.0 / maxf(60.0, full_day_seconds)
    game_minutes += minutes_per_second * delta
    if game_minutes >= 1440.0:
        game_minutes -= 1440.0
        day_index += 1

    var daylight: float = _get_daylight_factor()
    _update_daylight(daylight)
    _update_cold(player, daylight, delta)

    ui_timer -= delta
    if ui_timer <= 0.0:
        ui_timer = 0.25
        _update_status_hud(player, daylight)

func enter_outside(player: CharacterBody3D) -> void:
    if player == null:
        return

    var scene: Node = get_tree().current_scene
    if scene == null:
        return

    if outside_root == null or not is_instance_valid(outside_root):
        _build_outside(scene)

    var tenant: Node = scene.get_node_or_null("Monster")
    if tenant != null and tenant.has_method("stop_stalking"):
        tenant.call("stop_stalking")

    var dark_creature: Node = get_tree().get_first_node_in_group("darkness_creature")
    if dark_creature != null:
        dark_creature.queue_free()

    player.global_position = OUTSIDE_SPAWN
    player.velocity = Vector3.ZERO
    player.set("darkness_exposure", minf(18.0, float(player.get("darkness_exposure"))))
    outside_active = true

    var end_panel: Control = player.get_node_or_null("HUD/EndPanel") as Control
    if end_panel != null:
        end_panel.visible = false

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "THE OUTSIDE: Find the cabin. Search the abandoned supplies for fuel before night."

func activate_shelter(player: CharacterBody3D) -> bool:
    if shelter_powered:
        return true
    if player == null or not player.has_method("has_item"):
        return false

    var has_fuel: bool = bool(player.call("has_item", "generator_fuel"))
    if not has_fuel:
        var missing_objective: Label = player.get_node_or_null("HUD/Objective") as Label
        if missing_objective != null:
            missing_objective.text = "The generator is dry. Find a Fuel Can outside."
        return false

    if player.has_method("remove_item"):
        player.call("remove_item", "generator_fuel")

    shelter_powered = true
    cold_exposure = minf(cold_exposure, 20.0)
    _apply_shelter_power()

    var checkpoint_system: Node = get_node_or_null("/root/CheckpointSystem")
    if checkpoint_system != null and checkpoint_system.has_method("save_checkpoint"):
        checkpoint_system.call("save_checkpoint", player, SHELTER_CHECKPOINT, "Powered forest shelter")

    var objective: Label = player.get_node_or_null("HUD/Objective") as Label
    if objective != null:
        objective.text = "SHELTER ONLINE — Checkpoint saved. The lights will protect you tonight."
    return true

func is_outside_active() -> bool:
    return outside_active

func is_night() -> bool:
    return _get_daylight_factor() < 0.18

func get_time_minutes() -> float:
    return game_minutes

func get_cold_exposure() -> float:
    return cold_exposure

func _configure_scene(scene: Node) -> void:
    if not is_instance_valid(scene):
        return

    await get_tree().process_frame
    if not is_instance_valid(scene) or get_tree().current_scene != scene:
        return

    world_environment = scene.get_node_or_null("WorldEnvironment") as WorldEnvironment
    _build_outside(scene)

func _build_outside(scene: Node) -> void:
    if scene == null:
        return
    var existing: Node = scene.get_node_or_null("OutsideWorld")
    if existing != null:
        outside_root = existing as Node3D
        return

    outside_root = Node3D.new()
    outside_root.name = "OutsideWorld"
    scene.add_child(outside_root)

    var ground_material: StandardMaterial3D = StandardMaterial3D.new()
    ground_material.albedo_color = Color(0.055, 0.07, 0.055, 1.0)
    ground_material.roughness = 0.98

    var road_material: StandardMaterial3D = StandardMaterial3D.new()
    road_material.albedo_color = Color(0.075, 0.075, 0.07, 1.0)
    road_material.roughness = 0.94

    var cabin_material: StandardMaterial3D = StandardMaterial3D.new()
    cabin_material.albedo_color = Color(0.15, 0.105, 0.065, 1.0)
    cabin_material.roughness = 0.90

    var dark_material: StandardMaterial3D = StandardMaterial3D.new()
    dark_material.albedo_color = Color(0.045, 0.05, 0.045, 1.0)
    dark_material.roughness = 1.0

    _add_csg_box(outside_root, "ForestGround", Vector3(0.0, -0.12, -92.0), Vector3(72.0, 0.24, 80.0), ground_material)
    _add_csg_box(outside_root, "OldRoad", Vector3(0.0, 0.01, -82.0), Vector3(5.4, 0.04, 56.0), road_material)
    _add_csg_box(outside_root, "FarBoundary", Vector3(0.0, 1.2, -132.0), Vector3(72.0, 2.4, 0.35), dark_material)
    _add_csg_box(outside_root, "LeftBoundary", Vector3(-36.0, 1.2, -92.0), Vector3(0.35, 2.4, 80.0), dark_material)
    _add_csg_box(outside_root, "RightBoundary", Vector3(36.0, 1.2, -92.0), Vector3(0.35, 2.4, 80.0), dark_material)

    _build_cabin(cabin_material)
    _build_forest(dark_material)
    _build_daylight_nodes()
    _spawn_outside_loot()
    _apply_shelter_power()

func _build_cabin(material: Material) -> void:
    if outside_root == null:
        return

    _add_csg_box(outside_root, "CabinFloor", Vector3(14.0, 0.08, -82.0), Vector3(8.0, 0.18, 7.0), material)
    _add_csg_box(outside_root, "CabinRoof", Vector3(14.0, 3.15, -82.0), Vector3(8.4, 0.28, 7.4), material)
    _add_csg_box(outside_root, "CabinLeft", Vector3(10.0, 1.55, -82.0), Vector3(0.22, 3.0, 7.0), material)
    _add_csg_box(outside_root, "CabinRight", Vector3(18.0, 1.55, -82.0), Vector3(0.22, 3.0, 7.0), material)
    _add_csg_box(outside_root, "CabinBack", Vector3(14.0, 1.55, -85.5), Vector3(8.0, 3.0, 0.22), material)
    _add_csg_box(outside_root, "CabinFrontLeft", Vector3(11.4, 1.55, -78.5), Vector3(2.8, 3.0, 0.22), material)
    _add_csg_box(outside_root, "CabinFrontRight", Vector3(16.6, 1.55, -78.5), Vector3(2.8, 3.0, 0.22), material)
    _add_csg_box(outside_root, "CabinTable", Vector3(12.0, 0.72, -83.7), Vector3(1.8, 0.16, 0.8), material)

    if generator_script != null:
        shelter_generator = StaticBody3D.new()
        shelter_generator.name = "ShelterGenerator"
        shelter_generator.set_script(generator_script)
        shelter_generator.position = Vector3(16.1, 0.0, -84.0)
        outside_root.add_child(shelter_generator)

    var interior_light: OmniLight3D = OmniLight3D.new()
    interior_light.name = "ShelterInteriorLight"
    interior_light.position = Vector3(14.0, 2.45, -82.0)
    interior_light.light_color = Color(0.82, 0.76, 0.58, 1.0)
    interior_light.light_energy = 0.0
    interior_light.omni_range = 7.2
    interior_light.shadow_enabled = true
    outside_root.add_child(interior_light)
    shelter_lights.append(interior_light)

    var porch_light: OmniLight3D = OmniLight3D.new()
    porch_light.name = "ShelterPorchLight"
    porch_light.position = Vector3(14.0, 2.55, -77.8)
    porch_light.light_color = Color(0.76, 0.72, 0.58, 1.0)
    porch_light.light_energy = 0.0
    porch_light.omni_range = 8.0
    porch_light.shadow_enabled = true
    outside_root.add_child(porch_light)
    shelter_lights.append(porch_light)

func _build_forest(material: Material) -> void:
    if outside_root == null:
        return

    var tree_positions: Array[Vector3] = [
        Vector3(-8.0, 0.0, -61.0), Vector3(8.0, 0.0, -64.0),
        Vector3(-17.0, 0.0, -70.0), Vector3(19.0, 0.0, -69.0),
        Vector3(-25.0, 0.0, -82.0), Vector3(27.0, 0.0, -80.0),
        Vector3(-12.0, 0.0, -91.0), Vector3(25.0, 0.0, -94.0),
        Vector3(-27.0, 0.0, -101.0), Vector3(6.0, 0.0, -105.0),
        Vector3(-14.0, 0.0, -115.0), Vector3(22.0, 0.0, -117.0),
        Vector3(-30.0, 0.0, -123.0), Vector3(30.0, 0.0, -126.0)
    ]

    var index: int = 0
    for tree_position: Vector3 in tree_positions:
        index += 1
        _add_csg_box(outside_root, "Tree%d" % index, tree_position + Vector3(0.0, 1.8, 0.0), Vector3(0.55, 3.6, 0.55), material)

func _build_daylight_nodes() -> void:
    if outside_root == null:
        return

    sun = DirectionalLight3D.new()
    sun.name = "OutsideSun"
    sun.light_color = Color(0.86, 0.82, 0.70, 1.0)
    sun.light_energy = 0.0
    sun.shadow_enabled = true
    sun.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
    outside_root.add_child(sun)

    daylight_protection = OmniLight3D.new()
    daylight_protection.name = "DaylightProtection"
    daylight_protection.position = Vector3(0.0, 5.0, -92.0)
    daylight_protection.light_color = Color(0.58, 0.62, 0.56, 1.0)
    daylight_protection.light_energy = 0.0
    daylight_protection.omni_range = 90.0
    daylight_protection.shadow_enabled = false
    outside_root.add_child(daylight_protection)

func _spawn_outside_loot() -> void:
    if outside_root == null or pickup_script == null:
        return

    _spawn_pickup("OutsideFuel", "generator_fuel", "Fuel Can", Vector3(-11.5, 0.02, -69.0))
    _spawn_pickup("OutsideBattery", "flashlight_battery", "Flashlight Battery", Vector3(-20.0, 0.02, -76.0))
    _spawn_pickup("OutsideWater", "bottled_water", "Bottled Water", Vector3(24.0, 0.02, -70.0))
    _spawn_pickup("OutsideFood", "canned_food", "Canned Food", Vector3(25.0, 0.02, -102.0))
    _spawn_pickup("OutsideMedkit", "medkit", "Medkit", Vector3(-23.0, 0.02, -111.0))

func _spawn_pickup(node_name: String, item_id: String, display_name: String, position: Vector3) -> void:
    if outside_root == null or pickup_script == null:
        return
    if outside_root.has_node(NodePath(node_name)):
        return

    var pickup: StaticBody3D = StaticBody3D.new()
    pickup.name = StringName(node_name)
    pickup.set_script(pickup_script)
    pickup.set("item_id", item_id)
    pickup.set("display_name", display_name)
    pickup.set("objective_label_path", NodePath("../../Player/HUD/Objective"))
    pickup.position = position
    outside_root.add_child(pickup)

func _apply_shelter_power() -> void:
    for light: OmniLight3D in shelter_lights:
        if is_instance_valid(light):
            light.light_energy = 1.25 if shelter_powered else 0.0

    if shelter_generator != null and is_instance_valid(shelter_generator) and shelter_generator.has_method("set_powered_from_restore"):
        shelter_generator.call("set_powered_from_restore", shelter_powered)

func _update_daylight(daylight: float) -> void:
    if sun != null and is_instance_valid(sun):
        sun.light_energy = lerpf(0.0, 1.15, daylight)
        var sun_progress: float = game_minutes / 1440.0
        sun.rotation_degrees = Vector3(-15.0 - sin(sun_progress * TAU) * 55.0, -28.0, 0.0)

    if daylight_protection != null and is_instance_valid(daylight_protection):
        daylight_protection.light_energy = 0.34 * daylight

    if world_environment != null and world_environment.environment != null:
        var environment: Environment = world_environment.environment
        var night_color: Color = Color(0.006, 0.010, 0.018, 1.0)
        var day_color: Color = Color(0.34, 0.42, 0.48, 1.0)
        environment.background_color = night_color.lerp(day_color, daylight)
        environment.ambient_light_color = Color(0.12, 0.15, 0.18, 1.0).lerp(Color(0.60, 0.64, 0.62, 1.0), daylight)
        environment.ambient_light_energy = lerpf(0.07, 0.62, daylight)

func _update_cold(player: CharacterBody3D, daylight: float, delta: float) -> void:
    var in_shelter: bool = shelter_powered and player.global_position.distance_to(SHELTER_CENTER) <= 6.5

    if in_shelter:
        cold_exposure = maxf(0.0, cold_exposure - 4.0 * delta)
    elif daylight >= 0.35:
        cold_exposure = maxf(0.0, cold_exposure - 1.8 * delta)
    elif daylight < 0.18:
        cold_exposure = minf(100.0, cold_exposure + 0.70 * delta)
    else:
        cold_exposure = minf(100.0, cold_exposure + 0.25 * delta)

    if cold_exposure >= 72.0:
        var current_stamina: float = float(player.get("stamina"))
        player.set("stamina", maxf(0.0, current_stamina - 1.25 * delta))

    cold_damage_timer -= delta
    if cold_exposure >= 100.0 and cold_damage_timer <= 0.0:
        cold_damage_timer = 4.0
        if player.has_method("apply_damage"):
            player.call("apply_damage", 4.0, "exposure")
    elif cold_exposure < 100.0:
        cold_damage_timer = maxf(cold_damage_timer, 1.0)

func _get_daylight_factor() -> float:
    var minute: float = game_minutes
    if minute >= 420.0 and minute < 1020.0:
        return 1.0
    if minute >= 1020.0 and minute < 1140.0:
        return 1.0 - clampf((minute - 1020.0) / 120.0, 0.0, 1.0)
    if minute >= 300.0 and minute < 420.0:
        return clampf((minute - 300.0) / 120.0, 0.0, 1.0)
    return 0.0

func _ensure_status_label(player: CharacterBody3D) -> void:
    if status_label != null and is_instance_valid(status_label):
        return

    var hud: CanvasLayer = player.get_node_or_null("HUD") as CanvasLayer
    if hud == null:
        return

    status_label = Label.new()
    status_label.name = "OutsideStatus"
    status_label.anchor_left = 0.5
    status_label.anchor_right = 0.5
    status_label.anchor_top = 0.0
    status_label.anchor_bottom = 0.0
    status_label.offset_left = -190.0
    status_label.offset_right = 190.0
    status_label.offset_top = 14.0
    status_label.offset_bottom = 48.0
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 18)
    status_label.visible = outside_active
    hud.add_child(status_label)

func _update_status_hud(player: CharacterBody3D, daylight: float) -> void:
    if status_label == null:
        return

    var hour: int = int(floor(game_minutes / 60.0))
    var minute: int = int(game_minutes) % 60
    var phase: String = "DAY"
    if daylight < 0.18:
        phase = "NIGHT"
    elif daylight < 0.65:
        phase = "DUSK / DAWN"

    var viewport_width: float = player.get_viewport().get_visible_rect().size.x
    if viewport_width < 800.0:
        status_label.offset_left = -135.0
        status_label.offset_right = 135.0
        status_label.add_theme_font_size_override("font_size", 14)
        status_label.text = "%02d:%02d  COLD %d%%" % [hour, minute, int(round(cold_exposure))]
    else:
        status_label.offset_left = -210.0
        status_label.offset_right = 210.0
        status_label.add_theme_font_size_override("font_size", 18)
        status_label.text = "DAY %d  |  %02d:%02d  |  %s  |  COLD %d%%" % [day_index, hour, minute, phase, int(round(cold_exposure))]

func _add_csg_box(parent: Node3D, node_name: String, position: Vector3, size: Vector3, material: Material) -> CSGBox3D:
    var box: CSGBox3D = CSGBox3D.new()
    box.name = node_name
    box.position = position
    box.size = size
    box.use_collision = true
    box.material = material
    parent.add_child(box)
    return box
