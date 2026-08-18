extends "res://scripts/outside_director_ranger_v2.gd"

const FULL_DARKNESS_AMBIENT: float = 0.05
const NIGHT_MOON_FILL: float = 0.05

## v0.29 lighting balance:
## - full darkness ambient floor = 5%
## - moon fill is deliberately subtle and never counts as protective light
## - daylight curve remains bright enough for exploration
func _apply_v184_celestial_lighting() -> void:
    if outside_root == null or not is_instance_valid(outside_root):
        return

    var clock_minutes: float = fposmod(game_minutes, 1440.0)
    var clock_progress: float = clock_minutes / 1440.0
    var orbit_radians: float = clock_progress * TAU

    var sun_elevation: float = -cos(orbit_radians)
    var moon_elevation: float = cos(orbit_radians)

    var sun_strength: float = clampf((sun_elevation + 0.06) / 0.55, 0.0, 1.0)
    var moon_strength: float = clampf((moon_elevation + 0.05) / 0.70, 0.0, 1.0)
    var daylight: float = _get_daylight_factor()

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
        moon_fill.light_energy = NIGHT_MOON_FILL * moon_strength * night_weight
        moon_fill.shadow_enabled = false

    if world_environment != null and world_environment.environment != null:
        var environment: Environment = world_environment.environment
        var day_mix: float = clampf(sun_strength * 0.78 + daylight * 0.22, 0.0, 1.0)
        var twilight: float = clampf(1.0 - absf(sun_elevation) * 4.2, 0.0, 1.0)
        if sun_elevation < -0.26:
            twilight = 0.0

        var night_background: Color = Color(0.008, 0.012, 0.020, 1.0)
        var day_background: Color = Color(0.34, 0.43, 0.53, 1.0)
        var twilight_background: Color = Color(0.30, 0.15, 0.10, 1.0)
        var background: Color = night_background.lerp(day_background, day_mix)
        background = background.lerp(twilight_background, twilight * 0.30)
        environment.background_color = background

        var night_ambient: Color = Color(0.14, 0.17, 0.23, 1.0)
        var day_ambient: Color = Color(0.62, 0.65, 0.62, 1.0)
        var ambient: Color = night_ambient.lerp(day_ambient, day_mix)
        ambient = ambient.lerp(Color(0.64, 0.39, 0.27, 1.0), twilight * 0.18)
        environment.ambient_light_color = ambient
        environment.ambient_light_energy = lerpf(FULL_DARKNESS_AMBIENT, 0.66, day_mix)
