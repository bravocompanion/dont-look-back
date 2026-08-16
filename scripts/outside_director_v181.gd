extends "res://scripts/outside_director.gd"

const FOREST_SCENE_PATH: String = "res://scenes/forest.tscn"
var entry_boundary_scene_id: int = 0
var forest_polish_scene_id: int = 0
var moon_fill: DirectionalLight3D

func _process(delta: float) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        outside_active = false
        return
    super._process(delta)
    _ensure_forest_entry_boundary(scene)
    _ensure_v183_forest_polish(scene)
    _apply_v184_celestial_lighting()

func enter_outside(player: CharacterBody3D) -> void:
    var scene: Node = get_tree().current_scene
    if scene == null or scene.scene_file_path != FOREST_SCENE_PATH:
        var transition: Node = get_node_or_null("/root/MapTransitionSystem")
        if transition != null and transition.has_method("request_forest_transition"):
            transition.call("request_forest_transition")
        return
    super.enter_outside(player)

func _ensure_forest_entry_boundary(scene: Node) -> void:
    if outside_root == null or not is_instance_valid(outside_root):
        return
    var scene_id: int = int(scene.get_instance_id())
    if entry_boundary_scene_id == scene_id:
        return
    if outside_root.has_node("ForestEntryBoundary"):
        entry_boundary_scene_id = scene_id
        return

    var material: StandardMaterial3D = StandardMaterial3D.new()
    material.albedo_color = Color(0.035, 0.042, 0.035, 1.0)
    material.roughness = 1.0

    var boundary: CSGBox3D = CSGBox3D.new()
    boundary.name = "ForestEntryBoundary"
    boundary.position = Vector3(0.0, 1.25, -52.2)
    boundary.size = Vector3(72.0, 2.5, 0.35)
    boundary.use_collision = true
    boundary.material = material
    outside_root.add_child(boundary)
    entry_boundary_scene_id = scene_id

func _ensure_v183_forest_polish(scene: Node) -> void:
    if outside_root == null or not is_instance_valid(outside_root):
        return
    var scene_id: int = int(scene.get_instance_id())
    if forest_polish_scene_id == scene_id:
        return

    if not outside_root.has_node("CabinEntryStepV183"):
        var porch_material: StandardMaterial3D = StandardMaterial3D.new()
        porch_material.albedo_color = Color(0.16, 0.105, 0.065, 1.0)
        porch_material.roughness = 0.92

        var entry_step: CSGBox3D = CSGBox3D.new()
        entry_step.name = "CabinEntryStepV183"
        entry_step.position = Vector3(14.0, 0.055, -77.95)
        entry_step.size = Vector3(2.15, 0.11, 1.05)
        entry_step.use_collision = true
        entry_step.material = porch_material
        outside_root.add_child(entry_step)

    if not outside_root.has_node("CabinEntryDimV183"):
        var entry_light: OmniLight3D = OmniLight3D.new()
        entry_light.name = "CabinEntryDimV183"
        entry_light.position = Vector3(14.0, 2.25, -78.15)
        entry_light.light_color = Color(0.58, 0.52, 0.39, 1.0)
        entry_light.light_energy = 0.075
        entry_light.omni_range = 4.4
        entry_light.shadow_enabled = false
        outside_root.add_child(entry_light)

    moon_fill = outside_root.get_node_or_null("ForestMoonFillV183") as DirectionalLight3D
    if moon_fill == null:
        moon_fill = DirectionalLight3D.new()
        moon_fill.name = "ForestMoonFillV183"
        moon_fill.light_color = Color(0.34, 0.43, 0.62, 1.0)
        moon_fill.light_energy = 0.0
        moon_fill.shadow_enabled = false
        moon_fill.rotation_degrees = Vector3(-52.0, 24.0, 0.0)
        outside_root.add_child(moon_fill)

    forest_polish_scene_id = scene_id

func _apply_v184_celestial_lighting() -> void:
    if outside_root == null or not is_instance_valid(outside_root):
        return

    var clock_minutes: float = fposmod(game_minutes, 1440.0)
    var clock_progress: float = clock_minutes / 1440.0
    var orbit_radians: float = clock_progress * TAU

    # Positive solar elevation means the sun is above the horizon.
    # Midnight = -1, 06:00/18:00 = 0, noon = +1.
    var sun_elevation: float = -cos(orbit_radians)
    var moon_elevation: float = cos(orbit_radians)

    var sun_strength: float = clampf((sun_elevation + 0.06) / 0.55, 0.0, 1.0)
    var moon_strength: float = clampf((moon_elevation + 0.05) / 0.70, 0.0, 1.0)
    var daylight: float = _get_daylight_factor()

    # Full 360-degree daily orbit. -90 and 270 are equivalent, so the
    # midnight wrap is visually continuous instead of snapping direction.
    var sun_yaw: float = -90.0 + clock_progress * 360.0
    var sun_altitude: float = 3.0 + maxf(0.0, sun_elevation) * 72.0
    if sun != null and is_instance_valid(sun):
        sun.rotation_degrees = Vector3(-sun_altitude, sun_yaw, 0.0)
        sun.light_energy = 1.35 * sun_strength
        var low_sun: Color = Color(1.0, 0.48, 0.27, 1.0)
        var high_sun: Color = Color(1.0, 0.91, 0.76, 1.0)
        sun.light_color = low_sun.lerp(high_sun, clampf(sun_strength * 1.25, 0.0, 1.0))
        sun.shadow_enabled = sun_strength > 0.06

    if daylight_protection != null and is_instance_valid(daylight_protection):
        daylight_protection.light_energy = 0.34 * daylight

    if moon_fill == null or not is_instance_valid(moon_fill):
        moon_fill = outside_root.get_node_or_null("ForestMoonFillV183") as DirectionalLight3D

    if moon_fill != null and is_instance_valid(moon_fill):
        var moon_yaw: float = sun_yaw + 180.0
        var moon_altitude: float = 3.0 + maxf(0.0, moon_elevation) * 58.0
        var night_weight: float = clampf(1.0 - daylight, 0.0, 1.0)
        moon_fill.rotation_degrees = Vector3(-moon_altitude, moon_yaw, 0.0)
        moon_fill.light_color = Color(0.34, 0.43, 0.62, 1.0)
        moon_fill.light_energy = 0.16 * moon_strength * night_weight
        moon_fill.shadow_enabled = false

    if world_environment != null and world_environment.environment != null:
        var environment: Environment = world_environment.environment
        var day_mix: float = clampf(sun_strength * 0.78 + daylight * 0.22, 0.0, 1.0)
        var twilight: float = clampf(1.0 - absf(sun_elevation) * 4.2, 0.0, 1.0)
        if sun_elevation < -0.26:
            twilight = 0.0

        var night_background: Color = Color(0.014, 0.020, 0.032, 1.0)
        var day_background: Color = Color(0.34, 0.43, 0.53, 1.0)
        var twilight_background: Color = Color(0.30, 0.15, 0.10, 1.0)
        var background: Color = night_background.lerp(day_background, day_mix)
        background = background.lerp(twilight_background, twilight * 0.30)
        environment.background_color = background

        var night_ambient: Color = Color(0.19, 0.23, 0.30, 1.0)
        var day_ambient: Color = Color(0.62, 0.65, 0.62, 1.0)
        var ambient: Color = night_ambient.lerp(day_ambient, day_mix)
        ambient = ambient.lerp(Color(0.64, 0.39, 0.27, 1.0), twilight * 0.18)
        environment.ambient_light_color = ambient
        environment.ambient_light_energy = lerpf(0.15, 0.66, day_mix) + 0.035 * moon_strength * (1.0 - daylight)
